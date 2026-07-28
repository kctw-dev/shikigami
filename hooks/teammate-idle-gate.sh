#!/usr/bin/env bash
# teammate-idle-gate.sh — Product Team：TeammateIdle 未完成驗收條件閘門
#
# Hook 類別: TeammateIdle（teammate 即將轉為 idle 時觸發）
#
# 用途：
#   teammate 常在還有未滿足的驗收條件時就收工，導致依賴它的 task 永遠卡住
#   （這是 Agent Teams 官方文件自承的已知問題）。
#   此閘門在 teammate 想 idle 時檢查是否留有未完成標記，有則把它叫回去繼續。
#
# 判定：
#   payload 中若出現未完成訊號（未勾選的 checkbox、TODO、阻塞宣告、
#   FAIL 驗收項），且未同時出現明確的阻塞回報 → 擋下。
#
# 輸出標記（stdout）：
#   [TEAM-IDLE-GATE-PASS]  — 可以收工
#   [TEAM-IDLE-GATE-BLOCK] — 叫回去繼續（exit 2）
#   [TEAM-IDLE-GATE-SKIP]  — 基礎設施不可用，放行
#
# 失敗行為：
#   jq 缺失、payload 無法解析、stdin 為空 → 一律 exit 0 放行。
#   誤擋會讓 teammate 空轉燒 token，所以判定從嚴（只擋明確訊號）。
#
# Exit code:
#   0 = 放行（PASS / SKIP）
#   2 = 擋下並回饋

set -uo pipefail

# ── 讀取 payload ────────────────────────────────────────────────────────────
PAYLOAD=""
if [ ! -t 0 ]; then
  PAYLOAD=$(cat 2>/dev/null || true)
fi

if [ -z "$PAYLOAD" ]; then
  echo "[TEAM-IDLE-GATE-SKIP] 無 payload，放行"
  exit 0
fi

# ── 取出 teammate 最後產出文字 ──────────────────────────────────────────────
IDLE_TEXT=""
if command -v jq &>/dev/null; then
  IDLE_TEXT=$(printf '%s' "$PAYLOAD" \
    | jq -r '[.summary?, .result?, .message?, .last_message?, .transcript?]
             | map(select(. != null and . != "")) | join(" ")' 2>/dev/null || true)
fi

if [ -z "$IDLE_TEXT" ] || [ "$IDLE_TEXT" = "null" ]; then
  IDLE_TEXT="$PAYLOAD"
fi

# ── 豁免：已明確回報阻塞 ────────────────────────────────────────────────────
# 依紀律，teammate 無法完成時「回報阻塞原因」本身就是正確行為，不應被擋。
if printf '%s' "$IDLE_TEXT" | grep -qiE '阻塞|blocked|blocker|需要(人類)?確認|等待.*(確認|核准)|awaiting approval|需要澄清'; then
  echo "[TEAM-IDLE-GATE-PASS] 已明確回報阻塞，允許收工"
  exit 0
fi

# ── 主判定：是否留有未完成訊號 ───────────────────────────────────────────────
UNFINISHED=""

# 訊號 A：未勾選的 checkbox
if printf '%s' "$IDLE_TEXT" | grep -qE '^[[:space:]]*[-*][[:space:]]*\[[[:space:]]\]'; then
  UNFINISHED="${UNFINISHED}未勾選的驗收項 "
fi

# 訊號 B：TODO / FIXME / 待實作
if printf '%s' "$IDLE_TEXT" | grep -qiE 'TODO|FIXME|待實作|尚未實作|未完成|not implemented'; then
  UNFINISHED="${UNFINISHED}待辦標記 "
fi

# 訊號 C：驗收 FAIL
if printf '%s' "$IDLE_TEXT" | grep -qiE '\bFAIL(ED|ING)?\b|測試失敗|test.*fail'; then
  UNFINISHED="${UNFINISHED}失敗的驗收項 "
fi

if [ -z "$UNFINISHED" ]; then
  echo "[TEAM-IDLE-GATE-PASS] 無未完成訊號，允許收工"
  exit 0
fi

# ── 擋下 ────────────────────────────────────────────────────────────────────
echo "[TEAM-IDLE-GATE-BLOCK] 偵測到未完成訊號：${UNFINISHED}"
echo ""
echo "你的工作尚未收尾。請擇一處理："
echo "  1. 繼續完成剩下的驗收條件"
echo "  2. 若被阻塞，明確回報阻塞原因（含卡在哪一條、需要什麼才能繼續）"
echo ""
echo "不要在留有未完成項的情況下轉為 idle——依賴此 task 的其他 task 會永遠卡住。"

exit 2
