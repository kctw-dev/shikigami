#!/usr/bin/env bash
# session-end-release.sh
# US-312/US-311 — SessionEnd hook：自動 release 本 session 的所有 claim 與 file lock
#
# 功能：
#   - 列出 refs/claims/*，篩選本 session 的 claim（透過 gh label）
#   - 若 SESSION_ID 未知，release 所有 refs/claims/*（寧可多放不可多鎖）
#   - 逐一呼叫 hooks/release-issue.sh 執行 release
#   - 列出 refs/file-locks/*，刪除本 session 持有的所有檔案鎖（US-311 AC-5）
#   - 失敗不阻塞（AC-6：set +e / || true）
#   - 清除本地 lock file 與 metadata
#
# 輸出標記：
#   [CLAIM-RELEASE] refs/claims/<id>
#   [CLAIM-RELEASE-SKIP] 無本 session 的 claim
#   [FILE-LOCK-RELEASE] refs/file-locks/<hash>
#   [WARN] <原因>

# AC-6：失敗不阻塞，所有操作使用 || true
set +e

SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
LABEL="bot:session-${SESSION_ID}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_SCRIPT="${SCRIPT_DIR}/release-issue.sh"

# ── repo fingerprint 計算（本地鎖 cleanup）──────────────────────
REPO_FP=$(git rev-parse --show-toplevel 2>/dev/null | sha256sum 2>/dev/null | cut -c1-8 \
         || git rev-parse --show-toplevel 2>/dev/null | md5sum 2>/dev/null | cut -c1-8 \
         || echo "fallback0")
LOCK_FILE="/tmp/shikigami-claims-${REPO_FP}.lock"

# ── 列出所有 refs/claims/* ──────────────────────────────────────
ALL_REFS=$(git ls-remote origin "refs/claims/*" 2>/dev/null | awk '{print $2}' || echo "")

if [[ -z "$ALL_REFS" ]]; then
  echo "[CLAIM-RELEASE-SKIP] 無任何 claim ref，略過 release"
else
  RELEASED=0

  while IFS= read -r REF; do
    [[ -z "$REF" ]] && continue

    # 提取 ID（refs/claims/<id> → <id>）
    ID="${REF#refs/claims/}"

    if [[ "$SESSION_ID" == "unknown" ]]; then
      # SESSION_ID 未知：寧可多放不可多鎖，release 所有 ref
      echo "[WARN] SESSION_ID 未知，release 所有 claim ref（寬鬆策略）"
      bash "$RELEASE_SCRIPT" "$ID" || true
      RELEASED=$((RELEASED + 1))
    elif command -v gh &>/dev/null; then
      # SESSION_ID 已知：依 label 篩選，僅 release 本 session 的 claim
      LABELS=$(gh issue view "$ID" --json labels -q '.labels[].name' 2>/dev/null || echo "")
      if echo "$LABELS" | grep -qF "$LABEL"; then
        bash "$RELEASE_SCRIPT" "$ID" || true
        RELEASED=$((RELEASED + 1))
      fi
    else
      # gh 不可用但 SESSION_ID 已知：同樣採寬鬆策略
      echo "[WARN] gh CLI 不可用，release $REF（寬鬆策略）"
      bash "$RELEASE_SCRIPT" "$ID" || true
      RELEASED=$((RELEASED + 1))
    fi
  done <<< "$ALL_REFS"

  if [[ $RELEASED -eq 0 ]]; then
    echo "[CLAIM-RELEASE-SKIP] 無本 session（${SESSION_ID}）的 claim"
  fi
fi

# ── 清除本地 lock file ─────────────────────────────────────────
if [[ -f "$LOCK_FILE" ]]; then
  rm -f "$LOCK_FILE" 2>/dev/null || true
  echo "[CLAIM-RELEASE] 本地 lock file 已清除：$LOCK_FILE"
fi

# ── US-311 AC-5：釋放本 session 持有的所有 file locks ────────────
RELEASE_FILE_LOCK_SCRIPT="${SCRIPT_DIR}/release-file-lock.sh"
META_DIR="/tmp/shikigami-file-locks-${REPO_FP}"

FILE_LOCK_REFS=$(git ls-remote origin "refs/file-locks/*" 2>/dev/null | awk '{print $2}' || echo "")

if [[ -n "$FILE_LOCK_REFS" ]]; then
  FILE_LOCK_RELEASED=0

  while IFS= read -r FILE_REF; do
    [[ -z "$FILE_REF" ]] && continue

    HASH="${FILE_REF#refs/file-locks/}"
    META_FILE="${META_DIR}/${HASH}.meta"

    # 判斷是否屬於本 session
    SHOULD_RELEASE=false
    if [[ "$SESSION_ID" == "unknown" ]]; then
      # SESSION_ID 未知：寬鬆策略，釋放所有
      echo "[WARN] SESSION_ID 未知，release 所有 file lock ref（寬鬆策略）"
      SHOULD_RELEASE=true
    elif [[ -f "$META_FILE" ]]; then
      # 有本地 metadata：檢查 session_id
      OWNER_SESSION=$(grep '"session_id"' "$META_FILE" 2>/dev/null \
        | sed 's/.*"session_id": *"\([^"]*\)".*/\1/' || echo "")
      if [[ "$OWNER_SESSION" == "$SESSION_ID" ]]; then
        SHOULD_RELEASE=true
      fi
    else
      # 無本地 metadata：寬鬆策略，嘗試釋放（寧可多放不可多鎖）
      echo "[WARN] file lock $FILE_REF 無本地 metadata，採寬鬆策略 release"
      SHOULD_RELEASE=true
    fi

    if [[ "$SHOULD_RELEASE" == "true" ]]; then
      git push origin --delete "$FILE_REF" 2>/dev/null || true
      rm -f "${META_DIR}/${HASH}.meta" "${META_DIR}/${HASH}.lock" 2>/dev/null || true
      echo "[FILE-LOCK-RELEASE] $FILE_REF"
      FILE_LOCK_RELEASED=$((FILE_LOCK_RELEASED + 1))
    fi
  done <<< "$FILE_LOCK_REFS"

  if [[ $FILE_LOCK_RELEASED -eq 0 ]]; then
    echo "[FILE-LOCK-RELEASE] 無本 session（${SESSION_ID}）的 file lock，略過"
  fi
else
  echo "[FILE-LOCK-RELEASE] 無任何 file lock ref，略過"
fi

# ── 清除本地 metadata 目錄（若已空）─────────────────────────────
if [[ -d "$META_DIR" ]]; then
  META_COUNT=$(find "$META_DIR" -name "*.meta" 2>/dev/null | wc -l || echo "1")
  if [[ "$META_COUNT" -eq 0 ]]; then
    rmdir "$META_DIR" 2>/dev/null || true
  fi
fi

exit 0
