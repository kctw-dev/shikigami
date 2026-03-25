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


# ── 每日 00:00 UTC 歸檔觸發（#738 AC1）──────────────────────────────────
# 讀取 cruise_archive_days 配置（AC3：從 .claude/shikigami.local.md 讀取，預設 7）
CRUISE_ARCHIVE_DAYS=$(grep -A20 'cruise:' "${PROJECT_DIR}/.claude/shikigami.local.md" 2>/dev/null   | grep 'cruise_archive_days:' | awk '{print $2}' | head -1)
CRUISE_ARCHIVE_DAYS="${CRUISE_ARCHIVE_DAYS:-7}"

CURRENT_UTC_HOUR=$(date -u '+%H')
IS_MIDNIGHT=false
if [[ "${CURRENT_UTC_HOUR}" == "00" ]]; then
  IS_MIDNIGHT=true
fi

if [[ "${IS_MIDNIGHT}" == "true" ]]; then
  log "DAILY-ARCHIVE — 00:00 UTC 觸發歸檔（CRUISE_ARCHIVE_DAYS=${CRUISE_ARCHIVE_DAYS}）"
  CRUISE_LOG_DIR="${PROJECT_DIR}/docs/cruise-logs"
  ARCHIVE_BASE_DIR="${CRUISE_LOG_DIR}/archive"

  if [[ -d "${CRUISE_LOG_DIR}" ]]; then
    # 跨平台日期計算（GNU date / BSD date）
    if date --version &>/dev/null 2>&1; then
      CUTOFF_DATE=$(date -d "${CRUISE_ARCHIVE_DAYS} days ago" '+%Y-%m-%d')
    else
      CUTOFF_DATE=$(date -v "-${CRUISE_ARCHIVE_DAYS}d" '+%Y-%m-%d')
    fi

    ARCHIVE_COUNT=0
    while IFS= read -r -d '' jsonl_file; do
      filename="$(basename "${jsonl_file}")"
      file_date="${filename:0:10}"
      if [[ "${file_date}" < "${CUTOFF_DATE}" ]] 2>/dev/null; then
        file_month="${file_date:0:7}"
        ARCHIVE_DIR="${ARCHIVE_BASE_DIR}/${file_month}"
        mkdir -p "${ARCHIVE_DIR}" 2>/dev/null || { log "[LOG-ARCHIVE-WARN] 無法建立目錄，跳過"; continue; }
        if gzip -c "${jsonl_file}" > "${ARCHIVE_DIR}/${filename}.gz" 2>/dev/null; then
          git -C "${PROJECT_DIR}" rm --cached "${jsonl_file#${PROJECT_DIR}/}" 2>/dev/null || true
          rm -f "${jsonl_file}" 2>/dev/null || true
          ARCHIVE_COUNT=$((ARCHIVE_COUNT + 1))
        else
          log "[LOG-ARCHIVE-WARN] 壓縮失敗：${filename}，跳過"
          rm -f "${ARCHIVE_DIR}/${filename}.gz" 2>/dev/null || true
        fi
      fi
    done < <(find "${CRUISE_LOG_DIR}" -maxdepth 1 -name "*.jsonl" -type f -print0 2>/dev/null)

    if [[ "${ARCHIVE_COUNT}" -gt 0 ]]; then
      log "[LOG-ARCHIVE] 已歸檔 ${ARCHIVE_COUNT} 個 JSONL 檔案"
    else
      log "[LOG-ARCHIVE-SKIP] 無需歸檔（無超過 ${CUTOFF_DATE} 的 JSONL 檔案）"
    fi
  fi
fi
# NFR1: 歸檔失敗不影響 cruise 主流程（archive block 與 cruise 執行獨立）
# ────────────────────────────────────────────────────────────────────────

# ── Kill Switch 前置檢查（#783，AC3）─────────────────────────────────────
# Cruise main loop 在每個 patrol cycle 開始前檢查 kill-switch sentinel
# SESSION_ID 前綴 "cron-" 供使用者以 kill-switch.sh cron-<date> 停止排程
KILL_SENTINEL="/tmp/shikigami-kill-cron.flag"
if [[ -f "$KILL_SENTINEL" ]]; then
  log "[KILL-SWITCH-ACTIVATED] Kill switch sentinel detected — skipping this patrol cycle"
  log "  Sentinel: $KILL_SENTINEL"
  log "  To reactivate cruise, remove sentinel: rm -f $KILL_SENTINEL"
  exit 0
fi
# ────────────────────────────────────────────────────────────────────────

# 執行 cruise --once（每次乾淨 session）
export PATH="/home/kevin/.local/bin:/home/kevin/.nvm/versions/node/v24.14.0/bin:$PATH"
export CLAUDE_SESSION_ID="cron-$(date '+%Y%m%d-%H%M%S')"

claude -p "/cruise --once" \
  --allowedTools "Read,Glob,Grep,Bash,Edit,Write,Agent,Skill" \
  2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[0]}
log "END (exit: ${EXIT_CODE})"
exit "${EXIT_CODE}"
