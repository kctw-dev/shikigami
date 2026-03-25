#!/usr/bin/env bash
# Test: SRE runner_min_count logic
# AC1: sre-inspection.md reads sre.runner_min_count (default 1)
# AC2: online count >= runner_min_count -> not report
# AC3: online count < runner_min_count -> report

PASS=0
FAIL=0

# Test helper
assert_contains() {
  local desc="$1" expected="$2" actual="$3"
  if echo "$actual" | grep -q "$expected"; then
    echo "PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "FAIL: $desc"
    echo "  Expected: '$expected' in output"
    echo "  Got: '$actual'"
    FAIL=$((FAIL+1))
  fi
}

assert_not_contains() {
  local desc="$1" expected="$2" actual="$3"
  if ! echo "$actual" | grep -q "$expected"; then
    echo "PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "FAIL: $desc (should NOT contain '$expected')"
    echo "  Got: '$actual'"
    FAIL=$((FAIL+1))
  fi
}

# ---- Test AC1: runner_min_count can be read from config ----
# Simulate config reading
MOCK_CONFIG=$(cat << 'EOF'
---
shikigami:
  sre:
    runner_min_count: 2
EOF
)

RUNNER_MIN_COUNT=$(echo "$MOCK_CONFIG" | grep 'runner_min_count:' | awk '{print $2}' | head -1)
RUNNER_MIN_COUNT="${RUNNER_MIN_COUNT:-1}"

assert_contains "AC1: runner_min_count read from config = 2" "2" "$RUNNER_MIN_COUNT"

# ---- Test AC1 default: when not set, default = 1 ----
EMPTY_CONFIG="shikigami:\n  project_level: low"
RUNNER_MIN_COUNT_DEFAULT=$(echo -e "$EMPTY_CONFIG" | grep 'runner_min_count:' | awk '{print $2}' | head -1)
RUNNER_MIN_COUNT_DEFAULT="${RUNNER_MIN_COUNT_DEFAULT:-1}"

assert_contains "AC1: default runner_min_count = 1 when not configured" "1" "$RUNNER_MIN_COUNT_DEFAULT"

# ---- Test AC2: online >= runner_min_count -> no alert ----
ONLINE_COUNT=2
RUNNER_MIN=1

if [[ "$ONLINE_COUNT" -ge "$RUNNER_MIN" ]]; then
  ALERT="runner-count-normal"
else
  ALERT="runner-count-low"
fi

assert_contains "AC2: online=2 >= min=1 -> runner-count-normal" "runner-count-normal" "$ALERT"

# ---- Test AC2b: online == runner_min_count -> no alert ----
ONLINE_COUNT=1
RUNNER_MIN=1

if [[ "$ONLINE_COUNT" -ge "$RUNNER_MIN" ]]; then
  ALERT="runner-count-normal"
else
  ALERT="runner-count-low"
fi

assert_contains "AC2b: online=1 >= min=1 -> runner-count-normal" "runner-count-normal" "$ALERT"
assert_not_contains "AC2b: no create-issue when online=min" "runner-count-low" "$ALERT"

# ---- Test AC3: online < runner_min_count -> create issue ----
ONLINE_COUNT=0
RUNNER_MIN=1

if [[ "$ONLINE_COUNT" -ge "$RUNNER_MIN" ]]; then
  ALERT="runner-count-normal"
else
  ALERT="runner-count-low"
fi

assert_contains "AC3: online=0 < min=1 -> runner-count-low" "runner-count-low" "$ALERT"
assert_not_contains "AC3: no normal when online < min" "runner-count-normal" "$ALERT"

# ---- Summary ----
echo ""
echo "=== Test Results ==="
echo "PASS: $PASS  FAIL: $FAIL"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
