#!/usr/bin/env bash
# calculate-sprint-capacity.sh — Sprint 容量自動計算（基於 3-Sprint Velocity 平均）
# Sprint 155 | #734
# NFR1: 純 bash 實作，僅允許 jq（若可用）

set -euo pipefail

# ── 參數處理 ──────────────────────────────────────────────────────
METRICS_DIR="docs/km/metrics-log"
MAX_SPRINTS=3

while [[ $# -gt 0 ]]; do
  case "$1" in
    --metrics-dir) METRICS_DIR="$2"; shift ;;
    --max-sprints) MAX_SPRINTS="$2"; shift ;;
    --help)
      echo "Usage: $0 [--metrics-dir DIR] [--max-sprints N]"
      echo "  --metrics-dir DIR  metrics-log 目錄（預設: docs/km/metrics-log）"
      echo "  --max-sprints N    使用最近 N 個 Sprint（預設: 3）"
      exit 0
      ;;
    *) echo "[WARN] 未知參數: $1" ;;
  esac
  shift
done

# ── 確認目錄存在 ──────────────────────────────────────────────────
if [ ! -d "$METRICS_DIR" ]; then
  echo "[CAPACITY-ERROR] metrics-log 目錄不存在: $METRICS_DIR"
  exit 1
fi

# ── 讀取最近 N 個 metrics-log 中的 Velocity ───────────────────────
# 格式：「| Velocity | X pts |」
VELOCITIES=()
FILE_COUNT=0

while IFS= read -r file; do
  # 從 markdown 表格抓取 Velocity pts
  VELOCITY=$(grep -E "\|\s*Velocity\s*\|\s*[0-9]+ pts" "$file" 2>/dev/null | \
    grep -oE "[0-9]+ pts" | head -1 | grep -oE "[0-9]+" || echo "")

  if [ -n "$VELOCITY" ]; then
    VELOCITIES+=("$VELOCITY")
    FILE_COUNT=$((FILE_COUNT+1))
    [ $FILE_COUNT -ge $MAX_SPRINTS ] && break
  fi
done < <(ls -t "$METRICS_DIR"/*.md 2>/dev/null || true)

# ── 檢查歷史數據是否足夠（AC4）────────────────────────────────────
if [ "${#VELOCITIES[@]}" -eq 0 ]; then
  echo "[CAPACITY-ERROR] 無法讀取任何 Velocity 數據，請確認 $METRICS_DIR 格式正確"
  exit 1
fi

if [ "${#VELOCITIES[@]}" -lt "$MAX_SPRINTS" ]; then
  echo "[CAPACITY-WARN] 歷史 metrics-log 不足 ${MAX_SPRINTS} 個（實際: ${#VELOCITIES[@]}），使用現有數量計算"
fi

# ── 計算平均 Velocity ──────────────────────────────────────────────
TOTAL=0
for v in "${VELOCITIES[@]}"; do
  TOTAL=$((TOTAL + v))
done
COUNT="${#VELOCITIES[@]}"
AVG=$((TOTAL / COUNT))

# ── 計算 ±20% 容量範圍 ────────────────────────────────────────────
# 推薦容量 = 平均 Velocity（整數）
RECOMMENDED=$AVG
LOW=$(( RECOMMENDED * 80 / 100 ))   # -20%
HIGH=$(( RECOMMENDED * 120 / 100 )) # +20%

# ── 輸出結果（AC2）───────────────────────────────────────────────
echo "[CAPACITY] avg_velocity=${AVG}pts, recommended_capacity=${RECOMMENDED}pts (±20% range: ${LOW}-${HIGH}pts)"
echo "[CAPACITY-DETAIL] 基於最近 ${COUNT} 個 Sprint（velocities: ${VELOCITIES[*]}）"
