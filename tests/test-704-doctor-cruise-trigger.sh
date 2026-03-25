#!/usr/bin/env bash
# tests/test-704-doctor-cruise-trigger.sh
# Issue #704 — 驗證 /shikigami:doctor cruise 定期觸發整合（AC6 補完）
#
# AC1: cruise/references/startup-flow.md 新增 §4.3 Doctor 定期觸發邏輯
# AC2: 每 10 個 cycle 自動觸發 /shikigami:doctor 診斷（CYCLE_COUNT % 10 == 0）
# AC3: doctor 觸發記錄寫入 cruise log（type: doctor-triggered, cycle, timestamp）
# AC4: doctor 執行失敗不阻塞 cruise 主流程（降級容錯，輸出 [DOCTOR-WARN]）
# AC5: cycle count 持久化於 .claude/cruise-cycle-count 檔案

set -uo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
STARTUP_FLOW="${REPO_ROOT}/skills/cruise/references/startup-flow.md"

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

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

echo "=== Test #704: Doctor Cruise 定期觸發整合 ==="
echo ""

# AC1: §4.3 段落存在於 startup-flow.md
echo "--- AC1: §4.3 Doctor 定期觸發段落存在 ---"
assert_contains "$STARTUP_FLOW" "§4.3" "AC1: §4.3 段落存在於 startup-flow.md"
assert_contains "$STARTUP_FLOW" "Doctor 定期觸發" "AC1: 段落標題包含 'Doctor 定期觸發'"

# AC2: CYCLE_COUNT % 10 == 0 觸發邏輯
echo "--- AC2: CYCLE_COUNT % 10 觸發邏輯 ---"
assert_contains "$STARTUP_FLOW" "CYCLE_COUNT % 10" "AC2: CYCLE_COUNT % 10 判斷邏輯存在"
assert_contains "$STARTUP_FLOW" "invoke shikigami:doctor" "AC2: doctor 觸發指令存在"

# AC3: cruise log 記錄格式
echo "--- AC3: doctor 觸發記錄格式 ---"
assert_contains "$STARTUP_FLOW" "doctor-triggered" "AC3: type: doctor-triggered 記錄格式存在"
assert_contains "$STARTUP_FLOW" "CRUISE_LOG" "AC3: 寫入 CRUISE_LOG 變數"

# AC4: 降級容錯（失敗不阻塞）
echo "--- AC4: 降級容錯 ---"
assert_contains "$STARTUP_FLOW" "DOCTOR-WARN" "AC4: [DOCTOR-WARN] 降級標識存在"
assert_contains "$STARTUP_FLOW" "continuing cruise" "AC4: 失敗後繼續 cruise 的提示存在"

# AC5: cycle count 持久化
echo "--- AC5: Cycle Count 持久化 ---"
assert_contains "$STARTUP_FLOW" "cruise-cycle-count" "AC5: .claude/cruise-cycle-count 檔案路徑存在"
assert_contains "$STARTUP_FLOW" "CRUISE_CYCLE_COUNT_FILE" "AC5: 持久化變數名稱正確"

# 結構完整性：§4.3 在 §4.2 之後、§4.5 之前
echo "--- 結構驗證: §4.3 位置正確 ---"
SECTION_42_LINE=$(grep -n "§4.2" "$STARTUP_FLOW" 2>/dev/null | tail -1 | cut -d: -f1)
SECTION_43_LINE=$(grep -n "§4.3" "$STARTUP_FLOW" 2>/dev/null | tail -1 | cut -d: -f1)
SECTION_45_LINE=$(grep -n "§4.5" "$STARTUP_FLOW" 2>/dev/null | tail -1 | cut -d: -f1)

if [[ -n "$SECTION_42_LINE" && -n "$SECTION_43_LINE" && -n "$SECTION_45_LINE" ]]; then
  if (( SECTION_42_LINE < SECTION_43_LINE && SECTION_43_LINE < SECTION_45_LINE )); then
    pass "結構驗證: §4.2 < §4.3 < §4.5（位置正確）"
  else
    fail "結構驗證: §4.3 位置不在 §4.2 與 §4.5 之間"
  fi
else
  fail "結構驗證: 無法找到段落行號（§4.2=${SECTION_42_LINE:-MISSING}, §4.3=${SECTION_43_LINE:-MISSING}, §4.5=${SECTION_45_LINE:-MISSING}）"
fi

echo ""
echo "=== 結果: PASS=${PASS}, FAIL=${FAIL} ==="
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
