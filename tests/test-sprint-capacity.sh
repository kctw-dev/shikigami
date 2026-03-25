#!/usr/bin/env bash
# test-sprint-capacity.sh — #734 Sprint 容量自動計算腳本驗證
# Sprint 155 | AC1-AC4 驗證

set -euo pipefail

PASS=0
FAIL=0
SCRIPT="scripts/calculate-sprint-capacity.sh"
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

log_pass() { echo "[PASS] $1"; PASS=$((PASS+1)); }
log_fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

# ── TC-1: calculate-sprint-capacity.sh 存在 ──────────────────────
if [ -f "$SCRIPT" ]; then
  log_pass "TC-1: $SCRIPT 存在"
else
  log_fail "TC-1: $SCRIPT 不存在（AC1 要求）"
fi

# ── TC-2: 腳本可執行 ─────────────────────────────────────────────
if [ -x "$SCRIPT" ]; then
  log_pass "TC-2: $SCRIPT 有執行權限"
else
  log_fail "TC-2: $SCRIPT 沒有執行權限"
fi

# ── TC-3: 正常模式（3 個 metrics-log）─────────────────────────────
# 建立 mock metrics-log
mkdir -p "$TMP_DIR/metrics-log"
cat > "$TMP_DIR/metrics-log/2026-03-21-session-sprint152.md" << 'MOCK'
# Sprint 152 Metrics
## Velocity
| Metric | Value |
| Velocity | 6 pts |
MOCK

cat > "$TMP_DIR/metrics-log/2026-03-22-session-sprint153.md" << 'MOCK'
# Sprint 153 Metrics
## Velocity
| Metric | Value |
| Velocity | 5 pts |
MOCK

cat > "$TMP_DIR/metrics-log/2026-03-23-session-sprint154.md" << 'MOCK'
# Sprint 154 Metrics
## Velocity
| Metric | Value |
| Velocity | 7 pts |
MOCK

# 執行腳本（指向 mock 目錄）
if [ -f "$SCRIPT" ]; then
  OUTPUT=$(bash "$SCRIPT" --metrics-dir "$TMP_DIR/metrics-log" 2>&1 || true)
  if echo "$OUTPUT" | grep -q "\[CAPACITY\]"; then
    log_pass "TC-3: 正常模式輸出包含 [CAPACITY] 標籤"
    # 驗證平均 Velocity = (6+5+7)/3 = 6
    if echo "$OUTPUT" | grep -q "avg_velocity=6"; then
      log_pass "TC-3a: 平均 Velocity 計算正確（6pts）"
    else
      log_fail "TC-3a: 平均 Velocity 計算錯誤（期望 6pts），輸出：$OUTPUT"
    fi
    # 驗證輸出格式包含 ±20% range
    if echo "$OUTPUT" | grep -qE "range:.*-.*"; then
      log_pass "TC-3b: 輸出包含 ±20% range"
    else
      log_fail "TC-3b: 輸出缺少 ±20% range，輸出：$OUTPUT"
    fi
  else
    log_fail "TC-3: 正常模式輸出缺少 [CAPACITY] 標籤，輸出：$OUTPUT"
  fi
else
  log_fail "TC-3: 腳本不存在，跳過執行測試"
fi

# ── TC-4: 歷史數據不足 3 個時輸出 [CAPACITY-WARN]（AC4）──────────
mkdir -p "$TMP_DIR/metrics-log-sparse"
cat > "$TMP_DIR/metrics-log-sparse/2026-03-23-session-sprint154.md" << 'MOCK'
# Sprint 154 Metrics
## Velocity
| Metric | Value |
| Velocity | 7 pts |
MOCK

if [ -f "$SCRIPT" ]; then
  OUTPUT_SPARSE=$(bash "$SCRIPT" --metrics-dir "$TMP_DIR/metrics-log-sparse" 2>&1 || true)
  if echo "$OUTPUT_SPARSE" | grep -q "\[CAPACITY-WARN\]"; then
    log_pass "TC-4: 歷史數據不足 3 個時輸出 [CAPACITY-WARN]（AC4）"
  else
    log_fail "TC-4: 歷史數據不足 3 個時未輸出 [CAPACITY-WARN]，輸出：$OUTPUT_SPARSE"
  fi
else
  log_fail "TC-4: 腳本不存在，跳過"
fi

# ── TC-5: NFR1 — 純 bash 實作，不依賴外部工具（除 jq 外）──────────
if [ -f "$SCRIPT" ]; then
  # 檢查是否使用 python, node, ruby 等外部工具
  FORBIDDEN_TOOLS="python python3 node nodejs ruby perl"
  FOUND_FORBIDDEN=false
  for tool in $FORBIDDEN_TOOLS; do
    if grep -q "^[^#]*\b${tool}\b" "$SCRIPT" 2>/dev/null; then
      log_fail "TC-5: NFR1 — 腳本使用了禁止的外部工具: $tool"
      FOUND_FORBIDDEN=true
    fi
  done
  if ! $FOUND_FORBIDDEN; then
    log_pass "TC-5: NFR1 — 純 bash 實作，無禁止外部工具"
  fi
else
  log_fail "TC-5: 腳本不存在，跳過"
fi

# ── TC-6: Sprint Planning architect-prompt.md 引用腳本（AC3）──────
ARCHITECT_PROMPT="skills/sprint-planning/references/architect-prompt.md"
if grep -q "calculate-sprint-capacity\|sprint-capacity" "$ARCHITECT_PROMPT" 2>/dev/null; then
  log_pass "TC-6: AC3 — architect-prompt.md 引用 calculate-sprint-capacity.sh"
else
  log_fail "TC-6: AC3 — architect-prompt.md 未引用 calculate-sprint-capacity.sh"
fi

# ── 結果輸出 ─────────────────────────────────────────────────────
echo ""
echo "=== test-sprint-capacity.sh 結果 ==="
echo "PASS: $PASS | FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "[TEST-SUITE-PASS] 全部 $PASS 項通過"
  exit 0
else
  echo "[TEST-SUITE-FAIL] $FAIL 項失敗"
  exit 1
fi
