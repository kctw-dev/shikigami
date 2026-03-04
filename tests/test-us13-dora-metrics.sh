#!/usr/bin/env bash
# tests/test-us13-dora-metrics.sh
# US-13：DORA Metrics — 部署頻率、變更前置時間、MTTR、變更失敗率追蹤
# 覆蓋 AC1 / AC2 / AC3 / AC4

set -uo pipefail

# ---------------------------------------------------------------------------
# 測試框架（輕量）
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

assert_file_contains() {
  local needle="$1"
  local filepath="$2"
  local label="$3"
  if grep -qF "$needle" "$filepath"; then
    pass "$label"
  else
    fail "$label (檔案中找不到「$needle」)"
  fi
}

assert_file_contains_regex() {
  local pattern="$1"
  local filepath="$2"
  local label="$3"
  if grep -qE "$pattern" "$filepath"; then
    pass "$label"
  else
    fail "$label (檔案中找不到符合模式「$pattern」的內容)"
  fi
}

assert_file_exists() {
  local filepath="$1"
  local label="$2"
  if [ -f "$filepath" ]; then
    pass "$label"
  else
    fail "$label (檔案不存在：$filepath)"
  fi
}

# ---------------------------------------------------------------------------
# 設定路徑
# ---------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_FILE="$REPO_ROOT/skills/sprint-review/SKILL.md"
METRICS_LOG="$REPO_ROOT/docs/km/Metrics_Log.md"

echo "======================================================"
echo "US-13 DORA Metrics 測試套件"
echo "======================================================"
echo ""

# ---------------------------------------------------------------------------
# AC1：sprint-review SKILL.md 新增 DORA 指標計算步驟
# ---------------------------------------------------------------------------
echo "--- AC1：SKILL.md 存在 DORA 計算子節 ---"

assert_file_exists "$SKILL_FILE" "AC1-1: SKILL.md 存在"

assert_file_contains_regex "(§2\.7|§7\.1)" "$SKILL_FILE" \
  "AC1-2: SKILL.md 存在 §2.7 或 §7.1 子節"

assert_file_contains "Deployment Frequency" "$SKILL_FILE" \
  "AC1-3: SKILL.md 包含 Deployment Frequency 指標"

assert_file_contains "Lead Time for Changes" "$SKILL_FILE" \
  "AC1-4: SKILL.md 包含 Lead Time for Changes 指標"

assert_file_contains "MTTR" "$SKILL_FILE" \
  "AC1-5: SKILL.md 包含 MTTR 指標"

assert_file_contains "Change Failure Rate" "$SKILL_FILE" \
  "AC1-6: SKILL.md 包含 Change Failure Rate 指標"

assert_file_contains "DORA" "$SKILL_FILE" \
  "AC1-7: SKILL.md 包含 DORA 關鍵字"

echo ""

# ---------------------------------------------------------------------------
# AC2：資料來源為 gh CLI，以 <dora_input> XML 標記包裹
# ---------------------------------------------------------------------------
echo "--- AC2：gh CLI 資料來源與 XML 包裹要求 ---"

assert_file_contains "gh run list" "$SKILL_FILE" \
  "AC2-1: SKILL.md 包含 gh run list 指令"

assert_file_contains "gh pr list" "$SKILL_FILE" \
  "AC2-2: SKILL.md 包含 gh pr list 指令"

assert_file_contains "gh issue list --label bug" "$SKILL_FILE" \
  "AC2-3: SKILL.md 包含 gh issue list --label bug 指令"

assert_file_contains "<dora_input>" "$SKILL_FILE" \
  "AC2-4: SKILL.md 明確標注 <dora_input> XML 包裹要求"

assert_file_contains "</dora_input>" "$SKILL_FILE" \
  "AC2-5: SKILL.md 包含 </dora_input> XML 結束標記"

assert_file_contains "ADR-006" "$SKILL_FILE" \
  "AC2-6: SKILL.md 明確引用 ADR-006 合規說明"

echo ""

# ---------------------------------------------------------------------------
# AC3：指標累積至 Metrics_Log.md
# ---------------------------------------------------------------------------
echo "--- AC3：Metrics_Log.md 包含 DORA Metrics 表格段落 ---"

assert_file_exists "$METRICS_LOG" "AC3-1: Metrics_Log.md 存在"

assert_file_contains "DORA Metrics 記錄" "$METRICS_LOG" \
  "AC3-2: Metrics_Log.md 包含「DORA Metrics 記錄」段落標題"

assert_file_contains "部署頻率" "$METRICS_LOG" \
  "AC3-3: Metrics_Log.md 包含「部署頻率」欄位"

assert_file_contains "變更前置時間" "$METRICS_LOG" \
  "AC3-4: Metrics_Log.md 包含「變更前置時間」欄位"

assert_file_contains "MTTR" "$METRICS_LOG" \
  "AC3-5: Metrics_Log.md 包含「MTTR」欄位"

assert_file_contains "變更失敗率" "$METRICS_LOG" \
  "AC3-6: Metrics_Log.md 包含「變更失敗率」欄位"

assert_file_contains "趨勢判定" "$METRICS_LOG" \
  "AC3-7: Metrics_Log.md 包含「趨勢判定」欄位"

assert_file_contains "Sprint 40" "$METRICS_LOG" \
  "AC3-8: Metrics_Log.md 包含 Sprint 40 baseline 快照記錄"

echo ""

# ---------------------------------------------------------------------------
# AC4：趨勢分析演算法與資料不足處理邏輯
# ---------------------------------------------------------------------------
echo "--- AC4：趨勢判定演算法與 fallback 邏輯 ---"

assert_file_contains "改善中" "$SKILL_FILE" \
  "AC4-1: SKILL.md 定義「改善中」趨勢判定（連升）"

assert_file_contains "退步中" "$SKILL_FILE" \
  "AC4-2: SKILL.md 定義「退步中」趨勢判定（連降）"

assert_file_contains "穩定" "$SKILL_FILE" \
  "AC4-3: SKILL.md 定義「穩定」趨勢判定（±20%）"

assert_file_contains "資料不足" "$SKILL_FILE" \
  "AC4-4: SKILL.md 包含「資料不足」fallback 說明"

assert_file_contains_regex "Sprint.*[<≥].*3" "$SKILL_FILE" \
  "AC4-5: SKILL.md 明確定義累積 Sprint 數門檻（3 個 Sprint）"

assert_file_contains "N/A" "$SKILL_FILE" \
  "AC4-6: SKILL.md 定義 MTTR 無 bug 記錄時填 N/A"

# 確認 Metrics_Log.md 中 Sprint 40 的趨勢欄包含「資料不足」（首次 baseline）
assert_file_contains "資料不足" "$METRICS_LOG" \
  "AC4-7: Metrics_Log.md Sprint 40 趨勢欄標注「資料不足」（首次 baseline）"

echo ""

# ---------------------------------------------------------------------------
# 測試結果摘要
# ---------------------------------------------------------------------------
echo "======================================================"
echo "測試結果：PASS=$PASS_COUNT / FAIL=$FAIL_COUNT / 總計=$((PASS_COUNT + FAIL_COUNT))"
echo "======================================================"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "所有測試通過 — US-13 AC 全數符合"
  exit 0
else
  echo "有 $FAIL_COUNT 個測試失敗 — 請修復後重新執行"
  exit 1
fi
