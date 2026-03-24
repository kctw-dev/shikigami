#!/usr/bin/env bash
# tests/test-watchdog.sh
# Story #408 — Session Watchdog: Hook-based Heartbeat
# 驗收標準：
#   AC1: hooks/session-watchdog.sh 存在，heartbeat 更新正確
#   AC2: scripts/watchdog-monitor.sh 存在，超時偵測邏輯正確
#   AC3: scripts/watchdog-restart.sh 存在，呼叫 Crash Recovery 流程
#   AC4: 本測試驗證 heartbeat 超時偵測邏輯
#   AC5: hooks/hooks.json 包含 watchdog heartbeat hook 配置

set -uo pipefail

PASS=0
FAIL=0
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

check() {
  local desc="$1"
  local result="$2"
  if [[ "$result" == "PASS" ]]; then
    echo "  PASS: $desc"
    ((PASS++)) || true
  else
    echo "  FAIL: $desc"
    ((FAIL++)) || true
  fi
}

echo "=== test-watchdog.sh ==="
echo ""

# AC1: hooks/session-watchdog.sh 存在且可執行
echo "[AC1] hooks/session-watchdog.sh 存在性"
if [[ -f "hooks/session-watchdog.sh" ]]; then
  check "hooks/session-watchdog.sh 存在" "PASS"
  if [[ -x "hooks/session-watchdog.sh" ]]; then
    check "hooks/session-watchdog.sh 可執行" "PASS"
  else
    check "hooks/session-watchdog.sh 可執行" "FAIL"
  fi
else
  check "hooks/session-watchdog.sh 存在" "FAIL"
  check "hooks/session-watchdog.sh 可執行" "FAIL"
fi

# AC2: scripts/watchdog-monitor.sh 存在且可執行
echo "[AC2] scripts/watchdog-monitor.sh 存在性"
if [[ -f "scripts/watchdog-monitor.sh" ]]; then
  check "scripts/watchdog-monitor.sh 存在" "PASS"
  if [[ -x "scripts/watchdog-monitor.sh" ]]; then
    check "scripts/watchdog-monitor.sh 可執行" "PASS"
  else
    check "scripts/watchdog-monitor.sh 可執行" "FAIL"
  fi
else
  check "scripts/watchdog-monitor.sh 存在" "FAIL"
  check "scripts/watchdog-monitor.sh 可執行" "FAIL"
fi

# AC3: scripts/watchdog-restart.sh 存在且可執行
echo "[AC3] scripts/watchdog-restart.sh 存在性"
if [[ -f "scripts/watchdog-restart.sh" ]]; then
  check "scripts/watchdog-restart.sh 存在" "PASS"
  if [[ -x "scripts/watchdog-restart.sh" ]]; then
    check "scripts/watchdog-restart.sh 可執行" "PASS"
  else
    check "scripts/watchdog-restart.sh 可執行" "FAIL"
  fi
else
  check "scripts/watchdog-restart.sh 存在" "FAIL"
  check "scripts/watchdog-restart.sh 可執行" "FAIL"
fi

# AC4: Heartbeat 超時偵測測試（核心）
echo "[AC4] Heartbeat 超時偵測測試"

# Test 1: 新鮮 heartbeat → 不觸發 hang
FRESH_HB="$TMP_DIR/fresh-heartbeat.json"
FRESH_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)
cat > "$FRESH_HB" << HBEOF
{"session_id":"test-sess","last_beat_at":"${FRESH_TIME}","beat_count":5}
HBEOF
if [[ -f "scripts/watchdog-monitor.sh" ]]; then
  RESULT=$(WATCHDOG_HEARTBEAT_FILE="$FRESH_HB" SHIKIGAMI_WD_HANG_MINS=30 \
    bash scripts/watchdog-monitor.sh --check-only 2>&1 || true)
  if echo "$RESULT" | grep -q "WD-ALIVE\|alive\|fresh\|ok\|OK\|PASS\|no hang\|FRESH"; then
    check "新鮮 heartbeat 不觸發 hang 告警" "PASS"
  elif echo "$RESULT" | grep -q "WD-HANG\|hang detected"; then
    check "新鮮 heartbeat 不觸發 hang 告警（誤報了 hang）" "FAIL"
  else
    # Watchdog 無輸出也視為正確（新鮮時靜默）
    check "新鮮 heartbeat 不觸發 hang 告警（靜默=正常）" "PASS"
  fi

  # Test 2: 過期 heartbeat → 觸發 hang
  OLD_HB="$TMP_DIR/old-heartbeat.json"
  # 使用 2 小時前的時間戳（超過任何閾值）
  if date -d "2 hours ago" +%Y-%m-%dT%H:%M:%SZ > /dev/null 2>&1; then
    OLD_TIME=$(date -d "2 hours ago" -u +%Y-%m-%dT%H:%M:%SZ)
  else
    OLD_TIME=$(date -v-2H -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "2026-03-24T18:00:00Z")
  fi
  cat > "$OLD_HB" << HBEOF2
{"session_id":"test-sess-old","last_beat_at":"${OLD_TIME}","beat_count":3}
HBEOF2
  RESULT2=$(WATCHDOG_HEARTBEAT_FILE="$OLD_HB" SHIKIGAMI_WD_HANG_MINS=1 \
    bash scripts/watchdog-monitor.sh --check-only 2>&1 || true)
  if echo "$RESULT2" | grep -q "WD-HANG\|WD-WARN\|hang\|HANG\|stale\|STALE\|timeout\|TIMEOUT"; then
    check "過期 heartbeat 正確觸發 hang/warn 告警" "PASS"
  else
    check "過期 heartbeat 正確觸發 hang/warn 告警（output: ${RESULT2:0:80}）" "FAIL"
  fi
else
  check "新鮮 heartbeat 不觸發 hang 告警" "FAIL"
  check "過期 heartbeat 正確觸發 hang/warn 告警" "FAIL"
fi

# AC4: heartbeat update 功能（session-watchdog.sh）
echo "[AC4] Heartbeat 更新功能"
if [[ -f "hooks/session-watchdog.sh" ]]; then
  HB_FILE="$TMP_DIR/test-heartbeat.json"
  SESSION_ID="test-$(date +%s)" WATCHDOG_HEARTBEAT_FILE="$HB_FILE" \
    bash hooks/session-watchdog.sh 2>/dev/null || true
  if [[ -f "$HB_FILE" ]]; then
    check "session-watchdog.sh 更新 heartbeat 文件" "PASS"
    if grep -q "last_beat_at" "$HB_FILE" 2>/dev/null; then
      check "heartbeat 文件包含 last_beat_at 欄位" "PASS"
    else
      check "heartbeat 文件包含 last_beat_at 欄位" "FAIL"
    fi
  else
    check "session-watchdog.sh 更新 heartbeat 文件" "FAIL"
    check "heartbeat 文件包含 last_beat_at 欄位" "FAIL"
  fi
fi

# AC5: hooks/hooks.json 包含 watchdog 配置
echo "[AC5] hooks/hooks.json 包含 watchdog hook"
if grep -q "watchdog\|session-watchdog" hooks/hooks.json 2>/dev/null; then
  check "hooks/hooks.json 包含 watchdog hook 配置" "PASS"
else
  check "hooks/hooks.json 包含 watchdog hook 配置" "FAIL"
fi

# AC3: watchdog-restart.sh 呼叫 crash-recovery（內容驗證）
echo "[AC3] watchdog-restart.sh 整合 Crash Recovery"
if [[ -f "scripts/watchdog-restart.sh" ]]; then
  if grep -q "crash-recovery\|side-effect-guard\|recovery" scripts/watchdog-restart.sh 2>/dev/null; then
    check "watchdog-restart.sh 整合 Crash Recovery 流程" "PASS"
  else
    check "watchdog-restart.sh 整合 Crash Recovery 流程" "FAIL"
  fi
fi

# AC1（#646）: watchdog-monitor.sh 預設閾值驗證（10 分鐘）
# NFR1：hang 偵測延遲 < timeout + 1 分鐘（#408 規格：timeout=10min → 偵測 < 11min）
# 預設 WD_HANG_MINS 應為 10，WD_WARN_MINS 應為 8（或 ≤ 10）
echo "[AC1/#646] watchdog-monitor.sh 預設閾值驗證"
if [[ -f "scripts/watchdog-monitor.sh" ]]; then
  DEFAULT_HANG=$(grep -E '^WD_HANG_MINS=.*:-[0-9]+' scripts/watchdog-monitor.sh | grep -oE ':-[0-9]+\}' | grep -oE '[0-9]+' | head -1)
  DEFAULT_WARN=$(grep -E '^WD_WARN_MINS=.*:-[0-9]+' scripts/watchdog-monitor.sh | grep -oE ':-[0-9]+\}' | grep -oE '[0-9]+' | head -1)
  if [[ "${DEFAULT_HANG}" == "10" ]]; then
    check "WD_HANG_MINS 預設值 = 10 分鐘（#408 NFR1 規格）" "PASS"
  else
    check "WD_HANG_MINS 預設值 = 10 分鐘（實際: ${DEFAULT_HANG:-未設定}）" "FAIL"
  fi
  if [[ -n "${DEFAULT_WARN}" ]] && [[ "${DEFAULT_WARN}" -le 10 ]]; then
    check "WD_WARN_MINS 預設值 ≤ 10 分鐘（實際: ${DEFAULT_WARN}）" "PASS"
  else
    check "WD_WARN_MINS 預設值 ≤ 10 分鐘（實際: ${DEFAULT_WARN:-未設定}）" "FAIL"
  fi
  # SHIKIGAMI_WATCHDOG_TIMEOUT 環境變數應可覆蓋 WD_HANG_MINS（AC4）
  if grep -q "SHIKIGAMI_WATCHDOG_TIMEOUT\|SHIKIGAMI_WD_HANG_MINS" scripts/watchdog-monitor.sh 2>/dev/null; then
    check "SHIKIGAMI_WATCHDOG_TIMEOUT / SHIKIGAMI_WD_HANG_MINS 環境變數覆蓋支援" "PASS"
  else
    check "SHIKIGAMI_WATCHDOG_TIMEOUT / SHIKIGAMI_WD_HANG_MINS 環境變數覆蓋支援" "FAIL"
  fi
else
  check "WD_HANG_MINS 預設值 = 10 分鐘" "FAIL"
  check "WD_WARN_MINS 預設值 ≤ 10 分鐘" "FAIL"
  check "SHIKIGAMI_WATCHDOG_TIMEOUT / SHIKIGAMI_WD_HANG_MINS 環境變數覆蓋支援" "FAIL"
fi

echo ""
echo "=== 結果：$PASS PASS, $FAIL FAIL ==="
if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
exit 0
