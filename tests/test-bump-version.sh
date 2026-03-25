#!/usr/bin/env bash
# tests/test-bump-version.sh
# Story #839：bump-version.sh 自動化測試 — 版號同步 5 檔驗證
# 覆蓋 AC1（patch bump）/ AC2（minor bump）/ AC3（5 檔版號一致）/ AC4（exit 0）

set -euo pipefail

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

assert_file_contains() {
  local file="$1"
  local needle="$2"
  local label="$3"
  if [ ! -f "$file" ]; then
    fail "$label (檔案不存在：$file)"
    return
  fi
  if grep -qF "$needle" "$file"; then
    pass "$label"
  else
    fail "$label (檔案中找不到「$needle」：$file)"
  fi
}

assert_json_version() {
  local file="$1"
  local expected_version="$2"
  local label="$3"
  if [ ! -f "$file" ]; then
    fail "$label (檔案不存在：$file)"
    return
  fi
  local actual_version
  if actual_version=$(jq -r '.version' "$file" 2>/dev/null); then
    if [ "$actual_version" = "$expected_version" ]; then
      pass "$label"
    else
      fail "$label (期望版本 $expected_version，實際 $actual_version：$file)"
    fi
  else
    fail "$label (無法讀取 JSON：$file)"
  fi
}

assert_json_plugins_version() {
  local file="$1"
  local expected_version="$2"
  local label="$3"
  if [ ! -f "$file" ]; then
    fail "$label (檔案不存在：$file)"
    return
  fi
  local actual_version
  if actual_version=$(jq -r '.plugins[0].version' "$file" 2>/dev/null); then
    if [ "$actual_version" = "$expected_version" ]; then
      pass "$label"
    else
      fail "$label (期望版本 $expected_version，實際 $actual_version：$file)"
    fi
  else
    fail "$label (無法讀取 JSON：$file)"
  fi
}

# ---------------------------------------------------------------------------
# 測試環境設置
# ---------------------------------------------------------------------------
SCRIPT_UNDER_TEST="$(cd "$(dirname "$0")/.." && pwd)/scripts/bump-version.sh"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# 若系統未安裝 jq，建立 mock jq
_MOCK_BIN_DIR=""
MOCK_JQ_PATH=""

if ! command -v jq &>/dev/null; then
  _MOCK_BIN_DIR=$(mktemp -d)
  cat > "$_MOCK_BIN_DIR/jq" <<'MOCKJQ'
#!/usr/bin/env bash
# mock jq：實作測試所需的最小子集
filter="$2"
file="$3"
content=$(cat "$file")
case "$filter" in
  '.version')
    echo "$content" | grep -oP '"version"\s*:\s*"\K[^"]*' | head -1
    ;;
  '.plugins[0].version')
    echo "$content" | grep -oP '"version"\s*:\s*"\K[^"]*' | head -1
    ;;
  *)
    echo "" ;;
esac
MOCKJQ
  chmod +x "$_MOCK_BIN_DIR/jq"
  MOCK_JQ_PATH="$_MOCK_BIN_DIR"
fi

cleanup_mock() {
  [ -n "$_MOCK_BIN_DIR" ] && rm -rf "$_MOCK_BIN_DIR"
}
trap cleanup_mock EXIT

# 建立隔離的測試環境（fixture）
setup_fixture() {
  local tmpdir
  tmpdir=$(mktemp -d)

  # 建立 .claude-plugin 目錄結構
  mkdir -p "$tmpdir/.claude-plugin"

  # 建立初始版號檔案
  cat > "$tmpdir/.claude-plugin/plugin.json" <<'EOF'
{
  "name": "shikigami",
  "version": "0.106.0"
}
EOF

  cat > "$tmpdir/.claude-plugin/marketplace.json" <<'EOF'
{
  "plugins": [
    {
      "name": "shikigami",
      "version": "0.106.0"
    }
  ]
}
EOF

  cat > "$tmpdir/gemini-extension.json" <<'EOF'
{
  "name": "shikigami",
  "version": "0.106.0"
}
EOF

  cat > "$tmpdir/CLAUDE.md" <<'EOF'
# Shikigami — Claude Code Plugin 開發指南

- **專案名稱**：Shikigami（式神）
- **性質**：Claude Code Plugin — AI Agent Scrum Team 框架
- **目前版本**：v0.106.0
EOF

  cat > "$tmpdir/README.md" <<'EOF'
# Shikigami

![Version](https://img.shields.io/badge/version-v0.106.0-blue?style=flat-square)
EOF

  echo "$tmpdir"
}

run_script() {
  local dir="$1"
  local version="$2"
  local effective_path="${MOCK_JQ_PATH:+$MOCK_JQ_PATH:}$PATH"
  if LAST_OUTPUT=$(cd "$dir" && PATH="$effective_path" bash "$SCRIPT_UNDER_TEST" "$version" 2>&1); then
    LAST_EXIT_CODE=0
  else
    LAST_EXIT_CODE=$?
  fi
}

# ---------------------------------------------------------------------------
# TC-01：AC1 PASS — patch bump（v0.106.0 → v0.106.1）後 5 檔版號一致
# ---------------------------------------------------------------------------
test_ac1_patch_bump() {
  local fixture
  fixture=$(setup_fixture)

  run_script "$fixture" "0.106.1"

  assert_exit_code 0 "$LAST_EXIT_CODE" "TC-01 patch bump exit 0"
  assert_json_version "$fixture/.claude-plugin/plugin.json" "0.106.1" "TC-01 plugin.json 版號更新"
  assert_json_plugins_version "$fixture/.claude-plugin/marketplace.json" "0.106.1" "TC-01 marketplace.json 版號更新"
  assert_json_version "$fixture/gemini-extension.json" "0.106.1" "TC-01 gemini-extension.json 版號更新"
  assert_file_contains "$fixture/CLAUDE.md" "v0.106.1" "TC-01 CLAUDE.md 版號更新"
  assert_file_contains "$fixture/README.md" "v0.106.1" "TC-01 README.md badge 更新"

  rm -rf "$fixture"
}

# ---------------------------------------------------------------------------
# TC-02：AC2 PASS — minor bump（v0.106.0 → v0.107.0）後 5 檔版號一致
# ---------------------------------------------------------------------------
test_ac2_minor_bump() {
  local fixture
  fixture=$(setup_fixture)

  run_script "$fixture" "0.107.0"

  assert_exit_code 0 "$LAST_EXIT_CODE" "TC-02 minor bump exit 0"
  assert_json_version "$fixture/.claude-plugin/plugin.json" "0.107.0" "TC-02 plugin.json 版號更新"
  assert_json_plugins_version "$fixture/.claude-plugin/marketplace.json" "0.107.0" "TC-02 marketplace.json 版號更新"
  assert_json_version "$fixture/gemini-extension.json" "0.107.0" "TC-02 gemini-extension.json 版號更新"
  assert_file_contains "$fixture/CLAUDE.md" "v0.107.0" "TC-02 CLAUDE.md 版號更新"
  assert_file_contains "$fixture/README.md" "v0.107.0" "TC-02 README.md badge 更新"

  rm -rf "$fixture"
}

# ---------------------------------------------------------------------------
# TC-03：AC3 PASS — fixture 隔離驗證（不修改真實檔案）
# ---------------------------------------------------------------------------
test_ac3_fixture_isolation() {
  local fixture
  fixture=$(setup_fixture)

  # 保存真實檔案版號
  local real_plugin_version
  real_plugin_version=$(jq -r '.version' "$PROJECT_ROOT/.claude-plugin/plugin.json")

  run_script "$fixture" "0.108.0"

  # 確認真實檔案未被修改
  local real_plugin_version_after
  real_plugin_version_after=$(jq -r '.version' "$PROJECT_ROOT/.claude-plugin/plugin.json")

  if [ "$real_plugin_version" = "$real_plugin_version_after" ]; then
    pass "TC-03 fixture 隔離：真實檔案未修改"
  else
    fail "TC-03 fixture 隔離：真實檔案被修改"
  fi

  # 確認 fixture 檔案被修改
  assert_json_version "$fixture/.claude-plugin/plugin.json" "0.108.0" "TC-03 fixture 檔案被修改"

  rm -rf "$fixture"
}

# ---------------------------------------------------------------------------
# TC-04：AC4 PASS — exit 0
# ---------------------------------------------------------------------------
test_ac4_exit_code() {
  local fixture
  fixture=$(setup_fixture)

  run_script "$fixture" "0.106.1"

  assert_exit_code 0 "$LAST_EXIT_CODE" "TC-04 正常執行 exit 0"

  rm -rf "$fixture"
}

# ---------------------------------------------------------------------------
# TC-05：格式驗證 — 無效版本號格式應 exit 1
# ---------------------------------------------------------------------------
test_invalid_version_format() {
  local fixture
  fixture=$(setup_fixture)

  run_script "$fixture" "invalid-version"

  assert_exit_code 1 "$LAST_EXIT_CODE" "TC-05 無效版本號 exit 1"

  rm -rf "$fixture"
}

# ---------------------------------------------------------------------------
# TC-06：version 格式驗證 — major bump 應成功
# ---------------------------------------------------------------------------
test_major_bump_valid() {
  local fixture
  fixture=$(setup_fixture)

  run_script "$fixture" "1.0.0"

  assert_exit_code 0 "$LAST_EXIT_CODE" "TC-06 major bump exit 0"
  assert_json_version "$fixture/.claude-plugin/plugin.json" "1.0.0" "TC-06 major bump plugin.json 更新"

  rm -rf "$fixture"
}

# ---------------------------------------------------------------------------
# 執行所有測試
# ---------------------------------------------------------------------------
echo "=============================="
echo " Story #839 bump-version.sh 測試套件"
echo "=============================="
echo ""

test_ac1_patch_bump
test_ac2_minor_bump
test_ac3_fixture_isolation
test_ac4_exit_code
test_invalid_version_format
test_major_bump_valid

echo ""
echo "=============================="
echo " 結果：PASS=$PASS_COUNT  FAIL=$FAIL_COUNT"
echo "=============================="

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
