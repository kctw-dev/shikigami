#!/usr/bin/env bash
# Issue #638 — retro: tcb-write.sh smoke test（防止 start stdout 污染回歸）
# tcb-write.sh 本身為 #404 實作，此測試因 #638 retro 結論新增

# Intentionally no -e: tests must continue past individual failures to report full results
set -uo pipefail

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

# ── Setup：隔離測試用 REPO_ROOT ──────────────────────────────
REAL_REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TCB_SCRIPT="${REAL_REPO_ROOT}/hooks/tcb-write.sh"
TEST_REPO_ROOT=$(mktemp -d)
TEST_STDERR="${TEST_REPO_ROOT}/test-stderr.log"

# Mock git: intercept rev-parse --show-toplevel → TEST_REPO_ROOT; other calls pass through
REAL_GIT=$(command -v git)
MOCK_BIN=$(mktemp -d)
cat > "${MOCK_BIN}/git" << GITEOF
#!/usr/bin/env bash
if [[ "\${1:-}" == "rev-parse" && "\${2:-}" == "--show-toplevel" ]]; then
  echo "$TEST_REPO_ROOT"
  exit 0
fi
exec "$REAL_GIT" "\$@"
GITEOF
chmod +x "${MOCK_BIN}/git"

cleanup() {
  rm -rf "$TEST_REPO_ROOT" "$MOCK_BIN"
}
trap cleanup EXIT

# Validate setup
if [ ! -x "${MOCK_BIN}/git" ] || [ ! -d "$TEST_REPO_ROOT" ]; then
  echo "FATAL: test setup failed — mock git or temp dir not created"
  exit 2
fi

export PATH="${MOCK_BIN}:${PATH}"
export REPO_ROOT="$TEST_REPO_ROOT"

SPRINT=999
SESSION="test-session-$$"
STORY="638"

# ── AC2：init → start → complete 正常流程 ────────────────────

# Test init
bash "$TCB_SCRIPT" init "$SPRINT" "$SESSION" "$STORY" 2>>"$TEST_STDERR"
INDEX_FILE="${TEST_REPO_ROOT}/docs/sprints/tcb/sprint-${SPRINT}/session-${SESSION}/index.json"
if [ -f "$INDEX_FILE" ]; then
  pass "AC2-1: init creates index.json"
else
  fail "AC2-1: init creates index.json (file not found: $INDEX_FILE)"
fi

# Test start — stdout must be pure tcb_id without [TCB] prefix
TCB_ID=$(bash "$TCB_SCRIPT" start "$SPRINT" "$SESSION" "$STORY" "test-action" 2>>"$TEST_STDERR")

if [[ -z "$TCB_ID" ]]; then
  fail "AC2-2: start returns non-empty tcb_id (got empty)"
  fail "AC2-3: SKIPPED (depends on AC2-2)"
  fail "AC2-4: SKIPPED (depends on AC2-2)"
  fail "AC2-5: SKIPPED (depends on AC2-2)"
else
  pass "AC2-2: start returns non-empty tcb_id"

  if [[ "$TCB_ID" != *"[TCB]"* ]]; then
    pass "AC2-3: start stdout does NOT contain [TCB] prefix (got: ${TCB_ID})"
  else
    fail "AC2-3: start stdout does NOT contain [TCB] prefix (got: ${TCB_ID})"
  fi

  EXPECTED_ID="${STORY}-act-1"
  if [[ "$TCB_ID" == "$EXPECTED_ID" ]]; then
    pass "AC2-4: start returns expected tcb_id format (${EXPECTED_ID})"
  else
    fail "AC2-4: start returns expected tcb_id format (expected: ${EXPECTED_ID}, got: ${TCB_ID})"
  fi

  # Test complete
  bash "$TCB_SCRIPT" complete "$SPRINT" "$SESSION" "$TCB_ID" "test-output" 2>>"$TEST_STDERR"
  TCB_FILE="${TEST_REPO_ROOT}/docs/sprints/tcb/sprint-${SPRINT}/session-${SESSION}/${TCB_ID}.json"
  if [ -f "$TCB_FILE" ]; then
    STATUS=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('status',''))" "$TCB_FILE")
    if [[ "$STATUS" == "completed" ]]; then
      pass "AC2-5: complete sets status=completed"
    else
      fail "AC2-5: complete sets status=completed (got: ${STATUS})"
    fi
  else
    fail "AC2-5: complete sets status=completed (TCB file not found)"
  fi
fi

# ── AC3：fail + resume 顯示未完成 TCB ────────────────────────

# Start a new action, then fail it
TCB_ID2=$(bash "$TCB_SCRIPT" start "$SPRINT" "$SESSION" "$STORY" "fail-action" 2>>"$TEST_STDERR")
bash "$TCB_SCRIPT" fail "$SPRINT" "$SESSION" "$TCB_ID2" "test-error" 2>>"$TEST_STDERR"

TCB_FILE2="${TEST_REPO_ROOT}/docs/sprints/tcb/sprint-${SPRINT}/session-${SESSION}/${TCB_ID2}.json"
if [ -f "$TCB_FILE2" ]; then
  STATUS2=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('status',''))" "$TCB_FILE2")
  if [[ "$STATUS2" == "failed" ]]; then
    pass "AC3-1: fail sets status=failed"
  else
    fail "AC3-1: fail sets status=failed (got: ${STATUS2})"
  fi
else
  fail "AC3-1: fail sets status=failed (TCB file not found)"
fi

# Resume should show failed TCB
RESUME_OUTPUT=$(bash "$TCB_SCRIPT" resume "$SPRINT" "$SESSION" 2>>"$TEST_STDERR")
if echo "$RESUME_OUTPUT" | grep -q "$TCB_ID2"; then
  pass "AC3-2: resume lists failed TCB (${TCB_ID2})"
else
  fail "AC3-2: resume lists failed TCB (expected ${TCB_ID2} in output: ${RESUME_OUTPUT})"
fi

# ── AC4：resume 對不存在的 session 回傳空陣列 [] ──────────────

EMPTY_SESSION="empty-session-$$"
RESUME_EMPTY=$(bash "$TCB_SCRIPT" resume "$SPRINT" "$EMPTY_SESSION" 2>>"$TEST_STDERR")
TRIMMED=$(echo "$RESUME_EMPTY" | tr -d '[:space:]')
if [[ "$TRIMMED" == "[]" ]]; then
  pass "AC4-1: resume with no TCBs returns []"
else
  fail "AC4-1: resume with no TCBs returns [] (got: ${RESUME_EMPTY})"
fi

# ── 結果摘要 ────────────────────────────────────────────────

echo ""
echo "==============================="
echo "Results: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"
echo "==============================="

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  echo "--- stderr from tcb-write.sh ---"
  cat "$TEST_STDERR" 2>/dev/null
  echo "--- end stderr ---"
  echo "SOME TESTS FAILED"
  exit 1
fi

echo "ALL TESTS PASSED"
exit 0
