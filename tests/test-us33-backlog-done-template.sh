#!/usr/bin/env bash
# tests/test-us33-backlog-done-template.sh
# US-33：Onboarding 缺少 BACKLOG_DONE.md 模板 — 測試套件
# 覆蓋 AC1 / AC2a / AC2b / AC3a / AC3b / AC3c

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

assert_file_exists() {
  local filepath="$1"
  local label="$2"
  if [ -f "$filepath" ]; then
    pass "$label"
  else
    fail "$label (檔案不存在：$filepath)"
  fi
}

# ---------------------------------------------------------------------------
# 目標檔案路徑
# ---------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ONBOARDING_SKILL="$REPO_ROOT/skills/onboarding/SKILL.md"
TEMPLATE_FILE="$REPO_ROOT/templates/BACKLOG_DONE.md"

# ---------------------------------------------------------------------------
# TC-01：AC1 — skills/onboarding/SKILL.md 包含建立 BACKLOG_DONE.md 的步驟指引
# ---------------------------------------------------------------------------
test_tc01_onboarding_skill_mentions_backlog_done() {
  assert_file_contains \
    "BACKLOG_DONE.md" \
    "$ONBOARDING_SKILL" \
    "TC-01：onboarding SKILL.md 包含 BACKLOG_DONE.md 步驟指引"
}

# ---------------------------------------------------------------------------
# TC-02：AC2a — §2.1 前置條件檢查列出 BACKLOG_DONE.md 為必要產出物
# ---------------------------------------------------------------------------
test_tc02_prerequisite_check_includes_backlog_done() {
  assert_file_contains \
    "templates/BACKLOG_DONE.md" \
    "$ONBOARDING_SKILL" \
    "TC-02：§2.1 前置條件檢查列出 templates/BACKLOG_DONE.md"
}

# ---------------------------------------------------------------------------
# TC-03：AC2b — §2.3 複製表格包含 BACKLOG_DONE.md 操作說明
# ---------------------------------------------------------------------------
test_tc03_copy_table_includes_backlog_done() {
  # 確認複製表格有 BACKLOG_DONE.md 的來源 → 目的地記錄
  assert_file_contains \
    "docs/prd/BACKLOG_DONE.md" \
    "$ONBOARDING_SKILL" \
    "TC-03：§2.3 複製表格包含目的地 docs/prd/BACKLOG_DONE.md"
}

# ---------------------------------------------------------------------------
# TC-04：AC3a — templates/BACKLOG_DONE.md 存在
# ---------------------------------------------------------------------------
test_tc04_template_file_exists() {
  assert_file_exists \
    "$TEMPLATE_FILE" \
    "TC-04：templates/BACKLOG_DONE.md 存在"
}

# ---------------------------------------------------------------------------
# TC-05：AC3a — 模板 Header 包含文件標題
# ---------------------------------------------------------------------------
test_tc05_template_has_title() {
  assert_file_contains \
    "# Backlog Done" \
    "$TEMPLATE_FILE" \
    "TC-05：模板包含文件標題（# Backlog Done）"
}

# ---------------------------------------------------------------------------
# TC-06：AC3a — 模板 Header 包含最後更新欄位
# ---------------------------------------------------------------------------
test_tc06_template_has_last_update() {
  assert_file_contains \
    "最後更新" \
    "$TEMPLATE_FILE" \
    "TC-06：模板包含最後更新欄位"
}

# ---------------------------------------------------------------------------
# TC-07：AC3a — 模板 Header 包含管理者欄位
# ---------------------------------------------------------------------------
test_tc07_template_has_manager_field() {
  assert_file_contains \
    "管理者" \
    "$TEMPLATE_FILE" \
    "TC-07：模板包含管理者欄位"
}

# ---------------------------------------------------------------------------
# TC-08：AC3b — 模板包含佔位 Sprint 區段（## Sprint N — 完成 格式）
# ---------------------------------------------------------------------------
test_tc08_template_has_placeholder_sprint_section() {
  assert_file_contains \
    "## Sprint N" \
    "$TEMPLATE_FILE" \
    "TC-08：模板包含佔位 Sprint 區段（## Sprint N）"
}

# ---------------------------------------------------------------------------
# TC-09：AC3c — 模板表格欄位包含 Story ID
# ---------------------------------------------------------------------------
test_tc09_table_has_story_id_column() {
  assert_file_contains \
    "Story ID" \
    "$TEMPLATE_FILE" \
    "TC-09：模板表格包含 Story ID 欄位"
}

# ---------------------------------------------------------------------------
# TC-10：AC3c — 模板表格欄位包含標題
# ---------------------------------------------------------------------------
test_tc10_table_has_title_column() {
  assert_file_contains \
    "標題" \
    "$TEMPLATE_FILE" \
    "TC-10：模板表格包含標題欄位"
}

# ---------------------------------------------------------------------------
# TC-11：AC3c — 模板表格欄位包含 Size
# ---------------------------------------------------------------------------
test_tc11_table_has_size_column() {
  assert_file_contains \
    "Size" \
    "$TEMPLATE_FILE" \
    "TC-11：模板表格包含 Size 欄位"
}

# ---------------------------------------------------------------------------
# TC-12：AC3c — 模板表格欄位包含 Points
# ---------------------------------------------------------------------------
test_tc12_table_has_points_column() {
  assert_file_contains \
    "Points" \
    "$TEMPLATE_FILE" \
    "TC-12：模板表格包含 Points 欄位"
}

# ---------------------------------------------------------------------------
# TC-13：AC3c — 模板表格欄位包含完成 Sprint
# ---------------------------------------------------------------------------
test_tc13_table_has_done_sprint_column() {
  assert_file_contains \
    "完成 Sprint" \
    "$TEMPLATE_FILE" \
    "TC-13：模板表格包含完成 Sprint 欄位"
}

# ---------------------------------------------------------------------------
# 執行所有測試
# ---------------------------------------------------------------------------
echo "=== US-33 BACKLOG_DONE.md 模板測試套件 ==="
echo ""

test_tc01_onboarding_skill_mentions_backlog_done
test_tc02_prerequisite_check_includes_backlog_done
test_tc03_copy_table_includes_backlog_done
test_tc04_template_file_exists
test_tc05_template_has_title
test_tc06_template_has_last_update
test_tc07_template_has_manager_field
test_tc08_template_has_placeholder_sprint_section
test_tc09_table_has_story_id_column
test_tc10_table_has_title_column
test_tc11_table_has_size_column
test_tc12_table_has_points_column
test_tc13_table_has_done_sprint_column

echo ""
echo "=== 結果：PASS $PASS_COUNT / FAIL $FAIL_COUNT ==="

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
