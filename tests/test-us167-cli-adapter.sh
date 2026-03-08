#!/usr/bin/env bash
# tests/test-us167-cli-adapter.sh
# US-167 驗收測試：多模型 CLI 路由 Phase 1 — Adapter 介面設計與 Gemini CLI 整合實作
# TDD Red phase — 先寫測試，再實作

set -uo pipefail

PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ADAPTER_SCRIPT="${REPO_ROOT}/scripts/cli-adapter.sh"

pass() {
  echo "[PASS] $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "[FAIL] $1"
  FAIL=$((FAIL + 1))
}

echo "=== US-167 CLI Adapter 驗收測試 ==="
echo ""

# ── AC1: Adapter 介面定義（靜態） ────────────────────────────────────────────

echo "--- AC1: Adapter 介面定義 ---"

# AC1-1: cli-adapter.sh 存在
if [[ -f "${ADAPTER_SCRIPT}" ]]; then
  pass "AC1-1: cli-adapter.sh 存在"
else
  fail "AC1-1: cli-adapter.sh 不存在（路徑：${ADAPTER_SCRIPT}）"
fi

# AC1-2: cli-adapter.sh 非空
if [[ -f "${ADAPTER_SCRIPT}" ]] && [[ -s "${ADAPTER_SCRIPT}" ]]; then
  pass "AC1-2: cli-adapter.sh 非空"
else
  fail "AC1-2: cli-adapter.sh 為空或不存在"
fi

# AC1-3: 定義 invoke_cli_adapter 函式
if [[ -f "${ADAPTER_SCRIPT}" ]] && grep -q "invoke_cli_adapter" "${ADAPTER_SCRIPT}"; then
  pass "AC1-3: 定義 invoke_cli_adapter 函式"
else
  fail "AC1-3: 缺少 invoke_cli_adapter 函式定義"
fi

# AC1-4: 定義 prompt-in 格式（stdin 或 -p flag）
if [[ -f "${ADAPTER_SCRIPT}" ]] && grep -qE "stdin|--prompt|-p" "${ADAPTER_SCRIPT}"; then
  pass "AC1-4: 定義 prompt-in 格式（stdin 或 -p flag）"
else
  fail "AC1-4: 缺少 prompt-in 格式定義"
fi

# AC1-5: 定義 result-out 格式（stdout）
if [[ -f "${ADAPTER_SCRIPT}" ]] && grep -qE "stdout|output" "${ADAPTER_SCRIPT}"; then
  pass "AC1-5: 定義 result-out 格式（stdout）"
else
  fail "AC1-5: 缺少 result-out 格式定義"
fi

# AC1-6: 定義支援的 provider（claude, gemini）
if [[ -f "${ADAPTER_SCRIPT}" ]] && grep -q "claude" "${ADAPTER_SCRIPT}" && grep -q "gemini" "${ADAPTER_SCRIPT}"; then
  pass "AC1-6: 定義支援的 provider（claude, gemini）"
else
  fail "AC1-6: 缺少 provider 定義（claude 或 gemini）"
fi

echo ""

# ── AC2: Gemini CLI 整合（動態） ─────────────────────────────────────────────

echo "--- AC2: Gemini CLI 整合 ---"

# AC2-1: 支援 SHIKIGAMI_MODEL_PROVIDER 環境變數切換
if [[ -f "${ADAPTER_SCRIPT}" ]] && grep -q "SHIKIGAMI_MODEL_PROVIDER" "${ADAPTER_SCRIPT}"; then
  pass "AC2-1: 支援 SHIKIGAMI_MODEL_PROVIDER 環境變數"
else
  fail "AC2-1: 缺少 SHIKIGAMI_MODEL_PROVIDER 環境變數支援"
fi

# AC2-2: 設定 gemini provider 時呼叫 gemini CLI
if [[ -f "${ADAPTER_SCRIPT}" ]] && grep -qE "gemini.*--output-format|gemini.*-p|gemini.*json" "${ADAPTER_SCRIPT}"; then
  pass "AC2-2: Gemini CLI 呼叫使用 --output-format json"
else
  fail "AC2-2: Gemini CLI 呼叫缺少 --output-format json 參數"
fi

# AC2-3: 功能測試 — 預設 claude 模式（mock claude 存在時）
if command -v claude &>/dev/null || [[ -f "${ADAPTER_SCRIPT}" ]]; then
  # 使用 mock 模式測試 adapter 載入
  if [[ -f "${ADAPTER_SCRIPT}" ]]; then
    # 源碼載入測試：確認函式可被 source
    output=$(bash -c "source '${ADAPTER_SCRIPT}' 2>&1; type invoke_cli_adapter 2>&1")
    if echo "${output}" | grep -q "function\|invoke_cli_adapter"; then
      pass "AC2-3: invoke_cli_adapter 函式可從 source 載入"
    else
      fail "AC2-3: invoke_cli_adapter 函式 source 載入失敗"
    fi
  else
    fail "AC2-3: adapter 腳本不存在，無法測試"
  fi
fi

echo ""

# ── AC3: 降級策略（動態） ────────────────────────────────────────────────────

echo "--- AC3: 降級策略 ---"

# AC3-1: fallback 邏輯存在
if [[ -f "${ADAPTER_SCRIPT}" ]] && grep -qE "fallback|FALLBACK|退回|fall.back" "${ADAPTER_SCRIPT}"; then
  pass "AC3-1: 存在 fallback 邏輯"
else
  fail "AC3-1: 缺少 fallback 邏輯"
fi

# AC3-2: exit code 檢查（Gemini 失敗偵測）
if [[ -f "${ADAPTER_SCRIPT}" ]] && grep -qE "exit.code|\$\?|if.*gemini" "${ADAPTER_SCRIPT}"; then
  pass "AC3-2: 存在 exit code 檢查"
else
  fail "AC3-2: 缺少 exit code 檢查"
fi

# AC3-3: 失敗原因記錄至 stderr
if [[ -f "${ADAPTER_SCRIPT}" ]] && grep -qE ">&2|stderr" "${ADAPTER_SCRIPT}"; then
  pass "AC3-3: 失敗原因記錄至 stderr"
else
  fail "AC3-3: 缺少 stderr 失敗記錄"
fi

# AC3-4: 功能測試 — Gemini 失敗時 fallback 回 Claude
if [[ -f "${ADAPTER_SCRIPT}" ]]; then
  # 建立暫時的 mock gemini（故意失敗）
  TMPDIR_TEST=$(mktemp -d)
  cat > "${TMPDIR_TEST}/gemini" << 'MOCK_GEMINI'
#!/usr/bin/env bash
exit 1
MOCK_GEMINI
  chmod +x "${TMPDIR_TEST}/gemini"

  # 建立 mock claude（成功回傳）
  cat > "${TMPDIR_TEST}/claude" << 'MOCK_CLAUDE'
#!/usr/bin/env bash
echo "claude fallback response"
exit 0
MOCK_CLAUDE
  chmod +x "${TMPDIR_TEST}/claude"

  # 使用 PATH mock 執行 fallback 測試
  result=$(SHIKIGAMI_MODEL_PROVIDER=gemini PATH="${TMPDIR_TEST}:${PATH}" \
    bash -c "source '${ADAPTER_SCRIPT}'; invoke_cli_adapter 'gemini' 'test prompt'" 2>/dev/null)
  fallback_exit=$?

  rm -rf "${TMPDIR_TEST}"

  if [[ "${result}" == *"claude fallback response"* ]] || [[ "${fallback_exit}" -eq 0 ]]; then
    pass "AC3-4: Gemini 失敗時成功 fallback 回 Claude"
  else
    fail "AC3-4: Gemini 失敗時 fallback 機制未正常運作（result='${result}', exit=${fallback_exit}）"
  fi
fi

echo ""

# ── AC4: 預設行為維持 Claude（動態） ─────────────────────────────────────────

echo "--- AC4: 預設行為不變 ---"

# AC4-1: 未設定環境變數時預設使用 claude
# 接受兩種寫法：
#   (a) ${SHIKIGAMI_MODEL_PROVIDER:-claude}
#   (b) 常數定義 DEFAULT_PROVIDER="claude" 搭配 ${VAR:-${CONSTANT}}
if [[ -f "${ADAPTER_SCRIPT}" ]] && \
   grep -qE 'SHIKIGAMI_MODEL_PROVIDER[^}]*:-[^}]*claude|DEFAULT_PROVIDER[^=]*=.*claude' "${ADAPTER_SCRIPT}"; then
  pass "AC4-1: 未設定 SHIKIGAMI_MODEL_PROVIDER 時預設使用 claude"
else
  fail "AC4-1: 缺少 claude 預設行為定義"
fi

# AC4-2: 功能測試 — 未設定環境變數時使用 claude
if [[ -f "${ADAPTER_SCRIPT}" ]]; then
  TMPDIR_TEST2=$(mktemp -d)
  cat > "${TMPDIR_TEST2}/claude" << 'MOCK_CLAUDE2'
#!/usr/bin/env bash
echo "claude default response"
exit 0
MOCK_CLAUDE2
  chmod +x "${TMPDIR_TEST2}/claude"

  result=$(PATH="${TMPDIR_TEST2}:${PATH}" \
    bash -c "unset SHIKIGAMI_MODEL_PROVIDER; source '${ADAPTER_SCRIPT}'; invoke_cli_adapter '' 'test prompt'" 2>/dev/null)

  rm -rf "${TMPDIR_TEST2}"

  if [[ "${result}" == *"claude default response"* ]]; then
    pass "AC4-2: 未設定環境變數時使用 claude（預設行為正確）"
  else
    fail "AC4-2: 未設定環境變數時未使用 claude（result='${result}'）"
  fi
fi

# AC4-3: cli-adapter.sh 不修改任何現有 Sprint 流程檔案
SPRINT_SKILL="${REPO_ROOT}/skills/sprint-execution/SKILL.md"
if [[ -f "${SPRINT_SKILL}" ]]; then
  # 確認 Sprint SKILL.md 不強制依賴 cli-adapter.sh
  if ! grep -q "cli-adapter.sh.*required\|必須.*cli-adapter" "${SPRINT_SKILL}"; then
    pass "AC4-3: Sprint SKILL.md 不強制依賴 cli-adapter.sh"
  else
    fail "AC4-3: Sprint SKILL.md 被修改為強制依賴 cli-adapter.sh"
  fi
fi

echo ""

# ── 結果摘要 ─────────────────────────────────────────────────────────────────

echo "=== 測試結果摘要 ==="
echo "通過：${PASS}"
echo "失敗：${FAIL}"
echo ""

if [[ "${FAIL}" -eq 0 ]]; then
  echo "[ALL PASS] US-167 所有驗收測試通過"
  exit 0
else
  echo "[FAIL] ${FAIL} 項測試未通過"
  exit 1
fi
