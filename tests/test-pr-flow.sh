#!/usr/bin/env bash
# test-pr-flow.sh — US-315 PR-based Git Flow 測試
# 驗證：
#   1. protect-main.sh 攔截直推 main
#   2. protect-main.sh 豁免狀態文件直推
#   3. protect-main.sh 豁免 refs/claims/ push
#   4. protect-main.sh 豁免 tag push
#   5. hooks.json 包含 PreToolUse main-protect hook

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROTECT_SCRIPT="$REPO_ROOT/hooks/protect-main.sh"
HOOKS_JSON="$REPO_ROOT/hooks/hooks.json"

PASS=0
FAIL=0

pass() { echo "[PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL + 1)); }

# ── 測試 0：protect-main.sh 存在 ──────────────────────────────────────────
if [[ -f "$PROTECT_SCRIPT" ]]; then
  pass "protect-main.sh 存在"
else
  fail "protect-main.sh 不存在（預期路徑：$PROTECT_SCRIPT）"
fi

# ── 測試 1：hooks.json 包含 protect-main hook ────────────────────────────
if grep -q "protect-main.sh" "$HOOKS_JSON"; then
  pass "hooks.json 包含 protect-main.sh 引用"
else
  fail "hooks.json 未包含 protect-main.sh 引用"
fi

# ── 以下測試需要 protect-main.sh 存在才能執行 ────────────────────────────
if [[ ! -f "$PROTECT_SCRIPT" ]]; then
  echo ""
  echo "protect-main.sh 不存在，跳過剩餘測試"
  echo ""
  echo "結果：PASS=$PASS FAIL=$FAIL"
  [[ $FAIL -eq 0 ]] && exit 0 || exit 1
fi

run_protect() {
  # 以 CLAUDE_TOOL_INPUT 環境變數模擬 hook 執行
  CLAUDE_TOOL_INPUT="$1" bash "$PROTECT_SCRIPT" 2>&1
  return $?
}

protect_exit() {
  CLAUDE_TOOL_INPUT="$1" bash "$PROTECT_SCRIPT" > /dev/null 2>&1
  echo $?
}

# ── 測試 2：攔截 git push origin main ────────────────────────────────────
OUTPUT=$(CLAUDE_TOOL_INPUT='{"command":"git push origin main"}' bash "$PROTECT_SCRIPT" 2>&1 || true)
if echo "$OUTPUT" | grep -q "MAIN-PROTECT"; then
  pass "攔截 git push origin main → 輸出 [MAIN-PROTECT]"
else
  fail "未攔截 git push origin main（輸出：$OUTPUT）"
fi

# ── 測試 3：攔截 git push origin HEAD:main ───────────────────────────────
OUTPUT=$(CLAUDE_TOOL_INPUT='{"command":"git push origin HEAD:main"}' bash "$PROTECT_SCRIPT" 2>&1 || true)
if echo "$OUTPUT" | grep -q "MAIN-PROTECT"; then
  pass "攔截 git push origin HEAD:main → 輸出 [MAIN-PROTECT]"
else
  fail "未攔截 git push origin HEAD:main（輸出：$OUTPUT）"
fi

# ── 測試 4：豁免 — refs/claims/ push ─────────────────────────────────────
EXIT_CODE=$(CLAUDE_TOOL_INPUT='{"command":"git push origin refs/claims/123"}' bash "$PROTECT_SCRIPT" > /dev/null 2>&1; echo $?)
if [[ "$EXIT_CODE" == "0" ]]; then
  pass "豁免 refs/claims/ push（exit 0）"
else
  fail "refs/claims/ push 未被豁免（exit code：$EXIT_CODE）"
fi

# ── 測試 5：豁免 — git push origin --tags ────────────────────────────────
EXIT_CODE=$(CLAUDE_TOOL_INPUT='{"command":"git push origin --tags"}' bash "$PROTECT_SCRIPT" > /dev/null 2>&1; echo $?)
if [[ "$EXIT_CODE" == "0" ]]; then
  pass "豁免 git push origin --tags（exit 0）"
else
  fail "git push origin --tags 未被豁免（exit code：$EXIT_CODE）"
fi

# ── 測試 6：豁免 — tag push（v*.* 格式） ─────────────────────────────────
EXIT_CODE=$(CLAUDE_TOOL_INPUT='{"command":"git push origin v0.74.0"}' bash "$PROTECT_SCRIPT" > /dev/null 2>&1; echo $?)
if [[ "$EXIT_CODE" == "0" ]]; then
  pass "豁免 git push origin v0.74.0（exit 0）"
else
  fail "git push origin v0.74.0 未被豁免（exit code：$EXIT_CODE）"
fi

# ── 測試 7：豁免 — 狀態文件 commit（docs/sprints/ 路徑）────────────────
OUTPUT=$(CLAUDE_TOOL_INPUT='{"command":"git push origin main","staged_files":["docs/sprints/sprint.live.log"]}' bash "$PROTECT_SCRIPT" 2>&1 || true)
# 狀態文件豁免：需用環境變數 STAGED_FILES 傳遞
EXIT_CODE=$(STAGED_FILES="docs/sprints/sprint.live.log" CLAUDE_TOOL_INPUT='{"command":"git push origin main"}' bash "$PROTECT_SCRIPT" > /dev/null 2>&1; echo $?)
if [[ "$EXIT_CODE" == "0" ]]; then
  pass "豁免 docs/sprints/ 狀態文件直推 main（exit 0）"
else
  fail "docs/sprints/ 狀態文件未被豁免（exit code：$EXIT_CODE）"
fi

# ── 測試 8：豁免 — PROJECT_BOARD.md ──────────────────────────────────────
EXIT_CODE=$(STAGED_FILES="docs/PROJECT_BOARD.md" CLAUDE_TOOL_INPUT='{"command":"git push origin main"}' bash "$PROTECT_SCRIPT" > /dev/null 2>&1; echo $?)
if [[ "$EXIT_CODE" == "0" ]]; then
  pass "豁免 docs/PROJECT_BOARD.md 直推 main（exit 0）"
else
  fail "docs/PROJECT_BOARD.md 未被豁免（exit code：$EXIT_CODE）"
fi

# ── 測試 9：非 git push 指令不觸發攔截 ───────────────────────────────────
EXIT_CODE=$(CLAUDE_TOOL_INPUT='{"command":"git status"}' bash "$PROTECT_SCRIPT" > /dev/null 2>&1; echo $?)
if [[ "$EXIT_CODE" == "0" ]]; then
  pass "非 git push 指令不觸發攔截（exit 0）"
else
  fail "非 git push 指令意外被攔截（exit code：$EXIT_CODE）"
fi

# ── 測試 10：shoot SKILL.md 包含 PR flow 步驟 ────────────────────────────
SHOOT_SKILL="$REPO_ROOT/skills/shoot/SKILL.md"
if grep -q "gh pr create" "$SHOOT_SKILL" && grep -q "gh pr merge" "$SHOOT_SKILL"; then
  pass "shoot SKILL.md §7 步驟 6 包含 gh pr create + gh pr merge"
else
  fail "shoot SKILL.md §7 步驟 6 未包含 PR flow（gh pr create / gh pr merge）"
fi

# ── 測試 11：sprint-execution SKILL.md §3 包含 PR flow ───────────────────
SE_SKILL="$REPO_ROOT/skills/sprint-execution/SKILL.md"
if grep -q "gh pr create" "$SE_SKILL" && grep -q "sprint-.*/" "$SE_SKILL"; then
  pass "sprint-execution SKILL.md §3 包含 PR flow 與 branch 命名規則"
else
  fail "sprint-execution SKILL.md §3 未包含 PR flow"
fi

# ── 測試 12：sprint-execution SKILL.md §2.12 checkpoint 豁免標注 ─────────
if grep -q "豁免" "$SE_SKILL" && grep -q "sprint-checkpoint.json" "$SE_SKILL"; then
  pass "sprint-execution SKILL.md §2.12 包含 checkpoint 豁免標注"
else
  fail "sprint-execution SKILL.md §2.12 未包含 checkpoint 豁免標注"
fi


# ── #316 新增：protect-main.sh POSIX 相容性（#10）────────────────
echo ""
echo "── #316 #10：protect-main.sh POSIX grep 相容性 ─────────────────"

# 確認 protect-main.sh 不使用 grep -oP（macOS 不支援）
if grep -q 'grep.*-oP\|-oP.*grep' "$PROTECT_SCRIPT" 2>/dev/null; then
  fail "#316 #10：protect-main.sh 仍使用 grep -oP（macOS 不相容）"
else
  pass "#316 #10：protect-main.sh 不使用 grep -oP（POSIX 相容）"
fi

# 確認使用 sed 作為 fallback
if grep -q 'sed' "$PROTECT_SCRIPT" 2>/dev/null; then
  pass "#316 #10：protect-main.sh 含 sed fallback（POSIX）"
else
  fail "#316 #10：protect-main.sh 缺少 sed fallback"
fi

# ── #316 新增：protect-main.sh JSON 解析失敗 WARN（#16）──────────
echo ""
echo "── #316 #16：protect-main.sh JSON 解析失敗 WARN ────────────────"

# malformed JSON 應輸出 WARN 而非靜默放行
MALFORMED_OUTPUT=$(CLAUDE_TOOL_INPUT='{"command": malformed}' bash "$PROTECT_SCRIPT" 2>&1 || true)
# 預期：WARN 或直接 exit 0（無法解析 command → 放行）
# 修復後應輸出 WARN
if echo "$MALFORMED_OUTPUT" | grep -qi "warn\|WARN"; then
  pass "#316 #16：malformed JSON 觸發 WARN 而非靜默放行"
else
  # 如果 exit 0 也可接受（保守放行），但至少應有 WARN log
  MALFORMED_EXIT=$(CLAUDE_TOOL_INPUT='{"command": malformed}' bash "$PROTECT_SCRIPT" > /dev/null 2>&1; echo $?)
  if [[ "$MALFORMED_EXIT" == "0" ]]; then
    fail "#316 #16：protect-main.sh malformed JSON 靜默放行（缺 WARN）"
  else
    pass "#316 #16：protect-main.sh malformed JSON 有處理（exit $MALFORMED_EXIT）"
  fi
fi

# ── 摘要 ──────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "test-pr-flow.sh 結果：PASS=$PASS FAIL=$FAIL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

[[ $FAIL -eq 0 ]] && exit 0 || exit 1

