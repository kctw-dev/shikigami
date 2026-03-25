#!/usr/bin/env bash
# test-interactive-review.sh — #773 AC4
# Tests for quality-gate CRITICAL interactive decision point

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS_COUNT=0
FAIL_COUNT=0

pass() { echo "[PASS] $1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { echo "[FAIL] $1: $2"; FAIL_COUNT=$((FAIL_COUNT+1)); }

echo "=== test-interactive-review.sh ==="

DECISIONS_FILE="${REPO_ROOT}/docs/km/quality-gate-decisions.md"
IR_SCRIPT="${REPO_ROOT}/scripts/interactive-review.sh"

# TC1: interactive-review.sh exists and is executable
if [[ -x "$IR_SCRIPT" ]]; then
  pass "TC1: interactive-review.sh exists and is executable"
else
  fail "TC1" "scripts/interactive-review.sh not found or not executable"
fi

# TC2: [A] Accept Risk with rationale records to decisions file
if [[ -x "$IR_SCRIPT" ]]; then
  TEMP_DECISIONS=$(mktemp /tmp/qg-test-XXXXXX.md)
  cat > "$TEMP_DECISIONS" << 'HEADER'
# Quality Gate Decisions

| Date | Story | Finding | Severity | Decision | Rationale | Sprint |
|------|-------|---------|----------|----------|-----------|--------|
HEADER

  "$IR_SCRIPT" --story "#700" --finding "SQL injection vector" --severity "CRITICAL" \
    --decision "A" --rationale "Low exposure endpoint, no user data" \
    --decisions-file "$TEMP_DECISIONS" --sprint "159" 2>&1

  if grep -q "Accept" "$TEMP_DECISIONS" && grep -q "#700" "$TEMP_DECISIONS"; then
    pass "TC2: [A] Accept decision recorded correctly"
  else
    fail "TC2" "Accept decision not recorded in decisions file"
  fi
  rm -f "$TEMP_DECISIONS"
else
  fail "TC2" "interactive-review.sh not executable, skipping"
fi

# TC3: [B] Reject decision records to decisions file
if [[ -x "$IR_SCRIPT" ]]; then
  TEMP_DECISIONS=$(mktemp /tmp/qg-test-XXXXXX.md)
  cat > "$TEMP_DECISIONS" << 'HEADER'
# Quality Gate Decisions

| Date | Story | Finding | Severity | Decision | Rationale | Sprint |
|------|-------|---------|----------|----------|-----------|--------|
HEADER

  "$IR_SCRIPT" --story "#701" --finding "XSS via template" --severity "CRITICAL" \
    --decision "B" --rationale "Must fix" \
    --decisions-file "$TEMP_DECISIONS" --sprint "159" 2>&1

  if grep -q "Reject" "$TEMP_DECISIONS" && grep -q "#701" "$TEMP_DECISIONS"; then
    pass "TC3: [B] Reject decision recorded correctly"
  else
    fail "TC3" "Reject decision not recorded in decisions file"
  fi
  rm -f "$TEMP_DECISIONS"
else
  fail "TC3" "interactive-review.sh not executable, skipping"
fi

# TC4: [A] Accept with empty rationale is rejected (non-zero exit)
if [[ -x "$IR_SCRIPT" ]]; then
  TEMP_DECISIONS=$(mktemp /tmp/qg-test-XXXXXX.md)
  cat > "$TEMP_DECISIONS" << 'HEADER'
# Quality Gate Decisions

| Date | Story | Finding | Severity | Decision | Rationale | Sprint |
|------|-------|---------|----------|----------|-----------|--------|
HEADER

  EXIT_CODE=0
  "$IR_SCRIPT" --story "#702" --finding "Race condition" --severity "CRITICAL" \
    --decision "A" --rationale "" \
    --decisions-file "$TEMP_DECISIONS" --sprint "159" 2>&1 || EXIT_CODE=$?

  if [[ $EXIT_CODE -ne 0 ]]; then
    pass "TC4: [A] Accept with empty rationale is rejected (exit non-zero)"
  else
    fail "TC4" "Expected non-zero exit for empty rationale, got 0"
  fi
  rm -f "$TEMP_DECISIONS"
else
  fail "TC4" "interactive-review.sh not executable, skipping"
fi

# TC5: project_level=low auto-selects [B] Reject
if [[ -x "$IR_SCRIPT" ]]; then
  TEMP_DECISIONS=$(mktemp /tmp/qg-test-XXXXXX.md)
  cat > "$TEMP_DECISIONS" << 'HEADER'
# Quality Gate Decisions

| Date | Story | Finding | Severity | Decision | Rationale | Sprint |
|------|-------|---------|----------|----------|-----------|--------|
HEADER

  OUTPUT=$(SHIKIGAMI_PROJECT_LEVEL=low "$IR_SCRIPT" --story "#703" --finding "Memory leak" \
    --severity "CRITICAL" --decisions-file "$TEMP_DECISIONS" --sprint "159" 2>&1)

  if echo "$OUTPUT" | grep -qi "auto.*reject\|project_level=low.*reject\|Reject" && \
     grep -q "Reject" "$TEMP_DECISIONS"; then
    pass "TC5: project_level=low auto-selects [B] Reject"
  else
    fail "TC5" "project_level=low did not auto-reject. Output: $OUTPUT"
  fi
  rm -f "$TEMP_DECISIONS"
else
  fail "TC5" "interactive-review.sh not executable, skipping"
fi

echo ""
if [[ $FAIL_COUNT -eq 0 ]]; then
  echo "=== All interactive review tests PASS ==="
  exit 0
else
  echo "=== ${FAIL_COUNT} test(s) FAILED, ${PASS_COUNT} PASS ==="
  exit 1
fi
