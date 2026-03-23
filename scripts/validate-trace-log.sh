#!/usr/bin/env bash
# scripts/validate-trace-log.sh
# #483 Sprint 126 — Trace Log 端到端驗證
#
# 依據 ADR-033（Structured Trace Log 架構）與 docs/km/trace-log-completeness-spec.md
# 驗證 docs/trace-logs/ 目錄下的 JSONL trace log 品質。
#
# 驗證項目：
#   AC1：JSONL 格式合法性（每行為合法 JSON 物件）
#   AC2：必要欄位存在（traceId/spanId/parentSpanId/agentRole/action/timestamp/status/sessionId）
#   AC3：parentSpanId 參照完整性（指向已知 spanId 或 null）
#   AC4：per-session 檔案命名格式（YYYY-MM-DD-{session-id}.jsonl）
#   AC5：status 欄位合法值（started|completed|failed）
#
# 使用方式：
#   bash scripts/validate-trace-log.sh                    # 驗證所有檔案
#   bash scripts/validate-trace-log.sh [FILE]             # 驗證指定檔案
#   bash scripts/validate-trace-log.sh --dir [DIR]        # 驗證指定目錄
#
# Exit code:
#   0 = 全部通過（PASS / INFO / WARNING）
#   1 = 有 ERROR
#
# 依賴：bash >= 4, python3（JSON 解析）
# 技術規範：ADR-033 + docs/km/trace-log-completeness-spec.md

set -uo pipefail

source "$(dirname "$0")/lib/validate-helpers.sh"

# ---------------------------------------------------------------------------
# 常數
# ---------------------------------------------------------------------------
readonly TRACE_LOGS_DIR="docs/trace-logs"
readonly REQUIRED_FIELDS=("traceId" "spanId" "parentSpanId" "agentRole" "action" "timestamp" "status" "sessionId")
readonly VALID_STATUS_VALUES=("started" "completed" "failed")
# per-session 檔案命名格式：YYYY-MM-DD-{session-id}.jsonl
readonly NAMING_PATTERN='^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-zA-Z0-9_-]+\.jsonl$'

# ---------------------------------------------------------------------------
# 狀態追蹤
# ---------------------------------------------------------------------------
EXIT_CODE=0
ERROR_COUNT=0
WARNING_COUNT=0
TOTAL_FILES=0
TOTAL_SPANS=0
COMPLETE_SPANS=0

# ---------------------------------------------------------------------------
# 前置條件：確認 python3 存在
# ---------------------------------------------------------------------------
check_dependencies() {
  if ! command -v python3 &>/dev/null; then
    print_error "缺少依賴：python3 未安裝，無法進行 JSON 解析"
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# AC4：驗證 per-session 檔案命名格式
# 參數：$1 = 檔案名稱（basename）
# ---------------------------------------------------------------------------
validate_filename() {
  local filename="$1"
  if echo "$filename" | grep -qE "$NAMING_PATTERN"; then
    print_pass "命名格式：$filename 符合 per-session 格式（YYYY-MM-DD-{session-id}.jsonl）"
  else
    print_error "命名格式：$filename 不符合 per-session 格式，應為 YYYY-MM-DD-{session-id}.jsonl"
  fi
}

# ---------------------------------------------------------------------------
# 驗證單一 JSONL 檔案
# 參數：$1 = 完整檔案路徑
# ---------------------------------------------------------------------------
validate_file() {
  local filepath="$1"
  local filename
  filename=$(basename "$filepath")
  local file_error=0
  local line_num=0
  local file_spans=0
  local file_complete_spans=0
  local -a seen_span_ids=()

  print_section "檔案：$filepath"
  TOTAL_FILES=$((TOTAL_FILES + 1))

  # AC4：檔案命名格式
  validate_filename "$filename"

  # 檢查檔案是否為空
  if [ ! -s "$filepath" ]; then
    print_info "檔案為空，跳過內容驗證"
    return
  fi

  # 第一輪：收集所有 spanId（用於 AC3 參照完整性）
  local -a all_span_ids=()
  while IFS= read -r line || [ -n "$line" ]; do
    [ -z "$line" ] && continue
    local span_id
    span_id=$(python3 -c "
import json, sys
try:
    obj = json.loads(sys.argv[1])
    print(obj.get('spanId', ''))
except:
    print('')
" "$line" 2>/dev/null || true)
    [ -n "$span_id" ] && all_span_ids+=("$span_id")
  done < "$filepath"

  # 第二輪：逐行驗證
  while IFS= read -r line || [ -n "$line" ]; do
    line_num=$((line_num + 1))
    [ -z "$line" ] && continue

    file_spans=$((file_spans + 1))

    # AC1：JSONL 格式合法性
    local parse_result
    parse_result=$(python3 -c "
import json, sys
try:
    obj = json.loads(sys.argv[1])
    if isinstance(obj, dict):
        print('OK')
    else:
        print('NOT_OBJECT')
except json.JSONDecodeError as e:
    print(f'INVALID_JSON:{e}')
" "$line" 2>/dev/null || echo "PARSE_ERROR")

    if [[ "$parse_result" == "NOT_OBJECT" ]]; then
      print_error "行 $line_num：合法 JSON 但非物件格式（需為 {...}）"
      file_error=1
      continue
    elif [[ "$parse_result" != "OK" ]]; then
      print_error "行 $line_num：非合法 JSON — ${parse_result#INVALID_JSON:}"
      file_error=1
      continue
    fi

    # AC2：必要欄位存在性 + AC3 parentSpanId + AC5 status
    local validation_result
    validation_result=$(python3 -c "
import json, sys

line = sys.argv[1]
all_span_ids = sys.argv[2].split(',') if sys.argv[2] else []

required = ['traceId', 'spanId', 'parentSpanId', 'agentRole', 'action', 'timestamp', 'status', 'sessionId']
valid_status = ['started', 'completed', 'failed']

try:
    obj = json.loads(line)
    errors = []
    warnings = []

    # AC2：必要欄位檢查
    for field in required:
        if field not in obj:
            errors.append(f'MISSING_FIELD:{field}')

    # AC5：status 合法值
    if 'status' in obj and obj['status'] not in valid_status:
        errors.append(f'INVALID_STATUS:{obj[\"status\"]}')

    # AC3：parentSpanId 參照完整性
    if 'parentSpanId' in obj and obj['parentSpanId'] is not None:
        parent_id = obj['parentSpanId']
        if parent_id not in all_span_ids:
            warnings.append(f'ORPHAN_PARENT:{parent_id}')

    for e in errors:
        print(f'ERROR:{e}')
    for w in warnings:
        print(f'WARNING:{w}')
    if not errors:
        print('COMPLETE')
except Exception as e:
    print(f'ERROR:PARSE_FAILED:{e}')
" "$line" "$(IFS=','; echo "${all_span_ids[*]}")" 2>/dev/null || echo "ERROR:PYTHON_FAILED")

    local is_complete=1
    while IFS= read -r check_line; do
      [ -z "$check_line" ] && continue
      if [[ "$check_line" == ERROR:MISSING_FIELD:* ]]; then
        local field_name="${check_line#ERROR:MISSING_FIELD:}"
        print_error "行 $line_num：缺少必要欄位「$field_name」"
        file_error=1
        is_complete=0
      elif [[ "$check_line" == ERROR:INVALID_STATUS:* ]]; then
        local status_val="${check_line#ERROR:INVALID_STATUS:}"
        print_error "行 $line_num：status 值「$status_val」不合法（允許：started|completed|failed）"
        file_error=1
        is_complete=0
      elif [[ "$check_line" == ERROR:* ]]; then
        print_error "行 $line_num：驗證錯誤 — ${check_line#ERROR:}"
        file_error=1
        is_complete=0
      elif [[ "$check_line" == WARNING:ORPHAN_PARENT:* ]]; then
        local parent_id="${check_line#WARNING:ORPHAN_PARENT:}"
        print_warning "行 $line_num：parentSpanId「$parent_id」未在本檔案中找到對應 spanId（可能為跨 session 引用）"
        WARNING_COUNT=$((WARNING_COUNT + 1))
      fi
    done <<< "$validation_result"

    if [ "$is_complete" -eq 1 ]; then
      file_complete_spans=$((file_complete_spans + 1))
    fi

  done < "$filepath"

  TOTAL_SPANS=$((TOTAL_SPANS + file_spans))
  COMPLETE_SPANS=$((COMPLETE_SPANS + file_complete_spans))

  # 計算本檔案完整性率
  if [ "$file_spans" -gt 0 ]; then
    local completeness_pct
    completeness_pct=$(python3 -c "print(f'{$file_complete_spans / $file_spans * 100:.1f}')" 2>/dev/null || echo "N/A")
    if [ "$file_complete_spans" -eq "$file_spans" ]; then
      print_pass "完整性率：${completeness_pct}%（$file_complete_spans/$file_spans span 包含全部 8 個必要欄位）"
    elif [ "$file_error" -eq 0 ]; then
      print_warning "完整性率：${completeness_pct}%（$file_complete_spans/$file_spans span 完整）"
      WARNING_COUNT=$((WARNING_COUNT + 1))
    else
      print_error "完整性率：${completeness_pct}%（$file_complete_spans/$file_spans span 完整），存在必要欄位缺失"
    fi
  fi
}

# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------
main() {
  print_banner "validate-trace-log.sh - Trace Log 品質驗證（ADR-033）"

  check_dependencies

  # 決定驗證目標
  local target_dir="$TRACE_LOGS_DIR"
  local specific_file=""

  if [ "${1:-}" = "--dir" ] && [ -n "${2:-}" ]; then
    target_dir="$2"
  elif [ -n "${1:-}" ] && [ "${1:-}" != "--dir" ]; then
    specific_file="$1"
  fi

  if [ -n "$specific_file" ]; then
    # 驗證指定檔案
    if [ ! -f "$specific_file" ]; then
      print_error "找不到指定檔案：$specific_file"
      exit 1
    fi
    validate_file "$specific_file"
  else
    # 驗證目錄下所有 .jsonl 檔案
    if [ ! -d "$target_dir" ]; then
      print_error "找不到 trace-logs 目錄：$target_dir"
      print_info "請確認 docs/trace-logs/ 目錄存在（參見 ADR-033）"
      exit 1
    fi

    local jsonl_files=()
    while IFS= read -r -d $'\0' f; do
      jsonl_files+=("$f")
    done < <(find "$target_dir" -maxdepth 1 -name "*.jsonl" ! -name ".gitkeep" -print0 2>/dev/null | sort -z)

    if [ "${#jsonl_files[@]}" -eq 0 ]; then
      print_info "docs/trace-logs/ 目錄下無 .jsonl 檔案，跳過驗證"
      print_info "（Trace log 由 Agent 執行時寫入，空目錄為正常初始狀態）"
      echo ""
      echo "=============================="
      echo " 總結：無 trace log 檔案可驗證（正常）"
      echo "=============================="
      exit 0
    fi

    for f in "${jsonl_files[@]}"; do
      validate_file "$f"
    done
  fi

  # 全局總結
  echo ""
  echo "=============================="
  echo " Trace Log 驗證摘要"
  echo " 驗證檔案數：$TOTAL_FILES"
  echo " 總 span 數：$TOTAL_SPANS"
  echo " 完整 span 數：$COMPLETE_SPANS"

  if [ "$TOTAL_SPANS" -gt 0 ]; then
    local overall_pct
    overall_pct=$(python3 -c "print(f'{$COMPLETE_SPANS / $TOTAL_SPANS * 100:.1f}')" 2>/dev/null || echo "N/A")
    echo " 整體必要欄位覆蓋率：${overall_pct}%"
  fi

  if [ "$EXIT_CODE" -eq 0 ]; then
    if [ "$WARNING_COUNT" -gt 0 ]; then
      echo " 結果：通過（$WARNING_COUNT 個 WARNING）"
    else
      echo " 結果：全部通過 PASS"
    fi
  else
    echo " 結果：FAIL（$ERROR_COUNT 個 ERROR）"
  fi
  echo "=============================="

  exit "$EXIT_CODE"
}

main "${@}"
