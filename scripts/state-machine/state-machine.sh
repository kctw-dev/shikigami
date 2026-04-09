#!/usr/bin/env bash
# state-machine.sh — Sprint Execution Progress Tracker（Story #962 → #977 修訂）
#
# 角色：Progress Tracker（記錄進度，不驅動流程）
# 修訂：#977 將 gate 驅動邏輯移除，降級為純 progress tracker
#
# 用法：
#   state-machine.sh init <sprint_number>       初始化進度檔（冪等）
#   state-machine.sh check <step_name>          查詢步驟狀態（純 query，不 block）
#   state-machine.sh complete <step_name>       標記步驟完成
#   state-machine.sh fail <step_name> [reason]  標記步驟失敗
#   state-machine.sh status                     輸出目前進度摘要
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

# ── 指令：check（純 status query，不 block）──

cmd_check() {
  local step="${1:?Usage: state-machine.sh check <step_name>}"

  if ! is_valid_step "${step}"; then
    log_entry "${step}" "check" 1 "unknown step"
    echo "[CHECK-FAIL] Unknown step: ${step}" >&2
    return 1
  fi

  if [[ ! -f "${STATE_FILE}" ]]; then
    log_entry "${step}" "check" 1 "state file not found"
    echo "[CHECK-FAIL] State file not found. Run 'init' first." >&2
    return 1
  fi

  local step_status
  step_status=$(get_step_status "${step}")

  log_entry "${step}" "check" 0
  echo "[CHECK] ${step} — status: ${step_status}"
  # 輸出 JSON 格式供程式解析
  jq -c --arg s "${step}" '{step: $s, status: .steps[$s].status, completed_at: .steps[$s].completed_at}' "${STATE_FILE}"
  return 0
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
  echo "=== Sprint ${sprint_num} Execution Progress ==="

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
    check)    cmd_check "$@" ;;
    complete) cmd_complete "$@" ;;
    fail)     cmd_fail "$@" ;;
    status)   cmd_status "$@" ;;
    # 向後相容：gate 別名指向 check（已棄用，印警告）
    gate)
      echo "[DEPRECATED] 'gate' command is deprecated. Use 'check' instead." >&2
      cmd_check "$@"
      ;;
    *)
      echo "Usage: state-machine.sh {init|check|complete|fail|status} [args...]" >&2
      return 1
      ;;
  esac
}

main "$@"
