#!/usr/bin/env bash
# test-389-cruise-pr-comments.sh
# Issue #389 回歸測試：PO 巡邏新增關聯 PR comments 掃描步驟
# AC1：PO 巡邏流程文件新增「掃描關聯 PR comments」步驟
# AC2：Agent prompt 包含提取 PR stakeholder 指示的指引（含 gh pr view 指令）
# AC3：PR comments 與 Issue comments 衝突時有明確的優先級判斷規則
# AC4：回歸測試場景（#389 case）已在文件中記載

set -euo pipefail

SKILL_FILE="skills/cruise/SKILL.md"
# #460: 拆分後 PR comments 邏輯在 references/po-patrol.md，允許在任意 cruise 模組中搜尋
CRUISE_FILES="skills/cruise/SKILL.md skills/cruise/references/po-patrol.md skills/cruise/references/sre-inspection.md skills/cruise/references/auto-shoot.md"
PASS=0
FAIL=0

# 搜尋所有 cruise 模組（支援 extended regex）
cruise_grep() {
  local pattern="$1"
  # shellcheck disable=SC2086
  grep -qE "$pattern" $CRUISE_FILES 2>/dev/null
}

ok() {
  echo "PASS: $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "FAIL: $1"
  FAIL=$((FAIL + 1))
}

echo "--- AC1：PO 巡邏流程文件包含 PR comments 掃描步驟 ---"

# AC1-1：文件應有「關聯 PR comments 掃描步驟」段落
if cruise_grep "關聯 PR comments 掃描步驟"; then
  ok "AC1-1：cruise 模組包含關聯 PR comments 掃描步驟段落"
else
  fail "AC1-1：cruise 模組缺少關聯 PR comments 掃描步驟段落"
fi

# AC1-2：掃描步驟應位於「留言掃描步驟」之後（在 po-patrol.md 中）
PATROL_FILE="skills/cruise/references/po-patrol.md"
if [[ -f "$PATROL_FILE" ]]; then
  ISSUE_COMMENT_LINE=$(grep -n "### 留言掃描步驟\|## 留言掃描步驟" "$PATROL_FILE" | head -1 | cut -d: -f1)
  PR_COMMENT_LINE=$(grep -n "### 關聯 PR comments 掃描步驟\|## 關聯 PR comments 掃描步驟" "$PATROL_FILE" | head -1 | cut -d: -f1)
else
  ISSUE_COMMENT_LINE=$(grep -n "### 留言掃描步驟" "$SKILL_FILE" | head -1 | cut -d: -f1)
  PR_COMMENT_LINE=$(grep -n "### 關聯 PR comments 掃描步驟" "$SKILL_FILE" | head -1 | cut -d: -f1)
fi
if [[ -n "$ISSUE_COMMENT_LINE" && -n "$PR_COMMENT_LINE" && "$PR_COMMENT_LINE" -gt "$ISSUE_COMMENT_LINE" ]]; then
  ok "AC1-2：PR comments 掃描步驟位於留言掃描步驟之後（行 $PR_COMMENT_LINE > $ISSUE_COMMENT_LINE）"
else
  fail "AC1-2：PR comments 掃描步驟未位於留言掃描步驟之後"
fi

echo ""
echo "--- AC2：Agent prompt 包含提取 PR stakeholder 指示的指引 ---"

# AC2-1：文件應包含 gh pr view 指令
if cruise_grep "gh pr view"; then
  ok "AC2-1：cruise 模組包含 gh pr view 指令"
else
  fail "AC2-1：cruise 模組缺少 gh pr view 指令"
fi

# AC2-2：應包含 comments,reviews 欄位擷取
if cruise_grep "comments,reviews"; then
  ok "AC2-2：gh pr view 包含 comments,reviews 欄位"
else
  fail "AC2-2：gh pr view 缺少 comments,reviews 欄位定義"
fi

# AC2-3：應有 LAST_PATROL_TIME 篩選說明（避免重複處理舊指示）
if cruise_grep "LAST_PATROL_TIME"; then
  ok "AC2-3：文件包含 LAST_PATROL_TIME 篩選說明（避免重複處理舊指示）"
else
  fail "AC2-3：文件缺少 LAST_PATROL_TIME 篩選說明"
fi

# AC2-4：應有透過 timelineItems 識別關聯 PR 的方法
if cruise_grep "timelineItems"; then
  ok "AC2-4：文件包含透過 timelineItems 識別關聯 PR 的方法"
else
  fail "AC2-4：文件缺少透過 timelineItems 識別關聯 PR 的方法"
fi

echo ""
echo "--- AC3：PR comments 與 Issue comments 衝突時有明確優先級規則 ---"

# AC3-1：文件應有「衝突時的優先級規則」說明
if cruise_grep "PR comments 與 Issue comments 衝突時的優先級規則|PR comments 與 Issue comments.*衝突"; then
  ok "AC3-1：文件包含 PR comments 與 Issue comments 衝突時的優先級規則"
else
  fail "AC3-1：文件缺少衝突時的優先級規則說明"
fi

# AC3-2：文件應明確說明「以 PR comments 為準」
if cruise_grep "以 PR comments 為準"; then
  ok "AC3-2：文件明確指定以 PR comments 為準"
else
  fail "AC3-2：文件未明確說明以 PR comments 為準"
fi

# AC3-3：決策偽碼中應有 Step 0.5 PR comments 整合
if cruise_grep "Step 0.5"; then
  ok "AC3-3：處置決策偽碼包含 Step 0.5 PR comments 整合"
else
  fail "AC3-3：處置決策偽碼缺少 Step 0.5"
fi

# AC3-4：應有 log 記錄矛盾覆蓋的 action
if cruise_grep "pr-instruction-overrides-issue"; then
  ok "AC3-4：文件包含 pr-instruction-overrides-issue log action"
else
  fail "AC3-4：文件缺少 pr-instruction-overrides-issue log action"
fi

echo ""
echo "--- AC4：回歸測試場景（#389 case）已在文件記載 ---"

# AC4-1：文件應有回歸測試場景描述
if cruise_grep "回歸測試場景"; then
  ok "AC4-1：文件包含回歸測試場景段落"
else
  fail "AC4-1：文件缺少回歸測試場景段落"
fi

# AC4-2：回歸場景應包含 LinGeorge2/AIO-System 及 PR #29
if cruise_grep "LinGeorge2/AIO-System" && cruise_grep "PR #29"; then
  ok "AC4-2：回歸場景包含參考案例（LinGeorge2/AIO-System，PR #29）"
else
  fail "AC4-2：回歸場景缺少參考案例說明"
fi

# AC4-3：回歸場景應描述預期行為（識別拆分指示，不催促合併）
if cruise_grep "拆分" && cruise_grep "催促合併|不催促合併"; then
  ok "AC4-3：回歸場景描述預期行為（識別拆分指示 vs 不催促合併）"
else
  fail "AC4-3：回歸場景缺少預期行為描述"
fi

echo ""
echo "========================================="
if [[ $FAIL -eq 0 ]]; then
  echo "PASS: $PASS / FAIL: $FAIL"
else
  echo "PASS: $PASS / FAIL: $FAIL"
fi
echo "========================================="

[[ $FAIL -eq 0 ]]
