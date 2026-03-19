#!/usr/bin/env bash
# claim-issue.sh
# US-312 — 取得單一 Issue 的 Claim（遠端 ref 互斥鎖 + 本地 flock）
# US-316 — 修復：unfetched SHA 保守拒絕、stale delete WARN、REPO_FP 兩步法、flock/claim_remote 分離
#
# 用法：bash hooks/claim-issue.sh <issue_id>
#
# 輸出標記：
#   [CLAIM-OK] refs/claims/<id>          — 成功取得 claim
#   [CLAIM-BLOCKED] refs/claims/<id>     — 已被其他 session 占用
#   [CLAIM-STALE] refs/claims/<id> 已過期 Xh，強制清除  — stale lock 清除後重新 claim
#   [WARN] <原因>                        — 降級警告（不阻塞）
#
# 失敗不阻塞（AC-5/AC-6）：gh CLI 不可用時輸出 [WARN] 繼續

set +e

ID="${1:-}"
if [[ -z "$ID" ]]; then
  echo "[WARN] claim-issue.sh: 缺少 issue_id 參數" >&2
  exit 1
fi

REF="refs/claims/${ID}"
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
LABEL="bot:session-${SESSION_ID}"

# ── repo fingerprint 計算（兩步法，#6/#13 修復）──────────────────
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [[ -z "$REPO_ROOT" ]]; then
  echo "[WARN] claim-issue.sh: 非 git repo，REPO_FP 使用 fallback"
  REPO_FP="fallback0"
else
  REPO_FP=$(echo "$REPO_ROOT" | sha256sum 2>/dev/null | cut -c1-8 \
           || echo "$REPO_ROOT" | md5sum 2>/dev/null | cut -c1-8 \
           || echo "fallback0")
fi
LOCK_FILE="/tmp/shikigami-claims-${REPO_FP}.lock"

# ── 取得 gh 登入使用者（可選）──────────────────────────────────
GH_USER=""
if command -v gh &>/dev/null; then
  GH_USER=$(gh api user -q '.login' 2>/dev/null || echo "")
fi

# ── claim_remote：遠端 ref 互斥鎖 ───────────────────────────────
claim_remote() {
  local ISSUE_ID="$1"
  local ISSUE_REF="refs/claims/${ISSUE_ID}"

  # Stale lock 偵測：ref 存在超過 2h → 強制清除後重新 claim
  EXISTING=$(git ls-remote origin "$ISSUE_REF" 2>/dev/null)
  if [[ -n "$EXISTING" ]]; then
    # 取得 ref 的 commit 時間
    REF_SHA=$(echo "$EXISTING" | awk '{print $1}')

    # #7 修復：先嘗試 git fetch 取得 commit，避免 unfetched SHA 誤判
    COMMIT_TIME=$(git log -1 --format="%ct" "$REF_SHA" 2>/dev/null)
    if [[ -z "$COMMIT_TIME" ]]; then
      # 嘗試 fetch 後再查
      git fetch origin "$REF_SHA" 2>/dev/null || true
      COMMIT_TIME=$(git log -1 --format="%ct" "$REF_SHA" 2>/dev/null)
    fi

    if [[ -z "$COMMIT_TIME" ]]; then
      # #7 修復：SHA 查不到，保守拒絕（不 fallback 為 "0"）
      echo "[WARN] $ISSUE_REF SHA=${REF_SHA} 無法取得 commit 時間，保守拒絕 claim"
      echo "[CLAIM-BLOCKED] $ISSUE_REF（SHA 未知，保守拒絕）"
      return 1
    fi

    NOW=$(date +%s)
    AGE_SECONDS=$(( NOW - COMMIT_TIME ))
    AGE_HOURS=$(( AGE_SECONDS / 3600 ))

    if [[ $AGE_HOURS -ge 2 ]]; then
      # Stale lock：強制清除
      # #1 修復：stale delete 失敗時輸出 WARN
      git push origin --delete "$ISSUE_REF" 2>/dev/null
      local DELETE_EXIT=$?
      if [[ $DELETE_EXIT -ne 0 ]]; then
        echo "[WARN] $ISSUE_REF stale lock 強制清除失敗（exit=$DELETE_EXIT），保守拒絕"
        echo "[CLAIM-BLOCKED] $ISSUE_REF（stale delete 失敗，保守拒絕）"
        return 1
      fi
      echo "[CLAIM-STALE] $ISSUE_REF 已過期 ${AGE_HOURS}h，強制清除"
      # 清除後繼續 claim
    else
      echo "[CLAIM-BLOCKED] $ISSUE_REF 已被占用"
      return 1
    fi
  fi

  # 推送遠端 ref（原子性：同名 ref 若已存在則失敗）
  git push origin HEAD:"$ISSUE_REF" 2>/dev/null
  local PUSH_EXIT=$?
  if [[ $PUSH_EXIT -ne 0 ]]; then
    # #8 修復：claim_remote push 失敗（區別於 flock 失敗）
    echo "[CLAIM-BLOCKED] $ISSUE_REF push 失敗（race condition 或無 remote，遠端鎖未取得）"
    return 1
  fi

  # 展示層：設定 assignee + label（gh 可選，AC-5）
  if [[ -n "$GH_USER" ]]; then
    gh issue edit "$ISSUE_ID" \
      --add-assignee "$GH_USER" \
      2>/dev/null || echo "[WARN] gh add-assignee 失敗，繼續"
  else
    echo "[WARN] gh CLI 不可用或未認證，跳過 assignee 設定"
  fi

  if command -v gh &>/dev/null && [[ "$SESSION_ID" != "unknown" ]]; then
    gh issue edit "$ISSUE_ID" \
      --add-label "$LABEL" \
      2>/dev/null || echo "[WARN] gh add-label 失敗，繼續"
  fi

  echo "[CLAIM-OK] $ISSUE_REF"
  return 0
}

# ── 主流程：本地鎖 + 遠端鎖 ────────────────────────────────────
if command -v flock &>/dev/null; then
  # 有 flock：本地鎖保護 + 遠端鎖
  # #8 修復：flock 失敗訊息與 claim_remote 失敗訊息分離
  flock -n "$LOCK_FILE" -c "$(declare -f claim_remote); claim_remote '$ID'" \
    || echo "[CLAIM-BLOCKED] 本地 flock 取得失敗（本地並行衝突，非遠端鎖問題）"
else
  # 無 flock（macOS）：直接走遠端鎖
  claim_remote "$ID"
fi
