#!/usr/bin/env bash
# push-main-gate.sh — #446 PreToolUse hook：偵測 git push + main，提示 PR 流程
#
# 攔截邏輯：
#   - 偵測 git push 且包含 main 或 origin main 的指令
#   - 若偵測到，輸出 PUSH-MAIN-GATE 提醒（exit 1 讓 LLM 看見提示）
#   - 其他指令直接放行（exit 0）
#
# 取代原有 type: prompt hook，改為確定性 shell script 排除 LLM 隨機性
#
# 注意：此 hook 與 protect-main.sh 互補：
#   protect-main.sh — 執行完整豁免邏輯並硬攔截
#   push-main-gate.sh — 偵測明確包含 main 關鍵字的 push，輸出流程提示
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

# ── 只關心 git push + main 的指令 ───────────────────────────────────────
if ! echo "$CMD" | grep -qE 'git\s+push'; then
  exit 0
fi

if ! echo "$CMD" | grep -qE '(\s|^)main(\s|$)|origin\s+main'; then
  exit 0
fi

# ── 輸出 PUSH-MAIN-GATE 提醒 ─────────────────────────────────────────────
echo "[PUSH-MAIN-GATE] 直接 push 到 main 分支前，請確認："
echo "1. 本次變更是否在豁免清單中（doc-only / hotfix / version-bump）？"
echo "2. 若非豁免，請改用 PR 流程：git push origin {branch} 後執行 gh pr create。"
echo ""
echo "直接 push main 僅適用於豁免清單場景，一般功能實作必須走 PR 流程。"
exit 1
