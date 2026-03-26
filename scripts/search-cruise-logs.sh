#!/usr/bin/env bash
# search-cruise-logs.sh — #731 cruise logs 跨 session 搜尋查詢腳本
# Usage: search-cruise-logs.sh <keyword> [options]
#   --type <type>              按事件類型過濾
#   --date <YYYY-MM-DD|today>  按日期過濾（單日）
#   --since <YYYY-MM-DD>       開始日期（含）
#   --until <YYYY-MM-DD>       結束日期（含）  #842
#   --summary                  輸出各 type 計數統計   #842
#   --log-dir <dir>            自訂 log 目錄
# NFR1: 跨平台（Linux / macOS / WSL2），純 bash + jq
# NFR2: 執行時間 < 2s（掃描 30 天 logs）

set -uo pipefail

KEYWORD=""
FILTER_TYPE=""
FILTER_DATE=""
FILTER_SINCE=""
FILTER_UNTIL=""
SHOW_SUMMARY=false
LOG_DIR="${REPO_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/docs/cruise-logs"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)    FILTER_TYPE="$2";  shift 2 ;;
    --date)    FILTER_DATE="$2";  shift 2 ;;
    --since)   FILTER_SINCE="$2"; shift 2 ;;
    --until)   FILTER_UNTIL="$2"; shift 2 ;;
    --summary) SHOW_SUMMARY=true; shift ;;
    --log-dir) LOG_DIR="$2";      shift 2 ;;
    -*)        shift ;;
    *)
      if [[ -z "$KEYWORD" ]]; then KEYWORD="$1"; fi
      shift ;;
  esac
done

# Resolve --date today shortcut
if [[ "$FILTER_DATE" == "today" ]]; then
  FILTER_DATE=$(date '+%Y-%m-%d')
fi

# Find log files to search
if [[ -n "$FILTER_DATE" ]]; then
  # Single date: match exact prefix
  LOG_FILES=$(ls "${LOG_DIR}/${FILTER_DATE}-session-"*.jsonl 2>/dev/null || true)
elif [[ -n "$FILTER_SINCE" || -n "$FILTER_UNTIL" ]]; then
  # Date range: pick files whose YYYY-MM-DD prefix is within range
  ALL_FILES=$(ls "${LOG_DIR}/"*.jsonl 2>/dev/null | sort || true)
  LOG_FILES=""
  for F in $ALL_FILES; do
    FNAME=$(basename "$F")
    FDATE="${FNAME:0:10}"  # extract YYYY-MM-DD prefix
    # Compare dates lexicographically (ISO dates sort correctly)
    SINCE_OK=true; UNTIL_OK=true
    [[ -n "$FILTER_SINCE" && "$FDATE" < "$FILTER_SINCE" ]] && SINCE_OK=false
    [[ -n "$FILTER_UNTIL" && "$FDATE" > "$FILTER_UNTIL" ]] && UNTIL_OK=false
    if [[ "$SINCE_OK" == "true" && "$UNTIL_OK" == "true" ]]; then
      LOG_FILES="$LOG_FILES $F"
    fi
  done
  LOG_FILES="${LOG_FILES# }"  # trim leading space
else
  LOG_FILES=$(ls "${LOG_DIR}/"*.jsonl 2>/dev/null | sort -r | head -100 || true)
fi

if [[ -z "$LOG_FILES" ]]; then
  echo "No cruise logs found (date: ${FILTER_DATE:-any}, dir: ${LOG_DIR})"
  [[ "$SHOW_SUMMARY" == "true" ]] && echo "" && echo "=== Summary ===" && echo "(no data)"
  exit 0
fi

# Build jq filter for --type and keyword
JQ_FILTER='.'
if [[ -n "$FILTER_TYPE" ]]; then
  JQ_FILTER="${JQ_FILTER} | select(.type == \"${FILTER_TYPE}\")"
fi
if [[ -n "$KEYWORD" ]]; then
  JQ_FILTER="${JQ_FILTER} | select(tostring | test(\"${KEYWORD}\"; \"i\"))"
fi

TOTAL=0

if [[ "$SHOW_SUMMARY" == "true" ]]; then
  # Summary mode: count per type using jq -s on all concatenated input
  # Use process substitution to avoid slow shell loops
  SUMMARY_DATA=$(cat $LOG_FILES 2>/dev/null | \
    jq -r "${JQ_FILTER} | .type // \"unknown\"" 2>/dev/null | \
    sort | uniq -c | sort -rn || true)
  echo "=== Cruise Log Summary ==="
  if [[ -n "$SUMMARY_DATA" ]]; then
    printf "%-8s %-30s\n" "Count" "Type"
    printf "%-8s %-30s\n" "-----" "----"
    while IFS= read -r LINE; do
      COUNT=$(echo "$LINE" | awk '{print $1}')
      TYPE=$(echo "$LINE" | awk '{print $2}')
      printf "%-8s %-30s\n" "$COUNT" "$TYPE"
      TOTAL=$((TOTAL + COUNT))
    done <<< "$SUMMARY_DATA"
  else
    echo "(no matching events)"
  fi
  echo ""
  echo "Total: ${TOTAL} | type=${FILTER_TYPE:-any} | since=${FILTER_SINCE:-any} | until=${FILTER_UNTIL:-any} | keyword=${KEYWORD:-any}"
else
  # Normal mode: process all files with jq in batch (fast path)
  # cat all files and pipe to jq for batch processing — much faster than shell loop
  OUTPUT=$(cat $LOG_FILES 2>/dev/null | \
    jq -r "${JQ_FILTER} | \"\(.ts // \"?\")  type=\(.type // \"?\")  action=\(.action // \"?\")  issue=\(.issue // \"?\")  \(.detail // \"\")\"" \
    2>/dev/null || true)

  if [[ -n "$OUTPUT" ]]; then
    echo "$OUTPUT"
    TOTAL=$(echo "$OUTPUT" | grep -c "." || true)
  fi

  echo ""
  echo "Found ${TOTAL} result(s) | type=${FILTER_TYPE:-any} | date=${FILTER_DATE:-any} | since=${FILTER_SINCE:-any} | until=${FILTER_UNTIL:-any} | keyword=${KEYWORD:-any}"
fi
