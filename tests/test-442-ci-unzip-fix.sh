#!/usr/bin/env bash
# Test #442: CI unzip fix — 驗證 new-issue-intake.yml 中的 unzip 安裝步驟
# AC1: 使用 apt-get 安裝 unzip，不依賴 busybox.net
# AC2: 安裝步驟具冪等性（已有 unzip 時不報錯）
# AC3: 移除所有 busybox.net 外部網路依賴

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

echo "=== Test #442: CI unzip fix ==="

# AC1: workflow 使用 apt-get install unzip
grep -q "apt-get install -y unzip" "$WORKFLOW"
check "AC1: uses apt-get install -y unzip" $?

# AC1: busybox.net 已移除
! grep -q "busybox.net" "$WORKFLOW"
check "AC1: busybox.net removed (no external net dependency)" $?

# AC2: 冪等性 — 使用 command -v unzip 守衛
grep -q "command -v unzip" "$WORKFLOW"
check "AC2: idempotency guard (command -v unzip)" $?

# AC3: 無 curl 下載 busybox
! grep -q "curl.*busybox" "$WORKFLOW"
check "AC3: no curl busybox download" $?

# Structural: YAML is valid
python3 -c "import yaml; yaml.safe_load(open('$WORKFLOW'))" 2>/dev/null
check "STRUCTURE: YAML syntax valid" $?

# Structural: step name updated (no longer says 'no sudo')
! grep -q "Install unzip (no sudo)" "$WORKFLOW"
check "STRUCTURE: step name updated (removed 'no sudo' label)" $?

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "All tests passed."
