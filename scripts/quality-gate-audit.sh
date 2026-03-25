#!/usr/bin/env bash
# quality-gate-audit.sh — #779 AC3
# Reads quality-gate-decisions.md and outputs:
# - Count of Accept/Reject/Defer per severity
# - Pattern detection: same category accepted 3+ times

set -euo pipefail

DECISIONS_FILE="${1:-docs/km/quality-gate-decisions.md}"

if [[ ! -f "$DECISIONS_FILE" ]]; then
  echo "[ERROR] Decisions file not found: $DECISIONS_FILE" >&2
  exit 1
fi

echo "=== Quality Gate Audit Report ==="
echo "Source: $DECISIONS_FILE"
echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Parse table rows (skip header and separator lines)
# Format: | Date | Story | Finding | Severity | Decision | Rationale | Sprint |
ROWS=$(grep '^\|' "$DECISIONS_FILE" | grep -v 'Date.*Story.*Finding\|---' || true)

if [[ -z "$ROWS" ]]; then
  echo "No decision records found."
  exit 0
fi

# Count decisions by severity and decision type
echo "=== Decision Counts by Severity ==="
declare -A COUNTS

while IFS='|' read -r _ date story finding severity decision rationale sprint _; do
  severity=$(echo "$severity" | xargs)
  decision=$(echo "$decision" | xargs)
  [[ -z "$severity" || -z "$decision" ]] && continue
  key="${severity}:${decision}"
  COUNTS["$key"]=$(( ${COUNTS["$key"]:-0} + 1 ))
done <<< "$ROWS"

# Print summary table
printf "%-10s %-8s %s\n" "Severity" "Decision" "Count"
printf "%-10s %-8s %s\n" "--------" "--------" "-----"

for key in $(echo "${!COUNTS[@]}" | tr ' ' '\n' | sort); do
  sev="${key%%:*}"
  dec="${key##*:}"
  printf "%-10s %-8s %d\n" "$sev" "$dec" "${COUNTS[$key]}"
done

echo ""
echo "=== Pattern Detection (3+ Accepts of same category) ==="

# Detect repeated Accept patterns: count CRITICAL Accept occurrences
CRITICAL_ACCEPT=0
while IFS='|' read -r _ date story finding severity decision rationale sprint _; do
  severity=$(echo "$severity" | xargs)
  decision=$(echo "$decision" | xargs)
  if [[ "$severity" == "CRITICAL" && "$decision" == "Accept" ]]; then
    CRITICAL_ACCEPT=$((CRITICAL_ACCEPT + 1))
  fi
done <<< "$ROWS"

if [[ $CRITICAL_ACCEPT -ge 3 ]]; then
  echo "[PATTERN-WARN] CRITICAL Accept 累計 ${CRITICAL_ACCEPT} 次（閾值 3+）— 建議執行系統性安全審查"
else
  echo "[OK] 無重複 Accept 模式（CRITICAL Accept: ${CRITICAL_ACCEPT} 次，閾值 3）"
fi

# Overall stats
TOTAL=$(echo "$ROWS" | grep -c '^\|' || echo 0)
echo ""
echo "=== Summary ==="
echo "Total records: $TOTAL"
echo "CRITICAL Accept (pattern trigger): $CRITICAL_ACCEPT"
