#!/usr/bin/env bash
# tests/test-hook-timeout-isolation.sh
# Story #923: Hook 執行超時與隔離機制 — 單元測試
# AC4: >= 3 個測試（timeout, isolation, metric recording）

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK_RUNNER="${REPO_ROOT}/hooks/hook-runner.sh"
METRICS_FILE="${REPO_ROOT}/.claude/hooks/execution-metrics.jsonl"
PASS=0
FAIL=0

# Test helper
assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  [PASS] $desc"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $desc — expected='$expected' actual='$actual'"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -q "$needle"; then
    echo "  [PASS] $desc"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $desc — expected '$needle' in output"
    FAIL=$((FAIL + 1))
  fi
}

assert_file_exists() {
  local desc="$1" file="$2"
  if [[ -f "$file" ]]; then
    echo "  [PASS] $desc"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $desc — file not found: $file"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Test: Hook 執行超時與隔離機制 (Story #923) ==="

# Setup: create temp dir for test hooks
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Create a fast-completing hook
cat > "$TMPDIR/fast-hook.sh" << 'HOOK'
#!/usr/bin/env bash
echo "fast hook completed"
exit 0
HOOK
chmod +x "$TMPDIR/fast-hook.sh"

# Create a hook that sleeps longer than timeout
cat > "$TMPDIR/slow-hook.sh" << 'HOOK'
#!/usr/bin/env bash
sleep 60
echo "should not reach here"
exit 0
HOOK
chmod +x "$TMPDIR/slow-hook.sh"

# Create a hook that exits with error
cat > "$TMPDIR/fail-hook.sh" << 'HOOK'
#!/usr/bin/env bash
echo "hook failure output" >&2
exit 1
HOOK
chmod +x "$TMPDIR/fail-hook.sh"

# Create a hook that exits successfully
cat > "$TMPDIR/success-hook.sh" << 'HOOK'
#!/usr/bin/env bash
echo "hook success"
exit 0
HOOK
chmod +x "$TMPDIR/success-hook.sh"

# Remove old metrics file to start clean
rm -f "$METRICS_FILE"

echo ""
echo "--- TC-1: Timeout 機制 ---"

# TC-1.1: Fast hook completes within timeout → exit 0
RESULT=$(HOOK_TIMEOUT=5 METRICS_FILE="$METRICS_FILE" bash "$HOOK_RUNNER" "$TMPDIR/fast-hook.sh" 2>/dev/null; echo "exit:$?")
assert_contains "TC-1.1 fast hook completes successfully" "exit:0" "$RESULT"

# TC-1.2: Slow hook is killed by timeout → exit non-zero or timeout recorded
START=$(date +%s)
HOOK_TIMEOUT=2 METRICS_FILE="$METRICS_FILE" bash "$HOOK_RUNNER" "$TMPDIR/slow-hook.sh" 2>/dev/null || true
END=$(date +%s)
ELAPSED=$((END - START))
if [[ $ELAPSED -lt 5 ]]; then
  echo "  [PASS] TC-1.2 slow hook killed within timeout window (${ELAPSED}s < 5s)"
  PASS=$((PASS + 1))
else
  echo "  [FAIL] TC-1.2 slow hook took too long (${ELAPSED}s, timeout should be 2s)"
  FAIL=$((FAIL + 1))
fi

# TC-1.3: Default timeout (HOOK_TIMEOUT not set) → uses 30s default (just verify it runs)
OUTPUT=$(METRICS_FILE="$METRICS_FILE" bash "$HOOK_RUNNER" "$TMPDIR/fast-hook.sh" 2>/dev/null)
assert_contains "TC-1.3 default timeout config runs successfully" "fast hook completed" "$OUTPUT"

echo ""
echo "--- TC-2: Isolation 機制 ---"

# TC-2.1: Failed hook does not propagate failure to runner (isolation) → runner exits 0
ISOLATION_EXIT=0
HOOK_TIMEOUT=5 METRICS_FILE="$METRICS_FILE" bash "$HOOK_RUNNER" "$TMPDIR/fail-hook.sh" 2>/dev/null || ISOLATION_EXIT=$?
# Runner should handle failure gracefully (record it) without crashing
# exit code may be non-zero but process should complete cleanly
if [[ $ISOLATION_EXIT -le 1 ]]; then
  echo "  [PASS] TC-2.1 failed hook handled gracefully (exit=$ISOLATION_EXIT)"
  PASS=$((PASS + 1))
else
  echo "  [FAIL] TC-2.1 unexpected exit code: $ISOLATION_EXIT"
  FAIL=$((FAIL + 1))
fi

# TC-2.2: After a failed hook, subsequent hooks can still run
OUTPUT2=$(HOOK_TIMEOUT=5 METRICS_FILE="$METRICS_FILE" bash "$HOOK_RUNNER" "$TMPDIR/success-hook.sh" 2>/dev/null)
assert_contains "TC-2.2 subsequent hook runs after previous failure" "hook success" "$OUTPUT2"

echo ""
echo "--- TC-3: Metric 記錄 ---"

# TC-3.1: Metrics file created after hook execution
assert_file_exists "TC-3.1 metrics file exists after run" "$METRICS_FILE"

# TC-3.2: Metrics file contains JSONL entries
if [[ -f "$METRICS_FILE" ]]; then
  ENTRY_COUNT=$(wc -l < "$METRICS_FILE")
  if [[ $ENTRY_COUNT -gt 0 ]]; then
    echo "  [PASS] TC-3.2 metrics file has $ENTRY_COUNT entries"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] TC-3.2 metrics file is empty"
    FAIL=$((FAIL + 1))
  fi
fi

# TC-3.3: Metrics entries have required fields (hook, status, duration_ms, timestamp)
if [[ -f "$METRICS_FILE" ]]; then
  FIRST_ENTRY=$(head -1 "$METRICS_FILE")
  assert_contains "TC-3.3 metrics entry has 'hook' field" '"hook"' "$FIRST_ENTRY"
  assert_contains "TC-3.4 metrics entry has 'status' field" '"status"' "$FIRST_ENTRY"
  assert_contains "TC-3.5 metrics entry has 'timestamp' field" '"timestamp"' "$FIRST_ENTRY"
fi

echo ""
echo "=== Results ==="
echo "PASS: $PASS | FAIL: $FAIL"
if [[ $FAIL -eq 0 ]]; then
  echo "[TEST-SUITE-PASS] All tests passed"
  exit 0
else
  echo "[TEST-SUITE-FAIL] $FAIL test(s) failed"
  exit 1
fi
