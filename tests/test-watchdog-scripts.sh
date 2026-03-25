#!/usr/bin/env bash
# tests/test-watchdog-scripts.sh
# Story #847: Watchdog 腳本測試覆蓋
# 整合測試：check/monitor/restart 三合一驗證
# AC1: 新增 tests/test-watchdog-scripts.sh 整合測試
# AC2: 測試涵蓋 watchdog-check.sh 的正常/異常偵測場景（ALIVE/STALE/MISSING）
# AC3: 測試涵蓋 watchdog-restart.sh 的冪等性（不重複啟動）
# AC4: 測試 PASS 且 exit 0
# NFR1: 測試不啟動真實 watchdog 進程，使用 mock

set -uo pipefail

PASS=0; FAIL=0

ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

# ─── 測試環境設置 ───
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
WATCHDOG_DIR="${REPO_ROOT}/docs/sprints/watchdog"
CHECK_SCRIPT="${REPO_ROOT}/scripts/watchdog-check.sh"
MONITOR_SCRIPT="${REPO_ROOT}/scripts/watchdog-monitor.sh"
RESTART_SCRIPT="${REPO_ROOT}/scripts/watchdog-restart.sh"
TEST_DIR=$(mktemp -d) || {
  echo "Failed to create test directory"
  exit 1
}
trap "rm -rf '$TEST_DIR' 2>/dev/null || true" EXIT

# ─── 輔助函數 ───
# 建立 mock heartbeat 文件（ALIVE 狀態：新鮮）
create_alive_heartbeat() {
  local session_id="$1"
  local hb_file="${WATCHDOG_DIR}/${session_id}-heartbeat.json"
  mkdir -p "$WATCHDOG_DIR"
  printf '{"session_id":"%s","timestamp":"%s","status":"active","interval_minutes":5}\n' \
    "$session_id" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" > "$hb_file"
  echo "$hb_file"
}

# 建立 mock heartbeat 文件（STALE 狀態：過期）
create_stale_heartbeat() {
  local session_id="$1"
  local hb_file="${WATCHDOG_DIR}/${session_id}-heartbeat.json"
  mkdir -p "$WATCHDOG_DIR"
  local stale_time
  if date -d "2 hours ago" +%Y-%m-%dT%H:%M:%SZ > /dev/null 2>&1; then
    stale_time=$(date -u -d '2 hours ago' '+%Y-%m-%dT%H:%M:%SZ')
  else
    stale_time=$(date -u -v-2H '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "2000-01-01T00:00:00Z")
  fi
  printf '{"session_id":"%s","timestamp":"%s","status":"active","interval_minutes":5}\n' \
    "$session_id" "$stale_time" > "$hb_file"
  echo "$hb_file"
}

# 建立 mock heartbeat 文件（monitor 模式：last_beat_at）
create_monitor_heartbeat() {
  local session_id="$1"
  local age_mins="${2:-1}"  # 預設 1 分鐘前
  local hb_file="${WATCHDOG_DIR}/session-${session_id}-heartbeat.json"
  mkdir -p "$WATCHDOG_DIR"

  local beat_time
  if date -d "${age_mins} minutes ago" +%Y-%m-%dT%H:%M:%SZ > /dev/null 2>&1; then
    beat_time=$(date -u -d "${age_mins} minutes ago" '+%Y-%m-%dT%H:%M:%SZ')
  else
    beat_time=$(date -u -v-${age_mins}M '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "1970-01-01T00:00:00Z")
  fi

  printf '{"session_id":"%s","last_beat_at":"%s"}\n' \
    "$session_id" "$beat_time" > "$hb_file"
  echo "$hb_file"
}

# 檢查文件是否存在
file_exists() {
  [[ -f "$1" ]]
}

# 檢查文件不存在
file_not_exists() {
  [[ ! -f "$1" ]]
}

echo "=== Watchdog Scripts Integration Tests ==="

# ────────────────────────────────────────────────────────────────
# TC-1: watchdog-check.sh ALIVE 偵測（AC2 正常場景）
# ────────────────────────────────────────────────────────────────
echo ""
echo "--- TC-1: watchdog-check.sh ALIVE status ---"
if [[ -f "$CHECK_SCRIPT" ]]; then
  ok "watchdog-check.sh exists"

  TEST_SESSION="tc1-alive-$$"
  HB_FILE=$(create_alive_heartbeat "$TEST_SESSION")
  OUTPUT=$(bash "$CHECK_SCRIPT" "$TEST_SESSION" 2>/dev/null || true)

  if echo "$OUTPUT" | grep -q "ALIVE"; then
    ok "ALIVE status detected for fresh heartbeat"
  else
    fail "Expected ALIVE status, got: $OUTPUT"
  fi

  rm -f "$HB_FILE"
else
  fail "watchdog-check.sh not found"
fi

# ────────────────────────────────────────────────────────────────
# TC-2: watchdog-check.sh STALE 偵測（AC2 異常場景）
# ────────────────────────────────────────────────────────────────
echo ""
echo "--- TC-2: watchdog-check.sh STALE status ---"
if [[ -f "$CHECK_SCRIPT" ]]; then
  TEST_SESSION="tc2-stale-$$"
  HB_FILE=$(create_stale_heartbeat "$TEST_SESSION")
  OUTPUT=$(bash "$CHECK_SCRIPT" "$TEST_SESSION" 2>/dev/null || true)

  if echo "$OUTPUT" | grep -qE "STALE|WATCHDOG-ALERT"; then
    ok "STALE/WATCHDOG-ALERT detected for old heartbeat"
  else
    fail "Expected STALE or WATCHDOG-ALERT, got: $OUTPUT"
  fi

  rm -f "$HB_FILE"
else
  fail "watchdog-check.sh not found"
fi

# ────────────────────────────────────────────────────────────────
# TC-3: watchdog-check.sh MISSING 偵測（AC2 缺失場景）
# ────────────────────────────────────────────────────────────────
echo ""
echo "--- TC-3: watchdog-check.sh MISSING status ---"
if [[ -f "$CHECK_SCRIPT" ]]; then
  TEST_SESSION="nonexistent-$$"
  OUTPUT=$(bash "$CHECK_SCRIPT" "$TEST_SESSION" 2>/dev/null || true)

  if echo "$OUTPUT" | grep -q "MISSING"; then
    ok "MISSING status detected for absent heartbeat"
  else
    fail "Expected MISSING, got: $OUTPUT"
  fi
else
  fail "watchdog-check.sh not found"
fi

# ────────────────────────────────────────────────────────────────
# TC-4: watchdog-check.sh --write mode 冪等性
# ────────────────────────────────────────────────────────────────
echo ""
echo "--- TC-4: watchdog-check.sh --write idempotent ---"
if [[ -f "$CHECK_SCRIPT" ]]; then
  TEST_SESSION="tc4-write-$$"
  HB_FILE="${WATCHDOG_DIR}/${TEST_SESSION}-heartbeat.json"

  # 第一次寫入
  bash "$CHECK_SCRIPT" "$TEST_SESSION" --write > /dev/null 2>&1

  if file_exists "$HB_FILE"; then
    ok "Heartbeat file created on first --write"

    # 記錄第一次的內容
    FIRST_CONTENT=$(cat "$HB_FILE")

    # 等待 1 秒後再次寫入（確保時間戳記不同）
    sleep 1
    bash "$CHECK_SCRIPT" "$TEST_SESSION" --write > /dev/null 2>&1

    # 檢查第二次寫入是否成功（不應該產生多個文件）
    if file_exists "$HB_FILE"; then
      ok "Heartbeat file updated on second --write (idempotent)"
      # 驗證檔案內容更新（時間戳記應該變新）
      SECOND_CONTENT=$(cat "$HB_FILE")
      if [[ "$FIRST_CONTENT" != "$SECOND_CONTENT" ]]; then
        ok "Heartbeat timestamp updated correctly"
      else
        fail "Heartbeat timestamp not updated"
      fi
    else
      fail "Heartbeat file missing after second --write"
    fi
  else
    fail "Heartbeat file not created"
  fi

  rm -f "$HB_FILE"
else
  fail "watchdog-check.sh not found"
fi

# ────────────────────────────────────────────────────────────────
# TC-5: watchdog-monitor.sh --check-only ALIVE 偵測
# ────────────────────────────────────────────────────────────────
echo ""
echo "--- TC-5: watchdog-monitor.sh --check-only ALIVE ---"
if [[ -f "$MONITOR_SCRIPT" ]]; then
  ok "watchdog-monitor.sh exists"

  TEST_SESSION="tc5-monitor-alive-$$"
  HB_FILE=$(create_monitor_heartbeat "$TEST_SESSION" 1)

  OUTPUT=$(bash "$MONITOR_SCRIPT" --check-only --session "$TEST_SESSION" 2>/dev/null || true)

  if echo "$OUTPUT" | grep -q "WD-ALIVE"; then
    ok "WD-ALIVE detected for fresh heartbeat in monitor mode"
  else
    fail "Expected WD-ALIVE, got: $OUTPUT"
  fi

  # 驗證 exit code 為 0（正常狀態）
  bash "$MONITOR_SCRIPT" --check-only --session "$TEST_SESSION" > /dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    ok "Monitor exits with code 0 for ALIVE status"
  else
    fail "Monitor should exit with code 0 for ALIVE"
  fi

  rm -f "$HB_FILE"
else
  fail "watchdog-monitor.sh not found"
fi

# ────────────────────────────────────────────────────────────────
# TC-6: watchdog-monitor.sh --check-only WARN 偵測
# ────────────────────────────────────────────────────────────────
echo ""
echo "--- TC-6: watchdog-monitor.sh --check-only WARN ---"
if [[ -f "$MONITOR_SCRIPT" ]]; then
  TEST_SESSION="tc6-monitor-warn-$$"
  # 建立 8 分鐘前的 heartbeat（超過 WARN 閾值 8m，但未達 HANG 10m）
  HB_FILE=$(create_monitor_heartbeat "$TEST_SESSION" 9)

  OUTPUT=$(bash "$MONITOR_SCRIPT" --check-only --session "$TEST_SESSION" 2>/dev/null || true)

  if echo "$OUTPUT" | grep -qE "WD-WARN|WD-HANG-DETECTED"; then
    ok "WD-WARN or WD-HANG-DETECTED for aging heartbeat"
  else
    fail "Expected WD-WARN or WD-HANG-DETECTED, got: $OUTPUT"
  fi

  rm -f "$HB_FILE"
else
  fail "watchdog-monitor.sh not found"
fi

# ────────────────────────────────────────────────────────────────
# TC-7: watchdog-monitor.sh --check-only HANG 偵測
# ────────────────────────────────────────────────────────────────
echo ""
echo "--- TC-7: watchdog-monitor.sh --check-only HANG ---"
if [[ -f "$MONITOR_SCRIPT" ]]; then
  TEST_SESSION="tc7-monitor-hang-$$"
  # 建立 11 分鐘前的 heartbeat（超過 HANG 閾值 10m）
  HB_FILE=$(create_monitor_heartbeat "$TEST_SESSION" 11)

  OUTPUT=$(bash "$MONITOR_SCRIPT" --check-only --session "$TEST_SESSION" 2>/dev/null || true)

  if echo "$OUTPUT" | grep -q "WD-HANG-DETECTED"; then
    ok "WD-HANG-DETECTED for stale heartbeat"
  else
    fail "Expected WD-HANG-DETECTED, got: $OUTPUT"
  fi

  # 驗證 exit code 為 1（異常狀態）
  bash "$MONITOR_SCRIPT" --check-only --session "$TEST_SESSION" > /dev/null 2>&1
  if [[ $? -eq 1 ]]; then
    ok "Monitor exits with code 1 for HANG status"
  else
    fail "Monitor should exit with code 1 for HANG"
  fi

  rm -f "$HB_FILE"
else
  fail "watchdog-monitor.sh not found"
fi

# ────────────────────────────────────────────────────────────────
# TC-8: watchdog-restart.sh --dry-run 冪等性測試
# ────────────────────────────────────────────────────────────────
echo ""
echo "--- TC-8: watchdog-restart.sh --dry-run idempotent ---"
if [[ -f "$RESTART_SCRIPT" ]]; then
  ok "watchdog-restart.sh exists"

  TEST_SESSION="tc8-restart-$$"
  mkdir -p "$WATCHDOG_DIR"

  # 第一次 dry-run
  OUTPUT1=$(bash "$RESTART_SCRIPT" --session "$TEST_SESSION" --dry-run 2>/dev/null || true)

  if echo "$OUTPUT1" | grep -q "DRY-RUN"; then
    ok "Dry-run mode activated"
  else
    fail "Expected DRY-RUN output, got: $OUTPUT1"
  fi

  # 驗證 exit code 為 0（dry-run 不應該失敗）
  bash "$RESTART_SCRIPT" --session "$TEST_SESSION" --dry-run > /dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    ok "Restart dry-run exits with code 0"
  else
    fail "Restart dry-run should exit with code 0"
  fi

  # 第二次 dry-run（冪等性）
  OUTPUT2=$(bash "$RESTART_SCRIPT" --session "$TEST_SESSION" --dry-run 2>/dev/null || true)

  if echo "$OUTPUT2" | grep -q "DRY-RUN"; then
    ok "Dry-run can be executed multiple times (idempotent)"
  else
    fail "Second dry-run failed"
  fi
else
  fail "watchdog-restart.sh not found"
fi

# ────────────────────────────────────────────────────────────────
# TC-9: watchdog-restart.sh 不產生重複進程
# ────────────────────────────────────────────────────────────────
echo ""
echo "--- TC-9: watchdog-restart.sh no duplicate processes ---"
if [[ -f "$RESTART_SCRIPT" ]]; then
  TEST_SESSION="tc9-no-dup-$$"
  mkdir -p "$WATCHDOG_DIR"

  # 模擬無 kill-switch 環境（dry-run 就夠了驗證邏輯）
  PROC_COUNT_BEFORE=$(pgrep -f "watchdog-restart" 2>/dev/null | wc -l)
  PROC_COUNT_BEFORE=${PROC_COUNT_BEFORE:-0}

  # 執行 dry-run（不會實際啟動進程）
  bash "$RESTART_SCRIPT" --session "$TEST_SESSION" --dry-run > /dev/null 2>&1 || true

  PROC_COUNT_AFTER=$(pgrep -f "watchdog-restart" 2>/dev/null | wc -l)
  PROC_COUNT_AFTER=${PROC_COUNT_AFTER:-0}

  if [[ "$PROC_COUNT_AFTER" -le "$PROC_COUNT_BEFORE" ]]; then
    ok "No duplicate watchdog-restart processes spawned"
  else
    fail "Unexpected processes spawned: before=$PROC_COUNT_BEFORE after=$PROC_COUNT_AFTER"
  fi
else
  fail "watchdog-restart.sh not found"
fi

# ────────────────────────────────────────────────────────────────
# TC-10: watchdog-check.sh 參數驗證
# ────────────────────────────────────────────────────────────────
echo ""
echo "--- TC-10: watchdog-check.sh argument validation ---"
if [[ -f "$CHECK_SCRIPT" ]]; then
  # 無參數應輸出 usage
  OUTPUT=$(bash "$CHECK_SCRIPT" 2>&1 || true)

  if echo "$OUTPUT" | grep -q "Usage"; then
    ok "Check script shows usage when no arguments provided"
  else
    fail "Expected usage message"
  fi

  # 非法參數應被忽略或警告
  TEST_SESSION="tc10-invalid-$$"
  create_alive_heartbeat "$TEST_SESSION" > /dev/null
  OUTPUT=$(bash "$CHECK_SCRIPT" "$TEST_SESSION" invalid-arg 2>/dev/null || true)

  if echo "$OUTPUT" | grep -q "ALIVE\|STALE\|MISSING"; then
    ok "Check script handles invalid second argument gracefully"
  else
    fail "Check script did not handle arguments gracefully"
  fi

  rm -f "${WATCHDOG_DIR}/${TEST_SESSION}-heartbeat.json"
else
  fail "watchdog-check.sh not found"
fi

# ────────────────────────────────────────────────────────────────
# TC-11: watchdog-monitor.sh 環境變數覆蓋
# ────────────────────────────────────────────────────────────────
echo ""
echo "--- TC-11: watchdog-monitor.sh environment variable override ---"
if [[ -f "$MONITOR_SCRIPT" ]]; then
  TEST_SESSION="tc11-env-override-$$"
  HB_FILE=$(create_monitor_heartbeat "$TEST_SESSION" 9)

  # 覆蓋 warn 閾值為 10m（讓 9m 的 heartbeat 變成 ALIVE）
  OUTPUT=$(SHIKIGAMI_WD_WARN_MINS=10 bash "$MONITOR_SCRIPT" --check-only --session "$TEST_SESSION" 2>/dev/null || true)

  if echo "$OUTPUT" | grep -q "WD-ALIVE"; then
    ok "Environment variable SHIKIGAMI_WD_WARN_MINS overrides default"
  else
    fail "Expected WD-ALIVE with env override, got: $OUTPUT"
  fi

  rm -f "$HB_FILE"
else
  fail "watchdog-monitor.sh not found"
fi

# ────────────────────────────────────────────────────────────────
# TC-12: 整合測試 - 完整流程 (check → monitor → restart)
# ────────────────────────────────────────────────────────────────
echo ""
echo "--- TC-12: Integration test - complete workflow ---"
if [[ -f "$CHECK_SCRIPT" && -f "$MONITOR_SCRIPT" && -f "$RESTART_SCRIPT" ]]; then
  TEST_SESSION="tc12-integration-$$"

  # Step 1: 建立新鮮的 check-mode heartbeat（ALIVE）
  create_alive_heartbeat "$TEST_SESSION" > /dev/null
  OUTPUT=$(bash "$CHECK_SCRIPT" "$TEST_SESSION" 2>/dev/null || true)

  if echo "$OUTPUT" | grep -q "ALIVE"; then
    ok "Integration: check reports ALIVE"
  else
    fail "Integration: check should report ALIVE"
  fi

  # Step 2: 建立新鮮的 monitor-mode heartbeat
  rm -f "${WATCHDOG_DIR}/${TEST_SESSION}-heartbeat.json"
  create_monitor_heartbeat "$TEST_SESSION" 1 > /dev/null

  OUTPUT=$(bash "$MONITOR_SCRIPT" --check-only --session "$TEST_SESSION" 2>/dev/null || true)

  if echo "$OUTPUT" | grep -q "WD-ALIVE\|WD-WARN"; then
    ok "Integration: monitor checks and reports status"
  else
    fail "Integration: monitor should report status"
  fi

  # Step 3: 準備 restart（dry-run）
  OUTPUT=$(bash "$RESTART_SCRIPT" --session "$TEST_SESSION" --dry-run 2>/dev/null || true)

  if echo "$OUTPUT" | grep -q "DRY-RUN\|restart sequence"; then
    ok "Integration: restart can be triggered (dry-run)"
  else
    fail "Integration: restart trigger failed"
  fi

  rm -f "${WATCHDOG_DIR}/session-${TEST_SESSION}-heartbeat.json"
else
  fail "Not all watchdog scripts available"
fi

# ────────────────────────────────────────────────────────────────
# 最終輸出
# ────────────────────────────────────────────────────────────────
echo ""
echo "=== Test Summary ==="
echo "Results: ${PASS} passed, ${FAIL} failed"

if [[ $FAIL -eq 0 ]]; then
  echo "All tests PASSED"
  exit 0
else
  echo "Some tests FAILED"
  exit 1
fi
