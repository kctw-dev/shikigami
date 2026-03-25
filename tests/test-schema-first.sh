#!/usr/bin/env bash
# test-schema-first.sh — Schema-First Enforcement Tests
# Story #802 AC3: Validates validate-schema-contracts.sh tooling

set -uo pipefail
PASS=0; FAIL=0

ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

VALIDATE_SCRIPT="scripts/validate-schema-contracts.sh"
ARCHITECT_PROMPT="skills/sprint-planning/references/architect-prompt.md"

echo "=== Schema-First Enforcement Tests ==="

# AC1: validate-schema-contracts.sh exists and is executable
echo "--- AC1: validate-schema-contracts.sh ---"
if [[ -f "$VALIDATE_SCRIPT" ]]; then
  ok "validate-schema-contracts.sh exists"
  if [[ -x "$VALIDATE_SCRIPT" ]]; then
    ok "validate-schema-contracts.sh is executable"
  else
    fail "validate-schema-contracts.sh not executable"
  fi
  # Test: warn-only (non-blocking) on story without schema
  OUTPUT=$(bash "$VALIDATE_SCRIPT" --dry-run 2>/dev/null)
  EXIT_CODE=$?
  if [[ $EXIT_CODE -eq 0 ]]; then
    ok "validate-schema-contracts.sh exits 0 (warn-only, NFR1)"
  else
    fail "validate-schema-contracts.sh exits non-zero (should be warn-only)"
  fi
  # Test output contains WARN or OK prefix
  if echo "$OUTPUT" | grep -qE "SCHEMA-WARN|SCHEMA-OK|SCHEMA-CHECK"; then
    ok "output contains expected prefix (SCHEMA-WARN/OK/CHECK)"
  else
    fail "output missing expected prefix"
  fi
else
  fail "validate-schema-contracts.sh missing"
fi

# AC2: architect-prompt.md updated with schema contract flag rule
echo "--- AC2: Architect Prompt Update ---"
if [[ -f "$ARCHITECT_PROMPT" ]]; then
  ok "architect-prompt.md exists"
  if grep -q "validate-schema-contracts\|schema.*contract.*flag\|contract.*驗證\|ADR-036.*flag\|schema-first.*flag" "$ARCHITECT_PROMPT"; then
    ok "architect-prompt references schema-first validation"
  else
    fail "architect-prompt missing schema-first validation reference"
  fi
else
  fail "architect-prompt.md not found"
fi

# AC3: self-validation
echo "--- AC3: Self-validation ---"
ok "tests/test-schema-first.sh exists (running now)"

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
