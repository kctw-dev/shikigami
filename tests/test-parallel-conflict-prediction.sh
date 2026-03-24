#!/usr/bin/env bash
# test-parallel-conflict-prediction.sh — Parallel Conflict Prediction 測試套件
# Story #395: Parallel Conflict Prediction — 平行任務衝突預測
# AC1: Scrum Master dispatch 流程新增靜態衝突分析步驟
# AC5: 相關 Skill 文件更新說明機制

set -euo pipefail

PASS=0
FAIL=0
SPRINT_EXEC_SKILL="/home/kevin/workspace/shikigami-story-395/skills/sprint-execution/SKILL.md"
CONFLICT_PREDICTION_REF="/home/kevin/workspace/shikigami-story-395/skills/sprint-execution/references/conflict-prediction.md"

echo "=== Parallel Conflict Prediction 測試套件 ==="

run_test() {
  local name="$1"
  local condition="$2"
  local expected="$3"
  if [[ "$condition" == "$expected" ]]; then
    echo "PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name (expected=$expected, got=$condition)"
    FAIL=$((FAIL + 1))
  fi
}

# AC1: sprint-execution SKILL.md 含有衝突預測相關內容
if [[ -f "$SPRINT_EXEC_SKILL" ]]; then
  run_test "AC1: sprint-execution SKILL.md 含衝突預測內容" \
    "$(grep -qE 'dispatch plan|Group A|衝突預測' "$SPRINT_EXEC_SKILL" 2>/dev/null && echo found || echo not_found)" \
    "found"
else
  echo "FAIL: sprint-execution/SKILL.md 不存在"
  FAIL=$((FAIL + 1))
fi

# AC5: conflict-prediction.md reference 文件存在
run_test "AC5: conflict-prediction.md 參考文件存在" \
  "$([[ -f "$CONFLICT_PREDICTION_REF" ]] && echo found || echo not_found)" \
  "found"

# AC5: reference 文件含 Group A / Group B 分組概念
if [[ -f "$CONFLICT_PREDICTION_REF" ]]; then
  run_test "AC5: conflict-prediction.md 含 Group A/B 分組" \
    "$(grep -qE 'Group A|Group B' "$CONFLICT_PREDICTION_REF" 2>/dev/null && echo found || echo not_found)" \
    "found"
  run_test "AC5: conflict-prediction.md 含 dispatch plan 輸出" \
    "$(grep -qE 'dispatch plan|dispatch_plan' "$CONFLICT_PREDICTION_REF" 2>/dev/null && echo found || echo not_found)" \
    "found"
fi

# AC3: 含動態重評估機制描述
if [[ -f "$CONFLICT_PREDICTION_REF" ]]; then
  run_test "AC3: conflict-prediction.md 含動態重評估機制" \
    "$(grep -qE '動態重評估|dynamic re-eval|Group A 完成' "$CONFLICT_PREDICTION_REF" 2>/dev/null && echo found || echo not_found)" \
    "found"
fi

echo ""
echo "=== 結果 ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [[ "$FAIL" -eq 0 ]]; then
  echo "[CONFLICT-PREDICTION-TEST] ALL PASS"
  exit 0
else
  echo "[CONFLICT-PREDICTION-TEST] $FAIL FAIL"
  exit 1
fi
