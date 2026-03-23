#!/usr/bin/env bash
# test-validate-ci-versions.sh
# Issue #367 — CI 版本釘定策略：validate-ci-versions.sh 測試
#
# AC1：所有 .github/workflows/*.yml 中 actions/* 使用 @v4
# AC2：腳本存在且可執行，偵測高版本號（@v5, @v6...）發出 FAIL
# AC3：無高版本號時 exit code 0

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  [PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }
section() { echo ""; echo "── $1 ────────────────────────────────────"; }

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ -z "$REPO_ROOT" ]]; then
  echo "[ERROR] 不在 git repo 內"
  exit 1
fi

SCRIPT="$REPO_ROOT/scripts/validate-ci-versions.sh"

# ── AC2：腳本存在性 ──────────────────────────────────────────────
section "AC2 腳本存在性"

if [[ -f "$SCRIPT" ]]; then
  pass "scripts/validate-ci-versions.sh 存在"
else
  fail "scripts/validate-ci-versions.sh 不存在"
fi

if [[ -x "$SCRIPT" ]]; then
  pass "scripts/validate-ci-versions.sh 可執行"
else
  fail "scripts/validate-ci-versions.sh 無執行權限"
fi

# ── AC1：現有 workflows 全部使用 @v4 ────────────────────────────
section "AC1 現有 workflows 版本釘定"

WORKFLOW_DIR="$REPO_ROOT/.github/workflows"
if [[ -d "$WORKFLOW_DIR" ]]; then
  pass ".github/workflows 目錄存在"
else
  fail ".github/workflows 目錄不存在"
fi

# 掃描 actions/* 高版本號（@v5, @v6...）
HIGH_VER=$(grep -rn 'uses:.*actions/.*@v[5-9]\|uses:.*actions/.*@v[0-9][0-9]' \
  "$WORKFLOW_DIR"/*.yml 2>/dev/null || true)

if [[ -z "$HIGH_VER" ]]; then
  pass "所有 actions/* 均為 @v4 或以下（無高版本號）"
else
  fail "偵測到高版本號 actions：$HIGH_VER"
fi

# ── AC2：腳本可正確偵測高版本號（模擬測試）────────────────────
section "AC2 腳本偵測高版本號（沙箱測試）"

if [[ ! -f "$SCRIPT" ]]; then
  echo "  [SKIP] 腳本不存在，跳過功能測試"
else
  # 建立暫時 workflow 含高版本號
  TMPDIR_TEST=$(mktemp -d)
  mkdir -p "$TMPDIR_TEST/.github/workflows"
  cat > "$TMPDIR_TEST/.github/workflows/test.yml" <<'YAML'
name: Test
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-node@v4
YAML

  # 以 WORKFLOWS_DIR 覆寫執行腳本
  OUTPUT=$(WORKFLOWS_DIR="$TMPDIR_TEST/.github/workflows" bash "$SCRIPT" 2>&1 || true)

  if echo "$OUTPUT" | grep -q '\[FAIL\]'; then
    pass "腳本正確偵測 @v6 並輸出 [FAIL]"
  else
    fail "腳本未偵測到 @v6 高版本號（output: $OUTPUT）"
  fi

  # 建立全 @v4 的乾淨 workflow
  cat > "$TMPDIR_TEST/.github/workflows/test.yml" <<'YAML'
name: Test
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
YAML

  WORKFLOWS_DIR="$TMPDIR_TEST/.github/workflows" bash "$SCRIPT" > /dev/null 2>&1
  CLEAN_EXIT=$?
  if [[ "$CLEAN_EXIT" -eq 0 ]]; then
    pass "全 @v4 時腳本 exit code 為 0"
  else
    fail "全 @v4 時腳本 exit code 非 0（got: $CLEAN_EXIT）"
  fi

  rm -rf "$TMPDIR_TEST"
fi

# ── AC3：對真實 repo 執行腳本 exit code 0 ───────────────────────
section "AC3 真實 repo 執行結果"

if [[ -f "$SCRIPT" ]]; then
  if bash "$SCRIPT" > /dev/null 2>&1; then
    pass "validate-ci-versions.sh 對現有 workflows 回傳 exit code 0"
  else
    fail "validate-ci-versions.sh 偵測到問題（現有 workflows 可能有版本釘定問題）"
  fi
else
  echo "  [SKIP] 腳本不存在，跳過"
fi

# ── CLAUDE.md 開發紅線 ──────────────────────────────────────────
section "CLAUDE.md CI Actions 版本釘定紅線"

CLAUDE_MD="$REPO_ROOT/CLAUDE.md"
if grep -q "CI Actions 版本釘定" "$CLAUDE_MD" 2>/dev/null; then
  pass "CLAUDE.md 包含 CI Actions 版本釘定開發紅線"
else
  fail "CLAUDE.md 缺少 CI Actions 版本釘定開發紅線"
fi

# ── 結果摘要 ────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────"
echo "結果：PASS=$PASS  FAIL=$FAIL"
echo "────────────────────────────────────────"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
