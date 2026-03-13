#!/usr/bin/env bash
# tests/test-validate-version.sh
# US-T04：版號一致性驗證 — 測試套件
# 覆蓋 AC1（plugin.json 一致性）/ AC2（git tag 一致性）/ AC3（0.x.x 降級 WARNING）

set -euo pipefail

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
# 輔助：建立隔離的臨時測試環境
# ---------------------------------------------------------------------------
SCRIPT_UNDER_TEST="$(cd "$(dirname "$0")/.." && pwd)/scripts/validate-version.sh"

# ---------------------------------------------------------------------------
# 若系統未安裝 jq，建立全域 mock jq（僅建立一次）
# mock jq 支援測試所需的最小子集：
#   jq -r '.version' file
#   jq -r '.plugins[0].version' file
# ---------------------------------------------------------------------------
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

# 測試結束時清除 mock bin 目錄
cleanup_mock() {
  [ -n "$_MOCK_BIN_DIR" ] && rm -rf "$_MOCK_BIN_DIR"
}
trap cleanup_mock EXIT

setup_env() {
  # 建立臨時目錄，模擬完整的 git repo + .claude-plugin 結構
  local tmpdir
  tmpdir=$(mktemp -d)
  git -C "$tmpdir" init --quiet
  git -C "$tmpdir" config user.email "test@test.com"
  git -C "$tmpdir" config user.name "Test"
  # git 需要至少一個 commit 才能打 tag
  touch "$tmpdir/.gitkeep"
  git -C "$tmpdir" add .gitkeep
  git -C "$tmpdir" commit --quiet -m "init"
  mkdir -p "$tmpdir/.claude-plugin"
  echo "$tmpdir"
}

write_plugin_json() {
  local dir="$1"
  local version="$2"
  cat > "$dir/.claude-plugin/plugin.json" <<EOF
{
  "name": "shikigami",
  "version": "$version"
}
EOF
}

write_marketplace_json() {
  local dir="$1"
  local version="$2"
  cat > "$dir/.claude-plugin/marketplace.json" <<EOF
{
  "plugins": [
    {
      "name": "shikigami",
      "version": "$version"
    }
  ]
}
EOF
}

run_script() {
  # 在指定目錄下執行腳本，捕捉 exit code 與輸出
  # 若有 MOCK_JQ_PATH，將其加入 PATH 前端以啟用 mock jq
  # 使用 if 結構避免 set -e 提前中止，同時正確取得非零 exit code
  local dir="$1"
  local effective_path="${MOCK_JQ_PATH:+$MOCK_JQ_PATH:}$PATH"
  if LAST_OUTPUT=$(cd "$dir" && PATH="$effective_path" bash "$SCRIPT_UNDER_TEST" 2>&1); then
    LAST_EXIT_CODE=0
  else
    LAST_EXIT_CODE=$?
  fi
}

# ---------------------------------------------------------------------------
# TC-01：AC1 PASS — plugin.json 與 marketplace.json 版號一致，exit 0
# ---------------------------------------------------------------------------
test_ac1_pass() {
  local tmpdir
  tmpdir=$(setup_env)
  write_plugin_json    "$tmpdir" "0.1.0"
  write_marketplace_json "$tmpdir" "0.1.0"

  run_script "$tmpdir"

  assert_exit_code 0 "$LAST_EXIT_CODE" "TC-01 AC1 PASS：版號一致 exit 0"
  assert_output_contains "PASS" "$LAST_OUTPUT" "TC-01 AC1 PASS：輸出含 PASS 標記"

  rm -rf "$tmpdir"
}

# ---------------------------------------------------------------------------
# TC-02：AC1 FAIL — plugin.json 與 marketplace.json 版號不一致，exit 1
# ---------------------------------------------------------------------------
test_ac1_fail() {
  local tmpdir
  tmpdir=$(setup_env)
  write_plugin_json    "$tmpdir" "0.1.0"
  write_marketplace_json "$tmpdir" "0.2.0"

  run_script "$tmpdir"

  assert_exit_code 1 "$LAST_EXIT_CODE" "TC-02 AC1 FAIL：版號不一致 exit 1"
  assert_output_contains "FAIL" "$LAST_OUTPUT" "TC-02 AC1 FAIL：輸出含 FAIL 標記"

  rm -rf "$tmpdir"
}

# ---------------------------------------------------------------------------
# TC-03：AC2 無 tag — 跳過 tag 檢查，exit 0
# ---------------------------------------------------------------------------
test_ac2_no_tag() {
  local tmpdir
  tmpdir=$(setup_env)
  write_plugin_json    "$tmpdir" "0.1.0"
  write_marketplace_json "$tmpdir" "0.1.0"
  # 不打任何 tag

  run_script "$tmpdir"

  assert_exit_code 0 "$LAST_EXIT_CODE" "TC-03 AC2 無 tag：跳過 tag 檢查 exit 0"

  rm -rf "$tmpdir"
}

# ---------------------------------------------------------------------------
# TC-04：AC2 PASS — 有 tag 且與 plugin.json 一致，exit 0
# ---------------------------------------------------------------------------
test_ac2_tag_match() {
  local tmpdir
  tmpdir=$(setup_env)
  write_plugin_json    "$tmpdir" "1.0.0"
  write_marketplace_json "$tmpdir" "1.0.0"
  git -C "$tmpdir" tag v1.0.0

  run_script "$tmpdir"

  assert_exit_code 0 "$LAST_EXIT_CODE" "TC-04 AC2 tag 一致 exit 0"
  assert_output_contains "PASS" "$LAST_OUTPUT" "TC-04 AC2 tag 一致：輸出含 PASS 標記"

  rm -rf "$tmpdir"
}

# ---------------------------------------------------------------------------
# TC-05：AC3 — 0.x.x 版本 tag 不一致時降級為 WARNING，exit 0
# ---------------------------------------------------------------------------
test_ac3_dev_version_warning() {
  local tmpdir
  tmpdir=$(setup_env)
  write_plugin_json    "$tmpdir" "0.1.0"
  write_marketplace_json "$tmpdir" "0.1.0"
  git -C "$tmpdir" tag v0.2.0  # tag 與 plugin.json 不一致

  run_script "$tmpdir"

  assert_exit_code 0 "$LAST_EXIT_CODE" "TC-05 AC3 0.x.x tag 不一致降級 WARNING exit 0"
  assert_output_contains "WARNING" "$LAST_OUTPUT" "TC-05 AC3 0.x.x：輸出含 WARNING 標記"

  rm -rf "$tmpdir"
}

# ---------------------------------------------------------------------------
# TC-06：AC3 — 1.x.x 版本 tag 不一致時為 FAIL，exit 1
# ---------------------------------------------------------------------------
test_ac3_stable_version_fail() {
  local tmpdir
  tmpdir=$(setup_env)
  write_plugin_json    "$tmpdir" "1.0.0"
  write_marketplace_json "$tmpdir" "1.0.0"
  git -C "$tmpdir" tag v1.1.0  # tag 與 plugin.json 不一致

  run_script "$tmpdir"

  assert_exit_code 1 "$LAST_EXIT_CODE" "TC-06 AC3 1.x.x tag 不一致 FAIL exit 1"
  assert_output_contains "FAIL" "$LAST_OUTPUT" "TC-06 AC3 1.x.x：輸出含 FAIL 標記"

  rm -rf "$tmpdir"
}

# ---------------------------------------------------------------------------
# TC-07：AC2 jq 缺失 — 輸出含安裝建議的錯誤訊息，exit 1
# ---------------------------------------------------------------------------

# 建立一個不含 jq 的 PATH，用於模擬 jq 不存在的環境
make_no_jq_path() {
  # 過濾掉含有 jq 可執行檔的所有目錄
  local filtered_path=""
  local IFS=":"
  for dir in $PATH; do
    if [ -x "$dir/jq" ]; then
      continue  # 跳過含有 jq 的目錄
    fi
    filtered_path="${filtered_path:+$filtered_path:}$dir"
  done
  echo "$filtered_path"
}

run_script_no_jq() {
  # 執行腳本，但確保 jq 不在 PATH 中（無論系統是否安裝 jq）
  local dir="$1"
  local no_jq_path
  no_jq_path=$(make_no_jq_path)
  if LAST_OUTPUT=$(cd "$dir" && PATH="$no_jq_path" bash "$SCRIPT_UNDER_TEST" 2>&1); then
    LAST_EXIT_CODE=0
  else
    LAST_EXIT_CODE=$?
  fi
}

test_ac2_jq_missing() {
  local tmpdir
  tmpdir=$(setup_env)
  write_plugin_json    "$tmpdir" "0.1.0"
  write_marketplace_json "$tmpdir" "0.1.0"

  run_script_no_jq "$tmpdir"

  assert_exit_code 1 "$LAST_EXIT_CODE" "TC-07 AC2 jq 缺失：exit 1"
  assert_output_contains "jq" "$LAST_OUTPUT" "TC-07 AC2 jq 缺失：輸出含 jq 提示"
  assert_output_contains "install" "$LAST_OUTPUT" "TC-07 AC2 jq 缺失：輸出含安裝建議"

  rm -rf "$tmpdir"
}

# ---------------------------------------------------------------------------
# TC-08：AC4 版本為空字串 — 腳本 FAIL（exit 1），而非靜默 PASS
# ---------------------------------------------------------------------------
test_ac4_empty_version_fail() {
  local tmpdir
  tmpdir=$(setup_env)

  # 寫入含空 version 的 plugin.json（直接寫入空字串）
  cat > "$tmpdir/.claude-plugin/plugin.json" <<'EOF'
{
  "name": "shikigami",
  "version": ""
}
EOF
  write_marketplace_json "$tmpdir" ""

  run_script "$tmpdir"

  assert_exit_code 1 "$LAST_EXIT_CODE" "TC-08 AC4 空字串版本：exit 1"
  assert_output_contains "FAIL" "$LAST_OUTPUT" "TC-08 AC4 空字串版本：輸出含 FAIL 標記"

  rm -rf "$tmpdir"
}

# ---------------------------------------------------------------------------
# 執行所有測試
# ---------------------------------------------------------------------------
echo "=============================="
echo " US-T04 版號一致性驗證 測試套件"
echo "=============================="
echo ""

test_ac1_pass
test_ac1_fail
test_ac2_no_tag
test_ac2_tag_match
test_ac3_dev_version_warning
test_ac3_stable_version_fail
test_ac2_jq_missing
test_ac4_empty_version_fail

echo ""
echo "=============================="
echo " 結果：PASS=$PASS_COUNT  FAIL=$FAIL_COUNT"
echo "=============================="

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
