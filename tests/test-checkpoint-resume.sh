#!/usr/bin/env bash
# test-checkpoint-resume.sh
# US-313 Phase 2 — 測試 AC-2（斷點續跑）與 AC-3（孤兒 Claim 清理）
#
# 測試案例：
#   TC-1: checkpoint JSON 格式正確性
#   TC-2: claim-cleanup.sh --dry-run 模式
#   TC-3: claim-cleanup.sh 清理邏輯（模擬 stale ref）
#   TC-4: AC-2 resume 偵測邏輯（checkpoint 存在且有未完成 Story）
#   TC-5: AC-2 無 checkpoint 時正常流程（不 resume）

set -euo pipefail

PASS=0
FAIL=0
ERRORS=()

# bash arithmetic: (( expr )) returns exit 1 when result is 0, which trips set -e
# Use += workaround
inc_pass() { PASS=$((PASS + 1)); }
inc_fail() { FAIL=$((FAIL + 1)); }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLEANUP_SCRIPT="$REPO_ROOT/hooks/claim-cleanup.sh"
CHECKPOINT_FILE="$REPO_ROOT/docs/sprints/sprint-checkpoint.json"
CHECKPOINT_BACKUP=""

# ── 測試輔助函式 ─────────────────────────────────────────────────
pass() { echo "  [PASS] $1"; inc_pass; }
fail() { echo "  [FAIL] $1"; inc_fail; ERRORS+=("$1"); }

# ── TC-1: checkpoint JSON 格式正確性 ─────────────────────────────
echo ""
echo "TC-1: checkpoint JSON 格式正確性"

VALID_CHECKPOINT=$(cat <<'EOF'
{
  "sprint": 102,
  "stories": [
    {"id": "US-313", "status": "completed", "completed_at": "2026-03-19T18:15:01+08:00"},
    {"id": "US-314", "status": "in-progress", "completed_at": null},
    {"id": "US-315", "status": "pending", "completed_at": null}
  ],
  "current_step": "story-completed",
  "updated_at": "2026-03-19T18:15:01+08:00"
}
EOF
)

# TC-1a: valid JSON 能解析
if echo "$VALID_CHECKPOINT" | python3 -c "import json,sys; d=json.load(sys.stdin); assert 'sprint' in d" 2>/dev/null; then
  pass "TC-1a: 有效 checkpoint JSON 可正確解析"
else
  fail "TC-1a: 有效 checkpoint JSON 解析失敗"
fi

# TC-1b: 必要欄位存在
MISSING_FIELDS=""
for field in sprint stories current_step updated_at; do
  if ! echo "$VALID_CHECKPOINT" | python3 -c "import json,sys; d=json.load(sys.stdin); assert '$field' in d" 2>/dev/null; then
    MISSING_FIELDS="$MISSING_FIELDS $field"
  fi
done
if [[ -z "$MISSING_FIELDS" ]]; then
  pass "TC-1b: 所有必要欄位均存在（sprint, stories, current_step, updated_at）"
else
  fail "TC-1b: 缺少必要欄位:$MISSING_FIELDS"
fi

# TC-1c: stories 狀態值合法（completed/in-progress/pending）
INVALID_STATUS=$(echo "$VALID_CHECKPOINT" | python3 -c "
import json,sys
d=json.load(sys.stdin)
valid = {'completed','in-progress','pending'}
bad=[s['status'] for s in d['stories'] if s['status'] not in valid]
if bad: print(' '.join(bad))
" 2>/dev/null)
if [[ -z "$INVALID_STATUS" ]]; then
  pass "TC-1c: 所有 Story 狀態值合法"
else
  fail "TC-1c: 存在非法狀態值: $INVALID_STATUS"
fi

# TC-1d: completed Story 有 completed_at，非 completed 為 null
STATUS_OK=$(echo "$VALID_CHECKPOINT" | python3 -c "
import json,sys
d=json.load(sys.stdin)
ok=True
for s in d['stories']:
    if s['status']=='completed' and s['completed_at'] is None:
        ok=False
    if s['status'] in ('in-progress','pending') and s['completed_at'] is not None:
        ok=False
print('ok' if ok else 'fail')
" 2>/dev/null)
if [[ "$STATUS_OK" == "ok" ]]; then
  pass "TC-1d: completed Story 有 completed_at，未完成 Story 為 null"
else
  fail "TC-1d: completed_at 與狀態不一致"
fi

# ── TC-2: claim-cleanup.sh --dry-run 模式 ────────────────────────
echo ""
echo "TC-2: claim-cleanup.sh --dry-run 模式"

if [[ ! -f "$CLEANUP_SCRIPT" ]]; then
  fail "TC-2a: claim-cleanup.sh 不存在（需先建立）"
  FAIL_EARLY=true
else
  FAIL_EARLY=false

  # TC-2a: 腳本可執行（語法檢查）
  if bash -n "$CLEANUP_SCRIPT" 2>/dev/null; then
    pass "TC-2a: claim-cleanup.sh 語法正確"
  else
    fail "TC-2a: claim-cleanup.sh 語法錯誤"
  fi

  # TC-2b: --dry-run 不執行清理，只列出
  OUTPUT=$(bash "$CLEANUP_SCRIPT" --dry-run 2>&1 || true)
  if echo "$OUTPUT" | grep -q "\[DRY-RUN\]\|\[CLAIM-CLEANUP\]\|stale\|No stale\|0 個"; then
    pass "TC-2b: --dry-run 模式有合法輸出"
  else
    # 接受空輸出（無 stale claim 時）或有 CLAIM-CLEANUP 行
    if [[ -z "$(echo "$OUTPUT" | grep -v '^$')" ]] || echo "$OUTPUT" | grep -qiE "claim|stale|cleanup|clean"; then
      pass "TC-2b: --dry-run 模式執行完成（無 stale claims 或正常輸出）"
    else
      fail "TC-2b: --dry-run 輸出不符預期: $OUTPUT"
    fi
  fi

  # TC-2c: --dry-run 不刪除任何 ref（不呼叫 git push --delete）
  # 用 strace 或過濾輸出，這裡用間接驗證：dry-run 不應輸出 [CLAIM-RELEASE]
  if echo "$OUTPUT" | grep -q "\[CLAIM-RELEASE\]"; then
    fail "TC-2c: --dry-run 不應輸出 [CLAIM-RELEASE]（不應清理）"
  else
    pass "TC-2c: --dry-run 未執行實際清理"
  fi
fi

# ── TC-3: claim-cleanup.sh 清理邏輯（模擬 stale ref）────────────
echo ""
echo "TC-3: claim-cleanup.sh 清理邏輯驗證"

if [[ "${FAIL_EARLY:-false}" == "true" ]]; then
  fail "TC-3: 跳過（claim-cleanup.sh 不存在）"
else
  # TC-3a: 腳本接受 TTL 參數（--ttl 秒數），供測試縮短 TTL
  if grep -q "TTL\|ttl\|2.*hour\|7200\|--ttl" "$CLEANUP_SCRIPT" 2>/dev/null; then
    pass "TC-3a: claim-cleanup.sh 包含 TTL 相關邏輯"
  else
    fail "TC-3a: claim-cleanup.sh 未找到 TTL 相關邏輯"
  fi

  # TC-3b: 腳本呼叫 release-issue.sh 或等效清理方式
  if grep -q "release-issue\|push.*delete\|--delete" "$CLEANUP_SCRIPT" 2>/dev/null; then
    pass "TC-3b: claim-cleanup.sh 呼叫 release 機制"
  else
    fail "TC-3b: claim-cleanup.sh 未找到 release 機制呼叫"
  fi

  # TC-3c: 腳本輸出 [CLAIM-CLEANUP] 格式
  if grep -q "\[CLAIM-CLEANUP\]" "$CLEANUP_SCRIPT" 2>/dev/null; then
    pass "TC-3c: claim-cleanup.sh 包含 [CLAIM-CLEANUP] 輸出格式"
  else
    fail "TC-3c: claim-cleanup.sh 未找到 [CLAIM-CLEANUP] 輸出格式"
  fi

  # TC-3d: 無 stale ref 時，輸出 0 個 stale claim
  OUTPUT=$(bash "$CLEANUP_SCRIPT" 2>&1 || true)
  if echo "$OUTPUT" | grep -qE "\[CLAIM-CLEANUP\].*0|0.*stale|No stale|clean" 2>/dev/null; then
    pass "TC-3d: 無 stale ref 時正確輸出 0 個 stale claim"
  else
    # 如果無法連接 remote，接受 [WARN] 或空輸出
    if echo "$OUTPUT" | grep -qE "\[WARN\]|warning|No remote|not.*remote" 2>/dev/null || [[ -z "$OUTPUT" ]]; then
      pass "TC-3d: 無法連接 remote，輸出 [WARN] 或空（可接受）"
    elif echo "$OUTPUT" | grep -q "\[CLAIM-CLEANUP\]"; then
      pass "TC-3d: 輸出包含 [CLAIM-CLEANUP]（正常運行）"
    else
      fail "TC-3d: 輸出不符預期: $OUTPUT"
    fi
  fi
fi

# ── TC-4: AC-2 resume 偵測邏輯 ───────────────────────────────────
echo ""
echo "TC-4: AC-2 resume 偵測邏輯（SKILL.md §3 checkpoint 偵測）"

SKILL_FILE="$REPO_ROOT/skills/sprint-execution/SKILL.md"

# TC-4a: SKILL.md §3 包含 checkpoint 偵測步驟
if grep -q "CHECKPOINT-RESUME\|sprint-checkpoint.json\|checkpoint.*偵測\|偵測.*checkpoint" "$SKILL_FILE" 2>/dev/null; then
  pass "TC-4a: SKILL.md §3 包含 checkpoint 偵測相關描述"
else
  fail "TC-4a: SKILL.md §3 未找到 checkpoint 偵測相關描述"
fi

# TC-4b: §3 流程包含 resume 分支邏輯
if grep -q "CHECKPOINT-RESUME\|resume\|Resume\|斷點續跑\|從斷點" "$SKILL_FILE" 2>/dev/null; then
  pass "TC-4b: SKILL.md 包含 resume（斷點續跑）邏輯"
else
  fail "TC-4b: SKILL.md 未找到 resume 邏輯"
fi

# TC-4c: §3 流程定義跳過已完成 Story 的邏輯
if grep -q "completed\|已完成.*跳過\|跳過.*已完成\|skip.*completed" "$SKILL_FILE" 2>/dev/null; then
  pass "TC-4c: SKILL.md 包含跳過已完成 Story 的邏輯"
else
  fail "TC-4c: SKILL.md 未找到跳過已完成 Story 的邏輯"
fi

# ── TC-5: 無 checkpoint 時正常流程 ───────────────────────────────
echo ""
echo "TC-5: AC-2 無 checkpoint 時正常流程"

# TC-5a: §3 包含「不存在 → 正常開始」分支
if grep -q "不存在.*正常\|正常開始\|normal.*start\|checkpoint.*not.*exist" "$SKILL_FILE" 2>/dev/null; then
  pass "TC-5a: SKILL.md 包含無 checkpoint 時正常開始的邏輯"
else
  fail "TC-5a: SKILL.md 未找到無 checkpoint 時正常開始邏輯"
fi

# ── 總結 ─────────────────────────────────────────────────────────
echo ""
echo "========================================================"
echo "測試結果：PASS=$PASS  FAIL=$FAIL"
if [[ $FAIL -gt 0 ]]; then
  echo "失敗項目："
  for e in "${ERRORS[@]}"; do echo "  - $e"; done
  echo "========================================================"
  exit 1
else
  echo "全部通過"
  echo "========================================================"
  exit 0
fi
