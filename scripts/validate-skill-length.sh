#!/usr/bin/env bash
# scripts/validate-skill-length.sh
# #555：Skill 行數自動偵測腳本
#
# 掃描 skills/*/SKILL.md，偵測超出行數上限的 Skill 並輸出 WARNING。
# 一般 Skill 上限：350 行；大型 Skill 上限：400 行。
#
# Exit code:
#   0 = 完成（無論是否有 WARNING）
#
# Source: SDD-000 §2.1 Skill Layer

set -uo pipefail

# ---------------------------------------------------------------------------
# 閾值定義
# Source: SDD-000 §2.1 Skill Layer
# ---------------------------------------------------------------------------
DEFAULT_MAX_LINES=350
LARGE_SKILL_MAX_LINES=400

# ---------------------------------------------------------------------------
# 大型 Skill 清單（新增大型 Skill 只需修改此陣列）
# ---------------------------------------------------------------------------
LARGE_SKILLS=(
  "cruise"
  "sprint-execution"
  "sprint-planning"
  "scrum-master"
)

# ---------------------------------------------------------------------------
# 掃描目錄（可由環境變數覆蓋，供測試使用）
# ---------------------------------------------------------------------------
SKILLS_DIR="${SKILLS_DIR:-skills}"

# ---------------------------------------------------------------------------
# 輔助函式
# ---------------------------------------------------------------------------
is_large_skill() {
  local skill_name="$1"
  for large in "${LARGE_SKILLS[@]}"; do
    if [[ "$skill_name" == "$large" ]]; then
      return 0
    fi
  done
  return 1
}

# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------
WARN_COUNT=0

for skill_file in "${SKILLS_DIR}"/*/SKILL.md; do
  if [[ ! -f "$skill_file" ]]; then
    continue
  fi

  skill_name="$(basename "$(dirname "$skill_file")")"
  line_count=$(wc -l < "$skill_file")

  if is_large_skill "$skill_name"; then
    max_lines=$LARGE_SKILL_MAX_LINES
  else
    max_lines=$DEFAULT_MAX_LINES
  fi

  if [[ $line_count -gt $max_lines ]]; then
    echo "[WARN] ${skill_file}: ${line_count} lines (max ${max_lines})"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi
done

exit 0
