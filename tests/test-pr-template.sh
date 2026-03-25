#!/usr/bin/env bash
# test-pr-template.sh — #741 GitHub PR 描述模板標準化
# AC1: .github/pull_request_template.md 含 Summary, Test Results, AC Coverage, Issue Ref
# AC2: story-lifecycle-prompt.md PR 建立步驟引用此模板格式
# AC3: PR body 必須含 Closes #<issue_id>, PASS: <N>, Tests: <list>
# NFR1: 模板不超過 50 行

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

echo "=== test-pr-template.sh ==="

TEMPLATE="$REPO_ROOT/.github/pull_request_template.md"

# AC1: 模板檔案存在
if [[ -f "$TEMPLATE" ]]; then
  check "AC1: .github/pull_request_template.md 存在" "pass"
else
  check "AC1: .github/pull_request_template.md 存在" "fail"
fi

# AC1: 包含 Summary section
if grep -qi "summary\|## Summary" "$TEMPLATE" 2>/dev/null; then
  check "AC1: 模板包含 Summary 章節" "pass"
else
  check "AC1: 模板包含 Summary 章節" "fail"
fi

# AC1: 包含 Test Results section
if grep -qi "test results\|## Test" "$TEMPLATE" 2>/dev/null; then
  check "AC1: 模板包含 Test Results 章節" "pass"
else
  check "AC1: 模板包含 Test Results 章節" "fail"
fi

# AC1: 包含 AC Coverage section
if grep -qi "ac coverage\|## AC\|acceptance criteria" "$TEMPLATE" 2>/dev/null; then
  check "AC1: 模板包含 AC Coverage 章節" "pass"
else
  check "AC1: 模板包含 AC Coverage 章節" "fail"
fi

# AC1: 包含 Issue Ref section
if grep -qi "issue ref\|closes #\|## Issue" "$TEMPLATE" 2>/dev/null; then
  check "AC1: 模板包含 Issue Ref 章節" "pass"
else
  check "AC1: 模板包含 Issue Ref 章節" "fail"
fi

# AC3: 模板包含 Closes # 格式
if grep -q "Closes #\|closes #" "$TEMPLATE" 2>/dev/null; then
  check "AC3: 模板包含 Closes # issue ref" "pass"
else
  check "AC3: 模板包含 Closes # issue ref" "fail"
fi

# AC3: 模板包含 PASS 格式
if grep -q "PASS" "$TEMPLATE" 2>/dev/null; then
  check "AC3: 模板包含 PASS: <N> 測試結果格式" "pass"
else
  check "AC3: 模板包含 PASS: <N> 測試結果格式" "fail"
fi

# NFR1: 模板不超過 50 行
if [[ -f "$TEMPLATE" ]]; then
  LINE_COUNT=$(wc -l < "$TEMPLATE")
  if [[ $LINE_COUNT -le 50 ]]; then
    check "NFR1: 模板行數 ($LINE_COUNT 行) <= 50 行" "pass"
  else
    check "NFR1: 模板行數 ($LINE_COUNT 行) <= 50 行（超出限制）" "fail"
  fi
else
  check "NFR1: 模板行數檢查（檔案不存在）" "fail"
fi

# AC2: story-lifecycle-prompt.md 引用 PR 模板格式
LIFECYCLE_PROMPT="$REPO_ROOT/skills/sprint-execution/story-lifecycle-prompt.md"
if grep -q "pull_request_template\|PR.*模板\|pr.*template" "$LIFECYCLE_PROMPT" 2>/dev/null; then
  check "AC2: story-lifecycle-prompt.md 引用 PR 模板" "pass"
else
  check "AC2: story-lifecycle-prompt.md 引用 PR 模板" "fail"
fi

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
