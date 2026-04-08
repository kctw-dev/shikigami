#!/bin/bash
# Worktree cleanup after PR merge
# AC-1: Remove worktree associated with a branch
# AC-2: Execute before branch delete to prevent conflicts
# AC-3: Graceful skip if worktree doesn't exist

set -o pipefail

BRANCH_NAME="${1}"
WORKTREE_PATH="${2:-}"

if [[ -z "$BRANCH_NAME" ]]; then
  echo "[WORKTREE-CLEANUP] Error: branch name required"
  exit 1
fi

# Auto-detect worktree path if not provided
if [[ -z "$WORKTREE_PATH" ]]; then
  # Search for worktree by branch reference
  WORKTREE_PATH=$(git worktree list --porcelain 2>/dev/null | grep "branch refs/heads/$BRANCH_NAME" | awk '{print $1}' | head -1)

  if [[ -z "$WORKTREE_PATH" ]]; then
    echo "[WORKTREE-CLEANUP] No worktree found for branch: $BRANCH_NAME"
    echo "[WORKTREE-CLEANUP] Graceful skip (AC-3)"
    exit 0
  fi
fi

# Verify path is valid
if [[ ! -d "$WORKTREE_PATH" ]]; then
  echo "[WORKTREE-CLEANUP] Worktree path doesn't exist: $WORKTREE_PATH"
  echo "[WORKTREE-CLEANUP] Graceful skip (AC-3)"
  exit 0
fi

# Remove worktree (AC-1)
echo "[WORKTREE-CLEANUP] Removing worktree: $WORKTREE_PATH"
if git worktree remove "$WORKTREE_PATH" 2>/dev/null; then
  echo "[WORKTREE-CLEANUP] Successfully removed worktree: $WORKTREE_PATH"
  exit 0
else
  REMOVE_EXIT=$?
  echo "[WORKTREE-CLEANUP] Warning: Failed to remove worktree (exit code: $REMOVE_EXIT)"

  # Attempt force removal if regular removal fails
  if git worktree remove --force "$WORKTREE_PATH" 2>/dev/null; then
    echo "[WORKTREE-CLEANUP] Force removed worktree: $WORKTREE_PATH"
    exit 0
  else
    echo "[WORKTREE-CLEANUP] Error: Could not remove worktree even with force flag"
    echo "[WORKTREE-CLEANUP] Manual cleanup may be required: git worktree remove $WORKTREE_PATH"
    exit 1
  fi
fi
