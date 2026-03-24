#!/usr/bin/env bash
# PostToolUse hook: Agent tool call 完成時寫入 live-log
# 觸發條件：PostToolUse matcher=Agent
set -euo pipefail

# 讀取 session ID
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib/resolve-session-id.sh" 2>/dev/null || SHIKIGAMI_SESSION_ID="${SHIKIGAMI_SESSION_ID:-unknown}"

# 從 stdin 讀取 hook payload（JSON）
PAYLOAD=$(cat)

# 提取 description（Agent tool call 的 description 參數）
DESCRIPTION=$(echo "$PAYLOAD" | jq -r '.tool_input.description // "unknown agent"' 2>/dev/null || echo "unknown agent")

# 提取結果狀態
# PostToolUse 的 payload 包含 tool_result
RESULT_PREVIEW=$(echo "$PAYLOAD" | jq -r '.tool_result // "" | tostring | .[0:100]' 2>/dev/null || echo "")

# 寫入 live-log
LOG_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)/logs/live"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/$(date '+%Y-%m-%d')-session-${SHIKIGAMI_SESSION_ID}.log"

TIMESTAMP=$(date '+%H:%M:%S')
echo "[${TIMESTAMP}] [agent] ${DESCRIPTION} — completed" >> "$LOG_FILE" 2>/dev/null || true
