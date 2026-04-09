#!/usr/bin/env bash
# test-delivery-completion-check.sh — delivery-completion-check step subagent 測試（Story #988 AC-6）
#
# TC1: 正常 Story（mock gh 回傳 PR=OPEN, base=main）→ status=completed
# TC2: #953 情境（mock gh 回傳空）→ status=failed, error="NO_PR_FOUND"
# TC3: 偽造情境（claimed_pr_url 與實查不符）→ status=escalate, error="PR_MISMATCH_SUSPECTED_FABRICATION"
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POC_SCRIPT="${SCRIPT_DIR}/scripts/state-machine/step-subagent-poc.sh"
STATE_DIR=""
PASS=0
FAIL=0
TOTAL=0

# ── 測試工具函數 ──

setup() {
  STATE_DIR=$(mktemp -d)
  export STATE_MACHINE_DIR="${STATE_DIR}"
  export POC_OUTPUT_DIR="${STATE_DIR}/poc-output"
  mkdir -p "${STATE_DIR}/poc-output"
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

# ── TC1: 正常 Story（mock gh 回傳 PR=OPEN, base=main）→ status=completed ──

test_tc1_normal_story() {
  echo "TC1: 正常 Story（mock gh 回傳 PR=OPEN, base=main）→ status=completed"
  setup

  # 建立 fake gh binary（模擬 PR OPEN, base=main）
  local TMPBIN
  TMPBIN=$(mktemp -d)
  trap "rm -rf ${TMPBIN}" RETURN

  cat > "${TMPBIN}/gh" <<'FAKEGH'
#!/usr/bin/env bash
# Fake gh — TC1: 回傳 PR OPEN, base=main
if [[ "$1" == "pr" && "$2" == "list" ]]; then
  # 回傳 JSON 陣列（模擬 gh pr list --json 輸出）
  cat <<'PRJSON'
[{"number":123,"state":"OPEN","baseRefName":"main","url":"https://github.com/example/repo/pull/123"}]
PRJSON
  exit 0
elif [[ "$1" == "pr" && "$2" == "view" ]]; then
  cat <<'PRJSON'
{"number":123,"state":"OPEN","baseRefName":"main","url":"https://github.com/example/repo/pull/123","title":"Fake PR title"}
PRJSON
  exit 0
fi
exit 0
FAKEGH
  chmod +x "${TMPBIN}/gh"

  local result_file="${STATE_DIR}/poc-output/result-delivery-completion-check-999.json"

  PATH="${TMPBIN}:${PATH}" bash "${POC_SCRIPT}" simulate delivery-completion-check 181 \
    --story-id=999 \
    --branch="feat/#999-fake-story" \
    --claimed-pr-url="https://github.com/example/repo/pull/123" \
    --output="${result_file}" \
    2>/dev/null || true

  assert_file_exists "TC1: result JSON created" "${result_file}"
  assert_json_field "TC1: step_name is delivery-completion-check" "${result_file}" '.step_name' "delivery-completion-check"
  assert_json_field "TC1: status is completed" "${result_file}" '.status' "completed"
  assert_json_field "TC1: error is null" "${result_file}" '.error' "null"

  teardown
}

# ── TC2: #953 情境（mock gh 回傳空）→ status=failed, error="NO_PR_FOUND" ──

test_tc2_no_pr_found() {
  echo "TC2: #953 情境（mock gh 回傳空）→ status=failed, error=NO_PR_FOUND"
  setup

  # 建立 fake gh binary（模擬 gh pr list 回傳空）
  local TMPBIN
  TMPBIN=$(mktemp -d)
  trap "rm -rf ${TMPBIN}" RETURN

  cat > "${TMPBIN}/gh" <<'FAKEGH'
#!/usr/bin/env bash
# Fake gh — TC2: 模擬 #953 情境，gh pr list 回傳空 JSON 陣列
if [[ "$1" == "pr" && "$2" == "list" ]]; then
  # 回傳空陣列（無 PR）
  echo "[]"
  exit 0
elif [[ "$1" == "pr" && "$2" == "view" ]]; then
  echo "no pull requests found for branch" >&2
  exit 1
fi
exit 0
FAKEGH
  chmod +x "${TMPBIN}/gh"

  local result_file="${STATE_DIR}/poc-output/result-delivery-completion-check-953.json"

  PATH="${TMPBIN}:${PATH}" bash "${POC_SCRIPT}" simulate delivery-completion-check 181 \
    --story-id=953 \
    --branch="feat/#953-missing-pr" \
    --claimed-pr-url="" \
    --output="${result_file}" \
    2>/dev/null || true

  assert_file_exists "TC2: result JSON created" "${result_file}"
  assert_json_field "TC2: step_name is delivery-completion-check" "${result_file}" '.step_name' "delivery-completion-check"
  assert_json_field "TC2: status is failed" "${result_file}" '.status' "failed"
  assert_json_field "TC2: error is NO_PR_FOUND" "${result_file}" '.error' "NO_PR_FOUND"

  teardown
}

# ── TC3: 偽造情境（claimed_pr_url 與實查不符）→ status=escalate ──

test_tc3_pr_mismatch() {
  echo "TC3: 偽造情境（claimed_pr_url 與實查不符）→ status=escalate, error=PR_MISMATCH_SUSPECTED_FABRICATION"
  setup

  # 建立 fake gh binary（模擬 PR 存在但 URL 不符）
  local TMPBIN
  TMPBIN=$(mktemp -d)
  trap "rm -rf ${TMPBIN}" RETURN

  cat > "${TMPBIN}/gh" <<'FAKEGH'
#!/usr/bin/env bash
# Fake gh — TC3: PR 存在但 URL 與 claimed 不符（偽造情境）
if [[ "$1" == "pr" && "$2" == "list" ]]; then
  # 回傳真實 PR（URL 與 claimed_pr_url=#999 不同）
  cat <<'PRJSON'
[{"number":456,"state":"OPEN","baseRefName":"main","url":"https://github.com/example/repo/pull/456"}]
PRJSON
  exit 0
elif [[ "$1" == "pr" && "$2" == "view" ]]; then
  cat <<'PRJSON'
{"number":456,"state":"OPEN","baseRefName":"main","url":"https://github.com/example/repo/pull/456","title":"Real PR title"}
PRJSON
  exit 0
fi
exit 0
FAKEGH
  chmod +x "${TMPBIN}/gh"

  local result_file="${STATE_DIR}/poc-output/result-delivery-completion-check-000.json"

  # claimed_pr_url 指向 #999 但實際查到的是 #456
  PATH="${TMPBIN}:${PATH}" bash "${POC_SCRIPT}" simulate delivery-completion-check 181 \
    --story-id=000 \
    --branch="feat/#000-fabricated" \
    --claimed-pr-url="https://github.com/example/repo/pull/999" \
    --output="${result_file}" \
    2>/dev/null || true

  assert_file_exists "TC3: result JSON created" "${result_file}"
  assert_json_field "TC3: step_name is delivery-completion-check" "${result_file}" '.step_name' "delivery-completion-check"
  assert_json_field "TC3: status is escalate" "${result_file}" '.status' "escalate"
  assert_json_field "TC3: error is PR_MISMATCH_SUSPECTED_FABRICATION" "${result_file}" '.error' "PR_MISMATCH_SUSPECTED_FABRICATION"

  teardown
}

# ── 執行所有測試 ──

echo "=== delivery-completion-check Step Subagent Tests (Story #988 AC-6) ==="
echo ""

test_tc1_normal_story
echo ""
test_tc2_no_pr_found
echo ""
test_tc3_pr_mismatch
echo ""

echo "=== Results: ${PASS}/${TOTAL} passed, ${FAIL} failed ==="

if [[ ${FAIL} -gt 0 ]]; then
  exit 1
fi
