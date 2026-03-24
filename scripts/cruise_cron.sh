#!/usr/bin/env bash
# shikigami-schedule: cruise | interval=1m | cron=* * * * *
# Generated: 2026-03-24T16:49:53+0800
# Project: /home/kevin/workspace/00.shikigami-dev
# requiredTools-hash: b63063ce

set -euo pipefail

SKILL_NAME="cruise"
PROJECT_DIR="/home/kevin/workspace/00.shikigami-dev"
LOCK_FILE="/tmp/shikigami-schedule-8913708d-cruise.lock"
LOG_FILE="${PROJECT_DIR}/logs/schedule-cruise.log"

mkdir -p "$(dirname "$LOG_FILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

# flock 防重複執行（ADR-005）
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
  log "SKIPPED — previous run still active (lock: $LOCK_FILE)"
  exit 0
fi

log "START — skill=${SKILL_NAME} interval=1m group=none"

# 確保 OAuth 認證（不使用 API Key）
unset ANTHROPIC_API_KEY 2>/dev/null || true

cd "$PROJECT_DIR"

# 執行 cruise --once（每次乾淨 session）
export PATH="/home/kevin/.local/bin:/home/kevin/.nvm/versions/node/v24.14.0/bin:$PATH"
export CLAUDE_SESSION_ID="cron-$(date '+%Y%m%d-%H%M%S')"

claude -p "/cruise --once" \
  --allowedTools "Read,Glob,Grep,Bash,Edit,Write,Agent,Skill" \
  2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[0]}
log "END (exit: ${EXIT_CODE})"
exit "${EXIT_CODE}"
