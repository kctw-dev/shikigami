#!/usr/bin/env bash
# scripts/memory-trend-check.sh
# Story #743 — SRE patrol 記憶體使用趨勢偵測（漸進式洩漏告警）
#
# AC2: 若連續 3 次 patrol 記憶體下降 > 10%，輸出 [MEMORY-TREND-WARN]
# AC3: 分析最近 N 條 sre-memory-check 記錄
# NFR1: 純 bash + jq，不依賴外部工具
# NFR2: 分析窗口可配置（預設 5 次 patrol，可透過 --window N 或 MEMORY_TREND_WINDOW 覆蓋）
#
# Usage:
#   bash scripts/memory-trend-check.sh [--log-file <path>] [--window <N>]
#
# Environment:
#   MEMORY_TREND_WINDOW  — 分析窗口（預設 5）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Defaults ─────────────────────────────────────────────────────────────
DEFAULT_LOG_FILE="${REPO_ROOT}/docs/cruise-logs"
WINDOW="${MEMORY_TREND_WINDOW:-5}"
LOG_FILE=""

# ── Argument Parsing ─────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --log-file) LOG_FILE="$2"; shift 2 ;;
    --window)   WINDOW="$2";   shift 2 ;;
    *)          shift ;;
  esac
done

# ── Locate records ────────────────────────────────────────────────────────
# If --log-file passed, read directly from that file.
# Otherwise, scan docs/cruise-logs/ for sre-memory-check entries.
get_memory_records() {
  local window="$1"
  if [[ -n "${LOG_FILE}" ]]; then
    jq -r 'select(.type == "sre-memory-check") | .available_mb' "${LOG_FILE}" 2>/dev/null \
      | tail -"${window}"
  else
    # Scan cruise-logs directory
    local logs_dir="${REPO_ROOT}/docs/cruise-logs"
    if [[ ! -d "$logs_dir" ]]; then
      echo ""
      return
    fi
    # Read all .jsonl files sorted by name, extract sre-memory-check entries
    find "$logs_dir" -name "*.jsonl" | sort | while IFS= read -r f; do
      jq -r 'select(.type == "sre-memory-check") | .available_mb' "$f" 2>/dev/null || true
    done | tail -"${window}"
  fi
}

# ── Trend Analysis ────────────────────────────────────────────────────────
# Returns 1 if consecutive 3 records each drop > 10%, else 0
check_consecutive_drops() {
  local records=("$@")
  local count="${#records[@]}"

  if [[ $count -lt 3 ]]; then
    return 1  # Not enough data
  fi

  # Check last 3 records for consecutive drops > 10%
  local last3=("${records[@]: -3}")
  local r0="${last3[0]}"
  local r1="${last3[1]}"
  local r2="${last3[2]}"

  # Validate numeric
  [[ "$r0" =~ ^[0-9]+(\.[0-9]+)?$ ]] || return 1
  [[ "$r1" =~ ^[0-9]+(\.[0-9]+)?$ ]] || return 1
  [[ "$r2" =~ ^[0-9]+(\.[0-9]+)?$ ]] || return 1

  # Avoid division by zero
  [[ "$r0" == "0" || "$r1" == "0" ]] && return 1

  # Drop 1: from r0 to r1 — must be > 10%
  # drop1_pct = (r0 - r1) / r0 * 100
  local drop1_ok drop2_ok
  drop1_ok=$(echo "$r0 $r1" | awk '{
    if ($1 == 0) { print "no"; exit }
    drop = ($1 - $2) / $1 * 100
    if (drop > 10) print "yes"; else print "no"
  }')

  # Drop 2: from r1 to r2 — must be > 10%
  drop2_ok=$(echo "$r1 $r2" | awk '{
    if ($1 == 0) { print "no"; exit }
    drop = ($1 - $2) / $1 * 100
    if (drop > 10) print "yes"; else print "no"
  }')

  if [[ "$drop1_ok" == "yes" && "$drop2_ok" == "yes" ]]; then
    return 0
  fi
  return 1
}

# ── Main ──────────────────────────────────────────────────────────────────
main() {
  # Collect memory records
  mapfile -t RECORDS < <(get_memory_records "${WINDOW}")

  local count="${#RECORDS[@]}"

  if [[ $count -lt 3 ]]; then
    echo "[MEMORY-TREND-OK] 記錄數量不足（${count} < 3），無法判斷趨勢（需至少 3 筆）"
    return 0
  fi

  if check_consecutive_drops "${RECORDS[@]}"; then
    local last3=("${RECORDS[@]: -3}")
    echo "[MEMORY-TREND-WARN] 偵測到連續記憶體下降趨勢：${last3[0]}MB → ${last3[1]}MB → ${last3[2]}MB（連續 3 次下降 > 10%，疑似記憶體洩漏）"
    return 0
  fi

  local last_mb="${RECORDS[-1]}"
  echo "[MEMORY-TREND-OK] 記憶體趨勢正常（最新：${last_mb}MB，分析 ${count} 筆記錄，窗口=${WINDOW}）"
}

main "$@"
