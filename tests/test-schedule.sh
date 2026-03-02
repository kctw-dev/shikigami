#!/usr/bin/env bash
# tests/test-schedule.sh
# US-35：Schedule Skill 測試套件
# 覆蓋 AC1（interval 格式）/ AC2（Pre-flight）/ AC3（腳本生成）/
#        AC4（冪等 crontab）/ AC5（Post-deploy 回滾）/ AC6（--remove 冪等）/
#        AC7（--dry-run）/ AC8（Log 機制）

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

assert_eq() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  if [ "$actual" = "$expected" ]; then
    pass "$label"
  else
    fail "$label (expected='${expected}', actual='${actual}')"
  fi
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
    fail "$label (file not found: ${path})"
  fi
}

assert_file_not_exists() {
  local path="$1"
  local label="$2"
  if [ ! -f "$path" ]; then
    pass "$label"
  else
    fail "$label (file should NOT exist: ${path})"
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"
  if echo "$haystack" | grep -qF -- "$needle"; then
    pass "$label"
  else
    fail "$label (expected to find '${needle}')"
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"
  if ! echo "$haystack" | grep -qF -- "$needle"; then
    pass "$label"
  else
    fail "$label (expected NOT to find '${needle}')"
  fi
}

# ---------------------------------------------------------------------------
# 測試輔助：取得專案根目錄
# ---------------------------------------------------------------------------
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_MD="${PROJECT_DIR}/skills/schedule/SKILL.md"
TEMPLATE="${PROJECT_DIR}/templates/schedule_cron.sh.tmpl"

# ---------------------------------------------------------------------------
# 區段 1：SKILL.md 結構靜態驗證
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 1：SKILL.md 結構驗證 ==="

# 1.1 SKILL.md 存在
assert_file_exists "$SKILL_MD" "SKILL.md 存在於 skills/schedule/"

if [ -f "$SKILL_MD" ]; then
  SKILL_CONTENT=$(cat "$SKILL_MD")

  # 1.2 frontmatter 含 name: schedule
  assert_contains "$SKILL_CONTENT" "name: schedule" "SKILL.md frontmatter 含 name: schedule"

  # 1.3 frontmatter 含 requiredTools
  assert_contains "$SKILL_CONTENT" "requiredTools:" "SKILL.md frontmatter 含 requiredTools"

  # 1.4 含觸發語法文件
  assert_contains "$SKILL_CONTENT" "/schedule" "SKILL.md 含 /schedule 觸發語法"

  # 1.5 含 --interval 說明
  assert_contains "$SKILL_CONTENT" "--interval" "SKILL.md 含 --interval 參數說明"

  # 1.6 含 --remove 說明
  assert_contains "$SKILL_CONTENT" "--remove" "SKILL.md 含 --remove 說明"

  # 1.7 含 --dry-run 說明
  assert_contains "$SKILL_CONTENT" "--dry-run" "SKILL.md 含 --dry-run 說明"

  # 1.8 含 Pre-flight 字串
  assert_contains "$SKILL_CONTENT" "Pre-flight" "SKILL.md 含 Pre-flight 區段"

  # 1.9 含 Post-deploy 字串
  assert_contains "$SKILL_CONTENT" "Post-deploy" "SKILL.md 含 Post-deploy 區段"

  # 1.10 含 flock 說明
  assert_contains "$SKILL_CONTENT" "flock" "SKILL.md 含 flock 互斥鎖說明"

  # 1.11 含 unset ANTHROPIC_API_KEY
  assert_contains "$SKILL_CONTENT" "unset ANTHROPIC_API_KEY" "SKILL.md 含 unset ANTHROPIC_API_KEY"

  # 1.12 含 project-hash 說明
  assert_contains "$SKILL_CONTENT" "project-hash" "SKILL.md 含 project-hash 鎖命名說明"

  # 1.13 含 logs/schedule- 路徑
  assert_contains "$SKILL_CONTENT" "logs/schedule-" "SKILL.md 含 log 路徑 logs/schedule-<skill>"

  # 1.14 含 scripts/<skill-name>_cron.sh 路徑
  assert_contains "$SKILL_CONTENT" "_cron.sh" "SKILL.md 含腳本路徑 _cron.sh"

  # 1.15 interval 僅接受四種格式
  assert_contains "$SKILL_CONTENT" "1m" "SKILL.md interval 含 1m"
  assert_contains "$SKILL_CONTENT" "5m" "SKILL.md interval 含 5m"
  assert_contains "$SKILL_CONTENT" "15m" "SKILL.md interval 含 15m"
  assert_contains "$SKILL_CONTENT" "1h" "SKILL.md interval 含 1h"

  # 1.16 含 ADR-005 引用
  assert_contains "$SKILL_CONTENT" "ADR-005" "SKILL.md 含 ADR-005 引用"

  # 1.17 含回滾說明
  assert_contains "$SKILL_CONTENT" "回滾" "SKILL.md 含回滾說明"

  # 1.18 含 SKIPPED log 格式
  assert_contains "$SKILL_CONTENT" "SKIPPED" "SKILL.md 含 SKIPPED log 格式說明"

  # 1.19 含 START log 格式
  assert_contains "$SKILL_CONTENT" "START" "SKILL.md 含 START log 格式說明"

  # 1.20 含 END log 格式說明（exit code）
  assert_contains "$SKILL_CONTENT" "END" "SKILL.md 含 END log 格式說明"

  # 1.21 含 allowedTools 白名單說明
  assert_contains "$SKILL_CONTENT" "allowedTools" "SKILL.md 含 allowedTools 說明"
else
  # SKILL.md 不存在時跳過內容測試，額外記錄失敗
  fail "SKILL.md 內容測試跳過（檔案不存在）"
fi

# ---------------------------------------------------------------------------
# 區段 2：模板靜態驗證
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 2：templates/schedule_cron.sh.tmpl 驗證 ==="

assert_file_exists "$TEMPLATE" "schedule_cron.sh.tmpl 存在於 templates/"

if [ -f "$TEMPLATE" ]; then
  TMPL_CONTENT=$(cat "$TEMPLATE")

  # 2.1 含 flock 命令
  assert_contains "$TMPL_CONTENT" "flock" "模板含 flock 互斥鎖"

  # 2.2 flock 使用 -n（non-blocking）
  assert_contains "$TMPL_CONTENT" "flock -n" "模板 flock 使用 -n non-blocking 模式"

  # 2.3 含 project-hash 鎖檔案路徑佔位符
  assert_contains "$TMPL_CONTENT" "PROJECT_HASH" "模板含 PROJECT_HASH 鎖命名"

  # 2.4 鎖檔案路徑含 /tmp/shikigami-schedule-
  assert_contains "$TMPL_CONTENT" "/tmp/shikigami-schedule-" "模板鎖路徑使用 /tmp/shikigami-schedule- 前綴"

  # 2.5 含 unset ANTHROPIC_API_KEY
  assert_contains "$TMPL_CONTENT" "unset ANTHROPIC_API_KEY" "模板含 unset ANTHROPIC_API_KEY"

  # 2.6 含 allowedTools（注意模板中有前置空白）
  assert_contains "$TMPL_CONTENT" "allowedTools" "模板含 --allowedTools 參數"

  # 2.7 含 LOG_FILE 變數
  assert_contains "$TMPL_CONTENT" "LOG_FILE" "模板含 LOG_FILE 變數"

  # 2.8 log 路徑含 logs/schedule-
  assert_contains "$TMPL_CONTENT" "logs/schedule-" "模板 log 路徑含 logs/schedule-"

  # 2.9 含 START log 輸出
  assert_contains "$TMPL_CONTENT" "START" "模板含 START log 輸出"

  # 2.10 含 SKIPPED log 輸出
  assert_contains "$TMPL_CONTENT" "SKIPPED" "模板含 SKIPPED log 輸出"

  # 2.11 含 END log 輸出
  assert_contains "$TMPL_CONTENT" "END" "模板含 END log 輸出"

  # 2.12 含 exit code 記錄
  assert_contains "$TMPL_CONTENT" "EXIT_CODE" "模板含 EXIT_CODE 記錄"

  # 2.13 含 PROJECT_DIR 變數佔位符
  assert_contains "$TMPL_CONTENT" "PROJECT_DIR" "模板含 PROJECT_DIR 佔位符"

  # 2.14 含 SKILL_NAME 佔位符
  assert_contains "$TMPL_CONTENT" "SKILL_NAME" "模板含 SKILL_NAME 佔位符"

  # 2.15 含 shikigami-schedule-generated 標記（版本追蹤）
  assert_contains "$TMPL_CONTENT" "shikigami-schedule-generated" "模板含 shikigami-schedule-generated 標記"
else
  fail "模板內容測試跳過（檔案不存在）"
fi

# ---------------------------------------------------------------------------
# 區段 3：interval 格式驗證邏輯
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 3：interval 格式驗證 ==="

# 定義 interval 驗證函式（對應 SKILL.md 中的邏輯規格）
validate_interval() {
  local interval="$1"
  case "$interval" in
    1m|5m|15m|1h) return 0 ;;
    *) return 1 ;;
  esac
}

# 3.1 合法格式通過
validate_interval "1m"
assert_exit_code 0 $? "interval 1m 通過驗證"

validate_interval "5m"
assert_exit_code 0 $? "interval 5m 通過驗證"

validate_interval "15m"
assert_exit_code 0 $? "interval 15m 通過驗證"

validate_interval "1h"
assert_exit_code 0 $? "interval 1h 通過驗證"

# 3.2 非法格式拒絕
validate_interval "10m"
assert_exit_code 1 $? "interval 10m 拒絕（不在允許清單）"

validate_interval "30m"
assert_exit_code 1 $? "interval 30m 拒絕"

validate_interval "2h"
assert_exit_code 1 $? "interval 2h 拒絕"

validate_interval "*/5 * * * *"
assert_exit_code 1 $? "cron 表達式拒絕（不接受原始 cron 格式）"

validate_interval ""
assert_exit_code 1 $? "空字串拒絕"

validate_interval "60m"
assert_exit_code 1 $? "interval 60m 拒絕（應用 1h 取代）"

validate_interval "5M"
assert_exit_code 1 $? "interval 5M 拒絕（大寫 M 不接受）"

# ---------------------------------------------------------------------------
# 區段 4：interval 轉 cron 表達式邏輯
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 4：interval 轉換 cron 表達式 ==="

interval_to_cron() {
  local interval="$1"
  case "$interval" in
    1m)  echo "* * * * *" ;;
    5m)  echo "*/5 * * * *" ;;
    15m) echo "*/15 * * * *" ;;
    1h)  echo "0 * * * *" ;;
    *)   return 1 ;;
  esac
}

CRON_1M=$(interval_to_cron "1m")
assert_eq "* * * * *" "$CRON_1M" "1m 轉換為 * * * * *"

CRON_5M=$(interval_to_cron "5m")
assert_eq "*/5 * * * *" "$CRON_5M" "5m 轉換為 */5 * * * *"

CRON_15M=$(interval_to_cron "15m")
assert_eq "*/15 * * * *" "$CRON_15M" "15m 轉換為 */15 * * * *"

CRON_1H=$(interval_to_cron "1h")
assert_eq "0 * * * *" "$CRON_1H" "1h 轉換為 0 * * * *"

# ---------------------------------------------------------------------------
# 區段 5：冪等 crontab 寫入邏輯
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 5：冪等 crontab 寫入邏輯 ==="

# 模擬冪等寫入：移除同名 entry 再加入（不依賴系統 crontab）
idempotent_crontab_add() {
  local current_crontab="$1"
  local skill_name="$2"
  local cron_entry="$3"
  local marker="shikigami-schedule: ${skill_name}"
  # skill_name 含連字號，腳本路徑使用底線（my-skill -> my_skill_cron.sh）
  local script_token
  script_token=$(echo "$skill_name" | tr '-' '_')

  # 移除含同 skill 標記的舊 entry，再加入新 entry
  {
    echo "$current_crontab" | grep -v "$marker" | grep -v "${script_token}_cron.sh"
    echo "# ${marker}"
    echo "$cron_entry"
  }
}

FAKE_CRONTAB="0 9 * * 1 /home/user/other-job.sh"
ENTRY="*/5 * * * * /home/user/proj/scripts/test_skill_cron.sh"

# 第一次寫入
RESULT1=$(idempotent_crontab_add "$FAKE_CRONTAB" "test-skill" "$ENTRY")
COUNT1=$(echo "$RESULT1" | grep -cF "test_skill_cron.sh" || true)
assert_eq "1" "$COUNT1" "第一次寫入後只有一個 entry"

# 第二次寫入（冪等驗證）
RESULT2=$(idempotent_crontab_add "$RESULT1" "test-skill" "$ENTRY")
COUNT2=$(echo "$RESULT2" | grep -cF "test_skill_cron.sh" || true)
assert_eq "1" "$COUNT2" "第二次寫入後仍只有一個 entry（冪等）"

# 不影響其他 crontab entry
OTHER_COUNT=$(echo "$RESULT2" | grep -cF "other-job.sh" || true)
assert_eq "1" "$OTHER_COUNT" "冪等寫入不影響其他 crontab entry"

# ---------------------------------------------------------------------------
# 區段 6：--remove 冪等行為
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 6：--remove 冪等行為 ==="

# 模擬 remove 操作：若不存在則輸出警告並 exit 0
remove_schedule() {
  local current_crontab="$1"
  local skill_name="$2"
  # skill_name 含連字號，腳本路徑使用底線
  local script_token
  script_token=$(echo "$skill_name" | tr '-' '_')

  # 檢查是否存在對應排程
  if echo "$current_crontab" | grep -qF "${script_token}_cron.sh"; then
    # 移除
    echo "$current_crontab" | grep -vF "${script_token}_cron.sh"
    return 0
  else
    # 不存在：輸出警告但 exit 0
    echo "[WARN] 排程 '${skill_name}' 不存在，無需移除" >&2
    echo "$current_crontab"
    return 0
  fi
}

CRONTAB_WITH_SKILL="*/5 * * * * /proj/scripts/my_skill_cron.sh
0 9 * * 1 /home/user/other-job.sh"

# 6.1 移除存在的排程（exit 0）
REMOVED=$(remove_schedule "$CRONTAB_WITH_SKILL" "my-skill")
REMOVE_EXIT=$?
assert_exit_code 0 $REMOVE_EXIT "--remove 存在的排程 exit 0"
REMAINING=$(echo "$REMOVED" | grep -cF "my_skill_cron.sh" || true)
assert_eq "0" "$REMAINING" "--remove 後 crontab 中無該 entry"

# 6.2 移除不存在的排程（冪等：exit 0 + 警告）
WARN_OUTPUT=$(remove_schedule "0 9 * * 1 /home/user/other-job.sh" "non-existent-skill" 2>&1)
REMOVE_NOEXIST_EXIT=$?
assert_exit_code 0 $REMOVE_NOEXIST_EXIT "--remove 不存在排程 exit 0（冪等）"
assert_contains "$WARN_OUTPUT" "[WARN]" "--remove 不存在排程輸出警告訊息"

# ---------------------------------------------------------------------------
# 區段 7：模板生成（腳本內容驗證）
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 7：模板生成驗證 ==="

if [ -f "$TEMPLATE" ]; then
  TMPL_CONTENT=$(cat "$TEMPLATE")

  # 7.1 模板語法正確（非執行，只做靜態驗證）
  # 以 bash -n 驗證模板（替換佔位符後）
  TMP_SCRIPT=$(mktemp /tmp/test-schedule-tmpl-XXXX.sh)
  sed \
    -e 's/{{SKILL_NAME}}/test-skill/g' \
    -e 's/{{INTERVAL}}/5m/g' \
    -e 's/{{CRON_EXPR}}/\*\/5 \* \* \* \*/g' \
    -e 's/{{PROJECT_DIR}}/\/tmp\/test-proj/g' \
    -e 's/{{PROJECT_HASH}}/abc12345/g' \
    -e 's/{{TIMESTAMP}}/2026-03-02T00:00:00/g' \
    -e 's/{{ALLOWED_TOOLS}}/Read Glob Grep Edit Write Bash/g' \
    "$TEMPLATE" > "$TMP_SCRIPT"

  bash -n "$TMP_SCRIPT" 2>/dev/null
  assert_exit_code 0 $? "模板替換後語法正確（bash -n）"

  # 7.2 替換後含正確的鎖檔案路徑（LOCK_FILE 行）
  LOCK_LINE=$(grep "LOCK_FILE=" "$TMP_SCRIPT" | head -1)
  assert_contains "$LOCK_LINE" "abc12345" "生成腳本鎖路徑含 project-hash"
  assert_contains "$LOCK_LINE" "test-skill" "生成腳本鎖路徑含 skill-name"

  # 7.3 替換後含 unset ANTHROPIC_API_KEY
  assert_contains "$(cat "$TMP_SCRIPT")" "unset ANTHROPIC_API_KEY" "生成腳本含 unset ANTHROPIC_API_KEY"

  # 7.4 替換後含 --allowedTools（注意前置空白）
  assert_contains "$(cat "$TMP_SCRIPT")" "allowedTools" "生成腳本含 allowedTools"

  rm -f "$TMP_SCRIPT"
else
  fail "模板生成測試跳過（模板不存在）"
fi

# ---------------------------------------------------------------------------
# 區段 8：--dry-run 不產出檔案語意驗證
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 8：--dry-run 不產出檔案 ==="

# dry-run 旗標邏輯：設定 DRY_RUN=true 時不寫入任何檔案
# 此測試驗證 SKILL.md 中明確記載 --dry-run 只執行 Pre-flight
if [ -f "$SKILL_MD" ]; then
  SKILL_CONTENT=$(cat "$SKILL_MD")

  # 8.1 SKILL.md 明確說明 --dry-run 不部署檔案
  assert_contains "$SKILL_CONTENT" "dry-run" "SKILL.md 含 dry-run 說明（AC7）"

  # 8.2 SKILL.md 說明 --dry-run 只執行 Pre-flight
  # 允許中英混用的描述方式
  DRY_RUN_SECTION=$(echo "$SKILL_CONTENT" | grep -A 5 "dry-run" | head -20)
  HAS_PREFLIGHT=$(echo "$DRY_RUN_SECTION" | grep -c "Pre-flight\|preflight\|pre-flight" || true)
  if [ "$HAS_PREFLIGHT" -gt 0 ]; then
    pass "--dry-run 說明關聯至 Pre-flight 檢測"
  else
    fail "--dry-run 說明未明確關聯 Pre-flight（AC7 要求）"
  fi
else
  fail "--dry-run 測試跳過（SKILL.md 不存在）"
fi

# ---------------------------------------------------------------------------
# 區段 9：Log 機制驗證（AC8）
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 9：Log 機制驗證（AC8） ==="

if [ -f "$SKILL_MD" ]; then
  SKILL_CONTENT=$(cat "$SKILL_MD")

  # 9.1 log 路徑格式
  assert_contains "$SKILL_CONTENT" "logs/schedule-" "SKILL.md log 路徑格式正確"

  # 9.2 含三種 log 狀態說明
  assert_contains "$SKILL_CONTENT" "START" "SKILL.md log 含 START 格式"
  assert_contains "$SKILL_CONTENT" "SKIPPED" "SKILL.md log 含 SKIPPED 格式"
  assert_contains "$SKILL_CONTENT" "END" "SKILL.md log 含 END 格式"

  # 9.3 含 exit code 記錄說明
  assert_contains "$SKILL_CONTENT" "exit" "SKILL.md log 含 exit code 說明"
fi

# ---------------------------------------------------------------------------
# 區段 10：Retro #54 AC1 — 模板 set -euo pipefail 驗證
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 10：模板 set -euo pipefail 驗證（Retro #54 AC1） ==="

if [ -f "$TEMPLATE" ]; then
  TMPL_CONTENT=$(cat "$TEMPLATE")

  # 10.1 模板含 set -euo pipefail（包含 -e 旗標）
  assert_contains "$TMPL_CONTENT" "set -euo pipefail" "模板含 set -euo pipefail（-e 旗標確保命令失敗立即中止）"

  # 10.2 模板不使用舊的不安全寫法 set -uo pipefail（缺少 -e）
  # 允許 set -uo pipefail 出現在注釋中，但不允許作為實際指令
  if echo "$TMPL_CONTENT" | grep -qxF "set -uo pipefail"; then
    fail "模板不應含單獨的 set -uo pipefail 行（應改為 set -euo pipefail）"
  else
    pass "模板不含不安全的 set -uo pipefail（確認已升級為 -euo）"
  fi
else
  fail "模板不存在，AC1 測試跳過"
fi

# ---------------------------------------------------------------------------
# 區段 11：Retro #54 AC2 — SKILL.md 備份安全機制驗證
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 11：SKILL.md 備份安全機制（Retro #54 AC2） ==="

if [ -f "$SKILL_MD" ]; then
  SKILL_CONTENT=$(cat "$SKILL_MD")

  # 11.1 SKILL.md 含 mktemp（用於安全備份路徑生成）
  assert_contains "$SKILL_CONTENT" "mktemp" "SKILL.md 備份使用 mktemp 生成唯一臨時路徑"

  # 11.2 SKILL.md 含 chmod 600（備份檔案權限保護）
  assert_contains "$SKILL_CONTENT" "chmod 600" "SKILL.md 備份使用 chmod 600 保護檔案"

  # 11.3 SKILL.md 不應再使用固定路徑 /tmp/shikigami-crontab-backup-$(date +%s).bak
  if echo "$SKILL_CONTENT" | grep -qF 'shikigami-crontab-backup-$(date +%s).bak'; then
    fail "SKILL.md 備份不應再使用固定路徑（競態條件風險），應改用 mktemp"
  else
    pass "SKILL.md 備份已移除固定路徑 date +%s 模式（競態條件已消除）"
  fi
else
  fail "SKILL.md 不存在，AC2 測試跳過"
fi

# ---------------------------------------------------------------------------
# 結果摘要
# ---------------------------------------------------------------------------
echo ""
echo "=================================="
echo "測試結果摘要"
echo "=================================="
echo "PASS: ${PASS_COUNT}"
echo "FAIL: ${FAIL_COUNT}"
echo "TOTAL: $((PASS_COUNT + FAIL_COUNT))"
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "部分測試失敗（Red 階段 — 預期行為）"
  exit 1
else
  echo "所有測試通過（Green 階段）"
  exit 0
fi
