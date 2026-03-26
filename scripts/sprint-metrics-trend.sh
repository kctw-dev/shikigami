#!/usr/bin/env bash
# scripts/sprint-metrics-trend.sh
# Story #869: Sprint Metrics 歷史趨勢儀表板
# 掃描 docs/km/metrics-log/*.md，輸出多 Sprint Velocity/Completion/SPACE 趨勢
#
# Usage:
#   bash scripts/sprint-metrics-trend.sh [--last N]

set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
METRICS_DIR="${METRICS_DIR:-$REPO_ROOT/docs/km/metrics-log}"
LAST_N=5

while [[ $# -gt 0 ]]; do
  case "$1" in
    --last) LAST_N="${2:-5}"; shift 2 ;;
    *) shift ;;
  esac
done

# ── 掃描 metrics-log 檔案 ────────────────────────────────────────────────────

declare -a SPRINT_NUMS=()
declare -A SPRINT_VEL=()
declare -A SPRINT_COMP=()
declare -A SPRINT_SPACE=()
declare -A SEEN_SPRINTS=()

shopt -s nullglob
for file in "$METRICS_DIR"/*.md; do
  [[ -f "$file" ]] || continue

  sprint_num=$(grep -oE '(Sprint|sprint)[[:space:]]+([0-9]+)' "$file" 2>/dev/null | grep -oE '[0-9]+' | head -1 || true)
  [[ -z "$sprint_num" ]] && continue
  # Skip duplicates — keep first occurrence (oldest file)
  [[ -n "${SEEN_SPRINTS[$sprint_num]:-}" ]] && continue
  SEEN_SPRINTS["$sprint_num"]=1

  velocity=$(grep -iE 'velocity[[:space:]]*\|[[:space:]]*[0-9]' "$file" 2>/dev/null | grep -oE '[0-9]+[[:space:]]*pts' | grep -oE '^[0-9]+' | head -1 || true)
  [[ -z "$velocity" ]] && velocity=$(grep -iE 'velocity.*[0-9]+[[:space:]]*pts' "$file" 2>/dev/null | grep -oE '[0-9]+[[:space:]]*pts' | grep -oE '^[0-9]+' | head -1 || true)

  completion=$(grep -iE '完成率|completion.rate' "$file" 2>/dev/null | grep -oE '[0-9]+%' | head -1 | tr -d '%' || true)

  space=$(grep -iE 'overall[[:space:]]*\|[[:space:]]*[0-9]' "$file" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1 || true)
  [[ -z "$space" ]] && space=$(grep -iE 'space' "$file" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1 || true)

  SPRINT_NUMS+=("$sprint_num")
  SPRINT_VEL["$sprint_num"]="${velocity:-}"
  SPRINT_COMP["$sprint_num"]="${completion:-}"
  SPRINT_SPACE["$sprint_num"]="${space:-}"
done
shopt -u nullglob

# 排序
if [[ "${#SPRINT_NUMS[@]}" -eq 0 ]]; then
  echo "（無 metrics-log 資料）"
  exit 0
fi

IFS=$'\n' SORTED_NUMS=($(printf '%s\n' "${SPRINT_NUMS[@]}" | sort -n))
unset IFS

# 限制最近 N 個
TOTAL="${#SORTED_NUMS[@]}"
if [[ "$TOTAL" -gt "$LAST_N" ]]; then
  START=$(( TOTAL - LAST_N ))
  SORTED_NUMS=("${SORTED_NUMS[@]:$START}")
fi

# ── 輸出趨勢表 ───────────────────────────────────────────────────────────────

printf "%-10s %-10s %-12s %-8s %s\n" "Sprint" "Velocity" "Completion" "SPACE" "Trend"
printf "%-10s %-10s %-12s %-8s %s\n" "------" "--------" "----------" "-----" "-----"

PREV_VEL=""

for num in "${SORTED_NUMS[@]}"; do
  [[ -z "$num" ]] && continue
  vel="${SPRINT_VEL[$num]:-}"
  comp="${SPRINT_COMP[$num]:-}"
  space="${SPRINT_SPACE[$num]:-}"

  # 計算趨勢（僅在兩者都為數字時比較）
  trend=""
  if [[ -n "$vel" && -n "$PREV_VEL" ]] && \
     [[ "$vel" =~ ^[0-9]+$ ]] && [[ "$PREV_VEL" =~ ^[0-9]+$ ]]; then
    if (( vel > PREV_VEL )); then
      trend="[TREND-UP]"
    elif (( vel < PREV_VEL )); then
      trend="[TREND-DOWN]"
    else
      trend="[TREND-STABLE]"
    fi
  fi

  vel_display="${vel:+${vel}pts}"
  comp_display="${comp:+${comp}%}"

  printf "| %-8s | %-8s | %-10s | %-6s | %s\n" \
    "Sprint $num" "${vel_display:---}" "${comp_display:---}" "${space:---}" "$trend"

  [[ -n "$vel" ]] && PREV_VEL="$vel" || true
done

echo ""
echo "（顯示最近 ${#SORTED_NUMS[@]} 個 Sprint；--last N 可調整）"
