#!/usr/bin/env bash
# interactive-review.sh — #773 AC1, AC2, AC3
# CRITICAL quality-gate interactive decision point
# Usage:
#   interactive-review.sh --story "#N" --finding "summary" --severity "CRITICAL" \
#     [--decision "A|B|C"] [--rationale "text"] [--decisions-file "path"] [--sprint "N"]
#
# Decision options:
#   A = Accept Risk (requires non-empty rationale)
#   B = Reject & Fix
#   C = Defer to Next Sprint
#
# project_level=low auto-selects B (Reject) without prompt

set -euo pipefail

STORY=""
FINDING=""
SEVERITY="CRITICAL"
DECISION=""
RATIONALE=""
DECISIONS_FILE="docs/km/quality-gate-decisions.md"
SPRINT=""

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --story)       STORY="$2";          shift 2 ;;
    --finding)     FINDING="$2";        shift 2 ;;
    --severity)    SEVERITY="$2";       shift 2 ;;
    --decision)    DECISION="$2";       shift 2 ;;
    --rationale)   RATIONALE="$2";      shift 2 ;;
    --decisions-file) DECISIONS_FILE="$2"; shift 2 ;;
    --sprint)      SPRINT="$2";         shift 2 ;;
    *) echo "[ERROR] Unknown argument: $1" >&2; exit 1 ;;
  esac
done

# Validate required
if [[ -z "$STORY" || -z "$FINDING" ]]; then
  echo "[ERROR] --story and --finding are required" >&2
  exit 1
fi

if [[ -z "$SPRINT" ]]; then
  SPRINT=$(date '+%Y')
fi

# project_level=low: auto-select B (Reject)
PROJECT_LEVEL="${SHIKIGAMI_PROJECT_LEVEL:-}"
if [[ "$PROJECT_LEVEL" == "low" && -z "$DECISION" ]]; then
  echo "[INTERACTIVE-REVIEW] project_level=low — auto-selecting [B] Reject (unattended risk acceptance prohibited)"
  DECISION="B"
  RATIONALE="Auto-rejected by project_level=low policy"
fi

# If decision not provided, output prompt and exit (for human-driven mode)
if [[ -z "$DECISION" ]]; then
  echo ""
  echo "=== [CRITICAL] Quality Gate Interactive Decision Point ==="
  echo "Story    : $STORY"
  echo "Finding  : $FINDING"
  echo "Severity : $SEVERITY"
  echo ""
  echo "Choose a decision:"
  echo "  [A] Accept Risk + Reason"
  echo "  [B] Reject & Fix (recommended)"
  echo "  [C] Defer to Next Sprint"
  echo ""
  echo "Provide decision via --decision A|B|C and --rationale <text>"
  exit 0
fi

# Normalize decision
DECISION=$(echo "$DECISION" | tr '[:lower:]' '[:upper:]')

# Validate decision value
if [[ "$DECISION" != "A" && "$DECISION" != "B" && "$DECISION" != "C" ]]; then
  echo "[ERROR] Decision must be A, B, or C. Got: $DECISION" >&2
  exit 1
fi

# AC3: Accept requires non-empty rationale
if [[ "$DECISION" == "A" && -z "$RATIONALE" ]]; then
  echo "[ERROR] Decision [A] Accept Risk requires a non-empty --rationale" >&2
  exit 1
fi

# Map decision letter to label
case "$DECISION" in
  A) DECISION_LABEL="Accept" ;;
  B) DECISION_LABEL="Reject" ;;
  C) DECISION_LABEL="Defer" ;;
esac

if [[ -z "$RATIONALE" ]]; then
  RATIONALE="(no rationale provided)"
fi

DATE=$(date '+%Y-%m-%d')

# Ensure decisions file exists (append-only, never truncated)
if [[ ! -f "$DECISIONS_FILE" ]]; then
  echo "[WARN] decisions file not found: $DECISIONS_FILE — creating" >&2
  mkdir -p "$(dirname "$DECISIONS_FILE")"
  printf '%s\n' "# Quality Gate Decisions" "" "| Date | Story | Finding | Severity | Decision | Rationale | Sprint |" "|------|-------|---------|----------|----------|-----------|--------|" > "$DECISIONS_FILE"
fi

# AC2: Append record (never overwrite)
printf '| %s | %s | %s | %s | %s | %s | %s |\n' \
  "$DATE" "$STORY" "$FINDING" "$SEVERITY" "$DECISION_LABEL" "$RATIONALE" "$SPRINT" \
  >> "$DECISIONS_FILE"

echo "[INTERACTIVE-REVIEW] Decision recorded: $STORY → $DECISION_LABEL ($SEVERITY)"
echo "  Finding  : $FINDING"
echo "  Rationale: $RATIONALE"
echo "  Sprint   : $SPRINT"
echo "  File     : $DECISIONS_FILE"
