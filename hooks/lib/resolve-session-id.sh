#!/usr/bin/env bash
# Session ID 解析 — fallback chain（#572）
# 用法：source hooks/lib/resolve-session-id.sh
#       echo "$SHIKIGAMI_SESSION_ID"
#
# Fallback chain：
#   1. CLAUDE_SESSION_ID（環境變數，若有值直接使用）
#   2. SHIKIGAMI_SESSION_ID（已由外部設定，如 cruise_cron.sh 透過 CLAUDE_SESSION_ID 轉入）
#   3. ~/.claude/projects/<project>/ 目錄最近修改的 .jsonl 檔名（去掉 .jsonl 後綴）
#   4. pid-$$（ultimate fallback）

if [[ -n "${CLAUDE_SESSION_ID:-}" ]]; then
  SHIKIGAMI_SESSION_ID="$CLAUDE_SESSION_ID"
elif [[ -n "${SHIKIGAMI_SESSION_ID:-}" ]]; then
  : # 已由外部設定（如 cruise_cron.sh 透過 CLAUDE_SESSION_ID 轉入，或其他前置設定）
else
  # 嘗試從 ~/.claude/projects/ 找最近的 .jsonl
  PROJECT_DIR="${PWD}"
  PROJECT_PATH=$(echo "${PROJECT_DIR}" | sed 's|/|-|g; s|^-||')
  JSONL_DIR="${HOME}/.claude/projects/${PROJECT_PATH}"
  if [[ -d "$JSONL_DIR" ]]; then
    LATEST_JSONL=$(ls -t "${JSONL_DIR}"/*.jsonl 2>/dev/null | head -1)
    if [[ -n "$LATEST_JSONL" ]]; then
      SHIKIGAMI_SESSION_ID=$(basename "$LATEST_JSONL" .jsonl)
    fi
  fi
  # Ultimate fallback
  SHIKIGAMI_SESSION_ID="${SHIKIGAMI_SESSION_ID:-pid-$$}"
fi

export SHIKIGAMI_SESSION_ID
