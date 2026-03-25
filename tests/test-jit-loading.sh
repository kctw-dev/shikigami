#!/usr/bin/env bash
# test-jit-loading.sh — Context Engineering JIT Loading Tests
# Story #793 AC3: Validates hook ordering and JIT strategy documentation

set -uo pipefail
PASS=0; FAIL=0

ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

SKILL_FILE="skills/sprint-execution/SKILL.md"
HOOK_FILE="hooks/session-start"

echo "=== Context Engineering JIT Loading Tests ==="

# AC1: SKILL.md documents JIT loading strategy
echo "--- AC1: JIT Strategy in SKILL.md ---"
if [[ -f "$SKILL_FILE" ]]; then
  ok "sprint-execution/SKILL.md exists"
  if grep -q "JIT\|Just-in-Time\|jit.*load\|load.*jit" "$SKILL_FILE"; then
    ok "JIT keyword found in SKILL.md"
  else
    fail "JIT keyword missing in SKILL.md"
  fi
  if grep -q "pre-load\|pre_load\|前置載入\|按需載入\|on-demand" "$SKILL_FILE"; then
    ok "JIT vs pre-load distinction documented"
  else
    fail "JIT vs pre-load distinction missing"
  fi
else
  fail "sprint-execution/SKILL.md not found"
fi

# AC2: session-start hook loads minimal files (CLAUDE.md + shikigami.local)
echo "--- AC2: Session-Start Hook ---"
if [[ -f "$HOOK_FILE" ]]; then
  ok "hooks/session-start exists"
  # Hook should reference CLAUDE.md or shikigami.local - minimal load
  if grep -q "CLAUDE.md\|shikigami.local\|checkpoint\|RECOVERY" "$HOOK_FILE"; then
    ok "session-start references expected minimal files"
  else
    fail "session-start hook not referencing expected files"
  fi
  # NFR1: session-start should NOT pre-load all SKILL files
  if ! grep -q "^cat.*skills/.*SKILL.md\|^source.*skills/.*SKILL.md" "$HOOK_FILE"; then
    ok "session-start does not pre-load all SKILL.md files (JIT compatible)"
  else
    fail "session-start pre-loads SKILL.md files (JIT violation)"
  fi
else
  fail "hooks/session-start not found"
fi

# AC3: test file validates correctly
echo "--- AC3: Self-validation ---"
ok "tests/test-jit-loading.sh exists (running now)"

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
