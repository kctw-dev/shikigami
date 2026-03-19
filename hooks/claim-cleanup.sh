#!/usr/bin/env bash
# claim-cleanup.sh
# US-313 AC-3 — 孤兒 Claim 清理（TTL 到期自動釋放）
#
# 用法：
#   bash hooks/claim-cleanup.sh              # 清理超過 2 小時的 stale claims
#   bash hooks/claim-cleanup.sh --dry-run    # 僅列出，不清理
#   bash hooks/claim-cleanup.sh --ttl <秒>  # 指定 TTL（預設 7200，供測試使用）
#
# 輸出格式：
#   [DRY-RUN] refs/claims/<id> 已過期 Xh Ym（stale，但未清理）
#   [CLAIM-CLEANUP] refs/claims/<id> 已過期 Xh Ym，清理中...
#   [CLAIM-CLEANUP] <N> 個 stale claim 已清理
#   [WARN] <原因>                             — 降級警告（不阻塞）
#
# 此腳本可手動執行或搭配 schedule skill 定期清理孤兒 claim

set +e

# ── 參數解析 ─────────────────────────────────────────────────────
DRY_RUN=false
TTL_SECONDS=7200  # 預設 2 小時

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --ttl)
      TTL_SECONDS="${2:-7200}"
      shift 2
      ;;
    *)
      echo "[WARN] claim-cleanup.sh: 未知參數 $1" >&2
      shift
      ;;
  esac
done

# ── 取得 HOOK_DIR（供呼叫 release-issue.sh）────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_SCRIPT="$SCRIPT_DIR/release-issue.sh"

# ── 確認 git 可用 ────────────────────────────────────────────────
if ! command -v git &>/dev/null; then
  echo "[WARN] claim-cleanup.sh: git 不可用，跳過清理"
  exit 0
fi

# ── 確認有 remote origin ─────────────────────────────────────────
if ! git remote get-url origin &>/dev/null; then
  echo "[WARN] claim-cleanup.sh: 無法取得 remote origin，跳過清理"
  exit 0
fi

# ── 列出所有 refs/claims/* ───────────────────────────────────────
REFS=$(git ls-remote origin 'refs/claims/*' 2>/dev/null)
if [[ -z "$REFS" ]]; then
  echo "[CLAIM-CLEANUP] 0 個 stale claim 已清理"
  exit 0
fi

NOW=$(date +%s)
STALE_COUNT=0
CLEANED_COUNT=0

# ── 對每個 ref 檢查 commit timestamp ────────────────────────────
while IFS=$'\t' read -r SHA REF_NAME; do
  [[ -z "$SHA" || -z "$REF_NAME" ]] && continue

  # 提取 issue ID（refs/claims/<id> → <id>）
  ISSUE_ID="${REF_NAME#refs/claims/}"

  # 取得 ref commit 時間
  COMMIT_TIME=$(git log -1 --format="%ct" "$SHA" 2>/dev/null || echo "")

  if [[ -z "$COMMIT_TIME" || "$COMMIT_TIME" == "0" ]]; then
    # 無法取得時間，視為可能 stale，輸出 [WARN] 但不清理（保守策略）
    echo "[WARN] $REF_NAME 無法取得 commit 時間，跳過（保守策略）"
    continue
  fi

  AGE_SECONDS=$(( NOW - COMMIT_TIME ))

  if [[ $AGE_SECONDS -ge $TTL_SECONDS ]]; then
    STALE_COUNT=$((STALE_COUNT + 1))
    AGE_HOURS=$(( AGE_SECONDS / 3600 ))
    AGE_MINUTES=$(( (AGE_SECONDS % 3600) / 60 ))

    if [[ "$DRY_RUN" == "true" ]]; then
      echo "[DRY-RUN] $REF_NAME 已過期 ${AGE_HOURS}h ${AGE_MINUTES}m（stale，但未清理）"
    else
      echo "[CLAIM-CLEANUP] $REF_NAME 已過期 ${AGE_HOURS}h ${AGE_MINUTES}m，清理中..."

      # 優先使用 release-issue.sh（維持展示層一致性）
      if [[ -f "$RELEASE_SCRIPT" ]]; then
        bash "$RELEASE_SCRIPT" "$ISSUE_ID" 2>/dev/null || \
          git push origin --delete "$REF_NAME" 2>/dev/null || \
          echo "[WARN] $REF_NAME 清理失敗，繼續"
      else
        # release-issue.sh 不可用時，直接刪除遠端 ref
        git push origin --delete "$REF_NAME" 2>/dev/null || \
          echo "[WARN] $REF_NAME 清理失敗，繼續"
      fi

      CLEANED_COUNT=$((CLEANED_COUNT + 1))
    fi
  fi
done <<< "$REFS"

# ── 輸出總結 ─────────────────────────────────────────────────────
if [[ "$DRY_RUN" == "true" ]]; then
  echo "[CLAIM-CLEANUP] --dry-run 模式：偵測到 ${STALE_COUNT} 個 stale claim（未清理）"
else
  echo "[CLAIM-CLEANUP] ${CLEANED_COUNT} 個 stale claim 已清理"
fi
