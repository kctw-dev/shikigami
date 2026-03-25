#!/usr/bin/env bash
# quick-ship.sh — Shikigami Quick Ship Pipeline
# Story #798 AC1: 統一 validate -> test -> bump-patch -> commit -> push -> pr-create 單一指令交付
# AC2: --dry-run 顯示計畫動作，不執行任何副作用（NFR1: 任何時候安全執行 --dry-run）

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

DRY_RUN=false
SKIP_TESTS=false
SKIP_BUMP=false
COMMIT_MSG=""

usage() {
  cat <<USAGE
Usage: quick-ship.sh [options] [commit-message]

Quick Ship Pipeline: validate → test → bump-patch → commit → push → pr-create

Options:
  --dry-run      Show planned steps without executing (always safe, NFR1)
  --skip-tests   Skip test step (use with caution)
  --skip-bump    Skip version bump
  --help, -h     Show this help

Examples:
  quick-ship.sh "feat: add new skill"
  quick-ship.sh --dry-run
  quick-ship.sh --skip-bump "docs: update README"
USAGE
  exit 0
}

step() { echo "[QUICK-SHIP] Step: $1"; }
dry()  { echo "[DRY-RUN]    Would: $1"; }
ok()   { echo "[QUICK-SHIP] OK: $1"; }
fail() { echo "[QUICK-SHIP] FAIL: $1" >&2; exit 1; }

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)    DRY_RUN=true;    shift ;;
    --skip-tests) SKIP_TESTS=true; shift ;;
    --skip-bump)  SKIP_BUMP=true;  shift ;;
    --help|-h)    usage ;;
    *)
      if [[ -z "$COMMIT_MSG" ]]; then COMMIT_MSG="$1"; fi
      shift ;;
  esac
done

echo "=== Quick Ship Pipeline ==="
echo "  Repo: $REPO_ROOT"
echo "  Mode: $([[ "$DRY_RUN" == "true" ]] && echo 'DRY-RUN (no side effects)' || echo 'EXECUTE')"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
  echo "[DRY-RUN] Planned pipeline steps:"
  dry "1. validate — bash scripts/validate-version.sh + validate-json.sh"
  dry "2. test — bash tests/test-*.sh"
  dry "3. bump-patch — bash scripts/bump-version.sh patch"
  dry "4. commit — git add -A && git commit -m '${COMMIT_MSG:-<auto>}'"
  dry "5. push — git push origin main"
  dry "6. pr-create — gh pr create (if on non-main branch)"
  echo ""
  echo "[DRY-RUN] No changes made. Exit 0."
  exit 0
fi

cd "$REPO_ROOT"

# Step 1: validate
step "1/6 validate"
VALIDATE_ERRORS=0
for script in scripts/validate-version.sh scripts/validate-json.sh; do
  if [[ -f "$script" ]]; then
    if bash "$script" 2>/dev/null; then
      ok "$script passed"
    else
      echo "[QUICK-SHIP] WARN: $script failed (exit code: $?)"
      VALIDATE_ERRORS=$((VALIDATE_ERRORS+1))
    fi
  fi
done
if [[ $VALIDATE_ERRORS -gt 0 ]]; then
  fail "Validation failed ($VALIDATE_ERRORS errors). Fix before shipping."
fi

# Step 2: test
step "2/6 test"
if [[ "$SKIP_TESTS" == "true" ]]; then
  echo "[QUICK-SHIP] SKIP: tests (--skip-tests)"
else
  TEST_FAILED=0
  for test_script in tests/test-*.sh; do
    [[ -f "$test_script" ]] || continue
    if bash "$test_script" 2>/dev/null; then
      ok "$test_script passed"
    else
      echo "[QUICK-SHIP] FAIL: $test_script (exit: $?)"
      TEST_FAILED=$((TEST_FAILED+1))
    fi
  done
  if [[ $TEST_FAILED -gt 0 ]]; then
    fail "Tests failed ($TEST_FAILED failures). Fix before shipping."
  fi
fi

# Step 3: bump-patch
step "3/6 bump-patch"
if [[ "$SKIP_BUMP" == "true" ]]; then
  echo "[QUICK-SHIP] SKIP: version bump (--skip-bump)"
else
  if [[ -f "scripts/bump-version.sh" ]]; then
    if bash scripts/bump-version.sh patch 2>/dev/null; then
      ok "version bumped (patch)"
    else
      echo "[QUICK-SHIP] WARN: bump-version.sh failed, continuing"
    fi
  else
    echo "[QUICK-SHIP] WARN: bump-version.sh not found, skipping"
  fi
fi

# Step 4: commit
step "4/6 commit"
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
if [[ -z "$(git status --porcelain 2>/dev/null)" ]]; then
  echo "[QUICK-SHIP] SKIP: nothing to commit"
else
  FINAL_MSG="${COMMIT_MSG:-chore: quick-ship auto-commit $(date '+%Y-%m-%dT%H:%M')}"
  git add -A
  if git commit -m "$FINAL_MSG"; then
    ok "committed: $FINAL_MSG"
  else
    fail "git commit failed"
  fi
fi

# Step 5: push
step "5/6 push"
if git push origin "$CURRENT_BRANCH" 2>/dev/null; then
  ok "pushed to $CURRENT_BRANCH"
else
  fail "git push failed (exit: $?)"
fi

# Step 6: pr-create (only if not on main/master)
step "6/6 pr-create"
if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
  echo "[QUICK-SHIP] SKIP: on $CURRENT_BRANCH, no PR needed"
else
  if command -v gh &>/dev/null; then
    PR_TITLE="${COMMIT_MSG:-quick-ship from $CURRENT_BRANCH}"
    printf '%s\n' "Auto-created by quick-ship.sh" "" "Branch: $CURRENT_BRANCH" "🤖 Generated with Claude Code" > /tmp/quick-ship-pr-body.txt
    if gh pr create --title "$PR_TITLE" --body-file /tmp/quick-ship-pr-body.txt --base main 2>/dev/null; then
      ok "PR created"
    else
      echo "[QUICK-SHIP] WARN: gh pr create failed (PR may already exist)"
    fi
  else
    echo "[QUICK-SHIP] WARN: gh CLI not available, skipping PR creation"
  fi
fi

echo ""
echo "=== Quick Ship Complete ==="
