#!/usr/bin/env bash
# cleanup-worktrees.sh — Sprint 完成後 git worktree 自動清理（OOM 防護）
# Sprint 155 | #735
# 只清理已合併至 main 的 sprint-N/ 分支 worktree

set -euo pipefail

# ── 參數處理 ──────────────────────────────────────────────────────
DRY_RUN=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --verbose) VERBOSE=true ;;
    --help)
      echo "Usage: $0 [--dry-run] [--verbose]"
      echo "  --dry-run  預覽將清理的 worktree，不實際執行"
      echo "  --verbose  顯示詳細輸出"
      exit 0
      ;;
    *) echo "[WARN] 未知參數: $1" ;;
  esac
  shift
done

# ── 路徑設定 ──────────────────────────────────────────────────────
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
CRUISE_LOG_DIR="${REPO_ROOT}/docs/cruise-logs"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

log_info()  { echo "[INFO] $1"; }
log_warn()  { echo "[WARN] $1"; }
log_clean() { echo "[CLEAN] $1"; }
log_skip()  { echo "[SKIP] $1"; }
log_dry()   { echo "[DRY-RUN] 將清理: $1"; }

write_cruise_log() {
  local entry="$1"
  local log_file="${CRUISE_LOG_DIR}/worktree-cleanup-$(date +%Y%m%d).jsonl"
  mkdir -p "$CRUISE_LOG_DIR" 2>/dev/null || true
  printf '%s\n' "$entry" >> "$log_file" 2>/dev/null || \
    echo "[WARN] cruise log 寫入失敗，略過" >&2
}

# ── 確認 git repo ──────────────────────────────────────────────────
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "[ERROR] 非 git repository，中止"
  exit 1
fi

log_info "cleanup-worktrees.sh 開始（dry-run=$DRY_RUN）"

# ── 取得已合併至 main 的遠端分支清單 ──────────────────────────────
# AC2: 使用 --merged main 保護機制
git fetch --prune origin 2>/dev/null || log_warn "git fetch 失敗，使用本地快取"

MERGED_BRANCHES=$(git branch -r --merged origin/main 2>/dev/null | \
  grep -E "origin/sprint-[0-9]+" | \
  sed 's|origin/||' | \
  tr -d ' ' || echo "")

if [ -z "$MERGED_BRANCHES" ]; then
  log_info "沒有已合併至 main 的 sprint-N/ 遠端分支，無需清理"
  exit 0
fi

$VERBOSE && log_info "已合併的 sprint 分支：$(echo "$MERGED_BRANCHES" | tr '\n' ' ')"

# ── 掃描現有 worktree ──────────────────────────────────────────────
# AC1: 掃描所有 sprint-N/ 分支的 worktree
CLEANED=0
SKIPPED=0

while IFS= read -r line; do
  [[ "$line" == worktree* ]] && CURRENT_WORKTREE="${line#worktree }" && continue
  [[ "$line" == branch* ]]   && CURRENT_BRANCH="${line#branch refs/heads/}" && continue
  if [[ -z "$line" && -n "${CURRENT_BRANCH:-}" && -n "${CURRENT_WORKTREE:-}" ]]; then
    # 只處理 sprint-N/ 開頭的 worktree（AC1）
    if [[ "$CURRENT_BRANCH" =~ ^sprint-[0-9]+ ]]; then
      # 保護機制：只清理已合併的分支（AC2 --merged main）
      if echo "$MERGED_BRANCHES" | grep -qx "$CURRENT_BRANCH"; then
        if $DRY_RUN; then
          log_dry "$CURRENT_BRANCH ($CURRENT_WORKTREE)"
        else
          log_clean "移除已合併 worktree: $CURRENT_BRANCH"
          git worktree remove --force "$CURRENT_WORKTREE" 2>/dev/null && \
            CLEANED=$((CLEANED+1)) || \
            log_warn "移除失敗: $CURRENT_WORKTREE"
          # NFR2: 寫入 cruise log
          write_cruise_log "{\"type\":\"worktree-cleanup\",\"branch\":\"$CURRENT_BRANCH\",\"worktree\":\"$CURRENT_WORKTREE\",\"ts\":\"$TIMESTAMP\"}"
        fi
        CLEANED=$((CLEANED+1))
      else
        log_skip "保留未合併 worktree: $CURRENT_BRANCH"
        SKIPPED=$((SKIPPED+1))
      fi
    fi
    CURRENT_BRANCH=""
    CURRENT_WORKTREE=""
  fi
done < <(git worktree list --porcelain; echo "")

# ── 結果摘要 ──────────────────────────────────────────────────────
if $DRY_RUN; then
  log_info "[DRY-RUN 完成] 預計清理 $CLEANED 個 worktree，保留 $SKIPPED 個"
else
  log_info "清理完成：已清理 $CLEANED 個，保留 $SKIPPED 個"
  # NFR2: 寫摘要至 cruise log
  write_cruise_log "{\"type\":\"worktree-cleanup-summary\",\"cleaned\":$CLEANED,\"skipped\":$SKIPPED,\"ts\":\"$TIMESTAMP\"}" || true
fi

echo "[WORKTREE-CLEANUP-OK] cleaned=$CLEANED skipped=$SKIPPED"
