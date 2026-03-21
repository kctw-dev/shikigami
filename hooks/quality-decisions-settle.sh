#!/usr/bin/env bash
# hooks/quality-decisions-settle.sh
# US-#322 AC-5：結算腳本 — 合併同日 per-session quality-gate-decisions 檔案為 summary.md
#
# 用法：
#   bash hooks/quality-decisions-settle.sh [YYYY-MM-DD]
#   - 無參數：結算昨天
#   - 指定日期：結算指定日
#
# 行為：
#   - 掃描 docs/km/quality-decisions/<date>-session-*.md
#   - 合併所有 Quality Gate 決策記錄
#   - 寫出 docs/km/quality-decisions/<date>.summary.md
#   - 保留原始 per-session 檔案（保守策略）
#
# 環境變數：
#   QUALITY_DECISIONS_DIR — 可覆寫 quality-decisions 目錄（測試用）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 允許 QUALITY_DECISIONS_DIR 覆寫（測試友好）
QUALITY_DECISIONS_DIR="${QUALITY_DECISIONS_DIR:-${PLUGIN_ROOT}/docs/km/quality-decisions}"

# 決定結算日期（無參數預設昨天）
if [[ $# -ge 1 ]]; then
  TARGET_DATE="$1"
else
  TARGET_DATE="$(date -d 'yesterday' '+%Y-%m-%d' 2>/dev/null \
             || date -v-1d '+%Y-%m-%d' 2>/dev/null \
             || date '+%Y-%m-%d')"
fi

echo "[QUALITY-DECISIONS-SETTLE] 結算日期：${TARGET_DATE}"
echo "[QUALITY-DECISIONS-SETTLE] 目錄：${QUALITY_DECISIONS_DIR}"

# 確認目錄存在
if [[ ! -d "$QUALITY_DECISIONS_DIR" ]]; then
  echo "[QUALITY-DECISIONS-SETTLE] 目錄不存在，略過：${QUALITY_DECISIONS_DIR}"
  exit 0
fi

# 掃描 per-session 檔案
SESSION_FILES=()
while IFS= read -r f; do
  [[ -f "$f" ]] && SESSION_FILES+=("$f")
done < <(ls "${QUALITY_DECISIONS_DIR}/${TARGET_DATE}-session-"*.md 2>/dev/null || true)

if [[ ${#SESSION_FILES[@]} -eq 0 ]]; then
  echo "[QUALITY-DECISIONS-SETTLE] 無 per-session 檔案：${TARGET_DATE}，略過"
  exit 0
fi

echo "[QUALITY-DECISIONS-SETTLE] 找到 ${#SESSION_FILES[@]} 個 session 檔案"

# 合併所有 per-session 內容
COMBINED_TMP="$(mktemp)"
trap 'rm -f "$COMBINED_TMP"' EXIT

for f in "${SESSION_FILES[@]}"; do
  echo "[QUALITY-DECISIONS-SETTLE]   合併：$(basename "$f")"
  grep -v '^---$' "$f" 2>/dev/null >> "$COMBINED_TMP" || true
  echo "" >> "$COMBINED_TMP"
done

# 寫出 summary.md
SUMMARY_FILE="${QUALITY_DECISIONS_DIR}/${TARGET_DATE}.summary.md"
{
  echo "## Quality Gate Decisions — ${TARGET_DATE} Summary"
  echo ""
  echo "> 由 quality-decisions-settle.sh 自動合併（US-#322 AC-5）"
  echo ""
  cat "$COMBINED_TMP"
} > "$SUMMARY_FILE"

echo "[QUALITY-DECISIONS-SETTLE] summary.md 已寫出：${SUMMARY_FILE}"
echo "[QUALITY-DECISIONS-SETTLE] 原始 per-session 檔案保留（保守策略）"
