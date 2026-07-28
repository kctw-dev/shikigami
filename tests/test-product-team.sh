#!/usr/bin/env bash
# tests/test-product-team.sh
# Product Team（三檔變速產品工程團隊）測試套件
#
# 覆蓋：
#   AC1：Skill 與 references 結構完整
#   AC2：product-analyst agent 定義合法
#   AC3：TaskCreated 閘門 — 未標注檔案所有權時擋下
#   AC4：TaskCreated 閘門 — 已標注 / 唯讀類 task 放行
#   AC5：TaskCompleted 閘門 — 無測試證據時擋下
#   AC6：TaskCompleted 閘門 — 有測試證據 / 豁免類放行
#   AC7：TeammateIdle 閘門 — 未完成訊號擋下、阻塞回報放行
#   AC8：基礎設施失敗（空 payload）一律放行，不鎖死團隊
#   AC9：hooks.json 已註冊三個閘門

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# ---------------------------------------------------------------------------
# 測試框架（輕量）
# ---------------------------------------------------------------------------
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

assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  if [ "$actual" -eq "$expected" ]; then
    pass "$label"
  else
    fail "$label (expected exit=${expected}, actual exit=${actual})"
  fi
}

assert_file_exists() {
  local path="$1"
  local label="$2"
  if [ -f "$path" ]; then
    pass "$label"
  else
    fail "$label (檔案不存在：$path)"
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"
  if printf '%s' "$haystack" | grep -q "$needle"; then
    pass "$label"
  else
    fail "$label (未找到：$needle)"
  fi
}

# 執行 hook 並回傳 exit code（payload 由 stdin 餵入）
run_hook() {
  local script="$1"
  local payload="$2"
  printf '%s' "$payload" | bash "$script" >/dev/null 2>&1
  echo $?
}

# ---------------------------------------------------------------------------
# AC1：Skill 與 references 結構完整
# ---------------------------------------------------------------------------
echo "=== AC1：Skill 結構 ==="
assert_file_exists "$REPO_ROOT/skills/product-team/SKILL.md" "AC1-1 SKILL.md 存在"
assert_file_exists "$REPO_ROOT/skills/product-team/references/gear-selection.md" "AC1-2 換檔判定文件存在"
assert_file_exists "$REPO_ROOT/skills/product-team/references/teammate-dispatch.md" "AC1-3 派工範本存在"
assert_file_exists "$REPO_ROOT/skills/product-team/references/isolation-boundary.md" "AC1-4 隔離邊界文件存在"
assert_file_exists "$REPO_ROOT/commands/team.md" "AC1-5 /team command 存在"

SKILL_BODY=$(cat "$REPO_ROOT/skills/product-team/SKILL.md" 2>/dev/null || echo "")
assert_contains "$SKILL_BODY" "name: product-team" "AC1-6 frontmatter name 與目錄名一致"
assert_contains "$SKILL_BODY" "U5" "AC1-7 SKILL.md 含升檔條款 U5"
assert_contains "$SKILL_BODY" "R1" "AC1-8 SKILL.md 含回退條款 R1"

# ---------------------------------------------------------------------------
# AC2：product-analyst agent 定義合法
# ---------------------------------------------------------------------------
echo ""
echo "=== AC2：product-analyst agent ==="
ANALYST="$REPO_ROOT/agents/product-analyst.md"
assert_file_exists "$ANALYST" "AC2-1 agent 檔案存在"
ANALYST_BODY=$(cat "$ANALYST" 2>/dev/null || echo "")
assert_contains "$ANALYST_BODY" "^name: product-analyst" "AC2-2 含 name 欄位"
assert_contains "$ANALYST_BODY" "^model: sonnet" "AC2-3 model 為 sonnet"
assert_contains "$ANALYST_BODY" "待人類 PO 簽核" "AC2-4 產出標注為草稿（不可自行定案）"

# ---------------------------------------------------------------------------
# AC3 + AC4：TaskCreated 閘門
# ---------------------------------------------------------------------------
echo ""
echo "=== AC3/AC4：TaskCreated 檔案所有權閘門 ==="
GATE_CREATED="$REPO_ROOT/hooks/team-task-created-gate.sh"

CODE=$(run_hook "$GATE_CREATED" '{"subject":"實作登入功能","description":"把登入做完"}')
assert_exit_code 2 "$CODE" "AC3-1 未標注檔案所有權 → 擋下"

CODE=$(run_hook "$GATE_CREATED" '{"subject":"實作登入","description":"你擁有的檔案：src/auth/login.ts"}')
assert_exit_code 0 "$CODE" "AC4-1 已標注檔案路徑 → 放行"

CODE=$(run_hook "$GATE_CREATED" '{"subject":"調查登入失敗 root cause","description":"找出原因"}')
assert_exit_code 0 "$CODE" "AC4-2 唯讀調查類 task → 豁免放行"

CODE=$(run_hook "$GATE_CREATED" '{"subject":"review PR 安全性","description":"審查認證流程"}')
assert_exit_code 0 "$CODE" "AC4-3 review 類 task → 豁免放行"

# ---------------------------------------------------------------------------
# AC5 + AC6：TaskCompleted 閘門
# ---------------------------------------------------------------------------
echo ""
echo "=== AC5/AC6：TaskCompleted 測試證據閘門 ==="
GATE_DONE="$REPO_ROOT/hooks/team-task-completed-gate.sh"

CODE=$(run_hook "$GATE_DONE" '{"subject":"實作登入","result":"已經做完了，功能正常"}')
assert_exit_code 2 "$CODE" "AC5-1 無測試證據 → 擋下"

CODE=$(run_hook "$GATE_DONE" '{"subject":"實作登入","result":"完成，tests/auth/login.test.ts 已新增"}')
assert_exit_code 0 "$CODE" "AC6-1 附測試檔路徑 → 放行"

CODE=$(run_hook "$GATE_DONE" '{"subject":"實作登入","result":"完成，12 tests passed"}')
assert_exit_code 0 "$CODE" "AC6-2 附測試結果 → 放行"

CODE=$(run_hook "$GATE_DONE" '{"subject":"修正 README 錯字","result":"改好了"}')
assert_exit_code 0 "$CODE" "AC6-3 純文件類 → 豁免放行"

# ---------------------------------------------------------------------------
# AC7：TeammateIdle 閘門
# ---------------------------------------------------------------------------
echo ""
echo "=== AC7：TeammateIdle 未完成閘門 ==="
GATE_IDLE="$REPO_ROOT/hooks/teammate-idle-gate.sh"

CODE=$(run_hook "$GATE_IDLE" '{"summary":"- [x] AC1 完成\n- [ ] AC2 尚未處理"}')
assert_exit_code 2 "$CODE" "AC7-1 留有未勾選驗收項 → 擋下"

CODE=$(run_hook "$GATE_IDLE" '{"summary":"實作完成，TODO: 錯誤處理待補"}')
assert_exit_code 2 "$CODE" "AC7-2 留有 TODO 標記 → 擋下"

CODE=$(run_hook "$GATE_IDLE" '{"summary":"AC2 驗收 FAILED"}')
assert_exit_code 2 "$CODE" "AC7-3 驗收 FAIL → 擋下"

CODE=$(run_hook "$GATE_IDLE" '{"summary":"無法繼續，阻塞：需要人類確認資料遷移策略"}')
assert_exit_code 0 "$CODE" "AC7-4 已明確回報阻塞 → 放行"

CODE=$(run_hook "$GATE_IDLE" '{"summary":"全部驗收條件通過，測試全過"}')
assert_exit_code 0 "$CODE" "AC7-5 無未完成訊號 → 放行"

# ---------------------------------------------------------------------------
# AC8：基礎設施失敗一律放行（閘門不得鎖死團隊）
# ---------------------------------------------------------------------------
echo ""
echo "=== AC8：基礎設施失敗放行 ==="
for gate in "$GATE_CREATED" "$GATE_DONE" "$GATE_IDLE"; do
  gate_name=$(basename "$gate")
  CODE=$(printf '' | bash "$gate" >/dev/null 2>&1; echo $?)
  assert_exit_code 0 "$CODE" "AC8 空 payload → ${gate_name} 放行"
done

# ---------------------------------------------------------------------------
# AC9：hooks.json 已註冊三個閘門
# ---------------------------------------------------------------------------
echo ""
echo "=== AC9：hooks.json 註冊 ==="
HOOKS_JSON="$REPO_ROOT/hooks/hooks.json"
if command -v jq &>/dev/null; then
  for evt in TaskCreated TaskCompleted TeammateIdle; do
    if jq -e ".hooks.${evt}" "$HOOKS_JSON" >/dev/null 2>&1; then
      pass "AC9 hooks.json 含 ${evt}"
    else
      fail "AC9 hooks.json 缺少 ${evt}"
    fi
  done
  if jq -e . "$HOOKS_JSON" >/dev/null 2>&1; then
    pass "AC9 hooks.json 為合法 JSON"
  else
    fail "AC9 hooks.json JSON 格式錯誤"
  fi
else
  echo "SKIP: jq 未安裝，略過 hooks.json 結構驗證"
fi

# ---------------------------------------------------------------------------
# 總結
# ---------------------------------------------------------------------------
echo ""
echo "==================================="
echo "PASS: $PASS_COUNT   FAIL: $FAIL_COUNT"
echo "==================================="

[ "$FAIL_COUNT" -eq 0 ] || exit 1
exit 0
