#!/usr/bin/env bash
# scripts/validate-skills.sh
# US-T01：Skill 完整性驗證腳本
#
# 驗證 skills/ 下所有直接子目錄的 SKILL.md 是否合法：
#   AC1：掃描 skills/ 下所有子目錄，輸出目錄清單，數量與實際一致
#   AC2：每個 Skill 目錄下必須存在 SKILL.md，且 frontmatter 含 name 與 description 欄位
#   AC3：frontmatter 的 name 值必須與目錄名稱完全一致（大小寫敏感）
#   AC4：空目錄（無 SKILL.md）報錯，而非靜默略過
#   AC5：exit 0 = 全部通過，非 0 = 有 ERROR
#
# 使用方式：
#   bash scripts/validate-skills.sh
#   （在專案根目錄下執行；skills/ 目錄相對於 cwd）
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
readonly SKILLS_DIR="skills"

# ---------------------------------------------------------------------------
# 狀態追蹤
# ---------------------------------------------------------------------------
EXIT_CODE=0
ERROR_COUNT=0
SKILL_COUNT=0
PASS_COUNT=0

# ---------------------------------------------------------------------------
# 前置檢查：skills/ 目錄必須存在
# ---------------------------------------------------------------------------
preflight_check() {
  if [ ! -d "$SKILLS_DIR" ]; then
    echo "[ERROR] 找不到目錄：$SKILLS_DIR"
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# main 框架（骨架，驗證邏輯待補）
# ---------------------------------------------------------------------------
main() {
  print_banner "validate-skills.sh - Skill 完整性驗證"

  preflight_check

  echo ""
  echo "（骨架階段：驗證邏輯尚未實作）"

  exit "$EXIT_CODE"
}

main
