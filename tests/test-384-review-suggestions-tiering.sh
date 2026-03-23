#!/usr/bin/env bash
# tests/test-384-review-suggestions-tiering.sh
# Story #384：Review 建議清單分層（MUST FIX vs SUGGESTION）
# 驗證 quality-reviewer-prompt.md 與 quality-gate/SKILL.md 輸出格式已分兩層

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

QUALITY_REVIEWER="skills/sprint-execution/quality-reviewer-prompt.md"
QUALITY_GATE="skills/quality-gate/SKILL.md"

# ---------------------------------------------------------------------------
# AC1：quality-reviewer-prompt.md 輸出格式包含 MUST FIX 分層標記
# ---------------------------------------------------------------------------
echo "--- AC1：quality-reviewer-prompt.md MUST FIX 分層 ---"

if grep -q "MUST FIX" "$QUALITY_REVIEWER"; then
  pass "AC1-1：quality-reviewer-prompt.md 包含 MUST FIX 標籤"
else
  fail "AC1-1：quality-reviewer-prompt.md 缺少 MUST FIX 標籤"
fi

if grep -q "SUGGESTION" "$QUALITY_REVIEWER"; then
  pass "AC1-2：quality-reviewer-prompt.md 包含 SUGGESTION 標籤"
else
  fail "AC1-2：quality-reviewer-prompt.md 缺少 SUGGESTION 標籤"
fi

# MUST FIX 必須包含 CRITICAL 與 HIGH 的對照說明
if grep -A5 "MUST FIX" "$QUALITY_REVIEWER" | grep -q "Critical\|CRITICAL\|Critical.*HIGH\|CRITICAL.*HIGH"; then
  pass "AC1-3：MUST FIX 區塊涵蓋 Critical/HIGH 嚴重度"
else
  fail "AC1-3：MUST FIX 區塊未明確涵蓋 Critical/HIGH 嚴重度"
fi

# SUGGESTION 必須包含 MEDIUM 或 LOW 的對照說明
if grep -A5 "SUGGESTION" "$QUALITY_REVIEWER" | grep -q "Suggestion\|MEDIUM\|LOW\|Medium\|Low"; then
  pass "AC1-4：SUGGESTION 區塊涵蓋非阻塞嚴重度"
else
  fail "AC1-4：SUGGESTION 區塊未明確涵蓋非阻塞嚴重度"
fi

# ---------------------------------------------------------------------------
# AC2：quality-reviewer-prompt.md 輸出格式的 Issues 區塊用 MUST FIX / SUGGESTION 分層
# ---------------------------------------------------------------------------
echo ""
echo "--- AC2：輸出格式 Issues 區塊結構 ---"

# 在輸出格式（code block）中確認分層 header 存在
if grep -q "MUST FIX\|### MUST FIX" "$QUALITY_REVIEWER"; then
  pass "AC2-1：輸出格式包含 MUST FIX 分層 header"
else
  fail "AC2-1：輸出格式缺少 MUST FIX 分層 header"
fi

if grep -q "SUGGESTION\|### SUGGESTION" "$QUALITY_REVIEWER"; then
  pass "AC2-2：輸出格式包含 SUGGESTION 分層 header"
else
  fail "AC2-2：輸出格式缺少 SUGGESTION 分層 header"
fi

# ---------------------------------------------------------------------------
# AC3：SUGGESTION 必須要求記錄決策理由
# ---------------------------------------------------------------------------
echo ""
echo "--- AC3：SUGGESTION 決策理由記錄 ---"

if grep -B2 -A10 "SUGGESTION" "$QUALITY_REVIEWER" | grep -q "決策理由\|理由\|decision\|reason"; then
  pass "AC3-1：SUGGESTION 區塊要求記錄決策理由"
else
  fail "AC3-1：SUGGESTION 區塊未要求記錄決策理由"
fi

# ---------------------------------------------------------------------------
# AC4：quality-gate/SKILL.md 審查失敗處理章節反映分層邏輯
# ---------------------------------------------------------------------------
echo ""
echo "--- AC4：quality-gate/SKILL.md 分層說明 ---"

if grep -q "MUST FIX" "$QUALITY_GATE"; then
  pass "AC4-1：quality-gate SKILL.md 包含 MUST FIX 說明"
else
  fail "AC4-1：quality-gate SKILL.md 缺少 MUST FIX 說明"
fi

if grep -q "SUGGESTION" "$QUALITY_GATE"; then
  pass "AC4-2：quality-gate SKILL.md 包含 SUGGESTION 說明"
else
  fail "AC4-2：quality-gate SKILL.md 缺少 SUGGESTION 說明"
fi

# ---------------------------------------------------------------------------
# AC5：分層說明中 MUST FIX 是阻塞、SUGGESTION 是非阻塞
# ---------------------------------------------------------------------------
echo ""
echo "--- AC5：阻塞 vs 非阻塞語意 ---"

if grep -A3 "MUST FIX" "$QUALITY_REVIEWER" | grep -q "阻塞\|必須修復\|不通過\|block\|blocking"; then
  pass "AC5-1：MUST FIX 明確標示為阻塞"
else
  fail "AC5-1：MUST FIX 未明確標示為阻塞"
fi

if grep -A3 "SUGGESTION" "$QUALITY_REVIEWER" | grep -q "自行決定\|非阻塞\|Developer\|可選\|optional"; then
  pass "AC5-2：SUGGESTION 明確標示為非阻塞，Developer 自行決定"
else
  fail "AC5-2：SUGGESTION 未明確標示為非阻塞"
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
