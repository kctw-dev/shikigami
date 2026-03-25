#!/usr/bin/env bash
# tests/test-a2a-protocol.sh
# #801 驗收測試：A2A Protocol — Agent-to-Agent 結構化通訊協議標準化
# TDD Red phase — 先寫測試，再實作

PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ADR_FILE="${REPO_ROOT}/docs/adr/ADR-044-a2a-protocol.md"
LIFECYCLE_PROMPT="${REPO_ROOT}/skills/sprint-execution/story-lifecycle-prompt.md"
VALIDATE_SCRIPT="${REPO_ROOT}/scripts/validate-a2a-schema.sh"

pass() {
  echo "[PASS] $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "[FAIL] $1"
  FAIL=$((FAIL + 1))
}

echo "=== #801 A2A Protocol 驗收測試 ==="
echo ""

# ── AC1: ADR-044 存在且包含 Schema 定義 ──────────────────────────────────────

echo "--- AC1: ADR-044 存在且含 Schema 定義 ---"

if [[ -f "${ADR_FILE}" ]]; then
  pass "AC1-1: ADR-044-a2a-protocol.md 存在"
else
  fail "AC1-1: ADR-044-a2a-protocol.md 不存在"
fi

if [[ -f "${ADR_FILE}" ]] && grep -q "protocol_version" "${ADR_FILE}"; then
  pass "AC1-2: ADR-044 包含 protocol_version 欄位定義"
else
  fail "AC1-2: ADR-044 缺少 protocol_version 欄位定義"
fi

if [[ -f "${ADR_FILE}" ]] && grep -q "story_id" "${ADR_FILE}"; then
  pass "AC1-3: ADR-044 包含 story_id 欄位定義"
else
  fail "AC1-3: ADR-044 缺少 story_id 欄位定義"
fi

if [[ -f "${ADR_FILE}" ]] && grep -q '"actor"' "${ADR_FILE}"; then
  pass "AC1-4: ADR-044 包含 actor 欄位定義"
else
  fail "AC1-4: ADR-044 缺少 actor 欄位定義"
fi

if [[ -f "${ADR_FILE}" ]] && grep -q '"result"' "${ADR_FILE}"; then
  pass "AC1-5: ADR-044 包含 result 欄位定義"
else
  fail "AC1-5: ADR-044 缺少 result 欄位定義"
fi

if [[ -f "${ADR_FILE}" ]] && grep -q "PASS.*FAIL.*ESCALATE\|ESCALATE.*PASS.*FAIL" "${ADR_FILE}"; then
  pass "AC1-6: ADR-044 定義 result 合法值（PASS|FAIL|ESCALATE）"
else
  fail "AC1-6: ADR-044 缺少 result 合法值定義（PASS|FAIL|ESCALATE）"
fi

if [[ -f "${ADR_FILE}" ]] && grep -q '"summary"' "${ADR_FILE}"; then
  pass "AC1-7: ADR-044 包含 summary 欄位定義"
else
  fail "AC1-7: ADR-044 缺少 summary 欄位定義"
fi

if [[ -f "${ADR_FILE}" ]] && grep -q '"artifacts"' "${ADR_FILE}"; then
  pass "AC1-8: ADR-044 包含 artifacts 欄位定義"
else
  fail "AC1-8: ADR-044 缺少 artifacts 欄位定義"
fi

if [[ -f "${ADR_FILE}" ]] && grep -q '"metrics"' "${ADR_FILE}"; then
  pass "AC1-9: ADR-044 包含 metrics 欄位定義"
else
  fail "AC1-9: ADR-044 缺少 metrics 欄位定義"
fi

if [[ -f "${ADR_FILE}" ]] && grep -q '"timestamp"' "${ADR_FILE}"; then
  pass "AC1-10: ADR-044 包含 timestamp 欄位定義"
else
  fail "AC1-10: ADR-044 缺少 timestamp 欄位定義"
fi

if [[ -f "${ADR_FILE}" ]] && grep -q "Accepted" "${ADR_FILE}"; then
  pass "AC1-11: ADR-044 狀態為 Accepted"
else
  fail "AC1-11: ADR-044 狀態非 Accepted"
fi

echo ""

# ── AC2: story-lifecycle-prompt.md §9 已更新為 A2A 格式 ─────────────────────

echo "--- AC2: story-lifecycle-prompt.md §9 含 A2A 結構化輸出格式 ---"

if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "A2A\|a2a-protocol\|ADR-044" "${LIFECYCLE_PROMPT}"; then
  pass "AC2-1: story-lifecycle-prompt.md §9 包含 A2A 協議引用"
else
  fail "AC2-1: story-lifecycle-prompt.md §9 缺少 A2A 協議引用"
fi

if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "protocol_version" "${LIFECYCLE_PROMPT}"; then
  pass "AC2-2: story-lifecycle-prompt.md 包含 protocol_version 欄位"
else
  fail "AC2-2: story-lifecycle-prompt.md 缺少 protocol_version 欄位"
fi

# NFR1: 確認既有欄位仍存在（向後相容）
if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "PASS\|FAIL\|ESCALATE" "${LIFECYCLE_PROMPT}"; then
  pass "AC2-3（NFR1）: story-lifecycle-prompt.md 保留既有 PASS/FAIL/ESCALATE 結果格式"
else
  fail "AC2-3（NFR1）: story-lifecycle-prompt.md 缺少既有 PASS/FAIL/ESCALATE 格式"
fi

if [[ -f "${LIFECYCLE_PROMPT}" ]] && grep -q "story_id\|Story ID" "${LIFECYCLE_PROMPT}"; then
  pass "AC2-4（NFR1）: story-lifecycle-prompt.md 保留 story_id 欄位（向後相容）"
else
  fail "AC2-4（NFR1）: story-lifecycle-prompt.md 缺少 story_id 欄位"
fi

echo ""

# ── AC3: validate-a2a-schema.sh 存在且可執行 ────────────────────────────────

echo "--- AC3: validate-a2a-schema.sh 驗證腳本 ---"

if [[ -f "${VALIDATE_SCRIPT}" ]]; then
  pass "AC3-1: validate-a2a-schema.sh 存在"
else
  fail "AC3-1: validate-a2a-schema.sh 不存在"
fi

if [[ -f "${VALIDATE_SCRIPT}" ]] && [[ -x "${VALIDATE_SCRIPT}" ]]; then
  pass "AC3-2: validate-a2a-schema.sh 可執行"
else
  fail "AC3-2: validate-a2a-schema.sh 不可執行"
fi

# 測試合法輸入（包含所有必要欄位）
if [[ -f "${VALIDATE_SCRIPT}" ]]; then
  VALID_JSON_FILE="$(mktemp /tmp/a2a-valid-XXXX.json)"
  cat > "${VALID_JSON_FILE}" << 'EOF'
{
  "protocol_version": "1.0",
  "story_id": 801,
  "actor": "developer",
  "result": "PASS",
  "summary": "A2A Protocol 實作完成",
  "artifacts": [],
  "metrics": {
    "tests_total": 10,
    "tests_passed": 10,
    "files_created": 3,
    "files_modified": 1
  },
  "timestamp": "2026-03-25T22:00:00+08:00"
}
EOF

  if bash "${VALIDATE_SCRIPT}" "${VALID_JSON_FILE}" 2>&1 | grep -q "PASS"; then
    pass "AC3-3: validate-a2a-schema.sh 對合法 JSON 輸出 PASS"
  else
    fail "AC3-3: validate-a2a-schema.sh 對合法 JSON 未輸出 PASS"
  fi
  rm -f "${VALID_JSON_FILE}"
fi

# 測試非法輸入（缺少必要欄位）
if [[ -f "${VALIDATE_SCRIPT}" ]]; then
  INVALID_JSON_FILE="$(mktemp /tmp/a2a-invalid-XXXX.json)"
  cat > "${INVALID_JSON_FILE}" << 'EOF'
{
  "story_id": 999,
  "result": "PASS"
}
EOF

  if bash "${VALIDATE_SCRIPT}" "${INVALID_JSON_FILE}" 2>&1 | grep -q "FAIL"; then
    pass "AC3-4: validate-a2a-schema.sh 對缺少必要欄位的 JSON 輸出 FAIL"
  else
    fail "AC3-4: validate-a2a-schema.sh 對缺少必要欄位的 JSON 未輸出 FAIL"
  fi
  rm -f "${INVALID_JSON_FILE}"
fi

# 測試非法 result 值
if [[ -f "${VALIDATE_SCRIPT}" ]]; then
  INVALID_RESULT_FILE="$(mktemp /tmp/a2a-invalid-result-XXXX.json)"
  cat > "${INVALID_RESULT_FILE}" << 'EOF'
{
  "protocol_version": "1.0",
  "story_id": 999,
  "actor": "developer",
  "result": "UNKNOWN",
  "summary": "test",
  "timestamp": "2026-03-25T00:00:00Z"
}
EOF

  if bash "${VALIDATE_SCRIPT}" "${INVALID_RESULT_FILE}" 2>&1 | grep -q "FAIL"; then
    pass "AC3-5: validate-a2a-schema.sh 對非法 result 值輸出 FAIL"
  else
    fail "AC3-5: validate-a2a-schema.sh 對非法 result 值未輸出 FAIL"
  fi
  rm -f "${INVALID_RESULT_FILE}"
fi

# 測試非法 JSON
if [[ -f "${VALIDATE_SCRIPT}" ]]; then
  INVALID_FORMAT_FILE="$(mktemp /tmp/a2a-invalid-format-XXXX.json)"
  printf '%s\n' "not valid json" > "${INVALID_FORMAT_FILE}"

  if bash "${VALIDATE_SCRIPT}" "${INVALID_FORMAT_FILE}" 2>&1 | grep -q "FAIL"; then
    pass "AC3-6: validate-a2a-schema.sh 對非法 JSON 格式輸出 FAIL"
  else
    fail "AC3-6: validate-a2a-schema.sh 對非法 JSON 格式未輸出 FAIL"
  fi
  rm -f "${INVALID_FORMAT_FILE}"
fi

echo ""

# ── 總結 ──────────────────────────────────────────────────────────────────────

TOTAL=$((PASS + FAIL))
echo "=============================="
echo " #801 A2A Protocol 測試總結"
echo " 通過：${PASS}/${TOTAL}"
echo " 失敗：${FAIL}/${TOTAL}"
if [[ ${FAIL} -eq 0 ]]; then
  echo " 結果：全部 PASS"
else
  echo " 結果：FAIL（${FAIL} 項未通過）"
fi
echo "=============================="

exit ${FAIL}
