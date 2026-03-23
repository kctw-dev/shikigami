#!/usr/bin/env bash
# test-383-team-debate.sh — Team Debate 機制驗證測試（ADR-031 Phase 1）
# Story: #383 feat: 同職能 Team Debate — 雙 Agent 交替批判機制（方案 C）

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== test-383-team-debate.sh ==="
echo ""

# -------------------------------------------------------
# AC1: Worker 實作後 Critic 產出獨立批判報告
# → 驗證：SKILL.md 定義 Critic 批判格式（critique-round-N.md）
# -------------------------------------------------------
echo "[AC1] Critic 批判格式定義"

SKILL="$REPO_ROOT/skills/team-debate/SKILL.md"

if [[ ! -f "$SKILL" ]]; then
  fail "skills/team-debate/SKILL.md 不存在"
else
  pass "skills/team-debate/SKILL.md 存在"
fi

if grep -q "critique-round-{N}.md" "$SKILL" 2>/dev/null; then
  pass "批判檔案路徑格式 critique-round-{N}.md 已定義"
else
  fail "批判檔案路徑格式未定義"
fi

if grep -q "## Verdict: PASS | FAIL" "$SKILL" 2>/dev/null; then
  pass "批判結果格式包含 Verdict 欄位"
else
  fail "批判結果格式缺少 Verdict 欄位"
fi

if grep -q "SEVERITY: HIGH|MED|LOW" "$SKILL" 2>/dev/null; then
  pass "批判結果格式包含 SEVERITY 分級"
else
  fail "批判結果格式缺少 SEVERITY 分級"
fi

echo ""

# -------------------------------------------------------
# AC2: Worker 接收批判後修復，最多 2 輪
# → 驗證：SKILL.md 定義 2 輪硬上限，story-lifecycle 有 §7.8 段落
# -------------------------------------------------------
echo "[AC2] 2 輪硬上限與修復循環"

if grep -q "2 輪硬上限\|最多 2 輪\|禁止 Round 3" "$SKILL" 2>/dev/null; then
  pass "SKILL.md 定義 2 輪硬上限"
else
  fail "SKILL.md 未定義 2 輪硬上限"
fi

LIFECYCLE="$REPO_ROOT/skills/sprint-execution/story-lifecycle-prompt.md"

if grep -q "§7.8 Team Debate" "$LIFECYCLE" 2>/dev/null; then
  pass "story-lifecycle-prompt.md 包含 §7.8 Team Debate 段落"
else
  fail "story-lifecycle-prompt.md 缺少 §7.8 Team Debate 段落"
fi

if grep -q "Round 2" "$LIFECYCLE" 2>/dev/null; then
  pass "story-lifecycle-prompt.md 定義 Round 2 修復流程"
else
  fail "story-lifecycle-prompt.md 缺少 Round 2 修復流程"
fi

if grep -q "Worker 修復規則" "$LIFECYCLE" 2>/dev/null || grep -q "§7.8.1" "$LIFECYCLE" 2>/dev/null; then
  pass "story-lifecycle-prompt.md 定義 Worker 修復規則"
else
  fail "story-lifecycle-prompt.md 缺少 Worker 修復規則"
fi

echo ""

# -------------------------------------------------------
# AC3: 2 輪後仍未收斂 → [DEBATE-UNRESOLVED] 升級
# -------------------------------------------------------
echo "[AC3] [DEBATE-UNRESOLVED] 升級機制"

if grep -q "DEBATE-UNRESOLVED" "$SKILL" 2>/dev/null; then
  pass "SKILL.md 定義 [DEBATE-UNRESOLVED] 標記"
else
  fail "SKILL.md 未定義 [DEBATE-UNRESOLVED] 標記"
fi

if grep -q "DEBATE-UNRESOLVED" "$LIFECYCLE" 2>/dev/null; then
  pass "story-lifecycle-prompt.md 包含 [DEBATE-UNRESOLVED] 處置規則"
else
  fail "story-lifecycle-prompt.md 缺少 [DEBATE-UNRESOLVED] 處置規則"
fi

if grep -q "DEBATE_DESIGN_ISSUE" "$LIFECYCLE" 2>/dev/null; then
  pass "story-lifecycle-prompt.md 定義 DEBATE_DESIGN_ISSUE 升級類型"
else
  fail "story-lifecycle-prompt.md 缺少 DEBATE_DESIGN_ISSUE 升級類型"
fi

echo ""

# -------------------------------------------------------
# AC4: 通訊透過檔案交換（.claude/debate/）
# -------------------------------------------------------
echo "[AC4] 檔案交換通訊機制"

if grep -q "\.claude/debate/" "$SKILL" 2>/dev/null; then
  pass "SKILL.md 定義 .claude/debate/ 通訊路徑"
else
  fail "SKILL.md 未定義 .claude/debate/ 通訊路徑"
fi

if grep -q "\.claude/debate/" "$LIFECYCLE" 2>/dev/null; then
  pass "story-lifecycle-prompt.md 引用 .claude/debate/ 通訊路徑"
else
  fail "story-lifecycle-prompt.md 未引用 .claude/debate/ 通訊路徑"
fi

# 輸出 schema 包含 critique_files
if grep -q "critique_files" "$LIFECYCLE" 2>/dev/null; then
  pass "輸出 schema 包含 critique_files 欄位"
else
  fail "輸出 schema 缺少 critique_files 欄位"
fi

echo ""

# -------------------------------------------------------
# AC5: Phase 1 僅 Developer 角色適用
# -------------------------------------------------------
echo "[AC5] Phase 1 僅 Developer 角色適用"

if grep -q "Phase 1.*Developer\|Developer.*Phase 1" "$SKILL" 2>/dev/null; then
  pass "SKILL.md 明確限制 Phase 1 為 Developer 角色"
else
  fail "SKILL.md 未限制 Phase 1 角色範圍"
fi

DEVELOPER_AGENT="$REPO_ROOT/agents/developer.md"

if grep -q "Team Debate\|Worker.*Critic\|Critic.*Worker" "$DEVELOPER_AGENT" 2>/dev/null; then
  pass "agents/developer.md 包含 Worker/Critic 角色說明"
else
  fail "agents/developer.md 缺少 Worker/Critic 角色說明"
fi

if grep -q "PO.*不包含\|不適用角色\|不含.*PO\|PO.*不涉及\|PO.*非產出" "$SKILL" 2>/dev/null; then
  pass "SKILL.md 說明 Phase 1 不包含 PO 等非產出角色"
else
  fail "SKILL.md 未說明 Phase 1 不包含哪些角色"
fi

echo ""

# -------------------------------------------------------
# 額外驗證：scrum-master SKILL.md 引用 team-debate
# -------------------------------------------------------
echo "[Extra] scrum-master SKILL.md 引用 team-debate"

SCRUM_SKILL="$REPO_ROOT/skills/scrum-master/SKILL.md"

if grep -q "team-debate" "$SCRUM_SKILL" 2>/dev/null; then
  pass "scrum-master/SKILL.md 包含 team-debate Skill 引用"
else
  fail "scrum-master/SKILL.md 缺少 team-debate Skill 引用"
fi

echo ""

# -------------------------------------------------------
# 額外驗證：輸入 schema 包含 team_debate 欄位
# -------------------------------------------------------
echo "[Extra] story-lifecycle 輸入 schema 含 team_debate 欄位"

if grep -q "team_debate:" "$LIFECYCLE" 2>/dev/null; then
  pass "story-lifecycle-prompt.md 輸入 schema 包含 team_debate 欄位"
else
  fail "story-lifecycle-prompt.md 輸入 schema 缺少 team_debate 欄位"
fi

echo ""

# -------------------------------------------------------
# 結果統計
# -------------------------------------------------------
TOTAL=$((PASS + FAIL))
echo "=== 結果：$PASS/$TOTAL PASS ==="
echo ""

if [[ $FAIL -eq 0 ]]; then
  echo "ALL TESTS PASSED"
  exit 0
else
  echo "SOME TESTS FAILED ($FAIL/$TOTAL)"
  exit 1
fi
