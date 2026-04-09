#!/bin/bash
# Test suite for validate-skill-deps.sh
# Tests skill dependency validation script

set -u

PASS=0
FAIL=0

PROJECT_ROOT="/home/kevin/workspace/00.shikigami-dev"
SCRIPT_PATH="${PROJECT_ROOT}/scripts/validate-skill-deps.sh"

# TC1: Normal case - no broken references (should exit 0)
test_no_broken_references() {
  echo "TC1: Testing normal case (no broken references)..."

  if bash "$SCRIPT_PATH" > /tmp/tc1-output.txt 2>&1; then
    exit_code=0
    if grep -q "Skill dependency validation: OK" /tmp/tc1-output.txt; then
      echo "  [PASS] No broken references found (exit code 0)"
      PASS=$((PASS+1))
    else
      echo "  [FAIL] Expected 'OK' message not found"
      FAIL=$((FAIL+1))
    fi
  else
    echo "  [FAIL] Script exited with non-zero code when no violations expected"
    FAIL=$((FAIL+1))
  fi
}

# TC2: Create broken reference and verify detection
test_broken_reference_detection() {
  echo "TC2: Testing broken reference detection..."

  # Create a temporary test skill with broken reference
  TEST_SKILL_DIR="${PROJECT_ROOT}/skills/test-broken-skill"
  mkdir -p "${TEST_SKILL_DIR}/references"

  cat > "${TEST_SKILL_DIR}/SKILL.md" << 'EOF'
---
name: test-broken-skill
description: Test skill with broken reference
---

# Test Skill

This skill references [non-existent file](./references/does-not-exist.md)
EOF

  if bash "$SCRIPT_PATH" 2>&1 | grep -q "test-broken-skill.*does-not-exist.md"; then
    echo "  [PASS] Broken reference detected correctly"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] Failed to detect broken reference"
    FAIL=$((FAIL+1))
  fi

  # Cleanup
  rm -rf "${TEST_SKILL_DIR}"
}

# TC3: Verify execution time < 5 seconds
test_execution_time() {
  echo "TC3: Testing execution time < 5s..."

  start_time=$(date +%s%N)
  bash "$SCRIPT_PATH" > /dev/null 2>&1
  end_time=$(date +%s%N)

  # Calculate elapsed time in milliseconds
  elapsed_ms=$(( (end_time - start_time) / 1000000 ))
  elapsed_s=$(( elapsed_ms / 1000 ))

  if [ "$elapsed_s" -lt 5 ]; then
    echo "  [PASS] Execution completed in ${elapsed_s}s (< 5s)"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] Execution took ${elapsed_s}s (>= 5s)"
    FAIL=$((FAIL+1))
  fi
}

# Run tests
echo "====== Running Skill Dependency Validation Tests ======"
test_no_broken_references
test_broken_reference_detection
test_execution_time

echo ""
echo "====== Test Results ======"
echo "PASS=$PASS FAIL=$FAIL Total=$((PASS+FAIL))"

if [ "$FAIL" -eq 0 ]; then
  exit 0
else
  exit 1
fi
