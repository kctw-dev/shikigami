#!/usr/bin/env bash
# tests/test-orphan-allowlist.sh
# Test: validate-orphans.sh 豁免清單機制 (#658)
#
# AC1: validate-orphans.sh 支援 .orphan-allowlist 設定檔
# AC2: 豁免路徑改為 [INFO] 級別輸出（不影響 WARNING 計數）
# AC3: 初始化 .orphan-allowlist 含指定路徑
# AC4: test-infra-regression.sh PASS（或等效 validate 測試）
# AC5: README 或 validate-orphans.sh 頂部說明豁免清單

set -uo pipefail

PASS_COUNT=0
FAIL_COUNT=0

pass() { echo "[PASS] $1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { echo "[FAIL] $1"; FAIL_COUNT=$((FAIL_COUNT+1)); }

SCRIPT="scripts/validate-orphans.sh"
ALLOWLIST=".orphan-allowlist"

echo "=== Test: #658 validate-orphans.sh 豁免清單機制 ==="
echo ""

# AC1: validate-orphans.sh 支援 .orphan-allowlist
echo "--- AC1: validate-orphans.sh 讀取 .orphan-allowlist ---"
if grep -q "orphan-allowlist\|ORPHAN_ALLOWLIST" "$SCRIPT" 2>/dev/null; then
  pass "AC1: validate-orphans.sh 含豁免清單讀取邏輯"
else
  fail "AC1: validate-orphans.sh 未含豁免清單讀取邏輯"
fi

# AC2: 豁免路徑輸出 [INFO] 而非 WARNING
echo "--- AC2: 豁免路徑輸出 INFO 級別 ---"
if grep -q "\[INFO\].*allowlist\|INFO.*豁免\|allowlist.*INFO" "$SCRIPT" 2>/dev/null; then
  pass "AC2: validate-orphans.sh 豁免路徑輸出 INFO"
else
  fail "AC2: validate-orphans.sh 未實作 INFO 輸出邏輯"
fi

# AC3: .orphan-allowlist 存在且含指定路徑
echo "--- AC3: .orphan-allowlist 存在且含必要路徑 ---"
if [ -f "$ALLOWLIST" ]; then
  pass "AC3a: .orphan-allowlist 文件存在"
  if grep -q "docs/sprints/subagent-results" "$ALLOWLIST" 2>/dev/null; then
    pass "AC3b: 含 docs/sprints/subagent-results/ 豁免"
  else
    fail "AC3b: 缺少 docs/sprints/subagent-results/ 豁免"
  fi
  if grep -q "docs/sprints/tcb" "$ALLOWLIST" 2>/dev/null; then
    pass "AC3c: 含 docs/sprints/tcb/ 豁免"
  else
    fail "AC3c: 缺少 docs/sprints/tcb/ 豁免"
  fi
  if grep -q "docs/sprints/watchdog" "$ALLOWLIST" 2>/dev/null; then
    pass "AC3d: 含 docs/sprints/watchdog/ 豁免"
  else
    fail "AC3d: 缺少 docs/sprints/watchdog/ 豁免"
  fi
else
  fail "AC3a: .orphan-allowlist 文件不存在"
  fail "AC3b: 無法驗證路徑（文件不存在）"
  fail "AC3c: 無法驗證路徑（文件不存在）"
  fail "AC3d: 無法驗證路徑（文件不存在）"
fi

# AC5: validate-orphans.sh 頂部說明豁免清單使用方式
echo "--- AC5: validate-orphans.sh 說明豁免清單使用方式 ---"
if grep -q "orphan-allowlist\|allowlist" "$SCRIPT" | head -20 &>/dev/null || \
   head -30 "$SCRIPT" | grep -q "allowlist\|orphan-allowlist"; then
  pass "AC5: validate-orphans.sh 含豁免清單說明"
else
  fail "AC5: validate-orphans.sh 缺少豁免清單說明"
fi

echo ""
echo "=============================="
echo " 測試結果：PASS=$PASS_COUNT, FAIL=$FAIL_COUNT"
echo "=============================="

[ $FAIL_COUNT -eq 0 ] && exit 0 || exit 1
