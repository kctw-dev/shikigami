#!/usr/bin/env bash
# tests/test-validate-skill-length.sh
# Issue #555 — 驗證 validate-skill-length.sh 腳本行為
#
# AC1: 腳本能偵測超出上限的 Skill 並輸出 WARNING
# AC2: 未超出上限的 Skill 不輸出 WARNING
# AC3: 整合至 for f in scripts/validate-*.sh glob pattern（檔名符合）
# AC4: 閾值以變數定義於腳本頂部，並以註解標注來源為 SDD-000 §2.1
# AC5: WARNING 時 exit 0
# AC6: 大型 Skill 清單以陣列變數定義

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
  local text="$1"
  local pattern="$2"
  local label="$3"
  if echo "$text" | grep -qE "$pattern"; then
    fail "$label (pattern='${pattern}' unexpectedly found)"
  else
    pass "$label"
  fi
}

# ---------------------------------------------------------------------------
# 設定路徑
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_SCRIPT="${REPO_ROOT}/scripts/validate-skill-length.sh"

echo "=== #555 validate-skill-length.sh 驗證測試 ==="
echo "REPO_ROOT: $REPO_ROOT"
echo "TARGET_SCRIPT: $TARGET_SCRIPT"
echo ""

# ---------------------------------------------------------------------------
# 前置條件：腳本存在
# ---------------------------------------------------------------------------
if [[ ! -f "$TARGET_SCRIPT" ]]; then
  fail "前置：scripts/validate-skill-length.sh 存在"
  echo ""
  echo "=== 測試結果 ==="
  echo "PASS: $PASS_COUNT"
  echo "FAIL: $FAIL_COUNT"
  echo "總結：前置條件失敗，無法執行後續測試"
  exit 1
fi

pass "前置：scripts/validate-skill-length.sh 存在"

# ---------------------------------------------------------------------------
# AC3：檔名符合 validate-*.sh glob pattern
# ---------------------------------------------------------------------------
echo ""
echo "--- AC3：檔名符合 validate-*.sh glob pattern ---"

SCRIPT_BASENAME="$(basename "$TARGET_SCRIPT")"
if [[ "$SCRIPT_BASENAME" == validate-*.sh ]]; then
  pass "AC3: 檔名 '$SCRIPT_BASENAME' 符合 validate-*.sh pattern"
else
  fail "AC3: 檔名 '$SCRIPT_BASENAME' 不符合 validate-*.sh pattern"
fi

# ---------------------------------------------------------------------------
# AC4：腳本頂部含閾值變數定義，並有 SDD-000 §2.1 來源註解
# ---------------------------------------------------------------------------
echo ""
echo "--- AC4：閾值變數定義與 SDD-000 §2.1 來源註解 ---"

assert_contains "$TARGET_SCRIPT" \
  'DEFAULT_MAX_LINES=350' \
  "AC4a: 含 DEFAULT_MAX_LINES=350 定義"

assert_contains "$TARGET_SCRIPT" \
  'LARGE_SKILL_MAX_LINES=400' \
  "AC4b: 含 LARGE_SKILL_MAX_LINES=400 定義"

assert_contains "$TARGET_SCRIPT" \
  'SDD-000.*§2\.1|SDD-000.*§2.1' \
  "AC4c: 含 SDD-000 §2.1 來源註解"

# ---------------------------------------------------------------------------
# AC6：大型 Skill 清單以陣列變數定義
# ---------------------------------------------------------------------------
echo ""
echo "--- AC6：大型 Skill 清單以陣列定義 ---"

assert_contains "$TARGET_SCRIPT" \
  'LARGE_SKILLS=\(' \
  "AC6a: 含 LARGE_SKILLS 陣列定義"

assert_contains "$TARGET_SCRIPT" \
  '"cruise"' \
  "AC6b: LARGE_SKILLS 陣列含 cruise"

assert_contains "$TARGET_SCRIPT" \
  '"sprint-execution"' \
  "AC6c: LARGE_SKILLS 陣列含 sprint-execution"

# ---------------------------------------------------------------------------
# AC1 + AC2 + AC5：實際執行腳本，驗證 WARNING 行為與 exit code
# ---------------------------------------------------------------------------
echo ""
echo "--- AC1/AC2/AC5：建立暫存 Skill 目錄測試 WARNING 行為 ---"

TMP_DIR="$(mktemp -d)"
TMP_SKILLS_DIR="${TMP_DIR}/skills"
mkdir -p "${TMP_SKILLS_DIR}/normal-skill"
mkdir -p "${TMP_SKILLS_DIR}/large-skill-test"
mkdir -p "${TMP_SKILLS_DIR}/ok-skill"

# 產生超過 350 行的 normal skill（模擬 FAIL 情況）
python3 -c "print('\n'.join(['# line ' + str(i) for i in range(360)]))" \
  > "${TMP_SKILLS_DIR}/normal-skill/SKILL.md"

# 產生恰好 350 行的 normal skill（邊界，不應觸發 WARNING）
python3 -c "print('\n'.join(['# line ' + str(i) for i in range(350)]))" \
  > "${TMP_SKILLS_DIR}/ok-skill/SKILL.md"

# 產生超過 400 行的 large skill（需在 LARGE_SKILLS 清單中）
# 使用 sprint-execution 作為大型 Skill 名稱測試
mkdir -p "${TMP_SKILLS_DIR}/sprint-execution"
python3 -c "print('\n'.join(['# line ' + str(i) for i in range(410)]))" \
  > "${TMP_SKILLS_DIR}/sprint-execution/SKILL.md"

# 執行腳本，使用暫存目錄覆蓋 SKILLS_DIR
OUTPUT=$(SKILLS_DIR="${TMP_SKILLS_DIR}" bash "$TARGET_SCRIPT" 2>&1)
EXIT_CODE=$?

# AC5：WARNING 時 exit 0
if [[ $EXIT_CODE -eq 0 ]]; then
  pass "AC5: WARNING 情況下 exit code = 0"
else
  fail "AC5: 期望 exit 0，實際 exit $EXIT_CODE"
fi

# AC1：超過上限的 normal-skill 應有 WARNING
if echo "$OUTPUT" | grep -qE '\[WARN\].*normal-skill'; then
  pass "AC1a: normal-skill 超過 350 行時輸出 [WARN]"
else
  fail "AC1a: normal-skill 超過 350 行時應輸出 [WARN]，實際輸出: $OUTPUT"
fi

# AC1：超過 400 行的 sprint-execution（大型 Skill）應有 WARNING
if echo "$OUTPUT" | grep -qE '\[WARN\].*sprint-execution'; then
  pass "AC1b: sprint-execution 超過 400 行時輸出 [WARN]"
else
  fail "AC1b: sprint-execution 超過 400 行時應輸出 [WARN]，實際輸出: $OUTPUT"
fi

# AC2：ok-skill（350 行，剛好等於上限）不應有 WARNING
assert_not_contains "$OUTPUT" \
  '\[WARN\].*ok-skill' \
  "AC2: ok-skill（350 行）不輸出 [WARN]"

# AC2b：大型 Skill sprint-execution 在 400 行以內（恰好 400 行）不應觸發 WARNING
# 重建 sprint-execution 目錄為剛好 400 行（不超過上限）
rm -f "${TMP_SKILLS_DIR}/sprint-execution/SKILL.md"
python3 -c "print('\n'.join(['# line ' + str(i) for i in range(400)]))" \
  > "${TMP_SKILLS_DIR}/sprint-execution/SKILL.md"
OUTPUT2=$(SKILLS_DIR="${TMP_SKILLS_DIR}" bash "$TARGET_SCRIPT" 2>&1)

assert_not_contains "$OUTPUT2" \
  '\[WARN\].*sprint-execution' \
  "AC2b: sprint-execution（400 行，剛好等於大型上限）不輸出 [WARN]"

# 清理暫存目錄
rm -rf "$TMP_DIR"

# ---------------------------------------------------------------------------
# 結果摘要
# ---------------------------------------------------------------------------
echo ""
echo "=== 測試結果 ==="
echo "PASS: $PASS_COUNT"
echo "FAIL: $FAIL_COUNT"

if [[ $FAIL_COUNT -eq 0 ]]; then
  echo "總結：validate-skill-length.sh 驗證全部通過（#555 AC 滿足）"
  exit 0
else
  echo "總結：發現 $FAIL_COUNT 個 FAIL，請修正後重試"
  exit 1
fi
