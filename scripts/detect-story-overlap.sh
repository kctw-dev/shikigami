#!/usr/bin/env bash
# scripts/detect-story-overlap.sh
# Story #823 — Story 重疊檢查機制
#
# 使用方式：
#   bash scripts/detect-story-overlap.sh <sprint_candidate_file> [N_sprints]
#
# 說明：
#   掃描候選 Sprint 文件中的 Stories，與最近 N 個已完成 Sprint 文件比對，
#   輸出重疊分析報告（file path 維度 + skill/agent 名稱維度）。
#
# 參數：
#   sprint_candidate_file  — 含候選 Story 清單的文件（sprint_N.md 格式）
#   N_sprints              — 比對最近幾個 Sprint（預設 3）
#
# AC1: 輸出重疊分析結果
# AC2: 覆蓋 file path 與 skill/agent 名稱兩個維度
# AC3: 輸出格式為結構化文字，可直接嵌入 Refinement 報告

set -o pipefail

CANDIDATE_FILE="${1:-}"
N_SPRINTS="${2:-3}"
SPRINT_DIR="docs/sprints"

if [[ -z "$CANDIDATE_FILE" ]]; then
    echo "使用方式: $0 <sprint_candidate_file.md> [N_sprints]" >&2
    echo "範例: $0 docs/sprints/sprint_163.md 3" >&2
    exit 1
fi

if [[ ! -f "$CANDIDATE_FILE" ]]; then
    echo "[ERROR] 候選文件不存在: $CANDIDATE_FILE" >&2
    exit 1
fi

# ── 從 sprint 文件提取 Story 標題清單 ──
extract_stories() {
    local file="$1"
    grep -E '^\|[[:space:]]*[0-9]+[[:space:]]*\|' "$file" 2>/dev/null | while IFS='|' read -r _ num story issue _rest; do
        num=$(echo "$num" | xargs 2>/dev/null || echo "$num")
        story=$(echo "$story" | xargs 2>/dev/null || echo "$story")
        issue=$(echo "$issue" | xargs 2>/dev/null || echo "$issue")
        if [[ "$num" =~ ^[0-9]+$ ]] && [[ "$issue" =~ \#[0-9]+ ]]; then
            echo "${issue}|${story}"
        fi
    done
}

# ── Keyword → file path / skill / agent 映射 ──
extract_keywords() {
    local title="$1"
    local keywords=()

    # File paths
    [[ "$title" =~ [Ss]tory.lifecycle ]] && keywords+=("skills/sprint-execution/story-lifecycle-prompt.md")
    [[ "$title" =~ sprint.execution|[Ss]print.*[Ee]xecution ]] && keywords+=("skills/sprint-execution/SKILL.md")
    [[ "$title" =~ sprint.planning|[Ss]print.*[Pp]lanning ]] && keywords+=("skills/sprint-planning/SKILL.md")
    [[ "$title" =~ sprint.review|[Ss]print.*[Rr]eview ]] && keywords+=("skills/sprint-review/SKILL.md")
    [[ "$title" =~ worktree|[Ww]orktree ]] && keywords+=("scripts/cleanup-worktrees.sh")
    [[ "$title" =~ checkpoint|[Cc]heckpoint|TCB|tcb ]] && keywords+=("skills/sprint-execution/story-lifecycle-prompt.md" "scripts/tcb-status.sh")
    [[ "$title" =~ ADR.039|haiku|routing ]] && keywords+=("docs/adr/ADR-039-token-cost-routing.md")
    [[ "$title" =~ plugin.json|marketplace|[Vv]ersion|版本|bump ]] && keywords+=(".claude-plugin/plugin.json" ".claude-plugin/marketplace.json")
    [[ "$title" =~ PROJECT.BOARD|[Bb]acklog ]] && keywords+=("docs/PROJECT_BOARD.md")
    [[ "$title" =~ inject|[Ii]njection ]] && keywords+=("scripts/injection-scan.sh")
    [[ "$title" =~ predict.conflict|衝突.*靜態|靜態.*分析 ]] && keywords+=("scripts/predict-conflicts.sh")
    [[ "$title" =~ analyze.depend|依賴圖 ]] && keywords+=("scripts/analyze-dependencies.sh")

    # Skills
    [[ "$title" =~ [Cc]ruise ]] && keywords+=("skills/cruise")
    [[ "$title" =~ [Bb]acklog.manag ]] && keywords+=("skills/backlog-management")
    [[ "$title" =~ [Qq]uality.[Oo]bserver|MCP ]] && keywords+=("mcp-servers/quality-observer")
    [[ "$title" =~ [Ww]atchdog ]] && keywords+=("skills/session-watchdog")

    # Agents
    [[ "$title" =~ [Pp]roduct.[Oo]wner|PO ]] && keywords+=("agents/product-owner.md")
    [[ "$title" =~ [Aa]rchitect ]] && keywords+=("agents/architect.md")
    [[ "$title" =~ [Qq][Aa]|[Qq]uality.[Ee]ngineer ]] && keywords+=("agents/qa-engineer.md")

    if [[ ${#keywords[@]} -eq 0 ]]; then
        echo "(no specific file mapping)"
    else
        printf '%s\n' "${keywords[@]}" | sort -u
    fi
}

# ── 找最近 N 個已完成 Sprint 文件 ──
find_completed_sprints() {
    local n="$1"
    local candidate_base
    candidate_base=$(basename "$CANDIDATE_FILE" .md)
    # 提取候選 Sprint 編號
    local candidate_num=0
    if [[ "$candidate_base" =~ sprint_([0-9]+) ]]; then
        candidate_num="${BASH_REMATCH[1]}"
    fi

    # 列出所有 sprint_N.md，排除候選，取最近 N 個
    local found=0
    for num in $(seq $((candidate_num - 1)) -1 1); do
        local f="${SPRINT_DIR}/sprint_${num}.md"
        if [[ -f "$f" ]]; then
            echo "$f"
            ((found++))
            [[ $found -ge $n ]] && break
        fi
    done
}

# ── 主要邏輯 ──
CANDIDATE_NAME=$(basename "$CANDIDATE_FILE" .md)

echo "=== Story Overlap Detection Report ==="
echo "Candidate Sprint: ${CANDIDATE_NAME}"
echo "Comparing against: last ${N_SPRINTS} completed Sprints"
echo ""

# 取得候選 Stories
declare -A CANDIDATE_FILES
CANDIDATE_STORIES=()
while IFS='|' read -r issue_id story_title; do
    CANDIDATE_STORIES+=("${issue_id}|${story_title}")
    while IFS= read -r kw; do
        CANDIDATE_FILES["${issue_id}:${kw}"]="$story_title"
    done < <(extract_keywords "$story_title")
done < <(extract_stories "$CANDIDATE_FILE")

if [[ ${#CANDIDATE_STORIES[@]} -eq 0 ]]; then
    echo "[WARN] 候選 Sprint 文件中未找到 Story 清單" >&2
    echo "(no stories found in candidate file)"
    exit 0
fi

echo "── Candidate Stories ──"
for entry in "${CANDIDATE_STORIES[@]}"; do
    issue="${entry%%|*}"
    title="${entry#*|}"
    echo ""
    echo "  ${issue}: ${title:0:70}"
    echo "    [File dimension]"
    while IFS= read -r kw; do
        echo "      → ${kw}"
    done < <(extract_keywords "$title")
    echo "    [Skill/Agent dimension]"
    while IFS= read -r kw; do
        if echo "$kw" | grep -qE '^(skills/|agents/|mcp-)'; then
            echo "      → ${kw}"
        fi
    done < <(extract_keywords "$title")
done

echo ""
echo "── Completed Sprint Analysis ──"

COMPLETED_SPRINTS=()
while IFS= read -r sf; do
    COMPLETED_SPRINTS+=("$sf")
done < <(find_completed_sprints "$N_SPRINTS")

if [[ ${#COMPLETED_SPRINTS[@]} -eq 0 ]]; then
    echo "  (no completed sprints found for comparison)"
    echo ""
    echo "=== Overlap Summary ==="
    echo "  No completed sprints to compare against."
    echo "  Proceed with caution — this may be an early Sprint."
    echo "=== End of Overlap Report ==="
    exit 0
fi

# 建立 completed sprint keyword 映射
declare -A COMPLETED_KW_MAP  # keyword -> "sprint_N:issue:title"

for sprint_file in "${COMPLETED_SPRINTS[@]}"; do
    sprint_name=$(basename "$sprint_file" .md)
    while IFS='|' read -r issue_id story_title; do
        while IFS= read -r kw; do
            if [[ -n "${COMPLETED_KW_MAP[$kw]+x}" ]]; then
                COMPLETED_KW_MAP["$kw"]="${COMPLETED_KW_MAP[$kw]}; ${sprint_name}:${issue_id}"
            else
                COMPLETED_KW_MAP["$kw"]="${sprint_name}:${issue_id}:${story_title:0:50}"
            fi
        done < <(extract_keywords "$story_title")
    done < <(extract_stories "$sprint_file")
done

echo "  Completed Sprints scanned: ${COMPLETED_SPRINTS[*]}"

# 衝突偵測
echo ""
echo "── Overlap Detection ──"

OVERLAP_FOUND=0
declare -A SEEN_OVERLAPS

for candidate_entry in "${CANDIDATE_STORIES[@]}"; do
    candidate_issue="${candidate_entry%%|*}"
    candidate_title="${candidate_entry#*|}"

    while IFS= read -r kw; do
        if [[ -n "${COMPLETED_KW_MAP[$kw]+x}" ]]; then
            overlap_key="${candidate_issue}:${kw}"
            if [[ -z "${SEEN_OVERLAPS[$overlap_key]+x}" ]]; then
                SEEN_OVERLAPS["$overlap_key"]="1"
                echo ""
                echo "  [OVERLAP] ${candidate_issue}: ${candidate_title:0:60}"
                echo "    Dimension: ${kw}"
                echo "    Previously touched by: ${COMPLETED_KW_MAP[$kw]}"
                OVERLAP_FOUND=1
            fi
        fi
    done < <(extract_keywords "$candidate_title")
done

if [[ $OVERLAP_FOUND -eq 0 ]]; then
    echo "  (no overlaps detected — candidate stories are clean)"
fi

echo ""
echo "=== Overlap Summary ==="
if [[ $OVERLAP_FOUND -eq 1 ]]; then
    echo "  [OVERLAP-WARN] Overlaps detected. Review above before Sprint Planning Refinement."
    echo "  Recommendation: Architect/QA should verify whether overlapping Stories extend"
    echo "  or conflict with previously delivered functionality."
else
    echo "  [OVERLAP-CLEAN] No overlaps detected. Candidate Stories appear independent."
fi
echo ""
echo "  Sprints compared: ${COMPLETED_SPRINTS[*]}"
echo "=== End of Overlap Report ==="
