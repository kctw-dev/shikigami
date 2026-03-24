#!/usr/bin/env bash
# hooks/live-log-settle.sh
# US-#322 AC-2：結算腳本 — 合併同日 per-session live log 檔案為 summary.log
#
# 用法：
#   bash hooks/live-log-settle.sh [YYYY-MM-DD]
#   - 無參數：結算昨天
#   - 指定日期：結算指定日
#
# 行為：
#   - 掃描 logs/live/<date>-session-*.log
#   - 合併所有 log 行
#   - 寫出 logs/live/<date>.summary.log
#   - 保留原始 per-session 檔案（保守策略）
#
# 環境變數：
#   LIVE_LOG_DIR — 可覆寫 live-log 目錄（測試用）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 允許 LIVE_LOG_DIR 覆寫（測試友好）
LIVE_LOG_DIR="${LIVE_LOG_DIR:-${PLUGIN_ROOT}/logs/live}"

# 決定結算日期（無參數預設昨天）
if [[ $# -ge 1 ]]; then
  TARGET_DATE="$1"
else
  TARGET_DATE="$(date -d 'yesterday' '+%Y-%m-%d' 2>/dev/null \
             || date -v-1d '+%Y-%m-%d' 2>/dev/null \
             || date '+%Y-%m-%d')"
fi

echo "[LIVE-LOG-SETTLE] 結算日期：${TARGET_DATE}"
echo "[LIVE-LOG-SETTLE] 目錄：${LIVE_LOG_DIR}"

# 確認目錄存在
if [[ ! -d "$LIVE_LOG_DIR" ]]; then
  echo "[LIVE-LOG-SETTLE] 目錄不存在，略過：${LIVE_LOG_DIR}"
  exit 0
fi

# 掃描 per-session 檔案
SESSION_FILES=()
while IFS= read -r f; do
  [[ -f "$f" ]] && SESSION_FILES+=("$f")
done < <(ls "${LIVE_LOG_DIR}/${TARGET_DATE}-session-"*.log 2>/dev/null || true)

if [[ ${#SESSION_FILES[@]} -eq 0 ]]; then
  echo "[LIVE-LOG-SETTLE] 無 per-session 檔案：${TARGET_DATE}，略過"
  exit 0
fi

echo "[LIVE-LOG-SETTLE] 找到 ${#SESSION_FILES[@]} 個 session 檔案"

# 合併所有 per-session 內容
COMBINED_TMP="$(mktemp)"
trap 'rm -f "$COMBINED_TMP"' EXIT

for f in "${SESSION_FILES[@]}"; do
  echo "[LIVE-LOG-SETTLE]   合併：$(basename "$f")"
  cat "$f" >> "$COMBINED_TMP" 2>/dev/null || true
done

# 寫出 summary.log
SUMMARY_FILE="${LIVE_LOG_DIR}/${TARGET_DATE}.summary.log"
cp "$COMBINED_TMP" "$SUMMARY_FILE"

SUMMARY_LINES=$(wc -l < "$SUMMARY_FILE" | tr -d ' ')
echo "[LIVE-LOG-SETTLE] summary.log 已寫出：${SUMMARY_FILE}"
echo "[LIVE-LOG-SETTLE] 共 ${SUMMARY_LINES} 行日誌"
echo "[LIVE-LOG-SETTLE] 原始 per-session 檔案保留（保守策略）"
