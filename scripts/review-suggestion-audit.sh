#!/usr/bin/env bash
# scripts/review-suggestion-audit.sh — Review Suggestions 模式分析
# Story #799 (Sprint 161) | AC3
#
# Usage: bash scripts/review-suggestion-audit.sh [log-file]
# Output: Top recurring suggestions ranked by frequency
# Default log: docs/km/review-suggestions.md

set -u

LOG_FILE="${1:-docs/km/review-suggestions.md}"

if [[ ! -f "$LOG_FILE" ]]; then
  echo "[SUGGESTION-AUDIT-WARN] Log file not found: $LOG_FILE"
  exit 0
fi

echo "# Review Suggestions Audit Report"
echo "# Generated: $(date '+%Y-%m-%dT%H:%M:%S')"
echo "# Source: $LOG_FILE"
echo ""

# Extract suggestion text from table rows (skip header and non-data lines)
# Format: | Date | Story | Suggestion | Type | Status | Sprint |
SUGGESTIONS=$(grep -E '^\| [0-9]{4}-[0-9]{2}-[0-9]{2}' "$LOG_FILE" 2>/dev/null \
  | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $4); print $4}' \
  | sort | uniq -c | sort -rn)

if [[ -z "$SUGGESTIONS" ]]; then
  echo "No suggestions recorded yet."
  exit 0
fi

TOTAL=$(grep -cE '^\| [0-9]{4}-[0-9]{2}-[0-9]{2}' "$LOG_FILE" 2>/dev/null || echo 0)
echo "## Summary"
echo "Total suggestions recorded: $TOTAL"
echo ""
echo "## Top Recurring Suggestions"
echo ""
echo "| Count | Suggestion |"
echo "|-------|------------|"
echo "$SUGGESTIONS" | while read -r count suggestion; do
  echo "| $count | $suggestion |"
done
echo ""

# By Story breakdown
echo "## By Story"
echo ""
grep -E '^\| [0-9]{4}-[0-9]{2}-[0-9]{2}' "$LOG_FILE" 2>/dev/null \
  | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3); print $3}' \
  | sort | uniq -c | sort -rn \
  | while read -r count story; do
    echo "  Story $story: $count suggestion(s)"
  done
