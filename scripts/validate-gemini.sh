#!/usr/bin/env bash
# scripts/validate-gemini.sh
# Gemini CLI Extension 結構驗證腳本
#
# 驗證 Gemini CLI extension 相關檔案結構完整性：
#   AC1：gemini-extension.json 存在且 JSON 合法
#   AC2：必填欄位齊全（name、version、description、contextFileName）
#   AC3：version 與 .claude-plugin/plugin.json 一致
#   AC4：GEMINI.md 存在（contextFileName 指向的檔案）
#   AC5：.gemini/commands/shikigami/ 目錄與 4 個 .toml 檔案存在
#
# Exit code:
#   0 = 全部通過（PASS / WARNING）
#   1 = 有 ERROR
#
# 依賴：bash >= 4, grep, sed（Pure Bash，不使用 jq、python）

set -uo pipefail

source "$(dirname "$0")/lib/validate-helpers.sh"

# ---------------------------------------------------------------------------
# 常數
# ---------------------------------------------------------------------------
readonly GEMINI_EXTENSION_JSON="gemini-extension.json"
readonly PLUGIN_JSON=".claude-plugin/plugin.json"
readonly GEMINI_MD="GEMINI.md"
readonly COMMANDS_DIR=".gemini/commands/shikigami"
readonly EXPECTED_COMMANDS=("sprint.toml" "standup.toml" "review.toml" "dispel.toml")

# gemini-extension.json 必填欄位
readonly REQUIRED_FIELDS=("name" "version" "description" "contextFileName")

# ---------------------------------------------------------------------------
# 狀態追蹤
# ---------------------------------------------------------------------------
EXIT_CODE=0
ERROR_COUNT=0

# ---------------------------------------------------------------------------
# JSON 輔助：檢查頂層 key 是否存在
# 參數：$1 = 檔案路徑，$2 = key 名稱
# 回傳：0 = 存在，1 = 不存在
# ---------------------------------------------------------------------------
json_has_key() {
  local filepath="$1"
  local key="$2"
  grep -qE "^  \"${key}\"\s*:" "$filepath"
}

# ---------------------------------------------------------------------------
# JSON 輔助：提取頂層 key 的字串值
# 參數：$1 = 檔案路徑，$2 = key 名稱
# ---------------------------------------------------------------------------
json_get_string_value() {
  local filepath="$1"
  local key="$2"
  grep -E "^  \"${key}\"\s*:" "$filepath" \
    | head -1 \
    | sed -E "s/^  \"${key}\"\s*:\s*\"([^\"]*)\".*/\1/" \
    || true
}

# ---------------------------------------------------------------------------
# AC1：gemini-extension.json 存在性驗證
# ---------------------------------------------------------------------------
validate_ac1_existence() {
  print_section "AC1：gemini-extension.json 存在性驗證"

  if [ ! -f "$GEMINI_EXTENSION_JSON" ]; then
    print_error "找不到 $GEMINI_EXTENSION_JSON"
    return 1
  fi

  # 基本 JSON 結構檢查（首行以 { 開頭，末行含 }）
  if head -1 "$GEMINI_EXTENSION_JSON" | grep -q '^{' && \
     tail -1 "$GEMINI_EXTENSION_JSON" | grep -q '}'; then
    print_pass "$GEMINI_EXTENSION_JSON 存在且具備基本 JSON 結構"
  else
    print_error "$GEMINI_EXTENSION_JSON 不具備有效的 JSON 結構"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# AC2：必填欄位驗證
# ---------------------------------------------------------------------------
validate_ac2_required_fields() {
  print_section "AC2：gemini-extension.json 必填欄位驗證"

  local field
  for field in "${REQUIRED_FIELDS[@]}"; do
    if json_has_key "$GEMINI_EXTENSION_JSON" "$field"; then
      print_pass "gemini-extension.json：包含必填欄位「$field」"
    else
      print_error "gemini-extension.json：缺少必填欄位「$field」"
    fi
  done
}

# ---------------------------------------------------------------------------
# AC3：version 與 plugin.json 一致性驗證
# ---------------------------------------------------------------------------
validate_ac3_version_consistency() {
  print_section "AC3：version 一致性驗證（gemini-extension.json vs plugin.json）"

  if [ ! -f "$PLUGIN_JSON" ]; then
    print_warning "找不到 $PLUGIN_JSON，跳過版號一致性驗證"
    return
  fi

  local gemini_version plugin_version
  gemini_version=$(json_get_string_value "$GEMINI_EXTENSION_JSON" "version")
  plugin_version=$(json_get_string_value "$PLUGIN_JSON" "version")

  echo "  gemini-extension.json version: $gemini_version"
  echo "  plugin.json           version: $plugin_version"

  if [ "$gemini_version" = "$plugin_version" ]; then
    print_pass "gemini-extension.json 與 plugin.json 版號一致 ($gemini_version)"
  else
    print_error "版號不一致：gemini-extension.json=$gemini_version，plugin.json=$plugin_version"
  fi
}

# ---------------------------------------------------------------------------
# AC4：GEMINI.md 存在性驗證
# ---------------------------------------------------------------------------
validate_ac4_context_file() {
  print_section "AC4：GEMINI.md 存在性驗證"

  if [ -f "$GEMINI_MD" ]; then
    local line_count
    line_count=$(wc -l < "$GEMINI_MD")
    print_pass "$GEMINI_MD 存在（${line_count} 行）"
  else
    print_error "找不到 $GEMINI_MD（gemini-extension.json 的 contextFileName 指向此檔案）"
  fi
}

# ---------------------------------------------------------------------------
# AC5：TOML commands 目錄與檔案驗證
# ---------------------------------------------------------------------------
validate_ac5_commands() {
  print_section "AC5：Gemini CLI commands 驗證"

  if [ ! -d "$COMMANDS_DIR" ]; then
    print_error "找不到 commands 目錄：$COMMANDS_DIR"
    return
  fi

  print_pass "commands 目錄存在：$COMMANDS_DIR"

  local toml_file
  for toml_file in "${EXPECTED_COMMANDS[@]}"; do
    local filepath="$COMMANDS_DIR/$toml_file"
    if [ -f "$filepath" ]; then
      # 檢查 prompt 欄位存在
      if grep -qE '^prompt\s*=' "$filepath"; then
        print_pass "$toml_file：存在且包含 prompt 欄位"
      else
        print_error "$toml_file：缺少 prompt 欄位"
      fi
    else
      print_error "找不到 command 檔案：$filepath"
    fi
  done
}

# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------
main() {
  print_banner "validate-gemini.sh - Gemini CLI Extension 驗證"

  validate_ac1_existence || { exit "$EXIT_CODE"; }
  validate_ac2_required_fields
  validate_ac3_version_consistency
  validate_ac4_context_file
  validate_ac5_commands

  # 總結
  echo ""
  echo "=============================="
  if [ "$EXIT_CODE" -eq 0 ]; then
    echo " 總結：Gemini CLI Extension 驗證全部通過"
  else
    echo " 總結：Gemini CLI Extension 驗證發現 $ERROR_COUNT 個 ERROR，請修正後重試"
  fi
  echo "=============================="

  exit "$EXIT_CODE"
}

main
