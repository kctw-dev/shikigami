#!/usr/bin/env bash
# watchdog-check.sh — Session Watchdog Status Check
# Story #772 AC3: Reads heartbeat file and outputs ALIVE / STALE / MISSING
# AC2: If no heartbeat update for 2× interval → output [WATCHDOG-ALERT]
# NFR2: Pure bash + date + jq (no external dependencies)
# NFR3: Works across multiple parallel sessions (per-session heartbeat file)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
WATCHDOG_DIR="${REPO_ROOT}/docs/sprints/watchdog"

SESSION_ID="${1:-}"
WRITE_HEARTBEAT="${2:-}"

if [[ -z "$SESSION_ID" ]]; then
  echo "Usage: $0 <session-id> [--write]"
  echo "       $0 <session-id>         # Check status: ALIVE / STALE / MISSING"
  echo "       $0 <session-id> --write # Write/update heartbeat (for active cruise)"
  exit 1
fi

HEARTBEAT_FILE="${WATCHDOG_DIR}/${SESSION_ID}-heartbeat.json"

# --write mode: write/update heartbeat (AC1 — idempotent, NFR1)
if [[ "$WRITE_HEARTBEAT" == "--write" ]]; then
  mkdir -p "$WATCHDOG_DIR"
  INTERVAL="${WATCHDOG_INTERVAL_MINUTES:-5}"
  printf '{"session_id":"%s","timestamp":"%s","status":"active","interval_minutes":%s}\n' \
    "$SESSION_ID" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$INTERVAL" > "$HEARTBEAT_FILE"
  echo "[WATCHDOG-HEARTBEAT] session=$SESSION_ID interval=${INTERVAL}m heartbeat updated"
  exit 0
fi

# Read mode: check status
if [[ ! -f "$HEARTBEAT_FILE" ]]; then
  echo "[WATCHDOG-MISSING] session=$SESSION_ID heartbeat file not found: $HEARTBEAT_FILE"
  exit 0
fi

# Read heartbeat
if command -v jq &>/dev/null; then
  HEARTBEAT_TIME=$(jq -r '.timestamp // empty' "$HEARTBEAT_FILE" 2>/dev/null || echo "")
  INTERVAL_MINUTES=$(jq -r '.interval_minutes // 5' "$HEARTBEAT_FILE" 2>/dev/null || echo "5")
else
  # Fallback: grep for timestamp
  HEARTBEAT_TIME=$(grep -oE '"timestamp":"[^"]+"' "$HEARTBEAT_FILE" 2>/dev/null | cut -d'"' -f4 || echo "")
  INTERVAL_MINUTES=5
fi

if [[ -z "$HEARTBEAT_TIME" ]]; then
  echo "[WATCHDOG-MISSING] session=$SESSION_ID cannot parse timestamp from $HEARTBEAT_FILE"
  exit 0
fi

# Calculate age in seconds
NOW_EPOCH=$(date -u '+%s' 2>/dev/null || date '+%s')
HEARTBEAT_EPOCH=$(date -u -d "$HEARTBEAT_TIME" '+%s' 2>/dev/null \
  || date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$HEARTBEAT_TIME" '+%s' 2>/dev/null \
  || echo "0")

if [[ "$HEARTBEAT_EPOCH" -eq 0 ]]; then
  echo "[WATCHDOG-STALE] session=$SESSION_ID cannot parse timestamp: $HEARTBEAT_TIME"
  exit 0
fi

AGE_SECONDS=$(( NOW_EPOCH - HEARTBEAT_EPOCH ))
THRESHOLD_SECONDS=$(( INTERVAL_MINUTES * 2 * 60 ))  # 2× interval (AC2)
AGE_MINUTES=$(( AGE_SECONDS / 60 ))

if [[ $AGE_SECONDS -le $THRESHOLD_SECONDS ]]; then
  echo "[WATCHDOG-ALIVE] session=$SESSION_ID age=${AGE_MINUTES}m threshold=$((THRESHOLD_SECONDS/60))m status=ALIVE"
else
  # AC2: No update for 2× interval → WATCHDOG-ALERT to cruise log
  echo "[WATCHDOG-STALE] session=$SESSION_ID age=${AGE_MINUTES}m threshold=$((THRESHOLD_SECONDS/60))m"
  echo "[WATCHDOG-ALERT] session=$SESSION_ID has not updated heartbeat for ${AGE_MINUTES} minutes (2× interval = $((THRESHOLD_SECONDS/60))m). Possible silent hang detected."
fi

exit 0
