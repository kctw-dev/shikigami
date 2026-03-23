#!/usr/bin/env bash
# pr-merge-gate.sh — #446 PreToolUse hook：偵測 gh pr merge，提示審查確認
#
# 攔截邏輯：
#   - 偵測 gh pr merge 或 pr merge 指令
#   - 若偵測到，輸出 PR-MERGE-GATE 提醒（exit 1 讓 LLM 看見提示）
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

# ── 只關心包含 gh pr merge 或 pr merge 的指令 ────────────────────────────
if ! echo "$CMD" | grep -qE '(gh\s+pr\s+merge|pr\s+merge)'; then
  exit 0
fi

# ── 輸出 PR-MERGE-GATE 提醒 ──────────────────────────────────────────────
echo "[PR-MERGE-GATE] 合併前請確認以下審查已完成："
echo "1. pr-review-toolkit 三 agent 審查已執行且通過？（code-reviewer / silent-failure-hunter 無 CRITICAL/HIGH；comment-analyzer 無 Critical Issues）"
echo "2. 外部獨立審查已 CONFIRM（或 doc-only 跳過）？"
echo "3. CI/CD 雙審查 Gate（若有 .github/workflows 變更）已 PASS？"
echo ""
echo "若未完成，請先執行審查再合併。若確認已完成，可繼續合併。"
exit 1
