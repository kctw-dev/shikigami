#!/usr/bin/env bash
# test-bash-arithmetic-warning.sh — #751 Developer prompt bash arithmetic increment 慣例警示
# AC: story-lifecycle-prompt.md 包含 bash arithmetic increment 慣例警示
# AC: Developer Story template NFR 章節包含此警示
# Problem: set -euo pipefail 下 ((VAR++)) 在 VAR=0 時返回 exit code 1

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

check() {
  local desc="$1"
  local result="$2"
  if [[ "$result" == "pass" ]]; then
    echo "PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== test-bash-arithmetic-warning.sh ==="

LIFECYCLE_PROMPT="$REPO_ROOT/skills/sprint-execution/story-lifecycle-prompt.md"

# AC: story-lifecycle-prompt.md 包含 bash arithmetic increment 警示
if grep -q 'VAR=\$((VAR+1))\|VAR=\$((VAR + 1))\|arithmetic.*increment\|bash.*arithmetic\|\(\(VAR++\)\).*避免\|set -e.*((VAR' "$LIFECYCLE_PROMPT" 2>/dev/null; then
  check "AC: story-lifecycle-prompt.md 包含 bash arithmetic increment 警示" "pass"
else
  check "AC: story-lifecycle-prompt.md 包含 bash arithmetic increment 警示" "fail"
fi

# AC: 警示說明 set -e 相容性問題
if grep -q "set -e\|set -euo\|exit code 1\|exit.*code\|pipefail" "$LIFECYCLE_PROMPT" 2>/dev/null; then
  check "AC: story-lifecycle-prompt.md 說明 set -e 相容性問題" "pass"
else
  check "AC: story-lifecycle-prompt.md 說明 set -e 相容性問題" "fail"
fi

# AC: 推薦使用 VAR=$((VAR+1)) 取代 ((VAR++))
if grep -q 'VAR=\$((VAR' "$LIFECYCLE_PROMPT" 2>/dev/null; then
  check "AC: story-lifecycle-prompt.md 包含 VAR=\$((VAR+1)) 替換建議" "pass"
else
  check "AC: story-lifecycle-prompt.md 包含 VAR=\$((VAR+1)) 替換建議" "fail"
fi

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
