#!/usr/bin/env bash
# team-task-created-gate.sh — Product Team：TaskCreated 檔案所有權閘門
#
# Hook 類別: TaskCreated（Agent Teams 建立 task 時觸發）
#
# 用途：
#   擋下沒有標注檔案所有權範圍的 task。
#   兩個 teammate 改同一個檔案就是互相覆蓋，沒有例外處理，只有預防——
#   而預防的唯一時機就是 task 建立當下。
#
# 判定：
#   task 內容需出現檔案路徑標記（含副檔名的路徑、或明確的「檔案 / files / 擁有」宣告）。
#   純研究、純 review 類 task 以關鍵字豁免（不寫檔案，無覆蓋風險）。
#
# 輸出標記（stdout）：
#   [TEAM-TASK-GATE-PASS]  — 通過
#   [TEAM-TASK-GATE-BLOCK] — 擋下並回饋（exit 2）
#   [TEAM-TASK-GATE-SKIP]  — 基礎設施不可用，放行
#
# 失敗行為：
#   jq 缺失、payload 無法解析、stdin 為空 → 一律 exit 0 放行。
#   閘門不該把團隊鎖死。
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
  echo "[TEAM-TASK-GATE-SKIP] 無 payload，放行"
  exit 0
fi

# ── 取出 task 文字（多來源 fallback）──────────────────────────────────────────
TASK_TEXT=""
if command -v jq &>/dev/null; then
  TASK_TEXT=$(printf '%s' "$PAYLOAD" \
    | jq -r '[.subject?, .description?, .task?.subject?, .task?.description?, .prompt?]
             | map(select(. != null and . != "")) | join(" ")' 2>/dev/null || true)
fi

# jq 不可用或欄位對不上 → 退回整段 payload 做文字比對
if [ -z "$TASK_TEXT" ] || [ "$TASK_TEXT" = "null" ]; then
  TASK_TEXT="$PAYLOAD"
fi

# ── 豁免：不寫檔案的 task 無覆蓋風險 ─────────────────────────────────────────
if printf '%s' "$TASK_TEXT" | grep -qiE '調查|研究|review|審查|分析|research|investigate|explore|辯論|debate'; then
  echo "[TEAM-TASK-GATE-PASS] 唯讀類 task，豁免檔案所有權檢查"
  exit 0
fi

# ── 主判定：是否標注檔案所有權 ───────────────────────────────────────────────
# 條件 A：出現含副檔名的路徑（如 src/foo.ts、tests/bar.test.js、docs/x.md）
# 條件 B：出現明確的所有權宣告關鍵字
HAS_PATH=0
HAS_DECLARATION=0

if printf '%s' "$TASK_TEXT" | grep -qE '[A-Za-z0-9_./-]+\.[A-Za-z0-9]{1,6}([[:space:]]|$|["'"'"',)])'; then
  HAS_PATH=1
fi

if printf '%s' "$TASK_TEXT" | grep -qiE '你擁有的檔案|檔案所有權|owns:|files:|owned files'; then
  HAS_DECLARATION=1
fi

if [ "$HAS_PATH" -eq 1 ] || [ "$HAS_DECLARATION" -eq 1 ]; then
  echo "[TEAM-TASK-GATE-PASS] task 已標注檔案所有權範圍"
  exit 0
fi

# ── 擋下 ────────────────────────────────────────────────────────────────────
echo "[TEAM-TASK-GATE-BLOCK] 此 task 未標注檔案所有權範圍。"
echo ""
echo "兩個 teammate 改同一個檔案會互相覆蓋，沒有事後補救，只有事前預防。"
echo "請在 task 描述中加入「你擁有的檔案」清單，例如："
echo ""
echo "  ## 你擁有的檔案（唯獨這些）"
echo "  - src/auth/login.ts"
echo "  - tests/auth/login.test.ts"
echo "  不得修改此清單以外的任何檔案。"
echo ""
echo "若此 task 確實不寫任何檔案（研究 / review / 調查），請在描述中註明類型。"
echo "範本：skills/product-team/references/teammate-dispatch.md"

exit 2
