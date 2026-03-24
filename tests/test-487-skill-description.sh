#!/usr/bin/env bash
# tests/test-487-skill-description.sh
# #487 Skill description 改善 + 章節重新編號
# AC1: cruise description 含使用者自然語言觸發詞（巡航、自動巡邏、定期檢查）
# AC2: scrum-master SKILL.md ≤350 行
# AC3: issue-management SKILL.md ≤400 行
# AC4: 4 個 Skills 章節重新編號，無跳號（architecture-decision §4→§8→§10 修正）
# AC5: validate-skills.sh 全部 PASS

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

assert_line_count_le() {
  local file="$1"
  local max="$2"
  local label="$3"
  local count
  count=$(wc -l < "$file")
  if [[ "$count" -le "$max" ]]; then
    pass "$label (${count} 行 ≤ ${max})"
  else
    fail "$label (${count} 行 > ${max})"
  fi
}

assert_no_section_jump() {
  local file="$1"
  local label="$2"
  # 抽取所有頂層 ## N 章節編號
  local sections
  sections=$(grep -E '^## [0-9]+[. ]' "$file" | grep -oE '[0-9]+' | head -1 --)
  # 抓所有頂層章節編號（## N 格式），確認無跳號
  local prev=0
  local has_jump=false
  while IFS= read -r line; do
    local num
    num=$(echo "$line" | grep -oE '^## ([0-9]+)' | grep -oE '[0-9]+')
    if [[ -n "$num" ]]; then
      if [[ "$prev" -ne 0 ]] && [[ "$num" -ne $((prev + 1)) ]] && [[ "$num" -ne "$prev" ]]; then
        has_jump=true
        echo "  [JUMP] ${prev} → ${num} in $file"
      fi
      prev="$num"
    fi
  done < <(grep -E '^## [0-9]+[. ]' "$file")

  if [[ "$has_jump" == "false" ]]; then
    pass "$label"
  else
    fail "$label（章節有跳號）"
  fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CRUISE_SKILL="${REPO_ROOT}/skills/cruise/SKILL.md"
SCRUM_MASTER_SKILL="${REPO_ROOT}/skills/scrum-master/SKILL.md"
ISSUE_MGMT_SKILL="${REPO_ROOT}/skills/issue-management/SKILL.md"
ARCH_DECISION_SKILL="${REPO_ROOT}/skills/architecture-decision/SKILL.md"
SPRINT_PLANNING_SKILL="${REPO_ROOT}/skills/sprint-planning/SKILL.md"
SHOOT_SKILL="${REPO_ROOT}/skills/shoot/SKILL.md"

echo "=== #487 Skill description 改善 + 章節重新編號 ==="
echo ""

# ---------------------------------------------------------------------------
# AC1: cruise description 含使用者自然語言觸發詞
# ---------------------------------------------------------------------------
echo "--- AC1: cruise description 自然語言觸發詞 ---"

assert_contains "$CRUISE_SKILL" '巡航|cruise mode' \
  "AC1a: cruise description 含「巡航」或「cruise mode」"
assert_contains "$CRUISE_SKILL" '自動巡邏|automated patrol|auto patrol' \
  "AC1b: cruise description 含「自動巡邏」或「automated patrol」"
assert_contains "$CRUISE_SKILL" '定期檢查|periodic.*check|periodic.*scan' \
  "AC1c: cruise description 含「定期檢查」或「periodic check/scan」"

# ---------------------------------------------------------------------------
# AC2: scrum-master SKILL.md ≤350 行
# ---------------------------------------------------------------------------
echo ""
echo "--- AC2: scrum-master 行數 ≤ 350 ---"

assert_line_count_le "$SCRUM_MASTER_SKILL" 350 \
  "AC2: scrum-master SKILL.md 行數"

# ---------------------------------------------------------------------------
# AC3: issue-management SKILL.md ≤400 行
# ---------------------------------------------------------------------------
echo ""
echo "--- AC3: issue-management 行數 ≤ 400 ---"

assert_line_count_le "$ISSUE_MGMT_SKILL" 400 \
  "AC3: issue-management SKILL.md 行數"

# ---------------------------------------------------------------------------
# AC4: 章節編號無跳號
# ---------------------------------------------------------------------------
echo ""
echo "--- AC4: 章節編號無跳號 ---"

assert_no_section_jump "$ARCH_DECISION_SKILL" \
  "AC4a: architecture-decision 章節無跳號"
assert_no_section_jump "$SPRINT_PLANNING_SKILL" \
  "AC4b: sprint-planning 章節無跳號"
assert_no_section_jump "$SCRUM_MASTER_SKILL" \
  "AC4c: scrum-master 章節無跳號"
assert_no_section_jump "$SHOOT_SKILL" \
  "AC4d: shoot 章節無跳號"

# ---------------------------------------------------------------------------
# AC5: validate-skills.sh 全部 PASS
# ---------------------------------------------------------------------------
echo ""
echo "--- AC5: validate-skills.sh ---"

if bash "${REPO_ROOT}/scripts/validate-skills.sh" 2>&1 | grep -q "全部通過"; then
  pass "AC5: validate-skills.sh 全部通過"
else
  fail "AC5: validate-skills.sh 未全部通過"
fi

# ---------------------------------------------------------------------------
# 結果
# ---------------------------------------------------------------------------
echo ""
echo "=== 測試結果 ==="
echo "PASS: $PASS_COUNT"
echo "FAIL: $FAIL_COUNT"

if [[ $FAIL_COUNT -eq 0 ]]; then
  echo "總結：#487 Skill description 改善 + 章節重新編號全部通過"
  exit 0
else
  echo "總結：發現 $FAIL_COUNT 個 FAIL，請修正後重試"
  exit 1
fi
