#!/usr/bin/env bash
# tests/test-721-backlog-replenishment.sh
# Story #721 — Backlog 補充頻率調整驗收測試
#
# ── 目的 ──────────────────────────────────────────────────────────────────
#
# 驗收標準：
#   AC1: skills/backlog-management/SKILL.md 包含調整後的閾值邏輯（< 10）
#   AC2: .claude/shikigami.local.md backlog_health.threshold = 10
#   AC3: 參照 ADR-043（不是 ADR-041）記錄決策邏輯
#
# ── 使用方式 ─────────────────────────────────────────────────────────────
#   bash tests/test-721-backlog-replenishment.sh
# ─────────────────────────────────────────────────────────────────────────

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PASS_COUNT=0
FAIL_COUNT=0

pass() { echo "  [PASS] $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { echo "  [FAIL] $1"; echo "    [DIAG] $2"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

echo "=== Backlog 補充頻率調整測試套件 (#721) ==="
echo ""

BACKLOG_SKILL="${REPO_ROOT}/skills/backlog-management/SKILL.md"
LOCAL_CONFIG="${REPO_ROOT}/.claude/shikigami.local.md"
SPRINT_REVIEW_SKILL="${REPO_ROOT}/skills/sprint-review/SKILL.md"

# ─── AC1: SKILL.md 閾值邏輯 ──────────────────────────────────────────────
echo "--- AC1: backlog-management/SKILL.md 閾值邏輯更新 ---"

if [[ -f "${BACKLOG_SKILL}" ]]; then
  pass "AC1a: backlog-management/SKILL.md 存在"
else
  fail "AC1a: backlog-management/SKILL.md 不存在" \
    "找不到 ${BACKLOG_SKILL}"
fi

# 驗證 SKILL.md 包含 10 的閾值（proactive threshold）
if grep -q "sprint.candidate.*10\|10.*sprint.candidate\|threshold.*10\|< 10\|閾值.*10\|10.*閾值\|目標.*16\|16.*目標\|2.Sprint\|proactive" "${BACKLOG_SKILL}" 2>/dev/null; then
  pass "AC1b: SKILL.md 包含新閾值邏輯（10 / 2-Sprint 提前期）"
else
  fail "AC1b: SKILL.md 缺少新閾值邏輯" \
    "backlog-management/SKILL.md 需要包含 threshold=10 / 目標>=16 / 提前預警機制"
fi

# 驗證 sprint-review SKILL.md 預設值已更新
if grep -q "threshold.*10\|default.*10\|預設.*10\|10.*預設\|10.*default" "${SPRINT_REVIEW_SKILL}" 2>/dev/null; then
  pass "AC1c: sprint-review/SKILL.md 預設閾值已更新為 10"
else
  fail "AC1c: sprint-review/SKILL.md 預設閾值仍為 8" \
    "sprint-review/SKILL.md 需要將預設值 8 改為 10"
fi

echo ""

# ─── AC2: .claude/shikigami.local.md 閾值設定 ──────────────────────────
echo "--- AC2: shikigami.local.md 閾值設定 ---"

if [[ -f "${LOCAL_CONFIG}" ]]; then
  pass "AC2a: shikigami.local.md 存在"

  # 讀取 backlog_health.threshold 值
  THRESHOLD_VAL=$(grep -A 2 "backlog_health:" "${LOCAL_CONFIG}" | grep "threshold:" | awk '{print $2}' || echo "NOT_FOUND")
  if [[ "${THRESHOLD_VAL}" == "10" ]]; then
    pass "AC2b: backlog_health.threshold = 10（已從 8 更新）"
  else
    fail "AC2b: backlog_health.threshold = ${THRESHOLD_VAL}（期望 10）" \
      ".claude/shikigami.local.md 的 backlog_health.threshold 需從 8 改為 10"
  fi
else
  fail "AC2a: shikigami.local.md 不存在" \
    "找不到 ${LOCAL_CONFIG}"
fi

echo ""

# ─── AC3: ADR-043 參照 ───────────────────────────────────────────────────
echo "--- AC3: ADR-043 參照 ---"

ADR_043="${REPO_ROOT}/docs/adr/ADR-043-backlog-replenishment-strategy.md"
if [[ -f "${ADR_043}" ]]; then
  pass "AC3a: ADR-043 存在（#723 已建立）"
else
  fail "AC3a: ADR-043 不存在" \
    "需要先完成 #723 建立 ADR-043"
fi

# 確認 SKILL.md 引用 ADR-043（而非 ADR-041）
if grep -q "ADR-043\|ADR-043-backlog" "${BACKLOG_SKILL}" 2>/dev/null; then
  pass "AC3b: backlog-management/SKILL.md 引用 ADR-043"
elif grep -q "ADR-041" "${BACKLOG_SKILL}" 2>/dev/null; then
  fail "AC3b: SKILL.md 引用了錯誤的 ADR-041" \
    "應引用 ADR-043（ADR-041 已被 crash-recovery-design 使用）"
else
  fail "AC3b: SKILL.md 未引用 ADR-043" \
    "backlog-management/SKILL.md 需要引用 ADR-043-backlog-replenishment-strategy.md"
fi

echo ""

# ─── 摘要 ────────────────────────────────────────────────────────────────
echo "=== 摘要 ==="
echo "PASS: ${PASS_COUNT}, FAIL: ${FAIL_COUNT}"
echo ""

if [[ "${FAIL_COUNT}" -eq 0 ]]; then
  echo "[RESULT] PASS — 全部 ${PASS_COUNT} 項測試通過"
  exit 0
else
  echo "[RESULT] FAIL — ${FAIL_COUNT} 項測試失敗，${PASS_COUNT} 項通過"
  exit 1
fi
