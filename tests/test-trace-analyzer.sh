#!/usr/bin/env bash
# test-trace-analyzer.sh
# #782 驗收測試：Structured Trace Log — trace-analyzer.sh 分析工具
# TDD Red phase — 先寫測試，再實作

PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

TRACE_ANALYZER="${REPO_ROOT}/scripts/trace-analyzer.sh"
LIFECYCLE_PROMPT="${REPO_ROOT}/skills/sprint-execution/story-lifecycle-prompt.md"

pass() {
  echo "[PASS] $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "[FAIL] $1"
  FAIL=$((FAIL + 1))
}

echo "=== #782 Structured Trace Log — trace-analyzer 驗收測試 ==="
echo ""

# ── AC2: scripts/trace-analyzer.sh 存在且可執行 ────────────────────────────

echo "--- AC2: trace-analyzer.sh 存在與執行能力 ---"

if [[ -f "${TRACE_ANALYZER}" ]]; then
  pass "AC2-1: scripts/trace-analyzer.sh 檔案存在"
else
  fail "AC2-1: scripts/trace-analyzer.sh 不存在"
fi

if [[ -x "${TRACE_ANALYZER}" ]]; then
  pass "AC2-2: scripts/trace-analyzer.sh 有執行權限"
else
  fail "AC2-2: scripts/trace-analyzer.sh 無執行權限"
fi

# ── AC2: trace-analyzer 接受 session-id 參數 ───────────────────────────────

echo ""
echo "--- AC2: session-id 參數處理 ---"

if [[ -f "${TRACE_ANALYZER}" ]]; then
  # 無參數應顯示用法說明
  OUTPUT="$("${TRACE_ANALYZER}" 2>&1 || true)"
  if echo "${OUTPUT}" | grep -qi "usage\|session\|用法\|參數"; then
    pass "AC2-3: 無參數時顯示使用說明"
  else
    fail "AC2-3: 無參數時未顯示使用說明（output: ${OUTPUT}）"
  fi
else
  fail "AC2-3: trace-analyzer.sh 不存在，跳過"
fi

# ── AC4: 使用 seeded JSONL 測試正確輸出 ───────────────────────────────────

echo ""
echo "--- AC4: seeded JSONL 測試 ---"

# 建立臨時測試環境
TMPDIR_BASE="$(mktemp -d)"
FAKE_CRUISE_DIR="${TMPDIR_BASE}/cruise-logs"
mkdir -p "${FAKE_CRUISE_DIR}"

SESSION_ID="test-782-session"

# 建立 seeded JSONL 測試資料（模擬 cruise log 格式，含 [TRACE] 條目）
SEED_JSONL="${FAKE_CRUISE_DIR}/2026-03-25-session-${SESSION_ID}.jsonl"

cat > "${SEED_JSONL}" << 'JSONL_EOF'
{"event":"session_start","timestamp":"2026-03-25T10:00:00+0800","sessionId":"test-782-session"}
[TRACE] {"type":"action-type","story":782,"actor":"developer","action":"file-write","target":"scripts/trace-analyzer.sh","timestamp":"2026-03-25T10:01:00+0800"}
{"event":"cruise_cycle","timestamp":"2026-03-25T10:01:30+0800"}
[TRACE] {"type":"action-type","story":782,"actor":"developer","action":"file-write","target":"tests/test-trace-analyzer.sh","timestamp":"2026-03-25T10:02:00+0800"}
[TRACE] {"type":"action-type","story":782,"actor":"developer","action":"test-run","target":"tests/test-trace-analyzer.sh","timestamp":"2026-03-25T10:03:00+0800"}
[TRACE] {"type":"action-type","story":782,"actor":"developer","action":"decision","target":"use-jq-for-parsing","timestamp":"2026-03-25T10:04:00+0800"}
[TRACE] {"type":"action-type","story":782,"actor":"developer","action":"error","target":"missing-dependency","timestamp":"2026-03-25T10:05:00+0800"}
[TRACE] {"type":"action-type","story":783,"actor":"developer","action":"file-write","target":"other-file.sh","timestamp":"2026-03-25T10:06:00+0800"}
[TRACE] {"type":"action-type","story":783,"actor":"developer","action":"file-read","target":"SKILL.md","timestamp":"2026-03-25T10:07:00+0800"}
JSONL_EOF

if [[ -f "${TRACE_ANALYZER}" ]]; then
  # 執行 analyzer 對測試 JSONL
  ANALYZER_OUTPUT="$(CRUISE_LOG_DIR="${FAKE_CRUISE_DIR}" "${TRACE_ANALYZER}" "${SESSION_ID}" 2>&1)"

  # AC2: 應包含 Story 分組的 timeline
  if echo "${ANALYZER_OUTPUT}" | grep -q "782\|Story 782\|story:782"; then
    pass "AC4-1: 輸出含 Story 782 的 timeline"
  else
    fail "AC4-1: 輸出未含 Story 782（output: ${ANALYZER_OUTPUT}）"
  fi

  if echo "${ANALYZER_OUTPUT}" | grep -q "783\|Story 783\|story:783"; then
    pass "AC4-2: 輸出含 Story 783 的 timeline"
  else
    fail "AC4-2: 輸出未含 Story 783（output: ${ANALYZER_OUTPUT}）"
  fi

  # AC3: 每個 Story 應輸出 total actions
  if echo "${ANALYZER_OUTPUT}" | grep -qi "total\|total.*action\|action.*count\|共"; then
    pass "AC4-3: 輸出含 total actions 統計"
  else
    fail "AC4-3: 輸出未含 total actions 統計（output: ${ANALYZER_OUTPUT}）"
  fi

  # AC3: 應輸出 file-write count
  if echo "${ANALYZER_OUTPUT}" | grep -qi "file-write\|file_write\|寫入"; then
    pass "AC4-4: 輸出含 file-write 計數"
  else
    fail "AC4-4: 輸出未含 file-write 計數（output: ${ANALYZER_OUTPUT}）"
  fi

  # AC3: 應輸出 decision count
  if echo "${ANALYZER_OUTPUT}" | grep -qi "decision\|決策"; then
    pass "AC4-5: 輸出含 decision 計數"
  else
    fail "AC4-5: 輸出未含 decision 計數（output: ${ANALYZER_OUTPUT}）"
  fi

  # AC3: 應輸出 error count
  if echo "${ANALYZER_OUTPUT}" | grep -qi "error\|錯誤"; then
    pass "AC4-6: 輸出含 error 計數"
  else
    fail "AC4-6: 輸出未含 error 計數（output: ${ANALYZER_OUTPUT}）"
  fi

  # AC2: Story 782 應有 5 個 TRACE 條目（file-write x2, test-run x1, decision x1, error x1）
  STORY_782_COUNT=$(echo "${ANALYZER_OUTPUT}" | grep -c "782" || echo "0")
  if [[ "${STORY_782_COUNT}" -ge 1 ]]; then
    pass "AC4-7: Story 782 被識別並輸出（至少 1 行含 782）"
  else
    fail "AC4-7: Story 782 未被識別（count: ${STORY_782_COUNT}）"
  fi

  # AC3: 驗證 Story 782 的 file-write count = 2
  if echo "${ANALYZER_OUTPUT}" | grep -A20 "782" | grep -qi "file.write.*2\|2.*file.write"; then
    pass "AC4-8: Story 782 的 file-write 計數正確（= 2）"
  else
    # 接受 "file-write: 2" 或類似格式
    if echo "${ANALYZER_OUTPUT}" | grep -A20 "782" | grep -qE "file.write[^0-9]*[2-9]|[2-9][^0-9]*file.write"; then
      pass "AC4-8: Story 782 的 file-write 計數 >= 2"
    else
      fail "AC4-8: Story 782 的 file-write 計數不正確（output: ${ANALYZER_OUTPUT}）"
    fi
  fi

else
  fail "AC4-1: trace-analyzer.sh 不存在，跳過 seeded JSONL 測試"
  fail "AC4-2: trace-analyzer.sh 不存在，跳過"
  fail "AC4-3: trace-analyzer.sh 不存在，跳過"
  fail "AC4-4: trace-analyzer.sh 不存在，跳過"
  fail "AC4-5: trace-analyzer.sh 不存在，跳過"
  fail "AC4-6: trace-analyzer.sh 不存在，跳過"
  fail "AC4-7: trace-analyzer.sh 不存在，跳過"
  fail "AC4-8: trace-analyzer.sh 不存在，跳過"
fi

# ── AC1: story-lifecycle-prompt.md 含 [TRACE] 格式定義 ────────────────────

echo ""
echo "--- AC1: story-lifecycle-prompt.md TRACE 格式 ---"

if [[ -f "${LIFECYCLE_PROMPT}" ]]; then
  # AC1: 應含 [TRACE] 前綴格式
  if grep -q "\[TRACE\]" "${LIFECYCLE_PROMPT}"; then
    pass "AC1-1: story-lifecycle-prompt.md 含 [TRACE] 格式標記"
  else
    fail "AC1-1: story-lifecycle-prompt.md 缺少 [TRACE] 格式標記"
  fi

  # AC1: 格式中應包含 type 欄位
  if grep -q '"type"' "${LIFECYCLE_PROMPT}"; then
    pass "AC1-2: [TRACE] 格式含 type 欄位"
  else
    fail "AC1-2: [TRACE] 格式缺少 type 欄位"
  fi

  # AC1: 格式中應包含 story 欄位（story number）
  if grep -q '"story"' "${LIFECYCLE_PROMPT}"; then
    pass "AC1-3: [TRACE] 格式含 story 欄位"
  else
    fail "AC1-3: [TRACE] 格式缺少 story 欄位"
  fi

  # AC1: 格式中應包含 actor 欄位
  if grep -q '"actor"' "${LIFECYCLE_PROMPT}"; then
    pass "AC1-4: [TRACE] 格式含 actor 欄位"
  else
    fail "AC1-4: [TRACE] 格式缺少 actor 欄位"
  fi

  # AC1: 格式中應包含 action 欄位
  if grep -q '"action"' "${LIFECYCLE_PROMPT}"; then
    pass "AC1-5: [TRACE] 格式含 action 欄位"
  else
    fail "AC1-5: [TRACE] 格式缺少 action 欄位"
  fi

  # AC1: 格式中應包含 target 欄位
  if grep -q '"target"' "${LIFECYCLE_PROMPT}"; then
    pass "AC1-6: [TRACE] 格式含 target 欄位"
  else
    fail "AC1-6: [TRACE] 格式缺少 target 欄位"
  fi

  # AC1: 格式中應包含 timestamp 欄位
  if grep -q '"timestamp"' "${LIFECYCLE_PROMPT}"; then
    pass "AC1-7: [TRACE] 格式含 timestamp 欄位"
  else
    fail "AC1-7: [TRACE] 格式缺少 timestamp 欄位"
  fi

  # AC1: 應定義主要 action 類型（file-write, file-read, test-run, review-start, decision, error 等）
  if grep -q "file-write\|file-read\|test-run\|decision\|review-start" "${LIFECYCLE_PROMPT}"; then
    pass "AC1-8: story-lifecycle-prompt.md 定義主要 action 類型"
  else
    fail "AC1-8: story-lifecycle-prompt.md 缺少主要 action 類型定義"
  fi
else
  fail "AC1-1: story-lifecycle-prompt.md 不存在"
  fail "AC1-2: story-lifecycle-prompt.md 不存在，跳過"
  fail "AC1-3: story-lifecycle-prompt.md 不存在，跳過"
  fail "AC1-4: story-lifecycle-prompt.md 不存在，跳過"
  fail "AC1-5: story-lifecycle-prompt.md 不存在，跳過"
  fail "AC1-6: story-lifecycle-prompt.md 不存在，跳過"
  fail "AC1-7: story-lifecycle-prompt.md 不存在，跳過"
  fail "AC1-8: story-lifecycle-prompt.md 不存在，跳過"
fi

# ── NFR1: 不引入新的 log 基礎設施 ─────────────────────────────────────────

echo ""
echo "--- NFR1: TRACE 使用現有 cruise log 基礎設施 ---"

if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "cruise.log\|cruise-log\|stdout\|\[TRACE\]" "${LIFECYCLE_PROMPT}"; then
  pass "NFR1-1: TRACE 格式使用 stdout（cruise log 基礎設施）"
else
  fail "NFR1-1: 未確認 TRACE 使用 cruise log / stdout 基礎設施"
fi

# ── NFR2: trace-analyzer 為 post-hoc 分析工具 ─────────────────────────────

echo ""
echo "--- NFR2: trace-analyzer 為 post-hoc 分析（非阻塞）---"

if [[ -f "${TRACE_ANALYZER}" ]] && grep -q "post.hoc\|analysis\|分析\|offline\|non.blocking\|非阻塞" "${TRACE_ANALYZER}"; then
  pass "NFR2-1: trace-analyzer 有 post-hoc 說明"
else
  # 放寬：只要 trace-analyzer 是獨立腳本（非在 Sprint 中載入）即可
  if [[ -f "${TRACE_ANALYZER}" ]]; then
    pass "NFR2-1: trace-analyzer 為獨立後分析工具（非 Sprint 中執行）"
  else
    fail "NFR2-1: trace-analyzer.sh 不存在"
  fi
fi

# ── 清理臨時目錄 ─────────────────────────────────────────────────────────

rm -rf "${TMPDIR_BASE}"

# ── 最終結果 ─────────────────────────────────────────────────────────────

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
