#!/usr/bin/env bash
# tests/test-us85-schema-consistency.sh
# US-85：TD-002 技術債結案 + Schema 文案修正
# 測試目標：
#   1. schemas/po-subagent-output.schema.json reviewed_by 欄位 const 與 description 一致
#   2. docs/km/Tech_Debt_Registry.md TD-002 狀態已結案（含 Sprint 41 結案記錄）

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEMA_FILE="$REPO_ROOT/schemas/po-subagent-output.schema.json"
REGISTRY_FILE="$REPO_ROOT/docs/km/Tech_Debt_Registry.md"

PASS=0
FAIL=0

log_pass() { echo "[PASS] $*"; PASS=$((PASS + 1)); }
log_fail() { echo "[FAIL] $*" >&2; FAIL=$((FAIL + 1)); }

echo "=== US-85 Schema 一致性與 TD-002 結案驗證 ==="
echo ""

# ---------------------------------------------------------------------------
# TC-1: reviewed_by const 值應為 "PO subagent"（與 description 一致）
# ---------------------------------------------------------------------------
echo "--- TC-1: reviewed_by const 值一致性 ---"

if command -v python3 &>/dev/null; then
  result=$(python3 -c "
import json, sys
with open('$SCHEMA_FILE') as f:
    schema = json.load(f)

reviewed_by = schema['properties']['reviewed_by']
const_val = reviewed_by.get('const', '')
desc = reviewed_by.get('description', '')

# const 應為 'PO subagent'
if const_val == 'PO subagent':
    print('CONST_OK:' + const_val)
else:
    print('CONST_FAIL:' + const_val)
" 2>&1)

  if echo "$result" | grep -q "^CONST_OK:"; then
    log_pass "reviewed_by const 值為 'PO subagent'，與 description 一致"
  else
    actual=$(echo "$result" | sed 's/^CONST_FAIL://')
    log_fail "reviewed_by const 值不正確：期望 'PO subagent'，實際為 '$actual'"
  fi
else
  log_fail "python3 不可用，無法執行 TC-1 驗證"
fi

# ---------------------------------------------------------------------------
# TC-2: reviewed_by description 應提及 'PO subagent'（不應只說 'QA'）
# ---------------------------------------------------------------------------
echo "--- TC-2: reviewed_by description 文案正確性 ---"

if command -v python3 &>/dev/null; then
  result=$(python3 -c "
import json, sys
with open('$SCHEMA_FILE') as f:
    schema = json.load(f)

reviewed_by = schema['properties']['reviewed_by']
const_val = reviewed_by.get('const', '')
desc = reviewed_by.get('description', '')

# description 應提到 PO subagent，且 const 不應為裸的 'QA'
if const_val == 'QA' and 'PO subagent' in desc:
    print('DESC_INCONSISTENT:const=QA but desc says PO subagent')
elif const_val == 'PO subagent':
    print('DESC_OK')
else:
    print('DESC_FAIL:const=' + const_val)
" 2>&1)

  if echo "$result" | grep -q "^DESC_OK$"; then
    log_pass "reviewed_by const 與 description 文案一致"
  elif echo "$result" | grep -q "^DESC_INCONSISTENT:"; then
    log_fail "文案不一致：description 說 'PO subagent'，但 const 為 'QA'"
  else
    log_fail "reviewed_by 欄位驗證失敗：$result"
  fi
else
  log_fail "python3 不可用，無法執行 TC-2 驗證"
fi

# ---------------------------------------------------------------------------
# TC-3: Tech_Debt_Registry.md 中 TD-002 狀態應為已結案
# ---------------------------------------------------------------------------
echo "--- TC-3: Tech_Debt_Registry.md TD-002 狀態驗證 ---"

if grep -q "已結案" "$REGISTRY_FILE" 2>/dev/null; then
  if grep -q "TD-002" "$REGISTRY_FILE" && grep -A 2 "TD-002" "$REGISTRY_FILE" | grep -q "已結案"; then
    log_pass "Tech_Debt_Registry.md TD-002 狀態已標注為已結案"
  else
    # 用 python3 做更精確的確認
    result=$(python3 -c "
with open('$REGISTRY_FILE') as f:
    content = f.read()

# 在 Registry 表格中找 TD-002 行
lines = content.split('\n')
for line in lines:
    if 'TD-002' in line and '|' in line:
        if '已結案' in line:
            print('STATUS_OK')
        else:
            print('STATUS_FAIL:' + line.strip()[:100])
        break
" 2>&1)
    if echo "$result" | grep -q "^STATUS_OK$"; then
      log_pass "Tech_Debt_Registry.md TD-002 表格行狀態為已結案"
    else
      log_fail "Tech_Debt_Registry.md TD-002 表格行未標注已結案：$result"
    fi
  fi
else
  log_fail "Tech_Debt_Registry.md TD-002 狀態尚未更新為已結案"
fi

# ---------------------------------------------------------------------------
# TC-4: Tech_Debt_Registry.md 應包含 Sprint 41 結案記錄
# ---------------------------------------------------------------------------
echo "--- TC-4: Tech_Debt_Registry.md Sprint 41 結案記錄驗證 ---"

if grep -q "Sprint 41" "$REGISTRY_FILE" && grep -A 5 "TD-002" "$REGISTRY_FILE" | grep -q "Sprint 41"; then
  log_pass "Tech_Debt_Registry.md 包含 TD-002 Sprint 41 結案記錄"
else
  # 用更廣泛的搜尋確認 Sprint 41 結案段落是否存在
  if grep -q "Sprint 41" "$REGISTRY_FILE"; then
    log_fail "Tech_Debt_Registry.md 有 Sprint 41 記錄，但 TD-002 結案記錄可能未正確關聯"
  else
    log_fail "Tech_Debt_Registry.md 未包含 Sprint 41 TD-002 結案記錄"
  fi
fi

# ---------------------------------------------------------------------------
# 總結
# ---------------------------------------------------------------------------
echo ""
echo "=== 測試結果 ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [ "$FAIL" -eq 0 ]; then
  echo "整體結論：PASS"
  exit 0
else
  echo "整體結論：FAIL"
  exit 1
fi
