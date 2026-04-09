#!/usr/bin/env bash
# tests/test-po-prompt-soft-language.sh — AC: Story #994
# 驗證 PO Prompt 禁用軟性字樣清單與自檢步驟

set -u

PASS=0
FAIL=0
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PO_PROMPT="$REPO_ROOT/skills/sprint-planning/references/po-prompt.md"

pass() { echo "[PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

# Test 1: PO Prompt file exists
if [[ -f "$PO_PROMPT" ]]; then
  pass "PO Prompt file exists: skills/sprint-planning/references/po-prompt.md"
else
  fail "PO Prompt file missing: skills/sprint-planning/references/po-prompt.md"
  echo "=== Results: $PASS passed, $FAIL failed ==="
  exit 1
fi

# Test 2: AC1 — Soft language blocklist section exists
if grep -q "## 禁用軟性字樣清單" "$PO_PROMPT"; then
  pass "AC1: Soft language blocklist section exists"
else
  fail "AC1: Soft language blocklist section missing"
fi

# Test 3: AC1 — At least 8 forbidden words listed
FORBIDDEN_COUNT=$(grep -c "考慮\|明確\|適當\|合理\|盡量\|儘可能\|必要時\|建議" "$PO_PROMPT" || echo "0")
if [[ $FORBIDDEN_COUNT -ge 8 ]]; then
  pass "AC1: At least 8 forbidden words found ($FORBIDDEN_COUNT matches)"
else
  fail "AC1: Insufficient forbidden words found ($FORBIDDEN_COUNT < 8)"
fi

# Test 4: AC1 — Blocklist is in Markdown table format
if grep -A 20 "## 禁用軟性字樣清單" "$PO_PROMPT" | grep -q "^|.*|.*|"; then
  pass "AC1: Blocklist in Markdown table format"
else
  fail "AC1: Blocklist not in Markdown table format"
fi

# Test 5: AC2 — Self-check step exists in PO Round 1 output process
if grep -q "自檢" "$PO_PROMPT" || grep -q "self-check\|Self-check" "$PO_PROMPT"; then
  pass "AC2: Self-check step mentioned"
else
  fail "AC2: Self-check step not found"
fi

# Test 6: AC2 — grep self-check instruction exists
if grep -q "grep.*考慮\|grep.*軟性\|軟性字樣.*grep" "$PO_PROMPT"; then
  pass "AC2: grep self-check instruction found"
else
  fail "AC2: grep self-check instruction not found"
fi

# Test 7: AC3 — Rewrite rules exist (numeric/status/path conditions)
if grep -q "改寫規則" "$PO_PROMPT" && (grep -q "數值條件" "$PO_PROMPT" || grep -q "狀態條件" "$PO_PROMPT" || grep -q "路徑條件" "$PO_PROMPT"); then
  pass "AC3: Rewrite rules documented"
else
  fail "AC3: Rewrite rules not documented"
fi

# Test 8: Test example text with soft language — should detect it
EXAMPLE_WITH_SOFT="功能應考慮使用者體驗，建議採用合理的設計。"
GREP_CMD='考慮|明確|適當|合理|盡量|儘可能|必要時|建議'
if echo "$EXAMPLE_WITH_SOFT" | grep -qE "$GREP_CMD"; then
  pass "AC4: Example text with soft language detected correctly"
else
  fail "AC4: Example text with soft language not detected"
fi

# Test 9: Test example text without soft language — should pass
EXAMPLE_WITHOUT_SOFT="當 status=completed 時，顯示成功訊息；若檔案 X 存在，執行命令 Y。"
if ! echo "$EXAMPLE_WITHOUT_SOFT" | grep -qE "$GREP_CMD"; then
  pass "AC4: Example text without soft language passes correctly"
else
  fail "AC4: Example text without soft language incorrectly flagged"
fi

# Test 10: AC5 — validate-agents.sh passes
cd "$REPO_ROOT"
if bash scripts/validate-agents.sh > /dev/null 2>&1; then
  pass "AC5: validate-agents.sh passes"
else
  fail "AC5: validate-agents.sh failed"
fi

echo ""
echo "=== Test Results ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "Total:  $((PASS + FAIL))"

if [[ $FAIL -eq 0 ]]; then
  exit 0
else
  exit 1
fi
