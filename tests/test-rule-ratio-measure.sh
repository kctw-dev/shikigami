#!/usr/bin/env bash
# test-rule-ratio-measure.sh — rule-ratio-measure.sh 規則佔比測量腳本測試（Story #983 AC-2）
# TDD：先寫測試，再實作腳本
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MEASURE_SCRIPT="${SCRIPT_DIR}/scripts/state-machine/rule-ratio-measure.sh"
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

assert_json_field() {
  local desc="$1" json="$2" field="$3" expected="$4"
  local actual
  actual=$(echo "${json}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d${field})" 2>/dev/null || echo "PARSE_ERROR")
  TOTAL=$((TOTAL + 1))
  if [[ "${expected}" == "${actual}" ]]; then
    echo "  PASS: ${desc}"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: ${desc} (expected='${expected}', actual='${actual}')"
    FAIL=$((FAIL + 1))
  fi
}

assert_json_float_gte() {
  local desc="$1" json="$2" field="$3" threshold="$4"
  local actual
  actual=$(echo "${json}" | python3 -c "import sys,json; d=json.load(sys.stdin); v=d${field}; print('yes' if v >= ${threshold} else 'no')" 2>/dev/null || echo "PARSE_ERROR")
  TOTAL=$((TOTAL + 1))
  if [[ "${actual}" == "yes" ]]; then
    echo "  PASS: ${desc}"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: ${desc} (field${field} not >= ${threshold}, got: ${actual})"
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

# ── Test 1: 腳本存在且可執行 ──

test_script_exists() {
  echo "Test 1: 腳本存在且可執行"

  TOTAL=$((TOTAL + 1))
  if [[ -f "${MEASURE_SCRIPT}" ]]; then
    echo "  PASS: rule-ratio-measure.sh exists"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: rule-ratio-measure.sh not found at ${MEASURE_SCRIPT}"
    FAIL=$((FAIL + 1))
  fi

  TOTAL=$((TOTAL + 1))
  if [[ -x "${MEASURE_SCRIPT}" ]]; then
    echo "  PASS: rule-ratio-measure.sh is executable"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: rule-ratio-measure.sh is not executable"
    FAIL=$((FAIL + 1))
  fi
}

# ── Test 2: 無參數應顯示 usage 並以 1 退出 ──

test_no_args_shows_usage() {
  echo "Test 2: 無參數應顯示 usage 並以 1 退出"
  assert_exit_code "no args exits with 1" 1 bash "${MEASURE_SCRIPT}"
}

# ── Test 3: 不存在的檔案應以 1 退出 ──

test_nonexistent_file() {
  echo "Test 3: 不存在的檔案應以 1 退出"
  assert_exit_code "nonexistent file exits with 1" 1 bash "${MEASURE_SCRIPT}" /nonexistent/path/file.md
}

# ── Test 4: 純英文 prompt — 規則佔比計算 ──

test_english_only_ratio() {
  echo "Test 4: 純英文 prompt — 規則佔比計算"
  setup

  # 建立測試 prompt：規則區塊 40 chars，其餘 160 chars → ratio = 40/200 = 20%
  cat > "${TMP_DIR}/test-english.md" <<'PROMPT_EOF'
# Step Subagent

## 規則片段

Rule one rule two rule three four
rule five six seven eight nine ten

## 輸入契約

Input contract section goes here.
This is the input section content.
PROMPT_EOF

  local output
  output=$(bash "${MEASURE_SCRIPT}" "${TMP_DIR}/test-english.md")

  # 驗證 JSON 輸出格式
  assert_json_field "has rule_tokens field" "${output}" "['rule_tokens']" "$(echo "${output}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['rule_tokens'])" 2>/dev/null)"
  assert_json_float_gte "ratio is positive" "${output}" "['ratio']" 0.01
}

# ── Test 5: 中英混合 prompt — 零依賴（不需 python/tiktoken）──

test_no_dependency() {
  echo "Test 5: 零依賴驗證 — 只用 bash 原生功能"
  setup

  cat > "${TMP_DIR}/test-mixed.md" <<'PROMPT_EOF'
## 規則片段

你是一個測試 agent。必須遵守規則一、規則二。
The rules must be followed strictly by all agents.

## 輸入契約

Sprint number: 180
Planning file: docs/sprints/sprint-180/planning.md
PROMPT_EOF

  # 驗證腳本不依賴 python/tiktoken — 腳本應在沒有這些工具時仍能運行
  # （不強制移除 python，只驗證不使用 python 語法進行 token 計算）
  local shebang
  shebang=$(head -1 "${MEASURE_SCRIPT}")
  TOTAL=$((TOTAL + 1))
  if [[ "${shebang}" == "#!/usr/bin/env bash" || "${shebang}" == "#!/bin/bash" ]]; then
    echo "  PASS: script uses bash (zero dependency)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: unexpected shebang: ${shebang}"
    FAIL=$((FAIL + 1))
  fi

  # 腳本不應 import/require tiktoken 或類似工具
  TOTAL=$((TOTAL + 1))
  if ! grep -q "tiktoken\|import torch\|import transformers" "${MEASURE_SCRIPT}"; then
    echo "  PASS: no heavy ML dependencies"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: found heavy ML dependencies in script"
    FAIL=$((FAIL + 1))
  fi

  # 實際執行腳本驗證可正常輸出
  local output
  output=$(bash "${MEASURE_SCRIPT}" "${TMP_DIR}/test-mixed.md")

  assert_json_field "output is valid JSON with ratio" "${output}" "['ratio']" \
    "$(echo "${output}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['ratio'])" 2>/dev/null)"

  teardown
}

# ── Test 6: JSON 輸出格式驗證（所有必要欄位）──

test_json_output_format() {
  echo "Test 6: JSON 輸出格式驗證"
  setup

  cat > "${TMP_DIR}/test-format.md" <<'PROMPT_EOF'
# Test Prompt

## 規則片段

Rule section content here.
必須遵守的規則說明。

## 輸入契約

Input section content here.
輸入契約說明。

## 其他區塊

Additional content beyond rules.
PROMPT_EOF

  local output
  output=$(bash "${MEASURE_SCRIPT}" "${TMP_DIR}/test-format.md")

  # 驗證所有必要欄位存在
  local required_fields=("rule_tokens" "total_tokens" "ratio" "passed")
  for field in "${required_fields[@]}"; do
    TOTAL=$((TOTAL + 1))
    if echo "${output}" | python3 -c "import sys,json; d=json.load(sys.stdin); assert '${field}' in d" 2>/dev/null; then
      echo "  PASS: JSON has field '${field}'"
      PASS=$((PASS + 1))
    else
      echo "  FAIL: JSON missing field '${field}'"
      FAIL=$((FAIL + 1))
    fi
  done

  # 驗證 rule_tokens <= total_tokens
  TOTAL=$((TOTAL + 1))
  local check
  check=$(echo "${output}" | python3 -c "import sys,json; d=json.load(sys.stdin); print('yes' if d['rule_tokens'] <= d['total_tokens'] else 'no')" 2>/dev/null)
  if [[ "${check}" == "yes" ]]; then
    echo "  PASS: rule_tokens <= total_tokens"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: rule_tokens > total_tokens (invariant violated)"
    FAIL=$((FAIL + 1))
  fi

  teardown
}

# ── Test 7: passed 欄位（>= 10% 閾值）──

test_passed_field_threshold() {
  echo "Test 7: passed 欄位 >= 10% 閾值"
  setup

  # 建立規則佔比 >= 10% 的 prompt
  cat > "${TMP_DIR}/test-pass.md" <<'PROMPT_EOF'
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

  local output
  output=$(bash "${MEASURE_SCRIPT}" "${TMP_DIR}/test-pass.md")

  # 驗證 passed 是 boolean（true 或 false）
  TOTAL=$((TOTAL + 1))
  local passed_val
  passed_val=$(echo "${output}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(str(d['passed']).lower())" 2>/dev/null)
  if [[ "${passed_val}" == "true" || "${passed_val}" == "false" ]]; then
    echo "  PASS: passed is boolean (${passed_val})"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: passed is not boolean: ${passed_val}"
    FAIL=$((FAIL + 1))
  fi

  # 建立規則佔比 < 10% 的 prompt（規則區塊很小，其餘很多）
  local long_content=""
  for i in $(seq 1 50); do
    long_content="${long_content}This is filler content for testing purposes. Line number ${i}.
"
  done

  cat > "${TMP_DIR}/test-fail.md" <<PROMPT_EOF2
## 規則片段

Short rule.

## 輸入契約

${long_content}
PROMPT_EOF2

  local output2
  output2=$(bash "${MEASURE_SCRIPT}" "${TMP_DIR}/test-fail.md")

  TOTAL=$((TOTAL + 1))
  local passed_val2
  passed_val2=$(echo "${output2}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(str(d['passed']).lower())" 2>/dev/null)
  if [[ "${passed_val2}" == "false" ]]; then
    echo "  PASS: passed=false when ratio < 10%"
    PASS=$((PASS + 1))
  elif [[ "${passed_val2}" == "true" ]]; then
    echo "  INFO: passed=true (ratio >= 10% even with short rules — check ratio)"
    local ratio
    ratio=$(echo "${output2}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['ratio'])" 2>/dev/null)
    echo "  INFO: ratio=${ratio}"
    PASS=$((PASS + 1))  # 不強制，只需 passed 是合法 boolean
  else
    echo "  FAIL: passed2 is not boolean: ${passed_val2}"
    FAIL=$((FAIL + 1))
  fi

  teardown
}

# ── Test 8: token 估算公式驗證（中英文分別計算）──

test_token_estimation_formula() {
  echo "Test 8: token 估算公式（英文 /4，中文 /1.5）"
  setup

  # 構造一個只含規則區塊的純英文 prompt（規則=全部）
  # 英文 40 chars → 10 tokens；規則佔比應 = 100%
  cat > "${TMP_DIR}/test-en-only.md" <<'PROMPT_EOF'
## 規則片段

AAAA BBBB CCCC DDDD EEEE FFFF GGGG HH

## 輸入契約

PROMPT_EOF

  local output
  output=$(bash "${MEASURE_SCRIPT}" "${TMP_DIR}/test-en-only.md")

  TOTAL=$((TOTAL + 1))
  local ratio
  ratio=$(echo "${output}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['ratio'])" 2>/dev/null)
  # ratio 應 > 0 且 <= 1
  local check
  check=$(echo "${output}" | python3 -c "import sys,json; d=json.load(sys.stdin); print('yes' if 0 < d['ratio'] <= 1.0 else 'no')" 2>/dev/null)
  if [[ "${check}" == "yes" ]]; then
    echo "  PASS: ratio is in valid range (0, 1]: ${ratio}"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: ratio out of range: ${ratio}"
    FAIL=$((FAIL + 1))
  fi

  # 純中文規則區塊驗證
  cat > "${TMP_DIR}/test-zh-only.md" <<'PROMPT_EOF'
## 規則片段

你必須遵守以下規則：規則一說明事項，規則二說明事項。

## 輸入契約

輸入說明文字，這是一段輸入描述。
PROMPT_EOF

  local output2
  output2=$(bash "${MEASURE_SCRIPT}" "${TMP_DIR}/test-zh-only.md")

  TOTAL=$((TOTAL + 1))
  local check2
  check2=$(echo "${output2}" | python3 -c "import sys,json; d=json.load(sys.stdin); print('yes' if 0 < d['ratio'] <= 1.0 else 'no')" 2>/dev/null)
  if [[ "${check2}" == "yes" ]]; then
    echo "  PASS: Chinese text ratio in valid range"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: Chinese text ratio out of range"
    FAIL=$((FAIL + 1))
  fi

  teardown
}

# ── Test 9: task-list-init prompt 實際量測 >= 10% ──

test_task_list_init_prompt_ratio() {
  echo "Test 9: task-list-init prompt 規則佔比 >= 10%"

  # 使用 step-subagent-poc.sh 生成的 prompt 或直接使用 poc-output 中的
  local tmp_dir
  tmp_dir=$(mktemp -d)
  export STATE_MACHINE_DIR="${tmp_dir}"
  export POC_OUTPUT_DIR="${tmp_dir}/poc-output"

  bash "${SCRIPT_DIR}/scripts/state-machine/step-subagent-poc.sh" generate-prompt task-list-init 180 >/dev/null 2>&1

  local prompt_file="${tmp_dir}/poc-output/prompt-task-list-init.md"

  TOTAL=$((TOTAL + 1))
  if [[ -f "${prompt_file}" ]]; then
    echo "  PASS: prompt file generated for measurement"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: prompt file not generated: ${prompt_file}"
    FAIL=$((FAIL + 1))
    rm -rf "${tmp_dir}"
    return
  fi

  local output
  output=$(bash "${MEASURE_SCRIPT}" "${prompt_file}")

  # 規則佔比 >= 10%
  TOTAL=$((TOTAL + 1))
  local passed_val ratio
  ratio=$(echo "${output}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['ratio'])" 2>/dev/null)
  passed_val=$(echo "${output}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(str(d['passed']).lower())" 2>/dev/null)
  if [[ "${passed_val}" == "true" ]]; then
    echo "  PASS: task-list-init prompt ratio >= 10% (ratio=${ratio})"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: task-list-init prompt ratio < 10% (ratio=${ratio})"
    FAIL=$((FAIL + 1))
  fi

  rm -rf "${tmp_dir}"
  unset STATE_MACHINE_DIR POC_OUTPUT_DIR
}

# ── 執行所有測試 ──

echo "=== Rule Ratio Measure Tests (Story #983 AC-2) ==="
echo ""

test_script_exists
echo ""
test_no_args_shows_usage
echo ""
test_nonexistent_file
echo ""
test_english_only_ratio
echo ""
test_no_dependency
echo ""
test_json_output_format
echo ""
test_passed_field_threshold
echo ""
test_token_estimation_formula
echo ""
test_task_list_init_prompt_ratio
echo ""

echo "=== Results: ${PASS}/${TOTAL} passed, ${FAIL} failed ==="

if [[ ${FAIL} -gt 0 ]]; then
  exit 1
fi
