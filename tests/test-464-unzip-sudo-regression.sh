#!/usr/bin/env bash
# Test #464: unzip sudo — 歷史測試，#472 已覆寫 sudo -n 方案
# 注意：#472 發現 sudo -n 在無 NOPASSWD runner 上靜默失敗，已回歸至 sudo apt-get
# 本測試保留核心不變量驗證（冪等性、apt-get 存在、無 busybox）
# sudo -n 相關斷言已廢棄（由 test-472-unzip-regression-fix.sh 替代）

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

echo "=== Test #464: unzip core invariants (sudo -n ACs superseded by #472) ==="

# 核心不變量：使用 apt-get install unzip（#472 已確保不帶 -n）
grep -q "apt-get install -y unzip" "$WORKFLOW"
check "CORE: apt-get install -y unzip present" $?

# 核心不變量：冪等性守衛（command -v unzip）
grep -q "command -v unzip" "$WORKFLOW"
check "CORE: idempotency guard (command -v unzip) present" $?

# 核心不變量：busybox.net 未重新引入
result=0
grep -q "busybox.net" "$WORKFLOW" && result=1 || true
check "CORE: no busybox.net dependency" $result

# Structural: YAML is valid
python3 -c "import yaml; yaml.safe_load(open('$WORKFLOW'))" 2>/dev/null
check "STRUCTURE: YAML syntax valid" $?

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "All tests passed."
