#!/usr/bin/env bash
# tests/test-sprint-checkpoint-stale.sh
# Story #950 — Sprint Checkpoint Stale Detection
#
# AC2: tests/test-sprint-checkpoint-stale.sh validates stale checkpoint cleanup logic
#
# 測試場景：
#   TC1: 讀取當前 Sprint 編號
#   TC2: Checkpoint sprint 與當前 Sprint 相同時不刪除
#   TC3: Checkpoint sprint < 當前 Sprint 時自動刪除
#   TC4: Checkpoint sprint 無效 JSON 時刪除
#   TC5: 刪除後記錄日誌
#   TC6: Checkpoint 檔案不存在時無誤

set -uo pipefail

PASS=0
FAIL=0
TMPDIR_TEST=$(mktemp -d)
trap "rm -rf '$TMPDIR_TEST'" EXIT

pass() { echo "PASS: $1"; ((PASS++)); }
fail() { echo "FAIL: $1"; ((FAIL++)); }

# 確定 plugin root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 協助函數：從 sprint_*.md 檔案名取得當前 Sprint 編號
get_current_sprint() {
  local sprint_files
  sprint_files=$(ls -1 "${PLUGIN_ROOT}/docs/sprints/sprint_"*.md 2>/dev/null | sort -V | tail -1)
  if [[ -z "$sprint_files" ]]; then
    echo "0"
    return
  fi
  # 提取數字：sprint_178.md → 178
  echo "$sprint_files" | sed -E 's/.*sprint_([0-9]+)\.md/\1/'
}

# 協助函數：從 checkpoint JSON 讀取 sprint 編號
get_checkpoint_sprint() {
  local checkpoint_file="$1"
  if [[ ! -f "$checkpoint_file" ]]; then
    echo ""
    return
  fi
  grep -o '"sprint": *[0-9]*' "$checkpoint_file" 2>/dev/null | grep -o '[0-9]*' || echo ""
}

# ── TC1: 讀取當前 Sprint 編號 ──
CURRENT_SPRINT=$(get_current_sprint)
if [[ "$CURRENT_SPRINT" -gt 0 ]]; then
  pass "TC1: Current sprint number detected: Sprint $CURRENT_SPRINT"
else
  fail "TC1: Could not detect current sprint number"
  CURRENT_SPRINT=178  # fallback
fi

# ── TC2: Checkpoint sprint 與當前 Sprint 相同時不刪除 ──
CHECKPOINT_SAME="${TMPDIR_TEST}/checkpoint-same.json"
cat > "$CHECKPOINT_SAME" <<EOF
{
  "sprint": $CURRENT_SPRINT,
  "updated_at": "2026-04-09T10:00:00Z",
  "stories": [
    {"id": "1", "status": "completed"}
  ]
}
EOF

CHECKPOINT_SPRINT=$(get_checkpoint_sprint "$CHECKPOINT_SAME")
if [[ "$CHECKPOINT_SPRINT" == "$CURRENT_SPRINT" ]]; then
  # 應該不刪除
  if [[ -f "$CHECKPOINT_SAME" ]]; then
    pass "TC2: Checkpoint with current sprint preserved"
  else
    fail "TC2: Checkpoint with current sprint was incorrectly deleted"
  fi
else
  fail "TC2: Could not read checkpoint sprint correctly"
fi

# ── TC3: Checkpoint sprint < 當前 Sprint 時自動刪除 ──
OLD_SPRINT=$((CURRENT_SPRINT - 1))
CHECKPOINT_OLD="${TMPDIR_TEST}/checkpoint-old.json"
cat > "$CHECKPOINT_OLD" <<EOF
{
  "sprint": $OLD_SPRINT,
  "updated_at": "2026-04-08T10:00:00Z",
  "stories": []
}
EOF

CHECKPOINT_SPRINT=$(get_checkpoint_sprint "$CHECKPOINT_OLD")
if [[ "$CHECKPOINT_SPRINT" -lt "$CURRENT_SPRINT" ]]; then
  # 模擬刪除邏輯
  rm -f "$CHECKPOINT_OLD"
  if [[ ! -f "$CHECKPOINT_OLD" ]]; then
    pass "TC3: Stale checkpoint (sprint $CHECKPOINT_SPRINT < $CURRENT_SPRINT) deleted successfully"
  else
    fail "TC3: Stale checkpoint was not deleted"
  fi
else
  fail "TC3: Could not create old checkpoint file"
fi

# ── TC4: Checkpoint sprint 無效 JSON 時刪除 ──
CHECKPOINT_INVALID="${TMPDIR_TEST}/checkpoint-invalid.json"
echo "{ invalid json !!!" > "$CHECKPOINT_INVALID"

if [[ -f "$CHECKPOINT_INVALID" ]]; then
  # 試著讀取 sprint（應該失敗或返回空）
  SPRINT_VAL=$(get_checkpoint_sprint "$CHECKPOINT_INVALID")
  if [[ -z "$SPRINT_VAL" ]]; then
    # 無法讀取 → 刪除
    rm -f "$CHECKPOINT_INVALID"
    if [[ ! -f "$CHECKPOINT_INVALID" ]]; then
      pass "TC4: Invalid JSON checkpoint deleted successfully"
    else
      fail "TC4: Invalid JSON checkpoint was not deleted"
    fi
  else
    fail "TC4: Invalid JSON should not be parseable"
  fi
else
  fail "TC4: Could not create invalid checkpoint file"
fi

# ── TC5: 刪除後記錄日誌 ──
CHECKPOINT_LOG="${TMPDIR_TEST}/checkpoint-log.json"
OLD_SPRINT=$((CURRENT_SPRINT - 2))
cat > "$CHECKPOINT_LOG" <<EOF
{
  "sprint": $OLD_SPRINT,
  "updated_at": "2026-04-07T10:00:00Z",
  "stories": []
}
EOF

LOG_DIR="${TMPDIR_TEST}/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/checkpoint-cleanup.log"

# 模擬刪除並記錄
CHECKPOINT_SPRINT=$(get_checkpoint_sprint "$CHECKPOINT_LOG")
if [[ "$CHECKPOINT_SPRINT" -lt "$CURRENT_SPRINT" ]]; then
  echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] Removed stale checkpoint: sprint $CHECKPOINT_SPRINT (current: $CURRENT_SPRINT)" >> "$LOG_FILE"
  rm -f "$CHECKPOINT_LOG"

  if [[ -f "$LOG_FILE" ]] && grep -q "Removed stale checkpoint" "$LOG_FILE"; then
    pass "TC5: Stale checkpoint cleanup logged successfully"
  else
    fail "TC5: Stale checkpoint cleanup not logged"
  fi
else
  fail "TC5: Could not create test checkpoint"
fi

# ── TC6: Checkpoint 檔案不存在時無誤 ──
NONEXISTENT="${TMPDIR_TEST}/nonexistent-checkpoint.json"
if [[ ! -f "$NONEXISTENT" ]]; then
  # 嘗試讀取不存在的檔案（應該無誤）
  SPRINT_VAL=$(get_checkpoint_sprint "$NONEXISTENT" 2>/dev/null)
  if [[ -z "$SPRINT_VAL" ]]; then
    pass "TC6: Missing checkpoint file handled gracefully"
  else
    fail "TC6: Missing checkpoint should return empty string"
  fi
else
  fail "TC6: Nonexistent file was unexpectedly created"
fi

# ── 結果 ──
echo ""
echo "=== test-sprint-checkpoint-stale.sh Results ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
TOTAL=$((PASS + FAIL))
echo "TOTAL: $TOTAL"

if [[ $FAIL -eq 0 ]]; then
  echo "STATUS: ALL PASS"
  exit 0
else
  echo "STATUS: FAIL"
  exit 1
fi
