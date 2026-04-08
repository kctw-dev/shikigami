#!/usr/bin/env bash
# scripts/validate-xrefs.sh
# Story #949：交叉引用驗證腳本（含 skill-to-skill 交叉引用路徑驗證）
#
# 掃描倉庫中所有 .md 檔案的 shikigami:[a-z-]+ 引用，驗證對應資源存在。
# 包括：
#   - 頂層 .md 中的 skill/agent/command 引用
#   - skills/*/references/*.md 內的 skill-to-skill 交叉引用
#
# AC1：掃描所有 .md 的 shikigami:[a-z-]+ 引用（包含 references/*.md）
# AC2：驗證引用路徑存在 — skills/<name>/SKILL.md、agents/<name>.md、commands/<name>.md
# AC3：broken reference 輸出格式 ERROR: <file>:<line>: broken reference 'shikigami:<name>'
# AC4：exit 0 = 無 broken reference，非 0 = 至少一個
#
# 使用方式：
#   bash scripts/validate-xrefs.sh
#
# Exit code:
#   0 = 全部通過
#   1 = 有 broken reference
#
# 依賴：bash >= 4, grep

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
REF_COUNT=0
FILE_COUNT=0

# ---------------------------------------------------------------------------
# 前置檢查
# ---------------------------------------------------------------------------
if [[ ! -d "$SKILLS_DIR" ]]; then
  print_error "skills/ 目錄不存在"
  exit 1
fi

# ---------------------------------------------------------------------------
# 主邏輯：掃描所有 .md 檔案的 shikigami: 引用
# ---------------------------------------------------------------------------
print_banner "US-T05：交叉引用驗證"

# 收集所有 .md 檔案
while IFS= read -r md_file; do
  FILE_COUNT=$((FILE_COUNT + 1))

  # 逐行掃描 shikigami:[a-z-]+ 引用
  line_num=0
  while IFS= read -r line; do
    line_num=$((line_num + 1))

    # 提取該行所有 shikigami:xxx 引用
    while [[ "$line" =~ shikigami:([a-z][-a-z]*) ]]; do
      ref_name="${BASH_REMATCH[1]}"
      REF_COUNT=$((REF_COUNT + 1))

      # 跳過 placeholder 引用（如 shikigami:xxx）
      if [[ "$ref_name" == "xxx" ]]; then
        line="${line#*shikigami:${ref_name}}"
        continue
      fi

      # 驗證對應 skill、agent 或 command 存在
      if [[ ! -f "${SKILLS_DIR}/${ref_name}/SKILL.md" ]] \
        && [[ ! -f "agents/${ref_name}.md" ]] \
        && [[ ! -f "commands/${ref_name}.md" ]]; then
        print_error "${md_file}:${line_num}: broken reference 'shikigami:${ref_name}'"
      fi

      # 移除已匹配的部分，繼續找下一個
      line="${line#*shikigami:${ref_name}}"
    done
  done < "$md_file"

done < <(find . -name "*.md" -not -path "./.git/*" | sort)

# ---------------------------------------------------------------------------
# 摘要
# ---------------------------------------------------------------------------
print_section "摘要"
print_info "掃描 ${FILE_COUNT} 個 .md 檔案，找到 ${REF_COUNT} 個 shikigami:xxx 引用"

if [[ $ERROR_COUNT -gt 0 ]]; then
  print_info "${ERROR_COUNT} 個 broken reference"
else
  print_pass "所有引用均指向存在的 skill"
fi

exit "$EXIT_CODE"
