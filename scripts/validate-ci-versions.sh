#!/usr/bin/env bash
# scripts/validate-ci-versions.sh
# Issue #367 — CI 版本釘定策略
#
# 掃描 .github/workflows/*.yml 中 GitHub Actions 版本號：
#   AC1：所有 actions/* 統一使用 @v4
#   AC2：偵測到 @v5, @v6... 等高版本號時輸出 [FAIL] 並 exit 1
#   AC3：無高版本號時 exit code 0
#
# 使用方式：
#   bash scripts/validate-ci-versions.sh
#
# 環境變數覆寫（供測試使用）：
#   WORKFLOWS_DIR=<路徑>  覆寫 .github/workflows 目錄（預設：.github/workflows）
#
# Exit code:
#   0 = 全部通過
#   1 = 偵測到不合規版本號
#
# 依賴：bash >= 4, grep（Pure Bash）
# 技術規範：ADR-002 Pure Bash + shared library

set -uo pipefail

source "$(dirname "$0")/lib/validate-helpers.sh"

# ---------------------------------------------------------------------------
# 常數
# ---------------------------------------------------------------------------
readonly WORKFLOWS_DIR="${WORKFLOWS_DIR:-.github/workflows}"

# 允許的最高版本號（@v4 及以下為合規）
readonly MAX_ALLOWED_MAJOR=4

# ---------------------------------------------------------------------------
# 狀態追蹤
# ---------------------------------------------------------------------------
EXIT_CODE=0
ERROR_COUNT=0
WARNING_COUNT=0

# ---------------------------------------------------------------------------
# 主要邏輯
# ---------------------------------------------------------------------------

print_section "CI Actions 版本釘定檢查（Issue #367）"

# 前置檢查：workflows 目錄必須存在
if [[ ! -d "$WORKFLOWS_DIR" ]]; then
  print_warning "目錄不存在：$WORKFLOWS_DIR（跳過 CI 版本檢查）"
  exit 0
fi

# 收集所有 .yml 檔案
mapfile -t WORKFLOW_FILES < <(find "$WORKFLOWS_DIR" -maxdepth 1 -name "*.yml" -type f 2>/dev/null | sort)

if [[ ${#WORKFLOW_FILES[@]} -eq 0 ]]; then
  print_warning "找不到 workflow 檔案：$WORKFLOWS_DIR/*.yml"
  exit 0
fi

print_info "掃描目錄：$WORKFLOWS_DIR（${#WORKFLOW_FILES[@]} 個 workflow 檔案）"

# ---------------------------------------------------------------------------
# 逐檔掃描
# ---------------------------------------------------------------------------
VIOLATION_COUNT=0

for WORKFLOW_FILE in "${WORKFLOW_FILES[@]}"; do
  FILE_BASENAME=$(basename "$WORKFLOW_FILE")
  FILE_VIOLATIONS=0

  # 找出所有 uses: ... 行
  while IFS= read -r LINE; do
    # 提取 actions/* 的版本號（@vN）
    # 比對格式：uses: actions/<任意>@v<數字>
    if [[ "$LINE" =~ uses:[[:space:]]*actions/[^@]+@v([0-9]+) ]]; then
      VERSION_MAJOR="${BASH_REMATCH[1]}"
      ACTION_REF=$(echo "$LINE" | grep -oP 'actions/[^\s]+@v[0-9]+' | head -1)

      if [[ "$VERSION_MAJOR" -gt "$MAX_ALLOWED_MAJOR" ]]; then
        print_fail "$FILE_BASENAME：$ACTION_REF 超出允許版本（最高 @v${MAX_ALLOWED_MAJOR}）"
        FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
        VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
      fi
    fi
  done < "$WORKFLOW_FILE"

  if [[ "$FILE_VIOLATIONS" -eq 0 ]]; then
    print_pass "$FILE_BASENAME：actions/* 版本合規"
  fi
done

# ---------------------------------------------------------------------------
# 結果摘要
# ---------------------------------------------------------------------------
print_section "摘要"

if [[ "$VIOLATION_COUNT" -eq 0 ]]; then
  print_pass "所有 actions/* 版本釘定合規（統一 @v${MAX_ALLOWED_MAJOR} 或以下）"
  print_info "升級 actions 版本前請先確認 self-hosted runner 相容性"
else
  print_fail "發現 $VIOLATION_COUNT 個版本釘定違規（需改回 @v${MAX_ALLOWED_MAJOR}）"
  EXIT_CODE=1
fi

exit $EXIT_CODE
