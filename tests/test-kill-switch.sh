#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test-helpers.sh" 2>/dev/null || true

assert_contains() {
  local label="$1" haystack="$2" needle="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    echo "[PASS] $label"
  else
    echo "[FAIL] $label — expected '$needle' in output"
    exit 1
  fi
}

assert_file_exists() {
  local label="$1" file="$2"
  if [[ -f "$file" ]]; then
    echo "[PASS] $label"
  else
    echo "[FAIL] $label — file not found: $file"
    exit 1
  fi
}

assert_file_not_exists() {
  local label="$1" file="$2"
  if [[ ! -f "$file" ]]; then
    echo "[PASS] $label"
  else
    echo "[FAIL] $label — file should not exist: $file"
    exit 1
  fi
}

TEST_SESSION="test-session-$$"
SENTINEL="/tmp/shikigami-kill-${TEST_SESSION}.flag"

# Clean up any leftover sentinel
rm -f "$SENTINEL"

echo "=== test-kill-switch.sh ==="

# TC1: kill-switch.sh creates sentinel file
OUTPUT=$(bash "${SCRIPT_DIR}/../scripts/kill-switch.sh" "$TEST_SESSION" 2>&1)
assert_file_exists "TC1: sentinel file created" "$SENTINEL"
assert_contains "TC1: output contains KILL-SWITCH" "$OUTPUT" "KILL-SWITCH"

# TC2: running kill-switch.sh a second time confirms active kill
OUTPUT2=$(bash "${SCRIPT_DIR}/../scripts/kill-switch.sh" "$TEST_SESSION" 2>&1)
assert_contains "TC2: second run confirms active kill" "$OUTPUT2" "already active"

# TC3: check-kill-switch.sh returns ACTIVE when sentinel exists
OUTPUT3=$(bash "${SCRIPT_DIR}/../scripts/kill-switch.sh" --check "$TEST_SESSION" 2>&1)
assert_contains "TC3: check returns ACTIVE" "$OUTPUT3" "ACTIVE"

# TC4: after removing sentinel, check returns INACTIVE
rm -f "$SENTINEL"
OUTPUT4=$(bash "${SCRIPT_DIR}/../scripts/kill-switch.sh" --check "$TEST_SESSION" 2>&1)
assert_contains "TC4: check returns INACTIVE" "$OUTPUT4" "INACTIVE"

# TC5: --list shows worktrees (non-destructive)
OUTPUT5=$(bash "${SCRIPT_DIR}/../scripts/kill-switch.sh" --list "$TEST_SESSION" 2>&1)
assert_contains "TC5: --list output" "$OUTPUT5" "worktree"

echo "=== All kill-switch tests PASS ==="
