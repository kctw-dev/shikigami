#!/usr/bin/env bash
# test-state-machine.sh — 外部狀態機 PoC 測試（Story #962 AC3）
# 驗證 gate 條件：步驟產出物不存在時不放行下一步
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SM_DIR="${SCRIPT_DIR}/scripts/state-machine"
STATE_DIR=""
PASS=0
FAIL=0
TOTAL=0

# ── 測試工具函數 ──

setup() {
  STATE_DIR=$(mktemp -d)
  export STATE_MACHINE_DIR="${STATE_DIR}"
}

teardown() {
  if [[ -n "${STATE_DIR}" && -d "${STATE_DIR}" ]]; then
    rm -rf "${STATE_DIR}"
  fi
}

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  TOTAL=$((TOTAL + 1))
  if [[ "${expected}" == "${actual}" ]]; then
    echo "  PASS: ${desc}"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: ${desc} (expected='${expected}', actual='${actual}')"
    FAIL=$((FAIL + 1))
  fi
}

assert_exit_code() {
  local desc="$1" expected="$2"
  shift 2
  local actual=0
  "$@" >/dev/null 2>&1 || actual=$?
  TOTAL=$((TOTAL + 1))
  if [[ "${expected}" == "${actual}" ]]; then
    echo "  PASS: ${desc}"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: ${desc} (expected exit=${expected}, actual exit=${actual})"
    FAIL=$((FAIL + 1))
  fi
}

assert_file_exists() {
  local desc="$1" filepath="$2"
  TOTAL=$((TOTAL + 1))
  if [[ -f "${filepath}" ]]; then
    echo "  PASS: ${desc}"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: ${desc} (file not found: ${filepath})"
    FAIL=$((FAIL + 1))
  fi
}

assert_log_contains() {
  local desc="$1" pattern="$2" logfile="$3"
  TOTAL=$((TOTAL + 1))
  if grep -q "${pattern}" "${logfile}" 2>/dev/null; then
    echo "  PASS: ${desc}"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: ${desc} (pattern '${pattern}' not found in log)"
    FAIL=$((FAIL + 1))
  fi
}

# ── Test 1: init 建立初始狀態檔 ──

test_init_creates_state_file() {
  echo "Test 1: init 建立初始狀態檔"
  setup

  bash "${SM_DIR}/state-machine.sh" init 177
  assert_file_exists "state file created" "${STATE_DIR}/sprint-execution-state.json"

  local status
  status=$(jq -r '.steps["task-list-init"].status' "${STATE_DIR}/sprint-execution-state.json")
  assert_eq "task-list-init is pending" "pending" "${status}"

  status=$(jq -r '.steps["checkpoint-detection"].status' "${STATE_DIR}/sprint-execution-state.json")
  assert_eq "checkpoint-detection is pending" "pending" "${status}"

  status=$(jq -r '.steps["issue-ci-scan"].status' "${STATE_DIR}/sprint-execution-state.json")
  assert_eq "issue-ci-scan is pending" "pending" "${status}"

  local sprint_num
  sprint_num=$(jq -r '.sprint_number' "${STATE_DIR}/sprint-execution-state.json")
  assert_eq "sprint_number is 177" "177" "${sprint_num}"

  teardown
}

# ── Test 2: gate 阻擋 — 前置步驟未完成時不放行 ──

test_gate_blocks_when_predecessor_incomplete() {
  echo "Test 2: gate 阻擋 — 前置步驟未完成時不放行"
  setup

  bash "${SM_DIR}/state-machine.sh" init 177

  # checkpoint-detection 的 gate 應該被阻擋（task-list-init 未完成）
  assert_exit_code "gate blocks checkpoint-detection when task-list-init pending" 1 \
    bash "${SM_DIR}/state-machine.sh" gate checkpoint-detection

  # issue-ci-scan 的 gate 應該被阻擋（checkpoint-detection 未完成）
  assert_exit_code "gate blocks issue-ci-scan when checkpoint-detection pending" 1 \
    bash "${SM_DIR}/state-machine.sh" gate issue-ci-scan

  teardown
}

# ── Test 3: gate 放行 — 前置步驟完成後允許通過 ──

test_gate_passes_when_predecessor_complete() {
  echo "Test 3: gate 放行 — 前置步驟完成後允許通過"
  setup

  bash "${SM_DIR}/state-machine.sh" init 177

  # 第一步 gate 無前置依賴，應該直接通過
  assert_exit_code "gate passes task-list-init (no predecessor)" 0 \
    bash "${SM_DIR}/state-machine.sh" gate task-list-init

  # 完成第一步
  bash "${SM_DIR}/state-machine.sh" complete task-list-init

  # 第二步 gate 應該通過
  assert_exit_code "gate passes checkpoint-detection after task-list-init completed" 0 \
    bash "${SM_DIR}/state-machine.sh" gate checkpoint-detection

  # 完成第二步
  bash "${SM_DIR}/state-machine.sh" complete checkpoint-detection

  # 第三步 gate 應該通過
  assert_exit_code "gate passes issue-ci-scan after checkpoint-detection completed" 0 \
    bash "${SM_DIR}/state-machine.sh" gate issue-ci-scan

  teardown
}

# ── Test 4: complete 更新狀態與時間戳 ──

test_complete_updates_status() {
  echo "Test 4: complete 更新狀態與時間戳"
  setup

  bash "${SM_DIR}/state-machine.sh" init 177
  bash "${SM_DIR}/state-machine.sh" complete task-list-init

  local status completed_at exit_code
  status=$(jq -r '.steps["task-list-init"].status' "${STATE_DIR}/sprint-execution-state.json")
  assert_eq "status is completed" "completed" "${status}"

  completed_at=$(jq -r '.steps["task-list-init"].completed_at' "${STATE_DIR}/sprint-execution-state.json")
  assert_eq "completed_at is not null" "false" "$([ "${completed_at}" == "null" ] && echo true || echo false)"

  exit_code=$(jq -r '.steps["task-list-init"].exit_code' "${STATE_DIR}/sprint-execution-state.json")
  assert_eq "exit_code is 0" "0" "${exit_code}"

  teardown
}

# ── Test 5: fail 記錄失敗狀態 ──

test_fail_records_failure() {
  echo "Test 5: fail 記錄失敗狀態"
  setup

  bash "${SM_DIR}/state-machine.sh" init 177
  bash "${SM_DIR}/state-machine.sh" fail task-list-init "task creation timeout"

  local status reason exit_code
  status=$(jq -r '.steps["task-list-init"].status' "${STATE_DIR}/sprint-execution-state.json")
  assert_eq "status is failed" "failed" "${status}"

  reason=$(jq -r '.steps["task-list-init"].failure_reason' "${STATE_DIR}/sprint-execution-state.json")
  assert_eq "failure_reason recorded" "task creation timeout" "${reason}"

  exit_code=$(jq -r '.steps["task-list-init"].exit_code' "${STATE_DIR}/sprint-execution-state.json")
  assert_eq "exit_code is 1" "1" "${exit_code}"

  teardown
}

# ── Test 6: 可觀測 log（NFR2）──

test_observable_log() {
  echo "Test 6: 可觀測 log（NFR2 — step_name、exit_code、失敗原因）"
  setup

  bash "${SM_DIR}/state-machine.sh" init 177
  bash "${SM_DIR}/state-machine.sh" complete task-list-init

  local logfile="${STATE_DIR}/state-machine.log"
  assert_file_exists "log file exists" "${logfile}"
  assert_log_contains "log contains step_name" "task-list-init" "${logfile}"
  assert_log_contains "log contains exit_code" "exit_code" "${logfile}"

  # 測試失敗 log
  bash "${SM_DIR}/state-machine.sh" fail checkpoint-detection "gh timeout"
  assert_log_contains "failure log contains reason" "gh timeout" "${logfile}"

  teardown
}

# ── Test 7: 冪等重入（NFR4）— 重新執行時跳過已完成步驟 ──

test_idempotent_reentry() {
  echo "Test 7: 冪等重入（NFR4）— 重新執行時跳過已完成步驟"
  setup

  bash "${SM_DIR}/state-machine.sh" init 177
  bash "${SM_DIR}/state-machine.sh" complete task-list-init

  # 再次 init 不應覆蓋已完成的步驟
  bash "${SM_DIR}/state-machine.sh" init 177

  local status
  status=$(jq -r '.steps["task-list-init"].status' "${STATE_DIR}/sprint-execution-state.json")
  assert_eq "completed step preserved after re-init" "completed" "${status}"

  # 再次 complete 已完成的步驟應該是 no-op（冪等）
  local ts_before ts_after
  ts_before=$(jq -r '.steps["task-list-init"].completed_at' "${STATE_DIR}/sprint-execution-state.json")
  bash "${SM_DIR}/state-machine.sh" complete task-list-init
  ts_after=$(jq -r '.steps["task-list-init"].completed_at' "${STATE_DIR}/sprint-execution-state.json")
  assert_eq "completed_at unchanged on re-complete" "${ts_before}" "${ts_after}"

  teardown
}

# ── Test 8: 執行時間 < 1s（NFR3）──

test_execution_time() {
  echo "Test 8: 執行時間 < 1s（NFR3）"
  setup

  local start end elapsed
  start=$(date +%s%N)
  bash "${SM_DIR}/state-machine.sh" init 177
  bash "${SM_DIR}/state-machine.sh" gate task-list-init
  bash "${SM_DIR}/state-machine.sh" complete task-list-init
  bash "${SM_DIR}/state-machine.sh" gate checkpoint-detection
  bash "${SM_DIR}/state-machine.sh" complete checkpoint-detection
  bash "${SM_DIR}/state-machine.sh" gate issue-ci-scan
  bash "${SM_DIR}/state-machine.sh" complete issue-ci-scan
  end=$(date +%s%N)

  elapsed=$(( (end - start) / 1000000 ))  # ms
  TOTAL=$((TOTAL + 1))
  if [[ ${elapsed} -lt 1000 ]]; then
    echo "  PASS: full flow completed in ${elapsed}ms (< 1000ms)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: full flow took ${elapsed}ms (> 1000ms)"
    FAIL=$((FAIL + 1))
  fi

  teardown
}

# ── Test 9: status 命令輸出 ──

test_status_output() {
  echo "Test 9: status 命令輸出"
  setup

  bash "${SM_DIR}/state-machine.sh" init 177
  bash "${SM_DIR}/state-machine.sh" complete task-list-init

  local output
  output=$(bash "${SM_DIR}/state-machine.sh" status)
  TOTAL=$((TOTAL + 1))
  if echo "${output}" | grep -q "task-list-init" && echo "${output}" | grep -q "completed"; then
    echo "  PASS: status output contains step info"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: status output missing expected content"
    FAIL=$((FAIL + 1))
  fi

  teardown
}

# ── Test 10: 未知步驟名應報錯 ──

test_unknown_step_errors() {
  echo "Test 10: 未知步驟名應報錯"
  setup

  bash "${SM_DIR}/state-machine.sh" init 177
  assert_exit_code "gate rejects unknown step" 1 \
    bash "${SM_DIR}/state-machine.sh" gate nonexistent-step
  assert_exit_code "complete rejects unknown step" 1 \
    bash "${SM_DIR}/state-machine.sh" complete nonexistent-step

  teardown
}

# ── 執行所有測試 ──

echo "=== State Machine PoC Tests (Story #962) ==="
echo ""

test_init_creates_state_file
echo ""
test_gate_blocks_when_predecessor_incomplete
echo ""
test_gate_passes_when_predecessor_complete
echo ""
test_complete_updates_status
echo ""
test_fail_records_failure
echo ""
test_observable_log
echo ""
test_idempotent_reentry
echo ""
test_execution_time
echo ""
test_status_output
echo ""
test_unknown_step_errors
echo ""

echo "=== Results: ${PASS}/${TOTAL} passed, ${FAIL} failed ==="

if [[ ${FAIL} -gt 0 ]]; then
  exit 1
fi
