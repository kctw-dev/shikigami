#!/usr/bin/env bash
# tests/test-validate-hooks.sh
# Story #713 — onboarding hooks 驗證腳本測試
#
# 驗證 scripts/validate-hooks.sh 的行為符合 AC1-AC5

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATE_SCRIPT="${REPO_ROOT}/scripts/validate-hooks.sh"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL + 1)); }

echo "=== test-validate-hooks.sh ==="
echo "Testing: $VALIDATE_SCRIPT"
echo ""

# ── Pre-check: validate-hooks.sh 必須存在 ────────────────────────────────
if [[ ! -f "$VALIDATE_SCRIPT" ]]; then
  fail "scripts/validate-hooks.sh 不存在"
  echo "FAIL: $FAIL / PASS: $PASS"
  exit 1
fi
pass "scripts/validate-hooks.sh 存在"

# ── Pre-check: 腳本必須可執行 ────────────────────────────────────────────
if [[ ! -x "$VALIDATE_SCRIPT" ]]; then
  fail "scripts/validate-hooks.sh 不可執行（缺少 +x）"
  echo "FAIL: $FAIL / PASS: $PASS"
  exit 1
fi
pass "scripts/validate-hooks.sh 可執行"

# ── AC1: 執行腳本，成功時 exit 0，失敗時 exit 1 ───────────────────────
if bash "$VALIDATE_SCRIPT" > /tmp/validate_output.txt 2>&1; then
  pass "AC1: validate-hooks.sh 以 exit 0 完成（所有 hooks 通過）"
  VALIDATION_PASSED=true
else
  EXIT_CODE=$?
  if [[ $EXIT_CODE -eq 1 ]]; then
    pass "AC1: validate-hooks.sh 以 exit 1 完成（某些 hooks 失敗，符合預期）"
    VALIDATION_PASSED=false
  else
    fail "AC1: validate-hooks.sh 以非預期的 exit code $EXIT_CODE 完成"
    VALIDATION_PASSED=false
  fi
fi

# ── AC2: 驗證清單包含 claim-issue.sh、release-issue.sh、task-gate.sh ─────
OUTPUT=$(cat /tmp/validate_output.txt)

if echo "$OUTPUT" | grep -q "claim-issue.sh"; then
  pass "AC2: 輸出包含 claim-issue.sh 的驗證結果"
else
  fail "AC2: 輸出缺少 claim-issue.sh 的驗證結果"
fi

if echo "$OUTPUT" | grep -q "release-issue.sh"; then
  pass "AC2: 輸出包含 release-issue.sh 的驗證結果"
else
  fail "AC2: 輸出缺少 release-issue.sh 的驗證結果"
fi

if echo "$OUTPUT" | grep -q "task-gate.sh"; then
  pass "AC2: 輸出包含 task-gate.sh 的驗證結果"
else
  fail "AC2: 輸出缺少 task-gate.sh 的驗證結果"
fi

# ── AC3: 輸出格式含有 [PASS] 或 [FAIL] 標籤 ──────────────────────────────
if echo "$OUTPUT" | grep -qE "\[PASS\]|\[FAIL\]"; then
  pass "AC3: 輸出包含 [PASS] 或 [FAIL] 格式標籤"
else
  fail "AC3: 輸出缺少 [PASS] 或 [FAIL] 格式標籤"
fi

# ── AC4: 驗證失敗時（若有）應該輸出原因 ──────────────────────────────────
if $VALIDATION_PASSED; then
  pass "AC4: 所有 hooks 通過驗證，無失敗原因需輸出"
else
  # 應該至少有一個 [FAIL]，可能包含原因
  if echo "$OUTPUT" | grep -q "\[FAIL\]"; then
    pass "AC4: 驗證失敗時輸出包含失敗項目"
  else
    fail "AC4: 驗證失敗但未輸出 [FAIL] 標籤"
  fi
fi

# ── NFR1: 覆蓋所有 hooks/ 下的 .sh 檔案 ──────────────────────────────────
# 計算 hooks/ 下有多少 .sh 檔案（不含 lib/ 和 session-start）
TOTAL_SH_FILES=$(find "$REPO_ROOT/hooks" -maxdepth 1 -name "*.sh" -type f | wc -l)
COVERED_IN_OUTPUT=$(echo "$OUTPUT" | grep -oE "[a-z-]+\.sh" | sort -u | wc -l)

if [[ $COVERED_IN_OUTPUT -ge $((TOTAL_SH_FILES - 1)) ]]; then
  pass "NFR1: 輸出覆蓋所有或幾乎所有 .sh 檔案（期望 $TOTAL_SH_FILES，實際 $COVERED_IN_OUTPUT）"
else
  fail "NFR1: 輸出缺乏足夠的 .sh 檔案覆蓋（期望 $TOTAL_SH_FILES，實際 $COVERED_IN_OUTPUT）"
fi

# ── NFR2: 執行時間應在 5 秒內 ──────────────────────────────────────────────
START_TIME=$(date +%s)
bash "$VALIDATE_SCRIPT" > /dev/null 2>&1
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

if [[ $ELAPSED -le 5 ]]; then
  pass "NFR2: 執行時間 ${ELAPSED}s <= 5s（符合 usability 要求）"
else
  fail "NFR2: 執行時間 ${ELAPSED}s > 5s（超過 usability 要求）"
fi

# ── NFR3: 冪等性 — 多次執行結果一致 ────────────────────────────────────────
bash "$VALIDATE_SCRIPT" > /tmp/run1.txt 2>&1 || true
bash "$VALIDATE_SCRIPT" > /tmp/run2.txt 2>&1 || true
bash "$VALIDATE_SCRIPT" > /tmp/run3.txt 2>&1 || true

if diff /tmp/run1.txt /tmp/run2.txt > /dev/null 2>&1 && \
   diff /tmp/run2.txt /tmp/run3.txt > /dev/null 2>&1; then
  pass "NFR3: 多次執行結果完全一致（idempotency 滿足）"
else
  fail "NFR3: 多次執行結果不一致（idempotency 未滿足）"
fi

# ── Summary ────────────────────────────────────────────────────────────────
echo ""
echo "=== Test Summary ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [[ $FAIL -eq 0 ]]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
