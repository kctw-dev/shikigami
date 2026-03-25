#!/usr/bin/env bash
# tests/test-review-suggestions.sh — Review Suggestions tracking validation
# Tests AC1, AC2, AC3

set -u
PASS=0
FAIL=0

# AC1: docs/km/review-suggestions.md exists and is append-only log
test_ac1_file_exists() {
  if [[ -f "docs/km/review-suggestions.md" ]]; then
    echo "PASS: AC1 docs/km/review-suggestions.md exists"
    PASS=$((PASS+1))
  else
    echo "FAIL: AC1 docs/km/review-suggestions.md not found"
    FAIL=$((FAIL+1))
  fi
}

# AC1: append-only — header mentions append-only
test_ac1_append_only() {
  if grep -qi "append" docs/km/review-suggestions.md 2>/dev/null; then
    echo "PASS: AC1 review-suggestions.md mentions append-only"
    PASS=$((PASS+1))
  else
    echo "FAIL: AC1 review-suggestions.md does not mention append-only"
    FAIL=$((FAIL+1))
  fi
}

# AC2: story-lifecycle-prompt.md has SUGGESTION recording step
test_ac2_suggestion_step() {
  if grep -q "SUGGESTION" skills/sprint-execution/story-lifecycle-prompt.md 2>/dev/null; then
    echo "PASS: AC2 story-lifecycle-prompt.md contains SUGGESTION recording"
    PASS=$((PASS+1))
  else
    echo "FAIL: AC2 story-lifecycle-prompt.md missing SUGGESTION recording"
    FAIL=$((FAIL+1))
  fi
}

# AC2: optional (never blocks)
test_ac2_optional() {
  if grep -qi "optional\|never block" skills/sprint-execution/story-lifecycle-prompt.md 2>/dev/null; then
    echo "PASS: AC2 SUGGESTION step is marked optional/non-blocking"
    PASS=$((PASS+1))
  else
    echo "FAIL: AC2 SUGGESTION step not clearly optional"
    FAIL=$((FAIL+1))
  fi
}

# AC3: scripts/review-suggestion-audit.sh exists and is executable
test_ac3_audit_script() {
  if [[ -x "scripts/review-suggestion-audit.sh" ]]; then
    echo "PASS: AC3 scripts/review-suggestion-audit.sh exists and is executable"
    PASS=$((PASS+1))
  else
    echo "FAIL: AC3 scripts/review-suggestion-audit.sh missing or not executable"
    FAIL=$((FAIL+1))
  fi
}

# AC3: audit script produces output
test_ac3_audit_output() {
  local tmplog
  tmplog=$(mktemp --suffix=.md)
  cat >> "$tmplog" << 'LOGEOF'
| 2026-03-25 | #776 | Use consistent exit codes | SUGGESTION | open | Sprint 161 |
| 2026-03-25 | #776 | Use consistent exit codes | SUGGESTION | open | Sprint 161 |
| 2026-03-25 | #799 | Add error handling | SUGGESTION | open | Sprint 161 |
LOGEOF
  output=$(bash scripts/review-suggestion-audit.sh "$tmplog" 2>/dev/null)
  rm -f "$tmplog"
  if echo "$output" | grep -q "Use consistent exit codes"; then
    echo "PASS: AC3 audit script outputs recurring suggestions"
    PASS=$((PASS+1))
  else
    echo "FAIL: AC3 audit script did not identify recurring suggestion"
    FAIL=$((FAIL+1))
  fi
}

test_ac1_file_exists
test_ac1_append_only
test_ac2_suggestion_step
test_ac2_optional
test_ac3_audit_script
test_ac3_audit_output

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL Total=$((PASS+FAIL))"
[[ $FAIL -eq 0 ]]
