#!/usr/bin/env bash
# tests/test-sprint-review-parallel.sh
# Story #709 — Sprint Review 指標收集平行化驗證
#
# AC1: sprint-review/SKILL.md 重構指標收集段落，三個子流程改為 subagent 並行
# AC2: Analytics subagent 獨立計算 Velocity、Adoption Rate、Completion Rate
# AC3: SPACE subagent 獨立計算 5 個 SPACE 維度指標
# AC4: Quality Observer subagent 獨立查詢 MCP Server 品質指標
# AC5: 三個 subagent 均完成後，主 session 聚合結果
# AC6: Sprint Review 整體時長較串行基準縮短 >= 30%（估算）

set -euo pipefail

PASS=0
FAIL=0
START_TIME=$(date +%s)

pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_FILE="${REPO_ROOT}/skills/sprint-review/SKILL.md"

echo "================================================================"
echo "test-sprint-review-parallel.sh — Sprint Review 指標收集平行化驗證"
echo "================================================================"

# ── AC1: SKILL.md 存在性與重構標記 ──────────────────────────────────

echo ""
echo "── AC1: SKILL.md 指標收集平行化重構 ──"

if [ -f "$SKILL_FILE" ]; then
  pass "skills/sprint-review/SKILL.md 存在"
else
  fail "skills/sprint-review/SKILL.md 不存在"
  exit 1
fi

# 確認平行化段落已加入
if grep -q "指標收集平行化\|#709\|METRICS-PARALLEL" "$SKILL_FILE" 2>/dev/null; then
  pass "AC1: SKILL.md 含指標收集平行化段落（#709 標記）"
else
  fail "AC1: SKILL.md 未含指標收集平行化段落"
fi

# 確認三個 subagent 平行派遣說明
if grep -q "同時.*派遣\|Task tool 並行\|平行派遣" "$SKILL_FILE" 2>/dev/null; then
  pass "AC1: SKILL.md 含平行派遣說明（Task tool 並行）"
else
  fail "AC1: SKILL.md 未含平行派遣說明"
fi

# 確認 §3.0 章節存在
if grep -q "§3.0\|3\.0.*指標收集" "$SKILL_FILE" 2>/dev/null; then
  pass "AC1: SKILL.md 含 §3.0 指標收集平行化章節"
else
  fail "AC1: SKILL.md 缺少 §3.0 指標收集平行化章節"
fi

# ── AC2: Analytics subagent 說明 ─────────────────────────────────────

echo ""
echo "── AC2: Analytics subagent 獨立計算 ──"

ANALYTICS_METRICS=("Velocity" "Adoption Rate" "Completion Rate")
for metric in "${ANALYTICS_METRICS[@]}"; do
  if grep -q "$metric" "$SKILL_FILE" 2>/dev/null; then
    pass "AC2: SKILL.md 含 Analytics 指標「${metric}」"
  else
    fail "AC2: SKILL.md 缺少 Analytics 指標「${metric}」"
  fi
done

if grep -q "Analytics subagent" "$SKILL_FILE" 2>/dev/null; then
  pass "AC2: SKILL.md 明確標注 Analytics subagent"
else
  fail "AC2: SKILL.md 未標注 Analytics subagent"
fi

# ── AC3: SPACE subagent 說明 ──────────────────────────────────────────

echo ""
echo "── AC3: SPACE subagent 獨立計算 ──"

SPACE_DIMS=("Satisfaction" "Performance" "Activity" "Communication" "Efficiency")
for dim in "${SPACE_DIMS[@]}"; do
  if grep -q "$dim" "$SKILL_FILE" 2>/dev/null; then
    pass "AC3: SKILL.md 含 SPACE 維度「${dim}」"
  else
    fail "AC3: SKILL.md 缺少 SPACE 維度「${dim}」"
  fi
done

if grep -q "SPACE subagent" "$SKILL_FILE" 2>/dev/null; then
  pass "AC3: SKILL.md 明確標注 SPACE subagent"
else
  fail "AC3: SKILL.md 未標注 SPACE subagent"
fi

# ── AC4: Quality Observer subagent 說明 ──────────────────────────────

echo ""
echo "── AC4: Quality Observer subagent 說明 ──"

if grep -q "Quality Observer subagent" "$SKILL_FILE" 2>/dev/null; then
  pass "AC4: SKILL.md 明確標注 Quality Observer subagent"
else
  fail "AC4: SKILL.md 未標注 Quality Observer subagent"
fi

# MCP 降級處理
if grep -q "QO-UNAVAILABLE\|MCP.*不可用\|MCP.*降級" "$SKILL_FILE" 2>/dev/null; then
  pass "AC4: SKILL.md 含 Quality Observer MCP 降級處理（NFR2 相容）"
else
  fail "AC4: SKILL.md 缺少 Quality Observer MCP 降級處理"
fi

# ── AC5: 聚合邏輯說明 ────────────────────────────────────────────────

echo ""
echo "── AC5: 三個 subagent 聚合邏輯 ──"

if grep -q "聚合\|等待.*完成\|全部.*完成" "$SKILL_FILE" 2>/dev/null; then
  pass "AC5: SKILL.md 含聚合等待說明（等待三個 subagent 完成）"
else
  fail "AC5: SKILL.md 缺少聚合等待說明"
fi

# 降級說明（任一失敗使用 N/A）
if grep -q "METRICS-DEGRADE\|N/A\|降級.*N/A\|失敗.*N/A" "$SKILL_FILE" 2>/dev/null; then
  pass "AC5: SKILL.md 含 subagent 失敗降級（N/A）說明"
else
  fail "AC5: SKILL.md 缺少 subagent 失敗降級說明"
fi

# ── AC6: 時長縮短估算 ────────────────────────────────────────────────

echo ""
echo "── AC6: Sprint Review 時長縮短估算 ──"

if grep -q "縮短\|>= 30%\|> 30%\|30.*%" "$SKILL_FILE" 2>/dev/null; then
  pass "AC6: SKILL.md 含時長縮短估算（>= 30%）"
else
  fail "AC6: SKILL.md 缺少時長縮短估算"
fi

# ── NFR3: OOM 防護說明 ───────────────────────────────────────────────

echo ""
echo "── NFR3: OOM 防護 ──"

if grep -q "SHIKIGAMI_MAX_PARALLEL\|OOM\|parallel-safety" "$SKILL_FILE" 2>/dev/null; then
  pass "NFR3: SKILL.md 含 SHIKIGAMI_MAX_PARALLEL OOM 防護說明"
else
  fail "NFR3: SKILL.md 缺少 OOM 防護說明"
fi

# 降級為串行的說明
if grep -q "降級.*串行\|slots.*<\|METRICS-PARALLEL-DEGRADE" "$SKILL_FILE" 2>/dev/null; then
  pass "NFR3: SKILL.md 含 slots 不足時降級為串行說明"
else
  fail "NFR3: SKILL.md 缺少 slots 不足降級說明"
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
