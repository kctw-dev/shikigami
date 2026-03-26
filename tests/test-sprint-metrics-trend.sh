#!/usr/bin/env bash
# tests/test-sprint-metrics-trend.sh
# Story #869: Sprint Metrics 歷史趨勢儀表板 — 單元測試
# TDD: 測試先於實作

set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
SCRIPT="$REPO_ROOT/scripts/sprint-metrics-trend.sh"
FIXTURE_DIR="$(mktemp -d)"
PASS=0
FAIL=0

cleanup() { rm -rf "$FIXTURE_DIR"; }
trap cleanup EXIT

ok()   { echo "[PASS] $1"; ((PASS++)) || true; }
fail() { echo "[FAIL] $1"; ((FAIL++)) || true; }

# ── Fixture 建立 ──────────────────────────────────────────────────────────────

mk_metrics() {
  local sprint="$1" velocity="$2" completion="$3" space="${4:-4.5}"
  cat > "$FIXTURE_DIR/sprint-${sprint}-metrics.md" << EOF
# Sprint ${sprint} Metrics Log

**Sprint**：${sprint}
**日期**：2026-01-01

## Sprint Metrics

| 指標 | 值 |
|------|-----|
| Velocity | ${velocity} pts |
| 完成率 | ${completion}%（auto） |
| Sprint Goal 達成 | YES |

## SPACE Score

| Dimension | Score |
|-----------|-------|
| Overall | ${space} |
EOF
}

mk_metrics 160 6 100 4.5
mk_metrics 161 7 100 4.8
mk_metrics 162 5 83  4.2
mk_metrics 163 6 100 4.6
mk_metrics 164 8 100 5.0
mk_metrics 165 6 100 4.7

# ── Test 1: 腳本存在且可執行 ──────────────────────────────────────────────────
if [[ -x "$SCRIPT" ]]; then
  ok "T1: script exists and is executable"
else
  fail "T1: script not found or not executable: $SCRIPT"
fi

# ── Test 2: 基本輸出包含 Velocity 欄位 ───────────────────────────────────────
OUTPUT=$(METRICS_DIR="$FIXTURE_DIR" bash "$SCRIPT" 2>/dev/null)
if echo "$OUTPUT" | grep -qi "velocity\|Velocity\|速度"; then
  ok "T2: output contains Velocity column"
else
  fail "T2: output missing Velocity column"
fi

# ── Test 3: --last N 限制輸出數量 ─────────────────────────────────────────────
OUTPUT_L3=$(METRICS_DIR="$FIXTURE_DIR" bash "$SCRIPT" --last 3 2>/dev/null)
SPRINT_LINES=$(echo "$OUTPUT_L3" | grep -cE "Sprint [0-9]+" 2>/dev/null || true)
if [[ "$SPRINT_LINES" -le 3 ]]; then
  ok "T3: --last 3 limits to <= 3 sprint rows"
else
  fail "T3: --last 3 returned $SPRINT_LINES sprint rows (expected <= 3)"
fi

# ── Test 4: TREND-UP 偵測（前段低後段高）────────────────────────────────────
# Sprint 164=8 > Sprint 163=6，應觸發 TREND-UP
if echo "$OUTPUT" | grep -q "TREND-UP"; then
  ok "T4: [TREND-UP] detected when velocity increases"
else
  fail "T4: [TREND-UP] not found despite velocity increase"
fi

# ── Test 5: TREND-DOWN 偵測 ───────────────────────────────────────────────────
# Sprint 162=5 < Sprint 161=7，應觸發 TREND-DOWN
if echo "$OUTPUT" | grep -q "TREND-DOWN"; then
  ok "T5: [TREND-DOWN] detected when velocity decreases"
else
  fail "T5: [TREND-DOWN] not found despite velocity decrease"
fi

# ── Test 6: 空目錄優雅降級 ────────────────────────────────────────────────────
EMPTY_DIR=$(mktemp -d)
EXIT_CODE=0
METRICS_DIR="$EMPTY_DIR" bash "$SCRIPT" 2>/dev/null || EXIT_CODE=$?
rmdir "$EMPTY_DIR"
if [[ "$EXIT_CODE" -eq 0 ]]; then
  ok "T6: empty metrics dir exits gracefully"
else
  fail "T6: empty metrics dir caused crash (exit $EXIT_CODE)"
fi

# ── Test 7: 執行時間 < 3s（NFR1） ────────────────────────────────────────────
START_NS=$(date +%s%N 2>/dev/null || echo 0)
METRICS_DIR="$FIXTURE_DIR" bash "$SCRIPT" >/dev/null 2>&1
END_NS=$(date +%s%N 2>/dev/null || echo 3000000000)
ELAPSED_MS=$(( (END_NS - START_NS) / 1000000 ))
if [[ "$ELAPSED_MS" -lt 3000 ]]; then
  ok "T7: execution time ${ELAPSED_MS}ms < 3000ms (NFR1)"
else
  fail "T7: execution time ${ELAPSED_MS}ms >= 3000ms (NFR1 violated)"
fi

# ── Test 8: Sprint 編號出現在輸出 ────────────────────────────────────────────
if echo "$OUTPUT" | grep -qE "16[0-9]"; then
  ok "T8: sprint numbers appear in output"
else
  fail "T8: no sprint numbers found in output"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
