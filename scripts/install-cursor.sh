#!/usr/bin/env bash
# install-cursor.sh — 自動安裝 Shikigami Cursor Rules 適配層
# US-191：支援 Cursor 平台安裝（Sprint 72）
#
# 使用方式：
#   bash scripts/install-cursor.sh
#
# 此腳本將 Shikigami Skills 轉換為 Cursor Rules（.cursor/rules/*.mdc），
# 實現 Shikigami 在 Cursor 平台的核心工作流支援。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CURSOR_DIR="${PROJECT_ROOT}/.cursor"
RULES_DIR="${CURSOR_DIR}/rules"
SKILLS_DIR="${PROJECT_ROOT}/skills"

# Skills to install as Cursor Rules
# scrum-master 設為 alwaysApply: true（替代 SessionStart Hook）
# 其餘設為 alwaysApply: false
ALWAYS_APPLY_SKILLS=("scrum-master")
SKILLS=(
  "sprint-planning"
  "sprint-execution"
  "sprint-review"
  "backlog-management"
  "architecture-decision"
  "quality-gate"
  "security-review"
  "deployment-readiness"
  "systematic-debugging"
  "dispel"
  "git-workflow"
  "issue-management"
  "health-check"
  "onboarding"
  "shoot"
  "escalation"
  "architect"
  "qa-engineer"
  "schedule"
  "ux-agent"
  "ui-agent"
  "vision-critic"
)

echo "=== Shikigami Cursor Adapter 安裝 ==="
echo "目標目錄：${CURSOR_DIR}"
echo ""

# 1. 建立目錄結構
echo "[1/4] 建立 .cursor/ 目錄結構..."
mkdir -p "${RULES_DIR}"
echo "      ✓ ${RULES_DIR}"

# 2. 建立 skills symlink（可選，供直接引用）
if [ ! -e "${CURSOR_DIR}/skills" ]; then
  ln -s ../skills "${CURSOR_DIR}/skills"
  echo "      ✓ .cursor/skills -> ../skills (symlink 建立)"
else
  echo "      ✓ .cursor/skills symlink 已存在，跳過"
fi

# 3. 安裝 alwaysApply Skills（Scrum Master）
echo "[2/4] 安裝常駐 Rules（alwaysApply: true）..."
for skill in "${ALWAYS_APPLY_SKILLS[@]}"; do
  skill_file="${SKILLS_DIR}/${skill}/SKILL.md"
  rule_file="${RULES_DIR}/shikigami-${skill}.mdc"

  if [ ! -f "${skill_file}" ]; then
    echo "      ⚠️  ${skill}/SKILL.md 不存在，跳過"
    continue
  fi

  # 取得 Skill 的 description（從 SKILL.md frontmatter）
  description=$(grep -m1 "^description:" "${skill_file}" 2>/dev/null | sed 's/^description: *"//' | sed 's/"$//' || echo "${skill}")

  # 寫入 .mdc 檔案
  {
    echo "---"
    echo "description: \"Shikigami ${skill} — ${description}\""
    echo "alwaysApply: true"
    echo "---"
    echo ""
    # 跳過原始 SKILL.md 的 frontmatter（--- ... ---）
    awk '/^---/{if(++count==2){found=1;next}} found{print}' "${skill_file}"
  } > "${rule_file}"

  echo "      ✓ shikigami-${skill}.mdc (alwaysApply: true)"
done

# 4. 安裝其他 Skills
echo "[3/4] 安裝 Skill Rules（alwaysApply: false）..."
for skill in "${SKILLS[@]}"; do
  skill_file="${SKILLS_DIR}/${skill}/SKILL.md"
  rule_file="${RULES_DIR}/shikigami-${skill}.mdc"

  if [ ! -f "${skill_file}" ]; then
    echo "      ⚠️  ${skill}/SKILL.md 不存在，跳過"
    continue
  fi

  description=$(grep -m1 "^description:" "${skill_file}" 2>/dev/null | sed 's/^description: *"//' | sed 's/"$//' || echo "${skill}")

  {
    echo "---"
    echo "description: \"Shikigami ${skill} — ${description}\""
    echo "alwaysApply: false"
    echo "---"
    echo ""
    awk '/^---/{if(++count==2){found=1;next}} found{print}' "${skill_file}"
  } > "${rule_file}"

  echo "      ✓ shikigami-${skill}.mdc"
done

# 5. 驗證
echo "[4/4] 驗證安裝..."
rule_count=$(ls "${RULES_DIR}"/shikigami-*.mdc 2>/dev/null | wc -l)
echo "      ✓ 安裝完成：${rule_count} 個 Rules"

# 確認 scrum-master 為 alwaysApply
if grep -q "alwaysApply: true" "${RULES_DIR}/shikigami-scrum-master.mdc" 2>/dev/null; then
  echo "      ✓ scrum-master alwaysApply: true 已確認"
else
  echo "      ⚠️  scrum-master alwaysApply 設定可能有問題，請手動確認"
fi

echo ""
echo "=== 安裝完成 ==="
echo ""
echo "下一步："
echo "  1. 在 Cursor 中開啟此專案"
echo "  2. 在 Chat 中輸入：你有 shikigami superpowers 嗎？"
echo "  3. 確認 Scrum Master 角色介紹出現"
echo ""
echo "詳細使用說明：docs/INSTALL_CURSOR.md"
echo ""
echo "已知限制："
echo "  - parallel-dispatch Skill 在 Cursor 中不可用（無平行 Agent 機制）"
echo "  - 建議每個 Story 開新的 Cursor Chat 以避免 context 干擾"
echo "  - 複雜多角色流程請使用 Agent Mode"
