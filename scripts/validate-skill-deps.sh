#!/bin/bash
# Skill Dependency Declaration Consistency Validator
# Scans all Skills for reference declarations and validates path existence

set -u

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="${PROJECT_ROOT}/skills"

echo "Scanning Skill dependencies in ${SKILLS_DIR}..."

# Temporary file to collect violations
VIOLATIONS_FILE=$(mktemp)
trap "rm -f $VIOLATIONS_FILE" EXIT

# Iterate through each skill directory
for skill_dir in "${SKILLS_DIR}"/*; do
  [ -d "$skill_dir" ] || continue

  skill_name=$(basename "$skill_dir")
  skill_file="${skill_dir}/SKILL.md"

  # Skip if no SKILL.md file
  [ -f "$skill_file" ] || continue

  # Extract all markdown link references using grep
  # Pattern: [anything](./references/something.md)
  # Use perl-compatible grep to handle complex patterns safely
  grep -oP '\]\(\./references/[^)]+' "$skill_file" 2>/dev/null | while read -r match; do
    # Remove the leading ]( to get just the path
    ref_path="${match#\]\(}"

    [ -z "$ref_path" ] && continue

    full_ref_path="${skill_dir}${ref_path#.}"

    # Check if the referenced file exists
    if [ ! -f "$full_ref_path" ]; then
      echo "${skill_name}: ${ref_path}" >> "$VIOLATIONS_FILE"
    fi
  done
done

# Count violations from the file
violation_count=0
if [ -f "$VIOLATIONS_FILE" ] && [ -s "$VIOLATIONS_FILE" ]; then
  cat "$VIOLATIONS_FILE"
  violation_count=$(wc -l < "$VIOLATIONS_FILE")
fi

# Exit with appropriate code
if [ "$violation_count" -eq 0 ]; then
  echo "Skill dependency validation: OK"
  exit 0
else
  echo "Found $violation_count broken reference(s)"
  exit 1
fi
