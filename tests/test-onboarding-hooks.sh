#!/usr/bin/env bash
# test-onboarding-hooks.sh
# Story #692 — 驗證 onboarding 流程說明包含 claim/release hooks 安裝步驟
# AC4: 測試驗證 onboarding 後 hooks 存在且可執行

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL + 1)); }

echo "=== test-onboarding-hooks.sh ==="

# ── AC1: execution-steps.md §2.3 包含 claim-issue.sh 複製步驟 ────────────
EXEC_STEPS="${REPO_ROOT}/skills/onboarding/references/execution-steps.md"

if [[ -f "$EXEC_STEPS" ]]; then
  pass "execution-steps.md 存在"
else
  fail "execution-steps.md 不存在"
fi

if grep -q "claim-issue.sh" "$EXEC_STEPS" 2>/dev/null; then
  pass "execution-steps.md 包含 claim-issue.sh 安裝步驟"
else
  fail "execution-steps.md 缺少 claim-issue.sh 安裝步驟（AC1 未滿足）"
fi

if grep -q "release-issue.sh" "$EXEC_STEPS" 2>/dev/null; then
  pass "execution-steps.md 包含 release-issue.sh 安裝步驟"
else
  fail "execution-steps.md 缺少 release-issue.sh 安裝步驟（AC1 未滿足）"
fi

if grep -q "hooks/" "$EXEC_STEPS" 2>/dev/null; then
  pass "execution-steps.md 包含 hooks/ 目錄安裝指引"
else
  fail "execution-steps.md 缺少 hooks/ 目錄指引（AC1 未滿足）"
fi

# ── AC2: sre-inspection.md 包含 CLAIM-WARN 偵測與 self-heal 步驟 ─────────
SRE_INSP="${REPO_ROOT}/skills/cruise/references/sre-inspection.md"

if [[ -f "$SRE_INSP" ]]; then
  pass "sre-inspection.md 存在"
else
  fail "sre-inspection.md 不存在"
fi

if grep -q "CLAIM-WARN\|claim-warn" "$SRE_INSP" 2>/dev/null; then
  pass "sre-inspection.md 包含 CLAIM-WARN 偵測邏輯（AC2 滿足）"
else
  fail "sre-inspection.md 缺少 CLAIM-WARN 偵測邏輯（AC2 未滿足）"
fi

if grep -q "self-heal\|自動安裝\|claim-issue.sh" "$SRE_INSP" 2>/dev/null; then
  pass "sre-inspection.md 包含 self-heal 安裝邏輯（AC2 滿足）"
else
  fail "sre-inspection.md 缺少 self-heal 邏輯（AC2 未滿足）"
fi

# ── AC3: sre-inspection.md 包含失敗時建 Issue 的邏輯 ────────────────────
if grep -q "SRE.*claim hooks\|claim hooks.*缺失\|\[SRE\] claim" "$SRE_INSP" 2>/dev/null; then
  pass "sre-inspection.md 包含 claim hooks 缺失 Issue 建立（AC3 滿足）"
else
  fail "sre-inspection.md 缺少 claim hooks 缺失 Issue 邏輯（AC3 未滿足）"
fi

# ── AC4: 框架本身 hooks 存在且可執行 ─────────────────────────────────────
CLAIM_HOOK="${REPO_ROOT}/hooks/claim-issue.sh"
RELEASE_HOOK="${REPO_ROOT}/hooks/release-issue.sh"

if [[ -f "$CLAIM_HOOK" ]]; then
  pass "hooks/claim-issue.sh 存在"
else
  fail "hooks/claim-issue.sh 不存在"
fi

if [[ -x "$CLAIM_HOOK" ]]; then
  pass "hooks/claim-issue.sh 可執行"
else
  fail "hooks/claim-issue.sh 不可執行（缺少 +x 權限）"
fi

if [[ -f "$RELEASE_HOOK" ]]; then
  pass "hooks/release-issue.sh 存在"
else
  fail "hooks/release-issue.sh 不存在"
fi

if [[ -x "$RELEASE_HOOK" ]]; then
  pass "hooks/release-issue.sh 可執行"
else
  fail "hooks/release-issue.sh 不可執行（缺少 +x 權限）"
fi

# ── AC4: 模擬 onboarding 後 hooks 複製並驗證可執行性 ─────────────────────
# 建立臨時目錄模擬消費端 repo
TMP_CONSUMER=$(mktemp -d)
trap "rm -rf $TMP_CONSUMER" EXIT

mkdir -p "${TMP_CONSUMER}/hooks"

# 模擬 onboarding 複製動作
cp "${CLAIM_HOOK}" "${TMP_CONSUMER}/hooks/claim-issue.sh"
cp "${RELEASE_HOOK}" "${TMP_CONSUMER}/hooks/release-issue.sh"
chmod +x "${TMP_CONSUMER}/hooks/claim-issue.sh"
chmod +x "${TMP_CONSUMER}/hooks/release-issue.sh"

if [[ -f "${TMP_CONSUMER}/hooks/claim-issue.sh" ]] && \
   [[ -x "${TMP_CONSUMER}/hooks/claim-issue.sh" ]]; then
  pass "onboarding 後消費端 claim-issue.sh 存在且可執行（AC4 滿足）"
else
  fail "onboarding 後消費端 claim-issue.sh 不存在或不可執行（AC4 未滿足）"
fi

if [[ -f "${TMP_CONSUMER}/hooks/release-issue.sh" ]] && \
   [[ -x "${TMP_CONSUMER}/hooks/release-issue.sh" ]]; then
  pass "onboarding 後消費端 release-issue.sh 存在且可執行（AC4 滿足）"
else
  fail "onboarding 後消費端 release-issue.sh 不存在或不可執行（AC4 未滿足）"
fi

# ── 結果 ──────────────────────────────────────────────────────────────────
echo ""
echo "=== 結果：PASS=${PASS} FAIL=${FAIL} ==="
if [[ $FAIL -eq 0 ]]; then
  echo "[OK] 全部通過"
  exit 0
else
  echo "[NG] ${FAIL} 個測試失敗"
  exit 1
fi
