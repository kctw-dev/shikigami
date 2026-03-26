#!/usr/bin/env bash
# scripts/complexity-trend.sh — #848 複雜度趨勢追蹤
# 將每次 measure-complexity.sh 量測結果 append 至 docs/km/complexity-trend.csv
#
# Usage:
#   bash scripts/complexity-trend.sh              # 量測並 append，輸出趨勢
#   bash scripts/complexity-trend.sh --no-trend   # 只 append，不輸出趨勢
#   bash scripts/complexity-trend.sh --trend-only # 只顯示趨勢（不量測）
#
# 環境變數覆蓋：
#   COMPLEXITY_TREND_CSV  — 覆蓋 CSV 路徑（測試用）
#   REPO_ROOT             — 覆蓋 repo 根目錄（測試用）
#
# NFR1: CSV 可被 Sprint Review 直接引用

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
CSV_PATH="${COMPLEXITY_TREND_CSV:-$REPO_ROOT/docs/km/complexity-trend.csv}"
MEASURE_SCRIPT="$REPO_ROOT/scripts/measure-complexity.sh"

NO_TREND=false
TREND_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-trend)   NO_TREND=true;   shift ;;
    --trend-only) TREND_ONLY=true; shift ;;
    *) shift ;;
  esac
done

# ── 建立 CSV（若不存在）──────────────────────────────────────────────
ensure_csv_header() {
  mkdir -p "$(dirname "$CSV_PATH")" 2>/dev/null || true
  # 建立或修復：若檔案不存在、或為空、或 header 不正確則寫入 header
  if [[ ! -f "$CSV_PATH" ]] || ! grep -q "^date,SKILL_COUNT" "$CSV_PATH" 2>/dev/null; then
    echo "date,SKILL_COUNT,AGENT_COUNT,HOOK_COUNT,TOTAL_LINES" > "$CSV_PATH"
  fi
}

# ── 量測當前值 ────────────────────────────────────────────────────────
measure_current() {
  if [[ ! -f "$MEASURE_SCRIPT" ]]; then
    echo "WARN: measure-complexity.sh not found, using fallback" >&2
    SKILL_COUNT=$(find "$REPO_ROOT/skills" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    AGENT_COUNT=$(find "$REPO_ROOT/agents" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    HOOK_COUNT=$(find "$REPO_ROOT/hooks" -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')
    TOTAL_LINES=$(find "$REPO_ROOT" -name "*.md" -o -name "*.sh" -o -name "*.json" -o -name "*.yaml" 2>/dev/null \
      | grep -v ".claude/worktrees" | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
  else
    OUTPUT=$(bash "$MEASURE_SCRIPT" 2>/dev/null || true)
    SKILL_COUNT=$(echo "$OUTPUT" | grep -oP 'SKILL_COUNT\s+\K\d+' | head -1 || echo "0")
    AGENT_COUNT=$(echo "$OUTPUT" | grep -oP 'AGENT_COUNT\s+\K\d+' | head -1 || echo "0")
    HOOK_COUNT=$(echo "$OUTPUT"  | grep -oP 'HOOK_COUNT\s+\K\d+' | head -1 || echo "0")
    TOTAL_LINES=$(echo "$OUTPUT" | grep -oP 'TOTAL_LINES\s+\K\d+' | head -1 || echo "0")
  fi
  TODAY=$(date '+%Y-%m-%d')
}

# ── Append（冪等：同日期只寫一次）───────────────────────────────────
append_snapshot() {
  ensure_csv_header
  measure_current
  # 冪等檢查：若今日資料已存在，跳過
  if grep -q "^${TODAY}," "$CSV_PATH" 2>/dev/null; then
    echo "[COMPLEXITY-TREND] 今日快照已存在（${TODAY}），跳過追加"
    return 0
  fi
  echo "${TODAY},${SKILL_COUNT},${AGENT_COUNT},${HOOK_COUNT},${TOTAL_LINES}" >> "$CSV_PATH"
  echo "[COMPLEXITY-TREND] 追加快照：${TODAY} SKILL=${SKILL_COUNT} AGENT=${AGENT_COUNT} HOOK=${HOOK_COUNT} LINES=${TOTAL_LINES}"
}

# ── 趨勢計算（最近 5 次量測的增減百分比）─────────────────────────────
show_trend() {
  ensure_csv_header
  # 讀取最近 5 筆（不含 header）
  RECENT=$(tail -n +2 "$CSV_PATH" | tail -5)
  LINE_COUNT=$(echo "$RECENT" | grep -c "^[0-9]" || true)
  if [[ "$LINE_COUNT" -lt 2 ]]; then
    echo "[COMPLEXITY-TREND] 歷史資料不足（需 >= 2 筆），無法計算趨勢（目前 ${LINE_COUNT} 筆）"
    return 0
  fi

  echo ""
  echo "=== Complexity Trend（最近 ${LINE_COUNT} 次量測）==="
  echo ""

  # 取第一筆與最後一筆做整體趨勢
  FIRST=$(echo "$RECENT" | head -1)
  LAST=$(echo "$RECENT" | tail -1)

  F_DATE=$(echo "$FIRST" | cut -d',' -f1)
  L_DATE=$(echo "$LAST" | cut -d',' -f1)

  F_SKILL=$(echo "$FIRST" | cut -d',' -f2)
  L_SKILL=$(echo "$LAST" | cut -d',' -f2)
  F_AGENT=$(echo "$FIRST" | cut -d',' -f3)
  L_AGENT=$(echo "$LAST" | cut -d',' -f3)
  F_HOOK=$(echo "$FIRST" | cut -d',' -f4)
  L_HOOK=$(echo "$LAST" | cut -d',' -f4)
  F_LINES=$(echo "$FIRST" | cut -d',' -f5)
  L_LINES=$(echo "$LAST" | cut -d',' -f5)

  # 計算百分比變化（整數近似）
  pct_change() {
    local old="$1" new="$2"
    if [[ "$old" -eq 0 ]]; then echo "N/A"; return; fi
    local diff=$(( new - old ))
    local pct=$(( (diff * 100) / old ))
    if [[ "$diff" -gt 0 ]]; then
      echo "+${pct}%"
    elif [[ "$diff" -lt 0 ]]; then
      echo "${pct}%"
    else
      echo "0%"
    fi
  }

  echo "期間：${F_DATE} → ${L_DATE}"
  echo ""
  printf "%-15s %8s %8s %8s\n" "指標" "起始值" "最新值" "變化%"
  printf "%-15s %8s %8s %8s\n" "SKILL_COUNT" "$F_SKILL" "$L_SKILL" "$(pct_change "$F_SKILL" "$L_SKILL")"
  printf "%-15s %8s %8s %8s\n" "AGENT_COUNT" "$F_AGENT" "$L_AGENT" "$(pct_change "$F_AGENT" "$L_AGENT")"
  printf "%-15s %8s %8s %8s\n" "HOOK_COUNT"  "$F_HOOK"  "$L_HOOK"  "$(pct_change "$F_HOOK"  "$L_HOOK")"
  printf "%-15s %8s %8s %8s\n" "TOTAL_LINES" "$F_LINES" "$L_LINES" "$(pct_change "$F_LINES" "$L_LINES")"

  # 預警：TOTAL_LINES 增速 > 20%
  if [[ "$F_LINES" -gt 0 ]]; then
    LINES_PCT=$(( ((L_LINES - F_LINES) * 100) / F_LINES ))
    if [[ "$LINES_PCT" -gt 20 ]]; then
      echo ""
      echo "[COMPLEXITY-WARN] TOTAL_LINES 增速 ${LINES_PCT}% 超過 20% 閾值，建議評估複雜度預算"
    fi
  fi
  echo ""
  echo "CSV: $CSV_PATH"
}

# ── 主流程 ────────────────────────────────────────────────────────────
if [[ "$TREND_ONLY" == "true" ]]; then
  show_trend
else
  append_snapshot
  if [[ "$NO_TREND" != "true" ]]; then
    show_trend
  fi
fi
