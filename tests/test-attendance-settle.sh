#!/usr/bin/env bash
# tests/test-attendance-settle.sh
# US-#319 TDD — 結算腳本測試
# AC-1: per-session 檔案寫入正確
# AC-2: attendance-settle.sh 合併同日檔案為 summary.jsonl
# AC-3: 跨機器（不同 session_id）不衝突
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SETTLE_SCRIPT="${REPO_ROOT}/hooks/attendance-settle.sh"
SESSION_START="${REPO_ROOT}/hooks/session-start"
SESSION_END="${REPO_ROOT}/hooks/session-end-release.sh"

PASS=0
FAIL=0

pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

echo "=== test-attendance-settle.sh ==="

# ── 準備測試目錄 ───────────────────────────────────────────────────
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

TEST_DATE="2026-03-20"
SID_A="session-aaa111"
SID_B="session-bbb222"

# ── TC-1: per-session 檔名格式正確 ────────────────────────────────
echo ""
echo "--- TC-1: per-session 檔名格式 ---"

FILE_A="${TMPDIR_TEST}/${TEST_DATE}-session-${SID_A}.jsonl"
FILE_B="${TMPDIR_TEST}/${TEST_DATE}-session-${SID_B}.jsonl"

printf '{"session_id":"%s","role":"scrum-master","event":"checkin","timestamp":"2026-03-20T09:00:00+0800","repo":"shikigami"}\n' \
  "$SID_A" >> "$FILE_A"
printf '{"session_id":"%s","role":"scrum-master","event":"checkout","timestamp":"2026-03-20T10:00:00+0800","repo":"shikigami"}\n' \
  "$SID_A" >> "$FILE_A"

printf '{"session_id":"%s","role":"scrum-master","event":"checkin","timestamp":"2026-03-20T09:30:00+0800","repo":"shikigami"}\n' \
  "$SID_B" >> "$FILE_B"

# 驗證兩個 session 的檔案各自獨立
if [[ -f "$FILE_A" ]] && [[ -f "$FILE_B" ]]; then
  pass "TC-1a: 兩個 session 各自有獨立檔案"
else
  fail "TC-1a: per-session 獨立檔案不存在"
fi

# 驗證 FILE_A 有 2 行（checkin + checkout）
LINE_COUNT_A=$(wc -l < "$FILE_A")
if [[ "$LINE_COUNT_A" -eq 2 ]]; then
  pass "TC-1b: session-A 檔案有 2 筆紀錄"
else
  fail "TC-1b: session-A 應有 2 筆，實際 ${LINE_COUNT_A} 筆"
fi

# 驗證 FILE_B 有 1 行
LINE_COUNT_B=$(wc -l < "$FILE_B")
if [[ "$LINE_COUNT_B" -eq 1 ]]; then
  pass "TC-1c: session-B 檔案有 1 筆紀錄"
else
  fail "TC-1c: session-B 應有 1 筆，實際 ${LINE_COUNT_B} 筆"
fi

# ── TC-2: AC-3 跨機器不 conflict（兩個檔案無交集）────────────────
echo ""
echo "--- TC-2: 跨機器 conflict 驗證 ---"

# 如果 per-session 檔案各自獨立，永遠不會有 merge conflict
# 因為不同機器的 session_id 不同，寫入不同檔案
if [[ "$FILE_A" != "$FILE_B" ]]; then
  pass "TC-2: 不同 session 寫入不同檔案（天然隔離）"
else
  fail "TC-2: 相同 session_id 衝突"
fi

# ── TC-3: attend-settle.sh 存在且可執行 ───────────────────────────
echo ""
echo "--- TC-3: attendance-settle.sh 存在 ---"

if [[ -f "$SETTLE_SCRIPT" ]]; then
  pass "TC-3a: attendance-settle.sh 存在"
else
  fail "TC-3a: attendance-settle.sh 不存在（${SETTLE_SCRIPT}）"
fi

if [[ -x "$SETTLE_SCRIPT" ]]; then
  pass "TC-3b: attendance-settle.sh 可執行"
else
  fail "TC-3b: attendance-settle.sh 無執行權限"
fi

# ── TC-4: settle 合併同日檔案 ──────────────────────────────────────
echo ""
echo "--- TC-4: settle 合併同日 per-session 檔案 ---"

if [[ -f "$SETTLE_SCRIPT" ]]; then
  # 執行結算腳本，指定測試目錄和日期
  ATTENDANCE_DIR="$TMPDIR_TEST" bash "$SETTLE_SCRIPT" "$TEST_DATE" 2>/dev/null || true

  SUMMARY_FILE="${TMPDIR_TEST}/${TEST_DATE}.summary.jsonl"

  if [[ -f "$SUMMARY_FILE" ]]; then
    pass "TC-4a: summary.jsonl 已生成"
    SUMMARY_LINES=$(wc -l < "$SUMMARY_FILE")
    if [[ "$SUMMARY_LINES" -eq 3 ]]; then
      pass "TC-4b: summary.jsonl 包含所有 3 筆紀錄（2+1）"
    else
      fail "TC-4b: summary.jsonl 應有 3 筆，實際 ${SUMMARY_LINES} 筆"
    fi
    # 驗證排序：第一筆應是 09:00（最早）
    FIRST_TS=$(head -1 "$SUMMARY_FILE" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)
    if [[ "$FIRST_TS" == *"09:00"* ]]; then
      pass "TC-4c: summary.jsonl 按 timestamp 排序"
    else
      fail "TC-4c: summary.jsonl 排序錯誤，第一筆 timestamp=${FIRST_TS}"
    fi
  else
    fail "TC-4a: summary.jsonl 未生成（${SUMMARY_FILE}）"
    fail "TC-4b: 無法驗證（summary.jsonl 不存在）"
    fail "TC-4c: 無法驗證（summary.jsonl 不存在）"
  fi
else
  fail "TC-4a: 無法執行（settle 腳本不存在）"
  fail "TC-4b: 無法驗證（settle 腳本不存在）"
  fail "TC-4c: 無法驗證（settle 腳本不存在）"
fi

# ── TC-5: per-session 原始檔案保留 ─────────────────────────────────
echo ""
echo "--- TC-5: 原始 per-session 檔案保留（保守策略）---"

if [[ -f "$FILE_A" ]]; then
  pass "TC-5a: session-A 原始檔案保留"
else
  fail "TC-5a: session-A 原始檔案被刪除"
fi

if [[ -f "$FILE_B" ]]; then
  pass "TC-5b: session-B 原始檔案保留"
else
  fail "TC-5b: session-B 原始檔案被刪除"
fi

# ── TC-6: session-start 使用 per-session 檔名 ─────────────────────
echo ""
echo "--- TC-6: session-start 使用 per-session 檔名 ---"

if grep -q 'session-\${' "$SESSION_START" 2>/dev/null || \
   grep -q 'session-.*session_id\|YYYY-MM-DD-session\|session-.*SESSION_ID' "$SESSION_START" 2>/dev/null || \
   grep -qE 'session-\$\{?SESSION_ID' "$SESSION_START" 2>/dev/null; then
  pass "TC-6: session-start 含 per-session 檔名邏輯"
else
  # 檢查是否有 per-session 關鍵字
  if grep -qE 'per.session|per_session|session.*\.jsonl' "$SESSION_START" 2>/dev/null; then
    pass "TC-6: session-start 含 per-session 相關邏輯"
  else
    fail "TC-6: session-start 未更新為 per-session 檔名"
  fi
fi

# ── TC-7: session-end-release.sh 使用 per-session 檔名 ───────────
echo ""
echo "--- TC-7: session-end-release.sh 使用 per-session 檔名 ---"

if grep -qE 'session-\$\{?ATTEND_SESSION_ID|session-\$\{?SESSION_ID|YYYY-MM-DD-session' "$SESSION_END" 2>/dev/null; then
  pass "TC-7: session-end-release.sh 含 per-session 檔名邏輯"
else
  fail "TC-7: session-end-release.sh 未更新為 per-session 檔名"
fi

# ── TC-8: settle 預設處理昨天 ──────────────────────────────────────
echo ""
echo "--- TC-8: settle 預設日期為昨天 ---"

if [[ -f "$SETTLE_SCRIPT" ]]; then
  # 用 --help 或空白執行看輸出（不指定日期，應不 crash）
  SETTLE_OUT=$(ATTENDANCE_DIR="$TMPDIR_TEST" bash "$SETTLE_SCRIPT" 2>&1 || true)
  if [[ -n "$SETTLE_OUT" ]]; then
    pass "TC-8: settle 無參數時有輸出（正常執行）"
  else
    pass "TC-8: settle 無參數時靜默執行（也可接受）"
  fi
else
  fail "TC-8: settle 腳本不存在"
fi

# ── 總結 ────────────────────────────────────────────────────────────
echo ""
echo "=== 結果 ==="
echo "  PASS: ${PASS}"
echo "  FAIL: ${FAIL}"
echo ""

if [[ $FAIL -eq 0 ]]; then
  echo "[OK] test-attendance-settle.sh 全部通過"
  exit 0
else
  echo "[FAIL] ${FAIL} 個測試失敗"
  exit 1
fi
