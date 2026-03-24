#!/usr/bin/env bash
# test-oauth-token-monitor.sh — #597 retro: CI OAuth token monitoring tests
# Tests:
#   1. oauth-token-monitor.yml workflow 存在
#   2. workflow 包含 schedule trigger（每日執行）
#   3. workflow 包含 validate-token step
#   4. workflow 包含 401 偵測邏輯
#   5. workflow 包含 alert issue 建立邏輯（冪等防重複）

set -uo pipefail
PASS=0
FAIL=0

# Navigate to repo root regardless of where script is called from
REPO_ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || echo "")"
if [[ -n "$REPO_ROOT" ]]; then
  cd "$REPO_ROOT"
fi

pass() { echo "  PASS: $1"; ((PASS++)); }
fail() { echo "  FAIL: $1"; ((FAIL++)); }

WORKFLOW_FILE=".github/workflows/oauth-token-monitor.yml"

echo "=== OAuth Token Monitor Workflow Tests ==="

# Test 1: workflow 存在
if [[ -f "$WORKFLOW_FILE" ]]; then
  pass "oauth-token-monitor.yml 存在"
else
  fail "oauth-token-monitor.yml 不存在"
fi

# Test 2: 有 schedule trigger
if grep -q "schedule:" "$WORKFLOW_FILE" 2>/dev/null; then
  pass "workflow 包含 schedule trigger（每日定期執行）"
else
  fail "workflow 缺少 schedule trigger"
fi

# Test 3: 有 cron 設定
if grep -q "cron:" "$WORKFLOW_FILE" 2>/dev/null; then
  pass "workflow 包含 cron 排程設定"
else
  fail "workflow 缺少 cron 排程設定"
fi

# Test 4: 有 401 偵測
if grep -q "401" "$WORKFLOW_FILE" 2>/dev/null; then
  pass "workflow 包含 401 偵測邏輯"
else
  fail "workflow 缺少 401 偵測邏輯"
fi

# Test 5: 有告警 Issue 建立
if grep -q "gh issue create" "$WORKFLOW_FILE" 2>/dev/null; then
  pass "workflow 包含告警 Issue 建立邏輯"
else
  fail "workflow 缺少告警 Issue 建立邏輯"
fi

# Test 6: 冪等防重複（避免重複建立 token 告警 Issue）
if grep -q "冪等防重複建立\|EXISTING" "$WORKFLOW_FILE" 2>/dev/null; then
  pass "workflow 包含冪等防重複告警邏輯"
else
  fail "workflow 缺少冪等防重複邏輯"
fi

# Test 7: 使用 @v4 Actions
if grep -q "actions/checkout@v4" "$WORKFLOW_FILE" 2>/dev/null; then
  pass "workflow 使用 actions/checkout@v4（符合 CLAUDE.md 第 10 條）"
else
  fail "workflow 未使用 actions/checkout@v4"
fi

# Test 8: 參照 ADR-030
if grep -q "ADR-030" "$WORKFLOW_FILE" 2>/dev/null; then
  pass "workflow 參照 ADR-030（架構決策可追溯）"
else
  fail "workflow 未參照 ADR-030"
fi

echo ""
echo "=== 測試結果 ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
if [[ $FAIL -eq 0 ]]; then
  echo "  狀態: 全部通過"
  exit 0
else
  echo "  狀態: 有測試失敗"
  exit 1
fi
