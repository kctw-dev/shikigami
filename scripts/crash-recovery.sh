#!/usr/bin/env bash
# scripts/crash-recovery.sh
# Story #405 — Temporal-style Crash Recovery
# ADR-041 策略 C：Hybrid Checkpoint + Side Effect Log
#
# 使用方式：
#   bash scripts/crash-recovery.sh [--dry-run]
#   bash scripts/crash-recovery.sh --checkpoint /path/to/sprint-checkpoint.json
#
# 功能：
#   1. 讀取 sprint-checkpoint.json，偵測未完成的 Sprint/Story
#   2. 掃描 side-effects.jsonl，找出已執行的 side effect（防重複）
#   3. 輸出恢復報告（dry-run）或設定環境變數供 SM 使用

set -uo pipefail

# ── 引數解析 ──
DRY_RUN=false
CHECKPOINT_FILE="${CHECKPOINT_FILE:-}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --checkpoint)
      shift
      CHECKPOINT_FILE="$1"
      ;;
    *) echo "[WARN] Unknown argument: $1" >&2 ;;
  esac
  shift
done

# ── 路徑初始化 ──
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
CHECKPOINT_FILE="${CHECKPOINT_FILE:-${REPO_ROOT}/docs/sprints/sprint-checkpoint.json}"

# ── 工具檢查 ──
check_dependency() {
  command -v "$1" > /dev/null 2>&1
}

# ── 主邏輯 ──
echo "[CRASH-RECOVERY] Starting crash recovery scan..."
echo "[CRASH-RECOVERY] Checkpoint: $CHECKPOINT_FILE"

# Step 1: 讀取 checkpoint
if [[ ! -f "$CHECKPOINT_FILE" ]]; then
  echo "[CRASH-RECOVERY] No checkpoint found. No recovery needed."
  exit 0
fi

# 解析 checkpoint（優先使用 jq，fallback 使用 grep）
if check_dependency jq; then
  SPRINT_NUM=$(jq -r '.sprint // 0' "$CHECKPOINT_FILE" 2>/dev/null || echo "0")
  CURRENT_STEP=$(jq -r '.current_step // "unknown"' "$CHECKPOINT_FILE" 2>/dev/null || echo "unknown")
  IN_PROGRESS_STORIES=$(jq -r '[.stories[] | select(.status == "in-progress") | .id] | join(",")' "$CHECKPOINT_FILE" 2>/dev/null || echo "")
  PENDING_STORIES=$(jq -r '[.stories[] | select(.status == "pending") | .id] | join(",")' "$CHECKPOINT_FILE" 2>/dev/null || echo "")
  COMPLETED_STORIES=$(jq -r '[.stories[] | select(.status == "completed") | .id] | join(",")' "$CHECKPOINT_FILE" 2>/dev/null || echo "")
  UPDATED_AT=$(jq -r '.updated_at // "unknown"' "$CHECKPOINT_FILE" 2>/dev/null || echo "unknown")
else
  # Fallback: grep-based parsing（無 jq 環境）
  SPRINT_NUM=$(grep -oP '"sprint":\s*\K\d+' "$CHECKPOINT_FILE" 2>/dev/null | head -1 || echo "0")
  CURRENT_STEP=$(grep -oP '"current_step":\s*"\K[^"]+' "$CHECKPOINT_FILE" 2>/dev/null | head -1 || echo "unknown")
  IN_PROGRESS_STORIES=$(grep -A2 '"in-progress"' "$CHECKPOINT_FILE" 2>/dev/null | grep -oP '"#\K\d+' | awk '{printf "#%s,", $1}' | sed 's/,$//' || echo "")
  PENDING_STORIES=""
  COMPLETED_STORIES=""
  UPDATED_AT=$(grep -oP '"updated_at":\s*"\K[^"]+' "$CHECKPOINT_FILE" 2>/dev/null | head -1 || echo "unknown")
fi

echo ""
echo "[CRASH-RECOVERY] Sprint ${SPRINT_NUM} Checkpoint Analysis:"
echo "  Current Step   : $CURRENT_STEP"
echo "  Last Updated   : $UPDATED_AT"
echo "  In-Progress    : ${IN_PROGRESS_STORIES:-（none）}"
echo "  Pending        : ${PENDING_STORIES:-（none）}"
echo "  Completed      : ${COMPLETED_STORIES:-（none）}"

# Step 2: 判斷是否需要 recovery
if [[ -z "$IN_PROGRESS_STORIES" && -z "$PENDING_STORIES" ]]; then
  echo ""
  echo "[CRASH-RECOVERY] All stories completed. No recovery needed."
  exit 0
fi

echo ""
echo "[CRASH-RECOVERY] Recovery needed!"
echo "  Stories to resume: ${IN_PROGRESS_STORIES:-}${PENDING_STORIES:+, }${PENDING_STORIES:-}"

# Step 3: 掃描 Side Effect Log（找出已執行的 side effects）
SESSION_ID="${SESSION_ID:-}"
if [[ -n "$SESSION_ID" ]]; then
  SE_LOG="${REPO_ROOT}/docs/sprints/tcb/sprint-${SPRINT_NUM}/session-${SESSION_ID}/side-effects.jsonl"
else
  # 若無 SESSION_ID，掃描所有 session 的 side effect logs
  SE_LOG_DIR="${REPO_ROOT}/docs/sprints/tcb/sprint-${SPRINT_NUM}"
  SE_LOG=""
fi

if [[ -f "$SE_LOG" ]]; then
  SE_COUNT=$(wc -l < "$SE_LOG" 2>/dev/null || echo 0)
  echo "[CRASH-RECOVERY] Side Effect Log: $SE_LOG ($SE_COUNT entries)"
  echo "[CRASH-RECOVERY] These side effects will be SKIPPED on replay:"
  grep -oP '"effect_type":"\K[^"]+' "$SE_LOG" 2>/dev/null | while read -r et; do echo "  - $et"; done || true
elif [[ -n "$SE_LOG_DIR" ]] && [[ -d "$SE_LOG_DIR" ]]; then
  SE_LOGS=$(find "$SE_LOG_DIR" -name "side-effects.jsonl" 2>/dev/null | head -5)
  if [[ -n "$SE_LOGS" ]]; then
    echo "[CRASH-RECOVERY] Found side effect logs in $SE_LOG_DIR:"
    echo "$SE_LOGS" | while read -r log; do
      count=$(wc -l < "$log" 2>/dev/null || echo 0)
      echo "  - $log ($count entries)"
    done
  fi
else
  echo "[CRASH-RECOVERY] No side effect log found. All side effects will execute normally."
fi

# Step 4: 輸出恢復指令（dry-run 模式）
echo ""
if [[ "$DRY_RUN" == "true" ]]; then
  echo "[CRASH-RECOVERY] DRY-RUN mode — showing recovery plan:"
  echo ""
  echo "  Recovery Plan:"
  if [[ -n "$IN_PROGRESS_STORIES" ]]; then
    echo "  1. Resume in-progress stories: $IN_PROGRESS_STORIES"
    echo "     → Load TCB checkpoint for each story"
    echo "     → Skip side effects already in side-effects.jsonl"
    echo "     → Continue from last recorded action"
  fi
  if [[ -n "$PENDING_STORIES" ]]; then
    echo "  2. Execute pending stories: $PENDING_STORIES"
    echo "     → Normal execution (no recovery needed)"
  fi
  echo "  3. Skip completed stories: ${COMPLETED_STORIES:-（none）}"
  echo ""
  echo "[CRASH-RECOVERY] DRY-RUN complete. To execute, run without --dry-run flag."
else
  # 非 dry-run：輸出環境變數供 SM 使用
  echo "[CRASH-RECOVERY] Exporting recovery state..."
  echo "RECOVERY_SPRINT=${SPRINT_NUM}"
  echo "RECOVERY_IN_PROGRESS=${IN_PROGRESS_STORIES}"
  echo "RECOVERY_PENDING=${PENDING_STORIES}"
  echo "RECOVERY_COMPLETED=${COMPLETED_STORIES}"
  echo "RECOVERY_CURRENT_STEP=${CURRENT_STEP}"
  echo "[CRASH-RECOVERY] Recovery state exported. SM can use these variables to resume."
fi

echo ""
echo "[CRASH-RECOVERY] Scan complete."
exit 0
