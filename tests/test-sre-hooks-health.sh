#!/usr/bin/env bash
# test-sre-hooks-health.sh — #740 validate-hooks.sh 整合 cruise SRE patrol
# AC1: cruise SRE patrol 新增 validate-hooks.sh 執行步驟
# AC2: FAIL → [HOOKS-HEALTH-FAIL] + 寫入 cruise log（type: hooks-health）
# AC3: PASS → [HOOKS-HEALTH-OK]
# AC4: skills/cruise/references/sre-inspection.md 更新此步驟
# NFR1: 執行時間 < 5s
# NFR2: validate-hooks.sh 失敗不阻塞 SRE patrol 主流程

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

check() {
  local desc="$1"
  local result="$2"
  if [[ "$result" == "pass" ]]; then
    echo "PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== test-sre-hooks-health.sh ==="

SRE_DOC="$REPO_ROOT/skills/cruise/references/sre-inspection.md"

# AC4: sre-inspection.md 包含 validate-hooks.sh 步驟
if grep -q "validate-hooks" "$SRE_DOC" 2>/dev/null; then
  check "AC4: sre-inspection.md 包含 validate-hooks.sh 執行步驟" "pass"
else
  check "AC4: sre-inspection.md 包含 validate-hooks.sh 執行步驟" "fail"
fi

# AC2: sre-inspection.md 包含 HOOKS-HEALTH-FAIL 輸出
if grep -q "HOOKS-HEALTH-FAIL" "$SRE_DOC" 2>/dev/null; then
  check "AC2: sre-inspection.md 包含 [HOOKS-HEALTH-FAIL] 輸出說明" "pass"
else
  check "AC2: sre-inspection.md 包含 [HOOKS-HEALTH-FAIL] 輸出說明" "fail"
fi

# AC3: sre-inspection.md 包含 HOOKS-HEALTH-OK 輸出
if grep -q "HOOKS-HEALTH-OK" "$SRE_DOC" 2>/dev/null; then
  check "AC3: sre-inspection.md 包含 [HOOKS-HEALTH-OK] 輸出說明" "pass"
else
  check "AC3: sre-inspection.md 包含 [HOOKS-HEALTH-OK] 輸出說明" "fail"
fi

# NFR2: sre-inspection.md 說明 validate-hooks 失敗不阻塞流程
if grep -q "不阻塞\|non-blocking\|continue.*fail\|失敗.*繼續\||| true" "$SRE_DOC" 2>/dev/null; then
  check "NFR2: sre-inspection.md 說明 validate-hooks 失敗不阻塞主流程" "pass"
else
  check "NFR2: sre-inspection.md 說明 validate-hooks 失敗不阻塞主流程" "fail"
fi

# AC1: validate-hooks.sh 腳本存在
if [[ -f "$REPO_ROOT/scripts/validate-hooks.sh" ]]; then
  check "AC1: scripts/validate-hooks.sh 存在" "pass"
else
  check "AC1: scripts/validate-hooks.sh 存在" "fail"
fi

# NFR1: validate-hooks.sh 執行時間 < 5s（在本地快速跑一次）
if [[ -f "$REPO_ROOT/scripts/validate-hooks.sh" ]]; then
  START_T=$SECONDS
  bash "$REPO_ROOT/scripts/validate-hooks.sh" > /dev/null 2>&1 || true
  ELAPSED=$((SECONDS - START_T))
  if [[ $ELAPSED -lt 5 ]]; then
    check "NFR1: validate-hooks.sh 執行時間 ${ELAPSED}s < 5s" "pass"
  else
    check "NFR1: validate-hooks.sh 執行時間 ${ELAPSED}s >= 5s（超時）" "fail"
  fi
else
  check "NFR1: validate-hooks.sh 執行時間（腳本不存在）" "fail"
fi

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
