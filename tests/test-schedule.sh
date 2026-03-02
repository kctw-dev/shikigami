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
# 區段 12：Retro #53 — skill name 白名單驗證（AC1 + AC2）
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 12：skill name 白名單驗證（Retro #53） ==="

# 定義 validate_skill_name 函式（對應 SKILL.md §4 規格）
validate_skill_name() {
  local name="$1"
  if [[ ! "$name" =~ ^[a-z0-9][a-z0-9-]{0,63}$ ]]; then
    echo "[FAIL] skill name 不合法：'${name}'"
    echo "[INFO] 允許字元：小寫英文、數字、連字號（不可開頭為連字號，最長 64 字元）"
    return 1
  fi
}

# 12.1 合法 skill name 通過
validate_skill_name "sprint-execution" >/dev/null 2>&1
assert_exit_code 0 $? "skill name 'sprint-execution' 通過驗證（合法）"

validate_skill_name "backlog-management" >/dev/null 2>&1
assert_exit_code 0 $? "skill name 'backlog-management' 通過驗證（合法）"

validate_skill_name "a" >/dev/null 2>&1
assert_exit_code 0 $? "skill name 'a' 通過驗證（單字元合法）"

validate_skill_name "schedule" >/dev/null 2>&1
assert_exit_code 0 $? "skill name 'schedule' 通過驗證（合法）"

validate_skill_name "my-skill-v2" >/dev/null 2>&1
assert_exit_code 0 $? "skill name 'my-skill-v2' 通過驗證（含數字合法）"

# 12.2 特殊字元拒絕
validate_skill_name "my_skill" >/dev/null 2>&1
assert_exit_code 1 $? "skill name 'my_skill' 拒絕（底線為非法字元）"

validate_skill_name "my@skill" >/dev/null 2>&1
assert_exit_code 1 $? "skill name 'my@skill' 拒絕（@ 為非法字元）"

validate_skill_name "my!skill" >/dev/null 2>&1
assert_exit_code 1 $? "skill name 'my!skill' 拒絕（! 為非法字元）"

validate_skill_name "my.skill" >/dev/null 2>&1
assert_exit_code 1 $? "skill name 'my.skill' 拒絕（. 為非法字元）"

validate_skill_name "my*skill" >/dev/null 2>&1
assert_exit_code 1 $? "skill name 'my*skill' 拒絕（* 為非法字元）"

# 12.3 空格拒絕
validate_skill_name "my skill" >/dev/null 2>&1
assert_exit_code 1 $? "skill name 'my skill' 拒絕（空格為非法字元）"

validate_skill_name " " >/dev/null 2>&1
assert_exit_code 1 $? "skill name ' ' 拒絕（單空格不合法）"

validate_skill_name "my-skill name" >/dev/null 2>&1
assert_exit_code 1 $? "skill name 含空格拒絕"

# 12.4 大寫字母拒絕
validate_skill_name "MySkill" >/dev/null 2>&1
assert_exit_code 1 $? "skill name 'MySkill' 拒絕（大寫字母不合法）"

validate_skill_name "SKILL" >/dev/null 2>&1
assert_exit_code 1 $? "skill name 'SKILL' 拒絕（全大寫不合法）"

validate_skill_name "Sprint-Execution" >/dev/null 2>&1
assert_exit_code 1 $? "skill name 'Sprint-Execution' 拒絕（含大寫字母）"

# 12.5 路徑分隔符號拒絕
validate_skill_name "skills/schedule" >/dev/null 2>&1
assert_exit_code 1 $? "skill name 'skills/schedule' 拒絕（路徑分隔符 / 不合法）"

validate_skill_name "../../../etc/passwd" >/dev/null 2>&1
assert_exit_code 1 $? "skill name '../../../etc/passwd' 拒絕（路徑穿越攻擊）"

validate_skill_name "skill\\name" >/dev/null 2>&1
assert_exit_code 1 $? "skill name 含反斜線拒絕（路徑分隔符）"

# 12.6 開頭連字號拒絕
validate_skill_name "-skill" >/dev/null 2>&1
assert_exit_code 1 $? "skill name '-skill' 拒絕（不可以連字號開頭）"

validate_skill_name "--skill" >/dev/null 2>&1
assert_exit_code 1 $? "skill name '--skill' 拒絕（雙連字號開頭不合法）"

# 12.7 空字串拒絕
validate_skill_name "" >/dev/null 2>&1
assert_exit_code 1 $? "skill name 空字串拒絕"

# 12.8 其他非法輸入
validate_skill_name 'skill$name' >/dev/null 2>&1
assert_exit_code 1 $? "skill name 含 \$ 字元拒絕（非法字元）"

validate_skill_name "skill;rm -rf /" >/dev/null 2>&1
assert_exit_code 1 $? "skill name 含分號注入嘗試拒絕"

validate_skill_name "skill name" >/dev/null 2>&1
assert_exit_code 1 $? "skill name 含空格（注入嘗試）拒絕"

# 12.9 錯誤訊息格式驗證
ERROR_OUTPUT=$(validate_skill_name "Invalid-Name" 2>&1)
assert_contains "$ERROR_OUTPUT" "[FAIL]" "非法 skill name 輸出含 [FAIL] 標記"
assert_contains "$ERROR_OUTPUT" "[INFO]" "非法 skill name 輸出含 [INFO] 說明"

# 12.10 SKILL.md §4 Pre-flight 含白名單驗證項目（AC1 靜態驗證）
if [ -f "$SKILL_MD" ]; then
  SKILL_CONTENT=$(cat "$SKILL_MD")

  # 含白名單正則表達式
  assert_contains "$SKILL_CONTENT" "^[a-z0-9][a-z0-9-]{0,63}\$" "SKILL.md Pre-flight 含 skill name 白名單 regex"

  # 含 validate_skill_name 函式定義
  assert_contains "$SKILL_CONTENT" "validate_skill_name" "SKILL.md 含 validate_skill_name 函式"

  # 含白名單驗證的 Pre-flight 說明（阻擋非法輸入）
  assert_contains "$SKILL_CONTENT" "skill name" "SKILL.md Pre-flight 含 skill name 驗證說明"
else
  fail "SKILL.md 不存在，AC1 靜態驗證跳過"
fi

# 12.11 邊界值分析：恰好 64 字元（最大合法長度）應通過
NAME_64=$(printf 'a%.0s' {1..64})
validate_skill_name "$NAME_64" >/dev/null 2>&1
assert_exit_code 0 $? "skill name 恰好 64 字元通過驗證（最大合法長度）"

# 12.12 邊界值分析：恰好 65 字元（最小非法長度）應拒絕
NAME_65=$(printf 'a%.0s' {1..65})
validate_skill_name "$NAME_65" >/dev/null 2>&1
assert_exit_code 1 $? "skill name 恰好 65 字元拒絕（超過最大合法長度 64 字元）"

# ---------------------------------------------------------------------------
# 區段 13：US-36 AC1 — 序列鎖使用說明（SKILL.md）
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 13：US-36 AC1 — 序列鎖使用說明 ==="

ADR_MD="${PROJECT_DIR}/docs/adr/ADR-005-schedule-skill-technical-decisions.md"

if [ -f "$SKILL_MD" ]; then
  SKILL_CONTENT=$(cat "$SKILL_MD")

  # 13.1 SKILL.md 含 --sequential-group 觸發語法
  assert_contains "$SKILL_CONTENT" "--sequential-group" "SKILL.md 含 --sequential-group 觸發語法（AC1）"

  # 13.2 SKILL.md 含序列鎖 group 綁定說明
  assert_contains "$SKILL_CONTENT" "序列鎖" "SKILL.md 含「序列鎖」術語說明（AC1）"

  # 13.3 SKILL.md 含 group 鎖行為描述（同群組內序列執行）
  assert_contains "$SKILL_CONTENT" "sprint-cycle" "SKILL.md 含 sprint-cycle 群組範例（AC1）"

  # 13.4 SKILL.md §2 語法表含 --sequential-group 參數說明
  SYNTAX_SECTION=$(echo "$SKILL_CONTENT" | grep -A 30 "## 2\." | head -35)
  assert_contains "$SYNTAX_SECTION" "sequential-group" "SKILL.md §2 觸發語法含 sequential-group 參數（AC1）"
else
  fail "SKILL.md 不存在，US-36 AC1 測試跳過"
fi

# ---------------------------------------------------------------------------
# 區段 14：US-36 AC2 — 模板 group-level flock 驗證
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 14：US-36 AC2 — 模板 group-level flock 驗證 ==="

if [ -f "$TEMPLATE" ]; then
  TMPL_CONTENT=$(cat "$TEMPLATE")

  # 14.1 模板含 GROUP_LOCK_FILE 變數定義
  assert_contains "$TMPL_CONTENT" "GROUP_LOCK_FILE" "模板含 GROUP_LOCK_FILE 定義（AC2）"

  # 14.2 group 鎖路徑使用 /tmp/shikigami-group- 前綴
  assert_contains "$TMPL_CONTENT" "/tmp/shikigami-group-" "模板 group 鎖路徑使用 /tmp/shikigami-group- 前綴（AC2）"

  # 14.3 模板含 GROUP_NAME 佔位符
  assert_contains "$TMPL_CONTENT" "GROUP_NAME" "模板含 GROUP_NAME 佔位符（AC2）"

  # 14.4 模板含 exec 201 fd（group 鎖 fd）
  assert_contains "$TMPL_CONTENT" "exec 201>" "模板含 exec 201>（group 鎖 file descriptor）（AC2）"

  # 14.5 模板含 flock -n 201（group 鎖嘗試）
  assert_contains "$TMPL_CONTENT" "flock -n 201" "模板含 flock -n 201（group 鎖 non-blocking 嘗試）（AC2）"

  # 14.6 模板含 SKIPPED group 訊息（group 取鎖失敗時）
  assert_contains "$TMPL_CONTENT" "group" "模板 SKIPPED 訊息含 group 資訊（AC2）"

  # 14.7 模板含條件區塊標記 {{#IF_GROUP}} 或 {{/IF_GROUP}}
  assert_contains "$TMPL_CONTENT" "IF_GROUP" "模板含 IF_GROUP 條件區塊標記（AC2）"

  # 14.8 group 鎖在 skill 鎖（exec 200）之前定義
  GROUP_LOCK_POS=$(grep -n "exec 201>" "$TEMPLATE" | head -1 | cut -d: -f1)
  SKILL_LOCK_POS=$(grep -n "exec 200>" "$TEMPLATE" | head -1 | cut -d: -f1)
  if [ -n "$GROUP_LOCK_POS" ] && [ -n "$SKILL_LOCK_POS" ]; then
    if [ "$GROUP_LOCK_POS" -lt "$SKILL_LOCK_POS" ]; then
      pass "group 鎖（exec 201）在 skill 鎖（exec 200）之前（正確順序）（AC2）"
    else
      fail "group 鎖（exec 201）應在 skill 鎖（exec 200）之前（AC2）"
    fi
  else
    fail "模板中找不到 exec 201> 或 exec 200>（AC2）"
  fi
else
  fail "模板不存在，US-36 AC2 測試跳過"
fi

# ---------------------------------------------------------------------------
# 區段 15：US-36 AC3 — Pre-flight group 衝突偵測（SKILL.md §4）
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 15：US-36 AC3 — Pre-flight group 衝突偵測 ==="

if [ -f "$SKILL_MD" ]; then
  SKILL_CONTENT=$(cat "$SKILL_MD")

  # 15.1 SKILL.md §4 Pre-flight 表格含 group 衝突偵測列
  PREFLIGHT_SECTION=$(echo "$SKILL_CONTENT" | grep -A 30 "## 4\." | head -35)
  assert_contains "$PREFLIGHT_SECTION" "group" "SKILL.md §4 Pre-flight 含 group 衝突偵測（AC3）"

  # 15.2 SKILL.md 說明 group 衝突時阻擋部署
  assert_contains "$SKILL_CONTENT" "group 衝突" "SKILL.md 含 group 衝突阻擋說明（AC3）"
else
  fail "SKILL.md 不存在，US-36 AC3 測試跳過"
fi

# ---------------------------------------------------------------------------
# 區段 16：US-36 AC4 — Log 格式含 group 欄位（SKILL.md §10）
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 16：US-36 AC4 — Log 格式 group 欄位 ==="

if [ -f "$SKILL_MD" ]; then
  SKILL_CONTENT=$(cat "$SKILL_MD")

  # 16.1 SKILL.md §10 log 格式範例含 group= 欄位
  LOG_SECTION=$(echo "$SKILL_CONTENT" | grep -A 20 "## 10\." | head -25)
  assert_contains "$LOG_SECTION" "group=" "SKILL.md §10 log 格式含 group= 欄位（AC4）"

  # 16.2 SKILL.md 說明無 group 時記錄 none
  assert_contains "$SKILL_CONTENT" "group=none" "SKILL.md log 含 group=none（無 group 時記錄）（AC4）"
else
  fail "SKILL.md 不存在，US-36 AC4 測試跳過"
fi

# ---------------------------------------------------------------------------
# 區段 17：US-36 AC5 — ADR-005 決策域二新增序列鎖子節
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 17：US-36 AC5 — ADR-005 序列鎖子節 ==="

if [ -f "$ADR_MD" ]; then
  ADR_CONTENT=$(cat "$ADR_MD")

  # 17.1 ADR-005 含「跨 Skill 序列鎖」子節標題
  assert_contains "$ADR_CONTENT" "跨 Skill 序列鎖" "ADR-005 決策域二含「跨 Skill 序列鎖」子節（AC5）"

  # 17.2 ADR-005 含 group lock 路徑格式說明
  assert_contains "$ADR_CONTENT" "shikigami-group-" "ADR-005 含 group lock 路徑格式（AC5）"

  # 17.3 ADR-005 含 GROUP_NAME 說明
  assert_contains "$ADR_CONTENT" "group-name" "ADR-005 含 group-name 命名說明（AC5）"
else
  fail "ADR-005 不存在，US-36 AC5 測試跳過"
fi

# ---------------------------------------------------------------------------
# 區段 18：US-36 AC6 — 回歸驗證（無 --sequential-group 時行為不變）
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 18：US-36 AC6 — 回歸驗證（無 --sequential-group 不破壞現有功能） ==="

if [ -f "$TEMPLATE" ]; then
  # 18.1 模板替換不含 GROUP_NAME 時（無 group 情境），基本功能仍正常
  # 模擬 Sprint 18 情境：不替換 group 相關佔位符，用條件移除後驗證腳本語法
  TMP_REGRESSION=$(mktemp /tmp/test-schedule-regression-XXXX.sh)

  # 取得模板內容，移除 {{#IF_GROUP}} 到 {{/IF_GROUP}} 的區塊（模擬無 group 情境）
  perl -0777 -pe 's/\{\{#IF_GROUP\}\}.*?\{\{\/IF_GROUP\}\}\n?//gs' "$TEMPLATE" > "$TMP_REGRESSION" 2>/dev/null || \
    sed '/{{#IF_GROUP}}/,/{{\/IF_GROUP}}/d' "$TEMPLATE" > "$TMP_REGRESSION"

  # 替換剩餘佔位符
  sed -i \
    -e 's/{{SKILL_NAME}}/sprint-execution/g' \
    -e 's/{{INTERVAL}}/1h/g' \
    -e 's/{{CRON_EXPR}}/0 \* \* \* \*/g' \
    -e 's/{{PROJECT_DIR}}/\/tmp\/test-proj/g' \
    -e 's/{{PROJECT_HASH}}/abc12345/g' \
    -e 's/{{TIMESTAMP}}/2026-03-02T00:00:00/g' \
    -e 's/{{ALLOWED_TOOLS}}/Read Glob Grep Edit Write Bash/g' \
    "$TMP_REGRESSION"

  bash -n "$TMP_REGRESSION" 2>/dev/null
  assert_exit_code 0 $? "AC6 回歸：無 --sequential-group 時腳本語法正確（bash -n）"

  # 18.2 回歸腳本不含 GROUP_LOCK_FILE（無 group 時不應有 group 鎖）
  REGRESSION_CONTENT=$(cat "$TMP_REGRESSION")
  assert_not_contains "$REGRESSION_CONTENT" "GROUP_LOCK_FILE" "AC6 回歸：無 --sequential-group 腳本不含 GROUP_LOCK_FILE"

  # 18.3 回歸腳本仍含 skill 級 flock（exec 200）
  assert_contains "$REGRESSION_CONTENT" "exec 200>" "AC6 回歸：無 --sequential-group 腳本仍含 skill 級 flock（exec 200）"

  # 18.4 回歸腳本仍含 unset ANTHROPIC_API_KEY
  assert_contains "$REGRESSION_CONTENT" "unset ANTHROPIC_API_KEY" "AC6 回歸：無 --sequential-group 腳本仍含 unset ANTHROPIC_API_KEY"

  rm -f "$TMP_REGRESSION"
else
  fail "模板不存在，AC6 回歸測試跳過"
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
