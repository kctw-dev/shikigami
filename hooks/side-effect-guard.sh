#!/usr/bin/env bash
# hooks/side-effect-guard.sh
# Story #405 — Crash Recovery: Side Effect Idempotency Guard
# ADR-041 決策 4：Guard-before-Execute 模式
#
# 使用方式：
#   source hooks/side-effect-guard.sh
#   if check_side_effect "$EFFECT_TYPE" "$IDEMPOTENCY_KEY"; then
#     <執行操作>
#     record_side_effect "$EFFECT_TYPE" "$IDEMPOTENCY_KEY"
#   fi

# ── 路徑解析 ──
# 支援 SE_LOG_OVERRIDE 覆蓋（測試用）
_get_se_log() {
  local log_path="${SE_LOG_OVERRIDE:-}"
  if [[ -n "$log_path" ]]; then
    echo "$log_path"
    return
  fi
  local sprint="${SPRINT_NUM:-0}"
  local session="${SESSION_ID:-default}"
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
  echo "${repo_root}/docs/sprints/tcb/sprint-${sprint}/session-${session}/side-effects.jsonl"
}

# ── check_side_effect ──
# 引數：$1=effect_type, $2=idempotency_key, $3=（可選）log_path_override
# 回傳：0=未執行（允許繼續）, 1=已執行（跳過）
check_side_effect() {
  local effect_type="$1"
  local idempotency_key="$2"
  local se_log="${3:-$(_get_se_log)}"

  # 若 log 不存在，視為未執行
  if [[ ! -f "$se_log" ]]; then
    return 0
  fi

  # 使用 grep 快速比對 idempotency_key（比 jq 快，且 jq 不一定存在）
  if grep -qF "\"${idempotency_key}\"" "$se_log" 2>/dev/null; then
    echo "[SKIP-SIDE-EFFECT] ${effect_type} already executed: ${idempotency_key}" >&2
    return 1  # Already executed — skip
  fi

  return 0  # Not found — proceed
}

# ── record_side_effect ──
# 引數：$1=effect_type, $2=idempotency_key, $3=（可選）log_path_override, $4=（可選）payload json string
# 功能：append JSONL entry，失敗時 graceful degrade（NFR4：不拋出 fatal）
record_side_effect() {
  local effect_type="$1"
  local idempotency_key="$2"
  local se_log="${3:-$(_get_se_log)}"
  local payload="${4:-{\}}"

  local sprint="${SPRINT_NUM:-0}"
  local session="${SESSION_ID:-default}"
  local executed_at
  executed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "unknown")

  # NFR4: 寫入失敗時 graceful degrade（log warning，不拋出 fatal）
  mkdir -p "$(dirname "$se_log")" 2>/dev/null || {
    echo "[WARN] side-effect-guard: cannot create directory for $se_log" >&2
    return 0
  }

  # 構造 JSONL entry（不依賴 jq，使用字串拼接）
  local entry
  # 對 idempotency_key 和 payload 做基本 JSON 安全處理（移除雙引號）
  local safe_key="${idempotency_key//\"/\'}"
  printf '%s\n' \
    "{\"effect_type\":\"${effect_type}\",\"idempotency_key\":\"${safe_key}\",\"sprint\":${sprint},\"session_id\":\"${session}\",\"executed_at\":\"${executed_at}\",\"payload\":${payload}}" \
    >> "$se_log" 2>/dev/null || {
    echo "[WARN] side-effect-guard: write failed for $se_log" >&2
    return 0  # NFR4: graceful degrade
  }

  echo "[SIDE-EFFECT-RECORDED] ${effect_type}: ${idempotency_key}" >&2
}

# ── side_effect_wrap ──
# 便利函數：wrap 一個命令，自動 check + execute + record
# 引數：$1=effect_type, $2=idempotency_key, 剩餘引數=要執行的命令
# 範例：side_effect_wrap "git-commit" "$(git rev-parse HEAD)" git commit -m "..."
side_effect_wrap() {
  local effect_type="$1"
  local idempotency_key="$2"
  shift 2

  if ! check_side_effect "$effect_type" "$idempotency_key"; then
    return 0  # Already executed, skip (idempotent)
  fi

  # Execute the command
  "$@"
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    record_side_effect "$effect_type" "$idempotency_key"
  fi

  return $exit_code
}
