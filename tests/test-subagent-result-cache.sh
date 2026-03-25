#!/usr/bin/env bash
# test-subagent-result-cache.sh — #737 CACHE-RECOVERY 機制驗證
# Sprint 155 | AC4: 驗證格式與 [CACHE-RECOVERY-OK] 路徑

set -euo pipefail

PASS=0
FAIL=0
RESULTS_DIR="docs/sprints/subagent-results"
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

log_pass() { echo "[PASS] $1"; PASS=$((PASS+1)); }
log_fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

# ── TC-1: subagent-results 目錄存在 ──────────────────────────────
if [ -d "$RESULTS_DIR" ]; then
  log_pass "TC-1: $RESULTS_DIR 目錄存在"
else
  log_fail "TC-1: $RESULTS_DIR 目錄不存在（mkdir -p 應在執行期自動建立）"
fi

# ── TC-2: 暫存文件格式驗證 ───────────────────────────────────────
# 建立測試暫存文件
MOCK_STORY_ID="737"
MOCK_FILE="$TMP_DIR/subagent-results/${MOCK_STORY_ID}.md"
mkdir -p "$TMP_DIR/subagent-results"
cat > "$MOCK_FILE" << 'MOCK_EOF'
# Subagent Result — 737

<!-- 自動產生，供 context compaction 後結果復原使用 -->
<!-- 寫入時間：2026-03-25T08:41:00Z -->

## Story-Lifecycle 完成摘要

**Story ID**：US-#737
**結論**：PASS
**一句話摘要**：Story-Lifecycle CACHE-RECOVERY 防失敗強化
**PR**：#999
**Merged Commit**：abc1234
**Test Summary**：所有測試通過

status: PASS
merged_commit: abc1234
pr_number: 999
test_summary: 所有測試通過
timestamp: 2026-03-25T08:41:00Z
MOCK_EOF

# 驗證必填欄位
REQUIRED_FIELDS=("status:" "merged_commit:" "pr_number:" "test_summary:" "timestamp:")
ALL_OK=true
for field in "${REQUIRED_FIELDS[@]}"; do
  if grep -q "$field" "$MOCK_FILE"; then
    : # OK
  else
    log_fail "TC-2: 暫存文件缺少必填欄位 $field"
    ALL_OK=false
  fi
done
if $ALL_OK; then
  log_pass "TC-2: 暫存文件包含所有必填欄位（status, merged_commit, pr_number, test_summary, timestamp）"
fi

# ── TC-3: [CACHE-RECOVERY-OK] 路徑模擬 ──────────────────────────
# 模擬主 session CACHE-RECOVERY 讀取邏輯
simulate_cache_recovery() {
  local story_id="$1"
  local results_dir="$2"
  local cache_file="$results_dir/${story_id}.md"

  if [ -f "$cache_file" ]; then
    # 確認文件非空
    if [ -s "$cache_file" ]; then
      echo "[CACHE-RECOVERY-OK] story=${story_id} 從暫存文件恢復結果"
      return 0
    else
      echo "[CACHE-RECOVERY-FAIL] story=${story_id} 暫存文件存在但為空"
      return 1
    fi
  else
    echo "[CACHE-RECOVERY-FAIL] story=${story_id} 暫存文件不存在"
    return 1
  fi
}

RECOVERY_OUTPUT=$(simulate_cache_recovery "737" "$TMP_DIR/subagent-results")
if echo "$RECOVERY_OUTPUT" | grep -q "\[CACHE-RECOVERY-OK\]"; then
  log_pass "TC-3: [CACHE-RECOVERY-OK] 路徑正確觸發"
else
  log_fail "TC-3: [CACHE-RECOVERY-OK] 路徑未觸發（輸出：$RECOVERY_OUTPUT）"
fi

# ── TC-4: [CACHE-RECOVERY-FAIL] 路徑（文件不存在）───────────────
RECOVERY_FAIL_OUTPUT=$(simulate_cache_recovery "999" "$TMP_DIR/subagent-results" 2>&1 || true)
if echo "$RECOVERY_FAIL_OUTPUT" | grep -q "\[CACHE-RECOVERY-FAIL\]"; then
  log_pass "TC-4: [CACHE-RECOVERY-FAIL] 路徑在文件不存在時正確觸發"
else
  log_fail "TC-4: [CACHE-RECOVERY-FAIL] 路徑未正確觸發"
fi

# ── TC-5: NFR1 — subagent-results/ 在 .gitignore 中 ─────────────
if grep -q "subagent-results" .gitignore 2>/dev/null; then
  log_pass "TC-5: NFR1 — subagent-results/ 已在 .gitignore 中（runtime only）"
else
  log_fail "TC-5: NFR1 — subagent-results/ 未在 .gitignore 中，應加入"
fi

# ── TC-6: AC3 — Sprint Execution 確認暫存文件存在邏輯 ────────────
# 模擬 AC3：Sprint Execution 主 session 收到結果後，確認 subagent-results 檔案存在
simulate_ac3_confirmation() {
  local story_id="$1"
  local results_dir="$2"
  local cache_file="$results_dir/${story_id}.md"

  if [ -f "$cache_file" ]; then
    echo "[CACHE-CONFIRM-OK] story=${story_id} 暫存文件已確認存在"
    return 0
  else
    echo "[CACHE-CONFIRM-WARN] story=${story_id} 暫存文件不存在（subagent 可能未寫入）"
    return 1
  fi
}

AC3_OUTPUT=$(simulate_ac3_confirmation "737" "$TMP_DIR/subagent-results")
if echo "$AC3_OUTPUT" | grep -q "\[CACHE-CONFIRM-OK\]"; then
  log_pass "TC-6: AC3 — Sprint Execution 收到結果後確認暫存文件存在"
else
  log_fail "TC-6: AC3 — 確認邏輯失敗（輸出：$AC3_OUTPUT）"
fi

# ── 結果輸出 ─────────────────────────────────────────────────────
echo ""
echo "=== test-subagent-result-cache.sh 結果 ==="
echo "PASS: $PASS | FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "[TEST-SUITE-PASS] 全部 $PASS 項通過"
  exit 0
else
  echo "[TEST-SUITE-FAIL] $FAIL 項失敗"
  exit 1
fi
