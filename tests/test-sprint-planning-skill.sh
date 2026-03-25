#!/usr/bin/env bash
# tests/test-sprint-planning-skill.sh
# US-30：Sprint Planning SKILL.md 防漂移約束驗證 — 測試套件
# 覆蓋 AC1（防漂移約束存在）/ AC2（偏離判定規則）/ AC3（告警處理路徑）

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
# 防漂移約束定義在 po-prompt.md（PO subagent 載入的提示詞文件）
# ---------------------------------------------------------------------------
SKILL_FILE="$(cd "$(dirname "$0")/.." && pwd)/skills/sprint-planning/references/po-prompt.md"

# ---------------------------------------------------------------------------
# TC-01：AC1 — 防漂移約束小節標題存在
# ---------------------------------------------------------------------------
test_tc01_drift_protection_section_exists() {
  assert_file_contains \
    "防漂移約束" \
    "$SKILL_FILE" \
    "TC-01：防漂移約束小節標題存在"
}

# ---------------------------------------------------------------------------
# TC-02：AC1 — Round 2 Story 清單須與 Round 1 Story ID + 標題一致的約束說明存在
# ---------------------------------------------------------------------------
test_tc02_round_comparison_rule_exists() {
  assert_file_contains \
    "Round 2" \
    "$SKILL_FILE" \
    "TC-02：Round 2 比對規則說明存在"

  assert_file_contains \
    "Round 1" \
    "$SKILL_FILE" \
    "TC-02：Round 1 參照說明存在"
}

# ---------------------------------------------------------------------------
# TC-03：AC2 — 偏離判定規則包含 Story ID 不符
# ---------------------------------------------------------------------------
test_tc03_deviation_rule_id_mismatch() {
  assert_file_contains \
    "Story ID 不符" \
    "$SKILL_FILE" \
    "TC-03：偏離判定規則包含「Story ID 不符」"
}

# ---------------------------------------------------------------------------
# TC-04：AC2 — 偏離判定規則包含標題改寫
# ---------------------------------------------------------------------------
test_tc04_deviation_rule_title_rewrite() {
  assert_file_contains \
    "標題被改寫" \
    "$SKILL_FILE" \
    "TC-04：偏離判定規則包含「標題被改寫」"
}

# ---------------------------------------------------------------------------
# TC-05：AC2 — 偏離判定規則包含 AC 新增/刪除
# ---------------------------------------------------------------------------
test_tc05_deviation_rule_ac_change() {
  assert_file_contains \
    "AC 被新增" \
    "$SKILL_FILE" \
    "TC-05：偏離判定規則包含「AC 被新增」"
}

# ---------------------------------------------------------------------------
# TC-06：AC3 — 告警處理路徑：QA 告警說明存在
# ---------------------------------------------------------------------------
test_tc06_alert_path_qa_alert() {
  assert_file_contains \
    "QA 告警" \
    "$SKILL_FILE" \
    "TC-06：告警處理路徑包含「QA 告警」"
}

# ---------------------------------------------------------------------------
# TC-07：AC3 — 告警處理路徑：要求 PO 重新派遣說明存在
# ---------------------------------------------------------------------------
test_tc07_alert_path_po_redispatch() {
  assert_file_contains \
    "PO 重新派遣" \
    "$SKILL_FILE" \
    "TC-07：告警處理路徑包含「PO 重新派遣」"
}

# ---------------------------------------------------------------------------
# TC-08：AC3 — 不靜默接受的明確禁止說明存在
# ---------------------------------------------------------------------------
test_tc08_no_silent_acceptance() {
  assert_file_contains \
    "不靜默接受" \
    "$SKILL_FILE" \
    "TC-08：告警處理路徑包含「不靜默接受」"
}

# ---------------------------------------------------------------------------
# TC-09：AC3 — 告警格式範例包含偏離項目清單
# ---------------------------------------------------------------------------
test_tc09_alert_format_deviation_list() {
  assert_file_contains \
    "偏離項目" \
    "$SKILL_FILE" \
    "TC-09：告警格式包含「偏離項目」清單說明"
}

# ---------------------------------------------------------------------------
# TC-10：機器可解析告警關鍵字 [DRIFT-ALERT] 存在
# ---------------------------------------------------------------------------
test_tc10_drift_alert_keyword_exists() {
  assert_file_contains \
    "[DRIFT-ALERT]" \
    "$SKILL_FILE" \
    "TC-10：機器可解析告警關鍵字 [DRIFT-ALERT] 存在"
}

# ---------------------------------------------------------------------------
# TC-11：空表格邊緣案例備註存在
# ---------------------------------------------------------------------------
test_tc11_empty_round1_edge_case_note() {
  assert_file_contains \
    "Round 1 回傳空表格" \
    "$SKILL_FILE" \
    "TC-11：空表格邊緣案例備註（Round 1 回傳空表格）存在"
}

# ---------------------------------------------------------------------------
# #656：Pre-flight Backlog 健康度檢查測試
# 目標檔案：SKILL.md 本體
# ---------------------------------------------------------------------------
MAIN_SKILL_FILE="$(cd "$(dirname "$0")/.." && pwd)/skills/sprint-planning/SKILL.md"

# TC-12：AC1 — Pre-flight 健康度檢查步驟存在於 SKILL.md
test_tc12_preflight_check_step_exists() {
  assert_file_contains \
    "Pre-flight Backlog 健康度檢查" \
    "$MAIN_SKILL_FILE" \
    "TC-12：Pre-flight Backlog 健康度檢查步驟存在"
}

# TC-13：AC4 — 健康度檢查指令存在
test_tc13_preflight_check_command_exists() {
  assert_file_contains \
    'sprint-candidate' \
    "$MAIN_SKILL_FILE" \
    "TC-13：健康度檢查使用 sprint-candidate label"
}

# TC-14：AC2 — [BACKLOG-WARN] 關鍵字存在
test_tc14_backlog_warn_keyword_exists() {
  assert_file_contains \
    "[BACKLOG-WARN]" \
    "$MAIN_SKILL_FILE" \
    "TC-14：[BACKLOG-WARN] 關鍵字存在於 SKILL.md"
}

# TC-15：AC3 — [BACKLOG-OK] 關鍵字存在
test_tc15_backlog_ok_keyword_exists() {
  assert_file_contains \
    "[BACKLOG-OK]" \
    "$MAIN_SKILL_FILE" \
    "TC-15：[BACKLOG-OK] 關鍵字存在於 SKILL.md"
}

# TC-16：AC2 — 觸發 backlog-management 說明存在
test_tc16_backlog_management_trigger_exists() {
  assert_file_contains \
    "backlog-management" \
    "$MAIN_SKILL_FILE" \
    "TC-16：觸發 /backlog-management 說明存在"
}

# ---------------------------------------------------------------------------
# 執行所有測試
# ---------------------------------------------------------------------------
echo "=============================="
echo " US-30 Sprint Planning 防漂移約束 測試套件"
echo "=============================="
echo ""

test_tc01_drift_protection_section_exists
test_tc02_round_comparison_rule_exists
test_tc03_deviation_rule_id_mismatch
test_tc04_deviation_rule_title_rewrite
test_tc05_deviation_rule_ac_change
test_tc06_alert_path_qa_alert
test_tc07_alert_path_po_redispatch
test_tc08_no_silent_acceptance
test_tc09_alert_format_deviation_list
test_tc10_drift_alert_keyword_exists
test_tc11_empty_round1_edge_case_note

echo ""
echo "=============================="
echo " #656 Pre-flight Backlog 健康度檢查 測試"
echo "=============================="
echo ""

test_tc12_preflight_check_step_exists
test_tc13_preflight_check_command_exists
test_tc14_backlog_warn_keyword_exists
test_tc15_backlog_ok_keyword_exists
test_tc16_backlog_management_trigger_exists

echo ""
echo "=============================="
echo " 結果：PASS=$PASS_COUNT  FAIL=$FAIL_COUNT"
echo "=============================="

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
