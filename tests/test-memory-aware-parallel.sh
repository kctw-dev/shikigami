#!/bin/bash

# Test suite for memory-aware parallel dispatch safety mechanism (#712)
# Tests memory detection logic across Linux, macOS, and WSL2 environments

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source the memory detection function
source "${PROJECT_ROOT}/scripts/memory-aware-dispatch.sh"

# Color output for test results
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_count=0
pass_count=0
fail_count=0

# Helper function to run tests
run_test() {
    local test_name="$1"
    local test_func="$2"

    test_count=$((test_count + 1))
    echo -e "\n${YELLOW}[TEST $test_count]${NC} $test_name"

    if $test_func; then
        pass_count=$((pass_count + 1))
        echo -e "${GREEN}✓ PASS${NC}"
    else
        fail_count=$((fail_count + 1))
        echo -e "${RED}✗ FAIL${NC}"
    fi
}

# Test 1: Function exists and is callable
test_get_available_memory_exists() {
    declare -F get_available_memory_mb &>/dev/null
}

# Test 2: Memory value is a positive integer
test_get_available_memory_returns_positive_integer() {
    local mem=$(get_available_memory_mb)
    [[ "$mem" =~ ^[0-9]+$ ]] && [ "$mem" -gt 0 ]
}

# Test 3: Memory value is reasonable (between 512MB and 256GB)
test_get_available_memory_reasonable_range() {
    local mem=$(get_available_memory_mb)
    [ "$mem" -ge 512 ] && [ "$mem" -le 262144 ]
}

# Test 4: Calculate dynamic max function exists
test_calculate_dynamic_max_exists() {
    declare -F calculate_dynamic_max_parallel &>/dev/null
}

# Test 5: Dynamic max calculation is correct
test_calculate_dynamic_max_formula() {
    local result=$(calculate_dynamic_max_parallel 2048 10)  # 2GB available, high static max
    # Should be floor(2048 / 512) = 4, min(4, 10) = 4
    [ "$result" -eq 4 ]
}

# Test 6: Dynamic max respects static max
test_calculate_dynamic_max_respects_static_max() {
    # With 1024MB available and static max 2
    # Should return min(2, floor(1024/512)) = min(2, 2) = 2
    local result=$(calculate_dynamic_max_parallel 1024 2)
    [ "$result" -eq 2 ]
}

# Test 7: Dynamic max uses fallback when static max not provided
test_calculate_dynamic_max_default_fallback() {
    # With 3GB available and default static max 2
    # Should return min(2, floor(3072/512)) = min(2, 6) = 2
    local result=$(calculate_dynamic_max_parallel 3072)
    [ "$result" -eq 2 ]
}

# Test 8: Get memory detection method
test_get_memory_detection_method() {
    local method=$(get_memory_detection_method)
    [[ "$method" =~ ^(proc|sysctl|wsl2-proc|unknown)$ ]]
}

# Test 9: Dispatch decision logging exists
test_log_dispatch_decision_exists() {
    declare -F log_memory_dispatch_decision &>/dev/null
}

# Test 10: Memory too low warning calculation
test_memory_warning_threshold() {
    # With 768MB available and static max 2
    # Should calculate: available=768, baseline_per_agent=512
    # safe_count = floor(768/512) = 1, which is < 2 (static max)
    # This should trigger warning
    local mem=768
    local static_max=2
    local dynamic=$(calculate_dynamic_max_parallel "$mem" "$static_max")
    [ "$dynamic" -lt "$static_max" ]
}

# Test 11: Memory sufficient case
test_memory_sufficient_case() {
    # With 2GB available and static max 2
    # Should calculate: available=2048, baseline=512
    # safe_count = floor(2048/512) = 4, which is >= 2
    # No warning needed
    local mem=2048
    local static_max=2
    local dynamic=$(calculate_dynamic_max_parallel "$mem" "$static_max")
    [ "$dynamic" -eq "$static_max" ]
}

# Test 12: Edge case: very low memory
test_edge_case_very_low_memory() {
    # With 256MB available (below one agent baseline)
    # Should return 0 or fallback to 1
    local result=$(calculate_dynamic_max_parallel 256)
    # Must not be negative and must be >= 1 (at least one agent must run)
    [ "$result" -ge 1 ]
}

# Test 13: Edge case: very high memory
test_edge_case_very_high_memory() {
    # With 128GB available
    # Should calculate: floor(131072/512) = 256, but capped by static max
    local result=$(calculate_dynamic_max_parallel 131072 4)
    [ "$result" -le 4 ]
}

# Test 14: Environment variable reading
test_environment_variable_reading() {
    # Test that static max can be read from environment
    local original_max="${SHIKIGAMI_MAX_PARALLEL:-2}"
    export SHIKIGAMI_MAX_PARALLEL=3
    local result=$(calculate_dynamic_max_parallel 2048)
    SHIKIGAMI_MAX_PARALLEL="$original_max"
    # With 2GB and max 3: floor(2048/512)=4, min(4,3)=3
    [ "$result" -eq 3 ]
}

# Test 15: Fallback to default when env not set
test_fallback_to_default_when_env_unset() {
    local original_max="${SHIKIGAMI_MAX_PARALLEL:-}"
    unset SHIKIGAMI_MAX_PARALLEL || true
    local result=$(calculate_dynamic_max_parallel 2048)
    if [ -n "$original_max" ]; then
        export SHIKIGAMI_MAX_PARALLEL="$original_max"
    fi
    # Should use default 2: min(floor(2048/512), 2) = min(4, 2) = 2
    [ "$result" -eq 2 ]
}

# Run all tests
run_test "Memory detection function exists" test_get_available_memory_exists
run_test "Memory returns positive integer" test_get_available_memory_returns_positive_integer
run_test "Memory value in reasonable range" test_get_available_memory_reasonable_range
run_test "Dynamic max calculation function exists" test_calculate_dynamic_max_exists
run_test "Dynamic max calculation formula correct" test_calculate_dynamic_max_formula
run_test "Dynamic max respects static max" test_calculate_dynamic_max_respects_static_max
run_test "Dynamic max uses default fallback" test_calculate_dynamic_max_default_fallback
run_test "Memory detection method identification" test_get_memory_detection_method
run_test "Dispatch decision logging function exists" test_log_dispatch_decision_exists
run_test "Memory warning threshold triggers" test_memory_warning_threshold
run_test "Sufficient memory case" test_memory_sufficient_case
run_test "Edge case: very low memory" test_edge_case_very_low_memory
run_test "Edge case: very high memory" test_edge_case_very_high_memory
run_test "Environment variable reading" test_environment_variable_reading
run_test "Fallback to default when env unset" test_fallback_to_default_when_env_unset

# Summary
echo -e "\n${YELLOW}═════════════════════════════════════════${NC}"
echo -e "Test Results: ${GREEN}$pass_count PASS${NC} / ${RED}$fail_count FAIL${NC} (Total: $test_count)"
echo -e "${YELLOW}═════════════════════════════════════════${NC}\n"

if [ "$fail_count" -eq 0 ]; then
    exit 0
else
    exit 1
fi
