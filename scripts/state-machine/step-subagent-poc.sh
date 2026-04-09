#!/usr/bin/env bash
# step-subagent-poc.sh — Short-lived Step Subagent PoC（Story #977 AC-4 / #983 AC-1）
#
# 演示如何將 task-list-init 步驟改為 short-lived subagent 派遣。
# 支援兩種執行模式：
#   --mode=simulate（預設）：模擬 subagent 執行，不實際啟動 claude subagent
#   --mode=dispatch：真實派遣 short-lived subagent（Story #983 AC-1）
#
# 用法：
#   step-subagent-poc.sh generate-prompt <step_name> <sprint_number>
#     — 生成指定步驟的 subagent prompt 模板
#
#   step-subagent-poc.sh simulate <step_name> <sprint_number>
#     — 模擬 subagent 執行並產出結果 JSON
#
#   step-subagent-poc.sh dispatch <step_name> <sprint_number>
#     — 真實派遣 short-lived subagent（需要 claude CLI 可用）
#
#   step-subagent-poc.sh demo <sprint_number> [--mode=simulate|dispatch]
#     — 完整演示：生成 prompt → 執行（模擬/真實）→ 更新 progress tracker
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

# ── 真實派遣 Subagent（#983 AC-1 dispatch 模式）──

dispatch_task_list_init() {
  local sprint_number="$1"
  local result_file="${POC_OUTPUT_DIR}/result-task-list-init.json"
  local start_ms end_ms duration_ms

  mkdir -p "${POC_OUTPUT_DIR}"

  # 1. 生成 prompt 模板
  generate_prompt_task_list_init "${sprint_number}"
  local prompt_file="${POC_OUTPUT_DIR}/prompt-task-list-init.md"

  start_ms=$(timestamp_ms)

  # 2. 量測規則佔比（AC-2 整合）
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local measure_script="${script_dir}/rule-ratio-measure.sh"
  if [[ -x "${measure_script}" ]]; then
    local ratio_result
    ratio_result=$(bash "${measure_script}" "${prompt_file}" 2>/dev/null || echo '{"rule_tokens":0,"total_tokens":0,"ratio":0,"passed":false}')
    local ratio_passed
    ratio_passed=$(echo "${ratio_result}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['passed'])" 2>/dev/null || echo "False")
    if [[ "${ratio_passed}" == "True" ]]; then
      echo "[RULE-RATIO-PASS] 規則佔比達標（>= 10%）"
    else
      local ratio_val
      ratio_val=$(echo "${ratio_result}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['ratio'])" 2>/dev/null || echo "0")
      echo "[RULE-RATIO-WARN] 規則佔比 ${ratio_val} < 10%，建議增加規則內容" >&2
    fi
  fi

  # 3. 檢查 claude CLI 是否可用
  if command -v claude &>/dev/null; then
    echo "[DISPATCH-MODE] claude CLI 可用，準備真實派遣 short-lived subagent..."
    echo "[DISPATCH-PROMPT] 使用 prompt: ${prompt_file}"
    echo ""
    echo "--- subagent prompt preview ---"
    head -20 "${prompt_file}"
    echo "--- (end of preview) ---"
    echo ""
    echo "[DISPATCH-INFO] 真實派遣需要在主 session 使用 Agent tool 執行以下 prompt："
    echo "[DISPATCH-INFO] 請主 session 讀取 ${prompt_file} 並使用 Agent tool 派遣"
    echo "[DISPATCH-INFO] 結果 JSON 應寫入 ${result_file}"
    echo ""
    # 注意：此腳本不直接呼叫 claude CLI 啟動 subagent，
    # 因為 short-lived subagent 應由主 session 的 Agent tool 派遣。
    # 此 dispatch 模式的職責是：生成 prompt、量測規則佔比、指引主 session 派遣。
    echo "[DISPATCH-READY] prompt 已就緒，等待主 session 使用 Agent tool 派遣"
  else
    echo "[DISPATCH-FALLBACK] claude CLI 不可用，降級為 simulate 模式" >&2
    simulate_task_list_init "${sprint_number}"
    return
  fi

  end_ms=$(timestamp_ms)
  duration_ms=$((end_ms - start_ms))

  # 4. 產出 dispatch 結果 JSON（記錄派遣準備狀態）
  cat > "${result_file}" <<EOF
{
  "step_name": "task-list-init",
  "status": "dispatch_ready",
  "mode": "dispatch",
  "prompt_file": "${prompt_file}",
  "output_artifacts": [],
  "duration_ms": ${duration_ms},
  "error": null,
  "note": "Prompt generated and ready for Agent tool dispatch by main session"
}
EOF

  echo "[DISPATCH-OK] task-list-init dispatch preparation completed in ${duration_ms}ms"
  echo "[RESULT] ${result_file}"
}

dispatch() {
  local step_name="${1:?Usage: step-subagent-poc.sh dispatch <step_name> <sprint_number>}"
  local sprint_number="${2:?Usage: step-subagent-poc.sh dispatch <step_name> <sprint_number>}"

  case "${step_name}" in
    task-list-init)
      dispatch_task_list_init "${sprint_number}"
      ;;
    *)
      echo "[ERROR] No dispatch implementation for step: ${step_name}" >&2
      echo "[INFO] Currently supported: task-list-init" >&2
      return 1
      ;;
  esac
}

# ── 完整 Demo ──

demo() {
  local sprint_number="${1:?Usage: step-subagent-poc.sh demo <sprint_number>}"
  local mode="simulate"

  # 解析 --mode 旗標
  shift || true
  for arg in "$@"; do
    case "${arg}" in
      --mode=simulate) mode="simulate" ;;
      --mode=dispatch) mode="dispatch" ;;
      *) echo "[WARN] Unknown argument: ${arg}" >&2 ;;
    esac
  done

  echo "=== Step Subagent PoC Demo (Sprint ${sprint_number}, mode=${mode}) ==="
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

  # Step 4: 執行（模擬 or 真實派遣）
  if [[ "${mode}" == "dispatch" ]]; then
    echo "--- Step 4: Dispatch real subagent (--mode=dispatch) ---"
    dispatch "task-list-init" "${sprint_number}"
  else
    echo "--- Step 4: Simulate subagent execution (--mode=simulate) ---"
    simulate "task-list-init" "${sprint_number}"
  fi
  echo ""

  # Step 5: 驗證結果 JSON
  echo "--- Step 5: Validate result JSON ---"
  local result_file="${POC_OUTPUT_DIR}/result-task-list-init.json"
  if [[ -f "${result_file}" ]]; then
    local result_status
    result_status=$(jq -r '.status' "${result_file}")
    if [[ "${result_status}" == "completed" || "${result_status}" == "dispatch_ready" ]]; then
      echo "[VALIDATE-OK] Result status: ${result_status}"

      if [[ "${result_status}" == "completed" ]]; then
        # 驗證 output_artifacts 存在
        local artifacts_ok=true
        while IFS= read -r artifact; do
          if [[ ! -f "${artifact}" ]]; then
            echo "[VALIDATE-FAIL] Missing artifact: ${artifact}"
            artifacts_ok=false
          fi
        done < <(jq -r '.output_artifacts[]' "${result_file}" 2>/dev/null || true)

        if [[ "${artifacts_ok}" == "true" ]]; then
          echo "[VALIDATE-OK] All output artifacts exist"
        fi
      fi
    else
      echo "[VALIDATE-FAIL] Result status: ${result_status}"
    fi
  else
    echo "[VALIDATE-FAIL] Result file not found: ${result_file}"
  fi
  echo ""

  # Step 6: 更新 progress tracker（simulate 模式才更新為 completed）
  echo "--- Step 6: Update progress tracker ---"
  if [[ "${mode}" == "simulate" ]]; then
    bash "${STATE_MACHINE}" complete task-list-init
  else
    echo "[DISPATCH-MODE] 真實派遣模式：progress tracker 待主 session 確認 subagent 完成後更新"
  fi
  echo ""

  # Step 7: 查詢最終進度
  echo "--- Step 7: Final progress ---"
  bash "${STATE_MACHINE}" status
  echo ""

  echo "=== PoC Demo Complete (mode=${mode}) ==="
}

# ── 主入口 ──

main() {
  local cmd="${1:-help}"
  shift || true

  case "${cmd}" in
    generate-prompt) generate_prompt "$@" ;;
    simulate)        simulate "$@" ;;
    dispatch)        dispatch "$@" ;;
    demo)            demo "$@" ;;
    *)
      echo "Usage: step-subagent-poc.sh {generate-prompt|simulate|dispatch|demo} [args...]" >&2
      echo ""
      echo "Commands:"
      echo "  generate-prompt <step_name> <sprint_number>         Generate subagent prompt template"
      echo "  simulate <step_name> <sprint_number>                Simulate subagent execution (--mode=simulate)"
      echo "  dispatch <step_name> <sprint_number>                Real subagent dispatch preparation (--mode=dispatch)"
      echo "  demo <sprint_number> [--mode=simulate|dispatch]     Run full demo flow"
      echo ""
      echo "Modes:"
      echo "  --mode=simulate  (default) Mock execution, no real subagent spawned"
      echo "  --mode=dispatch  Prepare prompt and guide main session to dispatch via Agent tool"
      return 1
      ;;
  esac
}

main "$@"
