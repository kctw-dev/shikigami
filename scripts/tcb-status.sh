#!/usr/bin/env bash
# scripts/tcb-status.sh
# Story #781 — TCB 細粒度 Checkpoint：Phase-Level Checkpoint 狀態查詢
#
# 使用方式：
#   bash scripts/tcb-status.sh [sprint_N]
#
# 說明：
#   讀取 docs/sprints/subagent-results/*-phase-checkpoint.json，
#   輸出每個 Story 的 Phase 完成格網（grid）。
#
# AC3: scripts/tcb-status.sh reads all phase checkpoints and outputs
#      a per-Story phase completion grid

set -o pipefail

SPRINT_ARG="${1:-}"
RESULTS_DIR="docs/sprints/subagent-results"

PHASES=("analysis" "design" "implementation" "test")

# ── 符號定義 ──
SYMBOL_DONE="✓"
SYMBOL_IN_PROGRESS="→"
SYMBOL_PENDING="·"

# ASCII fallback（若終端不支援 Unicode）
if [[ "${TERM:-}" == "dumb" ]] || [[ "${ASCII_ONLY:-}" == "1" ]]; then
    SYMBOL_DONE="DONE"
    SYMBOL_IN_PROGRESS="PROG"
    SYMBOL_PENDING="----"
fi

if [[ ! -d "$RESULTS_DIR" ]]; then
    echo "[WARN] $RESULTS_DIR 不存在，無 Phase checkpoint 記錄" >&2
    echo "=== TCB Phase Status Grid ==="
    echo "(no subagent-results directory found)"
    echo "=== End of TCB Status ==="
    exit 0
fi

# ── 收集所有 Phase checkpoint 文件 ──
CHECKPOINT_FILES=()
while IFS= read -r -d '' f; do
    # 篩選 sprint 參數（若有）
    if [[ -n "$SPRINT_ARG" ]]; then
        sprint_in_file=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('sprint',''))" 2>/dev/null)
        if [[ "$sprint_in_file" != "$SPRINT_ARG" ]] && [[ "sprint_${sprint_in_file}" != "$SPRINT_ARG" ]]; then
            continue
        fi
    fi
    CHECKPOINT_FILES+=("$f")
done < <(find "$RESULTS_DIR" -name "*-phase-checkpoint.json" -print0 2>/dev/null | sort -z)

if [[ ${#CHECKPOINT_FILES[@]} -eq 0 ]]; then
    echo "=== TCB Phase Status Grid ==="
    if [[ -n "$SPRINT_ARG" ]]; then
        echo "(no phase checkpoints found for sprint: ${SPRINT_ARG})"
    else
        echo "(no phase checkpoints found)"
    fi
    echo "=== End of TCB Status ==="
    exit 0
fi

# ── 建立 story → phase → status 映射 ──
declare -A STORY_PHASE_STATUS
declare -A STORY_SPRINT
declare -A STORY_SESSION

for f in "${CHECKPOINT_FILES[@]}"; do
    data=$(python3 -c "
import json, sys
try:
    d = json.load(open('$f'))
    print(d.get('story','?').lstrip('#'))
    print(d.get('phase','?'))
    print(d.get('status','?'))
    print(str(d.get('sprint','')))
    print(d.get('session_id','?'))
except Exception as e:
    print('ERROR')
    print('ERROR')
    print('ERROR')
    print('')
    print('')
" 2>/dev/null)

    story_id=$(echo "$data" | sed -n '1p')
    phase=$(echo "$data" | sed -n '2p')
    status=$(echo "$data" | sed -n '3p')
    sprint_num=$(echo "$data" | sed -n '4p')
    session_id=$(echo "$data" | sed -n '5p')

    if [[ "$story_id" == "ERROR" ]]; then
        continue
    fi

    STORY_PHASE_STATUS["${story_id}:${phase}"]="$status"
    STORY_SPRINT["$story_id"]="$sprint_num"
    STORY_SESSION["$story_id"]="$session_id"
done

# ── 輸出格網 ──
SPRINT_LABEL=""
[[ -n "$SPRINT_ARG" ]] && SPRINT_LABEL=" (Sprint: ${SPRINT_ARG})"
echo "=== TCB Phase Status Grid${SPRINT_LABEL} ==="
echo ""

# Header
printf "  %-12s | %-10s | %-8s | %-14s | %-6s | %s\n" \
    "Story" "Analysis" "Design" "Implementation" "Test" "Session"
printf "  %s\n" "$(printf '%0.s─' {1..70})"

UNIQUE_STORIES=$(printf '%s\n' "${!STORY_SPRINT[@]}" | sort -n)

if [[ -z "$UNIQUE_STORIES" ]]; then
    echo "  (no stories with phase checkpoints)"
else
    for story_id in $UNIQUE_STORIES; do
        row=""
        for phase in "${PHASES[@]}"; do
            status="${STORY_PHASE_STATUS["${story_id}:${phase}"]:-}"
            case "$status" in
                "completed")   sym="$SYMBOL_DONE" ;;
                "in-progress") sym="$SYMBOL_IN_PROGRESS" ;;
                *)             sym="$SYMBOL_PENDING" ;;
            esac
            row="${row} ${sym}"
        done

        analysis_sym="${STORY_PHASE_STATUS["${story_id}:analysis"]:-}"
        design_sym="${STORY_PHASE_STATUS["${story_id}:design"]:-}"
        impl_sym="${STORY_PHASE_STATUS["${story_id}:implementation"]:-}"
        test_sym="${STORY_PHASE_STATUS["${story_id}:test"]:-}"

        fmt_phase() {
            case "$1" in "completed") echo "$SYMBOL_DONE" ;; "in-progress") echo "$SYMBOL_IN_PROGRESS" ;; *) echo "$SYMBOL_PENDING" ;; esac
        }

        sprint_label="s${STORY_SPRINT[$story_id]:-?}"
        session_short="${STORY_SESSION[$story_id]:-?}"
        session_short="${session_short:0:12}"

        printf "  #%-11s | %-10s | %-8s | %-14s | %-6s | %s\n" \
            "$story_id" \
            "$(fmt_phase "$analysis_sym")" \
            "$(fmt_phase "$design_sym")" \
            "$(fmt_phase "$impl_sym")" \
            "$(fmt_phase "$test_sym")" \
            "${sprint_label}/${session_short}"
    done
fi

echo ""
echo "Legend: ${SYMBOL_DONE}=completed  ${SYMBOL_IN_PROGRESS}=in-progress  ${SYMBOL_PENDING}=not started"
echo "=== End of TCB Status ==="
