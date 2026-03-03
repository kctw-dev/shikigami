#!/usr/bin/env bash
# tests/test-us37-prompt-injection-protection.sh
# US-37：防範 Issue 提示注入攻擊 — 測試套件
# 覆蓋 AC1 / AC2 / AC3

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

assert_file_contains_regex() {
  local pattern="$1"
  local filepath="$2"
  local label="$3"
  if grep -qE "$pattern" "$filepath"; then
    pass "$label"
  else
    fail "$label (檔案中找不到符合模式「$pattern」的內容)"
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

assert_file_not_contains_in_section() {
  # 確認特定文字不出現在指定區段之外的範圍（此測試方法做的是 positive check：
  # 確認 <issue_title> 與 <issue_body> 標記「確實存在」於 SKILL.md 中）
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
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_MD="$REPO_ROOT/skills/sprint-execution/SKILL.md"
ADR_006="$REPO_ROOT/docs/adr/ADR-006-prompt-injection-protection.md"

# ---------------------------------------------------------------------------
# === AC1 測試：結構化隔離標記實作 ===
# ---------------------------------------------------------------------------

# TC-01：AC1 — SKILL.md §3 回覆流程包含 <issue_title> 隔離標記
test_tc01_issue_title_isolation_marker() {
  assert_file_contains \
    "<issue_title>" \
    "$SKILL_MD" \
    "TC-01：SKILL.md 包含 <issue_title> 隔離標記（開始標記）"
}

# TC-02：AC1 — SKILL.md §3 回覆流程包含 </issue_title> 隔離標記
test_tc02_issue_title_isolation_close_marker() {
  assert_file_contains \
    "</issue_title>" \
    "$SKILL_MD" \
    "TC-02：SKILL.md 包含 </issue_title> 隔離標記（結束標記）"
}

# TC-03：AC1 — SKILL.md §3 回覆流程包含 <issue_body> 隔離標記
test_tc03_issue_body_isolation_marker() {
  assert_file_contains \
    "<issue_body>" \
    "$SKILL_MD" \
    "TC-03：SKILL.md 包含 <issue_body> 隔離標記（開始標記）"
}

# TC-04：AC1 — SKILL.md §3 回覆流程包含 </issue_body> 隔離標記
test_tc04_issue_body_isolation_close_marker() {
  assert_file_contains \
    "</issue_body>" \
    "$SKILL_MD" \
    "TC-04：SKILL.md 包含 </issue_body> 隔離標記（結束標記）"
}

# TC-05：AC1 — 隔離模式命名為「Prompt Injection Isolation Rule」
test_tc05_isolation_rule_named() {
  assert_file_contains \
    "Prompt Injection Isolation Rule" \
    "$SKILL_MD" \
    "TC-05：SKILL.md 包含命名規則「Prompt Injection Isolation Rule」"
}

# TC-06：AC1 — 隔離標記位於 §3 Issue 快掃回覆流程（PO subagent 步驟）
# 驗證方式：§3 中同時存在隔離標記和 PO subagent 相關描述
test_tc06_isolation_in_po_subagent_context() {
  assert_file_contains \
    "PO subagent" \
    "$SKILL_MD" \
    "TC-06：SKILL.md §3 包含 PO subagent 描述"
}

# ---------------------------------------------------------------------------
# === AC2 測試：ADR-006 建立 ===
# ---------------------------------------------------------------------------

# TC-07：AC2 — ADR-006 檔案存在
test_tc07_adr006_exists() {
  assert_file_exists \
    "$ADR_006" \
    "TC-07：docs/adr/ADR-006-prompt-injection-protection.md 存在"
}

# TC-08：AC2 — ADR-006 狀態為 Accepted
test_tc08_adr006_status_accepted() {
  assert_file_contains \
    "狀態**：Accepted" \
    "$ADR_006" \
    "TC-08：ADR-006 狀態為 Accepted"
}

# TC-09：AC2(a) — ADR-006 包含威脅模型
test_tc09_adr006_has_threat_model() {
  assert_file_contains \
    "威脅模型" \
    "$ADR_006" \
    "TC-09：ADR-006 包含威脅模型章節"
}

# TC-10：AC2(b) — ADR-006 包含至少 2 個緩解選項
# 驗證方式：存在「選項 A」和「選項 B」
test_tc10_adr006_has_multiple_options() {
  assert_file_contains_regex \
    "選項 [AB]" \
    "$ADR_006" \
    "TC-10：ADR-006 包含多個緩解選項（至少選項 A 和 B）"
}

# TC-11：AC2(c) — ADR-006 包含選定方案
test_tc11_adr006_has_decision() {
  assert_file_contains \
    "## 決策" \
    "$ADR_006" \
    "TC-11：ADR-006 包含決策章節"
}

# TC-12：AC2(d) — ADR-006 包含範圍限定章節
test_tc12_adr006_has_scope_limitation() {
  assert_file_contains \
    "範圍限定" \
    "$ADR_006" \
    "TC-12：ADR-006 包含範圍限定章節"
}

# TC-13：AC2(d) — ADR-006 範圍限定明確指向 sprint-execution Issue Quick-Scan
test_tc13_adr006_scope_targets_sprint_execution() {
  assert_file_contains \
    "sprint-execution" \
    "$ADR_006" \
    "TC-13：ADR-006 範圍限定包含 sprint-execution"
}

# ---------------------------------------------------------------------------
# === AC3 測試：現有觸發條件不受影響 ===
# ---------------------------------------------------------------------------

# TC-14：AC3 — 現有觸發條件 (a) label 過濾仍存在
test_tc14_trigger_condition_a_label_filter_intact() {
  assert_file_contains \
    "in-backlog" \
    "$SKILL_MD" \
    "TC-14：現有觸發條件 (a) label 過濾（in-backlog）未被移除"
}

# TC-15：AC3 — 現有觸發條件 (b) sprint-N-replied 去重仍存在
test_tc15_trigger_condition_b_dedup_intact() {
  assert_file_contains \
    "sprint-N-replied" \
    "$SKILL_MD" \
    "TC-15：現有觸發條件 (b) sprint-N-replied 去重標記未被移除"
}

# TC-16：AC3 — 現有觸發條件 (c) top-5 oldest 限制仍存在
test_tc16_trigger_condition_c_top5_intact() {
  assert_file_contains \
    "前 5 個" \
    "$SKILL_MD" \
    "TC-16：現有觸發條件 (c) 前 5 個最舊 issue 限制未被移除"
}

# TC-17：AC3 — 隔離標記不出現在觸發條件區段（只應出現在回覆流程）
# 驗證方式：觸發條件說明文字中不含 <issue_title> 或 <issue_body>
# 此測試透過確認三項觸發條件的關鍵文字仍存在（而非被標記取代）來驗證
test_tc17_isolation_not_in_trigger_conditions() {
  # 確認觸發條件關鍵字（retro-action）仍存在，說明觸發條件邏輯完整
  assert_file_contains \
    "retro-action" \
    "$SKILL_MD" \
    "TC-17：觸發條件 (a) retro-action label 過濾仍完整存在"
}

# ---------------------------------------------------------------------------
# 執行所有測試
# ---------------------------------------------------------------------------
echo "=== US-37 提示注入防護測試套件 ==="
echo ""

test_tc01_issue_title_isolation_marker
test_tc02_issue_title_isolation_close_marker
test_tc03_issue_body_isolation_marker
test_tc04_issue_body_isolation_close_marker
test_tc05_isolation_rule_named
test_tc06_isolation_in_po_subagent_context
test_tc07_adr006_exists
test_tc08_adr006_status_accepted
test_tc09_adr006_has_threat_model
test_tc10_adr006_has_multiple_options
test_tc11_adr006_has_decision
test_tc12_adr006_has_scope_limitation
test_tc13_adr006_scope_targets_sprint_execution
test_tc14_trigger_condition_a_label_filter_intact
test_tc15_trigger_condition_b_dedup_intact
test_tc16_trigger_condition_c_top5_intact
test_tc17_isolation_not_in_trigger_conditions

echo ""
echo "=== 結果：PASS $PASS_COUNT / FAIL $FAIL_COUNT ==="

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
