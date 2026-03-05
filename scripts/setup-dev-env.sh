#!/usr/bin/env bash
# scripts/setup-dev-env.sh
# US-95：開發環境可攜性 — GCE 環境設定腳本（Dotfiles Repo MVP）
#
# 功能：在新的 GCE 開發機上，從零建立可運行的 Shikigami 開發環境。
# 執行後可成功完成：clone repo、執行 git hooks、執行 validate-version.sh 取得 PASS。
#
# 設計原則：
#   - 冪等（Idempotent）：多次執行無副作用，已安裝的工具不重複安裝
#   - 安全：不處理認證資訊（OAuth Token、API Key），認證由 gce-auth-guide.md 另行設定
#   - 最小假設：僅依賴 Ubuntu 22.04+ 基礎環境
#
# 關聯文件：
#   - docs/env-portability-strategy.md（方向選定）
#   - docs/env-rebuild-guide.md（環境重建流程）
#   - docs/gce-auth-guide.md（認證設定）
#   - ADR-012 §環境管理考量
#
# Exit code:
#   0 = 全部安裝成功
#   1 = 有必要步驟失敗
#
# 使用方式：
#   bash scripts/setup-dev-env.sh
#   bash scripts/setup-dev-env.sh --dry-run   # 僅顯示將執行的步驟，不實際執行

set -uo pipefail

# ---------------------------------------------------------------------------
# 常數
# ---------------------------------------------------------------------------
readonly SCRIPT_NAME="setup-dev-env.sh"
readonly NODE_VERSION="20"
readonly CLAUDE_CODE_PACKAGE="@anthropic-ai/claude-code"
readonly REPO_URL="https://github.com/KCTW/shikigami.git"
readonly DEFAULT_REPO_DIR="${HOME}/shikigami"

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

run_cmd() {
  # 包裝命令執行，支援 dry-run 模式
  local description="$1"
  shift
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [DRY-RUN] 將執行：$*"
    return 0
  fi
  if "$@"; then
    return 0
  else
    print_fail "$description 執行失敗（命令：$*）"
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

# STEP 2：安裝基礎工具（git、curl、jq）
step_install_base_tools() {
  print_step "安裝基礎工具（git、curl、jq）"
  local missing_tools=()

  for tool in git curl jq; do
    if command -v "$tool" &>/dev/null; then
      print_skip "$tool 已安裝（$(command -v "$tool")）"
    else
      missing_tools+=("$tool")
    fi
  done

  if [[ ${#missing_tools[@]} -eq 0 ]]; then
    return 0
  fi

  print_info "需要安裝：${missing_tools[*]}"
  if [[ "$DRY_RUN" == "true" ]]; then
    print_info "將執行：sudo apt-get install -y ${missing_tools[*]}"
    print_pass "dry-run：基礎工具安裝步驟確認"
    return 0
  fi

  if sudo apt-get install -y "${missing_tools[@]}" -qq; then
    print_pass "基礎工具安裝完成：${missing_tools[*]}"
  else
    print_fail "基礎工具安裝失敗"
  fi
}

# STEP 3：安裝 Node.js（透過 NodeSource）
step_install_nodejs() {
  print_step "安裝 Node.js ${NODE_VERSION}"

  # 檢查現有版本
  if command -v node &>/dev/null; then
    local current_major
    current_major=$(node --version | sed 's/v//' | cut -d. -f1)
    if [[ "$current_major" -ge "$NODE_VERSION" ]]; then
      print_skip "Node.js 已安裝（$(node --version)），滿足最低需求（v${NODE_VERSION}+）"
      return 0
    else
      print_info "現有 Node.js 版本 $(node --version) 低於需求 v${NODE_VERSION}，將升級"
    fi
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    print_info "將執行：curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -"
    print_info "將執行：sudo apt-get install -y nodejs"
    print_pass "dry-run：Node.js 安裝步驟確認"
    return 0
  fi

  print_info "從 NodeSource 安裝 Node.js ${NODE_VERSION}..."
  if curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | sudo -E bash - -qq 2>/dev/null \
     && sudo apt-get install -y nodejs -qq; then
    print_pass "Node.js 安裝完成（$(node --version)）"
  else
    print_fail "Node.js 安裝失敗"
  fi
}

# STEP 4：安裝 Claude Code CLI
step_install_claude_code() {
  print_step "安裝 Claude Code CLI"

  if command -v claude &>/dev/null; then
    local current_version
    current_version=$(claude --version 2>/dev/null | head -1 || echo "unknown")
    print_skip "Claude Code 已安裝（${current_version}）"
    return 0
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    print_info "將執行：sudo npm install -g ${CLAUDE_CODE_PACKAGE}"
    print_pass "dry-run：Claude Code 安裝步驟確認"
    return 0
  fi

  print_info "安裝 Claude Code CLI..."
  if sudo npm install -g "${CLAUDE_CODE_PACKAGE}" --quiet; then
    print_pass "Claude Code 安裝完成（$(claude --version 2>/dev/null | head -1)）"
  else
    print_fail "Claude Code 安裝失敗"
  fi
}

# STEP 5：安裝 GitHub CLI（gh）
step_install_gh_cli() {
  print_step "安裝 GitHub CLI（gh）"

  if command -v gh &>/dev/null; then
    print_skip "GitHub CLI 已安裝（$(gh --version | head -1)）"
    return 0
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    print_info "將執行：sudo apt install gh（透過 GitHub 官方 apt repo）"
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

# STEP 6：設定 git 全域設定
step_configure_git() {
  print_step "設定 git 全域設定"

  local current_name
  local current_email
  current_name=$(git config --global user.name 2>/dev/null || echo "")
  current_email=$(git config --global user.email 2>/dev/null || echo "")

  if [[ -n "$current_name" && -n "$current_email" ]]; then
    print_skip "git 全域設定已存在（user.name=${current_name}，user.email=${current_email}）"
    return 0
  fi

  # 若未設定，提示使用者手動設定
  print_info "git 全域設定尚未完整，請執行以下命令設定："
  print_info "  git config --global user.name \"你的名字\""
  print_info "  git config --global user.email \"你的 email\""
  print_info "  git config --global core.autocrlf false"
  print_info "  git config --global init.defaultBranch main"
  print_pass "git 全域設定檢查完成（提示使用者手動設定）"
}

# STEP 7：Clone Shikigami repository
step_clone_repo() {
  print_step "Clone Shikigami repository"

  # 支援環境變數覆寫 repo 目錄
  local repo_dir="${SHIKIGAMI_DIR:-${DEFAULT_REPO_DIR}}"

  if [[ -d "${repo_dir}/.git" ]]; then
    print_skip "Repository 已存在於 ${repo_dir}"
    print_info "執行 git pull 確保為最新版本..."
    if [[ "$DRY_RUN" == "true" ]]; then
      print_info "將執行：git -C ${repo_dir} pull --ff-only"
    else
      git -C "${repo_dir}" pull --ff-only 2>/dev/null || print_info "git pull 跳過（非 fast-forward 或網路問題）"
    fi
    return 0
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    print_info "將執行：git clone ${REPO_URL} ${repo_dir}"
    print_pass "dry-run：Clone 步驟確認"
    return 0
  fi

  print_info "Clone ${REPO_URL} 至 ${repo_dir}..."
  if git clone "${REPO_URL}" "${repo_dir}"; then
    print_pass "Repository clone 完成（${repo_dir}）"
  else
    print_fail "Repository clone 失敗。請確認網路連線與 GitHub 認證（gh auth login）"
  fi
}

# STEP 8：設定 git hooks
step_setup_git_hooks() {
  print_step "設定 git hooks"

  local repo_dir="${SHIKIGAMI_DIR:-${DEFAULT_REPO_DIR}}"

  if [[ ! -d "${repo_dir}" ]]; then
    print_fail "Repository 目錄不存在（${repo_dir}），請先完成 STEP 7（Clone repo）"
    return 1
  fi

  local hooks_dir="${repo_dir}/.git/hooks"
  local project_hooks_dir="${repo_dir}/hooks"

  # 確認專案 hooks 目錄存在
  if [[ ! -d "${project_hooks_dir}" ]]; then
    print_fail "專案 hooks 目錄不存在（${project_hooks_dir}）"
    return 1
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    print_info "將設定 git hooks（${hooks_dir}）"
    print_info "Shikigami 使用 Claude Code SessionStart hook，由 plugin 自動管理"
    print_pass "dry-run：git hooks 設定步驟確認"
    return 0
  fi

  # Shikigami 的 hooks 透過 Claude Code plugin 機制（hooks/hooks.json）管理，
  # 不使用傳統 .git/hooks 符號連結方式
  print_info "Shikigami hooks 透過 Claude Code plugin 機制管理（hooks/hooks.json）"
  print_info "Claude Code 啟動時會自動讀取 hooks 設定，無需手動設定 .git/hooks 符號連結"
  print_pass "git hooks 設定確認完成"
}

# STEP 9：驗證 validate-version.sh 可執行並取得 PASS
step_validate_version() {
  print_step "執行 validate-version.sh 驗證（AC3 最低成功條件）"

  local repo_dir="${SHIKIGAMI_DIR:-${DEFAULT_REPO_DIR}}"
  local validate_script="${repo_dir}/scripts/validate-version.sh"

  if [[ ! -f "${validate_script}" ]]; then
    print_fail "validate-version.sh 不存在（${validate_script}），請先完成 Clone repo 步驟"
    return 1
  fi

  if [[ ! -x "${validate_script}" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
      print_info "將執行：chmod +x ${validate_script}"
    else
      chmod +x "${validate_script}"
    fi
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    print_info "將執行：bash ${validate_script}"
    print_pass "dry-run：validate-version.sh 執行步驟確認"
    return 0
  fi

  print_info "執行 validate-version.sh..."
  local output
  if output=$(bash "${validate_script}" 2>&1); then
    print_pass "validate-version.sh 執行通過（exit code 0）"
    echo ""
    echo "--- validate-version.sh 輸出 ---"
    echo "$output"
    echo "---"
  else
    print_fail "validate-version.sh 執行失敗（exit code $?）"
    echo ""
    echo "--- validate-version.sh 輸出（含錯誤）---"
    echo "$output"
    echo "---"
  fi
}

# STEP 10：顯示後續必要步驟（認證設定）
step_show_next_steps() {
  print_step "後續必要步驟（需手動執行）"

  echo ""
  echo "  以下步驟需要互動式操作，setup 腳本不自動執行："
  echo ""
  echo "  1. Claude Code OAuth 認證（該 GCE 專屬帳號）："
  echo "       claude auth login"
  echo "     詳見：docs/gce-auth-guide.md §1.2"
  echo ""
  echo "  2. GitHub CLI 認證（用於 clone private repo / 操作 Issues）："
  echo "       gh auth login"
  echo ""
  echo "  3. git 全域設定（若尚未完成）："
  echo "       git config --global user.name \"你的名字\""
  echo "       git config --global user.email \"你的 email\""
  echo ""
  echo "  4. （可選）Claude Code Plugin 啟用確認："
  echo "       cd ~/shikigami && claude"
  echo "     Claude Code 啟動時會自動偵測並安裝 shikigami plugin"
  echo ""

  print_pass "後續步驟說明完成"
}

# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------
main() {
  print_header "${SCRIPT_NAME} — Shikigami 開發環境設定腳本"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo "  [DRY-RUN 模式] 僅顯示將執行的步驟，不實際執行任何命令"
  fi

  echo ""
  echo "  關聯文件：docs/env-portability-strategy.md（方向選定）"
  echo "  關聯文件：docs/env-rebuild-guide.md（環境重建流程）"
  echo "  關聯 ADR：ADR-012 §環境管理考量"

  # 依序執行各步驟
  step_apt_update
  step_install_base_tools
  step_install_nodejs
  step_install_claude_code
  step_install_gh_cli
  step_configure_git
  step_clone_repo
  step_setup_git_hooks
  step_validate_version
  step_show_next_steps

  # 總結
  print_header "執行結果總結"
  echo ""
  echo "  PASS  ：${STEPS_PASSED} 個步驟"
  echo "  SKIP  ：${STEPS_SKIPPED} 個步驟（已存在，冪等跳過）"
  echo "  FAIL  ：${STEPS_FAILED} 個步驟"
  echo ""

  if [[ "$EXIT_CODE" -eq 0 ]]; then
    echo "  [SUCCESS] 環境設定完成！請依「後續必要步驟」完成認證設定。"
  else
    echo "  [ERROR] 有 ${STEPS_FAILED} 個步驟失敗，請依錯誤訊息排查後重新執行。"
    echo "  提示：腳本為冪等設計，重新執行不會影響已完成的步驟。"
  fi
  echo ""

  exit "$EXIT_CODE"
}

main
