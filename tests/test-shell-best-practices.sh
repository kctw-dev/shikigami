#!/usr/bin/env bash
# tests/test-shell-best-practices.sh — Shell test 最佳實踐 AC validation

set -u
PASS=0
FAIL=0

# AC1: QA Engineer SKILL.md has shell test best practices section
test_ac1_skill_has_section() {
  if grep -q "set -e\|counter\|最佳實踐\|VAR+1\|VAR++\|shell test" \
      skills/qa-engineer/SKILL.md 2>/dev/null; then
    echo "PASS: AC1 qa-engineer SKILL.md contains shell test best practices"
    PASS=$((PASS+1))
  else
    echo "FAIL: AC1 qa-engineer SKILL.md missing shell test best practices"
    FAIL=$((FAIL+1))
  fi
}

# AC2: templates/test-template.sh exists
test_ac2_template_exists() {
  if [[ -f "templates/test-template.sh" ]]; then
    echo "PASS: AC2 templates/test-template.sh exists"
    PASS=$((PASS+1))
  else
    echo "FAIL: AC2 templates/test-template.sh not found"
    FAIL=$((FAIL+1))
  fi
}

# AC2: template demonstrates correct counter pattern (no ((VAR++)))
test_ac2_template_correct_pattern() {
  if [[ -f "templates/test-template.sh" ]] && \
     grep -q '\$((.*+1))' templates/test-template.sh && \
     ! grep -v '^#' templates/test-template.sh | grep -q '(([A-Z]*++))'; then
    echo "PASS: AC2 template uses \$((VAR+1)) pattern, no ((VAR++)) found"
    PASS=$((PASS+1))
  else
    echo "FAIL: AC2 template has wrong counter pattern or missing"
    FAIL=$((FAIL+1))
  fi
}

# AC2: template does not use set -e
test_ac2_no_set_e() {
  if [[ -f "templates/test-template.sh" ]] && \
     ! grep -qE '^set -e|^set -.*e' templates/test-template.sh; then
    echo "PASS: AC2 template does not use 'set -e'"
    PASS=$((PASS+1))
  else
    echo "FAIL: AC2 template uses 'set -e' (prohibited per best practices)"
    FAIL=$((FAIL+1))
  fi
}

# AC3: scan tests/*.sh for ((VAR++)) residuals
test_ac3_no_counter_plus_plus() {
  # Find any ((VAR++)) patterns in test files (excluding the template which shows it as bad example)
  local violating_files
  violating_files=$(grep -rl '(([A-Z]*++))' tests/ 2>/dev/null \
    | grep -v test-template.sh \
    | grep -v test-shell-best-practices.sh \
    | grep -v test-bash-arithmetic-warning.sh \
    || true)
  if [[ -z "$violating_files" ]]; then
    echo "PASS: AC3 no ((VAR++)) residuals in tests/*.sh"
    PASS=$((PASS+1))
  else
    echo "FAIL: AC3 found ((VAR++)) in: $violating_files"
    FAIL=$((FAIL+1))
  fi
}

test_ac1_skill_has_section
test_ac2_template_exists
test_ac2_template_correct_pattern
test_ac2_no_set_e
test_ac3_no_counter_plus_plus

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL Total=$((PASS+FAIL))"
[[ $FAIL -eq 0 ]]
