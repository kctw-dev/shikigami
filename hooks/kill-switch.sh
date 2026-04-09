#!/usr/bin/env bash
# kill-switch.sh — Kill Switch 緊急停止機制（ADR-038）
#
# 用途：建立/檢查/報告 Kill Switch flag 與 Emergency Stop Report
# 設計原則：不依賴 LLM 執行，純 shell + file-based，在 LLM 失控時仍有效
#
# 子命令：
#   trigger {session_id} [--source manual|security-critical|timeout] [--by stakeholder|security-agent|cron]
#       建立 kill-switch flag，廣播停止訊號
#   check {session_id}
#       查詢 flag 是否存在（subagent polling 使用）
#       exit 0 = flag 存在（應停止），exit 1 = flag 不存在（繼續執行）
#   report {session_id}
#       產出 Emergency Stop Report（.kill-switch/{session_id}-report.json）
#   clear {session_id}
#       清除 flag（正常完成後清理）
#   list
#       列出所有當前 active 的 kill-switch flags
#
# Story: #398 Sprint 138
# ADR: docs/adr/ADR-038-kill-switch-design.md
#
# ─── Spike #955 Assessment (2026-04-09) ───────────────────────────────────────
# Timeout Protection: NOT NEEDED
# Rationale: The `clear` operation (used in SessionEnd) is trivial (file deletion
#            only, < 1ms execution time). Already protected by async=true in
#            hooks.json. No risk of hanging. Migration to hook-runner.sh would add
#            complexity without safety benefit. Recommended: keep inline async.
# See: docs/km/spike-955-kill-switch-assessment.md

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
KILL_SWITCH_DIR="${REPO_ROOT}/.kill-switch"

# 確保目錄存在
mkdir -p "${KILL_SWITCH_DIR}"

COMMAND="${1:-help}"
SESSION_ID="${2:-}"

case "${COMMAND}" in
  trigger)
    # 解析可選參數
    TRIGGER_SOURCE="manual"
    TRIGGERED_BY="stakeholder"
    shift 2 2>/dev/null || true
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --source) TRIGGER_SOURCE="$2"; shift 2 ;;
        --by) TRIGGERED_BY="$2"; shift 2 ;;
        *) shift ;;
      esac
    done

    if [[ -z "${SESSION_ID}" ]]; then
      echo "[KILL-SWITCH-ERROR] Usage: kill-switch.sh trigger {session_id} [--source manual|security-critical|timeout] [--by stakeholder|security-agent|cron]"
      exit 1
    fi

    FLAG_PATH="${KILL_SWITCH_DIR}/${SESSION_ID}.flag"
    TRIGGERED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    # 寫入 flag（JSON 格式，ADR-038 決策 1）
    cat > "${FLAG_PATH}" << FLAG_JSON
{
  "triggered_at": "${TRIGGERED_AT}",
  "trigger_source": "${TRIGGER_SOURCE}",
  "session_id": "${SESSION_ID}",
  "triggered_by": "${TRIGGERED_BY}"
}
FLAG_JSON

    echo "[KILL-SWITCH-TRIGGERED] session=${SESSION_ID} source=${TRIGGER_SOURCE} by=${TRIGGERED_BY} at=${TRIGGERED_AT}"
    echo "[KILL-SWITCH-TRIGGERED] Flag path: ${FLAG_PATH}"
    ;;

  check)
    if [[ -z "${SESSION_ID}" ]]; then
      echo "[KILL-SWITCH-ERROR] Usage: kill-switch.sh check {session_id}"
      exit 1
    fi

    FLAG_PATH="${KILL_SWITCH_DIR}/${SESSION_ID}.flag"

    if [[ -f "${FLAG_PATH}" ]]; then
      # Flag exists — kill switch triggered
      TRIGGERED_AT=$(python3 -c "import json; d=json.load(open('${FLAG_PATH}')); print(d.get('triggered_at','unknown'))" 2>/dev/null || echo "unknown")
      TRIGGER_SOURCE=$(python3 -c "import json; d=json.load(open('${FLAG_PATH}')); print(d.get('trigger_source','unknown'))" 2>/dev/null || echo "unknown")
      echo "[KILL-SWITCH-ACTIVE] session=${SESSION_ID} triggered_at=${TRIGGERED_AT} source=${TRIGGER_SOURCE}"
      exit 0  # exit 0 = flag exists = STOP
    else
      # No flag — continue execution
      echo "[KILL-SWITCH-CLEAR] session=${SESSION_ID} no flag found, continue execution"
      exit 1  # exit 1 = no flag = CONTINUE
    fi
    ;;

  report)
    if [[ -z "${SESSION_ID}" ]]; then
      echo "[KILL-SWITCH-ERROR] Usage: kill-switch.sh report {session_id}"
      exit 1
    fi

    FLAG_PATH="${KILL_SWITCH_DIR}/${SESSION_ID}.flag"
    REPORT_PATH="${KILL_SWITCH_DIR}/${SESSION_ID}-report.json"

    if [[ ! -f "${FLAG_PATH}" ]]; then
      echo "[KILL-SWITCH-ERROR] No flag found for session ${SESSION_ID}. Use 'trigger' first."
      exit 1
    fi

    # 讀取 flag 資訊
    TRIGGERED_AT=$(python3 -c "import json; d=json.load(open('${FLAG_PATH}')); print(d.get('triggered_at','unknown'))" 2>/dev/null || echo "unknown")
    TRIGGER_SOURCE=$(python3 -c "import json; d=json.load(open('${FLAG_PATH}')); print(d.get('trigger_source','unknown'))" 2>/dev/null || echo "unknown")

    # 產出 Emergency Stop Report（ADR-038 決策 3）
    # stories_status 從 sprint-checkpoint.json 取得（若存在）
    CHECKPOINT_FILE="${REPO_ROOT}/docs/sprints/sprint-checkpoint.json"
    if [[ -f "${CHECKPOINT_FILE}" ]]; then
      STORIES_STATUS=$(python3 -c "
import json
d = json.load(open('${CHECKPOINT_FILE}'))
stories = d.get('stories', [])
result = []
for s in stories:
    result.append({
        'story_id': s.get('id', '?'),
        'status': 'completed' if s.get('status') == 'completed' else 'in-progress-stopped',
        'last_action': 'last known action from checkpoint',
        'pr': s.get('pr')
    })
print(json.dumps(result, ensure_ascii=False, indent=2))
" 2>/dev/null || echo "[]")
    else
      STORIES_STATUS="[]"
    fi

    cat > "${REPORT_PATH}" << REPORT_JSON
{
  "session_id": "${SESSION_ID}",
  "triggered_at": "${TRIGGERED_AT}",
  "trigger_source": "${TRIGGER_SOURCE}",
  "report_generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "stories_status": ${STORIES_STATUS},
  "snapshot_path": ".kill-switch/${SESSION_ID}-snapshot/",
  "resume_possible": true,
  "notes": "Kill Switch triggered. Worktree states preserved. Manual review required before resuming."
}
REPORT_JSON

    echo "[KILL-SWITCH-REPORT] Report generated: ${REPORT_PATH}"
    cat "${REPORT_PATH}"
    ;;

  clear)
    if [[ -z "${SESSION_ID}" ]]; then
      echo "[KILL-SWITCH-ERROR] Usage: kill-switch.sh clear {session_id}"
      exit 1
    fi

    FLAG_PATH="${KILL_SWITCH_DIR}/${SESSION_ID}.flag"

    if [[ -f "${FLAG_PATH}" ]]; then
      rm "${FLAG_PATH}"
      echo "[KILL-SWITCH-CLEARED] session=${SESSION_ID} flag removed"
    else
      echo "[KILL-SWITCH-CLEAR] session=${SESSION_ID} no flag to clear"
    fi
    ;;

  list)
    echo "[KILL-SWITCH-LIST] Active kill-switch flags:"
    if ls "${KILL_SWITCH_DIR}"/*.flag 2>/dev/null | head -20; then
      :
    else
      echo "  (none)"
    fi
    ;;

  help|*)
    cat << HELP
kill-switch.sh — Kill Switch 緊急停止機制（ADR-038）

Usage:
  kill-switch.sh trigger {session_id} [--source manual|security-critical|timeout] [--by stakeholder|security-agent|cron]
  kill-switch.sh check {session_id}       # exit 0=stop, exit 1=continue
  kill-switch.sh report {session_id}      # 產出 Emergency Stop Report
  kill-switch.sh clear {session_id}       # 清除 flag
  kill-switch.sh list                     # 列出所有 active flags

Flag path: .kill-switch/{session_id}.flag
Report path: .kill-switch/{session_id}-report.json
HELP
    ;;
esac
