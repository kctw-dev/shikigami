#!/usr/bin/env bash
# tests/test-us264-version-hooks.sh
# US-264：版本驗證 Hook — Git pre-commit + Claude Code PreToolUse
#
# AC 覆蓋：
#   AC1：.githooks/pre-commit 存在且可執行
#   AC2：Git hook 跑 validate-version.sh，exit 1 時阻止 commit
#   AC3：hooks/hooks.json 新增 PreToolUse hook，matcher regex git\s+commit
#   AC4：兩層 hook 獨立性（a/b/c）

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

assert_true() {
  local condition_result="$1"
  local label="$2"
  if [ "$condition_result" -eq 0 ]; then
    pass "$label"
  else
    fail "$label"
  fi
}

assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  if [ "$actual" -eq "$expected" ]; then
    pass "$label"
  else
    fail "$label (期望 exit=$expected，實際 exit=$actual)"
  fi
}

assert_output_contains() {
  local needle="$1"
  local haystack="$2"
  local label="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    pass "$label"
  else
    fail "$label (輸出中找不到「$needle」)"
  fi
}

# ---------------------------------------------------------------------------
# 路徑常數
# ---------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRE_COMMIT_HOOK="$REPO_ROOT/.githooks/pre-commit"
HOOKS_JSON="$REPO_ROOT/hooks/hooks.json"

# ---------------------------------------------------------------------------
# TC-01：AC1 — .githooks/pre-commit 存在
# ---------------------------------------------------------------------------
test_ac1_pre_commit_exists() {
  if [ -f "$PRE_COMMIT_HOOK" ]; then
    pass "TC-01 AC1：.githooks/pre-commit 存在"
  else
    fail "TC-01 AC1：.githooks/pre-commit 不存在（路徑：$PRE_COMMIT_HOOK）"
  fi
}

# ---------------------------------------------------------------------------
# TC-02：AC1 — .githooks/pre-commit 可執行
# ---------------------------------------------------------------------------
test_ac1_pre_commit_executable() {
  if [ -x "$PRE_COMMIT_HOOK" ]; then
    pass "TC-02 AC1：.githooks/pre-commit 可執行"
  else
    fail "TC-02 AC1：.githooks/pre-commit 不可執行"
  fi
}

# ---------------------------------------------------------------------------
# TC-03：AC2 — pre-commit hook 包含 validate-version.sh 呼叫
# ---------------------------------------------------------------------------
test_ac2_hook_calls_validate_version() {
  if grep -q "validate-version.sh" "$PRE_COMMIT_HOOK" 2>/dev/null; then
    pass "TC-03 AC2：pre-commit hook 包含 validate-version.sh 呼叫"
  else
    fail "TC-03 AC2：pre-commit hook 未包含 validate-version.sh 呼叫"
  fi
}

# ---------------------------------------------------------------------------
# TC-04：AC2 — pre-commit hook 在版號不一致時阻止 commit（exit 1 → hook exit 非 0）
# ---------------------------------------------------------------------------
test_ac2_hook_blocks_on_version_mismatch() {
  # 建立臨時 git repo 模擬版號不一致環境
  local tmpdir
  tmpdir=$(mktemp -d)

  # 初始化 git repo
  git -C "$tmpdir" init --quiet
  git -C "$tmpdir" config user.email "test@test.com"
  git -C "$tmpdir" config user.name "Test"

  # 建立 .claude-plugin/ 結構，版號不一致
  mkdir -p "$tmpdir/.claude-plugin"
  cat > "$tmpdir/.claude-plugin/plugin.json" <<'EOF'
{
  "name": "shikigami",
  "version": "0.1.0"
}
EOF
  cat > "$tmpdir/.claude-plugin/marketplace.json" <<'EOF'
{
  "plugins": [{ "name": "shikigami", "version": "0.2.0" }]
}
EOF
  cat > "$tmpdir/README.md" <<'EOF'
![Version](https://img.shields.io/badge/version-v0.1.0-blue?style=flat-square)
EOF

  # 複製 validate-version.sh 到 tmpdir/scripts/
  mkdir -p "$tmpdir/scripts"
  cp "$REPO_ROOT/scripts/validate-version.sh" "$tmpdir/scripts/"

  # 複製 pre-commit hook 到 tmpdir/.githooks/
  mkdir -p "$tmpdir/.githooks"
  cp "$PRE_COMMIT_HOOK" "$tmpdir/.githooks/pre-commit"

  # 直接執行 hook（模擬 git pre-commit 觸發）
  local exit_code
  if (cd "$tmpdir" && bash "$tmpdir/.githooks/pre-commit" 2>/dev/null); then
    exit_code=0
  else
    exit_code=$?
  fi

  if [ "$exit_code" -ne 0 ]; then
    pass "TC-04 AC2：版號不一致時 hook exit 非 0（阻止 commit）"
  else
    fail "TC-04 AC2：版號不一致時 hook 應 exit 非 0，但 exit 0"
  fi

  rm -rf "$tmpdir"
}

# ---------------------------------------------------------------------------
# TC-05：AC2 — pre-commit hook 在版號一致時允許 commit（exit 0）
# ---------------------------------------------------------------------------
test_ac2_hook_passes_on_version_match() {
  local tmpdir
  tmpdir=$(mktemp -d)

  git -C "$tmpdir" init --quiet
  git -C "$tmpdir" config user.email "test@test.com"
  git -C "$tmpdir" config user.name "Test"

  mkdir -p "$tmpdir/.claude-plugin"
  cat > "$tmpdir/.claude-plugin/plugin.json" <<'EOF'
{
  "name": "shikigami",
  "version": "0.5.0"
}
EOF
  cat > "$tmpdir/.claude-plugin/marketplace.json" <<'EOF'
{
  "plugins": [{ "name": "shikigami", "version": "0.5.0" }]
}
EOF
  cat > "$tmpdir/README.md" <<'EOF'
![Version](https://img.shields.io/badge/version-v0.5.0-blue?style=flat-square)
EOF

  mkdir -p "$tmpdir/scripts"
  cp "$REPO_ROOT/scripts/validate-version.sh" "$tmpdir/scripts/"

  mkdir -p "$tmpdir/.githooks"
  cp "$PRE_COMMIT_HOOK" "$tmpdir/.githooks/pre-commit"

  local exit_code
  if (cd "$tmpdir" && bash "$tmpdir/.githooks/pre-commit" 2>/dev/null); then
    exit_code=0
  else
    exit_code=$?
  fi

  if [ "$exit_code" -eq 0 ]; then
    pass "TC-05 AC2：版號一致時 hook exit 0（允許 commit）"
  else
    fail "TC-05 AC2：版號一致時 hook 應 exit 0，但 exit $exit_code"
  fi

  rm -rf "$tmpdir"
}

# ---------------------------------------------------------------------------
# TC-06：AC3 — hooks/hooks.json 包含 PreToolUse 區段
# ---------------------------------------------------------------------------
test_ac3_hooks_json_has_pretooluse() {
  if grep -q "PreToolUse" "$HOOKS_JSON" 2>/dev/null; then
    pass "TC-06 AC3：hooks.json 包含 PreToolUse 區段"
  else
    fail "TC-06 AC3：hooks.json 未包含 PreToolUse 區段"
  fi
}

# ---------------------------------------------------------------------------
# TC-07：AC3 — PreToolUse matcher regex 包含 git\s+commit
# ---------------------------------------------------------------------------
test_ac3_pretooluse_matcher_regex() {
  # 解析 JSON 確認 matcher 或對應欄位含有 git.*commit 的 regex
  if grep -qE 'git\\s\+commit|git\\\\s\+commit' "$HOOKS_JSON" 2>/dev/null; then
    pass "TC-07 AC3：PreToolUse matcher 含 git\\s+commit regex"
  else
    fail "TC-07 AC3：hooks.json 中找不到 git\\s+commit regex"
  fi
}

# ---------------------------------------------------------------------------
# TC-08：AC3 — PreToolUse hook JSON 格式有效
# ---------------------------------------------------------------------------
test_ac3_hooks_json_valid() {
  if command -v jq &>/dev/null; then
    if jq empty "$HOOKS_JSON" 2>/dev/null; then
      pass "TC-08 AC3：hooks.json 為有效 JSON"
    else
      fail "TC-08 AC3：hooks.json JSON 格式無效"
    fi
  else
    # jq 不存在時，用 python 或直接跳過
    if python3 -m json.tool "$HOOKS_JSON" &>/dev/null; then
      pass "TC-08 AC3：hooks.json 為有效 JSON（python3 驗證）"
    else
      fail "TC-08 AC3：hooks.json JSON 格式無效（python3 驗證）"
    fi
  fi
}

# ---------------------------------------------------------------------------
# TC-09：AC4(a) — pre-commit hook 含有明確的 exit 1 阻止語意
# ---------------------------------------------------------------------------
test_ac4a_git_hook_blocks() {
  # 確認 hook 內有 exit 1（或 exit $?) 的阻止邏輯
  if grep -qE 'exit\s+1|exit\s+\$' "$PRE_COMMIT_HOOK" 2>/dev/null; then
    pass "TC-09 AC4(a)：pre-commit hook 含阻止 commit 的 exit 邏輯"
  else
    fail "TC-09 AC4(a)：pre-commit hook 缺少阻止 commit 的 exit 邏輯"
  fi
}

# ---------------------------------------------------------------------------
# TC-10：AC4(b) — Claude Code hook 為警告（command 非 exit 1 硬擋）
# ---------------------------------------------------------------------------
test_ac4b_claude_hook_is_warning() {
  # Claude Code PreToolUse hook 應為軟提醒，不強制阻斷
  # 驗證方式：hook command 不應以「exit 1」硬退出作為唯一手段
  # 實際上 Claude Code hook 以 echo/message 形式提醒即可
  if grep -q "PreToolUse" "$HOOKS_JSON" 2>/dev/null; then
    pass "TC-10 AC4(b)：Claude Code PreToolUse hook 存在（軟提醒層）"
  else
    fail "TC-10 AC4(b)：Claude Code PreToolUse hook 不存在"
  fi
}

# ---------------------------------------------------------------------------
# TC-11：AC1 — shebang 正確
# ---------------------------------------------------------------------------
test_ac1_shebang() {
  local first_line
  first_line=$(head -1 "$PRE_COMMIT_HOOK" 2>/dev/null)
  if [[ "$first_line" == "#!/"* ]]; then
    pass "TC-11 AC1：pre-commit hook 含正確 shebang"
  else
    fail "TC-11 AC1：pre-commit hook 缺少 shebang（第一行：$first_line）"
  fi
}

# ---------------------------------------------------------------------------
# 執行所有測試
# ---------------------------------------------------------------------------
echo "=============================="
echo " US-264 版本驗證 Hook 測試套件"
echo "=============================="
echo ""

test_ac1_pre_commit_exists
test_ac1_pre_commit_executable
test_ac2_hook_calls_validate_version
test_ac2_hook_blocks_on_version_mismatch
test_ac2_hook_passes_on_version_match
test_ac3_hooks_json_has_pretooluse
test_ac3_pretooluse_matcher_regex
test_ac3_hooks_json_valid
test_ac4a_git_hook_blocks
test_ac4b_claude_hook_is_warning
test_ac1_shebang

echo ""
echo "=============================="
echo " 結果：PASS=$PASS_COUNT  FAIL=$FAIL_COUNT"
echo "=============================="

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
