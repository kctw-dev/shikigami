#!/usr/bin/env bash
# tests/test-validate-xrefs.sh
# Story #840：validate-xrefs.sh 自動化測試
#
# 驗證 scripts/validate-xrefs.sh 的行為符合 AC1-AC4：
# - AC1：掃描所有 .md 的 shikigami:[a-z-]+ 引用
# - AC2：測試涵蓋有效引用（PASS）和無效引用（FAIL）場景
# - AC3：使用 fixture 目錄模擬 skills/agents 結構
# - AC4：測試 PASS 且 exit 0
# NFR1：測試執行時間 < 3 秒（透過 fixture 隔離避免全 repo 掃描）

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATE_SCRIPT="${REPO_ROOT}/scripts/validate-xrefs.sh"

PASS=0
FAIL=0

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

assert_output_not_contains() {
  local needle="$1"
  local haystack="$2"
  local label="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    fail "$label (輸出中不應出現「$needle」)"
  else
    pass "$label"
  fi
}

# ---------------------------------------------------------------------------
# 前置檢查：validate-xrefs.sh 必須存在
# ---------------------------------------------------------------------------
if [[ ! -f "$VALIDATE_SCRIPT" ]]; then
  echo "[FATAL] scripts/validate-xrefs.sh 不存在，無法執行測試"
  exit 1
fi

# ---------------------------------------------------------------------------
# Fixture 目錄建立（AC3）
# 建立最小 repo 結構，讓腳本在 fixture 內執行以控制測試時間（NFR1）
# ---------------------------------------------------------------------------
FIXTURE_DIR="$(mktemp -d)"
trap 'rm -rf "$FIXTURE_DIR"' EXIT

# 建立 fixture 目錄結構（模擬真實 repo）
mkdir -p "$FIXTURE_DIR/scripts/lib"
mkdir -p "$FIXTURE_DIR/skills/sprint-planning"
mkdir -p "$FIXTURE_DIR/skills/sprint-execution"
mkdir -p "$FIXTURE_DIR/agents"
mkdir -p "$FIXTURE_DIR/commands"

# 複製腳本與 lib（讓腳本在 fixture 內可執行）
cp "$VALIDATE_SCRIPT" "$FIXTURE_DIR/scripts/validate-xrefs.sh"
cp "$REPO_ROOT/scripts/lib/validate-helpers.sh" "$FIXTURE_DIR/scripts/lib/validate-helpers.sh"

# 建立 skill 的 references 目錄結構（用於 skill-to-skill 交叉引用驗證 — Story #949）
mkdir -p "$FIXTURE_DIR/skills/sprint-planning/references"
mkdir -p "$FIXTURE_DIR/skills/sprint-execution/references"
mkdir -p "$FIXTURE_DIR/skills/systematic-debugging/references"

# 建立 SKILL.md 供有效引用使用（fixture 內）
touch "$FIXTURE_DIR/skills/sprint-planning/SKILL.md"
touch "$FIXTURE_DIR/skills/sprint-execution/SKILL.md"
touch "$FIXTURE_DIR/skills/systematic-debugging/SKILL.md"

# ---------------------------------------------------------------------------
# TEST 1：腳本在 skills/ 目錄存在時能正常執行（AC1 基礎可執行性）
# 在 fixture clean env 中執行（僅含有效引用），驗證 exit 0
# ---------------------------------------------------------------------------
cat > "$FIXTURE_DIR/valid-doc.md" << 'EOF'
invoke shikigami:sprint-planning and shikigami:sprint-execution
EOF
OUTPUT=$(cd "$FIXTURE_DIR" && bash scripts/validate-xrefs.sh 2>&1)
EXIT_CODE_ACTUAL=$?
assert_exit_code 0 "$EXIT_CODE_ACTUAL" "TC1: fixture 環境中無 broken reference，exit 0"

# ---------------------------------------------------------------------------
# TEST 2：有效引用通過（AC2 PASS 場景）
# ---------------------------------------------------------------------------
assert_output_not_contains "broken reference 'shikigami:sprint-planning'" "$OUTPUT" "TC2: sprint-planning 引用為有效引用，不應出現 broken reference"
assert_output_not_contains "broken reference 'shikigami:sprint-execution'" "$OUTPUT" "TC2: sprint-execution 引用為有效引用，不應出現 broken reference"

# ---------------------------------------------------------------------------
# TEST 3：輸出摘要包含掃描統計（AC1 輸出格式）
# ---------------------------------------------------------------------------
assert_output_contains "掃描" "$OUTPUT" "TC3: 輸出包含掃描統計摘要"

# ---------------------------------------------------------------------------
# TEST 4：exit code 語意正確（AC4）
# exit 0 = 無 broken reference（fixture clean）
# ---------------------------------------------------------------------------
assert_exit_code 0 "$EXIT_CODE_ACTUAL" "TC4: fixture clean 環境 exit 0（無 broken reference）"

# ---------------------------------------------------------------------------
# TEST 5：broken reference 偵測（AC2 FAIL 場景）
# 在 fixture 中加入引用不存在 skill 的 .md
# ---------------------------------------------------------------------------
cat > "$FIXTURE_DIR/broken-doc.md" << 'EOF'
shikigami:nonexistent-skill-zzzzzz
EOF
BROKEN_OUTPUT=$(cd "$FIXTURE_DIR" && bash scripts/validate-xrefs.sh 2>&1)
BROKEN_EXIT=$?

assert_output_contains "broken reference 'shikigami:nonexistent-skill-zzzzzz'" "$BROKEN_OUTPUT" "TC5: broken reference 被正確偵測並輸出錯誤訊息"
assert_exit_code 1 "$BROKEN_EXIT" "TC5: broken reference 存在時 exit 1"

# 清除 broken-doc 讓後續測試乾淨
rm -f "$FIXTURE_DIR/broken-doc.md"

# ---------------------------------------------------------------------------
# TEST 7：skill-to-skill 交叉引用驗證（Story #949 AC2）
# 在 references/*.md 內的 shikigami:xxx 引用必須指向存在的 skill
# ---------------------------------------------------------------------------
cat > "$FIXTURE_DIR/skills/sprint-planning/references/process.md" << 'EOF'
This process invokes shikigami:sprint-execution for next steps.
When debugging is needed, use shikigami:systematic-debugging.
EOF

SKILL_XREF_OUTPUT=$(cd "$FIXTURE_DIR" && bash scripts/validate-xrefs.sh 2>&1)
SKILL_XREF_EXIT=$?

assert_output_not_contains "broken reference" "$SKILL_XREF_OUTPUT" "TC7: skill references/process.md 中的有效 skill 引用不應報錯"
assert_exit_code 0 "$SKILL_XREF_EXIT" "TC7: skill references 中的有效引用，exit 0"

# ---------------------------------------------------------------------------
# TEST 8：skill references 中的無效 skill 引用（Story #949 AC2 FAIL 場景）
# ---------------------------------------------------------------------------
cat > "$FIXTURE_DIR/skills/sprint-planning/references/invalid-ref.md" << 'EOF'
This references a nonexistent skill: shikigami:nonexistent-debugger
EOF

INVALID_SKILL_XREF=$(cd "$FIXTURE_DIR" && bash scripts/validate-xrefs.sh 2>&1)
INVALID_SKILL_EXIT=$?

assert_output_contains "broken reference 'shikigami:nonexistent-debugger'" "$INVALID_SKILL_XREF" "TC8: skill references 中的無效引用應被偵測"
assert_exit_code 1 "$INVALID_SKILL_EXIT" "TC8: skill references 中有無效引用時 exit 1"

# 清除無效引用檔案
rm -f "$FIXTURE_DIR/skills/sprint-planning/references/invalid-ref.md"

# ---------------------------------------------------------------------------
# TEST 6：placeholder 引用 shikigami:xxx 被跳過（邊界條件）
# ---------------------------------------------------------------------------
cat > "$FIXTURE_DIR/placeholder-doc.md" << 'EOF'
invoke shikigami:xxx as placeholder
EOF
PLACEHOLDER_OUTPUT=$(cd "$FIXTURE_DIR" && bash scripts/validate-xrefs.sh 2>&1)
PLACEHOLDER_EXIT=$?
rm -f "$FIXTURE_DIR/placeholder-doc.md"

assert_output_not_contains "broken reference 'shikigami:xxx'" "$PLACEHOLDER_OUTPUT" "TC6: placeholder shikigami:xxx 被正確跳過，不報錯"
assert_exit_code 0 "$PLACEHOLDER_EXIT" "TC6: placeholder 不觸發 broken reference，exit 0"

# ---------------------------------------------------------------------------
# 測試結果摘要
# ---------------------------------------------------------------------------
echo ""
echo "=============================="
echo "tests/test-validate-xrefs.sh"
echo "PASS: $PASS  FAIL: $FAIL"
echo "=============================="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
