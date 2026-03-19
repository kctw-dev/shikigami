#!/usr/bin/env bash
# session-end-release.sh
# US-312 — SessionEnd hook：自動 release 本 session 的所有 claim
#
# 功能：
#   - 列出 refs/claims/*，篩選本 session 的 claim（透過 gh label）
#   - 若 SESSION_ID 未知，release 所有 refs/claims/*（寧可多放不可多鎖）
#   - 逐一呼叫 hooks/release-issue.sh 執行 release
#   - 失敗不阻塞（AC-6：set +e / || true）
#   - 清除本地 lock file
#
# 輸出標記：
#   [CLAIM-RELEASE] refs/claims/<id>
#   [CLAIM-RELEASE-SKIP] 無本 session 的 claim
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

exit 0
