#!/usr/bin/env bash
# templates/test-template.sh — Shell Test 腳本範本
# Story #811（Sprint 161）| QA Engineer §1.18 最佳實踐
#
# 使用說明：
#   複製此檔案至 tests/test-<feature-name>.sh 並填入實際測試案例
#
# 最佳實踐重點：
#   1. 禁止使用 set -e（會因 ((VAR++)) 在 VAR=0 時觸發意外退出）
#   2. Counter 遞增使用 $((VAR+1)) 取代 ((VAR++))
#   3. 使用 set -u 保護未定義變量
#   4. 每個測試函式呼叫 pass/fail 輔助函式

# shellcheck disable=SC2034  # 範本變數聲明

set -u  # 啟用：未定義變量報錯
# 禁止：set -e（會破壞 counter 邏輯）
# 可選：set -o pipefail（管道錯誤偵測，不影響 counter）

# Counter 初始化
PASS=0
FAIL=0

# 輔助函式
pass() {
  echo "PASS: $1"
  PASS=$((PASS+1))  # 正確：$((VAR+1)) 模式
}

fail() {
  echo "FAIL: $1"
  FAIL=$((FAIL+1))  # 正確：$((VAR+1)) 模式
}

# ── 測試案例（填入實際測試）──

test_example_pass() {
  # 範例：測試某個腳本存在
  if [[ -f "scripts/example.sh" ]]; then
    pass "example.sh exists"
  else
    # 範本中用 pass 模擬（實際請改為 fail）
    pass "example (template placeholder)"
  fi
}

test_example_condition() {
  # 範例：測試某個條件
  local result
  result="expected_output"  # 替換為實際指令輸出
  if [[ "$result" == "expected_output" ]]; then
    pass "condition is met"
  else
    fail "condition not met (got: $result)"
  fi
}

# ── 執行所有測試 ──

test_example_pass
test_example_condition

# ── 結果摘要 ──

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL Total=$((PASS+FAIL))"

# 正確的 exit code：FAIL 為 0 則成功，否則失敗
[[ $FAIL -eq 0 ]]
