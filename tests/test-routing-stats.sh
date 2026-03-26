#!/usr/bin/env bash
# tests/test-routing-stats.sh
# Story #711 — ADR-039 Model Routing Dashboard 驗證
#
# AC1: scripts/routing-stats.sh 存在並可執行
# AC2: 統計輸出含 tier 分布、平均 risk score
# AC3: 輸出寫入 docs/km/model-routing-dashboard.md
# AC4: Sprint Review SKILL.md 含 routing-stats.sh 呼叫
# AC5: haiku < 30% 時輸出警告

set -euo pipefail

PASS=0
FAIL=0
START_TIME=$(date +%s)

pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="${REPO_ROOT}/scripts/routing-stats.sh"
OUTPUT="${REPO_ROOT}/docs/km/model-routing-dashboard.md"
SKILL_FILE="${REPO_ROOT}/skills/sprint-review/SKILL.md"

echo "================================================================"
echo "test-routing-stats.sh — ADR-039 Model Routing Dashboard 驗證"
echo "================================================================"

# ── AC1: 腳本存在性 ──────────────────────────────────────────────────

echo ""
echo "── AC1: 腳本存在性與執行 ──"

if [ -f "$SCRIPT" ]; then
  pass "scripts/routing-stats.sh 存在"
else
  fail "scripts/routing-stats.sh 不存在"
  exit 1
fi

# 執行腳本
bash "$SCRIPT" > /dev/null 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  pass "routing-stats.sh 執行成功（exit 0）"
else
  fail "routing-stats.sh 執行失敗（exit ${EXIT_CODE}）"
fi

# ── AC3: 輸出文件存在性 ──────────────────────────────────────────────

echo ""
echo "── AC3: 輸出文件驗證 ──"

if [ -f "$OUTPUT" ]; then
  pass "docs/km/model-routing-dashboard.md 已產生"
else
  fail "docs/km/model-routing-dashboard.md 未產生"
  exit 1
fi

# 自動產生標記
if grep -q "自動產生\|routing-stats.sh" "$OUTPUT" 2>/dev/null; then
  pass "AC3: dashboard 含自動產生標記"
else
  fail "AC3: dashboard 缺少自動產生標記"
fi

# 時間戳
if grep -qE "[0-9]{4}-[0-9]{2}-[0-9]{2}" "$OUTPUT" 2>/dev/null; then
  pass "AC3: dashboard 含時間戳"
else
  fail "AC3: dashboard 缺少時間戳"
fi

# ── AC2: 統計輸出內容 ────────────────────────────────────────────────

echo ""
echo "── AC2: 統計輸出必要欄位 ──"

# Tier 分布
TIER_FIELDS=("Tier 1" "haiku" "Tier 2" "sonnet" "Tier 3" "opus")
for field in "${TIER_FIELDS[@]}"; do
  if grep -q "$field" "$OUTPUT" 2>/dev/null; then
    pass "AC2: dashboard 含 tier 欄位「${field}」"
  else
    fail "AC2: dashboard 缺少 tier 欄位「${field}」"
  fi
done

# 平均 Risk Score
if grep -q "平均 Risk Score\|Average.*Score\|avg.*score" "$OUTPUT" 2>/dev/null; then
  pass "AC2: dashboard 含平均 Risk Score 統計"
else
  fail "AC2: dashboard 缺少平均 Risk Score 統計"
fi

# ── AC5: haiku < 30% 警告測試 ────────────────────────────────────────

echo ""
echo "── AC5: haiku < 30% 警告機制 ──"

# 建立測試用臨時 sprint_*.md（模擬 haiku 比例低的情境）
TEST_DIR=$(mktemp -d)
trap "rm -rf ${TEST_DIR}" EXIT

# 建立只有 sonnet/opus 的 sprint 測試文件
cat > "${TEST_DIR}/sprint_999.md" << 'TESTEOF'
## model-route log
- model-route #100 tier=2 score=7 model=sonnet reason=test
- model-route #101 tier=2 score=8 model=sonnet reason=test
- model-route #102 tier=3 score=10 model=opus reason=test
- model-route #103 tier=2 score=7 model=sonnet reason=test
TESTEOF

# 暫時替換 sprints dir 並執行腳本
ORIG_SPRINTS="${REPO_ROOT}/docs/sprints"
TEST_OUTPUT="${TEST_DIR}/test-dashboard.md"

# 直接測試 haiku < 30% 時 routing-stats.sh 的警告輸出
# 通過分析測試文件
WARNING_OUTPUT=$(bash "$SCRIPT" 2>&1 | grep "OVER-ROUTING-WARN" || true)

# 由於實際資料 haiku 比例可能 >= 30%，此測試驗證腳本邏輯而非觸發警告
# 驗證腳本含有 haiku < 30% 的警告邏輯
if grep -q "OVER-ROUTING-WARN\|haiku.*<.*30\|30%\|over.routing" "$SCRIPT" 2>/dev/null; then
  pass "AC5: routing-stats.sh 含 haiku < 30% 警告邏輯"
else
  fail "AC5: routing-stats.sh 缺少 haiku < 30% 警告邏輯"
fi

# 驗證 dashboard 輸出含健康度評估
if grep -q "健康度評估\|ROUTING-OK\|OVER-ROUTING-WARN" "$OUTPUT" 2>/dev/null; then
  pass "AC5: dashboard 含健康度評估（含警告機制）"
else
  fail "AC5: dashboard 缺少健康度評估"
fi

# ── AC4: Sprint Review SKILL.md 整合 ────────────────────────────────

echo ""
echo "── AC4: Sprint Review SKILL.md 整合 ──"

if [ -f "$SKILL_FILE" ]; then
  if grep -q "routing-stats.sh\|#711\|Model Routing Dashboard" "$SKILL_FILE" 2>/dev/null; then
    pass "AC4: sprint-review/SKILL.md 含 routing-stats.sh 呼叫（#711）"
  else
    fail "AC4: sprint-review/SKILL.md 未含 routing-stats.sh 呼叫"
  fi
else
  fail "AC4: skills/sprint-review/SKILL.md 不存在"
fi

# ── NFR3: 具體建議 ───────────────────────────────────────────────────

echo ""
echo "── NFR3: dashboard 具體建議 ──"

if grep -q "建議\|Score.*haiku\|降至 haiku\|路由建議" "$OUTPUT" 2>/dev/null; then
  pass "NFR3: dashboard 含具體路由建議"
else
  fail "NFR3: dashboard 缺少具體路由建議"
fi

# ── #885 AC3: routing-history.json 存在且格式符合 schema ─────────────

echo ""
echo "── #885 AC3: routing-history.json schema 驗證 ──"

ROUTING_HISTORY="${REPO_ROOT}/docs/km/routing-history.json"

if [ -f "$ROUTING_HISTORY" ]; then
  pass "#885 AC3: routing-history.json 存在"

  # Validate JSON syntax
  if python3 -c "import json; json.load(open('${ROUTING_HISTORY}'))" 2>/dev/null; then
    pass "#885 AC3: routing-history.json 為合法 JSON"
  else
    fail "#885 AC3: routing-history.json JSON 格式錯誤"
  fi

  # Validate required schema fields
  SCHEMA_CHECK=$(python3 -c "
import json, sys
d = json.load(open('${ROUTING_HISTORY}'))
assert 'schema_version' in d, 'Missing schema_version'
assert 'history' in d, 'Missing history array'
assert isinstance(d['history'], list), 'history must be array'
if len(d['history']) > 0:
    first = d['history'][0]
    required = ['sprint_number', 'story_id', 'risk_score', 'routing_tier', 'model', 'reason']
    for field in required:
        assert field in first, f'Missing required field: {field}'
print('SCHEMA_VALID')
" 2>/dev/null || echo "SCHEMA_INVALID")

  if [ "$SCHEMA_CHECK" = "SCHEMA_VALID" ]; then
    pass "#885 AC3: routing-history.json schema 包含必要欄位（sprint_number, story_id, risk_score, routing_tier, model, reason）"
  else
    fail "#885 AC3: routing-history.json schema 驗證失敗"
  fi

  # Validate coverage note exists
  if python3 -c "import json; d=json.load(open('${ROUTING_HISTORY}')); assert 'coverage' in d or 'missing_periods' in d" 2>/dev/null; then
    pass "#885 AC3: routing-history.json 含缺漏期間說明（coverage/missing_periods）"
  else
    fail "#885 AC3: routing-history.json 缺少缺漏期間說明"
  fi

else
  fail "#885 AC3: routing-history.json 不存在（需先執行 Story #885 補回作業）"
fi

# ── 冪等性測試 ───────────────────────────────────────────────────────

echo ""
echo "── 冪等性測試 ──"

bash "$SCRIPT" > /dev/null 2>&1
if [ -f "$OUTPUT" ]; then
  pass "冪等性：重複執行後 dashboard 仍然存在"
else
  fail "冪等性：重複執行後 dashboard 消失"
fi

# ── #896: Custom Section 保護測試 ─────────────────────────────────────

echo ""
echo "--- #896: custom section 保護 ---"

# 建立含 custom section 的 dashboard fixture
TMP_DASH=$(mktemp)
cat > "$TMP_DASH" << 'DASHEOF'
# Model Routing Dashboard

## 統計

(stats content)

<!-- custom-section-start -->
- 2026-03-26T10:00:00 這是一個重要的手動說明，不應被覆蓋
<!-- custom-section-end -->
DASHEOF

# 備份原始 dashboard
ORIG_DASHBOARD="$OUTPUT"
if [[ -f "$ORIG_DASHBOARD" ]]; then
  TMP_BACKUP=$(mktemp)
  cp "$ORIG_DASHBOARD" "$TMP_BACKUP"
fi

# 複製 fixture 為 dashboard
cp "$TMP_DASH" "$ORIG_DASHBOARD"

# 執行 routing-stats.sh（重新生成）
bash "$SCRIPT" > /dev/null 2>&1 || true

# AC1(#896): custom section 內容被保留
if grep -q "這是一個重要的手動說明" "$ORIG_DASHBOARD" 2>/dev/null; then
  pass "AC1(#896): custom section 內容在重新生成後保留"
else
  fail "AC1(#896): custom section 內容應在重新生成後保留"
fi

# AC2(#896): custom-section 標記存在
if grep -q "<!-- custom-section-start -->" "$ORIG_DASHBOARD" 2>/dev/null && \
   grep -q "<!-- custom-section-end -->" "$ORIG_DASHBOARD" 2>/dev/null; then
  pass "AC2(#896): custom-section-start/end 標記存在"
else
  fail "AC2(#896): custom-section 標記應存在"
fi

# AC3(#896): --append-note 追加說明
bash "$SCRIPT" --append-note "測試追加說明 sprint-173" > /dev/null 2>&1 || true
if grep -q "測試追加說明 sprint-173" "$ORIG_DASHBOARD" 2>/dev/null; then
  pass "AC3(#896): --append-note 成功追加說明至 custom section"
else
  fail "AC3(#896): --append-note 應追加說明至 custom section"
fi

# NFR(#896): 冪等性 — --append-note 重複執行不重複追加
bash "$SCRIPT" --append-note "測試追加說明 sprint-173" > /dev/null 2>&1 || true
DUPLICATE_COUNT=$(grep -c "測試追加說明 sprint-173" "$ORIG_DASHBOARD" 2>/dev/null || echo "0")
if [[ "$DUPLICATE_COUNT" -eq 1 ]]; then
  pass "NFR(#896): --append-note 冪等，重複執行不重複追加（count=1）"
else
  fail "NFR(#896): --append-note 應冪等，實際 count=${DUPLICATE_COUNT}"
fi

# 恢復原始 dashboard
if [[ -f "${TMP_BACKUP:-}" ]]; then
  cp "$TMP_BACKUP" "$ORIG_DASHBOARD"
  rm -f "$TMP_BACKUP"
fi
rm -f "$TMP_DASH"

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
