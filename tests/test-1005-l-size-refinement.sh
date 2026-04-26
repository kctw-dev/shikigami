#!/usr/bin/env bash
# tests/test-1005-l-size-refinement.sh
# #1005：排程模式 L-size sprint-candidate 自動觸發 Refinement
#
# 覆蓋 AC：
#   AC1 — po-patrol.md 含 Step 3.7 L-size 偵測區段
#   AC2 — 觸發條件：sprint-candidate + size:L + age >= 24h + 無 needs-refinement
#   AC3 — 觀察期保護：age < 24h → l-size-candidate-observing
#   AC4 — 冪等性：已有 needs-refinement label → 跳過
#   AC5 — project_level 分流：low/medium/high 各有不同 action log
#   AC6 — needs-refinement label 替換 sprint-candidate label
#   AC7 — --body-file 模式（CLAUDE.md 紅線 13）
#   AC8 — 結果 JSON 含 l_size_refinement_triggered 與 l_size_observing 欄位
#   AC9 — architect-prompt.md 含 L-size Patrol Refinement 章節
#   AC10 — 排程模式互動表更新（patrol 觸發路徑）
#   AC11 — Architect 執行步驟（Step A–G）完整定義
#   AC12 — Architect sub-issue 使用 gh-issue-create.sh（CLAUDE.md 紅線 13）

set -uo pipefail

PASS=0
FAIL=0
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATROL="$REPO_ROOT/skills/cruise/references/po-patrol.md"
ARCHITECT="$REPO_ROOT/skills/sprint-planning/references/architect-prompt.md"

pass() { echo "[PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

# ---------------------------------------------------------------------------
# AC1：po-patrol.md 含 Step 3.7 L-size 偵測區段
# ---------------------------------------------------------------------------
[[ -f "$PATROL" ]] && pass "AC1.0 po-patrol.md 存在" \
  || { fail "AC1.0 po-patrol.md 缺失"; exit 1; }

if grep -q "Step 3.7" "$PATROL"; then
  pass "AC1.1 po-patrol.md 含 Step 3.7 區段標記"
else
  fail "AC1.1 po-patrol.md 缺 Step 3.7 區段"
fi

if grep -q "L-size sprint-candidate" "$PATROL" && grep -q "1005" "$PATROL"; then
  pass "AC1.2 Step 3.7 含 L-size sprint-candidate + issue 引用"
else
  fail "AC1.2 Step 3.7 缺 L-size sprint-candidate 或 #1005 引用"
fi

# ---------------------------------------------------------------------------
# AC2：觸發條件完整性
# ---------------------------------------------------------------------------
STEP37_CONTENT=$(awk '/Step 3.7/,/Step 4/' "$PATROL")

for cond in "sprint-candidate" "size:L" "needs-refinement" "AGE_HOURS" "24"; do
  if printf '%s' "$STEP37_CONTENT" | grep -q "$cond"; then
    pass "AC2 Step 3.7 含觸發條件：$cond"
  else
    fail "AC2 Step 3.7 缺觸發條件：$cond"
  fi
done

# stakeholder 安全邊界
if printf '%s' "$STEP37_CONTENT" | grep -q "stakeholder"; then
  pass "AC2 Step 3.7 含 stakeholder 安全邊界"
else
  fail "AC2 Step 3.7 缺 stakeholder 安全邊界"
fi

# ---------------------------------------------------------------------------
# AC3：觀察期保護（age < 24h → l-size-candidate-observing）
# ---------------------------------------------------------------------------
if grep -q "l-size-candidate-observing" "$PATROL"; then
  pass "AC3.1 po-patrol.md 含 l-size-candidate-observing action"
else
  fail "AC3.1 po-patrol.md 缺 l-size-candidate-observing action"
fi

if printf '%s' "$STEP37_CONTENT" | grep -q "AGE_HOURS < 24"; then
  pass "AC3.2 Step 3.7 觀察期條件為 < 24"
else
  fail "AC3.2 Step 3.7 觀察期條件缺 AGE_HOURS < 24"
fi

# ---------------------------------------------------------------------------
# AC4：冪等性（already has needs-refinement → skip）
# ---------------------------------------------------------------------------
if printf '%s' "$STEP37_CONTENT" | grep -q "needs-refinement.*continue\|needs-refinement.*OR.*stakeholder\|stakeholder.*needs-refinement"; then
  pass "AC4 Step 3.7 含 needs-refinement 冪等保護"
else
  # alternative pattern
  if printf '%s' "$STEP37_CONTENT" | grep -q "needs-refinement" && \
     printf '%s' "$STEP37_CONTENT" | grep -q "continue"; then
    pass "AC4 Step 3.7 含 needs-refinement + continue（冪等保護）"
  else
    fail "AC4 Step 3.7 缺 needs-refinement 冪等保護"
  fi
fi

# ---------------------------------------------------------------------------
# AC5：project_level 分流 log actions
# ---------------------------------------------------------------------------
for level in low medium high; do
  if grep -q "l-size-refinement.*${level}\|${level}.*l-size-refinement" "$PATROL"; then
    pass "AC5 po-patrol.md 含 project_level=${level} 的 l-size-refinement log"
  else
    fail "AC5 po-patrol.md 缺 project_level=${level} 的 l-size-refinement log"
  fi
done

# low 必有 HARD-GATE
if grep -q "HARD-GATE" "$PATROL" && grep -A5 "HARD-GATE" "$PATROL" | grep -q "L-size\|l-size\|Patrol Refinement"; then
  pass "AC5 low 路徑含 HARD-GATE 強制標記"
else
  fail "AC5 low 路徑缺 HARD-GATE"
fi

# ---------------------------------------------------------------------------
# AC6：needs-refinement 替換 sprint-candidate
# ---------------------------------------------------------------------------
if printf '%s' "$STEP37_CONTENT" | grep -q "add-label.*needs-refinement\|add.*needs-refinement"; then
  pass "AC6.1 Step 3.7 加 needs-refinement label"
else
  fail "AC6.1 Step 3.7 未加 needs-refinement label"
fi

if printf '%s' "$STEP37_CONTENT" | grep -q "remove-label.*sprint-candidate\|remove.*sprint-candidate"; then
  pass "AC6.2 Step 3.7 移除 sprint-candidate label"
else
  fail "AC6.2 Step 3.7 未移除 sprint-candidate label"
fi

# ---------------------------------------------------------------------------
# AC7：留言使用 --body-file（CLAUDE.md 紅線 13）
# ---------------------------------------------------------------------------
if printf '%s' "$STEP37_CONTENT" | grep -q "body-file"; then
  pass "AC7 Step 3.7 留言使用 --body-file 模式"
else
  fail "AC7 Step 3.7 留言未使用 --body-file（違反 CLAUDE.md 紅線 13）"
fi

# ---------------------------------------------------------------------------
# AC8：結果 JSON 含新欄位
# ---------------------------------------------------------------------------
if grep -q "l_size_refinement_triggered" "$PATROL"; then
  pass "AC8.1 po-patrol.md 結果 JSON 含 l_size_refinement_triggered"
else
  fail "AC8.1 po-patrol.md 結果 JSON 缺 l_size_refinement_triggered"
fi

if grep -q "l_size_observing" "$PATROL"; then
  pass "AC8.2 po-patrol.md 結果 JSON 含 l_size_observing"
else
  fail "AC8.2 po-patrol.md 結果 JSON 缺 l_size_observing"
fi

# actions 說明表包含新類型
if grep -q "l-size-refinement-trigger.*actions\|actions.*l-size-refinement-trigger\|l-size-refinement-trigger.*說明\|l-size.*Patrol Refinement" "$PATROL"; then
  pass "AC8.3 actions 說明表含 l-size-refinement-trigger 類型"
else
  # check the table separately
  if grep -q '"l-size-refinement-trigger"' "$PATROL"; then
    pass "AC8.3 actions 說明表含 l-size-refinement-trigger 類型"
  else
    fail "AC8.3 actions 說明表缺 l-size-refinement-trigger 類型"
  fi
fi

# ---------------------------------------------------------------------------
# AC9：architect-prompt.md 含 L-size Patrol Refinement 章節
# ---------------------------------------------------------------------------
[[ -f "$ARCHITECT" ]] && pass "AC9.0 architect-prompt.md 存在" \
  || { fail "AC9.0 architect-prompt.md 缺失"; exit 1; }

if grep -q "L-size Patrol Refinement" "$ARCHITECT"; then
  pass "AC9.1 architect-prompt.md 含 L-size Patrol Refinement 章節"
else
  fail "AC9.1 architect-prompt.md 缺 L-size Patrol Refinement 章節"
fi

if grep -q "1005" "$ARCHITECT"; then
  pass "AC9.2 architect-prompt.md 含 #1005 引用"
else
  fail "AC9.2 architect-prompt.md 缺 #1005 引用"
fi

# ---------------------------------------------------------------------------
# AC10：排程模式互動表更新
# ---------------------------------------------------------------------------
if grep -q "Cruise Patrol" "$ARCHITECT" && grep -q "L-size Patrol Refinement\|Patrol Refinement" "$ARCHITECT"; then
  pass "AC10 排程模式互動表包含 Cruise Patrol 觸發路徑"
else
  fail "AC10 排程模式互動表缺 Cruise Patrol 觸發路徑"
fi

# 舊表述應改為只針對 Sprint Planning
if grep -q "排程 Sprint Planning\|排程模式.*Sprint Planning" "$ARCHITECT"; then
  pass "AC10 排程模式互動表有區分「Sprint Planning」vs「Patrol」兩種路徑"
else
  fail "AC10 排程模式互動表未區分兩種路徑"
fi

# ---------------------------------------------------------------------------
# AC11：Architect 執行步驟（Step A–G）完整
# ---------------------------------------------------------------------------
for step in "Step A" "Step B" "Step C" "Step D" "Step E" "Step F" "Step G"; do
  if grep -q "$step" "$ARCHITECT"; then
    pass "AC11 architect-prompt.md 含 $step"
  else
    fail "AC11 architect-prompt.md 缺 $step"
  fi
done

# 決策結果三路（grep -E 用 | 不用 \|）
if grep -qE "split|可拆解" "$ARCHITECT"; then
  pass "AC11 Architect 決策含 split/可拆解"
else
  fail "AC11 Architect 決策缺 split/可拆解"
fi
if grep -qE "not-splittable|不可拆解" "$ARCHITECT"; then
  pass "AC11 Architect 決策含 not-splittable/不可拆解"
else
  fail "AC11 Architect 決策缺 not-splittable/不可拆解"
fi
if grep -qE "needs-info|需補充" "$ARCHITECT"; then
  pass "AC11 Architect 決策含 needs-info/需補充"
else
  fail "AC11 Architect 決策缺 needs-info/需補充"
fi

# ---------------------------------------------------------------------------
# AC12：sub-issue 使用 gh-issue-create.sh（CLAUDE.md 紅線 13）
# ---------------------------------------------------------------------------
if grep -q "gh-issue-create.sh" "$ARCHITECT"; then
  pass "AC12 L-size Patrol Refinement 使用 gh-issue-create.sh 建立 sub-issues"
else
  fail "AC12 L-size Patrol Refinement 未使用 gh-issue-create.sh（違反 CLAUDE.md 紅線 13）"
fi

# ---------------------------------------------------------------------------
# 結算
# ---------------------------------------------------------------------------
echo ""
echo "=========================================="
echo "Test Result: PASS=$PASS  FAIL=$FAIL"
echo "=========================================="

[[ $FAIL -eq 0 ]] && exit 0 || exit 1
