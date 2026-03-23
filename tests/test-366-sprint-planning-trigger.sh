#!/usr/bin/env bash
# tests/test-366-sprint-planning-trigger.sh
# Issue #366 — retro: Sprint Planning 觸發加入測試案例
# 驗證 #352 修正落地：Sprint Planning 觸發已移至 PO 巡邏 Step 5，主 loop 不再負責

set -uo pipefail

# ---------------------------------------------------------------------------
# 測試框架（輕量，與 test-cruise-skill.sh 一致）
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

assert_not_contains_in_section() {
  # 在指定段落（從 START_PATTERN 到 END_PATTERN 之間）確認 TARGET_PATTERN 不存在
  local file="$1"
  local start_pattern="$2"
  local end_pattern="$3"
  local target_pattern="$4"
  local label="$5"
  local section
  section=$(awk "/$start_pattern/{found=1} found; /$end_pattern/ && found>1{exit}" "$file" 2>/dev/null || true)
  if echo "$section" | grep -qE "$target_pattern" 2>/dev/null; then
    fail "$label (pattern='${target_pattern}' 不應出現在此段落)"
  else
    pass "$label"
  fi
}

# ---------------------------------------------------------------------------
# 設定路徑
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_FILE="${REPO_ROOT}/skills/cruise/SKILL.md"

echo "=== #366 Sprint Planning 觸發可靠性測試 ==="
echo "REPO_ROOT: $REPO_ROOT"
echo "SKILL_FILE: $SKILL_FILE"
echo ""

# ---------------------------------------------------------------------------
# TC-32（正向）：Sprint Planning 觸發已移至 PO 巡邏 Step 5
# ---------------------------------------------------------------------------
echo "--- TC-32：PO 巡邏 Step 5 含 Sprint Planning 觸發邏輯 ---"

if [[ ! -f "$SKILL_FILE" ]]; then
  fail "前置：skills/cruise/SKILL.md 存在"
  echo ""
  echo "=== 測試結果 ==="
  echo "PASS: $PASS_COUNT"
  echo "FAIL: $FAIL_COUNT"
  echo "總結：前置條件失敗，無法執行後續測試"
  exit 1
fi

# TC-32a：SKILL.md 含 Step 5 標題（Sprint Planning 觸發在 PO 巡邏 Step 5）
assert_contains "$SKILL_FILE" \
  'Step 5.*Sprint Planning|Sprint Planning.*Step 5' \
  "TC-32a: SKILL.md PO 巡邏含 Step 5 Sprint Planning 觸發"

# TC-32b：SKILL.md 明確說明 #352 移交（主 loop 不再負責觸發）
assert_contains "$SKILL_FILE" \
  '主 loop.*不再.*Sprint Planning|Sprint Planning.*移至.*PO|#352' \
  "TC-32b: SKILL.md 明確說明 Sprint Planning 觸發已由主 loop 移至 PO 巡邏（#352）"

# TC-32c：觸發條件定義完整（count >= 3 OR oldest >= 30min）
assert_contains "$SKILL_FILE" \
  'SPRINT_CANDIDATE_COUNT.*>=.*3|count.*>=.*3.*OR|>=.*3.*OR.*>=.*1' \
  "TC-32c: SKILL.md 含 sprint-candidate count >= 3 觸發條件"

assert_contains "$SKILL_FILE" \
  'OLDEST_CANDIDATE_AGE.*>=.*30|>= 30|30.*分鐘|30min' \
  "TC-32c2: SKILL.md 含 oldest sprint-candidate >= 30min 觸發條件"

# TC-32d：三種 project_level 的觸發行為均已定義
assert_contains "$SKILL_FILE" \
  "PROJECT_LEVEL.*==.*['\"]low['\"]|project_level.*low|low.*sprint-planning" \
  "TC-32d-low: SKILL.md low → 直接 invoke sprint-planning"

assert_contains "$SKILL_FILE" \
  "project_level.*medium.*Sprint Planning.*留言|sprint-planning-notify|留言.*sprint-planning" \
  "TC-32d-medium: SKILL.md medium → 留言通知等使用者確認"

assert_contains "$SKILL_FILE" \
  "project_level.*high.*sprint-planning-marked|sprint-planning-marked.*project_level.*high|high.*只標記" \
  "TC-32d-high: SKILL.md high → 只標記不觸發"

# TC-32e：log action 含 trigger-sprint-planning 類型
assert_contains "$SKILL_FILE" \
  'trigger-sprint-planning' \
  "TC-32e: SKILL.md log actions 含 trigger-sprint-planning 類型"

# TC-32f：sprint-planning-notify log action 存在（medium 路徑可觀察）
assert_contains "$SKILL_FILE" \
  'sprint-planning-notify' \
  "TC-32f: SKILL.md log actions 含 sprint-planning-notify 類型（medium 路徑）"

# TC-32g：sprint-planning-marked log action 存在（high 路徑可觀察）
assert_contains "$SKILL_FILE" \
  'sprint-planning-marked' \
  "TC-32g: SKILL.md log actions 含 sprint-planning-marked 類型（high 路徑）"

# ---------------------------------------------------------------------------
# TC-33（反向）：主 loop 代碼區段不直接觸發 Sprint Planning
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-33（反向）：主 loop 不直接觸發 Sprint Planning ---"

# TC-33a：主 loop 代碼段含 #352 說明（移交說明必須存在）
assert_contains "$SKILL_FILE" \
  'Sprint Planning 觸發已移至 PO 巡邏直接執行|主 loop 不再負責 Sprint Planning 觸發' \
  "TC-33a: 主 loop 含 #352 移交說明（明確宣告不再負責）"

# TC-33b：主 loop 區段內（Auto-shoot 之後）不含「實際執行」invoke sprint-planning
# 說明：#352 注釋中可能出現 sprint-planning 文字（屬於說明），但不應有非注釋的執行指令
# 使用 grep -v 排除注釋行（以 # 開頭或 #── 開頭的行），確認無實際執行呼叫
MAIN_LOOP_SECTION=$(sed -n '/Auto-shoot 連續派遣/,/PO 巡邏指引/p' "$SKILL_FILE" 2>/dev/null || true)
# 去除注釋行後再比對
MAIN_LOOP_NO_COMMENTS=$(echo "$MAIN_LOOP_SECTION" | grep -vE '^\s*#' 2>/dev/null || true)
if echo "$MAIN_LOOP_NO_COMMENTS" | grep -qE 'invoke shikigami:sprint-planning' 2>/dev/null; then
  fail "TC-33b: 主 loop Auto-shoot 段落（排除注釋行）不應含 invoke shikigami:sprint-planning（應在 PO Step 5 執行）"
else
  pass "TC-33b: 主 loop Auto-shoot 段落（排除注釋行）無 invoke shikigami:sprint-planning（#352 確認）"
fi

# TC-33c：PO 巡邏 Step 5 前（Steps 1-4）不含 sprint-planning 觸發
# 截取 PO 巡邏指引到 Step 5 之前的段落
PO_PRE_STEP5=$(sed -n '/PO 巡邏指引/,/Step 5.*Sprint Planning/p' "$SKILL_FILE" 2>/dev/null || true)
if echo "$PO_PRE_STEP5" | grep -qE 'invoke shikigami:sprint-planning' 2>/dev/null; then
  fail "TC-33c: PO 巡邏 Step 1-4 不應含 invoke shikigami:sprint-planning（只應在 Step 5）"
else
  pass "TC-33c: PO 巡邏 Step 1-4 中無 invoke shikigami:sprint-planning（觸發集中於 Step 5）"
fi

# ---------------------------------------------------------------------------
# TC-34：log 範例驗證（SKILL.md 文件示例一致性）
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-34：log 範例含 trigger-sprint-planning 類型 ---"

# TC-34a：單一 repo log 範例含 trigger-sprint-planning
assert_contains "$SKILL_FILE" \
  '"type":"trigger-sprint-planning"' \
  "TC-34a: SKILL.md 單一 repo log 範例含 trigger-sprint-planning 類型"

# TC-34b：行動類型對照表含 trigger-sprint-planning 說明
assert_contains "$SKILL_FILE" \
  '"trigger-sprint-planning".*sprint-candidate|sprint-candidate.*trigger-sprint-planning' \
  "TC-34b: 行動類型對照表含 trigger-sprint-planning 說明"

# ---------------------------------------------------------------------------
# 結果摘要
# ---------------------------------------------------------------------------
echo ""
echo "=== 測試結果 ==="
echo "PASS: $PASS_COUNT"
echo "FAIL: $FAIL_COUNT"

if [[ $FAIL_COUNT -eq 0 ]]; then
  echo "總結：Sprint Planning 觸發可靠性測試全部通過（#366 AC 滿足）"
  exit 0
else
  echo "總結：發現 $FAIL_COUNT 個 FAIL，Sprint Planning 觸發邏輯有遺漏，請修正"
  exit 1
fi
