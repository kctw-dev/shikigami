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

# ---------------------------------------------------------------------------
# 前置檢查：skills/ 目錄必須存在
# ---------------------------------------------------------------------------
preflight_check() {
  if [ ! -d "$SKILLS_DIR" ]; then
    print_error "找不到目錄：$SKILLS_DIR"
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# AC1：掃描 skills/ 下所有直接子目錄，回傳目錄路徑列表（每行一個）
# 輸出：每行一個子目錄路徑（已排序）
# ---------------------------------------------------------------------------
scan_skills() {
  find "$SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d | sort
}

# ---------------------------------------------------------------------------
# 從 SKILL.md 的 frontmatter 提取 name 欄位值
# 參數：$1 = SKILL.md 檔案路徑
# 輸出：name 欄位的值（去除前後空白），若無則輸出空字串
# ---------------------------------------------------------------------------
extract_frontmatter_name() {
  local filepath="$1"
  awk '/^---/{c++; if(c==2) exit} c==1' "$filepath" \
    | grep -E '^name[[:space:]]*:' \
    | sed 's/^name[[:space:]]*:[[:space:]]*//' \
    | tr -d '"'"'" \
    | tr -d '[:space:]' \
    || true
}

# ---------------------------------------------------------------------------
# 驗證單一 Skill 目錄（AC2 + AC3 + AC4）
# 參數：$1 = skill 目錄路徑（如 skills/git-workflow）
# 副作用：可能修改全域 EXIT_CODE、ERROR_COUNT
# ---------------------------------------------------------------------------
validate_skill_dir() {
  local skill_dir="$1"
  local skill_name
  skill_name=$(basename "$skill_dir")
  local skill_md="$skill_dir/SKILL.md"

  print_section "驗證 $skill_name"

  # AC4 + AC2（前半）：SKILL.md 必須存在
  if [ ! -f "$skill_md" ]; then
    print_error "$skill_name：找不到 SKILL.md（空目錄或缺少 SKILL.md）"
    return
  fi

  # AC2：frontmatter 必須含 name 欄位
  local has_name=0
  if has_frontmatter_field "$skill_md" "name"; then
    print_pass "$skill_name：frontmatter 含 name 欄位"
    has_name=1
  else
    print_error "$skill_name：frontmatter 缺少 name 欄位"
  fi

  # AC2：frontmatter 必須含 description 欄位
  if has_frontmatter_field "$skill_md" "description"; then
    print_pass "$skill_name：frontmatter 含 description 欄位"
  else
    print_error "$skill_name：frontmatter 缺少 description 欄位"
  fi

  # AC3：name 值必須與目錄名稱完全一致（大小寫敏感）
  if [ "$has_name" -eq 1 ]; then
    local name_value
    name_value=$(extract_frontmatter_name "$skill_md")
    if [ "$name_value" = "$skill_name" ]; then
      print_pass "$skill_name：name 值與目錄名稱一致（\"$name_value\"）"
    else
      print_error "$skill_name：name 值「$name_value」與目錄名稱「$skill_name」不一致"
    fi
  fi
}

# ---------------------------------------------------------------------------
# 主掃描流程：AC1 掃描所有 Skill 目錄，並逐一驗證
# ---------------------------------------------------------------------------
scan_and_validate_skills() {
  local skill_dirs
  skill_dirs=$(scan_skills)

  # AC1：輸出掃描到的目錄清單與數量
  print_section "AC1：掃描 $SKILLS_DIR/ 目錄"

  if [ -z "$skill_dirs" ]; then
    print_info "$SKILLS_DIR/ 目錄中無子目錄，驗證跳過"
    return
  fi

  SKILL_COUNT=$(echo "$skill_dirs" | wc -l | tr -d ' ')
  echo "  找到 $SKILL_COUNT 個 Skill 目錄："
  while IFS= read -r d; do
    echo "    - $d"
  done <<< "$skill_dirs"

  # 逐一驗證每個 Skill 目錄
  while IFS= read -r skill_dir; do
    validate_skill_dir "$skill_dir"
  done <<< "$skill_dirs"
}

# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------
main() {
  print_banner "validate-skills.sh - Skill 完整性驗證"

  preflight_check

  scan_and_validate_skills

  # 總結
  echo ""
  echo "=============================="
  if [ "$EXIT_CODE" -eq 0 ]; then
    echo " 總結：Skill 完整性驗證全部通過（共 $SKILL_COUNT 個 Skill）"
  else
    echo " 總結：Skill 完整性驗證發現 $ERROR_COUNT 個 ERROR，請修正後重試"
  fi
  echo "=============================="

  exit "$EXIT_CODE"
}

main
