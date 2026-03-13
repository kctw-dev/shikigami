#!/usr/bin/env bash
# test-us253-smoke-test-requirement.sh
# US-253 驗收測試：Smoke Test 要求 — 涉及外部資源的 Story 需真實資料驗證
# TDD Red phase — 先寫測試，再實作

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

QA_SKILL="${REPO_ROOT}/skills/qa-engineer/SKILL.md"
LIFECYCLE_PROMPT="${REPO_ROOT}/skills/sprint-execution/story-lifecycle-prompt.md"

pass() {
  echo "[PASS] $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "[FAIL] $1"
  FAIL=$((FAIL + 1))
}

echo "=== US-253 Smoke Test 要求驗收測試 ==="
echo ""

# ── AC1: 識別「涉及外部資源」的 Story 定義清單 ─────────────────────────────

echo "--- AC1: 涉及外部資源的 Story 定義清單 ---"

if grep -q "外部資源" "${QA_SKILL}"; then
  pass "AC1-1: qa-engineer/SKILL.md 含「外部資源」定義"
else
  fail "AC1-1: qa-engineer/SKILL.md 缺少「外部資源」定義"
fi

if grep -q "外部資源" "${LIFECYCLE_PROMPT}"; then
  pass "AC1-2: story-lifecycle-prompt.md 含「外部資源」定義"
else
  fail "AC1-2: story-lifecycle-prompt.md 缺少「外部資源」定義"
fi

# 驗證外部資源類型清單（至少包含 API 和 RSS 兩種）
if grep -q "API\|RSS\|外部 API\|外部服務" "${QA_SKILL}"; then
  pass "AC1-3: qa-engineer/SKILL.md 含外部資源類型範例（API/RSS 等）"
else
  fail "AC1-3: qa-engineer/SKILL.md 缺少外部資源類型範例"
fi

# ── AC2: 此類 Story 要求至少 1 個 smoke test 用真實資料驗證 ─────────────────

echo ""
echo "--- AC2: Smoke Test 真實資料驗證要求 ---"

if grep -q "smoke test\|Smoke Test\|煙霧測試" "${QA_SKILL}"; then
  pass "AC2-1: qa-engineer/SKILL.md 含 smoke test 要求"
else
  fail "AC2-1: qa-engineer/SKILL.md 缺少 smoke test 要求"
fi

if grep -q "smoke test\|Smoke Test\|煙霧測試" "${LIFECYCLE_PROMPT}"; then
  pass "AC2-2: story-lifecycle-prompt.md 含 smoke test 要求"
else
  fail "AC2-2: story-lifecycle-prompt.md 缺少 smoke test 要求"
fi

# 驗證「真實資料」驗證的明確要求
if grep -q "真實資料\|real data\|真實.*驗證\|實際.*驗證" "${QA_SKILL}"; then
  pass "AC2-3: qa-engineer/SKILL.md 明確要求真實資料驗證"
else
  fail "AC2-3: qa-engineer/SKILL.md 缺少真實資料驗證說明"
fi

# ── AC3: Code Review 時檢查是否包含相應的 smoke test ─────────────────────────

echo ""
echo "--- AC3: Code Review 檢查點 ---"

if grep -q "CQ-SMOKE\|smoke.*check\|Smoke.*check\|smoke.*review\|Smoke.*Review" "${QA_SKILL}"; then
  pass "AC3-1: qa-engineer/SKILL.md 含 Code Review smoke test 檢查點"
else
  fail "AC3-1: qa-engineer/SKILL.md 缺少 Code Review smoke test 檢查點"
fi

if grep -q "CQ-SMOKE\|smoke.*check\|Smoke.*check" "${LIFECYCLE_PROMPT}"; then
  pass "AC3-2: story-lifecycle-prompt.md 含 Code Quality 審查的 smoke test 檢查"
else
  fail "AC3-2: story-lifecycle-prompt.md 缺少 Code Quality 審查的 smoke test 檢查"
fi

# ── AC4: 框架文件補充「何時需要 Smoke Test」指引 ─────────────────────────────

echo ""
echo "--- AC4: 框架文件 Smoke Test 指引 ---"

if grep -q "何時需要.*Smoke Test\|When.*Smoke Test\|Smoke Test.*指引\|smoke test.*指引" "${QA_SKILL}"; then
  pass "AC4-1: qa-engineer/SKILL.md 含「何時需要 Smoke Test」指引"
else
  fail "AC4-1: qa-engineer/SKILL.md 缺少「何時需要 Smoke Test」指引"
fi

# 指引應包含觸發條件
if grep -q "觸發條件\|trigger\|識別標準\|判斷標準" "${QA_SKILL}" && grep -q -A5 "smoke\|Smoke" "${QA_SKILL}" | grep -q "觸發\|trigger\|標準\|識別"; then
  pass "AC4-2: qa-engineer/SKILL.md smoke test 指引含觸發條件說明"
else
  fail "AC4-2: qa-engineer/SKILL.md smoke test 指引缺少觸發條件說明"
fi

# ── 最終統計 ─────────────────────────────────────────────────────────────────

echo ""
echo "=== 測試結果 ==="
echo "通過: ${PASS}"
echo "失敗: ${FAIL}"

if [[ ${FAIL} -eq 0 ]]; then
  echo "結論: ALL PASS"
  exit 0
else
  echo "結論: FAIL（${FAIL} 項未通過）"
  exit 1
fi
