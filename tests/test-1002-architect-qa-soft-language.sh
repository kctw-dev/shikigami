#!/usr/bin/env bash
# tests/test-1002-architect-qa-soft-language.sh
# Issue #1002 (Sprint 182 Retro A2)：Architect / QA prompt 禁用軟性字樣清單
#
# 覆蓋 AC：
#   AC1 — Architect prompt 加入禁用軟性字樣清單（與 #994 同 8 詞）
#   AC2 — QA prompt 加入禁用軟性字樣清單（與 #994 同 8 詞）
#   AC3 — sprint-planning SKILL.md §2 Architect/QA checklist 含自檢指示
#   AC4 — 含禁用字樣文字會被 grep 偵測；不含則通過

set -u

PASS=0
FAIL=0
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ARCH_PROMPT="$REPO_ROOT/skills/sprint-planning/references/architect-prompt.md"
QA_PROMPT="$REPO_ROOT/skills/sprint-planning/references/qa-prompt.md"
PO_PROMPT="$REPO_ROOT/skills/sprint-planning/references/po-prompt.md"
SKILL_MD="$REPO_ROOT/skills/sprint-planning/SKILL.md"

pass() { echo "[PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

# 8 個詞與 PO #994 完全一致（單一來源）
FORBIDDEN_WORDS=(考慮 明確 適當 合理 盡量 儘可能 必要時 建議)
GREP_PATTERN='考慮|明確|適當|合理|盡量|儘可能|必要時|建議'

# ---------------------------------------------------------------------------
# 前置：檔案存在
# ---------------------------------------------------------------------------
for f in "$ARCH_PROMPT" "$QA_PROMPT" "$PO_PROMPT" "$SKILL_MD"; do
  if [[ -f "$f" ]]; then
    pass "前置：檔案存在 ${f#$REPO_ROOT/}"
  else
    fail "前置：檔案缺失 ${f#$REPO_ROOT/}"
    echo "=== Test Result: PASS=$PASS FAIL=$FAIL ==="
    exit 1
  fi
done

# ---------------------------------------------------------------------------
# AC1：Architect prompt
# ---------------------------------------------------------------------------
if grep -q "## 禁用軟性字樣清單" "$ARCH_PROMPT"; then
  pass "AC1.1 Architect prompt 含「禁用軟性字樣清單」section"
else
  fail "AC1.1 Architect prompt 缺「禁用軟性字樣清單」section"
fi

# AC1.2 — 8 個詞全數出現
for w in "${FORBIDDEN_WORDS[@]}"; do
  if grep -q "$w" "$ARCH_PROMPT"; then
    pass "AC1.2 Architect prompt 含禁用字樣「$w」"
  else
    fail "AC1.2 Architect prompt 缺禁用字樣「$w」"
  fi
done

# AC1.3 — 包含 grep 自檢指令
if grep -q "grep -E.*考慮.*明確" "$ARCH_PROMPT" || grep -q "$GREP_PATTERN" "$ARCH_PROMPT"; then
  pass "AC1.3 Architect prompt 含 grep 自檢指令"
else
  fail "AC1.3 Architect prompt 缺 grep 自檢指令"
fi

# AC1.4 — NEEDS_REVISION 標記指示存在
if grep -q "\[NEEDS_REVISION\]" "$ARCH_PROMPT"; then
  pass "AC1.4 Architect prompt 含 [NEEDS_REVISION] 標記指示"
else
  fail "AC1.4 Architect prompt 缺 [NEEDS_REVISION] 標記指示"
fi

# AC1.5 — 引用 PO 為單一來源（避免 drift）
if grep -q "po-prompt.md" "$ARCH_PROMPT"; then
  pass "AC1.5 Architect prompt 引用 po-prompt.md 作單一來源"
else
  fail "AC1.5 Architect prompt 未引用 po-prompt.md"
fi

# ---------------------------------------------------------------------------
# AC2：QA prompt
# ---------------------------------------------------------------------------
if grep -q "## 禁用軟性字樣清單" "$QA_PROMPT"; then
  pass "AC2.1 QA prompt 含「禁用軟性字樣清單」section"
else
  fail "AC2.1 QA prompt 缺「禁用軟性字樣清單」section"
fi

for w in "${FORBIDDEN_WORDS[@]}"; do
  if grep -q "$w" "$QA_PROMPT"; then
    pass "AC2.2 QA prompt 含禁用字樣「$w」"
  else
    fail "AC2.2 QA prompt 缺禁用字樣「$w」"
  fi
done

if grep -q "grep -E.*考慮.*明確" "$QA_PROMPT" || grep -q "$GREP_PATTERN" "$QA_PROMPT"; then
  pass "AC2.3 QA prompt 含 grep 自檢指令"
else
  fail "AC2.3 QA prompt 缺 grep 自檢指令"
fi

if grep -q "\[NEEDS_REVISION\]" "$QA_PROMPT"; then
  pass "AC2.4 QA prompt 含 [NEEDS_REVISION] 標記指示"
else
  fail "AC2.4 QA prompt 缺 [NEEDS_REVISION] 標記指示"
fi

if grep -q "po-prompt.md" "$QA_PROMPT"; then
  pass "AC2.5 QA prompt 引用 po-prompt.md 作單一來源"
else
  fail "AC2.5 QA prompt 未引用 po-prompt.md"
fi

# ---------------------------------------------------------------------------
# AC3：SKILL.md §2 含自檢指示
# ---------------------------------------------------------------------------
# 只看 checklist 行（- [ ] 起頭），避開模型表格與其他段落引用
ARCH_LINE=$(grep -nE '^- \[ \] \*\*Architect\*\* 技術評估' "$SKILL_MD" | head -1 | cut -d: -f1)
QA_LINE=$(grep -nE '^- \[ \] \*\*QA\*\* 驗收標準確認' "$SKILL_MD" | head -1 | cut -d: -f1)

if [[ -n "$ARCH_LINE" ]] && sed -n "${ARCH_LINE}p" "$SKILL_MD" | grep -qE "1002|NEEDS_REVISION|軟性字樣自檢"; then
  pass "AC3.1 SKILL.md §2 Architect checklist 含自檢提示"
else
  fail "AC3.1 SKILL.md §2 Architect checklist 缺自檢提示（行=$ARCH_LINE）"
fi

if [[ -n "$QA_LINE" ]] && sed -n "${QA_LINE}p" "$SKILL_MD" | grep -qE "1002|NEEDS_REVISION|軟性字樣自檢"; then
  pass "AC3.2 SKILL.md §2 QA checklist 含自檢提示"
else
  fail "AC3.2 SKILL.md §2 QA checklist 缺自檢提示（行=$QA_LINE）"
fi

# ---------------------------------------------------------------------------
# AC4：grep 行為驗證 — 含禁用字樣應被偵測；不含則通過
# ---------------------------------------------------------------------------
SOFT_TEXTS=(
  "Story 估點時應考慮複雜度，採用適當設計模式"
  "AC 應該明確並合理覆蓋邊界"
  "盡量減少呼叫次數，儘可能批次處理"
  "必要時補上 ADR，建議使用 jq"
  "Architect 的估點應該確保合理性"  # "確保"不在清單但 "合理"在 → 應觸發
)
for text in "${SOFT_TEXTS[@]}"; do
  if echo "$text" | grep -qE "$GREP_PATTERN"; then
    pass "AC4.+ 偵測到軟性文字：「$text」"
  else
    fail "AC4.+ 未偵測到應觸發的軟性文字：「$text」"
  fi
done

CLEAN_TEXTS=(
  "估點 = 受影響檔案數 × 0.5 + 新增 ADR 數 × 1"
  "P95 < 200ms（在 100 RPS 負載下）"
  "Story 涉及新技術選型 → 自動建立 RESEARCH ADR Issue"
  "受影響檔案數 = 4，歷史平均 = M size，請求重估"
)
for text in "${CLEAN_TEXTS[@]}"; do
  if echo "$text" | grep -qE "$GREP_PATTERN"; then
    fail "AC4.- 不應觸發但被偵測到的乾淨文字：「$text」"
  else
    pass "AC4.- 乾淨文字通過：「$text」"
  fi
done

# ---------------------------------------------------------------------------
# AC5：與 PO 一致性 — Architect/QA 使用的 8 詞與 PO 完全一致（避免 drift）
# ---------------------------------------------------------------------------
for w in "${FORBIDDEN_WORDS[@]}"; do
  if grep -q "$w" "$PO_PROMPT"; then
    pass "AC5 PO 仍含禁用字樣「$w」（一致性檢查）"
  else
    fail "AC5 PO 缺禁用字樣「$w」— Architect/QA 與 PO 不一致"
  fi
done

# ---------------------------------------------------------------------------
# 結算
# ---------------------------------------------------------------------------
echo ""
echo "=========================================="
echo "Test Result: PASS=$PASS  FAIL=$FAIL"
echo "=========================================="

[[ $FAIL -eq 0 ]] && exit 0 || exit 1
