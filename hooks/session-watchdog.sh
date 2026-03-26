#!/usr/bin/env bash
# hooks/session-watchdog.sh
# Story #408 — Session Watchdog: Hook-based Heartbeat
# ADR-042 決策 1：每次 PostToolUse hook 觸發時更新 heartbeat 文件
#
# Hook 類別: settle（PostToolUse 事件，被動觸發）
#
# 使用方式（PostToolUse hook 或直接呼叫）：
#   bash hooks/session-watchdog.sh
#   SESSION_ID=my-session bash hooks/session-watchdog.sh
#
# 環境變數：
#   SESSION_ID               — Session 識別碼（可選，從 shikigami.local.md 讀取）
#   WATCHDOG_HEARTBEAT_FILE  — 覆蓋 heartbeat 文件路徑（測試用）
#
# 輸出標記（stdout）：
#   [WATCHDOG-OK]    — heartbeat 已更新
#   [WATCHDOG-SKIP]  — 無法取得 SESSION_ID，跳過
#
# 失敗行為：靜默降級（heartbeat 寫入失敗不影響主流程）

set -uo pipefail

# ── 路徑初始化 ──
SESSION_ID="${SESSION_ID:-${SHIKIGAMI_SESSION_ID:-default}}"
SPRINT_NUM="${SPRINT_NUM:-${SHIKIGAMI_SPRINT_NUM:-0}}"
STORY_ID="${STORY_ID:-${SHIKIGAMI_STORY_ID:-}}"
TOOL_NAME="${TOOL_NAME:-${SHIKIGAMI_TOOL_NAME:-unknown}}"

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
DEFAULT_HB_FILE="${REPO_ROOT}/docs/sprints/watchdog/session-${SESSION_ID}-heartbeat.json"
HB_FILE="${WATCHDOG_HEARTBEAT_FILE:-$DEFAULT_HB_FILE}"

# ── Heartbeat 更新（NFR4：失敗時 graceful degrade）──
update_heartbeat() {
  local beat_count=0
  local started_at
  started_at=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "unknown")

  # 讀取現有 heartbeat 以累積 beat_count 和 started_at
  if [[ -f "$HB_FILE" ]]; then
    if command -v jq > /dev/null 2>&1; then
      beat_count=$(jq -r '.beat_count // 0' "$HB_FILE" 2>/dev/null || echo 0)
      started_at=$(jq -r '.started_at // "unknown"' "$HB_FILE" 2>/dev/null || echo "$started_at")
    else
      beat_count=$(grep -oP '"beat_count":\s*\K\d+' "$HB_FILE" 2>/dev/null | head -1 || echo 0)
      started_at=$(grep -oP '"started_at":\s*"\K[^"]+' "$HB_FILE" 2>/dev/null | head -1 || echo "$started_at")
    fi
    ((beat_count++)) || true
  fi

  local now
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "unknown")

  # NFR4: 建立目錄失敗時 graceful degrade
  mkdir -p "$(dirname "$HB_FILE")" 2>/dev/null || {
    echo "[WD-WARN] Cannot create watchdog directory for $HB_FILE" >&2
    return 0
  }

  # 寫入 heartbeat（原子性：先寫 tmp 再 mv）
  local tmp_file="${HB_FILE}.tmp.$$"
  cat > "$tmp_file" << HBEOF
{
  "session_id": "${SESSION_ID}",
  "sprint": ${SPRINT_NUM},
  "story_id": "${STORY_ID:-null}",
  "action": "${TOOL_NAME}",
  "last_beat_at": "${now}",
  "started_at": "${started_at}",
  "beat_count": ${beat_count}
}
HBEOF
  mv "$tmp_file" "$HB_FILE" 2>/dev/null || {
    rm -f "$tmp_file" 2>/dev/null
    echo "[WD-WARN] Cannot write heartbeat to $HB_FILE" >&2
    return 0
  }
}

update_heartbeat
