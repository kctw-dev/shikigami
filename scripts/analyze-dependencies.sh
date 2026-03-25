#!/usr/bin/env bash
# scripts/analyze-dependencies.sh
# Story #800 — TDAD Story 依賴圖：Sprint 平行執行衝突自動靜態分析
#
# 使用方式：
#   bash scripts/analyze-dependencies.sh docs/sprints/sprint_163.md
#
# 輸出：文字格式依賴圖，列出每個 Story 的目標檔案與衝突關係
#
# AC1: 讀取 sprint_N.md Story list，輸出依賴圖（text format）
# AC2: 識別 Stories 之間基於 AC file paths 的 file-level 衝突
# AC3: 測試腳本在 tests/test-dependency-map.sh
# NFR1: < 10 秒完成

set -o pipefail

SPRINT_FILE="${1:-}"

if [[ -z "$SPRINT_FILE" ]]; then
    echo "使用方式: $0 <sprint_file.md>" >&2
    echo "範例: $0 docs/sprints/sprint_163.md" >&2
    exit 1
fi

if [[ ! -f "$SPRINT_FILE" ]]; then
    echo "[ERROR] Sprint 文件不存在: $SPRINT_FILE" >&2
    exit 1
fi

# ── 解析 Sprint 文件中的 Story 清單 ──
# 從 Sprint Backlog 表格提取 Issue ID 與 Story 標題
declare -A STORY_TITLES
declare -A STORY_FILES

# 提取 Sprint Backlog 表格行：| N | Story title | #NNN | points | status | ... |
# 格式：| 數字 | 標題 | #issue_id | ...
while IFS='|' read -r _ num_col story_col issue_col _rest; do
    num_col=$(echo "$num_col" | xargs 2>/dev/null || echo "$num_col")
    story_col=$(echo "$story_col" | xargs 2>/dev/null || echo "$story_col")
    issue_col=$(echo "$issue_col" | xargs 2>/dev/null || echo "$issue_col")
    # 匹配行首數字列（Sprint Backlog 表格），issue 列格式 #NNN
    if [[ "$num_col" =~ ^[0-9]+$ ]] && [[ "$issue_col" =~ \#([0-9]+) ]]; then
        issue_id="${BASH_REMATCH[1]}"
        STORY_TITLES["$issue_id"]="$story_col"
    fi
done < <(grep -E '^\|[[:space:]]*[0-9]+[[:space:]]*\|' "$SPRINT_FILE" 2>/dev/null)

if [[ ${#STORY_TITLES[@]} -eq 0 ]]; then
    echo "[WARN] Sprint 文件中未找到 Story 清單（格式：| title | #N | ... |）" >&2
    echo "=== Dependency Graph ==="
    echo "(no stories found)"
    exit 0
fi

# ── 從 Story 標題推導目標檔案（keyword-based heuristic）──
extract_target_files() {
    local story_title="$1"
    local files=()

    # 基於標題關鍵字推導涉及的檔案路徑
    if echo "$story_title" | grep -qi "story-lifecycle\|story lifecycle"; then
        files+=("skills/sprint-execution/story-lifecycle-prompt.md")
    fi
    if echo "$story_title" | grep -qi "sprint-execution\|sprint execution"; then
        files+=("skills/sprint-execution/SKILL.md")
    fi
    if echo "$story_title" | grep -qi "sprint-planning\|sprint planning"; then
        files+=("skills/sprint-planning/SKILL.md")
    fi
    if echo "$story_title" | grep -qi "sprint-review\|sprint review"; then
        files+=("skills/sprint-review/SKILL.md")
    fi
    if echo "$story_title" | grep -qi "backlog\|sprint-candidate"; then
        files+=("docs/PROJECT_BOARD.md")
    fi
    if echo "$story_title" | grep -qi "adr-039\|haiku\|routing"; then
        files+=("docs/adr/ADR-039-token-cost-routing.md")
    fi
    if echo "$story_title" | grep -qi "worktree\|cleanup"; then
        files+=("scripts/cleanup-worktrees.sh")
    fi
    if echo "$story_title" | grep -qi "checkpoint\|tcb"; then
        files+=("skills/sprint-execution/story-lifecycle-prompt.md" "scripts/tcb-status.sh")
    fi
    if echo "$story_title" | grep -qi "analyze-depend\|dependency\|依賴圖"; then
        files+=("scripts/analyze-dependencies.sh" "tests/test-dependency-map.sh")
    fi
    if echo "$story_title" | grep -qi "重疊\|overlap"; then
        files+=("scripts/detect-story-overlap.sh")
    fi
    if echo "$story_title" | grep -qi "plugin.json\|marketplace\|version\|版本\|bump"; then
        files+=(".claude-plugin/plugin.json" ".claude-plugin/marketplace.json")
    fi
    if echo "$story_title" | grep -qi "PROJECT_BOARD\|project board"; then
        files+=("docs/PROJECT_BOARD.md")
    fi

    # 無匹配時回傳 unknown
    if [[ ${#files[@]} -eq 0 ]]; then
        files+=("(unknown — 需人工補充 AC file paths)")
    fi

    printf '%s\n' "${files[@]}"
}

# ── 建立 file → stories 映射 ──
declare -A FILE_TO_STORIES

for issue_id in "${!STORY_TITLES[@]}"; do
    title="${STORY_TITLES[$issue_id]}"
    while IFS= read -r file_path; do
        # 避免重複（同 story 相同 file_path 出現兩次）
        if [[ -n "${STORY_FILES["${issue_id}:${file_path}"]+x}" ]]; then
            continue
        fi
        STORY_FILES["${issue_id}:${file_path}"]="1"
        if [[ -n "${FILE_TO_STORIES[$file_path]+x}" ]]; then
            FILE_TO_STORIES["$file_path"]="${FILE_TO_STORIES[$file_path]} #${issue_id}"
        else
            FILE_TO_STORIES["$file_path"]="#${issue_id}"
        fi
    done < <(extract_target_files "$title" | sort -u)
done

# ── 輸出依賴圖 ──
SPRINT_NAME=$(basename "$SPRINT_FILE" .md)
echo "=== Story Dependency Graph: ${SPRINT_NAME} ==="
echo ""

# 每個 Story 的目標檔案
echo "── Story → Target Files ──"
for issue_id in $(echo "${!STORY_TITLES[@]}" | tr ' ' '\n' | sort -n); do
    title="${STORY_TITLES[$issue_id]}"
    echo ""
    echo "  #${issue_id}: ${title:0:60}"
    for key in "${!STORY_FILES[@]}"; do
        if [[ "$key" == "${issue_id}:"* ]]; then
            file_path="${key#${issue_id}:}"
            echo "    → ${file_path}"
        fi
    done
done

echo ""
echo "── File-level Conflicts ──"

# 找出共享檔案的 Stories（衝突）
CONFLICT_FOUND=0
for file_path in "${!FILE_TO_STORIES[@]}"; do
    stories="${FILE_TO_STORIES[$file_path]}"
    story_count=$(echo "$stories" | wc -w)
    if [[ $story_count -gt 1 ]]; then
        echo ""
        echo "  [CONFLICT] ${file_path}"
        echo "    Shared by: ${stories}"
        CONFLICT_FOUND=1
    fi
done

if [[ $CONFLICT_FOUND -eq 0 ]]; then
    echo "  (no file-level conflicts detected — all stories can run in parallel)"
fi

echo ""
echo "── Execution Groups ──"

# 計算衝突 story IDs
declare -A CONFLICTING_STORIES
for file_path in "${!FILE_TO_STORIES[@]}"; do
    stories="${FILE_TO_STORIES[$file_path]}"
    story_count=$(echo "$stories" | wc -w)
    if [[ $story_count -gt 1 ]]; then
        for s in $stories; do
            CONFLICTING_STORIES["${s#\#}"]="1"
        done
    fi
done

PARALLEL_GROUP=()
SEQUENTIAL_GROUP=()
for issue_id in $(echo "${!STORY_TITLES[@]}" | tr ' ' '\n' | sort -n); do
    if [[ -n "${CONFLICTING_STORIES[$issue_id]+x}" ]]; then
        SEQUENTIAL_GROUP+=("#${issue_id}")
    else
        PARALLEL_GROUP+=("#${issue_id}")
    fi
done

echo ""
if [[ ${#PARALLEL_GROUP[@]} -gt 0 ]]; then
    echo "  Group A (parallel): ${PARALLEL_GROUP[*]}"
else
    echo "  Group A (parallel): (none)"
fi

if [[ ${#SEQUENTIAL_GROUP[@]} -gt 0 ]]; then
    echo "  Group B (sequential): ${SEQUENTIAL_GROUP[*]}"
else
    echo "  Group B (sequential): (none)"
fi

echo ""
echo "=== End of Dependency Graph ==="
