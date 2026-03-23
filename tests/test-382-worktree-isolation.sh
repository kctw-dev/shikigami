#!/usr/bin/env bash
# tests/test-382-worktree-isolation.sh
# Issue #382 — 驗證 worktree 隔離機制在實際 Sprint 執行中生效
# 驗證 #379 落地：Sprint Execution SKILL.md 含 worktree 隔離相關說明

set -uo pipefail

# ---------------------------------------------------------------------------
# 測試框架（輕量，與 test-366-sprint-planning-trigger.sh 一致）
# ---------------------------------------------------------------------------
PASS_COUNT=0
FAIL_COUNT=0

pass() {
  echo "PASS: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "FAIL: $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

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

# ---------------------------------------------------------------------------
# 設定路徑
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_FILE="${REPO_ROOT}/skills/sprint-execution/SKILL.md"

echo "=== #382 worktree 隔離機制驗證測試 ==="
echo "REPO_ROOT: $REPO_ROOT"
echo "SKILL_FILE: $SKILL_FILE"
echo ""

# ---------------------------------------------------------------------------
# 前置條件：SKILL.md 存在
# ---------------------------------------------------------------------------
if [[ ! -f "$SKILL_FILE" ]]; then
  fail "前置：skills/sprint-execution/SKILL.md 存在"
  echo ""
  echo "=== 測試結果 ==="
  echo "PASS: $PASS_COUNT"
  echo "FAIL: $FAIL_COUNT"
  echo "總結：前置條件失敗，無法執行後續測試"
  exit 1
fi

# ---------------------------------------------------------------------------
# AC-1：確認 Sprint Execution SKILL.md 含 isolation: "worktree" 參數
# ---------------------------------------------------------------------------
echo "--- AC-1：isolation: \"worktree\" 參數存在 ---"

assert_contains "$SKILL_FILE" \
  'isolation:.*worktree|isolation.*"worktree"' \
  "AC-1a: SKILL.md 含 isolation: \"worktree\" 派遣參數（#379）"

assert_contains "$SKILL_FILE" \
  '#379' \
  "AC-1b: SKILL.md 含 #379 參照，確認為刻意引入的功能"

# ---------------------------------------------------------------------------
# AC-2：確認 worktree 描述段落存在
# ---------------------------------------------------------------------------
echo ""
echo "--- AC-2：worktree 描述段落存在 ---"

assert_contains "$SKILL_FILE" \
  'Git Worktree 隔離|worktree 隔離' \
  "AC-2a: SKILL.md 含 Git Worktree 隔離段落標題"

assert_contains "$SKILL_FILE" \
  '獨立.*工作目錄|每個 subagent.*獨立|subagent.*獨立.*worktree' \
  "AC-2b: SKILL.md 說明每個 subagent 在獨立工作目錄操作"

assert_contains "$SKILL_FILE" \
  '互不影響' \
  "AC-2c: SKILL.md 說明 subagent 互不影響"

# ---------------------------------------------------------------------------
# AC-3：確認 worktree 清理說明存在
# ---------------------------------------------------------------------------
echo ""
echo "--- AC-3：worktree 清理說明存在 ---"

assert_contains "$SKILL_FILE" \
  'worktree.*自動清理|自動清理.*worktree|清理.*worktree' \
  "AC-3a: SKILL.md 含 worktree 自動清理說明"

assert_contains "$SKILL_FILE" \
  'subagent 完成後.*清理|完成後.*worktree.*清理|無修改.*自動清理' \
  "AC-3b: SKILL.md 說明 subagent 完成後清理時機"

# ---------------------------------------------------------------------------
# AC-4：確認主 session 不受影響的說明存在
# ---------------------------------------------------------------------------
echo ""
echo "--- AC-4：主 session 不受 subagent 影響的說明存在 ---"

assert_contains "$SKILL_FILE" \
  '主 session.*不受.*subagent|主 session.*工作目錄.*不受' \
  "AC-4a: SKILL.md 明確說明主 session 不受 subagent 影響"

assert_contains "$SKILL_FILE" \
  'worktree 隔離模式|worktree.*隔離.*模式' \
  "AC-4b: SKILL.md 含 worktree 隔離模式說明區塊"

# ---------------------------------------------------------------------------
# 結果摘要
# ---------------------------------------------------------------------------
echo ""
echo "=== 測試結果 ==="
echo "PASS: $PASS_COUNT"
echo "FAIL: $FAIL_COUNT"

if [[ $FAIL_COUNT -eq 0 ]]; then
  echo "總結：worktree 隔離機制驗證全部通過（#382 AC 滿足）"
  exit 0
else
  echo "總結：發現 $FAIL_COUNT 個 FAIL，worktree 隔離機制說明有遺漏，請修正"
  exit 1
fi
