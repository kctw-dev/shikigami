#!/usr/bin/env bash
# tests/test-450-ci-health-check.sh
# Issue #450 — CI 健康檢查腳本 — 主動偵測 CI 故障點
# AC1: scripts/ci-health-check.sh 可執行且輸出 PASS/FAIL
# AC2: 偵測 GitHub App 安裝狀態
# AC3: 整合 validate-ci-versions.sh
# AC4: 偵測必要套件（unzip 等）
# AC5: --json flag 輸出結構化報告

set -uo pipefail

PASS_COUNT=0
FAIL_COUNT=0

pass() {
  echo "  PASS: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "  FAIL: $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
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

assert_executable() {
  local path="$1"
  local label="$2"
  if [[ -x "$path" ]]; then
    pass "$label"
  else
    fail "$label (not executable: $path)"
  fi
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

assert_output_contains() {
  local output="$1"
  local pattern="$2"
  local label="$3"
  if echo "$output" | grep -qE "$pattern"; then
    pass "$label"
  else
    fail "$label (pattern='${pattern}' not found in output)"
  fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HEALTH_SCRIPT="${REPO_ROOT}/scripts/ci-health-check.sh"

echo "=== Issue #450：CI 健康檢查腳本 測試套件 ==="
echo "REPO_ROOT: $REPO_ROOT"
echo ""

# ---------------------------------------------------------------------------
# TC-1：腳本存在且可執行（AC1）
# ---------------------------------------------------------------------------
echo "--- TC-1：腳本存在且可執行 ---"

assert_file_exists "$HEALTH_SCRIPT" "TC-1a: scripts/ci-health-check.sh 存在"
assert_executable "$HEALTH_SCRIPT" "TC-1b: scripts/ci-health-check.sh 可執行"

# ---------------------------------------------------------------------------
# TC-2：腳本結構 — 必要功能片段（AC2/AC3/AC4/AC5）
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-2：腳本結構完整性 ---"

assert_contains "$HEALTH_SCRIPT" \
  "PASS|FAIL" \
  "TC-2a: 腳本包含 PASS/FAIL 輸出"

assert_contains "$HEALTH_SCRIPT" \
  "GitHub App|installation|gh api" \
  "TC-2b: 腳本包含 GitHub App 偵測邏輯（AC2）"

assert_contains "$HEALTH_SCRIPT" \
  "validate-ci-versions" \
  "TC-2c: 腳本整合 validate-ci-versions.sh（AC3）"

assert_contains "$HEALTH_SCRIPT" \
  "unzip|which unzip|command -v unzip" \
  "TC-2d: 腳本偵測 unzip 套件（AC4）"

assert_contains "$HEALTH_SCRIPT" \
  "\-\-json|--json" \
  "TC-2e: 腳本支援 --json flag（AC5）"

# ---------------------------------------------------------------------------
# TC-3：腳本執行 — 基本輸出格式（AC1）
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-3：腳本執行輸出格式 ---"

# 執行腳本（允許非零退出碼，因為 GitHub App 可能偵測失敗）
HEALTH_OUTPUT=$(CI_HEALTH_CHECK_REPO_ROOT="${REPO_ROOT}" bash "$HEALTH_SCRIPT" 2>&1 || true)

assert_output_contains "$HEALTH_OUTPUT" \
  "PASS|FAIL|ERROR" \
  "TC-3a: 執行輸出含有 PASS/FAIL/ERROR 狀態字"

assert_output_contains "$HEALTH_OUTPUT" \
  "CI 健康|ci.health|Health Check|健康檢查" \
  "TC-3b: 執行輸出含有健康檢查標題"

assert_output_contains "$HEALTH_OUTPUT" \
  "GitHub App|App 安裝|installation" \
  "TC-3c: 執行輸出含 GitHub App 偵測結果"

assert_output_contains "$HEALTH_OUTPUT" \
  "unzip|套件|package" \
  "TC-3d: 執行輸出含套件偵測結果"

assert_output_contains "$HEALTH_OUTPUT" \
  "validate-ci-versions|Action 版本|CI Actions" \
  "TC-3e: 執行輸出含 Action 版本檢查結果"

# ---------------------------------------------------------------------------
# TC-4：--json flag 輸出結構化報告（AC5）
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-4：--json flag 輸出結構化 JSON ---"

JSON_OUTPUT=$(CI_HEALTH_CHECK_REPO_ROOT="${REPO_ROOT}" bash "$HEALTH_SCRIPT" --json 2>&1 || true)

assert_output_contains "$JSON_OUTPUT" \
  '^\{|"status"|"checks"' \
  "TC-4a: --json 輸出包含 JSON 結構（大括號或 status/checks key）"

assert_output_contains "$JSON_OUTPUT" \
  '"github_app"|"ci_versions"|"packages"' \
  "TC-4b: --json 輸出包含各偵測項目 key"

# 驗證輸出可被 python3 解析為合法 JSON
JSON_VALID=$(echo "$JSON_OUTPUT" | python3 -c "import sys,json; data=json.load(sys.stdin); print('ok')" 2>/dev/null || echo "invalid")
if [[ "$JSON_VALID" == "ok" ]]; then
  pass "TC-4c: --json 輸出可被解析為合法 JSON"
else
  fail "TC-4c: --json 輸出無法被解析為合法 JSON (output was: ${JSON_OUTPUT:0:200})"
fi

# ---------------------------------------------------------------------------
# 結果彙整
# ---------------------------------------------------------------------------
echo ""
echo "==================================================="
echo "test-450-ci-health-check.sh 結果："
echo "  PASS=$PASS_COUNT  FAIL=$FAIL_COUNT"
echo "==================================================="

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi
exit 0
