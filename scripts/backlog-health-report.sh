#!/usr/bin/env bash
# backlog-health-report.sh — #736 Backlog 健康趨勢報告腳本
# 掃描最近 N 天 cruise logs，輸出每日 sprint-candidate 計數趨勢
# Usage: backlog-health-report.sh [--last-n <N>] [--log-dir <dir>] [--alert] [--min-candidates <N>]
#
# --alert 模式（#882）：
#   掃描最新一天的 sprint-candidate 計數，若 < MIN_CANDIDATES 則 exit 1
#   用於 GitHub Actions workflow 觸發告警

set -euo pipefail

# Default values
LAST_N=7
LOG_DIR="${REPO_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/docs/cruise-logs"
THRESHOLD=3       # sprint-candidate 告警閾值（trend 報告用）
MIN_CANDIDATES=10 # --alert 模式低水位閾值（#882，預設 10）
ALERT_MODE=false  # --alert 模式開關

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
    --min-candidates)
      MIN_CANDIDATES="$2"
      shift 2
      ;;
    --alert)
      ALERT_MODE=true
      shift
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

# --- Log 格式版本偵測 (#759) ---
# 掃描 JSONL 內部 "type" 欄位存在性，確認格式相容
_SAMPLE_LOGS=()
while IFS= read -r -d '' _f; do
  _SAMPLE_LOGS+=("$_f")
  if [[ ${#_SAMPLE_LOGS[@]} -ge 20 ]]; then
    break
  fi
done < <(find "${LOG_DIR}" -maxdepth 1 -name '*.jsonl' -print0 2>/dev/null)

if [[ ${#_SAMPLE_LOGS[@]} -gt 0 ]]; then
  _COMPATIBLE_COUNT=0
  for _f in "${_SAMPLE_LOGS[@]}"; do
    if grep -q '"type":' "$_f" 2>/dev/null; then
      _COMPATIBLE_COUNT=$((_COMPATIBLE_COUNT + 1))
    fi
  done
  if [[ $_COMPATIBLE_COUNT -eq 0 ]]; then
    echo "[WARN] No compatible cruise log files found (expected JSONL with 'type' field)"
    echo "[WARN] Log format may have changed — statistics may be inaccurate"
  fi
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

# --- --alert 模式（#882）---
# 統計最近 LAST_N 天所有 sprint-candidate（去重），判斷是否低水位
if [[ "$ALERT_MODE" == "true" ]]; then
  echo ""
  echo "[BACKLOG-HEALTH-ALERT] 執行低水位檢查（MIN_CANDIDATES=${MIN_CANDIDATES}）..."

  TOTAL_CANDIDATES=0
  if [[ -d "$LOG_DIR" ]]; then
    for i in $(seq 0 $((LAST_N - 1))); do
      if date -d "${TODAY} -${i} days" '+%Y-%m-%d' &>/dev/null 2>&1; then
        SCAN_DAY=$(date -d "${TODAY} -${i} days" '+%Y-%m-%d')
      else
        SCAN_DAY=$(date -v "-${i}d" '+%Y-%m-%d' 2>/dev/null || echo "")
      fi
      [[ -z "$SCAN_DAY" ]] && continue

      SCAN_LOGS=$(ls "${LOG_DIR}/${SCAN_DAY}-session-"*.jsonl 2>/dev/null || true)
      for LOG_FILE in $SCAN_LOGS; do
        COUNT=$(jq -r 'select(.action == "sprint-candidate") | .issue' "$LOG_FILE" 2>/dev/null \
          | sort -u | wc -l | tr -d ' ')
        TOTAL_CANDIDATES=$((TOTAL_CANDIDATES + COUNT))
      done
    done
  fi

  echo "[BACKLOG-HEALTH-ALERT] 目前 sprint-candidate 數量：${TOTAL_CANDIDATES}"

  if [[ $TOTAL_CANDIDATES -lt $MIN_CANDIDATES ]]; then
    echo "[BACKLOG-HEALTH-ALERT] 低水位觸發！${TOTAL_CANDIDATES} < ${MIN_CANDIDATES}，需補充 Backlog"
    exit 1
  else
    echo "[BACKLOG-HEALTH-ALERT] 水位正常（${TOTAL_CANDIDATES} >= ${MIN_CANDIDATES}）"
    exit 0
  fi
fi
