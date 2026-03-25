#!/usr/bin/env bash
# tests/test-validate-skills.sh
# Story #838：Skill 定義驗證 — 測試套件
#
# 驗證 scripts/validate-skills.sh 的行為符合 AC1-AC5
# - AC1：掃描 skills/ 下所有子目錄
# - AC2：驗證每個 Skill 目錄下有 SKILL.md 且含 name、description 欄位
# - AC3：驗證 name 值與目錄名稱完全一致（大小寫敏感）
# - AC4：空目錄或缺少 SKILL.md 報錯
# - AC5：exit 0 通過，exit 1 失敗

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATE_SCRIPT="${REPO_ROOT}/scripts/validate-skills.sh"
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
  mkdir -p "$tmpdir/skills"
  echo "$tmpdir"
}

# Write a valid SKILL.md file
write_valid_skill() {
  local dir="$1"
  local name="$2"
  cat > "$dir/skills/${name}/SKILL.md" <<EOF
---
name: $name
description: A test skill for $name
---

# $name

This is a test skill.
EOF
}

# Run validate script and return exit code
run_validate_test() {
  local tmpdir="$1"
  local exit_code
  cd "$tmpdir"
  if bash "$VALIDATE_SCRIPT" > /tmp/validate_skills_output.txt 2>&1; then
    exit_code=0
  else
    exit_code=$?
  fi
  cd "$REPO_ROOT"
  echo "$exit_code"
}

echo "=============================="
echo " Story #838 - test-validate-skills.sh"
echo "=============================="
echo ""

# ── Pre-check: validate-skills.sh 必須存在 ────────────────────────────────
if [[ ! -f "$VALIDATE_SCRIPT" ]]; then
  fail "scripts/validate-skills.sh 不存在"
  echo "FAIL: $FAIL / PASS: $PASS"
  exit 1
fi
pass "scripts/validate-skills.sh 存在"

# ── TC-01: AC1 通過 — 掃描並列出所有 Skill 目錄 ───────────────────────────
tmpdir=$(setup_test_env)
mkdir -p "$tmpdir/skills/skill-one"
mkdir -p "$tmpdir/skills/skill-two"
write_valid_skill "$tmpdir" "skill-one"
write_valid_skill "$tmpdir" "skill-two"
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_skills_output.txt)

assert_exit_code 0 "$exit_code" "TC-01 AC1：有效 Skill 掃描 exit 0"
assert_output_contains "skill-one" "$output" "TC-01 AC1：輸出列出 skill-one 目錄"
assert_output_contains "skill-two" "$output" "TC-01 AC1：輸出列出 skill-two 目錄"
assert_output_contains "2 個 Skill" "$output" "TC-01 AC1：輸出顯示正確數量"
rm -rf "$tmpdir"

# ── TC-02: AC2 FAIL — 缺少 SKILL.md ──────────────────────────────────────
tmpdir=$(setup_test_env)
mkdir -p "$tmpdir/skills/empty-skill"
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_skills_output.txt)

assert_exit_code 1 "$exit_code" "TC-02 AC4 缺少 SKILL.md：exit 1"
assert_output_contains "找不到 SKILL.md" "$output" "TC-02 AC4 缺少 SKILL.md：輸出含錯誤訊息"
rm -rf "$tmpdir"

# ── TC-03: AC2 FAIL — 缺少 name 欄位 ──────────────────────────────────────
tmpdir=$(setup_test_env)
mkdir -p "$tmpdir/skills/no-name-skill"
cat > "$tmpdir/skills/no-name-skill/SKILL.md" <<'EOF'
---
description: A skill without name
---

# No Name Skill
EOF
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_skills_output.txt)

assert_exit_code 1 "$exit_code" "TC-03 AC2 缺少 name：exit 1"
assert_output_contains "缺少 name 欄位" "$output" "TC-03 AC2 缺少 name：輸出含錯誤訊息"
rm -rf "$tmpdir"

# ── TC-04: AC2 FAIL — 缺少 description 欄位 ───────────────────────────────
tmpdir=$(setup_test_env)
mkdir -p "$tmpdir/skills/no-desc-skill"
cat > "$tmpdir/skills/no-desc-skill/SKILL.md" <<'EOF'
---
name: no-desc-skill
---

# No Description Skill
EOF
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_skills_output.txt)

assert_exit_code 1 "$exit_code" "TC-04 AC2 缺少 description：exit 1"
assert_output_contains "缺少 description 欄位" "$output" "TC-04 AC2 缺少 description：輸出含錯誤訊息"
rm -rf "$tmpdir"

# ── TC-05: AC3 FAIL — name 與目錄名稱不一致 ───────────────────────────────
tmpdir=$(setup_test_env)
mkdir -p "$tmpdir/skills/my-skill"
cat > "$tmpdir/skills/my-skill/SKILL.md" <<'EOF'
---
name: different-name
description: A skill with mismatched name
---

# Different Name
EOF
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_skills_output.txt)

assert_exit_code 1 "$exit_code" "TC-05 AC3 name 不一致：exit 1"
assert_output_contains "不一致" "$output" "TC-05 AC3 name 不一致：輸出含錯誤訊息"
rm -rf "$tmpdir"

# ── TC-06: AC3 PASS — name 與目錄名稱一致 ──────────────────────────────────
tmpdir=$(setup_test_env)
mkdir -p "$tmpdir/skills/matching-skill"
cat > "$tmpdir/skills/matching-skill/SKILL.md" <<'EOF'
---
name: matching-skill
description: A skill with matching name
---

# Matching Skill
EOF
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_skills_output.txt)

assert_exit_code 0 "$exit_code" "TC-06 AC3 name 一致：exit 0"
assert_output_contains "name 值與目錄名稱一致" "$output" "TC-06 AC3 name 一致：輸出驗證通過"
rm -rf "$tmpdir"

# ── TC-07: AC3 FAIL — 大小寫不一致（敏感檢查） ──────────────────────────────
tmpdir=$(setup_test_env)
mkdir -p "$tmpdir/skills/CaseSensitive"
cat > "$tmpdir/skills/CaseSensitive/SKILL.md" <<'EOF'
---
name: casesensitive
description: A skill with case mismatch
---

# Case Mismatch
EOF
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_skills_output.txt)

assert_exit_code 1 "$exit_code" "TC-07 AC3 大小寫不一致：exit 1"
assert_output_contains "不一致" "$output" "TC-07 AC3 大小寫不一致：輸出含錯誤訊息"
rm -rf "$tmpdir"

# ── TC-08: 多個 Skill 有效 ──────────────────────────────────────────────────
tmpdir=$(setup_test_env)
for i in {1..3}; do
  mkdir -p "$tmpdir/skills/skill-$i"
  write_valid_skill "$tmpdir" "skill-$i"
done
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_skills_output.txt)

assert_exit_code 0 "$exit_code" "TC-08 多個有效 Skill：exit 0"
assert_output_contains "3 個 Skill" "$output" "TC-08 多個有效 Skill：輸出正確數量"
rm -rf "$tmpdir"

# ── TC-09: 混合有效和無效 Skill ─────────────────────────────────────────────
tmpdir=$(setup_test_env)
mkdir -p "$tmpdir/skills/valid-skill"
write_valid_skill "$tmpdir" "valid-skill"
mkdir -p "$tmpdir/skills/invalid-skill"
cat > "$tmpdir/skills/invalid-skill/SKILL.md" <<'EOF'
---
name: wrong-name
description: Invalid skill
---

# Invalid
EOF
exit_code=$(run_validate_test "$tmpdir")
output=$(cat /tmp/validate_skills_output.txt)

assert_exit_code 1 "$exit_code" "TC-09 混合有效/無效：exit 1（因為有無效 Skill）"
assert_output_contains "valid-skill" "$output" "TC-09 混合有效/無效：輸出包含有效 Skill"
assert_output_contains "不一致" "$output" "TC-09 混合有效/無效：輸出包含錯誤訊息"
rm -rf "$tmpdir"

# ── NFR1: 執行時間 < 5 秒 ──────────────────────────────────────────────────
tmpdir=$(setup_test_env)
for i in {1..5}; do
  mkdir -p "$tmpdir/skills/perf-skill-$i"
  write_valid_skill "$tmpdir" "perf-skill-$i"
done
start_time=$(date +%s)
cd "$tmpdir"
bash "$VALIDATE_SCRIPT" > /tmp/validate_skills_output.txt 2>&1 || true
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
