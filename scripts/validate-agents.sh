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

# TODO: 骨架階段 - 尚未實作 extract_frontmatter_value 與 validate_agent_file

# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------
main() {
  print_banner "validate-agents.sh - Agent 完整性驗證"

  preflight_check

  # TODO: 骨架階段 - 尚未實作完整掃描與驗證流程

  echo ""
  echo "=============================="
  echo " 總結：骨架階段，尚未完成驗證"
  echo "=============================="

  exit "$EXIT_CODE"
}

main
