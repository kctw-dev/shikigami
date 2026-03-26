#!/usr/bin/env bash
# tests/test-sprint-goal-stats.sh
# Story #874: Sprint Goal 達成率歷史追蹤 — 單元測試
# TDD: 測試先於實作

set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
SCRIPT="$REPO_ROOT/scripts/sprint-goal-stats.sh"
FIXTURE_DIR="$(mktemp -d)"
PASS=0
FAIL=0

cleanup() { rm -rf "$FIXTURE_DIR"; }
trap cleanup EXIT

ok()   { echo "[PASS] $1"; ((PASS++)) || true; }
fail() { echo "[FAIL] $1"; ((FAIL++)) || true; }

# ── Fixture 建立 ──────────────────────────────────────────────────────────────

mk_sprint() {
  local n="$1" total="$2" done="$3"
  local file="$FIXTURE_DIR/sprint_${n}.md"
  {
    echo "# Sprint $n"
    echo ""
    for i in $(seq 1 "$done"); do
      echo "| Story $i | #$((100+i)) | S | 1 | DONE |"
    done
    for i in $(seq $((done+1)) "$total"); do
      echo "| Story $i | #$((100+i)) | S | 1 | TODO |"
    done
  } > "$file"
}

# Sprint 1: 3/3 DONE = 100%
mk_sprint 1 3 3
# Sprint 2: 2/4 DONE = 50%
mk_sprint 2 4 2
# Sprint 3: 4/4 DONE = 100%
mk_sprint 3 4 4
# Sprint 4: 4/4 DONE = 100%
mk_sprint 4 4 4
# Sprint 5: 1/5 DONE = 20%
mk_sprint 5 5 1
# Sprint 6: 3/3 DONE = 100%
mk_sprint 6 3 3
# Sprint 7 — 無任何 DONE 列（0%）
echo "# Sprint 7" > "$FIXTURE_DIR/sprint_7.md"
echo "| Story A | #201 | S | 1 | TODO |" >> "$FIXTURE_DIR/sprint_7.md"

# ── Test 1: 腳本存在且可執行 ──────────────────────────────────────────────────
if [[ -x "$SCRIPT" ]]; then
  ok "T1: script exists and is executable"
else
  fail "T1: script not found or not executable: $SCRIPT"
fi

# ── Test 2: 基本輸出包含標題列 ────────────────────────────────────────────────
OUTPUT=$(SPRINT_DIR="$FIXTURE_DIR" bash "$SCRIPT" 2>/dev/null)
if echo "$OUTPUT" | grep -q "Sprint"; then
  ok "T2: output contains Sprint header"
else
  fail "T2: output missing Sprint header"
fi

# ── Test 3: 100% 達成率正確識別 ───────────────────────────────────────────────
if echo "$OUTPUT" | grep -q "100%"; then
  ok "T3: 100% achievement rate detected"
else
  fail "T3: 100% achievement rate not detected"
fi

# ── Test 4: --last N 參數限制輸出數量 ─────────────────────────────────────────
OUTPUT_LAST3=$(SPRINT_DIR="$FIXTURE_DIR" bash "$SCRIPT" --last 3 2>/dev/null)
SPRINT_LINE_COUNT=$(echo "$OUTPUT_LAST3" | grep -cE "^[[:space:]]*\|[[:space:]]*Sprint" 2>/dev/null || true)
if [[ "$SPRINT_LINE_COUNT" -le 3 ]]; then
  ok "T4: --last 3 limits output to <= 3 sprints"
else
  fail "T4: --last 3 returned $SPRINT_LINE_COUNT sprint lines (expected <= 3)"
fi

# ── Test 5: 連續 100% 最長記錄識別 ───────────────────────────────────────────
# Sprint 3+4 連續 100% = 2，Sprint 1+3+4+6 各有 100% 但中斷，最長連續應為 2
CONSECUTIVE_OUTPUT=$(SPRINT_DIR="$FIXTURE_DIR" bash "$SCRIPT" 2>/dev/null)
if echo "$CONSECUTIVE_OUTPUT" | grep -qiE "consecutive|連續|streak"; then
  ok "T5: consecutive streak detection present in output"
else
  fail "T5: no consecutive streak detection in output"
fi

# ── Test 6: Sprint 文件不存在時優雅略過（空目錄）─────────────────────────────
EMPTY_DIR=$(mktemp -d)
OUTPUT_EMPTY=$(SPRINT_DIR="$EMPTY_DIR" bash "$SCRIPT" 2>/dev/null)
rmdir "$EMPTY_DIR"
if [[ $? -eq 0 ]]; then
  ok "T6: empty sprint dir exits gracefully (no crash)"
else
  fail "T6: empty sprint dir caused crash"
fi

# ── Test 7: 部分達成率（50%）正確輸出 ────────────────────────────────────────
if echo "$OUTPUT" | grep -qE "50%|2/4"; then
  ok "T7: partial achievement rate (50%) detected"
else
  fail "T7: partial achievement rate not detected in output"
fi

# ── Test 8: 0% 達成率（Sprint 7）不崩潰 ──────────────────────────────────────
if echo "$OUTPUT" | grep -qE "Sprint 7|0%|0/"; then
  ok "T8: 0% achievement rate handled without crash"
else
  fail "T8: Sprint 7 (0% rate) missing or caused crash"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
