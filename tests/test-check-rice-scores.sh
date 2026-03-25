#!/usr/bin/env bash
# tests/test-check-rice-scores.sh — AC: Story #826
# 驗證 scripts/check-rice-scores.sh 掃描 sprint-candidate Issues 缺少 RICE Score

set -u

PASS=0
FAIL=0
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/check-rice-scores.sh"

pass() { echo "[PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

# Test 1: Script exists
if [[ -f "$SCRIPT" ]]; then
  pass "Script exists: scripts/check-rice-scores.sh"
else
  fail "Script missing: scripts/check-rice-scores.sh"
  echo "=== Results: $PASS passed, $FAIL failed ==="
  exit 1
fi

# Test 2: Script runs without crash even when gh unavailable
GH_STUB=$(mktemp -d)
cat > "$GH_STUB/gh" << 'GHEOF'
#!/usr/bin/env bash
# gh stub: returns empty JSON (simulates gh failure)
echo "[]"
exit 0
GHEOF
chmod +x "$GH_STUB/gh"

OUTPUT=$(PATH="$GH_STUB:$PATH" bash "$SCRIPT" 2>&1)
EC=$?
rm -rf "$GH_STUB"
if [[ $EC -le 1 ]]; then
  pass "NFR1: Script handles empty gh response without crash (exit $EC)"
else
  fail "NFR1: Script crashed on empty gh response (exit $EC)"
fi

# Test 3: AC1 — With issues having no RICE Score, output [RICE-MISSING]
GH_STUB=$(mktemp -d)
cat > "$GH_STUB/gh" << 'GHEOF'
#!/usr/bin/env bash
# gh stub: returns issues without RICE Score
echo '[{"number":99,"title":"Test Issue without scoring","body":"## User Story\nAs a user I want something. No priority scoring present.","labels":[{"name":"sprint-candidate"}]}]'
exit 0
GHEOF
chmod +x "$GH_STUB/gh"

OUTPUT=$(PATH="$GH_STUB:$PATH" bash "$SCRIPT" 2>&1)
EC=$?
rm -rf "$GH_STUB"

if [[ $EC -le 1 ]]; then
  pass "AC1: Script completes without crash for issues without RICE"
else
  fail "AC1: Script crashed for issues without RICE (exit $EC)"
fi

if echo "$OUTPUT" | grep -q "\[RICE-MISSING\]"; then
  pass "AC2: [RICE-MISSING] output for issue without RICE Score"
else
  fail "AC2: [RICE-MISSING] not found for issue without RICE Score"
fi

# Test 4: AC1 — Issues with RICE Score should not trigger warning
GH_STUB=$(mktemp -d)
cat > "$GH_STUB/gh" << 'GHEOF'
#!/usr/bin/env bash
# gh stub: returns issue with RICE Score
echo '[{"number":100,"title":"Test Issue with RICE","body":"## RICE Score\nReach: 2 | Impact: 3 | Confidence: 80% | Effort: 1\nRICE = 4.8","labels":[{"name":"sprint-candidate"}]}]'
exit 0
GHEOF
chmod +x "$GH_STUB/gh"

OUTPUT=$(PATH="$GH_STUB:$PATH" bash "$SCRIPT" 2>&1)
rm -rf "$GH_STUB"

if ! echo "$OUTPUT" | grep -q "\[RICE-MISSING\]"; then
  pass "AC1: No [RICE-MISSING] for issue that has RICE Score"
else
  fail "AC1: False [RICE-MISSING] for issue with RICE Score"
fi

# Test 5: AC3 — Script can be called from backlog-health-report (check it accepts --output-format flag or runs silently)
OUTPUT=$(bash "$SCRIPT" --help 2>&1)
EC=$?
if [[ $EC -le 1 ]]; then
  pass "AC3: Script accepts --help flag for integration (exit $EC)"
else
  fail "AC3: Script crashed on --help (exit $EC)"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]]
