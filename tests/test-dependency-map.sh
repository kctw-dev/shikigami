#!/usr/bin/env bash
# tests/test-dependency-map.sh
# Story #800 — TDAD Story 依賴圖測試
# AC3: tests/test-dependency-map.sh validates script with sample sprint data

PASS=0
FAIL=0
SCRIPT="scripts/analyze-dependencies.sh"
TMPDIR_TEST=$(mktemp -d)

pass() { echo "PASS: $1"; ((PASS++)); }
fail() { echo "FAIL: $1"; ((FAIL++)); }

# ── TC1: 正常 sprint 文件解析 ──
cat > "$TMPDIR_TEST/sprint_test.md" << 'EOF'
# Sprint Test

## Sprint Backlog

| # | Story | Issue | Points | Status | Assignee |
|---|-------|-------|--------|--------|----------|
| 1 | feat: TCB Checkpoint — story-lifecycle 修改 | #781 | 3 | TODO | Developer |
| 2 | retro: worktree 清理驗證 | #790 | 1 | TODO | Developer |
| 3 | retro: ADR-039 haiku 路由擴充 | #817 | 1 | TODO | Developer |
EOF

OUTPUT=$(bash "$SCRIPT" "$TMPDIR_TEST/sprint_test.md" 2>/dev/null)

if echo "$OUTPUT" | grep -q "#781"; then
    pass "TC1: Story #781 detected in output"
else
    fail "TC1: Story #781 not found in output"
fi

if echo "$OUTPUT" | grep -q "#790"; then
    pass "TC1: Story #790 detected in output"
else
    fail "TC1: Story #790 not found in output"
fi

if echo "$OUTPUT" | grep -q "Story Dependency Graph"; then
    pass "TC1: Output header present"
else
    fail "TC1: Output header missing"
fi

# ── TC2: 衝突偵測 ──
if echo "$OUTPUT" | grep -q "Group B (sequential)"; then
    pass "TC2: Sequential group present for conflicting stories"
else
    fail "TC2: Sequential group missing"
fi

if echo "$OUTPUT" | grep -q "Group A (parallel)"; then
    pass "TC2: Parallel group present"
else
    fail "TC2: Parallel group missing"
fi

# ── TC3: 無 Story 文件（空 Sprint）──
cat > "$TMPDIR_TEST/sprint_empty.md" << 'EOF'
# Sprint Empty

## Sprint Backlog

(no stories)
EOF

OUTPUT_EMPTY=$(bash "$SCRIPT" "$TMPDIR_TEST/sprint_empty.md" 2>&1)
EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]]; then
    pass "TC3: Empty sprint file exits 0 (no crash)"
else
    fail "TC3: Empty sprint file crashed (exit code $EXIT_CODE)"
fi

if echo "$OUTPUT_EMPTY" | grep -q "no stories found"; then
    pass "TC3: Empty sprint outputs warning message"
else
    fail "TC3: Empty sprint missing warning message"
fi

# ── TC4: 不存在的文件 ──
bash "$SCRIPT" /nonexistent/sprint.md 2>/dev/null
EXIT_CODE=$?
if [[ $EXIT_CODE -ne 0 ]]; then
    pass "TC4: Non-existent file returns non-zero exit code"
else
    fail "TC4: Non-existent file should return error"
fi

# ── TC5: 無參數調用 ──
bash "$SCRIPT" 2>/dev/null
EXIT_CODE=$?
if [[ $EXIT_CODE -ne 0 ]]; then
    pass "TC5: No-args invocation returns non-zero exit code"
else
    fail "TC5: No-args invocation should return error"
fi

# ── TC6: 使用真實 sprint_163.md（若存在）──
if [[ -f "docs/sprints/sprint_163.md" ]]; then
    OUTPUT_163=$(bash "$SCRIPT" "docs/sprints/sprint_163.md" 2>/dev/null)
    if echo "$OUTPUT_163" | grep -q "sprint_163"; then
        pass "TC6: Real sprint_163.md parsed successfully"
    else
        fail "TC6: Real sprint_163.md parsing failed"
    fi
else
    pass "TC6: sprint_163.md not found, skipping (not an error)"
fi

# ── 清理 ──
rm -rf "$TMPDIR_TEST"

# ── 結果 ──
echo ""
echo "=== test-dependency-map.sh Results ==="
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
