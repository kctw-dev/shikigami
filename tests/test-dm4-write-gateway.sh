#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

pass() { echo "[PASS] $1"; }
fail() { echo "[FAIL] $1 — $2"; exit 1; }

echo "=== test-dm4-write-gateway.sh ==="

# TC1: SKILL.md contains coordinator-only file list
SKILL_CONTENT=$(cat "$REPO_ROOT/skills/sprint-execution/SKILL.md")
echo "$SKILL_CONTENT" | grep -q "coordinator-only" || fail "TC1" "SKILL.md missing coordinator-only reference"
pass "TC1: SKILL.md contains coordinator-only reference"

# TC2: story-lifecycle-prompt.md contains DM-4 HARD-GATE
LIFECYCLE_CONTENT=$(cat "$REPO_ROOT/skills/sprint-execution/story-lifecycle-prompt.md")
echo "$LIFECYCLE_CONTENT" | grep -q "coordinator-only\|DM-4\|禁止直接修改" || \
  fail "TC2" "story-lifecycle-prompt.md missing DM-4 hard gate"
pass "TC2: story-lifecycle-prompt.md contains DM-4 hard gate"

# TC3: Coordinator-only files are listed: PROJECT_BOARD.md, sprint_N.md, sprint-checkpoint.json
echo "$SKILL_CONTENT" | grep -qE "PROJECT_BOARD\.md" || fail "TC3a" "Missing PROJECT_BOARD.md in coordinator-only list"
echo "$SKILL_CONTENT" | grep -qE "sprint_N\.md|sprint_\[N\]\.md|sprint.*\.md" || fail "TC3b" "Missing sprint_N.md in coordinator-only list"
echo "$SKILL_CONTENT" | grep -qE "sprint-checkpoint\.json|checkpoint\.json" || fail "TC3c" "Missing checkpoint.json in coordinator-only list"
pass "TC3: All coordinator-only files listed in SKILL.md"

echo "=== All DM-4 Write Gateway tests PASS ==="
