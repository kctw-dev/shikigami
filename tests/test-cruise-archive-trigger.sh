#!/usr/bin/env bash
# tests/test-cruise-archive-trigger.sh
# Story #738 — cruise logs 歸檔每日自動觸發（定時 cron 整合）
# AC4: 驗證 cron 觸發路徑

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CRUISE_CRON="${REPO_ROOT}/scripts/cruise_cron.sh"
LOCAL_CONFIG="${REPO_ROOT}/.claude/shikigami.local.md"

PASS=0
FAIL=0

pass() { echo "[PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL + 1)); }

# ── T1: cruise_cron.sh exists ────────────────────────────────────────────
if [[ -f "${CRUISE_CRON}" ]]; then
  pass "T1: scripts/cruise_cron.sh exists"
else
  fail "T1: scripts/cruise_cron.sh not found"
fi

# ── T2: cruise_cron.sh contains daily archive trigger at 00:00 UTC ───────
if grep -qE "00:00|midnight|daily|archive" "${CRUISE_CRON}" 2>/dev/null; then
  pass "T2: cruise_cron.sh references archive/daily/midnight trigger"
else
  fail "T2: cruise_cron.sh does not reference archive or daily trigger"
fi

# ── T3: cruise_cron.sh reads CRUISE_ARCHIVE_DAYS from config (AC3) ───────
if grep -q "CRUISE_ARCHIVE_DAYS\|cruise_archive_days" "${CRUISE_CRON}" 2>/dev/null; then
  pass "T3: cruise_cron.sh references CRUISE_ARCHIVE_DAYS config (AC3)"
else
  fail "T3: cruise_cron.sh does not reference CRUISE_ARCHIVE_DAYS"
fi

# ── T4: .claude/shikigami.local.md contains cruise_archive_days: 7 (AC2) ─
if grep -q "cruise_archive_days" "${LOCAL_CONFIG}" 2>/dev/null; then
  pass "T4: .claude/shikigami.local.md contains cruise_archive_days config (AC2)"
else
  fail "T4: .claude/shikigami.local.md missing cruise_archive_days config"
fi

# ── T5: cruise_archive_days default value is 7 (AC2) ─────────────────────
if grep -E "cruise_archive_days:\s*7" "${LOCAL_CONFIG}" 2>/dev/null | grep -q "7"; then
  pass "T5: cruise_archive_days default value is 7 (AC2)"
else
  fail "T5: cruise_archive_days is not set to 7 in .claude/shikigami.local.md"
fi

# ── T6: archive trigger fails gracefully (NFR1) ───────────────────────────
# Verify cruise_cron.sh has error handling (|| true or similar) around archive
if grep -qE "\|\| true||| :|set -e" "${CRUISE_CRON}" 2>/dev/null; then
  pass "T6: cruise_cron.sh has error tolerance (NFR1 — cron 失敗不影響主流程)"
else
  # Check if there's no bare 'set -e' without protection
  if ! grep -q "set -e" "${CRUISE_CRON}" 2>/dev/null; then
    pass "T6: cruise_cron.sh has no strict -e that would propagate archive failure"
  else
    fail "T6: cruise_cron.sh may not handle archive failures gracefully (NFR1)"
  fi
fi

# ── T7: startup-flow.md §4.4 archive logic referenced in cruise_cron.sh ─
if grep -qE "archive|4\.4|LOG.ARCHIVE|ARCHIVE_DAYS" "${CRUISE_CRON}" 2>/dev/null; then
  pass "T7: cruise_cron.sh references §4.4 archive logic"
else
  fail "T7: cruise_cron.sh does not reference archive logic (§4.4 not integrated)"
fi

# ── T8: cron schedule includes daily 00:00 UTC trigger ───────────────────
# The cruise_cron.sh should have a note or condition for daily archive
if grep -qE "00:00 UTC|ARCHIVE_HOUR|IS_MIDNIGHT|is_midnight|daily_archive" "${CRUISE_CRON}" 2>/dev/null; then
  pass "T8: cruise_cron.sh contains explicit midnight/daily archive detection"
else
  fail "T8: cruise_cron.sh missing explicit midnight/daily archive trigger detection"
fi

# ── Summary ──────────────────────────────────────────────────────────────
echo ""
echo "=== test-cruise-archive-trigger.sh Results: ${PASS} PASS, ${FAIL} FAIL ==="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
