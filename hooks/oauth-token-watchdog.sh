#!/usr/bin/env bash
# oauth-token-watchdog.sh — ADR-030：Claude OAuth Token 過期偵測與告警
#
# 行為：
#   - 讀取 ~/.claude/.credentials.json
#   - 檢查 claudeAiOauth.expiresAt 是否距現在 < warn_threshold_hours（預設 24 小時）
#   - 即將過期 → 輸出 [OAUTH-WARN] 告警（提示執行 claude auth login）
#   - 檔案不存在 / 欄位缺失 / 解析失敗 → 靜默跳過（不阻塞 session）
#
# 設計原則（ADR-030）：
#   - 只偵測+告警，不主動 refresh（refresh 端點未公開）
#   - 靜默跳過：任何讀取或解析錯誤均不影響 session 啟動

CREDENTIALS_FILE="${HOME}/.claude/.credentials.json"

# 告警門檻：從 .claude/shikigami.local.md 讀取 oauth.warn_threshold_hours（預設 24）
_LOCAL_CONFIG="$(git rev-parse --show-toplevel 2>/dev/null)/.claude/shikigami.local.md"
_THRESHOLD_HOURS=24
if [[ -f "$_LOCAL_CONFIG" ]]; then
  _RAW=$(grep 'warn_threshold_hours:' "$_LOCAL_CONFIG" 2>/dev/null | awk '{print $2}' | head -1)
  if [[ "$_RAW" =~ ^[0-9]+$ ]]; then
    _THRESHOLD_HOURS="$_RAW"
  fi
fi
WARN_THRESHOLD_SECONDS=$(( _THRESHOLD_HOURS * 3600 ))

# 檔案不存在 → 靜默跳過
if [[ ! -f "$CREDENTIALS_FILE" ]]; then
  exit 0
fi

# 取得 expiresAt 欄位（milliseconds epoch）
# 支援 python3 / python（fallback），均不可用則靜默跳過
EXPIRES_AT_MS=""
if command -v python3 >/dev/null 2>&1; then
  EXPIRES_AT_MS=$(python3 -c "
import json, sys
try:
    data = json.load(open('${CREDENTIALS_FILE}'))
    oauth = data.get('claudeAiOauth', {})
    expires = oauth.get('expiresAt')
    if expires is not None:
        print(int(expires))
except Exception:
    pass
" 2>/dev/null)
elif command -v python >/dev/null 2>&1; then
  EXPIRES_AT_MS=$(python -c "
import json, sys
try:
    data = json.load(open('${CREDENTIALS_FILE}'))
    oauth = data.get('claudeAiOauth', {})
    expires = oauth.get('expiresAt')
    if expires is not None:
        print(int(expires))
except Exception:
    pass
" 2>/dev/null)
fi

# expiresAt 欄位不存在或解析失敗 → 靜默跳過
if [[ -z "$EXPIRES_AT_MS" ]]; then
  exit 0
fi

# 計算剩餘秒數
NOW_SECONDS=$(date +%s)
EXPIRES_AT_SECONDS=$(( EXPIRES_AT_MS / 1000 ))
REMAINING_SECONDS=$(( EXPIRES_AT_SECONDS - NOW_SECONDS ))

# token 已過期或即將過期（< 24h）
if [[ "$REMAINING_SECONDS" -lt "$WARN_THRESHOLD_SECONDS" ]]; then
  if [[ "$REMAINING_SECONDS" -le 0 ]]; then
    echo "[OAUTH-WARN] Claude OAuth token 已過期，請執行 claude auth login 更新"
  else
    REMAINING_HOURS=$(( REMAINING_SECONDS / 3600 ))
    echo "[OAUTH-WARN] Claude OAuth token 即將過期（剩餘 ${REMAINING_HOURS}h），請執行 claude auth login 更新"
  fi
fi

exit 0
