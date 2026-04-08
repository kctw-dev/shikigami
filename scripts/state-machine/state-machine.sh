#!/usr/bin/env bash
# state-machine.sh — Sprint Execution 外部狀態機 PoC（Story #962）
#
# 用法：
#   state-machine.sh init <sprint_number>     初始化狀態檔（冪等）
#   state-machine.sh gate <step_name>         檢查 gate 條件（前置步驟完成？）
#   state-machine.sh complete <step_name>     標記步驟完成
#   state-machine.sh fail <step_name> [reason] 標記步驟失敗
#   state-machine.sh status                   輸出目前狀態摘要
#
# 環境變數：
#   STATE_MACHINE_DIR — 狀態檔存放目錄（預設 .state-machine/）
#
# NFR1: 向後相容 — 新目錄隔離
# NFR2: 可觀測 log — 含 step_name、exit_code、失敗原因
# NFR3: 執行時間 < 1s
# NFR4: 冪等重入 — 重新執行時跳過已完成步驟
set -euo pipefail

# ── 常數 ──

STEPS_ORDERED=("task-list-init" "checkpoint-detection" "issue-ci-scan")

# step -> predecessor mapping
declare -A STEP_PREDECESSOR=(
  ["task-list-init"]=""
  ["checkpoint-detection"]="task-list-init"
  ["issue-ci-scan"]="checkpoint-detection"
)

# ── 路徑 ──

STATE_DIR="${STATE_MACHINE_DIR:-.state-machine}"
STATE_FILE="${STATE_DIR}/sprint-execution-state.json"
LOG_FILE="${STATE_DIR}/state-machine.log"

# ── 工具函數 ──

timestamp() {
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

log_entry() {
  local step_name="$1" action="$2" exit_code="${3:-0}" reason="${4:-}"
  local ts
  ts=$(timestamp)
  printf '{"timestamp":"%s","step_name":"%s","action":"%s","exit_code":%d' \
    "${ts}" "${step_name}" "${action}" "${exit_code}" >> "${LOG_FILE}"
  if [[ -n "${reason}" ]]; then
    printf ',"failure_reason":"%s"' "${reason}" >> "${LOG_FILE}"
  fi
  printf '}\n' >> "${LOG_FILE}"
}

is_valid_step() {
  local step="$1"
  for s in "${STEPS_ORDERED[@]}"; do
    if [[ "${s}" == "${step}" ]]; then
      return 0
    fi
  done
  return 1
}

get_step_status() {
  local step="$1"
  jq -r --arg s "${step}" '.steps[$s].status' "${STATE_FILE}"
}

# ── 指令：init ──

cmd_init() {
  local sprint_number="${1:?Usage: state-machine.sh init <sprint_number>}"

  mkdir -p "${STATE_DIR}"

  # 冪等重入（NFR4）：若狀態檔已存在，保留已完成步驟
  if [[ -f "${STATE_FILE}" ]]; then
    local existing_sprint
    existing_sprint=$(jq -r '.sprint_number' "${STATE_FILE}")
    if [[ "${existing_sprint}" == "${sprint_number}" ]]; then
      # 同 sprint，保留已完成步驟，只補 pending 的缺失步驟
      local tmp
      tmp=$(mktemp)
      jq --arg ts "$(timestamp)" '.last_updated = $ts' "${STATE_FILE}" > "${tmp}"
      mv "${tmp}" "${STATE_FILE}"
      log_entry "init" "re-init" 0 "sprint ${sprint_number} state preserved"
      return 0
    fi
  fi

  # 全新初始化
  local ts
  ts=$(timestamp)
  cat > "${STATE_FILE}" <<EOF
{
  "sprint_number": ${sprint_number},
  "steps": {
    "task-list-init": { "status": "pending", "completed_at": null, "exit_code": null },
    "checkpoint-detection": { "status": "pending", "completed_at": null, "exit_code": null },
    "issue-ci-scan": { "status": "pending", "completed_at": null, "exit_code": null }
  },
  "last_updated": "${ts}"
}
EOF

  log_entry "init" "init" 0 "sprint ${sprint_number}"
}

# ── 指令：gate ──

cmd_gate() {
  local step="${1:?Usage: state-machine.sh gate <step_name>}"

  if ! is_valid_step "${step}"; then
    log_entry "${step}" "gate" 1 "unknown step"
    echo "[GATE-FAIL] Unknown step: ${step}" >&2
    return 1
  fi

  if [[ ! -f "${STATE_FILE}" ]]; then
    log_entry "${step}" "gate" 1 "state file not found"
    echo "[GATE-FAIL] State file not found. Run 'init' first." >&2
    return 1
  fi

  local predecessor="${STEP_PREDECESSOR[${step}]}"

  # 無前置依賴 → 直接放行
  if [[ -z "${predecessor}" ]]; then
    log_entry "${step}" "gate" 0
    echo "[GATE-PASS] ${step} — no predecessor required"
    return 0
  fi

  # 檢查前置步驟狀態
  local pred_status
  pred_status=$(get_step_status "${predecessor}")

  if [[ "${pred_status}" == "completed" ]]; then
    log_entry "${step}" "gate" 0
    echo "[GATE-PASS] ${step} — predecessor '${predecessor}' completed"
    return 0
  else
    log_entry "${step}" "gate" 1 "predecessor '${predecessor}' status=${pred_status}"
    echo "[GATE-FAIL] ${step} — predecessor '${predecessor}' status=${pred_status} (need completed)" >&2
    return 1
  fi
}

# ── 指令：complete ──

cmd_complete() {
  local step="${1:?Usage: state-machine.sh complete <step_name>}"

  if ! is_valid_step "${step}"; then
    log_entry "${step}" "complete" 1 "unknown step"
    echo "[COMPLETE-FAIL] Unknown step: ${step}" >&2
    return 1
  fi

  if [[ ! -f "${STATE_FILE}" ]]; then
    log_entry "${step}" "complete" 1 "state file not found"
    echo "[COMPLETE-FAIL] State file not found." >&2
    return 1
  fi

  # 冪等重入（NFR4）：已完成的步驟不覆蓋
  local current_status
  current_status=$(get_step_status "${step}")
  if [[ "${current_status}" == "completed" ]]; then
    log_entry "${step}" "complete" 0 "already completed (idempotent skip)"
    echo "[COMPLETE-SKIP] ${step} — already completed (idempotent)"
    return 0
  fi

  local ts
  ts=$(timestamp)
  local tmp
  tmp=$(mktemp)
  jq --arg s "${step}" --arg ts "${ts}" \
    '.steps[$s].status = "completed" | .steps[$s].completed_at = $ts | .steps[$s].exit_code = 0 | .last_updated = $ts' \
    "${STATE_FILE}" > "${tmp}"
  mv "${tmp}" "${STATE_FILE}"

  log_entry "${step}" "complete" 0
  echo "[COMPLETE-OK] ${step}"
}

# ── 指令：fail ──

cmd_fail() {
  local step="${1:?Usage: state-machine.sh fail <step_name> [reason]}"
  local reason="${2:-unknown}"

  if ! is_valid_step "${step}"; then
    log_entry "${step}" "fail" 1 "unknown step"
    echo "[FAIL-ERROR] Unknown step: ${step}" >&2
    return 1
  fi

  if [[ ! -f "${STATE_FILE}" ]]; then
    log_entry "${step}" "fail" 1 "state file not found"
    echo "[FAIL-ERROR] State file not found." >&2
    return 1
  fi

  local ts
  ts=$(timestamp)
  local tmp
  tmp=$(mktemp)
  jq --arg s "${step}" --arg ts "${ts}" --arg r "${reason}" \
    '.steps[$s].status = "failed" | .steps[$s].completed_at = $ts | .steps[$s].exit_code = 1 | .steps[$s].failure_reason = $r | .last_updated = $ts' \
    "${STATE_FILE}" > "${tmp}"
  mv "${tmp}" "${STATE_FILE}"

  log_entry "${step}" "fail" 1 "${reason}"
  echo "[FAIL-RECORDED] ${step} — reason: ${reason}"
}

# ── 指令：status ──

cmd_status() {
  if [[ ! -f "${STATE_FILE}" ]]; then
    echo "[STATUS] No state file found."
    return 0
  fi

  local sprint_num
  sprint_num=$(jq -r '.sprint_number' "${STATE_FILE}")
  echo "=== Sprint ${sprint_num} Execution State ==="

  for step in "${STEPS_ORDERED[@]}"; do
    local status completed_at
    status=$(jq -r --arg s "${step}" '.steps[$s].status' "${STATE_FILE}")
    completed_at=$(jq -r --arg s "${step}" '.steps[$s].completed_at // "—"' "${STATE_FILE}")
    printf "  %-25s %s  (at: %s)\n" "${step}" "${status}" "${completed_at}"
  done

  local last_updated
  last_updated=$(jq -r '.last_updated' "${STATE_FILE}")
  echo "  Last updated: ${last_updated}"
}

# ── 主入口 ──

main() {
  local cmd="${1:-help}"
  shift || true

  case "${cmd}" in
    init)     cmd_init "$@" ;;
    gate)     cmd_gate "$@" ;;
    complete) cmd_complete "$@" ;;
    fail)     cmd_fail "$@" ;;
    status)   cmd_status "$@" ;;
    *)
      echo "Usage: state-machine.sh {init|gate|complete|fail|status} [args...]" >&2
      return 1
      ;;
  esac
}

main "$@"
