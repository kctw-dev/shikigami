#!/usr/bin/env bash
# hooks/exploration-settle.sh
# US-#317 Phase 3 AC-2 — 結算腳本：合併同日 per-session 探索檔案為 summary.jsonl
#
# 用法：
#   bash hooks/exploration-settle.sh [YYYY-MM-DD]
#   - 無參數：結算昨天
#   - 指定日期：結算指定日
#
# 行為：
#   - 掃描 docs/exploration/<date>-session-*.jsonl
#   - 合併並依 timestamp 排序
#   - 寫出 docs/exploration/<date>.summary.jsonl
#   - 保留原始 per-session 檔案（保守策略）
#
# 環境變數：
#   EXPLORATION_DIR — 可覆寫探索目錄（測試用）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 允許 EXPLORATION_DIR 覆寫（測試友好）
EXPLORATION_DIR="${EXPLORATION_DIR:-${PLUGIN_ROOT}/docs/exploration}"

# 決定結算日期（無參數預設昨天）
if [[ $# -ge 1 ]]; then
  TARGET_DATE="$1"
else
  TARGET_DATE="$(date -d 'yesterday' '+%Y-%m-%d' 2>/dev/null \
             || date -v-1d '+%Y-%m-%d' 2>/dev/null \
             || date '+%Y-%m-%d')"
fi

echo "[EXPLORATION-SETTLE] 結算日期：${TARGET_DATE}"
echo "[EXPLORATION-SETTLE] 目錄：${EXPLORATION_DIR}"

# 確認目錄存在
if [[ ! -d "$EXPLORATION_DIR" ]]; then
  echo "[EXPLORATION-SETTLE] 目錄不存在，略過：${EXPLORATION_DIR}"
  exit 0
fi

# 掃描 per-session 檔案
SESSION_FILES=()
while IFS= read -r f; do
  [[ -f "$f" ]] && SESSION_FILES+=("$f")
done < <(ls "${EXPLORATION_DIR}/${TARGET_DATE}-session-"*.jsonl 2>/dev/null || true)

if [[ ${#SESSION_FILES[@]} -eq 0 ]]; then
  echo "[EXPLORATION-SETTLE] 無 per-session 檔案：${TARGET_DATE}，略過"
  exit 0
fi

echo "[EXPLORATION-SETTLE] 找到 ${#SESSION_FILES[@]} 個 session 檔案"

# 合併所有 per-session 內容
COMBINED_TMP="$(mktemp)"
trap 'rm -f "$COMBINED_TMP"' EXIT

for f in "${SESSION_FILES[@]}"; do
  echo "[EXPLORATION-SETTLE]   合併：$(basename "$f")"
  cat "$f" >> "$COMBINED_TMP" 2>/dev/null || true
done

# 依 timestamp 欄位排序（ISO 8601 字典序 = 時間序）
SUMMARY_FILE="${EXPLORATION_DIR}/${TARGET_DATE}.summary.jsonl"
sort -t'"' -k8 "$COMBINED_TMP" > "$SUMMARY_FILE" 2>/dev/null || \
  cp "$COMBINED_TMP" "$SUMMARY_FILE"

SUMMARY_LINES=$(wc -l < "$SUMMARY_FILE" | tr -d ' ')
echo "[EXPLORATION-SETTLE] summary.jsonl 已寫出：${SUMMARY_FILE}"
echo "[EXPLORATION-SETTLE] 共 ${SUMMARY_LINES} 筆紀錄"
echo "[EXPLORATION-SETTLE] 原始 per-session 檔案保留（保守策略）"
