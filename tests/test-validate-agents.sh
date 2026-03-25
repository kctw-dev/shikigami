#!/usr/bin/env bash
# tests/test-validate-agents.sh
# Story #838：Agent 定義驗證 — 測試套件
#
# 驗證 scripts/validate-agents.sh 的行為符合 AC1-AC5
# - AC1：掃描 agents/ 下所有 .md 檔案
# - AC2：驗證 frontmatter 含 name、description、model 欄位
# - AC3：驗證 model 值在白名單中（sonnet、haiku、opus）
# - AC4：驗證 description 欄位非空
# - AC5：exit 0 通過，exit 1 失敗

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATE_SCRIPT="${REPO_ROOT}/scripts/validate-agents.sh"
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
  mkdir -p "$tmpdir/agents"
  echo "$tmpdir"
}

# Write a valid agent .md file
write_valid_agent() {
  local dir="$1"
  local name="$2"
  cat > "$dir/agents/${name}.md" <<EOF
---
name: $name
description: A test agent for $name
model: sonnet
---

# $name

This is a test agent.
EOF
}

# Write an invalid agent (empty description)
write_invalid_agent_empty_desc() {
  local dir="$1"
  local name="$2"
  cat > "$dir/agents/${name}.md" <<EOF
---
name: $name
description:
model: sonnet
---

# $name

This agent has empty description.
EOF
}

# Run validate script and return exit code
run_validate_test() {
  local tmpdir="$1"
  local exit_code
  cd "$tmpdir"
  if bash "$VALIDATE_SCRIPT" > /tmp/validate_agents_output.txt 2>&1; then
    exit_code=0
  else
    exit_code=$?
  fi
  cd "$REPO_ROOT"
  echo "$exit_code"
}

echo "=============================="
echo " Story #838 - test-validate-agents.sh"
echo "=============================="
echo ""

# ── Pre-check: validate-agents.sh 必須存在 ────────────────────────────────
if [[ ! -f "$VALIDATE_SCRIPT" ]]; then
  fail "scripts/validate-agents.sh 不存在"
  echo "FAIL: $FAIL / PASS: $PASS"
  exit 1
fi
pass "scripts/validate-agents.sh 存在"

# ── TC-01: AC1 通過 — 掃描並列出所有 agent 檔案 ────────────────────────────
tmpdir=$(setup_test_env)
write_valid_agent "$tmpdir" "test-agent-1"
write_valid_agent "$tmpdir" "test-agent-2"
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_agents_output.txt)

assert_exit_code 0 "$exit_code" "TC-01 AC1：有效 agent 掃描 exit 0"
assert_output_contains "test-agent-1.md" "$output" "TC-01 AC1：輸出列出 test-agent-1.md"
assert_output_contains "test-agent-2.md" "$output" "TC-01 AC1：輸出列出 test-agent-2.md"
assert_output_contains "2 個 Agent" "$output" "TC-01 AC1：輸出顯示正確數量"
rm -rf "$tmpdir"

# ── TC-02: AC2 FAIL — 缺少 name 欄位 ─────────────────────────────────────
tmpdir=$(setup_test_env)
cat > "$tmpdir/agents/no-name.md" <<'EOF'
---
description: Agent without name
model: sonnet
---

# No Name
EOF
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_agents_output.txt)

assert_exit_code 1 "$exit_code" "TC-02 AC2 缺少 name：exit 1"
assert_output_contains "缺少 name 欄位" "$output" "TC-02 AC2 缺少 name：輸出含錯誤訊息"
rm -rf "$tmpdir"

# ── TC-03: AC2 FAIL — 缺少 description 欄位 ──────────────────────────────
tmpdir=$(setup_test_env)
cat > "$tmpdir/agents/no-desc.md" <<'EOF'
---
name: no-desc
model: sonnet
---

# No Description
EOF
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_agents_output.txt)

assert_exit_code 1 "$exit_code" "TC-03 AC2 缺少 description：exit 1"
assert_output_contains "缺少 description 欄位" "$output" "TC-03 AC2 缺少 description：輸出含錯誤訊息"
rm -rf "$tmpdir"

# ── TC-04: AC2 FAIL — 缺少 model 欄位 ───────────────────────────────────
tmpdir=$(setup_test_env)
cat > "$tmpdir/agents/no-model.md" <<'EOF'
---
name: no-model
description: Test agent
---

# No Model
EOF
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_agents_output.txt)

assert_exit_code 1 "$exit_code" "TC-04 AC2 缺少 model：exit 1"
assert_output_contains "缺少 model 欄位" "$output" "TC-04 AC2 缺少 model：輸出含錯誤訊息"
rm -rf "$tmpdir"

# ── TC-05: AC3 FAIL — model 值不在白名單中 ──────────────────────────────
tmpdir=$(setup_test_env)
cat > "$tmpdir/agents/bad-model.md" <<'EOF'
---
name: bad-model
description: A test agent
model: gpt-4
---

# Bad Model
EOF
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_agents_output.txt)

assert_exit_code 1 "$exit_code" "TC-05 AC3 無效 model：exit 1"
assert_output_contains "不在白名單" "$output" "TC-05 AC3 無效 model：輸出含錯誤訊息"
rm -rf "$tmpdir"

# ── TC-06: AC3 PASS — model 值有效（sonnet） ─────────────────────────────
tmpdir=$(setup_test_env)
write_valid_agent "$tmpdir" "sonnet-agent"
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_agents_output.txt)

assert_exit_code 0 "$exit_code" "TC-06 AC3 sonnet model：exit 0"
assert_output_contains "sonnet" "$output" "TC-06 AC3 sonnet model：輸出驗證通過"
rm -rf "$tmpdir"

# ── TC-07: AC3 PASS — model 值有效（haiku） ──────────────────────────────
tmpdir=$(setup_test_env)
cat > "$tmpdir/agents/haiku-agent.md" <<'EOF'
---
name: haiku-agent
description: A haiku-based agent
model: haiku
---

# Haiku Agent
EOF
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_agents_output.txt)

assert_exit_code 0 "$exit_code" "TC-07 AC3 haiku model：exit 0"
assert_output_contains "haiku" "$output" "TC-07 AC3 haiku model：輸出驗證通過"
rm -rf "$tmpdir"

# ── TC-08: AC3 PASS — model 值有效（opus） ───────────────────────────────
tmpdir=$(setup_test_env)
cat > "$tmpdir/agents/opus-agent.md" <<'EOF'
---
name: opus-agent
description: An opus-based agent
model: opus
---

# Opus Agent
EOF
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_agents_output.txt)

assert_exit_code 0 "$exit_code" "TC-08 AC3 opus model：exit 0"
assert_output_contains "opus" "$output" "TC-08 AC3 opus model：輸出驗證通過"
rm -rf "$tmpdir"

# ── TC-09: AC4 FAIL — description 為空 ─────────────────────────────────
tmpdir=$(setup_test_env)
write_invalid_agent_empty_desc "$tmpdir" "empty-desc"
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_agents_output.txt)

assert_exit_code 1 "$exit_code" "TC-09 AC4 空 description：exit 1"
assert_output_contains "為空字串或僅含空白字元" "$output" "TC-09 AC4 空 description：輸出含錯誤訊息"
rm -rf "$tmpdir"

# ── TC-10: AC4 PASS — description 非空 ───────────────────────────────────
tmpdir=$(setup_test_env)
write_valid_agent "$tmpdir" "valid-agent"
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_agents_output.txt)

assert_exit_code 0 "$exit_code" "TC-10 AC4 非空 description：exit 0"
assert_output_contains "description 欄位非空" "$output" "TC-10 AC4 非空 description：輸出驗證通過"
rm -rf "$tmpdir"

# ── NFR1: 執行時間 < 5 秒 ──────────────────────────────────────────────────
tmpdir=$(setup_test_env)
write_valid_agent "$tmpdir" "perf-test"
start_time=$(date +%s)
cd "$tmpdir"
bash "$VALIDATE_SCRIPT" > /tmp/validate_agents_output.txt 2>&1 || true
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
