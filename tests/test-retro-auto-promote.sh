#!/usr/bin/env bash
# test-retro-auto-promote.sh — #739 retro-action 高優先級自動升格 sprint-candidate
# AC1: Sprint Planning PO Round 1 流程自動掃描 retro-action + priority:must label
# AC2: 自動加 sprint-candidate label
# AC3: 輸出 [RETRO-AUTO-PROMOTE] #N → sprint-candidate
# AC4: po-prompt.md 包含此邏輯說明

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

echo "=== test-retro-auto-promote.sh ==="

# AC4: po-prompt.md 包含 RETRO-AUTO-PROMOTE 邏輯
PO_PROMPT="$REPO_ROOT/skills/sprint-planning/references/po-prompt.md"
if grep -q "RETRO-AUTO-PROMOTE" "$PO_PROMPT" 2>/dev/null; then
  check "AC4: po-prompt.md 包含 RETRO-AUTO-PROMOTE 說明" "pass"
else
  check "AC4: po-prompt.md 包含 RETRO-AUTO-PROMOTE 說明" "fail"
fi

# AC4: po-prompt.md 包含 retro-action + priority:must 判斷邏輯
if grep -q "priority.*must\|must.*priority" "$PO_PROMPT" 2>/dev/null && \
   grep -q "retro-action" "$PO_PROMPT" 2>/dev/null; then
  check "AC4: po-prompt.md 包含 retro-action + priority:must 條件" "pass"
else
  check "AC4: po-prompt.md 包含 retro-action + priority:must 條件" "fail"
fi

# AC1/NFR1: 升格邏輯包含 NFR2 範圍限定說明（不過度自動化）
if grep -q "NFR2\|must.*不升格.*should\|only.*must\|範圍限定\|避免過度自動化" "$PO_PROMPT" 2>/dev/null; then
  check "NFR1: 升格邏輯限定 priority:must（不過度自動化）" "pass"
else
  check "NFR1: 升格邏輯限定 priority:must（不過度自動化）" "fail"
fi

# AC3: po-prompt.md 包含輸出格式說明
if grep -q "\[RETRO-AUTO-PROMOTE\]" "$PO_PROMPT" 2>/dev/null; then
  check "AC3: po-prompt.md 包含 [RETRO-AUTO-PROMOTE] 輸出格式" "pass"
else
  check "AC3: po-prompt.md 包含 [RETRO-AUTO-PROMOTE] 輸出格式" "fail"
fi

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
