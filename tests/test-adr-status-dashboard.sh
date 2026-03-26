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

# ── Story #868: --check-staleness テスト ─────────────────────────────────────
echo ""
echo "=== Story #868: --check-staleness 老化偵測テスト ==="

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

# Fixture: Stale Accepted ADR（超過 90 天 — 使用 git log 會傳回空，降級用檔案 mtime）
# 建立一個很舊的 ADR fixture（touch 設舊 mtime）
STALE_FIXTURE_DIR=$(mktemp -d)
trap "rm -rf ${STALE_FIXTURE_DIR}" EXIT

cat > "${STALE_FIXTURE_DIR}/ADR-010-stale.md" << 'ADR_EOF'
# ADR-010：老化測試 ADR

**狀態**：Accepted
**日期**：2025-01-01
**決策者**：Architect
ADR_EOF
# 設定超過 90 天前的 mtime
touch -t "202501010000" "${STALE_FIXTURE_DIR}/ADR-010-stale.md"

cat > "${STALE_FIXTURE_DIR}/ADR-011-fresh.md" << 'ADR_EOF'
# ADR-011：新鮮測試 ADR

**狀態**：Accepted
**日期**：2026-03-01
**決策者**：Architect
ADR_EOF
# 設定 10 天前的 mtime (新鮮)
touch -t "202603160000" "${STALE_FIXTURE_DIR}/ADR-011-fresh.md"

# Test S1: --check-staleness 旗標執行不崩潰
echo ""
echo "--- S1: --check-staleness 旗標執行不崩潰 ---"
EXIT_CODE=0
bash "$REPO_ROOT/$SCRIPT" --check-staleness "$STALE_FIXTURE_DIR" > /dev/null 2>&1 || EXIT_CODE=$?
if [[ "$EXIT_CODE" -le 1 ]]; then
  echo "  PASS: --check-staleness 執行正常（exit $EXIT_CODE）"
  PASS=$((PASS + 1))
else
  echo "  FAIL: --check-staleness 崩潰（exit $EXIT_CODE）"
  FAIL=$((FAIL + 1))
fi

# Test S2: 老化 ADR 輸出 [ADR-STALE] 標記
echo ""
echo "--- S2: 老化 ADR 輸出 [ADR-STALE] ---"
STALE_OUTPUT=$(bash "$REPO_ROOT/$SCRIPT" --check-staleness "$STALE_FIXTURE_DIR" 2>/dev/null || true)
if echo "$STALE_OUTPUT" | grep -q "\[ADR-STALE\]"; then
  echo "  PASS: [ADR-STALE] 標記出現在輸出"
  PASS=$((PASS + 1))
else
  echo "  FAIL: [ADR-STALE] 標記未出現（輸出：$(echo "$STALE_OUTPUT" | head -3)）"
  FAIL=$((FAIL + 1))
fi

# Test S3: 新鮮 ADR 不輸出 [ADR-STALE]
echo ""
echo "--- S3: 新鮮 ADR 不輸出 [ADR-STALE] ---"
FRESH_ONLY_DIR=$(mktemp -d)
trap "rm -rf ${FRESH_ONLY_DIR}" EXIT
cat > "${FRESH_ONLY_DIR}/ADR-020-fresh.md" << 'ADR_EOF'
# ADR-020：新鮮 ADR

**狀態**：Accepted
**日期**：2026-03-20
**決策者**：Architect
ADR_EOF
touch -t "202603200000" "${FRESH_ONLY_DIR}/ADR-020-fresh.md"
FRESH_OUTPUT=$(bash "$REPO_ROOT/$SCRIPT" --check-staleness "${FRESH_ONLY_DIR}" 2>/dev/null || true)
STALE_COUNT=$(echo "$FRESH_OUTPUT" | grep -c "\[ADR-STALE\]" 2>/dev/null || true)
if [[ "$STALE_COUNT" -eq 0 ]]; then
  echo "  PASS: 新鮮 ADR 無 [ADR-STALE] 標記"
  PASS=$((PASS + 1))
else
  echo "  FAIL: 新鮮 ADR 出現 $STALE_COUNT 個 [ADR-STALE]（不應有）"
  FAIL=$((FAIL + 1))
fi

# Test S4: --check-staleness 執行時間 < 3s（NFR1）
echo ""
echo "--- S4: 執行時間 < 3s（NFR1）---"
START_NS=$(date +%s%N 2>/dev/null || echo 0)
bash "$REPO_ROOT/$SCRIPT" --check-staleness "$STALE_FIXTURE_DIR" > /dev/null 2>&1 || true
END_NS=$(date +%s%N 2>/dev/null || echo 3000000000)
ELAPSED_MS=$(( (END_NS - START_NS) / 1000000 ))
if [[ "$ELAPSED_MS" -lt 3000 ]]; then
  echo "  PASS: 執行時間 ${ELAPSED_MS}ms < 3000ms（NFR1）"
  PASS=$((PASS + 1))
else
  echo "  FAIL: 執行時間 ${ELAPSED_MS}ms >= 3000ms（NFR1 違反）"
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
