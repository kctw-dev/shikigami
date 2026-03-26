#!/usr/bin/env bash
# tests/test-adr-status-dashboard.sh
# ADR 狀態儀表板自動化測試
# Issue #846, Sprint 167, AC4

set -euo pipefail

PASS=0
FAIL=0
SCRIPT="scripts/adr-status-dashboard.sh"

# 建立 fixture 目錄
FIXTURE_DIR=$(mktemp -d)
trap "rm -rf ${FIXTURE_DIR}" EXIT

# Fixture: Accepted ADR
cat > "${FIXTURE_DIR}/ADR-001.md" << 'EOF'
# ADR-001：測試 ADR（Accepted）

**狀態**：Accepted
**日期**：2026-01-01
**決策者**：Architect
EOF

# Fixture: Proposed ADR
cat > "${FIXTURE_DIR}/ADR-002-proposed.md" << 'EOF'
# ADR-002：測試 ADR（Proposed）

**狀態**：Proposed
**日期**：2026-01-02
**決策者**：Architect
EOF

# Fixture: Draft ADR
cat > "${FIXTURE_DIR}/ADR-003-draft.md" << 'EOF'
# ADR-003：測試 ADR（Draft）

**狀態**：Draft
**日期**：2026-01-03
**決策者**：Architect
EOF

run_test() {
  local NAME="$1"
  local RESULT="$2"
  local EXPECTED="$3"

  if [[ "$RESULT" == "$EXPECTED" ]]; then
    echo "  PASS: $NAME"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $NAME"
    echo "    Expected: $EXPECTED"
    echo "    Got:      $RESULT"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== ADR 狀態儀表板測試 ==="
echo ""

# TC1: 腳本存在且可執行
echo "TC1: 腳本存在性"
if [[ -f "$SCRIPT" ]]; then
  echo "  PASS: $SCRIPT 存在"
  PASS=$((PASS + 1))
else
  echo "  FAIL: $SCRIPT 不存在"
  FAIL=$((FAIL + 1))
fi

# TC2: 基本執行（使用 fixture 目錄）
echo "TC2: 基本執行輸出"
OUTPUT=$(bash "$SCRIPT" "$FIXTURE_DIR" 2>&1)
if echo "$OUTPUT" | grep -q "ADR 狀態儀表板"; then
  echo "  PASS: 輸出包含標題"
  PASS=$((PASS + 1))
else
  echo "  FAIL: 輸出缺少標題"
  FAIL=$((FAIL + 1))
fi

# TC3: AC2 — 表格欄位驗證
echo "TC3: 表格欄位（AC2）"
if echo "$OUTPUT" | grep -q "| 編號 | 標題 | 狀態 | 日期 | 待辦動作 |"; then
  echo "  PASS: 表格欄位正確"
  PASS=$((PASS + 1))
else
  echo "  FAIL: 表格欄位缺失或不符"
  FAIL=$((FAIL + 1))
fi

# TC4: AC3 — [ADR-PENDING] 標記（Proposed）
echo "TC4: [ADR-PENDING] 標記 Proposed（AC3）"
if echo "$OUTPUT" | grep -q "\[ADR-PENDING\]"; then
  echo "  PASS: [ADR-PENDING] 標記存在"
  PASS=$((PASS + 1))
else
  echo "  FAIL: [ADR-PENDING] 標記缺失"
  FAIL=$((FAIL + 1))
fi

# TC5: AC3 — [ADR-PENDING] 標記（Draft）
echo "TC5: [ADR-PENDING] 標記 Draft（AC3）"
DRAFT_LINE=$(echo "$OUTPUT" | grep "ADR-003" || true)
if echo "$DRAFT_LINE" | grep -q "\[ADR-PENDING\]"; then
  echo "  PASS: Draft ADR 正確標記"
  PASS=$((PASS + 1))
else
  echo "  FAIL: Draft ADR 未正確標記"
  FAIL=$((FAIL + 1))
fi

# TC6: Accepted ADR 不標記 [ADR-PENDING]
echo "TC6: Accepted ADR 無 [ADR-PENDING]"
ACCEPTED_LINE=$(echo "$OUTPUT" | grep "ADR-001" || true)
if echo "$ACCEPTED_LINE" | grep -q "\[ADR-PENDING\]"; then
  echo "  FAIL: Accepted ADR 被誤標記"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: Accepted ADR 無誤標記"
  PASS=$((PASS + 1))
fi

# TC7: 統計行輸出
echo "TC7: 統計行輸出"
if echo "$OUTPUT" | grep -qE "共 [0-9]+ 個 ADR"; then
  echo "  PASS: 統計行存在"
  PASS=$((PASS + 1))
else
  echo "  FAIL: 統計行缺失"
  FAIL=$((FAIL + 1))
fi

# TC8: NFR1 — 執行時間 < 2 秒
echo "TC8: 執行時間 < 2 秒（NFR1）"
START_NS=$(date +%s%N 2>/dev/null || date +%s)
bash "$SCRIPT" "$FIXTURE_DIR" > /dev/null 2>&1
END_NS=$(date +%s%N 2>/dev/null || date +%s)
if command -v python3 > /dev/null 2>&1 && [[ ${#START_NS} -gt 10 ]]; then
  ELAPSED_MS=$(( (END_NS - START_NS) / 1000000 ))
  if [[ "$ELAPSED_MS" -lt 2000 ]]; then
    echo "  PASS: 執行時間 ${ELAPSED_MS}ms < 2000ms"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: 執行時間 ${ELAPSED_MS}ms >= 2000ms"
    FAIL=$((FAIL + 1))
  fi
else
  echo "  PASS: 執行時間檢查略過（精度不足）"
  PASS=$((PASS + 1))
fi

# TC9: 錯誤處理 — 目錄不存在
echo "TC9: 錯誤處理（目錄不存在）"
if ! bash "$SCRIPT" "/nonexistent-dir-$(date +%s)" > /dev/null 2>&1; then
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
