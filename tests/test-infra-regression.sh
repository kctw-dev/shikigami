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

echo "=== INFRA Regression Test Suite（#494/#495）==="
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
# [UNIT] U-3：#423 OIDC token exchange 配置驗證（AC2a）
# 關聯 Story：#423（GitHub App 安裝驗證 / OIDC token exchange）
# 側重：CI workflow 是否正確配置 id-token 權限（OIDC token exchange 前置條件）
# ============================================================================

echo "--- [UNIT] U-3：#423 OIDC token exchange 配置驗證 ---"

if should_run "unit"; then
  INTAKE_WORKFLOW="${REPO_ROOT}/.github/workflows/new-issue-intake.yml"

  if [[ -f "${INTAKE_WORKFLOW}" ]]; then
    # AC2a：OIDC token exchange 需要 id-token: write 權限
    assert_contains "${INTAKE_WORKFLOW}" \
      "id-token.*write|id-token:.*write" \
      "U-3a: new-issue-intake.yml 含 id-token: write 權限（OIDC 前置條件）" \
      "#423" \
      "在 new-issue-intake.yml 的 permissions 區塊加入 id-token: write，以啟用 OIDC token exchange"

    # AC2a：workflow 包含 claude-code-action（OIDC token 消費方）
    assert_contains "${INTAKE_WORKFLOW}" \
      "anthropics/claude-code-action|claude.*oauth.*token|CLAUDE_CODE_OAUTH_TOKEN" \
      "U-3b: new-issue-intake.yml 包含 Claude OAuth token 使用步驟" \
      "#423" \
      "確認 new-issue-intake.yml 中 claude-code-action 步驟仍使用 CLAUDE_CODE_OAUTH_TOKEN"

    # AC2a：permissions 區塊存在（防止意外移除整段 permissions）
    assert_contains "${INTAKE_WORKFLOW}" \
      "^[[:space:]]*permissions:" \
      "U-3c: new-issue-intake.yml 含 permissions 區塊（最小權限原則）" \
      "#423" \
      "確認 new-issue-intake.yml 保有明確的 permissions 區塊，避免預設 permissions 過寬"
  else
    skip "U-3: new-issue-intake.yml 不存在，跳過 OIDC 配置驗證"
  fi
else
  skip "U-3: OIDC token exchange 配置（level=unit）"
fi

echo ""

# ============================================================================
# [UNIT] U-4：#442 unzip 修復深度回歸驗證（AC2b）
# 關聯 Story：#442（unzip 可用性修復）
# 側重：回歸驗證 — 確認修復後的 idempotent 安裝邏輯未退化
# 與 test-442-ci-unzip-fix.sh 區分：本測試著重「修復後的行為結構是否保持正確」
# ============================================================================

echo "--- [UNIT] U-4：#442 unzip 修復深度回歸驗證 ---"

if should_run "unit"; then
  INTAKE_WORKFLOW="${REPO_ROOT}/.github/workflows/new-issue-intake.yml"

  if [[ -f "${INTAKE_WORKFLOW}" ]]; then
    # AC2b：冪等安裝：先檢查 unzip 是否存在，再決定是否安裝
    assert_contains "${INTAKE_WORKFLOW}" \
      "command -v unzip|which unzip" \
      "U-4a: CI workflow unzip 安裝步驟包含冪等檢查（command -v unzip）" \
      "#442" \
      "確認 new-issue-intake.yml 中 unzip 安裝前有 'if ! command -v unzip' 冪等判斷，防止每次都重新安裝"

    # AC2b：使用 apt-get 安裝（不依賴外部下載站台）
    assert_contains "${INTAKE_WORKFLOW}" \
      "apt-get install.*-y.*unzip|apt-get install.*unzip.*-y" \
      "U-4b: CI workflow 使用 apt-get install -y unzip（非外部依賴）" \
      "#442" \
      "確認 new-issue-intake.yml 使用 'apt-get install -y unzip'，不依賴 busybox.net 或其他外部站台"

    # AC2b：確認沒有 sudo -n（#464 修復後的退化檢查）
    # #464 曾引入 sudo -n 導致靜默失敗，本測試確保此退化不再出現
    # 注意：僅檢查非註解行（排除 # 開頭的說明行）
    if grep -vE "^[[:space:]]*#" "${INTAKE_WORKFLOW}" 2>/dev/null | grep -qE "sudo[[:space:]]+-n[[:space:]]"; then
      fail "U-4c: CI workflow 不含 sudo -n（已知靜默失敗根因）" \
        "發現 sudo -n 用法（非註解行），此為 #464 引入的已知靜默失敗根因，#442/#472 已修復" \
        "#442" \
        "移除 workflow 中的 sudo -n，改用 sudo apt-get install -y unzip（無 -n flag）"
    else
      pass "U-4c: CI workflow 不含 sudo -n（已知靜默失敗根因）"
    fi
  else
    skip "U-4: new-issue-intake.yml 不存在，跳過 unzip 深度回歸驗證"
  fi
else
  skip "U-4: unzip 修復深度回歸（level=unit）"
fi

echo ""

# ============================================================================
# [INTEGRATION] I-3：#424 validate-ci-versions.sh 實際執行驗證（AC2c）
# 關聯 Story：#424（Node.js 20 遷移 / CI Actions 版本釘定）
# 側重：結合現有 validate-ci-versions.sh，驗證 CI Actions 版本符合釘定規範
# ============================================================================

echo "--- [INTEGRATION] I-3：#424 CI Actions 版本釘定實際執行驗證 ---"

if should_run "integration"; then
  VALIDATE_CI="${REPO_ROOT}/scripts/validate-ci-versions.sh"

  if [[ -f "${VALIDATE_CI}" ]]; then
    # AC2c：實際執行 validate-ci-versions.sh，驗證目前 workflows 均符合版本規範
    VALIDATE_OUTPUT=$(CI_VERSIONS_REPO_ROOT="${REPO_ROOT}" bash "${VALIDATE_CI}" 2>&1)
    VALIDATE_EXIT=$?

    if [[ $VALIDATE_EXIT -eq 0 ]]; then
      pass "I-3a: validate-ci-versions.sh 執行通過（所有 Actions 版本符合規範）"
    else
      fail "I-3a: validate-ci-versions.sh 執行失敗（發現不符合規範的 Actions 版本）" \
        "validate-ci-versions.sh 回傳非零 exit code（${VALIDATE_EXIT}）" \
        "#424" \
        "執行 bash scripts/validate-ci-versions.sh 查看詳細報告，並依 CLAUDE.md 第 10 條更新 Actions 版本至允許清單版本"
    fi

    # AC2c：輸出包含 PASS 字串（確認腳本輸出格式穩定）
    assert_output_contains "${VALIDATE_OUTPUT}" \
      "PASS|結果：PASS" \
      "I-3b: validate-ci-versions.sh 輸出包含 PASS 結果字串" \
      "#424" \
      "確認 validate-ci-versions.sh 在版本合規時輸出 PASS 狀態，格式未被改動"

    # AC2c：確認至少掃描到 workflow 檔案（防止 workflows 目錄被清空的回歸）
    # 注意：new-issue-intake.yml / sprint-dispatch.yml / e2e.yml 已於 Sprint 142 移除
    # 改為驗證 validate-ci-versions.sh 仍能掃描到存在的 workflow 檔案
    assert_output_contains "${VALIDATE_OUTPUT}" \
      "\.yml" \
      "I-3c: validate-ci-versions.sh 掃描到至少一個 workflow 檔案" \
      "#424" \
      "確認 .github/workflows/ 中存在至少一個 workflow 檔案且被 validate-ci-versions.sh 掃描"
  else
    skip "I-3: validate-ci-versions.sh 不存在，跳過版本釘定執行驗證"
  fi
else
  skip "I-3: CI Actions 版本釘定實際執行（level=integration）"
fi

echo ""

# ============================================================================
# [INTEGRATION] I-4：#423 GitHub App 安裝 — OIDC token 端對端結構驗證（AC2a）
# 關聯 Story：#423（GitHub App 安裝驗證 / OIDC token exchange）
# 側重：ci-health-check.sh 中 GitHub App 偵測邏輯的完整端對端結構
# ============================================================================

echo "--- [INTEGRATION] I-4：#423 OIDC token 端對端結構驗證 ---"

if should_run "integration"; then
  HEALTH_SCRIPT="${REPO_ROOT}/scripts/ci-health-check.sh"

  if [[ -f "${HEALTH_SCRIPT}" ]]; then
    # AC2a：健康檢查腳本呼叫 GitHub API installation endpoint
    assert_contains "${HEALTH_SCRIPT}" \
      "repos/.*installation|/installation" \
      "I-4a: ci-health-check.sh 使用 /repos/{owner}/{repo}/installation API endpoint" \
      "#423" \
      "確認 ci-health-check.sh 呼叫 GitHub API '/repos/\$repo_slug/installation' 偵測 App 安裝狀態"

    # AC2a：健康檢查腳本能辨識 404（App 未安裝）vs 401/403（認證問題）
    assert_contains "${HEALTH_SCRIPT}" \
      "404|Not Found" \
      "I-4b: ci-health-check.sh 能辨識 404（GitHub App 未安裝）" \
      "#423" \
      "確認 ci-health-check.sh 對 GitHub API 404 回應有明確處理（App 未安裝）"

    assert_contains "${HEALTH_SCRIPT}" \
      "401|403|Unauthorized|Forbidden" \
      "I-4c: ci-health-check.sh 能辨識 401/403（認證不足）" \
      "#423" \
      "確認 ci-health-check.sh 對 GitHub API 401/403 回應有明確處理（認證問題與安裝問題區分）"
  else
    skip "I-4: ci-health-check.sh 不存在，跳過 OIDC 端對端結構驗證"
  fi
else
  skip "I-4: OIDC token 端對端結構（level=integration）"
fi

echo ""

# ============================================================================
# [SMOKE] S-3：AC3 CI pipeline 整合驗證（#495 AC3）
# 關聯 Story：#495（INFRA 回歸測試案例實作與 CI 整合）
# 側重：確認 INFRA 回歸測試有對應的 GitHub Actions workflow，可被 CI 觸發
# ============================================================================

echo "--- [SMOKE] S-3：AC3 CI pipeline 整合驗證 ---"

if should_run "smoke"; then
  INFRA_CI_WORKFLOW="${REPO_ROOT}/.github/workflows/infra-regression.yml"

  assert_file_exists "${INFRA_CI_WORKFLOW}" \
    "S-3a: .github/workflows/infra-regression.yml 存在（AC3 CI 整合）" \
    "#495"

  if [[ -f "${INFRA_CI_WORKFLOW}" ]]; then
    # 確認 CI workflow 觸發 INFRA regression 測試
    assert_contains "${INFRA_CI_WORKFLOW}" \
      "test-infra-regression\.sh" \
      "S-3b: CI workflow 包含 test-infra-regression.sh 執行步驟" \
      "#495" \
      "確認 infra-regression.yml 中包含執行 tests/test-infra-regression.sh 的步驟"

    # 確認 CI workflow 有 push/pull_request 觸發（自動回歸）
    assert_contains "${INFRA_CI_WORKFLOW}" \
      "pull_request|push" \
      "S-3c: CI workflow 包含 push/pull_request 自動觸發條件" \
      "#495" \
      "確認 infra-regression.yml 在 push 或 pull_request 時自動觸發，實現持續回歸"

    # 確認 CI workflow 使用 @v4 Actions（版本釘定）
    assert_contains "${INFRA_CI_WORKFLOW}" \
      "actions/checkout@v4" \
      "S-3d: CI workflow Actions 版本符合釘定規範（actions/checkout@v4）" \
      "#424" \
      "確認 infra-regression.yml 使用 actions/checkout@v4（CLAUDE.md 第 10 條）"
  fi
else
  skip "S-3: CI pipeline 整合驗證（level=smoke）"
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
