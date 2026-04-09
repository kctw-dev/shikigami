#!/usr/bin/env bash
# step-subagent-poc.sh — Short-lived Step Subagent PoC（Story #977 AC-4）
#
# 演示如何將 task-list-init 步驟改為 short-lived subagent 派遣。
# 此 PoC 模擬 subagent 的派遣流程，不實際啟動 claude subagent，
# 而是展示 prompt 模板生成、結果回傳 JSON 契約、progress tracker 整合。
#
# 用法：
#   step-subagent-poc.sh generate-prompt <step_name> <sprint_number>
#     — 生成指定步驟的 subagent prompt 模板
#
#   step-subagent-poc.sh simulate <step_name> <sprint_number>
#     — 模擬 subagent 執行並產出結果 JSON
#
#   step-subagent-poc.sh demo <sprint_number>
#     — 完整演示：生成 prompt → 模擬執行 → 更新 progress tracker
#
# 環境變數：
#   STATE_MACHINE_DIR — 狀態檔存放目錄（預設 .state-machine/）
#   POC_OUTPUT_DIR    — PoC 輸出目錄（預設 .state-machine/poc-output/）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_MACHINE="${SCRIPT_DIR}/state-machine.sh"

STATE_DIR="${STATE_MACHINE_DIR:-.state-machine}"
POC_OUTPUT_DIR="${POC_OUTPUT_DIR:-${STATE_DIR}/poc-output}"

# ── 工具函數 ──

timestamp() {
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

timestamp_ms() {
  date +%s%N | cut -b1-13
}

# ── Prompt 模板生成 ──

generate_prompt_task_list_init() {
  local sprint_number="$1"
  local output_file="${POC_OUTPUT_DIR}/prompt-task-list-init.md"

  mkdir -p "${POC_OUTPUT_DIR}"

  cat > "${output_file}" <<'PROMPT_EOF'
# Step Subagent: task-list-init

## 規則片段

你是 Sprint Execution 的 task-list-init 步驟 subagent。你的唯一任務是初始化 Sprint 的 Task List。

### 必須遵守的規則
1. Task List 必須包含 Sprint 中所有 Story 的標題、Issue 編號、Size、Routing
2. 排序依據：依賴關係優先、RICE 分數次之
3. 每個 Story 必須有明確的驗收標準引用
4. 禁止自行增減 Story — Task List 內容必須與 Sprint Planning 結果一致

### 禁止事項
- 不可開始執行任何 Story
- 不可修改 Story 的 Size 或 Routing
- 不可跳過此步驟直接進入 Story Selection

## 輸入契約

- Sprint 編號：{sprint_number}
- Sprint Planning 結果：docs/sprints/sprint-{sprint_number}/planning.md
- Backlog：docs/sprints/backlog.md

## 輸出契約

必須產出：
- docs/sprints/sprint-{sprint_number}/task-list.md（Task List 檔案）
- {result_file}（步驟結果 JSON）

## 成功/失敗判定

成功條件：
- task-list.md 檔案存在且包含至少 1 個 Story
- 每個 Story 有 Issue 編號、標題、Size、Routing

失敗條件：
- Sprint Planning 結果檔案不存在
- task-list.md 產出後驗證失敗

遇到失敗時：寫入失敗 JSON 並結束，不嘗試自行修復。
PROMPT_EOF

  # 替換 placeholder
  sed -i "s/{sprint_number}/${sprint_number}/g" "${output_file}"
  sed -i "s|{result_file}|${POC_OUTPUT_DIR}/result-task-list-init.json|g" "${output_file}"

  echo "[PROMPT-GENERATED] ${output_file}"
}

generate_prompt() {
  local step_name="${1:?Usage: step-subagent-poc.sh generate-prompt <step_name> <sprint_number>}"
  local sprint_number="${2:?Usage: step-subagent-poc.sh generate-prompt <step_name> <sprint_number>}"

  case "${step_name}" in
    task-list-init)
      generate_prompt_task_list_init "${sprint_number}"
      ;;
    *)
      echo "[ERROR] No prompt template for step: ${step_name}" >&2
      echo "[INFO] Currently supported: task-list-init" >&2
      return 1
      ;;
  esac
}

# ── 模擬 Subagent 執行 ──

simulate_task_list_init() {
  local sprint_number="$1"
  local result_file="${POC_OUTPUT_DIR}/result-task-list-init.json"
  local start_ms end_ms duration_ms

  mkdir -p "${POC_OUTPUT_DIR}"

  start_ms=$(timestamp_ms)

  # 模擬 subagent 工作：產出 task-list.md（模擬版本）
  local task_list_file="${POC_OUTPUT_DIR}/task-list-mock.md"
  cat > "${task_list_file}" <<EOF
# Sprint ${sprint_number} Task List

| # | Issue | Title | Size | Routing |
|---|-------|-------|------|---------|
| 1 | #977 | feat: ADR-045 方向修正 | L (3pts) | opus |

Generated at: $(timestamp)
EOF

  end_ms=$(timestamp_ms)
  duration_ms=$((end_ms - start_ms))

  # 產出結果 JSON（符合 ADR-045 定義的契約）
  cat > "${result_file}" <<EOF
{
  "step_name": "task-list-init",
  "status": "completed",
  "output_artifacts": [
    "${task_list_file}"
  ],
  "duration_ms": ${duration_ms},
  "error": null
}
EOF

  echo "[SIMULATE-OK] task-list-init completed in ${duration_ms}ms"
  echo "[RESULT] ${result_file}"
}

simulate() {
  local step_name="${1:?Usage: step-subagent-poc.sh simulate <step_name> <sprint_number>}"
  local sprint_number="${2:?Usage: step-subagent-poc.sh simulate <step_name> <sprint_number>}"

  case "${step_name}" in
    task-list-init)
      simulate_task_list_init "${sprint_number}"
      ;;
    *)
      echo "[ERROR] No simulation for step: ${step_name}" >&2
      return 1
      ;;
  esac
}

# ── 完整 Demo ──

demo() {
  local sprint_number="${1:?Usage: step-subagent-poc.sh demo <sprint_number>}"

  echo "=== Step Subagent PoC Demo (Sprint ${sprint_number}) ==="
  echo ""

  # Step 1: 初始化 progress tracker
  echo "--- Step 1: Initialize progress tracker ---"
  bash "${STATE_MACHINE}" init "${sprint_number}"
  echo ""

  # Step 2: 查詢目前進度
  echo "--- Step 2: Check current progress ---"
  bash "${STATE_MACHINE}" check task-list-init
  echo ""

  # Step 3: 生成 prompt 模板
  echo "--- Step 3: Generate prompt template ---"
  generate_prompt "task-list-init" "${sprint_number}"
  echo ""

  # Step 4: 模擬 subagent 執行
  echo "--- Step 4: Simulate subagent execution ---"
  simulate "task-list-init" "${sprint_number}"
  echo ""

  # Step 5: 驗證結果 JSON
  echo "--- Step 5: Validate result JSON ---"
  local result_file="${POC_OUTPUT_DIR}/result-task-list-init.json"
  if [[ -f "${result_file}" ]]; then
    local result_status
    result_status=$(jq -r '.status' "${result_file}")
    if [[ "${result_status}" == "completed" ]]; then
      echo "[VALIDATE-OK] Result status: completed"

      # 驗證 output_artifacts 存在
      local artifacts_ok=true
      while IFS= read -r artifact; do
        if [[ ! -f "${artifact}" ]]; then
          echo "[VALIDATE-FAIL] Missing artifact: ${artifact}"
          artifacts_ok=false
        fi
      done < <(jq -r '.output_artifacts[]' "${result_file}")

      if [[ "${artifacts_ok}" == "true" ]]; then
        echo "[VALIDATE-OK] All output artifacts exist"
      fi
    else
      echo "[VALIDATE-FAIL] Result status: ${result_status}"
    fi
  else
    echo "[VALIDATE-FAIL] Result file not found: ${result_file}"
  fi
  echo ""

  # Step 6: 更新 progress tracker
  echo "--- Step 6: Update progress tracker ---"
  bash "${STATE_MACHINE}" complete task-list-init
  echo ""

  # Step 7: 查詢最終進度
  echo "--- Step 7: Final progress ---"
  bash "${STATE_MACHINE}" status
  echo ""

  echo "=== PoC Demo Complete ==="
}

# ── 主入口 ──

main() {
  local cmd="${1:-help}"
  shift || true

  case "${cmd}" in
    generate-prompt) generate_prompt "$@" ;;
    simulate)        simulate "$@" ;;
    demo)            demo "$@" ;;
    *)
      echo "Usage: step-subagent-poc.sh {generate-prompt|simulate|demo} [args...]" >&2
      echo ""
      echo "Commands:"
      echo "  generate-prompt <step_name> <sprint_number>  Generate subagent prompt template"
      echo "  simulate <step_name> <sprint_number>         Simulate subagent execution"
      echo "  demo <sprint_number>                         Run full demo flow"
      return 1
      ;;
  esac
}

main "$@"
