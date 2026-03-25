#!/usr/bin/env bash
# init-project.sh — Shikigami 專案快速初始化腳本
# Story #797 AC2: Copies template files to target directory with project name substitution
# NFR1: Does not overwrite existing files without --force flag

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TEMPLATE_DIR="${REPO_ROOT}/templates/project-template"

usage() {
  echo "Usage: $0 [--dry-run] [--force] <target-dir> <project-name>"
  echo ""
  echo "Options:"
  echo "  --dry-run     Show planned actions without executing"
  echo "  --force       Overwrite existing files"
  echo ""
  echo "Arguments:"
  echo "  target-dir    Target directory for the new project"
  echo "  project-name  Project name (used for substitution in templates)"
  exit 1
}

DRY_RUN=false
FORCE=false

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --force)   FORCE=true;   shift ;;
    --help|-h) usage ;;
    *) break ;;
  esac
done

TARGET_DIR="${1:-}"
PROJECT_NAME="${2:-}"

if [[ -z "$TARGET_DIR" || -z "$PROJECT_NAME" ]]; then
  echo "[ERROR] Missing required arguments: target-dir and project-name"
  usage
fi

if [[ ! -d "$TEMPLATE_DIR" ]]; then
  echo "[ERROR] Template directory not found: $TEMPLATE_DIR"
  exit 1
fi

if [[ "$DRY_RUN" == "true" ]]; then
  echo "[DRY-RUN] init-project.sh — planned actions:"
  echo "  Source template: $TEMPLATE_DIR"
  echo "  Target directory: $TARGET_DIR"
  echo "  Project name: $PROJECT_NAME"
  echo "  Files to copy:"
  for f in "$TEMPLATE_DIR"/.* "$TEMPLATE_DIR"/*; do
    fname=$(basename "$f")
    [[ "$fname" == "." || "$fname" == ".." ]] && continue
    [[ -f "$f" ]] || continue
    target_file="$TARGET_DIR/$fname"
    if [[ -f "$target_file" && "$FORCE" == "false" ]]; then
      echo "    SKIP (exists): $fname"
    else
      echo "    COPY: $fname"
    fi
  done
  exit 0
fi

# Create target directory if it doesn't exist
if [[ ! -d "$TARGET_DIR" ]]; then
  mkdir -p "$TARGET_DIR"
  echo "[INIT] Created directory: $TARGET_DIR"
fi

COPIED=0
SKIPPED=0

# Copy template files with project name substitution
for f in "$TEMPLATE_DIR"/.* "$TEMPLATE_DIR"/*; do
  fname=$(basename "$f")
  [[ "$fname" == "." || "$fname" == ".." ]] && continue
  [[ -f "$f" ]] || continue

  target_file="$TARGET_DIR/$fname"

  # NFR1: Skip existing files without --force
  if [[ -f "$target_file" && "$FORCE" == "false" ]]; then
    echo "[SKIP] Already exists (use --force to overwrite): $fname"
    SKIPPED=$((SKIPPED+1))
    continue
  fi

  # Perform substitution: {{PROJECT_NAME}} and {{OWNER_REPO}}
  sed "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g; s/{{OWNER_REPO}}/${PROJECT_NAME}/g" \
    "$f" > "$target_file"

  echo "[COPY] $fname → $TARGET_DIR/$fname"
  COPIED=$((COPIED+1))
done

echo ""
echo "[INIT-COMPLETE] Project '$PROJECT_NAME' initialized at $TARGET_DIR"
echo "  Files copied: $COPIED, skipped: $SKIPPED"
echo ""
echo "Next steps:"
echo "  1. cd $TARGET_DIR"
echo "  2. Review and customize CLAUDE.md and shikigami.local.md"
echo "  3. mkdir -p docs/{adr,sprints,km,prd}"
