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
