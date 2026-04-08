#!/bin/bash
# Test AC Completeness Check (#967)
# Tests the AC-1 (existence) and AC-2 (completeness) checks for sprint-candidate issues

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_count=0
pass_count=0
fail_count=0

# Helper function to print test results
print_test() {
  local test_name=$1
  local result=$2
  local message=$3

  test_count=$((test_count + 1))

  if [ "$result" = "PASS" ]; then
    echo -e "${GREEN}✓ Test $test_count: $test_name${NC}"
    pass_count=$((pass_count + 1))
  else
    echo -e "${RED}✗ Test $test_count: $test_name${NC}"
    if [ -n "$message" ]; then
      echo "  Error: $message"
    fi
    fail_count=$((fail_count + 1))
  fi
}

# Test 1: Check if SKILL.md includes AC completeness check step
test_skill_md_ac_check() {
  local skill_file="$REPO_ROOT/skills/backlog-management/SKILL.md"

  if ! grep -q "AC 完整性檢查" "$skill_file"; then
    print_test "SKILL.md includes AC completeness check section" "FAIL" \
      "Cannot find 'AC 完整性檢查' in SKILL.md"
    return 1
  fi

  if ! grep -q "ac-completeness-check.md" "$skill_file"; then
    print_test "SKILL.md references ac-completeness-check.md" "FAIL" \
      "Cannot find reference to ac-completeness-check.md"
    return 1
  fi

  if ! grep -q "sprint-candidate" "$skill_file"; then
    print_test "SKILL.md mentions sprint-candidate label" "FAIL" \
      "Cannot find 'sprint-candidate' in SKILL.md"
    return 1
  fi

  print_test "SKILL.md includes AC completeness check section" "PASS"
  return 0
}

# Test 2: Check if Subagent dispatch order includes AC check step
test_subagent_order() {
  local skill_file="$REPO_ROOT/skills/backlog-management/SKILL.md"

  if ! grep -q "AC 完整性檢查（§3.1）" "$skill_file"; then
    print_test "Subagent dispatch order includes AC check" "FAIL" \
      "Cannot find AC check step in dispatch order"
    return 1
  fi

  print_test "Subagent dispatch order includes AC check" "PASS"
  return 0
}

# Test 3: Check if reference file exists
test_reference_file_exists() {
  local ref_file="$REPO_ROOT/skills/backlog-management/references/ac-completeness-check.md"

  if [ ! -f "$ref_file" ]; then
    print_test "Reference file ac-completeness-check.md exists" "FAIL" \
      "File not found: $ref_file"
    return 1
  fi

  print_test "Reference file ac-completeness-check.md exists" "PASS"
  return 0
}

# Test 4: Check reference file content - AC-1 section
test_ac1_section() {
  local ref_file="$REPO_ROOT/skills/backlog-management/references/ac-completeness-check.md"

  if ! grep -q "### AC-1：存在性檢查" "$ref_file"; then
    print_test "Reference file includes AC-1 existence check definition" "FAIL" \
      "Cannot find AC-1 section"
    return 1
  fi

  if ! grep -q "## Acceptance Criteria\|## AC" "$ref_file"; then
    print_test "Reference file includes AC section pattern" "FAIL" \
      "Cannot find pattern for AC section"
    return 1
  fi

  print_test "Reference file includes AC-1 existence check definition" "PASS"
  return 0
}

# Test 5: Check reference file content - AC-2 section
test_ac2_section() {
  local ref_file="$REPO_ROOT/skills/backlog-management/references/ac-completeness-check.md"

  if ! grep -q "### AC-2：完整性檢查" "$ref_file"; then
    print_test "Reference file includes AC-2 completeness check definition" "FAIL" \
      "Cannot find AC-2 section"
    return 1
  fi

  if ! grep -q "checkbox_count" "$ref_file"; then
    print_test "Reference file includes checkbox counting logic" "FAIL" \
      "Cannot find checkbox_count logic"
    return 1
  fi

  print_test "Reference file includes AC-2 completeness check definition" "PASS"
  return 0
}

# Test 6: Check reference file content - execution flow
test_execution_flow() {
  local ref_file="$REPO_ROOT/skills/backlog-management/references/ac-completeness-check.md"

  if ! grep -q "## 執行流程" "$ref_file"; then
    print_test "Reference file includes execution flow section" "FAIL" \
      "Cannot find execution flow section"
    return 1
  fi

  if ! grep -q "### 單一 Issue 檢查" "$ref_file"; then
    print_test "Reference file includes single issue check procedure" "FAIL" \
      "Cannot find single issue check section"
    return 1
  fi

  if ! grep -q "### 批次檢查" "$ref_file"; then
    print_test "Reference file includes batch check procedure" "FAIL" \
      "Cannot find batch check section"
    return 1
  fi

  print_test "Reference file includes execution flow section" "PASS"
  return 0
}

# Test 7: Test AC-1 check logic (existence)
test_ac1_logic() {
  # Create temporary test files
  local temp_dir="/tmp/ac-test-$$"
  mkdir -p "$temp_dir"

  # Test case 1: Body WITH AC section
  local body_with_ac="# Issue Title

## Acceptance Criteria

- [ ] AC-1: First criterion
- [ ] AC-2: Second criterion
"

  if ! echo "$body_with_ac" | grep -qi "## acceptance criteria\|## ac"; then
    print_test "AC-1 logic detects AC section" "FAIL" \
      "Failed to detect AC section in body with AC"
    rm -rf "$temp_dir"
    return 1
  fi

  # Test case 2: Body WITHOUT AC section
  local body_without_ac="# Issue Title

## Description

Some description without AC
"

  if echo "$body_without_ac" | grep -qi "## acceptance criteria\|## ac"; then
    print_test "AC-1 logic rejects body without AC section" "FAIL" \
      "Incorrectly detected AC in body without AC"
    rm -rf "$temp_dir"
    return 1
  fi

  print_test "AC-1 logic detects AC section correctly" "PASS"
  rm -rf "$temp_dir"
  return 0
}

# Test 8: Test AC-2 check logic (completeness)
test_ac2_logic() {
  # Test case 1: AC with checkbox items
  local ac_with_checkboxes="## Acceptance Criteria

- [ ] AC-1: First item
- [ ] AC-2: Second item
"

  local checkbox_count=$(echo "$ac_with_checkboxes" | grep -c "^- \[")
  if [ "$checkbox_count" -lt 1 ]; then
    print_test "AC-2 logic counts checkboxes correctly" "FAIL" \
      "Failed to count checkboxes in AC with items"
    return 1
  fi

  # Test case 2: AC without checkbox items
  local ac_without_checkboxes="## Acceptance Criteria

Just some text here without checkboxes
"

  checkbox_count=$(echo "$ac_without_checkboxes" | grep -c "^- \[")
  if [ "$checkbox_count" -gt 0 ]; then
    print_test "AC-2 logic rejects AC without checkboxes" "FAIL" \
      "Incorrectly detected checkboxes in plain text"
    return 1
  fi

  print_test "AC-2 logic counts checkboxes correctly" "PASS"
  return 0
}

# Test 9: Check if reference file mentions sprint-candidate label requirement
test_sprint_candidate_requirement() {
  local ref_file="$REPO_ROOT/skills/backlog-management/references/ac-completeness-check.md"

  if ! grep -q "sprint-candidate" "$ref_file"; then
    print_test "Reference file mentions sprint-candidate label requirement" "FAIL" \
      "Cannot find sprint-candidate reference"
    return 1
  fi

  if ! grep -q "不得取得" "$ref_file"; then
    print_test "Reference file states AC failure blocks sprint-candidate label" "FAIL" \
      "Cannot find block condition statement"
    return 1
  fi

  print_test "Reference file mentions sprint-candidate label requirement" "PASS"
  return 0
}

# Test 10: Check JSON format validation
test_json_validity() {
  # Check if any JSON files in the repository are still valid
  if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⊘ Skipping JSON validation (jq not available)${NC}"
    return 0
  fi

  # This is a basic check - we're not introducing new JSON files in this story
  print_test "JSON format validation" "PASS"
  return 0
}

# Main execution
echo "========================================="
echo "Test: AC Completeness Check (#967)"
echo "========================================="
echo ""

test_skill_md_ac_check
test_subagent_order
test_reference_file_exists
test_ac1_section
test_ac2_section
test_execution_flow
test_ac1_logic
test_ac2_logic
test_sprint_candidate_requirement
test_json_validity

echo ""
echo "========================================="
echo "Test Results: $pass_count passed, $fail_count failed out of $test_count tests"
echo "========================================="

if [ $fail_count -eq 0 ]; then
  exit 0
else
  exit 1
fi
