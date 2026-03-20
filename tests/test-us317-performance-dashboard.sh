#!/usr/bin/env bash
# tests/test-us317-performance-dashboard.sh
# US-#317 Phase 4 — TDD 測試套件：績效儀表板 Skill
# AC1：/performance-dashboard Skill 可叫用，輸出 Markdown 報表
# AC2：報表含出勤角色列表 + 各角色時數
# AC3：報表含當日會議次數 + 會議連結
# AC4：報表含當日探索次數 + top-5 URL/查詢
# AC5：支援日期參數（預設今日，可指定 YYYY-MM-DD）
# AC6：daily-summary 不存在時輸出提示（不自動結算）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SKILL_FILE="${PLUGIN_ROOT}/skills/performance-dashboard/SKILL.md"

PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

# ── TC-01：SKILL.md 存在 ────────────────────────────────────────────────────
if [[ -f "$SKILL_FILE" ]]; then
  pass "TC-01：skills/performance-dashboard/SKILL.md 存在"
else
  fail "TC-01：skills/performance-dashboard/SKILL.md 存在"
fi

# ── TC-02：frontmatter name 欄位正確 ──────────────────────────────────────
if grep -q 'name: performance-dashboard' "$SKILL_FILE" 2>/dev/null; then
  pass "TC-02：frontmatter name=performance-dashboard"
else
  fail "TC-02：frontmatter name=performance-dashboard"
fi

# ── TC-03：requiredTools 包含 Read ────────────────────────────────────────
if grep -q 'Read' "$SKILL_FILE" 2>/dev/null; then
  pass "TC-03：requiredTools 包含 Read"
else
  fail "TC-03：requiredTools 包含 Read"
fi

# ── TC-04：requiredTools 包含 Glob ────────────────────────────────────────
if grep -q 'Glob' "$SKILL_FILE" 2>/dev/null; then
  pass "TC-04：requiredTools 包含 Glob"
else
  fail "TC-04：requiredTools 包含 Glob"
fi

# ── TC-05：requiredTools 包含 Bash ────────────────────────────────────────
if grep -q 'Bash' "$SKILL_FILE" 2>/dev/null; then
  pass "TC-05：requiredTools 包含 Bash"
else
  fail "TC-05：requiredTools 包含 Bash"
fi

# ── TC-06：AC2 — 報表含出勤摘要區段 ──────────────────────────────────────
if grep -q '出勤摘要' "$SKILL_FILE" 2>/dev/null; then
  pass "TC-06：SKILL.md 包含「出勤摘要」區段關鍵字"
else
  fail "TC-06：SKILL.md 包含「出勤摘要」區段關鍵字"
fi

# ── TC-07：AC2 — 參照 docs/attendance/ 路徑 ──────────────────────────────
if grep -q 'docs/attendance' "$SKILL_FILE" 2>/dev/null; then
  pass "TC-07：SKILL.md 參照 docs/attendance 路徑"
else
  fail "TC-07：SKILL.md 參照 docs/attendance 路徑"
fi

# ── TC-08：AC2 — 提及 summary.jsonl 格式 ─────────────────────────────────
if grep -q 'summary.jsonl' "$SKILL_FILE" 2>/dev/null; then
  pass "TC-08：SKILL.md 提及 summary.jsonl 格式"
else
  fail "TC-08：SKILL.md 提及 summary.jsonl 格式"
fi

# ── TC-09：AC3 — 報表含會議紀錄摘要區段 ─────────────────────────────────
if grep -q '會議紀錄摘要' "$SKILL_FILE" 2>/dev/null; then
  pass "TC-09：SKILL.md 包含「會議紀錄摘要」區段關鍵字"
else
  fail "TC-09：SKILL.md 包含「會議紀錄摘要」區段關鍵字"
fi

# ── TC-10：AC3 — 參照 docs/meetings/ 路徑 ────────────────────────────────
if grep -q 'docs/meetings' "$SKILL_FILE" 2>/dev/null; then
  pass "TC-10：SKILL.md 參照 docs/meetings 路徑"
else
  fail "TC-10：SKILL.md 參照 docs/meetings 路徑"
fi

# ── TC-11：AC4 — 報表含探索紀錄摘要區段 ─────────────────────────────────
if grep -q '探索紀錄摘要' "$SKILL_FILE" 2>/dev/null; then
  pass "TC-11：SKILL.md 包含「探索紀錄摘要」區段關鍵字"
else
  fail "TC-11：SKILL.md 包含「探索紀錄摘要」區段關鍵字"
fi

# ── TC-12：AC4 — 參照 docs/exploration/ 路徑 ─────────────────────────────
if grep -q 'docs/exploration' "$SKILL_FILE" 2>/dev/null; then
  pass "TC-12：SKILL.md 參照 docs/exploration 路徑"
else
  fail "TC-12：SKILL.md 參照 docs/exploration 路徑"
fi

# ── TC-13：AC4 — 提及 top-5 ──────────────────────────────────────────────
if grep -q 'top-5\|top 5\|Top 5\|Top-5' "$SKILL_FILE" 2>/dev/null; then
  pass "TC-13：SKILL.md 提及 top-5 URL/查詢"
else
  fail "TC-13：SKILL.md 提及 top-5 URL/查詢"
fi

# ── TC-14：AC5 — 支援日期參數（YYYY-MM-DD） ──────────────────────────────
if grep -q 'YYYY-MM-DD' "$SKILL_FILE" 2>/dev/null; then
  pass "TC-14：SKILL.md 說明 YYYY-MM-DD 日期參數"
else
  fail "TC-14：SKILL.md 說明 YYYY-MM-DD 日期參數"
fi

# ── TC-15：AC5 — 使用 date 指令取得今日 ──────────────────────────────────
if grep -q '`date`\|date 指令\|date command' "$SKILL_FILE" 2>/dev/null; then
  pass "TC-15：SKILL.md 說明使用 date 指令取得今日日期"
else
  fail "TC-15：SKILL.md 說明使用 date 指令取得今日日期"
fi

# ── TC-16：AC6 — 不存在時顯示提示（不自動結算） ──────────────────────────
if grep -q '尚未結算\|不存在\|not found' "$SKILL_FILE" 2>/dev/null; then
  pass "TC-16：SKILL.md 包含 summary 不存在時的提示文字"
else
  fail "TC-16：SKILL.md 包含 summary 不存在時的提示文字"
fi

# ── TC-17：AC6 — 提示使用 attendance-settle.sh ────────────────────────────
if grep -q 'attendance-settle' "$SKILL_FILE" 2>/dev/null; then
  pass "TC-17：SKILL.md 提示執行 attendance-settle.sh"
else
  fail "TC-17：SKILL.md 提示執行 attendance-settle.sh"
fi

# ── TC-18：AC6 — 提示使用 exploration-settle.sh ──────────────────────────
if grep -q 'exploration-settle' "$SKILL_FILE" 2>/dev/null; then
  pass "TC-18：SKILL.md 提示執行 exploration-settle.sh"
else
  fail "TC-18：SKILL.md 提示執行 exploration-settle.sh"
fi

# ── TC-19：報表標題格式含日期 ────────────────────────────────────────────
if grep -q '績效儀表板' "$SKILL_FILE" 2>/dev/null; then
  pass "TC-19：SKILL.md 包含「績效儀表板」標題關鍵字"
else
  fail "TC-19：SKILL.md 包含「績效儀表板」標題關鍵字"
fi

# ── TC-20：彙總區段存在 ───────────────────────────────────────────────────
if grep -q '彙總' "$SKILL_FILE" 2>/dev/null; then
  pass "TC-20：SKILL.md 包含「彙總」區段"
else
  fail "TC-20：SKILL.md 包含「彙總」區段"
fi

echo ""
echo "結果：PASS=${PASS}  FAIL=${FAIL}"
if [[ "$FAIL" -eq 0 ]]; then
  echo "ALL PASS"
  exit 0
else
  exit 1
fi
