#!/usr/bin/env bash
# scripts/watchdog-monitor.sh
# Story #408 — Session Watchdog: Heartbeat Timeout Detection
# ADR-042 決策 1 + 2：監控 heartbeat 文件更新時間，超過閾值觸發 hang 偵測
#
# 使用方式：
#   bash scripts/watchdog-monitor.sh [--check-only] [--session SESSION_ID]
#   WATCHDOG_HEARTBEAT_FILE=/path/to/hb.json bash scripts/watchdog-monitor.sh --check-only
#
# --check-only：單次檢查後退出（不持續監控）
# 無 --check-only：持續監控循環（每 60 秒檢查一次）

set -uo pipefail

# ── 配置 ──
WD_WARN_MINS="${SHIKIGAMI_WD_WARN_MINS:-15}"   # 警告閾值（分鐘）
WD_HANG_MINS="${SHIKIGAMI_WD_HANG_MINS:-30}"   # hang 判定閾值（分鐘）
WD_POLL_SECS="${SHIKIGAMI_WD_POLL_SECS:-60}"   # 輪詢間隔（秒）

# ── 引數解析 ──
CHECK_ONLY=false
TARGET_SESSION="${SESSION_ID:-}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check-only) CHECK_ONLY=true ;;
    --session) shift; TARGET_SESSION="$1" ;;
    *) echo "[WD-WARN] Unknown argument: $1" >&2 ;;
  esac
  shift
done

# ── 路徑解析 ──
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
WATCHDOG_DIR="${REPO_ROOT}/docs/sprints/watchdog"
EVENTS_LOG="${REPO_ROOT}/docs/sprints/watchdog/watchdog-events.jsonl"

# 支援 WATCHDOG_HEARTBEAT_FILE 直接指定（測試用）
if [[ -n "${WATCHDOG_HEARTBEAT_FILE:-}" ]]; then
  HB_FILES=("$WATCHDOG_HEARTBEAT_FILE")
elif [[ -n "$TARGET_SESSION" ]]; then
  HB_FILES=("${WATCHDOG_DIR}/session-${TARGET_SESSION}-heartbeat.json")
else
  # 掃描所有 heartbeat 文件
  mapfile -t HB_FILES < <(find "$WATCHDOG_DIR" -name "*-heartbeat.json" 2>/dev/null | sort)
fi

# ── 工具函數 ──
log_event() {
  local event_type="$1"
  local session_id="$2"
  local detail="$3"
  local now
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "unknown")
  mkdir -p "$(dirname "$EVENTS_LOG")" 2>/dev/null || true
  printf '%s\n' "{\"event\":\"${event_type}\",\"session_id\":\"${session_id}\",\"detail\":\"${detail}\",\"ts\":\"${now}\"}" \
    >> "$EVENTS_LOG" 2>/dev/null || true
}

# ── Heartbeat 年齡計算 ──
# 回傳 heartbeat 距今分鐘數
get_heartbeat_age_mins() {
  local hb_file="$1"
  local last_beat_at

  if command -v jq > /dev/null 2>&1; then
    last_beat_at=$(jq -r '.last_beat_at // empty' "$hb_file" 2>/dev/null || echo "")
  else
    last_beat_at=$(grep -oP '"last_beat_at":\s*"\K[^"]+' "$hb_file" 2>/dev/null | head -1 || echo "")
  fi

  if [[ -z "$last_beat_at" ]]; then
    echo "999"  # 無法解析，視為超時
    return
  fi

  # 計算時間差（分鐘）
  local now_epoch last_epoch
  if date -d "$last_beat_at" +%s > /dev/null 2>&1; then
    # GNU date（Linux）
    last_epoch=$(date -d "$last_beat_at" +%s 2>/dev/null || echo 0)
    now_epoch=$(date +%s)
  elif date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_beat_at" +%s > /dev/null 2>&1; then
    # BSD date（macOS）
    last_beat_at_clean="${last_beat_at%Z}"
    last_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${last_beat_at_clean}" +%s 2>/dev/null || echo 0)
    now_epoch=$(date +%s)
  else
    echo "999"
    return
  fi

  local diff_secs=$(( now_epoch - last_epoch ))
  echo $(( diff_secs / 60 ))
}

# ── 單次檢查邏輯 ──
check_heartbeats() {
  local any_hang=false

  if [[ ${#HB_FILES[@]} -eq 0 ]]; then
    echo "[WD-NO-HEARTBEAT] No heartbeat files found in $WATCHDOG_DIR"
    return 0
  fi

  for hb_file in "${HB_FILES[@]}"; do
    [[ -f "$hb_file" ]] || continue

    local session_id
    if command -v jq > /dev/null 2>&1; then
      session_id=$(jq -r '.session_id // "unknown"' "$hb_file" 2>/dev/null || echo "unknown")
    else
      session_id=$(grep -oP '"session_id":\s*"\K[^"]+' "$hb_file" 2>/dev/null | head -1 || echo "unknown")
    fi

    local age_mins
    age_mins=$(get_heartbeat_age_mins "$hb_file")

    if [[ "$age_mins" -ge "$WD_HANG_MINS" ]]; then
      echo "[WD-HANG-DETECTED] session=${session_id} age=${age_mins}min (threshold=${WD_HANG_MINS}min)"
      log_event "WD-HANG-DETECTED" "$session_id" "age=${age_mins}min"
      any_hang=true
    elif [[ "$age_mins" -ge "$WD_WARN_MINS" ]]; then
      echo "[WD-WARN] session=${session_id} age=${age_mins}min (warn_threshold=${WD_WARN_MINS}min)"
      log_event "WD-WARN" "$session_id" "age=${age_mins}min"
    else
      echo "[WD-ALIVE] session=${session_id} age=${age_mins}min — FRESH"
      log_event "WD-ALIVE" "$session_id" "age=${age_mins}min"
    fi
  done

  if [[ "$any_hang" == "true" ]]; then
    return 1
  fi
  return 0
}

# ── 主邏輯 ──
if [[ "$CHECK_ONLY" == "true" ]]; then
  check_heartbeats
  exit $?
fi

# 持續監控模式（NFR4：收到 SIGTERM graceful 停止）
echo "[WD-MONITOR-START] warn=${WD_WARN_MINS}m hang=${WD_HANG_MINS}m poll=${WD_POLL_SECS}s"
trap 'echo "[WD-MONITOR-STOP] Received SIGTERM, stopping gracefully"; exit 0' TERM INT

while true; do
  check_heartbeats || {
    # Hang detected — 觸發 restart（若 watchdog-restart.sh 存在）
    SCRIPT_DIR=$(dirname "$0")
    if [[ -x "${SCRIPT_DIR}/watchdog-restart.sh" ]]; then
      echo "[WD-TRIGGERING-RESTART] Invoking watchdog-restart.sh..."
      bash "${SCRIPT_DIR}/watchdog-restart.sh" 2>&1 || true
    fi
  }
  sleep "$WD_POLL_SECS"
done
