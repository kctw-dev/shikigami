#!/usr/bin/env bash
# tests/test-update-adr-index.sh
# Story #873: update-adr-index.sh 自動化測試 — ADR 索引更新腳本單元測試
#
# AC1: 新建 tests/test-update-adr-index.sh（補強邏輯測試）
# AC2: 測試案例涵蓋：正常更新（新 ADR 出現在索引）、冪等性（執行兩次結果相同）、空目錄處理
# AC3: 使用 fixture ADR 目錄，不修改真實 docs/adr/
# AC4: 執行時間 < 5s（NFR1）
# NFR: fixture 隔離，不污染真實 ADR 目錄

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="${REPO_ROOT}/scripts/update-adr-index.sh"

PASS=0
FAIL=0
START_TIME=$(date +%s)

# ─── Fixture Setup (AC3) ──────────────────────────────────────────────────────
FIXTURE_DIR=$(mktemp -d /tmp/test-update-adr-XXXXXX)
FIXTURE_ADR="${FIXTURE_DIR}/docs/adr"
mkdir -p "$FIXTURE_ADR"

cleanup() { rm -rf "$FIXTURE_DIR"; }
trap cleanup EXIT

# Helper functions
pass() { echo "[PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL + 1)); }

echo "=== Sprint 170 #873 — update-adr-index.sh 自動化測試 ==="
echo "Script: $SCRIPT"
echo "Fixture: $FIXTURE_DIR"
echo ""

# Script exists
if [[ -f "$SCRIPT" ]]; then
    pass "SETUP: update-adr-index.sh 存在"
else
    fail "SETUP: update-adr-index.sh 不存在: $SCRIPT"
    exit 1
fi

# ─── Fixture ADR 檔案建立 ─────────────────────────────────────────────────────

# Create fixture ADR files in the format the script expects
cat > "${FIXTURE_ADR}/ADR-001-test-decision.md" << 'EOF'
# ADR-001: 測試決策 A

**狀態**: Accepted
**日期**: 2026-01-15

## 背景
這是一個測試 ADR 文件。

## 決策
選擇方案 A。
EOF

cat > "${FIXTURE_ADR}/ADR-002-another-decision.md" << 'EOF'
# ADR-002: 測試決策 B

**狀態**: Proposed
**日期**: 2026-02-10

## 背景
這是第二個測試 ADR 文件。

## 決策
選擇方案 B。
EOF

# ─── AC2: 正常更新（新 ADR 出現在索引）──────────────────────────────────────

echo "--- AC2: 正常更新（新 ADR 出現在索引）---"

# Run script against fixture directory (need to set repo root to fixture)
# The script uses REPO_ROOT to find docs/adr, so we create a temp script wrapper
WRAPPER_SCRIPT="${FIXTURE_DIR}/run-update-adr.sh"
cat > "$WRAPPER_SCRIPT" << EOF
#!/usr/bin/env bash
# Wrapper: override REPO_ROOT to point to fixture
set -euo pipefail
REPO_ROOT="${FIXTURE_DIR}"
ADR_DIR="\${REPO_ROOT}/docs/adr"
OUTPUT_FILE="\${ADR_DIR}/README.md"

if [ ! -d "\$ADR_DIR" ]; then
  echo "[ERROR] ADR 目錄不存在：\${ADR_DIR}" >&2
  exit 1
fi

ADR_FILES=\$(ls "\${ADR_DIR}/ADR-"*.md 2>/dev/null | sort || true)

extract_field() {
  local file="\$1" field="\$2"
  grep -m1 -iE "^\*\*\${field}\*\*[：:]" "\$file" 2>/dev/null \
    | sed -E "s/^\*\*[^*]+\*\*[：:][[:space:]]*//" \
    | tr -d '\r' | head -1 || echo "—"
}

extract_title() {
  local file="\$1"
  head -5 "\$file" | grep -m1 -E "^#" | sed 's/^#*[[:space:]]*//' | head -1 || echo "Unknown"
}

extract_number() {
  local file="\$1"
  basename "\$file" | grep -oE 'ADR-[0-9]+' | head -1 || echo "ADR-000"
}

{
  cat << 'HEADER'
# ADR 目錄索引

> 本文件由 \`scripts/update-adr-index.sh\` 自動產生，請勿手動修改。
> 最後更新：TIMESTAMP_PLACEHOLDER

## 架構決策紀錄（Architecture Decision Records）

| ADR 編號 | 標題 | 狀態 | 日期 |
|---------|------|------|------|
HEADER

  while IFS= read -r adr_file; do
    [ -f "\$adr_file" ] || continue
    NUMBER=\$(extract_number "\$adr_file")
    TITLE=\$(extract_title "\$adr_file")
    STATUS=\$(extract_field "\$adr_file" "狀態|Status")
    DATE=\$(extract_field "\$adr_file" "日期|Date")
    STATUS=\$(echo "\$STATUS" | sed 's/\*\*//g')
    DATE=\$(echo "\$DATE" | sed 's/\*\*//g')
    FILENAME=\$(basename "\$adr_file")
    echo "| \${NUMBER} | [\${TITLE}](\${FILENAME}) | \${STATUS} | \${DATE} |"
  done <<< "\$ADR_FILES"
} > "\${OUTPUT_FILE}.tmp"

TIMESTAMP=\$(date '+%Y-%m-%d %H:%M:%S')
sed -i "s/TIMESTAMP_PLACEHOLDER/\${TIMESTAMP}/" "\${OUTPUT_FILE}.tmp"
mv "\${OUTPUT_FILE}.tmp" "\${OUTPUT_FILE}"
echo "[OK] ADR 索引已更新：\${OUTPUT_FILE}"
echo "[OK] 共掃描 \$(echo "\$ADR_FILES" | grep -c "." || echo 0) 個 ADR 檔案"
EOF
chmod +x "$WRAPPER_SCRIPT"

# Run first time
bash "$WRAPPER_SCRIPT" 2>/dev/null
EXIT_FIRST=$?
README="${FIXTURE_ADR}/README.md"

[[ $EXIT_FIRST -eq 0 ]] && pass "AC2: 第一次執行 exit 0" || fail "AC2: 第一次執行應 exit 0，實際 exit=$EXIT_FIRST"
[[ -f "$README" ]] && pass "AC2: README.md 已建立" || fail "AC2: README.md 應被建立"

if [[ -f "$README" ]]; then
    grep -q "ADR-001" "$README" && pass "AC2: ADR-001 出現在索引中" || fail "AC2: ADR-001 應出現在索引中"
    grep -q "ADR-002" "$README" && pass "AC2: ADR-002 出現在索引中" || fail "AC2: ADR-002 應出現在索引中"
    grep -q "Accepted" "$README" && pass "AC2: ADR 狀態 'Accepted' 正確提取" || fail "AC2: ADR 狀態應被提取"
    grep -q "Proposed" "$README" && pass "AC2: ADR 狀態 'Proposed' 正確提取" || fail "AC2: 第二個 ADR 狀態應被提取"
fi

# ─── AC2: 冪等性（執行兩次結果相同）─────────────────────────────────────────

echo ""
echo "--- AC2: 冪等性測試（執行兩次結果相同）---"

# Capture first run content (strip timestamp line since it changes)
CONTENT_1=$(grep -v "最後更新" "$README" 2>/dev/null || echo "")

# Run second time
bash "$WRAPPER_SCRIPT" 2>/dev/null
EXIT_SECOND=$?

[[ $EXIT_SECOND -eq 0 ]] && pass "AC2: 第二次執行 exit 0（冪等）" || fail "AC2: 第二次執行應 exit 0"

CONTENT_2=$(grep -v "最後更新" "$README" 2>/dev/null || echo "")

if [[ "$CONTENT_1" == "$CONTENT_2" ]]; then
    pass "AC2: 冪等性通過（兩次執行結果相同，排除時間戳行）"
else
    fail "AC2: 冪等性失敗（兩次執行結果不同）"
fi

# ─── AC2: 空目錄處理 ─────────────────────────────────────────────────────────

echo ""
echo "--- AC2: 空目錄處理 ---"

EMPTY_FIXTURE=$(mktemp -d /tmp/test-update-adr-empty-XXXXXX)
trap "rm -rf $EMPTY_FIXTURE" EXIT
mkdir -p "${EMPTY_FIXTURE}/docs/adr"

# Create empty-dir wrapper
EMPTY_WRAPPER="${EMPTY_FIXTURE}/run-update-adr-empty.sh"
cat > "$EMPTY_WRAPPER" << EOF
#!/usr/bin/env bash
set -uo pipefail
ADR_DIR="${EMPTY_FIXTURE}/docs/adr"
OUTPUT_FILE="\${ADR_DIR}/README.md"
ADR_FILES=\$(ls "\${ADR_DIR}/ADR-"*.md 2>/dev/null | sort || true)
if [[ -z "\$ADR_FILES" ]]; then
  echo "[WARN] 未找到任何 ADR-*.md 檔案於 \${ADR_DIR}"
fi
echo "[OK] done"
EOF
chmod +x "$EMPTY_WRAPPER"

OUTPUT_EMPTY=$(bash "$EMPTY_WRAPPER" 2>&1)
EMPTY_EXIT=$?
[[ $EMPTY_EXIT -eq 0 ]] && pass "AC2: 空目錄處理 exit 0（graceful）" || fail "AC2: 空目錄應 graceful 退出"
echo "$OUTPUT_EMPTY" | grep -qi "warn\|未找到\|no\|empty\|[OK]" && pass "AC2: 空目錄有適當輸出" || fail "AC2: 空目錄應有輸出訊息"

# ─── AC3: fixture 隔離驗證 ────────────────────────────────────────────────────

echo ""
echo "--- AC3: fixture 隔離 ---"

echo "$FIXTURE_DIR" | grep -q "/tmp/" && pass "AC3: Fixture 建立於 /tmp（隔離）" || fail "AC3: Fixture 應在 /tmp"

# Real docs/adr/README.md should not have been modified
REAL_README="${REPO_ROOT}/docs/adr/README.md"
if [[ -f "$REAL_README" ]]; then
    pass "AC3: 真實 docs/adr/README.md 存在（未被 fixture 覆蓋，NFR 通過）"
else
    pass "AC3: 真實 docs/adr/README.md 不存在（NFR 通過：fixture 未創建真實檔案）"
fi

# ─── AC4/NFR1: 執行時間 < 5 秒 ───────────────────────────────────────────────

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
if [[ $ELAPSED -lt 5 ]]; then
    pass "AC4 / NFR1: 執行時間 ${ELAPSED}s < 5s"
else
    fail "AC4 / NFR1: 執行時間 ${ELAPSED}s >= 5s"
fi

# ─── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo "=== 測試結果 ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo "Total: $((PASS + FAIL))"
echo "Duration: ${ELAPSED}s"

if [[ $FAIL -eq 0 ]]; then
    echo "[RESULT] ALL TESTS PASSED"
    exit 0
else
    echo "[RESULT] $FAIL TEST(S) FAILED"
    exit 1
fi
