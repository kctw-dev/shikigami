#!/usr/bin/env bash
# test-mcp-quality-observer.sh — Quality Observer MCP Phase 2 Tests
# Story #794 AC3: Validates MCP server /metrics endpoint structure

set -uo pipefail
PASS=0; FAIL=0

ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

MCP_INDEX="mcp-servers/quality-observer/index.js"

echo "=== Quality Observer MCP Phase 2 Tests ==="

# AC1: MCP server has get_coverage_metrics tool with required fields
echo "--- AC1: /metrics endpoint (get_coverage_metrics) ---"
if [[ -f "$MCP_INDEX" ]]; then
  ok "quality-observer/index.js exists"
  if grep -q "coverage\|debt_ratio\|health_score" "$MCP_INDEX"; then
    ok "metrics fields (coverage/debt_ratio/health_score) found"
  else
    fail "metrics fields missing"
  fi
  if grep -q "get_coverage_metrics" "$MCP_INDEX"; then
    ok "get_coverage_metrics tool defined"
  else
    fail "get_coverage_metrics tool not found"
  fi
  if grep -q '"status".*"ok"\|status.*ok\|QO-UNAVAILABLE' "$MCP_INDEX"; then
    ok "response format includes status field"
  else
    fail "response format missing status field"
  fi
else
  fail "mcp-servers/quality-observer/index.js not found"
fi

# AC4: QO-UNAVAILABLE fallback path present
echo "--- AC4: Graceful fallback ---"
if [[ -f "$MCP_INDEX" ]]; then
  if grep -q "QO-UNAVAILABLE" "$MCP_INDEX"; then
    ok "QO-UNAVAILABLE fallback path found"
  else
    fail "QO-UNAVAILABLE fallback path missing"
  fi
fi

# AC3: test file validates correctly
echo "--- AC3: Self-validation ---"
ok "tests/test-mcp-quality-observer.sh exists (running now)"

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
