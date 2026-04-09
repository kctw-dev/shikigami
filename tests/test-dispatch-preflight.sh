#!/usr/bin/env bash
# test-dispatch-preflight.sh — dispatch-preflight.sh 派遣前檢查測試 (Story #990)
#
# TDD 測試流程：
# TC1: low-ratio fixture → exit != 0 (BLOCK)
# TC2: warn-ratio fixture → exit == 0 but WARN in log
# TC3: normal prompt → exit == 0 and ratio >= 0.10 (PASS)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREFLIGHT_SCRIPT="${SCRIPT_DIR}/scripts/state-machine/dispatch-preflight.sh"
FIXTURES_DIR="${SCRIPT_DIR}/tests/fixtures"

PASS=0
FAIL=0
TOTAL=0
TMP_DIR=""

# ── 測試工具函數 ──

setup() {
  TMP_DIR=$(mktemp -d)
}

teardown() {
  if [[ -n "${TMP_DIR}" && -d "${TMP_DIR}" ]]; then
    rm -rf "${TMP_DIR}"
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

assert_file_contains() {
  local desc="$1" file="$2" pattern="$3"
  TOTAL=$((TOTAL + 1))
  if grep -q "${pattern}" "${file}" 2>/dev/null; then
    echo "  PASS: ${desc}"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: ${desc} (pattern '${pattern}' not found in ${file})"
    FAIL=$((FAIL + 1))
  fi
}

assert_json_field() {
  local desc="$1" file="$2" field="$3" expected="$4"
  TOTAL=$((TOTAL + 1))
  local actual
  # Read the entire file (it's a single JSON object even if pretty-printed)
  actual=$(cat "${file}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d${field})" 2>/dev/null || echo "PARSE_ERROR")
  if [[ "${expected}" == "${actual}" ]]; then
    echo "  PASS: ${desc}"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: ${desc} (expected='${expected}', actual='${actual}')"
    FAIL=$((FAIL + 1))
  fi
}

# ── Test 1: 腳本存在且可執行 ──

test_script_exists() {
  echo "Test 1: dispatch-preflight.sh 存在且可執行"

  TOTAL=$((TOTAL + 1))
  if [[ -f "${PREFLIGHT_SCRIPT}" ]]; then
    echo "  PASS: dispatch-preflight.sh exists"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: dispatch-preflight.sh not found at ${PREFLIGHT_SCRIPT}"
    FAIL=$((FAIL + 1))
  fi

  TOTAL=$((TOTAL + 1))
  if [[ -x "${PREFLIGHT_SCRIPT}" ]]; then
    echo "  PASS: dispatch-preflight.sh is executable"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: dispatch-preflight.sh is not executable"
    FAIL=$((FAIL + 1))
  fi
}

# ── Test 2: fixtures 存在 ──

test_fixtures_exist() {
  echo "Test 2: 測試 fixtures 存在"

  for fixture in "low-ratio-prompt.txt" "warn-ratio-prompt.txt"; do
    TOTAL=$((TOTAL + 1))
    if [[ -f "${FIXTURES_DIR}/${fixture}" ]]; then
      echo "  PASS: ${fixture} exists"
      PASS=$((PASS + 1))
    else
      echo "  FAIL: ${fixture} not found at ${FIXTURES_DIR}/${fixture}"
      FAIL=$((FAIL + 1))
    fi
  done
}

# ── Test 3: 無參數應顯示 usage 並以 1 退出 ──

test_no_args_shows_usage() {
  echo "Test 3: 無參數應顯示 usage 並以 1 退出"
  assert_exit_code "no args exits with 1" 1 bash "${PREFLIGHT_SCRIPT}"
}

# ── Test 4: 缺少必要引數應退出 1 ──

test_missing_required_args() {
  echo "Test 4: 缺少必要引數應退出 1"
  setup

  assert_exit_code "missing --story-id exits with 1" 1 \
    bash "${PREFLIGHT_SCRIPT}" --prompt "${TMP_DIR}/test.md"

  assert_exit_code "missing --prompt exits with 1" 1 \
    bash "${PREFLIGHT_SCRIPT}" --story-id "#990"

  teardown
}

# ── Test 5: TC1 - low-ratio fixture → exit != 0 (BLOCK) ──

test_low_ratio_blocks() {
  echo "Test 5: TC1 - low-ratio fixture 應拒絕派遣 (exit != 0, BLOCK)"
  setup

  local log_file="${TMP_DIR}/dispatch-rule-ratio.jsonl"

  # 應該以 exit 1 失敗
  assert_exit_code "low-ratio fixture blocks dispatch" 1 \
    bash "${PREFLIGHT_SCRIPT}" \
      --prompt "${FIXTURES_DIR}/low-ratio-prompt.txt" \
      --story-id "#990" \
      --output-log "${log_file}"

  # 驗證 log 記錄中 threshold 為 BLOCK
  if [[ -f "${log_file}" ]]; then
    assert_json_field "log threshold is BLOCK" "${log_file}" "['threshold']" "BLOCK"
    assert_json_field "log action is block" "${log_file}" "['action']" "block"
  fi

  teardown
}

# ── Test 6: TC2 - warn-ratio fixture → exit == 0 but WARN ──

test_warn_ratio_continues() {
  echo "Test 6: TC2 - warn-ratio fixture 應發出告警但繼續派遣 (exit == 0, WARN)"
  setup

  local log_file="${TMP_DIR}/dispatch-rule-ratio.jsonl"

  # 應該以 exit 0 成功
  assert_exit_code "warn-ratio fixture continues with exit 0" 0 \
    bash "${PREFLIGHT_SCRIPT}" \
      --prompt "${FIXTURES_DIR}/warn-ratio-prompt.txt" \
      --story-id "#990" \
      --output-log "${log_file}"

  # 驗證 log 記錄中 threshold 為 WARN
  if [[ -f "${log_file}" ]]; then
    assert_json_field "log threshold is WARN" "${log_file}" "['threshold']" "WARN"
    assert_json_field "log action is continue" "${log_file}" "['action']" "continue"
  fi

  teardown
}

# ── Test 7: TC3 - normal prompt → exit == 0 and ratio >= 0.10 (PASS) ──

test_normal_prompt_passes() {
  echo "Test 7: TC3 - 正常 prompt (ratio >= 0.10) 應通過 (exit == 0, PASS)"
  setup

  # 建立規則佔比 >= 10% 的 prompt
  cat > "${TMP_DIR}/test-normal.md" <<'PROMPT_EOF'
## 規則片段

你是 Sprint Execution 的 task-list-init 步驟 subagent。你的唯一任務是初始化 Sprint 的 Task List。

必須遵守的規則：
1. Task List 必須包含 Sprint 中所有 Story 的標題、Issue 編號、Size、Routing
2. 排序依據：依賴關係優先、RICE 分數次之
3. 每個 Story 必須有明確的驗收標準引用
4. 禁止自行增減 Story，Task List 內容必須與 Sprint Planning 結果一致

禁止事項：不可開始執行任何 Story，不可修改 Size 或 Routing，不可跳過此步驟。

## 輸入契約

Sprint 編號：180
Planning file: docs/sprints/sprint-180/planning.md
Backlog: docs/sprints/backlog.md

## 輸出契約

產出 task-list.md 和結果 JSON。

## 成功/失敗判定

成功條件：task-list.md 存在。
PROMPT_EOF

  local log_file="${TMP_DIR}/dispatch-rule-ratio.jsonl"

  # 應該以 exit 0 成功
  assert_exit_code "normal prompt passes with exit 0" 0 \
    bash "${PREFLIGHT_SCRIPT}" \
      --prompt "${TMP_DIR}/test-normal.md" \
      --story-id "#990" \
      --output-log "${log_file}"

  # 驗證 log 記錄中 threshold 為 PASS
  if [[ -f "${log_file}" ]]; then
    assert_json_field "log threshold is PASS" "${log_file}" "['threshold']" "PASS"
    assert_json_field "log action is continue" "${log_file}" "['action']" "continue"
  fi

  teardown
}

# ── Test 8: 預設 log 路徑 ──

test_default_log_path() {
  echo "Test 8: 預設 log 路徑應為 docs/cruise-logs/dispatch-rule-ratio-<date>.jsonl"
  setup

  local today
  today=$(date +%Y-%m-%d)
  local default_log="${SCRIPT_DIR}/docs/cruise-logs/dispatch-rule-ratio-${today}.jsonl"

  # 移除預設 log（如果存在）以便測試
  if [[ -f "${default_log}" ]]; then
    mv "${default_log}" "${default_log}.bak"
  fi

  # 執行 preflight 而不指定 --output-log
  bash "${PREFLIGHT_SCRIPT}" \
    --prompt "${FIXTURES_DIR}/warn-ratio-prompt.txt" \
    --story-id "#990" \
    >/dev/null 2>&1 || true

  TOTAL=$((TOTAL + 1))
  if [[ -f "${default_log}" ]]; then
    echo "  PASS: default log created at ${default_log}"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: default log not created"
    FAIL=$((FAIL + 1))
  fi

  # 恢復備份
  if [[ -f "${default_log}.bak" ]]; then
    mv "${default_log}.bak" "${default_log}"
  fi

  teardown
}

# ── Test 9: log entry 格式驗證 ──

test_log_entry_format() {
  echo "Test 9: log entry 應為有效 JSONL 格式，含所有必要欄位"
  setup

  local log_file="${TMP_DIR}/dispatch-rule-ratio.jsonl"

  bash "${PREFLIGHT_SCRIPT}" \
    --prompt "${FIXTURES_DIR}/warn-ratio-prompt.txt" \
    --story-id "#990" \
    --output-log "${log_file}" \
    >/dev/null 2>&1 || true

  TOTAL=$((TOTAL + 1))
  if [[ -f "${log_file}" ]]; then
    echo "  PASS: log file created"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: log file not created"
    FAIL=$((FAIL + 1))
    teardown
    return
  fi

  # 驗證 JSON 格式（應是有效 JSON，即使多行）
  local required_fields=("timestamp" "story_id" "prompt_size_chars" "rule_tokens" "total_tokens" "ratio" "threshold" "action")
  for field in "${required_fields[@]}"; do
    TOTAL=$((TOTAL + 1))
    if cat "${log_file}" | python3 -c "import sys,json; d=json.load(sys.stdin); assert '${field}' in d" 2>/dev/null; then
      echo "  PASS: log has field '${field}'"
      PASS=$((PASS + 1))
    else
      echo "  FAIL: log missing field '${field}'"
      FAIL=$((FAIL + 1))
    fi
  done

  teardown
}

# ── Test 10: fail-safe — rule-ratio-measure.sh 缺失 ──

test_fail_safe_missing_measure_script() {
  echo "Test 10: Fail-safe — rule-ratio-measure.sh 缺失應拒絕派遣"
  setup

  # 臨時禁用 rule-ratio-measure.sh（備份它）
  local measure_script="${SCRIPT_DIR}/scripts/state-machine/rule-ratio-measure.sh"
  if [[ -f "${measure_script}" ]]; then
    mv "${measure_script}" "${measure_script}.bak"
  fi

  local log_file="${TMP_DIR}/dispatch-rule-ratio.jsonl"

  # 應該以 exit 1 失敗
  assert_exit_code "missing measure script blocks dispatch" 1 \
    bash "${PREFLIGHT_SCRIPT}" \
      --prompt "${FIXTURES_DIR}/warn-ratio-prompt.txt" \
      --story-id "#990" \
      --output-log "${log_file}"

  # 恢復
  if [[ -f "${measure_script}.bak" ]]; then
    mv "${measure_script}.bak" "${measure_script}"
  fi

  teardown
}

# ── 執行所有測試 ──

echo "=== Dispatch Preflight Tests (Story #990) ==="
echo ""

test_script_exists
echo ""
test_fixtures_exist
echo ""
test_no_args_shows_usage
echo ""
test_missing_required_args
echo ""
test_low_ratio_blocks
echo ""
test_warn_ratio_continues
echo ""
test_normal_prompt_passes
echo ""
test_default_log_path
echo ""
test_log_entry_format
echo ""
test_fail_safe_missing_measure_script
echo ""

echo "=== Results: ${PASS}/${TOTAL} passed, ${FAIL} failed ==="

if [[ ${FAIL} -gt 0 ]]; then
  exit 1
fi
