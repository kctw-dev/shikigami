#!/usr/bin/env bash
# branch-gate.sh — #446 PreToolUse hook：偵測 git checkout -b / git switch -c，提示 claim 確認
#
# 攔截邏輯：
#   - 偵測 git checkout -b 或 git switch -c 指令
#   - 若偵測到，輸出 BRANCH-GATE 提醒（exit 1 讓 LLM 看見提示）
#   - 其他指令直接放行（exit 0）
#
# 取代原有 type: prompt hook，改為確定性 shell script 排除 LLM 隨機性
#
# 使用方式：由 hooks.json PreToolUse hook 呼叫
#   CLAUDE_TOOL_INPUT（JSON）提供 command 欄位

set -euo pipefail

# ── 讀取指令 ────────────────────────────────────────────────────────────────
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"
if [[ -z "$TOOL_INPUT" ]]; then
  exit 0
fi

# 從 JSON 解析 command 欄位（支援 jq 與 POSIX sed 兩種方式）
CMD=""
if command -v jq &>/dev/null; then
  JQ_OUT=$(echo "$TOOL_INPUT" | jq -r '.command // ""' 2>/dev/null || echo "__JQ_PARSE_ERROR__")
  if [[ "$JQ_OUT" == "__JQ_PARSE_ERROR__" ]]; then
    exit 0
  fi
  CMD="$JQ_OUT"
else
  CMD=$(echo "$TOOL_INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null | head -1 || echo "")
fi

if [[ -z "$CMD" ]]; then
  exit 0
fi

# ── 只關心 git checkout -b 或 git switch -c 指令 ─────────────────────────
if ! echo "$CMD" | grep -qE '(git\s+checkout\s+.*-b|git\s+switch\s+.*-c)'; then
  exit 0
fi

# ── 輸出 BRANCH-GATE 提醒 ────────────────────────────────────────────────
echo "[BRANCH-GATE] 建立新分支前，請確認："
echo "1. 已在 Sprint Backlog 中 claim 本 Story（避免多 session 搶單）？"
echo "2. 分支命名遵循慣例 sprint-{N}/{story-id}？"
echo ""
echo "若尚未 claim，請先更新 Sprint 文件再建立分支。"
exit 1
