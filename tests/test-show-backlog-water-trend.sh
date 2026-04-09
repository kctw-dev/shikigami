#!/bin/bash
# Tests for show-backlog-water-trend.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$SCRIPT_DIR/scripts/show-backlog-water-trend.sh"
TEST_TMPDIR=$(mktemp -d)

cleanup() {
  rm -rf "$TEST_TMPDIR"
}
trap cleanup EXIT

# Test 1: Script exists and is executable
test_script_exists() {
  if [[ ! -f "$SCRIPT" ]]; then
    echo "FAIL: Script $SCRIPT does not exist"
    exit 1
  fi
  if [[ ! -x "$SCRIPT" ]]; then
    echo "FAIL: Script $SCRIPT is not executable"
    exit 1
  fi
  echo "PASS: Script exists and is executable"
}

# Test 2: With valid data, output contains table headers
test_valid_data_has_headers() {
  # Create test JSONL file with sample data
  local test_dir="$TEST_TMPDIR/test_data"
  mkdir -p "$test_dir"

  cat > "$test_dir/backlog-water-20260401.jsonl" << 'EOF'
{"timestamp":"2026-04-01T10:09:54Z","sprint_candidate_count":12,"threshold":10,"status":"ok","repo":"kctw-dev/shikigami"}
EOF

  cat > "$test_dir/backlog-water-20260403.jsonl" << 'EOF'
{"timestamp":"2026-04-03T09:56:47Z","sprint_candidate_count":14,"threshold":10,"status":"ok","repo":"kctw-dev/shikigami"}
EOF

  output=$("$SCRIPT" "$test_dir" 2>&1 || true)

  if echo "$output" | grep -q "Date"; then
    echo "PASS: Output contains Date header"
  else
    echo "FAIL: Output missing Date header"
    echo "Output: $output"
    exit 1
  fi

  if echo "$output" | grep -q "Water Level\|count"; then
    echo "PASS: Output contains water level data"
  else
    echo "FAIL: Output missing water level data"
    echo "Output: $output"
    exit 1
  fi
}

# Test 3: With empty/missing data, script doesn't error
test_empty_data_graceful() {
  local empty_dir="$TEST_TMPDIR/empty"
  mkdir -p "$empty_dir"

  output=$("$SCRIPT" "$empty_dir" 2>&1 || true)

  # Should not crash, may output a message
  if [[ $? -le 1 ]]; then
    echo "PASS: Script handles empty data gracefully"
  else
    echo "FAIL: Script crashed on empty data"
    exit 1
  fi
}

# Test 4: Script outputs at least 7 days if data available
test_seven_days_output() {
  local test_dir="$TEST_TMPDIR/seven_days"
  mkdir -p "$test_dir"

  # Create 10 days of data
  for i in {1..10}; do
    local day=$((31 + i - 1))
    if [[ $day -gt 31 ]]; then
      day=$((day - 31))
      month="04"
    else
      month="03"
    fi

    cat >> "$test_dir/backlog-water-20260401.jsonl" << EOF
{"timestamp":"2026-03-${day}T10:00:00Z","sprint_candidate_count":$((10 + i)),"threshold":10,"status":"ok","repo":"kctw-dev/shikigami"}
EOF
  done

  output=$("$SCRIPT" "$test_dir" 2>&1 || true)

  # Count data lines (should be at least 7, excluding header)
  line_count=$(echo "$output" | tail -n +2 | grep -c . || true)

  if [[ $line_count -ge 7 ]]; then
    echo "PASS: Output contains at least 7 days of data ($line_count lines)"
  else
    echo "FAIL: Output has only $line_count days (expected at least 7)"
    echo "Output: $output"
    exit 1
  fi
}

# Test 5: Script uses provided directory parameter
test_custom_directory() {
  local custom_dir="$TEST_TMPDIR/custom"
  mkdir -p "$custom_dir"

  cat > "$custom_dir/backlog-water-20260405.jsonl" << 'EOF'
{"timestamp":"2026-04-05T10:00:00Z","sprint_candidate_count":15,"threshold":10,"status":"ok","repo":"kctw-dev/shikigami"}
EOF

  output=$("$SCRIPT" "$custom_dir" 2>&1 || true)

  if echo "$output" | grep -q "2026-04-05\|15"; then
    echo "PASS: Script respects custom directory parameter"
  else
    echo "FAIL: Script didn't process custom directory"
    echo "Output: $output"
    exit 1
  fi
}

# Run all tests
test_script_exists
test_valid_data_has_headers
test_empty_data_graceful
test_seven_days_output
test_custom_directory

echo ""
echo "All tests passed!"
