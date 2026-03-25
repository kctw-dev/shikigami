#!/usr/bin/env bash
# tests/test-ci-token-rotation.sh
# Story #637 — CI Token 輪換自動化測試
# 驗收標準：
#   AC1: 研究方案已記錄至文件
#   AC2: 替代認證方式已評估
#   AC3: 決策文件已產出
#   AC4: workflow 使用 anthropic_api_key（非 oauth token）

set -euo pipefail

PASS=0
FAIL=0

check() {
  local desc="$1"
  local result="$2"
  if [[ "$result" == "PASS" ]]; then
    echo "  PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "  FAIL: $desc"
    FAIL=$((FAIL+1))
  fi
}

echo "=== test-ci-token-rotation.sh ==="
echo ""

# AC3: 決策文件存在
echo "[AC3] 決策文件存在性檢查"
if [[ -f "docs/km/ci-token-rotation-strategy.md" ]]; then
  check "docs/km/ci-token-rotation-strategy.md 存在" "PASS"
else
  check "docs/km/ci-token-rotation-strategy.md 存在" "FAIL"
fi

# AC3: 決策文件包含必要章節
echo "[AC3] 決策文件內容檢查"
if [[ -f "docs/km/ci-token-rotation-strategy.md" ]]; then
  if grep -q "## 決策" docs/km/ci-token-rotation-strategy.md; then
    check "決策文件包含決策章節" "PASS"
  else
    check "決策文件包含決策章節" "FAIL"
  fi
  if grep -q "ANTHROPIC_API_KEY\|anthropic_api_key" docs/km/ci-token-rotation-strategy.md; then
    check "決策文件評估了 ANTHROPIC_API_KEY 方案" "PASS"
  else
    check "決策文件評估了 ANTHROPIC_API_KEY 方案" "FAIL"
  fi
fi

# AC4 (實作驗證): new-issue-intake.yml 已移除（Sprint 142 #660），跳過 workflow 認證驗證
echo "[AC4] Workflow 認證方式驗證（已跳過：new-issue-intake.yml 已移除）"
echo "  SKIP: new-issue-intake.yml 已於 Sprint 142 移除，AC4 認證驗證不再適用"

echo ""
echo "=== 結果：$PASS PASS, $FAIL FAIL ==="
if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
exit 0
