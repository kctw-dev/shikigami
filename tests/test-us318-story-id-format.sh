#!/usr/bin/env bash
# tests/test-us318-story-id-format.sh
# US-#318：Story ID 格式統一為 US-#N
# AC1：Skill prompt 不再含裸 US-XX placeholder（允許 US-# 開頭或具體範例）
# AC3：architect/SKILL.md ADR 建立流程含 claim 前置步驟

set -uo pipefail

PASS_COUNT=0
FAIL_COUNT=0

pass() { echo "PASS: $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { echo "FAIL: $1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# ---------------------------------------------------------------------------
# AC1：Skill prompts 不含裸 US-XX placeholder
# ---------------------------------------------------------------------------
# 定義需檢查的檔案
SKILL_FILES=(
  "skills/sprint-planning/references/po-prompt.md"
  "skills/sprint-execution/story-lifecycle-prompt.md"
  "skills/sprint-execution/SKILL.md"
  "skills/sprint-execution/developer-prompt.md"
  "skills/architect/SKILL.md"
  "skills/sprint-planning/references/qa-prompt.md"
  "skills/sprint-planning/references/architect-prompt.md"
  "skills/shoot/SKILL.md"
  "skills/qa-engineer/SKILL.md"
  "skills/sprint-review/po-review-prompt.md"
)

echo "=== AC1: Skill prompt 不含裸 US-XX placeholder ==="

for file in "${SKILL_FILES[@]}"; do
  full_path="$REPO_ROOT/$file"
  if [[ ! -f "$full_path" ]]; then
    fail "AC1[$file] 檔案不存在"
    continue
  fi

  # 抓取裸 US-XX pattern（US-XX 或 US-YY 或 US-ZZ 等）
  # 允許：US-#N、US-#312（含 # 的格式）
  # 不允許：US-XX、US-YY、US-ZZ（不含 # 的純字母佔位符）作為 placeholder
  # 排除含數字的真實 ID（如 US-40、US-41、US-255 等）
  # 例外：shoot/SKILL.md 明確標注向後相容的 US-XX 行（含「向後相容」或「舊格式」關鍵字）
  if [[ "$file" == "skills/shoot/SKILL.md" ]]; then
    # 只計算非向後相容行的裸 US-XX
    bare_count=$(grep -P '\bUS-[A-Z]{2,}\b' "$full_path" | grep -v '向後相容\|舊格式\|backward' | grep -v 'US-#' | wc -l)
  else
    bare_count=$(grep -oP '\bUS-[A-Z]{2,}\b' "$full_path" | wc -l)
  fi

  if [[ "$bare_count" -eq 0 ]]; then
    pass "AC1[$file] 無裸 US-XX placeholder（非向後相容行）"
  else
    fail "AC1[$file] 仍含 ${bare_count} 個裸 US-XX placeholder"
    if [[ "$file" == "skills/shoot/SKILL.md" ]]; then
      grep -nP '\bUS-[A-Z]{2,}\b' "$full_path" | grep -v '向後相容\|舊格式\|backward' | grep -v 'US-#' | head -5
    else
      grep -nP '\bUS-[A-Z]{2,}\b' "$full_path" | head -5
    fi
  fi
done

# ---------------------------------------------------------------------------
# AC3：architect/SKILL.md 含 ADR claim 前置步驟
# ---------------------------------------------------------------------------
echo ""
echo "=== AC3: architect/SKILL.md ADR 建立流程含 claim 前置步驟 ==="

ARCH_SKILL="$REPO_ROOT/skills/architect/SKILL.md"

if grep -q 'claim-issue.sh' "$ARCH_SKILL"; then
  pass "AC3 architect/SKILL.md 含 claim-issue.sh 步驟"
else
  fail "AC3 architect/SKILL.md 缺少 claim-issue.sh 前置步驟"
fi

if grep -q 'adr-' "$ARCH_SKILL"; then
  pass "AC3 architect/SKILL.md 含 adr- claim 參數範例"
else
  fail "AC3 architect/SKILL.md 缺少 adr- claim 參數範例"
fi

# ---------------------------------------------------------------------------
# 結果
# ---------------------------------------------------------------------------
echo ""
echo "=== 測試結果 ==="
echo "PASS: ${PASS_COUNT}"
echo "FAIL: ${FAIL_COUNT}"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi
exit 0
