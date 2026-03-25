#!/usr/bin/env bash
# test-context-engineering.sh — #400 feat: Context Engineering JIT Retrieval
# ADR-037 Phase 1 (Direction C: Read-on-Demand Hook)
# Tests:
#   1. context-manifest.yaml 存在（AC2）
#   2. manifest 包含 always 區段
#   3. manifest 包含 on_demand 區段
#   4. always 區段路徑存在（AC3）
#   5. ADR-037 存在且狀態為 Accepted（AC4）
#   6. session-start hook 包含 JIT manifest 讀取邏輯（AC1）
#   7. session-start hook 包含 JIT fallback（manifest 不存在時退回全量預載）（AC5）
#   8. session-start hook 包含 JIT hint 注入邏輯

set -uo pipefail
PASS=0
FAIL=0

# Navigate to repo root
REPO_ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || echo "")"
if [[ -n "$REPO_ROOT" ]]; then
  cd "$REPO_ROOT"
fi

pass() { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

MANIFEST="agents/context-manifest.yaml"
ADR_FILE="docs/adr/ADR-037-context-engineering-jit.md"
HOOK_FILE="hooks/session-start"

echo "=== Context Engineering JIT Retrieval Tests (ADR-037 Phase 1) ==="

# Test 1: context-manifest.yaml 存在（AC2）
if [[ -f "$MANIFEST" ]]; then
  pass "context-manifest.yaml 存在（AC2）"
else
  fail "context-manifest.yaml 不存在：${MANIFEST}"
fi

# Test 2: manifest 包含 always 區段
if grep -q "always:" "$MANIFEST" 2>/dev/null; then
  pass "manifest 包含 always 區段（AC2 always-load 資源）"
else
  fail "manifest 缺少 always 區段"
fi

# Test 3: manifest 包含 on_demand 區段
if grep -q "on_demand:" "$MANIFEST" 2>/dev/null; then
  pass "manifest 包含 on_demand 區段（AC2 on-demand 資源）"
else
  fail "manifest 缺少 on_demand 區段"
fi

# Test 4: always 區段中 scrum-master SKILL.md 路徑存在（AC3）
ALWAYS_SKILL="skills/scrum-master/SKILL.md"
if [[ -f "$ALWAYS_SKILL" ]]; then
  pass "always-load 資源路徑存在：${ALWAYS_SKILL}（AC3）"
else
  fail "always-load 資源路徑不存在：${ALWAYS_SKILL}"
fi

# Test 5: ADR-037 存在且狀態為 Accepted（AC4）
if [[ -f "$ADR_FILE" ]]; then
  if grep -q "Accepted" "$ADR_FILE" 2>/dev/null; then
    pass "ADR-037 存在且狀態為 Accepted（AC4）"
  else
    fail "ADR-037 存在但狀態不是 Accepted"
  fi
else
  fail "ADR-037 不存在：${ADR_FILE}"
fi

# Test 6: session-start hook 包含 JIT manifest 讀取邏輯（AC1）
if grep -q "context-manifest" "$HOOK_FILE" 2>/dev/null; then
  pass "session-start hook 包含 context-manifest 讀取邏輯（AC1）"
else
  fail "session-start hook 缺少 context-manifest 讀取邏輯"
fi

# Test 7: session-start hook 包含 JIT fallback（AC5）
# 確認 manifest 不存在時退回全量預載（JIT_MODE=false 為 fallback 狀態）
if grep -q "JIT_MODE=false" "$HOOK_FILE" 2>/dev/null; then
  pass "session-start hook 包含 JIT fallback 初始化（AC5）"
else
  fail "session-start hook 缺少 JIT fallback（JIT_MODE=false）"
fi

# Test 8: session-start hook 包含 JIT hint 注入邏輯
if grep -q "JIT_HINT" "$HOOK_FILE" 2>/dev/null; then
  pass "session-start hook 包含 JIT hint 注入邏輯"
else
  fail "session-start hook 缺少 JIT hint 注入邏輯"
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
