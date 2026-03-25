#!/usr/bin/env bash
# Log rotate for Shikigami logs/
# 用法：bash scripts/logrotate.sh [--dry-run]
# 建議排程：每天跑一次（或由 cron cruise 結束後呼叫）

set -euo pipefail

# --dry-run 模式：只列出將被清理的檔案，不實際刪除（AC4）
DRY_RUN=false
for arg in "$@"; do
  [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
done

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LIVE_DIR="${PROJECT_DIR}/logs/live"
SCHEDULE_LOG="${PROJECT_DIR}/logs/schedule-cruise.log"
ARCHIVE_DIR="${PROJECT_DIR}/logs/archive"
KEEP_DAYS=7

# cruise-logs 保留天數（可透過環境變數覆蓋，AC2/NFR2）
CRUISE_KEEP_DAYS="${CRUISE_KEEP_DAYS:-3}"
# cruise-logs 目錄（可透過環境變數覆蓋，用於測試）
CRUISE_LOG_DIR="${CRUISE_LOG_DIR:-${PROJECT_DIR}/docs/cruise-logs}"

if [[ "$DRY_RUN" == "false" ]]; then
  mkdir -p "$ARCHIVE_DIR"
fi

# --- live log: 合併同一天的 session log 為 daily summary，刪除原始檔 ---
if [[ -d "$LIVE_DIR" ]]; then
  # 找出所有日期
  DATES=$(ls "$LIVE_DIR"/*.log 2>/dev/null | sed -E 's|.*/([0-9]{4}-[0-9]{2}-[0-9]{2})-session-.*|\1|' | sort -u)
  TODAY=$(date '+%Y-%m-%d')

  for D in $DATES; do
    # 不合併今天的（還在寫入）
    [[ "$D" == "$TODAY" ]] && continue

    SUMMARY="${ARCHIVE_DIR}/${D}-live-summary.log"
    # 合併該天所有 session log
    cat "$LIVE_DIR"/${D}-session-*.log > "$SUMMARY" 2>/dev/null || true
    # 刪除原始檔
    rm -f "$LIVE_DIR"/${D}-session-*.log
    echo "[logrotate] ${D} live logs → ${SUMMARY} ($(wc -l < "$SUMMARY") lines)"
  done
fi

# --- schedule-cruise.log: 超過 KEEP_DAYS 天的部分歸檔 ---
if [[ -f "$SCHEDULE_LOG" ]]; then
  CUTOFF=$(date -d "-${KEEP_DAYS} days" '+%Y-%m-%d' 2>/dev/null || date -v-${KEEP_DAYS}d '+%Y-%m-%d')
  ARCHIVE_FILE="${ARCHIVE_DIR}/schedule-cruise-before-${CUTOFF}.log"

  # 把 CUTOFF 之前的行移到 archive
  LINES_BEFORE=$(grep -n "^\[${CUTOFF}" "$SCHEDULE_LOG" | head -1 | cut -d: -f1 || true)
  if [[ -n "${LINES_BEFORE:-}" && "$LINES_BEFORE" -gt 1 ]]; then
    head -n $((LINES_BEFORE - 1)) "$SCHEDULE_LOG" >> "$ARCHIVE_FILE"
    tail -n +${LINES_BEFORE} "$SCHEDULE_LOG" > "${SCHEDULE_LOG}.tmp"
    mv "${SCHEDULE_LOG}.tmp" "$SCHEDULE_LOG"
    echo "[logrotate] schedule-cruise.log archived ${LINES_BEFORE} lines → ${ARCHIVE_FILE}"
  fi
fi

# --- 刪除超過 30 天的 archive ---
if [[ "$DRY_RUN" == "false" ]]; then
  find "$ARCHIVE_DIR" -name "*.log" -mtime +30 -delete 2>/dev/null || true
else
  echo "[dry-run] would delete archive files older than 30 days in $ARCHIVE_DIR"
fi

# --- cruise-logs JSONL: 刪除超過 CRUISE_KEEP_DAYS 天的 JSONL（AC1/AC2）---
CRUISE_CLEANED=0
CRUISE_KEPT=0
CRUISE_CUTOFF=$(date -d "-${CRUISE_KEEP_DAYS} days" '+%Y-%m-%d' 2>/dev/null \
  || date -v-${CRUISE_KEEP_DAYS}d '+%Y-%m-%d' 2>/dev/null \
  || echo "")

if [[ -d "$CRUISE_LOG_DIR" && -n "$CRUISE_CUTOFF" ]]; then
  TODAY=$(date '+%Y-%m-%d')
  while IFS= read -r -d '' f; do
    fname=$(basename "$f")
    # 從檔名提取日期（格式：YYYY-MM-DD-session-*.jsonl）
    fdate=$(echo "$fname" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}' || true)
    if [[ -z "$fdate" ]]; then
      CRUISE_KEPT=$((CRUISE_KEPT + 1))
      continue
    fi
    # 不清理今天的檔案（還在寫入中）
    if [[ "$fdate" == "$TODAY" ]]; then
      CRUISE_KEPT=$((CRUISE_KEPT + 1))
      continue
    fi
    if [[ "$fdate" < "$CRUISE_CUTOFF" ]]; then
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] would delete: $f"
      else
        rm -f "$f"
      fi
      CRUISE_CLEANED=$((CRUISE_CLEANED + 1))
    else
      CRUISE_KEPT=$((CRUISE_KEPT + 1))
    fi
  done < <(find "$CRUISE_LOG_DIR" -maxdepth 1 -name "*.jsonl" -print0 2>/dev/null)

  # 記錄清理動作（AC3）
  if [[ "$DRY_RUN" == "false" ]]; then
    echo "{\"type\":\"log-rotate\",\"target\":\"cruise-logs\",\"cleaned\":${CRUISE_CLEANED},\"kept\":${CRUISE_KEPT},\"cutoff\":\"${CRUISE_CUTOFF}\"}"
  else
    echo "[dry-run] cruise-logs: would clean ${CRUISE_CLEANED}, keep ${CRUISE_KEPT} (cutoff: ${CRUISE_CUTOFF})"
  fi
else
  echo "[logrotate] cruise-logs dir not found or date calc failed, skipping"
fi

echo "[logrotate] done"
