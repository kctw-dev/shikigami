#!/usr/bin/env bash
# tests/test-generate-retro-template.sh — AC3: Story #827
# 驗證 scripts/generate-retro-template.sh 解析 sprint_162.md 輸出正確欄位

set -u

PASS=0
FAIL=0
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/generate-retro-template.sh"
SPRINT_162="$REPO_ROOT/docs/sprints/sprint_162.md"

pass() { echo "[PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

# Test 1: Script exists
if [[ -f "$SCRIPT" ]]; then
  pass "Script exists: scripts/generate-retro-template.sh"
else
  fail "Script missing: scripts/generate-retro-template.sh"
  echo "=== Results: $PASS passed, $FAIL failed ==="
  exit 1
fi

# Test 2: Fixture sprint_162.md exists
if [[ -f "$SPRINT_162" ]]; then
  pass "Fixture exists: docs/sprints/sprint_162.md"
else
  fail "Fixture missing: docs/sprints/sprint_162.md"
fi

# Test 3: AC3 — parse sprint_162.md and output correct fields
if [[ -f "$SPRINT_162" ]]; then
  OUTPUT=$(bash "$SCRIPT" "$SPRINT_162" 2>&1)
  EC=$?

  if [[ $EC -eq 0 ]]; then
    pass "AC3: Script exits 0 parsing sprint_162.md"
  else
    fail "AC3: Script exited with error $EC on sprint_162.md"
  fi

  # Check for Sprint Goal
  if echo "$OUTPUT" | grep -qiE "(Sprint Goal|Sprint.*Goal)"; then
    pass "AC3: Output contains Sprint Goal section"
  else
    fail "AC3: Output missing Sprint Goal"
  fi

  # Check for velocity (pts)
  if echo "$OUTPUT" | grep -qE "[0-9]+ pts"; then
    pass "AC3: Output contains velocity/points data"
  else
    fail "AC3: Output missing velocity/points"
  fi

  # Check for DONE stories or completion rate
  if echo "$OUTPUT" | grep -qiE "(DONE|完成|completed|velocity)"; then
    pass "AC3: Output contains DONE/completion info"
  else
    fail "AC3: Output missing DONE/completion section"
  fi
fi

# Test 4: AC1 — output contains Retrospective template sections
if [[ -f "$SPRINT_162" ]]; then
  OUTPUT=$(bash "$SCRIPT" "$SPRINT_162" 2>&1)

  # Check for went-well / improvement sections (standard retro template)
  if echo "$OUTPUT" | grep -qiE "(Well|好|改善|Improvement|問題|Problem|Action)"; then
    pass "AC1: Output contains retrospective template sections"
  else
    fail "AC1: Output missing retrospective template sections"
  fi
fi

# Test 5: AC2 — output format aligns with existing sprint review format
if [[ -f "$SPRINT_162" ]]; then
  OUTPUT=$(bash "$SCRIPT" "$SPRINT_162" 2>&1)
  # Should contain markdown header
  if echo "$OUTPUT" | grep -qE "^#"; then
    pass "AC2: Output contains markdown headers (format aligned)"
  else
    fail "AC2: Output missing markdown headers"
  fi
fi

# Test 6: NFR2 — Bad format input outputs [RETRO-TEMPLATE-WARN] not crash
TMPFILE=$(mktemp --suffix=.md)
echo "This is not a valid sprint file format" > "$TMPFILE"
OUTPUT=$(bash "$SCRIPT" "$TMPFILE" 2>&1)
EC=$?
rm -f "$TMPFILE"

if [[ $EC -le 1 ]]; then
  pass "NFR2: Graceful handling of bad format (exit $EC)"
else
  fail "NFR2: Script crashed on bad format (exit $EC)"
fi

if echo "$OUTPUT" | grep -q "\[RETRO-TEMPLATE-WARN\]"; then
  pass "NFR2: [RETRO-TEMPLATE-WARN] output for bad format"
else
  fail "NFR2: [RETRO-TEMPLATE-WARN] not found for bad format"
fi

# Test 7: Missing file handling
OUTPUT=$(bash "$SCRIPT" /nonexistent/sprint.md 2>&1)
EC=$?
if [[ $EC -le 1 ]]; then
  pass "Edge: Handles missing file without crash (exit $EC)"
else
  fail "Edge: Crashed on missing file (exit $EC)"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]]
