#!/usr/bin/env bash
# test-quality-gate-audit.sh — #779 AC4
# Tests for quality-gate-audit.sh and quality-gate-decisions.md format

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS_COUNT=0
FAIL_COUNT=0

pass() { echo "[PASS] $1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { echo "[FAIL] $1: $2"; FAIL_COUNT=$((FAIL_COUNT+1)); }

echo "=== test-quality-gate-audit.sh ==="

# TC1: quality-gate-decisions.md exists with correct header columns
DECISIONS_FILE="${REPO_ROOT}/docs/km/quality-gate-decisions.md"
if [[ -f "$DECISIONS_FILE" ]]; then
  if grep -q "Date.*Story.*Finding.*Severity.*Decision.*Rationale.*Sprint" "$DECISIONS_FILE"; then
    pass "TC1: quality-gate-decisions.md exists with correct header"
  else
    fail "TC1" "quality-gate-decisions.md missing required columns (Date|Story|Finding|Severity|Decision|Rationale|Sprint)"
  fi
else
  fail "TC1" "quality-gate-decisions.md not found at docs/km/quality-gate-decisions.md"
fi

# TC2: quality-gate-audit.sh exists and is executable
AUDIT_SCRIPT="${REPO_ROOT}/scripts/quality-gate-audit.sh"
if [[ -x "$AUDIT_SCRIPT" ]]; then
  pass "TC2: quality-gate-audit.sh exists and is executable"
else
  fail "TC2" "quality-gate-audit.sh not found or not executable"
fi

# TC3: audit script outputs Accept/Reject/Defer counts with seeded data
SEED_FILE=$(mktemp /tmp/qg-decisions-seed-XXXXXX.md)
cat > "$SEED_FILE" << 'SEEDEOF'
# Quality Gate Decisions

| Date | Story | Finding | Severity | Decision | Rationale | Sprint |
|------|-------|---------|----------|----------|-----------|--------|
| 2026-01-10 | #700 | Hardcoded secret in config | CRITICAL | Accept | Low exposure, will rotate | 150 |
| 2026-01-15 | #705 | SQL injection vector | CRITICAL | Reject | Must fix before merge | 150 |
| 2026-01-20 | #710 | Unused import | MEDIUM | Accept | Cosmetic, negligible | 151 |
| 2026-01-25 | #715 | Missing input validation | CRITICAL | Accept | Low priority endpoint | 151 |
| 2026-02-01 | #720 | XSS via template | HIGH | Defer | Sprint 152 backlog | 151 |
| 2026-02-10 | #730 | Race condition | CRITICAL | Accept | Rare edge case | 152 |
SEEDEOF

if [[ -x "$AUDIT_SCRIPT" ]]; then
  AUDIT_OUT=$("$AUDIT_SCRIPT" "$SEED_FILE" 2>&1)
  if echo "$AUDIT_OUT" | grep -q "Accept" && echo "$AUDIT_OUT" | grep -q "Reject"; then
    pass "TC3: audit script outputs Accept/Reject counts from seeded data"
  else
    fail "TC3" "audit script output missing Accept/Reject counts. Got: ${AUDIT_OUT}"
  fi
  rm -f "$SEED_FILE"
else
  fail "TC3" "audit script not executable, skipping seeded test"
  rm -f "$SEED_FILE"
fi

# TC4: audit script detects pattern (same category accepted 3+ times)
SEED_FILE2=$(mktemp /tmp/qg-decisions-pattern-XXXXXX.md)
cat > "$SEED_FILE2" << 'SEEDEOF'
# Quality Gate Decisions

| Date | Story | Finding | Severity | Decision | Rationale | Sprint |
|------|-------|---------|----------|----------|-----------|--------|
| 2026-01-10 | #700 | Hardcoded secret in config | CRITICAL | Accept | Low exposure | 150 |
| 2026-01-15 | #705 | Hardcoded secret in env | CRITICAL | Accept | Will rotate | 150 |
| 2026-01-20 | #710 | Hardcoded secret in test | CRITICAL | Accept | Test only | 151 |
| 2026-01-25 | #715 | SQL injection vector | CRITICAL | Reject | Must fix | 151 |
SEEDEOF

if [[ -x "$AUDIT_SCRIPT" ]]; then
  AUDIT_OUT2=$("$AUDIT_SCRIPT" "$SEED_FILE2" 2>&1)
  if echo "$AUDIT_OUT2" | grep -qi "pattern\|3\+\|repeated\|CRITICAL.*Accept.*3\|Accept.*3"; then
    pass "TC4: audit script detects repeated Accept pattern"
  else
    fail "TC4" "audit script did not detect pattern (3+ CRITICAL Accept). Got: ${AUDIT_OUT2}"
  fi
  rm -f "$SEED_FILE2"
else
  fail "TC4" "audit script not executable, skipping pattern test"
  rm -f "$SEED_FILE2"
fi

# TC5: sprint-review SKILL.md references quality-gate-decisions.md
SPRINT_REVIEW_SKILL="${REPO_ROOT}/skills/sprint-review/SKILL.md"
if [[ -f "$SPRINT_REVIEW_SKILL" ]]; then
  if grep -q "quality-gate-decisions" "$SPRINT_REVIEW_SKILL"; then
    pass "TC5: sprint-review SKILL.md references quality-gate-decisions.md"
  else
    fail "TC5" "sprint-review SKILL.md missing quality-gate-decisions.md reference"
  fi
else
  fail "TC5" "skills/sprint-review/SKILL.md not found"
fi

echo ""
if [[ $FAIL_COUNT -eq 0 ]]; then
  echo "=== All quality-gate audit tests PASS ==="
  exit 0
else
  echo "=== ${FAIL_COUNT} test(s) FAILED, ${PASS_COUNT} PASS ==="
  exit 1
fi
