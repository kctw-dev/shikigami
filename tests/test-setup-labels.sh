#!/usr/bin/env bash
# tests/test-setup-labels.sh
# US-34：Onboarding 應預建常用 GitHub Labels — 測試套件
# 覆蓋 AC1（Label 建立腳本存在、語法正確、含必要 labels）
#       AC2（冪等性：含 --force 參數）
#       AC3（GETTING_STARTED.md 含 Label 設定步驟）

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
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_FILE="$REPO_ROOT/scripts/setup-labels.sh"
GETTING_STARTED="$REPO_ROOT/docs/tutorial/GETTING_STARTED.md"

# ---------------------------------------------------------------------------
# TC-01：AC1 — scripts/setup-labels.sh 存在
# ---------------------------------------------------------------------------
test_tc01_script_exists() {
  if [ -f "$SCRIPT_FILE" ]; then
    pass "TC-01：scripts/setup-labels.sh 存在"
  else
    fail "TC-01：scripts/setup-labels.sh 不存在"
  fi
}

# ---------------------------------------------------------------------------
# TC-02：AC1 — 腳本可執行（executable bit 已設定）
# ---------------------------------------------------------------------------
test_tc02_script_executable() {
  if [ -x "$SCRIPT_FILE" ]; then
    pass "TC-02：scripts/setup-labels.sh 可執行"
  else
    fail "TC-02：scripts/setup-labels.sh 不可執行（未設定 executable bit）"
  fi
}

# ---------------------------------------------------------------------------
# TC-03：AC1 — bash -n 語法檢查通過
# ---------------------------------------------------------------------------
test_tc03_script_syntax_valid() {
  if bash -n "$SCRIPT_FILE" 2>/dev/null; then
    pass "TC-03：scripts/setup-labels.sh 語法檢查通過"
  else
    fail "TC-03：scripts/setup-labels.sh 語法錯誤（bash -n 失敗）"
  fi
}

# ---------------------------------------------------------------------------
# TC-04：AC1 — 腳本含 gh label create 呼叫
# ---------------------------------------------------------------------------
test_tc04_script_uses_gh_label_create() {
  assert_file_contains \
    "gh label create" \
    "$SCRIPT_FILE" \
    "TC-04：腳本含 gh label create 呼叫"
}

# ---------------------------------------------------------------------------
# TC-05：AC1 — 必要 label：bug
# ---------------------------------------------------------------------------
test_tc05_label_bug() {
  assert_file_contains \
    "bug" \
    "$SCRIPT_FILE" \
    "TC-05：腳本含必要 label「bug」"
}

# ---------------------------------------------------------------------------
# TC-06：AC1 — 必要 label：feature-request
# ---------------------------------------------------------------------------
test_tc06_label_feature_request() {
  assert_file_contains \
    "feature-request" \
    "$SCRIPT_FILE" \
    "TC-06：腳本含必要 label「feature-request」"
}

# ---------------------------------------------------------------------------
# TC-07：AC1 — 必要 label：retro-action
# ---------------------------------------------------------------------------
test_tc07_label_retro_action() {
  assert_file_contains \
    "retro-action" \
    "$SCRIPT_FILE" \
    "TC-07：腳本含必要 label「retro-action」"
}

# ---------------------------------------------------------------------------
# TC-08：AC1 — 必要 label：in-backlog
# ---------------------------------------------------------------------------
test_tc08_label_in_backlog() {
  assert_file_contains \
    "in-backlog" \
    "$SCRIPT_FILE" \
    "TC-08：腳本含必要 label「in-backlog」"
}

# ---------------------------------------------------------------------------
# TC-09：AC1 — 必要 label：needs-info
# ---------------------------------------------------------------------------
test_tc09_label_needs_info() {
  assert_file_contains \
    "needs-info" \
    "$SCRIPT_FILE" \
    "TC-09：腳本含必要 label「needs-info」"
}

# ---------------------------------------------------------------------------
# TC-10：AC1 — 必要 label：priority-high
# ---------------------------------------------------------------------------
test_tc10_label_priority_high() {
  assert_file_contains \
    "priority-high" \
    "$SCRIPT_FILE" \
    "TC-10：腳本含必要 label「priority-high」"
}

# ---------------------------------------------------------------------------
# TC-11：AC1 — 必要 label：priority-low
# ---------------------------------------------------------------------------
test_tc11_label_priority_low() {
  assert_file_contains \
    "priority-low" \
    "$SCRIPT_FILE" \
    "TC-11：腳本含必要 label「priority-low」"
}

# ---------------------------------------------------------------------------
# TC-12：AC2 — 腳本含 --force 確保冪等性
# ---------------------------------------------------------------------------
test_tc12_idempotent_force_flag() {
  local label="TC-12：腳本含 --force 參數（冪等性保證）"
  if grep -qF -- "--force" "$SCRIPT_FILE"; then
    pass "$label"
  else
    fail "$label (檔案中找不到「--force」)"
  fi
}

# ---------------------------------------------------------------------------
# TC-13：AC3 — GETTING_STARTED.md 含 setup-labels.sh 引用
# ---------------------------------------------------------------------------
test_tc13_getting_started_references_script() {
  assert_file_contains \
    "setup-labels.sh" \
    "$GETTING_STARTED" \
    "TC-13：GETTING_STARTED.md 含 setup-labels.sh 引用"
}

# ---------------------------------------------------------------------------
# TC-14：AC3 — GETTING_STARTED.md 含 Label 設定步驟標題
# ---------------------------------------------------------------------------
test_tc14_getting_started_label_section() {
  assert_file_contains \
    "GitHub Labels" \
    "$GETTING_STARTED" \
    "TC-14：GETTING_STARTED.md 含「GitHub Labels」相關步驟"
}

# ---------------------------------------------------------------------------
# TC-15：AC3 — GETTING_STARTED.md 提及冪等性說明
# ---------------------------------------------------------------------------
test_tc15_getting_started_idempotent_note() {
  assert_file_contains \
    "冪等" \
    "$GETTING_STARTED" \
    "TC-15：GETTING_STARTED.md 含冪等性說明"
}

# ---------------------------------------------------------------------------
# 執行所有測試
# ---------------------------------------------------------------------------
echo "=============================="
echo " US-34 GitHub Labels Setup 測試套件"
echo "=============================="
echo ""

test_tc01_script_exists
test_tc02_script_executable
test_tc03_script_syntax_valid
test_tc04_script_uses_gh_label_create
test_tc05_label_bug
test_tc06_label_feature_request
test_tc07_label_retro_action
test_tc08_label_in_backlog
test_tc09_label_needs_info
test_tc10_label_priority_high
test_tc11_label_priority_low
test_tc12_idempotent_force_flag
test_tc13_getting_started_references_script
test_tc14_getting_started_label_section
test_tc15_getting_started_idempotent_note

echo ""
echo "=============================="
echo " 結果：PASS=$PASS_COUNT  FAIL=$FAIL_COUNT"
echo "=============================="

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
