#!/usr/bin/env bash
# tests/test-sprint-execution-lsize.sh
# Retro #58：L-size Story QA checklist 強化 — 測試套件
# 覆蓋 AC1（L-size Story 審查增強區段存在）/ AC2（觸發條件明確）/ AC3（格式一致性）

set -uo pipefail

# ---------------------------------------------------------------------------
# 測試框架（輕量）
# ---------------------------------------------------------------------------
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

assert_file_contains() {
  local needle="$1"
  local filepath="$2"
  local label="$3"
  if grep -qF -- "$needle" "$filepath"; then
    pass "$label"
  else
    fail "$label (檔案中找不到「$needle」)"
  fi
}

# ---------------------------------------------------------------------------
# 目標檔案路徑
# ---------------------------------------------------------------------------
SKILL_FILE="$(cd "$(dirname "$0")/.." && pwd)/skills/sprint-execution/SKILL.md"

# ---------------------------------------------------------------------------
# TC-01：AC1 — L-size Story 審查增強子節標題存在
# ---------------------------------------------------------------------------
test_tc01_lsize_section_exists() {
  assert_file_contains \
    "L-size Story 審查增強" \
    "$SKILL_FILE" \
    "TC-01：L-size Story 審查增強子節標題存在"
}

# ---------------------------------------------------------------------------
# TC-02：AC1 — L-size Story 審查增強區段含至少 2 項 checklist 條目
# ---------------------------------------------------------------------------
test_tc02_checklist_min_two_items() {
  local count
  count=$(awk '/L-size Story 審查增強/,/^## [0-9]/' "$SKILL_FILE" | grep -cF -- "- [ ]" || true)
  if [ "$count" -ge 2 ]; then
    pass "TC-02：L-size Story 審查增強區段含至少 2 項 checklist 條目（找到 $count 項）"
  else
    fail "TC-02：L-size Story 審查增強區段 checklist 條目數量不足（找到 $count 項，需至少 2 項）"
  fi
}

# ---------------------------------------------------------------------------
# TC-03：AC2 — 觸發條件包含「Story Size」說明
# ---------------------------------------------------------------------------
test_tc03_trigger_condition_story_size_exists() {
  assert_file_contains \
    "Story Size" \
    "$SKILL_FILE" \
    "TC-03：觸發條件包含「Story Size」說明"
}

# ---------------------------------------------------------------------------
# TC-04：AC2 — 觸發條件包含「3 points」
# ---------------------------------------------------------------------------
test_tc04_trigger_condition_3points_exists() {
  assert_file_contains \
    "3 points" \
    "$SKILL_FILE" \
    "TC-04：觸發條件包含「3 points」"
}

# ---------------------------------------------------------------------------
# TC-05：AC2 — 觸發條件包含「自動啟用」說明
# ---------------------------------------------------------------------------
test_tc05_trigger_auto_activate_exists() {
  assert_file_contains \
    "自動啟用" \
    "$SKILL_FILE" \
    "TC-05：觸發條件包含「自動啟用」說明"
}

# ---------------------------------------------------------------------------
# TC-06：AC3 — 格式一致性：使用 - [ ] 格式
# ---------------------------------------------------------------------------
test_tc06_format_checkbox_exists() {
  assert_file_contains \
    "- [ ]" \
    "$SKILL_FILE" \
    "TC-06：checklist 條目使用「- [ ]」格式"
}

# ---------------------------------------------------------------------------
# TC-07：AC3 — 格式一致性：L-size 區段含粗體項目名稱（**…** 格式）
# ---------------------------------------------------------------------------
test_tc07_format_bold_name_in_lsize_section() {
  local section_content
  section_content=$(awk '/L-size Story 審查增強/,/^## [0-9]/' "$SKILL_FILE")
  if [[ "$section_content" == *"**"* ]]; then
    pass "TC-07：L-size Story 審查增強區段含粗體項目名稱（**…** 格式）"
  else
    fail "TC-07：L-size Story 審查增強區段缺少粗體項目名稱（**…** 格式）"
  fi
}

# ---------------------------------------------------------------------------
# TC-08：AC1 — 增強項包含 Architect 設計審查相關說明
# ---------------------------------------------------------------------------
test_tc08_architect_review_exists() {
  local section_content
  section_content=$(awk '/L-size Story 審查增強/,/^## [0-9]/' "$SKILL_FILE")
  if [[ "$section_content" == *"Architect"* ]]; then
    pass "TC-08：增強項包含 Architect 設計審查說明"
  else
    fail "TC-08：增強項缺少 Architect 設計審查說明"
  fi
}

# ---------------------------------------------------------------------------
# TC-09：AC1 — 新增子節位於「審查失敗處理」之後、「安全審查」之前（位置正確）
# 使用標題文字比對而非節次編號，兼容節次重編號（US-41 Phase 2 後 §6→§7，§7→§8）
# ---------------------------------------------------------------------------
test_tc09_section_position_between_sec6_and_sec7() {
  local lsize_line
  lsize_line=$(grep -n "L-size Story 審查增強" "$SKILL_FILE" | head -1 | cut -d: -f1 || true)
  # 使用章節標題而非節次編號：兼容新舊編號
  local sec_review_line
  sec_review_line=$(grep -n "^## [0-9]\+\. 審查失敗處理" "$SKILL_FILE" | head -1 | cut -d: -f1 || true)
  local sec_security_line
  sec_security_line=$(grep -n "^## [0-9]\+\. 安全審查觸發條件" "$SKILL_FILE" | head -1 | cut -d: -f1 || true)
  if [ -n "$lsize_line" ] && [ -n "$sec_review_line" ] && [ -n "$sec_security_line" ] \
     && [ "$lsize_line" -gt "$sec_review_line" ] && [ "$lsize_line" -lt "$sec_security_line" ]; then
    pass "TC-09：L-size Story 審查增強子節位於「審查失敗處理」之後、「安全審查觸發條件」之前（行 $sec_review_line < $lsize_line < $sec_security_line）"
  else
    fail "TC-09：L-size Story 審查增強子節位置不正確（審查失敗處理=$sec_review_line, lsize=$lsize_line, 安全審查=$sec_security_line）"
  fi
}

# ---------------------------------------------------------------------------
# 執行所有測試
# ---------------------------------------------------------------------------
echo "=============================="
echo " Retro #58 L-size Story QA checklist 強化 測試套件"
echo "=============================="
echo ""

test_tc01_lsize_section_exists
test_tc02_checklist_min_two_items
test_tc03_trigger_condition_story_size_exists
test_tc04_trigger_condition_3points_exists
test_tc05_trigger_auto_activate_exists
test_tc06_format_checkbox_exists
test_tc07_format_bold_name_in_lsize_section
test_tc08_architect_review_exists
test_tc09_section_position_between_sec6_and_sec7

echo ""
echo "=============================="
echo " 結果：PASS=$PASS_COUNT  FAIL=$FAIL_COUNT"
echo "=============================="

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
