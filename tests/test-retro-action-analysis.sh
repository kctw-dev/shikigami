#!/usr/bin/env bash
# tests/test-retro-action-analysis.sh
# Story #872: Retro Action Items 歷史分析工具 — 完成率與重複主題趨勢
# TDD: 測試先於實作，使用 fixture 隔離（模擬 gh API 輸出）

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/retro-action-analysis.sh"
PASS=0
FAIL=0

ok()   { echo "[PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

echo "=== test-retro-action-analysis.sh ==="

# ── T1: 腳本存在且可執行 ──────────────────────────────────────────────────────
if [[ -x "$SCRIPT" ]]; then
  ok "T1: script exists and is executable"
else
  fail "T1: script not found or not executable: $SCRIPT"
fi

# ── T2: 完成率計算正確 ────────────────────────────────────────────────────────
# fixture: 10 issues total, 7 closed, 3 open
GH_STUB=$(mktemp -d)
cat > "$GH_STUB/gh" << 'GHEOF'
#!/usr/bin/env bash
# gh stub: 10 issues (7 closed, 3 open), mixed Sprint labels
# Supports: gh issue list --label retro-action --state all
echo '[
  {"number":101,"title":"改善 CI pipeline 速度","state":"CLOSED","labels":[{"name":"retro-action"},{"name":"Sprint 170"}]},
  {"number":102,"title":"補充文件說明","state":"CLOSED","labels":[{"name":"retro-action"},{"name":"Sprint 170"}]},
  {"number":103,"title":"改善 CI pipeline 穩定性","state":"OPEN","labels":[{"name":"retro-action"},{"name":"Sprint 170"}]},
  {"number":104,"title":"改善溝通流程","state":"CLOSED","labels":[{"name":"retro-action"},{"name":"Sprint 171"}]},
  {"number":105,"title":"補充測試覆蓋","state":"CLOSED","labels":[{"name":"retro-action"},{"name":"Sprint 171"}]},
  {"number":106,"title":"改善 review 品質","state":"OPEN","labels":[{"name":"retro-action"},{"name":"Sprint 171"}]},
  {"number":107,"title":"改善部署流程","state":"CLOSED","labels":[{"name":"retro-action"},{"name":"Sprint 172"}]},
  {"number":108,"title":"加強 code review 機制","state":"CLOSED","labels":[{"name":"retro-action"},{"name":"Sprint 172"}]},
  {"number":109,"title":"改善文件完整性","state":"OPEN","labels":[{"name":"retro-action"},{"name":"Sprint 172"}]},
  {"number":110,"title":"改善 CI pipeline 覆蓋率","state":"CLOSED","labels":[{"name":"retro-action"},{"name":"Sprint 173"}]}
]'
GHEOF
chmod +x "$GH_STUB/gh"

OUTPUT=$(PATH="$GH_STUB:$PATH" bash "$SCRIPT" 2>&1)
EC=$?
rm -rf "$GH_STUB"

if [[ $EC -eq 0 ]]; then
  ok "T2a: script exits 0 with valid fixture"
else
  fail "T2a: script exited non-zero ($EC)"
fi

# 完成率 = 7/10 = 70%
if echo "$OUTPUT" | grep -qE "70%|7/10"; then
  ok "T2b: completion rate 70% (7/10) displayed"
else
  fail "T2b: completion rate 70% not found in output"
fi

# ── T3: total=0 邊界條件不崩潰 ───────────────────────────────────────────────
GH_STUB=$(mktemp -d)
cat > "$GH_STUB/gh" << 'GHEOF'
#!/usr/bin/env bash
echo '[]'
GHEOF
chmod +x "$GH_STUB/gh"

EXIT_CODE=0
EMPTY_OUT=$(PATH="$GH_STUB:$PATH" bash "$SCRIPT" 2>&1) || EXIT_CODE=$?
rm -rf "$GH_STUB"

if [[ $EXIT_CODE -eq 0 ]]; then
  ok "T3: total=0 exits gracefully"
else
  fail "T3: total=0 caused crash (exit $EXIT_CODE)"
fi

# ── T4: 關鍵字重複偵測 — [SYSTEMIC-ISSUE] 標記 ───────────────────────────────
# "CI pipeline" 出現 3 次，"改善" 出現多次，應標記 [SYSTEMIC-ISSUE]
GH_STUB=$(mktemp -d)
cat > "$GH_STUB/gh" << 'GHEOF'
#!/usr/bin/env bash
echo '[
  {"number":201,"title":"CI pipeline 速度問題","state":"CLOSED","labels":[{"name":"retro-action"},{"name":"Sprint 168"}]},
  {"number":202,"title":"CI pipeline 穩定性問題","state":"OPEN","labels":[{"name":"retro-action"},{"name":"Sprint 169"}]},
  {"number":203,"title":"CI pipeline 覆蓋不足","state":"CLOSED","labels":[{"name":"retro-action"},{"name":"Sprint 170"}]},
  {"number":204,"title":"文件缺失","state":"CLOSED","labels":[{"name":"retro-action"},{"name":"Sprint 171"}]},
  {"number":205,"title":"溝通流程待改善","state":"OPEN","labels":[{"name":"retro-action"},{"name":"Sprint 172"}]}
]'
GHEOF
chmod +x "$GH_STUB/gh"

SYSTEMIC_OUT=$(PATH="$GH_STUB:$PATH" bash "$SCRIPT" 2>&1)
rm -rf "$GH_STUB"

if echo "$SYSTEMIC_OUT" | grep -q "\[SYSTEMIC-ISSUE\]"; then
  ok "T4a: [SYSTEMIC-ISSUE] detected for repeated keyword (CI pipeline)"
else
  fail "T4a: [SYSTEMIC-ISSUE] not found for repeated keyword 'CI pipeline'"
fi

# ── T5: 無重複關鍵字時不出現 [SYSTEMIC-ISSUE] ────────────────────────────────
GH_STUB=$(mktemp -d)
cat > "$GH_STUB/gh" << 'GHEOF'
#!/usr/bin/env bash
echo '[
  {"number":301,"title":"alpha unique issue","state":"CLOSED","labels":[{"name":"retro-action"},{"name":"Sprint 170"}]},
  {"number":302,"title":"beta separate concern","state":"OPEN","labels":[{"name":"retro-action"},{"name":"Sprint 171"}]},
  {"number":303,"title":"gamma distinct topic","state":"CLOSED","labels":[{"name":"retro-action"},{"name":"Sprint 172"}]}
]'
GHEOF
chmod +x "$GH_STUB/gh"

NO_SYSTEMIC_OUT=$(PATH="$GH_STUB:$PATH" bash "$SCRIPT" 2>&1)
rm -rf "$GH_STUB"

if ! echo "$NO_SYSTEMIC_OUT" | grep -q "\[SYSTEMIC-ISSUE\]"; then
  ok "T5: no [SYSTEMIC-ISSUE] when no repeated keywords"
else
  fail "T5: false [SYSTEMIC-ISSUE] triggered for unique keywords"
fi

# ── T6: 近 5 Sprint 趨勢輸出格式 ─────────────────────────────────────────────
GH_STUB=$(mktemp -d)
cat > "$GH_STUB/gh" << 'GHEOF'
#!/usr/bin/env bash
echo '[
  {"number":401,"title":"issue alpha","state":"CLOSED","labels":[{"name":"retro-action"},{"name":"Sprint 168"}]},
  {"number":402,"title":"issue beta","state":"OPEN","labels":[{"name":"retro-action"},{"name":"Sprint 169"}]},
  {"number":403,"title":"issue gamma","state":"CLOSED","labels":[{"name":"retro-action"},{"name":"Sprint 170"}]},
  {"number":404,"title":"issue delta","state":"CLOSED","labels":[{"name":"retro-action"},{"name":"Sprint 171"}]},
  {"number":405,"title":"issue epsilon","state":"OPEN","labels":[{"name":"retro-action"},{"name":"Sprint 172"}]},
  {"number":406,"title":"issue zeta","state":"CLOSED","labels":[{"name":"retro-action"},{"name":"Sprint 173"}]}
]'
GHEOF
chmod +x "$GH_STUB/gh"

TREND_OUT=$(PATH="$GH_STUB:$PATH" bash "$SCRIPT" 2>&1)
rm -rf "$GH_STUB"

# 應輸出 Sprint 趨勢區塊，顯示近 5 Sprint（168-173 中最近 5 個）
SPRINT_TREND_COUNT=$(echo "$TREND_OUT" | grep -cE "Sprint [0-9]+" || true)
if [[ "$SPRINT_TREND_COUNT" -ge 1 && "$SPRINT_TREND_COUNT" -le 5 ]]; then
  ok "T6a: trend output shows 1-5 sprint entries (got $SPRINT_TREND_COUNT)"
else
  fail "T6a: trend output unexpected sprint count: $SPRINT_TREND_COUNT (expected 1-5)"
fi

# 應有完成率格式（百分比或分數）
if echo "$TREND_OUT" | grep -qE "[0-9]+%|[0-9]+/[0-9]+"; then
  ok "T6b: trend output contains completion rate format"
else
  fail "T6b: trend output missing completion rate format"
fi

# ── T7: gh API 失敗時優雅降級 — 輸出 [WARN] ─────────────────────────────────
GH_STUB=$(mktemp -d)
cat > "$GH_STUB/gh" << 'GHEOF'
#!/usr/bin/env bash
echo "error: authentication required" >&2
exit 1
GHEOF
chmod +x "$GH_STUB/gh"

WARN_EXIT=0
WARN_OUT=$(PATH="$GH_STUB:$PATH" bash "$SCRIPT" 2>&1) || WARN_EXIT=$?
rm -rf "$GH_STUB"

# 腳本不應 crash（exit 0 或非嚴重錯誤），且應輸出 [WARN]
if [[ $WARN_EXIT -eq 0 ]]; then
  ok "T7a: gh API failure — script exits 0 (graceful degradation)"
else
  fail "T7a: gh API failure — script exited non-zero ($WARN_EXIT)"
fi

if echo "$WARN_OUT" | grep -q "\[WARN\]"; then
  ok "T7b: gh API failure — [WARN] marker present in output"
else
  fail "T7b: gh API failure — [WARN] marker missing from output"
fi

# ── T8: 執行時間 < 10s (NFR) ─────────────────────────────────────────────────
GH_STUB=$(mktemp -d)
cat > "$GH_STUB/gh" << 'GHEOF'
#!/usr/bin/env bash
echo '[{"number":501,"title":"perf test issue","state":"CLOSED","labels":[{"name":"retro-action"},{"name":"Sprint 173"}]}]'
GHEOF
chmod +x "$GH_STUB/gh"

START_NS=$(date +%s%N 2>/dev/null || echo 0)
PATH="$GH_STUB:$PATH" bash "$SCRIPT" >/dev/null 2>&1 || true
END_NS=$(date +%s%N 2>/dev/null || echo 10000000000)
ELAPSED_MS=$(( (END_NS - START_NS) / 1000000 ))
rm -rf "$GH_STUB"

if [[ "$ELAPSED_MS" -lt 10000 ]]; then
  ok "T8: execution time ${ELAPSED_MS}ms < 10000ms (NFR)"
else
  fail "T8: execution time ${ELAPSED_MS}ms >= 10000ms (NFR violated)"
fi

# ── T9: 整體輸出結構完整性 ───────────────────────────────────────────────────
# 使用 T2 的標準 fixture，驗證輸出包含預期區塊
GH_STUB=$(mktemp -d)
cat > "$GH_STUB/gh" << 'GHEOF'
#!/usr/bin/env bash
echo '[
  {"number":601,"title":"改善 CI pipeline 速度","state":"CLOSED","labels":[{"name":"retro-action"},{"name":"Sprint 170"}]},
  {"number":602,"title":"補充文件說明","state":"CLOSED","labels":[{"name":"retro-action"},{"name":"Sprint 170"}]},
  {"number":603,"title":"改善溝通效率","state":"OPEN","labels":[{"name":"retro-action"},{"name":"Sprint 171"}]}
]'
GHEOF
chmod +x "$GH_STUB/gh"

FULL_OUT=$(PATH="$GH_STUB:$PATH" bash "$SCRIPT" 2>&1)
rm -rf "$GH_STUB"

# 輸出應包含「完成率」相關詞彙
if echo "$FULL_OUT" | grep -qiE "完成率|completion|closed|total"; then
  ok "T9a: output contains completion rate section"
else
  fail "T9a: output missing completion rate section"
fi

# 輸出應包含「趨勢」或「trend」相關詞彙
if echo "$FULL_OUT" | grep -qiE "趨勢|trend|Sprint [0-9]+"; then
  ok "T9b: output contains trend section"
else
  fail "T9b: output missing trend section"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
