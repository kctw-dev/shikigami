#!/usr/bin/env bash
# scripts/dispatch-with-fallback.sh
# Issue #1003 (Sprint 182 Retro A3) / ADR-046：subagent 派遣 fallback 偵測 + 紀錄
#
# 三類錯誤偵測 + jsonl 紀錄。實際的重新派遣動作由主 session（LLM）依本 script
# 的判斷結果執行 — shell 無法直接 invoke Agent tool。
#
# 用法（單次偵測）：
#   bash scripts/dispatch-with-fallback.sh detect-error  --input-file <stderr-file>
#   bash scripts/dispatch-with-fallback.sh detect-refusal --input-file <stdout-file>
#   bash scripts/dispatch-with-fallback.sh detect-error  --text  "Server returned 429..."
#   bash scripts/dispatch-with-fallback.sh detect-refusal --text "I can't help with that..."
#
# 用法（紀錄事件）：
#   bash scripts/dispatch-with-fallback.sh record-event \
#     --story 1003 --from opus --to sonnet --reason HTTP529 [--retry-count 0]
#
# 用法（顯示偵測 pattern）：
#   bash scripts/dispatch-with-fallback.sh patterns
#
# Exit code:
#   detect-*: 0 = 偵測到 + 已輸出建議動作；1 = 未偵測到
#   record-event: 0 = 紀錄成功；1 = 參數錯誤
#   其他: 0 = 正常；1 = 用法錯誤

set -uo pipefail

readonly SCRIPT_NAME="dispatch-with-fallback.sh"

# ---------------------------------------------------------------------------
# 偵測 Pattern（單一來源；ADR-046 D3）
# ---------------------------------------------------------------------------
# HTTP 429 — Rate Limit
readonly PATTERN_HTTP_429='(^|[^0-9])429([^0-9]|$)|rate[_ -]?limit|rate limit error|RateLimit'
# HTTP 500 / 529 — Server Error / Overload
readonly PATTERN_HTTP_5XX='(^|[^0-9])(500|529)([^0-9]|$)|Overloaded|overloaded_error|server[_ -]error|Internal server error'
# Usage Policy Refusal — subagent 正常完成但內容是拒答
# 設計原則（codex review P2-3 / P2-5）：所有「不協助」動詞片語都必須帶有
# 「明確指向請求」的限定詞（that / this / your / the request / with X），
# 才能與技術診斷區分（例如「I am unable to provide the exact line」是診斷，
# 「I am unable to provide that」是拒答）。
readonly PATTERN_REFUSAL="I can't help with (that|this|your)|I cannot help with (that|this|your)|I'm unable to (help|assist|comply|fulfill|provide|process|do) (with )?(that|this|your|the request|the task)|I am unable to (help|assist|comply|fulfill|provide|process|do) (with )?(that|this|your|the request|the task)|I can't assist with (that|this|your)|I cannot assist with (that|this|your)|I won't be able to (help|assist|comply|fulfill|do|provide) (with )?(that|this|your|the request|the task)|I (must|have to) decline (that|this|your)|cannot comply with (that|this|your) request|against (my|our|the) (guidelines|policies|policy|rules|values)|goes against (my|our|the) (guidelines|policies|policy|rules|values)"

# Exit code 2 = usage / contract error（呼叫方有問題）
# Exit code 1 = no match / no fallback needed（正常無 fallback）
# Exit code 0 = match / fallback recommended
die() { echo "[ERROR] $*" >&2; exit 2; }

# require_value <flag-name> <remaining-arg-count>
# 在 shift 2 之前呼叫，避免缺值 + 無 set -e 導致無限迴圈
require_value() {
  local flag="$1" remaining="$2"
  [[ "$remaining" -ge 2 ]] || die "$flag requires a value"
}

# ---------------------------------------------------------------------------
# 子命令：偵測錯誤（429/5xx）
# ---------------------------------------------------------------------------
cmd_detect_error() {
  local text="$1"
  if [[ -z "$text" ]]; then
    echo "[NONE] empty input"
    return 1
  fi
  # API 錯誤訊息來源多樣（不同 SDK / proxy / log），大小寫不一定統一
  # 用 -i 確保「Rate limit exceeded」「Internal Server Error」等變體也能匹配
  # （codex review P2 第三輪）
  if grep -iqE "$PATTERN_HTTP_429" <<< "$text"; then
    echo "[DETECTED] type=HTTP_429 action=RETRY_SAME(backoff=30,60,120) then=DOWNGRADE_SONNET"
    return 0
  fi
  if grep -iqE "$PATTERN_HTTP_5XX" <<< "$text"; then
    echo "[DETECTED] type=HTTP_5XX action=DOWNGRADE_SONNET_IMMEDIATE then=BACKOFF_SONNET(30,60,120)"
    return 0
  fi
  echo "[NONE] no error pattern matched"
  return 1
}

# ---------------------------------------------------------------------------
# 子命令：偵測拒答（policy refusal）
# ---------------------------------------------------------------------------
cmd_detect_refusal() {
  local text="$1"
  if [[ -z "$text" ]]; then
    echo "[NONE] empty input"
    return 1
  fi
  if grep -qE "$PATTERN_REFUSAL" <<< "$text"; then
    echo "[DETECTED] type=POLICY_REFUSAL action=DOWNGRADE_AND_RETRY_ONCE then=ESCALATE_HUMAN"
    return 0
  fi
  echo "[NONE] no refusal pattern matched"
  return 1
}

# ---------------------------------------------------------------------------
# 子命令：紀錄事件
# ---------------------------------------------------------------------------
cmd_record_event() {
  local story="" from="" to="" reason="" retry_count="0"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --story)       require_value --story "$#";       story="$2";       shift 2 ;;
      --from)        require_value --from "$#";        from="$2";        shift 2 ;;
      --to)          require_value --to "$#";          to="$2";          shift 2 ;;
      --reason)      require_value --reason "$#";      reason="$2";      shift 2 ;;
      --retry-count) require_value --retry-count "$#"; retry_count="$2"; shift 2 ;;
      *)             die "unknown arg: $1" ;;
    esac
  done

  [[ -n "$story" ]]  || die "--story required"
  [[ -n "$from" ]]   || die "--from required"
  [[ -n "$to" ]]     || die "--to required"
  [[ -n "$reason" ]] || die "--reason required (HTTP429 | HTTP500 | HTTP529 | POLICY_REFUSAL)"

  case "$reason" in
    HTTP429|HTTP500|HTTP529|POLICY_REFUSAL) ;;
    *) die "invalid --reason: $reason (expected: HTTP429 | HTTP500 | HTTP529 | POLICY_REFUSAL)" ;;
  esac

  local repo_root
  repo_root="$(cd "$(dirname "$0")/.." && pwd)"
  local log_dir="$repo_root/docs/cruise-logs"
  # 寫入失敗（read-only / permission / disk-full）必須立即 die，
  # 不可在沒寫成功的情況下回傳 [RECORDED]（codex review P2-4）
  mkdir -p "$log_dir" || die "無法建立 log 目錄：$log_dir"

  local date_str
  date_str="$(date -u '+%Y-%m-%d')"
  local log_file="$log_dir/model-fallback-${date_str}.jsonl"

  local timestamp
  timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

  # 嚴格 JSON — 所有欄位均為字串或數字，避免 jq 解析失敗
  if ! printf '{"timestamp":"%s","story_id":"#%s","from_model":"%s","to_model":"%s","reason":"%s","retry_count":%d}\n' \
    "$timestamp" "$story" "$from" "$to" "$reason" "$retry_count" \
    >> "$log_file"; then
    die "無法寫入 log 檔：$log_file"
  fi

  echo "[RECORDED] $log_file"
  echo "[MODEL-FALLBACK] #$story from=$from to=$to reason=$reason"
}

# ---------------------------------------------------------------------------
# 子命令：顯示 patterns（debug）
# ---------------------------------------------------------------------------
cmd_patterns() {
  cat <<EOF
=== ADR-046 Fallback 偵測 Pattern ===

[HTTP_429]      $PATTERN_HTTP_429
[HTTP_5XX]      $PATTERN_HTTP_5XX
[POLICY_REFUSAL] $PATTERN_REFUSAL

對應動作：
  HTTP_429        → 指數退避同模型（30s/60s/120s）→ 耗盡降級 sonnet
  HTTP_5XX        → 立即降級 sonnet → 退避 sonnet（30s/60s/120s）
  POLICY_REFUSAL  → 換 sonnet 重試 1 次 → 仍拒答則 [POLICY-REFUSAL] 轉人工

紀錄位置：docs/cruise-logs/model-fallback-<date>.jsonl
EOF
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
  cat <<'EOF'
用法：bash scripts/dispatch-with-fallback.sh <subcommand> [args]

子命令：
  detect-error    --input-file FILE | --text TEXT
                  從 stderr / 例外訊息偵測 HTTP 429 / 5xx

  detect-refusal  --input-file FILE | --text TEXT
                  從 subagent 正常輸出偵測 policy refusal 字樣

  record-event    --story N --from MODEL --to MODEL --reason TYPE [--retry-count N]
                  紀錄 fallback 事件至 docs/cruise-logs/model-fallback-<date>.jsonl
                  TYPE: HTTP429 | HTTP500 | HTTP529 | POLICY_REFUSAL

  patterns        顯示三類錯誤的偵測 pattern（debug）

  -h, --help      顯示此說明

Exit codes:
  0  detect-* 偵測到 → 輸出建議動作；其他子命令正常完成
  1  detect-* 未偵測到 → 不需 fallback（正常路徑）
  2  使用者錯誤（缺值、互斥旗標、無效 reason、檔案不可讀、寫入失敗等）
EOF
}

# ---------------------------------------------------------------------------
# 共用：解析 --input-file / --text → 寫入全域 $INPUT
# 不能用 $(...) command substitution + stdout 回傳，因為 die 在 subshell 中
# 只殺 subshell，主流程會以空字串繼續跑出 "[NONE] empty input" 假成功
# （codex review P2 第四輪）
# ---------------------------------------------------------------------------
INPUT=""
read_input_to_global() {
  local input_file="" text=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --input-file) require_value --input-file "$#"; input_file="$2"; shift 2 ;;
      --text)       require_value --text "$#";       text="$2";       shift 2 ;;
      *)            die "unknown arg: $1" ;;
    esac
  done
  if [[ -n "$input_file" && -n "$text" ]]; then
    die "--input-file 與 --text 互斥，擇一即可"
  fi
  # 完全沒給 input source（被遺漏的 caller bug）必須當 usage error，
  # 否則 INPUT="" 會走進 [NONE] empty input + exit 1 → 與「正常無 fallback」
  # 撞碼，靜默吞掉真正的 caller error（codex review P2 第七輪）
  if [[ -z "$input_file" && -z "$text" ]]; then
    die "需指定 --input-file FILE 或 --text TEXT 之一"
  fi
  if [[ -n "$input_file" ]]; then
    [[ -r "$input_file" ]] || die "input file 不可讀：$input_file"
    INPUT="$(cat "$input_file")"
  else
    INPUT="$text"
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
[[ $# -ge 1 ]] || { usage; exit 1; }

cmd="$1"
shift

case "$cmd" in
  detect-error)
    read_input_to_global "$@"
    cmd_detect_error "$INPUT"
    ;;
  detect-refusal)
    read_input_to_global "$@"
    cmd_detect_refusal "$INPUT"
    ;;
  record-event)
    cmd_record_event "$@"
    ;;
  patterns)
    cmd_patterns
    ;;
  -h|--help)
    usage
    ;;
  *)
    echo "未知子命令：$cmd" >&2
    usage
    exit 1
    ;;
esac
