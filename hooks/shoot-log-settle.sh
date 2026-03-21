#!/usr/bin/env bash
# hooks/shoot-log-settle.sh
# US-#322 AC-1：結算腳本 — 合併同日 per-session Shoot Log 檔案為 summary.md
#
# 用法：
#   bash hooks/shoot-log-settle.sh [YYYY-MM-DD]
#   - 無參數：結算昨天
#   - 指定日期：結算指定日
#
# 行為：
#   - 掃描 docs/km/shoot-log/<date>-session-*.md
#   - 合併所有表格列
#   - 寫出 docs/km/shoot-log/<date>.summary.md（含表格標題行）
#   - 保留原始 per-session 檔案（保守策略）
#
# 環境變數：
#   SHOOT_LOG_DIR — 可覆寫 shoot-log 目錄（測試用）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 允許 SHOOT_LOG_DIR 覆寫（測試友好）
SHOOT_LOG_DIR="${SHOOT_LOG_DIR:-${PLUGIN_ROOT}/docs/km/shoot-log}"

# 決定結算日期（無參數預設昨天）
if [[ $# -ge 1 ]]; then
  TARGET_DATE="$1"
else
  TARGET_DATE="$(date -d 'yesterday' '+%Y-%m-%d' 2>/dev/null \
             || date -v-1d '+%Y-%m-%d' 2>/dev/null \
             || date '+%Y-%m-%d')"
fi

echo "[SHOOT-LOG-SETTLE] 結算日期：${TARGET_DATE}"
echo "[SHOOT-LOG-SETTLE] 目錄：${SHOOT_LOG_DIR}"

# 確認目錄存在
if [[ ! -d "$SHOOT_LOG_DIR" ]]; then
  echo "[SHOOT-LOG-SETTLE] 目錄不存在，略過：${SHOOT_LOG_DIR}"
  exit 0
fi

# 掃描 per-session 檔案
SESSION_FILES=()
while IFS= read -r f; do
  [[ -f "$f" ]] && SESSION_FILES+=("$f")
done < <(ls "${SHOOT_LOG_DIR}/${TARGET_DATE}-session-"*.md 2>/dev/null || true)

if [[ ${#SESSION_FILES[@]} -eq 0 ]]; then
  echo "[SHOOT-LOG-SETTLE] 無 per-session 檔案：${TARGET_DATE}，略過"
  exit 0
fi

echo "[SHOOT-LOG-SETTLE] 找到 ${#SESSION_FILES[@]} 個 session 檔案"

# 合併所有 per-session 表格列（略過空行與標題行）
COMBINED_TMP="$(mktemp)"
trap 'rm -f "$COMBINED_TMP"' EXIT

for f in "${SESSION_FILES[@]}"; do
  echo "[SHOOT-LOG-SETTLE]   合併：$(basename "$f")"
  # 只取含 | 的非標題行（排除 |---|--- 分隔行）
  grep '^|' "$f" 2>/dev/null | grep -v '^|[-: |]*$' >> "$COMBINED_TMP" || true
done

# 寫出 summary.md（含表頭）
SUMMARY_FILE="${SHOOT_LOG_DIR}/${TARGET_DATE}.summary.md"
{
  echo "## Shoot Log — ${TARGET_DATE} Summary"
  echo ""
  echo "| 日期 | 來源 | 標題 | 結果 | commit |"
  echo "|------|------|------|------|--------|"
  cat "$COMBINED_TMP"
} > "$SUMMARY_FILE"

ENTRY_COUNT=$(grep -c '^|' "$COMBINED_TMP" 2>/dev/null || echo 0)
echo "[SHOOT-LOG-SETTLE] summary.md 已寫出：${SUMMARY_FILE}"
echo "[SHOOT-LOG-SETTLE] 共 ${ENTRY_COUNT} 筆紀錄"
echo "[SHOOT-LOG-SETTLE] 原始 per-session 檔案保留（保守策略）"
