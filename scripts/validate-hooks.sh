#!/usr/bin/env bash
# scripts/validate-hooks.sh
# Story #713 — onboarding hooks 驗證腳本
#
# 驗證 hooks/ 目錄下的所有 .sh 檔案是否存在且可執行。
# 作為 onboarding 安裝後的驗證步驟。
#
# Exit code:
#   0 = 所有 hooks 通過驗證
#   1 = 有 hooks 驗證失敗（缺失、無執行權限或其他）
#
# 使用方式：
#   bash scripts/validate-hooks.sh
#
# 依賴：bash >= 4, find, grep

set -uo pipefail

# ---------------------------------------------------------------------------
# 常數
# ---------------------------------------------------------------------------
readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly HOOKS_DIR="${REPO_ROOT}/hooks"

# 必須驗證的 hooks（應該存在且可執行）
# 注意：lib/ 目錄和 session-start 檔案不在驗證範圍
declare -a REQUIRED_HOOKS=(
  "claim-issue.sh"
  "release-issue.sh"
  "task-gate.sh"
)

# ---------------------------------------------------------------------------
# 狀態追蹤
# ---------------------------------------------------------------------------
EXIT_CODE=0
PASS_COUNT=0
FAIL_COUNT=0

# ---------------------------------------------------------------------------
# 輔助函式
# ---------------------------------------------------------------------------
print_pass() {
  echo "[PASS] $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

print_fail() {
  echo "[FAIL] $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  EXIT_CODE=1
}

print_info() {
  echo "[INFO] $1"
}

# ---------------------------------------------------------------------------
# 主邏輯
# ---------------------------------------------------------------------------

# 檢查 hooks 目錄存在
if [[ ! -d "$HOOKS_DIR" ]]; then
  print_fail "hooks/ 目錄不存在：$HOOKS_DIR"
  exit 1
fi

print_info "開始驗證 hooks 完整性..."
print_info "Hooks 目錄：$HOOKS_DIR"
echo ""

# ── 驗證必須 hooks（AC2 要求的三個） ───────────────────────────────────
print_info "驗證必須 hooks："

for hook in "${REQUIRED_HOOKS[@]}"; do
  hook_path="${HOOKS_DIR}/${hook}"

  if [[ ! -f "$hook_path" ]]; then
    print_fail "$hook：file not found"
  elif [[ ! -x "$hook_path" ]]; then
    print_fail "$hook：permission denied (not executable)"
  else
    print_pass "$hook"
  fi
done

echo ""

# ── 掃描並驗證所有 .sh 檔案（NFR1 要求的完整性） ──────────────────────
print_info "掃描並驗證所有 .sh 檔案（NFR1）："
echo ""

# 找出所有 .sh 檔案（排除 lib/ 子目錄，不排除 session-start）
while IFS= read -r hook_path; do
  hook_file=$(basename "$hook_path")

  # 跳過 lib/ 目錄中的檔案
  if [[ "$hook_path" == *"/lib/"* ]]; then
    continue
  fi

  # 跳過 hooks.json 和 run-hook.cmd
  if [[ "$hook_file" == "hooks.json" || "$hook_file" == "run-hook.cmd" ]]; then
    continue
  fi

  # 驗證 .sh 檔案
  if [[ "$hook_file" == *.sh ]]; then
    if [[ ! -x "$hook_path" ]]; then
      print_fail "$hook_file：permission denied (not executable)"
    else
      print_pass "$hook_file"
    fi
  fi
done < <(find "$HOOKS_DIR" -maxdepth 1 -type f -name "*.sh" | sort)

echo ""

# ── 檢查是否有任何驗證失敗 ──────────────────────────────────────────────
print_info "驗證統計："
print_info "  通過：$PASS_COUNT"
print_info "  失敗：$FAIL_COUNT"
echo ""

if [[ $EXIT_CODE -eq 0 ]]; then
  print_pass "所有 hooks 驗證通過！"
else
  print_fail "部分 hooks 驗證失敗，請檢查上述失敗項目"
fi

exit $EXIT_CODE
