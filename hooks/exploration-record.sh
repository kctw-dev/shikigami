#!/usr/bin/env bash
# hooks/exploration-record.sh
# US-#317 Phase 3 — 探索紀錄收集（PreToolUse hook）
#
# 觸發時機：WebSearch 或 WebFetch 工具呼叫前（PreToolUse hook）
# 行為：
#   - 從 CLAUDE_TOOL_INPUT JSON 解析查詢/URL
#   - append JSONL 到 docs/exploration/YYYY-MM-DD-session-<session_id>.jsonl
#   - per-session 檔案（天然隔離，無需 flock）
#
# 環境變數：
#   CLAUDE_TOOL_NAME    — 工具名稱（WebSearch 或 WebFetch）
#   CLAUDE_TOOL_INPUT   — JSON 輸入（{"query":"..."} 或 {"url":"..."}）
#   CLAUDE_SESSION_ID   — 目前 session ID
#   EXPLORATION_DIR     — 可覆寫探索目錄（測試友好）
#
# JSONL 格式：
#   {"session_id":"<id>","role":"scrum-master","event":"explore",
#    "timestamp":"<ISO8601>","repo":"<repo>","tool":"WebSearch|WebFetch",
#    "query_or_url":"<查詢或 URL>"}

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── 只處理 WebSearch / WebFetch ─────────────────────────────────────────────
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
if [[ "$TOOL_NAME" != "WebSearch" && "$TOOL_NAME" != "WebFetch" ]]; then
  exit 0
fi

# ── 讀取工具輸入 JSON ────────────────────────────────────────────────────────
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"
if [[ -z "$TOOL_INPUT" ]]; then
  exit 0
fi

# ── 解析 query 或 url ────────────────────────────────────────────────────────
QUERY_OR_URL=""
if command -v jq &>/dev/null; then
  if [[ "$TOOL_NAME" == "WebSearch" ]]; then
    QUERY_OR_URL=$(echo "$TOOL_INPUT" | jq -r '.query // .q // ""' 2>/dev/null || echo "")
  else
    QUERY_OR_URL=$(echo "$TOOL_INPUT" | jq -r '.url // .URL // ""' 2>/dev/null || echo "")
  fi
else
  # POSIX sed fallback
  if [[ "$TOOL_NAME" == "WebSearch" ]]; then
    QUERY_OR_URL=$(echo "$TOOL_INPUT" | sed -n 's/.*"query"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")
  else
    QUERY_OR_URL=$(echo "$TOOL_INPUT" | sed -n 's/.*"url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")
  fi
fi

# ── 建立探索目錄 ─────────────────────────────────────────────────────────────
EXPLORATION_DIR="${EXPLORATION_DIR:-${PLUGIN_ROOT}/docs/exploration}"
mkdir -p "$EXPLORATION_DIR"

# ── Session ID（沿用 #319 模式）─────────────────────────────────────────────
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
if [[ "$SESSION_ID" == "unknown" ]]; then
  SESSION_ID="unknown-$(date +%s)"
fi

# ── 組裝 JSONL 欄位 ──────────────────────────────────────────────────────────
ROLE="scrum-master"
EVENT="explore"
TIMESTAMP="$(date '+%Y-%m-%dT%H:%M:%S%z')"
TODAY="$(date '+%Y-%m-%d')"

# 取得 repo 名稱
REPO_ROOT_PATH=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PLUGIN_ROOT")
REPO_NAME=$(git remote get-url origin 2>/dev/null \
  | sed 's|.*[/:]||' | sed 's/\.git$//' \
  || basename "$REPO_ROOT_PATH")

# per-session 檔案路徑
JSONL_FILE="${EXPLORATION_DIR}/${TODAY}-session-${SESSION_ID}.jsonl"

# JSON 特殊字元轉義 helper
escape_json() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

QUERY_ESCAPED="$(escape_json "${QUERY_OR_URL}")"

# ── append JSONL（per-session 天然隔離，無需 flock）──────────────────────────
printf '{"session_id":"%s","role":"%s","event":"%s","timestamp":"%s","repo":"%s","tool":"%s","query_or_url":"%s"}\n' \
  "$SESSION_ID" "$ROLE" "$EVENT" "$TIMESTAMP" "$REPO_NAME" "$TOOL_NAME" "$QUERY_ESCAPED" \
  >> "$JSONL_FILE" 2>/dev/null || true
