#!/usr/bin/env bash
# tests/test-us305-minor-to-patch-downgrade.sh
# US-305：版號策略 — 當日 minor 降級 patch
#
# AC 覆蓋：
#   AC1：當日已有 minor bump 時，後續 bump 降級為 patch
#   AC2：跨日第一次 bump 維持 minor（不受影響）
#   AC3：git tag --sort=-creatordate 查詢可正常運作（無 tag 時不報錯，降級為 minor）

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

assert_equals() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  if [ "$actual" = "$expected" ]; then
    pass "$label"
  else
    fail "$label (期望「$expected」，實際「$actual」)"
  fi
}

# ---------------------------------------------------------------------------
# 路徑常數
# ---------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_FILE="$REPO_ROOT/skills/deployment-readiness/SKILL.md"

# ---------------------------------------------------------------------------
# 核心判斷邏輯（從 SKILL.md 抽出，在 subshell 中執行以便測試）
# ---------------------------------------------------------------------------

# 模擬 bump_type 決策函式
# 參數：
#   $1 = TAG_DATE（模擬 git log 取得的日期，或空字串表示無 tag）
#   $2 = TODAY（模擬今天的日期）
# 輸出：BUMP_TYPE = "patch" | "minor"
decide_bump_type() {
  local TAG_DATE="$1"
  local TODAY="$2"

  if [[ "$TAG_DATE" == "$TODAY" ]]; then
    echo "patch"
  else
    echo "minor"
  fi
}

# ---------------------------------------------------------------------------
# TC-01：AC1 — 當日已有 minor bump，後續降級為 patch
# ---------------------------------------------------------------------------
test_ac1_same_day_downgrades_to_patch() {
  local TODAY="2026-03-20"
  local TAG_DATE="2026-03-20"   # 最新 tag 日期 = 今天

  local result
  result=$(decide_bump_type "$TAG_DATE" "$TODAY")

  assert_equals "patch" "$result" \
    "TC-01 AC1：當日已有 tag → 降級為 patch bump"
}

# ---------------------------------------------------------------------------
# TC-02：AC2 — 跨日（昨天的 tag），維持 minor bump
# ---------------------------------------------------------------------------
test_ac2_previous_day_keeps_minor() {
  local TODAY="2026-03-20"
  local TAG_DATE="2026-03-19"   # 最新 tag 日期 = 昨天

  local result
  result=$(decide_bump_type "$TAG_DATE" "$TODAY")

  assert_equals "minor" "$result" \
    "TC-02 AC2：跨日（昨天的 tag）→ 維持 minor bump"
}

# ---------------------------------------------------------------------------
# TC-03：AC2 — 更早的 tag，維持 minor bump
# ---------------------------------------------------------------------------
test_ac2_older_tag_keeps_minor() {
  local TODAY="2026-03-20"
  local TAG_DATE="2026-01-01"   # 更早的日期

  local result
  result=$(decide_bump_type "$TAG_DATE" "$TODAY")

  assert_equals "minor" "$result" \
    "TC-03 AC2：更早的 tag 日期 → 維持 minor bump"
}

# ---------------------------------------------------------------------------
# TC-04：AC3 — 無 tag 時（TAG_DATE 為空），不報錯，降級為 minor
# ---------------------------------------------------------------------------
test_ac3_no_tag_defaults_to_minor() {
  local TODAY="2026-03-20"
  local TAG_DATE=""   # 無 tag

  local result
  result=$(decide_bump_type "$TAG_DATE" "$TODAY")

  assert_equals "minor" "$result" \
    "TC-04 AC3：無任何 tag → 預設 minor bump（不報錯）"
}

# ---------------------------------------------------------------------------
# TC-05：AC3 — git tag --sort=-creatordate 指令在本 repo 可正常執行
# ---------------------------------------------------------------------------
test_ac3_git_tag_sort_works() {
  local exit_code=0
  git -C "$REPO_ROOT" tag --sort=-creatordate > /dev/null 2>&1 || exit_code=$?

  if [ "$exit_code" -eq 0 ]; then
    pass "TC-05 AC3：git tag --sort=-creatordate 執行成功（exit 0）"
  else
    fail "TC-05 AC3：git tag --sort=-creatordate 執行失敗（exit $exit_code）"
  fi
}

# ---------------------------------------------------------------------------
# TC-06：AC3 — 無 tag 時 head -1 輸出為空，git log 對空字串不崩潰
# ---------------------------------------------------------------------------
test_ac3_empty_tag_git_log_safe() {
  local tmpdir
  tmpdir=$(mktemp -d)

  # 建立全新無 tag 的 repo
  git -C "$tmpdir" init --quiet
  git -C "$tmpdir" config user.email "test@test.com"
  git -C "$tmpdir" config user.name "Test"

  # 模擬 SKILL.md 中的判斷邏輯
  local LATEST_TAG
  LATEST_TAG=$(git -C "$tmpdir" tag --sort=-creatordate 2>/dev/null | head -1)

  local TAG_DATE=""
  if [[ -n "$LATEST_TAG" ]]; then
    TAG_DATE=$(git -C "$tmpdir" log -1 --format='%cd' --date=short "$LATEST_TAG" 2>/dev/null)
  fi

  local TODAY
  TODAY=$(date '+%Y-%m-%d')

  local BUMP_TYPE
  if [[ "$TAG_DATE" == "$TODAY" ]]; then
    BUMP_TYPE="patch"
  else
    BUMP_TYPE="minor"
  fi

  if [[ "$BUMP_TYPE" == "minor" ]]; then
    pass "TC-06 AC3：無 tag 的全新 repo → BUMP_TYPE=minor（不報錯）"
  else
    fail "TC-06 AC3：無 tag 的全新 repo 應為 minor，實際為 $BUMP_TYPE"
  fi

  rm -rf "$tmpdir"
}

# ---------------------------------------------------------------------------
# TC-07：AC1 — 完整模擬：有今日 tag 的 repo，驗證降級邏輯
# ---------------------------------------------------------------------------
test_ac1_full_simulation_with_today_tag() {
  local tmpdir
  tmpdir=$(mktemp -d)

  git -C "$tmpdir" init --quiet
  git -C "$tmpdir" config user.email "test@test.com"
  git -C "$tmpdir" config user.name "Test"

  # 建立一個 commit 並打今日 tag
  touch "$tmpdir/dummy.txt"
  git -C "$tmpdir" add dummy.txt
  git -C "$tmpdir" commit -m "init" --quiet

  local TAG="v0.74.0"
  git -C "$tmpdir" tag "$TAG"

  # 執行判斷邏輯
  local LATEST_TAG
  LATEST_TAG=$(git -C "$tmpdir" tag --sort=-creatordate | head -1)

  local TAG_DATE=""
  if [[ -n "$LATEST_TAG" ]]; then
    TAG_DATE=$(git -C "$tmpdir" log -1 --format='%cd' --date=short "$LATEST_TAG" 2>/dev/null)
  fi

  local TODAY
  TODAY=$(date '+%Y-%m-%d')

  local BUMP_TYPE
  if [[ "$TAG_DATE" == "$TODAY" ]]; then
    BUMP_TYPE="patch"
  else
    BUMP_TYPE="minor"
  fi

  # 因為 tag 是今天打的，TAG_DATE 應等於 TODAY
  if [[ "$BUMP_TYPE" == "patch" ]]; then
    pass "TC-07 AC1：今日 tag 的 repo → BUMP_TYPE=patch（降級成功）"
  else
    fail "TC-07 AC1：今日 tag 的 repo 應降級為 patch，實際為 $BUMP_TYPE（TAG_DATE=$TAG_DATE, TODAY=$TODAY）"
  fi

  rm -rf "$tmpdir"
}

# ---------------------------------------------------------------------------
# TC-08：SKILL.md 包含當日重複 Minor 降級子節
# ---------------------------------------------------------------------------
test_skill_md_contains_downgrade_section() {
  if grep -q "當日重複 Minor 降級為 Patch" "$SKILL_FILE" 2>/dev/null; then
    pass "TC-08：SKILL.md 包含「當日重複 Minor 降級為 Patch」子節"
  else
    fail "TC-08：SKILL.md 缺少「當日重複 Minor 降級為 Patch」子節"
  fi
}

# ---------------------------------------------------------------------------
# TC-09：SKILL.md 包含判斷邏輯的 bash 程式碼
# ---------------------------------------------------------------------------
test_skill_md_contains_bash_logic() {
  if grep -q "git tag --sort=-creatordate" "$SKILL_FILE" 2>/dev/null; then
    pass "TC-09：SKILL.md 包含 git tag --sort=-creatordate 查詢指令"
  else
    fail "TC-09：SKILL.md 缺少 git tag --sort=-creatordate 查詢指令"
  fi
}

# ---------------------------------------------------------------------------
# TC-10：SKILL.md 包含 HARD-GATE 保護無 tag 情況
# ---------------------------------------------------------------------------
test_skill_md_has_hard_gate_for_no_tag() {
  if grep -qA5 "當日重複 Minor 降級" "$SKILL_FILE" 2>/dev/null | grep -q "HARD-GATE"; then
    pass "TC-10：SKILL.md 降級子節含有 HARD-GATE"
  else
    # 更寬鬆的搜尋：只要 HARD-GATE 和 無 tag 兩個關鍵字都存在於降級區段附近
    local section_content
    section_content=$(awk '/當日重複 Minor 降級為 Patch/,/#### Major Bump/' "$SKILL_FILE" 2>/dev/null)
    if echo "$section_content" | grep -q "HARD-GATE" && \
       echo "$section_content" | grep -q "無 tag"; then
      pass "TC-10：SKILL.md 降級子節含有 HARD-GATE 與無 tag 保護"
    else
      fail "TC-10：SKILL.md 降級子節缺少 HARD-GATE 或無 tag 保護說明"
    fi
  fi
}

# ---------------------------------------------------------------------------
# 執行所有測試
# ---------------------------------------------------------------------------
echo "========================================"
echo " US-305 版號策略 — 當日 minor 降級 patch"
echo "========================================"
echo ""

test_ac1_same_day_downgrades_to_patch
test_ac2_previous_day_keeps_minor
test_ac2_older_tag_keeps_minor
test_ac3_no_tag_defaults_to_minor
test_ac3_git_tag_sort_works
test_ac3_empty_tag_git_log_safe
test_ac1_full_simulation_with_today_tag
test_skill_md_contains_downgrade_section
test_skill_md_contains_bash_logic
test_skill_md_has_hard_gate_for_no_tag

echo ""
echo "========================================"
echo " 結果：PASS=$PASS_COUNT  FAIL=$FAIL_COUNT"
echo "========================================"

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
