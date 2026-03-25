#!/usr/bin/env bash
# tests/test-validate-json.sh
# Story #838：JSON Schema 驗證 — 測試套件
#
# 驗證 scripts/validate-json.sh 的行為符合 AC1-AC5
# - AC1：驗證 plugin.json 必填欄位（name、version、description、author）
# - AC2：驗證 marketplace.json 必填欄位（name、plugins）
# - AC3：驗證 version 格式符合 semver（major.minor.patch）
# - AC4：驗證 plugin.json 欄位白名單（白名單外欄位觸發 WARNING，非 ERROR）
# - AC5：exit code 0 無 ERROR，非 0 有 ERROR

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATE_SCRIPT="${REPO_ROOT}/scripts/validate-json.sh"
PASS=0
FAIL=0

# Helper functions
pass() {
  echo "[PASS] $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "[FAIL] $1"
  FAIL=$((FAIL + 1))
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

# Setup temporary test environment
setup_test_env() {
  local tmpdir
  tmpdir=$(mktemp -d)
  mkdir -p "$tmpdir/.claude-plugin"
  echo "$tmpdir"
}

# Write a valid plugin.json
write_valid_plugin_json() {
  local dir="$1"
  local version="${2:-0.1.0}"
  cat > "$dir/.claude-plugin/plugin.json" <<EOF
{
  "name": "test-plugin",
  "version": "$version",
  "description": "A test plugin",
  "author": "Test Author"
}
EOF
}

# Write a valid marketplace.json
write_valid_marketplace_json() {
  local dir="$1"
  local version="${2:-0.1.0}"
  cat > "$dir/.claude-plugin/marketplace.json" <<EOF
{
  "name": "test-plugin",
  "plugins": [
    {
      "name": "test-plugin",
      "version": "$version"
    }
  ]
}
EOF
}

# Run validate script and return exit code
run_validate_test() {
  local tmpdir="$1"
  local exit_code
  cd "$tmpdir"
  if bash "$VALIDATE_SCRIPT" > /tmp/validate_json_output.txt 2>&1; then
    exit_code=0
  else
    exit_code=$?
  fi
  cd "$REPO_ROOT"
  echo "$exit_code"
}

echo "=============================="
echo " Story #838 - test-validate-json.sh"
echo "=============================="
echo ""

# ── Pre-check: validate-json.sh 必須存在 ────────────────────────────────
if [[ ! -f "$VALIDATE_SCRIPT" ]]; then
  fail "scripts/validate-json.sh 不存在"
  echo "FAIL: $FAIL / PASS: $PASS"
  exit 1
fi
pass "scripts/validate-json.sh 存在"

# ── TC-01: AC1 PASS — plugin.json 包含所有必填欄位 ──────────────────────────
tmpdir=$(setup_test_env)
write_valid_plugin_json "$tmpdir" "0.1.0"
write_valid_marketplace_json "$tmpdir" "0.1.0"
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_json_output.txt)

assert_exit_code 0 "$exit_code" "TC-01 AC1 plugin.json 有效：exit 0"
assert_output_contains "name" "$output" "TC-01 AC1：輸出驗證 name 欄位"
assert_output_contains "version" "$output" "TC-01 AC1：輸出驗證 version 欄位"
assert_output_contains "description" "$output" "TC-01 AC1：輸出驗證 description 欄位"
assert_output_contains "author" "$output" "TC-01 AC1：輸出驗證 author 欄位"
rm -rf "$tmpdir"

# ── TC-02: AC1 FAIL — plugin.json 缺少 name ──────────────────────────────
tmpdir=$(setup_test_env)
cat > "$tmpdir/.claude-plugin/plugin.json" <<'EOF'
{
  "version": "0.1.0",
  "description": "Missing name",
  "author": "Test"
}
EOF
write_valid_marketplace_json "$tmpdir" "0.1.0"
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_json_output.txt)

assert_exit_code 1 "$exit_code" "TC-02 AC1 缺少 name：exit 1"
assert_output_contains "缺少必填欄位「name」" "$output" "TC-02 AC1 缺少 name：輸出含錯誤訊息"
rm -rf "$tmpdir"

# ── TC-03: AC1 FAIL — plugin.json 缺少 version ──────────────────────────
tmpdir=$(setup_test_env)
cat > "$tmpdir/.claude-plugin/plugin.json" <<'EOF'
{
  "name": "test-plugin",
  "description": "Missing version",
  "author": "Test"
}
EOF
write_valid_marketplace_json "$tmpdir" "0.1.0"
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_json_output.txt)

assert_exit_code 1 "$exit_code" "TC-03 AC1 缺少 version：exit 1"
assert_output_contains "缺少必填欄位「version」" "$output" "TC-03 AC1 缺少 version：輸出含錯誤訊息"
rm -rf "$tmpdir"

# ── TC-04: AC1 FAIL — plugin.json 缺少 description ───────────────────────
tmpdir=$(setup_test_env)
cat > "$tmpdir/.claude-plugin/plugin.json" <<'EOF'
{
  "name": "test-plugin",
  "version": "0.1.0",
  "author": "Test"
}
EOF
write_valid_marketplace_json "$tmpdir" "0.1.0"
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_json_output.txt)

assert_exit_code 1 "$exit_code" "TC-04 AC1 缺少 description：exit 1"
assert_output_contains "缺少必填欄位「description」" "$output" "TC-04 AC1 缺少 description：輸出含錯誤訊息"
rm -rf "$tmpdir"

# ── TC-05: AC1 FAIL — plugin.json 缺少 author ──────────────────────────
tmpdir=$(setup_test_env)
cat > "$tmpdir/.claude-plugin/plugin.json" <<'EOF'
{
  "name": "test-plugin",
  "version": "0.1.0",
  "description": "Missing author"
}
EOF
write_valid_marketplace_json "$tmpdir" "0.1.0"
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_json_output.txt)

assert_exit_code 1 "$exit_code" "TC-05 AC1 缺少 author：exit 1"
assert_output_contains "缺少必填欄位「author」" "$output" "TC-05 AC1 缺少 author：輸出含錯誤訊息"
rm -rf "$tmpdir"

# ── TC-06: AC2 PASS — marketplace.json 包含所有必填欄位 ────────────────────
tmpdir=$(setup_test_env)
write_valid_plugin_json "$tmpdir" "0.1.0"
write_valid_marketplace_json "$tmpdir" "0.1.0"
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_json_output.txt)

assert_exit_code 0 "$exit_code" "TC-06 AC2 marketplace.json 有效：exit 0"
assert_output_contains "plugins" "$output" "TC-06 AC2：輸出驗證 plugins 欄位"
rm -rf "$tmpdir"

# ── TC-07: AC2 FAIL — marketplace.json 缺少 name ──────────────────────────
tmpdir=$(setup_test_env)
write_valid_plugin_json "$tmpdir" "0.1.0"
cat > "$tmpdir/.claude-plugin/marketplace.json" <<'EOF'
{
  "plugins": [
    {
      "name": "test-plugin",
      "version": "0.1.0"
    }
  ]
}
EOF
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_json_output.txt)

assert_exit_code 1 "$exit_code" "TC-07 AC2 缺少 name：exit 1"
assert_output_contains "缺少必填欄位「name」" "$output" "TC-07 AC2 缺少 name：輸出含錯誤訊息"
rm -rf "$tmpdir"

# ── TC-08: AC2 FAIL — marketplace.json 缺少 plugins ──────────────────────
tmpdir=$(setup_test_env)
write_valid_plugin_json "$tmpdir" "0.1.0"
cat > "$tmpdir/.claude-plugin/marketplace.json" <<'EOF'
{
  "name": "test-plugin"
}
EOF
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_json_output.txt)

assert_exit_code 1 "$exit_code" "TC-08 AC2 缺少 plugins：exit 1"
assert_output_contains "缺少必填欄位「plugins」" "$output" "TC-08 AC2 缺少 plugins：輸出含錯誤訊息"
rm -rf "$tmpdir"

# ── TC-09: AC3 PASS — version 符合 semver ────────────────────────────────
tmpdir=$(setup_test_env)
write_valid_plugin_json "$tmpdir" "1.2.3"
write_valid_marketplace_json "$tmpdir" "1.2.3"
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_json_output.txt)

assert_exit_code 0 "$exit_code" "TC-09 AC3 semver 有效：exit 0"
assert_output_contains "semver" "$output" "TC-09 AC3 semver 有效：輸出驗證通過"
rm -rf "$tmpdir"

# ── TC-10: AC3 FAIL — version 不符合 semver（缺少 patch）────────────────────
tmpdir=$(setup_test_env)
cat > "$tmpdir/.claude-plugin/plugin.json" <<'EOF'
{
  "name": "test-plugin",
  "version": "1.2",
  "description": "Invalid version",
  "author": "Test"
}
EOF
write_valid_marketplace_json "$tmpdir" "1.2"
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_json_output.txt)

assert_exit_code 1 "$exit_code" "TC-10 AC3 版本無效（缺 patch）：exit 1"
assert_output_contains "不符合 semver" "$output" "TC-10 AC3 版本無效：輸出含錯誤訊息"
rm -rf "$tmpdir"

# ── TC-11: AC3 FAIL — version 含非數字字符 ──────────────────────────────────
tmpdir=$(setup_test_env)
cat > "$tmpdir/.claude-plugin/plugin.json" <<'EOF'
{
  "name": "test-plugin",
  "version": "1.2.3-beta",
  "description": "Invalid version",
  "author": "Test"
}
EOF
write_valid_marketplace_json "$tmpdir" "1.2.3-beta"
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_json_output.txt)

assert_exit_code 1 "$exit_code" "TC-11 AC3 版本含預發標籤：exit 1"
assert_output_contains "不符合 semver" "$output" "TC-11 AC3 版本含預發標籤：輸出含錯誤訊息"
rm -rf "$tmpdir"

# ── TC-12: AC4 PASS — plugin.json 中白名單欄位 ──────────────────────────────
tmpdir=$(setup_test_env)
cat > "$tmpdir/.claude-plugin/plugin.json" <<'EOF'
{
  "name": "test-plugin",
  "version": "0.1.0",
  "description": "Test",
  "author": "Author",
  "homepage": "https://example.com",
  "license": "MIT"
}
EOF
write_valid_marketplace_json "$tmpdir" "0.1.0"
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_json_output.txt)

assert_exit_code 0 "$exit_code" "TC-12 AC4 白名單欄位有效：exit 0"
assert_output_contains "homepage" "$output" "TC-12 AC4 白名單欄位：輸出驗證通過"
rm -rf "$tmpdir"

# ── TC-13: AC4 WARNING — plugin.json 中非白名單欄位 ────────────────────────
tmpdir=$(setup_test_env)
cat > "$tmpdir/.claude-plugin/plugin.json" <<'EOF'
{
  "name": "test-plugin",
  "version": "0.1.0",
  "description": "Test",
  "author": "Author",
  "unknownField": "value"
}
EOF
write_valid_marketplace_json "$tmpdir" "0.1.0"
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_json_output.txt)

assert_exit_code 0 "$exit_code" "TC-13 AC4 非白名單欄位：exit 0（WARNING 不影響 exit code）"
assert_output_contains "WARNING" "$output" "TC-13 AC4 非白名單欄位：輸出含 WARNING 標記"
assert_output_contains "unknownField" "$output" "TC-13 AC4 非白名單欄位：輸出標明無效欄位"
rm -rf "$tmpdir"

# ── TC-14: 所有必填欄位缺失 ──────────────────────────────────────────────
tmpdir=$(setup_test_env)
cat > "$tmpdir/.claude-plugin/plugin.json" <<'EOF'
{
}
EOF
cat > "$tmpdir/.claude-plugin/marketplace.json" <<'EOF'
{
}
EOF
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_json_output.txt)

assert_exit_code 1 "$exit_code" "TC-14 所有必填欄位缺失：exit 1"
assert_output_contains "缺少必填欄位" "$output" "TC-14 所有必填欄位缺失：輸出含多個錯誤訊息"
rm -rf "$tmpdir"

# ── NFR1: 執行時間 < 5 秒 ──────────────────────────────────────────────────
tmpdir=$(setup_test_env)
write_valid_plugin_json "$tmpdir" "0.1.0"
write_valid_marketplace_json "$tmpdir" "0.1.0"
start_time=$(date +%s)
cd "$tmpdir"
bash "$VALIDATE_SCRIPT" > /tmp/validate_json_output.txt 2>&1 || true
cd "$REPO_ROOT"
end_time=$(date +%s)
duration=$((end_time - start_time))

if [ "$duration" -lt 5 ]; then
  pass "NFR1：執行時間 $duration 秒 < 5 秒"
else
  fail "NFR1：執行時間 $duration 秒 >= 5 秒"
fi
rm -rf "$tmpdir"

echo ""
echo "=============================="
echo " 結果：PASS=$PASS  FAIL=$FAIL"
echo "=============================="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
