#!/usr/bin/env bash
# tests/test-939-sessionend-hook-runner.sh
# Story #939: SessionEnd Hook migration to hook-runner.sh
# AC1: hooks.json SessionEnd Hook 改為透過 hook-runner.sh 執行
# AC2: test-hook-integration-suite.sh 通過
# AC3: 新增至少 1 個測試（本測試即為新增測試）
# NFR1: 遷移不影響現有 Hook 功能行為
# NFR2: timeout 設定不意外 kill 正常 Hook

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_JSON="$REPO_ROOT/hooks/hooks.json"
HOOK_RUNNER="$REPO_ROOT/hooks/hook-runner.sh"
SESSION_END_SCRIPT="$REPO_ROOT/hooks/session-end-release.sh"

PASS=0
FAIL=0

assert_pass() {
  local desc="$1"; shift
  local rc=0; "$@" >/dev/null 2>&1 || rc=$?
  if [[ $rc -eq 0 ]]; then echo "  [PASS] $desc"; PASS=$((PASS+1))
  else echo "  [FAIL] $desc (exit=$rc)"; FAIL=$((FAIL+1)); fi
}

echo "--- AC1: hooks.json SessionEnd 使用 hook-runner.sh ---"
# The command for session-end-release.sh must go through hook-runner.sh
SESSION_END_CMD=$(python3 -c "
import json
d=json.load(open('$HOOKS_JSON'))
for entry in d['hooks']['SessionEnd']:
    for h in entry.get('hooks', []):
        cmd = h.get('command', '')
        if 'session-end-release' in cmd:
            print(cmd); exit()
print('NOT-FOUND')
" 2>/dev/null)
echo "  Session-end command: $SESSION_END_CMD"

if echo "$SESSION_END_CMD" | grep -q "hook-runner.sh"; then
  echo "  [PASS] SessionEnd Hook 使用 hook-runner.sh"
  PASS=$((PASS+1))
else
  echo "  [FAIL] SessionEnd Hook 未使用 hook-runner.sh"
  echo "         current: $SESSION_END_CMD"
  FAIL=$((FAIL+1))
fi

echo "--- AC2: hook-runner.sh 存在且可執行 ---"
if [[ -x "$HOOK_RUNNER" ]]; then
  echo "  [PASS] hook-runner.sh 存在且可執行"
  PASS=$((PASS+1))
else
  echo "  [FAIL] hook-runner.sh 不存在或不可執行"
  FAIL=$((FAIL+1))
fi

echo "--- NFR1: session-end-release.sh 存在（功能未破壞）---"
if [[ -f "$SESSION_END_SCRIPT" ]]; then
  echo "  [PASS] session-end-release.sh 存在"
  PASS=$((PASS+1))
else
  echo "  [FAIL] session-end-release.sh 不存在"
  FAIL=$((FAIL+1))
fi

echo "--- NFR2: hook-runner.sh 以 HOOK_TIMEOUT >= 30 執行（不誤殺正常 Hook）---"
# Verify that hook-runner.sh wraps with reasonable timeout (default 30s)
# We just verify the hook-runner.sh default timeout is not too low
DEFAULT_TIMEOUT=$(grep 'HOOK_TIMEOUT:-' "$HOOK_RUNNER" | head -1 | grep -oE '[0-9]+' | head -1)
echo "  Default HOOK_TIMEOUT: $DEFAULT_TIMEOUT"
if [[ -n "$DEFAULT_TIMEOUT" && "$DEFAULT_TIMEOUT" -ge 30 ]]; then
  echo "  [PASS] 預設 HOOK_TIMEOUT=${DEFAULT_TIMEOUT}s >= 30s"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 預設 HOOK_TIMEOUT=${DEFAULT_TIMEOUT:-unknown}s < 30s"
  FAIL=$((FAIL+1))
fi

echo ""
echo "=== 結果: PASS=$PASS FAIL=$FAIL ==="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
