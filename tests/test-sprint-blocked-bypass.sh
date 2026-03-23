#!/usr/bin/env bash
# tests/test-sprint-blocked-bypass.sh
# Issue #434 — retro: Sprint 被外部依賴阻塞時應自動 bypass 並推進 backlog
# 驗證 PO 巡邏新增「Sprint 實質完成」偵測邏輯

set -uo pipefail

# ---------------------------------------------------------------------------
# 測試框架（輕量，與 test-366-sprint-planning-trigger.sh 一致）
# ---------------------------------------------------------------------------
PASS_COUNT=0
FAIL_COUNT=0

pass() {
  echo "PASS: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "FAIL: $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -qE "$pattern" "$file" 2>/dev/null; then
    pass "$label"
  else
    fail "$label (pattern='${pattern}' not found in $file)"
  fi
}

# ---------------------------------------------------------------------------
# 設定路徑
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_FILE="${REPO_ROOT}/skills/cruise/SKILL.md"

echo "=== #434 Sprint 實質完成偵測（blocked bypass）測試 ==="
echo "REPO_ROOT: $REPO_ROOT"
echo "SKILL_FILE: $SKILL_FILE"
echo ""

if [[ ! -f "$SKILL_FILE" ]]; then
  fail "前置：skills/cruise/SKILL.md 存在"
  echo ""
  echo "=== 測試結果 ==="
  echo "PASS: $PASS_COUNT"
  echo "FAIL: $FAIL_COUNT"
  echo "總結：前置條件失敗，無法執行後續測試"
  exit 1
fi

# ---------------------------------------------------------------------------
# TC-40a：SKILL.md 含 Sprint 實質完成偵測邏輯段落（Step 5.5 或獨立區塊）
# ---------------------------------------------------------------------------
echo "--- TC-40a：SKILL.md 含 Sprint 實質完成偵測邏輯 ---"

assert_contains "$SKILL_FILE" \
  'Sprint.*實質完成|effectively.*complete|EFFECTIVELY_COMPLETE' \
  "TC-40a: SKILL.md 含 Sprint 實質完成 / EFFECTIVELY_COMPLETE 關鍵字"

# ---------------------------------------------------------------------------
# TC-40b：觸發條件 — BLOCKED_SPRINT_STORIES 定義
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-40b：觸發條件定義完整 ---"

assert_contains "$SKILL_FILE" \
  'BLOCKED_SPRINT_STORIES' \
  "TC-40b1: SKILL.md 含 BLOCKED_SPRINT_STORIES 變數定義"

assert_contains "$SKILL_FILE" \
  'TOTAL_SPRINT_STORIES' \
  "TC-40b2: SKILL.md 含 TOTAL_SPRINT_STORIES 變數定義"

assert_contains "$SKILL_FILE" \
  'EFFECTIVELY_COMPLETE' \
  "TC-40b3: SKILL.md 含 EFFECTIVELY_COMPLETE 判定變數"

# ---------------------------------------------------------------------------
# TC-40c：觸發條件語意正確 — 全部為 blocked 才判定實質完成
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-40c：判定邏輯語意 ---"

assert_contains "$SKILL_FILE" \
  'BLOCKED_SPRINT_STORIES.*==.*TOTAL_SPRINT_STORIES|全部.*blocked|blocked.*全部' \
  "TC-40c: SKILL.md 判定條件為 blocked == total（全部被阻塞才觸發）"

assert_contains "$SKILL_FILE" \
  'TOTAL_SPRINT_STORIES.*>.*0|total.*>.*0' \
  "TC-40c2: SKILL.md 含 TOTAL_SPRINT_STORIES > 0 防空集合條件"

# ---------------------------------------------------------------------------
# TC-40d：三種 project_level 行為均已定義
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-40d：三種 project_level 的 blocked bypass 行為 ---"

assert_contains "$SKILL_FILE" \
  'effectively.*complete.*low|low.*Sprint Review|blocked.*bypass.*low|Sprint.*實質完成.*low' \
  "TC-40d-low: SKILL.md low → 自動觸發 Sprint Review"

assert_contains "$SKILL_FILE" \
  'effectively.*complete.*medium|medium.*blocked.*bypass|blocked.*bypass.*medium|Sprint.*實質完成.*medium' \
  "TC-40d-medium: SKILL.md medium → 留言通知等確認"

# ---------------------------------------------------------------------------
# TC-40e：low 模式自動觸發 Sprint Review（invoke）
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-40e：low 模式自動 invoke Sprint Review ---"

assert_contains "$SKILL_FILE" \
  'invoke shikigami:sprint-review|sprint-review.*invoke' \
  "TC-40e: SKILL.md low 路徑含 invoke shikigami:sprint-review"

# ---------------------------------------------------------------------------
# TC-40f：log action 含 effectively-complete 類型（可觀察性）
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-40f：log action 可觀察性 ---"

assert_contains "$SKILL_FILE" \
  'effectively-complete|sprint-effectively-complete' \
  "TC-40f: SKILL.md log action 含 effectively-complete 類型"

# ---------------------------------------------------------------------------
# TC-40g：偵測邏輯位置在 Step 5 與 Step 6 之間（Step 5.5）
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-40g：偵測邏輯位於 Step 5 與 Step 6 之間 ---"

# 驗證 Step 5.5（或類似命名）存在於 Step 5 之後、Step 6 之前
STEP5_LINE=$(grep -n "Step 5" "$SKILL_FILE" | head -1 | cut -d: -f1)
STEP6_LINE=$(grep -n "Step 6" "$SKILL_FILE" | head -1 | cut -d: -f1)
EFFECTIVELY_LINE=$(grep -n "EFFECTIVELY_COMPLETE\|Step 5\.5\|Sprint.*實質完成偵測" "$SKILL_FILE" | head -1 | cut -d: -f1)

if [[ -n "$STEP5_LINE" && -n "$STEP6_LINE" && -n "$EFFECTIVELY_LINE" ]]; then
  if [[ "$EFFECTIVELY_LINE" -gt "$STEP5_LINE" && "$EFFECTIVELY_LINE" -lt "$STEP6_LINE" ]]; then
    pass "TC-40g: Sprint 實質完成偵測邏輯位於 Step 5（L${STEP5_LINE}）與 Step 6（L${STEP6_LINE}）之間（L${EFFECTIVELY_LINE}）"
  else
    fail "TC-40g: Sprint 實質完成偵測邏輯（L${EFFECTIVELY_LINE}）應在 Step 5（L${STEP5_LINE}）與 Step 6（L${STEP6_LINE}）之間"
  fi
else
  fail "TC-40g: 無法定位 Step 5、Step 6 或 EFFECTIVELY_COMPLETE（Step5=${STEP5_LINE:-?}, Step6=${STEP6_LINE:-?}, Detect=${EFFECTIVELY_LINE:-?}）"
fi

# ---------------------------------------------------------------------------
# 結果摘要
# ---------------------------------------------------------------------------
echo ""
echo "=== 測試結果 ==="
echo "PASS: $PASS_COUNT"
echo "FAIL: $FAIL_COUNT"

if [[ $FAIL_COUNT -eq 0 ]]; then
  echo "總結：Sprint 實質完成偵測測試全部通過（#434 AC 滿足）"
  exit 0
else
  echo "總結：發現 $FAIL_COUNT 個 FAIL，Sprint 實質完成偵測邏輯有遺漏，請修正"
  exit 1
fi
