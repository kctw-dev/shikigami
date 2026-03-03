#!/usr/bin/env bash
# test-retro61-onboarding-stale-refs.sh
# Retro #61 — Onboarding SKILL.md stale reference 審查與修正
# TDD 測試：驗證 skills/onboarding/SKILL.md 無 stale reference

set -euo pipefail

SKILL_FILE="$(git rev-parse --show-toplevel)/skills/onboarding/SKILL.md"

PASS=0
FAIL=0

run_test() {
    local name="$1"
    local result="$2"  # 0=pass, 1=fail
    if [[ "$result" -eq 0 ]]; then
        echo "  PASS: $name"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $name"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== Retro #61: Onboarding SKILL.md Stale Reference Tests ==="
echo ""

# --- AC2: Numeric reference 審查 ---
echo "--- Numeric References ---"

# Test 1: §2.3 不應出現 "3 個核心範本"（已知 stale，BACKLOG_DONE.md 加入後應為 4 個）
if grep -q "3 個核心範本" "$SKILL_FILE"; then
    run_test "§2.3 不含 stale '3 個核心範本'" 1
else
    run_test "§2.3 不含 stale '3 個核心範本'" 0
fi

# Test 2: §2.3 應出現 "4 個核心範本"（正確數量）
if grep -q "4 個核心範本" "$SKILL_FILE"; then
    run_test "§2.3 含正確 '4 個核心範本'" 0
else
    run_test "§2.3 含正確 '4 個核心範本'" 1
fi

# Test 3: §2.1 仍應含 "4 個範本文件"（已正確，驗證未被破壞）
if grep -q "4 個範本文件" "$SKILL_FILE"; then
    run_test "§2.1 含正確 '4 個範本文件'" 0
else
    run_test "§2.1 含正確 '4 個範本文件'" 1
fi

# Test 4: §2.3 table 實際應有 4 列資料行（以 | 開頭的 table rows，包含 templates/...docs/ 格式）
TABLE_ROWS=$(grep -c "^| \`templates/.*\.md\`" "$SKILL_FILE" || true)
if [[ "$TABLE_ROWS" -eq 4 ]]; then
    run_test "§2.3 table 有 4 列資料行" 0
else
    run_test "§2.3 table 有 4 列資料行 (found: $TABLE_ROWS)" 1
fi

echo ""

# --- AC2: Path reference 審查 ---
echo "--- Path References ---"

# Test 5: /standup 引用存在時，對應的 commands/standup.md 必須存在（路徑有效性驗證）
REPO_ROOT="$(git rev-parse --show-toplevel)"
if grep -q "/standup" "$SKILL_FILE"; then
    if [[ -f "$REPO_ROOT/commands/standup.md" ]]; then
        run_test "/standup 引用有效（commands/standup.md 存在）" 0
    else
        run_test "/standup 引用有效（commands/standup.md 不存在）" 1
    fi
else
    run_test "/standup 引用存在性（引用不存在，視為通過）" 0
fi

# Test 6: shikigami:health-check skill 路徑有效
if grep -q "shikigami:health-check" "$SKILL_FILE"; then
    if [[ -d "$REPO_ROOT/skills/health-check" ]]; then
        run_test "shikigami:health-check 路徑有效" 0
    else
        run_test "shikigami:health-check 路徑有效（skill 目錄不存在）" 1
    fi
fi

# Test 7: shikigami:sprint-planning skill 路徑有效
if grep -q "shikigami:sprint-planning" "$SKILL_FILE"; then
    if [[ -d "$REPO_ROOT/skills/sprint-planning" ]]; then
        run_test "shikigami:sprint-planning 路徑有效" 0
    else
        run_test "shikigami:sprint-planning 路徑有效（skill 目錄不存在）" 1
    fi
fi

# Test 8: shikigami:architecture-decision skill 路徑有效
if grep -q "shikigami:architecture-decision" "$SKILL_FILE"; then
    if [[ -d "$REPO_ROOT/skills/architecture-decision" ]]; then
        run_test "shikigami:architecture-decision 路徑有效" 0
    else
        run_test "shikigami:architecture-decision 路徑有效（skill 目錄不存在）" 1
    fi
fi

# Test 9: shikigami:backlog-management skill 路徑有效
if grep -q "shikigami:backlog-management" "$SKILL_FILE"; then
    if [[ -d "$REPO_ROOT/skills/backlog-management" ]]; then
        run_test "shikigami:backlog-management 路徑有效" 0
    else
        run_test "shikigami:backlog-management 路徑有效（skill 目錄不存在）" 1
    fi
fi

# Test 10: templates/ 目錄路徑有效（SKILL.md 中引用的 templates/ 實際存在）
if grep -q "templates/" "$SKILL_FILE"; then
    if [[ -d "$REPO_ROOT/templates" ]]; then
        run_test "templates/ 目錄路徑有效" 0
    else
        run_test "templates/ 目錄路徑有效（目錄不存在）" 1
    fi
fi

# Test 11: 4 個 templates/*.md 引用在 §2.1 中皆實際存在
TEMPLATES_OK=0
for tmpl in "PRODUCT_BACKLOG.md" "ROADMAP.md" "PROJECT_BOARD.md" "BACKLOG_DONE.md"; do
    if [[ ! -f "$REPO_ROOT/templates/$tmpl" ]]; then
        TEMPLATES_OK=1
        echo "  (missing: templates/$tmpl)"
    fi
done
run_test "4 個 templates/*.md 引用皆實際存在" "$TEMPLATES_OK"

echo ""
echo "=== 結果 ==="
echo "PASS: $PASS  FAIL: $FAIL"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
    echo "FAIL — $FAIL 個測試未通過"
    exit 1
else
    echo "PASS — 所有測試通過"
    exit 0
fi
