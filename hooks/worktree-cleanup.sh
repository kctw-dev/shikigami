#!/usr/bin/env bash
# hooks/worktree-cleanup.sh
# Issue #500 — SessionEnd / Sprint Review 後自動清理殘留 worktree
#
# 功能：
#   - 掃描 .claude/worktrees/ 目錄，找出所有殘留 worktree
#   - 檢查每個 worktree 是否有活躍進程（NFR1：不刪執行中的 subagent）
#   - 執行 git worktree remove 清理已完成的 worktree
#   - 輸出清理結果（清除數量、釋放磁碟空間）
#
# 環境變數：
#   DRY_RUN=1   — 只掃描不刪除，輸出預計清理的 worktree 列表
#
# 輸出標記：
#   [WORKTREE-CLEANUP] 清除 N 個殘留 worktree，釋放 X MB
#   [WORKTREE-CLEANUP-SKIP] <path> — 仍有活躍進程，跳過
#   [WORKTREE-CLEANUP-DRY] <path> — dry-run 模式，不實際刪除
#   [WARN] <原因>
#
# NFR1: 清理前確認 worktree 無活躍進程
# NFR2: 失敗不阻塞主流程（set +e）

set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKTREE_DIR="${REPO_ROOT}/.claude/worktrees"

DRY_RUN="${DRY_RUN:-0}"

# ── 確認 worktree 目錄存在 ───────────────────────────────────────────
if [[ ! -d "$WORKTREE_DIR" ]]; then
  echo "[WORKTREE-CLEANUP] .claude/worktrees/ 不存在，無需清理"
  exit 0
fi

# ── 取得已登記的 git worktree 列表（所有 worktree 路徑）────────────────
REGISTERED_WORKTREES=$(git -C "$REPO_ROOT" worktree list --porcelain 2>/dev/null \
  | grep '^worktree ' | awk '{print $2}' || echo "")

# ── 掃描 .claude/worktrees/ 子目錄 ────────────────────────────────────
REMOVED=0
SKIPPED=0
TOTAL_FREED_KB=0

shopt -s nullglob
WORKTREE_PATHS=("${WORKTREE_DIR}"/*)
shopt -u nullglob

if [[ ${#WORKTREE_PATHS[@]} -eq 0 ]]; then
  echo "[WORKTREE-CLEANUP] .claude/worktrees/ 無殘留目錄，跳過清理"
  exit 0
fi

for WT_PATH in "${WORKTREE_PATHS[@]}"; do
  [[ -d "$WT_PATH" ]] || continue

  WT_NAME="$(basename "$WT_PATH")"

  # ── NFR1：檢查是否有活躍進程使用此目錄 ─────────────────────────────
  ACTIVE_PROCS=""
  if command -v lsof &>/dev/null; then
    ACTIVE_PROCS=$(lsof +D "$WT_PATH" 2>/dev/null | grep -v "^COMMAND" | head -1 || echo "")
  elif command -v fuser &>/dev/null; then
    ACTIVE_PROCS=$(fuser -c "$WT_PATH" 2>/dev/null || echo "")
  else
    # fallback：用 /proc 檢查開啟的文件描述符（Linux only）
    ACTIVE_PROCS=$(ls /proc/*/cwd 2>/dev/null \
      | xargs -I{} readlink {} 2>/dev/null \
      | grep -F "$WT_PATH" | head -1 || echo "")
  fi

  if [[ -n "$ACTIVE_PROCS" ]]; then
    echo "[WORKTREE-CLEANUP-SKIP] ${WT_NAME} — 仍有活躍進程，跳過（running）"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # ── 計算目錄磁碟佔用 ──────────────────────────────────────────────
  DIR_SIZE_KB=$(du -sk "$WT_PATH" 2>/dev/null | awk '{print $1}' || echo "0")

  # ── DRY_RUN 模式：只報告不刪除 ────────────────────────────────────
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[WORKTREE-CLEANUP-DRY] ${WT_NAME} — 預計清除（${DIR_SIZE_KB} KB）"
    REMOVED=$((REMOVED + 1))
    TOTAL_FREED_KB=$((TOTAL_FREED_KB + DIR_SIZE_KB))
    continue
  fi

  # ── 實際清理：優先用 git worktree remove ──────────────────────────
  REMOVE_OK=false

  # 確認此路徑是已登記的 git worktree
  if echo "$REGISTERED_WORKTREES" | grep -qF "$WT_PATH"; then
    git -C "$REPO_ROOT" worktree remove --force "$WT_PATH" 2>/dev/null
    if [[ $? -eq 0 ]]; then
      REMOVE_OK=true
    fi
  fi

  # 若 git worktree remove 失敗（或不在 worktree 列表），直接刪目錄
  if [[ "$REMOVE_OK" == "false" ]]; then
    rm -rf "$WT_PATH" 2>/dev/null
    if [[ $? -eq 0 ]]; then
      REMOVE_OK=true
    else
      echo "[WARN] ${WT_NAME} 清除失敗，孤兒目錄可能殘留"
    fi
  fi

  if [[ "$REMOVE_OK" == "true" ]]; then
    REMOVED=$((REMOVED + 1))
    TOTAL_FREED_KB=$((TOTAL_FREED_KB + DIR_SIZE_KB))
  fi

done

# ── 計算釋放 MB（四捨五入）──────────────────────────────────────────
FREED_MB=$(( (TOTAL_FREED_KB + 512) / 1024 ))

# ── 輸出最終摘要 ───────────────────────────────────────────────────
if [[ "$DRY_RUN" == "1" ]]; then
  echo "[WORKTREE-CLEANUP] dry-run：預計清除 ${REMOVED} 個殘留 worktree，可釋放 ${FREED_MB} MB"
else
  echo "[WORKTREE-CLEANUP] 清除 ${REMOVED} 個殘留 worktree，釋放 ${FREED_MB} MB"
fi

if [[ $SKIPPED -gt 0 ]]; then
  echo "[WORKTREE-CLEANUP] 跳過 ${SKIPPED} 個仍在執行中的 worktree（active）"
fi

exit 0
