#!/usr/bin/env bash
# test-us317-exploration.sh
# US-#317 Phase 3 — 探索紀錄收集 TDD 測試套件
#
# AC 覆蓋：
#   AC1：WebSearch/WebFetch 後 append 到 docs/exploration/YYYY-MM-DD-session-<session_id>.jsonl
#   AC2：hooks/exploration-settle.sh 合併為 daily-summary
#   AC3：跨機器不 conflict（per-session 檔案）
#   AC4：欄位完整（session_id, role, event, timestamp, repo, tool, query_or_url）
#   AC5：測試覆蓋（本檔案）

set -euo pipefail

PASS=0
FAIL=0

check() {
  local desc="$1"
  local result="$2"
  if [[ "$result" == "pass" ]]; then
    echo "PASS: $desc"
    (( PASS++ )) || true
  else
    echo "FAIL: $desc"
    (( FAIL++ )) || true
  fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

RECORD_SH="${PLUGIN_ROOT}/hooks/exploration-record.sh"
SETTLE_SH="${PLUGIN_ROOT}/hooks/exploration-settle.sh"
HOOKS_JSON="${PLUGIN_ROOT}/hooks/hooks.json"
PROTECT_MAIN="${PLUGIN_ROOT}/hooks/protect-main.sh"
ADR_025="${PLUGIN_ROOT}/docs/adr/ADR-025-exploration-record.md"

# ── TC-01：exploration-record.sh 存在 ──────────────────────────────────────
check "TC-01：exploration-record.sh 存在" \
  "$([[ -f "$RECORD_SH" ]] && echo pass || echo fail)"

# ── TC-02：exploration-settle.sh 存在 ──────────────────────────────────────
check "TC-02：exploration-settle.sh 存在" \
  "$([[ -f "$SETTLE_SH" ]] && echo pass || echo fail)"

# ── TC-03：hooks.json 包含 WebSearch|WebFetch matcher ──────────────────────
check "TC-03：hooks.json 包含 WebSearch|WebFetch matcher" \
  "$(grep -q 'WebSearch|WebFetch\|WebSearch.*WebFetch' "$HOOKS_JSON" 2>/dev/null && echo pass || echo fail)"

# ── TC-04：hooks.json PreToolUse 包含 exploration-record.sh ───────────────
check "TC-04：hooks.json PreToolUse 包含 exploration-record.sh" \
  "$(grep -q 'exploration-record.sh' "$HOOKS_JSON" 2>/dev/null && echo pass || echo fail)"

# ── TC-05：exploration-record.sh 包含 docs/exploration 路徑 ───────────────
check "TC-05：exploration-record.sh 包含 docs/exploration 路徑" \
  "$(grep -q 'docs/exploration' "$RECORD_SH" 2>/dev/null && echo pass || echo fail)"

# ── TC-06：exploration-record.sh 包含 explore event ───────────────────────
check "TC-06：exploration-record.sh 包含 explore event" \
  "$(grep -q '"explore"' "$RECORD_SH" 2>/dev/null && echo pass || echo fail)"

# ── TC-07：exploration-record.sh 包含 session_id 欄位 ─────────────────────
check "TC-07：exploration-record.sh 包含 session_id 欄位" \
  "$(grep -q 'session_id' "$RECORD_SH" 2>/dev/null && echo pass || echo fail)"

# ── TC-08：exploration-record.sh 包含 query_or_url 欄位 ───────────────────
check "TC-08：exploration-record.sh 包含 query_or_url 欄位" \
  "$(grep -q 'query_or_url' "$RECORD_SH" 2>/dev/null && echo pass || echo fail)"

# ── TC-09：exploration-record.sh 包含 tool 欄位 ───────────────────────────
check "TC-09：exploration-record.sh 包含 tool 欄位" \
  "$(grep -q '"tool"' "$RECORD_SH" 2>/dev/null && echo pass || echo fail)"

# ── TC-10：exploration-record.sh 支援 EXPLORATION_DIR 環境變數覆寫（測試友好）
check "TC-10：exploration-record.sh 支援 EXPLORATION_DIR 環境變數覆寫" \
  "$(grep -q 'EXPLORATION_DIR' "$RECORD_SH" 2>/dev/null && echo pass || echo fail)"

# ── TC-11：exploration-record.sh 使用 per-session 檔案命名 ────────────────
check "TC-11：exploration-record.sh 使用 per-session 檔案命名（session-\$SESSION_ID）" \
  "$(grep -q 'session-' "$RECORD_SH" 2>/dev/null && echo pass || echo fail)"

# ── TC-12：exploration-record.sh session_id=unknown 時加 epoch ────────────
check "TC-12：exploration-record.sh session_id=unknown 時加 epoch timestamp" \
  "$(grep -q 'unknown-\$(date' "$RECORD_SH" 2>/dev/null && echo pass || echo fail)"

# ── TC-13：exploration-settle.sh 包含 docs/exploration 路徑 ───────────────
check "TC-13：exploration-settle.sh 包含 docs/exploration 路徑" \
  "$(grep -q 'docs/exploration' "$SETTLE_SH" 2>/dev/null && echo pass || echo fail)"

# ── TC-14：exploration-settle.sh 產出 summary.jsonl ───────────────────────
check "TC-14：exploration-settle.sh 產出 summary.jsonl" \
  "$(grep -q 'summary.jsonl' "$SETTLE_SH" 2>/dev/null && echo pass || echo fail)"

# ── TC-15：exploration-settle.sh 保留原始 per-session 檔案 ────────────────
check "TC-15：exploration-settle.sh 保留原始 per-session 檔案（保守策略）" \
  "$(grep -qi 'preserve\|保留\|保守' "$SETTLE_SH" 2>/dev/null && echo pass || echo fail)"

# ── TC-16：protect-main.sh 豁免清單包含 docs/exploration/ ─────────────────
check "TC-16：protect-main.sh 豁免清單包含 docs/exploration/" \
  "$(grep -q 'docs/exploration' "$PROTECT_MAIN" 2>/dev/null && echo pass || echo fail)"

# ── TC-17：ADR-025 存在 ────────────────────────────────────────────────────
check "TC-17：ADR-025-exploration-record.md 存在" \
  "$([[ -f "$ADR_025" ]] && echo pass || echo fail)"

# ── TC-18：ADR-025 包含 PreToolUse 觸發機制說明 ───────────────────────────
check "TC-18：ADR-025 包含 PreToolUse 觸發機制說明" \
  "$(grep -q 'PreToolUse' "$ADR_025" 2>/dev/null && echo pass || echo fail)"

# ── TC-19：exploration-record.sh 實際寫入功能測試 ──────────────────────────
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# 模擬 WebSearch 呼叫
EXPLORATION_DIR="$TMP_DIR/exploration" \
CLAUDE_SESSION_ID="test-session-001" \
CLAUDE_TOOL_NAME="WebSearch" \
CLAUDE_TOOL_INPUT='{"query":"shikigami claude plugin"}' \
  bash "$RECORD_SH" > /dev/null 2>&1 || true

# 檢查檔案是否建立
EXPECTED_FILE="$TMP_DIR/exploration/$(date '+%Y-%m-%d')-session-test-session-001.jsonl"
if [[ -f "$EXPECTED_FILE" ]]; then
  check "TC-19：WebSearch 呼叫後 per-session JSONL 已建立" "pass"
  # 驗證欄位完整性（AC4）
  CONTENT=$(cat "$EXPECTED_FILE")
  if echo "$CONTENT" | grep -q '"session_id"' && \
     echo "$CONTENT" | grep -q '"role"' && \
     echo "$CONTENT" | grep -q '"event"' && \
     echo "$CONTENT" | grep -q '"timestamp"' && \
     echo "$CONTENT" | grep -q '"tool"' && \
     echo "$CONTENT" | grep -q '"query_or_url"'; then
    check "TC-20：JSONL 欄位完整（session_id+role+event+timestamp+tool+query_or_url）" "pass"
  else
    check "TC-20：JSONL 欄位完整（session_id+role+event+timestamp+tool+query_or_url）" "fail"
  fi
else
  check "TC-19：WebSearch 呼叫後 per-session JSONL 已建立" "fail"
  check "TC-20：JSONL 欄位完整（session_id+role+event+timestamp+tool+query_or_url）" "fail"
fi

# ── TC-21：exploration-settle.sh 合併測試 ──────────────────────────────────
SETTLE_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR" "$SETTLE_DIR"' EXIT

mkdir -p "$SETTLE_DIR"
TODAY="$(date '+%Y-%m-%d')"

# 建立兩個 per-session 測試檔案
echo '{"session_id":"a","role":"scrum-master","event":"explore","timestamp":"2026-03-20T10:00:00+0800","repo":"shikigami","tool":"WebSearch","query_or_url":"test query 1"}' \
  >> "${SETTLE_DIR}/${TODAY}-session-aaa.jsonl"
echo '{"session_id":"b","role":"scrum-master","event":"explore","timestamp":"2026-03-20T09:00:00+0800","repo":"shikigami","tool":"WebFetch","query_or_url":"https://example.com"}' \
  >> "${SETTLE_DIR}/${TODAY}-session-bbb.jsonl"

# 執行 settle
EXPLORATION_DIR="$SETTLE_DIR" bash "$SETTLE_SH" "$TODAY" > /dev/null 2>&1 || true

SUMMARY_FILE="${SETTLE_DIR}/${TODAY}.summary.jsonl"
if [[ -f "$SUMMARY_FILE" ]]; then
  SUMMARY_LINES=$(wc -l < "$SUMMARY_FILE" | tr -d ' ')
  check "TC-21：exploration-settle.sh 合併產出 summary.jsonl（共 2 筆）" \
    "$([[ "$SUMMARY_LINES" -eq 2 ]] && echo pass || echo fail)"
  # 檢查原始 per-session 保留
  check "TC-22：原始 per-session 檔案保留（session-aaa.jsonl 仍存在）" \
    "$([[ -f "${SETTLE_DIR}/${TODAY}-session-aaa.jsonl" ]] && echo pass || echo fail)"
else
  check "TC-21：exploration-settle.sh 合併產出 summary.jsonl（共 2 筆）" "fail"
  check "TC-22：原始 per-session 檔案保留（session-aaa.jsonl 仍存在）" "fail"
fi

# ── 結果輸出 ──────────────────────────────────────────────────────────────
echo ""
echo "結果：PASS=${PASS}  FAIL=${FAIL}"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
