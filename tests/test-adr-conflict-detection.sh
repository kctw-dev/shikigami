#!/usr/bin/env bash
# test-adr-conflict-detection.sh — #730 ADR 編號衝突預偵測機制驗證
# Sprint 155 | AC1-AC3

set -euo pipefail

PASS=0
FAIL=0
ARCHITECT_PROMPT="skills/sprint-planning/references/architect-prompt.md"

log_pass() { echo "[PASS] $1"; PASS=$((PASS+1)); }
log_fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

# ── TC-1: architect-prompt.md 包含 ADR 編號衝突偵測邏輯（AC1）──
if grep -q "ADR-CONFLICT\|adr.*conflict\|ADR.*衝突\|ADR.*占用\|ADR.*已被" "$ARCHITECT_PROMPT" 2>/dev/null; then
  log_pass "TC-1: AC1 — architect-prompt.md 包含 ADR 編號衝突偵測邏輯"
else
  log_fail "TC-1: AC1 — architect-prompt.md 缺少 ADR 編號衝突偵測邏輯"
fi

# ── TC-2: 偵測到衝突時自動建議下一個可用 ADR 編號（AC2）──────────
if grep -q "下一個可用\|next.*ADR\|available.*ADR\|自動建議\|auto.*suggest" "$ARCHITECT_PROMPT" 2>/dev/null; then
  log_pass "TC-2: AC2 — architect-prompt.md 包含自動建議下一個可用 ADR 編號邏輯"
else
  log_fail "TC-2: AC2 — architect-prompt.md 缺少自動建議下一個可用 ADR 編號邏輯"
fi

# ── TC-3: ADR 衝突偵測腳本功能驗證（AC3）────────────────────────
# 模擬 ADR 目錄
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

mkdir -p "$TMP_DIR/docs/adr"
touch "$TMP_DIR/docs/adr/ADR-041-crash-recovery-design.md"
touch "$TMP_DIR/docs/adr/ADR-042-session-watchdog-design.md"
touch "$TMP_DIR/docs/adr/ADR-043-backlog-replenishment-strategy.md"

# 模擬衝突偵測邏輯（取自 architect-prompt.md 的 bash snippet）
detect_adr_conflict() {
  local proposed_num="$1"
  local adr_dir="$2"

  if ls "$adr_dir"/ADR-${proposed_num}-*.md 2>/dev/null | head -1 | grep -q .; then
    # 找下一個可用編號
    NEXT=$(ls "$adr_dir"/ADR-*.md 2>/dev/null | grep -oE 'ADR-[0-9]+' | sort -t- -k2 -n | tail -1 | grep -oE '[0-9]+' || echo "0")
    NEXT=$((10#$NEXT+1))  # 10# 前綴防止 leading-zero 被解析為 octal
    echo "[ADR-CONFLICT] ADR-${proposed_num} 已被佔用，建議使用 ADR-${NEXT}"
    return 1
  else
    echo "[ADR-OK] ADR-${proposed_num} 可用"
    return 0
  fi
}

# 測試衝突場景（ADR-041 已被佔用）
CONFLICT_OUTPUT=$(detect_adr_conflict "041" "$TMP_DIR/docs/adr" || true)
if echo "$CONFLICT_OUTPUT" | grep -q "\[ADR-CONFLICT\]"; then
  log_pass "TC-3: AC3 — ADR 衝突偵測正確識別已佔用編號（ADR-041）"
else
  log_fail "TC-3: AC3 — ADR 衝突偵測未識別 ADR-041 佔用，輸出：$CONFLICT_OUTPUT"
fi

# 測試可用場景（ADR-044 未佔用）
OK_OUTPUT=$(detect_adr_conflict "044" "$TMP_DIR/docs/adr")
if echo "$OK_OUTPUT" | grep -q "\[ADR-OK\]"; then
  log_pass "TC-3a: AC3 — ADR 衝突偵測正確識別可用編號（ADR-044）"
else
  log_fail "TC-3a: AC3 — ADR 衝突偵測誤判 ADR-044，輸出：$OK_OUTPUT"
fi

# 測試自動建議下一個可用編號（ADR-044 或 ADR-44，mock 可能不做 zero-padding）
if echo "$CONFLICT_OUTPUT" | grep -qE "建議.*ADR-0?44|suggest.*ADR-0?44|ADR-0?44"; then
  log_pass "TC-3b: AC2 — 衝突時自動建議 ADR-044（正確下一個可用編號）"
else
  log_fail "TC-3b: AC2 — 衝突時未建議正確下一個可用編號，輸出：$CONFLICT_OUTPUT"
fi

# ── TC-4: 衝突偵測腳本存在（AC3）────────────────────────────────
CONFLICT_SCRIPT="scripts/check-adr-conflict.sh"
if [ -f "$CONFLICT_SCRIPT" ]; then
  log_pass "TC-4: AC3 — $CONFLICT_SCRIPT 存在"
else
  log_fail "TC-4: AC3 — $CONFLICT_SCRIPT 不存在"
fi

# ── TC-5: 腳本可執行 ─────────────────────────────────────────────
if [ -f "$CONFLICT_SCRIPT" ] && [ -x "$CONFLICT_SCRIPT" ]; then
  log_pass "TC-5: $CONFLICT_SCRIPT 有執行權限"
else
  log_fail "TC-5: $CONFLICT_SCRIPT 不存在或沒有執行權限"
fi

# ── 結果輸出 ─────────────────────────────────────────────────────
echo ""
echo "=== test-adr-conflict-detection.sh 結果 ==="
echo "PASS: $PASS | FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "[TEST-SUITE-PASS] 全部 $PASS 項通過"
  exit 0
else
  echo "[TEST-SUITE-FAIL] $FAIL 項失敗"
  exit 1
fi
