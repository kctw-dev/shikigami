#!/usr/bin/env bash
# tests/test-parallel-conflict-detection.sh
# US-32：parallel-dispatch 同檔案衝突偵測與自動序列化 — 測試套件
# 覆蓋 AC1（偵測邏輯區段）/ AC2（三個結構性要素）/ AC3（告警格式欄位）/ AC4（回歸不破壞）

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
PROMPT_FILE="$(cd "$(dirname "$0")/.." && pwd)/skills/sprint-execution/developer-prompt.md"

# ---------------------------------------------------------------------------
# TC-01：AC1 — 「同檔案衝突偵測」區段標題存在
# ---------------------------------------------------------------------------
test_tc01_section_title_exists() {
  assert_file_contains \
    "同檔案衝突偵測與自動序列化" \
    "$PROMPT_FILE" \
    "TC-01：「同檔案衝突偵測與自動序列化」區段標題存在"
}

# ---------------------------------------------------------------------------
# TC-02：AC1 — 輸入定義（本 Story 修改檔案清單）存在
# ---------------------------------------------------------------------------
test_tc02_input_story_file_list_exists() {
  assert_file_contains \
    "本 Story 預計修改的檔案清單" \
    "$PROMPT_FILE" \
    "TC-02：輸入定義「本 Story 預計修改的檔案清單」存在"
}

# ---------------------------------------------------------------------------
# TC-03：AC1 — 輸入定義（其他平行 Story 修改檔案清單）存在
# ---------------------------------------------------------------------------
test_tc03_input_parallel_story_list_exists() {
  assert_file_contains \
    "其他平行 Story 的修改檔案清單" \
    "$PROMPT_FILE" \
    "TC-03：輸入定義「其他平行 Story 的修改檔案清單」存在"
}

# ---------------------------------------------------------------------------
# TC-04：AC1 — 輸出定義（衝突檔案列表）存在
# ---------------------------------------------------------------------------
test_tc04_output_conflict_list_exists() {
  assert_file_contains \
    "衝突檔案列表" \
    "$PROMPT_FILE" \
    "TC-04：輸出定義「衝突檔案列表」存在"
}

# ---------------------------------------------------------------------------
# TC-05：AC2(a) — 衝突偵測觸發條件定義存在（修改檔案清單存在交集）
# ---------------------------------------------------------------------------
test_tc05_trigger_condition_exists() {
  assert_file_contains \
    "修改檔案清單存在交集" \
    "$PROMPT_FILE" \
    "TC-05：AC2(a) 衝突偵測觸發條件「修改檔案清單存在交集」存在"
}

# ---------------------------------------------------------------------------
# TC-06：AC2(b) — 序列化切換指引存在（暫停實作衝突檔案）
# ---------------------------------------------------------------------------
test_tc06_serialization_guide_exists() {
  assert_file_contains \
    "暫停實作該衝突檔案" \
    "$PROMPT_FILE" \
    "TC-06：AC2(b) 序列化切換指引「暫停實作該衝突檔案」存在"
}

# ---------------------------------------------------------------------------
# TC-07：AC2(b) — 序列化切換指引步驟完整（等待依賴 Story 完成）
# ---------------------------------------------------------------------------
test_tc07_wait_dependency_exists() {
  assert_file_contains \
    "等待依賴 Story 完成" \
    "$PROMPT_FILE" \
    "TC-07：AC2(b) 序列化切換步驟「等待依賴 Story 完成」存在"
}

# ---------------------------------------------------------------------------
# TC-08：AC2(c) — 使用者告警格式定義存在（[FILE-CONFLICT] 前綴）
# ---------------------------------------------------------------------------
test_tc08_alert_format_prefix_exists() {
  assert_file_contains \
    "[FILE-CONFLICT]" \
    "$PROMPT_FILE" \
    "TC-08：AC2(c) 告警格式前綴「[FILE-CONFLICT]」存在"
}

# ---------------------------------------------------------------------------
# TC-09：AC3 — 告警格式含衝突檔案路徑欄位
# ---------------------------------------------------------------------------
test_tc09_alert_field_conflict_file() {
  assert_file_contains \
    "衝突檔案" \
    "$PROMPT_FILE" \
    "TC-09：AC3 告警格式欄位「衝突檔案」存在"
}

# ---------------------------------------------------------------------------
# TC-10：AC3 — 告警格式含涉及 Story ID 欄位
# ---------------------------------------------------------------------------
test_tc10_alert_field_story_ids() {
  assert_file_contains \
    "涉及 Stories" \
    "$PROMPT_FILE" \
    "TC-10：AC3 告警格式欄位「涉及 Stories」存在"
}

# ---------------------------------------------------------------------------
# TC-11：AC3 — 告警格式含建議執行順序欄位
# ---------------------------------------------------------------------------
test_tc11_alert_field_execution_order() {
  assert_file_contains \
    "建議執行順序" \
    "$PROMPT_FILE" \
    "TC-11：AC3 告警格式欄位「建議執行順序」存在"
}

# ---------------------------------------------------------------------------
# TC-12：AC4（回歸）— TDD 流程區段仍然存在
# ---------------------------------------------------------------------------
test_tc12_regression_tdd_section_intact() {
  assert_file_contains \
    "TDD 流程（強制）" \
    "$PROMPT_FILE" \
    "TC-12：AC4 回歸驗證 — TDD 流程（強制）區段未被移除"
}

# ---------------------------------------------------------------------------
# TC-13：AC4（回歸）— Commit 規範區段仍然存在
# ---------------------------------------------------------------------------
test_tc13_regression_commit_section_intact() {
  assert_file_contains \
    "Commit 規範" \
    "$PROMPT_FILE" \
    "TC-13：AC4 回歸驗證 — Commit 規範區段未被移除"
}

# ---------------------------------------------------------------------------
# TC-14：AC4（回歸）— DoD 自檢清單區段仍然存在
# ---------------------------------------------------------------------------
test_tc14_regression_dod_section_intact() {
  assert_file_contains \
    "DoD 自檢清單" \
    "$PROMPT_FILE" \
    "TC-14：AC4 回歸驗證 — DoD 自檢清單區段未被移除"
}

# ---------------------------------------------------------------------------
# TC-15：AC4（回歸）— 設計原則區段仍然存在
# ---------------------------------------------------------------------------
test_tc15_regression_design_principles_intact() {
  assert_file_contains \
    "設計原則" \
    "$PROMPT_FILE" \
    "TC-15：AC4 回歸驗證 — 設計原則區段未被移除"
}

# ---------------------------------------------------------------------------
# 執行所有測試
# ---------------------------------------------------------------------------
echo "=============================="
echo " US-32 parallel-dispatch 衝突偵測 測試套件"
echo "=============================="
echo ""

test_tc01_section_title_exists
test_tc02_input_story_file_list_exists
test_tc03_input_parallel_story_list_exists
test_tc04_output_conflict_list_exists
test_tc05_trigger_condition_exists
test_tc06_serialization_guide_exists
test_tc07_wait_dependency_exists
test_tc08_alert_format_prefix_exists
test_tc09_alert_field_conflict_file
test_tc10_alert_field_story_ids
test_tc11_alert_field_execution_order
test_tc12_regression_tdd_section_intact
test_tc13_regression_commit_section_intact
test_tc14_regression_dod_section_intact
test_tc15_regression_design_principles_intact

echo ""
echo "=============================="
echo " 結果：PASS=$PASS_COUNT  FAIL=$FAIL_COUNT"
echo "=============================="

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
