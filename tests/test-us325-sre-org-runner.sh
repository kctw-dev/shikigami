#!/usr/bin/env bash
# tests/test-us325-sre-org-runner.sh
# US-#325：SRE 巡檢 org-level runner API 預設
# AC-1：Runner 查詢改為 org-level 優先
# AC-2：org 名稱自動偵測（owner type 判斷）
# AC-3：前置條件提示（admin:org scope）
# AC-4：測試覆蓋

set -uo pipefail

PASS_COUNT=0
FAIL_COUNT=0

pass() {
  echo "PASS: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "FAIL: $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -qE "$pattern" "$file" 2>/dev/null; then
    pass "$label"
  else
    fail "$label (pattern='${pattern}' not found in $file)"
  fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_FILE="${REPO_ROOT}/skills/cruise/SKILL.md"

echo "=== US-#325 SRE org-level Runner API 測試 ==="
echo "SKILL_FILE: $SKILL_FILE"
echo ""

# ---------------------------------------------------------------------------
# TC-325-1：AC-1 — org-level API 呼叫存在
# ---------------------------------------------------------------------------
echo "--- TC-325-1：org-level Runner API 驗證 ---"

assert_contains "$SKILL_FILE" \
  '/orgs/\{org\}/actions/runners|/orgs/\{owner\}/actions/runners|orgs.*actions.*runners' \
  "TC-325-1a: SKILL.md 含 org-level runners API 路徑"

# ---------------------------------------------------------------------------
# TC-325-2：AC-1 — fallback 邏輯存在
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-325-2：fallback repo-level 邏輯驗證 ---"

assert_contains "$SKILL_FILE" \
  'fallback|FALLBACK|fallback.*repo|repo.*fallback' \
  "TC-325-2a: SKILL.md 含 fallback 邏輯"

assert_contains "$SKILL_FILE" \
  '/repos/\{owner\}/\{repo\}/actions/runners|repos.*actions.*runners' \
  "TC-325-2b: SKILL.md 含 repo-level runners API fallback 路徑"

assert_contains "$SKILL_FILE" \
  'org-level API 不可用|org.*fallback.*repo|fallback.*log|fallback 至 repo' \
  "TC-325-2c: SKILL.md fallback 時有 log 提示"

# ---------------------------------------------------------------------------
# TC-325-3：AC-2 — owner type 偵測邏輯
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-325-3：owner type 偵測邏輯驗證 ---"

assert_contains "$SKILL_FILE" \
  'gh repo view.*owner|owner.*json|--json owner' \
  "TC-325-3a: SKILL.md 含從 gh repo view 取得 owner"

assert_contains "$SKILL_FILE" \
  'gh api /orgs/|/orgs/\{owner\}|orgs.*owner.*type|判斷.*org' \
  "TC-325-3b: SKILL.md 含 /orgs/{owner} 判斷 org 類型"

assert_contains "$SKILL_FILE" \
  'User|org.*user|user.*org|owner.*type|ownerType|owner_type' \
  "TC-325-3c: SKILL.md 含 org vs user 判斷"

# ---------------------------------------------------------------------------
# TC-325-4：AC-3 — admin:org scope 前置條件提示
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-325-4：admin:org scope 前置條件驗證 ---"

assert_contains "$SKILL_FILE" \
  'admin:org|admin_org' \
  "TC-325-4a: SKILL.md 含 admin:org scope 提示"

assert_contains "$SKILL_FILE" \
  '403|403.*fallback|fallback.*403|權限不足.*fallback|scope.*403' \
  "TC-325-4b: SKILL.md 含 403 時 fallback 並提示 scope"

# ---------------------------------------------------------------------------
# 結果摘要
# ---------------------------------------------------------------------------
echo ""
echo "=== 測試結果 ==="
echo "PASS: $PASS_COUNT"
echo "FAIL: $FAIL_COUNT"

if [[ $FAIL_COUNT -eq 0 ]]; then
  echo "總結：US-#325 測試全部通過"
  exit 0
else
  echo "總結：發現 $FAIL_COUNT 個 FAIL，請修正後重試"
  exit 1
fi
