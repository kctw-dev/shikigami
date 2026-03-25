#!/bin/bash

# Memory-aware parallel dispatch safety mechanism (#712)
# Dynamically adjusts SHIKIGAMI_MAX_PARALLEL based on available system memory
# Supports: Linux (/proc/meminfo), macOS (sysctl), WSL2 (fallback)

set -u

# ────────────────────────────────────────────────────────────────────────────
# Configuration
# ────────────────────────────────────────────────────────────────────────────

# Baseline memory per worktree subagent (MB)
MEMORY_PER_AGENT_MB=${MEMORY_PER_AGENT_MB:-512}

# Default static max parallel limit (fallback)
DEFAULT_MAX_PARALLEL=${SHIKIGAMI_MAX_PARALLEL:-2}

# Timeout for memory detection (milliseconds)
MEMORY_DETECTION_TIMEOUT_MS=100

# ────────────────────────────────────────────────────────────────────────────
# Function: get_memory_detection_method
# Returns: Detection method name (proc, sysctl, wsl2-proc, unknown)
# ────────────────────────────────────────────────────────────────────────────

get_memory_detection_method() {
    if [ -r /proc/meminfo ]; then
        echo "proc"
    elif command -v sysctl &>/dev/null; then
        echo "sysctl"
    elif [ -r /proc/meminfo ] && grep -q "^MemAvailable" /proc/meminfo 2>/dev/null; then
        echo "wsl2-proc"
    else
        echo "unknown"
    fi
}

# ────────────────────────────────────────────────────────────────────────────
# Function: get_available_memory_mb
# Returns: Available system memory in MB
# Fallback: Returns DEFAULT_MAX_PARALLEL * MEMORY_PER_AGENT_MB if detection fails
# ────────────────────────────────────────────────────────────────────────────

get_available_memory_mb() {
    local method
    local available_kb=0
    local available_mb=0

    method=$(get_memory_detection_method)

    case "$method" in
        proc)
            # Linux: Read from /proc/meminfo
            # Try MemAvailable (preferred, newer kernels), fallback to MemFree
            if available_kb=$(awk '/^MemAvailable:/{print $2; exit}' /proc/meminfo 2>/dev/null); then
                [ -z "$available_kb" ] && available_kb=$(awk '/^MemFree:/{print $2; exit}' /proc/meminfo 2>/dev/null)
            fi
            available_mb=$((available_kb / 1024))
            ;;

        sysctl)
            # macOS: Use sysctl to get total physical memory, then estimate available
            # Note: macOS sysctl doesn't provide direct "available" - use total and estimate
            local total_bytes
            if total_bytes=$(sysctl -n hw.memsize 2>/dev/null); then
                local total_mb=$((total_bytes / 1048576))
                # Conservative estimate: assume 60% of total is available
                available_mb=$((total_mb * 60 / 100))
            fi
            ;;

        wsl2-proc)
            # WSL2: Fallback to MemFree from /proc/meminfo
            available_kb=$(awk '/^MemFree:/{print $2; exit}' /proc/meminfo 2>/dev/null || echo "0")
            available_mb=$((available_kb / 1024))
            ;;

        *)
            # Unknown system: Return fallback value
            available_mb=$((DEFAULT_MAX_PARALLEL * MEMORY_PER_AGENT_MB))
            ;;
    esac

    # Sanity check: minimum 512MB, maximum 256GB
    if [ "$available_mb" -lt 512 ]; then
        available_mb=512
    elif [ "$available_mb" -gt 262144 ]; then
        available_mb=262144
    fi

    echo "$available_mb"
}

# ────────────────────────────────────────────────────────────────────────────
# Function: calculate_dynamic_max_parallel
# Args:
#   $1: Available memory in MB (optional, will detect if not provided)
#   $2: Static max parallel limit (optional, defaults to SHIKIGAMI_MAX_PARALLEL or 2)
# Returns: Safe maximum parallel count
# ────────────────────────────────────────────────────────────────────────────

calculate_dynamic_max_parallel() {
    local available_mb="${1:-$(get_available_memory_mb)}"
    local static_max="${2:-${SHIKIGAMI_MAX_PARALLEL:-2}}"

    # Calculate dynamic max: floor(available_mb / per_agent_mb)
    local dynamic_max=$((available_mb / MEMORY_PER_AGENT_MB))

    # Ensure at least 1 agent can run
    if [ "$dynamic_max" -lt 1 ]; then
        dynamic_max=1
    fi

    # Return minimum of dynamic and static max
    if [ "$dynamic_max" -lt "$static_max" ]; then
        echo "$dynamic_max"
    else
        echo "$static_max"
    fi
}

# ────────────────────────────────────────────────────────────────────────────
# Function: log_memory_dispatch_decision
# Logs memory-aware dispatch decision to cruise log in JSONL format
# Args:
#   $1: Available memory (MB)
#   $2: Dynamic max calculated
#   $3: Static max limit
#   $4: Detection method used
#   $5: Log file path (optional)
# ────────────────────────────────────────────────────────────────────────────

log_memory_dispatch_decision() {
    local available_mb="$1"
    local dynamic_max="$2"
    local static_max="$3"
    local detection_method="$4"
    local log_file="${5:-}"

    # Determine cruise log file if not provided
    if [ -z "$log_file" ]; then
        local session_id="${SESSION_ID:-$(date +%Y%m%d-%H%M%S)}"
        log_file="docs/cruise-logs/$(date +%Y-%m-%d)-session-${session_id}.jsonl"
    fi

    # Create parent directory if needed
    mkdir -p "$(dirname "$log_file")"

    # Build JSONL entry
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local warning_triggered="false"
    if [ "$dynamic_max" -lt "$static_max" ]; then
        warning_triggered="true"
    fi

    local json_entry="{\"timestamp\":\"$timestamp\",\"type\":\"memory-aware-dispatch\",\"available_mb\":$available_mb,\"dynamic_max\":$dynamic_max,\"static_max\":$static_max,\"detection_method\":\"$detection_method\",\"warning_triggered\":$warning_triggered,\"memory_per_agent_mb\":$MEMORY_PER_AGENT_MB}"

    # Append to log file
    echo "$json_entry" >> "$log_file" 2>/dev/null || true
}

# ────────────────────────────────────────────────────────────────────────────
# Function: get_dispatch_decision
# Main function that performs all memory-aware dispatch checks
# Returns: Space-separated values: dynamic_max, detection_method, warning_triggered
# ────────────────────────────────────────────────────────────────────────────

get_dispatch_decision() {
    local method
    local available_mb
    local dynamic_max
    local static_max
    local warning_triggered="false"

    # Get detection method
    method=$(get_memory_detection_method)

    # Get available memory
    available_mb=$(get_available_memory_mb)

    # Get static max from environment
    static_max="${SHIKIGAMI_MAX_PARALLEL:-2}"

    # Calculate dynamic max
    dynamic_max=$(calculate_dynamic_max_parallel "$available_mb" "$static_max")

    # Check if warning should be triggered
    if [ "$dynamic_max" -lt "$static_max" ]; then
        warning_triggered="true"
    fi

    # Log the decision
    log_memory_dispatch_decision "$available_mb" "$dynamic_max" "$static_max" "$method"

    # Output decision info
    echo "$dynamic_max $method $warning_triggered"
}

# ────────────────────────────────────────────────────────────────────────────
# Function: format_oom_warning
# Formats OOM warning message for output
# Args:
#   $1: Dynamic max calculated
#   $2: Static max limit
#   $3: Available memory (MB)
#   $4: Detection method
# ────────────────────────────────────────────────────────────────────────────

format_oom_warning() {
    local dynamic_max="$1"
    local static_max="$2"
    local available_mb="$3"
    local method="$4"

    printf "[OOM-WARN] Dynamic memory adjustment: available=%dMB, safe_parallel=%d (limit=%d, method=%s)\n" \
        "$available_mb" "$dynamic_max" "$static_max" "$method"
}

# ────────────────────────────────────────────────────────────────────────────
# Main execution: Export functions when sourced
# ────────────────────────────────────────────────────────────────────────────

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Script is being executed directly (for testing)
    get_dispatch_decision
    exit 0
fi
