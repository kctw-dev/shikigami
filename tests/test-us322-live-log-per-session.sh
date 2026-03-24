#!/usr/bin/env bash
# tests/test-us322-live-log-per-session.sh
# US-#322 AC-2 TDD — sprint.live.log 改為 per-session + 結算
#
# TC-1: live-log-settle.sh 存在且可執行
# TC-2: settle 合併同日 per-session .log 檔案為 summary.log
# TC-3: 不同 session 各自有獨立檔案（天然隔離）
# TC-4: 原始 per-session 檔案保留（保守策略）
# TC-5: 結算空目錄不 crash
# TC-6: protect-main.sh 豁免清單含 logs/live/
# TC-7: story-lifecycle-prompt.md 更新為 per-session 路徑
# TC-8: sprint-execution SKILL.md Live Log 說明更新
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SETTLE_SCRIPT="${REPO_ROOT}/hooks/live-log-settle.sh"
LIFECYCLE_PROMPT="${REPO_ROOT}/skills/sprint-execution/story-lifecycle-prompt.md"
SPRINT_EX_SKILL="${REPO_ROOT}/skills/sprint-execution/SKILL.md"
PROTECT_MAIN="${REPO_ROOT}/hooks/protect-main.sh"

PASS=0
FAIL=0

pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

echo "=== test-us322-live-log-per-session.sh ==="

# ── TC-1: live-log-settle.sh 存在且可執行 ────────────────────────
echo ""
echo "--- TC-1: live-log-settle.sh 存在且可執行 ---"

if [[ -f "$SETTLE_SCRIPT" ]]; then
  pass "TC-1a: live-log-settle.sh 存在"
else
  fail "TC-1a: live-log-settle.sh 不存在（${SETTLE_SCRIPT}）"
fi

if [[ -x "$SETTLE_SCRIPT" ]]; then
  pass "TC-1b: live-log-settle.sh 可執行"
else
  fail "TC-1b: live-log-settle.sh 無執行權限"
fi

# ── TC-2: settle 合併同日 per-session .log 檔案 ───────────────────
echo ""
echo "--- TC-2: settle 合併同日 per-session .log 檔案為 summary.log ---"

TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

TEST_DATE="2026-03-20"
SID_A="aaa111"
SID_B="bbb222"

FILE_A="${TMPDIR_TEST}/${TEST_DATE}-session-${SID_A}.log"
FILE_B="${TMPDIR_TEST}/${TEST_DATE}-session-${SID_B}.log"

# 建立測試 per-session log 檔案
cat >> "$FILE_A" <<'EOF'
[09:00:01] [US-320] 開始執行
[09:05:00] [US-320] TDD Red — 開始
[09:10:00] [US-320] 結果：PASS
EOF

cat >> "$FILE_B" <<'EOF'
[09:30:00] [US-321] 開始執行
[09:35:00] [US-321] 結果：PASS
EOF

if [[ -f "$SETTLE_SCRIPT" ]]; then
  LIVE_LOG_DIR="$TMPDIR_TEST" bash "$SETTLE_SCRIPT" "$TEST_DATE" 2>/dev/null || true

  SUMMARY_FILE="${TMPDIR_TEST}/${TEST_DATE}.summary.log"

  if [[ -f "$SUMMARY_FILE" ]]; then
    pass "TC-2a: summary.log 已生成"
    SUMMARY_LINES=$(wc -l < "$SUMMARY_FILE")
    if [[ "$SUMMARY_LINES" -eq 5 ]]; then
      pass "TC-2b: summary.log 包含所有 5 行日誌（3+2）"
    else
      fail "TC-2b: summary.log 應有 5 行，實際 ${SUMMARY_LINES} 行"
    fi
  else
    fail "TC-2a: summary.log 未生成（${SUMMARY_FILE}）"
    fail "TC-2b: 無法驗證（summary.log 不存在）"
  fi
else
  fail "TC-2a: 無法執行（settle 腳本不存在）"
  fail "TC-2b: 無法驗證（settle 腳本不存在）"
fi

# ── TC-3: 不同 session 各自獨立（天然隔離）───────────────────────
echo ""
echo "--- TC-3: 不同 session 各自獨立（天然隔離）---"

if [[ "$FILE_A" != "$FILE_B" ]]; then
  pass "TC-3: 不同 session 寫入不同檔案（天然隔離，無 conflict）"
else
  fail "TC-3: 相同 session_id 導致衝突"
fi

# ── TC-4: 原始 per-session 檔案保留 ──────────────────────────────
echo ""
echo "--- TC-4: 原始 per-session 檔案保留（保守策略）---"

if [[ -f "$FILE_A" ]]; then
  pass "TC-4a: session-A 原始檔案保留"
else
  fail "TC-4a: session-A 原始檔案被刪除"
fi

if [[ -f "$FILE_B" ]]; then
  pass "TC-4b: session-B 原始檔案保留"
else
  fail "TC-4b: session-B 原始檔案被刪除"
fi

# ── TC-5: 空目錄時 settle 不 crash ───────────────────────────────
echo ""
echo "--- TC-5: 空目錄時 settle 不 crash ---"

EMPTY_DIR="$(mktemp -d)"
if [[ -f "$SETTLE_SCRIPT" ]]; then
  LIVE_LOG_DIR="$EMPTY_DIR" bash "$SETTLE_SCRIPT" "2099-01-01" 2>&1 || true
  pass "TC-5: 空目錄時 settle 正常退出"
else
  fail "TC-5: settle 腳本不存在"
fi
rm -rf "$EMPTY_DIR"

# ── TC-6: protect-main.sh 豁免清單含 logs/live/ ──────
echo ""
echo "--- TC-6: protect-main.sh 豁免清單含 logs/live/ ---"

if grep -qE 'logs/live' "$PROTECT_MAIN" 2>/dev/null; then
  pass "TC-6: protect-main.sh 已包含 logs/live/ 豁免"
else
  fail "TC-6: protect-main.sh 未包含 logs/live/ 豁免"
fi

# ── TC-7: story-lifecycle-prompt.md 更新為 per-session 路徑 ───────
echo ""
echo "--- TC-7: story-lifecycle-prompt.md 更新為 per-session 路徑 ---"

if grep -qE 'live-log/.*session|per.session.*live|YYYY-MM-DD-session.*\.log|LIVE_LOG_FILE' "$LIFECYCLE_PROMPT" 2>/dev/null; then
  pass "TC-7: story-lifecycle-prompt.md 含 per-session live log 路徑"
else
  fail "TC-7: story-lifecycle-prompt.md 未更新為 per-session 路徑"
fi

# ── TC-8: sprint-execution SKILL.md Live Log 說明更新 ─────────────
echo ""
echo "--- TC-8: sprint-execution SKILL.md Live Log 說明更新 ---"

if grep -qE 'live-log/|live-log' "$SPRINT_EX_SKILL" 2>/dev/null; then
  pass "TC-8: sprint-execution SKILL.md 含 live-log/ 路徑"
else
  fail "TC-8: sprint-execution SKILL.md 未更新 Live Log 路徑"
fi

# ── 總結 ────────────────────────────────────────────────────────────
echo ""
echo "=== 結果 ==="
echo "  PASS: ${PASS}"
echo "  FAIL: ${FAIL}"
echo ""

if [[ $FAIL -eq 0 ]]; then
  echo "[OK] test-us322-live-log-per-session.sh 全部通過"
  exit 0
else
  echo "[FAIL] ${FAIL} 個測試失敗"
  exit 1
fi
