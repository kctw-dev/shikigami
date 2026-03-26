#!/usr/bin/env bash
# test-complexity-trend.sh — #848 複雜度趨勢追蹤測試
# AC1: scripts/complexity-trend.sh 存在，執行後 append 至 docs/km/complexity-trend.csv
# AC2: CSV 含欄位：日期, SKILL_COUNT, AGENT_COUNT, HOOK_COUNT, TOTAL_LINES
# AC3: 輸出簡易趨勢（最近 5 次量測的增減百分比）
# AC4: 對應測試存在（本檔）
# NFR1: CSV 可被 Sprint Review 直接引用

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

check() {
  local desc="$1"
  local result="$2"
  if [[ "$result" == "pass" ]]; then
    echo "PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== test-complexity-trend.sh ==="

SCRIPT="$REPO_ROOT/scripts/complexity-trend.sh"
CSV="$REPO_ROOT/docs/km/complexity-trend.csv"
TMP_CSV=$(mktemp)

cleanup() {
  rm -f "$TMP_CSV"
}
trap cleanup EXIT

# AC1: 腳本存在
if [[ -f "$SCRIPT" ]]; then
  check "AC1: scripts/complexity-trend.sh 存在" "pass"
else
  check "AC1: scripts/complexity-trend.sh 存在" "fail"
fi

# AC2: CSV 欄位驗證 — 執行腳本後 CSV 含正確 header
OVERRIDE_CSV="$TMP_CSV"
if COMPLEXITY_TREND_CSV="$OVERRIDE_CSV" bash "$SCRIPT" --no-trend 2>/dev/null; then
  if [[ -f "$OVERRIDE_CSV" ]]; then
    HEADER=$(head -1 "$OVERRIDE_CSV" 2>/dev/null || true)
    if echo "$HEADER" | grep -q "date" && \
       echo "$HEADER" | grep -q "SKILL_COUNT" && \
       echo "$HEADER" | grep -q "AGENT_COUNT" && \
       echo "$HEADER" | grep -q "HOOK_COUNT" && \
       echo "$HEADER" | grep -q "TOTAL_LINES"; then
      check "AC2: CSV header 包含所有必要欄位" "pass"
    else
      check "AC2: CSV header 包含所有必要欄位 (got: $HEADER)" "fail"
    fi
    # 驗證有一筆資料行
    DATA_LINES=$(tail -n +2 "$OVERRIDE_CSV" | grep -c "^[0-9]" || true)
    if [[ "$DATA_LINES" -ge 1 ]]; then
      check "AC2: CSV 包含至少一筆資料行" "pass"
    else
      check "AC2: CSV 包含至少一筆資料行" "fail"
    fi
  else
    check "AC2: CSV 檔案被建立" "fail"
    check "AC2: CSV 包含至少一筆資料行" "fail"
  fi
else
  check "AC2: 腳本執行成功" "fail"
  check "AC2: CSV 包含至少一筆資料行" "fail"
fi

# AC3: 趨勢輸出 — 需要至少 2 筆資料才能計算趨勢，先 append 兩筆再呼叫
TMP_TREND_CSV=$(mktemp)
# 寫入 2 筆模擬歷史資料
cat > "$TMP_TREND_CSV" << 'CSVEOF'
date,SKILL_COUNT,AGENT_COUNT,HOOK_COUNT,TOTAL_LINES
2026-03-25,30,8,29,9800
2026-03-26,31,8,30,10049
CSVEOF
TREND_OUTPUT=$(COMPLEXITY_TREND_CSV="$TMP_TREND_CSV" bash "$SCRIPT" --trend-only 2>/dev/null || true)
rm -f "$TMP_TREND_CSV"
if echo "$TREND_OUTPUT" | grep -qiE "trend|%|increase|decrease|增|減|TOTAL_LINES" 2>/dev/null; then
  check "AC3: 趨勢輸出包含變化資訊" "pass"
else
  check "AC3: 趨勢輸出包含變化資訊 (got: $(echo "$TREND_OUTPUT" | head -3))" "fail"
fi

# AC4: 測試自身存在
if [[ -f "$REPO_ROOT/tests/test-complexity-trend.sh" ]]; then
  check "AC4: tests/test-complexity-trend.sh 存在" "pass"
else
  check "AC4: tests/test-complexity-trend.sh 存在" "fail"
fi

# NFR1: CSV append 冪等性 — 同日期執行兩次，不重複追加
TMP_IDEM_CSV=$(mktemp)
cat > "$TMP_IDEM_CSV" << 'CSVEOF'
date,SKILL_COUNT,AGENT_COUNT,HOOK_COUNT,TOTAL_LINES
CSVEOF
COMPLEXITY_TREND_CSV="$TMP_IDEM_CSV" bash "$SCRIPT" --no-trend 2>/dev/null || true
LINES_AFTER_1=$(wc -l < "$TMP_IDEM_CSV")
COMPLEXITY_TREND_CSV="$TMP_IDEM_CSV" bash "$SCRIPT" --no-trend 2>/dev/null || true
LINES_AFTER_2=$(wc -l < "$TMP_IDEM_CSV")
rm -f "$TMP_IDEM_CSV"
if [[ "$LINES_AFTER_1" -eq "$LINES_AFTER_2" ]]; then
  check "NFR1: 同日期重複執行不重複追加（冪等）" "pass"
else
  check "NFR1: 同日期重複執行不重複追加（冪等）" "fail"
fi

echo ""
echo "Results: PASS=${PASS} FAIL=${FAIL}"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
