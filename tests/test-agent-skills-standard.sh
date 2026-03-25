#!/usr/bin/env bash
# test-agent-skills-standard.sh — #396 research: Agent Skills 開放標準對齊評估
# Tests:
#   1. Gap Analysis 文件存在
#   2. 包含三類分析（直接相容、需調整、框架特化）
#   3. 包含 PoC 評估結論
#   4. 包含三個遷移策略選項

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

GAP_DOC="docs/research/agent-skills-standard-gap-analysis.md"

echo "=== Agent Skills Standard Gap Analysis Tests ==="

# Test 1: Gap Analysis 文件存在（AC1）
if [[ -f "$GAP_DOC" ]]; then
  pass "Gap Analysis 文件存在（AC1）"
else
  fail "Gap Analysis 文件不存在：${GAP_DOC}"
fi

# Test 2: 包含直接相容分析
if grep -q "直接相容" "$GAP_DOC" 2>/dev/null; then
  pass "文件包含「直接相容」分析（AC1 對照表）"
else
  fail "文件缺少「直接相容」分析"
fi

# Test 3: 包含需調整分析
if grep -q "需要小幅調整\|需要.*調整" "$GAP_DOC" 2>/dev/null; then
  pass "文件包含「需調整」分析（AC1 對照表）"
else
  fail "文件缺少「需調整」分析"
fi

# Test 4: 包含框架特化分析
if grep -q "框架特化" "$GAP_DOC" 2>/dev/null; then
  pass "文件包含「框架特化需求」分析（AC1 對照表）"
else
  fail "文件缺少「框架特化需求」分析"
fi

# Test 5: 包含 Developer PoC 評估（AC2）
if grep -q "Developer.*PoC\|PoC.*Developer" "$GAP_DOC" 2>/dev/null; then
  pass "文件包含 Developer PoC 遷移評估（AC2）"
else
  fail "文件缺少 Developer PoC 評估"
fi

# Test 6: 包含決策建議（AC3）
if grep -q "決策建議\|遷移策略" "$GAP_DOC" 2>/dev/null; then
  pass "文件包含決策建議與遷移策略（AC3）"
else
  fail "文件缺少決策建議"
fi

# Test 7: 包含三個策略選項（AC3：全量遷移/部分對齊/維持現狀）
if grep -q "全量遷移" "$GAP_DOC" 2>/dev/null && grep -q "部分對齊" "$GAP_DOC" 2>/dev/null && grep -q "維持現狀" "$GAP_DOC" 2>/dev/null; then
  pass "文件包含三個遷移策略選項（AC3）"
else
  fail "文件缺少完整三個遷移策略選項"
fi

# Test 8: 回歸測試 — 直接相關測試通過（doc-only RESEARCH，只跑 validate-version + shoot）
# 說明：此 Story 為 doc-only RESEARCH，只新增 docs/research/ 文件，不修改 Skill/Agent 程式碼
# 因此只需確認與文件相關的核心驗證腳本通過（非全量 tests/）
REGRESSION_PASS=0
REGRESSION_FAIL=0

# 版號一致性（不應被 doc-only 修改影響）
if bash scripts/validate-version.sh > /dev/null 2>&1; then
  ((REGRESSION_PASS++))
else
  ((REGRESSION_FAIL++))
  echo "  [WARN] validate-version.sh 失敗"
fi

# JSON 格式驗證（不應被 doc 修改影響）
if bash scripts/validate-json.sh > /dev/null 2>&1; then
  ((REGRESSION_PASS++))
else
  ((REGRESSION_FAIL++))
  echo "  [WARN] validate-json.sh 失敗"
fi

if [[ $REGRESSION_FAIL -eq 0 ]]; then
  pass "核心驗證腳本通過（版號一致性 + JSON 格式），doc-only 無回歸（AC2）"
else
  fail "核心驗證腳本失敗（${REGRESSION_FAIL} 個）"
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
