#!/usr/bin/env bash
# scripts/update-adr-index.sh
# Story #742 — ADR 目錄索引自動維護（docs/adr/README.md 自動更新）
#
# AC1: 掃描 docs/adr/ADR-*.md，產生/更新 docs/adr/README.md
# AC2: README.md 格式：表格（ADR 編號 | 標題 | 狀態 | 日期）
# NFR1: 純 bash + grep，不依賴 Python

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADR_DIR="${REPO_ROOT}/docs/adr"
OUTPUT_FILE="${ADR_DIR}/README.md"

# ── 掃描 ADR 檔案 ────────────────────────────────────────────────────

if [ ! -d "$ADR_DIR" ]; then
  echo "[ERROR] ADR 目錄不存在：${ADR_DIR}" >&2
  exit 1
fi

ADR_FILES=$(ls "${ADR_DIR}/ADR-"*.md 2>/dev/null | sort || true)

if [ -z "$ADR_FILES" ]; then
  echo "[WARN] 未找到任何 ADR-*.md 檔案於 ${ADR_DIR}"
  ADR_FILES=""
fi

# ── 提取 ADR 資訊 ────────────────────────────────────────────────────

extract_field() {
  local file="$1"
  local field="$2"
  # 支援 **狀態**:、**狀態**：、**Status**: 等格式
  grep -m1 -iE "^\*\*${field}\*\*[：:]" "$file" 2>/dev/null \
    | sed -E "s/^\*\*[^*]+\*\*[：:][[:space:]]*//" \
    | tr -d '\r' \
    | head -1 \
    || echo "—"
}

extract_title() {
  local file="$1"
  # 第一個 # 標題行
  grep -m1 "^# " "$file" 2>/dev/null \
    | sed 's/^# //' \
    | tr -d '\r' \
    || basename "$file" .md
}

extract_number() {
  local file="$1"
  basename "$file" | grep -oP 'ADR-\d+' | head -1 || echo "—"
}

# ── 產生 README.md ───────────────────────────────────────────────────

{
  cat << 'HEADER'
# ADR 目錄索引

> 本文件由 `scripts/update-adr-index.sh` 自動產生，請勿手動修改。
> 最後更新：TIMESTAMP_PLACEHOLDER

## 架構決策紀錄（Architecture Decision Records）

| ADR 編號 | 標題 | 狀態 | 日期 |
|---------|------|------|------|
HEADER

  if [ -n "$ADR_FILES" ]; then
    while IFS= read -r adr_file; do
      [ -f "$adr_file" ] || continue

      NUMBER=$(extract_number "$adr_file")
      TITLE=$(extract_title "$adr_file")
      STATUS=$(extract_field "$adr_file" "狀態|Status")
      DATE=$(extract_field "$adr_file" "日期|Date")

      # 去除可能的 markdown 粗體殘留
      STATUS=$(echo "$STATUS" | sed 's/\*\*//g')
      DATE=$(echo "$DATE" | sed 's/\*\*//g')

      # 產生相對連結
      FILENAME=$(basename "$adr_file")
      echo "| ${NUMBER} | [${TITLE}](${FILENAME}) | ${STATUS} | ${DATE} |"
    done <<< "$ADR_FILES"
  fi

} > "${OUTPUT_FILE}.tmp"

# 替換時間戳
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
sed -i "s/TIMESTAMP_PLACEHOLDER/${TIMESTAMP}/" "${OUTPUT_FILE}.tmp"

mv "${OUTPUT_FILE}.tmp" "${OUTPUT_FILE}"

echo "[OK] ADR 索引已更新：${OUTPUT_FILE}"
echo "[OK] 共掃描 $(echo "$ADR_FILES" | grep -c "." || echo 0) 個 ADR 檔案"
