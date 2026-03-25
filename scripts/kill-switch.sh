#!/usr/bin/env bash
# kill-switch.sh — Shikigami 優雅緊急停止機制
# Usage:
#   kill-switch.sh <session-id>           # Activate kill-switch
#   kill-switch.sh --check <session-id>   # Check if kill-switch is active
#   kill-switch.sh --list <session-id>    # List active worktrees (non-destructive)
#   kill-switch.sh --deactivate <session-id>  # Deactivate kill-switch
set -euo pipefail

MODE="activate"
SESSION_ID=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)       MODE="check";      shift ;;
    --list)        MODE="list";       shift ;;
    --deactivate)  MODE="deactivate"; shift ;;
    --help|-h)
      echo "Usage: kill-switch.sh [--check|--list|--deactivate] <session-id>"
      exit 0
      ;;
    *)
      SESSION_ID="$1"
      shift
      ;;
  esac
done

if [[ -z "$SESSION_ID" ]]; then
  echo "[ERROR] kill-switch.sh requires a session-id argument" >&2
  exit 1
fi

SENTINEL="/tmp/shikigami-kill-${SESSION_ID}.flag"
TIMESTAMP=$(date '+%Y-%m-%dT%H:%M:%S')

case "$MODE" in
  activate)
    if [[ -f "$SENTINEL" ]]; then
      echo "[KILL-SWITCH] already active — sentinel exists: $SENTINEL"
      echo "  Created at: $(cat "$SENTINEL" | head -1)"
      echo "  To deactivate: kill-switch.sh --deactivate $SESSION_ID"
      exit 0
    fi
    echo "timestamp=${TIMESTAMP}" > "$SENTINEL"
    echo "session=${SESSION_ID}" >> "$SENTINEL"
    echo "[KILL-SWITCH-ACTIVATED] Sentinel created: $SENTINEL"
    echo "  Shikigami will stop after completing the current Story unit."
    echo "  In-progress subagent will be allowed to finish its current phase."
    echo "  To deactivate: kill-switch.sh --deactivate $SESSION_ID"
    ;;

  check)
    if [[ -f "$SENTINEL" ]]; then
      echo "[KILL-SWITCH] ACTIVE — sentinel: $SENTINEL"
      cat "$SENTINEL"
      exit 0
    else
      echo "[KILL-SWITCH] INACTIVE — no sentinel found for session: $SESSION_ID"
      exit 0
    fi
    ;;

  list)
    echo "[KILL-SWITCH] Listing active git worktrees (non-destructive report):"
    REPO_ROOT=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null \
      || git rev-parse --show-toplevel 2>/dev/null || echo "unknown")
    git -C "$REPO_ROOT" worktree list 2>/dev/null || echo "  (unable to list worktrees)"
    ;;

  deactivate)
    if [[ -f "$SENTINEL" ]]; then
      rm -f "$SENTINEL"
      echo "[KILL-SWITCH] Deactivated — sentinel removed: $SENTINEL"
    else
      echo "[KILL-SWITCH] No active sentinel found for session: $SESSION_ID"
    fi
    ;;
esac
