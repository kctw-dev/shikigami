#!/usr/bin/env bash
# tests/test-compliance-audit.sh
# 驗證三個 sprint skill 的 Compliance Audit 定義

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

PASS=0; FAIL=0
ok()   { echo "✅ $1"; PASS=$((PASS+1)); }
fail() { echo "❌ $1"; FAIL=$((FAIL+1)); }

echo "=== Compliance Audit 定義測試 ==="

for SKILL in sprint-planning sprint-execution sprint-review; do
  FILE="$REPO_ROOT/skills/$SKILL/SKILL.md"
  echo ""
  echo "--- $SKILL ---"

  # AC1: Compliance Audit 節存在
  grep -q "Compliance Audit" "$FILE" \
    && ok "$SKILL: Compliance Audit 節存在" \
    || fail "$SKILL: 缺少 Compliance Audit 節"

  # AC2: HARD-GATE 存在（確保強制執行）
  GATE_COUNT=$(grep -c '<HARD-GATE>' "$FILE" 2>/dev/null || echo 0)
  [ "$GATE_COUNT" -ge 1 ] \
    && ok "$SKILL: 含 HARD-GATE（共 ${GATE_COUNT} 個）" \
    || fail "$SKILL: 缺少 HARD-GATE"

  # AC3: [COMPLIANCE-AUDIT] 輸出標記存在
  grep -q '\[COMPLIANCE-AUDIT\]' "$FILE" \
    && ok "$SKILL: [COMPLIANCE-AUDIT] 輸出標記存在" \
    || fail "$SKILL: 缺少 [COMPLIANCE-AUDIT] 輸出標記"

  # AC4: ✅ 和 ⏭ 符號規則有定義
  grep -q '✅' "$FILE" && grep -q '⏭' "$FILE" \
    && ok "$SKILL: ✅ / ⏭ 符號定義存在" \
    || fail "$SKILL: 缺少符號定義"

  # AC5: ❌ 符號有定義（失敗情況）
  grep -q '❌' "$FILE" \
    && ok "$SKILL: ❌ 失敗符號定義存在" \
    || fail "$SKILL: 缺少 ❌ 失敗符號定義"

  # AC6: Artifact 驗證欄位（planning/review 需有 docs/ 路徑，execution 需有 PR）
  case "$SKILL" in
    sprint-planning)
      grep -q 'docs/sprints/sprint_N' "$FILE" \
        && ok "$SKILL: Artifact 含 sprint doc 路徑" \
        || fail "$SKILL: Artifact 缺 sprint doc 路徑"
      ;;
    sprint-execution)
      grep -q 'PR #N' "$FILE" \
        && ok "$SKILL: Artifact 含 PR 驗證" \
        || fail "$SKILL: Artifact 缺 PR 驗證"
      ;;
    sprint-review)
      grep -q 'docs/meetings' "$FILE" \
        && ok "$SKILL: Artifact 含 meeting doc 路徑" \
        || fail "$SKILL: Artifact 缺 meeting doc 路徑"
      ;;
  esac

  # AC7: 「最後一個動作」或等效強制語言
  grep -qE "最後一個動作|結束前.*必須|必須輸出" "$FILE" \
    && ok "$SKILL: 有強制輸出語言" \
    || fail "$SKILL: 缺強制輸出語言"

done

echo ""
echo "=== 結果：PASS ${PASS} / FAIL ${FAIL} / TOTAL $((PASS+FAIL)) ==="
[ "$FAIL" -eq 0 ] && echo "✅ 全部通過" || { echo "❌ 有失敗項目"; exit 1; }
