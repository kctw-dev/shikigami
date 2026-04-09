#!/bin/bash
# Show backlog water level historical trend from JSONL logs
# Usage: ./scripts/show-backlog-water-trend.sh [data_dir]
# If data_dir not provided, defaults to docs/cruise-logs/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="${1:-$SCRIPT_DIR/docs/cruise-logs}"

# Check if directory exists
if [[ ! -d "$DATA_DIR" ]]; then
  echo "Error: Directory $DATA_DIR not found"
  exit 1
fi

# Find all backlog-water-*.jsonl files and process them
declare -A data_by_date

# Collect all data
for jsonl_file in "$DATA_DIR"/backlog-water-*.jsonl; do
  if [[ ! -f "$jsonl_file" ]]; then
    continue
  fi

  while IFS= read -r line; do
    if [[ -z "$line" ]]; then
      continue
    fi

    # Extract timestamp, sprint_candidate_count, and status
    timestamp=$(echo "$line" | jq -r '.timestamp // empty' 2>/dev/null || echo "")
    count=$(echo "$line" | jq -r '.sprint_candidate_count // empty' 2>/dev/null || echo "")
    status=$(echo "$line" | jq -r '.status // empty' 2>/dev/null || echo "")

    if [[ -n "$timestamp" && -n "$count" ]]; then
      # Extract date from ISO 8601 timestamp (YYYY-MM-DD)
      date=$(echo "$timestamp" | cut -d'T' -f1)

      # Store the latest record for each date (use count and status)
      data_by_date["$date"]="$count|$status"
    fi
  done < "$jsonl_file"
done

# Check if we have any data
if [[ ${#data_by_date[@]} -eq 0 ]]; then
  echo "No backlog water level data found in $DATA_DIR"
  exit 0
fi

# Sort dates and display as table
echo "Backlog Water Level Trend"
echo "========================================================================"
printf "%-12s | %-12s | %-10s\n" "Date" "Water Level" "Status"
echo "------------ | ------------ | ----------"

sorted_dates=($(printf '%s\n' "${!data_by_date[@]}" | sort))

# Show last 7 days or all available data
start_idx=$((${#sorted_dates[@]} - 7))
if [[ $start_idx -lt 0 ]]; then
  start_idx=0
fi

for ((i = start_idx; i < ${#sorted_dates[@]}; i++)); do
  date="${sorted_dates[$i]}"
  data="${data_by_date[$date]}"
  count=$(echo "$data" | cut -d'|' -f1)
  status=$(echo "$data" | cut -d'|' -f2)
  printf "%-12s | %-12s | %-10s\n" "$date" "$count" "$status"
done

echo "========================================================================"
echo "Total records: ${#sorted_dates[@]}"
