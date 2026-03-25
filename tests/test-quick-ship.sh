#!/usr/bin/env bash
# test-quick-ship.sh — Quick Ship Pipeline Tests
# Story #798: scripts/quick-ship.sh

set -uo pipefail
PASS=0; FAIL=0

ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

SCRIPT="scripts/quick-ship.sh"
echo "=== Quick Ship Pipeline Tests ==="

# AC1: quick-ship.sh exists and implements pipeline
echo "--- AC1: quick-ship.sh ---"
if [[ -f "$SCRIPT" ]]; then
  ok "quick-ship.sh exists"
  if [[ -x "$SCRIPT" ]]; then
    ok "quick-ship.sh is executable"
  else
    fail "quick-ship.sh not executable"
  fi
  # Check pipeline steps present
  for step in validate test bump commit push; do
    if grep -q "$step" "$SCRIPT"; then
      ok "pipeline step '$step' found"
    else
      fail "pipeline step '$step' missing"
    fi
  done
else
  fail "quick-ship.sh missing"
fi

# AC2: --dry-run mode exists and is safe
echo "--- AC2: Dry-run mode ---"
if [[ -f "$SCRIPT" ]]; then
  if grep -q "dry.run\|dry_run\|DRY_RUN" "$SCRIPT"; then
    ok "--dry-run flag supported"
  else
    fail "--dry-run flag missing"
  fi
  # Run dry-run — must not fail with non-zero exit
  OUTPUT=$(bash "$SCRIPT" --dry-run 2>&1)
  EXIT_CODE=$?
  if [[ $EXIT_CODE -eq 0 ]]; then
    ok "--dry-run exits 0 (safe)"
  else
    fail "--dry-run exits $EXIT_CODE (should be 0)"
  fi
  if echo "$OUTPUT" | grep -qiE "dry.run|DRY-RUN|planned"; then
    ok "--dry-run shows planned steps"
  else
    fail "--dry-run output missing planned steps info"
  fi
fi

# AC3: self-validation
echo "--- AC3: Self-validation ---"
ok "tests/test-quick-ship.sh exists (running now)"

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
