#!/usr/bin/env bash
# scripts/state-machine/post-execution-pr-verify.sh
# Story #989: L1 主 session inline PR 強制驗證
#
# 用法：
#   bash scripts/state-machine/post-execution-pr-verify.sh --branch <branch_name>
#
# 退出碼：
#   0 → PR 驗證 PASS（存在 OPEN PR，base=main）
#   1 → PR 驗證 FAIL（PR 缺失、base 錯誤、state 非 OPEN）
#
# 升級動作矩陣：
#   PR_COUNT == 0             → [POST-EXEC-PR-MISSING]   + exit 1
#   baseRefName != "main"     → [POST-EXEC-PR-WRONG-BASE] + exit 1
#   state != "OPEN"           → [POST-EXEC-PR-NOT-OPEN]   + exit 1
#   正常                      → [POST-EXEC-PR-PASS]        + exit 0
#
# 規則：
#   - 不自動補救（不建 PR、不 push、不 merge）
#   - 多 PR 時取 base=main + state=OPEN 的第一個
#   - 固定使用 --head <branch>，不用 --search（避免誤匹配）

set -uo pipefail

BRANCH=""

# --- 參數解析 ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch)
      BRANCH="$2"
      shift 2
      ;;
    *)
      echo "[ERROR] 未知參數: $1" >&2
      echo "用法: $0 --branch <branch_name>" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$BRANCH" ]]; then
  echo "[ERROR] 必須指定 --branch <branch_name>" >&2
  echo "用法: $0 --branch <branch_name>" >&2
  exit 1
fi

echo "[POST-EXEC-PR-VERIFY] 開始驗證 branch: $BRANCH"

# --- 執行 gh pr list，固定使用 --head（不用 --search）---
PR_JSON=$(gh pr list \
  --head "$BRANCH" \
  --json number,state,baseRefName,headRefName \
  2>&1)

GH_EXIT=$?
if [[ $GH_EXIT -ne 0 ]]; then
  echo "[POST-EXEC-PR-VERIFY-ERROR] gh pr list 執行失敗（exit=$GH_EXIT）：$PR_JSON" >&2
  exit 1
fi

# --- PR 數量檢查 ---
PR_COUNT=$(echo "$PR_JSON" | grep -o '"number"' | wc -l | tr -d ' ')

if [[ "$PR_COUNT" -eq 0 ]]; then
  echo "[POST-EXEC-PR-MISSING] branch=$BRANCH 無對應 PR"
  echo "  → 拒絕 PASS，Story=BLOCKED，暫停 Sprint"
  echo "  → 不自動補救（不建 PR、不 push、不 merge）"
  exit 1
fi

# --- 多 PR 時：取 base=main + state=OPEN 的第一個 ---
# 使用 grep 逐行解析 JSON（避免 jq 依賴）
# 格式：[{"number":N,"state":"OPEN","baseRefName":"main","headRefName":"..."},...]

# 嘗試找到 base=main 且 state=OPEN 的 PR
MATCHED_NUMBER=""
MATCHED_STATE=""
MATCHED_BASE=""

# 解析 JSON 陣列中每個 PR 物件
# 提取所有 PR 的 number、state、baseRefName
while IFS= read -r pr_entry; do
  [[ -z "$pr_entry" ]] && continue

  # 提取欄位（簡單 grep/sed 解析）
  num=$(echo "$pr_entry" | grep -o '"number":[0-9]*' | grep -o '[0-9]*' | head -1)
  state=$(echo "$pr_entry" | grep -o '"state":"[^"]*"' | grep -o ':[^}]*' | tr -d ':"' | head -1)
  base=$(echo "$pr_entry" | grep -o '"baseRefName":"[^"]*"' | grep -o ':[^}]*' | tr -d ':"' | head -1)

  [[ -z "$num" ]] && continue

  # 優先選 base=main + state=OPEN
  if [[ "$base" == "main" && "$state" == "OPEN" ]]; then
    MATCHED_NUMBER="$num"
    MATCHED_STATE="$state"
    MATCHED_BASE="$base"
    break
  fi

  # 若尚未有匹配，記錄第一個供後續錯誤報告
  if [[ -z "$MATCHED_NUMBER" ]]; then
    MATCHED_NUMBER="$num"
    MATCHED_STATE="$state"
    MATCHED_BASE="$base"
  fi
done < <(echo "$PR_JSON" | tr ',' '\n' | grep -E '"number"|"state"|"baseRefName"' | paste - - - | sed 's/^/[/;s/$$/]/') 2>/dev/null || true

# 若上述解析失敗，fallback：直接從原始 JSON 提取第一個條目
if [[ -z "$MATCHED_NUMBER" ]]; then
  # 提取第一個 number
  MATCHED_NUMBER=$(echo "$PR_JSON" | grep -o '"number":[0-9]*' | head -1 | grep -o '[0-9]*')
  MATCHED_STATE=$(echo "$PR_JSON" | grep -o '"state":"[^"]*"' | head -1 | sed 's/"state":"//;s/"//')
  MATCHED_BASE=$(echo "$PR_JSON" | grep -o '"baseRefName":"[^"]*"' | head -1 | sed 's/"baseRefName":"//;s/"//')
fi

echo "[POST-EXEC-PR-VERIFY] 找到 PR #${MATCHED_NUMBER} state=${MATCHED_STATE} base=${MATCHED_BASE}"

# --- baseRefName 檢查 ---
if [[ "$MATCHED_BASE" != "main" ]]; then
  echo "[POST-EXEC-PR-WRONG-BASE] PR #${MATCHED_NUMBER} base=${MATCHED_BASE}（應為 main）"
  echo "  → 拒絕 PASS"
  echo "  → 不自動補救"
  exit 1
fi

# --- state 檢查 ---
if [[ "$MATCHED_STATE" != "OPEN" ]]; then
  echo "[POST-EXEC-PR-NOT-OPEN] PR #${MATCHED_NUMBER} state=${MATCHED_STATE}（應為 OPEN）"
  echo "  → 拒絕 PASS"
  echo "  → 不自動補救"
  exit 1
fi

# --- 全部通過 ---
echo "[POST-EXEC-PR-PASS] PR #${MATCHED_NUMBER} 驗證通過（base=main, state=OPEN）"
exit 0
