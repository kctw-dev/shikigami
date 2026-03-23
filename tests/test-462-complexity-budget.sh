#!/usr/bin/env bash
# tests/test-462-complexity-budget.sh
# #462 框架複雜度預算機制
# AC1: 定義複雜度度量方式（Skill/Agent/Hook/總行數）
# AC2: 建立複雜度基線（當前值）
# AC3: Sprint Planning 流程加入複雜度影響評估步驟
# AC4: 新增功能 PR 必須附帶複雜度變化報告（+N/-M）
# AC5: 複雜度超出預算時觸發警告（門檻值可配置）
# AC6: 向後相容：既有 Skill/Agent 不需修改即可通過複雜度檢查

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/measure-complexity.sh"

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

assert_file_exists() {
  local path="$1"
  local label="$2"
  if [[ -f "$path" ]]; then
    pass "$label"
  else
    fail "$label (file not found: $path)"
  fi
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -qE "$pattern" "$file" 2>/dev/null; then
    pass "$label"
  else
    fail "$label (pattern '$pattern' not found in $file)"
  fi
}

assert_not_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if ! grep -qE "$pattern" "$file" 2>/dev/null; then
    pass "$label"
  else
    fail "$label (unwanted pattern '$pattern' found in $file)"
  fi
}

assert_output_contains() {
  local output="$1"
  local pattern="$2"
  local label="$3"
  if echo "$output" | grep -qE "$pattern"; then
    pass "$label"
  else
    fail "$label (pattern '$pattern' not found in output)"
  fi
}

assert_exit_code() {
  local actual="$1"
  local expected="$2"
  local label="$3"
  if [[ "$actual" -eq "$expected" ]]; then
    pass "$label"
  else
    fail "$label (expected exit $expected, got $actual)"
  fi
}

echo "=== #462 框架複雜度預算機制 測試開始 ==="
echo ""

# ── AC1：腳本存在，且包含四個量化指標 ────────────────────────────

echo "--- AC1: 複雜度度量定義 ---"
assert_file_exists "$SCRIPT" "AC1: measure-complexity.sh 存在"
assert_contains "$SCRIPT" "SKILL_COUNT|skill_count|技能數|skills" "AC1: 腳本包含 Skill 數量指標"
assert_contains "$SCRIPT" "AGENT_COUNT|agent_count|agents" "AC1: 腳本包含 Agent 數量指標"
assert_contains "$SCRIPT" "HOOK_COUNT|hook_count|hooks" "AC1: 腳本包含 Hook 數量指標"
assert_contains "$SCRIPT" "TOTAL_LINES|total_lines|行數|wc -l" "AC1: 腳本包含總行數指標"

# ── AC2：腳本可執行並輸出基線數據 ────────────────────────────────

echo ""
echo "--- AC2: 複雜度基線輸出 ---"
if [[ -x "$SCRIPT" ]]; then
  OUTPUT=$(cd "$REPO_ROOT" && bash "$SCRIPT" 2>&1)
  EXIT_CODE=$?
  assert_exit_code "$EXIT_CODE" "0" "AC2: 腳本正常退出（exit 0）"
  assert_output_contains "$OUTPUT" "[0-9]+" "AC2: 輸出包含數字（基線數據）"
  assert_output_contains "$OUTPUT" "SKILL|skill|技能" "AC2: 輸出包含 Skill 計數"
  assert_output_contains "$OUTPUT" "AGENT|agent|角色" "AC2: 輸出包含 Agent 計數"
  assert_output_contains "$OUTPUT" "HOOK|hook|鉤子" "AC2: 輸出包含 Hook 計數"
  assert_output_contains "$OUTPUT" "LINE|line|行數" "AC2: 輸出包含行數統計"
else
  fail "AC2: measure-complexity.sh 無執行權限或不存在，跳過執行測試"
fi

# ── AC3：Sprint Planning SKILL.md 加入複雜度評估步驟 ──────────────

echo ""
echo "--- AC3: Sprint Planning 複雜度評估步驟 ---"
PLANNING_SKILL="$REPO_ROOT/skills/sprint-planning/SKILL.md"
assert_file_exists "$PLANNING_SKILL" "AC3: Sprint Planning SKILL.md 存在"
assert_contains "$PLANNING_SKILL" "複雜度|complexity|measure-complexity" \
  "AC3: Sprint Planning SKILL.md 包含複雜度評估步驟"

# ── AC4：腳本支援 --report / --diff 模式（複雜度變化報告）────────

echo ""
echo "--- AC4: PR 複雜度變化報告 ---"
assert_contains "$SCRIPT" "\-\-report|\-\-diff|DIFF|report|delta|變化" \
  "AC4: measure-complexity.sh 支援複雜度變化報告模式"

# ── AC5：超出門檻時輸出 WARNING ──────────────────────────────────

echo ""
echo "--- AC5: 複雜度門檻警告 ---"
assert_contains "$SCRIPT" "WARNING|WARN|warning|超出|exceed|threshold|THRESHOLD|門檻" \
  "AC5: 腳本包含警告邏輯"
assert_contains "$SCRIPT" "COMPLEXITY_BUDGET|BUDGET|budget|MAX_SKILL|MAX_AGENT|可配置" \
  "AC5: 門檻值可配置"

# 測試超標警告是否正常觸發（門檻設為 0 強制超標）
WARN_OUTPUT=$(cd "$REPO_ROOT" && COMPLEXITY_SKILL_BUDGET=0 bash "$SCRIPT" 2>&1) || true
assert_output_contains "$WARN_OUTPUT" "WARNING|WARN|超出|exceed" \
  "AC5: 門檻設為 0 時輸出 WARNING"

# ── AC6：向後相容，現有結構 PASS ─────────────────────────────────

echo ""
echo "--- AC6: 向後相容 ---"
COMPAT_OUTPUT=$(cd "$REPO_ROOT" && bash "$SCRIPT" 2>&1)
COMPAT_EXIT=$?
assert_exit_code "$COMPAT_EXIT" "0" "AC6: 既有結構執行腳本 exit 0（PASS）"
# 確認沒有因既有結構觸發 FATAL 錯誤
if echo "$COMPAT_OUTPUT" | grep -qE "FATAL|ERROR|fatal|error" 2>/dev/null; then
  fail "AC6: 既有結構觸發 FATAL/ERROR（破壞向後相容）"
else
  pass "AC6: 既有結構無 FATAL/ERROR（向後相容通過）"
fi

echo ""
echo "=== 測試完成：PASS=${PASS_COUNT}  FAIL=${FAIL_COUNT} ==="
if [[ "$FAIL_COUNT" -eq 0 ]]; then
  echo "RESULT: PASS"
  exit 0
else
  echo "RESULT: FAIL"
  exit 1
fi
