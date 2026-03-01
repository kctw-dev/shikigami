#!/usr/bin/env bash
# scripts/validate-json.sh
# US-T03：JSON Schema 驗證腳本
#
# 驗證 .claude-plugin/ 下的 JSON 設定檔是否合法：
#   AC1：plugin.json 必填欄位（name、version、description、author）
#   AC2：marketplace.json 必填欄位（name、plugins 陣列）
#   AC3：version 格式符合 semver（major.minor.patch 三段純數字）
#   AC4：plugin.json 欄位白名單（白名單以外欄位觸發 WARNING，非 ERROR）
#   AC5：exit code 0 = 無 ERROR；非 0 = 存在至少一個 ERROR
#
# 使用方式：
#   bash scripts/validate-json.sh
#   （在專案根目錄下執行；.claude-plugin/ 目錄相對於 cwd）
#
# Exit code:
#   0 = 全部通過（PASS / INFO / WARNING）
#   1 = 有 ERROR
#
# 依賴：bash >= 4, grep, sed, awk（Pure Bash，不使用 jq、python）
# 技術規範：ADR-002 Pure Bash + shared library

set -uo pipefail

source "$(dirname "$0")/lib/validate-helpers.sh"

# ---------------------------------------------------------------------------
# 常數
# ---------------------------------------------------------------------------
readonly PLUGIN_DIR=".claude-plugin"
readonly PLUGIN_JSON="$PLUGIN_DIR/plugin.json"
readonly MARKETPLACE_JSON="$PLUGIN_DIR/marketplace.json"

# plugin.json 必填欄位
readonly PLUGIN_REQUIRED_FIELDS=("name" "version" "description" "author")

# marketplace.json 必填欄位
readonly MARKETPLACE_REQUIRED_FIELDS=("name")

# plugin.json 欄位白名單（AC4）
readonly PLUGIN_WHITELIST=(
  "name"
  "version"
  "description"
  "author"
  "homepage"
  "license"
  "tags"
  "minVersion"
  "repository"
  "keywords"
)

# ---------------------------------------------------------------------------
# 狀態追蹤
# ---------------------------------------------------------------------------
EXIT_CODE=0
ERROR_COUNT=0
WARNING_COUNT=0

# ---------------------------------------------------------------------------
# 前置檢查：.claude-plugin/ 目錄與必要 JSON 檔案必須存在
# ---------------------------------------------------------------------------
preflight_check() {
  if [ ! -d "$PLUGIN_DIR" ]; then
    print_error "找不到目錄：$PLUGIN_DIR"
    exit 1
  fi

  if [ ! -f "$PLUGIN_JSON" ]; then
    print_error "找不到檔案：$PLUGIN_JSON"
    exit 1
  fi

  if [ ! -f "$MARKETPLACE_JSON" ]; then
    print_error "找不到檔案：$MARKETPLACE_JSON"
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# JSON 輔助：檢查頂層 key 是否存在於 JSON 檔案
# 參數：$1 = 檔案路徑，$2 = key 名稱
# 回傳：0 = 存在，1 = 不存在
# 實作：僅比對行首有雙引號包住的 key，避免巢狀值干擾
# ---------------------------------------------------------------------------
json_has_key() {
  local filepath="$1"
  local key="$2"
  grep -qE "^\s*\"${key}\"\s*:" "$filepath"
}

# ---------------------------------------------------------------------------
# JSON 輔助：提取頂層 key 的字串值
# 參數：$1 = 檔案路徑，$2 = key 名稱
# 輸出：key 對應的字串值（去除雙引號），若非字串值則輸出空字串
# ---------------------------------------------------------------------------
json_get_string_value() {
  local filepath="$1"
  local key="$2"
  grep -E "^\s*\"${key}\"\s*:" "$filepath" \
    | head -1 \
    | sed -E "s/^\s*\"${key}\"\s*:\s*\"([^\"]*)\".*/\1/" \
    || true
}

# ---------------------------------------------------------------------------
# JSON 輔助：取出所有頂層 key（僅取第一層，排除巢狀物件/陣列內的 key）
# 輸出：每行一個 key 名稱
# 實作說明：掃描 JSON 頂層縮排層次（以 2 個空格或 4 個空格為首的行視為頂層）
# 採用行縮排深度 0 或 1 的方式：只取 "key": 在第 1 縮排層的行（depth=1 indent）
# ---------------------------------------------------------------------------
json_get_top_level_keys() {
  local filepath="$1"
  # 只取縮排為 2 空格（1 level）的 "key": 行
  # 排除 { 與 [ 後面的行（即巢狀結構內部）
  grep -E '^\s{2}"[^"]+"\s*:' "$filepath" \
    | grep -oE '"[^"]+"\s*:' \
    | sed -E 's/"([^"]+)"\s*:/\1/' \
    || true
}

# ---------------------------------------------------------------------------
# AC1：驗證 plugin.json 必填欄位
# ---------------------------------------------------------------------------
validate_plugin_required_fields() {
  print_section "AC1：plugin.json 必填欄位驗證"

  local field
  for field in "${PLUGIN_REQUIRED_FIELDS[@]}"; do
    if json_has_key "$PLUGIN_JSON" "$field"; then
      print_pass "plugin.json：包含必填欄位「$field」"
    else
      print_error "plugin.json：缺少必填欄位「$field」"
    fi
  done
}

# ---------------------------------------------------------------------------
# AC2：驗證 marketplace.json 必填欄位
# ---------------------------------------------------------------------------
validate_marketplace_required_fields() {
  print_section "AC2：marketplace.json 必填欄位驗證"

  # 驗證 name 欄位
  local field
  for field in "${MARKETPLACE_REQUIRED_FIELDS[@]}"; do
    if json_has_key "$MARKETPLACE_JSON" "$field"; then
      print_pass "marketplace.json：包含必填欄位「$field」"
    else
      print_error "marketplace.json：缺少必填欄位「$field」"
    fi
  done

  # 驗證 plugins 陣列欄位
  if grep -qE '^\s*"plugins"\s*:\s*\[' "$MARKETPLACE_JSON"; then
    print_pass "marketplace.json：包含必填欄位「plugins」（陣列格式）"
  else
    print_error "marketplace.json：缺少必填欄位「plugins」（需為陣列格式）"
  fi
}

# ---------------------------------------------------------------------------
# AC3：驗證 version 欄位符合 semver 格式（major.minor.patch）
# ---------------------------------------------------------------------------
validate_version_semver() {
  print_section "AC3：version semver 格式驗證"

  if ! json_has_key "$PLUGIN_JSON" "version"; then
    print_info "plugin.json：version 欄位不存在，跳過 semver 格式驗證"
    return
  fi

  local version_value
  version_value=$(json_get_string_value "$PLUGIN_JSON" "version")

  if echo "$version_value" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    print_pass "plugin.json：version「$version_value」符合 semver 格式（major.minor.patch）"
  else
    print_error "plugin.json：version「$version_value」不符合 semver 格式（需為 major.minor.patch 三段純數字）"
  fi
}

# ---------------------------------------------------------------------------
# AC4：驗證 plugin.json 欄位白名單（白名單外的欄位觸發 WARNING）
# ---------------------------------------------------------------------------
validate_plugin_field_whitelist() {
  print_section "AC4：plugin.json 欄位白名單驗證"

  local all_keys
  all_keys=$(json_get_top_level_keys "$PLUGIN_JSON")

  if [ -z "$all_keys" ]; then
    print_info "plugin.json：無法提取頂層欄位，跳過白名單驗證"
    return
  fi

  local key
  while IFS= read -r key; do
    [ -z "$key" ] && continue
    local is_whitelisted=0
    local allowed_key
    for allowed_key in "${PLUGIN_WHITELIST[@]}"; do
      if [ "$key" = "$allowed_key" ]; then
        is_whitelisted=1
        break
      fi
    done

    if [ "$is_whitelisted" -eq 1 ]; then
      print_pass "plugin.json：欄位「$key」在白名單內"
    else
      print_warning "plugin.json：欄位「$key」不在白名單內（白名單：${PLUGIN_WHITELIST[*]}）"
      WARNING_COUNT=$((WARNING_COUNT + 1))
    fi
  done <<< "$all_keys"
}

# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------
main() {
  print_banner "validate-json.sh - JSON Schema 驗證"

  preflight_check

  validate_plugin_required_fields
  validate_marketplace_required_fields
  validate_version_semver
  validate_plugin_field_whitelist

  # 總結
  echo ""
  echo "=============================="
  if [ "$EXIT_CODE" -eq 0 ]; then
    if [ "$WARNING_COUNT" -gt 0 ]; then
      echo " 總結：JSON Schema 驗證通過，但有 $WARNING_COUNT 個 WARNING，請確認欄位白名單"
    else
      echo " 總結：JSON Schema 驗證全部通過"
    fi
  else
    echo " 總結：JSON Schema 驗證發現 $ERROR_COUNT 個 ERROR，請修正後重試"
  fi
  echo "=============================="

  exit "$EXIT_CODE"
}

main
