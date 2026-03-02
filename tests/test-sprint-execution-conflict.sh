#!/usr/bin/env bash
# tests/test-sprint-execution-conflict.sh
# Retro #57：Developer subagent 狀態更新衝突防護 — 測試套件
# 覆蓋 AC1（衝突偵測機制定義）/ AC2（可觀察的衝突指示）/ AC3（衝突場景驗收）

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
  if grep -qF "$needle" "$filepath"; then
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
# TC-01：AC1 — 狀態更新衝突防護小節標題存在
# ---------------------------------------------------------------------------
test_tc01_conflict_protection_section_exists() {
  assert_file_contains \
    "狀態更新衝突防護" \
    "$SKILL_FILE" \
    "TC-01：狀態更新衝突防護小節標題存在"
}

# ---------------------------------------------------------------------------
# TC-02：AC1 — read-then-compare 機制描述存在
# ---------------------------------------------------------------------------
test_tc02_read_then_compare_exists() {
  assert_file_contains \
    "read-then-compare" \
    "$SKILL_FILE" \
    "TC-02：read-then-compare 機制描述存在"
}

# ---------------------------------------------------------------------------
# TC-03：AC1 — 放棄寫入（不靜默覆蓋）的說明存在
# ---------------------------------------------------------------------------
test_tc03_no_silent_overwrite_exists() {
  assert_file_contains \
    "放棄寫入" \
    "$SKILL_FILE" \
    "TC-03：放棄寫入說明存在"
}

# ---------------------------------------------------------------------------
# TC-04：AC2 — 衝突警告字串前綴 [CONFLICT] 存在
# ---------------------------------------------------------------------------
test_tc04_conflict_keyword_exists() {
  assert_file_contains \
    "[CONFLICT]" \
    "$SKILL_FILE" \
    "TC-04：衝突警告關鍵字 [CONFLICT] 存在"
}

# ---------------------------------------------------------------------------
# TC-05：AC2 — 衝突警告字串完整格式存在
# ---------------------------------------------------------------------------
test_tc05_conflict_warning_format_exists() {
  assert_file_contains \
    "[CONFLICT] 狀態衝突，跳過覆蓋：" \
    "$SKILL_FILE" \
    "TC-05：衝突警告字串完整格式（[CONFLICT] 狀態衝突，跳過覆蓋：）存在"
}

# ---------------------------------------------------------------------------
# TC-06：AC2 — 警告字串包含 story_id 佔位符
# ---------------------------------------------------------------------------
test_tc06_conflict_format_story_id_placeholder() {
  assert_file_contains \
    "{story_id}" \
    "$SKILL_FILE" \
    "TC-06：衝突警告格式包含 {story_id} 佔位符"
}

# ---------------------------------------------------------------------------
# TC-07：AC2 — 警告字串包含 actual（當前值）佔位符
# ---------------------------------------------------------------------------
test_tc07_conflict_format_actual_placeholder() {
  assert_file_contains \
    "當前值={actual}" \
    "$SKILL_FILE" \
    "TC-07：衝突警告格式包含「當前值={actual}」"
}

# ---------------------------------------------------------------------------
# TC-08：AC2 — 警告字串包含 expected（預期值）佔位符
# ---------------------------------------------------------------------------
test_tc08_conflict_format_expected_placeholder() {
  assert_file_contains \
    "預期值={expected}" \
    "$SKILL_FILE" \
    "TC-08：衝突警告格式包含「預期值={expected}」"
}

# ---------------------------------------------------------------------------
# TC-09：AC2 — 可觀察指示（a）：輸出精確字串說明存在
# ---------------------------------------------------------------------------
test_tc09_observable_output_string() {
  assert_file_contains \
    "輸出精確字串" \
    "$SKILL_FILE" \
    "TC-09：可觀察指示（a）輸出精確字串說明存在"
}

# ---------------------------------------------------------------------------
# TC-10：AC2 — 可觀察指示（b）：不執行任何檔案寫入說明存在
# ---------------------------------------------------------------------------
test_tc10_observable_no_file_write() {
  assert_file_contains \
    "不執行任何檔案寫入" \
    "$SKILL_FILE" \
    "TC-10：可觀察指示（b）不執行任何檔案寫入說明存在"
}

# ---------------------------------------------------------------------------
# TC-11：AC2 — 可觀察指示（c）：主 session log 識別說明存在
# ---------------------------------------------------------------------------
test_tc11_observable_main_session_log() {
  assert_file_contains \
    "主 session" \
    "$SKILL_FILE" \
    "TC-11：可觀察指示（c）主 session log 識別說明存在"
}

# ---------------------------------------------------------------------------
# TC-12：AC3 — 衝突場景步驟描述存在（read-then-compare 先讀後比對）
# ---------------------------------------------------------------------------
test_tc12_conflict_scenario_steps() {
  assert_file_contains \
    "先讀取目前檔案中該 Story 的狀態值" \
    "$SKILL_FILE" \
    "TC-12：衝突場景描述「先讀取目前檔案中該 Story 的狀態值」存在"
}

# ---------------------------------------------------------------------------
# 執行所有測試
# ---------------------------------------------------------------------------
echo "=============================="
echo " Retro #57 狀態更新衝突防護 測試套件"
echo "=============================="
echo ""

test_tc01_conflict_protection_section_exists
test_tc02_read_then_compare_exists
test_tc03_no_silent_overwrite_exists
test_tc04_conflict_keyword_exists
test_tc05_conflict_warning_format_exists
test_tc06_conflict_format_story_id_placeholder
test_tc07_conflict_format_actual_placeholder
test_tc08_conflict_format_expected_placeholder
test_tc09_observable_output_string
test_tc10_observable_no_file_write
test_tc11_observable_main_session_log
test_tc12_conflict_scenario_steps

echo ""
echo "=============================="
echo " 結果：PASS=$PASS_COUNT  FAIL=$FAIL_COUNT"
echo "=============================="

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
