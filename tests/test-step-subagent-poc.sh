#!/usr/bin/env bash
# test-step-subagent-poc.sh — Step Subagent PoC 測試（Story #977 AC-4）
# 驗證 short-lived subagent 派遣 PoC：prompt 生成、模擬執行、結果 JSON 契約
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POC_DIR="${SCRIPT_DIR}/scripts/state-machine"
STATE_DIR=""
PASS=0
FAIL=0
TOTAL=0

# ── 測試工具函數 ──

setup() {
  STATE_DIR=$(mktemp -d)
  export STATE_MACHINE_DIR="${STATE_DIR}"
  export POC_OUTPUT_DIR="${STATE_DIR}/poc-output"
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

assert_file_contains() {
  local desc="$1" pattern="$2" filepath="$3"
  TOTAL=$((TOTAL + 1))
  if grep -q "${pattern}" "${filepath}" 2>/dev/null; then
    echo "  PASS: ${desc}"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: ${desc} (pattern '${pattern}' not found in ${filepath})"
    FAIL=$((FAIL + 1))
  fi
}

assert_json_field() {
  local desc="$1" filepath="$2" field="$3" expected="$4"
  local actual
  actual=$(jq -r "${field}" "${filepath}" 2>/dev/null || echo "JQ_ERROR")
  TOTAL=$((TOTAL + 1))
  if [[ "${expected}" == "${actual}" ]]; then
    echo "  PASS: ${desc}"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: ${desc} (expected='${expected}', actual='${actual}')"
    FAIL=$((FAIL + 1))
  fi
}

# ── Test 1: generate-prompt 產出 prompt 模板 ──

test_generate_prompt() {
  echo "Test 1: generate-prompt 產出 prompt 模板"
  setup

  bash "${POC_DIR}/step-subagent-poc.sh" generate-prompt task-list-init 179

  local prompt_file="${STATE_DIR}/poc-output/prompt-task-list-init.md"
  assert_file_exists "prompt file created" "${prompt_file}"
  assert_file_contains "prompt contains step name" "task-list-init" "${prompt_file}"
  assert_file_contains "prompt contains sprint number" "179" "${prompt_file}"
  assert_file_contains "prompt contains rules section" "規則片段" "${prompt_file}"
  assert_file_contains "prompt contains input contract" "輸入契約" "${prompt_file}"
  assert_file_contains "prompt contains output contract" "輸出契約" "${prompt_file}"
  assert_file_contains "prompt contains success criteria" "成功/失敗判定" "${prompt_file}"

  teardown
}

# ── Test 2: generate-prompt 未知步驟應報錯 ──

test_generate_prompt_unknown_step() {
  echo "Test 2: generate-prompt 未知步驟應報錯"
  setup

  assert_exit_code "generate-prompt rejects unknown step" 1 \
    bash "${POC_DIR}/step-subagent-poc.sh" generate-prompt nonexistent-step 179

  teardown
}

# ── Test 3: simulate 產出結果 JSON ──

test_simulate_produces_result() {
  echo "Test 3: simulate 產出結果 JSON"
  setup

  bash "${POC_DIR}/step-subagent-poc.sh" simulate task-list-init 179

  local result_file="${STATE_DIR}/poc-output/result-task-list-init.json"
  assert_file_exists "result JSON created" "${result_file}"

  # 驗證 JSON 契約欄位
  assert_json_field "step_name is task-list-init" "${result_file}" '.step_name' "task-list-init"
  assert_json_field "status is completed" "${result_file}" '.status' "completed"
  assert_json_field "error is null" "${result_file}" '.error' "null"

  # 驗證 output_artifacts 非空
  local artifacts_count
  artifacts_count=$(jq '.output_artifacts | length' "${result_file}")
  TOTAL=$((TOTAL + 1))
  if [[ "${artifacts_count}" -gt 0 ]]; then
    echo "  PASS: output_artifacts has ${artifacts_count} item(s)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: output_artifacts is empty"
    FAIL=$((FAIL + 1))
  fi

  # 驗證 duration_ms 為正數
  local duration
  duration=$(jq '.duration_ms' "${result_file}")
  TOTAL=$((TOTAL + 1))
  if [[ "${duration}" -ge 0 ]]; then
    echo "  PASS: duration_ms is ${duration} (non-negative)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: duration_ms is negative: ${duration}"
    FAIL=$((FAIL + 1))
  fi

  teardown
}

# ── Test 4: simulate 產出的 artifacts 檔案存在 ──

test_simulate_artifacts_exist() {
  echo "Test 4: simulate 產出的 artifacts 檔案存在"
  setup

  bash "${POC_DIR}/step-subagent-poc.sh" simulate task-list-init 179

  local result_file="${STATE_DIR}/poc-output/result-task-list-init.json"
  while IFS= read -r artifact; do
    assert_file_exists "artifact exists: ${artifact}" "${artifact}"
  done < <(jq -r '.output_artifacts[]' "${result_file}")

  teardown
}

# ── Test 5: demo 完整流程（含 progress tracker 整合）──

test_demo_full_flow() {
  echo "Test 5: demo 完整流程（含 progress tracker 整合）"
  setup

  bash "${POC_DIR}/step-subagent-poc.sh" demo 179 >/dev/null

  # 驗證 progress tracker 已更新
  local state_file="${STATE_DIR}/sprint-execution-state.json"
  assert_file_exists "state file exists after demo" "${state_file}"
  assert_json_field "task-list-init is completed in tracker" "${state_file}" '.steps["task-list-init"].status' "completed"

  # 驗證 prompt 和 result 都產出
  assert_file_exists "prompt file produced" "${STATE_DIR}/poc-output/prompt-task-list-init.md"
  assert_file_exists "result file produced" "${STATE_DIR}/poc-output/result-task-list-init.json"

  teardown
}

# ── Test 6: 結果 JSON 契約完整性 ──

test_result_json_contract() {
  echo "Test 6: 結果 JSON 契約完整性（所有必要欄位存在）"
  setup

  bash "${POC_DIR}/step-subagent-poc.sh" simulate task-list-init 179

  local result_file="${STATE_DIR}/poc-output/result-task-list-init.json"
  local required_fields=("step_name" "status" "output_artifacts" "duration_ms" "error")

  for field in "${required_fields[@]}"; do
    local has_field
    has_field=$(jq "has(\"${field}\")" "${result_file}")
    TOTAL=$((TOTAL + 1))
    if [[ "${has_field}" == "true" ]]; then
      echo "  PASS: result JSON has field '${field}'"
      PASS=$((PASS + 1))
    else
      echo "  FAIL: result JSON missing field '${field}'"
      FAIL=$((FAIL + 1))
    fi
  done

  teardown
}

# ── 執行所有測試 ──

echo "=== Step Subagent PoC Tests (Story #977 AC-4) ==="
echo ""

test_generate_prompt
echo ""
test_generate_prompt_unknown_step
echo ""
test_simulate_produces_result
echo ""
test_simulate_artifacts_exist
echo ""
test_demo_full_flow
echo ""
test_result_json_contract
echo ""

echo "=== Results: ${PASS}/${TOTAL} passed, ${FAIL} failed ==="

if [[ ${FAIL} -gt 0 ]]; then
  exit 1
fi
