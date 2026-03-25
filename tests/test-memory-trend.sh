#!/usr/bin/env bash
# tests/test-memory-trend.sh
# Story #743 — SRE patrol 記憶體使用趨勢偵測（漸進式洩漏告警）
# AC4: 模擬下降趨勢並驗證告警觸發

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MEMORY_TREND_SCRIPT="${REPO_ROOT}/scripts/memory-trend-check.sh"

PASS=0
FAIL=0
TEST_TMPDIR=$(mktemp -d)
trap "rm -rf ${TEST_TMPDIR}" EXIT

pass() { echo "[PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL + 1)); }

# ── Helper: create fake cruise log with sre-memory-check entries ──────────
make_log() {
  local log_file="$1"
  shift
  local ts="2026-03-25T10:00:00Z"
  > "$log_file"
  for mb in "$@"; do
    echo "{\"ts\":\"${ts}\",\"type\":\"sre-memory-check\",\"session\":\"test\",\"available_mb\":${mb}}" >> "$log_file"
  done
}

# ── T1: Script exists and is executable ──────────────────────────────────
if [[ -f "${MEMORY_TREND_SCRIPT}" && -x "${MEMORY_TREND_SCRIPT}" ]]; then
  pass "T1: memory-trend-check.sh exists and is executable"
else
  fail "T1: memory-trend-check.sh not found or not executable at ${MEMORY_TREND_SCRIPT}"
fi

# ── T2: No warn when fewer than 3 records (reliability — QA Minor AC5) ───
LOG="${TEST_TMPDIR}/cruise-log-t2.jsonl"
make_log "$LOG" 1000 900
OUTPUT=$(bash "${MEMORY_TREND_SCRIPT}" --log-file "$LOG" 2>&1 || true)
if echo "$OUTPUT" | grep -q "\[MEMORY-TREND-WARN\]"; then
  fail "T2: should NOT warn with < 3 records, but got WARN"
else
  pass "T2: no [MEMORY-TREND-WARN] with only 2 records (reliability boundary)"
fi

# ── T3: No warn when 3 records but NOT all declining > 10% ───────────────
LOG="${TEST_TMPDIR}/cruise-log-t3.jsonl"
make_log "$LOG" 1000 950 940  # last drop only ~1%
OUTPUT=$(bash "${MEMORY_TREND_SCRIPT}" --log-file "$LOG" 2>&1 || true)
if echo "$OUTPUT" | grep -q "\[MEMORY-TREND-WARN\]"; then
  fail "T3: should NOT warn when decline < 10%, but got WARN"
else
  pass "T3: no [MEMORY-TREND-WARN] when last drop < 10%"
fi

# ── T4: WARN when 3 consecutive records each declining > 10% ─────────────
LOG="${TEST_TMPDIR}/cruise-log-t4.jsonl"
make_log "$LOG" 1000 800 600  # 20% drop then 25% drop — both > 10%
OUTPUT=$(bash "${MEMORY_TREND_SCRIPT}" --log-file "$LOG" 2>&1 || true)
if echo "$OUTPUT" | grep -q "\[MEMORY-TREND-WARN\]"; then
  pass "T4: [MEMORY-TREND-WARN] triggered correctly for consecutive >10% drops"
else
  fail "T4: expected [MEMORY-TREND-WARN] for consecutive >10% drops, got: ${OUTPUT}"
fi

# ── T5: Configurable window — uses last N records (NFR2) ─────────────────
LOG="${TEST_TMPDIR}/cruise-log-t5.jsonl"
# 5 records; first 3 stable, last 3 declining
make_log "$LOG" 2000 1950 1800 1400 1000  # last 3 show significant drops
OUTPUT=$(bash "${MEMORY_TREND_SCRIPT}" --log-file "$LOG" --window 3 2>&1 || true)
if echo "$OUTPUT" | grep -q "\[MEMORY-TREND-WARN\]"; then
  pass "T5: window=3 correctly triggers WARN on last 3 records with drops"
else
  fail "T5: expected [MEMORY-TREND-WARN] with --window 3, got: ${OUTPUT}"
fi

# ── T6: No external tools — pure bash/jq ─────────────────────────────────
# Verify script content does not use python/perl/awk for logic
if grep -qE "^\s*(python|perl|ruby|node)" "${MEMORY_TREND_SCRIPT}" 2>/dev/null; then
  fail "T6: script uses external tools (python/perl/ruby/node) — violates NFR1"
else
  pass "T6: script uses only bash/jq (NFR1 compliant)"
fi

# ── T7: sre-inspection.md contains memory check logging ──────────────────
SRE_INSP="${REPO_ROOT}/skills/cruise/references/sre-inspection.md"
if grep -q "sre-memory-check" "${SRE_INSP}" 2>/dev/null; then
  pass "T7: sre-inspection.md contains sre-memory-check logging (AC1)"
else
  fail "T7: sre-inspection.md missing sre-memory-check logging"
fi

# ── Summary ──────────────────────────────────────────────────────────────
echo ""
echo "=== test-memory-trend.sh Results: ${PASS} PASS, ${FAIL} FAIL ==="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
