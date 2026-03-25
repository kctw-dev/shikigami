#!/usr/bin/env bash
# test-validate-ci-versions.sh
# 測試 scripts/validate-ci-versions.sh 的基本功能
#
# 使用方式：bash tests/test-validate-ci-versions.sh
# 退出碼：0 = 全部通過，1 = 有測試失敗

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VALIDATE_SCRIPT="${REPO_ROOT}/scripts/validate-ci-versions.sh"

PASS_COUNT=0
FAIL_COUNT=0

# ──────────────────────────────────────────────
# 測試工具函式
# ──────────────────────────────────────────────
assert_exit_code() {
  local test_name="$1"
  local expected_exit="$2"
  local actual_exit="$3"

  if [[ "${actual_exit}" -eq "${expected_exit}" ]]; then
    echo "  PASS: ${test_name}"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: ${test_name} — 預期 exit ${expected_exit}，實際 exit ${actual_exit}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

assert_output_contains() {
  local test_name="$1"
  local expected_pattern="$2"
  local actual_output="$3"

  if echo "${actual_output}" | grep -q "${expected_pattern}"; then
    echo "  PASS: ${test_name}"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: ${test_name} — 輸出未包含：${expected_pattern}"
    echo "    實際輸出："
    echo "${actual_output}" | head -20 | sed 's/^/      /'
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

assert_output_not_contains() {
  local test_name="$1"
  local pattern="$2"
  local actual_output="$3"

  if ! echo "${actual_output}" | grep -q "${pattern}"; then
    echo "  PASS: ${test_name}"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: ${test_name} — 輸出不應包含：${pattern}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

echo "======================================"
echo "  測試：validate-ci-versions.sh"
echo "======================================"
echo ""

# ──────────────────────────────────────────────
# Test 0：腳本存在且可執行
# ──────────────────────────────────────────────
echo "[ T0 ] 腳本存在且可執行"
if [[ -f "${VALIDATE_SCRIPT}" ]]; then
  echo "  PASS: 腳本存在"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "  FAIL: 腳本不存在：${VALIDATE_SCRIPT}"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if [[ -x "${VALIDATE_SCRIPT}" ]]; then
  echo "  PASS: 腳本可執行"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "  FAIL: 腳本不可執行，嘗試修正..."
  chmod +x "${VALIDATE_SCRIPT}"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo ""

# ──────────────────────────────────────────────
# Test 1：對真實 workflow 執行，應該 PASS
# ──────────────────────────────────────────────
echo "[ T1 ] 對真實 workflow 執行（應 PASS）"
set +e
actual_output=$(bash "${VALIDATE_SCRIPT}" 2>&1)
actual_exit=$?
set -e

assert_exit_code "退出碼應為 0" 0 "${actual_exit}"
assert_output_contains "輸出應包含 PASS" "PASS" "${actual_output}"
assert_output_contains "輸出應包含 actions/checkout@v4" "actions/checkout@v4" "${actual_output}"
assert_output_not_contains "不應有 FAIL 結果行" "結果：FAIL" "${actual_output}"

echo ""

# ──────────────────────────────────────────────
# Test 2：偵測到 Node.js 20 deprecation warnings
# ──────────────────────────────────────────────
echo "[ T2 ] 偵測到 Node.js 20 Deprecation warnings"
assert_output_contains "輸出應包含 Node.js 20 Deprecation 偵測" "Node.js 20 Deprecation" "${actual_output}"
assert_output_contains "輸出應包含 WARNING" "WARNING" "${actual_output}"

echo ""

# ──────────────────────────────────────────────
# Test 3：對含不合規 action 的臨時 workflow，應 FAIL
# ──────────────────────────────────────────────
echo "[ T3 ] 偵測不合規 action 版本（應 FAIL）"

TMP_WORKFLOW_DIR=$(mktemp -d)
trap 'rm -rf "${TMP_WORKFLOW_DIR}"' EXIT

cat > "${TMP_WORKFLOW_DIR}/test-bad.yml" << 'EOF'
name: Bad Workflow
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v2
EOF

# 建立臨時環境以測試不合規情境
# 使用子 shell + 覆寫 WORKFLOWS_DIR（透過環境變數注入）
# 注意：validate-ci-versions.sh 使用 REPO_ROOT 推導 WORKFLOWS_DIR
# 我們建立一個最小化的假 repo 結構
TMP_REPO=$(mktemp -d)
mkdir -p "${TMP_REPO}/.github/workflows"
cat > "${TMP_REPO}/.github/workflows/bad.yml" << 'EOF'
name: Bad Workflow
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v2
EOF

set +e
bad_output=$(CI_VERSIONS_REPO_ROOT="${TMP_REPO}" bash "${VALIDATE_SCRIPT}" 2>&1)
bad_exit=$?
set -e

rm -rf "${TMP_REPO}"

assert_exit_code "不合規 action 退出碼應為 1" 1 "${bad_exit}"
assert_output_contains "不合規輸出應包含 FAIL" "FAIL" "${bad_output}"
assert_output_contains "應偵測到 checkout@v3 不合規" "actions/checkout@v3" "${bad_output}"

echo ""

# ──────────────────────────────────────────────
# Test 4：偵測 pinned SHA action（允許但產生 warning）
# ──────────────────────────────────────────────
echo "[ T4 ] 允許 pinned SHA action"

TMP_REPO2=$(mktemp -d)
mkdir -p "${TMP_REPO2}/.github/workflows"
cat > "${TMP_REPO2}/.github/workflows/sha-pinned.yml" << 'EOF'
name: SHA Pinned
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: oven-sh/setup-bun@4bc047ad259df6fc24a6c9b0f9a0cb08cf17fbe5
EOF

set +e
sha_output=$(CI_VERSIONS_REPO_ROOT="${TMP_REPO2}" bash "${VALIDATE_SCRIPT}" 2>&1)
sha_exit=$?
set -e

rm -rf "${TMP_REPO2}"

assert_exit_code "pinned SHA workflow 退出碼應為 0" 0 "${sha_exit}"
assert_output_contains "應顯示 pinned SHA 狀態" "pinned SHA" "${sha_output}"
assert_output_contains "應顯示 WARN 建議更新 SHA" "WARN" "${sha_output}"

echo ""

# ──────────────────────────────────────────────
# Test 5：偵測 setup-node node-version: "20" 並發出警告
# （#526 Node.js 20 actions deprecation 追蹤）
# ──────────────────────────────────────────────
echo "[ T5 ] 偵測 node-version: \"20\" 並發出警告（#526）"

TMP_REPO5=$(mktemp -d)
mkdir -p "${TMP_REPO5}/.github/workflows"
cat > "${TMP_REPO5}/.github/workflows/node20.yml" << 'EOF'
name: Node20 Workflow
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
EOF

set +e
node20_output=$(CI_VERSIONS_REPO_ROOT="${TMP_REPO5}" bash "${VALIDATE_SCRIPT}" 2>&1)
node20_exit=$?
set -e

rm -rf "${TMP_REPO5}"

assert_exit_code "node-version 20 workflow 退出碼應為 0（不是 FAIL，但有 WARNING）" 0 "${node20_exit}"
assert_output_contains "應發出 node-version 20 警告" "node-version.*20\|node version.*20\|node-version: .20" "${node20_output}"

echo ""

# ──────────────────────────────────────────────
# Test 6：e2e.yml 不應使用 node-version: "20"
# （#526 AC — e2e.yml 已升級至 Node.js 24）
# 注意：e2e.yml 已於 Sprint 142 移除，本測試永遠 SKIP
# ──────────────────────────────────────────────
echo "[ T6 ] e2e.yml 不應使用 node-version: \"20\"（#526）"

E2E_WORKFLOW="${REPO_ROOT}/.github/workflows/e2e.yml"
if [[ -f "${E2E_WORKFLOW}" ]]; then
  if grep -q 'node-version:.*"20"' "${E2E_WORKFLOW}" || grep -q "node-version:.*'20'" "${E2E_WORKFLOW}"; then
    echo "  FAIL: e2e.yml 仍在使用 node-version: 20，需升級至 24（#526）"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  else
    echo "  PASS: e2e.yml 未使用 node-version: 20"
    PASS_COUNT=$((PASS_COUNT + 1))
  fi
else
  echo "  SKIP: e2e.yml 已移除（Sprint 142），跳過驗證"
fi

echo ""

# ──────────────────────────────────────────────
# 結果摘要
# ──────────────────────────────────────────────
TOTAL=$((PASS_COUNT + FAIL_COUNT))
echo "======================================"
echo "  測試結果：${PASS_COUNT}/${TOTAL} 通過"
echo "======================================"

if [[ "${FAIL_COUNT}" -eq 0 ]]; then
  echo "  PASS — 全部測試通過"
  exit 0
else
  echo "  FAIL — ${FAIL_COUNT} 個測試失敗"
  exit 1
fi
