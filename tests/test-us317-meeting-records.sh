#!/usr/bin/env bash
# tests/test-us317-meeting-records.sh
# US-317 Phase 1：Sprint 會議紀錄自動產生 — 測試套件
# 覆蓋 AC1（sprint-planning 寫入 meetings）/ AC1.3（sprint-review & retro 同樣寫入）

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
PLANNING_SKILL="$REPO_ROOT/skills/sprint-planning/SKILL.md"
REVIEW_SKILL="$REPO_ROOT/skills/sprint-review/SKILL.md"

# ---------------------------------------------------------------------------
# TC-01：sprint-planning SKILL.md 包含 docs/meetings 寫入指引
# ---------------------------------------------------------------------------
test_tc01_planning_mentions_meetings_dir() {
  assert_file_contains \
    "docs/meetings" \
    "$PLANNING_SKILL" \
    "TC-01：sprint-planning SKILL.md 包含 docs/meetings 路徑"
}

# ---------------------------------------------------------------------------
# TC-02：sprint-planning SKILL.md 包含 sprint-planning 事件類型
# ---------------------------------------------------------------------------
test_tc02_planning_mentions_event_type() {
  assert_file_contains \
    "sprint-planning" \
    "$PLANNING_SKILL" \
    "TC-02：sprint-planning SKILL.md 包含 sprint-planning event-type"
}

# ---------------------------------------------------------------------------
# TC-03：sprint-planning SKILL.md 包含 frontmatter 欄位指引（participants）
# ---------------------------------------------------------------------------
test_tc03_planning_mentions_participants() {
  assert_file_contains \
    "participants" \
    "$PLANNING_SKILL" \
    "TC-03：sprint-planning SKILL.md 包含 participants frontmatter 欄位"
}

# ---------------------------------------------------------------------------
# TC-04：sprint-planning SKILL.md §5 產出文件表包含 meetings 一列
# ---------------------------------------------------------------------------
test_tc04_planning_output_table_includes_meetings() {
  assert_file_contains \
    "meetings" \
    "$PLANNING_SKILL" \
    "TC-04：sprint-planning SKILL.md §5 產出文件表包含 meetings"
}

# ---------------------------------------------------------------------------
# TC-05：sprint-planning SKILL.md 包含 start_time 指引
# ---------------------------------------------------------------------------
test_tc05_planning_mentions_start_time() {
  assert_file_contains \
    "start_time" \
    "$PLANNING_SKILL" \
    "TC-05：sprint-planning SKILL.md 包含 start_time 欄位指引"
}

# ---------------------------------------------------------------------------
# TC-06：sprint-review SKILL.md 包含 docs/meetings 寫入指引
# ---------------------------------------------------------------------------
test_tc06_review_mentions_meetings_dir() {
  assert_file_contains \
    "docs/meetings" \
    "$REVIEW_SKILL" \
    "TC-06：sprint-review SKILL.md 包含 docs/meetings 路徑"
}

# ---------------------------------------------------------------------------
# TC-07：sprint-review SKILL.md 包含 sprint-review 事件類型
# ---------------------------------------------------------------------------
test_tc07_review_mentions_event_type() {
  assert_file_contains \
    "sprint-review" \
    "$REVIEW_SKILL" \
    "TC-07：sprint-review SKILL.md 包含 sprint-review event-type"
}

# ---------------------------------------------------------------------------
# TC-08：sprint-review SKILL.md 包含 retro 事件類型
# ---------------------------------------------------------------------------
test_tc08_review_mentions_retro_event() {
  assert_file_contains \
    "retro" \
    "$REVIEW_SKILL" \
    "TC-08：sprint-review SKILL.md 包含 retro event-type"
}

# ---------------------------------------------------------------------------
# TC-09：sprint-review SKILL.md §5 產出文件表包含 meetings 一列
# ---------------------------------------------------------------------------
test_tc09_review_output_table_includes_meetings() {
  assert_file_contains \
    "meetings" \
    "$REVIEW_SKILL" \
    "TC-09：sprint-review SKILL.md §5 產出文件表包含 meetings"
}

# ---------------------------------------------------------------------------
# TC-10：sprint-review SKILL.md 包含 participants frontmatter 欄位指引
# ---------------------------------------------------------------------------
test_tc10_review_mentions_participants() {
  assert_file_contains \
    "participants" \
    "$REVIEW_SKILL" \
    "TC-10：sprint-review SKILL.md 包含 participants frontmatter 欄位"
}

# ---------------------------------------------------------------------------
# 執行所有測試
# ---------------------------------------------------------------------------
echo "=============================="
echo " US-317 Sprint 會議紀錄自動產生 測試套件"
echo "=============================="
echo ""

test_tc01_planning_mentions_meetings_dir
test_tc02_planning_mentions_event_type
test_tc03_planning_mentions_participants
test_tc04_planning_output_table_includes_meetings
test_tc05_planning_mentions_start_time
test_tc06_review_mentions_meetings_dir
test_tc07_review_mentions_event_type
test_tc08_review_mentions_retro_event
test_tc09_review_output_table_includes_meetings
test_tc10_review_mentions_participants

echo ""
echo "=============================="
echo " 結果：PASS=$PASS_COUNT  FAIL=$FAIL_COUNT"
echo "=============================="

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
