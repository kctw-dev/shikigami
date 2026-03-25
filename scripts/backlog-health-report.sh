#!/usr/bin/env bash
# backlog-health-report.sh — #736 Backlog 健康趨勢報告腳本
# 掃描最近 N 天 cruise logs，輸出每日 sprint-candidate 計數趨勢
# Usage: backlog-health-report.sh [--last-n <N>] [--log-dir <dir>]

set -euo pipefail

# Default values
LAST_N=7
LOG_DIR="${REPO_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/docs/cruise-logs"
THRESHOLD=3  # sprint-candidate 告警閾值

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --last-n)
      LAST_N="$2"
      shift 2
      ;;
    --log-dir)
      LOG_DIR="$2"
      shift 2
      ;;
    --threshold)
      THRESHOLD="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

echo "=== Backlog Health Report（最近 ${LAST_N} 天）==="
echo "Log dir: $LOG_DIR"
echo "Threshold: >= ${THRESHOLD} sprint-candidate"
echo ""

# Check if log dir exists
if [[ ! -d "$LOG_DIR" ]]; then
  echo "[BACKLOG-HEALTH] No cruise logs directory found at: $LOG_DIR"
  exit 0
fi

# Find recent log files (within LAST_N days)
TODAY=$(date '+%Y-%m-%d')
FOUND_DAYS=0

echo "| 日期 | sprint-candidate 計數 | 狀態信號 |"
echo "|------|----------------------|---------|"

for i in $(seq 0 $((LAST_N - 1))); do
  # Calculate date N days ago
  if date -d "${TODAY} -${i} days" '+%Y-%m-%d' &>/dev/null 2>&1; then
    DAY=$(date -d "${TODAY} -${i} days" '+%Y-%m-%d')
  else
    # macOS/BSD date fallback
    DAY=$(date -v "-${i}d" '+%Y-%m-%d' 2>/dev/null || echo "")
  fi

  [[ -z "$DAY" ]] && continue

  # Find log files for this day (using jq to parse JSONL)
  DAY_LOGS=$(ls "${LOG_DIR}/${DAY}-session-"*.jsonl 2>/dev/null || true)

  if [[ -z "$DAY_LOGS" ]]; then
    echo "| ${DAY} | N/A (no logs) | — |"
    continue
  fi

  # Count sprint-candidate actions in logs for this day
  CANDIDATE_COUNT=0
  for LOG_FILE in $DAY_LOGS; do
    COUNT=$(jq -r 'select(.action == "sprint-candidate") | .issue' "$LOG_FILE" 2>/dev/null \
      | sort -u | wc -l | tr -d ' ')
    CANDIDATE_COUNT=$((CANDIDATE_COUNT + COUNT))
  done

  # Determine signal
  if [[ $CANDIDATE_COUNT -ge $THRESHOLD ]]; then
    SIGNAL="OK"
  else
    SIGNAL="TRIGGER"
  fi

  echo "| ${DAY} | ${CANDIDATE_COUNT} | ${SIGNAL} |"
  FOUND_DAYS=$((FOUND_DAYS + 1))
done

echo ""
if [[ $FOUND_DAYS -eq 0 ]]; then
  echo "[BACKLOG-HEALTH] No cruise logs found in the last ${LAST_N} days."
else
  echo "[BACKLOG-HEALTH] 報告完成。TRIGGER 信號表示 sprint-candidate < ${THRESHOLD}，建議補充 Backlog。"
fi
