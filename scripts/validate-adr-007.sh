#!/usr/bin/env bash
# scripts/validate-adr-007.sh
# US-39 AC 驗證腳本：ADR-007 Story 生命週期 Subagent 封裝
#
# 驗證 docs/adr/ADR-007-story-lifecycle-subagent.md 是否符合 US-39 所有 AC：
#   AC1：ADR-007 存在，狀態為 Accepted，包含至少 3 個選項
#         (A) 現有基準、(B) 完整 Story-Lifecycle subagent、(C) 至少一個替代方案
#   AC2：包含 Story-Lifecycle subagent 最小介面契約：
#         (a) 輸入格式、(b) 輸出格式（PASS/FAIL + 摘要 + 修改檔案清單 + commit SHA）
#         (c) 錯誤/升級輸出（escalation output）
#   AC3：定義審查獨立性補償機制，含可量測元素：
#         抽樣百分比、觸發條件、文件位置
#   AC4：明確定義 M/L size Stories 的 context overflow 回退策略（fallback strategy）
#
# 使用方式：
#   bash scripts/validate-adr-007.sh
#   （在專案根目錄下執行）
#
# Exit code:
#   0 = 全部通過（PASS）
#   1 = 有 ERROR

set -uo pipefail

source "$(dirname "$0")/lib/validate-helpers.sh"

# ---------------------------------------------------------------------------
# 常數
# ---------------------------------------------------------------------------
readonly ADR_FILE="docs/adr/ADR-007-story-lifecycle-subagent.md"

# ---------------------------------------------------------------------------
# 狀態追蹤
# ---------------------------------------------------------------------------
EXIT_CODE=0
ERROR_COUNT=0

# ---------------------------------------------------------------------------
# 前置檢查：ADR 檔案必須存在
# ---------------------------------------------------------------------------
preflight_check() {
  if [ ! -f "$ADR_FILE" ]; then
    print_error "找不到 ADR-007 檔案：$ADR_FILE"
    exit 1
  fi
  print_info "ADR-007 檔案存在：$ADR_FILE"
}

# ---------------------------------------------------------------------------
# AC1：ADR 基本結構驗證
# ---------------------------------------------------------------------------

# AC1a：狀態必須為 Accepted
validate_ac1_status_accepted() {
  if grep -q "^\*\*狀態\*\*：Accepted" "$ADR_FILE"; then
    print_pass "AC1a：ADR-007 狀態為 Accepted"
  else
    print_fail "AC1a：ADR-007 狀態不是 Accepted（必須包含 '**狀態**：Accepted'）"
  fi
}

# AC1b：包含選項 A（現有基準 / current baseline）
validate_ac1_option_a() {
  if grep -qi "current baseline\|現有基準" "$ADR_FILE"; then
    print_pass "AC1b：ADR-007 包含選項 A（現有基準 / current baseline）"
  else
    print_fail "AC1b：ADR-007 缺少選項 A（現有基準 / current baseline）"
  fi
}

# AC1c：包含選項 B（完整 Story-Lifecycle subagent）
validate_ac1_option_b() {
  if grep -qi "Story-Lifecycle subagent\|story lifecycle subagent" "$ADR_FILE"; then
    print_pass "AC1c：ADR-007 包含選項 B（完整 Story-Lifecycle subagent）"
  else
    print_fail "AC1c：ADR-007 缺少選項 B（Story-Lifecycle subagent）"
  fi
}

# AC1d：包含至少一個替代方案（選項 C）
validate_ac1_option_c() {
  # 驗證存在選項 C 相關描述（部分封裝、分段委派、或其他替代方案）
  if grep -qiE "選項 C|Option C|部分封裝|分段委派|修復循環隔離" "$ADR_FILE"; then
    print_pass "AC1d：ADR-007 包含選項 C（替代方案）"
  else
    print_fail "AC1d：ADR-007 缺少選項 C（至少一個替代方案）"
  fi
}

# AC1e：至少 3 個選項（驗證數量）
validate_ac1_option_count() {
  local option_count
  # 計算「選項 A」「選項 B」「選項 C」等的出現次數（每個至少出現一次）
  local has_a has_b has_c
  has_a=$(grep -c "選項 A：\|### 選項 A" "$ADR_FILE" 2>/dev/null || echo 0)
  has_b=$(grep -c "選項 B：\|### 選項 B" "$ADR_FILE" 2>/dev/null || echo 0)
  has_c=$(grep -c "選項 C：\|### 選項 C" "$ADR_FILE" 2>/dev/null || echo 0)

  option_count=0
  [ "$has_a" -gt 0 ] && option_count=$((option_count + 1))
  [ "$has_b" -gt 0 ] && option_count=$((option_count + 1))
  [ "$has_c" -gt 0 ] && option_count=$((option_count + 1))

  if [ "$option_count" -ge 3 ]; then
    print_pass "AC1e：ADR-007 包含至少 3 個選項（實際：${option_count} 個）"
  else
    print_fail "AC1e：ADR-007 選項數量不足（要求 ≥3，實際：${option_count}）"
  fi
}

# ---------------------------------------------------------------------------
# AC2：介面契約驗證
# ---------------------------------------------------------------------------

# AC2a：包含輸入格式定義（story_id 或 Sprint 文件路徑等）
validate_ac2_input_format() {
  if grep -qi "輸入格式\|input.*format\|story_id\|sprint_file" "$ADR_FILE"; then
    print_pass "AC2a：ADR-007 包含輸入格式定義（story_id 或 sprint_file 等）"
  else
    print_fail "AC2a：ADR-007 缺少輸入格式定義（需包含 story_id、sprint_file 等欄位說明）"
  fi
}

# AC2b：輸出格式包含 PASS/FAIL
validate_ac2_output_pass_fail() {
  if grep -q "PASS\|FAIL" "$ADR_FILE"; then
    print_pass "AC2b：ADR-007 輸出格式包含 PASS/FAIL 結論"
  else
    print_fail "AC2b：ADR-007 輸出格式缺少 PASS/FAIL 結論"
  fi
}

# AC2b：輸出格式包含摘要（一句話摘要或摘要欄位）
validate_ac2_output_summary() {
  if grep -qi "摘要\|summary\|一句話" "$ADR_FILE"; then
    print_pass "AC2b：ADR-007 輸出格式包含摘要欄位"
  else
    print_fail "AC2b：ADR-007 輸出格式缺少摘要欄位"
  fi
}

# AC2b：輸出格式包含修改檔案清單
validate_ac2_output_files() {
  if grep -qi "修改檔案\|files.*changed\|changed.*files\|修改.*清單" "$ADR_FILE"; then
    print_pass "AC2b：ADR-007 輸出格式包含修改檔案清單"
  else
    print_fail "AC2b：ADR-007 輸出格式缺少修改檔案清單"
  fi
}

# AC2b：輸出格式包含 commit SHA
validate_ac2_output_commit_sha() {
  if grep -qi "commit SHA\|commit sha\|Commit SHA" "$ADR_FILE"; then
    print_pass "AC2b：ADR-007 輸出格式包含 commit SHA"
  else
    print_fail "AC2b：ADR-007 輸出格式缺少 commit SHA"
  fi
}

# AC2c：包含錯誤/升級輸出定義（escalation output）
validate_ac2_escalation_output() {
  if grep -qi "escalat\|升級\|ESCALATE" "$ADR_FILE"; then
    print_pass "AC2c：ADR-007 包含錯誤/升級輸出（escalation output）定義"
  else
    print_fail "AC2c：ADR-007 缺少錯誤/升級輸出（escalation output）定義"
  fi
}

# AC2c：升級輸出定義何時回傳主 session 處理
validate_ac2_escalation_conditions() {
  if grep -qiE "升級類型|升級原因|DESIGN_ISSUE|CONTEXT_OVERFLOW|REQUIREMENT_AMBIGUITY|何時.*回傳|回傳.*主.*session" "$ADR_FILE"; then
    print_pass "AC2c：ADR-007 定義了升級至主 session 的條件"
  else
    print_fail "AC2c：ADR-007 缺少升級至主 session 的條件定義"
  fi
}

# ---------------------------------------------------------------------------
# AC3：審查獨立性補償機制驗證
# ---------------------------------------------------------------------------

# AC3a：包含抽樣百分比（sampling percentage）
validate_ac3_sampling_percentage() {
  if grep -qiE "抽樣.*[0-9]+%|sampling.*[0-9]+%|[0-9]+%.*抽樣" "$ADR_FILE"; then
    print_pass "AC3a：ADR-007 包含抽樣百分比（sampling percentage）"
  else
    print_fail "AC3a：ADR-007 缺少抽樣百分比定義（需包含具體百分比，如 30%）"
  fi
}

# AC3b：包含觸發條件（trigger conditions）
validate_ac3_trigger_conditions() {
  if grep -qiE "觸發條件|trigger condition|TC-[0-9]|觸發.*審查" "$ADR_FILE"; then
    print_pass "AC3b：ADR-007 包含審查獨立性補償的觸發條件"
  else
    print_fail "AC3b：ADR-007 缺少審查獨立性補償的觸發條件"
  fi
}

# AC3c：包含文件位置（mechanism documentation location）
validate_ac3_documentation_location() {
  # 機制定義的文件路徑應在 ADR 中被引用
  if grep -qiE "skills/sprint-execution/SKILL\.md|SKILL\.md.*AC3|文件位置|定義位置" "$ADR_FILE"; then
    print_pass "AC3c：ADR-007 包含補償機制的文件位置說明"
  else
    print_fail "AC3c：ADR-007 缺少補償機制的文件位置說明（需指向機制定義所在的文件路徑）"
  fi
}

# ---------------------------------------------------------------------------
# AC4：Context Overflow Fallback Strategy 驗證
# ---------------------------------------------------------------------------

# AC4a：包含 M-size Story 的 fallback 策略
validate_ac4_m_size_fallback() {
  if grep -qiE "M.size|M size|M-size" "$ADR_FILE"; then
    print_pass "AC4a：ADR-007 包含 M-size Story 的 fallback 策略說明"
  else
    print_fail "AC4a：ADR-007 缺少 M-size Story 的 fallback 策略"
  fi
}

# AC4b：包含 L-size Story 的 fallback 策略
validate_ac4_l_size_fallback() {
  if grep -qiE "L.size|L size|L-size" "$ADR_FILE"; then
    print_pass "AC4b：ADR-007 包含 L-size Story 的 fallback 策略說明"
  else
    print_fail "AC4b：ADR-007 缺少 L-size Story 的 fallback 策略"
  fi
}

# AC4c：說明 context 接近上限時的處理方式
validate_ac4_overflow_handling() {
  if grep -qiE "context.*overflow|overflow.*context|context.*上限|上限.*context|overflow 回退|回退策略" "$ADR_FILE"; then
    print_pass "AC4c：ADR-007 說明 context 接近上限時的處理方式（fallback strategy）"
  else
    print_fail "AC4c：ADR-007 缺少 context 接近上限時的處理方式說明"
  fi
}

# AC4d：fallback 策略有具體操作步驟（非僅概念描述）
validate_ac4_concrete_steps() {
  # 驗證是否有明確的操作性描述（分批、分段、緊急回退等）
  if grep -qiE "分批|分段提交|批次|PARTIAL_PASS|緊急回退|Overflow 緊急" "$ADR_FILE"; then
    print_pass "AC4d：ADR-007 fallback 策略包含具體操作步驟"
  else
    print_fail "AC4d：ADR-007 fallback 策略缺少具體操作步驟（需描述分批、回退等操作方式）"
  fi
}

# ---------------------------------------------------------------------------
# 主程式
# ---------------------------------------------------------------------------
main() {
  print_banner "ADR-007 驗證 — US-39 Acceptance Criteria"

  preflight_check

  print_section "AC1：ADR 基本結構與選項驗證"
  validate_ac1_status_accepted
  validate_ac1_option_a
  validate_ac1_option_b
  validate_ac1_option_c
  validate_ac1_option_count

  print_section "AC2：介面契約驗證"
  validate_ac2_input_format
  validate_ac2_output_pass_fail
  validate_ac2_output_summary
  validate_ac2_output_files
  validate_ac2_output_commit_sha
  validate_ac2_escalation_output
  validate_ac2_escalation_conditions

  print_section "AC3：審查獨立性補償機制驗證"
  validate_ac3_sampling_percentage
  validate_ac3_trigger_conditions
  validate_ac3_documentation_location

  print_section "AC4：Context Overflow Fallback Strategy 驗證"
  validate_ac4_m_size_fallback
  validate_ac4_l_size_fallback
  validate_ac4_overflow_handling
  validate_ac4_concrete_steps

  echo ""
  echo "==============================="
  if [ "$EXIT_CODE" -eq 0 ]; then
    echo " 結果：全部通過（PASS）"
    echo " 錯誤數：0"
  else
    echo " 結果：驗證失敗（FAIL）"
    echo " 錯誤數：${ERROR_COUNT}"
  fi
  echo "==============================="
}

main

exit "$EXIT_CODE"
