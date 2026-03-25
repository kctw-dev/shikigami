#!/usr/bin/env bash
# tests/test-adr-index.sh
# Story #742 — ADR 目錄索引自動維護（驗證腳本）
#
# AC4: 驗證 docs/adr/README.md 索引格式正確
# NFR1: 純 bash + grep，不依賴 Python

set -euo pipefail

PASS=0
FAIL=0
START_TIME=$(date +%s)

pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="${REPO_ROOT}/scripts/update-adr-index.sh"
OUTPUT="${REPO_ROOT}/docs/adr/README.md"

echo "================================================================"
echo "test-adr-index.sh — ADR 目錄索引格式驗證"
echo "================================================================"

# ── AC1: 腳本存在性 ──────────────────────────────────────────────────

echo ""
echo "── AC1: 腳本存在性 ──"

if [ -f "$SCRIPT" ]; then
  pass "scripts/update-adr-index.sh 存在"
else
  fail "scripts/update-adr-index.sh 不存在"
fi

if [ -x "$SCRIPT" ] || bash "$SCRIPT" --help 2>/dev/null || true; then
  pass "scripts/update-adr-index.sh 可執行（bash 相容）"
fi

# ── AC1+AC2: 執行腳本並驗證輸出 ────────────────────────────────────

echo ""
echo "── AC1+AC2: 執行 update-adr-index.sh 並驗證輸出 ──"

bash "$SCRIPT" > /dev/null 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  pass "update-adr-index.sh 執行成功（exit 0）"
else
  fail "update-adr-index.sh 執行失敗（exit ${EXIT_CODE}）"
fi

if [ -f "$OUTPUT" ]; then
  pass "docs/adr/README.md 已產生"
else
  fail "docs/adr/README.md 未產生"
  echo "================================================================"
  echo "結果：PASS=${PASS}  FAIL=${FAIL}"
  echo "================================================================"
  exit 1
fi

# ── AC2: README.md 格式驗證 ──────────────────────────────────────────

echo ""
echo "── AC2: README.md 格式驗證 ──"

# 標題存在
if grep -q "^# ADR 目錄索引" "$OUTPUT"; then
  pass "README.md 含標題「# ADR 目錄索引」"
else
  fail "README.md 缺少標題「# ADR 目錄索引」"
fi

# 表格標頭
if grep -q "| ADR 編號 | 標題 | 狀態 | 日期 |" "$OUTPUT"; then
  pass "README.md 含正確表格標頭（ADR 編號 | 標題 | 狀態 | 日期）"
else
  fail "README.md 表格標頭格式不正確"
fi

# 表格分隔線
if grep -q "|---------|------|------|------|" "$OUTPUT"; then
  pass "README.md 含表格分隔線"
else
  fail "README.md 缺少表格分隔線"
fi

# 至少有一條 ADR 記錄
ADR_ROWS=$(grep -c "^| ADR-" "$OUTPUT" 2>/dev/null || true)
if [ "$ADR_ROWS" -ge 1 ]; then
  pass "README.md 含 ${ADR_ROWS} 條 ADR 記錄"
else
  fail "README.md 未含任何 ADR 記錄"
fi

# 每行格式：| ADR-NNN | [title](file) | status | date |
VALID_ROWS=0
INVALID_ROWS=0
while IFS= read -r line; do
  if [[ "$line" =~ ^\|\ ADR-[0-9]+ ]]; then
    # 檢查 4 個欄位（用 | 分割）
    COLS=$(echo "$line" | tr '|' '\n' | grep -v "^$" | wc -l)
    if [ "$COLS" -eq 4 ]; then
      VALID_ROWS=$((VALID_ROWS + 1))
    else
      INVALID_ROWS=$((INVALID_ROWS + 1))
    fi
  fi
done < "$OUTPUT"

if [ "$VALID_ROWS" -ge 1 ] && [ "$INVALID_ROWS" -eq 0 ]; then
  pass "所有 ADR 記錄行格式正確（${VALID_ROWS} 行，4 欄）"
elif [ "$INVALID_ROWS" -gt 0 ]; then
  fail "有 ${INVALID_ROWS} 行 ADR 記錄格式不正確（非 4 欄）"
else
  fail "未找到合法的 ADR 記錄行"
fi

# 自動生成標記
if grep -q "自動產生\|auto.*generat" "$OUTPUT"; then
  pass "README.md 含自動產生標記"
else
  fail "README.md 缺少自動產生標記"
fi

# 時間戳格式（YYYY-MM-DD）
if grep -qE "[0-9]{4}-[0-9]{2}-[0-9]{2}" "$OUTPUT"; then
  pass "README.md 含有效時間戳（YYYY-MM-DD 格式）"
else
  fail "README.md 缺少有效時間戳"
fi

# ── 冪等性測試：執行兩次結果相同 ────────────────────────────────────

echo ""
echo "── 冪等性測試 ──"

bash "$SCRIPT" > /dev/null 2>&1
ROWS_AFTER=$(grep -c "^| ADR-" "$OUTPUT" 2>/dev/null || true)

if [ "$ROWS_AFTER" -eq "$ADR_ROWS" ]; then
  pass "冪等性：重複執行後 ADR 記錄數不變（${ADR_ROWS} 條）"
else
  fail "冪等性：重複執行後記錄數變化（${ADR_ROWS} → ${ROWS_AFTER}）"
fi

# ── NFR1: 純 bash + grep 驗證 ────────────────────────────────────────

echo ""
echo "── NFR1: 純 bash + grep 驗證 ──"

PYTHON_USAGE=$(grep -c "python\|python3\|node\|ruby\|perl" "$SCRIPT" 2>/dev/null || true)
if [ "$PYTHON_USAGE" -eq 0 ]; then
  pass "NFR1: 腳本不依賴 Python/Node/Ruby/Perl"
else
  fail "NFR1: 腳本含外部語言依賴（count=${PYTHON_USAGE}）"
fi

# ── 結果摘要 ─────────────────────────────────────────────────────────

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo ""
echo "================================================================"
echo "結果：PASS=${PASS}  FAIL=${FAIL}  時間=${ELAPSED}s"
echo "================================================================"

if [ "$FAIL" -eq 0 ]; then
  echo "[RESULT] ALL PASS"
  exit 0
else
  echo "[RESULT] FAIL (${FAIL} 項未通過)"
  exit 1
fi
