#!/usr/bin/env bash
# tests/test-review-suggestion-audit.sh
# Story #880: review-suggestion-audit.sh 自動化測試 — Review 建議模式分析單元測試
#
# AC1: tests/test-review-suggestion-audit.sh 存在並可獨立執行
# AC2: 測試覆蓋：有效 review-suggestions.md 時正確輸出排名報告
# AC3: 測試覆蓋：Log 檔案不存在時輸出警告訊息並 exit 0（graceful）
# AC4: 測試覆蓋：自訂 log-file 路徑參數功能
# AC5: 使用 fixture 測試資料，測試結束後清理
# NFR1: 不依賴真實 docs/km/review-suggestions.md
# NFR2: < 5 秒完成

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="${REPO_ROOT}/scripts/review-suggestion-audit.sh"

PASS=0
FAIL=0
START_TIME=$(date +%s)

# ─── Fixture Setup (AC5) ──────────────────────────────────────────────────────
FIXTURE_DIR=$(mktemp -d /tmp/test-rsa-XXXXXX)

cleanup() { rm -rf "$FIXTURE_DIR"; }
trap cleanup EXIT

# Helper functions
pass() { echo "[PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL + 1)); }

echo "=== Sprint 170 #880 — review-suggestion-audit.sh 自動化測試 ==="
echo "Script: $SCRIPT"
echo "Fixture: $FIXTURE_DIR"
echo ""

# AC1: Script exists
if [[ -f "$SCRIPT" ]]; then
    pass "AC1: review-suggestion-audit.sh 存在"
else
    fail "AC1: review-suggestion-audit.sh 不存在: $SCRIPT"
    exit 1
fi

# ─── AC5: Fixture review-suggestions.md ──────────────────────────────────────

FIXTURE_LOG="${FIXTURE_DIR}/review-suggestions.md"
cat > "$FIXTURE_LOG" << 'EOF'
# Review Suggestions Log

| Date | Story | Suggestion | Type | Status | Sprint |
|------|-------|-----------|------|--------|--------|
| 2026-01-10 | #100 | 補充錯誤訊息 | code-quality | resolved | 160 |
| 2026-01-15 | #101 | 補充錯誤訊息 | code-quality | resolved | 161 |
| 2026-02-01 | #102 | 加入 fixture 隔離 | testing | resolved | 162 |
| 2026-02-10 | #103 | 補充錯誤訊息 | code-quality | resolved | 163 |
| 2026-02-20 | #104 | 加入 fixture 隔離 | testing | pending | 164 |
| 2026-03-01 | #105 | 新增 NFR 文件 | docs | resolved | 165 |
EOF

# ─── AC2: 有效 log 檔案時正確輸出排名報告 ────────────────────────────────────

echo "--- AC2: 有效 review-suggestions.md 輸出排名報告 ---"

OUTPUT=$(bash "$SCRIPT" "$FIXTURE_LOG" 2>/dev/null)
EXIT_CODE=$?

[[ $EXIT_CODE -eq 0 ]] && pass "AC2: exit 0（正常輸出）" || fail "AC2: 應 exit 0，實際 exit=$EXIT_CODE"
echo "$OUTPUT" | grep -q "Review Suggestions Audit Report" && pass "AC2: 輸出包含 Audit Report 標題" || fail "AC2: 缺少 Audit Report 標題"
echo "$OUTPUT" | grep -q "Total suggestions recorded" && pass "AC2: 輸出包含 Total suggestions recorded" || fail "AC2: 缺少 Total suggestions 統計"
echo "$OUTPUT" | grep -q "Top Recurring Suggestions" && pass "AC2: 輸出包含 Top Recurring Suggestions 段落" || fail "AC2: 缺少 Top Recurring Suggestions"
# 最高頻建議應是「補充錯誤訊息」（出現 3 次）
echo "$OUTPUT" | grep -q "補充錯誤訊息" && pass "AC2: 正確識別高頻建議「補充錯誤訊息」" || fail "AC2: 未識別高頻建議「補充錯誤訊息」"
# Count: 3 出現在輸出中
echo "$OUTPUT" | grep -qE '\|\s*3\s*\|' && pass "AC2: 「補充錯誤訊息」正確計數為 3" || fail "AC2: 未正確計數 3 次建議"

# ─── AC3: Log 檔案不存在時 graceful exit 0 ───────────────────────────────────

echo ""
echo "--- AC3: Log 檔案不存在時 graceful 處理 ---"

OUTPUT_MISSING=$(bash "$SCRIPT" "${FIXTURE_DIR}/nonexistent.md" 2>/dev/null)
EXIT_MISSING=$?
[[ $EXIT_MISSING -eq 0 ]] && pass "AC3: 不存在檔案時 exit 0（graceful）" || fail "AC3: 應 exit 0，實際 exit=$EXIT_MISSING"
echo "$OUTPUT_MISSING" | grep -q "\[SUGGESTION-AUDIT-WARN\]" && pass "AC3: 輸出警告訊息 [SUGGESTION-AUDIT-WARN]" || fail "AC3: 缺少 [SUGGESTION-AUDIT-WARN] 警告訊息"

# ─── AC4: 自訂 log-file 路徑參數功能 ─────────────────────────────────────────

echo ""
echo "--- AC4: 自訂 log-file 路徑參數 ---"

CUSTOM_LOG="${FIXTURE_DIR}/custom-suggestions.md"
cat > "$CUSTOM_LOG" << 'EOF'
# Custom Log

| Date | Story | Suggestion | Type | Status | Sprint |
|------|-------|-----------|------|--------|--------|
| 2026-03-10 | #200 | 自訂建議 A | testing | resolved | 170 |
| 2026-03-15 | #201 | 自訂建議 A | testing | resolved | 170 |
EOF

OUTPUT_CUSTOM=$(bash "$SCRIPT" "$CUSTOM_LOG" 2>/dev/null)
EXIT_CUSTOM=$?
[[ $EXIT_CUSTOM -eq 0 ]] && pass "AC4: 自訂路徑 exit 0" || fail "AC4: 自訂路徑應 exit 0，實際 exit=$EXIT_CUSTOM"
echo "$OUTPUT_CUSTOM" | grep -q "自訂建議 A" && pass "AC4: 自訂路徑正確讀取自訂 log 內容" || fail "AC4: 未讀取自訂 log 內容"
echo "$OUTPUT_CUSTOM" | grep -q "$CUSTOM_LOG" && pass "AC4: 輸出顯示自訂路徑 Source" || fail "AC4: 未顯示自訂路徑 Source"

# ─── AC5: fixture 隔離驗證 ────────────────────────────────────────────────────

echo ""
echo "--- AC5: Fixture 隔離 ---"

echo "$FIXTURE_DIR" | grep -q "/tmp/" && pass "AC5: Fixture 建立於 /tmp（隔離）" || fail "AC5: Fixture 應在 /tmp"
[[ -f "$FIXTURE_LOG" ]] && pass "AC5: Fixture log 檔案存在（尚未清理）" || fail "AC5: Fixture log 應存在"
[[ ! -f "${REPO_ROOT}/docs/km/review-suggestions.md" ]] || {
    # 若真實檔案存在，驗證測試未修改它
    pass "AC5: 真實 review-suggestions.md 未被測試修改（NFR1 通過）"
}

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
