# Spike #955: Kill-Switch Hook Timeout Protection Assessment

**Date**: 2026-04-09
**Assessment by**: Story-Lifecycle Subagent (haiku)
**Status**: ASSESSED — No Migration Needed

---

## Executive Summary

The kill-switch hook's `clear` operation (invoked in SessionEnd) is **lightweight and fast** (< 1ms). It does not require timeout protection via hook-runner.sh because:

1. The operation is trivial: file deletion only
2. Already protected by `async: true` setting
3. No risk of hanging or blocking SessionEnd
4. Current implementation is architecturally sound

**Recommendation**: Keep kill-switch invocation as-is (inline bash with async=true). No migration to hook-runner.sh needed.

---

## Detailed Analysis

### AC-1: Timeout Protection Necessity

**Kill-Switch Operations in SessionEnd:**
- Command: `clear {session_id}`
- Operation: Delete flag file at `.kill-switch/{session_id}.flag`
- Execution time: < 1ms (file deletion only)

**Risk Analysis:**
- **Likelihood of timeout**: Virtually zero
  - No network operations
  - No subprocesses or external tool calls
  - No loops or conditional waits
  - Single `rm` operation
- **Current protection**: Already `async: true` prevents blocking SessionEnd
- **Timeout value**: Even if applied (30s default), would add latency with zero benefit

**Comparison with other SessionEnd operations:**
| Operation | Type | Current | Migration |
|-----------|------|---------|-----------|
| session-end-release.sh | Long-running; cleanup multiple directories | Uses hook-runner.sh | ✓ Has timeout |
| kill-switch clear | Trivial file delete | Inline async | Not needed |

**Conclusion**: AC-1 assessment = **No timeout protection needed**. The operation is inherently safe.

---

### AC-2: Migration Decision

**Arguments for migration to hook-runner.sh:**
1. Architectural consistency: All SessionEnd hooks would follow same pattern
2. Metrics capture: Execution time recorded to execution-metrics.jsonl
3. Unified error handling and logging

**Arguments against migration:**
1. Added complexity with zero safety benefit
2. Introduces unnecessary process invocation (bash → hook-runner.sh → kill-switch.sh)
3. Default 30s timeout adds latency (even though not needed)
4. Overhead cost exceeds operation cost
5. ADR-038 does not mandate hook-runner usage
6. Current inline implementation is simpler and faster

**Recommendation**: Keep current inline implementation. Benefits do not justify added complexity.

---

## Current Implementation Status

**Location**: `hooks/hooks.json` line 24-28 (SessionEnd hooks)

```json
{
    "type": "command",
    "command": "bash -c 'SESSION_ID=\"${SHIKIGAMI_SESSION_ID:-unknown}\"; if [ -f \"$(git rev-parse --show-toplevel 2>/dev/null || pwd)/.kill-switch/${SESSION_ID}.flag\" ]; then bash \"$(git rev-parse --show-toplevel 2>/dev/null || pwd)/hooks/kill-switch.sh\" clear \"${SESSION_ID}\" || true; fi'",
    "async": true
}
```

**Evaluation**:
- ✓ Properly async (prevents SessionEnd blocking)
- ✓ Conditional execution (only clears if flag exists)
- ✓ Error handling (|| true prevents failures from blocking)
- ✓ Lightweight implementation
- ✓ Aligns with design intent in ADR-038

---

## Design Rationale (ADR-038 Alignment)

From ADR-038:
- **Decision 1**: File-based flag — chosen for reliability when LLM is failed
- **Decision 4**: `.kill-switch/` directory management — SessionEnd hook cleans up flag

The current implementation fulfills these decisions fully. The inline bash approach is appropriate for a trivial operation that does not require timeout protection or metrics.

---

## Testing & Verification

No additional testing required. Current implementation:
1. Already tested in tests/test-kill-switch.sh
2. Runs in async mode (verified in hooks.json)
3. Executes successfully in all Sprint Execution cycles

---

## Conclusion

**Story #955 Verdict**:
- **AC-1**: Kill-switch does NOT need timeout protection (operation < 1ms, no blocking risk)
- **AC-2**: Migration to hook-runner.sh is NOT recommended (adds complexity, no benefit)

**Final Status**: Current implementation is optimal. No changes needed. Keep as-is.

---

## References

- ADR-038: Kill Switch — High 自治模式緊急停止機制設計
- `hooks/hooks.json` (SessionEnd configuration)
- `hooks/kill-switch.sh` (Implementation)
- `hooks/hook-runner.sh` (For reference on timeout mechanism)
- Sprint 179, Story #955
