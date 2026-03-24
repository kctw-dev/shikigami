#!/usr/bin/env bash
# Test: #485 Team Debate 觸發條件驗證
# AC7：Team Debate trigger simulation test
# Sprint 127 — 驗證 HARD-RULE 與 team-debate-prompt.md 的觸發條件一致性

set -euo pipefail

PASS=0
FAIL=0
SKIP=0

pass() { echo "  [PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }
skip() { echo "  [SKIP] $1"; SKIP=$((SKIP+1)); }

STORY_LIFECYCLE="skills/sprint-execution/story-lifecycle-prompt.md"
TEAM_DEBATE_REF="skills/sprint-execution/references/team-debate-prompt.md"
SKILL_MD="skills/sprint-execution/SKILL.md"

echo "=== Test #485: Team Debate 觸發條件驗證 ==="
echo ""

# AC7.1: story-lifecycle-prompt.md 包含 HARD-RULE Team Debate 觸發條件
echo "--- AC7.1: HARD-RULE Team Debate 觸發條件存在於主文件 ---"
if grep -q 'HARD-RULE.*conditional-step-trigger\|id="conditional-step-trigger"' "$STORY_LIFECYCLE" 2>/dev/null; then
  pass "HARD-RULE conditional-step-trigger 區塊存在"
else
  fail "HARD-RULE conditional-step-trigger 區塊不存在"
fi

if grep -q 'size=M.*size=L.*Team Debate\|Team Debate.*size=M.*size=L\|§7.8 Team Debate.*size=M 或 size=L' "$STORY_LIFECYCLE" 2>/dev/null; then
  pass "M/L size 觸發條件記錄在 HARD-RULE 中"
else
  fail "M/L size 觸發條件未記錄在 HARD-RULE 中"
fi

if grep -q 'M/L Stories 必須觸發' "$STORY_LIFECYCLE" 2>/dev/null; then
  pass "「M/L Stories 必須觸發」強制宣告存在"
else
  fail "「M/L Stories 必須觸發」強制宣告不存在"
fi

echo ""
echo "--- AC7.2: team-debate-prompt.md 存在且包含完整觸發規則 ---"
if [[ -f "$TEAM_DEBATE_REF" ]]; then
  pass "team-debate-prompt.md 存在"
else
  fail "team-debate-prompt.md 不存在"
fi

if grep -q 'M/L Stories 必須觸發 Team Debate' "$TEAM_DEBATE_REF" 2>/dev/null; then
  pass "M/L Stories 必須觸發明確記錄在 team-debate-prompt.md"
else
  fail "M/L Stories 必須觸發未記錄在 team-debate-prompt.md"
fi

if grep -q 'DEBATE-SKIP' "$TEAM_DEBATE_REF" 2>/dev/null; then
  pass "[DEBATE-SKIP] 豁免條件存在"
else
  fail "[DEBATE-SKIP] 豁免條件不存在"
fi

if grep -q 'doc_only.*true.*跳過\|doc_only = true.*跳過\|doc_only=true.*跳過' "$TEAM_DEBATE_REF" 2>/dev/null; then
  pass "doc_only=true 豁免規則存在"
else
  fail "doc_only=true 豁免規則不存在"
fi

if grep -q 'RESEARCH.*跳過\|DESIGN.*跳過' "$TEAM_DEBATE_REF" 2>/dev/null; then
  pass "RESEARCH/DESIGN story_type 豁免規則存在"
else
  fail "RESEARCH/DESIGN story_type 豁免規則不存在"
fi

if grep -q 'team_debate.*false\|team_debate = false' "$TEAM_DEBATE_REF" 2>/dev/null; then
  pass "team_debate=false 豁免規則存在"
else
  fail "team_debate=false 豁免規則不存在"
fi

echo ""
echo "--- AC7.3: story-lifecycle-prompt.md 行數 ≤ 700 (AC1) ---"
LINE_COUNT=$(wc -l < "$STORY_LIFECYCLE")
if [[ "$LINE_COUNT" -le 700 ]]; then
  pass "story-lifecycle-prompt.md 行數 = $LINE_COUNT (≤700)"
else
  fail "story-lifecycle-prompt.md 行數 = $LINE_COUNT (超過700限制)"
fi

echo ""
echo "--- AC7.4: SKILL.md §8 numbering conflict 已修正 (AC5) ---"
SEC8_COUNT=$(grep -c '^## 8\. ' "$SKILL_MD" 2>/dev/null || true)
if [[ "$SEC8_COUNT" -le 1 ]]; then
  pass "SKILL.md §8 編號衝突已修正（重複 ## 8. 頭部數量 = $SEC8_COUNT）"
else
  fail "SKILL.md 仍有 $SEC8_COUNT 個 ## 8. 標題（應 ≤1）"
fi

echo ""
echo "--- AC7.5: references/ 目錄模組化檔案完整性 ---"
REQUIRED_REFS=(
  "skills/sprint-execution/references/provider-routing.md"
  "skills/sprint-execution/references/story-type-rules.md"
  "skills/sprint-execution/references/test-writability-check.md"
  "skills/sprint-execution/references/design-type-path.md"
  "skills/sprint-execution/references/runtime-verification.md"
  "skills/sprint-execution/references/cicd-dual-review.md"
  "skills/sprint-execution/references/km-api-verification.md"
  "skills/sprint-execution/references/team-debate-prompt.md"
  "skills/sprint-execution/references/external-sampling.md"
  "skills/sprint-execution/references/output-schema.md"
)

for ref in "${REQUIRED_REFS[@]}"; do
  if [[ -f "$ref" ]]; then
    pass "$(basename "$ref") 存在"
  else
    fail "$(basename "$ref") 不存在（路徑：$ref）"
  fi
done

echo ""
echo "--- AC7.6: SSOT 指標 — 主文件 [REFERENCE] 指針完整性 ---"
REF_COUNT=$(grep -c '\[REFERENCE\]' "$STORY_LIFECYCLE" 2>/dev/null || true)
if [[ "$REF_COUNT" -ge 8 ]]; then
  pass "[REFERENCE] 指針數量 = $REF_COUNT (≥8 表示模組化充分)"
else
  fail "[REFERENCE] 指針數量 = $REF_COUNT (≤8，模組化不足)"
fi

echo ""
echo "==================================="
echo "結果：PASS=$PASS  FAIL=$FAIL  SKIP=$SKIP"
echo "==================================="

if [[ "$FAIL" -gt 0 ]]; then
  echo "[RESULT] FAIL"
  exit 1
else
  echo "[RESULT] PASS"
  exit 0
fi
