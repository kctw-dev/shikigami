#!/usr/bin/env bash
# scripts/audit-adr-references.sh
# D5（ADR 歸檔策略）：稽核每個 ADR 在「執行面」的活躍度
#
# 分類：
#   ACTIVE     — 在 skills / scripts / hooks / agents / commands /
#                CLAUDE.md / README.md 中被引用 ≥ 1 次
#   DOCS-ONLY  — 只在 docs/ 內部其他文件被互引（沒有執行面引用）
#   DORMANT    — 完全沒被引用（archive 候選）
#   SUPERSEDED — ADR 內文標記「Superseded by」（archive 候選）
#
# 用法：
#   bash scripts/audit-adr-references.sh                   # 表格報告
#   bash scripts/audit-adr-references.sh --json            # JSONL 輸出
#   bash scripts/audit-adr-references.sh --candidates      # 只列 archive 候選
#   bash scripts/audit-adr-references.sh --threshold N     # 自訂 ACTIVE 門檻（預設 1）

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADR_DIR="$REPO_ROOT/docs/adr"

THRESHOLD=1
FORMAT="table"
ONLY_CANDIDATES=0

usage() {
  cat <<'EOF'
用法：bash scripts/audit-adr-references.sh [OPTIONS]

選項：
  --json              改輸出 JSONL（每行一筆，方便管線處理）
  --candidates        只列 archive 候選（DORMANT / SUPERSEDED）
  --threshold N       自訂 ACTIVE 門檻（預設 1，<N 視為 DOCS-ONLY 或 DORMANT）
  -h, --help          顯示此說明

分類：
  ACTIVE      執行面引用 ≥ 門檻
  DOCS-ONLY   只有文件互引（docs/ 下被引用）
  DORMANT     完全沒被引用
  SUPERSEDED  ADR 內文標記 Superseded by

掃描範圍（執行面）：
  skills/ scripts/ hooks/ agents/ commands/
  CLAUDE.md README.md
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)        FORMAT="json"; shift ;;
    --candidates)  ONLY_CANDIDATES=1; shift ;;
    --threshold)
      [[ $# -ge 2 ]] || { echo "[ERROR] --threshold 需要值" >&2; exit 2; }
      THRESHOLD="$2"; shift 2 ;;
    -h|--help)     usage; exit 0 ;;
    *)             echo "[ERROR] 未知參數：$1" >&2; usage; exit 2 ;;
  esac
done

[[ "$THRESHOLD" =~ ^[0-9]+$ ]] || { echo "[ERROR] --threshold 必須是非負整數" >&2; exit 2; }
[[ -d "$ADR_DIR" ]] || { echo "[ERROR] 找不到 ADR 目錄：$ADR_DIR" >&2; exit 2; }

# ---------------------------------------------------------------------------
# 收集所有 ADR 編號
# ---------------------------------------------------------------------------
declare -a ADR_NUMS=()
while IFS= read -r f; do
  base=$(basename "$f")
  num=$(echo "$base" | grep -oE '^ADR-([0-9]+)' | grep -oE '[0-9]+')
  [[ -n "$num" ]] && ADR_NUMS+=("$num")
done < <(find "$ADR_DIR" -maxdepth 1 -name 'ADR-*.md' -type f | sort)

# ---------------------------------------------------------------------------
# 分類函式
# ---------------------------------------------------------------------------
count_runtime_refs() {
  local num="$1"
  # 兩種寫法：ADR-NN（主流）+ ADR-0NN / ADR-00NN（少見補零）
  local pattern="ADR-0*${num}\\b"
  local count
  count=$(grep -rh -E "$pattern" \
    "$REPO_ROOT/skills" \
    "$REPO_ROOT/scripts" \
    "$REPO_ROOT/hooks" \
    "$REPO_ROOT/agents" \
    "$REPO_ROOT/commands" \
    "$REPO_ROOT/CLAUDE.md" \
    "$REPO_ROOT/README.md" \
    2>/dev/null | grep -cE "$pattern" 2>/dev/null)
  echo "${count:-0}"
}

count_docs_refs() {
  local num="$1"
  local pattern="ADR-0*${num}\\b"
  local count
  count=$(grep -rhE "$pattern" "$REPO_ROOT/docs" 2>/dev/null \
    | grep -cE "$pattern" 2>/dev/null)
  echo "${count:-0}"
}

is_superseded() {
  # 只認「自身已被取代」的標記，不認本文中描述其他 ADR 取代關係的字樣。
  # 接受的格式：
  #   - 行首為「Superseded by ADR-NN」
  #   - **粗體**包覆的「Superseded by」（典型 status/header）
  #   - 引用區塊「> **[Superseded by ADR-NN ...]**」
  #   - 中文「**狀態**：Superseded」
  local f="$1"
  grep -qE \
    -e '^[[:space:]]*\*\*狀態\*\*[^*]*Superseded' \
    -e '^[[:space:]]*\*\*Status\*\*[^*]*Superseded' \
    -e '^[[:space:]]*>?[[:space:]]*\*\*\[?Superseded by ADR' \
    -e '^[[:space:]]*Superseded by ADR' \
    "$f" 2>/dev/null
}

get_title() {
  local f="$1"
  head -1 "$f" 2>/dev/null | sed 's/^# //; s/^[[:space:]]*//' | head -c 80
}

get_status() {
  local f="$1"
  grep -m1 "^\*\*狀態" "$f" 2>/dev/null | sed 's/.*：//; s/\*\*//g; s/^[[:space:]]*//' | head -c 60
}

# ---------------------------------------------------------------------------
# 主迴圈：分類 + 輸出
# ---------------------------------------------------------------------------
total_active=0
total_docs_only=0
total_dormant=0
total_superseded=0

# 預備一個 sortable 清單（category|num|...）寫入 stdout
emit_records() {
  for num in "${ADR_NUMS[@]}"; do
    local f
    f=$(find "$ADR_DIR" -maxdepth 1 -name "ADR-${num}*.md" | head -1)
    [[ -z "$f" ]] && continue

    local rt_refs docs_refs cat
    rt_refs=$(count_runtime_refs "$num")
    docs_refs=$(count_docs_refs "$num")

    if is_superseded "$f"; then
      cat="SUPERSEDED"; total_superseded=$((total_superseded + 1))
    elif [[ "$rt_refs" -ge "$THRESHOLD" ]]; then
      cat="ACTIVE"; total_active=$((total_active + 1))
    elif [[ "$docs_refs" -ge 1 ]]; then
      cat="DOCS-ONLY"; total_docs_only=$((total_docs_only + 1))
    else
      cat="DORMANT"; total_dormant=$((total_dormant + 1))
    fi

    # 以 candidate 模式時跳過 ACTIVE / DOCS-ONLY
    if [[ "$ONLY_CANDIDATES" -eq 1 ]]; then
      [[ "$cat" == "DORMANT" || "$cat" == "SUPERSEDED" ]] || continue
    fi

    local title status
    title=$(get_title "$f")
    status=$(get_status "$f")

    if [[ "$FORMAT" == "json" ]]; then
      # 嚴格 JSON — 用 printf 並對字串做最低限度跳脫
      esc_title=${title//\"/\\\"}
      esc_status=${status//\"/\\\"}
      esc_path=${f#$REPO_ROOT/}
      printf '{"adr":"%s","category":"%s","runtime_refs":%d,"docs_refs":%d,"status":"%s","path":"%s","title":"%s"}\n' \
        "ADR-$num" "$cat" "$rt_refs" "$docs_refs" "$esc_status" "$esc_path" "$esc_title"
    else
      printf '%-12s | %-10s | rt=%-3d | docs=%-3d | %s\n' \
        "ADR-$num" "$cat" "$rt_refs" "$docs_refs" "$title"
    fi
  done
}

if [[ "$FORMAT" == "table" ]]; then
  echo "=== ADR 引用稽核（threshold=$THRESHOLD）==="
  echo ""
  printf '%-12s | %-10s | %-7s | %-8s | %s\n' "ADR" "CATEGORY" "RUNTIME" "DOCS" "TITLE"
  printf '%s\n' "----------------------------------------------------------------------"
fi

emit_records

if [[ "$FORMAT" == "table" ]]; then
  echo ""
  echo "=== 統計 ==="
  printf 'ACTIVE      : %d\n' "$total_active"
  printf 'DOCS-ONLY   : %d\n' "$total_docs_only"
  printf 'DORMANT     : %d  ← archive 候選\n' "$total_dormant"
  printf 'SUPERSEDED  : %d  ← archive 候選\n' "$total_superseded"
  printf 'TOTAL       : %d\n' $((total_active + total_docs_only + total_dormant + total_superseded))
fi

exit 0
