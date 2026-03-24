#!/usr/bin/env bash
# tests/test-364-project-level-low-no-ask.sh
# Issue #364 — retro: CLAUDE.md 紅線 #9 明確化
# 驗證 project_level=low 時各文件明確定義「不停下詢問」行為

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

assert_file_exists() {
  local path="$1"
  local label="$2"
  if [[ -f "$path" ]]; then
    pass "$label"
  else
    fail "$label (file not found: $path)"
  fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CLAUDE_MD="${REPO_ROOT}/CLAUDE.md"
PO_PROMPT="${REPO_ROOT}/skills/sprint-planning/references/po-prompt.md"
CRUISE_SKILL="${REPO_ROOT}/skills/cruise/SKILL.md"
SPRINT_PLAN_SKILL="${REPO_ROOT}/skills/sprint-planning/SKILL.md"

echo "=== Issue #364：project_level=low 不停下詢問 測試套件 ==="
echo "REPO_ROOT: $REPO_ROOT"
echo ""

# ---------------------------------------------------------------------------
# TC-1：CLAUDE.md 紅線 #9 明確化
# ---------------------------------------------------------------------------
echo "--- TC-1：CLAUDE.md 紅線 #9 三段式定義 ---"

assert_file_exists "$CLAUDE_MD" "TC-1a: CLAUDE.md 存在"

assert_contains "$CLAUDE_MD" "project_level=low" \
  "TC-1b: CLAUDE.md 包含 project_level=low 關鍵字"

assert_contains "$CLAUDE_MD" "project_level=medium" \
  "TC-1c: CLAUDE.md 包含 project_level=medium 關鍵字"

assert_contains "$CLAUDE_MD" "project_level=high" \
  "TC-1d: CLAUDE.md 包含 project_level=high 關鍵字"

assert_contains "$CLAUDE_MD" "(禁止停下來問|不停下詢問|禁止.*詢問|不.*問人)" \
  "TC-1e: CLAUDE.md 紅線 #9 明確禁止停下詢問"

# ---------------------------------------------------------------------------
# TC-2：po-prompt.md 包含 project_level=low 行為說明
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-2：po-prompt.md project_level=low 行為描述 ---"

assert_file_exists "$PO_PROMPT" "TC-2a: po-prompt.md 存在"

assert_contains "$PO_PROMPT" "project_level" \
  "TC-2b: po-prompt.md 包含 project_level 說明"

assert_contains "$PO_PROMPT" "low" \
  "TC-2c: po-prompt.md 明確定義 low 行為"

assert_contains "$PO_PROMPT" "(自動執行|不.*問|不.*詢問|不.*停下)" \
  "TC-2d: po-prompt.md 說明 low 模式自動執行不詢問"

# ---------------------------------------------------------------------------
# TC-3：cruise/SKILL.md 行為矩陣完整
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-3：cruise/SKILL.md project_level 行為矩陣 ---"

assert_file_exists "$CRUISE_SKILL" "TC-3a: cruise/SKILL.md 存在"

assert_contains "$CRUISE_SKILL" "project_level 行為矩陣" \
  "TC-3b: cruise SKILL.md 含行為矩陣標題"

assert_contains "$CRUISE_SKILL" "low.*medium.*high|low.*自動" \
  "TC-3c: cruise SKILL.md 行為矩陣含三段式（low/medium/high）"

# ---------------------------------------------------------------------------
# TC-4：sprint-planning/SKILL.md low=不問人
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-4：sprint-planning/SKILL.md low=自動啟動不問人 ---"

assert_file_exists "$SPRINT_PLAN_SKILL" "TC-4a: sprint-planning/SKILL.md 存在"

assert_contains "$SPRINT_PLAN_SKILL" "low.*不問人|low：自動|low.*自動啟動" \
  "TC-4b: sprint-planning SKILL.md 明確定義 low 不問人"

# ---------------------------------------------------------------------------
# 結果彙整
# ---------------------------------------------------------------------------
echo ""
echo "==================================================="
echo "test-364-project-level-low-no-ask.sh 結果："
echo "  PASS=$PASS_COUNT  FAIL=$FAIL_COUNT"
echo "==================================================="

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi
exit 0
