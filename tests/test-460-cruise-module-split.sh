#!/usr/bin/env bash
# tests/test-460-cruise-module-split.sh
# #460 Cruise SKILL.md 模組拆分驗證
# AC1: 拆分為 ≥3 個子模組
# AC2: 主文件保留概覽和引用
# AC3: 拆分後所有現有測試仍通過
# AC4: 引用路徑正確，subagent 可正確讀取子模組

set -uo pipefail

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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_DIR="${REPO_ROOT}/skills/cruise"
SKILL_FILE="${SKILL_DIR}/SKILL.md"
PO_PATROL_FILE="${SKILL_DIR}/po-patrol.md"
SRE_FILE="${SKILL_DIR}/sre-inspection.md"
AUTO_SHOOT_FILE="${SKILL_DIR}/auto-shoot.md"

echo "=== #460 Cruise 模組拆分驗證 ==="
echo "SKILL_DIR: $SKILL_DIR"
echo ""

# ---------------------------------------------------------------------------
# AC1: 拆分為 ≥3 個子模組
# ---------------------------------------------------------------------------
echo "--- AC1: 子模組存在驗證 ---"

assert_file_exists "$SKILL_FILE" "AC1a: SKILL.md 主文件存在"
assert_file_exists "$PO_PATROL_FILE" "AC1b: po-patrol.md 子模組存在"
assert_file_exists "$SRE_FILE" "AC1c: sre-inspection.md 子模組存在"
assert_file_exists "$AUTO_SHOOT_FILE" "AC1d: auto-shoot.md 子模組存在"

# 計算子模組數量（不含 SKILL.md 本身）
MODULE_COUNT=$(ls "${SKILL_DIR}"/*.md 2>/dev/null | grep -v SKILL.md | wc -l | tr -d ' ')
if [[ "$MODULE_COUNT" -ge 3 ]]; then
  pass "AC1e: 子模組數量 ≥ 3（實際 ${MODULE_COUNT} 個）"
else
  fail "AC1e: 子模組數量不足（需 ≥ 3，實際 ${MODULE_COUNT} 個）"
fi

# ---------------------------------------------------------------------------
# AC2: 主文件保留概覽和引用
# ---------------------------------------------------------------------------
echo ""
echo "--- AC2: 主文件概覽與引用驗證 ---"

assert_contains "$SKILL_FILE" 'name: cruise' "AC2a: SKILL.md 保留 YAML frontmatter name=cruise"
assert_contains "$SKILL_FILE" 'description:' "AC2b: SKILL.md 保留 description 欄位"
assert_contains "$SKILL_FILE" 'requiredTools:' "AC2c: SKILL.md 保留 requiredTools 欄位"
assert_contains "$SKILL_FILE" '/cruise' "AC2d: SKILL.md 保留觸發語法"
assert_contains "$SKILL_FILE" '概覽|概述|overview' "AC2e: SKILL.md 保留概覽段落"
assert_contains "$SKILL_FILE" 'po-patrol.md' "AC2f: SKILL.md 引用 po-patrol.md"
assert_contains "$SKILL_FILE" 'sre-inspection.md' "AC2g: SKILL.md 引用 sre-inspection.md"
assert_contains "$SKILL_FILE" 'auto-shoot.md' "AC2h: SKILL.md 引用 auto-shoot.md"

# ---------------------------------------------------------------------------
# AC3: 子模組包含完整邏輯
# ---------------------------------------------------------------------------
echo ""
echo "--- AC3: 子模組完整邏輯驗證 ---"

# po-patrol.md 應包含 PO 巡邏核心邏輯
assert_contains "$PO_PATROL_FILE" 'gh issue list' "AC3a: po-patrol.md 含 issue 掃描指令"
assert_contains "$PO_PATROL_FILE" 'awaiting-reply' "AC3b: po-patrol.md 含 awaiting-reply 處置"
assert_contains "$PO_PATROL_FILE" 'sprint-candidate' "AC3c: po-patrol.md 含 sprint-candidate 處置"
assert_contains "$PO_PATROL_FILE" '"triage"' "AC3d: po-patrol.md 含 triage log 類型"
assert_contains "$PO_PATROL_FILE" 'stakeholder' "AC3e: po-patrol.md 含安全邊界（stakeholder）"

# sre-inspection.md 應包含 SRE 巡檢核心邏輯
assert_contains "$SRE_FILE" 'gh run list' "AC3f: sre-inspection.md 含 CI 狀態檢查"
assert_contains "$SRE_FILE" 'runner' "AC3g: sre-inspection.md 含 Runner 健康檢查"
assert_contains "$SRE_FILE" '/systematic-debugging' "AC3h: sre-inspection.md 含 debugging 指引"
assert_contains "$SRE_FILE" 'deploy-failure' "AC3i: sre-inspection.md 含 deploy failure 處置"
assert_contains "$SRE_FILE" 'runner-offline' "AC3j: sre-inspection.md 含 runner offline 處置"

# auto-shoot.md 應包含 auto-shoot 核心邏輯
assert_contains "$AUTO_SHOOT_FILE" 'SHOOT_FLAG' "AC3k: auto-shoot.md 含 SHOOT_FLAG 邏輯"
assert_contains "$AUTO_SHOOT_FILE" 'shikigami:shoot' "AC3l: auto-shoot.md 含 invoke shikigami:shoot"
assert_contains "$AUTO_SHOOT_FILE" 'sprint-candidate' "AC3m: auto-shoot.md 含失敗升級邏輯"

# ---------------------------------------------------------------------------
# AC4: 引用路徑正確
# ---------------------------------------------------------------------------
echo ""
echo "--- AC4: 引用路徑正確驗證 ---"

# 確認 SKILL.md 中的引用路徑為相對路徑（./）
assert_contains "$SKILL_FILE" '\./po-patrol\.md|\(./po-patrol\.md\)|po-patrol\.md' "AC4a: SKILL.md 引用 po-patrol.md 路徑"
assert_contains "$SKILL_FILE" '\./sre-inspection\.md|\(./sre-inspection\.md\)|sre-inspection\.md' "AC4b: SKILL.md 引用 sre-inspection.md 路徑"
assert_contains "$SKILL_FILE" '\./auto-shoot\.md|\(./auto-shoot\.md\)|auto-shoot\.md' "AC4c: SKILL.md 引用 auto-shoot.md 路徑"

# 確認引用的檔案實際存在（路徑可讀性）
for module in po-patrol.md sre-inspection.md auto-shoot.md; do
  if [[ -f "${SKILL_DIR}/${module}" ]]; then
    pass "AC4d: ${module} 路徑可讀取（subagent 可存取）"
  else
    fail "AC4d: ${module} 路徑無效（subagent 無法存取）"
  fi
done

# ---------------------------------------------------------------------------
# 子模組索引表存在
# ---------------------------------------------------------------------------
echo ""
echo "--- AC5: 主文件子模組索引 ---"

assert_contains "$SKILL_FILE" '子模組|索引|sub.*module|module.*index' "AC5a: SKILL.md 含子模組索引"

# ---------------------------------------------------------------------------
# 結果
# ---------------------------------------------------------------------------
echo ""
echo "=== 測試結果 ==="
echo "PASS: $PASS_COUNT"
echo "FAIL: $FAIL_COUNT"

if [[ $FAIL_COUNT -eq 0 ]]; then
  echo "總結：#460 Cruise 模組拆分驗證全部通過"
  exit 0
else
  echo "總結：發現 $FAIL_COUNT 個 FAIL，請修正後重試"
  exit 1
fi
