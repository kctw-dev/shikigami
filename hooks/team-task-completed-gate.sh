#!/usr/bin/env bash
# team-task-completed-gate.sh — Product Team：TaskCompleted 測試證據閘門
#
# Hook 類別: TaskCompleted（Agent Teams 標記 task 完成時觸發）
#
# 用途：
#   擋下「宣稱完成但拿不出測試證據」的 task。
#   寫在 prompt 裡的「不得跳過測試」agent 會忘；寫成 hook 它繞不過去。
#
# 判定：
#   完成宣告需附測試證據——測試檔路徑、測試通過輸出、或明確的測試結果陳述。
#   唯讀類 task（研究 / review / 調查）與純文件 task 豁免。
#
# 輸出標記（stdout）：
#   [TEAM-DONE-GATE-PASS]  — 通過
#   [TEAM-DONE-GATE-BLOCK] — 擋下並回饋（exit 2）
#   [TEAM-DONE-GATE-SKIP]  — 基礎設施不可用，放行
#
# 失敗行為：
#   jq 缺失、payload 無法解析、stdin 為空 → 一律 exit 0 放行。
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
  echo "[TEAM-DONE-GATE-SKIP] 無 payload，放行"
  exit 0
fi

# ── 取出 task 文字 ──────────────────────────────────────────────────────────
TASK_TEXT=""
if command -v jq &>/dev/null; then
  TASK_TEXT=$(printf '%s' "$PAYLOAD" \
    | jq -r '[.subject?, .description?, .result?, .summary?,
              .task?.subject?, .task?.description?, .task?.result?]
             | map(select(. != null and . != "")) | join(" ")' 2>/dev/null || true)
fi

if [ -z "$TASK_TEXT" ] || [ "$TASK_TEXT" = "null" ]; then
  TASK_TEXT="$PAYLOAD"
fi

# ── 豁免：唯讀類與純文件 task ────────────────────────────────────────────────
if printf '%s' "$TASK_TEXT" | grep -qiE '調查|研究|review|審查|分析|research|investigate|explore|辯論|debate'; then
  echo "[TEAM-DONE-GATE-PASS] 唯讀類 task，豁免測試證據檢查"
  exit 0
fi

if printf '%s' "$TASK_TEXT" | grep -qiE '純文件|docs only|documentation only|typo|錯字'; then
  echo "[TEAM-DONE-GATE-PASS] 純文件 task，豁免測試證據檢查"
  exit 0
fi

# ── 主判定：是否附測試證據 ───────────────────────────────────────────────────
# 條件 A：出現測試檔路徑（*.test.*、*_test.*、test_*、tests/ 下的檔案）
# 條件 B：出現測試結果陳述（passing / 通過 / passed / N tests / 全過）
HAS_TEST_FILE=0
HAS_TEST_RESULT=0

if printf '%s' "$TASK_TEXT" | grep -qE '(\.test\.|_test\.|/test_|tests?/[A-Za-z0-9_./-]+\.)'; then
  HAS_TEST_FILE=1
fi

if printf '%s' "$TASK_TEXT" | grep -qiE '測試(全)?過|測試通過|[0-9]+ (tests?|passed|passing)|all tests pass|test.*(pass|green)'; then
  HAS_TEST_RESULT=1
fi

if [ "$HAS_TEST_FILE" -eq 1 ] || [ "$HAS_TEST_RESULT" -eq 1 ]; then
  echo "[TEAM-DONE-GATE-PASS] 完成宣告已附測試證據"
  exit 0
fi

# ── 擋下 ────────────────────────────────────────────────────────────────────
echo "[TEAM-DONE-GATE-BLOCK] 此 task 宣稱完成，但未附測試證據。"
echo ""
echo "完成定義：所有驗收條件有對應測試且通過。"
echo "請在完成回報中附上其中之一："
echo "  - 測試檔路徑（例：tests/auth/login.test.ts）"
echo "  - 測試執行結果（例：12 tests passed）"
echo ""
echo "若確實無法寫出測試，那代表需求不清——回報阻塞原因，不要標記完成。"
echo "（寫不出測試就必須回退釐清，這優先於任何交付壓力。）"

exit 2
