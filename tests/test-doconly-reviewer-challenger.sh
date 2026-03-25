#!/usr/bin/env bash
# Test: doc_only Story Reviewer + Challenger review stages
# AC1: story-lifecycle-prompt.md doc_only path adds Reviewer + Challenger review steps
# AC2: review does not depend on TDD (uses content checklist)
# AC3: backward compat - simple doc_only (pure SKILL.md changes) can bypass

PASS=0
FAIL=0

SKILL_FILE="skills/sprint-execution/story-lifecycle-prompt.md"

assert_contains_file() {
  local desc="$1" pattern="$2"
  if grep -q "$pattern" "$SKILL_FILE" 2>/dev/null; then
    echo "PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "FAIL: $desc"
    echo "  Pattern '$pattern' not found in $SKILL_FILE"
    FAIL=$((FAIL+1))
  fi
}

assert_not_contains_file() {
  local desc="$1" pattern="$2"
  if ! grep -q "$pattern" "$SKILL_FILE" 2>/dev/null; then
    echo "PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "FAIL: $desc (pattern should NOT be in file)"
    FAIL=$((FAIL+1))
  fi
}

# AC1: doc_only section has Reviewer step
assert_contains_file "AC1a: doc_only path has Reviewer step" "Reviewer.*doc_only\|doc_only.*Reviewer"

# AC1: doc_only section has Challenger step
assert_contains_file "AC1b: doc_only path has Challenger step" "Challenger.*doc_only\|doc_only.*Challenger"

# AC2: review uses content checklist (not TDD)
assert_contains_file "AC2: content checklist mentioned for doc_only" "content.*checklist\|checklist.*doc_only\|文件.*checklist\|checklist.*文件"

# AC3: bypass condition exists for simple doc_only
assert_contains_file "AC3: bypass condition exists for simple doc_only" "bypass.*doc_only\|doc_only.*bypass\|簡單.*doc_only\|doc_only.*簡單\|SKILL.md.*bypass\|bypass.*SKILL"

echo ""
echo "=== Test Results ==="
echo "PASS: $PASS  FAIL: $FAIL"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
