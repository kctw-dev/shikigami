#!/usr/bin/env bash
# scripts/lib/validate-helpers.sh
# ADR-002：驗證腳本共享函式庫
#
# 提供所有 validate-*.sh 腳本共用的輸出格式函式與 frontmatter 解析工具。
#
# 使用方式（在腳本開頭 source）：
#   source "$(dirname "$0")/lib/validate-helpers.sh"
#
# 前置條件：
#   呼叫端必須先定義 EXIT_CODE=0 與 ERROR_COUNT=0

# ---------------------------------------------------------------------------
# 輸出格式函式
# ---------------------------------------------------------------------------

# print_pass：印出通過訊息（不影響 exit code）
# 參數：$1 = 訊息內容
print_pass() { echo "[PASS] $1"; }

# print_fail：印出失敗訊息，設定 EXIT_CODE=1 並遞增 ERROR_COUNT
# 參數：$1 = 訊息內容
print_fail() { echo "[FAIL] $1"; EXIT_CODE=1; ERROR_COUNT=$((ERROR_COUNT + 1)); }

# print_error：印出錯誤訊息，設定 EXIT_CODE=1 並遞增 ERROR_COUNT
# 參數：$1 = 訊息內容
print_error() { echo "[ERROR] $1"; EXIT_CODE=1; ERROR_COUNT=$((ERROR_COUNT + 1)); }

# print_info：印出一般資訊（不影響 exit code）
# 參數：$1 = 訊息內容
print_info() { echo "[INFO] $1"; }

# print_warning：印出警告訊息（不影響 exit code）
# 參數：$1 = 訊息內容
print_warning() { echo "[WARNING] $1"; }

# print_section：印出區段標題（前置空行）
# 參數：$1 = 區段標題
print_section() { echo ""; echo "--- $1"; }

# print_banner：印出橫幅標題（含上下框線）
# 參數：$1 = 標題內容
print_banner() { echo "=============================="; echo " $1"; echo "=============================="; }

# ---------------------------------------------------------------------------
# Frontmatter 解析工具
# ---------------------------------------------------------------------------

# has_frontmatter_field：檢查 YAML frontmatter 是否包含指定欄位
# 參數：$1 = 檔案路徑，$2 = 欄位名稱（如 name、description）
# 回傳：0 = 欄位存在，1 = 欄位不存在
# 注意：frontmatter 定義為兩個 --- 之間的內容
has_frontmatter_field() {
  local filepath="$1" field="$2"
  awk '/^---/{c++; if(c==2) exit} c==1' "$filepath" \
    | grep -qE "^${field}[[:space:]]*:"
}
