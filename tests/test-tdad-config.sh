#!/usr/bin/env bash
# tests/test-tdad-config.sh
# Test: TDAD 依賴分析可透過設定關閉 (#653)
#
# AC1: developer-prompt.md TDAD 觸發條件加入 tdad=false 時跳過
# AC2: 預設 true（向後相容）
# AC3: 測試驗證

set -uo pipefail

PASS_COUNT=0
FAIL_COUNT=0

pass() { echo "[PASS] $1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { echo "[FAIL] $1"; FAIL_COUNT=$((FAIL_COUNT+1)); }

DEVELOPER_PROMPT="skills/sprint-execution/developer-prompt.md"

echo "=== Test: #653 TDAD 依賴分析可透過設定關閉 ==="
echo ""

# AC1: developer-prompt.md 應包含 tdad=false 跳過條件
echo "--- AC1: developer-prompt.md 含 tdad=false 跳過條件 ---"
if grep -q "tdad.*false\|tdad=false\|tdad: false" "$DEVELOPER_PROMPT" 2>/dev/null; then
  pass "AC1: developer-prompt.md 含 tdad=false 跳過條件"
else
  fail "AC1: developer-prompt.md 未含 tdad=false 跳過條件"
fi

# AC2: 預設為 true（backward compatible）- developer-prompt.md 應說明預設行為
echo "--- AC2: developer-prompt.md 說明預設行為（tdad 預設啟用）---"
if grep -q "tdad.*true\|預設.*啟用\|預設.*true\|backward\|向後相容" "$DEVELOPER_PROMPT" 2>/dev/null; then
  pass "AC2: developer-prompt.md 說明 tdad 預設啟用（向後相容）"
else
  fail "AC2: developer-prompt.md 未說明 tdad 預設行為"
fi

# AC1 detail: grep 確認 .claude/shikigami.local.md 讀取方式有描述
echo "--- AC1 detail: 讀取設定方式描述 ---"
if grep -q "shikigami.local.md\|local.md\|tdad" "$DEVELOPER_PROMPT" 2>/dev/null; then
  pass "AC1 detail: developer-prompt.md 描述設定讀取方式"
else
  fail "AC1 detail: developer-prompt.md 未描述設定讀取方式"
fi

echo ""
echo "=============================="
echo " 測試結果：PASS=$PASS_COUNT, FAIL=$FAIL_COUNT"
echo "=============================="

[ $FAIL_COUNT -eq 0 ] && exit 0 || exit 1
