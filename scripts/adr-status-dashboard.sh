#!/usr/bin/env bash
# scripts/adr-status-dashboard.sh
# ADR 狀態儀表板 — 輸出 Proposed/Draft ADR 摘要表
# Issue #846, Sprint 167
# AC1: 輸出 ADR 狀態摘要表
# AC2: 表格含欄位：編號、標題、狀態、日期、待辦動作
# AC3: Proposed/Draft 狀態以 [ADR-PENDING] 標記輸出
# AC4: 對應測試 tests/test-adr-status-dashboard.sh
# NFR1: 執行時間 < 2 秒
#
# Story #868: --check-staleness 旗標
# AC1: 新增 --check-staleness 旗標
# AC2: 超過 90 天未修改的 Accepted ADR 輸出 [ADR-STALE]
# NFR1（Story #868）: 使用 git log --follow 取得最後修改日期，< 3s

set -euo pipefail

CHECK_STALENESS=false
ADR_DIR=""
STALE_THRESHOLD_DAYS=90

for arg in "$@"; do
  case "$arg" in
    --check-staleness) CHECK_STALENESS=true ;;
    *) [[ -z "$ADR_DIR" ]] && ADR_DIR="$arg" || true ;;
  esac
done
ADR_DIR="${ADR_DIR:-docs/adr}"

if [[ ! -d "$ADR_DIR" ]]; then
  echo "[ERROR] ADR 目錄不存在: $ADR_DIR" >&2
  exit 1
fi

# ── 老化偵測輔助函數（Story #868）────────────────────────────────────────────

get_last_modified_days() {
  local file="$1"
  local today_ts
  today_ts=$(date +%s)

  # 嘗試 git log --follow 取得最後 commit 日期
  local last_commit_date
  last_commit_date=$(git log --follow --format="%aI" -1 -- "$file" 2>/dev/null | head -1 || true)

  local last_ts
  if [[ -n "$last_commit_date" ]]; then
    last_ts=$(date -d "$last_commit_date" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${last_commit_date:0:19}" +%s 2>/dev/null || echo 0)
  fi

  # fallback: 使用檔案 mtime
  if [[ -z "${last_ts:-}" ]] || [[ "$last_ts" -eq 0 ]]; then
    last_ts=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null || echo 0)
  fi

  if [[ "$last_ts" -eq 0 ]]; then
    echo 999  # unknown — treat as stale
  else
    echo $(( (today_ts - last_ts) / 86400 ))
  fi
}

echo "# ADR 狀態儀表板"
echo ""
echo "| 編號 | 標題 | 狀態 | 日期 | 待辦動作 |"
echo "|------|------|------|------|---------|"

PENDING_COUNT=0
TOTAL_COUNT=0

for f in "$ADR_DIR"/ADR-*.md; do
  [[ -f "$f" ]] || continue
  [[ "$(basename "$f")" == "README.md" ]] && continue

  # 提取欄位
  FILENAME=$(basename "$f" .md)
  ADR_NUM=$(echo "$FILENAME" | grep -oP 'ADR-\d+' | head -1 || echo "$FILENAME")
  TITLE=$(grep -m1 "^# ADR" "$f" 2>/dev/null | sed 's/^# //' || echo "(無標題)")
  STATUS=$(grep -m1 "^\*\*狀態\*\*" "$f" 2>/dev/null | sed 's/\*\*狀態\*\*：//' || echo "Unknown")
  DATE=$(grep -m1 "^\*\*日期\*\*" "$f" 2>/dev/null | sed 's/\*\*日期\*\*：//' || echo "—")

  TOTAL_COUNT=$((TOTAL_COUNT + 1))

  # 判斷 Proposed/Draft
  if echo "$STATUS" | grep -qiE "Proposed|Draft"; then
    STATUS_DISPLAY="[ADR-PENDING] ${STATUS}"
    TODO="需決策/補充"
    PENDING_COUNT=$((PENDING_COUNT + 1))
  else
    STATUS_DISPLAY="$STATUS"
    TODO="—"
  fi

  # Story #868: 老化偵測 — Accepted ADR 超過 90 天
  if [[ "$CHECK_STALENESS" == "true" ]] && echo "$STATUS" | grep -qiE "Accepted"; then
    DAYS_OLD=$(get_last_modified_days "$f")
    if [[ "$DAYS_OLD" -ge "$STALE_THRESHOLD_DAYS" ]]; then
      STATUS_DISPLAY="[ADR-STALE] ${STATUS}（${DAYS_OLD}天未更新）"
      TODO="建議重新評估"
    fi
  fi

  echo "| ${ADR_NUM} | ${TITLE} | ${STATUS_DISPLAY} | ${DATE} | ${TODO} |"
done

echo ""
echo "**統計**：共 ${TOTAL_COUNT} 個 ADR，其中 ${PENDING_COUNT} 個待決策（Proposed/Draft）"

if [[ "$PENDING_COUNT" -gt 0 ]]; then
  echo ""
  echo "> [ADR-PENDING] 上述標記的 ADR 需要決策者關注並推進至 Accepted 或 Deprecated。"
fi

if [[ "$CHECK_STALENESS" == "true" ]]; then
  echo ""
  echo "> 老化偵測（--check-staleness）：Accepted ADR 超過 ${STALE_THRESHOLD_DAYS} 天未更新者已標記（Story #868）。"
fi
