#!/usr/bin/env bash
# test-architect-conflict-prevention.sh — #752 Architect 批次分組共同修改檔案衝突預防標注
# AC: architect-prompt.md Parallel Grouping 說明包含共同修改檔案衝突預防規則

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

echo "=== test-architect-conflict-prevention.sh ==="

ARCH_PROMPT="$REPO_ROOT/skills/sprint-planning/references/architect-prompt.md"

# AC: architect-prompt.md 包含共同修改檔案衝突預防規則
if grep -q "同檔案\|shared.file\|衝突預防\|conflict.*prevent\|shared-file" "$ARCH_PROMPT" 2>/dev/null; then
  check "AC: architect-prompt.md 包含共同修改檔案衝突預防說明" "pass"
else
  check "AC: architect-prompt.md 包含共同修改檔案衝突預防說明" "fail"
fi

# AC: architect-prompt.md 包含「順序依賴」或「序列執行」說明
if grep -q "順序依賴\|序列\|sequential\|順序執行\|先後順序" "$ARCH_PROMPT" 2>/dev/null; then
  check "AC: architect-prompt.md 包含順序依賴/序列執行說明" "pass"
else
  check "AC: architect-prompt.md 包含順序依賴/序列執行說明" "fail"
fi

# AC: 規則包含 Parallel Grouping 相關段落
if grep -q "Parallel Grouping\|parallel.*group\|批次分組\|平行分群" "$ARCH_PROMPT" 2>/dev/null; then
  check "AC: architect-prompt.md 包含 Parallel Grouping 段落" "pass"
else
  check "AC: architect-prompt.md 包含 Parallel Grouping 段落" "fail"
fi

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
