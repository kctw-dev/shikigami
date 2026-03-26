#!/usr/bin/env bash
# scripts/hook-metrics-report.sh
# #941：Hook 執行指標查詢工具
#
# 讀取 .claude/hooks/execution-metrics.jsonl，輸出：
#   (a) 最慢 5 個 Hook（by avg duration_ms）
#   (b) 超時次數排行
#   (c) 失敗率 > 10% 的 Hook
#
# Usage:
#   bash scripts/hook-metrics-report.sh
#   bash scripts/hook-metrics-report.sh --since 2026-03-01
#
# Exit code:
#   0 = 成功（含 metrics 不存在時靜默退出）

set -uo pipefail

# ---------------------------------------------------------------------------
# 參數解析
# ---------------------------------------------------------------------------
SINCE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --since)
      SINCE="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Metrics 檔案路徑（可由環境變數覆蓋，供測試使用）
# ---------------------------------------------------------------------------
METRICS_FILE="${METRICS_FILE:-.claude/hooks/execution-metrics.jsonl}"

# AC4：檔案不存在時靜默退出
if [[ ! -f "$METRICS_FILE" ]]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# 讀取並過濾資料
# ---------------------------------------------------------------------------
if [[ -n "$SINCE" ]]; then
  DATA=$(jq -c --arg since "$SINCE" 'select(.timestamp >= $since)' "$METRICS_FILE" 2>/dev/null)
else
  DATA=$(cat "$METRICS_FILE")
fi

if [[ -z "$DATA" ]]; then
  echo "No metrics data found."
  exit 0
fi

# ---------------------------------------------------------------------------
# (a) 最慢 5 個 Hook（by avg duration_ms）
# ---------------------------------------------------------------------------
echo "## (a) 最慢 5 個 Hook（平均 duration_ms）"
echo ""
echo "| Hook | Avg Duration (ms) | Count |"
echo "|------|-------------------|-------|"
echo "$DATA" | jq -r '[.hook, (.duration_ms | tostring)] | @tsv' 2>/dev/null \
  | awk -F'\t' '{
      sum[$1] += $2
      count[$1] += 1
    }
    END {
      for (h in sum) {
        avg = sum[h] / count[h]
        printf "%s\t%.0f\t%d\n", h, avg, count[h]
      }
    }' \
  | sort -t$'\t' -k2 -rn \
  | head -5 \
  | while IFS=$'\t' read -r hook avg cnt; do
      printf "| %s | %s | %s |\n" "$hook" "$avg" "$cnt"
    done
echo ""

# ---------------------------------------------------------------------------
# (b) 超時次數排行
# ---------------------------------------------------------------------------
echo "## (b) 超時次數排行"
echo ""
TIMEOUT_DATA=$(echo "$DATA" | jq -r 'select(.status == "timeout") | .hook' 2>/dev/null | sort | uniq -c | sort -rn)
if [[ -z "$TIMEOUT_DATA" ]]; then
  echo "No timeouts recorded."
else
  echo "| Hook | Timeout Count |"
  echo "|------|---------------|"
  echo "$TIMEOUT_DATA" | while read -r cnt hook; do
    printf "| %s | %s |\n" "$hook" "$cnt"
  done
fi
echo ""

# ---------------------------------------------------------------------------
# (c) 失敗率 > 10% 的 Hook
# ---------------------------------------------------------------------------
echo "## (c) 失敗率 > 10% 的 Hook"
echo ""
FAIL_REPORT=$(echo "$DATA" | jq -r '[.hook, .status] | @tsv' 2>/dev/null \
  | awk -F'\t' '{
      total[$1] += 1
      if ($2 == "failure" || $2 == "timeout") fail[$1] += 1
    }
    END {
      for (h in total) {
        f = (h in fail) ? fail[h] : 0
        rate = (f / total[h]) * 100
        if (rate > 10) {
          printf "%s\t%.1f\t%d\t%d\n", h, rate, f, total[h]
        }
      }
    }' \
  | sort -t$'\t' -k2 -rn)

if [[ -z "$FAIL_REPORT" ]]; then
  echo "All hooks have failure rate <= 10%."
else
  echo "| Hook | Failure Rate | Failures | Total |"
  echo "|------|-------------|----------|-------|"
  echo "$FAIL_REPORT" | while IFS=$'\t' read -r hook rate fails total; do
    printf "| %s | %s%% | %s | %s |\n" "$hook" "$rate" "$fails" "$total"
  done
fi
echo ""
