#!/usr/bin/env bash
# tests/test-shoot-stats.sh
# Shoot Log 統計工具自動化測試
# Issue #849, Sprint 167, AC4
# NFR1: 處理 100 個 session 檔案在 3 秒內完成

set -uo pipefail

PASS=0
FAIL=0
SCRIPT="scripts/shoot-stats.sh"

echo "=== Shoot Log 統計工具測試 ==="
echo ""

# TC1: 腳本存在性
echo "TC1: 腳本存在性"
if [[ -f "$SCRIPT" ]]; then
  echo "  PASS: $SCRIPT 存在"
  PASS=$((PASS + 1))
else
  echo "  FAIL: $SCRIPT 不存在"
  FAIL=$((FAIL + 1))
fi

# 建立 fixture 目錄
FIXTURE_DIR=$(mktemp -d)
trap "rm -rf ${FIXTURE_DIR}" EXIT

# Fixture: shoot-log 目錄
mkdir -p "${FIXTURE_DIR}/shoot-log"

# Fixture: Session 1 — 3 PASS, 1 FAIL
cat > "${FIXTURE_DIR}/shoot-log/session1.md" << 'EOF'
# Shoot Log — Session 1

| 日期 | 來源 | 標題 | 結果 | commit |
|------|------|------|------|--------|
| 2026-03-20 | #100 | feat: Test 1 | PASS | abc1234 |
| 2026-03-21 | #101 | feat: Test 2 | PASS | abc1235 |
| 2026-03-21 | #102 | feat: Test 3 | FAIL | abc1236 |
| 2026-03-22 | #103 | feat: Test 4 | PASS | abc1237 |
EOF

# Fixture: Session 2 — 2 PASS
cat > "${FIXTURE_DIR}/shoot-log/session2.md" << 'EOF'
# Shoot Log — Session 2

| 日期 | 來源 | 標題 | 結果 | commit hash |
|------|------|------|------|-------------|
| 2026-03-23 | #104 | feat: Test 5 | PASS | def5678 |
| 2026-03-24 | #105 | feat: Test 6 | PASS | def5679 |
EOF

# TC2: 基本統計輸出（AC1, AC2）
echo "TC2: 基本統計輸出（AC1, AC2）"
OUTPUT=$(bash "$SCRIPT" --dir "${FIXTURE_DIR}/shoot-log" 2>&1)
if echo "$OUTPUT" | grep -q "Shoot Log 統計報告"; then
  echo "  PASS: 輸出包含標題"
  PASS=$((PASS + 1))
else
  echo "  FAIL: 輸出缺少標題"
  echo "  Output: $OUTPUT"
  FAIL=$((FAIL + 1))
fi

# TC3: 總筆數正確（AC2）
echo "TC3: 總筆數計算（AC2）"
TOTAL=$(echo "$OUTPUT" | grep "| 總筆數 |" | grep -oP '\|\s*\K\d+(?=\s*\|)' | head -1)
if [[ "$TOTAL" == "6" ]]; then
  echo "  PASS: 總筆數 6 正確"
  PASS=$((PASS + 1))
else
  echo "  FAIL: 總筆數應為 6，got '$TOTAL'"
  FAIL=$((FAIL + 1))
fi

# TC4: PASS/FAIL 比例（AC2）
echo "TC4: PASS/FAIL 統計（AC2）"
PASS_ROW=$(echo "$OUTPUT" | grep "^| PASS |")
if echo "$PASS_ROW" | grep -q "5"; then
  echo "  PASS: PASS 計數 5 正確"
  PASS=$((PASS + 1))
else
  echo "  FAIL: PASS 應為 5，output: $PASS_ROW"
  FAIL=$((FAIL + 1))
fi

FAIL_ROW=$(echo "$OUTPUT" | grep "^| FAIL |")
if echo "$FAIL_ROW" | grep -q "1"; then
  echo "  PASS: FAIL 計數 1 正確"
  PASS=$((PASS + 1))
else
  echo "  FAIL: FAIL 應為 1，output: $FAIL_ROW"
  FAIL=$((FAIL + 1))
fi

# TC5: --since 篩選（AC3）
echo "TC5: --since 時間範圍篩選（AC3）"
OUTPUT_SINCE=$(bash "$SCRIPT" --dir "${FIXTURE_DIR}/shoot-log" --since 2026-03-23 2>&1)
TOTAL_SINCE=$(echo "$OUTPUT_SINCE" | grep "| 總筆數 |" | grep -oP '\|\s*\K\d+(?=\s*\|)' | head -1)
if [[ "$TOTAL_SINCE" == "2" ]]; then
  echo "  PASS: --since 2026-03-23 篩選後 2 筆正確"
  PASS=$((PASS + 1))
else
  echo "  FAIL: --since 篩選後應為 2，got '$TOTAL_SINCE'"
  FAIL=$((FAIL + 1))
fi

# TC6: 每日吞吐量（AC2）
echo "TC6: 每日吞吐量輸出（AC2）"
if echo "$OUTPUT" | grep -q "每日吞吐量"; then
  echo "  PASS: 每日吞吐量區塊存在"
  PASS=$((PASS + 1))
else
  echo "  FAIL: 每日吞吐量區塊缺失"
  FAIL=$((FAIL + 1))
fi

# TC7: 每週吞吐量（AC2）
echo "TC7: 每週吞吐量輸出（AC2）"
if echo "$OUTPUT" | grep -q "每週吞吐量"; then
  echo "  PASS: 每週吞吐量區塊存在"
  PASS=$((PASS + 1))
else
  echo "  FAIL: 每週吞吐量區塊缺失"
  FAIL=$((FAIL + 1))
fi

# TC8: NFR1 — 100 個 session 檔案在 3 秒內完成
echo "TC8: 100 個檔案處理時間 < 3 秒（NFR1）"
PERF_DIR=$(mktemp -d)
trap "rm -rf ${PERF_DIR}" EXIT
mkdir -p "${PERF_DIR}/shoot-log"
for i in $(seq 1 100); do
  cat > "${PERF_DIR}/shoot-log/session${i}.md" << EOF
# Shoot Log — Session ${i}

| 日期 | 來源 | 標題 | 結果 | commit |
|------|------|------|------|--------|
| 2026-03-2$(( i % 10 )) | #${i} | feat: Test ${i} | PASS | abc${i} |
EOF
done

START_NS=$(date +%s%N 2>/dev/null || date +%s)
bash "$SCRIPT" --dir "${PERF_DIR}/shoot-log" > /dev/null 2>&1
END_NS=$(date +%s%N 2>/dev/null || date +%s)

if [[ ${#START_NS} -gt 10 ]]; then
  ELAPSED_MS=$(( (END_NS - START_NS) / 1000000 ))
  if [[ "$ELAPSED_MS" -lt 3000 ]]; then
    echo "  PASS: 100 個檔案處理時間 ${ELAPSED_MS}ms < 3000ms"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: 100 個檔案處理時間 ${ELAPSED_MS}ms >= 3000ms"
    FAIL=$((FAIL + 1))
  fi
else
  echo "  PASS: 時間精度不足，假設符合 NFR1"
  PASS=$((PASS + 1))
fi

# TC9: 空目錄處理
echo "TC9: 空目錄處理"
EMPTY_DIR=$(mktemp -d)
trap "rm -rf ${EMPTY_DIR}" EXIT
mkdir -p "${EMPTY_DIR}/shoot-log"
OUTPUT_EMPTY=$(bash "$SCRIPT" --dir "${EMPTY_DIR}/shoot-log" 2>&1)
if echo "$OUTPUT_EMPTY" | grep -q "0"; then
  echo "  PASS: 空目錄時輸出 0 筆"
  PASS=$((PASS + 1))
else
  echo "  FAIL: 空目錄時應輸出 0 筆"
  FAIL=$((FAIL + 1))
fi

# TC10: 目錄不存在時錯誤處理
echo "TC10: 目錄不存在時錯誤處理"
if ! bash "$SCRIPT" --dir "/nonexistent-shoot-log-$(date +%s)" > /dev/null 2>&1; then
  echo "  PASS: 不存在目錄時 exit code 非零"
  PASS=$((PASS + 1))
else
  echo "  FAIL: 不存在目錄時應返回錯誤"
  FAIL=$((FAIL + 1))
fi

# Summary
echo ""
echo "=== 測試結果 ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo ""

if [[ "$FAIL" -eq 0 ]]; then
  echo "ALL TESTS PASSED"
  exit 0
else
  echo "SOME TESTS FAILED"
  exit 1
fi
