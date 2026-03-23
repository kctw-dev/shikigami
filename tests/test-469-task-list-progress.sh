#!/usr/bin/env bash
# tests/test-469-task-list-progress.sh
# #469 Cruise/Sprint 執行時建立 Task List — 防止 compact 後跳步
# AC1: Cruise 啟動時呼叫 TaskCreate 建立所有 phase 的 task
# AC2: 每個 phase 完成時呼叫 TaskUpdate 標記 completed
# AC3: Sprint 執行啟動時同樣建立 Task List（Planning/Execution/Review）
# AC4: compact 後透過 TaskList 恢復進度，跳過已完成的 phase
# AC5: 多 session 隔離：不同 session 的 Task List 互不干擾
# AC6: 失敗恢復：phase 執行失敗時 task 標記為 failed

set -uo pipefail

PASS_COUNT=0
FAIL_COUNT=0

pass() {
  echo "PASS: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "FAIL: $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -qE "$pattern" "$file" 2>/dev/null; then
    pass "$label"
  else
    fail "$label (pattern='${pattern}' not found in $file)"
  fi
}

assert_not_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if ! grep -qE "$pattern" "$file" 2>/dev/null; then
    pass "$label"
  else
    fail "$label (pattern='${pattern}' found but should not be in $file)"
  fi
}

assert_file_exists() {
  local path="$1"
  local label="$2"
  if [[ -f "$path" ]]; then
    pass "$label"
  else
    fail "$label (file not found: $path)"
  fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CRUISE_SKILL="${REPO_ROOT}/skills/cruise/SKILL.md"
SPRINT_EXEC_SKILL="${REPO_ROOT}/skills/sprint-execution/SKILL.md"

echo "=== #469 Task List 防跳步驗證 ==="
echo "CRUISE_SKILL: $CRUISE_SKILL"
echo "SPRINT_EXEC_SKILL: $SPRINT_EXEC_SKILL"
echo ""

# ---------------------------------------------------------------------------
# AC1: Cruise 啟動時 TaskCreate 建立所有 phase 的 task
# ---------------------------------------------------------------------------
echo "--- AC1: Cruise 啟動時 TaskCreate 建立所有 phase 的 task ---"

assert_file_exists "$CRUISE_SKILL" "AC1: Cruise SKILL.md 存在"
assert_contains "$CRUISE_SKILL" "TaskCreate" "AC1: Cruise SKILL.md 包含 TaskCreate 指令"
assert_contains "$CRUISE_SKILL" "task_list_id|TASK_LIST_ID" "AC1: Cruise SKILL.md 定義 task_list_id 變數"
assert_contains "$CRUISE_SKILL" "PO.*巡邏|SRE.*巡檢" "AC1: Cruise SKILL.md Task List 包含 PO 巡邏和 SRE 巡檢 phase"

# ---------------------------------------------------------------------------
# AC2: 每個 phase 完成時 TaskUpdate 標記 completed
# ---------------------------------------------------------------------------
echo ""
echo "--- AC2: 每個 phase 完成時 TaskUpdate 標記 completed ---"

assert_contains "$CRUISE_SKILL" "TaskUpdate" "AC2: Cruise SKILL.md 包含 TaskUpdate 指令"
assert_contains "$CRUISE_SKILL" "completed" "AC2: Cruise SKILL.md 包含 completed 狀態標記"

# ---------------------------------------------------------------------------
# AC3: Sprint 執行啟動時建立 Task List（Planning/Execution/Review）
# ---------------------------------------------------------------------------
echo ""
echo "--- AC3: Sprint 執行啟動時建立 Task List ---"

assert_file_exists "$SPRINT_EXEC_SKILL" "AC3: Sprint Execution SKILL.md 存在"
assert_contains "$SPRINT_EXEC_SKILL" "TaskCreate" "AC3: Sprint Execution SKILL.md 包含 TaskCreate 指令"
assert_contains "$SPRINT_EXEC_SKILL" "Sprint.*Plan|Planning" "AC3: Sprint Execution Task List 包含 Planning phase"
assert_contains "$SPRINT_EXEC_SKILL" "Sprint.*Execut|Execution" "AC3: Sprint Execution Task List 包含 Execution phase"
assert_contains "$SPRINT_EXEC_SKILL" "Sprint.*Review|Review" "AC3: Sprint Execution Task List 包含 Review phase"

# ---------------------------------------------------------------------------
# AC4: compact 後透過 TaskList 恢復進度，跳過已完成的 phase
# ---------------------------------------------------------------------------
echo ""
echo "--- AC4: compact 後 TaskList 恢復進度 ---"

assert_contains "$CRUISE_SKILL" "TaskList|task.list|task_list" "AC4: Cruise SKILL.md 包含 TaskList 查詢恢復機制"
assert_contains "$CRUISE_SKILL" "恢復|recover|resume|compact" "AC4: Cruise SKILL.md 包含 compact 恢復說明"
assert_contains "$SPRINT_EXEC_SKILL" "TaskList|task.list|task_list" "AC4: Sprint Execution SKILL.md 包含 TaskList 查詢恢復機制"

# ---------------------------------------------------------------------------
# AC5: 多 session 隔離 — Task List 以 SESSION_ID 命名，互不干擾
# ---------------------------------------------------------------------------
echo ""
echo "--- AC5: 多 session 隔離 ---"

assert_contains "$CRUISE_SKILL" "SESSION_ID|session_id" "AC5: Cruise SKILL.md Task List 包含 SESSION_ID 隔離"
assert_contains "$SPRINT_EXEC_SKILL" "SESSION_ID|session_id" "AC5: Sprint Execution SKILL.md Task List 包含 SESSION_ID 隔離"

# ---------------------------------------------------------------------------
# AC6: 失敗恢復 — phase 失敗時 task 標記 failed
# ---------------------------------------------------------------------------
echo ""
echo "--- AC6: 失敗恢復 ---"

assert_contains "$CRUISE_SKILL" "failed|TaskUpdate.*failed" "AC6: Cruise SKILL.md 包含 failed 狀態標記"
assert_contains "$SPRINT_EXEC_SKILL" "failed|TaskUpdate.*failed" "AC6: Sprint Execution SKILL.md 包含 failed 狀態標記"

# ---------------------------------------------------------------------------
# 彙整結果
# ---------------------------------------------------------------------------
echo ""
echo "========================================="
echo "結果：PASS=${PASS_COUNT}，FAIL=${FAIL_COUNT}"
echo "========================================="

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi
exit 0
