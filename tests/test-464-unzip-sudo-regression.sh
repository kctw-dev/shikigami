#!/usr/bin/env bash
# Test #464: unzip sudo regression fix — 驗證 new-issue-intake.yml 不使用需要密碼的 sudo
# AC1: workflow 不再因 sudo 密碼而失敗（使用 sudo -n 非互動模式）
# AC2: 已有 unzip 時靜默跳過（command -v 守衛）
# AC3: 無 unzip + 無 sudo 權限時 graceful fallback（不卡住）

set -euo pipefail

WORKFLOW=".github/workflows/new-issue-intake.yml"
PASS=0
FAIL=0

check() {
  local desc="$1"
  local result="$2"
  if [ "$result" = "0" ]; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Test #464: unzip sudo regression fix ==="

# AC1: 不使用會卡住的 plain sudo（必須是 sudo -n 非互動模式）
! grep -qP "^\s+sudo apt-get" "$WORKFLOW"
check "AC1: no plain 'sudo apt-get' (would block on password prompt)" $?

# AC1: 使用 sudo -n（non-interactive，無密碼時立即失敗而非卡住）
grep -q "sudo -n apt-get install -y unzip" "$WORKFLOW"
check "AC1: uses sudo -n apt-get install -y unzip (non-interactive)" $?

# AC2: 冪等性守衛仍存在（已有 unzip 時跳過）
grep -q "command -v unzip" "$WORKFLOW"
check "AC2: idempotency guard (command -v unzip) present" $?

# AC3: graceful fallback — sudo 失敗時有 fallback echo（不卡住）
grep -q "proceeding anyway" "$WORKFLOW"
check "AC3: graceful fallback message present (proceeding anyway)" $?

# AC3: sudo -n 輸出導向 /dev/null，不會因 stderr 雜訊而影響 log
grep -q "sudo -n apt-get install -y unzip 2>/dev/null" "$WORKFLOW"
check "AC3: sudo -n stderr redirected to /dev/null" $?

# Structural: YAML is valid
python3 -c "import yaml; yaml.safe_load(open('$WORKFLOW'))" 2>/dev/null
check "STRUCTURE: YAML syntax valid" $?

# Structural: apt-get 仍在（確認未被誤刪）
grep -q "apt-get install -y unzip" "$WORKFLOW"
check "STRUCTURE: apt-get install unzip still present" $?

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "All tests passed."
