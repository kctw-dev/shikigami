#!/usr/bin/env bash
# scripts/validate-agents.sh
# US-T02：Agent 完整性驗證腳本
#
# 驗證 agents/ 下所有 .md 檔案的 frontmatter 是否合法：
#   AC1：掃描 agents/ 下所有 .md 檔案，輸出檔案清單，數量與實際一致
#   AC2：每個 agent .md 的 frontmatter 必須含 name、description、model 欄位
#   AC3：model 值必須為白名單之一：sonnet、haiku、opus（大小寫敏感）
#   AC4：description 欄位存在且值非空字串（空白字元視為空）
#   AC5：exit 0 = 全部通過，非 0 = 有 ERROR
#
# 使用方式：
#   bash scripts/validate-agents.sh
#   （在專案根目錄下執行；agents/ 目錄相對於 cwd）
#
# Exit code:
#   0 = 全部通過（PASS / INFO）
#   1 = 有 ERROR
#
# 依賴：bash >= 4, awk, grep

set -uo pipefail

source "$(dirname "$0")/lib/validate-helpers.sh"

# ---------------------------------------------------------------------------
# 常數
# ---------------------------------------------------------------------------
readonly AGENTS_DIR="agents"
readonly VALID_MODELS=("sonnet" "haiku" "opus")

# ---------------------------------------------------------------------------
# 狀態追蹤
# ---------------------------------------------------------------------------
EXIT_CODE=0
ERROR_COUNT=0
AGENT_COUNT=0

# ---------------------------------------------------------------------------
# 前置檢查：agents/ 目錄必須存在且非空
# ---------------------------------------------------------------------------
preflight_check() {
  if [ ! -d "$AGENTS_DIR" ]; then
    print_error "找不到目錄：$AGENTS_DIR"
    exit 1
  fi

  local md_count
  md_count=$(find "$AGENTS_DIR" -maxdepth 1 -name "*.md" -type f | wc -l | tr -d ' ')
  if [ "$md_count" -eq 0 ]; then
    print_error "$AGENTS_DIR/ 目錄中無 .md 檔案"
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# AC1：掃描 agents/ 下所有 .md 檔案，回傳檔案路徑列表（每行一個）
# 輸出：每行一個檔案路徑（已排序）
# ---------------------------------------------------------------------------
scan_agents() {
  find "$AGENTS_DIR" -maxdepth 1 -name "*.md" -type f | sort
}

# ---------------------------------------------------------------------------
# 從 agent .md 的 frontmatter 提取指定欄位的值
# 參數：$1 = 檔案路徑，$2 = 欄位名稱（如 model、description）
# 輸出：欄位的值（去除前後空白與引號），若無則輸出空字串
# ---------------------------------------------------------------------------
extract_frontmatter_value() {
  local filepath="$1"
  local field="$2"
  awk '/^---/{c++; if(c==2) exit} c==1' "$filepath" \
    | grep -E "^${field}[[:space:]]*:" \
    | sed "s/^${field}[[:space:]]*:[[:space:]]*//" \
    | sed 's/^"\(.*\)"$/\1/' \
    | sed "s/^'\(.*\)'$/\1/" \
    || true
}

# ---------------------------------------------------------------------------
# 檢查 model 值是否在合法白名單中（大小寫敏感完全字串比對）
# 參數：$1 = model 值
# 回傳：0 = 合法，1 = 不合法
# ---------------------------------------------------------------------------
is_valid_model() {
  local model_value="$1"
  local valid_model
  for valid_model in "${VALID_MODELS[@]}"; do
    if [ "$model_value" = "$valid_model" ]; then
      return 0
    fi
  done
  return 1
}

# ---------------------------------------------------------------------------
# 驗證單一 agent .md 檔案（AC2 + AC3 + AC4）
# 參數：$1 = agent .md 檔案路徑
# 副作用：可能修改全域 EXIT_CODE、ERROR_COUNT
# ---------------------------------------------------------------------------
validate_agent_file() {
  local agent_file="$1"
  local agent_name
  agent_name=$(basename "$agent_file" .md)

  print_section "驗證 $agent_name"

  # AC2：frontmatter 必須含 name 欄位
  if has_frontmatter_field "$agent_file" "name"; then
    print_pass "$agent_name：frontmatter 含 name 欄位"
  else
    print_error "$agent_name：frontmatter 缺少 name 欄位"
  fi

  # AC2：frontmatter 必須含 description 欄位
  local has_description=0
  if has_frontmatter_field "$agent_file" "description"; then
    print_pass "$agent_name：frontmatter 含 description 欄位"
    has_description=1
  else
    print_error "$agent_name：frontmatter 缺少 description 欄位"
  fi

  # AC2：frontmatter 必須含 model 欄位
  local has_model=0
  if has_frontmatter_field "$agent_file" "model"; then
    print_pass "$agent_name：frontmatter 含 model 欄位"
    has_model=1
  else
    print_error "$agent_name：frontmatter 缺少 model 欄位"
  fi

  # AC3：model 值必須在白名單中（大小寫敏感）
  if [ "$has_model" -eq 1 ]; then
    local model_value
    model_value=$(extract_frontmatter_value "$agent_file" "model")
    if is_valid_model "$model_value"; then
      print_pass "$agent_name：model 值合法（\"$model_value\"）"
    else
      print_error "$agent_name：model 值「$model_value」不在白名單（sonnet、haiku、opus）中"
    fi
  fi

  # AC4：description 欄位存在且值非空（含空白視為空）
  if [ "$has_description" -eq 1 ]; then
    local desc_value
    desc_value=$(extract_frontmatter_value "$agent_file" "description")
    # 去除空白字元後判斷是否為空
    local desc_trimmed
    desc_trimmed=$(echo "$desc_value" | tr -d '[:space:]')
    if [ -n "$desc_trimmed" ]; then
      print_pass "$agent_name：description 欄位非空"
    else
      print_error "$agent_name：description 欄位為空字串或僅含空白字元"
    fi
  fi
}

# ---------------------------------------------------------------------------
# 主掃描流程：AC1 掃描所有 agent .md 檔案，並逐一驗證
# ---------------------------------------------------------------------------
scan_and_validate_agents() {
  local agent_files
  agent_files=$(scan_agents)

  # AC1：輸出掃描到的檔案清單與數量
  print_section "AC1：掃描 $AGENTS_DIR/ 目錄"

  if [ -z "$agent_files" ]; then
    print_info "$AGENTS_DIR/ 目錄中無 .md 檔案，驗證跳過"
    return
  fi

  AGENT_COUNT=$(echo "$agent_files" | wc -l | tr -d ' ')
  echo "  找到 $AGENT_COUNT 個 Agent 檔案："
  while IFS= read -r f; do
    echo "    - $f"
  done <<< "$agent_files"

  # 逐一驗證每個 agent .md 檔案
  while IFS= read -r agent_file; do
    validate_agent_file "$agent_file"
  done <<< "$agent_files"
}

# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------
main() {
  print_banner "validate-agents.sh - Agent 完整性驗證"

  preflight_check

  scan_and_validate_agents

  # 總結
  echo ""
  echo "=============================="
  if [ "$EXIT_CODE" -eq 0 ]; then
    echo " 總結：Agent 完整性驗證全部通過（共 $AGENT_COUNT 個 Agent）"
  else
    echo " 總結：Agent 完整性驗證發現 $ERROR_COUNT 個 ERROR，請修正後重試"
  fi
  echo "=============================="

  exit "$EXIT_CODE"
}

main
