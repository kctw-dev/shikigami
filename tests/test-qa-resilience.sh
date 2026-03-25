#!/usr/bin/env bash
# test-qa-resilience.sh — QA FREE-MAD Resilience Protocol Tests
# Story #795 AC3: Validates qa-engineer.md contains resilience rules

set -uo pipefail
PASS=0; FAIL=0

ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

QA_SKILL="agents/qa-engineer.md"
echo "=== QA Resilience Protocol Tests ==="

# AC1: qa-engineer.md contains resilience protocol
echo "--- AC1: Resilience Protocol in qa-engineer.md ---"
if [[ -f "$QA_SKILL" ]]; then
  ok "qa-engineer.md exists"
  if grep -q "resilience\|韌性" "$QA_SKILL"; then
    ok "resilience keyword found"
  else
    fail "resilience keyword missing"
  fi
  if grep -q "counter-evidence\|counter_evidence\|明確反證" "$QA_SKILL"; then
    ok "counter-evidence requirement found"
  else
    fail "counter-evidence requirement missing"
  fi
  if grep -q "FREE-MAD\|挑戰韌性\|多數壓力" "$QA_SKILL"; then
    ok "FREE-MAD resilience mechanism found"
  else
    fail "FREE-MAD resilience mechanism missing"
  fi
  if grep -q "維持挑戰\|維持.*立場\|不.*撤回" "$QA_SKILL"; then
    ok "maintain challenge position rule found"
  else
    fail "maintain challenge position rule missing"
  fi
else
  fail "qa-engineer.md not found"
fi

# AC2: position-change-log mechanism present
echo "--- AC2: Position Change Log ---"
if [[ -f "$QA_SKILL" ]]; then
  if grep -q "POSITION-CHANGE\|立場異動" "$QA_SKILL"; then
    ok "position-change-log mechanism found"
  else
    fail "position-change-log mechanism missing"
  fi
  if grep -q "觸發 counter-evidence\|撤回.*理由" "$QA_SKILL"; then
    ok "counter-evidence logging requirement found"
  else
    fail "counter-evidence logging requirement missing"
  fi
fi

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
