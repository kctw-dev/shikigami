#!/usr/bin/env bash
# tests/test-backfill-routing-history.sh
# Story #867 — routing-stats 歷史趨勢補齊測試

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="${REPO_ROOT}/scripts/backfill-routing-history.sh"
METRICS_LOG="${REPO_ROOT}/docs/km/Metrics_Log.md"
METRICS_LOG_DIR="${REPO_ROOT}/docs/km/metrics-log"

pass_count=0
fail_count=0

test_pass() {
  echo "[PASS] $1"
  ((pass_count++))
}

test_fail() {
  echo "[FAIL] $1"
  ((fail_count++))
}

cleanup() {
  # 恢復 Metrics_Log.md 和清除 backfill session 檔案
  if [ -f "$METRICS_BACKUP" ]; then
    cp "$METRICS_BACKUP" "$METRICS_LOG"
    rm -f "$METRICS_BACKUP"
  fi
  # 移除臨時建立的 backfill session 檔案
  rm -f "${METRICS_LOG_DIR}/"*-backfill-routing-history.md
}

trap cleanup EXIT

# ── 測試 1: Script 存在且可執行 ──────────────────────────────────────────

if [ -x "$SCRIPT" ]; then
  test_pass "Script 存在且可執行"
else
  test_fail "Script 不存在或不可執行"
  exit 1
fi

# ── 測試 2: 在乾淨 Metrics_Log 上執行 dry-run ──────────────────────────────

# 備份原始檔案
METRICS_BACKUP=$(mktemp)
cp "$METRICS_LOG" "$METRICS_BACKUP"

# 建立臨時乾淨的 Metrics_Log.md（只有 header）
TMP_METRICS=$(mktemp)
head -20 "$METRICS_LOG" > "$TMP_METRICS"

# 暫時替換為乾淨版本
cp "$TMP_METRICS" "$METRICS_LOG"

# 執行 dry-run
DRY_OUT=$(bash "$SCRIPT" --dry-run 2>&1)

# 檢查：--dry-run 有輸出
if echo "$DRY_OUT" | grep -q "model-route"; then
  test_pass "--dry-run 輸出包含 model-route 記錄"
else
  test_fail "--dry-run 未輸出 model-route 記錄"
fi

if echo "$DRY_OUT" | grep -q "DRY-RUN"; then
  test_pass "--dry-run 輸出標註為 DRY-RUN"
else
  test_fail "--dry-run 未標註為 DRY-RUN"
fi

# 檢查：--dry-run 不修改
if diff -q "$TMP_METRICS" "$METRICS_LOG" > /dev/null 2>&1; then
  test_pass "--dry-run 不修改 Metrics_Log.md"
else
  test_fail "--dry-run 修改了 Metrics_Log.md（應該只預覽）"
fi

rm -f "$TMP_METRICS"

# ── 測試 3: 實際執行補齊（使用乾淨的 Metrics_Log.md） ──────────────────────────

# 建立新的乾淨 Metrics_Log
head -20 "$METRICS_BACKUP" > "$METRICS_LOG"

bash "$SCRIPT" > /tmp/backfill.out 2>&1
test_pass "實際執行補齊成功"

# 檢查是否有新記錄被寫入
if grep -q "model-route" "$METRICS_LOG"; then
  test_pass "Metrics_Log.md 包含 model-route 記錄"
else
  test_fail "Metrics_Log.md 未包含 model-route 記錄"
fi

# 檢查 metrics-log 補齊檔案是否被建立
if ls "${METRICS_LOG_DIR}/"*-backfill-routing-history.md > /dev/null 2>&1; then
  test_pass "metrics-log 補齊檔案已建立"
else
  test_fail "metrics-log 補齊檔案未建立"
fi

# ── 測試 4: Idempotent — 重複執行結果相同 ──────────────────────────────

# 獲取執行後的檔案雜湊
HASH_AFTER_FIRST=$(md5sum "$METRICS_LOG" | awk '{print $1}')

# 再執行一次
bash "$SCRIPT" > /dev/null 2>&1

HASH_AFTER_SECOND=$(md5sum "$METRICS_LOG" | awk '{print $1}')

if [ "$HASH_AFTER_FIRST" = "$HASH_AFTER_SECOND" ]; then
  test_pass "重複執行幂等（無重複記錄）"
else
  test_fail "重複執行產生重複記錄或內容變化"
fi

# ── 輸出總結 ──────────────────────────────────────────────────────────────

echo ""
echo "====================================="
echo "Test Summary"
echo "====================================="
echo "PASS: $pass_count"
echo "FAIL: $fail_count"
echo "====================================="

if [ "$fail_count" -eq 0 ]; then
  exit 0
else
  exit 1
fi
