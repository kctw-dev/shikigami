#!/usr/bin/env bash
# scripts/bump-version.sh
# US-94：版號更新三檔同步腳本
#
# 用法：bash scripts/bump-version.sh <MAJOR.MINOR.PATCH>
#
# 原子性地更新下列三個檔案的 version 欄位：
#   .claude-plugin/plugin.json
#   .claude-plugin/marketplace.json
#   gemini-extension.json
#
# Exit code:
#   0 = 全部更新成功
#   1 = 輸入錯誤或更新失敗
#
# 依賴：jq, bash >= 4

set -euo pipefail

# ---------------------------------------------------------------------------
# 常數
# ---------------------------------------------------------------------------
readonly SCRIPT_NAME="bump-version.sh"
readonly PLUGIN_JSON=".claude-plugin/plugin.json"
readonly MARKETPLACE_JSON=".claude-plugin/marketplace.json"
readonly GEMINI_EXTENSION_JSON="gemini-extension.json"

# ---------------------------------------------------------------------------
# 輔助函式
# ---------------------------------------------------------------------------
usage() {
  echo "用法：bash scripts/${SCRIPT_NAME} <MAJOR.MINOR.PATCH>"
  echo ""
  echo "範例："
  echo "  bash scripts/${SCRIPT_NAME} 1.0.0"
  echo "  bash scripts/${SCRIPT_NAME} 0.30.0"
}

error_exit() {
  echo "[ERROR] $1" >&2
  exit 1
}

print_info() {
  echo "[INFO]  $1"
}

print_ok() {
  echo "[OK]    $1"
}

# ---------------------------------------------------------------------------
# 輸入驗證
# ---------------------------------------------------------------------------
validate_version_format() {
  local version="$1"
  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "[ERROR] 版本格式不符：'${version}'" >&2
    echo "[ERROR] 必須符合 MAJOR.MINOR.PATCH 格式（例如：1.0.0、0.30.0）" >&2
    echo "" >&2
    usage >&2
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# 前置檢查：確認必要工具與檔案存在
# ---------------------------------------------------------------------------
preflight_check() {
  # 確認 jq 可用
  if ! command -v jq &>/dev/null; then
    error_exit "找不到 jq，請先安裝：sudo apt-get install jq"
  fi

  # 確認三個目標檔案存在
  local missing=0
  for file in "$PLUGIN_JSON" "$MARKETPLACE_JSON" "$GEMINI_EXTENSION_JSON"; do
    if [ ! -f "$file" ]; then
      echo "[ERROR] 找不到目標檔案：$file" >&2
      missing=1
    fi
  done

  if [ "$missing" -eq 1 ]; then
    error_exit "前置檢查失敗，請確認在專案根目錄執行此腳本"
  fi
}

# ---------------------------------------------------------------------------
# 更新函式
# ---------------------------------------------------------------------------

# 更新頂層 .version 欄位
update_top_level_version() {
  local file="$1"
  local version="$2"
  local old_version

  old_version=$(jq -r '.version' "$file")

  # 使用 jq 更新，透過暫存檔確保原子性
  local tmp_file
  tmp_file=$(mktemp)
  if jq --arg v "$version" '.version = $v' "$file" > "$tmp_file"; then
    mv "$tmp_file" "$file"
    print_ok "$file：${old_version} -> ${version}"
  else
    rm -f "$tmp_file"
    error_exit "更新 $file 失敗"
  fi
}

# 更新 marketplace.json 的 .plugins[0].version 欄位
update_marketplace_version() {
  local file="$1"
  local version="$2"
  local old_version

  old_version=$(jq -r '.plugins[0].version' "$file")

  local tmp_file
  tmp_file=$(mktemp)
  if jq --arg v "$version" '.plugins[0].version = $v' "$file" > "$tmp_file"; then
    mv "$tmp_file" "$file"
    print_ok "$file（plugins[0].version）：${old_version} -> ${version}"
  else
    rm -f "$tmp_file"
    error_exit "更新 $file 失敗"
  fi
}

# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------
main() {
  # 確認傳入參數
  if [ $# -ne 1 ]; then
    echo "[ERROR] 參數數量不符，需要恰好一個版本號參數" >&2
    echo "" >&2
    usage >&2
    exit 1
  fi

  local new_version="$1"

  # 驗證版本格式
  validate_version_format "$new_version"

  echo "=============================="
  echo " ${SCRIPT_NAME}"
  echo " 版號同步更新至：${new_version}"
  echo "=============================="
  echo ""

  # 前置檢查
  preflight_check

  print_info "開始更新三個版本檔案..."
  echo ""

  # 更新 plugin.json（頂層 .version）
  update_top_level_version "$PLUGIN_JSON" "$new_version"

  # 更新 marketplace.json（.plugins[0].version）
  update_marketplace_version "$MARKETPLACE_JSON" "$new_version"

  # 更新 gemini-extension.json（頂層 .version）
  update_top_level_version "$GEMINI_EXTENSION_JSON" "$new_version"

  echo ""
  echo "=============================="
  echo " 版號更新完成：${new_version}"
  echo " 請執行 bash scripts/validate-version.sh 確認結果"
  echo "=============================="
}

main "$@"
