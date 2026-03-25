#!/usr/bin/env bash
# scripts/velocity-report.sh — #825 Sprint Velocity Trend 自動報告
# 讀取 docs/sprints/sprint_*.md，輸出最近 5 Sprint velocity 表格與滾動平均
#
# Usage: bash scripts/velocity-report.sh [--sprint-dir <dir>] [--last-n <N>] [--capacity-limit <pts>]
# Output: velocity 表格 + [CAPACITY] 建議容量區間
# NFR1: 腳本無需網路連線（純本地 docs/ 解析）

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPRINT_DIR="${REPO_ROOT}/docs/sprints"
LAST_N=5
CAPACITY_LIMIT=8

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sprint-dir)     SPRINT_DIR="$2"; shift 2 ;;
    --last-n)         LAST_N="$2"; shift 2 ;;
    --capacity-limit) CAPACITY_LIMIT="$2"; shift 2 ;;
    --help)           echo "Usage: $0 [--sprint-dir <dir>] [--last-n <N>] [--capacity-limit <pts>]"; exit 0 ;;
    *) shift ;;
  esac
done

if [[ ! -d "$SPRINT_DIR" ]]; then
  echo "[VELOCITY-WARN] Sprint directory not found: $SPRINT_DIR"
  echo "[CAPACITY] avg_velocity=N/A, recommended_capacity=N/A (no data)"
  exit 0
fi

# Find sprint files and sort by sprint number (descending)
mapfile -t SPRINT_FILES < <(
  ls "$SPRINT_DIR"/sprint_[0-9]*.md 2>/dev/null \
  | sort -t_ -k2 -V \
  | tail -n "$LAST_N"
)

if [[ ${#SPRINT_FILES[@]} -eq 0 ]]; then
  echo "[VELOCITY-WARN] No sprint_*.md files found in: $SPRINT_DIR"
  echo "[CAPACITY] avg_velocity=N/A, recommended_capacity=N/A (no sprint files)"
  exit 0
fi

echo "=== Sprint Velocity Trend（最近 ${#SPRINT_FILES[@]} Sprint）==="
echo ""
echo "| Sprint | Velocity (pts) |"
echo "|--------|---------------|"

TOTAL=0
COUNT=0
declare -a VELOCITIES=()

for FILE in "${SPRINT_FILES[@]}"; do
  SPRINT_NAME=$(basename "$FILE" .md)
  # Extract Total pts from "**Total: N pts**" pattern
  PTS=$(grep -oE '\*\*Total: [0-9]+ pts\*\*' "$FILE" 2>/dev/null | head -1 \
        | grep -oE '[0-9]+' || echo "")
  if [[ -n "$PTS" && "$PTS" =~ ^[0-9]+$ ]]; then
    echo "| ${SPRINT_NAME} | ${PTS} |"
    TOTAL=$((TOTAL + PTS))
    COUNT=$((COUNT + 1))
    VELOCITIES+=("$PTS")
  else
    echo "| ${SPRINT_NAME} | N/A |"
  fi
done

echo ""

if [[ $COUNT -eq 0 ]]; then
  echo "[VELOCITY-WARN] Could not extract velocity from any sprint file"
  echo "[CAPACITY] avg_velocity=N/A, recommended_capacity=N/A"
  exit 0
fi

# Calculate average (integer arithmetic, rounded)
AVG=$(echo "scale=1; $TOTAL / $COUNT" | bc 2>/dev/null || python3 -c "print(round($TOTAL/$COUNT,1))" 2>/dev/null || echo "$((TOTAL / COUNT))")
AVG_INT=$(python3 -c "import math; print(round($TOTAL/$COUNT))" 2>/dev/null || echo "$((TOTAL / COUNT))")

# AC2: Recommended capacity = avg ± 1 pt, max CAPACITY_LIMIT
LOW=$(python3 -c "print(max(1, $AVG_INT - 1))" 2>/dev/null || echo "$((AVG_INT > 1 ? AVG_INT - 1 : 1))")
HIGH=$(python3 -c "print(min($CAPACITY_LIMIT, $AVG_INT + 1))" 2>/dev/null || echo "$((AVG_INT + 1 < CAPACITY_LIMIT ? AVG_INT + 1 : CAPACITY_LIMIT))")

echo "| **平均** | **${AVG} pts** |"
echo "| **建議容量** | **${LOW}-${HIGH} pts** |"
echo ""
echo "[CAPACITY] avg_velocity=${AVG_INT}pts, recommended_capacity=${AVG_INT}pts (±20% range: ${LOW}-${HIGH}pts)"
echo "[CAPACITY-DETAIL] 基於最近 ${COUNT} 個 Sprint（velocities: ${VELOCITIES[*]}）"

exit 0
