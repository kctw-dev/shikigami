#!/usr/bin/env bash
# tests/test-500-worktree-cleanup.sh
# Issue #500 — 驗證 Worktree 自動清理機制
#
# AC1: health-check skill 新增 worktree 偵測段落（第 7 項檢查）
# AC2: hooks/worktree-cleanup.sh 存在且可執行（SessionEnd 清理腳本）
# AC3: worktree-cleanup.sh 清理前檢查活躍進程（NFR1：不刪執行中 worktree）
# AC4: worktree-cleanup.sh 輸出 [WORKTREE-CLEANUP] 格式訊息

set -uo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
HEALTH_CHECK_SKILL="${REPO_ROOT}/skills/health-check/SKILL.md"
DIAGNOSTIC_RULES="${REPO_ROOT}/skills/health-check/references/diagnostic-rules.md"
CLEANUP_SCRIPT="${REPO_ROOT}/hooks/worktree-cleanup.sh"
SESSION_END_SCRIPT="${REPO_ROOT}/hooks/session-end-release.sh"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

assert_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -qE "$pattern" "$file" 2>/dev/null; then
    pass "$label"
  else
    fail "$label (pattern='${pattern}' not found in $file)"
  fi
}

# ── AC1: health-check skill 新增 worktree 偵測 ─────────────────────────
echo "=== AC1: health-check skill 含 worktree 偵測 ==="

assert_contains "$HEALTH_CHECK_SKILL" \
  'worktree|Worktree' \
  "AC1a: SKILL.md 含 worktree 相關說明"

assert_contains "$HEALTH_CHECK_SKILL" \
  '7\.|檢查 7|第 7|\.claude/worktrees' \
  "AC1b: SKILL.md 含第 7 項檢查（worktree 偵測）"

assert_contains "$DIAGNOSTIC_RULES" \
  'worktree|Worktree' \
  "AC1c: diagnostic-rules.md 含 worktree 偵測規則"

assert_contains "$DIAGNOSTIC_RULES" \
  '\.claude/worktrees' \
  "AC1d: diagnostic-rules.md 說明掃描 .claude/worktrees/ 目錄"

# ── AC2: hooks/worktree-cleanup.sh 存在且可執行 ────────────────────────
echo ""
echo "=== AC2: worktree-cleanup.sh 存在且可執行 ==="

if [[ -f "$CLEANUP_SCRIPT" ]]; then
  pass "AC2a: worktree-cleanup.sh 存在"
else
  fail "AC2a: worktree-cleanup.sh 不存在（路徑：$CLEANUP_SCRIPT）"
fi

if [[ -x "$CLEANUP_SCRIPT" ]]; then
  pass "AC2b: worktree-cleanup.sh 可執行"
else
  fail "AC2b: worktree-cleanup.sh 不可執行"
fi

# AC2c: session-end-release.sh 中調用 worktree-cleanup.sh
assert_contains "$SESSION_END_SCRIPT" \
  'worktree-cleanup' \
  "AC2c: session-end-release.sh 調用 worktree-cleanup.sh"

# ── AC3: worktree-cleanup.sh 含活躍進程檢查邏輯 ───────────────────────
echo ""
echo "=== AC3: worktree-cleanup.sh 含活躍進程檢查（NFR1）==="

assert_contains "$CLEANUP_SCRIPT" \
  'lsof|fuser|proc|ps |pgrep' \
  "AC3a: worktree-cleanup.sh 含進程偵測（lsof/fuser/pgrep）"

assert_contains "$CLEANUP_SCRIPT" \
  'SKIP|skip|活躍|active|正在執行|running' \
  "AC3b: worktree-cleanup.sh 含跳過仍在執行的 worktree 邏輯"

# ── AC4: worktree-cleanup.sh 輸出 [WORKTREE-CLEANUP] 格式 ──────────────
echo ""
echo "=== AC4: worktree-cleanup.sh 輸出 [WORKTREE-CLEANUP] ==="

assert_contains "$CLEANUP_SCRIPT" \
  '\[WORKTREE-CLEANUP\]' \
  "AC4a: worktree-cleanup.sh 含 [WORKTREE-CLEANUP] 輸出標記"

assert_contains "$CLEANUP_SCRIPT" \
  '清除.*個.*worktree|MB|磁碟' \
  "AC4b: worktree-cleanup.sh 輸出清除數量與磁碟釋放量"

# ── AC4 執行測試：dry-run 模式不刪任何東西但輸出格式正確 ──────────────
echo ""
echo "=== AC4 執行測試（dry-run）==="
if [[ -x "$CLEANUP_SCRIPT" ]]; then
  DRY_OUTPUT=$(DRY_RUN=1 bash "$CLEANUP_SCRIPT" 2>&1 || true)
  if echo "$DRY_OUTPUT" | grep -q '\[WORKTREE-CLEANUP\]'; then
    pass "AC4c: dry-run 輸出含 [WORKTREE-CLEANUP] 標記"
  else
    fail "AC4c: dry-run 輸出未含 [WORKTREE-CLEANUP] 標記（output: ${DRY_OUTPUT:0:200}）"
  fi
else
  fail "AC4c: 無法執行 dry-run（腳本不可執行）"
fi

# ── NFR2: cleanup 腳本自身不應以非零 exit code 阻塞 ───────────────────
echo ""
echo "=== NFR2: 清理失敗不阻塞主流程 ==="
assert_contains "$CLEANUP_SCRIPT" \
  'set \+e|\|\| true' \
  "NFR2: worktree-cleanup.sh 含 set +e 或 || true（失敗不阻塞）"

# ── 結果摘要 ───────────────────────────────────────────────────────────
echo ""
echo "=== 測試結果 ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [[ $FAIL -eq 0 ]]; then
  echo "總結：#500 Worktree 自動清理機制驗證全部通過"
  exit 0
else
  echo "總結：發現 $FAIL 個 FAIL，請修正後再 commit"
  exit 1
fi
