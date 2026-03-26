#!/usr/bin/env bash
# hooks/hook-runner.sh
# Story #923: Hook 執行超時與隔離機制
#
# 用途：帶 timeout + 隔離層的 Hook 執行包裝器
#       所有 Hook 可透過此包裝器執行以獲得：
#       1. Timeout 控制（預設 30s，可透過 HOOK_TIMEOUT 環境變數配置）
#       2. 執行隔離（trap + subshell，單一 Hook 失敗不波及整體流程）
#       3. 執行結果 metric 記錄（寫入 .claude/hooks/execution-metrics.jsonl）
#
# 用法：
#   bash hooks/hook-runner.sh <hook-script> [args...]
#   HOOK_TIMEOUT=60 bash hooks/hook-runner.sh hooks/my-hook.sh arg1
#   HOOK_TIMEOUT=0  bash hooks/hook-runner.sh hooks/my-hook.sh  # 0 = 無限制

set -uo pipefail

# ── 設定區 ──────────────────────────────────────────────────────────────────

# Hook timeout 秒數（NFR1：可配置，預設 30s）
HOOK_TIMEOUT="${HOOK_TIMEOUT:-30}"

# Metrics 寫入路徑（可透過環境變數覆蓋，用於測試隔離）
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
METRICS_FILE="${METRICS_FILE:-${REPO_ROOT}/.claude/hooks/execution-metrics.jsonl}"

# ── 工具函式 ────────────────────────────────────────────────────────────────

_now_ms() {
  # 取得毫秒級時間戳（bash + date 相容實作）
  if date +%s%3N >/dev/null 2>&1; then
    date +%s%3N
  else
    # macOS fallback: python3
    python3 -c "import time; print(int(time.time()*1000))" 2>/dev/null || \
      echo $(($(date +%s) * 1000))
  fi
}

_iso_timestamp() {
  date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date '+%Y-%m-%dT%H:%M:%SZ'
}

_write_metric() {
  local hook_name="$1"
  local status="$2"   # success | failure | timeout
  local duration_ms="$3"
  local exit_code="${4:-0}"

  # 確保 metrics 目錄存在
  local metrics_dir
  metrics_dir="$(dirname "$METRICS_FILE")"
  mkdir -p "$metrics_dir" 2>/dev/null || true

  # 建構 JSONL 條目（NFR2：所有狀態均記錄）
  local entry
  entry=$(printf '{"timestamp":"%s","hook":"%s","status":"%s","duration_ms":%s,"exit_code":%s}' \
    "$(_iso_timestamp)" \
    "$hook_name" \
    "$status" \
    "$duration_ms" \
    "$exit_code")

  # 寫入（append），失敗靜默忽略（不阻塞主流程）
  echo "$entry" >> "$METRICS_FILE" 2>/dev/null || true
}

# ── 主流程 ──────────────────────────────────────────────────────────────────

# 驗證輸入
if [[ $# -lt 1 ]]; then
  echo "[HOOK-RUNNER] ERROR: 必須提供 hook script 路徑" >&2
  exit 1
fi

HOOK_SCRIPT="$1"
shift
HOOK_ARGS=("$@")
HOOK_NAME="$(basename "$HOOK_SCRIPT")"

# 記錄開始時間
START_MS=$(_now_ms)

# ── AC2: Hook 執行隔離層 ─────────────────────────────────────────────────────
# 使用 subshell + trap 確保 Hook 失敗不影響外層流程

HOOK_EXIT=0
HOOK_STATUS="success"

if [[ "$HOOK_TIMEOUT" -eq 0 ]]; then
  # 無限制模式：直接在 subshell 中執行
  (
    set +e
    bash "$HOOK_SCRIPT" "${HOOK_ARGS[@]+"${HOOK_ARGS[@]}"}"
  )
  HOOK_EXIT=$?
else
  # ── AC1: Timeout 機制 ───────────────────────────────────────────────────
  # 使用 timeout 指令包裝執行（POSIX 相容）
  # timeout 返回碼：124 = timed out，其他 = hook 自身返回碼
  if command -v timeout >/dev/null 2>&1; then
    (
      set +e
      timeout "$HOOK_TIMEOUT" bash "$HOOK_SCRIPT" "${HOOK_ARGS[@]+"${HOOK_ARGS[@]}"}"
    )
    HOOK_EXIT=$?
  else
    # fallback: background + wait（macOS 無 timeout 指令時）
    (
      set +e
      bash "$HOOK_SCRIPT" "${HOOK_ARGS[@]+"${HOOK_ARGS[@]}"}" &
    ) &
    BG_PID=$!
    # 等待最多 HOOK_TIMEOUT 秒
    WAIT_COUNT=0
    while kill -0 "$BG_PID" 2>/dev/null && [[ $WAIT_COUNT -lt $HOOK_TIMEOUT ]]; do
      sleep 1
      WAIT_COUNT=$((WAIT_COUNT + 1))
    done
    if kill -0 "$BG_PID" 2>/dev/null; then
      # 仍在執行 → 超時，kill
      kill -TERM "$BG_PID" 2>/dev/null || true
      sleep 1
      kill -KILL "$BG_PID" 2>/dev/null || true
      HOOK_EXIT=124  # 與 timeout 指令一致
    else
      wait "$BG_PID" 2>/dev/null
      HOOK_EXIT=$?
    fi
  fi
fi

# 計算執行時間
END_MS=$(_now_ms)
DURATION_MS=$((END_MS - START_MS))

# ── 狀態判定 ────────────────────────────────────────────────────────────────

if [[ $HOOK_EXIT -eq 124 ]]; then
  HOOK_STATUS="timeout"
  # AC1: 超時記錄到 live-log（NFR2: observability）
  echo "[HOOK-RUNNER] TIMEOUT: ${HOOK_NAME} exceeded ${HOOK_TIMEOUT}s limit, killed" >&2
elif [[ $HOOK_EXIT -ne 0 ]]; then
  HOOK_STATUS="failure"
fi

# ── AC3: Metric 記錄 ────────────────────────────────────────────────────────
_write_metric "$HOOK_NAME" "$HOOK_STATUS" "$DURATION_MS" "$HOOK_EXIT"

# ── 返回 Hook 的原始 exit code（AC2: 隔離層透明傳遞，不吞掉錯誤資訊）──────
exit "$HOOK_EXIT"
