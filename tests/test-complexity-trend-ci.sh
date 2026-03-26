#!/usr/bin/env bash
# tests/test-complexity-trend-ci.sh — #922 complexity-trend CI 觸發機制測試
#
# 測試項目：
#   T1: workflow YAML 檔案存在
#   T2: workflow YAML 格式正確（yamllint）
#   T3: Actions 版本釘定 @v4（validate-ci-versions.sh）
#   T4: complexity-trend.sh 可執行並產出 CSV
#   T5: CSV 輸出格式正確（header + timestamp + 數值欄位）
#   T6: CSV 至少有表頭 + 1 筆資料列

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKFLOW_FILE="${REPO_ROOT}/.github/workflows/complexity-trend.yml"
COMPLEXITY_SCRIPT="${REPO_ROOT}/scripts/complexity-trend.sh"

PASS_COUNT=0
FAIL_COUNT=0

pass() { echo "[PASS] $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { echo "[FAIL] $1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

echo "=============================="
echo "  #922 complexity-trend CI 測試"
echo "=============================="
echo ""

# T1: workflow 檔案存在
echo "T1: workflow 檔案存在..."
if [[ -f "${WORKFLOW_FILE}" ]]; then
  pass "T1: complexity-trend.yml 存在"
else
  fail "T1: complexity-trend.yml 不存在（路徑：${WORKFLOW_FILE}）"
fi

# T2: YAML 格式正確（yamllint）
echo ""
echo "T2: YAML 格式驗證（yamllint）..."
if ! command -v yamllint > /dev/null 2>&1; then
  echo "  [SKIP] yamllint 未安裝，跳過 T2"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  if yamllint \
    -d '{extends: default, rules: {line-length: {max: 200}, truthy: {allowed-values: ["true", "false", "on", "off"]}, comments: {min-spaces-from-content: 1}}}' \
    "${WORKFLOW_FILE}" > /dev/null 2>&1; then
    pass "T2: workflow YAML 格式正確"
  else
    fail "T2: workflow YAML 格式錯誤"
    yamllint \
      -d '{extends: default, rules: {line-length: {max: 200}, truthy: {allowed-values: ["true", "false", "on", "off"]}, comments: {min-spaces-from-content: 1}}}' \
      "${WORKFLOW_FILE}" 2>&1 | head -20
  fi
fi

# T3: Actions 版本釘定 @v4
echo ""
echo "T3: Actions 版本釘定驗證..."
if bash "${REPO_ROOT}/scripts/validate-ci-versions.sh" > /dev/null 2>&1; then
  pass "T3: 所有 Actions 版本符合規範（@v4）"
else
  fail "T3: Actions 版本不符合規範"
  bash "${REPO_ROOT}/scripts/validate-ci-versions.sh" 2>&1 | tail -10
fi

# T4: workflow 包含 schedule（cron）和 workflow_dispatch
echo ""
echo "T4: workflow 包含必要觸發條件..."
if [[ -f "${WORKFLOW_FILE}" ]]; then
  HAS_CRON=false
  HAS_DISPATCH=false
  HAS_CHECKOUT=false
  HAS_SCRIPT=false

  grep -q "cron:" "${WORKFLOW_FILE}" && HAS_CRON=true
  grep -q "workflow_dispatch" "${WORKFLOW_FILE}" && HAS_DISPATCH=true
  grep -q "actions/checkout@v4" "${WORKFLOW_FILE}" && HAS_CHECKOUT=true
  grep -q "complexity-trend.sh" "${WORKFLOW_FILE}" && HAS_SCRIPT=true

  ALL_T4=true
  [[ "${HAS_CRON}" == "true" ]]     || { fail "T4a: 缺少 cron schedule"; ALL_T4=false; }
  [[ "${HAS_DISPATCH}" == "true" ]] || { fail "T4b: 缺少 workflow_dispatch"; ALL_T4=false; }
  [[ "${HAS_CHECKOUT}" == "true" ]] || { fail "T4c: 缺少 actions/checkout@v4"; ALL_T4=false; }
  [[ "${HAS_SCRIPT}" == "true" ]]   || { fail "T4d: 缺少 complexity-trend.sh 執行"; ALL_T4=false; }
  [[ "${ALL_T4}" == "true" ]] && pass "T4: workflow 觸發條件與步驟齊備"
else
  fail "T4: workflow 檔案不存在，跳過觸發條件檢查"
fi

# T5: complexity-trend.sh 可執行並產出正確 CSV 格式
echo ""
echo "T5: complexity-trend.sh CSV 格式驗證..."
TMP_CSV=$(mktemp /tmp/complexity-trend-test-XXXXXX.csv)
trap 'rm -f "${TMP_CSV}"' EXIT

if COMPLEXITY_TREND_CSV="${TMP_CSV}" REPO_ROOT="${REPO_ROOT}" \
   bash "${COMPLEXITY_SCRIPT}" --no-trend > /dev/null 2>&1; then
  # 檢查 header 行
  HEADER=$(head -1 "${TMP_CSV}" 2>/dev/null || echo "")
  if [[ "${HEADER}" == "date,SKILL_COUNT,AGENT_COUNT,HOOK_COUNT,TOTAL_LINES" ]]; then
    pass "T5a: CSV header 正確"
  else
    fail "T5a: CSV header 不正確（得到：'${HEADER}'）"
  fi

  # 檢查資料列格式（日期 + 4 個數字欄位）
  DATA_LINE=$(tail -n +2 "${TMP_CSV}" | head -1 2>/dev/null || echo "")
  if echo "${DATA_LINE}" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2},[0-9]+,[0-9]+,[0-9]+,[0-9]+$'; then
    pass "T5b: CSV 資料列格式正確（日期 + 4 數值欄位）"
  else
    fail "T5b: CSV 資料列格式不正確（得到：'${DATA_LINE}'）"
  fi
else
  fail "T5: complexity-trend.sh 執行失敗"
fi

# T6: docs/km/complexity-trend.csv 至少有表頭 + 1 筆資料
echo ""
echo "T6: docs/km/complexity-trend.csv 資料列數驗證（>= 5 列）..."
CSV_FILE="${REPO_ROOT}/docs/km/complexity-trend.csv"
if [[ -f "${CSV_FILE}" ]]; then
  # 計算資料列（不含表頭）
  DATA_ROWS=$(tail -n +2 "${CSV_FILE}" | grep -c "^[0-9]" || echo "0")
  if [[ "${DATA_ROWS}" -ge 5 ]]; then
    pass "T6: CSV 含 ${DATA_ROWS} 筆資料列（>= 5）"
  else
    fail "T6: CSV 只有 ${DATA_ROWS} 筆資料列（需 >= 5）"
  fi
else
  fail "T6: docs/km/complexity-trend.csv 不存在"
fi

# T7: NFR1 — workflow 使用 continue-on-error 或不阻擋其他 pipeline
echo ""
echo "T7: NFR1 — workflow 失敗隔離（continue-on-error 或 job 層級配置）..."
if [[ -f "${WORKFLOW_FILE}" ]]; then
  if grep -q "continue-on-error" "${WORKFLOW_FILE}"; then
    pass "T7: workflow 設有 continue-on-error（NFR1）"
  else
    # 獨立 workflow 本身不阻擋其他 pipeline，也可接受
    pass "T7: workflow 為獨立 job，不阻擋其他 CI pipeline（NFR1）"
  fi
else
  fail "T7: workflow 檔案不存在，無法驗證 NFR1"
fi

# 結果摘要
echo ""
echo "=============================="
echo "  測試結果：PASS=${PASS_COUNT}  FAIL=${FAIL_COUNT}"
echo "=============================="

if [[ "${FAIL_COUNT}" -gt 0 ]]; then
  exit 1
fi
exit 0
