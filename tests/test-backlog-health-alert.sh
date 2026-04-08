#!/usr/bin/env bash
# test-backlog-health-alert.sh — #882 Backlog Health 自動告警測試
# AC1: backlog-health-report.sh 支援 --alert 模式，低水位時 exit 1
# AC2: GitHub Actions workflow 存在（backlog-health-alert.yml）
# AC3: workflow 包含建立 GitHub Issue 邏輯（--body-file 模式）
# AC4: MIN_CANDIDATES 閾值可透過 env var 覆蓋
# AC5: tests/test-backlog-health-alert.sh 測試告警觸發與靜默邏輯
# NFR1: 告警去重（檢查已存在 open issue）
# NFR2: workflow 使用 --body-file 模式建立 Issue

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

check() {
  local desc="$1"
  local result="$2"
  if [[ "$result" == "pass" ]]; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== test-backlog-health-alert.sh (#882) ==="

SCRIPT="$REPO_ROOT/scripts/backlog-health-report.sh"
WORKFLOW="$REPO_ROOT/.github/workflows/backlog-health-alert.yml"

# --- AC1: --alert 模式存在 ---
if grep -q "\-\-alert" "$SCRIPT" 2>/dev/null; then
  check "AC1: backlog-health-report.sh 支援 --alert 模式" "pass"
else
  check "AC1: backlog-health-report.sh 支援 --alert 模式" "fail"
fi

# --- AC1: MIN_CANDIDATES 定義存在 ---
if grep -q "MIN_CANDIDATES" "$SCRIPT" 2>/dev/null; then
  check "AC1: MIN_CANDIDATES 變數定義存在" "pass"
else
  check "AC1: MIN_CANDIDATES 變數定義存在" "fail"
fi

# --- AC1: --alert 模式低水位時 exit 1 ---
# 建立 mock 環境：0 個 sprint-candidate
TMP_DIR=$(mktemp -d)
TODAY=$(date '+%Y-%m-%d')
# 建立包含非 sprint-candidate action 的假 log
cat > "$TMP_DIR/${TODAY}-session-test-fake.jsonl" <<'EOF'
{"type":"message","action":"other-action","issue":"#100","timestamp":"2026-01-01T00:00:00Z"}
EOF

ALERT_EXIT=0
bash "$SCRIPT" --alert --min-candidates 5 --log-dir "$TMP_DIR" --last-n 1 2>&1 || ALERT_EXIT=$?
rm -rf "$TMP_DIR"

if [[ $ALERT_EXIT -eq 1 ]]; then
  check "AC1: 低水位（0 < 5）時 --alert 模式 exit 1" "pass"
else
  check "AC1: 低水位（0 < 5）時 --alert 模式 exit 1" "fail"
fi

# --- AC1: --alert 模式高水位時 exit 0 ---
TMP_DIR2=$(mktemp -d)
TODAY=$(date '+%Y-%m-%d')
# 建立包含足夠 sprint-candidate 的假 log
for i in $(seq 1 15); do
  echo "{\"type\":\"message\",\"action\":\"sprint-candidate\",\"issue\":\"#${i}\",\"timestamp\":\"2026-01-01T00:00:00Z\"}" \
    >> "$TMP_DIR2/${TODAY}-session-test-fake.jsonl"
done

QUIET_EXIT=0
bash "$SCRIPT" --alert --min-candidates 10 --log-dir "$TMP_DIR2" --last-n 1 2>&1 || QUIET_EXIT=$?
rm -rf "$TMP_DIR2"

if [[ $QUIET_EXIT -eq 0 ]]; then
  check "AC1: 高水位（15 >= 10）時 --alert 模式 exit 0（靜默）" "pass"
else
  check "AC1: 高水位（15 >= 10）時 --alert 模式 exit 0（靜默）" "fail"
fi

# --- AC2: workflow 檔案存在 ---
if [[ -f "$WORKFLOW" ]]; then
  check "AC2: .github/workflows/backlog-health-alert.yml 存在" "pass"
else
  check "AC2: .github/workflows/backlog-health-alert.yml 存在" "fail"
fi

# --- AC2: workflow 使用 @v4 ---
if [[ -f "$WORKFLOW" ]]; then
  # 不應有非 v4 的 actions（只檢查 uses: actions/ 開頭）
  if grep -E "uses: actions/[^@]+@" "$WORKFLOW" 2>/dev/null | grep -qv "@v4"; then
    check "AC2: workflow 中所有 actions 使用 @v4" "fail"
  else
    check "AC2: workflow 中所有 actions 使用 @v4" "pass"
  fi
fi

# --- AC3: workflow 包含建立 Issue 邏輯 ---
if [[ -f "$WORKFLOW" ]]; then
  if grep -q "gh issue create\|issue.*create" "$WORKFLOW" 2>/dev/null; then
    check "AC3: workflow 包含建立 GitHub Issue 邏輯" "pass"
  else
    check "AC3: workflow 包含建立 GitHub Issue 邏輯" "fail"
  fi
fi

# --- NFR2: workflow 使用 --body-file 模式（不使用 --body "..." 直接傳入）---
if [[ -f "$WORKFLOW" ]]; then
  # 檢查沒有直接 --body 帶引號的用法
  if grep -q "\-\-body-file" "$WORKFLOW" 2>/dev/null; then
    check "NFR2: workflow 使用 --body-file 模式" "pass"
  else
    check "NFR2: workflow 使用 --body-file 模式" "fail"
  fi
  # 確認沒有 --body "..." 直接模式（只找 --body 後跟引號的情形）
  if grep -E "\-\-body ['\"]" "$WORKFLOW" 2>/dev/null | grep -qv "\-\-body-file"; then
    check "NFR2: workflow 無 --body 直接模式（禁止）" "fail"
  else
    check "NFR2: workflow 無 --body 直接模式（禁止）" "pass"
  fi
fi

# --- NFR1: 告警去重（workflow 包含 open issue 檢查）---
if [[ -f "$WORKFLOW" ]]; then
  if grep -q "gh issue list\|issue.*list" "$WORKFLOW" 2>/dev/null; then
    check "NFR1: workflow 包含 open issue 去重檢查" "pass"
  else
    check "NFR1: workflow 包含 open issue 去重檢查" "fail"
  fi
fi

# --- AC4: MIN_CANDIDATES 可透過 env var 覆蓋 ---
if [[ -f "$WORKFLOW" ]]; then
  if grep -q "MIN_CANDIDATES" "$WORKFLOW" 2>/dev/null; then
    check "AC4: workflow 支援 MIN_CANDIDATES env var 覆蓋" "pass"
  else
    check "AC4: workflow 支援 MIN_CANDIDATES env var 覆蓋" "fail"
  fi
fi

# --- Functional: --alert 標記在 normal 模式下不影響輸出 ---
SCRIPT_OUT=$(bash "$SCRIPT" --last-n 1 2>&1) || true
if [[ -n "$SCRIPT_OUT" ]]; then
  check "Functional: 正常模式（無 --alert）仍可正常執行" "pass"
else
  check "Functional: 正常模式（無 --alert）仍可正常執行" "fail"
fi

# --- AC5: MIN_CANDIDATES 同步至 10（ADR-043 驗收） ---
echo ""
echo "=== AC5: MIN_CANDIDATES 同步驗證（ADR-043 閾值 = 10） ==="

# 檢查 backlog-health-report.sh 中 MIN_CANDIDATES=10
if grep -q "^MIN_CANDIDATES=10" "$SCRIPT" 2>/dev/null; then
  check "AC5.1: backlog-health-report.sh 預設值為 10" "pass"
else
  check "AC5.1: backlog-health-report.sh 預設值為 10" "fail"
fi

# 檢查 backlog-health-alert.yml 中 default: "10"
if grep -q 'default: "10"' "$WORKFLOW" 2>/dev/null; then
  check "AC5.2: backlog-health-alert.yml 預設值為 10" "pass"
else
  check "AC5.2: backlog-health-alert.yml 預設值為 10" "fail"
fi

# 檢查 workflow 中 MIN_CANDIDATES 環境變數設定
if grep -q "MIN_CANDIDATES:.*'10'" "$WORKFLOW" 2>/dev/null; then
  check "AC5.3: workflow env 中 MIN_CANDIDATES 預設為 10" "pass"
else
  check "AC5.3: workflow env 中 MIN_CANDIDATES 預設為 10" "fail"
fi

# 檢查沒有其他不同的 MIN_CANDIDATES 值（應該全是 10）
# 更精確的檢查：MIN_CANDIDATES=10 或 default: "10" 或 || '10'
SCRIPT_VALUES=$(grep -E "^MIN_CANDIDATES=|default:" "$SCRIPT" "$WORKFLOW" 2>/dev/null | grep -oE "MIN_CANDIDATES=[0-9]+|default: \"[0-9]+\"" | grep -oE "[0-9]+" | sort -u | grep -v "^10$" || true)
if [[ -z "$SCRIPT_VALUES" ]]; then
  check "AC5.4: 所有 MIN_CANDIDATES 值一致（皆為 10）" "pass"
else
  check "AC5.4: 所有 MIN_CANDIDATES 值一致（皆為 10）" "fail"
  echo "    發現非 10 的值：$SCRIPT_VALUES"
fi

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
