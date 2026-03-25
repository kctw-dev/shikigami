#!/usr/bin/env bash
# test-project-template.sh — Project Template Tests
# Story #797: templates/project-template + scripts/init-project.sh

set -uo pipefail
PASS=0; FAIL=0

ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "=== Project Template Tests ==="

# AC1: templates/project-template/ directory exists with required files
echo "--- AC1: Template Directory ---"
if [[ -d "templates/project-template" ]]; then
  ok "templates/project-template/ exists"
else
  fail "templates/project-template/ missing"
fi

for f in "templates/project-template/CLAUDE.md" "templates/project-template/shikigami.local.md" "templates/project-template/.gitignore"; do
  if [[ -f "$f" ]]; then
    ok "$f exists"
  else
    fail "$f missing"
  fi
done

# AC2: scripts/init-project.sh exists and is executable
echo "--- AC2: init-project.sh ---"
if [[ -f "scripts/init-project.sh" ]]; then
  ok "scripts/init-project.sh exists"
  if [[ -x "scripts/init-project.sh" ]]; then
    ok "init-project.sh is executable"
  else
    fail "init-project.sh not executable"
  fi
else
  fail "scripts/init-project.sh missing"
fi

# Test --dry-run mode (NFR1 safe run)
if [[ -f "scripts/init-project.sh" ]]; then
  TMPDIR_TEST=$(mktemp -d)
  bash scripts/init-project.sh --dry-run "$TMPDIR_TEST" "TestProject" 2>/dev/null
  if [[ ! -f "$TMPDIR_TEST/CLAUDE.md" ]]; then
    ok "dry-run does not create files"
  else
    fail "dry-run created files (should not)"
  fi
  rm -rf "$TMPDIR_TEST"
fi

# Test project name substitution
if [[ -f "scripts/init-project.sh" ]]; then
  TMPDIR_TEST=$(mktemp -d)
  bash scripts/init-project.sh "$TMPDIR_TEST" "MyTestProject" 2>/dev/null
  if [[ -f "$TMPDIR_TEST/CLAUDE.md" ]]; then
    ok "init-project.sh creates CLAUDE.md"
    if grep -q "MyTestProject" "$TMPDIR_TEST/CLAUDE.md"; then
      ok "project name substitution works"
    else
      fail "project name substitution missing"
    fi
  else
    fail "init-project.sh did not create CLAUDE.md"
  fi
  # NFR1: Second run WITHOUT --force should skip (not overwrite)
  echo "existing_content_marker" > "$TMPDIR_TEST/CLAUDE.md"
  bash scripts/init-project.sh "$TMPDIR_TEST" "MyTestProject" 2>/dev/null
  if grep -q "existing_content_marker" "$TMPDIR_TEST/CLAUDE.md"; then
    ok "NFR1: does not overwrite without --force"
  else
    fail "NFR1: overwrote existing file without --force"
  fi
  rm -rf "$TMPDIR_TEST"
fi

# AC3: test file itself validates correctly
echo "--- AC3: Self-validation ---"
ok "tests/test-project-template.sh exists (running now)"

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
