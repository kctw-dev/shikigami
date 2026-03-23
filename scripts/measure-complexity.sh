#!/usr/bin/env bash
# scripts/measure-complexity.sh
# #462 框架複雜度預算機制
# 量化 Shikigami 框架的複雜度指標，並在超出預算時輸出 WARNING
#
# 用法：
#   bash scripts/measure-complexity.sh              # 輸出當前基線
#   bash scripts/measure-complexity.sh --report     # 輸出詳細報告（同 --baseline）
#   bash scripts/measure-complexity.sh --diff <baseline_file>  # 與基線比較，輸出 +N/-M
#
# 可配置門檻（環境變數）：
#   COMPLEXITY_SKILL_BUDGET   最大 Skill 數量（預設 40）
#   COMPLEXITY_AGENT_BUDGET   最大 Agent 數量（預設 15）
#   COMPLEXITY_HOOK_BUDGET    最大 Hook 腳本數量（預設 35）
#   COMPLEXITY_LINES_BUDGET   最大總行數（預設 25000）
#
# 退出碼：
#   0 — 測量成功（包括有 WARNING 的情況）
#   1 — 執行錯誤（目錄不存在等）

set -uo pipefail

# ── 腳本定位 ──────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── 可配置預算門檻 ─────────────────────────────────────────────────
COMPLEXITY_SKILL_BUDGET="${COMPLEXITY_SKILL_BUDGET:-40}"
COMPLEXITY_AGENT_BUDGET="${COMPLEXITY_AGENT_BUDGET:-15}"
COMPLEXITY_HOOK_BUDGET="${COMPLEXITY_HOOK_BUDGET:-35}"
COMPLEXITY_LINES_BUDGET="${COMPLEXITY_LINES_BUDGET:-25000}"

# ── 度量函式 ───────────────────────────────────────────────────────

measure_skill_count() {
  # 每個 skills/ 子目錄算一個 Skill
  local count=0
  if [[ -d "$REPO_ROOT/skills" ]]; then
    count=$(find "$REPO_ROOT/skills" -maxdepth 1 -mindepth 1 -type d | wc -l)
  fi
  echo "$count"
}

measure_agent_count() {
  # agents/ 下的 .md 檔案算 Agent 定義（排除 prompt 附屬檔）
  local count=0
  if [[ -d "$REPO_ROOT/agents" ]]; then
    count=$(find "$REPO_ROOT/agents" -maxdepth 1 -name "*.md" | wc -l)
  fi
  echo "$count"
}

measure_hook_count() {
  # hooks/ 下的 .sh 腳本算 Hook（不含 hooks.json 等）
  local count=0
  if [[ -d "$REPO_ROOT/hooks" ]]; then
    count=$(find "$REPO_ROOT/hooks" -maxdepth 2 -name "*.sh" | wc -l)
  fi
  echo "$count"
}

measure_total_lines() {
  # Skill SKILL.md + Agent .md + Hook .sh 的總行數
  local total=0
  local skill_lines=0
  local agent_lines=0
  local hook_lines=0

  if [[ -d "$REPO_ROOT/skills" ]]; then
    skill_lines=$(find "$REPO_ROOT/skills" -name "SKILL.md" -exec wc -l {} + 2>/dev/null \
      | awk '/total$/{print $1}' | tail -1)
    skill_lines="${skill_lines:-0}"
  fi

  if [[ -d "$REPO_ROOT/agents" ]]; then
    agent_lines=$(find "$REPO_ROOT/agents" -maxdepth 1 -name "*.md" -exec wc -l {} + 2>/dev/null \
      | awk '/total$/{print $1}' | tail -1)
    agent_lines="${agent_lines:-0}"
  fi

  if [[ -d "$REPO_ROOT/hooks" ]]; then
    hook_lines=$(find "$REPO_ROOT/hooks" -name "*.sh" -exec wc -l {} + 2>/dev/null \
      | awk '/total$/{print $1}' | tail -1)
    hook_lines="${hook_lines:-0}"
  fi

  total=$(( skill_lines + agent_lines + hook_lines ))
  echo "$total"
}

# ── 警告判斷 ───────────────────────────────────────────────────────
check_budget() {
  local metric="$1"
  local value="$2"
  local budget="$3"
  if [[ "$value" -gt "$budget" ]]; then
    echo "WARNING: $metric 超出預算（當前 $value，門檻 $budget）" >&2
    return 1
  fi
  return 0
}

# ── 模式解析 ───────────────────────────────────────────────────────
MODE="baseline"
DIFF_FILE=""

if [[ "${1:-}" == "--diff" ]]; then
  MODE="diff"
  DIFF_FILE="${2:-}"
  if [[ -z "$DIFF_FILE" ]]; then
    echo "ERROR: --diff 需要提供基線檔案路徑" >&2
    exit 1
  fi
elif [[ "${1:-}" == "--report" ]] || [[ "${1:-}" == "--baseline" ]]; then
  MODE="baseline"
fi

# ── 測量當前值 ─────────────────────────────────────────────────────
SKILL_COUNT=$(measure_skill_count)
AGENT_COUNT=$(measure_agent_count)
HOOK_COUNT=$(measure_hook_count)
TOTAL_LINES=$(measure_total_lines)

# ── 輸出基線模式 ────────────────────────────────────────────────────
if [[ "$MODE" == "baseline" ]]; then
  echo "=== Shikigami 框架複雜度基線報告 ==="
  echo "測量時間：$(date '+%Y-%m-%dT%H:%M:%S')"
  echo ""
  echo "SKILL_COUNT=${SKILL_COUNT}  （門檻 ${COMPLEXITY_SKILL_BUDGET}）"
  echo "AGENT_COUNT=${AGENT_COUNT}  （門檻 ${COMPLEXITY_AGENT_BUDGET}）"
  echo "HOOK_COUNT=${HOOK_COUNT}  （門檻 ${COMPLEXITY_HOOK_BUDGET}）"
  echo "TOTAL_LINES=${TOTAL_LINES}  （門檻 ${COMPLEXITY_LINES_BUDGET}）"
  echo ""

  # 預算檢查（WARNING 輸出至 stderr，不影響 exit 0）
  WARN=0
  check_budget "SKILL" "$SKILL_COUNT" "$COMPLEXITY_SKILL_BUDGET" || WARN=1
  check_budget "AGENT" "$AGENT_COUNT" "$COMPLEXITY_AGENT_BUDGET" || WARN=1
  check_budget "HOOK"  "$HOOK_COUNT"  "$COMPLEXITY_HOOK_BUDGET"  || WARN=1
  check_budget "LINES" "$TOTAL_LINES" "$COMPLEXITY_LINES_BUDGET" || WARN=1

  if [[ "$WARN" -eq 0 ]]; then
    echo "RESULT: PASS（所有指標在預算內）"
  else
    echo "RESULT: WARNING（部分指標超出預算，請評估是否刪減舊功能）"
  fi
  exit 0
fi

# ── 差異比較模式（--diff） ─────────────────────────────────────────
if [[ "$MODE" == "diff" ]]; then
  if [[ ! -f "$DIFF_FILE" ]]; then
    echo "ERROR: 基線檔案不存在：$DIFF_FILE" >&2
    exit 1
  fi

  # 讀取基線值（格式：KEY=VALUE）
  BASE_SKILL=$(grep "^SKILL_COUNT=" "$DIFF_FILE" 2>/dev/null | cut -d= -f2 | tr -d ' ' | head -1)
  BASE_AGENT=$(grep "^AGENT_COUNT=" "$DIFF_FILE" 2>/dev/null | cut -d= -f2 | tr -d ' ' | head -1)
  BASE_HOOK=$(grep "^HOOK_COUNT=" "$DIFF_FILE" 2>/dev/null | cut -d= -f2 | tr -d ' ' | head -1)
  BASE_LINES=$(grep "^TOTAL_LINES=" "$DIFF_FILE" 2>/dev/null | cut -d= -f2 | tr -d ' ' | head -1)

  BASE_SKILL="${BASE_SKILL:-0}"
  BASE_AGENT="${BASE_AGENT:-0}"
  BASE_HOOK="${BASE_HOOK:-0}"
  BASE_LINES="${BASE_LINES:-0}"

  DELTA_SKILL=$(( SKILL_COUNT - BASE_SKILL ))
  DELTA_AGENT=$(( AGENT_COUNT - BASE_AGENT ))
  DELTA_HOOK=$(( HOOK_COUNT  - BASE_HOOK  ))
  DELTA_LINES=$(( TOTAL_LINES - BASE_LINES ))

  format_delta() {
    local v="$1"
    if [[ "$v" -gt 0 ]]; then echo "+${v}"
    elif [[ "$v" -lt 0 ]]; then echo "${v}"
    else echo "±0"
    fi
  }

  echo "=== 複雜度變化報告 ==="
  echo "基線來源：$DIFF_FILE"
  echo ""
  echo "指標           | 基線  | 當前  | 變化"
  echo "---------------|-------|-------|------"
  echo "SKILL_COUNT    | ${BASE_SKILL}    | ${SKILL_COUNT}    | $(format_delta $DELTA_SKILL)"
  echo "AGENT_COUNT    | ${BASE_AGENT}    | ${AGENT_COUNT}    | $(format_delta $DELTA_AGENT)"
  echo "HOOK_COUNT     | ${BASE_HOOK}    | ${HOOK_COUNT}    | $(format_delta $DELTA_HOOK)"
  echo "TOTAL_LINES    | ${BASE_LINES}  | ${TOTAL_LINES}  | $(format_delta $DELTA_LINES)"
  echo ""

  # 預算檢查
  WARN=0
  check_budget "SKILL" "$SKILL_COUNT" "$COMPLEXITY_SKILL_BUDGET" || WARN=1
  check_budget "AGENT" "$AGENT_COUNT" "$COMPLEXITY_AGENT_BUDGET" || WARN=1
  check_budget "HOOK"  "$HOOK_COUNT"  "$COMPLEXITY_HOOK_BUDGET"  || WARN=1
  check_budget "LINES" "$TOTAL_LINES" "$COMPLEXITY_LINES_BUDGET" || WARN=1

  if [[ "$WARN" -eq 0 ]]; then
    echo "RESULT: PASS（所有指標在預算內）"
  else
    echo "RESULT: WARNING（部分指標超出預算）"
  fi
  exit 0
fi
