#!/usr/bin/env bash
# scripts/cli-adapter.sh
# US-167：多模型 CLI 路由 Phase 1 — Adapter 介面
#
# 提供統一的 CLI adapter 呼叫函式，支援 Claude 與 Gemini CLI 切換。
#
# 使用方式（source 後呼叫）：
#   source "$(dirname "$0")/../scripts/cli-adapter.sh"
#   invoke_cli_adapter [provider] [prompt]
#
# 環境變數：
#   SHIKIGAMI_MODEL_PROVIDER  指定 provider（預設: claude）
#                             可選值: claude | gemini
#
# prompt-in 格式：
#   - 短 prompt：透過第二個引數傳入（內部使用 -p 旗標）
#   - 長 prompt：透過 stdin 管道傳入
#
# result-out 格式：
#   - stdout：模型回應純文字（預設）
#   - 若 Gemini 使用 --output-format json，自動提取 .response 欄位
#
# fallback 策略：
#   - Gemini CLI 呼叫失敗（exit code != 0）時自動 fallback 回 Claude
#   - 失敗原因記錄至 stderr

# ---------------------------------------------------------------------------
# 常數定義
# ---------------------------------------------------------------------------

readonly CLI_ADAPTER_DEFAULT_PROVIDER="claude"
readonly CLI_ADAPTER_VERSION="1.0.0"

# ---------------------------------------------------------------------------
# 內部工具函式
# ---------------------------------------------------------------------------

# _cli_adapter_log_error：記錄錯誤至 stderr
# 參數：$1 = 錯誤訊息
_cli_adapter_log_error() {
  echo "[cli-adapter] ERROR: $1" >&2
}

# _cli_adapter_log_info：記錄資訊至 stderr
# 參數：$1 = 資訊訊息
_cli_adapter_log_info() {
  echo "[cli-adapter] INFO: $1" >&2
}

# ---------------------------------------------------------------------------
# Provider 實作
# ---------------------------------------------------------------------------

# _invoke_claude：呼叫 Claude CLI
# 參數：$1 = prompt（空字串時從 stdin 讀取）
# 回傳：stdout = 模型回應；exit code 0 = 成功，非 0 = 失敗
_invoke_claude() {
  local prompt="$1"
  if [[ -n "${prompt}" ]]; then
    claude -p "${prompt}"
  else
    claude  # 從 stdin 讀取
  fi
}

# _invoke_gemini：呼叫 Gemini CLI
# 設計依據 GEMINI_CLI_INVESTIGATION.md：
#   - 統一使用 stdin pipe 傳遞 prompt（避免 OS ARG_MAX 與多位元組字元問題）
#   - 使用 --output-format json 取得乾淨的 .response 欄位
#   - 監控 exit code 以偵測失敗；jq 不可用時輸出原始 JSON
# 參數：$1 = prompt（空字串時從 stdin 讀取）
# 回傳：stdout = 模型回應純文字；exit code 0 = 成功，非 0 = 失敗
_invoke_gemini() {
  local prompt="$1"
  local raw_output

  # 統一使用 stdin pipe：若有 prompt 引數則 echo，否則直接從 stdin 讀取
  if [[ -n "${prompt}" ]]; then
    raw_output=$(echo "${prompt}" | gemini --output-format json 2>/dev/null)
  else
    raw_output=$(gemini --output-format json 2>/dev/null)
  fi
  local exit_code=$?

  [[ "${exit_code}" -ne 0 ]] && return "${exit_code}"

  # 從 JSON 輸出提取 .response 欄位（jq 不可用時降級輸出原始 JSON）
  if command -v jq &>/dev/null; then
    echo "${raw_output}" | jq -r '.response // empty'
  else
    echo "${raw_output}"
  fi
}

# ---------------------------------------------------------------------------
# 主要介面函式
# ---------------------------------------------------------------------------

# invoke_cli_adapter：統一的 CLI adapter 呼叫入口
#
# 語法：
#   invoke_cli_adapter [provider] [prompt]
#
# 參數：
#   provider  CLI provider（claude | gemini）
#             空字串時讀取 SHIKIGAMI_MODEL_PROVIDER 環境變數
#             環境變數也未設定時預設使用 claude
#   prompt    傳給模型的 prompt 內容
#             空字串時從 stdin 讀取（適合長 prompt 或管道輸入）
#
# 環境變數：
#   SHIKIGAMI_MODEL_PROVIDER  覆蓋 provider 引數的預設值（仍可被引數覆蓋）
#
# 回傳：
#   stdout    模型回應純文字
#   stderr    錯誤訊息與 fallback 記錄
#   exit code 0 = 成功（含 fallback 後成功），1 = 完全失敗
#
# 範例：
#   # 使用預設 provider（claude）
#   invoke_cli_adapter "" "請解釋 TDD 是什麼"
#
#   # 明確指定 gemini
#   invoke_cli_adapter "gemini" "Summarize this file"
#
#   # 透過環境變數切換
#   SHIKIGAMI_MODEL_PROVIDER=gemini invoke_cli_adapter "" "your prompt"
#
#   # stdin 管道輸入（長 prompt）
#   cat long-prompt.txt | invoke_cli_adapter "" ""
invoke_cli_adapter() {
  local provider="${1:-}"
  local prompt="${2:-}"

  # 決定實際使用的 provider
  # 優先順序：引數 > 環境變數 > 預設值（claude）
  if [[ -z "${provider}" ]]; then
    provider="${SHIKIGAMI_MODEL_PROVIDER:-${CLI_ADAPTER_DEFAULT_PROVIDER}}"
  fi

  case "${provider}" in
    claude)
      _invoke_claude "${prompt}"
      ;;
    gemini)
      # 嘗試呼叫 Gemini CLI
      local gemini_output
      local gemini_exit

      gemini_output=$(_invoke_gemini "${prompt}" 2>&1)
      gemini_exit=$?

      if [[ "${gemini_exit}" -eq 0 ]]; then
        # Gemini 成功，輸出結果至 stdout
        echo "${gemini_output}"
      else
        # Gemini 失敗，記錄原因並 fallback 回 Claude
        _cli_adapter_log_error "Gemini CLI 失敗（exit code: ${gemini_exit}）。失敗訊息: ${gemini_output}"
        _cli_adapter_log_info "fallback 至 Claude CLI..."
        _invoke_claude "${prompt}"
      fi
      ;;
    *)
      _cli_adapter_log_error "不支援的 provider: '${provider}'（支援: claude | gemini）"
      return 1
      ;;
  esac
}
