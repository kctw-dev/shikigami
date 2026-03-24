#!/bin/bash
# GCE agent-team watchdog: 同步 Claude OAuth token 至 GitHub Secret
# 前置條件：機器上已有 Claude CLI 登入 + gh CLI 認證
#
# 用法：
#   bash refresh-claude-token.sh
#
# 環境變數（可覆寫預設值）：
#   CLAUDE_CREDENTIALS_FILE  — credentials.json 路徑（預設自動偵測）
#   GITHUB_REPO              — 目標 GitHub repo（預設 kctw-dev/shikigami）
#   GITHUB_SECRET_NAME       — Secret 名稱（預設 CLAUDE_CODE_OAUTH_TOKEN）
#   MIN_TOKEN_LENGTH         — token 最短長度（預設 20）

set -euo pipefail

# ──────────────────────────────────────────────
# 設定
# ──────────────────────────────────────────────
REPO="${GITHUB_REPO:-kctw-dev/shikigami}"
SECRET_NAME="${GITHUB_SECRET_NAME:-CLAUDE_CODE_OAUTH_TOKEN}"
MIN_TOKEN_LENGTH="${MIN_TOKEN_LENGTH:-20}"

# Claude CLI credentials 可能位於多個路徑，依序嘗試
CANDIDATE_FILES=(
  "${CLAUDE_CREDENTIALS_FILE:-}"
  "${HOME}/.claude/.credentials.json"
  "${HOME}/.claude/credentials.json"
)

LOG_PREFIX="[WATCHDOG $(date '+%Y-%m-%dT%H:%M:%S')]"

# ──────────────────────────────────────────────
# 函式
# ──────────────────────────────────────────────

log_info() {
  echo "${LOG_PREFIX} INFO: $*"
}

log_error() {
  echo "${LOG_PREFIX} ERROR: $*" >&2
}

# 找到存在的 credentials 檔案
find_credentials_file() {
  for candidate in "${CANDIDATE_FILES[@]}"; do
    if [[ -n "$candidate" && -f "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

# 從 credentials JSON 提取 token（嘗試多種 key 路徑）
extract_token() {
  local file="$1"
  local token

  # 依序嘗試已知的 key 路徑
  token=$(jq -r '
    .claudeAiOauth.accessToken //
    .claudeAiOauth.oauth_token //
    .oauthToken //
    .accessToken //
    .oauth_token //
    .access_token //
    empty
  ' "$file" 2>/dev/null)

  echo "$token"
}

# 驗證 token 格式
validate_token() {
  local token="$1"

  if [[ -z "$token" || "$token" == "null" ]]; then
    return 1
  fi

  if [[ ${#token} -lt ${MIN_TOKEN_LENGTH} ]]; then
    return 2
  fi

  return 0
}

# 確認 gh CLI 可用且已認證
check_gh_auth() {
  if ! command -v gh &>/dev/null; then
    log_error "gh CLI 未安裝或不在 PATH 中"
    return 1
  fi

  if ! gh auth status &>/dev/null; then
    log_error "gh CLI 未認證，請先執行 'gh auth login'"
    return 1
  fi

  return 0
}

# ──────────────────────────────────────────────
# 主流程
# ──────────────────────────────────────────────

main() {
  log_info "啟動 Claude OAuth token watchdog"
  log_info "目標 repo: ${REPO} / secret: ${SECRET_NAME}"

  # 1. 找 credentials 檔案
  local creds_file
  if ! creds_file=$(find_credentials_file); then
    log_error "找不到 Claude credentials 檔案，已嘗試路徑："
    for c in "${CANDIDATE_FILES[@]}"; do
      [[ -n "$c" ]] && log_error "  - $c"
    done
    log_error "請確認 Claude CLI 已登入（claude login）"
    exit 1
  fi
  log_info "使用 credentials 檔案: ${creds_file}"

  # 2. 提取 token
  local token
  token=$(extract_token "$creds_file")

  # 3. 驗證 token
  local validate_result
  validate_token "$token"
  validate_result=$?

  case $validate_result in
    1)
      log_error "無法從 ${creds_file} 取得有效 token（值為空或 null）"
      log_error "不覆蓋現有 Secret，避免中斷服務"
      exit 1
      ;;
    2)
      log_error "token 長度異常（${#token} < ${MIN_TOKEN_LENGTH}），可能已損壞"
      log_error "不覆蓋現有 Secret，避免中斷服務"
      exit 1
      ;;
  esac

  log_info "token 驗證通過（長度: ${#token}）"

  # 4. 確認 gh CLI 就緒
  if ! check_gh_auth; then
    exit 1
  fi

  # 5. 更新 GitHub Secret
  log_info "正在同步 token 至 GitHub Secret..."
  if ! echo "$token" | gh secret set "$SECRET_NAME" -R "$REPO" --body -; then
    log_error "gh secret set 失敗，請檢查 gh CLI 認證與 repo 權限"
    exit 1
  fi

  log_info "token 同步成功"
  log_info "完成"
}

main "$@"
