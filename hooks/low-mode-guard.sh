#!/bin/bash
# low-mode-guard.sh — project_level=low 確認語句攔截
# Stop hook：偵測 agent 輸出含確認語句，block 並要求直接執行
#
# 觸發時機：agent 每次回應完成後（Stop event）
# 行為：讀取 CLAUDE_TOOL_INPUT（agent 輸出），比對確認語句模式

set -euo pipefail

# 讀取 project_level
CONFIG_FILE="${CLAUDE_CWD:-.}/.claude/shikigami.local.md"
PROJECT_LEVEL=$(grep -A5 'shikigami:' "$CONFIG_FILE" 2>/dev/null | grep 'project_level:' | awk '{print $2}' | head -1)
PROJECT_LEVEL="${PROJECT_LEVEL:-medium}"

# 僅 low 模式攔截
if [[ "$PROJECT_LEVEL" != "low" ]]; then
  exit 0
fi

# 讀取 agent 輸出（Stop hook 的 stop_response 透過 stdin）
RESPONSE=$(cat)

# 確認語句模式（中文 + 英文）
PATTERNS=(
  '還是.*[？?]'
  '要不要'
  '是否要'
  '你覺得.*[？?]'
  '需要.*嗎[？?]'
  '繼續.*嗎[？?]'
  '要繼續嗎'
  '要.*還是.*[？?]'
  'shall I'
  'should I'
  'do you want'
  'would you like'
)

for PATTERN in "${PATTERNS[@]}"; do
  if echo "$RESPONSE" | grep -qiP "$PATTERN"; then
    echo "[LOW-MODE-GUARD] project_level=low 禁止確認語句。偵測到: $(echo "$RESPONSE" | grep -oiP "$PATTERN" | head -1)"
    echo "直接執行，不要問。"
    exit 2  # non-zero = block
  fi
done

exit 0
