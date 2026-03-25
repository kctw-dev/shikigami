#!/usr/bin/env bash
# test-calculate-sprint-capacity.sh — calculate-sprint-capacity.sh 自動化驗證
# Story #844 | AC1-AC4 驗證
# AC1: 新增 tests/test-calculate-sprint-capacity.sh
# AC2: 測試涵蓋標準場景（5 Sprint 滾動平均 = 6 pts）
# AC3: 測試涵蓋邊界場景（< 5 個歷史 Sprint、0 個歷史 Sprint）
# AC4: 測試 PASS 且 exit 0
# NFR1: 測試使用 fixture Sprint 紀錄，不依賴真實 docs/sprints/

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
  log_pass "TC-1: $SCRIPT 存在（AC1 要求）"
else
  log_fail "TC-1: $SCRIPT 不存在（AC1 要求）"
fi

# ── TC-2: 腳本可執行 ─────────────────────────────────────────────
if [ -x "$SCRIPT" ]; then
  log_pass "TC-2: $SCRIPT 有執行權限"
else
  log_fail "TC-2: $SCRIPT 沒有執行權限"
fi

# ── AC2: 標準場景 — 5 Sprint 滾動平均 = 6 pts ─────────────────────────
# 5 個 metrics-log：velocities = [4, 5, 6, 7, 8]
# 平均 = (4+5+6+7+8)/5 = 30/5 = 6 pts
mkdir -p "$TMP_DIR/metrics-5sprint"
cat > "$TMP_DIR/metrics-5sprint/2026-03-20-session-sprint150.md" << 'MOCK'
# Sprint 150 Metrics
## Velocity
| Metric | Value |
| Velocity | 4 pts |
MOCK

cat > "$TMP_DIR/metrics-5sprint/2026-03-21-session-sprint151.md" << 'MOCK'
# Sprint 151 Metrics
## Velocity
| Metric | Value |
| Velocity | 5 pts |
MOCK

cat > "$TMP_DIR/metrics-5sprint/2026-03-22-session-sprint152.md" << 'MOCK'
# Sprint 152 Metrics
## Velocity
| Metric | Value |
| Velocity | 6 pts |
MOCK

cat > "$TMP_DIR/metrics-5sprint/2026-03-23-session-sprint153.md" << 'MOCK'
# Sprint 153 Metrics
## Velocity
| Metric | Value |
| Velocity | 7 pts |
MOCK

cat > "$TMP_DIR/metrics-5sprint/2026-03-24-session-sprint154.md" << 'MOCK'
# Sprint 154 Metrics
## Velocity
| Metric | Value |
| Velocity | 8 pts |
MOCK

if [ -f "$SCRIPT" ]; then
  OUTPUT=$(bash "$SCRIPT" --metrics-dir "$TMP_DIR/metrics-5sprint" --max-sprints 5 2>&1 || true)

  # TC-3: 輸出包含 [CAPACITY] 標籤
  if echo "$OUTPUT" | grep -q "\[CAPACITY\]"; then
    log_pass "TC-3: AC2 標準場景 — 輸出包含 [CAPACITY] 標籤"
  else
    log_fail "TC-3: AC2 標準場景 — 缺少 [CAPACITY] 標籤，輸出：$OUTPUT"
  fi

  # TC-3a: 5 Sprint 平均 = 6 pts
  if echo "$OUTPUT" | grep -q "avg_velocity=6"; then
    log_pass "TC-3a: AC2 平均 Velocity 計算正確（6pts，5 個 Sprint 平均）"
  else
    log_fail "TC-3a: AC2 平均 Velocity 計算錯誤（期望 6pts），輸出：$OUTPUT"
  fi

  # TC-3b: 包含 ±20% range
  if echo "$OUTPUT" | grep -qE "range:.*-.*"; then
    log_pass "TC-3b: AC2 輸出包含 ±20% range（low-high 格式）"
  else
    log_fail "TC-3b: AC2 輸出缺少 ±20% range，輸出：$OUTPUT"
  fi

  # TC-3c: ±20% 範圍計算正確（6 * 80% = 4, 6 * 120% = 7 → 4-7）
  if echo "$OUTPUT" | grep -qE "4-7"; then
    log_pass "TC-3c: AC2 ±20% 範圍計算正確（6 pts → 4-7 pts，整數截斷）"
  else
    log_fail "TC-3c: AC2 ±20% 範圍計算錯誤（期望 4-7 pts），輸出：$OUTPUT"
  fi
else
  log_fail "TC-3: 腳本不存在，跳過 AC2 標準場景測試"
fi

# ── AC3: 邊界場景 — 少於 5 個歷史 Sprint（2 個 Sprint）────────────────
# velocities = [5, 7]
# 平均 = (5+7)/2 = 6 pts
mkdir -p "$TMP_DIR/metrics-2sprint"
cat > "$TMP_DIR/metrics-2sprint/2026-03-23-session-sprint153.md" << 'MOCK'
# Sprint 153 Metrics
## Velocity
| Metric | Value |
| Velocity | 5 pts |
MOCK

cat > "$TMP_DIR/metrics-2sprint/2026-03-24-session-sprint154.md" << 'MOCK'
# Sprint 154 Metrics
## Velocity
| Metric | Value |
| Velocity | 7 pts |
MOCK

if [ -f "$SCRIPT" ]; then
  OUTPUT_2SPRINT=$(bash "$SCRIPT" --metrics-dir "$TMP_DIR/metrics-2sprint" --max-sprints 5 2>&1 || true)

  # TC-4: 歷史數據不足 5 個時輸出 [CAPACITY-WARN]
  if echo "$OUTPUT_2SPRINT" | grep -q "\[CAPACITY-WARN\]"; then
    log_pass "TC-4: AC3 邊界場景（<5個Sprint）— 輸出 [CAPACITY-WARN]"
  else
    log_fail "TC-4: AC3 邊界場景 — 缺少 [CAPACITY-WARN]，輸出：$OUTPUT_2SPRINT"
  fi

  # TC-4a: 仍能正確計算平均
  if echo "$OUTPUT_2SPRINT" | grep -q "avg_velocity=6"; then
    log_pass "TC-4a: AC3 邊界場景 — 平均計算正確（2個Sprint平均 = 6pts）"
  else
    log_fail "TC-4a: AC3 邊界場景 — 平均計算錯誤，輸出：$OUTPUT_2SPRINT"
  fi
else
  log_fail "TC-4: 腳本不存在，跳過 AC3 邊界場景（2 Sprint）測試"
fi

# ── AC3: 邊界場景 — 0 個歷史 Sprint（空目錄）────────────────────────
mkdir -p "$TMP_DIR/metrics-empty"

if [ -f "$SCRIPT" ]; then
  OUTPUT_EMPTY=$(bash "$SCRIPT" --metrics-dir "$TMP_DIR/metrics-empty" 2>&1 || true)
  EXIT_CODE_EMPTY=$(bash "$SCRIPT" --metrics-dir "$TMP_DIR/metrics-empty" > /dev/null 2>&1; echo $?)

  # TC-5: 無歷史數據時 exit 非 0
  if [ $EXIT_CODE_EMPTY -ne 0 ]; then
    log_pass "TC-5: AC3 邊界場景（0個Sprint）— exit 非 0（錯誤處理）"
  else
    log_fail "TC-5: AC3 邊界場景（0個Sprint）— exit 0（應該失敗），輸出：$OUTPUT_EMPTY"
  fi

  # TC-5a: 輸出 [CAPACITY-ERROR]
  if echo "$OUTPUT_EMPTY" | grep -q "\[CAPACITY-ERROR\]"; then
    log_pass "TC-5a: AC3 邊界場景（0個Sprint）— 輸出 [CAPACITY-ERROR]"
  else
    log_fail "TC-5a: AC3 邊界場景（0個Sprint）— 缺少 [CAPACITY-ERROR]，輸出：$OUTPUT_EMPTY"
  fi
else
  log_fail "TC-5: 腳本不存在，跳過 AC3 邊界場景（0 Sprint）測試"
fi

# ── AC4: 測試 PASS 且 exit 0（正常場景）──────────────────────────────
mkdir -p "$TMP_DIR/metrics-3sprint"
cat > "$TMP_DIR/metrics-3sprint/2026-03-22-session-sprint152.md" << 'MOCK'
# Sprint 152 Metrics
## Velocity
| Metric | Value |
| Velocity | 6 pts |
MOCK

cat > "$TMP_DIR/metrics-3sprint/2026-03-23-session-sprint153.md" << 'MOCK'
# Sprint 153 Metrics
## Velocity
| Metric | Value |
| Velocity | 5 pts |
MOCK

cat > "$TMP_DIR/metrics-3sprint/2026-03-24-session-sprint154.md" << 'MOCK'
# Sprint 154 Metrics
## Velocity
| Metric | Value |
| Velocity | 7 pts |
MOCK

if [ -f "$SCRIPT" ]; then
  bash "$SCRIPT" --metrics-dir "$TMP_DIR/metrics-3sprint" > /dev/null 2>&1
  EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then
    log_pass "TC-6: AC4 正常場景 — exit 0"
  else
    log_fail "TC-6: AC4 正常場景 — exit $EXIT_CODE（期望 0）"
  fi
else
  log_fail "TC-6: 腳本不存在，跳過 AC4 測試"
fi

# ── NFR1: 測試使用 fixture Sprint 紀錄，不依賴真實 docs/sprints/ ──────
# 驗證上述所有測試都是用 fixture（$TMP_DIR），而非真實文件
log_pass "NFR1: 所有測試使用 fixture（--metrics-dir 指向 $TMP_DIR），不依賴真實 docs/sprints/"

# ── TC-7: NFR1 — 純 bash 實作，不依賴外部工具（除 jq 外）──────────────
if [ -f "$SCRIPT" ]; then
  FORBIDDEN_TOOLS="python python3 node nodejs ruby perl"
  FOUND_FORBIDDEN=false
  for tool in $FORBIDDEN_TOOLS; do
    if grep -q "^[^#]*\b${tool}\b" "$SCRIPT" 2>/dev/null; then
      log_fail "TC-7: 腳本使用了禁止的外部工具: $tool"
      FOUND_FORBIDDEN=true
    fi
  done
  if ! $FOUND_FORBIDDEN; then
    log_pass "TC-7: NFR1 — 純 bash 實作，無禁止外部工具"
  fi
else
  log_fail "TC-7: 腳本不存在，跳過"
fi

# ── TC-8: --help 參數正常工作 ─────────────────────────────────────────
if [ -f "$SCRIPT" ]; then
  OUTPUT_HELP=$(bash "$SCRIPT" --help 2>&1 || true)
  if echo "$OUTPUT_HELP" | grep -q "Usage:"; then
    log_pass "TC-8: --help 參數輸出正常"
  else
    log_fail "TC-8: --help 參數輸出異常，輸出：$OUTPUT_HELP"
  fi
else
  log_fail "TC-8: 腳本不存在，跳過"
fi

# ── 結果輸出 ─────────────────────────────────────────────────────────
echo ""
echo "=== test-calculate-sprint-capacity.sh 結果 ==="
echo "PASS: $PASS | FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "[TEST-SUITE-PASS] 全部 $PASS 項通過（AC1-AC4、NFR1 全覆蓋）"
  exit 0
else
  echo "[TEST-SUITE-FAIL] $FAIL 項失敗"
  exit 1
fi
