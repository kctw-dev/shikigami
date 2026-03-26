#!/usr/bin/env bash
# <hook-name>.sh
# <一句話說明 Hook 職責>
#
# Story/Issue: #<N>
# Hook 類別: <gate | settle | utility>
#
# 用法：bash hooks/<hook-name>.sh [<arg1>] [<arg2>]
# 參數：
#   $1  <param_name>  — <說明>（必填）
#   $2  <param_name>  — <說明>（可選，預設 <default>）
#
# 輸出標記（stdout）：
#   [<HOOK>-OK]      — 操作成功完成
#   [<HOOK>-WARN]    — 非致命警告，流程繼續
#   [<HOOK>-BLOCKED] — 被阻擋，不允許通過（Gate Hook 適用）
#   [<HOOK>-SKIP]    — 條件不滿足，跳過執行
#
# 失敗行為：<exit 1 並阻塞 | 降級繼續 | 靜默忽略>
# 環境變數：
#   CLAUDE_PLUGIN_ROOT   — Plugin 根目錄（Claude Code 注入）
#   SHIKIGAMI_SESSION_ID — 當前 Session ID

# ── 模式選擇（擇一刪除另一）─────────────────────────────────────────────────
#
# Gate / Utility Hook: 嚴格模式 — 讓錯誤立即傳播
set -uo pipefail
#
# Settle Hook: 降級模式 — 所有操作加 || true，不因錯誤中止
# set +e

# ── 設定區 ──────────────────────────────────────────────────────────────────

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK_NAME="$(basename "$0" .sh)"

# 解析位置參數
ARG1="${1:-}"
ARG2="${2:-}"  # 可選

# ── 前置驗證 ────────────────────────────────────────────────────────────────

# 驗證必填參數
if [[ -z "$ARG1" ]]; then
  echo "[${HOOK_NAME^^}-ERROR] 缺少必填參數 \$1" >&2
  echo "用法：bash hooks/${HOOK_NAME}.sh <arg1> [arg2]" >&2
  exit 2
fi

# 驗證外部依賴（依需要取消註解）
# if ! command -v gh >/dev/null 2>&1; then
#   echo "[WARN] gh CLI 不可用，跳過 GitHub 操作" >&2
#   exit 0
# fi

# ── 工具函式 ────────────────────────────────────────────────────────────────

_timestamp() {
  date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "UNKNOWN"
}

_log_warn() {
  echo "[${HOOK_NAME^^}-WARN] $*" >&2
}

# ── 主流程 ──────────────────────────────────────────────────────────────────

# TODO: 在此實作 Hook 核心邏輯

# 範例：成功路徑
# echo "[${HOOK_NAME^^}-OK] 操作完成: $ARG1"
# exit 0

# 範例：Gate Hook 阻擋路徑
# echo "[${HOOK_NAME^^}-BLOCKED] 條件不滿足: $ARG1" >&2
# exit 1

# 範例：Settle Hook — 寫入 per-session log（不使用共用文件）
# LOG_FILE="${REPO_ROOT}/docs/cruise-logs/${HOOK_NAME}-$(date +%Y%m%d).jsonl"
# mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
# printf '{"type":"%s","arg1":"%s","ts":"%s"}\n' \
#   "$HOOK_NAME" "$ARG1" "$(_timestamp)" >> "$LOG_FILE" 2>/dev/null || true
# exit 0

# 清理臨時資源（若有建立）
# TMPFILE=$(mktemp)
# trap 'rm -f "$TMPFILE"' EXIT

echo "[${HOOK_NAME^^}-OK] 範本 Hook 執行完成（請替換此行為實際邏輯）"
exit 0
