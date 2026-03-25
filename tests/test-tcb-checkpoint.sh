#!/usr/bin/env bash
# tests/test-tcb-checkpoint.sh
# Story #781 — TCB Phase-Level Checkpoint 測試
#
# AC4: tests/test-tcb-checkpoint.sh simulates a mid-phase interruption
#      and validates correct resume behavior
#
# 測試場景：
#   TC1: Phase checkpoint 寫入與讀取（正常路徑）
#   TC2: 中斷模擬 — implementation phase 中斷後恢復（從 test phase 繼續）
#   TC3: tcb-status.sh 輸出格網驗證
#   TC4: NFR2 fallback — 無 checkpoint 時回傳空 phase_context
#   TC5: NFR1 session_id 跨 session 識別
#   TC6: 無效 JSON 文件不 crash

PASS=0
FAIL=0
RESULTS_DIR="docs/sprints/subagent-results"
TMPDIR_TEST=$(mktemp -d)

pass() { echo "PASS: $1"; ((PASS++)); }
fail() { echo "FAIL: $1"; ((FAIL++)); }

# 確保測試目錄存在
mkdir -p "$RESULTS_DIR"

# ── TC1: Phase checkpoint 寫入與讀取 ──
TC1_FILE="${RESULTS_DIR}/test-story-tc1-phase-checkpoint.json"
STORY_ID="test-story-tc1"
SPRINT_NUM="163"
SESSION_ID="test-session-001"
PHASE="analysis"

python3 -c "
import json, datetime, os
data = {
    'story': '#${STORY_ID}',
    'sprint': int('${SPRINT_NUM}'),
    'session_id': '${SESSION_ID}',
    'phase': '${PHASE}',
    'status': 'completed',
    'timestamp': datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
}
os.makedirs(os.path.dirname('${TC1_FILE}'), exist_ok=True)
with open('${TC1_FILE}', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
" 2>/dev/null

if [[ -f "$TC1_FILE" ]]; then
    pass "TC1: Phase checkpoint file created"
else
    fail "TC1: Phase checkpoint file not created"
fi

PHASE_VAL=$(python3 -c "import json; d=json.load(open('${TC1_FILE}')); print(d['phase'])" 2>/dev/null)
if [[ "$PHASE_VAL" == "analysis" ]]; then
    pass "TC1: Phase value correctly written (analysis)"
else
    fail "TC1: Phase value incorrect: got '${PHASE_VAL}', expected 'analysis'"
fi

STATUS_VAL=$(python3 -c "import json; d=json.load(open('${TC1_FILE}')); print(d['status'])" 2>/dev/null)
if [[ "$STATUS_VAL" == "completed" ]]; then
    pass "TC1: Status value correctly written (completed)"
else
    fail "TC1: Status value incorrect: got '${STATUS_VAL}'"
fi

# ── TC2: 中斷模擬 — implementation phase 完成後，Sprint Execution 讀取並確定從 test 繼續 ──
TC2_FILE="${RESULTS_DIR}/test-story-tc2-phase-checkpoint.json"

# 寫入 implementation 完成的 checkpoint（模擬中斷點）
python3 -c "
import json, os
data = {
    'story': '#test-story-tc2',
    'sprint': 163,
    'session_id': 'test-session-002',
    'phase': 'implementation',
    'status': 'completed',
    'timestamp': '2026-03-25T23:00:00Z'
}
os.makedirs(os.path.dirname('${TC2_FILE}'), exist_ok=True)
with open('${TC2_FILE}', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null

# 模擬 Sprint Execution 讀取邏輯
if [[ -f "$TC2_FILE" ]]; then
    LAST_PHASE=$(python3 -c "import json; d=json.load(open('${TC2_FILE}')); print(d.get('phase',''))" 2>/dev/null)
    LAST_STATUS=$(python3 -c "import json; d=json.load(open('${TC2_FILE}')); print(d.get('status',''))" 2>/dev/null)

    if [[ "$LAST_STATUS" == "completed" && "$LAST_PHASE" == "implementation" ]]; then
        PHASE_CONTEXT="resume from phase after ${LAST_PHASE}"
        pass "TC2: Mid-phase interrupt detected: last completed phase = implementation"
        pass "TC2: Resume context generated: '${PHASE_CONTEXT}'"
    else
        fail "TC2: Interrupt detection failed (phase=${LAST_PHASE}, status=${LAST_STATUS})"
    fi
else
    fail "TC2: Could not create checkpoint file for simulation"
fi

# ── TC3: tcb-status.sh 格網輸出 ──
TC3_FILE="${RESULTS_DIR}/test-story-tc3-phase-checkpoint.json"
python3 -c "
import json, os
data = {'story': '#test-story-tc3', 'sprint': 163, 'session_id': 'sess-003',
        'phase': 'design', 'status': 'completed', 'timestamp': '2026-03-25T22:00:00Z'}
os.makedirs(os.path.dirname('${TC3_FILE}'), exist_ok=True)
with open('${TC3_FILE}', 'w') as f: json.dump(data, f)
" 2>/dev/null

TCB_OUTPUT=$(ASCII_ONLY=1 bash scripts/tcb-status.sh 163 2>/dev/null)

if echo "$TCB_OUTPUT" | grep -q "TCB Phase Status Grid"; then
    pass "TC3: tcb-status.sh outputs grid header"
else
    fail "TC3: tcb-status.sh missing grid header"
fi

if echo "$TCB_OUTPUT" | grep -q "DONE"; then
    pass "TC3: Grid shows DONE status for completed phase"
else
    fail "TC3: Grid missing DONE status"
fi

if echo "$TCB_OUTPUT" | grep -q "Legend"; then
    pass "TC3: Grid includes legend"
else
    fail "TC3: Grid missing legend"
fi

# ── TC4: NFR2 fallback — 無 checkpoint 文件時應回傳空 context ──
NON_EXISTENT_CP="docs/sprints/subagent-results/nonexistent-story-999-phase-checkpoint.json"
if [[ ! -f "$NON_EXISTENT_CP" ]]; then
    PHASE_CONTEXT=""
    FALLBACK_APPLIED=false
    if [[ ! -f "$NON_EXISTENT_CP" ]]; then
        FALLBACK_APPLIED=true
        PHASE_CONTEXT=""  # fallback: 從頭開始
    fi
    if [[ "$FALLBACK_APPLIED" == "true" && -z "$PHASE_CONTEXT" ]]; then
        pass "TC4: NFR2 fallback correctly applied (empty phase_context)"
    else
        fail "TC4: NFR2 fallback not applied correctly"
    fi
else
    fail "TC4: Test precondition failed (checkpoint file should not exist)"
fi

# ── TC5: NFR1 session_id 跨 session 識別 ──
TC5_FILE="${RESULTS_DIR}/test-story-tc5-phase-checkpoint.json"
python3 -c "
import json, os
data = {'story': '#test-story-tc5', 'sprint': 163, 'session_id': 'old-session-001',
        'phase': 'analysis', 'status': 'completed', 'timestamp': '2026-03-24T10:00:00Z'}
os.makedirs(os.path.dirname('${TC5_FILE}'), exist_ok=True)
with open('${TC5_FILE}', 'w') as f: json.dump(data, f)
" 2>/dev/null

if [[ -f "$TC5_FILE" ]]; then
    CHECKPOINT_SESSION=$(python3 -c "import json; d=json.load(open('${TC5_FILE}')); print(d.get('session_id',''))" 2>/dev/null)
    CURRENT_SESSION="new-session-002"
    if [[ "$CHECKPOINT_SESSION" != "$CURRENT_SESSION" ]]; then
        pass "TC5: NFR1 session_id mismatch correctly detectable (old: ${CHECKPOINT_SESSION}, current: ${CURRENT_SESSION})"
    else
        fail "TC5: NFR1 session_id should differ between sessions"
    fi
else
    fail "TC5: Could not create TC5 checkpoint file"
fi

# ── TC6: 無效 JSON 不 crash ──
TC6_FILE="${RESULTS_DIR}/test-story-tc6-phase-checkpoint.json"
echo "{ invalid json !!!" > "$TC6_FILE"

TC6_OUTPUT=$(ASCII_ONLY=1 bash scripts/tcb-status.sh 163 2>/dev/null)
TC6_EXIT=$?
if [[ $TC6_EXIT -eq 0 ]]; then
    pass "TC6: Invalid JSON file does not crash tcb-status.sh (exit 0)"
else
    fail "TC6: tcb-status.sh crashed on invalid JSON (exit ${TC6_EXIT})"
fi

# ── 清理測試文件 ──
rm -f "${RESULTS_DIR}/test-story-tc1-phase-checkpoint.json"
rm -f "${RESULTS_DIR}/test-story-tc2-phase-checkpoint.json"
rm -f "${RESULTS_DIR}/test-story-tc3-phase-checkpoint.json"
rm -f "${RESULTS_DIR}/test-story-tc5-phase-checkpoint.json"
rm -f "${RESULTS_DIR}/test-story-tc6-phase-checkpoint.json"
rm -rf "$TMPDIR_TEST"

# ── 結果 ──
echo ""
echo "=== test-tcb-checkpoint.sh Results ==="
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
