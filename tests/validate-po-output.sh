#!/usr/bin/env bash
# tests/validate-po-output.sh
# TD-002：PO subagent 輸出格式 JSON Schema 正式驗證腳本
# AC2：schema check 步驟，含工具存在性檢查與 graceful fallback
#
# 用法：
#   ./tests/validate-po-output.sh <json_file>
#   echo '{"reply":"..."}'  | ./tests/validate-po-output.sh
#
# 說明：
#   若 JSON Schema 驗證工具（ajv / jsonschema / check-jsonschema）不可用，
#   則輸出警告並執行 graceful fallback（基本結構檢查），不阻斷 Sprint 執行。

set -uo pipefail

# ---------------------------------------------------------------------------
# 常數
# ---------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEMA_FILE="$REPO_ROOT/schemas/po-subagent-output.schema.json"

# 退出碼定義
EXIT_PASS=0
EXIT_FAIL=1
EXIT_SCHEMA_TOOL_UNAVAILABLE=2   # graceful fallback：工具不可用，僅警告

# ---------------------------------------------------------------------------
# 工具函式
# ---------------------------------------------------------------------------

log_info()    { echo "[INFO] $*"; }
log_warn()    { echo "[WARN] $*" >&2; }
log_error()   { echo "[ERROR] $*" >&2; }
log_pass()    { echo "[PASS] $*"; }
log_fail()    { echo "[FAIL] $*" >&2; }

# ---------------------------------------------------------------------------
# 步驟 0：確認 Schema 檔案存在
# ---------------------------------------------------------------------------
check_schema_file() {
  if [ ! -f "$SCHEMA_FILE" ]; then
    log_error "Schema 檔案不存在：$SCHEMA_FILE"
    log_error "請確認 schemas/po-subagent-output.schema.json 已建立（TD-002 AC1）"
    return $EXIT_FAIL
  fi
  log_info "Schema 檔案確認：$SCHEMA_FILE"
  return $EXIT_PASS
}

# ---------------------------------------------------------------------------
# 步驟 1：工具存在性檢查
# 優先順序：ajv > check-jsonschema > python3 jsonschema
# ---------------------------------------------------------------------------
detect_validator() {
  if command -v ajv &>/dev/null; then
    echo "ajv"
    return $EXIT_PASS
  fi

  if command -v check-jsonschema &>/dev/null; then
    echo "check-jsonschema"
    return $EXIT_PASS
  fi

  if command -v python3 &>/dev/null && python3 -c "import jsonschema" &>/dev/null 2>&1; then
    echo "python3-jsonschema"
    return $EXIT_PASS
  fi

  echo "none"
  return $EXIT_SCHEMA_TOOL_UNAVAILABLE
}

# ---------------------------------------------------------------------------
# 步驟 2：取得待驗證 JSON（從參數或 stdin）
# ---------------------------------------------------------------------------
get_input_json() {
  local input_file="${1:-}"

  if [ -n "$input_file" ] && [ -f "$input_file" ]; then
    cat "$input_file"
  elif [ ! -t 0 ]; then
    # 從 stdin 讀取
    cat
  else
    log_error "未提供 JSON 輸入。用法：$0 <json_file> 或透過 stdin 傳入"
    return $EXIT_FAIL
  fi
}

# ---------------------------------------------------------------------------
# 步驟 3：基本結構驗證（graceful fallback）
# 不依賴外部工具，使用 python3 內建 json 模組或 bash 基本檢查
# ---------------------------------------------------------------------------
fallback_basic_check() {
  local json_content="$1"

  log_warn "JSON Schema 驗證工具不可用，執行 graceful fallback（基本結構檢查）"
  log_warn "建議安裝驗證工具：pip install check-jsonschema 或 npm install -g ajv-cli"
  log_warn "本次僅執行基本 JSON 格式與必要欄位檢查，不執行完整 Schema 驗證"

  # 使用 python3 內建 json 模組進行基本 JSON 格式驗證
  if command -v python3 &>/dev/null; then
    local parse_result
    parse_result=$(echo "$json_content" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    # 檢查必要欄位（對應 schema 的 required 欄位）
    required_fields = ['reply', 'tone', 'reviewed_by']
    missing = [f for f in required_fields if f not in data]
    if missing:
        print(f'MISSING_FIELDS:{','.join(missing)}')
        sys.exit(1)
    print('BASIC_OK')
except json.JSONDecodeError as e:
    print(f'JSON_PARSE_ERROR:{e}')
    sys.exit(1)
" 2>&1)

    if echo "$parse_result" | grep -q "^BASIC_OK$"; then
      log_warn "[FALLBACK-PASS] 基本結構檢查通過（未執行完整 Schema 驗證）"
      log_warn "人工審查觸發：請人工確認 PO subagent 輸出格式符合 schemas/po-subagent-output.schema.json"
      return $EXIT_SCHEMA_TOOL_UNAVAILABLE
    elif echo "$parse_result" | grep -q "^MISSING_FIELDS:"; then
      local missing_fields
      missing_fields=$(echo "$parse_result" | sed 's/^MISSING_FIELDS://')
      log_fail "[FALLBACK-FAIL] 必要欄位缺失：$missing_fields"
      return $EXIT_FAIL
    else
      log_fail "[FALLBACK-FAIL] JSON 格式錯誤：$parse_result"
      return $EXIT_FAIL
    fi
  else
    # 無 python3：最低限度驗證（確認為 JSON 物件）
    if echo "$json_content" | grep -qE '^\s*\{'; then
      log_warn "[FALLBACK-WARN] 無法執行 JSON 解析（python3 不可用），僅確認輸入以 '{' 開頭"
      log_warn "人工審查觸發：請人工確認 PO subagent 輸出格式符合 schemas/po-subagent-output.schema.json"
      return $EXIT_SCHEMA_TOOL_UNAVAILABLE
    else
      log_fail "[FALLBACK-FAIL] 輸入不符合 JSON 物件格式"
      return $EXIT_FAIL
    fi
  fi
}

# ---------------------------------------------------------------------------
# 步驟 4：執行完整 Schema 驗證
# ---------------------------------------------------------------------------
run_schema_validation() {
  local validator="$1"
  local json_content="$2"
  local tmp_json
  tmp_json=$(mktemp)
  echo "$json_content" > "$tmp_json"

  local result=0

  case "$validator" in
    ajv)
      if ajv validate -s "$SCHEMA_FILE" -d "$tmp_json" 2>&1; then
        log_pass "[SCHEMA-PASS] ajv Schema 驗證通過"
      else
        log_fail "[SCHEMA-FAIL] ajv Schema 驗證失敗，請人工審查 PO subagent 輸出"
        log_warn "警告訊息：PO subagent 輸出不符合 schemas/po-subagent-output.schema.json"
        log_warn "人工審查觸發條件：Schema 驗證失敗（詳見 skills/sprint-execution/SKILL.md §3 Schema 驗證失敗回退說明）"
        result=$EXIT_FAIL
      fi
      ;;

    check-jsonschema)
      if check-jsonschema --schemafile "$SCHEMA_FILE" "$tmp_json" 2>&1; then
        log_pass "[SCHEMA-PASS] check-jsonschema Schema 驗證通過"
      else
        log_fail "[SCHEMA-FAIL] check-jsonschema Schema 驗證失敗，請人工審查 PO subagent 輸出"
        log_warn "警告訊息：PO subagent 輸出不符合 schemas/po-subagent-output.schema.json"
        log_warn "人工審查觸發條件：Schema 驗證失敗（詳見 skills/sprint-execution/SKILL.md §3 Schema 驗證失敗回退說明）"
        result=$EXIT_FAIL
      fi
      ;;

    python3-jsonschema)
      if python3 -c "
import json, jsonschema, sys
with open('$SCHEMA_FILE') as sf:
    schema = json.load(sf)
with open('$tmp_json') as df:
    data = json.load(df)
try:
    jsonschema.validate(instance=data, schema=schema)
    print('[SCHEMA-PASS] python3 jsonschema 驗證通過')
except jsonschema.exceptions.ValidationError as e:
    print(f'[SCHEMA-FAIL] 驗證錯誤：{e.message}', file=sys.stderr)
    sys.exit(1)
" 2>&1; then
        log_pass "python3 jsonschema Schema 驗證通過"
      else
        log_fail "[SCHEMA-FAIL] python3 jsonschema Schema 驗證失敗，請人工審查 PO subagent 輸出"
        log_warn "警告訊息：PO subagent 輸出不符合 schemas/po-subagent-output.schema.json"
        log_warn "人工審查觸發條件：Schema 驗證失敗（詳見 skills/sprint-execution/SKILL.md §3 Schema 驗證失敗回退說明）"
        result=$EXIT_FAIL
      fi
      ;;
  esac

  rm -f "$tmp_json"
  return $result
}

# ---------------------------------------------------------------------------
# 主程式
# ---------------------------------------------------------------------------
main() {
  local input_file="${1:-}"

  echo "=== PO subagent 輸出 JSON Schema 驗證 ==="
  echo "Schema：$SCHEMA_FILE"
  echo ""

  # 步驟 0：確認 Schema 檔案
  if ! check_schema_file; then
    exit $EXIT_FAIL
  fi

  # 取得 JSON 輸入
  local json_content
  if ! json_content=$(get_input_json "$input_file"); then
    exit $EXIT_FAIL
  fi

  # 步驟 1：工具存在性檢查
  local validator
  validator=$(detect_validator)
  local tool_status=$?

  echo "驗證工具：$validator"
  echo ""

  if [ "$validator" = "none" ] || [ $tool_status -eq $EXIT_SCHEMA_TOOL_UNAVAILABLE ]; then
    # Graceful fallback：工具不可用，執行基本結構檢查
    fallback_basic_check "$json_content"
    local fallback_result=$?
    echo ""
    if [ $fallback_result -eq $EXIT_FAIL ]; then
      echo "=== 結果：FAIL（基本結構檢查失敗）==="
      exit $EXIT_FAIL
    else
      echo "=== 結果：WARN（graceful fallback 執行，建議安裝驗證工具）==="
      # 不阻斷執行（graceful fallback 成功）
      exit $EXIT_PASS
    fi
  fi

  # 步驟 2：執行完整 Schema 驗證
  if run_schema_validation "$validator" "$json_content"; then
    echo ""
    echo "=== 結果：PASS ==="
    exit $EXIT_PASS
  else
    echo ""
    echo "=== 結果：FAIL（Schema 驗證失敗，觸發人工審查）==="
    exit $EXIT_FAIL
  fi
}

main "$@"
