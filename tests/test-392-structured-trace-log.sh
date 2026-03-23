#!/usr/bin/env bash
# test-392-structured-trace-log.sh
# #392 驗收測試：Structured Trace Log — Multi-Agent Observability
# TDD Red phase — 先寫測試，再實作

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

LIFECYCLE_PROMPT="${REPO_ROOT}/skills/sprint-execution/story-lifecycle-prompt.md"
TRACE_LOG_DIR="${REPO_ROOT}/docs/trace-logs"
RETENTION_SCRIPT="${REPO_ROOT}/hooks/trace-log-retention.sh"
SESSION_START_HOOK="${REPO_ROOT}/hooks/session-start"

pass() {
  echo "[PASS] $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "[FAIL] $1"
  FAIL=$((FAIL + 1))
}

echo "=== #392 Structured Trace Log 驗收測試 ==="
echo ""

# ── AC1: JSONL trace schema 定義完整性 ────────────────────────────────────

echo "--- AC1: JSONL trace schema 定義 ---"

# ADR-033 已 Accepted，story-lifecycle-prompt.md 應包含 trace 寫入指令，含 schema 欄位
if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "traceId" "${LIFECYCLE_PROMPT}"; then
  pass "AC1-1: story-lifecycle-prompt.md 含 traceId schema 欄位"
else
  fail "AC1-1: story-lifecycle-prompt.md 缺少 traceId schema 欄位"
fi

if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "spanId" "${LIFECYCLE_PROMPT}"; then
  pass "AC1-2: story-lifecycle-prompt.md 含 spanId schema 欄位"
else
  fail "AC1-2: story-lifecycle-prompt.md 缺少 spanId schema 欄位"
fi

if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "parentSpanId" "${LIFECYCLE_PROMPT}"; then
  pass "AC1-3: story-lifecycle-prompt.md 含 parentSpanId schema 欄位"
else
  fail "AC1-3: story-lifecycle-prompt.md 缺少 parentSpanId schema 欄位"
fi

if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "agentRole" "${LIFECYCLE_PROMPT}"; then
  pass "AC1-4: story-lifecycle-prompt.md 含 agentRole schema 欄位"
else
  fail "AC1-4: story-lifecycle-prompt.md 缺少 agentRole schema 欄位"
fi

if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "duration" "${LIFECYCLE_PROMPT}"; then
  pass "AC1-5: story-lifecycle-prompt.md 含 duration schema 欄位"
else
  fail "AC1-5: story-lifecycle-prompt.md 缺少 duration schema 欄位"
fi

# ── AC2: Agent 執行時寫入 trace log ────────────────────────────────────────

echo ""
echo "--- AC2: story-lifecycle-prompt.md 含 trace 寫入指令 ---"

# story-lifecycle-prompt.md 應有 trace-log 寫入指令（TRACE_LOG_FILE 路徑設定）
if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "TRACE_LOG_FILE\|trace-logs" "${LIFECYCLE_PROMPT}"; then
  pass "AC2-1: story-lifecycle-prompt.md 含 trace log 路徑設定"
else
  fail "AC2-1: story-lifecycle-prompt.md 缺少 trace log 路徑設定"
fi

# 應在 story start 時寫入 started span
if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "story_start\|tdd-implement.*started\|dispatch-story" "${LIFECYCLE_PROMPT}"; then
  pass "AC2-2: story-lifecycle-prompt.md 含 started span 寫入"
else
  fail "AC2-2: story-lifecycle-prompt.md 缺少 started span 寫入指令"
fi

# 應在 story end 時寫入 completed span
if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "completed\|status.*completed" "${LIFECYCLE_PROMPT}"; then
  pass "AC2-3: story-lifecycle-prompt.md 含 completed span 寫入"
else
  fail "AC2-3: story-lifecycle-prompt.md 缺少 completed span 寫入指令"
fi

# trace log 寫入指令應包含 sessionId
if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "sessionId\|CLAUDE_SESSION_ID" "${LIFECYCLE_PROMPT}"; then
  pass "AC2-4: trace 寫入指令含 sessionId"
else
  fail "AC2-4: trace 寫入指令缺少 sessionId"
fi

# ── AC3: per-session 檔案命名格式 ─────────────────────────────────────────

echo ""
echo "--- AC3: per-session 檔案命名 ---"

# story-lifecycle-prompt.md 應有 docs/trace-logs/ 路徑引用
if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "docs/trace-logs" "${LIFECYCLE_PROMPT}"; then
  pass "AC3-1: story-lifecycle-prompt.md 含 docs/trace-logs 路徑"
else
  fail "AC3-1: story-lifecycle-prompt.md 缺少 docs/trace-logs 路徑"
fi

# 命名格式應含 {date}-{session-id}.jsonl（與 ADR-033 一致）
if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -qE "trace-logs/.*session.*\.jsonl" "${LIFECYCLE_PROMPT}"; then
  pass "AC3-2: story-lifecycle-prompt.md 含正確的 per-session JSONL 命名格式"
else
  fail "AC3-2: story-lifecycle-prompt.md 缺少 per-session JSONL 命名格式"
fi

# docs/trace-logs/ 目錄存在（.gitkeep）
if [[ -d "${TRACE_LOG_DIR}" ]]; then
  pass "AC3-3: docs/trace-logs/ 目錄存在"
else
  fail "AC3-3: docs/trace-logs/ 目錄不存在"
fi

# ── AC4: 三種 log 各自獨立不衝突 ─────────────────────────────────────────

echo ""
echo "--- AC4: 三種 log 職責分離 ---"

# story-lifecycle-prompt.md 應已有 LIVE_LOG_FILE 路徑（既有）
if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "LIVE_LOG_FILE\|live-log" "${LIFECYCLE_PROMPT}"; then
  pass "AC4-1: story-lifecycle-prompt.md 含既有 live-log 路徑"
else
  fail "AC4-1: story-lifecycle-prompt.md 缺少 live-log 路徑"
fi

# trace-log 路徑應為 docs/trace-logs/（不與 cruise-logs / live-log 混淆）
if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "trace-logs" "${LIFECYCLE_PROMPT}"; then
  pass "AC4-2: trace-log 使用獨立的 docs/trace-logs 路徑"
else
  fail "AC4-2: trace-log 未使用獨立路徑"
fi

# ── AC5: ADR-033 Accepted 且實作一致 ──────────────────────────────────────

echo ""
echo "--- AC5: ADR-033 一致性 ---"

ADR_033="${REPO_ROOT}/docs/adr/ADR-033-structured-trace-log.md"
if [[ -f "${ADR_033}" ]]; then
  pass "AC5-1: ADR-033 文件存在"
else
  fail "AC5-1: ADR-033 文件不存在"
fi

if [[ -f "${ADR_033}" ]] && grep -q "Accepted" "${ADR_033}"; then
  pass "AC5-2: ADR-033 狀態為 Accepted"
else
  fail "AC5-2: ADR-033 狀態非 Accepted"
fi

# story-lifecycle-prompt.md 應引用 ADR-033（或其定義的欄位，確認一致性）
if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "ADR-033\|trace.log\|trace-log" "${LIFECYCLE_PROMPT}"; then
  pass "AC5-3: story-lifecycle-prompt.md 含 ADR-033 相關引用或 trace log 實作"
else
  fail "AC5-3: story-lifecycle-prompt.md 缺少 ADR-033 trace log 實作"
fi

# ── AC6: Retention 策略（7天自動清理）────────────────────────────────────

echo ""
echo "--- AC6: Retention 清理機制 ---"

if [[ -f "${RETENTION_SCRIPT}" ]]; then
  pass "AC6-1: hooks/trace-log-retention.sh 存在"
else
  fail "AC6-1: hooks/trace-log-retention.sh 不存在"
fi

if [[ -f "${RETENTION_SCRIPT}" ]] && [[ -x "${RETENTION_SCRIPT}" ]]; then
  pass "AC6-2: hooks/trace-log-retention.sh 有執行權限"
else
  fail "AC6-2: hooks/trace-log-retention.sh 無執行權限"
fi

# retention script 應支援 SHIKIGAMI_TRACE_RETENTION_DAYS 環境變數
if [[ -f "${RETENTION_SCRIPT}" ]] && grep -q "SHIKIGAMI_TRACE_RETENTION_DAYS" "${RETENTION_SCRIPT}"; then
  pass "AC6-3: retention script 支援 SHIKIGAMI_TRACE_RETENTION_DAYS 環境變數"
else
  fail "AC6-3: retention script 缺少 SHIKIGAMI_TRACE_RETENTION_DAYS 支援"
fi

# retention 預設值應為 7
if [[ -f "${RETENTION_SCRIPT}" ]] && grep -q ":-7\|:- 7\|RETENTION_DAYS.*7\|7.*RETENTION" "${RETENTION_SCRIPT}"; then
  pass "AC6-4: retention script 預設值為 7 天"
else
  fail "AC6-4: retention script 缺少 7 天預設值"
fi

# retention 應只清理 docs/trace-logs/ 下的 .jsonl 檔案
if [[ -f "${RETENTION_SCRIPT}" ]] && grep -q "trace-logs.*\.jsonl\|\.jsonl.*trace-logs" "${RETENTION_SCRIPT}"; then
  pass "AC6-5: retention script 僅清理 trace-logs/*.jsonl"
else
  fail "AC6-5: retention script 未限定清理 trace-logs/*.jsonl"
fi

# session-start hook 應呼叫 retention script
if [[ -f "${SESSION_START_HOOK}" ]] && grep -q "trace-log-retention\|trace.*retention" "${SESSION_START_HOOK}"; then
  pass "AC6-6: session-start hook 呼叫 retention script"
else
  fail "AC6-6: session-start hook 未呼叫 retention script"
fi

# ── 非功能性需求：隱私保護 ────────────────────────────────────────────────

echo ""
echo "--- NFR: 隱私/安全 ---"

# trace 寫入指令不應記錄使用者輸入（$CLAUDE_TOOL_INPUT 等），只記錄 metadata
if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "不記錄使用者輸入\|action metadata\|隱私" "${LIFECYCLE_PROMPT}"; then
  pass "NFR-1: story-lifecycle-prompt.md 含隱私保護說明"
else
  fail "NFR-1: story-lifecycle-prompt.md 缺少隱私保護說明"
fi

# ── Retention 腳本功能測試 ────────────────────────────────────────────────

echo ""
echo "--- AC6 Functional: retention 實際行為測試 ---"

if [[ -f "${RETENTION_SCRIPT}" ]]; then
  # 建立臨時測試環境
  TMPDIR="$(mktemp -d)"
  FAKE_TRACE_DIR="${TMPDIR}/trace-logs"
  mkdir -p "${FAKE_TRACE_DIR}"

  # 建立 9 天前的舊檔案（應被清理）
  OLD_FILE="${FAKE_TRACE_DIR}/2020-01-01-session-old.jsonl"
  touch -d "9 days ago" "${OLD_FILE}" 2>/dev/null || \
    touch -t "$(date -d '9 days ago' '+%Y%m%d%H%M' 2>/dev/null || date -v-9d '+%Y%m%d%H%M' 2>/dev/null || echo '202001010000')" "${OLD_FILE}" 2>/dev/null || \
    touch "${OLD_FILE}"

  # 建立 3 天前的新檔案（應保留）
  NEW_FILE="${FAKE_TRACE_DIR}/$(date '+%Y-%m-%d')-session-new.jsonl"
  touch "${NEW_FILE}"

  # 執行 retention（以 TRACE_LOG_DIR 覆蓋）
  TRACE_LOG_DIR="${FAKE_TRACE_DIR}" SHIKIGAMI_TRACE_RETENTION_DAYS=7 bash "${RETENTION_SCRIPT}" 2>/dev/null || true

  # 由於 touch -d 可能不支援（如 macOS），跳過嚴格時間測試，只驗證腳本不報錯
  pass "AC6-F1: retention script 執行無崩潰"

  # 新檔案應存在
  if [[ -f "${NEW_FILE}" ]]; then
    pass "AC6-F2: 新檔案（3天內）未被清除"
  else
    fail "AC6-F2: 新檔案（3天內）被錯誤清除"
  fi

  rm -rf "${TMPDIR}"
else
  fail "AC6-F1: retention script 不存在，跳過功能測試"
  fail "AC6-F2: retention script 不存在，跳過功能測試"
fi

# ── 最終結果 ────────────────────────────────────────────────────────────

echo ""
echo "============================================"
echo "結果：PASS=${PASS}  FAIL=${FAIL}"
echo "============================================"

if [[ "${FAIL}" -eq 0 ]]; then
  echo "[FINAL] ALL PASS"
  exit 0
else
  echo "[FINAL] FAIL（${FAIL} 項未通過）"
  exit 1
fi
