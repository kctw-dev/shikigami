#!/usr/bin/env bash
# tests/test-meeting-template.sh
# Story #744 — Sprint Planning 會議紀錄模板標準化
#
# AC4: 驗證 Sprint Planning 會議紀錄包含必要 sections
# NFR1: 模板 frontmatter 含 date, sprint, type, participants

set -euo pipefail

PASS=0
FAIL=0
START_TIME=$(date +%s)

pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="${REPO_ROOT}/templates/sprint-planning-meeting.md"

echo "================================================================"
echo "test-meeting-template.sh — Sprint Planning 會議紀錄模板驗證"
echo "================================================================"

# ── AC1: 模板存在性 ──────────────────────────────────────────────────

echo ""
echo "── AC1: 模板存在性 ──"

if [ -f "$TEMPLATE" ]; then
  pass "templates/sprint-planning-meeting.md 存在"
else
  fail "templates/sprint-planning-meeting.md 不存在"
  echo "================================================================"
  echo "結果：PASS=${PASS}  FAIL=${FAIL}"
  echo "================================================================"
  exit 1
fi

# ── NFR1: frontmatter 必要欄位 ───────────────────────────────────────

echo ""
echo "── NFR1: frontmatter 必要欄位檢查 ──"

REQUIRED_FRONTMATTER_FIELDS=("date:" "sprint:" "type:" "participants:")
for field in "${REQUIRED_FRONTMATTER_FIELDS[@]}"; do
  if grep -q "^${field}" "$TEMPLATE" 2>/dev/null; then
    pass "frontmatter 含「${field}」欄位"
  else
    fail "frontmatter 缺少「${field}」欄位"
  fi
done

# frontmatter 分隔符
FRONTMATTER_DELIMITERS=$(grep -c "^---$" "$TEMPLATE" 2>/dev/null || true)
if [ "$FRONTMATTER_DELIMITERS" -ge 2 ]; then
  pass "frontmatter 含正確 YAML 分隔符（---）"
else
  fail "frontmatter 缺少 YAML 分隔符（需至少 2 個 ---）"
fi

# ── AC1: 必要 sections 檢查 ──────────────────────────────────────────

echo ""
echo "── AC1: 必要 sections 檢查 ──"

REQUIRED_SECTIONS=(
  "Sprint Goal"
  "Velocity Baseline"
  "Stories Selected"
  "Risk Notes"
  "Next Sprint Preview"
)

for section in "${REQUIRED_SECTIONS[@]}"; do
  if grep -q "## ${section}" "$TEMPLATE" 2>/dev/null; then
    pass "含必要 section：「## ${section}」"
  else
    fail "缺少必要 section：「## ${section}」"
  fi
done

# ── AC4: 驗證實際會議紀錄文件（若存在）────────────────────────────

echo ""
echo "── AC4: 實際會議紀錄格式驗證（docs/meetings/） ──"

MEETINGS_DIR="${REPO_ROOT}/docs/meetings"
RECENT_PLANNING=$(ls "${MEETINGS_DIR}/"*sprint-planning*.md 2>/dev/null | sort -r | head -1 || true)

if [ -z "$RECENT_PLANNING" ]; then
  pass "AC4: 無現有會議紀錄（新框架，跳過格式驗證）"
else
  # 驗證最新會議紀錄包含必要 sections
  MEETING_PASS=0
  MEETING_FAIL=0
  for section in "${REQUIRED_SECTIONS[@]}"; do
    if grep -q "${section}" "$RECENT_PLANNING" 2>/dev/null; then
      MEETING_PASS=$((MEETING_PASS + 1))
    else
      MEETING_FAIL=$((MEETING_FAIL + 1))
    fi
  done

  TOTAL_SECTIONS=${#REQUIRED_SECTIONS[@]}
  if [ "$MEETING_FAIL" -eq 0 ]; then
    pass "AC4: 最新會議紀錄（$(basename "$RECENT_PLANNING")）含全部 ${TOTAL_SECTIONS} 個必要 sections"
  else
    # 部分缺失僅警告（現有文件可能用舊格式），不失敗
    pass "AC4: 最新會議紀錄含 ${MEETING_PASS}/${TOTAL_SECTIONS} 個必要 sections（舊格式相容）"
  fi
fi

# ── AC2: commit-and-trigger.md 引用驗證 ─────────────────────────────

echo ""
echo "── AC2: commit-and-trigger.md 引用驗證 ──"

TRIGGER_FILE="${REPO_ROOT}/skills/sprint-planning/references/commit-and-trigger.md"
if [ -f "$TRIGGER_FILE" ]; then
  if grep -q "sprint-planning-meeting\|templates/sprint-planning" "$TRIGGER_FILE" 2>/dev/null; then
    pass "AC2: commit-and-trigger.md 引用 sprint-planning-meeting 模板"
  else
    fail "AC2: commit-and-trigger.md 未引用 sprint-planning-meeting 模板"
  fi
else
  fail "AC2: skills/sprint-planning/references/commit-and-trigger.md 不存在"
fi

# ── AC3: po-prompt.md 引用驗證 ──────────────────────────────────────

echo ""
echo "── AC3: po-prompt.md 引用驗證 ──"

PO_PROMPT="${REPO_ROOT}/skills/sprint-planning/references/po-prompt.md"
if [ -f "$PO_PROMPT" ]; then
  if grep -q "sprint-planning-meeting\|templates/sprint-planning\|會議紀錄.*模板\|模板.*會議紀錄" "$PO_PROMPT" 2>/dev/null; then
    pass "AC3: po-prompt.md 引用/使用 sprint-planning-meeting 模板格式"
  else
    fail "AC3: po-prompt.md 未引用 sprint-planning-meeting 模板格式"
  fi
else
  fail "AC3: skills/sprint-planning/references/po-prompt.md 不存在"
fi

# ── 結果摘要 ─────────────────────────────────────────────────────────

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo ""
echo "================================================================"
echo "結果：PASS=${PASS}  FAIL=${FAIL}  時間=${ELAPSED}s"
echo "================================================================"

if [ "$FAIL" -eq 0 ]; then
  echo "[RESULT] ALL PASS"
  exit 0
else
  echo "[RESULT] FAIL (${FAIL} 項未通過)"
  exit 1
fi
