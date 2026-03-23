#!/usr/bin/env bash
# scripts/runner-setup.sh
# #436：Self-hosted runner 環境標準化 — 確保必要工具預裝
#
# 功能：在 self-hosted GitHub Actions runner VM 啟動時，
#       自動安裝並驗證所有必要工具，確保 CI 工作流可正常執行。
#
# 問題背景（#433）：Runner 缺 unzip 導致 claude-code-action 無法執行。
#                   MIG startup script 未包含必要工具。
#
# 設計原則：
#   - 冪等（Idempotent）：多次執行無副作用，已安裝的工具不重複安裝
#   - 安全：不處理認證資訊（OAuth Token、API Key）
#   - 最小假設：僅依賴 Ubuntu 22.04+ 基礎環境
#
# 關聯文件：
#   - docs/km/runner-environment-checklist.md（必裝套件清單）
#   - Issue #433（缺 unzip 的根因）
#   - Issue #436（本 Story）
#
# Exit code:
#   0 = 全部必要工具安裝並驗證成功
#   1 = 有必要步驟失敗
#
# 使用方式：
#   bash scripts/runner-setup.sh
#   bash scripts/runner-setup.sh --dry-run   # 僅顯示將執行的步驟，不實際執行

set -uo pipefail

# ---------------------------------------------------------------------------
# 常數
# ---------------------------------------------------------------------------
readonly SCRIPT_NAME="runner-setup.sh"

# 必要工具清單（按類別）
# 基礎工具：自解壓 / 資料處理 / 網路
readonly BASE_TOOLS=(unzip zip curl wget jq)
# 版本控制
readonly VCS_TOOLS=(git)
# GitHub 操作
readonly GH_TOOLS=(gh)
# Shell 工具
readonly SHELL_TOOLS=(bash)

# ---------------------------------------------------------------------------
# 模式旗標
# ---------------------------------------------------------------------------
DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

# ---------------------------------------------------------------------------
# 狀態追蹤
# ---------------------------------------------------------------------------
EXIT_CODE=0
STEPS_PASSED=0
STEPS_FAILED=0
STEPS_SKIPPED=0

# ---------------------------------------------------------------------------
# 輸出函式
# ---------------------------------------------------------------------------
print_header() {
  echo ""
  echo "=============================="
  echo " $1"
  echo "=============================="
}

print_step() {
  echo ""
  echo "--- STEP: $1"
}

print_pass() {
  echo "[PASS] $1"
  STEPS_PASSED=$((STEPS_PASSED + 1))
}

print_skip() {
  echo "[SKIP] $1（已存在，跳過）"
  STEPS_SKIPPED=$((STEPS_SKIPPED + 1))
}

print_fail() {
  echo "[FAIL] $1"
  EXIT_CODE=1
  STEPS_FAILED=$((STEPS_FAILED + 1))
}

print_info() {
  echo "  [INFO] $1"
}

# ---------------------------------------------------------------------------
# 工具函式
# ---------------------------------------------------------------------------

# 偵測遺漏工具
find_missing_tools() {
  local -n tools_ref=$1
  local missing=()
  for tool in "${tools_ref[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
      missing+=("$tool")
    fi
  done
  echo "${missing[@]:-}"
}

# 安裝套件（冪等：先檢查再安裝）
install_packages() {
  local description="$1"
  shift
  local packages=("$@")

  if [[ ${#packages[@]} -eq 0 ]]; then
    return 0
  fi

  print_info "需要安裝：${packages[*]}"

  if [[ "$DRY_RUN" == "true" ]]; then
    print_info "將執行：sudo apt-get install -y ${packages[*]}"
    print_pass "dry-run：${description} 安裝步驟確認"
    return 0
  fi

  if sudo apt-get install -y "${packages[@]}" -qq 2>/dev/null; then
    print_pass "${description} 安裝完成：${packages[*]}"
  else
    print_fail "${description} 安裝失敗"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# 步驟函式
# ---------------------------------------------------------------------------

# STEP 1：更新 apt 套件索引
step_apt_update() {
  print_step "更新 apt 套件索引"

  if [[ "$DRY_RUN" == "true" ]]; then
    print_info "將執行：sudo apt-get update -qq"
    print_skip "dry-run 模式，跳過"
    return 0
  fi

  if sudo apt-get update -qq 2>/dev/null; then
    print_pass "apt 套件索引更新完成"
  else
    print_fail "apt update 失敗"
  fi
}

# STEP 2：安裝基礎工具（unzip, zip, curl, wget, jq）
step_install_base_tools() {
  print_step "安裝基礎工具（unzip, zip, curl, wget, jq）"

  local already_installed=()
  local to_install=()

  for tool in "${BASE_TOOLS[@]}"; do
    if command -v "$tool" &>/dev/null; then
      already_installed+=("$tool")
    else
      to_install+=("$tool")
    fi
  done

  for tool in "${already_installed[@]}"; do
    print_skip "${tool} 已安裝（$(command -v "$tool")）"
  done

  if [[ ${#to_install[@]} -eq 0 ]]; then
    return 0
  fi

  install_packages "基礎工具" "${to_install[@]}"
}

# STEP 3：安裝版本控制工具（git）
step_install_vcs_tools() {
  print_step "安裝版本控制工具（git）"

  for tool in "${VCS_TOOLS[@]}"; do
    if command -v "$tool" &>/dev/null; then
      print_skip "${tool} 已安裝（$(command -v "$tool")）"
    else
      install_packages "版本控制工具" "$tool"
    fi
  done
}

# STEP 4：安裝 GitHub CLI（gh）
step_install_gh_cli() {
  print_step "安裝 GitHub CLI（gh）"

  if command -v gh &>/dev/null; then
    print_skip "GitHub CLI 已安裝（$(gh --version | head -1)）"
    return 0
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    print_info "將執行：安裝 GitHub CLI（透過 GitHub 官方 apt repo）"
    print_pass "dry-run：GitHub CLI 安裝步驟確認"
    return 0
  fi

  print_info "從官方 repo 安裝 GitHub CLI..."
  if curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null \
     && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
     && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
     && sudo apt-get update -qq \
     && sudo apt-get install -y gh -qq; then
    print_pass "GitHub CLI 安裝完成（$(gh --version | head -1)）"
  else
    print_fail "GitHub CLI 安裝失敗"
  fi
}

# STEP 5：驗證所有必要工具已就緒
step_verify_all_tools() {
  print_step "驗證所有必要工具已就緒"

  local all_tools=("${BASE_TOOLS[@]}" "${VCS_TOOLS[@]}" "${GH_TOOLS[@]}")
  local failed=()
  local passed=()

  for tool in "${all_tools[@]}"; do
    if command -v "$tool" &>/dev/null; then
      local version
      version=$("$tool" --version 2>/dev/null | head -1 || echo "（版本未知）")
      passed+=("${tool}: ${version}")
    else
      failed+=("$tool")
    fi
  done

  echo ""
  echo "  已就緒工具："
  for info in "${passed[@]}"; do
    echo "    ✓ ${info}"
  done

  if [[ ${#failed[@]} -gt 0 ]]; then
    echo ""
    echo "  缺失工具："
    for tool in "${failed[@]}"; do
      echo "    ✗ ${tool}"
    done
    print_fail "以下工具缺失：${failed[*]}"
    return 1
  fi

  print_pass "所有必要工具驗證通過（共 ${#passed[@]} 個）"
}

# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------
main() {
  print_header "${SCRIPT_NAME} — Self-hosted Runner 環境標準化腳本"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo "  [DRY-RUN 模式] 僅顯示將執行的步驟，不實際執行任何命令"
  fi

  echo ""
  echo "  目的：確保 CI runner 具備所有必要工具，防止因缺工具導致 CI 失敗（#433）"
  echo "  關聯文件：docs/km/runner-environment-checklist.md"

  # 依序執行各步驟
  step_apt_update
  step_install_base_tools
  step_install_vcs_tools
  step_install_gh_cli
  step_verify_all_tools

  # 總結
  print_header "執行結果總結"
  echo ""
  echo "  PASS  ：${STEPS_PASSED} 個步驟"
  echo "  SKIP  ：${STEPS_SKIPPED} 個步驟（已存在，冪等跳過）"
  echo "  FAIL  ：${STEPS_FAILED} 個步驟"
  echo ""

  if [[ "$EXIT_CODE" -eq 0 ]]; then
    echo "  [SUCCESS] Runner 環境標準化完成！所有必要工具已就緒。"
  else
    echo "  [ERROR] 有 ${STEPS_FAILED} 個步驟失敗，請依錯誤訊息排查後重新執行。"
    echo "  提示：腳本為冪等設計，重新執行不會影響已完成的步驟。"
  fi
  echo ""

  exit "$EXIT_CODE"
}

main
