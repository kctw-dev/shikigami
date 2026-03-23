#!/usr/bin/env bash
# scripts/ci-health-check.sh
# CI 健康檢查腳本 — 主動偵測 CI 故障點
# Issue #450 — Sprint 123
#
# 使用方式：
#   bash scripts/ci-health-check.sh          # 人類可讀報告
#   bash scripts/ci-health-check.sh --json   # JSON 結構化輸出（供 Cruise SRE 消費）
#
# 退出碼：0 = PASS，1 = FAIL

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${CI_HEALTH_CHECK_REPO_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

# ──────────────────────────────────────────────
# 引數解析
# ──────────────────────────────────────────────
JSON_MODE=false
for arg in "$@"; do
  if [[ "$arg" == "--json" ]]; then
    JSON_MODE=true
  fi
done

# ──────────────────────────────────────────────
# 狀態追蹤
# ──────────────────────────────────────────────
OVERALL_PASS=true

# 各項目結果（供 JSON 輸出）
GITHUB_APP_STATUS="UNKNOWN"
GITHUB_APP_DETAIL=""
CI_VERSIONS_STATUS="UNKNOWN"
CI_VERSIONS_DETAIL=""
PACKAGES_STATUS="UNKNOWN"
declare -A PACKAGE_RESULTS
TOKEN_STATUS="UNKNOWN"
TOKEN_DETAIL=""

# ──────────────────────────────────────────────
# 工具函數
# ──────────────────────────────────────────────
print_header() {
  if [[ "$JSON_MODE" == "false" ]]; then
    echo "======================================"
    echo "  CI 健康檢查 (CI Health Check)"
    echo "  工作目錄：${REPO_ROOT}"
    echo "  時間：$(date '+%Y-%m-%d %H:%M:%S')"
    echo "======================================"
    echo ""
  fi
}

print_section() {
  if [[ "$JSON_MODE" == "false" ]]; then
    echo "──────────────────────────────────────"
    echo "  $1"
    echo "──────────────────────────────────────"
  fi
}

print_item() {
  if [[ "$JSON_MODE" == "false" ]]; then
    echo "  $1"
  fi
}

# JSON 字串轉義（簡易版）
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  echo "$s"
}

# ──────────────────────────────────────────────
# CHECK 1：GitHub App 安裝狀態（AC2）
# ──────────────────────────────────────────────
check_github_app() {
  print_section "1. GitHub App 安裝狀態"

  # 嘗試從 GITHUB_REPOSITORY 取得 repo（CI 環境）
  # 若無，嘗試從 git remote 推斷
  local repo_slug=""
  if [[ -n "${GITHUB_REPOSITORY:-}" ]]; then
    repo_slug="${GITHUB_REPOSITORY}"
  else
    # 從 git remote 推斷
    local remote_url
    remote_url=$(git -C "${REPO_ROOT}" remote get-url origin 2>/dev/null || echo "")
    if [[ "$remote_url" =~ github\.com[:/]([^/]+/[^/.]+) ]]; then
      repo_slug="${BASH_REMATCH[1]}"
      repo_slug="${repo_slug%.git}"
    fi
  fi

  if [[ -z "$repo_slug" ]]; then
    GITHUB_APP_STATUS="WARN"
    GITHUB_APP_DETAIL="無法推斷 GitHub repo slug，跳過 App 安裝偵測（非 GitHub 環境？）"
    print_item "WARN: ${GITHUB_APP_DETAIL}"
    return
  fi

  print_item "Repo: ${repo_slug}"

  # 呼叫 GitHub API 偵測 App 安裝
  local api_response
  local api_exit=0
  api_response=$(gh api "/repos/${repo_slug}/installation" \
    --jq '{"app_id": .app_id, "app_slug": .app_slug, "account": .account.login, "created_at": .created_at}' \
    2>&1) || api_exit=$?

  if [[ $api_exit -eq 0 ]]; then
    GITHUB_APP_STATUS="PASS"
    GITHUB_APP_DETAIL="GitHub App 已安裝 — ${api_response}"
    print_item "PASS: GitHub App 已安裝"
    print_item "      詳細：${api_response}"
  else
    # 404 代表未安裝；其他錯誤代表 API 問題
    if echo "$api_response" | grep -q "404\|Not Found\|installation.*not.*found"; then
      GITHUB_APP_STATUS="FAIL"
      GITHUB_APP_DETAIL="GitHub App 未安裝在此 repo（404）。請至 GitHub App 設定頁安裝。"
      OVERALL_PASS=false
      print_item "FAIL: GitHub App 未安裝"
      print_item "      建議：至 https://github.com/apps 安裝對應的 GitHub App"
    elif echo "$api_response" | grep -q "401\|403\|Unauthorized\|Forbidden"; then
      GITHUB_APP_STATUS="WARN"
      GITHUB_APP_DETAIL="GitHub API 認證不足，無法驗證 App 安裝（401/403）。請確認 gh auth 狀態。"
      print_item "WARN: GitHub API 認證不足，無法驗證 App 安裝"
      print_item "      建議：執行 'gh auth status' 確認認證狀態"
    else
      GITHUB_APP_STATUS="WARN"
      GITHUB_APP_DETAIL="GitHub API 呼叫異常：${api_response:0:200}"
      print_item "WARN: GitHub API 呼叫異常"
      print_item "      ${api_response:0:200}"
    fi
  fi
}

# ──────────────────────────────────────────────
# CHECK 2：Action 版本合規（AC3）— 整合 validate-ci-versions.sh
# ──────────────────────────────────────────────
check_ci_versions() {
  print_section "2. CI Action 版本合規（validate-ci-versions.sh）"

  local validate_script="${SCRIPT_DIR}/validate-ci-versions.sh"

  if [[ ! -f "$validate_script" ]]; then
    CI_VERSIONS_STATUS="FAIL"
    CI_VERSIONS_DETAIL="validate-ci-versions.sh 不存在：${validate_script}"
    OVERALL_PASS=false
    print_item "FAIL: validate-ci-versions.sh 不存在"
    return
  fi

  local validate_output
  local validate_exit=0
  validate_output=$(CI_VERSIONS_REPO_ROOT="${REPO_ROOT}" bash "$validate_script" 2>&1) || validate_exit=$?

  if [[ $validate_exit -eq 0 ]]; then
    CI_VERSIONS_STATUS="PASS"
    CI_VERSIONS_DETAIL="所有 Action 版本符合規範（CLAUDE.md 第 10 條）"
    print_item "PASS: 所有 Action 版本符合規範"
  else
    CI_VERSIONS_STATUS="FAIL"
    CI_VERSIONS_DETAIL="發現不符合規範的 Action 版本，請人工審核"
    OVERALL_PASS=false
    print_item "FAIL: 發現不符合規範的 Action 版本"
    if [[ "$JSON_MODE" == "false" ]]; then
      echo ""
      echo "  [validate-ci-versions.sh 輸出]"
      echo "$validate_output" | sed 's/^/    /'
    fi
  fi
}

# ──────────────────────────────────────────────
# CHECK 3：必要套件偵測（AC4）
# ──────────────────────────────────────────────
check_packages() {
  print_section "3. 必要套件偵測"

  # 必須存在的工具列表
  local required_packages=(
    "unzip"
    "git"
    "curl"
    "jq"
    "python3"
  )

  # 選擇性（WARN）工具列表
  local optional_packages=(
    "bun"
    "node"
    "gh"
  )

  local all_required_ok=true

  for pkg in "${required_packages[@]}"; do
    if command -v "$pkg" &>/dev/null; then
      local version
      version=$(command -v "$pkg")
      PACKAGE_RESULTS["${pkg}"]="PASS:${version}"
      print_item "  PASS: ${pkg} ($(command -v "$pkg"))"
    else
      PACKAGE_RESULTS["${pkg}"]="FAIL:not found"
      OVERALL_PASS=false
      all_required_ok=false
      print_item "  FAIL: ${pkg} — 未安裝。建議：apt-get install -y ${pkg}"
    fi
  done

  for pkg in "${optional_packages[@]}"; do
    if command -v "$pkg" &>/dev/null; then
      PACKAGE_RESULTS["${pkg}"]="PASS:$(command -v "$pkg")"
      print_item "  PASS: ${pkg} (選用)"
    else
      PACKAGE_RESULTS["${pkg}"]="WARN:not found"
      print_item "  WARN: ${pkg} — 未安裝（選用，部分 workflow 需要）"
    fi
  done

  if [[ "$all_required_ok" == "true" ]]; then
    PACKAGES_STATUS="PASS"
    print_item ""
    print_item "所有必要套件已就緒"
  else
    PACKAGES_STATUS="FAIL"
    print_item ""
    print_item "部分必要套件缺失，請安裝後重試"
  fi
}

# ──────────────────────────────────────────────
# CHECK 4：OAuth/Token 有效性偵測
# ──────────────────────────────────────────────
check_token() {
  print_section "4. OAuth/Token 有效性"

  local auth_output
  local auth_exit=0
  auth_output=$(gh auth status 2>&1) || auth_exit=$?

  if [[ $auth_exit -eq 0 ]]; then
    TOKEN_STATUS="PASS"
    TOKEN_DETAIL="gh auth 狀態正常"
    print_item "PASS: gh auth 認證有效"
    # 提取登入帳號（if available）
    local logged_as
    logged_as=$(echo "$auth_output" | grep -oE 'Logged in to .+ as [^ ]+' | head -1 || echo "")
    if [[ -n "$logged_as" ]]; then
      print_item "      ${logged_as}"
    fi
  else
    if echo "$auth_output" | grep -q "not.*logged\|not.*authenticated\|no credentials"; then
      TOKEN_STATUS="FAIL"
      TOKEN_DETAIL="gh 未登入，請執行 'gh auth login'"
      OVERALL_PASS=false
      print_item "FAIL: gh 未登入"
      print_item "      建議：執行 'gh auth login' 完成認證"
    else
      TOKEN_STATUS="WARN"
      TOKEN_DETAIL="gh auth 狀態異常：${auth_output:0:200}"
      print_item "WARN: gh auth 狀態異常"
      print_item "      ${auth_output:0:100}"
    fi
  fi
}

# ──────────────────────────────────────────────
# 輸出 JSON 報告
# ──────────────────────────────────────────────
output_json() {
  local overall_status
  if [[ "$OVERALL_PASS" == "true" ]]; then
    overall_status="PASS"
  else
    overall_status="FAIL"
  fi

  # 組裝 packages JSON
  local packages_json="{"
  local first=true
  for pkg in "${!PACKAGE_RESULTS[@]}"; do
    local result="${PACKAGE_RESULTS[$pkg]}"
    local pkg_status="${result%%:*}"
    local pkg_detail="${result#*:}"
    if [[ "$first" == "true" ]]; then
      first=false
    else
      packages_json+=","
    fi
    packages_json+="\"${pkg}\":{\"status\":\"${pkg_status}\",\"detail\":\"$(json_escape "$pkg_detail")\"}"
  done
  packages_json+="}"

  cat <<EOF
{
  "status": "$(json_escape "$overall_status")",
  "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "repo_root": "$(json_escape "$REPO_ROOT")",
  "checks": {
    "github_app": {
      "status": "$(json_escape "$GITHUB_APP_STATUS")",
      "detail": "$(json_escape "$GITHUB_APP_DETAIL")"
    },
    "ci_versions": {
      "status": "$(json_escape "$CI_VERSIONS_STATUS")",
      "detail": "$(json_escape "$CI_VERSIONS_DETAIL")"
    },
    "packages": {
      "status": "$(json_escape "$PACKAGES_STATUS")",
      "items": ${packages_json}
    },
    "token": {
      "status": "$(json_escape "$TOKEN_STATUS")",
      "detail": "$(json_escape "$TOKEN_DETAIL")"
    }
  }
}
EOF
}

# ──────────────────────────────────────────────
# 主流程
# ──────────────────────────────────────────────
main() {
  print_header

  check_github_app
  if [[ "$JSON_MODE" == "false" ]]; then echo ""; fi

  check_ci_versions
  if [[ "$JSON_MODE" == "false" ]]; then echo ""; fi

  check_packages
  if [[ "$JSON_MODE" == "false" ]]; then echo ""; fi

  check_token
  if [[ "$JSON_MODE" == "false" ]]; then echo ""; fi

  if [[ "$JSON_MODE" == "true" ]]; then
    output_json
  else
    # 人類可讀總結
    echo "======================================"
    if [[ "$OVERALL_PASS" == "true" ]]; then
      echo "  結果：PASS"
      echo "  所有 CI 健康檢查項目通過"
    else
      echo "  結果：FAIL"
      echo "  部分 CI 健康檢查項目失敗，請參閱上方報告修復"
    fi
    echo "======================================"
  fi

  if [[ "$OVERALL_PASS" == "true" ]]; then
    exit 0
  else
    exit 1
  fi
}

main
