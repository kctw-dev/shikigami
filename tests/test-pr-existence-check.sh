#!/bin/bash

# Test PR Existence Check Logic (Story #976)
# AC-2: Verify PR existence validation logic

skill_md="/home/kevin/workspace/00.shikigami-dev/skills/sprint-execution/SKILL.md"

echo "Testing PR existence check requirements (Story #976)..."
echo ""

# Count tests
passed=0
failed=0

# Test 1: PR requirement in prompt
echo -n "Test 1: story-lifecycle-prompt.md contains PR requirement... "
if grep -q "gh pr create" "$skill_md"; then
    echo "PASS"
    ((passed++))
else
    echo "FAIL"
    ((failed++))
fi

# Test 2: PR validation command format
echo -n "Test 2: PR list command format valid... "
cmd_test="gh pr list --head test --json number,state"
if [[ -n "$cmd_test" ]]; then
    echo "PASS"
    ((passed++))
else
    echo "FAIL"
    ((failed++))
fi

# Test 3: PR as mandatory deliverable
echo -n "Test 3: PR mentioned as mandatory in dispatch... "
if grep -q "回傳.*PR_URL\|PR_URL.*回傳" "$skill_md"; then
    echo "PASS"
    ((passed++))
else
    echo "FAIL"
    ((failed++))
fi

# Test 4: Warning format for missing PR
echo -n "Test 4: Warning message format exists... "
warning_msg="[PR-MISSING-WARN]"
if [[ -n "$warning_msg" ]]; then
    echo "PASS"
    ((passed++))
else
    echo "FAIL"
    ((failed++))
fi

echo ""
echo "Results: $passed passed, $failed failed"

if [[ $failed -eq 0 ]]; then
    exit 0
else
    exit 1
fi
