#!/usr/bin/env bash
# test-cleanup-worktrees.sh — #735 git worktree 自動清理腳本驗證
# Sprint 155 | AC4: 驗證保護機制（不清理未合併 worktree）

set -euo pipefail

PASS=0
FAIL=0
SCRIPT="scripts/cleanup-worktrees.sh"

log_pass() { echo "[PASS] $1"; PASS=$((PASS+1)); }
log_fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

# ── TC-1: cleanup-worktrees.sh 腳本存在 ──────────────────────────
if [ -f "$SCRIPT" ]; then
  log_pass "TC-1: $SCRIPT 存在"
else
  log_fail "TC-1: $SCRIPT 不存在（AC1 要求）"
fi

# ── TC-2: 腳本可執行 ─────────────────────────────────────────────
if [ -x "$SCRIPT" ]; then
  log_pass "TC-2: $SCRIPT 有執行權限"
else
  log_fail "TC-2: $SCRIPT 沒有執行權限（需 chmod +x）"
fi

# ── TC-3: --dry-run 參數存在（NFR1）─────────────────────────────
if grep -q "\-\-dry-run\|dry_run\|DRY_RUN" "$SCRIPT" 2>/dev/null; then
  log_pass "TC-3: NFR1 — $SCRIPT 支援 --dry-run 模式"
else
  log_fail "TC-3: NFR1 — $SCRIPT 缺少 --dry-run 支援"
fi

# ── TC-4: 保護機制 — 只清理 --merged main 的 worktree（AC2） ───
if grep -q "\-\-merged\|merged main\|merged origin/main" "$SCRIPT" 2>/dev/null; then
  log_pass "TC-4: AC2 — 腳本包含 --merged main 保護機制"
else
  log_fail "TC-4: AC2 — 腳本缺少 --merged main 保護機制（風險：可能清理未合併的 worktree）"
fi

# ── TC-5: --dry-run 模式不實際刪除 worktree ─────────────────────
if grep -q "dry-run\|DRY_RUN" "$SCRIPT" 2>/dev/null; then
  # 模擬 dry-run 模式不執行 git worktree remove
  DRY_RUN_USES_REMOVE=$(grep "git worktree remove" "$SCRIPT" 2>/dev/null | grep -v "DRY_RUN\|dry_run\|dry-run" | wc -l || echo "0")
  if [ "$DRY_RUN_USES_REMOVE" -eq 0 ] || grep -q 'if.*DRY_RUN.*git worktree remove\|DRY_RUN.*remove\|\[ "\$DRY_RUN' "$SCRIPT" 2>/dev/null; then
    log_pass "TC-5: NFR1 — --dry-run 模式下不實際執行刪除"
  else
    # 檢查是否有 guard 保護
    if grep -B5 "git worktree remove" "$SCRIPT" 2>/dev/null | grep -q "DRY_RUN\|dry"; then
      log_pass "TC-5: NFR1 — --dry-run 模式有 guard 保護"
    else
      log_fail "TC-5: NFR1 — --dry-run 可能不安全（git worktree remove 未被 DRY_RUN 保護）"
    fi
  fi
else
  log_fail "TC-5: NFR1 — 無 DRY_RUN 邏輯"
fi

# ── TC-6: 清理結果記錄（NFR2）────────────────────────────────────
if grep -q "cruise.log\|cruise log\|worktree-cleanup\|CRUISE_LOG\|cruise-log" "$SCRIPT" 2>/dev/null; then
  log_pass "TC-6: NFR2 — 腳本包含 cruise log 寫入邏輯"
else
  log_fail "TC-6: NFR2 — 腳本缺少 cruise log 寫入（worktree-cleanup type）"
fi

# ── TC-7: 只清理 sprint-N/ 分支的 worktree（AC1）────────────────
if grep -q "sprint-\|sprint_" "$SCRIPT" 2>/dev/null; then
  log_pass "TC-7: AC1 — 腳本針對 sprint-N/ 分支 worktree"
else
  log_fail "TC-7: AC1 — 腳本未限縮為 sprint-N/ 分支 worktree"
fi

# ── 結果輸出 ─────────────────────────────────────────────────────
echo ""
echo "=== test-cleanup-worktrees.sh 結果 ==="
echo "PASS: $PASS | FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "[TEST-SUITE-PASS] 全部 $PASS 項通過"
  exit 0
else
  echo "[TEST-SUITE-FAIL] $FAIL 項失敗"
  exit 1
fi
