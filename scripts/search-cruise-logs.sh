#!/usr/bin/env bash
# search-cruise-logs.sh — #731 cruise logs 跨 session 搜尋查詢腳本
# Usage: search-cruise-logs.sh <keyword> [--type <type>] [--date <YYYY-MM-DD|today>] [--log-dir <dir>]
# NFR1: 跨平台（Linux / macOS / WSL2），純 bash + jq
# NFR2: 執行時間 < 2s（掃描 30 天 logs）

set -euo pipefail

KEYWORD=""
FILTER_TYPE=""
FILTER_DATE=""
LOG_DIR="${REPO_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/docs/cruise-logs"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      FILTER_TYPE="$2"
      shift 2
      ;;
    --date)
      FILTER_DATE="$2"
      shift 2
      ;;
    --log-dir)
      LOG_DIR="$2"
      shift 2
      ;;
    -*)
      shift
      ;;
    *)
      if [[ -z "$KEYWORD" ]]; then
        KEYWORD="$1"
      fi
      shift
      ;;
  esac
done

# Resolve --date today shortcut
if [[ "$FILTER_DATE" == "today" ]]; then
  FILTER_DATE=$(date '+%Y-%m-%d')
fi

# Build jq filter
JQ_FILTER='.'
if [[ -n "$FILTER_TYPE" ]]; then
  JQ_FILTER="${JQ_FILTER} | select(.type == \"${FILTER_TYPE}\")"
fi
if [[ -n "$KEYWORD" ]]; then
  JQ_FILTER="${JQ_FILTER} | select(tostring | test(\"${KEYWORD}\"; \"i\"))"
fi

# Find log files to search
if [[ -n "$FILTER_DATE" ]]; then
  LOG_FILES=$(ls "${LOG_DIR}/${FILTER_DATE}-session-"*.jsonl 2>/dev/null || true)
else
  LOG_FILES=$(ls "${LOG_DIR}/"*.jsonl 2>/dev/null | sort -r | head -100 || true)
fi

if [[ -z "$LOG_FILES" ]]; then
  echo "No cruise logs found (date: ${FILTER_DATE:-any}, dir: ${LOG_DIR})"
  exit 0
fi

TOTAL=0

for LOG_FILE in $LOG_FILES; do
  while IFS= read -r LINE; do
    [[ -z "$LINE" ]] && continue
    # Apply jq filter
    MATCHED=$(echo "$LINE" | jq -r "${JQ_FILTER} | \"\(.ts // \"?\")  type=\(.type // \"?\")  action=\(.action // \"?\")  issue=\(.issue // \"?\")  \(.detail // \"\")\"" 2>/dev/null || true)
    if [[ -n "$MATCHED" && "$MATCHED" != "null" ]]; then
      echo "$MATCHED"
      TOTAL=$((TOTAL + 1))
    fi
  done < "$LOG_FILE"
done

echo ""
echo "Found ${TOTAL} result(s) | type=${FILTER_TYPE:-any} | date=${FILTER_DATE:-any} | keyword=${KEYWORD:-any}"
