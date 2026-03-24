#!/usr/bin/env bash
# tests/test-572-resolve-session-id.sh
# #572：resolve-session-id.sh fallback chain 測試套件
#
# 覆蓋：
#   AC1-T1：CLAUDE_SESSION_ID 有值時直接使用
#   AC1-T2：SHIKIGAMI_SESSION_ID 已由外部設定時保留
#   AC1-T3：~/.claude/projects/ 存在且有 .jsonl 時從中讀取
#   AC1-T4：全部 fallback 失敗時輸出 pid-$$ 格式
#   AC3：cruise_cron.sh 設定 CLAUDE_SESSION_ID=cron-... 與 chain 相容

set -uo pipefail

# ---------------------------------------------------------------------------
# 測試框架
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

assert_eq() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  if [[ "$actual" == "$expected" ]]; then
    pass "$label"
  else
    fail "$label (expected='${expected}' actual='${actual}')"
  fi
}

assert_match() {
  local pattern="$1"
  local actual="$2"
  local label="$3"
  if [[ "$actual" =~ $pattern ]]; then
    pass "$label"
  else
    fail "$label (pattern='${pattern}' did not match actual='${actual}')"
  fi
}

# ---------------------------------------------------------------------------
# 目標檔案路徑
# ---------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RESOLVE_SCRIPT="$REPO_ROOT/hooks/lib/resolve-session-id.sh"

# ---------------------------------------------------------------------------
# TC-00：resolve-session-id.sh 存在且可讀
# ---------------------------------------------------------------------------
test_tc00_script_exists() {
  if [[ -f "$RESOLVE_SCRIPT" ]]; then
    pass "TC-00: resolve-session-id.sh 存在"
  else
    fail "TC-00: resolve-session-id.sh 不存在 ($RESOLVE_SCRIPT)"
  fi
}

# ---------------------------------------------------------------------------
# TC-01：CLAUDE_SESSION_ID 有值時直接使用（fallback chain 第 1 步）
# ---------------------------------------------------------------------------
test_tc01_claude_session_id_takes_precedence() {
  local result
  result=$(
    env -i HOME="$HOME" CLAUDE_SESSION_ID="test-session-abc123" \
      bash -c "source '$RESOLVE_SCRIPT'; echo \"\$SHIKIGAMI_SESSION_ID\""
  )
  assert_eq "test-session-abc123" "$result" "TC-01: CLAUDE_SESSION_ID=test-session-abc123 → SHIKIGAMI_SESSION_ID=test-session-abc123"
}

# ---------------------------------------------------------------------------
# TC-02：SHIKIGAMI_SESSION_ID 已由外部設定時保留（fallback chain 第 2 步）
# ---------------------------------------------------------------------------
test_tc02_shikigami_session_id_preserved() {
  local result
  result=$(
    env -i HOME="$HOME" SHIKIGAMI_SESSION_ID="pre-set-session-xyz" \
      bash -c "source '$RESOLVE_SCRIPT'; echo \"\$SHIKIGAMI_SESSION_ID\""
  )
  assert_eq "pre-set-session-xyz" "$result" "TC-02: SHIKIGAMI_SESSION_ID 已由外部設定時保留"
}

# ---------------------------------------------------------------------------
# TC-03：CLAUDE_SESSION_ID 優先於 SHIKIGAMI_SESSION_ID（fallback chain 第 1 步 > 第 2 步）
# ---------------------------------------------------------------------------
test_tc03_claude_session_id_overrides_shikigami() {
  local result
  result=$(
    env -i HOME="$HOME" CLAUDE_SESSION_ID="claude-wins" SHIKIGAMI_SESSION_ID="shikigami-loses" \
      bash -c "source '$RESOLVE_SCRIPT'; echo \"\$SHIKIGAMI_SESSION_ID\""
  )
  assert_eq "claude-wins" "$result" "TC-03: CLAUDE_SESSION_ID 優先於 SHIKIGAMI_SESSION_ID"
}

# ---------------------------------------------------------------------------
# TC-04：從 ~/.claude/projects/ 找最新 .jsonl（fallback chain 第 3 步）
# ---------------------------------------------------------------------------
test_tc04_jsonl_dir_fallback() {
  # 建立臨時目錄模擬 ~/.claude/projects/<project>/
  local TMPDIR_ROOT
  TMPDIR_ROOT=$(mktemp -d)
  trap "rm -rf '$TMPDIR_ROOT'" EXIT

  # 計算 project path（與 resolve-session-id.sh 邏輯一致）
  local PROJECT_PATH
  PROJECT_PATH=$(echo "$REPO_ROOT" | sed 's|/|-|g; s|^-||')
  local JSONL_DIR="${TMPDIR_ROOT}/.claude/projects/${PROJECT_PATH}"
  mkdir -p "$JSONL_DIR"

  # 建立假 .jsonl 檔案（模擬 session UUID）
  local FAKE_UUID="a1b2c3d4-e5f6-7890-abcd-ef1234567890"
  touch "${JSONL_DIR}/${FAKE_UUID}.jsonl"

  local result
  result=$(
    env -i HOME="$TMPDIR_ROOT" PWD="$REPO_ROOT" \
      bash -c "cd '$REPO_ROOT'; source '$RESOLVE_SCRIPT'; echo \"\$SHIKIGAMI_SESSION_ID\""
  )
  assert_eq "$FAKE_UUID" "$result" "TC-04: 從 ~/.claude/projects/ 找最新 .jsonl 取得 session ID"

  trap - EXIT
  rm -rf "$TMPDIR_ROOT"
}

# ---------------------------------------------------------------------------
# TC-05：ultimate fallback — pid-$$ 格式（fallback chain 第 4 步）
# ---------------------------------------------------------------------------
test_tc05_pid_fallback() {
  local TMPDIR_ROOT
  TMPDIR_ROOT=$(mktemp -d)
  trap "rm -rf '$TMPDIR_ROOT'" EXIT

  # 沒有 .jsonl 目錄 → 觸發 pid-$$ fallback
  local result
  result=$(
    env -i HOME="$TMPDIR_ROOT" PWD="$REPO_ROOT" \
      bash -c "cd '$REPO_ROOT'; source '$RESOLVE_SCRIPT'; echo \"\$SHIKIGAMI_SESSION_ID\""
  )
  assert_match "^pid-[0-9]+$" "$result" "TC-05: ultimate fallback 輸出 pid-<數字> 格式"

  trap - EXIT
  rm -rf "$TMPDIR_ROOT"
}

# ---------------------------------------------------------------------------
# TC-06：cruise_cron.sh 設定 CLAUDE_SESSION_ID=cron-... 與 chain 相容（AC3）
# ---------------------------------------------------------------------------
test_tc06_cron_mode_compat() {
  local CRON_SESSION_ID="cron-20260324-120000"
  local result
  result=$(
    env -i HOME="$HOME" CLAUDE_SESSION_ID="$CRON_SESSION_ID" \
      bash -c "source '$RESOLVE_SCRIPT'; echo \"\$SHIKIGAMI_SESSION_ID\""
  )
  assert_eq "$CRON_SESSION_ID" "$result" "TC-06: cruise_cron.sh CLAUDE_SESSION_ID=cron-... 被正確採用"
}

# ---------------------------------------------------------------------------
# TC-07：腳本包含 export SHIKIGAMI_SESSION_ID
# ---------------------------------------------------------------------------
test_tc07_export_present() {
  if grep -q "export SHIKIGAMI_SESSION_ID" "$RESOLVE_SCRIPT"; then
    pass "TC-07: resolve-session-id.sh 包含 export SHIKIGAMI_SESSION_ID"
  else
    fail "TC-07: resolve-session-id.sh 缺少 export SHIKIGAMI_SESSION_ID"
  fi
}

# ---------------------------------------------------------------------------
# TC-08：hooks 都已整合 resolve-session-id.sh（AC2 覆蓋）
# ---------------------------------------------------------------------------
test_tc08_hooks_integration() {
  local HOOKS_TO_CHECK=(
    "$REPO_ROOT/hooks/session-start"
    "$REPO_ROOT/hooks/session-end-release.sh"
    "$REPO_ROOT/hooks/claim-issue.sh"
    "$REPO_ROOT/hooks/release-issue.sh"
    "$REPO_ROOT/hooks/acquire-file-lock.sh"
    "$REPO_ROOT/hooks/task-gate.sh"
    "$REPO_ROOT/hooks/exploration-record.sh"
  )
  for HOOK_FILE in "${HOOKS_TO_CHECK[@]}"; do
    local HOOK_NAME
    HOOK_NAME=$(basename "$HOOK_FILE")
    if grep -q "resolve-session-id.sh\|SHIKIGAMI_SESSION_ID" "$HOOK_FILE" 2>/dev/null; then
      pass "TC-08: $HOOK_NAME 已整合 resolve-session-id.sh 或使用 SHIKIGAMI_SESSION_ID"
    else
      fail "TC-08: $HOOK_NAME 未整合 resolve-session-id.sh（缺少引用）"
    fi
  done
}

# ---------------------------------------------------------------------------
# TC-09：cruise SKILL.md 包含 source hooks/lib/resolve-session-id.sh（AC2）
# ---------------------------------------------------------------------------
test_tc09_cruise_skill_updated() {
  local SKILL_FILE="$REPO_ROOT/skills/cruise/SKILL.md"
  if grep -q "resolve-session-id.sh" "$SKILL_FILE" 2>/dev/null; then
    pass "TC-09: cruise/SKILL.md 包含 resolve-session-id.sh 引用"
  else
    fail "TC-09: cruise/SKILL.md 未更新（缺少 resolve-session-id.sh 引用）"
  fi
}

# ---------------------------------------------------------------------------
# TC-10：AC4 向後相容 — session-unknown 檔案名稱格式仍可被接受
# ---------------------------------------------------------------------------
test_tc10_backward_compat_unknown() {
  # 驗證 session-start 中保留 unknown fallback 保護邏輯
  local SESSION_START="$REPO_ROOT/hooks/session-start"
  if grep -q "unknown" "$SESSION_START" 2>/dev/null; then
    pass "TC-10: session-start 保留 unknown fallback（向後相容）"
  else
    fail "TC-10: session-start 缺少 unknown fallback（向後相容性風險）"
  fi
}

# ---------------------------------------------------------------------------
# 執行所有測試
# ---------------------------------------------------------------------------
echo "=== test-572-resolve-session-id.sh ==="
echo ""

test_tc00_script_exists
test_tc01_claude_session_id_takes_precedence
test_tc02_shikigami_session_id_preserved
test_tc03_claude_session_id_overrides_shikigami
test_tc04_jsonl_dir_fallback
test_tc05_pid_fallback
test_tc06_cron_mode_compat
test_tc07_export_present
test_tc08_hooks_integration
test_tc09_cruise_skill_updated
test_tc10_backward_compat_unknown

echo ""
echo "=== 結果 ==="
echo "PASS: $PASS_COUNT  FAIL: $FAIL_COUNT"

if [[ $FAIL_COUNT -gt 0 ]]; then
  exit 1
else
  exit 0
fi
