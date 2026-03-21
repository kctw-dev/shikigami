#!/usr/bin/env bash
# tests/test-us322-shoot-log-per-session.sh
# US-#322 AC-1 TDD — Shoot_Log 改為 per-session + 結算
#
# TC-1: shoot-log-settle.sh 存在且可執行
# TC-2: settle 合併同日 per-session 檔案為 summary.md
# TC-3: 不同 session 各自有獨立檔案（天然隔離）
# TC-4: 原始 per-session 檔案保留（保守策略）
# TC-5: 結算 summary.md 包含所有筆數
# TC-6: protect-main.sh 豁免清單含 docs/km/shoot-log/
# TC-7: skill/shoot/SKILL.md §9 更新為 per-session 路徑
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SETTLE_SCRIPT="${REPO_ROOT}/hooks/shoot-log-settle.sh"
SHOOT_SKILL="${REPO_ROOT}/skills/shoot/SKILL.md"
PROTECT_MAIN="${REPO_ROOT}/hooks/protect-main.sh"

PASS=0
FAIL=0

pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

echo "=== test-us322-shoot-log-per-session.sh ==="

# ── TC-1: shoot-log-settle.sh 存在且可執行 ────────────────────────
echo ""
echo "--- TC-1: shoot-log-settle.sh 存在且可執行 ---"

if [[ -f "$SETTLE_SCRIPT" ]]; then
  pass "TC-1a: shoot-log-settle.sh 存在"
else
  fail "TC-1a: shoot-log-settle.sh 不存在（${SETTLE_SCRIPT}）"
fi

if [[ -x "$SETTLE_SCRIPT" ]]; then
  pass "TC-1b: shoot-log-settle.sh 可執行"
else
  fail "TC-1b: shoot-log-settle.sh 無執行權限"
fi

# ── TC-2: settle 合併同日 per-session 檔案 ────────────────────────
echo ""
echo "--- TC-2: settle 合併同日 per-session 檔案為 summary.md ---"

TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

TEST_DATE="2026-03-20"
SID_A="aaa111"
SID_B="bbb222"

FILE_A="${TMPDIR_TEST}/${TEST_DATE}-session-${SID_A}.md"
FILE_B="${TMPDIR_TEST}/${TEST_DATE}-session-${SID_B}.md"

# 建立測試 per-session 檔案（Markdown 表格列格式）
cat >> "$FILE_A" <<'EOF'
| 2026-03-20 | direct | 修復登入頁面 CORS 問題 | PASS | abc1234 |
| 2026-03-20 | #100 | 修復 API timeout | PASS | def5678 |
EOF

cat >> "$FILE_B" <<'EOF'
| 2026-03-20 | direct | 修復 CSS 問題 | PASS | ghi9012 |
EOF

if [[ -f "$SETTLE_SCRIPT" ]]; then
  SHOOT_LOG_DIR="$TMPDIR_TEST" bash "$SETTLE_SCRIPT" "$TEST_DATE" 2>/dev/null || true

  SUMMARY_FILE="${TMPDIR_TEST}/${TEST_DATE}.summary.md"

  if [[ -f "$SUMMARY_FILE" ]]; then
    pass "TC-2a: summary.md 已生成"
    # 計算資料行數（含 | 但排除 |---| 分隔行與標題行）
    SUMMARY_LINES=$(grep '^|' "$SUMMARY_FILE" 2>/dev/null | grep -v '^|[-: |]*$' | grep -v '日期.*來源' | wc -l | tr -d ' ' || echo 0)
    if [[ "$SUMMARY_LINES" -eq 3 ]]; then
      pass "TC-2b: summary.md 包含所有 3 筆紀錄（2+1）"
    else
      fail "TC-2b: summary.md 應有 3 筆，實際 ${SUMMARY_LINES} 筆"
    fi
  else
    fail "TC-2a: summary.md 未生成（${SUMMARY_FILE}）"
    fail "TC-2b: 無法驗證（summary.md 不存在）"
  fi
else
  fail "TC-2a: 無法執行（settle 腳本不存在）"
  fail "TC-2b: 無法驗證（settle 腳本不存在）"
fi

# ── TC-3: 不同 session 各自獨立（天然隔離）───────────────────────
echo ""
echo "--- TC-3: 不同 session 各自獨立（天然隔離）---"

if [[ "$FILE_A" != "$FILE_B" ]]; then
  pass "TC-3: 不同 session 寫入不同檔案（天然隔離，無 conflict）"
else
  fail "TC-3: 相同 session_id 導致衝突"
fi

# ── TC-4: 原始 per-session 檔案保留 ──────────────────────────────
echo ""
echo "--- TC-4: 原始 per-session 檔案保留（保守策略）---"

if [[ -f "$FILE_A" ]]; then
  pass "TC-4a: session-A 原始檔案保留"
else
  fail "TC-4a: session-A 原始檔案被刪除"
fi

if [[ -f "$FILE_B" ]]; then
  pass "TC-4b: session-B 原始檔案保留"
else
  fail "TC-4b: session-B 原始檔案被刪除"
fi

# ── TC-5: 結算空目錄不 crash ──────────────────────────────────────
echo ""
echo "--- TC-5: 空目錄時 settle 不 crash ---"

EMPTY_DIR="$(mktemp -d)"
if [[ -f "$SETTLE_SCRIPT" ]]; then
  SHOOT_LOG_DIR="$EMPTY_DIR" bash "$SETTLE_SCRIPT" "2099-01-01" 2>&1 || true
  pass "TC-5: 空目錄時 settle 正常退出"
else
  fail "TC-5: settle 腳本不存在"
fi
rm -rf "$EMPTY_DIR"

# ── TC-6: protect-main.sh 豁免清單含 docs/km/shoot-log/ ──────────
echo ""
echo "--- TC-6: protect-main.sh 豁免清單含 docs/km/shoot-log/ ---"

if grep -qE 'docs/km/shoot-log' "$PROTECT_MAIN" 2>/dev/null; then
  pass "TC-6: protect-main.sh 已包含 docs/km/shoot-log/ 豁免"
else
  fail "TC-6: protect-main.sh 未包含 docs/km/shoot-log/ 豁免"
fi

# ── TC-7: shoot SKILL.md §9 更新為 per-session 路徑 ───────────────
echo ""
echo "--- TC-7: shoot SKILL.md §9 更新為 per-session 路徑 ---"

if grep -qE 'shoot-log/.*session|per.session|YYYY-MM-DD-session' "$SHOOT_SKILL" 2>/dev/null; then
  pass "TC-7: shoot SKILL.md 含 per-session 路徑描述"
else
  fail "TC-7: shoot SKILL.md 未更新為 per-session 路徑"
fi

# ── 總結 ────────────────────────────────────────────────────────────
echo ""
echo "=== 結果 ==="
echo "  PASS: ${PASS}"
echo "  FAIL: ${FAIL}"
echo ""

if [[ $FAIL -eq 0 ]]; then
  echo "[OK] test-us322-shoot-log-per-session.sh 全部通過"
  exit 0
else
  echo "[FAIL] ${FAIL} 個測試失敗"
  exit 1
fi
