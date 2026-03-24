#!/usr/bin/env bash
# task-gate.sh — #538 AC7：Sprint Execution 啟動時檢查 Task List 完整性
#
# 用途：
#   Sprint Execution 啟動時，由 agent 主動呼叫此腳本檢查 Task List 是否已為
#   當前 Sprint 建立對應 Task（格式：{repo}/sprint-{N}-{phase}）。
#
#   由於 Claude Task 工具無法在 shell script 中直接呼叫，此腳本採用
#   「標記 + WARN 輸出」模式：
#     - 若 SPRINT_TASK_INITIALIZED 標記不存在 → 輸出 [TASK-GATE-WARN]，要求 agent 補建 Task
#     - 若標記存在 → [TASK-GATE-PASS]，繼續執行
#
# 呼叫方式（由 agent 在 Sprint Execution 啟動時執行）：
#   SPRINT_NUM=<N> bash hooks/task-gate.sh
#
# 環境變數：
#   SPRINT_NUM — Sprint 編號（必填）
#   REPO_ROOT  — Repo 根目錄（選填，預設為 git rev-parse --show-toplevel）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── 讀取參數 ────────────────────────────────────────────────────────────────
SPRINT_NUM="${SPRINT_NUM:-}"
REPO_ROOT="${REPO_ROOT:-$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$SCRIPT_DIR/..")}"

if [[ -z "$SPRINT_NUM" ]]; then
  echo "[TASK-GATE-SKIP] SPRINT_NUM 未設定，跳過 Task Gate 檢查"
  exit 0
fi

# ── 解析 OWNER_REPO ──────────────────────────────────────────────────────────
OWNER_REPO=$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null \
  | sed -E 's#^(https?://[^/]+/|git@[^:]+:)##; s#\.git$##' \
  || echo "")

if [[ -z "$OWNER_REPO" ]] || [[ ! "$OWNER_REPO" =~ ^[^/]+/[^/]+$ ]]; then
  echo "[TASK-GATE-SKIP] 無法解析 OWNER_REPO，跳過 Task Gate 檢查"
  exit 0
fi

# ── 檢查 Task 初始化標記 ──────────────────────────────────────────────────────
# 使用 /tmp 標記檔案追蹤 Task 是否已建立（輕量實作，重啟後失效觸發補建）
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
TASK_INIT_FLAG="/tmp/shikigami-task-init-sprint${SPRINT_NUM}-${SESSION_ID}.flag"

if [[ -f "$TASK_INIT_FLAG" ]]; then
  echo "[TASK-GATE-PASS] Sprint ${SPRINT_NUM} Task List 已初始化（${OWNER_REPO}/sprint-${SPRINT_NUM}-*）"
  exit 0
fi

# ── 輸出 WARN，要求 agent 補建 Task ──────────────────────────────────────────
echo "[TASK-GATE-WARN] Sprint ${SPRINT_NUM} Task List 尚未初始化！"
echo ""
echo "請立即執行以下 Task 建立指令（TaskCreate 工具）："
echo "  TaskCreate subject=\"${OWNER_REPO}/sprint-${SPRINT_NUM}-planning\"   status=pending"
echo "  TaskCreate subject=\"${OWNER_REPO}/sprint-${SPRINT_NUM}-execution\"  status=pending"
echo "  TaskCreate subject=\"${OWNER_REPO}/sprint-${SPRINT_NUM}-review\"     status=pending"
echo ""
echo "建立完成後，執行以下指令建立標記："
echo "  touch ${TASK_INIT_FLAG}"
echo ""
echo "Task 命名格式：${OWNER_REPO}/sprint-${SPRINT_NUM}-{phase}"
echo "compact 後 TaskList 查詢前綴：${OWNER_REPO}/sprint-${SPRINT_NUM}-"

# 輸出 exit 2 作為 WARN 信號（非 1，不阻塞主流程，但讓 agent 看見提示）
exit 2
