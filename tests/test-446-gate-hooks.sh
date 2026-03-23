#!/usr/bin/env bash
# test-446-gate-hooks.sh — 驗證 #446 gate hooks 確定性行為
#
# AC1: 3 個 prompt hooks 全部改為 command type（hooks.json 結構驗證）
# AC2: gh pr merge 觸發 PR-MERGE-GATE
# AC3: git checkout -b 觸發 BRANCH-GATE
# AC4: git push origin main 觸發 PUSH-MAIN-GATE
# AC5: 非目標指令不觸發（0 false positive）

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
HOOKS_DIR="$REPO_ROOT/hooks"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

# ── 輔助函式：模擬 CLAUDE_TOOL_INPUT 呼叫 hook ──────────────────────────
run_hook() {
  local script="$1"
  local cmd="$2"
  local input
  input=$(printf '{"command": "%s"}' "$cmd")
  CLAUDE_TOOL_INPUT="$input" bash "$HOOKS_DIR/$script" 2>&1
  return $?
}

# ── AC1: hooks.json 不含任何 type: prompt ───────────────────────────────
echo "=== AC1: hooks.json 無 type: prompt ==="
if ! grep -q '"type": "prompt"' "$HOOKS_DIR/hooks.json"; then
  pass "hooks.json 已無 type: prompt"
else
  fail "hooks.json 仍含 type: prompt"
fi

# 確認 3 個 gate scripts 存在
for script in pr-merge-gate.sh branch-gate.sh push-main-gate.sh; do
  if [[ -x "$HOOKS_DIR/$script" ]]; then
    pass "$script 存在且可執行"
  else
    fail "$script 不存在或不可執行"
  fi
done

# ── AC2: PR-MERGE-GATE ────────────────────────────────────────────────
echo "=== AC2: PR-MERGE-GATE ==="
# 目標指令應觸發（exit 1）
for cmd in "gh pr merge 123" "gh pr merge --squash" "pr merge"; do
  if output=$(run_hook pr-merge-gate.sh "$cmd" 2>&1); then
    fail "應觸發但未觸發: $cmd"
  else
    if echo "$output" | grep -q "PR-MERGE-GATE"; then
      pass "正確觸發: $cmd"
    else
      fail "觸發但無 PR-MERGE-GATE 文字: $cmd"
    fi
  fi
done

# AC5: 非目標指令應放行（exit 0）
for cmd in "gh issue view 123" "gh run list" "gh pr list" "git status" "git log --oneline"; do
  if run_hook pr-merge-gate.sh "$cmd" >/dev/null 2>&1; then
    pass "正確放行: $cmd"
  else
    fail "誤攔截（false positive）: $cmd"
  fi
done

# ── AC3: BRANCH-GATE ─────────────────────────────────────────────────
echo "=== AC3: BRANCH-GATE ==="
# 目標指令應觸發（exit 1）
for cmd in "git checkout -b sprint-123/446" "git switch -c feature-xyz"; do
  if output=$(run_hook branch-gate.sh "$cmd" 2>&1); then
    fail "應觸發但未觸發: $cmd"
  else
    if echo "$output" | grep -q "BRANCH-GATE"; then
      pass "正確觸發: $cmd"
    else
      fail "觸發但無 BRANCH-GATE 文字: $cmd"
    fi
  fi
done

# AC5: 非目標指令應放行
for cmd in "git checkout main" "git switch main" "git status" "gh issue view 123"; do
  if run_hook branch-gate.sh "$cmd" >/dev/null 2>&1; then
    pass "正確放行: $cmd"
  else
    fail "誤攔截（false positive）: $cmd"
  fi
done

# ── AC4: PUSH-MAIN-GATE ───────────────────────────────────────────────
echo "=== AC4: PUSH-MAIN-GATE ==="
# 目標指令應觸發（exit 1）
for cmd in "git push origin main" "git push main" "git push --force origin main"; do
  if output=$(run_hook push-main-gate.sh "$cmd" 2>&1); then
    fail "應觸發但未觸發: $cmd"
  else
    if echo "$output" | grep -q "PUSH-MAIN-GATE"; then
      pass "正確觸發: $cmd"
    else
      fail "觸發但無 PUSH-MAIN-GATE 文字: $cmd"
    fi
  fi
done

# AC5: 非目標指令應放行
for cmd in "git push origin sprint-123/446" "git push" "git status" "gh run list" "git push origin feature-branch"; do
  if run_hook push-main-gate.sh "$cmd" >/dev/null 2>&1; then
    pass "正確放行: $cmd"
  else
    fail "誤攔截（false positive）: $cmd"
  fi
done

# ── 結果彙總 ─────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════"
echo "結果：PASS=$PASS，FAIL=$FAIL"
echo "══════════════════════════════════════"

if [[ $FAIL -eq 0 ]]; then
  echo "ALL TESTS PASSED"
  exit 0
else
  echo "SOME TESTS FAILED"
  exit 1
fi
