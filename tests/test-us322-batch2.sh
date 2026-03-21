#!/usr/bin/env bash
# tests/test-us322-batch2.sh
# US-#322 Batch 2 TDD — AC-3, AC-4, AC-5, AC-6, AC-8, AC-9, AC-10
#
# TC-1:  hooks/metrics-settle.sh 存在且可執行
# TC-2:  hooks/retro-settle.sh 存在且可執行
# TC-3:  hooks/quality-decisions-settle.sh 存在且可執行
# TC-4:  hooks/tech-debt-settle.sh 存在且可執行
# TC-5:  protect-main.sh 豁免 ^docs/km/metrics-log/
# TC-6:  protect-main.sh 豁免 ^docs/km/retro-log/
# TC-7:  protect-main.sh 豁免 ^docs/km/quality-decisions/
# TC-8:  protect-main.sh 豁免 ^docs/km/tech-debt/
# TC-9:  sprint-review SKILL.md 引用新 metrics-log 路徑
# TC-10: sprint-review SKILL.md 引用新 retro-log 路徑
# TC-11: quality-gate SKILL.md §7.2 引用新 quality-decisions 路徑
# TC-12: story-lifecycle-prompt.md 引用新 tech-debt 路徑
# TC-13: sprint-execution SKILL.md sprint_N.md 含 push retry 機制
# TC-14: metrics-settle.sh 結算功能（unit smoke）
# TC-15: retro-settle.sh 結算功能（unit smoke）
# TC-16: quality-decisions-settle.sh 結算功能（unit smoke）
# TC-17: tech-debt-settle.sh 結算功能（unit smoke）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PASS=0
FAIL=0

# 統一清理目錄（set -u 相容：使用 :- 空字串預設值）
TMPDIR_METRICS=""
TMPDIR_RETRO=""
TMPDIR_QD=""
TMPDIR_TD=""
trap 'rm -rf "${TMPDIR_METRICS:-}" "${TMPDIR_RETRO:-}" "${TMPDIR_QD:-}" "${TMPDIR_TD:-}" 2>/dev/null || true' EXIT

pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

echo "=== test-us322-batch2.sh ==="

# ── TC-1: hooks/metrics-settle.sh 存在且可執行 ───────────────────
echo ""
echo "--- TC-1: hooks/metrics-settle.sh 存在且可執行 ---"
METRICS_SETTLE="${REPO_ROOT}/hooks/metrics-settle.sh"
if [[ -f "$METRICS_SETTLE" ]]; then
  pass "TC-1a: metrics-settle.sh 存在"
  if [[ -x "$METRICS_SETTLE" ]]; then
    pass "TC-1b: metrics-settle.sh 可執行"
  else
    fail "TC-1b: metrics-settle.sh 不可執行"
  fi
else
  fail "TC-1a: metrics-settle.sh 不存在"
  fail "TC-1b: metrics-settle.sh 不可執行（不存在）"
fi

# ── TC-2: hooks/retro-settle.sh 存在且可執行 ─────────────────────
echo ""
echo "--- TC-2: hooks/retro-settle.sh 存在且可執行 ---"
RETRO_SETTLE="${REPO_ROOT}/hooks/retro-settle.sh"
if [[ -f "$RETRO_SETTLE" ]]; then
  pass "TC-2a: retro-settle.sh 存在"
  if [[ -x "$RETRO_SETTLE" ]]; then
    pass "TC-2b: retro-settle.sh 可執行"
  else
    fail "TC-2b: retro-settle.sh 不可執行"
  fi
else
  fail "TC-2a: retro-settle.sh 不存在"
  fail "TC-2b: retro-settle.sh 不可執行（不存在）"
fi

# ── TC-3: hooks/quality-decisions-settle.sh 存在且可執行 ─────────
echo ""
echo "--- TC-3: hooks/quality-decisions-settle.sh 存在且可執行 ---"
QD_SETTLE="${REPO_ROOT}/hooks/quality-decisions-settle.sh"
if [[ -f "$QD_SETTLE" ]]; then
  pass "TC-3a: quality-decisions-settle.sh 存在"
  if [[ -x "$QD_SETTLE" ]]; then
    pass "TC-3b: quality-decisions-settle.sh 可執行"
  else
    fail "TC-3b: quality-decisions-settle.sh 不可執行"
  fi
else
  fail "TC-3a: quality-decisions-settle.sh 不存在"
  fail "TC-3b: quality-decisions-settle.sh 不可執行（不存在）"
fi

# ── TC-4: hooks/tech-debt-settle.sh 存在且可執行 ─────────────────
echo ""
echo "--- TC-4: hooks/tech-debt-settle.sh 存在且可執行 ---"
TD_SETTLE="${REPO_ROOT}/hooks/tech-debt-settle.sh"
if [[ -f "$TD_SETTLE" ]]; then
  pass "TC-4a: tech-debt-settle.sh 存在"
  if [[ -x "$TD_SETTLE" ]]; then
    pass "TC-4b: tech-debt-settle.sh 可執行"
  else
    fail "TC-4b: tech-debt-settle.sh 不可執行"
  fi
else
  fail "TC-4a: tech-debt-settle.sh 不存在"
  fail "TC-4b: tech-debt-settle.sh 不可執行（不存在）"
fi

# ── TC-5~8: protect-main.sh 豁免清單 ─────────────────────────────
echo ""
echo "--- TC-5~8: protect-main.sh 豁免清單 ---"
PROTECT="${REPO_ROOT}/hooks/protect-main.sh"

if grep -qE 'docs/km/metrics-log' "$PROTECT" 2>/dev/null; then
  pass "TC-5: protect-main.sh 豁免 docs/km/metrics-log/"
else
  fail "TC-5: protect-main.sh 未豁免 docs/km/metrics-log/"
fi

if grep -qE 'docs/km/retro-log' "$PROTECT" 2>/dev/null; then
  pass "TC-6: protect-main.sh 豁免 docs/km/retro-log/"
else
  fail "TC-6: protect-main.sh 未豁免 docs/km/retro-log/"
fi

if grep -qE 'docs/km/quality-decisions' "$PROTECT" 2>/dev/null; then
  pass "TC-7: protect-main.sh 豁免 docs/km/quality-decisions/"
else
  fail "TC-7: protect-main.sh 未豁免 docs/km/quality-decisions/"
fi

if grep -qE 'docs/km/tech-debt' "$PROTECT" 2>/dev/null; then
  pass "TC-8: protect-main.sh 豁免 docs/km/tech-debt/"
else
  fail "TC-8: protect-main.sh 未豁免 docs/km/tech-debt/"
fi

# ── TC-9~10: sprint-review SKILL.md 引用新路徑 ───────────────────
echo ""
echo "--- TC-9~10: sprint-review SKILL.md 引用新路徑 ---"
SPRINT_REVIEW_SKILL="${REPO_ROOT}/skills/sprint-review/SKILL.md"

if grep -qE 'metrics-log/' "$SPRINT_REVIEW_SKILL" 2>/dev/null; then
  pass "TC-9: sprint-review SKILL.md 引用 metrics-log/ 路徑"
else
  fail "TC-9: sprint-review SKILL.md 未引用 metrics-log/ 路徑"
fi

if grep -qE 'retro-log/' "$SPRINT_REVIEW_SKILL" 2>/dev/null; then
  pass "TC-10: sprint-review SKILL.md 引用 retro-log/ 路徑"
else
  fail "TC-10: sprint-review SKILL.md 未引用 retro-log/ 路徑"
fi

# ── TC-11: quality-gate SKILL.md §7.2 引用新路徑 ────────────────
echo ""
echo "--- TC-11: quality-gate SKILL.md §7.2 引用新 quality-decisions 路徑 ---"
QG_SKILL="${REPO_ROOT}/skills/quality-gate/SKILL.md"

if grep -qE 'quality-decisions/' "$QG_SKILL" 2>/dev/null; then
  pass "TC-11: quality-gate SKILL.md 引用 quality-decisions/ 路徑"
else
  fail "TC-11: quality-gate SKILL.md 未引用 quality-decisions/ 路徑"
fi

# ── TC-12: story-lifecycle-prompt.md 引用新 tech-debt 路徑 ───────
echo ""
echo "--- TC-12: story-lifecycle-prompt.md 引用新 tech-debt 路徑 ---"
SLP="${REPO_ROOT}/skills/sprint-execution/story-lifecycle-prompt.md"

if grep -qE 'km/tech-debt/' "$SLP" 2>/dev/null; then
  pass "TC-12: story-lifecycle-prompt.md 引用 km/tech-debt/ 路徑"
else
  fail "TC-12: story-lifecycle-prompt.md 未引用 km/tech-debt/ 路徑"
fi

# ── TC-13: sprint-execution SKILL.md sprint_N.md 含 push retry ──
echo ""
echo "--- TC-13: sprint-execution SKILL.md sprint_N.md push retry ---"
SPRINT_EXEC_SKILL="${REPO_ROOT}/skills/sprint-execution/SKILL.md"

if grep -qE 'Push Retry|push retry|PUSH-RETRY' "$SPRINT_EXEC_SKILL" 2>/dev/null; then
  pass "TC-13: sprint-execution SKILL.md 含 push retry 機制"
else
  fail "TC-13: sprint-execution SKILL.md 未含 push retry 機制"
fi

# ── TC-14: metrics-settle.sh smoke test ──────────────────────────
echo ""
echo "--- TC-14: metrics-settle.sh smoke test ---"
if [[ -f "$METRICS_SETTLE" ]]; then
  TMPDIR_METRICS="$(mktemp -d)"

  # 建立假的 per-session 檔案
  TEST_DATE="2099-01-15"
  mkdir -p "${TMPDIR_METRICS}/metrics-log"
  cat > "${TMPDIR_METRICS}/metrics-log/${TEST_DATE}-session-test1.md" <<'EOF'
## Sprint Metrics — test session

| Sprint | Velocity | 完成率 | P50 |
|--------|----------|--------|-----|
| S-01 | 10 | 80% | 3d |
EOF

  METRICS_LOG_DIR="${TMPDIR_METRICS}/metrics-log" bash "$METRICS_SETTLE" "$TEST_DATE" 2>&1
  SUMMARY="${TMPDIR_METRICS}/metrics-log/${TEST_DATE}.summary.md"
  if [[ -f "$SUMMARY" ]]; then
    pass "TC-14: metrics-settle.sh 成功生成 summary.md"
  else
    fail "TC-14: metrics-settle.sh 未生成 summary.md"
  fi
else
  fail "TC-14: metrics-settle.sh 不存在，無法測試"
fi

# ── TC-15: retro-settle.sh smoke test ────────────────────────────
echo ""
echo "--- TC-15: retro-settle.sh smoke test ---"
if [[ -f "$RETRO_SETTLE" ]]; then
  TMPDIR_RETRO="$(mktemp -d)"

  TEST_DATE="2099-01-15"
  mkdir -p "${TMPDIR_RETRO}/retro-log"
  cat > "${TMPDIR_RETRO}/retro-log/${TEST_DATE}-session-test1.md" <<'EOF'
## Retrospective — test session

### Good
- 交付準時

### Problem
- 測試覆蓋不足

### Action
- 下次加強測試
EOF

  RETRO_LOG_DIR="${TMPDIR_RETRO}/retro-log" bash "$RETRO_SETTLE" "$TEST_DATE" 2>&1
  SUMMARY="${TMPDIR_RETRO}/retro-log/${TEST_DATE}.summary.md"
  if [[ -f "$SUMMARY" ]]; then
    pass "TC-15: retro-settle.sh 成功生成 summary.md"
  else
    fail "TC-15: retro-settle.sh 未生成 summary.md"
  fi
else
  fail "TC-15: retro-settle.sh 不存在，無法測試"
fi

# ── TC-16: quality-decisions-settle.sh smoke test ────────────────
echo ""
echo "--- TC-16: quality-decisions-settle.sh smoke test ---"
if [[ -f "$QD_SETTLE" ]]; then
  TMPDIR_QD="$(mktemp -d)"

  TEST_DATE="2099-01-15"
  mkdir -p "${TMPDIR_QD}/quality-decisions"
  cat > "${TMPDIR_QD}/quality-decisions/${TEST_DATE}-session-test1.md" <<'EOF'
## 2099-01-15 — US-999

| 欄位 | 內容 |
|------|------|
| 問題描述 | 測試 CRITICAL 缺陷 |
| 選擇 | B（降級） |
| 理由 | 測試用 |
| 後續行動 | N/A |
| 審查者 | QA Engineer |
EOF

  QUALITY_DECISIONS_DIR="${TMPDIR_QD}/quality-decisions" bash "$QD_SETTLE" "$TEST_DATE" 2>&1
  SUMMARY="${TMPDIR_QD}/quality-decisions/${TEST_DATE}.summary.md"
  if [[ -f "$SUMMARY" ]]; then
    pass "TC-16: quality-decisions-settle.sh 成功生成 summary.md"
  else
    fail "TC-16: quality-decisions-settle.sh 未生成 summary.md"
  fi
else
  fail "TC-16: quality-decisions-settle.sh 不存在，無法測試"
fi

# ── TC-17: tech-debt-settle.sh smoke test ────────────────────────
echo ""
echo "--- TC-17: tech-debt-settle.sh smoke test ---"
if [[ -f "$TD_SETTLE" ]]; then
  TMPDIR_TD="$(mktemp -d)"

  TEST_DATE="2099-01-15"
  mkdir -p "${TMPDIR_TD}/tech-debt"
  cat > "${TMPDIR_TD}/tech-debt/${TEST_DATE}-session-test1.md" <<'EOF'
## Tech Debt — test session

| ID | 描述 | 嚴重度 | 引入 Story | 狀態 |
|----|------|--------|-----------|------|
| TD-099 | 測試技術債 | M | US-999 | Active |
EOF

  TECH_DEBT_DIR="${TMPDIR_TD}/tech-debt" bash "$TD_SETTLE" "$TEST_DATE" 2>&1
  SUMMARY="${TMPDIR_TD}/tech-debt/${TEST_DATE}.summary.md"
  if [[ -f "$SUMMARY" ]]; then
    pass "TC-17: tech-debt-settle.sh 成功生成 summary.md"
  else
    fail "TC-17: tech-debt-settle.sh 未生成 summary.md"
  fi
else
  fail "TC-17: tech-debt-settle.sh 不存在，無法測試"
fi

# ── 總結 ────────────────────────────────────────────────────────────
echo ""
echo "=== 結果 ==="
echo "  PASS: ${PASS}"
echo "  FAIL: ${FAIL}"
echo ""

if [[ $FAIL -eq 0 ]]; then
  echo "[OK] test-us322-batch2.sh 全部通過"
  exit 0
else
  echo "[FAIL] ${FAIL} 個測試失敗"
  exit 1
fi
