#!/usr/bin/env bash
# scripts/adr-status-dashboard.sh
# ADR 狀態儀表板 — 輸出 Proposed/Draft ADR 摘要表
# Issue #846, Sprint 167
# AC1: 輸出 ADR 狀態摘要表
# AC2: 表格含欄位：編號、標題、狀態、日期、待辦動作
# AC3: Proposed/Draft 狀態以 [ADR-PENDING] 標記輸出
# AC4: 對應測試 tests/test-adr-status-dashboard.sh
# NFR1: 執行時間 < 2 秒

set -euo pipefail

ADR_DIR="${1:-docs/adr}"

if [[ ! -d "$ADR_DIR" ]]; then
  echo "[ERROR] ADR 目錄不存在: $ADR_DIR" >&2
  exit 1
fi

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

  echo "| ${ADR_NUM} | ${TITLE} | ${STATUS_DISPLAY} | ${DATE} | ${TODO} |"
done

echo ""
echo "**統計**：共 ${TOTAL_COUNT} 個 ADR，其中 ${PENDING_COUNT} 個待決策（Proposed/Draft）"

if [[ "$PENDING_COUNT" -gt 0 ]]; then
  echo ""
  echo "> [ADR-PENDING] 上述標記的 ADR 需要決策者關注並推進至 Accepted 或 Deprecated。"
fi
