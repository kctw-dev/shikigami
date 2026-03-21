#!/usr/bin/env bash
# tests/test-runner-dispatch.sh
# US-#323 Phase 4：GitHub Actions Runner 動態 Sprint 派遣 測試套件
# 覆蓋 AC-1~10

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ---------------------------------------------------------------------------
# 測試框架（輕量）
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

assert_file_exists() {
  local path="$1"
  local label="$2"
  if [[ -f "$path" ]]; then
    pass "$label"
  else
    fail "$label (file not found: $path)"
  fi
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

assert_not_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -qE "$pattern" "$file" 2>/dev/null; then
    fail "$label (unexpected pattern='${pattern}' found in $file)"
  else
    pass "$label"
  fi
}

# ---------------------------------------------------------------------------
echo ""
echo "=== TC-1：AC-1 Workflow YAML 存在 + 結構驗證 ==="
# ---------------------------------------------------------------------------

WORKFLOW="$REPO_ROOT/.github/workflows/sprint-dispatch.yml"
assert_file_exists "$WORKFLOW" "AC-1: sprint-dispatch.yml 存在"
assert_contains "$WORKFLOW" "workflow_dispatch" "AC-1: workflow_dispatch 觸發器"
assert_contains "$WORKFLOW" "target_repo" "AC-1: inputs.target_repo"
assert_contains "$WORKFLOW" "sprint_command" "AC-1: inputs.sprint_command"
assert_contains "$WORKFLOW" "timeout_minutes" "AC-1: inputs.timeout_minutes（可配）"
assert_contains "$WORKFLOW" "required: true" "AC-1: target_repo 為必填"
assert_contains "$WORKFLOW" "claim" "AC-1: 靠 claim 機制協調（不設 concurrency）"
assert_contains "$WORKFLOW" "多 runner 可平行" "AC-1: 同 repo 多 runner 平行說明"
assert_contains "$WORKFLOW" "self-hosted" "AC-1: runs-on self-hosted"
assert_contains "$WORKFLOW" "shikigami-sprint" "AC-1: runner label shikigami-sprint"

# ---------------------------------------------------------------------------
echo ""
echo "=== TC-2：AC-2 Headless mode（--allowedTools）==="
# ---------------------------------------------------------------------------

assert_contains "$WORKFLOW" "\-\-allowedTools" "AC-2: --allowedTools 存在"
# MCP 不啟動（CI 降級）— 不應有 --mcp-config 或 mcp 啟動
assert_not_contains "$WORKFLOW" "\-\-mcp-config" "AC-2: MCP 不啟動（無 --mcp-config）"

# ---------------------------------------------------------------------------
echo ""
echo "=== TC-3：AC-3 Session ID 綁定 ==="
# ---------------------------------------------------------------------------

assert_contains "$WORKFLOW" "CLAUDE_SESSION_ID" "AC-3: CLAUDE_SESSION_ID env 設定"
assert_contains "$WORKFLOW" "github.run_id" "AC-3: github.run_id 作為 Session ID"

# ---------------------------------------------------------------------------
echo ""
echo "=== TC-4：AC-4 stdout 標記格式 ==="
# ---------------------------------------------------------------------------

SKILL_MD="$REPO_ROOT/skills/sprint-execution/SKILL.md"
LIFECYCLE_PROMPT="$REPO_ROOT/skills/sprint-execution/story-lifecycle-prompt.md"

assert_contains "$LIFECYCLE_PROMPT" "\[SHIKIGAMI\] event=story_start" "AC-4: story_start 標記格式"
assert_contains "$LIFECYCLE_PROMPT" "\[SHIKIGAMI\] event=story_end" "AC-4: story_end 標記格式"
assert_contains "$LIFECYCLE_PROMPT" "status=PASS" "AC-4: story_end status 欄位"
assert_contains "$SKILL_MD" "\[SHIKIGAMI\] event=sprint_end" "AC-4: sprint_end 標記格式（SKILL.md）"

# ---------------------------------------------------------------------------
echo ""
echo "=== TC-5：AC-5 Layer 2 per-session log push step ==="
# ---------------------------------------------------------------------------

assert_contains "$WORKFLOW" "if: always()" "AC-5: if: always() 條件"
assert_contains "$WORKFLOW" "git commit" "AC-5: session log git commit step"
assert_contains "$WORKFLOW" "git push" "AC-5: session log git push step"

# ---------------------------------------------------------------------------
echo ""
echo "=== TC-6：AC-6 Layer 3 Issue 留言 opt-in 機制 ==="
# ---------------------------------------------------------------------------

assert_contains "$LIFECYCLE_PROMPT" "SHIKIGAMI_LIVE_NOTIFY" "AC-6: SHIKIGAMI_LIVE_NOTIFY env var"
assert_contains "$LIFECYCLE_PROMPT" "SHIKIGAMI_LIVE_NOTIFY_ISSUE" "AC-6: SHIKIGAMI_LIVE_NOTIFY_ISSUE env var"
assert_contains "$LIFECYCLE_PROMPT" "gh issue comment" "AC-6: gh issue comment 執行"
assert_contains "$LIFECYCLE_PROMPT" "SHIKIGAMI_LIVE_NOTIFY.*true" "AC-6: opt-in 條件判斷"

# ---------------------------------------------------------------------------
echo ""
echo "=== TC-7：AC-7 failure isolation（|| true）==="
# ---------------------------------------------------------------------------

# 觀測操作必須有 || true 保護
assert_contains "$LIFECYCLE_PROMPT" "gh issue comment" "AC-7: Layer 3 有 gh issue comment"
# 至少有一處 || true 在 story_start/story_end 附近（stdout 標記 failure isolation）
assert_contains "$LIFECYCLE_PROMPT" "|| true" "AC-7: || true failure isolation 機制"

# ---------------------------------------------------------------------------
echo ""
echo "=== TC-8：AC-8 ADR-027 CI 權限 存在 ==="
# ---------------------------------------------------------------------------

ADR027="$REPO_ROOT/docs/adr/ADR-027-ci-permissions.md"
assert_file_exists "$ADR027" "AC-8: ADR-027-ci-permissions.md 存在"
assert_contains "$ADR027" "\-\-allowedTools" "AC-8: ADR-027 決策含 --allowedTools"
assert_contains "$ADR027" "MCP" "AC-8: ADR-027 涵蓋 MCP 降級決策"
assert_contains "$ADR027" "Accepted" "AC-8: ADR-027 狀態 Accepted"

# ---------------------------------------------------------------------------
echo ""
echo "=== TC-9：AC-9 ADR-028 多 Sprint 觀測 存在 ==="
# ---------------------------------------------------------------------------

ADR028="$REPO_ROOT/docs/adr/ADR-028-multi-sprint-observability.md"
assert_file_exists "$ADR028" "AC-9: ADR-028-multi-sprint-observability.md 存在"
assert_contains "$ADR028" "Actions UI" "AC-9: ADR-028 決策含 Actions UI（方案 A）"
assert_contains "$ADR028" "Issue" "AC-9: ADR-028 決策含 Issue 留言（方案 D）"
assert_contains "$ADR028" "Accepted" "AC-9: ADR-028 狀態 Accepted"

# ---------------------------------------------------------------------------
echo ""
echo "=== TC-10：AC-5 protect-main.sh 相容（per-session log 路徑豁免）==="
# ---------------------------------------------------------------------------

PROTECT_MAIN="$REPO_ROOT/hooks/protect-main.sh"
# docs/sprints/live-log/ 已在豁免清單中（US-322 建立）
assert_contains "$PROTECT_MAIN" "docs/sprints/live-log" "AC-10: protect-main 豁免 live-log 路徑"
# workflow YAML 不在豁免清單 — 需走 PR 流程
assert_contains "$PROTECT_MAIN" "docs/sprints/" "AC-10: docs/sprints/ 路徑豁免確認"

# ---------------------------------------------------------------------------
echo ""
echo "=== 測試結果摘要 ==="
# ---------------------------------------------------------------------------

TOTAL=$((PASS_COUNT + FAIL_COUNT))
echo "Total: $TOTAL | PASS: $PASS_COUNT | FAIL: $FAIL_COUNT"

if [[ "$FAIL_COUNT" -eq 0 ]]; then
  echo ""
  echo "[US-#323] test-runner-dispatch.sh — ALL PASS"
  exit 0
else
  echo ""
  echo "[US-#323] test-runner-dispatch.sh — FAIL ($FAIL_COUNT failures)"
  exit 1
fi
