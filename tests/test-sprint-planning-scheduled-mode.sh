#!/usr/bin/env bash
# tests/test-sprint-planning-scheduled-mode.sh
# US-38：排程模式下 Velocity 自動調小 — 僅選 S size Stories
# 覆蓋 AC1（排程模式章節存在）/ AC2（HARD-GATE 定義）/
#        AC3（非排程模式不受影響說明）/ AC4（偵測機制明確定義）

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
SKILL_FILE="$(cd "$(dirname "$0")/.." && pwd)/skills/sprint-planning/SKILL.md"
CRON_TMPL="$(cd "$(dirname "$0")/.." && pwd)/templates/schedule_cron.sh.tmpl"

# ---------------------------------------------------------------------------
# TC-01：AC1 — 「排程模式」章節標題存在
# ---------------------------------------------------------------------------
test_tc01_scheduled_mode_section_exists() {
  assert_file_contains \
    "排程模式" \
    "$SKILL_FILE" \
    "TC-01：「排程模式」章節標題存在"
}

# ---------------------------------------------------------------------------
# TC-02：AC1 — 章節明確說明排程模式僅 S size Stories 可納入
# ---------------------------------------------------------------------------
test_tc02_s_size_only_rule_stated() {
  assert_file_contains \
    "S size" \
    "$SKILL_FILE" \
    "TC-02：明確提及 S size Stories 限制"
}

# ---------------------------------------------------------------------------
# TC-03：AC2 — HARD-GATE 標籤存在（排程模式專用）
# ---------------------------------------------------------------------------
test_tc03_hard_gate_label_exists() {
  assert_file_contains \
    "HARD-GATE" \
    "$SKILL_FILE" \
    "TC-03：HARD-GATE 標籤存在"
}

# ---------------------------------------------------------------------------
# TC-04：AC2 — M/L Stories 不得選入的明確禁止說明
# ---------------------------------------------------------------------------
test_tc04_ml_stories_forbidden() {
  assert_file_contains \
    "M/L" \
    "$SKILL_FILE" \
    "TC-04：M/L Stories 禁止說明存在"
}

# ---------------------------------------------------------------------------
# TC-05：AC2 — 違反規則時 Sprint Planning 必須中止的說明
# ---------------------------------------------------------------------------
test_tc05_abort_on_violation() {
  assert_file_contains \
    "中止" \
    "$SKILL_FILE" \
    "TC-05：違反規則時 Sprint Planning 必須中止說明存在"
}

# ---------------------------------------------------------------------------
# TC-06：AC3 — 非排程模式不受影響的明確說明
# ---------------------------------------------------------------------------
test_tc06_manual_mode_unaffected() {
  assert_file_contains \
    "非排程模式" \
    "$SKILL_FILE" \
    "TC-06：非排程模式不受影響說明存在"
}

# ---------------------------------------------------------------------------
# TC-07：AC3 — 手動 Sprint Planning 的 M/L Story 仍可選入的說明
# ---------------------------------------------------------------------------
test_tc07_manual_mode_ml_allowed() {
  assert_file_contains \
    "手動" \
    "$SKILL_FILE" \
    "TC-07：手動模式說明存在（M/L Stories 仍可依原流程選入）"
}

# ---------------------------------------------------------------------------
# TC-08：AC4 — 偵測機制明確定義（SHIKIGAMI_SCHEDULED 環境變數）
# ---------------------------------------------------------------------------
test_tc08_detection_mechanism_env_var() {
  assert_file_contains \
    "SHIKIGAMI_SCHEDULED" \
    "$SKILL_FILE" \
    "TC-08：SHIKIGAMI_SCHEDULED 環境變數偵測機制已定義"
}

# ---------------------------------------------------------------------------
# TC-09：AC4 — 偵測機制包含具體值定義（true）
# ---------------------------------------------------------------------------
test_tc09_detection_mechanism_value() {
  assert_file_contains \
    "SHIKIGAMI_SCHEDULED=true" \
    "$SKILL_FILE" \
    "TC-09：偵測機制包含 SHIKIGAMI_SCHEDULED=true 具體值定義"
}

# ---------------------------------------------------------------------------
# TC-10：AC4 — cron 腳本模板注入 SHIKIGAMI_SCHEDULED=true
# ---------------------------------------------------------------------------
test_tc10_cron_tmpl_injects_env_var() {
  assert_file_contains \
    "SHIKIGAMI_SCHEDULED=true" \
    "$CRON_TMPL" \
    "TC-10：schedule_cron.sh.tmpl 注入 SHIKIGAMI_SCHEDULED=true"
}

# ---------------------------------------------------------------------------
# TC-11：AC2 — 排程模式章節內含 HARD-GATE 區塊格式（XML 風格標籤）
# ---------------------------------------------------------------------------
test_tc11_hard_gate_block_format() {
  assert_file_contains \
    "<HARD-GATE>" \
    "$SKILL_FILE" \
    "TC-11：HARD-GATE 區塊使用 <HARD-GATE> 標籤格式"
}

# ---------------------------------------------------------------------------
# TC-12：AC1 — 排程模式章節包含 Scheduled Mode 英文標注
# ---------------------------------------------------------------------------
test_tc12_scheduled_mode_english_label() {
  assert_file_contains \
    "Scheduled Mode" \
    "$SKILL_FILE" \
    "TC-12：章節包含 Scheduled Mode 英文標注"
}

# ---------------------------------------------------------------------------
# 執行所有測試
# ---------------------------------------------------------------------------
echo "=============================="
echo " US-38 排程模式 S-size 篩選 測試套件"
echo "=============================="
echo ""

test_tc01_scheduled_mode_section_exists
test_tc02_s_size_only_rule_stated
test_tc03_hard_gate_label_exists
test_tc04_ml_stories_forbidden
test_tc05_abort_on_violation
test_tc06_manual_mode_unaffected
test_tc07_manual_mode_ml_allowed
test_tc08_detection_mechanism_env_var
test_tc09_detection_mechanism_value
test_tc10_cron_tmpl_injects_env_var
test_tc11_hard_gate_block_format
test_tc12_scheduled_mode_english_label

echo ""
echo "=============================="
echo " 結果：PASS=$PASS_COUNT  FAIL=$FAIL_COUNT"
echo "=============================="

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
