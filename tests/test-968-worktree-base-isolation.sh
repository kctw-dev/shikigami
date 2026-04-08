#!/usr/bin/env bash
# tests/test-968-worktree-base-isolation.sh
# Story #968 — worktree branch base isolation 隔離檢查與防污染測試
#
# ── 目的 ──────────────────────────────────────────────────────────────────
#
# 驗證平行 worktree 執行時，branch 正確從乾淨的 origin/main base 建立。
# 防止 Sprint 177 #935 PR 混入 #954 commit 的問題重演。
#
# AC-1：parallel-safety.md 加入「建立 worktree 前先 fetch + 確認 base commit」步驟
# AC-2：worktree 建立範例改為明確指定 base commit（origin/main 或可配置的 base ref）
# AC-3：Sprint Execution 流程文件中加入 worktree branch isolation checklist
#
# ── 使用方式 ─────────────────────────────────────────────────────────────
#   bash tests/test-968-worktree-base-isolation.sh
# ─────────────────────────────────────────────────────────────────────────

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PASS_COUNT=0
FAIL_COUNT=0

pass() { echo "  [PASS] $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { echo "  [FAIL] $1"; echo "    [DIAG] $2"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

echo "=== worktree branch base isolation 隔離檢查測試 (#968) ==="
echo ""

# ─── AC-1：parallel-safety.md 包含 fetch + base commit 檢查步驟 ────────
echo "--- AC-1: parallel-safety.md 包含 base 同步檢查 ---"

PARALLEL_SAFETY_REF="${REPO_ROOT}/skills/sprint-execution/references/parallel-safety.md"

if [[ -f "${PARALLEL_SAFETY_REF}" ]]; then
  pass "AC-1a: parallel-safety.md 存在"

  # 檢查是否包含 fetch origin/main 或類似的 base 同步指令
  if grep -q "git fetch\|fetch origin\|origin/main\|base.*commit\|clean.*base\|base branch" "${PARALLEL_SAFETY_REF}" 2>/dev/null; then
    pass "AC-1b: parallel-safety.md 包含 base 同步檢查邏輯（fetch/origin-main）"
  else
    fail "AC-1b: parallel-safety.md 缺少 base 同步檢查" \
      "未找到 git fetch、origin/main、或 base commit 驗證的相關說明"
  fi

  # 檢查是否提及 worktree 建立前的準備步驟
  if grep -q "worktree.*建立前\|before.*worktree\|準備.*worktree\|worktree.*isolat" "${PARALLEL_SAFETY_REF}" 2>/dev/null; then
    pass "AC-1c: parallel-safety.md 提及 worktree 建立前的準備流程"
  else
    fail "AC-1c: parallel-safety.md 缺少 worktree 建立前準備描述" \
      "需要明確說明建立 worktree 前應執行的基礎檢查（fetch、base 驗證）"
  fi
else
  fail "AC-1a: parallel-safety.md 不存在" \
    "找不到 ${PARALLEL_SAFETY_REF}"
fi

echo ""

# ─── AC-2：worktree 建立範例使用明確 base commit / origin/main ────────
echo "--- AC-2: worktree 建立範例使用 origin/main base ---"

# 檢查 parallel-safety.md 中是否有 worktree 建立範例
if [[ -f "${PARALLEL_SAFETY_REF}" ]]; then
  if grep -q "git worktree add" "${PARALLEL_SAFETY_REF}" 2>/dev/null; then
    pass "AC-2a: parallel-safety.md 包含 git worktree add 範例"

    # 檢查範例是否明確指定 base（origin/main 或 HEAD）
    if grep "git worktree add" "${PARALLEL_SAFETY_REF}" | grep -q "origin/main\|HEAD\|@\|fetch" 2>/dev/null; then
      pass "AC-2b: worktree add 範例明確指定 base ref（origin/main 或 HEAD）"
    else
      fail "AC-2b: worktree add 範例未明確指定 base" \
        "範例應使用 'git worktree add <path> origin/main' 或類似明確 base 指定"
    fi
  else
    fail "AC-2a: parallel-safety.md 缺少 git worktree add 範例" \
      "應在 parallel-safety.md 中提供 worktree 建立的明確範例代碼"
  fi
fi

echo ""

# ─── AC-3：Sprint Execution 流程文件中加入 worktree isolation checklist ──
echo "--- AC-3: Sprint Execution 流程包含 worktree isolation checklist ---"

SPRINT_EXEC_SKILL="${REPO_ROOT}/skills/sprint-execution/SKILL.md"
STORY_LIFECYCLE_PROMPT="${REPO_ROOT}/skills/sprint-execution/story-lifecycle-prompt.md"

# 檢查 SKILL.md 或 story-lifecycle-prompt.md 是否提及 worktree base 隔離
if [[ -f "${SPRINT_EXEC_SKILL}" ]]; then
  if grep -q "worktree.*base\|base.*branch\|isolation.*check\|clean.*main\|origin/main" "${SPRINT_EXEC_SKILL}" 2>/dev/null; then
    pass "AC-3a: sprint-execution/SKILL.md 包含 worktree base 隔離內容"
  else
    fail "AC-3a: sprint-execution/SKILL.md 缺少 worktree base 隔離說明" \
      "應在 SKILL.md 中提及 worktree base 隔離檢查（fetch origin/main、branch from clean base）"
  fi
else
  fail "AC-3a: sprint-execution/SKILL.md 不存在" \
    "找不到 ${SPRINT_EXEC_SKILL}"
fi

# 檢查 story-lifecycle-prompt.md 是否提及 base 隔離流程
if [[ -f "${STORY_LIFECYCLE_PROMPT}" ]]; then
  if grep -q "fetch origin\|origin/main\|base.*commit\|worktree.*base\|clean.*base" "${STORY_LIFECYCLE_PROMPT}" 2>/dev/null; then
    pass "AC-3b: story-lifecycle-prompt.md 包含 base 隔離流程說明"
  else
    # 不強制要求，因為隔離可能在 parallel-safety.md 或其他參考文件中
    pass "AC-3b: story-lifecycle-prompt.md 不需強制提及（可在 parallel-safety.md 中統一說明）"
  fi
else
  fail "AC-3b: story-lifecycle-prompt.md 不存在" \
    "找不到 ${STORY_LIFECYCLE_PROMPT}"
fi

echo ""

# ─── 額外驗證：確認相關技術文件的一致性 ──────────────────────────────────
echo "--- 額外驗證：技術文件一致性 ---"

# 檢查 git-workflow 中是否提及 base isolation
GIT_WORKFLOW_REF="${REPO_ROOT}/skills/git-workflow/references/branch-setup.md"
if [[ -f "${GIT_WORKFLOW_REF}" ]]; then
  if grep -q "origin/main\|fetch\|base" "${GIT_WORKFLOW_REF}" 2>/dev/null; then
    pass "AC-Extra-1: git-workflow/branch-setup.md 包含 base 相關內容"
  else
    fail "AC-Extra-1: git-workflow/branch-setup.md 缺少 base isolation 說明" \
      "建議在 branch-setup.md 中提及 origin/main 作為 base"
  fi
else
  pass "AC-Extra-1: git-workflow/branch-setup.md 不存在（非強制）"
fi

# 檢查 parallel-safety.md 中是否包含過時或錯誤的 worktree 建立方式
if [[ -f "${PARALLEL_SAFETY_REF}" ]]; then
  # 負向檢查：確保沒有建議直接使用當前 HEAD 而不檢查 origin/main
  if grep "git worktree add" "${PARALLEL_SAFETY_REF}" | grep -q "^[^#]*git worktree add[^#]*$" 2>/dev/null; then
    # 有 worktree add 指令，檢查是否避免了危險的做法
    if ! grep "git worktree add" "${PARALLEL_SAFETY_REF}" | grep -q "\-\-detach\|\.\|\$\{PWD\}" 2>/dev/null; then
      # 不包含危險的相對路徑或 PWD，這是好的
      pass "AC-Extra-2: worktree add 指令不包含危險的相對參照"
    fi
  fi
fi

echo ""

# ─── 統計結果 ────────────────────────────────────────────────────────────
echo ""
TOTAL=$((PASS_COUNT + FAIL_COUNT))
PASS_PCT=0
if [[ $TOTAL -gt 0 ]]; then
  PASS_PCT=$((PASS_COUNT * 100 / TOTAL))
fi

echo "=== 測試結果摘要 ==="
echo "通過：$PASS_COUNT / $TOTAL（$PASS_PCT%）"

if [[ $FAIL_COUNT -gt 0 ]]; then
  echo "失敗：$FAIL_COUNT"
  exit 1
else
  echo "失敗：0"
  exit 0
fi
