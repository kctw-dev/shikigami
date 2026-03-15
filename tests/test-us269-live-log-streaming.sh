#!/bin/bash
# TDD Test — US-269 演示模式 Live Log Streaming
# 驗證目標：
#   1. story-lifecycle-prompt.md 含有 5 個關鍵步驟的日誌寫入指令
#   2. 日誌路徑統一為 docs/sprints/sprint.live.log
#   3. SKILL.md 含有 Sprint Live Log 說明段落
#   4. 日誌格式含時間戳 $(date +%H:%M:%S)、Story ID、步驟名稱

set -e

PASS=0
FAIL=0
SKILL_FILE="skills/sprint-execution/SKILL.md"
PROMPT_FILE="skills/sprint-execution/story-lifecycle-prompt.md"
LOG_PATH="docs/sprints/sprint.live.log"

pass() { echo "  [PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }

echo "=== Test Suite: US-269 Live Log Streaming ==="
echo ""

# --- AC1: SKILL.md 新增 Sprint Live Log 說明段落 ---
echo "[AC1] SKILL.md 含 Sprint Live Log 說明段落"

if grep -q "Sprint Live Log" "$SKILL_FILE"; then
    pass "SKILL.md 含 'Sprint Live Log' 段落"
else
    fail "SKILL.md 缺少 'Sprint Live Log' 段落"
fi

if grep -q "tail -f" "$SKILL_FILE"; then
    pass "SKILL.md 含 'tail -f' 使用指引"
else
    fail "SKILL.md 缺少 'tail -f' 使用指引"
fi

if grep -q "$LOG_PATH" "$SKILL_FILE"; then
    pass "SKILL.md 含正確日誌路徑 $LOG_PATH"
else
    fail "SKILL.md 缺少日誌路徑 $LOG_PATH"
fi

echo ""

# --- AC2: story-lifecycle-prompt.md 在關鍵步驟加入日誌寫入指令 ---
echo "[AC2] story-lifecycle-prompt.md 關鍵步驟含日誌寫入指令"

# 檢查日誌路徑出現在 prompt 中
if grep -c "$LOG_PATH" "$PROMPT_FILE" | grep -qE "^[5-9]|^[1-9][0-9]"; then
    pass "prompt 含多個 $LOG_PATH 寫入指令（≥5 處）"
else
    COUNT=$(grep -c "$LOG_PATH" "$PROMPT_FILE" 2>/dev/null || echo 0)
    fail "prompt 僅含 $COUNT 處 $LOG_PATH 寫入指令（需 ≥5 處）"
fi

# 檢查 Story 開始執行 log
if grep -q "開始執行" "$PROMPT_FILE" && grep -q "sprint.live.log" "$PROMPT_FILE"; then
    pass "prompt 含 Story 開始執行日誌寫入"
else
    fail "prompt 缺少 Story 開始執行日誌寫入"
fi

# 檢查 TDD 相關 log
if grep -q "TDD" "$PROMPT_FILE" && grep -q "sprint.live.log" "$PROMPT_FILE"; then
    pass "prompt 含 TDD 階段日誌寫入"
else
    fail "prompt 缺少 TDD 階段日誌寫入"
fi

# 檢查 Spec Compliance Review log
if grep -q "Spec Compliance" "$PROMPT_FILE" && grep -q "sprint.live.log" "$PROMPT_FILE"; then
    pass "prompt 含 Spec Compliance Review 日誌寫入"
else
    fail "prompt 缺少 Spec Compliance Review 日誌寫入"
fi

# 檢查 Code Quality Review log
if grep -q "Code Quality" "$PROMPT_FILE" && grep -q "sprint.live.log" "$PROMPT_FILE"; then
    pass "prompt 含 Code Quality Review 日誌寫入"
else
    fail "prompt 缺少 Code Quality Review 日誌寫入"
fi

# 檢查 PASS/FAIL 結果 log
if grep -q "PASS\|FAIL\|ESCALATE" "$PROMPT_FILE" && grep -q "sprint.live.log" "$PROMPT_FILE"; then
    pass "prompt 含結果回傳日誌寫入"
else
    fail "prompt 缺少結果回傳日誌寫入"
fi

echo ""

# --- AC3: 日誌格式含時間戳 ---
echo "[AC3] 日誌格式含時間戳"

if grep -q 'date +%H:%M:%S' "$PROMPT_FILE"; then
    pass "prompt 日誌指令含 date +%H:%M:%S 時間戳"
else
    fail "prompt 日誌指令缺少 date +%H:%M:%S 時間戳"
fi

echo ""

# --- AC4: 日誌寫入為可選，不影響既有行為（容錯設計） ---
echo "[AC4] 日誌寫入可選容錯設計"

# 日誌寫入指令使用 >> 追加模式（不覆蓋）
if grep -q ">>" "$PROMPT_FILE"; then
    pass "日誌寫入使用 >> 追加模式（非覆蓋）"
else
    fail "日誌寫入未使用 >> 追加模式"
fi

# 存在容錯機制說明（失敗時靜默忽略）
if grep -q "靜默\|容錯\|不影響\|2>/dev/null\||| true" "$PROMPT_FILE" && grep -q "sprint.live.log" "$PROMPT_FILE"; then
    pass "日誌寫入含容錯機制（失敗靜默忽略）"
else
    fail "日誌寫入缺少容錯機制說明"
fi

echo ""

# --- AC5: 日誌路徑 docs/sprints/sprint.live.log ---
echo "[AC5] 日誌路徑遵循命名規範"

if grep -q "docs/sprints/sprint.live.log" "$PROMPT_FILE"; then
    pass "prompt 日誌路徑為 docs/sprints/sprint.live.log"
else
    fail "prompt 日誌路徑不符命名規範"
fi

if grep -q "docs/sprints/sprint.live.log" "$SKILL_FILE"; then
    pass "SKILL.md 日誌路徑為 docs/sprints/sprint.live.log"
else
    fail "SKILL.md 日誌路徑不符命名規範"
fi

echo ""

# --- 結果匯總 ---
echo "=== 結果匯總 ==="
echo "PASS: $PASS | FAIL: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
    echo "[RESULT] 全部通過 ✓"
    exit 0
else
    echo "[RESULT] 有 $FAIL 項測試失敗"
    exit 1
fi
