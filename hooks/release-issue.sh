#!/usr/bin/env bash
# release-issue.sh
# US-312 — 釋放單一 Issue 的 Claim（刪除遠端 ref + 清除展示層）
# US-316 — 修復：#2 push --delete 失敗不再假成功；DISPUTE 修復：delete 失敗輸出 [CLAIM-RELEASE-FAILED] + exit 1
#
# 用法：bash hooks/release-issue.sh <issue_id>
#
# 輸出標記：
#   [CLAIM-RELEASE] refs/claims/<id>          — 成功釋放 claim（遠端 delete 成功）
#   [CLAIM-RELEASE-FAILED] refs/claims/<id>   — 釋放失敗（遠端 delete 失敗，exit 1）
#   [WARN] <原因>                              — 降級警告（不阻塞）
#
# 失敗不阻塞（AC-5/AC-6）：gh CLI 不可用時輸出 [WARN] 繼續

set +e

ID="${1:-}"
if [[ -z "$ID" ]]; then
  echo "[WARN] release-issue.sh: 缺少 issue_id 參數" >&2
  exit 1
fi

REF="refs/claims/${ID}"
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
LABEL="bot:session-${SESSION_ID}"

# ── 取得 gh 登入使用者（可選）──────────────────────────────────
GH_USER=""
if command -v gh &>/dev/null; then
  GH_USER=$(gh api user -q '.login' 2>/dev/null || echo "")
fi

# ── 1. 刪除遠端 ref ─────────────────────────────────────────────
# #2 修復（DISPUTE）：delete 成功才輸出 [CLAIM-RELEASE]，失敗輸出 [CLAIM-RELEASE-FAILED] + exit 1
git push origin --delete "$REF" 2>/dev/null
DELETE_EXIT=$?
if [[ $DELETE_EXIT -ne 0 ]]; then
  echo "[WARN] $REF 遠端刪除失敗（exit=$DELETE_EXIT），可能已被他人清除或無網路"
  echo "[CLAIM-RELEASE-FAILED] $REF"
  exit 1
fi

# ── 2. 展示層清除（gh 可選，AC-5）──────────────────────────────
if [[ -n "$GH_USER" ]]; then
  gh issue edit "$ID" \
    --remove-assignee "$GH_USER" \
    2>/dev/null || echo "[WARN] gh remove-assignee 失敗，繼續"

  if [[ "$SESSION_ID" != "unknown" ]]; then
    gh issue edit "$ID" \
      --remove-label "$LABEL" \
      2>/dev/null || echo "[WARN] gh remove-label 失敗，繼續"
  fi
else
  echo "[WARN] gh CLI 不可用或未認證，跳過展示層清除"
fi

# delete 成功才到達此行，輸出 [CLAIM-RELEASE]
echo "[CLAIM-RELEASE] $REF"
