#!/usr/bin/env bash
# scripts/shoot-stats.sh
# Shoot Log 統計工具 — 成功率/吞吐量/趨勢分析
# Issue #849, Sprint 167
# AC1: 從 docs/km/shoot-log/ 目錄解析統計
# AC2: 輸出：總筆數、PASS/FAIL 比例、每日/每週吞吐量
# AC3: 支援 --since YYYY-MM-DD 時間範圍篩選
# AC4: 新增對應測試
# NFR1: 處理 100 個 session 檔案在 3 秒內完成

set -uo pipefail

SHOOT_LOG_DIR="${SHOOT_LOG_DIR:-docs/km/shoot-log}"
SINCE_DATE=""

# 解析參數
while [[ $# -gt 0 ]]; do
  case "$1" in
    --since)
      SINCE_DATE="${2:-}"
      shift 2
      ;;
    --dir)
      SHOOT_LOG_DIR="${2:-docs/km/shoot-log}"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--since YYYY-MM-DD] [--dir <shoot-log-dir>]"
      echo ""
      echo "Options:"
      echo "  --since YYYY-MM-DD  只統計此日期之後的紀錄"
      echo "  --dir <path>        指定 shoot-log 目錄（預設 docs/km/shoot-log）"
      exit 0
      ;;
    *)
      echo "[ERROR] 未知參數: $1" >&2
      exit 1
      ;;
  esac
done

if [[ ! -d "$SHOOT_LOG_DIR" ]]; then
  echo "[ERROR] Shoot log 目錄不存在: $SHOOT_LOG_DIR" >&2
  exit 1
fi

# 收集所有 shoot log 條目
# 格式：| 日期 | 來源 | 標題 | 結果 | commit |
# 跳過標題行（含 "日期" 的行）

TOTAL=0
PASS_COUNT=0
FAIL_COUNT=0
declare -A DAILY_COUNT
declare -A WEEKLY_COUNT

while IFS= read -r line; do
  # 跳過非資料行
  [[ "$line" =~ ^\|[[:space:]]日期 ]] && continue
  [[ "$line" =~ ^#[[:space:]] ]] && continue
  [[ -z "$line" ]] && continue

  # 解析 Markdown 表格行
  if [[ "$line" =~ ^\|[[:space:]]*([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
    DATE="${BASH_REMATCH[1]}"

    # --since 篩選
    if [[ -n "$SINCE_DATE" && "$DATE" < "$SINCE_DATE" ]]; then
      continue
    fi

    # 判斷 PASS/FAIL
    RESULT=$(echo "$line" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $5); print $5}')

    TOTAL=$((TOTAL + 1))
    if echo "$RESULT" | grep -qi "PASS"; then
      PASS_COUNT=$((PASS_COUNT + 1))
    elif echo "$RESULT" | grep -qi "FAIL"; then
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    # 每日計數
    DAILY_COUNT["$DATE"]=$(( ${DAILY_COUNT["$DATE"]:-0} + 1 ))

    # 每週計數（用 ISO 週號 YYYY-WNN）
    if command -v date > /dev/null 2>&1; then
      WEEK=$(date -d "$DATE" +"%Y-W%V" 2>/dev/null || echo "${DATE:0:7}")
    else
      WEEK="${DATE:0:7}"
    fi
    WEEKLY_COUNT["$WEEK"]=$(( ${WEEKLY_COUNT["$WEEK"]:-0} + 1 ))
  fi
done < <(cat "$SHOOT_LOG_DIR"/*.md 2>/dev/null || true)

# 計算比例
if [[ "$TOTAL" -gt 0 ]]; then
  PASS_PCT=$(( PASS_COUNT * 100 / TOTAL ))
  FAIL_PCT=$(( FAIL_COUNT * 100 / TOTAL ))
  OTHER_COUNT=$(( TOTAL - PASS_COUNT - FAIL_COUNT ))
  OTHER_PCT=$(( OTHER_COUNT * 100 / TOTAL ))
else
  PASS_PCT=0
  FAIL_PCT=0
  OTHER_COUNT=0
  OTHER_PCT=0
fi

# 輸出報告
echo "# Shoot Log 統計報告"
if [[ -n "$SINCE_DATE" ]]; then
  echo "> 時間範圍：${SINCE_DATE} 至今"
fi
echo ""
echo "## 總覽"
echo ""
echo "| 指標 | 數值 |"
echo "|------|------|"
echo "| 總筆數 | ${TOTAL} |"
echo "| PASS | ${PASS_COUNT}（${PASS_PCT}%）|"
echo "| FAIL | ${FAIL_COUNT}（${FAIL_PCT}%）|"
echo "| 其他 | ${OTHER_COUNT}（${OTHER_PCT}%）|"

if [[ "$TOTAL" -eq 0 ]]; then
  echo ""
  echo "> 無符合條件的 Shoot Log 紀錄。"
  exit 0
fi

echo ""
echo "## 每日吞吐量（最近 7 天）"
echo ""
echo "| 日期 | 筆數 |"
echo "|------|------|"

# 排序日期（最近優先），顯示最近 7 天
SORTED_DATES=$(for d in "${!DAILY_COUNT[@]}"; do echo "$d"; done | sort -r | head -7)
for DATE in $SORTED_DATES; do
  echo "| ${DATE} | ${DAILY_COUNT[$DATE]} |"
done

echo ""
echo "## 每週吞吐量（最近 4 週）"
echo ""
echo "| 週次 | 筆數 |"
echo "|------|------|"

SORTED_WEEKS=$(for w in "${!WEEKLY_COUNT[@]}"; do echo "$w"; done | sort -r | head -4)
for WEEK in $SORTED_WEEKS; do
  echo "| ${WEEK} | ${WEEKLY_COUNT[$WEEK]} |"
done
