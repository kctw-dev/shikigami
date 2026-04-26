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
  # 注意：不能用 [：:] 字元類，BSD sed 會 byte-by-byte 處理多字節 ：，
  # 吃掉 1 byte 留下 2 bytes 殘渣 → ��Accepted。改成兩段獨立替換。
  grep -m1 -iE "^\*\*${field}\*\*[：:]" "$file" 2>/dev/null \
    | sed -E "s/^\*\*[^*]+\*\*：[[:space:]]*//" \
    | sed -E "s/^\*\*[^*]+\*\*:[[:space:]]*//" \
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
  # 改用 grep -oE（POSIX 擴充），相容 BSD / macOS
  basename "$file" | grep -oE 'ADR-[0-9]+' | head -1 || echo "—"
}

# ── 產生 README.md ───────────────────────────────────────────────────

# 識別 forwarding stub（已歸檔 ADR 的轉址檔案）
is_forwarding_stub() {
  local f="$1"
  grep -qE "^# ADR-[0-9]+ — 已歸檔|^> \*\*此 ADR 已歸檔" "$f" 2>/dev/null
}

# 掃描 archive 子目錄
ARCHIVE_DIR="${ADR_DIR}/archive"
ARCHIVED_FILES=""
if [ -d "$ARCHIVE_DIR" ]; then
  ARCHIVED_FILES=$(ls "${ARCHIVE_DIR}/ADR-"*.md 2>/dev/null | sort || true)
fi

{
  cat << 'HEADER'
# ADR 目錄索引

> 本文件由 `scripts/update-adr-index.sh` 自動產生，請勿手動修改。
> 最後更新：TIMESTAMP_PLACEHOLDER

## 架構決策紀錄（Architecture Decision Records）

| ADR 編號 | 標題 | 狀態 | 日期 |
|---------|------|------|------|
HEADER

  declare -a STUB_FILES
  STUB_FILES=()

  if [ -n "$ADR_FILES" ]; then
    while IFS= read -r adr_file; do
      [ -f "$adr_file" ] || continue

      # 把 forwarding stub 抽出，稍後在「已歸檔 ADR」段落呈現
      if is_forwarding_stub "$adr_file"; then
        STUB_FILES+=("$adr_file")
        continue
      fi

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

  # ── 已歸檔 ADR 段落（forwarding stub + archive/ 實際檔案）──
  if [ "${#STUB_FILES[@]}" -gt 0 ] || [ -n "$ARCHIVED_FILES" ]; then
    cat << 'ARCHIVED_HEADER'

## 已歸檔 ADR（Archived）

> 歸檔依據：[ARCHIVAL_POLICY.md](ARCHIVAL_POLICY.md)。歸檔的 ADR 仍保留歷史脈絡，但不再驅動執行面決策。

| ADR 編號 | 標題 | 取代者 / 狀態 | Stub | 實檔位置 |
|---------|------|-------------|------|---------|
ARCHIVED_HEADER

    for stub in "${STUB_FILES[@]:-}"; do
      [ -z "${stub:-}" ] && continue
      [ -f "$stub" ] || continue
      NUMBER=$(extract_number "$stub")
      # Stub 的 H1 是 forwarding 用，無有意義標題；改從 archive/ 實檔讀真標題
      ARCHIVE_FILE="archive/$(basename "$stub")"
      ARCHIVE_PATH="${ADR_DIR}/${ARCHIVE_FILE}"
      if [ -f "$ARCHIVE_PATH" ]; then
        TITLE=$(extract_title "$ARCHIVE_PATH")
      else
        TITLE="(歸檔實檔遺失)"
      fi
      # 取代者：抓「Superseded by ADR-NN」中緊跟其後的 ADR 編號（不是行內第一個）
      SUPERSEDER=$(awk '/Superseded by ADR-[0-9]+/ {
        match($0, /Superseded by ADR-[0-9]+/);
        if (RSTART > 0) {
          chunk = substr($0, RSTART, RLENGTH);
          match(chunk, /ADR-[0-9]+/);
          print substr(chunk, RSTART, RLENGTH);
          exit;
        }
      }' "$stub" 2>/dev/null)
      [ -z "$SUPERSEDER" ] && SUPERSEDER="—"
      STUB_FILE=$(basename "$stub")
      echo "| ${NUMBER} | ${TITLE} | ${SUPERSEDER} | [stub](${STUB_FILE}) | [${ARCHIVE_FILE}](${ARCHIVE_FILE}) |"
    done

    # 也列出 archive/ 中沒有 stub 的孤兒（直接歸檔未保留 forwarding）
    if [ -n "$ARCHIVED_FILES" ]; then
      while IFS= read -r archived; do
        [ -f "$archived" ] || continue
        archived_basename=$(basename "$archived")
        # 若 stub 列表已含對應 ADR，跳過
        skip=0
        for stub in "${STUB_FILES[@]:-}"; do
          [ -z "${stub:-}" ] && continue
          [ "$(basename "$stub")" = "$archived_basename" ] && skip=1 && break
        done
        [ "$skip" -eq 1 ] && continue
        NUMBER=$(extract_number "$archived")
        TITLE=$(extract_title "$archived")
        ARCHIVE_FILE="archive/${archived_basename}"
        echo "| ${NUMBER} | ${TITLE} | — | （無 stub）| [${ARCHIVE_FILE}](${ARCHIVE_FILE}) |"
      done <<< "$ARCHIVED_FILES"
    fi
  fi

} > "${OUTPUT_FILE}.tmp"

# 替換時間戳（用兩段 mv 避免 sed -i 在 BSD/macOS 與 GNU/Linux 語法分歧）
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
sed "s/TIMESTAMP_PLACEHOLDER/${TIMESTAMP}/" "${OUTPUT_FILE}.tmp" > "${OUTPUT_FILE}.tmp2"
mv "${OUTPUT_FILE}.tmp2" "${OUTPUT_FILE}"
rm -f "${OUTPUT_FILE}.tmp"

echo "[OK] ADR 索引已更新：${OUTPUT_FILE}"
echo "[OK] 共掃描 $(echo "$ADR_FILES" | grep -c "." || echo 0) 個 ADR 檔案"
