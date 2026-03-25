#!/usr/bin/env bash
# test-d3-record.sh — D3 Debate Protocol 格式驗證測試（Story #777）
# AC4: 驗證 docs/km/d3-decisions.md 的格式正確性

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== test-d3-record.sh ==="
echo ""

D3_FILE="$REPO_ROOT/docs/km/d3-decisions.md"
SPRINT_PLANNING="$REPO_ROOT/skills/sprint-planning/SKILL.md"

# -------------------------------------------------------
# AC4: docs/km/d3-decisions.md 格式驗證
# -------------------------------------------------------
echo "[AC4-1] d3-decisions.md 檔案存在"

if [[ -f "$D3_FILE" ]]; then
  pass "docs/km/d3-decisions.md 存在"
else
  fail "docs/km/d3-decisions.md 不存在"
fi

echo ""
echo "[AC4-2] d3-decisions.md 包含必要欄位標題"

REQUIRED_COLS=("Date" "Sprint" "Story" "Advocate Position" "Challenge" "Rebuttal" "Judge Rationale" "Final Decision")

for col in "${REQUIRED_COLS[@]}"; do
  if grep -q "$col" "$D3_FILE" 2>/dev/null; then
    pass "欄位存在：$col"
  else
    fail "欄位缺失：$col"
  fi
done

echo ""
echo "[AC4-3] d3-decisions.md 包含 Markdown 表格格式"

if grep -q "^|" "$D3_FILE" 2>/dev/null; then
  pass "包含 Markdown 表格（以 | 開頭的行）"
else
  fail "缺少 Markdown 表格格式"
fi

if grep -q "^|[-| ]*|" "$D3_FILE" 2>/dev/null; then
  pass "包含表格分隔行（---）"
else
  fail "缺少表格分隔行"
fi

echo ""
echo "[AC4-4] d3-decisions.md 包含範例條目"

if grep -q "範例\|Example\|example" "$D3_FILE" 2>/dev/null; then
  pass "包含範例條目說明"
else
  fail "缺少範例條目說明"
fi

echo ""
# -------------------------------------------------------
# AC1: sprint-planning SKILL.md 定義 D3 三輪結構
# -------------------------------------------------------
echo "[AC1-1] sprint-planning SKILL.md 包含 D3 Debate Protocol 段落"

if grep -q "D3 Debate Protocol\|D3 Protocol" "$SPRINT_PLANNING" 2>/dev/null; then
  pass "SKILL.md 包含 D3 Debate Protocol 段落"
else
  fail "SKILL.md 缺少 D3 Debate Protocol 段落"
fi

echo ""
echo "[AC1-2] 定義三輪結構：Advocate（Architect）"

if grep -q "Advocate.*Architect\|Architect.*Advocate" "$SPRINT_PLANNING" 2>/dev/null; then
  pass "定義 Advocate（Architect）角色"
else
  fail "缺少 Advocate（Architect）角色定義"
fi

echo ""
echo "[AC1-3] 定義三輪結構：Challenge（QA）"

if grep -q "Challenge.*QA\|QA.*Challenge" "$SPRINT_PLANNING" 2>/dev/null; then
  pass "定義 Challenge（QA）角色"
else
  fail "缺少 Challenge（QA）角色定義"
fi

echo ""
echo "[AC1-4] 定義三輪結構：Cost-aware rebuttal（Architect）"

if grep -q "Cost-aware\|cost-aware\|成本意識\|Rebuttal.*Architect\|Architect.*Rebuttal" "$SPRINT_PLANNING" 2>/dev/null; then
  pass "定義 Cost-aware rebuttal（Architect）"
else
  fail "缺少 Cost-aware rebuttal 定義"
fi

echo ""
echo "[AC1-5] 定義三輪結構：Judge decision（SM）"

if grep -q "Judge.*SM\|SM.*Judge\|Judge decision\|裁決.*SM\|SM.*裁決" "$SPRINT_PLANNING" 2>/dev/null; then
  pass "定義 Judge decision（SM）"
else
  fail "缺少 Judge decision（SM）定義"
fi

echo ""
# -------------------------------------------------------
# AC2: D3 記錄格式定義
# -------------------------------------------------------
echo "[AC2-1] SKILL.md 提及 d3-decisions.md 記錄路徑"

if grep -q "d3-decisions.md\|docs/km/d3" "$SPRINT_PLANNING" 2>/dev/null; then
  pass "SKILL.md 定義 d3-decisions.md 記錄路徑"
else
  fail "SKILL.md 缺少 d3-decisions.md 記錄路徑"
fi

echo ""
# -------------------------------------------------------
# AC3: D3 觸發時 sprint planning 文件包含 ## D3 Record
# -------------------------------------------------------
echo "[AC3-1] SKILL.md 定義 D3 Record 段落格式"

if grep -q "## D3 Record\|D3 Record" "$SPRINT_PLANNING" 2>/dev/null; then
  pass "SKILL.md 定義 ## D3 Record 段落"
else
  fail "SKILL.md 缺少 ## D3 Record 段落定義"
fi

echo ""
# -------------------------------------------------------
# NFR 驗證
# -------------------------------------------------------
echo "[NFR1] D3 是選擇性觸發（僅在 Architect 和 QA 意見不同時）"

if grep -q "optional\|選擇性\|意見不同\|disagree\|不同意\|分歧" "$SPRINT_PLANNING" 2>/dev/null; then
  pass "SKILL.md 說明 D3 為選擇性觸發"
else
  fail "SKILL.md 未說明 D3 的選擇性觸發條件"
fi

echo ""
echo "[NFR2] 最多 3 輪，無無限循環"

if grep -q "最多 3 輪\|maximum 3\|Maximum 3\|3 輪\|3-round\|3 rounds" "$SPRINT_PLANNING" 2>/dev/null; then
  pass "SKILL.md 定義最多 3 輪上限"
else
  fail "SKILL.md 未定義 3 輪上限"
fi

echo ""

# -------------------------------------------------------
# 結果統計
# -------------------------------------------------------
TOTAL=$((PASS + FAIL))
echo "=== 結果：$PASS/$TOTAL PASS ==="
echo ""

if [[ $FAIL -eq 0 ]]; then
  echo "ALL TESTS PASSED"
  exit 0
else
  echo "SOME TESTS FAILED ($FAIL/$TOTAL)"
  exit 1
fi
