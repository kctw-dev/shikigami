#!/usr/bin/env bash
# tests/test-266-pr-review-toolkit-integration.sh
# Story #266：pr-review-toolkit 審查 agents 整合至 shoot / sprint-execution commit 前 Gate
# 驗證 AC1~AC6 的結構存在性與引用一致性

set -uo pipefail

# ---------------------------------------------------------------------------
# 測試框架（輕量）
# ---------------------------------------------------------------------------
PASS_COUNT=0
FAIL_COUNT=0

pass() {
  echo "PASS: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "FAIL: $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

SHOOT_SKILL="skills/shoot/SKILL.md"
LIFECYCLE_PROMPT="skills/sprint-execution/story-lifecycle-prompt.md"
ADR_021="docs/adr/ADR-021-pr-review-toolkit-integration.md"

# ---------------------------------------------------------------------------
# AC1：shoot 步驟 5.4 存在
# ---------------------------------------------------------------------------
echo "--- AC1：shoot 步驟 5.4 ---"

if grep -q "步驟 5.4" "$SHOOT_SKILL" && grep -q "pr-review-toolkit" "$SHOOT_SKILL"; then
  pass "AC1-1：shoot SKILL.md 包含步驟 5.4 pr-review-toolkit"
else
  fail "AC1-1：shoot SKILL.md 缺少步驟 5.4 pr-review-toolkit"
fi

# 三 agent 派遣
if grep -q "code-reviewer" "$SHOOT_SKILL" && grep -q "silent-failure-hunter" "$SHOOT_SKILL" && grep -q "comment-analyzer" "$SHOOT_SKILL"; then
  pass "AC1-2：shoot 步驟 5.4 包含三個 agent 名稱"
else
  fail "AC1-2：shoot 步驟 5.4 缺少三個 agent 名稱"
fi

# HARD-GATE 標記
if grep -q "<HARD-GATE>" "$SHOOT_SKILL" && grep -A5 "步驟 5.4" "$SHOOT_SKILL" | head -20 | grep -q "pr-review-toolkit\|補充審查"; then
  pass "AC1-3：shoot 步驟 5.4 有 HARD-GATE 標記"
else
  fail "AC1-3：shoot 步驟 5.4 缺少 HARD-GATE 標記"
fi

# 步驟 5.4 在步驟 5.3 之後、步驟 5.5 之前（流程圖區域內）
# 取流程圖區域（§7 執行流程）中的順序
LINE_53_FLOW=$(grep -n "\[步驟 5.3\]" "$SHOOT_SKILL" | head -1 | cut -d: -f1)
LINE_54_FLOW=$(grep -n "\[步驟 5.4\]" "$SHOOT_SKILL" | head -1 | cut -d: -f1)
LINE_55_FLOW=$(grep -n "\[步驟 5.5\]" "$SHOOT_SKILL" | head -1 | cut -d: -f1)
if [[ -n "$LINE_53_FLOW" && -n "$LINE_54_FLOW" && -n "$LINE_55_FLOW" ]] && [[ "$LINE_53_FLOW" -lt "$LINE_54_FLOW" && "$LINE_54_FLOW" -lt "$LINE_55_FLOW" ]]; then
  pass "AC1-4：步驟 5.4 位於步驟 5.3 與 5.5 之間（流程圖）"
else
  fail "AC1-4：步驟 5.4 位置不正確（5.3=$LINE_53_FLOW, 5.4=$LINE_54_FLOW, 5.5=$LINE_55_FLOW）"
fi

# ---------------------------------------------------------------------------
# AC2：sprint-execution §7.5 存在
# ---------------------------------------------------------------------------
echo ""
echo "--- AC2：sprint-execution §7.5 ---"

if grep -q "§7.5" "$LIFECYCLE_PROMPT" && grep -q "pr-review-toolkit\|補充審查" "$LIFECYCLE_PROMPT"; then
  pass "AC2-1：story-lifecycle-prompt.md 包含 §7.5 補充審查"
else
  fail "AC2-1：story-lifecycle-prompt.md 缺少 §7.5 補充審查"
fi

# §7.5 section header 在 §7 之後、§8 之前
LINE_S7=$(grep -n "^## §7 " "$LIFECYCLE_PROMPT" | head -1 | cut -d: -f1)
LINE_S75=$(grep -n "^## §7.5 " "$LIFECYCLE_PROMPT" | head -1 | cut -d: -f1)
LINE_S8=$(grep -n "^## §8 " "$LIFECYCLE_PROMPT" | head -1 | cut -d: -f1)
if [[ -n "$LINE_S7" && -n "$LINE_S75" && -n "$LINE_S8" ]] && [[ "$LINE_S7" -lt "$LINE_S75" && "$LINE_S75" -lt "$LINE_S8" ]]; then
  pass "AC2-2：§7.5 section 位於 §7 與 §8 之間"
else
  fail "AC2-2：§7.5 位置不正確（§7=$LINE_S7, §7.5=$LINE_S75, §8=$LINE_S8）"
fi

# ---------------------------------------------------------------------------
# AC3：嚴重度 Gate 規則（CRITICAL/HIGH 阻擋，MEDIUM/LOW 記錄）
# ---------------------------------------------------------------------------
echo ""
echo "--- AC3：嚴重度 Gate 規則 ---"

if grep -q "CRITICAL" "$SHOOT_SKILL" && grep -q "HIGH" "$SHOOT_SKILL" && grep -q "MEDIUM" "$SHOOT_SKILL" && grep -q "LOW" "$SHOOT_SKILL"; then
  pass "AC3-1：shoot SKILL.md 包含四級嚴重度（CRITICAL/HIGH/MEDIUM/LOW）"
else
  fail "AC3-1：shoot SKILL.md 缺少嚴重度定義"
fi

# 修復閉環：二審仍 CRITICAL/HIGH 升級 Architect
if grep -q "Architect" "$SHOOT_SKILL" && grep -q "二審\|第二輪" "$SHOOT_SKILL"; then
  pass "AC3-2：shoot SKILL.md 包含修復閉環（二審升級 Architect）"
else
  fail "AC3-2：shoot SKILL.md 缺少修復閉環定義"
fi

# ---------------------------------------------------------------------------
# AC4：引用式寫法（story-lifecycle-prompt.md 不直接內嵌 agent prompt）
# ---------------------------------------------------------------------------
echo ""
echo "--- AC4：引用式寫法 ---"

# story-lifecycle-prompt.md 應引用 ADR-021 而非複製內容
if grep -q "ADR-021" "$LIFECYCLE_PROMPT"; then
  pass "AC4-1：story-lifecycle-prompt.md 引用 ADR-021"
else
  fail "AC4-1：story-lifecycle-prompt.md 缺少 ADR-021 引用"
fi

# 不應包含完整嚴重度對照表（應引用而非複製）
SEVERITY_TABLE_LINES=$(grep -c "confidence 91-100\|confidence 80-90" "$LIFECYCLE_PROMPT" || true)
if [[ "$SEVERITY_TABLE_LINES" -eq 0 ]]; then
  pass "AC4-2：story-lifecycle-prompt.md 未複製嚴重度對照表（引用式）"
else
  fail "AC4-2：story-lifecycle-prompt.md 直接複製了嚴重度對照表（應引用）"
fi

# ---------------------------------------------------------------------------
# AC5：責任邊界清晰（§8.5 外部獨立審查 vs 步驟 5.4 補充審查）
# ---------------------------------------------------------------------------
echo ""
echo "--- AC5：責任邊界 ---"

if grep -q "Spec Compliance" "$SHOOT_SKILL" && grep -q "工程品質\|品質深度" "$SHOOT_SKILL"; then
  pass "AC5-1：shoot SKILL.md 區分 Spec Compliance 與工程品質深度"
else
  fail "AC5-1：shoot SKILL.md 缺少責任邊界說明"
fi

# ---------------------------------------------------------------------------
# AC6：doc-only 條件觸發（doc_only=true 僅執行 comment-analyzer）
# ---------------------------------------------------------------------------
echo ""
echo "--- AC6：doc-only 條件觸發 ---"

if grep -q "doc-only\|doc_only" "$SHOOT_SKILL" && grep -q "comment-analyzer" "$SHOOT_SKILL"; then
  pass "AC6-1：shoot SKILL.md 包含 doc-only 條件觸發規則"
else
  fail "AC6-1：shoot SKILL.md 缺少 doc-only 條件觸發規則"
fi

# ---------------------------------------------------------------------------
# 降級行為
# ---------------------------------------------------------------------------
echo ""
echo "--- 降級行為 ---"

if grep -q "\[WARN\]" "$SHOOT_SKILL" && grep -q "跳過\|降級" "$SHOOT_SKILL"; then
  pass "降級-1：shoot SKILL.md 包含降級行為定義"
else
  fail "降級-1：shoot SKILL.md 缺少降級行為定義"
fi

# ---------------------------------------------------------------------------
# 流程圖更新
# ---------------------------------------------------------------------------
echo ""
echo "--- 流程圖更新 ---"

# shoot 流程圖包含步驟 5.4
FLOWCHART_SECTION=$(sed -n '/^## 7\. 執行流程/,/^## 8\./p' "$SHOOT_SKILL")
if echo "$FLOWCHART_SECTION" | grep -q "步驟 5.4"; then
  pass "流程圖-1：shoot 流程圖包含步驟 5.4"
else
  fail "流程圖-1：shoot 流程圖缺少步驟 5.4"
fi

# story-lifecycle-prompt.md 流程圖包含 §7.5
LIFECYCLE_FLOWCHART=$(sed -n '/^## 執行流程/,/^## 開始前準備/p' "$LIFECYCLE_PROMPT")
if echo "$LIFECYCLE_FLOWCHART" | grep -q "§7.5\|7\.5"; then
  pass "流程圖-2：story-lifecycle-prompt.md 流程圖包含 §7.5"
else
  fail "流程圖-2：story-lifecycle-prompt.md 流程圖缺少 §7.5"
fi

# ---------------------------------------------------------------------------
# 輸出格式引用
# ---------------------------------------------------------------------------
echo ""
echo "--- 輸出格式 ---"

if grep -q "pr-review-toolkit 補充審查" "$SHOOT_SKILL"; then
  pass "輸出格式-1：shoot SKILL.md 包含輸出格式區塊"
else
  fail "輸出格式-1：shoot SKILL.md 缺少輸出格式區塊"
fi

# ---------------------------------------------------------------------------
# 結果摘要
# ---------------------------------------------------------------------------
echo ""
echo "========================================="
echo "PASS: $PASS_COUNT / FAIL: $FAIL_COUNT"
echo "========================================="

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
else
  exit 0
fi
