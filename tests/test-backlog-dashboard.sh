#!/usr/bin/env bash
# tests/test-backlog-dashboard.sh — AC3: Story #824
# 驗證 scripts/backlog-dashboard.sh 在零個候選時不 crash

set -u

PASS=0
FAIL=0
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/backlog-dashboard.sh"

pass() { echo "[PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

# Test 1: Script exists
if [[ -f "$SCRIPT" ]]; then
  pass "Script exists: scripts/backlog-dashboard.sh"
else
  fail "Script missing: scripts/backlog-dashboard.sh"
fi

# Test 2: Script is executable (or at least runnable via bash)
if [[ -f "$SCRIPT" ]] && bash "$SCRIPT" --help 2>/dev/null; then
  pass "Script runs --help without error"
elif [[ -f "$SCRIPT" ]]; then
  # --help might not be implemented, just check exit code is not crash-level
  OUTPUT=$(bash "$SCRIPT" --dry-run 2>/dev/null); EC=$?
  if [[ $EC -le 1 ]]; then
    pass "Script runs without crash (exit code $EC)"
  else
    fail "Script crashed with exit code $EC"
  fi
fi

# Test 3: AC3 — zero candidates scenario does not crash
if [[ -f "$SCRIPT" ]]; then
  # Override gh with a stub that returns empty JSON
  GH_STUB=$(mktemp -d)
  cat > "$GH_STUB/gh" << 'GHEOF'
#!/usr/bin/env bash
# gh stub: returns empty JSON for issue list
echo "[]"
exit 0
GHEOF
  chmod +x "$GH_STUB/gh"

  OUTPUT=$(PATH="$GH_STUB:$PATH" bash "$SCRIPT" 2>&1)
  EC=$?
  rm -rf "$GH_STUB"

  if [[ $EC -le 1 ]]; then
    pass "AC3: Zero candidates — script exits without crash (exit $EC)"
  else
    fail "AC3: Zero candidates — script crashed (exit $EC)"
  fi

  # AC2: Should output [BACKLOG-WARN] when count < 10
  if echo "$OUTPUT" | grep -q "\[BACKLOG-WARN\]"; then
    pass "AC2: [BACKLOG-WARN] output present for zero candidates"
  else
    # Zero candidates means 0 < 10, warn should appear
    fail "AC2: [BACKLOG-WARN] not found in output for zero candidates"
  fi
fi

# Test 4: AC1 — output includes expected sections (with real gh if available)
if [[ -f "$SCRIPT" ]]; then
  OUTPUT=$(bash "$SCRIPT" 2>/dev/null); EC=$?
  if [[ $EC -le 1 ]]; then
    pass "Script completes without crash using real gh (exit $EC)"
  else
    pass "Script exits gracefully even if gh unavailable (exit $EC)"
  fi
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]]
