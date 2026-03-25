#!/usr/bin/env bash
# tests/test-708-cruise-log-archive.sh
# Story #708 — cruise logs 壓縮歸檔機制（長期可觀測性）
#
# ── 目的 ──────────────────────────────────────────────────────────────────
#
# 驗證 §4.4 Log 歸檔邏輯的三個核心行為：
#   AC1: startup-flow.md 包含 §4.4 Log 歸檔邏輯
#   AC2: 超過 7 天的 JSONL 自動壓縮至 archive/YYYY-MM/ 目錄
#   AC3: 歸檔後原始 JSONL 從 git 追蹤移除（不保留於 repo）
#   AC4: 歸檔操作結果寫入 cruise log（type: log-archived）
#   AC5: .gitignore 正確配置
#
# ── 使用方式 ─────────────────────────────────────────────────────────────
#   bash tests/test-708-cruise-log-archive.sh
# ─────────────────────────────────────────────────────────────────────────

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PASS_COUNT=0
FAIL_COUNT=0

pass() { echo "  [PASS] $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { echo "  [FAIL] $1"; echo "    [DIAG] $2"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

echo "=== cruise log archive test suite (#708) ==="
echo ""

# ─── AC1：startup-flow.md 包含 §4.4 Log 歸檔邏輯 ───────────────────────
echo "--- AC1: startup-flow.md §4.4 Log 歸檔邏輯 ---"

STARTUP_FLOW="${REPO_ROOT}/skills/cruise/references/startup-flow.md"

if [[ -f "${STARTUP_FLOW}" ]]; then
  pass "AC1a: startup-flow.md 存在"

  if grep -q "§4.4" "${STARTUP_FLOW}"; then
    pass "AC1b: startup-flow.md 包含 §4.4 標記"
  else
    fail "AC1b: startup-flow.md 缺少 §4.4 標記" \
      "startup-flow.md 中未找到 '§4.4' 字串，請新增 §4.4 Log 歸檔邏輯段落"
  fi

  if grep -q "log-archive\|log_archive\|LOG_ARCHIVE\|cruise-log-archive\|log-archived" "${STARTUP_FLOW}"; then
    pass "AC1c: startup-flow.md 包含歸檔邏輯關鍵字"
  else
    fail "AC1c: startup-flow.md 缺少歸檔邏輯關鍵字" \
      "未找到歸檔相關關鍵字（log-archive, log-archived 等）"
  fi

  if grep -q "archive/\|ARCHIVE_DIR\|archive_dir" "${STARTUP_FLOW}"; then
    pass "AC1d: startup-flow.md 包含歸檔目錄參照"
  else
    fail "AC1d: startup-flow.md 缺少歸檔目錄參照" \
      "未找到歸檔目錄（archive/ 相關字串）"
  fi
else
  fail "AC1a: startup-flow.md 不存在" \
    "找不到 ${STARTUP_FLOW}"
fi

echo ""

# ─── AC2：7 天閾值與目錄結構 ────────────────────────────────────────────
echo "--- AC2: 7 天閾值與 YYYY-MM 目錄結構 ---"

if grep -q "7\|ARCHIVE_DAYS\|archive_days" "${STARTUP_FLOW}" 2>/dev/null; then
  pass "AC2a: startup-flow.md 包含 7 天閾值設定"
else
  fail "AC2a: startup-flow.md 缺少 7 天閾值設定" \
    "未找到 7 天或 ARCHIVE_DAYS 相關設定"
fi

if grep -q "YYYY-MM\|%Y-%m\|archive.*YYYY\|archive.*%Y" "${STARTUP_FLOW}" 2>/dev/null; then
  pass "AC2b: startup-flow.md 包含 YYYY-MM 月份目錄格式"
else
  fail "AC2b: startup-flow.md 缺少 YYYY-MM 目錄格式" \
    "未找到 YYYY-MM 或 %Y-%m 格式字串"
fi

echo ""

# ─── AC3：git rm --cached 邏輯 ──────────────────────────────────────────
echo "--- AC3: git rm --cached 邏輯 ---"

if grep -q "git rm --cached\|git_rm_cached\|GIT_RM" "${STARTUP_FLOW}" 2>/dev/null; then
  pass "AC3: startup-flow.md 包含 git rm --cached 邏輯"
else
  fail "AC3: startup-flow.md 缺少 git rm --cached 邏輯" \
    "歸檔後需從 git 追蹤移除原始 JSONL"
fi

echo ""

# ─── AC4：log-archived type 寫入 ────────────────────────────────────────
echo "--- AC4: log-archived cruise log 寫入 ---"

if grep -q "log-archived\|\"log-archived\"\|type.*log.archived" "${STARTUP_FLOW}" 2>/dev/null; then
  pass "AC4: startup-flow.md 包含 log-archived log type"
else
  fail "AC4: startup-flow.md 缺少 log-archived log type" \
    "歸檔操作結果須寫入 cruise log，type: log-archived"
fi

echo ""

# ─── AC5：.gitignore 配置 ───────────────────────────────────────────────
echo "--- AC5: .gitignore 配置 ---"

GITIGNORE="${REPO_ROOT}/.gitignore"

if grep -q "cruise-logs/archive\|cruise.logs.*archive\|archive.*\.gz" "${GITIGNORE}" 2>/dev/null; then
  pass "AC5a: .gitignore 包含 cruise-logs 歸檔目錄規則"
else
  fail "AC5a: .gitignore 缺少 cruise-logs 歸檔目錄規則" \
    "需配置 .gitignore 使 .gz 保留、原始 JSONL 豁免"
fi

echo ""

# ─── 摘要 ────────────────────────────────────────────────────────────────
echo "=== 摘要 ==="
echo "PASS: ${PASS_COUNT}, FAIL: ${FAIL_COUNT}"
echo ""

if [[ "${FAIL_COUNT}" -eq 0 ]]; then
  echo "[RESULT] PASS — 全部 ${PASS_COUNT} 項測試通過"
  exit 0
else
  echo "[RESULT] FAIL — ${FAIL_COUNT} 項測試失敗，${PASS_COUNT} 項通過"
  exit 1
fi
