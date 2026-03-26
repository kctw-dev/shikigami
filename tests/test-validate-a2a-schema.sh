#!/usr/bin/env bash
# tests/test-validate-a2a-schema.sh
# Story #883: validate-a2a-schema.sh 自動化測試 — A2A 協議 Schema 驗證單元測試
#
# AC1: tests/test-validate-a2a-schema.sh 存在並可獨立執行
# AC2: 測試覆蓋合法 A2A schema 文件通過驗證
# AC3: 測試覆蓋缺少必要欄位時輸出具體錯誤訊息並 exit non-zero
# AC4: 測試覆蓋非法欄位型別偵測
# AC5: 使用 /tmp fixture schema 檔案，測試結束後清理
#
# NFR1: 不依賴真實 A2A 通訊，純靜態 schema 驗證
# NFR2: < 5 秒完成

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="${REPO_ROOT}/scripts/validate-a2a-schema.sh"

PASS=0
FAIL=0
START_TIME=$(date +%s)

# ─── Fixture Setup (AC5) ──────────────────────────────────────────────────────
FIXTURE_DIR=$(mktemp -d /tmp/test-a2a-schema-XXXXXX)
cleanup() { rm -rf "$FIXTURE_DIR"; }
trap cleanup EXIT

# Helper functions
pass() { echo "[PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL + 1)); }

assert_exit_code() {
    local expected="$1" actual="$2" label="$3"
    if [ "$actual" -eq "$expected" ]; then pass "$label"
    else fail "$label (expected exit=$expected, actual exit=$actual)"; fi
}

echo "=== Sprint 169 #883 — validate-a2a-schema.sh 自動化測試 ==="
echo "Script: $SCRIPT"
echo "Fixture: $FIXTURE_DIR"
echo ""

# Prerequisite: script exists
if [ ! -f "$SCRIPT" ]; then
    echo "[ERROR] Script not found: $SCRIPT"
    exit 1
fi

# ─── AC2: 合法 A2A schema 文件通過驗證 ────────────────────────────────────────

echo "--- AC2: 合法 schema 通過驗證 ---"

# Create valid A2A result JSON
VALID_JSON="${FIXTURE_DIR}/valid-a2a.json"
cat > "$VALID_JSON" << 'EOF'
{
  "protocol_version": "1.0",
  "story_id": 879,
  "actor": "developer",
  "result": "PASS",
  "summary": "Tests written and all pass",
  "timestamp": "2026-03-26T14:00:00Z"
}
EOF

VALID_OUT=$(bash "$SCRIPT" "$VALID_JSON" 2>&1)
if echo "$VALID_OUT" | grep -q "\[PASS\]"; then pass "AC2: 合法 JSON 輸出 [PASS]"; else fail "AC2: 合法 JSON 應輸出 [PASS]"; fi

bash "$SCRIPT" "$VALID_JSON" > /dev/null 2>&1
assert_exit_code 0 $? "AC2: 合法 JSON exit 0"

# Test with ESCALATE result (valid)
ESCALATE_JSON="${FIXTURE_DIR}/escalate-a2a.json"
cat > "$ESCALATE_JSON" << 'EOF'
{
  "protocol_version": "1.0",
  "story_id": 880,
  "actor": "architect",
  "result": "ESCALATE",
  "summary": "Design issue found",
  "timestamp": "2026-03-26T14:01:00Z",
  "escalation": {
    "type": "DESIGN_ISSUE",
    "reason": "Architecture requires review"
  }
}
EOF

bash "$SCRIPT" "$ESCALATE_JSON" > /dev/null 2>&1
assert_exit_code 0 $? "AC2: ESCALATE 結果且含 escalation 欄位 exit 0"

# ─── AC3: 缺少必要欄位時 exit non-zero ─────────────────────────────────────────

echo ""
echo "--- AC3: 必要欄位缺失偵測 ---"

# Missing 'result' field
MISSING_RESULT="${FIXTURE_DIR}/missing-result.json"
cat > "$MISSING_RESULT" << 'EOF'
{
  "protocol_version": "1.0",
  "story_id": 999,
  "actor": "developer",
  "summary": "Missing result field",
  "timestamp": "2026-03-26T14:00:00Z"
}
EOF

MISSING_OUT=$(bash "$SCRIPT" "$MISSING_RESULT" 2>/dev/null)
if echo "$MISSING_OUT" | grep -q "\[FAIL\]"; then pass "AC3: 缺少 result 欄位輸出 [FAIL]"; else fail "AC3: 缺少 result 欄位應輸出 [FAIL]"; fi

bash "$SCRIPT" "$MISSING_RESULT" > /dev/null 2>&1
assert_exit_code 1 $? "AC3: 缺少 result 欄位 exit 1"

# Missing 'actor' field
MISSING_ACTOR="${FIXTURE_DIR}/missing-actor.json"
cat > "$MISSING_ACTOR" << 'EOF'
{
  "protocol_version": "1.0",
  "story_id": 999,
  "result": "PASS",
  "summary": "Missing actor",
  "timestamp": "2026-03-26T14:00:00Z"
}
EOF

bash "$SCRIPT" "$MISSING_ACTOR" > /dev/null 2>&1
assert_exit_code 1 $? "AC3: 缺少 actor 欄位 exit 1"

# Missing 'protocol_version'
MISSING_VER="${FIXTURE_DIR}/missing-version.json"
cat > "$MISSING_VER" << 'EOF'
{
  "story_id": 999,
  "actor": "developer",
  "result": "PASS",
  "summary": "Missing version",
  "timestamp": "2026-03-26T14:00:00Z"
}
EOF

bash "$SCRIPT" "$MISSING_VER" > /dev/null 2>&1
assert_exit_code 1 $? "AC3: 缺少 protocol_version 欄位 exit 1"

# Verify error message is specific
ERROR_MSG=$(bash "$SCRIPT" "$MISSING_RESULT" 2>/dev/null | grep "\[FAIL\]" | head -1)
if [ -n "$ERROR_MSG" ]; then pass "AC3: 錯誤訊息具體非空: \"$ERROR_MSG\""; else fail "AC3: 錯誤訊息應具體非空"; fi

# ─── AC4: 非法欄位型別偵測 ─────────────────────────────────────────────────────

echo ""
echo "--- AC4: 非法欄位值偵測 ---"

# Invalid actor value
INVALID_ACTOR="${FIXTURE_DIR}/invalid-actor.json"
cat > "$INVALID_ACTOR" << 'EOF'
{
  "protocol_version": "1.0",
  "story_id": 999,
  "actor": "invalid_role",
  "result": "PASS",
  "summary": "Invalid actor value",
  "timestamp": "2026-03-26T14:00:00Z"
}
EOF

bash "$SCRIPT" "$INVALID_ACTOR" > /dev/null 2>&1
assert_exit_code 1 $? "AC4: 非法 actor 值 exit 1"

# Invalid result value
INVALID_RESULT="${FIXTURE_DIR}/invalid-result.json"
cat > "$INVALID_RESULT" << 'EOF'
{
  "protocol_version": "1.0",
  "story_id": 999,
  "actor": "developer",
  "result": "UNKNOWN",
  "summary": "Invalid result value",
  "timestamp": "2026-03-26T14:00:00Z"
}
EOF

bash "$SCRIPT" "$INVALID_RESULT" > /dev/null 2>&1
assert_exit_code 1 $? "AC4: 非法 result 值 exit 1"

# ESCALATE without escalation field
ESCALATE_NO_DETAIL="${FIXTURE_DIR}/escalate-no-detail.json"
cat > "$ESCALATE_NO_DETAIL" << 'EOF'
{
  "protocol_version": "1.0",
  "story_id": 999,
  "actor": "developer",
  "result": "ESCALATE",
  "summary": "Missing escalation field",
  "timestamp": "2026-03-26T14:00:00Z"
}
EOF

bash "$SCRIPT" "$ESCALATE_NO_DETAIL" > /dev/null 2>&1
assert_exit_code 1 $? "AC4: ESCALATE 結果缺少 escalation 欄位 exit 1"

# String story_id (type error) — #894 新增
INVALID_STORY_ID_STRING="${FIXTURE_DIR}/invalid-story-id-string.json"
cat > "$INVALID_STORY_ID_STRING" << 'EOF'
{
  "protocol_version": "1.0",
  "story_id": "879",
  "actor": "developer",
  "result": "PASS",
  "summary": "story_id as string",
  "timestamp": "2026-03-26T14:00:00Z"
}
EOF

STRING_OUT=$(bash "$SCRIPT" "$INVALID_STORY_ID_STRING" 2>/dev/null)
if echo "$STRING_OUT" | grep -q "story_id.*整數\|story_id.*integer"; then
    pass "AC4: story_id 字串型別錯誤訊息含型別提示"
else
    fail "AC4: story_id 字串型別錯誤訊息應含型別提示"
fi

bash "$SCRIPT" "$INVALID_STORY_ID_STRING" > /dev/null 2>&1
assert_exit_code 1 $? "AC4: story_id 為字串型別 exit 1"

# ─── AC5: /tmp fixture 使用與清理驗證 ──────────────────────────────────────────

echo ""
echo "--- AC5: /tmp fixture 清理 ---"

echo "$FIXTURE_DIR" | grep -q "/tmp/" && pass "AC5: Fixture 建立於 /tmp" || fail "AC5: Fixture 應在 /tmp"
[ -d "$FIXTURE_DIR" ] && pass "AC5: Fixture 存在（EXIT trap 登記完成）" || fail "AC5: Fixture 應存在"

# Verify non-existent file handling
bash "$SCRIPT" "${FIXTURE_DIR}/nonexistent.json" > /dev/null 2>&1
NON_EXIT=$?
[ $NON_EXIT -ne 0 ] && pass "AC5: 不存在檔案 exit non-zero" || fail "AC5: 不存在檔案應 exit non-zero"

# ─── NFR2: 執行時間 < 5 秒 ────────────────────────────────────────────────────

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
if [ "$ELAPSED" -lt 5 ]; then
    pass "NFR2: 執行時間 ${ELAPSED}s < 5s"
else
    fail "NFR2: 執行時間 ${ELAPSED}s >= 5s"
fi

# ─── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo "=== 測試結果 ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo "Total: $((PASS + FAIL))"
echo "Duration: ${ELAPSED}s"

if [ "$FAIL" -eq 0 ]; then
    echo "[RESULT] ALL TESTS PASSED"
    exit 0
else
    echo "[RESULT] $FAIL TEST(S) FAILED"
    exit 1
fi
