#!/usr/bin/env bash
# Test #472: unzip 缺失問題復發 — 驗證 new-issue-intake.yml 使用正確的 sudo apt-get 安裝
# 根因：#464 的 sudo -n 修復在無 NOPASSWD 的 runner 上靜默失敗，導致 unzip 仍未安裝
# AC1: workflow 使用 sudo apt-get install -y unzip（不帶 -n flag）
# AC2: 有 unzip 快取時靜默跳過（command -v 守衛，冪等性）
# AC3: 不使用 sudo -n（避免靜默失敗）

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

echo "=== Test #472: unzip regression fix (reverts #464 sudo -n approach) ==="

# AC1: 使用 sudo apt-get install -y unzip（不帶 -n flag）
grep -q "sudo apt-get install -y unzip" "$WORKFLOW"
check "AC1: uses 'sudo apt-get install -y unzip' (without -n)" $?

# AC3: 不使用 sudo -n（#464 回歸根因）
result=0
grep -q "sudo -n apt-get" "$WORKFLOW" && result=1 || true
check "AC3: no 'sudo -n apt-get' (silent failure pattern removed)" $result

# AC3: 不使用 graceful fallback（不再靜默忽略錯誤）
result=0
grep -q "proceeding anyway" "$WORKFLOW" && result=1 || true
check "AC3: no silent fallback 'proceeding anyway' (unzip must succeed)" $result

# AC2: 冪等性守衛仍存在（已有 unzip 時跳過安裝）
grep -q "command -v unzip" "$WORKFLOW"
check "AC2: idempotency guard (command -v unzip) present" $?

# AC1: Install unzip 步驟位於 New Issue Intake step 之前（依賴順序正確）
UNZIP_LINE=$(grep -n "Install unzip" "$WORKFLOW" | grep "name:" | head -1 | cut -d: -f1)
INTAKE_LINE=$(grep -n "New Issue Intake" "$WORKFLOW" | grep "name:" | grep -v "^1:" | head -1 | cut -d: -f1)
result=0
{ [ -z "$UNZIP_LINE" ] || [ -z "$INTAKE_LINE" ] || [ "$UNZIP_LINE" -ge "$INTAKE_LINE" ]; } && result=1 || true
check "AC1: Install unzip step is BEFORE New Issue Intake step" $result

# Structural: busybox.net 未重新引入
result=0
grep -q "busybox.net" "$WORKFLOW" && result=1 || true
check "STRUCTURE: no busybox.net dependency (regression guard)" $result

# Structural: YAML is valid
python3 -c "import yaml; yaml.safe_load(open('$WORKFLOW'))" 2>/dev/null
check "STRUCTURE: YAML syntax valid" $?

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "All tests passed."
