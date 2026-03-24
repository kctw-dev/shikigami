#!/usr/bin/env bash
# scripts/watchdog-restart.sh
# Story #408 — Session Watchdog: Auto-restart Integration
# ADR-042 決策 3：Watchdog 偵測 hang 後觸發 Kill Switch + Crash Recovery
#
# 使用方式：
#   bash scripts/watchdog-restart.sh [--session SESSION_ID] [--dry-run]

set -uo pipefail

# ── 引數解析 ──
DRY_RUN=false
TARGET_SESSION="${SESSION_ID:-}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --session) shift; TARGET_SESSION="$1" ;;
    *) echo "[WD-RESTART-WARN] Unknown argument: $1" >&2 ;;
  esac
  shift
done

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
WATCHDOG_DIR="${REPO_ROOT}/docs/sprints/watchdog"
RESTART_LOG="${WATCHDOG_DIR}/session-${TARGET_SESSION:-unknown}-restart-log.json"
EVENTS_LOG="${WATCHDOG_DIR}/watchdog-events.jsonl"

log_event() {
  local event_type="$1"
  local detail="$2"
  local now
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "unknown")
  mkdir -p "$(dirname "$EVENTS_LOG")" 2>/dev/null || true
  printf '%s\n' "{\"event\":\"${event_type}\",\"session_id\":\"${TARGET_SESSION:-unknown}\",\"detail\":\"${detail}\",\"ts\":\"${now}\"}" \
    >> "$EVENTS_LOG" 2>/dev/null || true
}

# ── 冷卻期檢查（ADR-042：10 分鐘內連續重啟超 3 次 → 升級）──
check_restart_cooldown() {
  if [[ ! -f "$EVENTS_LOG" ]]; then return 0; fi

  local ten_min_ago
  if date -d "10 minutes ago" +%Y-%m-%dT%H:%M:%SZ > /dev/null 2>&1; then
    ten_min_ago=$(date -d "10 minutes ago" -u +%Y-%m-%dT%H:%M:%SZ)
  else
    ten_min_ago=$(date -v-10M -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "1970-01-01T00:00:00Z")
  fi

  local recent_restarts
  recent_restarts=$(grep "WD-RESTART-TRIGGERED" "$EVENTS_LOG" 2>/dev/null | \
    awk -v since="$ten_min_ago" -F'"ts":"' '{if ($2 > since) print}' | wc -l || echo 0)

  if [[ "$recent_restarts" -ge 3 ]]; then
    echo "[WD-ESCALATE] Session ${TARGET_SESSION:-unknown}: 3+ restarts in 10 minutes. Stopping restart loop."
    log_event "WD-ESCALATE" "restart_count=${recent_restarts} in 10min"
    return 1
  fi
  return 0
}

echo "[WD-RESTART] Starting restart sequence for session: ${TARGET_SESSION:-unknown}"

# 冷卻期檢查
if ! check_restart_cooldown; then
  exit 1
fi

if [[ "$DRY_RUN" == "true" ]]; then
  echo "[WD-RESTART] DRY-RUN mode — showing restart plan:"
  echo "  1. Kill Switch: bash hooks/kill-switch.sh trigger ${TARGET_SESSION:-unknown} --source watchdog"
  echo "  2. Update restart log: $RESTART_LOG"
  echo "  3. Crash Recovery: bash scripts/crash-recovery.sh"
  echo "  4. Clean heartbeat: rm docs/sprints/watchdog/session-${TARGET_SESSION:-unknown}-heartbeat.json"
  echo "[WD-RESTART] DRY-RUN complete."
  exit 0
fi

# Step 1: 觸發 Kill Switch（ADR-038）
echo "[WD-RESTART] Step 1: Triggering Kill Switch..."
KILL_SWITCH="${REPO_ROOT}/hooks/kill-switch.sh"
if [[ -x "$KILL_SWITCH" ]]; then
  bash "$KILL_SWITCH" trigger "${TARGET_SESSION:-unknown}" --source watchdog --by watchdog-agent 2>/dev/null || {
    echo "[WD-RESTART-WARN] kill-switch.sh failed, continuing..." >&2
  }
  echo "[WD-RESTART] Kill Switch triggered."
else
  echo "[WD-RESTART-WARN] kill-switch.sh not found at $KILL_SWITCH, skipping." >&2
fi

# Step 2: 記錄 restart log
echo "[WD-RESTART] Step 2: Recording restart log..."
mkdir -p "$WATCHDOG_DIR" 2>/dev/null || true
local_now=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "unknown")
cat > "$RESTART_LOG" << RSEOF
{
  "session_id": "${TARGET_SESSION:-unknown}",
  "restart_reason": "watchdog-hang",
  "restarted_at": "${local_now}",
  "crash_recovery_triggered": true
}
RSEOF
log_event "WD-RESTART-TRIGGERED" "reason=watchdog-hang"

# Step 3: 觸發 Crash Recovery（ADR-041）
echo "[WD-RESTART] Step 3: Triggering Crash Recovery..."
CRASH_RECOVERY="${REPO_ROOT}/scripts/crash-recovery.sh"
if [[ -x "$CRASH_RECOVERY" ]]; then
  bash "$CRASH_RECOVERY" 2>/dev/null || {
    echo "[WD-RESTART-WARN] crash-recovery.sh exited non-zero." >&2
  }
  echo "[WD-RESTART] Crash Recovery completed."
else
  echo "[WD-RESTART-WARN] crash-recovery.sh not found, skipping." >&2
fi

# Step 4: 清理 heartbeat 文件
echo "[WD-RESTART] Step 4: Cleaning heartbeat file..."
HB_FILE="${WATCHDOG_DIR}/session-${TARGET_SESSION:-unknown}-heartbeat.json"
if [[ -f "$HB_FILE" ]]; then
  rm -f "$HB_FILE" 2>/dev/null || true
  echo "[WD-RESTART] Heartbeat file removed."
fi

echo "[WD-RESTART] Restart sequence complete."
exit 0
