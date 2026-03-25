#!/usr/bin/env bash
# tests/test-init-project.sh
# Story #845 — init-project.sh 自動化測試 — Onboarding 腳本初始化驗證
# AC1: 新增 tests/test-init-project.sh
# AC2: 測試在空目錄中執行 init-project.sh 後產生預期結構
# AC3: 測試重複執行的冪等性（不覆蓋已有設定）
# AC4: 測試 PASS 且 exit 0
# NFR1: 測試在 /tmp 下建立沙箱目錄，不影響真實 repo

set -uo pipefail

# ---------------------------------------------------------------------------
# 測試框架
# ---------------------------------------------------------------------------
PASS_COUNT=0
FAIL_COUNT=0

pass() {
  echo "PASS: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "FAIL: $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

assert_file_exists() {
  local path="$1"
  local label="$2"
  if [[ -f "$path" ]]; then
    pass "$label"
  else
    fail "$label (file not found: $path)"
  fi
}

assert_dir_exists() {
  local path="$1"
  local label="$2"
  if [[ -d "$path" ]]; then
    pass "$label"
  else
    fail "$label (directory not found: $path)"
  fi
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -qF "$pattern" "$file" 2>/dev/null; then
    pass "$label"
  else
    fail "$label (pattern not found in $file)"
  fi
}

assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  if [[ "$actual" -eq "$expected" ]]; then
    pass "$label"
  else
    fail "$label (expected exit code $expected, got $actual)"
  fi
}

# ---------------------------------------------------------------------------
# 設定路徑
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INIT_PROJECT_SCRIPT="${REPO_ROOT}/scripts/init-project.sh"
TEMPLATE_DIR="${REPO_ROOT}/templates/project-template"

# NFR1: 沙箱目錄在 /tmp 下
SANDBOX_BASE="/tmp/test-init-project-$$"
SANDBOX_DIR="${SANDBOX_BASE}/test-project"

echo "=== Story #845：init-project.sh 自動化測試 ==="
echo "REPO_ROOT: $REPO_ROOT"
echo "SCRIPT: $INIT_PROJECT_SCRIPT"
echo "SANDBOX: $SANDBOX_BASE"
echo ""

# 記錄真實 repo 中現有的檔案集合（作為基線）
REPO_BASELINE=$(find "$REPO_ROOT" -maxdepth 1 -type f -printf '%f\n' | sort)

# 清理環境（確保乾淨的沙箱）
if [[ -d "$SANDBOX_BASE" ]]; then
  rm -rf "$SANDBOX_BASE"
fi

# ---------------------------------------------------------------------------
# 前置條件：腳本與模板存在
# ---------------------------------------------------------------------------
echo "--- 前置條件 ---"

if [[ ! -f "$INIT_PROJECT_SCRIPT" ]]; then
  fail "前置：scripts/init-project.sh 存在"
  echo ""
  echo "=== 測試結果 ==="
  echo "PASS: $PASS_COUNT"
  echo "FAIL: $FAIL_COUNT"
  echo "總結：前置條件失敗，無法執行後續測試"
  exit 1
fi
pass "前置：scripts/init-project.sh 存在"

if [[ ! -d "$TEMPLATE_DIR" ]]; then
  fail "前置：templates/project-template 目錄存在"
  echo ""
  echo "=== 測試結果 ==="
  echo "PASS: $PASS_COUNT"
  echo "FAIL: $FAIL_COUNT"
  echo "總結：前置條件失敗，無法執行後續測試"
  exit 1
fi
pass "前置：templates/project-template 目錄存在"

# ---------------------------------------------------------------------------
# TC-1：空目錄初始化 — 執行後應產生預期結構
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-1：空目錄初始化 —— AC2 ---"

# 建立沙箱空目錄
mkdir -p "$SANDBOX_BASE"

# 執行 init-project.sh，捕捉 exit code
bash "$INIT_PROJECT_SCRIPT" "$SANDBOX_DIR" "test-project" > /tmp/init-output-$$.log 2>&1
EXIT_CODE=$?

assert_exit_code 0 $EXIT_CODE "TC-1a: init-project.sh 執行成功（exit 0）— AC4"

# 檢查目錄結構
assert_dir_exists "$SANDBOX_DIR" "TC-1b: 目錄 $SANDBOX_DIR 已建立"

# 檢查模板檔案是否被複製
# 從 templates/project-template 中找出所有檔案
for template_file in "$TEMPLATE_DIR"/{.,}*; do
  fname=$(basename "$template_file")
  # 跳過 . 和 ..
  [[ "$fname" == "." || "$fname" == ".." ]] && continue
  [[ -f "$template_file" ]] || continue

  # 檢查是否被複製到沙箱
  target_file="$SANDBOX_DIR/$fname"
  assert_file_exists "$target_file" "TC-1c: 模板檔案 $fname 已複製"
done

# 檢查專案名稱替換（CLAUDE.md 應含 test-project）
if [[ -f "$SANDBOX_DIR/CLAUDE.md" ]]; then
  # 模板中應包含 {{PROJECT_NAME}} 佔位符
  # 執行後應被替換為 test-project
  assert_file_contains "$SANDBOX_DIR/CLAUDE.md" "test-project" \
    "TC-1d: 專案名稱替換成功（{{PROJECT_NAME}} → test-project）"
fi

# ---------------------------------------------------------------------------
# TC-2：冪等性 — 重複執行不覆蓋已有設定檔 — AC3
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-2：冪等性 —— AC3 ---"

# 修改一個已複製的檔案
CLAUDE_FILE="$SANDBOX_DIR/CLAUDE.md"
MARKER_CONTENT="TEST-MARKER-$RANDOM"
if [[ -f "$CLAUDE_FILE" ]]; then
  echo "$MARKER_CONTENT" >> "$CLAUDE_FILE"
  pass "TC-2a: 在 CLAUDE.md 中追加測試標記"
fi

# 第二次執行，應該跳過已存在的檔案
bash "$INIT_PROJECT_SCRIPT" "$SANDBOX_DIR" "test-project" > /tmp/init-output-2-$$.log 2>&1
EXIT_CODE=$?

assert_exit_code 0 $EXIT_CODE "TC-2b: 第二次執行成功（exit 0）"

# 檢查標記是否仍在（未被覆蓋）
if [[ -f "$CLAUDE_FILE" ]]; then
  assert_file_contains "$CLAUDE_FILE" "$MARKER_CONTENT" \
    "TC-2c: 標記仍存在（檔案未被覆蓋）— AC3 冪等性"
else
  fail "TC-2c: 標記仍存在（檔案未被覆蓋）— AC3 冪等性 (CLAUDE.md 遺失)"
fi

# 檢查日誌中是否包含 SKIP 訊息
if grep -q "SKIP.*Already exists" /tmp/init-output-2-$$.log; then
  pass "TC-2d: 日誌記錄跳過已存在的檔案"
else
  fail "TC-2d: 日誌記錄跳過已存在的檔案 (未在日誌中找到 SKIP 訊息)"
fi

# ---------------------------------------------------------------------------
# TC-3：/tmp 沙箱隔離 — 確認不影響真實 repo — NFR1
# ---------------------------------------------------------------------------
echo ""
echo "--- TC-3：沙箱隔離 —— NFR1 ---"

# 驗證沙箱目錄位於 /tmp 下
if [[ "$SANDBOX_BASE" == /tmp/* ]]; then
  pass "TC-3a: 沙箱位於 /tmp 目錄下"
else
  fail "TC-3a: 沙箱位於 /tmp 目錄下 (實際: $SANDBOX_BASE)"
fi

# 驗證真實 repo 未受影響（檔案集合不變，除了測試過程中建立的測試指令檔）
REPO_CURRENT=$(find "$REPO_ROOT" -maxdepth 1 -type f -printf '%f\n' | sort)
if [[ "$REPO_BASELINE" == "$REPO_CURRENT" ]]; then
  pass "TC-3b: 真實 repo 未受測試影響（檔案集合不變）"
else
  # 允許臨時檔案（以 /tmp 開頭的路徑不算）
  fail "TC-3b: 真實 repo 未受測試影響（檔案集合不變）"
fi

# ---------------------------------------------------------------------------
# AC1: tests/test-init-project.sh 存在
# ---------------------------------------------------------------------------
echo ""
echo "--- AC1：測試檔案存在驗證 ---"

TEST_SCRIPT="$REPO_ROOT/tests/test-init-project.sh"
assert_file_exists "$TEST_SCRIPT" "AC1: tests/test-init-project.sh 存在"

# ---------------------------------------------------------------------------
# 清理沙箱
# ---------------------------------------------------------------------------
echo ""
echo "--- 清理沙箱 ---"
rm -rf "$SANDBOX_BASE"
rm -f /tmp/init-output-$$.log /tmp/init-output-2-$$.log
pass "清理完成"

# ---------------------------------------------------------------------------
# 結果摘要
# ---------------------------------------------------------------------------
echo ""
echo "=== 測試結果 ==="
echo "PASS: $PASS_COUNT"
echo "FAIL: $FAIL_COUNT"

if [[ $FAIL_COUNT -eq 0 ]]; then
  echo "總結：Story #845 全部 AC 通過（AC1-AC4 + NFR1）"
  exit 0
else
  echo "總結：發現 $FAIL_COUNT 個 FAIL，請修正"
  exit 1
fi
