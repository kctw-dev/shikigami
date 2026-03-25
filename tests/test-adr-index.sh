#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/update-adr-index.sh"

pass() { echo "[PASS] $1"; }
fail() { echo "[FAIL] $1 — $2"; exit 1; }

echo "=== test-adr-index.sh ==="

# TC1: update-adr-index.sh exists and is executable
[[ -x "$SCRIPT" ]] || fail "TC1" "update-adr-index.sh not found or not executable"
pass "TC1: update-adr-index.sh exists and is executable"

# TC2: Running script generates docs/adr/README.md
bash "$SCRIPT" 2>/dev/null
README="$REPO_ROOT/docs/adr/README.md"
[[ -f "$README" ]] || fail "TC2" "docs/adr/README.md not generated"
pass "TC2: docs/adr/README.md generated"

# TC3: README.md contains table columns (ADR#, Title, Status, Date)
README_CONTENT=$(cat "$README")
echo "$README_CONTENT" | grep -qi "ADR\|Number\|編號" || fail "TC3a" "Missing ADR# column"
echo "$README_CONTENT" | grep -qi "Title\|標題" || fail "TC3b" "Missing Title column"
echo "$README_CONTENT" | grep -qi "Status\|狀態" || fail "TC3c" "Missing Status column"
pass "TC3: README.md has required columns"

# TC4: README.md contains known ADRs
echo "$README_CONTENT" | grep -q "ADR-001" || fail "TC4a" "Missing ADR-001"
echo "$README_CONTENT" | grep -q "ADR-010" || fail "TC4b" "Missing ADR-010"
pass "TC4: Known ADRs listed in index"

# TC5: architecture-decision SKILL.md references update-adr-index.sh
ADR_SKILL="$REPO_ROOT/skills/architecture-decision/SKILL.md"
[[ -f "$ADR_SKILL" ]] || fail "TC5" "architecture-decision/SKILL.md not found"
grep -q "update-adr-index\|update_adr_index" "$ADR_SKILL" || \
  fail "TC5" "architecture-decision/SKILL.md doesn't reference update-adr-index.sh"
pass "TC5: architecture-decision SKILL.md references update-adr-index.sh"

echo "=== All ADR Index tests PASS ==="
