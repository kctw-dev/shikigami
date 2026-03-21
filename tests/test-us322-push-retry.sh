#!/usr/bin/env bash
# tests/test-us322-push-retry.sh
# US-#322 AC-7 TDD — PROJECT_BOARD.md push retry 機制
#
# TC-1: sprint-execution SKILL.md §3 步驟 7 含 push retry 機制說明
# TC-2: retry 機制包含 git pull --rebase
# TC-3: retry 最多 3 次
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SKILL_FILE="${REPO_ROOT}/skills/sprint-execution/SKILL.md"

PASS=0
FAIL=0

pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

echo "=== test-us322-push-retry.sh ==="

# ── TC-1: sprint-execution SKILL.md 含 push retry 機制 ───────────
echo ""
echo "--- TC-1: sprint-execution SKILL.md 含 push retry 機制 ---"

if grep -qiE 'retry|push.*失敗|push.*fail' "$SKILL_FILE" 2>/dev/null; then
  pass "TC-1: SKILL.md 含 push retry 或失敗處理邏輯"
else
  fail "TC-1: SKILL.md 未含 push retry 邏輯"
fi

# ── TC-2: retry 機制包含 git pull --rebase ────────────────────────
echo ""
echo "--- TC-2: retry 機制包含 git pull --rebase ---"

if grep -qE 'git pull --rebase|pull.*rebase' "$SKILL_FILE" 2>/dev/null; then
  pass "TC-2: SKILL.md 含 git pull --rebase 指令"
else
  fail "TC-2: SKILL.md 未含 git pull --rebase 指令"
fi

# ── TC-3: retry 最多 3 次 ─────────────────────────────────────────
echo ""
echo "--- TC-3: retry 最多 3 次 ---"

if grep -qE '最多.*3|3.*次|retry.*3|3.*retry|max.*3|3.*attempt' "$SKILL_FILE" 2>/dev/null; then
  pass "TC-3: SKILL.md 含 retry 最多 3 次說明"
else
  fail "TC-3: SKILL.md 未含 retry 最多 3 次說明"
fi

# ── 總結 ────────────────────────────────────────────────────────────
echo ""
echo "=== 結果 ==="
echo "  PASS: ${PASS}"
echo "  FAIL: ${FAIL}"
echo ""

if [[ $FAIL -eq 0 ]]; then
  echo "[OK] test-us322-push-retry.sh 全部通過"
  exit 0
else
  echo "[FAIL] ${FAIL} 個測試失敗"
  exit 1
fi
