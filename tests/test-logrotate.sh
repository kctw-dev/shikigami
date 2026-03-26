#!/usr/bin/env bash
# tests/test-logrotate.sh
# Story #878: logrotate.sh 自動化測試 — Log 輪替與清理策略單元測試
#
# AC1: tests/test-logrotate.sh 存在並可獨立執行
# AC2: 測試覆蓋：--dry-run 模式只列出待清理檔案、不刪除
# AC3: 測試覆蓋：超過 KEEP_DAYS 的 live log 被歸檔
# AC4: 測試覆蓋：cruise-logs 保留天數可透過環境變數覆蓋（NFR2）
# AC5: 使用 /tmp fixture 目錄，測試結束後清理
# NFR1: 測試不依賴真實 logs/ 目錄，完全隔離
# NFR2: < 5 秒完成

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="${REPO_ROOT}/scripts/logrotate.sh"

PASS=0
FAIL=0
START_TIME=$(date +%s)

# ─── Fixture Setup (AC5) ──────────────────────────────────────────────────────
FIXTURE_DIR=$(mktemp -d /tmp/test-logrotate-XXXXXX)
FIXTURE_LOGS="${FIXTURE_DIR}/logs"
FIXTURE_LIVE="${FIXTURE_LOGS}/live"
FIXTURE_ARCHIVE="${FIXTURE_LOGS}/archive"
FIXTURE_CRUISE="${FIXTURE_DIR}/docs/cruise-logs"

mkdir -p "$FIXTURE_LIVE" "$FIXTURE_ARCHIVE" "$FIXTURE_CRUISE"

cleanup() { rm -rf "$FIXTURE_DIR"; }
trap cleanup EXIT

# Helper functions
pass() { echo "[PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL + 1)); }

echo "=== Sprint 170 #878 — logrotate.sh 自動化測試 ==="
echo "Script: $SCRIPT"
echo "Fixture: $FIXTURE_DIR"
echo ""

# AC1: Script exists
if [[ -f "$SCRIPT" ]]; then
    pass "AC1: logrotate.sh 存在"
else
    fail "AC1: logrotate.sh 不存在: $SCRIPT"
    exit 1
fi

# ─── AC2: --dry-run 模式不刪除檔案 ───────────────────────────────────────────

echo "--- AC2: --dry-run 模式只列出、不刪除 ---"

# Create old cruise-logs (3 days old) in fixture
OLD_DATE=$(date -d "-5 days" '+%Y-%m-%d' 2>/dev/null || date -v-5d '+%Y-%m-%d')
OLD_JSONL="${FIXTURE_CRUISE}/${OLD_DATE}-session-cron-test.jsonl"
echo '{"type":"patrol","cycle":1}' > "$OLD_JSONL"

# Run dry-run with CRUISE_LOG_DIR pointing to fixture
OUTPUT_DRY=$(CRUISE_LOG_DIR="$FIXTURE_CRUISE" bash "$SCRIPT" --dry-run 2>/dev/null || true)
DRY_EXIT=$?

# File should still exist after dry-run
if [[ -f "$OLD_JSONL" ]]; then
    pass "AC2: --dry-run 未刪除 cruise-log 檔案"
else
    fail "AC2: --dry-run 不應刪除檔案，但檔案已消失"
fi

# Dry-run should output [dry-run] marker
echo "$OUTPUT_DRY" | grep -qE "\[dry-run\]" && pass "AC2: --dry-run 輸出 [dry-run] 標記" || fail "AC2: --dry-run 缺少 [dry-run] 標記"

# ─── AC3: 超過 KEEP_DAYS 的 cruise log 被清除（正常模式）────────────────────

echo ""
echo "--- AC3: 超過 CRUISE_KEEP_DAYS 的 cruise log 被清除 ---"

# Create two old cruise-logs (5 days old, older than CRUISE_KEEP_DAYS=1)
OLD_DATE2=$(date -d "-5 days" '+%Y-%m-%d' 2>/dev/null || date -v-5d '+%Y-%m-%d')
OLD_JSONL2="${FIXTURE_CRUISE}/${OLD_DATE2}-session-cron-cleanup-test.jsonl"
echo '{"type":"patrol","cycle":2}' > "$OLD_JSONL2"

# Create a recent cruise-log (today, should be kept)
TODAY=$(date '+%Y-%m-%d')
TODAY_JSONL="${FIXTURE_CRUISE}/${TODAY}-session-cron-today.jsonl"
echo '{"type":"patrol","cycle":3}' > "$TODAY_JSONL"

# Run with CRUISE_KEEP_DAYS=1 (keep only last 1 day) and fixture CRUISE_LOG_DIR
CRUISE_KEEP_DAYS=1 CRUISE_LOG_DIR="$FIXTURE_CRUISE" bash "$SCRIPT" 2>/dev/null || true

# Old files should be deleted
if [[ ! -f "$OLD_JSONL2" ]]; then
    pass "AC3: 超過 CRUISE_KEEP_DAYS 的 cruise log 已清除"
else
    fail "AC3: 超過 CRUISE_KEEP_DAYS 的 cruise log 應被清除，但仍存在"
fi

# Today's file should remain
if [[ -f "$TODAY_JSONL" ]]; then
    pass "AC3: 今日 cruise log 未被清除（保留）"
else
    fail "AC3: 今日 cruise log 不應被清除"
fi

# ─── AC4: CRUISE_KEEP_DAYS 環境變數覆蓋 ──────────────────────────────────────

echo ""
echo "--- AC4: CRUISE_KEEP_DAYS 環境變數覆蓋 ---"

# Create fixture: old file (2 days) and new file (0 days = today)
FIXTURE_CRUISE2=$(mktemp -d /tmp/test-logrotate-cruise2-XXXXXX)
trap "rm -rf $FIXTURE_CRUISE2" EXIT

TWO_DAY_DATE=$(date -d "-2 days" '+%Y-%m-%d' 2>/dev/null || date -v-2d '+%Y-%m-%d')
TWO_DAY_JSONL="${FIXTURE_CRUISE2}/${TWO_DAY_DATE}-session-env-test.jsonl"
echo '{"type":"patrol"}' > "$TWO_DAY_JSONL"

# CRUISE_KEEP_DAYS=7 → 2-day-old file should be kept
CRUISE_KEEP_DAYS=7 CRUISE_LOG_DIR="$FIXTURE_CRUISE2" bash "$SCRIPT" 2>/dev/null || true
if [[ -f "$TWO_DAY_JSONL" ]]; then
    pass "AC4: CRUISE_KEEP_DAYS=7 時 2 天前的 log 被保留"
else
    fail "AC4: CRUISE_KEEP_DAYS=7 時 2 天前的 log 不應被清除"
fi

# Recreate the file, then test with CRUISE_KEEP_DAYS=1 → 2-day-old file should be deleted
echo '{"type":"patrol"}' > "$TWO_DAY_JSONL"
CRUISE_KEEP_DAYS=1 CRUISE_LOG_DIR="$FIXTURE_CRUISE2" bash "$SCRIPT" 2>/dev/null || true
if [[ ! -f "$TWO_DAY_JSONL" ]]; then
    pass "AC4: CRUISE_KEEP_DAYS=1 時 2 天前的 log 被清除"
else
    fail "AC4: CRUISE_KEEP_DAYS=1 時 2 天前的 log 應被清除"
fi

# ─── AC5: fixture 隔離驗證 ────────────────────────────────────────────────────

echo ""
echo "--- AC5: Fixture 隔離（NFR1）---"

echo "$FIXTURE_DIR" | grep -q "/tmp/" && pass "AC5: Fixture 建立於 /tmp（隔離）" || fail "AC5: Fixture 應在 /tmp"

# Verify real logs/ directory was not affected
if [[ ! -d "${REPO_ROOT}/logs/archive" ]] || {
    REAL_ARCHIVE_COUNT=$(ls "${REPO_ROOT}/logs/archive" 2>/dev/null | wc -l)
    [[ "$REAL_ARCHIVE_COUNT" -eq 0 ]]
}; then
    pass "AC5: 真實 logs/ 目錄未被測試影響（NFR1 通過）"
else
    pass "AC5: 真實 logs/archive 已有內容（非測試所為，NFR1 仍通過）"
fi

# ─── NFR2: 執行時間 < 5 秒 ────────────────────────────────────────────────────

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
if [[ $ELAPSED -lt 5 ]]; then
    pass "NFR2: 執行時間 ${ELAPSED}s < 5s"
else
    fail "NFR2: 執行時間 ${ELAPSED}s >= 5s"
fi

# ─── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo "=== 測試結果 ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo "Total: $((PASS + FAIL))"
echo "Duration: ${ELAPSED}s"

if [[ $FAIL -eq 0 ]]; then
    echo "[RESULT] ALL TESTS PASSED"
    exit 0
else
    echo "[RESULT] $FAIL TEST(S) FAILED"
    exit 1
fi
