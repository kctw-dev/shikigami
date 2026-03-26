#!/usr/bin/env bash
# scripts/sprint-goal-stats.sh
# Story #874: Sprint Goal 達成率歷史追蹤
# 掃描 docs/sprints/sprint_*.md，統計每個 Sprint 的目標達成率
#
# Usage:
#   bash scripts/sprint-goal-stats.sh [--last N]
#
# Options:
#   --last N    只顯示最近 N 個 Sprint（預設 10）
#
# Output:
#   表格格式：Sprint | DONE | Total | 達成率 | 狀態
#   末尾顯示連續 100% 最長連續記錄（streak）

set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
SPRINT_DIR="${SPRINT_DIR:-$REPO_ROOT/docs/sprints}"
LAST_N=10

# 解析參數
while [[ $# -gt 0 ]]; do
  case "$1" in
    --last)
      LAST_N="${2:-10}"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# ── 掃描 Sprint 文件 ──────────────────────────────────────────────────────────

declare -a SPRINT_NUMS=()
declare -A SPRINT_DONE=()
declare -A SPRINT_TOTAL=()

for file in "$SPRINT_DIR"/sprint_*.md; do
  [[ -f "$file" ]] || continue
  # 提取 Sprint 編號
  num=$(basename "$file" | grep -oE '[0-9]+' | head -1)
  [[ -z "$num" ]] && continue

  # 計算 DONE 和 Total Story 行數（匹配表格行含 DONE 或其他狀態）
  done_count=$(grep -cE '\|\s*DONE\s*\|?' "$file" 2>/dev/null || echo 0)
  total_count=$(grep -cE '^\s*\|[^|]+\|[^|]+\|\s*(S|M|L)\s*\|' "$file" 2>/dev/null || echo 0)

  # 若無明確 Story 行，嘗試用 DONE 計數推算（確保不除零）
  [[ "$total_count" -eq 0 && "$done_count" -gt 0 ]] && total_count="$done_count"

  SPRINT_NUMS+=("$num")
  SPRINT_DONE["$num"]="$done_count"
  SPRINT_TOTAL["$num"]="${total_count:-0}"
done

# 排序 Sprint 編號（數字升序）
IFS=$'\n' SORTED_NUMS=($(printf '%s\n' "${SPRINT_NUMS[@]:-}" | sort -n))
unset IFS

# 限制最近 N 個
TOTAL_COUNT="${#SORTED_NUMS[@]}"
if [[ "$TOTAL_COUNT" -gt "$LAST_N" ]]; then
  START_IDX=$(( TOTAL_COUNT - LAST_N ))
  SORTED_NUMS=("${SORTED_NUMS[@]:$START_IDX}")
fi

# ── 輸出表格 ──────────────────────────────────────────────────────────────────

printf "%-12s %-6s %-6s %-10s %s\n" "Sprint" "DONE" "Total" "達成率" "狀態"
printf "%-12s %-6s %-6s %-10s %s\n" "------" "----" "-----" "------" "----"

declare -a RATES=()

for num in "${SORTED_NUMS[@]:-}"; do
  [[ -z "$num" ]] && continue
  done="${SPRINT_DONE[$num]:-0}"
  total="${SPRINT_TOTAL[$num]:-0}"

  if [[ "$total" -eq 0 ]]; then
    rate=0
    label="—"
  else
    rate=$(( done * 100 / total ))
    if [[ "$rate" -eq 100 ]]; then
      label="100%"
    elif [[ "$rate" -ge 50 ]]; then
      label="${rate}%（部分）"
    else
      label="${rate}%（未達成）"
    fi
  fi

  printf "| %-10s | %-4s | %-5s | %-9s |\n" "Sprint $num" "$done" "$total" "$label"
  RATES+=("$rate")
done

# ── 連續 100% 最長連續記錄（streak）────────────────────────────────────────────

max_streak=0
cur_streak=0
for rate in "${RATES[@]:-}"; do
  if [[ "$rate" -eq 100 ]]; then
    (( cur_streak++ )) || true
    [[ "$cur_streak" -gt "$max_streak" ]] && max_streak="$cur_streak"
  else
    cur_streak=0
  fi
done

echo ""
echo "連續 100% 最長 streak：${max_streak} 個 Sprint"
