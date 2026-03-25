#!/usr/bin/env bash
# test-watchdog.sh — Session Watchdog Tests
# Story #772 AC4: Validates watchdog-check.sh behavior

set -uo pipefail
PASS=0; FAIL=0

ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

WATCHDOG_SCRIPT="scripts/watchdog-check.sh"
WATCHDOG_DIR="docs/sprints/watchdog"

echo "=== Session Watchdog Tests ==="

# AC3: watchdog-check.sh exists and outputs ALIVE/STALE/MISSING
echo "--- AC3: watchdog-check.sh ---"
if [[ -f "$WATCHDOG_SCRIPT" ]]; then
  ok "watchdog-check.sh exists"
  if [[ -x "$WATCHDOG_SCRIPT" ]]; then
    ok "watchdog-check.sh is executable"
  else
    fail "watchdog-check.sh not executable"
  fi
else
  fail "watchdog-check.sh missing"
fi

# AC1: Test ALIVE status (fresh heartbeat)
echo "--- AC1/AC3: ALIVE status ---"
if [[ -f "$WATCHDOG_SCRIPT" && -d "$WATCHDOG_DIR" ]]; then
  TEST_SESSION="test-watchdog-$$"
  HEARTBEAT_FILE="${WATCHDOG_DIR}/${TEST_SESSION}-heartbeat.json"
  # Write fresh heartbeat
  printf '{"session_id":"%s","timestamp":"%s","status":"active","interval_minutes":5}\n' \
    "$TEST_SESSION" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" > "$HEARTBEAT_FILE"
  OUTPUT=$(bash "$WATCHDOG_SCRIPT" "$TEST_SESSION" 2>/dev/null)
  if echo "$OUTPUT" | grep -q "ALIVE"; then
    ok "ALIVE status for fresh heartbeat"
  else
    fail "Expected ALIVE, got: $OUTPUT"
  fi
  rm -f "$HEARTBEAT_FILE"
fi

# AC4: Test STALE status (old heartbeat)
echo "--- AC4: STALE status ---"
if [[ -f "$WATCHDOG_SCRIPT" && -d "$WATCHDOG_DIR" ]]; then
  TEST_SESSION="test-stale-$$"
  HEARTBEAT_FILE="${WATCHDOG_DIR}/${TEST_SESSION}-heartbeat.json"
  # Write stale heartbeat (2 hours ago)
  STALE_TIME=$(date -u -d '2 hours ago' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null \
    || date -u -v-2H '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null \
    || echo "2000-01-01T00:00:00Z")
  printf '{"session_id":"%s","timestamp":"%s","status":"active","interval_minutes":5}\n' \
    "$TEST_SESSION" "$STALE_TIME" > "$HEARTBEAT_FILE"
  OUTPUT=$(bash "$WATCHDOG_SCRIPT" "$TEST_SESSION" 2>/dev/null)
  if echo "$OUTPUT" | grep -qE "STALE|WATCHDOG-ALERT"; then
    ok "STALE/WATCHDOG-ALERT for stale heartbeat"
  else
    fail "Expected STALE or WATCHDOG-ALERT, got: $OUTPUT"
  fi
  rm -f "$HEARTBEAT_FILE"
fi

# AC4: Test MISSING status (no heartbeat file)
echo "--- AC4: MISSING status ---"
if [[ -f "$WATCHDOG_SCRIPT" ]]; then
  OUTPUT=$(bash "$WATCHDOG_SCRIPT" "nonexistent-session-$$" 2>/dev/null)
  if echo "$OUTPUT" | grep -q "MISSING"; then
    ok "MISSING status for absent heartbeat"
  else
    fail "Expected MISSING, got: $OUTPUT"
  fi
fi

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
