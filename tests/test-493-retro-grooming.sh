#!/usr/bin/env bash
# tests/test-493-retro-grooming.sh
# Story #493：Retro-Action 連續未完成自動觸發 Grooming 機制
# 覆蓋 AC1（偵測規則定義）/ AC2（Sprint Planning 加入偵測邏輯）/ AC3（#452 觸發案例說明）

set -uo pipefail

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

assert_file_exists() {
  local filepath="$1"
  local label="$2"
  if [ -f "$filepath" ]; then
    pass "$label"
  else
    fail "$label (檔案不存在：$filepath)"
  fi
}

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SPRINT_REVIEW_SKILL="$REPO_ROOT/skills/sprint-review/SKILL.md"
SPRINT_PLANNING_SKILL="$REPO_ROOT/skills/sprint-planning/SKILL.md"
RETRO_GROOMING_REF="$REPO_ROOT/skills/sprint-review/references/retro-grooming.md"

echo "=============================="
echo " Story #493：Retro-Action 連續未完成自動觸發 Grooming 測試套件"
echo "=============================="
echo ""

# ---------------------------------------------------------------------------
# AC1：定義「連續未完成」的偵測規則
# ---------------------------------------------------------------------------

# TC-01：retro-grooming.md 偵測規則文件存在
test_tc01_grooming_reference_exists() {
  assert_file_exists \
    "$RETRO_GROOMING_REF" \
    "TC-01：retro-grooming.md 參考文件存在"
}

# TC-02：偵測規則包含「連續」關鍵字（連續 Sprint 未排入概念）
test_tc02_consecutive_rule_defined() {
  assert_file_contains \
    "連續" \
    "$RETRO_GROOMING_REF" \
    "TC-02：偵測規則包含「連續」Sprint 未完成概念"
}

# TC-03：偵測規則包含「retro-action」label 作為偵測目標
test_tc03_retro_action_label_mentioned() {
  assert_file_contains \
    "retro-action" \
    "$RETRO_GROOMING_REF" \
    "TC-03：偵測規則基於 retro-action label"
}

# TC-04：偵測規則包含閾值定義（2 Sprint）
test_tc04_threshold_defined() {
  assert_file_contains \
    "2" \
    "$RETRO_GROOMING_REF" \
    "TC-04：偵測閾值定義（至少含「2」）"
}

# TC-05：偵測規則包含觸發 Grooming 的動作說明
test_tc05_grooming_trigger_action_defined() {
  assert_file_contains \
    "Grooming" \
    "$RETRO_GROOMING_REF" \
    "TC-05：偵測規則包含觸發 Grooming 的動作說明"
}

# TC-06：偵測規則包含機器可解析的告警關鍵字
test_tc06_machine_readable_alert_keyword() {
  assert_file_contains \
    "[RETRO-GROOMING-TRIGGER]" \
    "$RETRO_GROOMING_REF" \
    "TC-06：機器可解析告警關鍵字 [RETRO-GROOMING-TRIGGER] 存在"
}

# ---------------------------------------------------------------------------
# AC2：Sprint Planning Skill 加入此偵測邏輯
# ---------------------------------------------------------------------------

# TC-07：Sprint Planning SKILL.md 引用 retro-grooming 偵測
test_tc07_sprint_planning_references_grooming() {
  assert_file_contains \
    "retro-grooming" \
    "$SPRINT_PLANNING_SKILL" \
    "TC-07：Sprint Planning SKILL.md 引用 retro-grooming 偵測"
}

# TC-08：Sprint Review SKILL.md 包含 retro-action 逐項確認邏輯（已有，驗收已存在的偵測觸發說明）
test_tc08_sprint_review_retro_action_check() {
  assert_file_contains \
    "retro-action" \
    "$SPRINT_REVIEW_SKILL" \
    "TC-08：Sprint Review SKILL.md 包含 retro-action 確認邏輯"
}

# TC-09：Sprint Review SKILL.md 包含連續未完成升級說明（引用 retro-grooming.md）
test_tc09_sprint_review_references_grooming_doc() {
  assert_file_contains \
    "retro-grooming" \
    "$SPRINT_REVIEW_SKILL" \
    "TC-09：Sprint Review SKILL.md 引用 retro-grooming.md"
}

# ---------------------------------------------------------------------------
# AC3：#452 作為觸發案例驗證機制可行性
# ---------------------------------------------------------------------------

# TC-10：retro-grooming.md 包含 #452 觸發案例說明
test_tc10_452_case_documented() {
  assert_file_contains \
    "#452" \
    "$RETRO_GROOMING_REF" \
    "TC-10：retro-grooming.md 包含 #452 觸發案例說明"
}

# TC-11：retro-grooming.md 包含「升級 priority」或「強制排入」處置說明
test_tc11_grooming_action_options_defined() {
  if grep -qF "升級 priority" "$RETRO_GROOMING_REF" || grep -qF "強制排入" "$RETRO_GROOMING_REF"; then
    pass "TC-11：grooming 處置說明包含「升級 priority」或「強制排入」"
  else
    fail "TC-11：grooming 處置說明未含「升級 priority」或「強制排入」"
  fi
}

# TC-12：retro-grooming.md 包含 gh 指令範例（掃描 retro-action open issues）
test_tc12_gh_command_example_exists() {
  assert_file_contains \
    "gh issue list" \
    "$RETRO_GROOMING_REF" \
    "TC-12：retro-grooming.md 包含 gh issue list 指令範例"
}

# ---------------------------------------------------------------------------
# 執行所有測試
# ---------------------------------------------------------------------------
test_tc01_grooming_reference_exists
test_tc02_consecutive_rule_defined
test_tc03_retro_action_label_mentioned
test_tc04_threshold_defined
test_tc05_grooming_trigger_action_defined
test_tc06_machine_readable_alert_keyword
test_tc07_sprint_planning_references_grooming
test_tc08_sprint_review_retro_action_check
test_tc09_sprint_review_references_grooming_doc
test_tc10_452_case_documented
test_tc11_grooming_action_options_defined
test_tc12_gh_command_example_exists

echo ""
echo "=============================="
echo " 結果：PASS=$PASS_COUNT  FAIL=$FAIL_COUNT"
echo "=============================="

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
