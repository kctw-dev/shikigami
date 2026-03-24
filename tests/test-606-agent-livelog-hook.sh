#!/usr/bin/env bash
# test-606-agent-livelog-hook.sh — 驗證 #606 PostToolUse Agent live-log hook
#
# AC1: posttooluse-agent-livelog.sh 存在且可執行
# AC2: hooks.json 包含 matcher=Agent 的 PostToolUse entry
# AC3: 腳本包含 resolve-session-id.sh source（session 隔離）
# AC4: hook 為 async: true（不阻塞主流程）
# AC5: 腳本包含 logs/live/ 路徑

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
HOOKS_DIR="$REPO_ROOT/hooks"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

# ── AC1: 腳本存在且可執行 ──────────────────────────────────────────────
echo "=== AC1: posttooluse-agent-livelog.sh 存在且可執行 ==="
if [[ -x "$HOOKS_DIR/posttooluse-agent-livelog.sh" ]]; then
  pass "posttooluse-agent-livelog.sh 存在且可執行"
else
  fail "posttooluse-agent-livelog.sh 不存在或不可執行"
fi

# ── AC2: hooks.json 包含 matcher=Agent 的 PostToolUse entry ───────────
echo "=== AC2: hooks.json PostToolUse matcher=Agent entry ==="
if python3 -c "
import json, sys
data = json.load(open('$HOOKS_DIR/hooks.json'))
ptu = data.get('hooks', {}).get('PostToolUse', [])
found = any(e.get('matcher') == 'Agent' for e in ptu)
sys.exit(0 if found else 1)
" 2>/dev/null; then
  pass "hooks.json 包含 PostToolUse matcher=Agent"
else
  fail "hooks.json 缺少 PostToolUse matcher=Agent"
fi

# ── AC3: 腳本包含 resolve-session-id.sh source ────────────────────────
echo "=== AC3: 腳本包含 resolve-session-id.sh source ==="
if grep -q "resolve-session-id.sh" "$HOOKS_DIR/posttooluse-agent-livelog.sh"; then
  pass "腳本包含 resolve-session-id.sh source"
else
  fail "腳本未包含 resolve-session-id.sh source"
fi

# ── AC4: hook 為 async: true ──────────────────────────────────────────
echo "=== AC4: Agent hook 為 async: true ==="
if python3 -c "
import json, sys
data = json.load(open('$HOOKS_DIR/hooks.json'))
ptu = data.get('hooks', {}).get('PostToolUse', [])
agent_entry = next((e for e in ptu if e.get('matcher') == 'Agent'), None)
if agent_entry is None:
  sys.exit(1)
all_async = all(h.get('async') == True for h in agent_entry.get('hooks', []))
sys.exit(0 if all_async else 1)
" 2>/dev/null; then
  pass "Agent hook 已設定 async: true"
else
  fail "Agent hook 未設定 async: true"
fi

# ── AC5: 腳本包含 logs/live/ 路徑 ─────────────────────────────────────
echo "=== AC5: 腳本包含 logs/live/ 路徑 ==="
if grep -q "logs/live" "$HOOKS_DIR/posttooluse-agent-livelog.sh"; then
  pass "腳本包含 logs/live/ 路徑"
else
  fail "腳本未包含 logs/live/ 路徑"
fi

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
