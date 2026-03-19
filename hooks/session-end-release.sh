#!/usr/bin/env bash
# session-end-release.sh
# US-312 — SessionEnd hook：自動 release 本 session 的所有 claim
#
# 功能：
#   - 列出 refs/claims/*，篩選本 session 的 claim
#   - 逐一 release（delete ref + remove assignee + remove label）
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

# ── repo fingerprint 計算（本地鎖 cleanup）──────────────────────
REPO_FP=$(git rev-parse --show-toplevel 2>/dev/null | sha256sum 2>/dev/null | cut -c1-8 \
         || git rev-parse --show-toplevel 2>/dev/null | md5sum 2>/dev/null | cut -c1-8 \
         || echo "fallback0")
LOCK_FILE="/tmp/shikigami-claims-${REPO_FP}.lock"

# ── 取得 gh 登入使用者（可選）──────────────────────────────────
GH_USER=""
if command -v gh &>/dev/null; then
  GH_USER=$(gh api user -q '.login' 2>/dev/null || echo "")
fi

# ── release_claim：釋放單一 claim ───────────────────────────────
release_claim() {
  local ID=$1
  local REF="refs/claims/${ID}"

  # 1. 刪除遠端 ref
  git push origin --delete "$REF" 2>/dev/null || true

  # 2. 展示層清除（gh 可選，AC-5）
  if [[ -n "$GH_USER" ]]; then
    gh issue edit "$ID" \
      --remove-assignee "$GH_USER" \
      2>/dev/null || echo "[WARN] gh remove-assignee 失敗，繼續"

    gh issue edit "$ID" \
      --remove-label "$LABEL" \
      2>/dev/null || echo "[WARN] gh remove-label 失敗，繼續"
  else
    echo "[WARN] gh CLI 不可用或未認證，跳過展示層清除"
  fi

  echo "[CLAIM-RELEASE] $REF"
}

# ── 主流程 ─────────────────────────────────────────────────────

# 列出所有 refs/claims/*
ALL_REFS=$(git ls-remote origin "refs/claims/*" 2>/dev/null | awk '{print $2}' || echo "")

if [[ -z "$ALL_REFS" ]]; then
  echo "[CLAIM-RELEASE-SKIP] 無任何 claim ref，略過 release"
else
  RELEASED=0

  # 若 SESSION_ID 為 unknown，嘗試透過 gh label 比對
  # 若 SESSION_ID 已知，依 label 篩選；否則釋放全部本機 ref
  while IFS= read -r REF; do
    [[ -z "$REF" ]] && continue

    # 提取 ID（refs/claims/<id> → <id>）
    ID="${REF#refs/claims/}"

    # 確認是否為本 session 的 claim（透過 gh label 查詢）
    IS_MINE=0
    if [[ "$SESSION_ID" != "unknown" ]] && command -v gh &>/dev/null; then
      LABELS=$(gh issue view "$ID" --json labels -q '.labels[].name' 2>/dev/null || echo "")
      if echo "$LABELS" | grep -qF "$LABEL"; then
        IS_MINE=1
      fi
    else
      # SESSION_ID 未知或 gh 不可用：無法精確篩選，跳過（保守策略）
      echo "[WARN] SESSION_ID 未知或 gh 不可用，跳過 $REF 的 release（保守策略）"
      continue
    fi

    if [[ $IS_MINE -eq 1 ]]; then
      release_claim "$ID"
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
