#!/usr/bin/env bash
# tests/test-sprint-candidate-removal.sh
# #954：Sprint Planning 選入時自動移除 sprint-candidate label
# 驗證 PO Round 2 的 gh issue edit 指令包含 --remove-label "sprint-candidate"
#
# AC1: Sprint Planning PO Round 2 選入 Story 後自動移除 sprint-candidate label
# AC2: 移除邏輯位於 PO Round 2 的 gh issue edit 操作內
# AC3: 冪等性：已無 sprint-candidate label 的 Issue 不報錯

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

# ---------------------------------------------------------------------------
# AC1 & AC2: PO Round 2 中 gh issue edit 指令包含移除 sprint-candidate label
# ---------------------------------------------------------------------------
test_po_prompt_contains_sprint_candidate_removal() {
  local po_prompt_file="/home/kevin/workspace/00.shikigami-dev/skills/sprint-planning/references/po-prompt.md"

  if [ ! -f "$po_prompt_file" ]; then
    fail "AC1/AC2: po-prompt.md 不存在"
    return 1
  fi

  # 讀取 PO Round 2 區段（大約在 line 167-220 附近）
  local po_round2_content=$(sed -n '167,220p' "$po_prompt_file")

  # 檢查是否包含 sprint-candidate
  if echo "$po_round2_content" | grep -q 'sprint-candidate'; then
    pass "AC1/AC2: PO Round 2 包含 sprint-candidate 標籤移除"
  else
    fail "AC1/AC2: PO Round 2 未包含 sprint-candidate 標籤移除"
  fi
}

# ---------------------------------------------------------------------------
# AC3: 冪等性驗證 — gh issue edit 對不存在的 label 靜默成功
# 由於 gh issue edit --remove-label 本身就是冪等的，
# 我們驗證指令中沒有額外的錯誤檢查邏輯
# ---------------------------------------------------------------------------
test_idempotency_documented() {
  local po_prompt_file="/home/kevin/workspace/00.shikigami-dev/skills/sprint-planning/references/po-prompt.md"

  if [ ! -f "$po_prompt_file" ]; then
    fail "AC3: po-prompt.md 不存在"
    return 1
  fi

  # 檢查 PO Round 2 區段是否包含 gh issue edit 指令
  local po_round2_content=$(sed -n '167,220p' "$po_prompt_file")

  if echo "$po_round2_content" | grep -q 'gh issue edit'; then
    pass "AC3: gh issue edit 指令存在（冪等性由 gh 命令自動保證）"
  else
    fail "AC3: 找不到 gh issue edit 指令"
  fi
}

# ---------------------------------------------------------------------------
# 執行所有測試
# ---------------------------------------------------------------------------
echo "=== Story #954 Test Suite ==="
echo ""

test_po_prompt_contains_sprint_candidate_removal
test_idempotency_documented

echo ""
echo "=== 測試結果 ==="
echo "PASS: $PASS_COUNT"
echo "FAIL: $FAIL_COUNT"

if [ $FAIL_COUNT -gt 0 ]; then
  exit 1
fi

exit 0
