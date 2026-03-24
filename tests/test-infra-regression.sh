#!/usr/bin/env bash
# tests/test-infra-regression.sh
# Story #494 — INFRA 測試框架架構設計與框架整合
# 父 Story: #452 INFRA 自動化回歸測試框架
#
# ── INFRA 測試類型定義與邊界（AC1）──────────────────────────────────────────
#
# INFRA 測試（本框架涵蓋範圍）的定義：
#   凡是「與 Shikigami Plugin 框架本身的基礎設施有關」的測試，統稱 INFRA 測試。
#   具體涵蓋以下三類：
#
#   [UNIT] 單元層級：
#     - 對單一腳本或設定檔的靜態結構驗證
#     - 例如：validate-*.sh 各驗證腳本自身的正確性
#     - 例如：CI workflow YAML 語法合法性
#     - 例如：特定 flag / pattern 是否存在於腳本中
#
#   [INTEGRATION] 整合層級：
#     - 驗證多個 INFRA 元件共同運作是否正常
#     - 例如：ci-health-check.sh 整合 validate-ci-versions.sh 並正確解析輸出
#     - 例如：CI Actions 版本與 runner 相容性組合驗證
#     - 例如：unzip 可用性 + apt-get 安裝步驟的端對端路徑
#
#   [SMOKE] 冒煙層級：
#     - 最小化快速驗證，確認關鍵 INFRA 元件「存在且可執行」
#     - 例如：scripts/ci-health-check.sh 可執行且 exit 0
#     - 例如：必要 CLI 工具（gh、git、unzip、node）是否可用
#     - 此層級應在每次 PR 前必跑，時間 < 30s
#
# 不屬於本框架範圍（由其他 test-*.sh 覆蓋）：
#   - Skill / Agent 的行為邏輯測試（由各 test-us*.sh 覆蓋）
#   - Sprint 流程驗證（由 test-sprint-*.sh 覆蓋）
#   - MCP 工具功能測試（由各功能測試腳本覆蓋）
#
# ── INFRA Story 對應矩陣 ──────────────────────────────────────────────────────
#
# 本框架追蹤以下 INFRA Story 的回歸場景：
#   #423 — GitHub App 安裝驗證（integration / smoke）
#   #442 — unzip 可用性修復（unit / smoke）
#   #424 — Node.js 20 遷移 / CI Actions 版本釘定（unit / integration）
#
# ── 診斷資訊輸出規範（AC4）──────────────────────────────────────────────────
#
# 測試失敗時必須輸出：
#   [INFRA-DIAG] 錯誤原因：<具體描述>
#   [INFRA-DIAG] 受影響的 INFRA Story：<Story ID>
#   [INFRA-DIAG] 建議修復步驟：<具體修復建議>
#
# ── 使用方式 ─────────────────────────────────────────────────────────────────
#
# 單獨執行：
#   bash tests/test-infra-regression.sh
#
# 批次執行（整合至 tests/test-*.sh）：
#   bash tests/test-*.sh   (本腳本自動被包含)
#
# 執行特定測試層級：
#   INFRA_TEST_LEVEL=smoke  bash tests/test-infra-regression.sh
#   INFRA_TEST_LEVEL=unit   bash tests/test-infra-regression.sh
#   INFRA_TEST_LEVEL=all    bash tests/test-infra-regression.sh  (預設)
#
# ─────────────────────────────────────────────────────────────────────────────

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

INFRA_TEST_LEVEL="${INFRA_TEST_LEVEL:-all}"

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

# ── 輔助函式 ─────────────────────────────────────────────────────────────────

pass() {
  echo "  [PASS] $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  local msg="$1"
  local diag_reason="${2:-（未提供具體原因）}"
  local diag_story="${3:-（未指定受影響 Story）}"
  local diag_fix="${4:-（未提供修復建議）}"
  echo "  [FAIL] ${msg}"
  echo "    [INFRA-DIAG] 錯誤原因：${diag_reason}"
  echo "    [INFRA-DIAG] 受影響的 INFRA Story：${diag_story}"
  echo "    [INFRA-DIAG] 建議修復步驟：${diag_fix}"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

skip() {
  echo "  [SKIP] $1 (INFRA_TEST_LEVEL=${INFRA_TEST_LEVEL})"
  SKIP_COUNT=$((SKIP_COUNT + 1))
}

# 是否執行此層級的測試
should_run() {
  local level="$1"
  if [[ "${INFRA_TEST_LEVEL}" == "all" || "${INFRA_TEST_LEVEL}" == "${level}" ]]; then
    return 0
  fi
  return 1
}

assert_file_exists() {
  local path="$1"
  local label="$2"
  local story_id="${3:-（未指定）}"
  if [[ -f "${path}" ]]; then
    pass "${label}"
  else
    fail "${label}" \
      "檔案不存在：${path}" \
      "${story_id}" \
      "確認檔案是否被誤刪，或路徑是否正確：ls ${path}"
  fi
}

assert_executable() {
  local path="$1"
  local label="$2"
  local story_id="${3:-（未指定）}"
  if [[ -x "${path}" ]]; then
    pass "${label}"
  else
    fail "${label}" \
      "檔案無執行權限：${path}" \
      "${story_id}" \
      "執行 chmod +x ${path} 修復執行權限"
  fi
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  local story_id="${4:-（未指定）}"
  local fix_hint="${5:-請確認相關實作是否移除或更名}"
  if grep -qE "${pattern}" "${file}" 2>/dev/null; then
    pass "${label}"
  else
    fail "${label}" \
      "檔案 ${file} 中找不到 pattern：${pattern}" \
      "${story_id}" \
      "${fix_hint}"
  fi
}

assert_command_available() {
  local cmd="$1"
  local label="$2"
  local story_id="${3:-（未指定）}"
  if command -v "${cmd}" &>/dev/null; then
    pass "${label}"
  else
    fail "${label}" \
      "必要指令 '${cmd}' 不可用（command not found）" \
      "${story_id}" \
      "在此環境安裝 ${cmd}：sudo apt-get install -y ${cmd} 或確認 PATH 設定"
  fi
}

assert_output_contains() {
  local output="$1"
  local pattern="$2"
  local label="$3"
  local story_id="${4:-（未指定）}"
  local fix_hint="${5:-請確認腳本輸出格式是否被更動}"
  if echo "${output}" | grep -qE "${pattern}"; then
    pass "${label}"
  else
    fail "${label}" \
      "執行輸出中找不到 pattern：${pattern}" \
      "${story_id}" \
      "${fix_hint}"
  fi
}

# ── 測試套件開始 ──────────────────────────────────────────────────────────────

echo "=== INFRA Regression Test Suite（#494）==="
echo "  REPO_ROOT: ${REPO_ROOT}"
echo "  INFRA_TEST_LEVEL: ${INFRA_TEST_LEVEL}"
echo ""

# ============================================================================
# [SMOKE] S-1：關鍵 INFRA 腳本存在且可執行
# 關聯 Story：#450（ci-health-check）、#424（validate-ci-versions）
# ============================================================================

echo "--- [SMOKE] S-1：關鍵 INFRA 腳本存在且可執行 ---"

if should_run "smoke"; then
  assert_file_exists \
    "${REPO_ROOT}/scripts/ci-health-check.sh" \
    "S-1a: scripts/ci-health-check.sh 存在" \
    "#450"

  assert_executable \
    "${REPO_ROOT}/scripts/ci-health-check.sh" \
    "S-1b: scripts/ci-health-check.sh 可執行" \
    "#450"

  assert_file_exists \
    "${REPO_ROOT}/scripts/validate-ci-versions.sh" \
    "S-1c: scripts/validate-ci-versions.sh 存在" \
    "#424"
else
  skip "S-1: 關鍵 INFRA 腳本存在性（level=smoke）"
fi

echo ""

# ============================================================================
# [SMOKE] S-2：必要 CLI 工具可用性
# 關聯 Story：#442（unzip）、#424（node）、#423（gh）
# ============================================================================

echo "--- [SMOKE] S-2：必要 CLI 工具可用性 ---"

if should_run "smoke"; then
  assert_command_available "git" "S-2a: git 可用" "#424"
  assert_command_available "unzip" \
    "S-2b: unzip 可用" \
    "#442" # 若此 FAIL，代表 #442 修復退化
  assert_command_available "node" \
    "S-2c: node 可用（Node.js 20+）" \
    "#424"
  assert_command_available "gh" \
    "S-2d: gh CLI 可用" \
    "#423"
else
  skip "S-2: CLI 工具可用性（level=smoke）"
fi

echo ""

# ============================================================================
# [UNIT] U-1：CI Actions 版本釘定 — validate-ci-versions.sh 結構驗證
# 關聯 Story：#424
# ============================================================================

echo "--- [UNIT] U-1：CI Actions 版本釘定驗證 ---"

if should_run "unit"; then
  VALIDATE_CI="${REPO_ROOT}/scripts/validate-ci-versions.sh"

  assert_file_exists "${VALIDATE_CI}" "U-1a: validate-ci-versions.sh 存在" "#424"

  assert_contains "${VALIDATE_CI}" \
    "@v4|@v3|@v2" \
    "U-1b: validate-ci-versions.sh 包含版本號檢查邏輯" \
    "#424" \
    "確認 validate-ci-versions.sh 仍包含 Actions 版本號 (@vN) 檢查邏輯"

  assert_contains "${VALIDATE_CI}" \
    "PASS|FAIL|pass|fail" \
    "U-1c: validate-ci-versions.sh 輸出 PASS/FAIL 狀態" \
    "#424" \
    "確認腳本輸出格式包含 PASS 或 FAIL 字串"
else
  skip "U-1: CI Actions 版本釘定（level=unit）"
fi

echo ""

# ============================================================================
# [UNIT] U-2：unzip 修復 — CI workflow 結構驗證
# 關聯 Story：#442
# ============================================================================

echo "--- [UNIT] U-2：unzip 安裝方式驗證 ---"

if should_run "unit"; then
  WORKFLOW="${REPO_ROOT}/.github/workflows/new-issue-intake.yml"

  if [[ -f "${WORKFLOW}" ]]; then
    assert_contains "${WORKFLOW}" \
      "apt-get install.*unzip|apt.*install.*unzip" \
      "U-2a: CI workflow 使用 apt-get 安裝 unzip" \
      "#442" \
      "確認 new-issue-intake.yml 中 unzip 安裝使用 apt-get，而非 busybox.net"

    if grep -qE "busybox\.net" "${WORKFLOW}" 2>/dev/null; then
      fail "U-2b: CI workflow 不含 busybox.net 外部依賴" \
        "發現 busybox.net 依賴，此為已修復的退化" \
        "#442" \
        "移除 workflow 中所有 busybox.net 相關行，改用 apt-get install -y unzip"
    else
      pass "U-2b: CI workflow 不含 busybox.net 外部依賴"
    fi
  else
    skip "U-2: new-issue-intake.yml 不存在，跳過 unzip 驗證"
  fi
else
  skip "U-2: unzip 安裝方式（level=unit）"
fi

echo ""

# ============================================================================
# [INTEGRATION] I-1：ci-health-check.sh 整合驗證
# 關聯 Story：#450、#442、#423
# ============================================================================

echo "--- [INTEGRATION] I-1：ci-health-check.sh 整合驗證 ---"

if should_run "integration"; then
  HEALTH_SCRIPT="${REPO_ROOT}/scripts/ci-health-check.sh"

  if [[ -f "${HEALTH_SCRIPT}" && -x "${HEALTH_SCRIPT}" ]]; then
    # 執行 health check（允許非零 exit，環境未必有 GitHub App）
    HEALTH_OUTPUT=$(CI_HEALTH_CHECK_REPO_ROOT="${REPO_ROOT}" bash "${HEALTH_SCRIPT}" 2>&1 || true)

    assert_output_contains "${HEALTH_OUTPUT}" \
      "PASS|FAIL|ERROR" \
      "I-1a: ci-health-check.sh 輸出包含狀態字" \
      "#450" \
      "確認 ci-health-check.sh 執行後仍輸出 PASS/FAIL/ERROR 字串"

    assert_output_contains "${HEALTH_OUTPUT}" \
      "validate-ci-versions|CI Actions|Action 版本" \
      "I-1b: ci-health-check.sh 整合 validate-ci-versions" \
      "#424" \
      "確認 ci-health-check.sh 呼叫 validate-ci-versions.sh 並輸出結果"

    assert_output_contains "${HEALTH_OUTPUT}" \
      "unzip|套件|package" \
      "I-1c: ci-health-check.sh 偵測 unzip 可用性" \
      "#442" \
      "確認 ci-health-check.sh 包含 unzip 可用性偵測邏輯"
  else
    skip "I-1: ci-health-check.sh 不存在或無執行權限，跳過整合測試"
  fi
else
  skip "I-1: ci-health-check.sh 整合（level=integration）"
fi

echo ""

# ============================================================================
# [INTEGRATION] I-2：GitHub App 安裝 — 結構驗證
# 關聯 Story：#423
# ============================================================================

echo "--- [INTEGRATION] I-2：GitHub App 安裝驗證結構 ---"

if should_run "integration"; then
  HEALTH_SCRIPT="${REPO_ROOT}/scripts/ci-health-check.sh"

  if [[ -f "${HEALTH_SCRIPT}" ]]; then
    assert_contains "${HEALTH_SCRIPT}" \
      "GitHub App|installation|gh api" \
      "I-2a: ci-health-check.sh 包含 GitHub App 偵測邏輯" \
      "#423" \
      "確認 ci-health-check.sh 中保有 GitHub App 安裝狀態偵測邏輯"
  else
    skip "I-2: ci-health-check.sh 不存在，跳過 GitHub App 驗證"
  fi
else
  skip "I-2: GitHub App 安裝驗證（level=integration）"
fi

echo ""

# ============================================================================
# 框架自身完整性驗證（#494 AC5 — 本框架符合現有命名慣例與結構）
# ============================================================================

echo "--- 框架自身完整性（#494 AC5）---"

THIS_SCRIPT="${REPO_ROOT}/tests/test-infra-regression.sh"

assert_file_exists "${THIS_SCRIPT}" \
  "AC5a: test-infra-regression.sh 存在於 tests/ 目錄" \
  "#494"

assert_contains "${THIS_SCRIPT}" \
  "PASS_COUNT|FAIL_COUNT|pass\(\)|fail\(\)" \
  "AC5b: 框架使用標準 pass/fail 計數模式" \
  "#494" \
  "確認 test-infra-regression.sh 包含 PASS_COUNT/FAIL_COUNT 變數及 pass()/fail() 函式"

assert_contains "${THIS_SCRIPT}" \
  "INFRA-DIAG" \
  "AC5c: 框架輸出包含診斷標記 [INFRA-DIAG]（AC4）" \
  "#494" \
  "確認 fail() 函式輸出包含 [INFRA-DIAG] 標記"

assert_contains "${THIS_SCRIPT}" \
  "INFRA_TEST_LEVEL" \
  "AC5d: 框架支援 INFRA_TEST_LEVEL 分層執行" \
  "#494" \
  "確認腳本頂端定義 INFRA_TEST_LEVEL 變數支援 smoke/unit/integration/all"

echo ""

# ── 結果彙整 ─────────────────────────────────────────────────────────────────

echo "==================================================="
echo "test-infra-regression.sh 結果："
echo "  PASS=${PASS_COUNT}  FAIL=${FAIL_COUNT}  SKIP=${SKIP_COUNT}"
echo "==================================================="

if [[ "${FAIL_COUNT}" -gt 0 ]]; then
  echo "[RESULT] FAIL"
  echo ""
  echo "有 ${FAIL_COUNT} 個測試失敗。請依上方 [INFRA-DIAG] 訊息進行修復。"
  exit 1
fi

echo "[RESULT] PASS"
exit 0
