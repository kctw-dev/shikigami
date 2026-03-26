#!/usr/bin/env bash
# tests/test-injection-scan-unit.sh — injection-scan.sh unit test suite
# Story #870 (Sprint 168)
#
# Unit tests for injection-scan.sh covering:
# - PASS mode: normal story body (exit 0)
# - WARN mode: suspicious but non-blocking patterns (exit 1)
# - BLOCK mode: high-risk injection patterns (exit 2)
#
# Usage: bash tests/test-injection-scan-unit.sh
# Exit: 0 if all tests pass, 1 if any test fails

set -u

SCRIPT="$(dirname "$0")/../scripts/injection-scan.sh"
FIXTURE_DIR="$(dirname "$0")/fixtures/injection-scan-unit"

PASS_COUNT=0
FAIL_COUNT=0
START_TIME=$(date +%s)

# ── Helper function ──
run_test() {
  local name="$1"
  local fixture_file="$2"
  local expected_result="$3"
  local expected_exit="$4"

  if [[ ! -f "$fixture_file" ]]; then
    echo "FAIL: $name (fixture not found: $fixture_file)"
    FAIL_COUNT=$((FAIL_COUNT+1))
    return 1
  fi

  # Run injection-scan.sh and capture both output and exit code
  local output
  local exit_code
  output=$(bash "$SCRIPT" "$fixture_file" 2>&1) || exit_code=$?
  exit_code=${exit_code:-0}

  # Extract result (last line)
  local result
  result=$(echo "$output" | tail -1)

  # Verify result and exit code
  if [[ "$result" == "$expected_result" ]] && [[ "$exit_code" == "$expected_exit" ]]; then
    echo "PASS: $name (result=$result exit=$exit_code)"
    PASS_COUNT=$((PASS_COUNT+1))
    return 0
  else
    echo "FAIL: $name"
    echo "  Expected: result=$expected_result exit=$expected_exit"
    echo "  Got:      result=$result exit=$exit_code"
    echo "  Output: $output"
    FAIL_COUNT=$((FAIL_COUNT+1))
    return 1
  fi
}

# ── AC1: Test PASS mode ──
echo "=== AC1: PASS Mode (Normal Story Body) ==="
run_test "PASS: normal-story.txt" \
  "$FIXTURE_DIR/normal-story.txt" \
  "PASS" \
  "0"

# ── AC2: Test WARN mode ──
echo ""
echo "=== AC2: WARN Mode (Suspicious Patterns) ==="
run_test "WARN: suspicious-story.txt" \
  "$FIXTURE_DIR/suspicious-story.txt" \
  "WARN" \
  "1"

# ── AC3: Test BLOCK mode ──
echo ""
echo "=== AC3: BLOCK Mode (High-Risk Injection) ==="
run_test "BLOCK: malicious-story.txt" \
  "$FIXTURE_DIR/malicious-story.txt" \
  "BLOCK" \
  "2"

# ── AC4: Additional edge cases ──
echo ""
echo "=== AC4: Additional Edge Cases ==="

# Create temp fixture for empty file
tmpfile=$(mktemp)
trap "rm -f '$tmpfile'" EXIT
echo "" > "$tmpfile"
run_test "PASS: empty file" "$tmpfile" "PASS" "0"

# ── AC5: Performance check ──
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
echo ""
echo "=== AC5: Performance (NFR1: < 5s) ==="
echo "Total execution time: ${DURATION}s"
if [[ $DURATION -lt 5 ]]; then
  echo "PASS: execution time acceptable"
else
  echo "FAIL: execution time exceeded 5s limit"
  FAIL_COUNT=$((FAIL_COUNT+1))
fi

# ── Summary ──
echo ""
echo "========================================="
TOTAL=$((PASS_COUNT + FAIL_COUNT))
echo "Test Results: PASS=$PASS_COUNT FAIL=$FAIL_COUNT Total=$TOTAL"
echo "========================================="

# Exit with appropriate code
if [[ $FAIL_COUNT -eq 0 ]]; then
  exit 0
else
  exit 1
fi
