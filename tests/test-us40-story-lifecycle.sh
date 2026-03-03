#!/usr/bin/env bash
# test-us40-story-lifecycle.sh
# US-40 驗收測試：Story-Lifecycle Subagent 實作 — ADR-007 Phase 1
# TDD Red phase — 先寫測試，再實作

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SKILL_DIR="${REPO_ROOT}/skills/sprint-execution"
LIFECYCLE_PROMPT="${SKILL_DIR}/story-lifecycle-prompt.md"
SKILL_MD="${SKILL_DIR}/SKILL.md"

pass() {
  echo "[PASS] $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "[FAIL] $1"
  FAIL=$((FAIL + 1))
}

echo "=== US-40 Story-Lifecycle Subagent 驗收測試 ==="
echo ""

# ── AC1: story-lifecycle-prompt.md 存在且非空 ─────────────────────────────

echo "--- AC1: story-lifecycle-prompt.md 建立 ---"

if [[ -f "${LIFECYCLE_PROMPT}" ]]; then
  pass "AC1-1: story-lifecycle-prompt.md 存在"
else
  fail "AC1-1: story-lifecycle-prompt.md 不存在（路徑：${LIFECYCLE_PROMPT}）"
fi

if [[ -f "${LIFECYCLE_PROMPT}" ]] && [[ -s "${LIFECYCLE_PROMPT}" ]]; then
  pass "AC1-2: story-lifecycle-prompt.md 非空"
else
  fail "AC1-2: story-lifecycle-prompt.md 為空或不存在"
fi

# AC1: 角色定義
if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "Story-Lifecycle" "${LIFECYCLE_PROMPT}"; then
  pass "AC1-3: prompt 含 Story-Lifecycle 角色定義"
else
  fail "AC1-3: prompt 缺少 Story-Lifecycle 角色定義"
fi

# AC1: 輸入格式說明（Story ID、AC 清單、相關檔案路徑）
if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "story_id\|Story ID" "${LIFECYCLE_PROMPT}"; then
  pass "AC1-4: prompt 含輸入格式 story_id 說明"
else
  fail "AC1-4: prompt 缺少輸入格式 story_id 說明"
fi

if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "sprint_file\|AC 清單\|ac_list" "${LIFECYCLE_PROMPT}"; then
  pass "AC1-5: prompt 含輸入格式 AC 清單說明"
else
  fail "AC1-5: prompt 缺少輸入格式 AC 清單說明"
fi

if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "related_adrs\|related_sdds\|檔案路徑" "${LIFECYCLE_PROMPT}"; then
  pass "AC1-6: prompt 含輸入格式相關檔案路徑說明"
else
  fail "AC1-6: prompt 缺少輸入格式相關檔案路徑說明"
fi

# AC1: 輸出格式說明（PASS/FAIL + 摘要 + 修改檔案清單 + commit SHA）
if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -qE "PASS|FAIL" "${LIFECYCLE_PROMPT}"; then
  pass "AC1-7: prompt 含輸出格式 PASS/FAIL 說明"
else
  fail "AC1-7: prompt 缺少輸出格式 PASS/FAIL 說明"
fi

if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "commit_sha\|Commit SHA" "${LIFECYCLE_PROMPT}"; then
  pass "AC1-8: prompt 含輸出格式 commit SHA 說明"
else
  fail "AC1-8: prompt 缺少輸出格式 commit SHA 說明"
fi

if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "modified_files\|修改檔案清單" "${LIFECYCLE_PROMPT}"; then
  pass "AC1-9: prompt 含輸出格式修改檔案清單說明"
else
  fail "AC1-9: prompt 缺少輸出格式修改檔案清單說明"
fi

# AC1: 錯誤升級條件（escalation triggers）
if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -qE "ESCALATE|escalation|升級" "${LIFECYCLE_PROMPT}"; then
  pass "AC1-10: prompt 含錯誤升級條件（escalation triggers）"
else
  fail "AC1-10: prompt 缺少錯誤升級條件（escalation triggers）"
fi

# AC1: Developer TDD 章節
if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -qE "Red.*Green.*Refactor|TDD.*循環|TDD 流程" "${LIFECYCLE_PROMPT}"; then
  pass "AC1-11: prompt 含 Developer TDD 章節"
else
  fail "AC1-11: prompt 缺少 Developer TDD 章節"
fi

# AC1: self-review 章節（Spec Compliance, Code Quality, Security conditional）
if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "Spec Compliance" "${LIFECYCLE_PROMPT}"; then
  pass "AC1-12: prompt 含 Spec Compliance self-review 章節"
else
  fail "AC1-12: prompt 缺少 Spec Compliance self-review 章節"
fi

if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "Code Quality" "${LIFECYCLE_PROMPT}"; then
  pass "AC1-13: prompt 含 Code Quality self-review 章節"
else
  fail "AC1-13: prompt 缺少 Code Quality self-review 章節"
fi

if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "Security" "${LIFECYCLE_PROMPT}"; then
  pass "AC1-14: prompt 含 Security self-review 章節（含觸發條件）"
else
  fail "AC1-14: prompt 缺少 Security self-review 章節"
fi

# AC1: ADR-007 介面契約參考
if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "ADR-007" "${LIFECYCLE_PROMPT}"; then
  pass "AC1-15: prompt 含 ADR-007 介面契約參考"
else
  fail "AC1-15: prompt 缺少 ADR-007 介面契約參考"
fi

echo ""

# ── AC2: SKILL.md §3 更新含 ASCII flow diagram ───────────────────────────

echo "--- AC2: SKILL.md §3 更新含 ASCII flow diagram ---"

# §3 引用 story-lifecycle-prompt.md
if grep -q "story-lifecycle-prompt.md" "${SKILL_MD}"; then
  pass "AC2-1: SKILL.md §3 引用 story-lifecycle-prompt.md"
else
  fail "AC2-1: SKILL.md §3 未引用 story-lifecycle-prompt.md"
fi

# ASCII flow diagram 含 Story-Lifecycle subagent 派遣節點
if grep -q "Story-Lifecycle" "${SKILL_MD}"; then
  pass "AC2-2: SKILL.md 含 Story-Lifecycle subagent 節點"
else
  fail "AC2-2: SKILL.md 缺少 Story-Lifecycle subagent 節點"
fi

# ASCII flow diagram 存在（含圖形字元或 ASCII art 格式）
if grep -qE "\+--|-->|──|├─|└─" "${SKILL_MD}"; then
  pass "AC2-3: SKILL.md 含 ASCII flow diagram 格式字元"
else
  fail "AC2-3: SKILL.md 缺少 ASCII flow diagram 格式字元"
fi

# §2 tagline 已更新，不再只是「雙階段審查」舊模型描述
if grep -q "Story-Lifecycle" "${SKILL_MD}"; then
  pass "AC2-4: SKILL.md 已更新以反映 Story-Lifecycle 模型"
else
  fail "AC2-4: SKILL.md 未更新以反映 Story-Lifecycle 模型"
fi

# developer-prompt.md 仍然存在（backward compatibility 保留）
DEVELOPER_PROMPT="${SKILL_DIR}/developer-prompt.md"
if [[ -f "${DEVELOPER_PROMPT}" ]]; then
  pass "AC2-5: developer-prompt.md 保留（backward compatibility）"
else
  fail "AC2-5: developer-prompt.md 不存在，違反保留要求"
fi

echo ""

# ── AC3: 介面契約內嵌 YAML schema ────────────────────────────────────────

echo "--- AC3: 介面契約內嵌 YAML schema ---"

# YAML schema 含 input schema（story_id, ac list, file paths）
check_schema_field() {
  local field="$1"
  local desc="$2"
  local found=0

  if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "${field}" "${LIFECYCLE_PROMPT}"; then
    found=1
  elif grep -q "${field}" "${SKILL_MD}"; then
    found=1
  fi

  if [[ "${found}" -eq 1 ]]; then
    pass "AC3: schema 含 ${desc} (${field})"
  else
    fail "AC3: schema 缺少 ${desc} (${field})"
  fi
}

check_schema_field "story_id" "input: story_id"
check_schema_field "sprint_file" "input: sprint_file"
check_schema_field "related_adrs" "input: related_adrs"
check_schema_field "doc_only" "input: doc_only"
check_schema_field "size" "input: size"
check_schema_field "bypass" "input: bypass"
check_schema_field "status" "output: status"
check_schema_field "summary" "output: summary"
check_schema_field "modified_files" "output: modified_files"
check_schema_field "commit_sha" "output: commit_sha"
check_schema_field "escalation" "output: escalation"

# Phase 1 sampling placeholder（TODO marker）
if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "TODO.*AC3.*sampling\|TODO.*sampling.*ADR-007" "${LIFECYCLE_PROMPT}"; then
  pass "AC3: Phase 1 sampling TODO placeholder 存在（story-lifecycle-prompt.md）"
elif grep -q "TODO.*AC3.*sampling\|TODO.*sampling.*ADR-007" "${SKILL_MD}"; then
  pass "AC3: Phase 1 sampling TODO placeholder 存在（SKILL.md）"
else
  fail "AC3: 缺少 Phase 1 sampling TODO placeholder"
fi

echo ""

# ── AC4: 現有測試套件（N/A 確認）────────────────────────────────────────

echo "--- AC4: 現有測試套件驗證 ---"

# 確認 developer-prompt.md 仍存在（backward compatibility critical check）
if [[ -f "${DEVELOPER_PROMPT}" ]]; then
  pass "AC4-1: developer-prompt.md 未被刪除"
else
  fail "AC4-1: developer-prompt.md 被刪除，違反 backward compatibility 要求"
fi

# story-lifecycle-prompt.md 是新建而非替換
if [[ -f "${LIFECYCLE_PROMPT}" ]] && [[ -f "${DEVELOPER_PROMPT}" ]]; then
  pass "AC4-2: 兩個 prompt 並存（新建而非替換）"
else
  fail "AC4-2: 並存條件不滿足"
fi

echo ""

# ── 結果摘要 ─────────────────────────────────────────────────────────────

echo "=== 測試結果摘要 ==="
echo "通過：${PASS}"
echo "失敗：${FAIL}"
echo ""

if [[ "${FAIL}" -eq 0 ]]; then
  echo "[ALL PASS] US-40 所有驗收測試通過"
  exit 0
else
  echo "[FAIL] ${FAIL} 項測試未通過"
  exit 1
fi
