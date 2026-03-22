#!/usr/bin/env bash
# tests/test-cruise-skill.sh
# US-321 Phase 1：Cruise Mode 測試套件
# 覆蓋 AC-1（PO 巡邏）/ AC-2（SRE 巡檢）/ AC-4（介面）/ AC-5（跨機器安全）/ AC-6（測試）

set -uo pipefail

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

assert_file_exists() {
  local path="$1"
  local label="$2"
  if [[ -f "$path" ]]; then
    pass "$label"
  else
    fail "$label (file not found: $path)"
  fi
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

assert_command_output() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  if [[ "$actual" == "$expected" ]]; then
    pass "$label"
  else
    fail "$label (expected='${expected}', actual='${actual}')"
  fi
}

# ---------------------------------------------------------------------------
# 設定路徑
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SKILL_FILE="${REPO_ROOT}/skills/cruise/SKILL.md"
HOOK_FILE="${REPO_ROOT}/hooks/session-end-release.sh"
PROTECT_FILE="${REPO_ROOT}/hooks/protect-main.sh"
ADR_FILE="${REPO_ROOT}/docs/adr/ADR-026-cruise-mode.md"

echo "=== Cruise Skill 測試套件 ==="
echo "REPO_ROOT: $REPO_ROOT"
echo ""

# ---------------------------------------------------------------------------
# TC-1：SKILL.md 存在且 name=cruise
# ---------------------------------------------------------------------------
echo "--- TC-1：SKILL.md 結構驗證 ---"

assert_file_exists "$SKILL_FILE" "TC-1a: skills/cruise/SKILL.md 存在"

if [[ -f "$SKILL_FILE" ]]; then
  SKILL_NAME=$(grep -m1 '^name:' "$SKILL_FILE" 2>/dev/null | sed 's/name:[[:space:]]*//' | tr -d '"' | tr -d "'" | xargs || echo "")
  assert_command_output "cruise" "$SKILL_NAME" "TC-1b: SKILL.md name=cruise"

  assert_contains "$SKILL_FILE" 'description:' "TC-1c: SKILL.md 含 description 欄位"
  assert_contains "$SKILL_FILE" 'requiredTools:' "TC-1d: SKILL.md 含 requiredTools 欄位"
fi

# ---------------------------------------------------------------------------
# TC-2：hooks/session-end-release.sh 含 cruise cleanup
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-2：SessionEnd hook cruise cleanup 驗證 ---"

assert_file_exists "$HOOK_FILE" "TC-2a: session-end-release.sh 存在"

if [[ -f "$HOOK_FILE" ]]; then
  assert_contains "$HOOK_FILE" 'shikigami-cruise' "TC-2b: hook 含 cruise flag 清理邏輯"
  assert_contains "$HOOK_FILE" 'CRUISE_FLAG' "TC-2c: hook 定義 CRUISE_FLAG 變數"
  assert_contains "$HOOK_FILE" 'rm -f.*CRUISE_FLAG|CRUISE_FLAG.*rm' "TC-2d: hook 執行 rm -f CRUISE_FLAG"
fi

# ---------------------------------------------------------------------------
# TC-3：protect-main.sh 豁免清單含 cruise-logs
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-3：protect-main.sh 豁免驗證 ---"

assert_file_exists "$PROTECT_FILE" "TC-3a: protect-main.sh 存在"

if [[ -f "$PROTECT_FILE" ]]; then
  assert_contains "$PROTECT_FILE" 'docs/cruise-logs' "TC-3b: protect-main.sh 豁免含 cruise-logs"
fi

# ---------------------------------------------------------------------------
# TC-4：validate-skills.sh PASS（包含 cruise）
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-4：validate-skills.sh 執行 ---"

VALIDATE_SKILL_SCRIPT="${REPO_ROOT}/scripts/validate-skills.sh"
if [[ -f "$VALIDATE_SKILL_SCRIPT" ]]; then
  VALIDATE_OUTPUT=$(bash "$VALIDATE_SKILL_SCRIPT" 2>&1)
  VALIDATE_EXIT=$?
  if [[ $VALIDATE_EXIT -eq 0 ]]; then
    pass "TC-4a: validate-skills.sh PASS"
  else
    fail "TC-4a: validate-skills.sh FAIL（exit=$VALIDATE_EXIT）"
  fi
  # 確認 cruise 在 skill 清單中
  if echo "$VALIDATE_OUTPUT" | grep -q "cruise"; then
    pass "TC-4b: validate-skills.sh 輸出含 cruise"
  else
    fail "TC-4b: validate-skills.sh 輸出未含 cruise"
  fi
else
  fail "TC-4a: validate-skills.sh 不存在"
fi

# ---------------------------------------------------------------------------
# TC-5：PO 巡邏指引包含必要元素
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-5：PO 巡邏指引驗證 ---"

if [[ -f "$SKILL_FILE" ]]; then
  assert_contains "$SKILL_FILE" 'gh issue list|open issues|open_issues|掃描.*issue|issue.*掃描' "TC-5a: PO 巡邏含 open issues 掃描"
  assert_contains "$SKILL_FILE" '留言|comment|gh issue comment' "TC-5b: PO 巡邏含留言追蹤"
  assert_contains "$SKILL_FILE" '交付|in-sprint|Story 進度|delivery' "TC-5c: PO 巡邏含交付追蹤"
fi

# ---------------------------------------------------------------------------
# TC-6：SRE 巡檢指引包含必要元素
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-6：SRE 巡檢指引驗證 ---"

if [[ -f "$SKILL_FILE" ]]; then
  assert_contains "$SKILL_FILE" 'gh run list|CI/CD|CI_CD|CI 狀態|pipeline' "TC-6a: SRE 巡檢含 CI failure 檢查"
  assert_contains "$SKILL_FILE" 'Runner|runner' "TC-6b: SRE 巡檢含 Runner 健康檢查"
  assert_contains "$SKILL_FILE" 'Warnings|warnings|警告' "TC-6c: SRE 巡檢含 Warnings 掃描"
  assert_contains "$SKILL_FILE" '建 Issue|gh issue create|建立 Issue|create.*issue' "TC-6d: SRE 發現問題時建 Issue"
fi

# ---------------------------------------------------------------------------
# TC-7：per-session log 路徑格式正確
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-7：per-session log 路徑驗證 ---"

if [[ -f "$SKILL_FILE" ]]; then
  assert_contains "$SKILL_FILE" 'docs/cruise-logs' "TC-7a: SKILL.md 含 cruise-logs 目錄路徑"
  assert_contains "$SKILL_FILE" 'SESSION_ID|session_id|session-id' "TC-7b: SKILL.md 含 SESSION_ID 路徑格式"
  assert_contains "$SKILL_FILE" 'jsonl|JSONL' "TC-7c: SKILL.md 使用 JSONL 格式"
fi

# ---------------------------------------------------------------------------
# TC-8：Issue 重複防護邏輯存在
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-8：Issue 重複防護驗證 ---"

if [[ -f "$SKILL_FILE" ]]; then
  assert_contains "$SKILL_FILE" 'gh issue list.*search|--search|重複防護|duplicate.*check|already.*exist' "TC-8a: SKILL.md 含 Issue 重複防護邏輯"
fi

# ---------------------------------------------------------------------------
# TC-9：ADR-026 存在且狀態為 Accepted
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-9：ADR-026 驗證 ---"

assert_file_exists "$ADR_FILE" "TC-9a: ADR-026-cruise-mode.md 存在"

if [[ -f "$ADR_FILE" ]]; then
  assert_contains "$ADR_FILE" 'Accepted|accepted' "TC-9b: ADR-026 狀態為 Accepted"
  assert_contains "$ADR_FILE" 'flag file|flag_file|FLAG_FILE' "TC-9c: ADR-026 決策含 flag file 機制"
  assert_contains "$ADR_FILE" 'per-session|per_session|SESSION_ID' "TC-9d: ADR-026 決策含 per-session log"
fi

# ---------------------------------------------------------------------------
# TC-10：介面定義驗證（/cruise、/cruise 10m、/cruise stop）
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-10：介面定義驗證 ---"

if [[ -f "$SKILL_FILE" ]]; then
  assert_contains "$SKILL_FILE" '/cruise' "TC-10a: SKILL.md 含 /cruise 觸發語法"
  assert_contains "$SKILL_FILE" '/cruise stop|cruise.*stop|stop.*cruise' "TC-10b: SKILL.md 含 /cruise stop"
  assert_contains "$SKILL_FILE" '10m|<interval>|interval|間隔' "TC-10c: SKILL.md 含間隔參數說明"
fi

# ---------------------------------------------------------------------------
# TC-11：strict flag 觸發語法（AC-1）
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-11：strict 觸發語法驗證 ---"

if [[ -f "$SKILL_FILE" ]]; then
  assert_contains "$SKILL_FILE" 'strict' "TC-11a: SKILL.md 觸發語法含 strict"
  assert_contains "$SKILL_FILE" '/cruise strict|cruise.*strict' "TC-11b: SKILL.md 含 /cruise strict 範例"
  assert_contains "$SKILL_FILE" '10m.*strict|strict.*10m' "TC-11c: SKILL.md 含自訂間隔+strict 組合範例"
fi

# ---------------------------------------------------------------------------
# TC-12：THRESHOLD_DAYS 參數化（AC-3）
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-12：THRESHOLD_DAYS 參數化驗證 ---"

if [[ -f "$SKILL_FILE" ]]; then
  assert_contains "$SKILL_FILE" 'THRESHOLD_DAYS' "TC-12a: SKILL.md 含 THRESHOLD_DAYS 變數"
  assert_contains "$SKILL_FILE" 'THRESHOLD_DAYS=3' "TC-12b: SKILL.md 預設 THRESHOLD_DAYS=3"
  assert_contains "$SKILL_FILE" 'THRESHOLD_DAYS=0' "TC-12c: SKILL.md strict 模式 THRESHOLD_DAYS=0"
  assert_contains "$SKILL_FILE" 'THRESHOLD_DAYS.*days_since_comment|days_since_comment.*THRESHOLD_DAYS' "TC-12d: 無回應判斷使用 THRESHOLD_DAYS"
fi

# ---------------------------------------------------------------------------
# TC-13：strict flag 解析 + strict log 格式（AC-2 + AC-4）
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-13：strict flag 解析與 log 格式驗證 ---"

if [[ -f "$SKILL_FILE" ]]; then
  assert_contains "$SKILL_FILE" 'STRICT_MODE' "TC-13a: SKILL.md 含 STRICT_MODE 變數"
  assert_contains "$SKILL_FILE" 'STRICT_MODE=false|STRICT_MODE=true' "TC-13b: SKILL.md 含 STRICT_MODE 初始化"
  assert_contains "$SKILL_FILE" '"strict".*true|strict.*true' "TC-13c: strict 模式 log 格式含 strict 欄位"
fi

# ---------------------------------------------------------------------------
# TC-14：自動行動決策表（AC-1）
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-14：PO 巡邏自動行動決策表驗證 ---"

if [[ -f "$SKILL_FILE" ]]; then
  assert_contains "$SKILL_FILE" '自動行動決策表' "TC-14a: SKILL.md 含「自動行動決策表」子段標題"
  assert_contains "$SKILL_FILE" 'backlog-management|invoke.*backlog|排入.*Backlog|Backlog.*排入' "TC-14b: 決策表含「排入 Backlog」行動（invoke backlog-management）"
  assert_contains "$SKILL_FILE" '直接回覆|reply.*internal|internal.*reply|內部.*Issue.*回覆' "TC-14c: 決策表含「直接回覆」行動（內部 Issue only）"
  assert_contains "$SKILL_FILE" '4.*情境|情境.*4|four.*scenario|scenario.*four' "TC-14d: 決策表列出 4 種情境"
fi

# ---------------------------------------------------------------------------
# TC-15：交付推進自動化（AC-2）
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-15：交付推進自動化驗證 ---"

if [[ -f "$SKILL_FILE" ]]; then
  assert_contains "$SKILL_FILE" 'staging.*E2E|E2E.*staging|交付鏈|delivery.*chain' "TC-15a: SKILL.md 含交付鏈（staging → E2E → tag → production）"
  assert_contains "$SKILL_FILE" 'PR.*merge|merge.*PR|PR.*merged|merged.*PR' "TC-15b: 交付推進判斷 PR merge 狀態"
  assert_contains "$SKILL_FILE" '前置條件|precondition|pre.*condition|CI.*狀態.*推進|推進.*前.*檢查' "TC-15c: 推進前檢查前置條件（避免跳步）"
  assert_contains "$SKILL_FILE" 'push-delivery|交付推進|推進交付' "TC-15d: log actions 含 push-delivery 類型"
fi

# ---------------------------------------------------------------------------
# TC-16：awaiting-reply 超時催促（AC-3）
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-16：awaiting-reply 超時催促驗證 ---"

if [[ -f "$SKILL_FILE" ]]; then
  assert_contains "$SKILL_FILE" 'awaiting-reply' "TC-16a: SKILL.md 含 awaiting-reply 標籤判斷"
  assert_contains "$SKILL_FILE" '24h|每.*24|24.*小時|最多.*1.*次|最多.*催.*次' "TC-16b: 催促頻率上限（每 24h 最多 1 次）"
  assert_contains "$SKILL_FILE" '最後一則留言|last.*comment.*time|已是自動催促|重複催促.*跳過|冪等.*催促' "TC-16c: 冪等性保護（最後留言為自動催促則跳過）"
  assert_contains "$SKILL_FILE" 'nudge|催促' "TC-16d: log actions 含 nudge 類型"
fi

# ---------------------------------------------------------------------------
# TC-17：無 label Issue 自動 Triage（AC-4）
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-17：無 label 自動 Triage 驗證 ---"

if [[ -f "$SKILL_FILE" ]]; then
  assert_contains "$SKILL_FILE" '無.*label.*triage|triage.*無.*label|no.*label.*triage|labels.*empty.*triage' "TC-17a: SKILL.md 含無 label → 觸發 triage 邏輯"
  assert_contains "$SKILL_FILE" 'issue-management.*triage|triage.*issue-management' "TC-17b: 自動觸發 issue-management triage"
  assert_contains "$SKILL_FILE" '已有.*label.*不.*triage|label.*exist.*skip.*triage|triage.*冪等' "TC-17c: 已有 label 不重複 triage（冪等性）"
  assert_contains "$SKILL_FILE" '"triage"' "TC-17d: log actions 含 triage 類型"
fi

# ---------------------------------------------------------------------------
# TC-18：安全邊界 — Stakeholder Issue 不自動行動（AC-5）
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-18：安全邊界驗證 ---"

if [[ -f "$SKILL_FILE" ]]; then
  assert_contains "$SKILL_FILE" '§安全邊界|##.*安全邊界|安全邊界' "TC-18a: SKILL.md 新增安全邊界段落"
  assert_contains "$SKILL_FILE" 'stakeholder.*label|label.*stakeholder' "TC-18b: 安全邊界判斷標準為 stakeholder label"
  assert_contains "$SKILL_FILE" 'stakeholder.*只記錄|只記錄.*stakeholder|skipped.*stakeholder|stakeholder.*不.*行動' "TC-18c: Stakeholder Issue 只記錄不自動行動"
  assert_contains "$SKILL_FILE" '"skipped".*"stakeholder-issue"|skipped.*stakeholder-issue' "TC-18d: log 標注 skipped: stakeholder-issue"
fi

# ---------------------------------------------------------------------------
# TC-19：Cruise log 擴充行動類型（AC-6）
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-19：Cruise log 行動類型擴充驗證 ---"

if [[ -f "$SKILL_FILE" ]]; then
  assert_contains "$SKILL_FILE" '"reply"' "TC-19a: log actions 含 reply 類型"
  assert_contains "$SKILL_FILE" '"triage"' "TC-19b: log actions 含 triage 類型"
  assert_contains "$SKILL_FILE" '"push-delivery"' "TC-19c: log actions 含 push-delivery 類型"
  assert_contains "$SKILL_FILE" '"nudge"' "TC-19d: log actions 含 nudge 類型"
  assert_contains "$SKILL_FILE" '"skipped"' "TC-19e: log actions 含 skipped 類型"
fi

# ---------------------------------------------------------------------------
# TC-20：CI failure → Issue body 含 /systematic-debugging 指引（AC-1 Phase 2）
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-20：SRE CI failure 建 Issue + debugging 指引驗證 ---"

if [[ -f "$SKILL_FILE" ]]; then
  assert_contains "$SKILL_FILE" '/systematic-debugging' "TC-20a: SRE CI failure Issue body 含 /systematic-debugging 指引"
  assert_contains "$SKILL_FILE" 'sre-auto-debug' "TC-20b: SRE CI failure Issue 加上 sre-auto-debug label"
  assert_contains "$SKILL_FILE" '不在.*cruise.*loop.*同步|cruise.*loop.*外|cruise.*輕量|松耦合' "TC-20c: 備注：不在 cruise loop 內同步執行 debugging"
  assert_contains "$SKILL_FILE" 'create-issue-with-debug' "TC-20d: log actions 含 create-issue-with-debug 類型"
fi

# ---------------------------------------------------------------------------
# TC-21：Deploy failure → 建 Issue + 通知 PO（AC-2 Phase 2）
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-21：SRE Deploy failure 建 Issue + 通知 PO 驗證 ---"

if [[ -f "$SKILL_FILE" ]]; then
  assert_contains "$SKILL_FILE" 'Deploy fail|deploy.*fail|deploy.*failure|部署.*失敗' "TC-21a: SKILL.md 含 Deploy failure 情境"
  assert_contains "$SKILL_FILE" '@.*PO|mention.*PO|PO.*mention|@mention.*PO' "TC-21b: Deploy failure Issue body 含 @mention PO"
  assert_contains "$SKILL_FILE" 'deploy-failure' "TC-21c: Deploy failure Issue 加上 deploy-failure label"
  assert_contains "$SKILL_FILE" 'create-issue-deploy' "TC-21d: log actions 含 create-issue-deploy 類型"
fi

# ---------------------------------------------------------------------------
# TC-22：Runner offline → 建 Issue（AC-3 Phase 2）
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-22：SRE Runner offline 建 Issue 驗證 ---"

if [[ -f "$SKILL_FILE" ]]; then
  assert_contains "$SKILL_FILE" 'Runner.*offline|runner.*offline|offline.*runner' "TC-22a: SKILL.md 含 Runner offline 情境"
  assert_contains "$SKILL_FILE" 'runner-offline' "TC-22b: Runner offline Issue 加上 runner-offline label"
  assert_contains "$SKILL_FILE" 'create-issue-runner' "TC-22c: log actions 含 create-issue-runner 類型"
fi

# ---------------------------------------------------------------------------
# TC-23：Cruise log SRE 行動類型擴充（AC-4 Phase 2）
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-23：SRE Cruise log 行動類型擴充驗證 ---"

if [[ -f "$SKILL_FILE" ]]; then
  assert_contains "$SKILL_FILE" '"create-issue-with-debug"' "TC-23a: SRE log actions 含 create-issue-with-debug 類型"
  assert_contains "$SKILL_FILE" '"create-issue-deploy"' "TC-23b: SRE log actions 含 create-issue-deploy 類型"
  assert_contains "$SKILL_FILE" '"create-issue-runner"' "TC-23c: SRE log actions 含 create-issue-runner 類型"
fi

# ---------------------------------------------------------------------------
# TC-24：跨機器冪等性 — 所有新 Issue 類型均有重複防護（AC-5 Phase 2）
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-24：SRE 跨機器冪等性驗證 ---"

if [[ -f "$SKILL_FILE" ]]; then
  assert_contains "$SKILL_FILE" 'deploy.*failure.*search|search.*deploy.*failure|Deploy.*ISSUE_TITLE.*search|EXISTING.*deploy' "TC-24a: Deploy failure Issue 建立前執行 search 重複防護"
  assert_contains "$SKILL_FILE" 'runner.*offline.*search|search.*runner.*offline|Runner.*ISSUE_TITLE.*search|EXISTING.*runner' "TC-24b: Runner offline Issue 建立前執行 search 重複防護"
  assert_contains "$SKILL_FILE" '多.*runner.*同時|同時.*發現.*同一|multi.*runner.*idempotent|冪等.*所有.*Issue.*類型' "TC-24c: 文件說明多 runner 冪等性保障"
fi

# ---------------------------------------------------------------------------
# 結果摘要
# ---------------------------------------------------------------------------
echo ""
echo "=== 測試結果 ==="
echo "PASS: $PASS_COUNT"
echo "FAIL: $FAIL_COUNT"

if [[ $FAIL_COUNT -eq 0 ]]; then
  echo "總結：Cruise Skill 測試全部通過"
  exit 0
else
  echo "總結：發現 $FAIL_COUNT 個 FAIL，請修正後重試"
  exit 1
fi
