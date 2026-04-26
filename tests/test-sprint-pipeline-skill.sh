#!/usr/bin/env bash
# tests/test-sprint-pipeline-skill.sh
# Sprint Pipeline Skill 結構驗證測試

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$REPO_ROOT/skills/sprint/SKILL.md"

PASS=0; FAIL=0
ok()   { echo "✅ $1"; PASS=$((PASS+1)); }
fail() { echo "❌ $1"; FAIL=$((FAIL+1)); }

echo "=== Sprint Pipeline Skill 測試 ==="

# AC1: SKILL.md 存在
test -f "$SKILL" && ok "SKILL.md 存在" || fail "SKILL.md 不存在"

# AC2: frontmatter name 正確
grep -q '^name: sprint$' "$SKILL" && ok "name: sprint" || fail "name 欄位錯誤"

# AC3: description 包含 end-to-end 語意
grep -qi "end.to.end\|端到端\|full sprint\|complete sprint" "$SKILL" \
  && ok "description 含端到端語意" || fail "description 缺端到端語意"

# AC4: 三個階段定義存在
grep -q "Stage 1" "$SKILL" && ok "Stage 1 定義存在" || fail "Stage 1 缺失"
grep -q "Stage 2" "$SKILL" && ok "Stage 2 定義存在" || fail "Stage 2 缺失"
grep -q "Stage 3" "$SKILL" && ok "Stage 3 定義存在" || fail "Stage 3 缺失"

# AC5: 三個 Stage 對應正確的 skill 派遣
grep -q "sprint-planning" "$SKILL" && ok "Stage 1 派遣 sprint-planning" || fail "Stage 1 缺 sprint-planning 派遣"
grep -q "sprint-execution" "$SKILL" && ok "Stage 2 派遣 sprint-execution" || fail "Stage 2 缺 sprint-execution 派遣"
grep -q "sprint-review"    "$SKILL" && ok "Stage 3 派遣 sprint-review"    || fail "Stage 3 缺 sprint-review 派遣"

# AC6: Artifact 驗證存在（每個 stage）
ARTIFACT_CHECKS=$(grep -c "PIPELINE_HALT\|HALT" "$SKILL" 2>/dev/null || echo 0)
[ "$ARTIFACT_CHECKS" -ge 3 ] \
  && ok "Artifact 驗證點 >= 3 個（實際: ${ARTIFACT_CHECKS}）" \
  || fail "Artifact 驗證點不足（需 >= 3，實際: ${ARTIFACT_CHECKS}）"

# AC7: HARD-GATE 存在
grep -q '<HARD-GATE>' "$SKILL" && ok "HARD-GATE 存在" || fail "HARD-GATE 缺失"

# AC8: PIPELINE-HALT 定義
grep -q 'PIPELINE-HALT' "$SKILL" && ok "PIPELINE-HALT 機制定義存在" || fail "PIPELINE-HALT 機制缺失"

# AC9: 禁止自動重試的明確說明
grep -qi "禁止.*重試\|不.*重試" "$SKILL" && ok "HALT 後禁止自動重試" || fail "未明確禁止 HALT 後重試"

# AC10: 狀態偵測機制（Step 0）
grep -q "Step 0\|狀態偵測" "$SKILL" && ok "Step 0 狀態偵測存在" || fail "Step 0 狀態偵測缺失"

# AC11: 可從指定 Stage 繼續（resume）
grep -qE "/sprint plan|/sprint exec|/sprint review" "$SKILL" \
  && ok "支援從指定 Stage 繼續" || fail "缺乏 resume 語法"

# AC12: project_level 行為差異定義
grep -q "project_level" "$SKILL" && ok "project_level 行為定義存在" || fail "project_level 行為缺失"

# AC13: 與 cruise 的差異說明
grep -qi "cruise" "$SKILL" && ok "與 cruise 的差異有說明" || fail "缺 cruise 對比說明"

# AC14: 進度輸出格式定義（使用者可讀）
grep -qE "\[1/3\]|\[2/3\]|\[3/3\]" "$SKILL" && ok "進度格式 [N/3] 定義存在" || fail "進度格式缺失"

# AC15: README 已更新 skill 數量
README="$REPO_ROOT/README.md"
grep -q "skills-32" "$README" && ok "README badge 已更新為 32" || fail "README badge 未更新（仍是 31）"
grep -q "sprint.*端到端\|端到端.*Sprint" "$README" && ok "README skills 清單含 sprint" || fail "README skills 清單未加 sprint"

# 總結
echo ""
echo "=== 結果：PASS ${PASS} / FAIL ${FAIL} / TOTAL $((PASS+FAIL)) ==="
[ "$FAIL" -eq 0 ] && echo "✅ 全部通過" || { echo "❌ 有失敗項目"; exit 1; }
