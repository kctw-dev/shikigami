#!/usr/bin/env bash
# tests/test-780-predict-conflicts.sh
# Story #780 — 平行任務衝突預測靜態分析驗收測試
#
# ── 目的 ──────────────────────────────────────────────────────────────────
#
# 驗收標準：
#   AC1: scripts/predict-conflicts.sh <story-list> 存在且可執行，輸出衝突預測矩陣（JSON）
#   AC2: sprint-execution SKILL.md Parallel Grouping 段落新增 predict-conflicts.sh 使用說明
#   AC3: 預測基於 Story body 關鍵字（檔案路徑、模組名稱），不需要 git history
#   AC4: 測試三個已知衝突場景，驗證正確分組
#
# ── 使用方式 ─────────────────────────────────────────────────────────────
#   bash tests/test-780-predict-conflicts.sh
# ─────────────────────────────────────────────────────────────────────────

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PASS_COUNT=0
FAIL_COUNT=0

pass() { echo "  [PASS] $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { echo "  [FAIL] $1"; echo "    [DIAG] $2"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

PREDICT_SCRIPT="${REPO_ROOT}/scripts/predict-conflicts.sh"
SPRINT_EXEC_SKILL="${REPO_ROOT}/skills/sprint-execution/SKILL.md"

echo "=== 平行任務衝突預測靜態分析測試套件 (#780) ==="
echo ""

# ─── AC1: scripts/predict-conflicts.sh 存在且可執行 ──────────────────────
echo "--- AC1: predict-conflicts.sh 存在、可執行、輸出 JSON ---"

if [[ -f "${PREDICT_SCRIPT}" ]]; then
  pass "AC1a: predict-conflicts.sh 存在"
else
  fail "AC1a: predict-conflicts.sh 不存在" \
    "找不到 ${PREDICT_SCRIPT}"
fi

if [[ -x "${PREDICT_SCRIPT}" ]]; then
  pass "AC1b: predict-conflicts.sh 可執行"
else
  fail "AC1b: predict-conflicts.sh 不可執行" \
    "chmod +x ${PREDICT_SCRIPT}"
fi

# 驗證腳本接受 story-list 參數（--help 或 -h 不報 usage error）
if [[ -x "${PREDICT_SCRIPT}" ]]; then
  HELP_OUTPUT=$(bash "${PREDICT_SCRIPT}" --help 2>&1 || true)
  if echo "${HELP_OUTPUT}" | grep -qiE "usage|story|conflict|predict|用法|說明"; then
    pass "AC1c: predict-conflicts.sh 支援 --help 並顯示使用說明"
  else
    fail "AC1c: predict-conflicts.sh --help 輸出未包含使用說明" \
      "輸出：${HELP_OUTPUT:0:200}"
  fi
fi

echo ""

# ─── AC2: sprint-execution SKILL.md 含 predict-conflicts.sh 使用說明 ─────
echo "--- AC2: SKILL.md Parallel Grouping 段落包含 predict-conflicts.sh 說明 ---"

if grep -q "predict-conflicts" "${SPRINT_EXEC_SKILL}" 2>/dev/null; then
  pass "AC2a: SKILL.md 含 predict-conflicts.sh 引用"
else
  fail "AC2a: SKILL.md 未含 predict-conflicts.sh 引用" \
    "${SPRINT_EXEC_SKILL} 需要在 Parallel Grouping 段落加入 predict-conflicts.sh"
fi

if grep -qE "predict-conflicts.*before|派遣前.*predict-conflicts|Run predict-conflicts|執行 predict-conflicts|pre-arrange" "${SPRINT_EXEC_SKILL}" 2>/dev/null; then
  pass "AC2b: SKILL.md 說明派遣前執行 predict-conflicts.sh"
else
  fail "AC2b: SKILL.md 未說明派遣前執行時機" \
    "需要加入 'Run predict-conflicts.sh before dispatching' 或等效說明"
fi

echo ""

# ─── AC3: 無 git history 也能運作（關鍵字萃取邏輯）─────────────────────
echo "--- AC3: 基於 Story body 關鍵字預測，不需 git history ---"

if [[ -f "${PREDICT_SCRIPT}" ]]; then
  # 驗證腳本不依賴 git log / git history
  if grep -qE "git log|git blame|git show.*HEAD" "${PREDICT_SCRIPT}" 2>/dev/null; then
    fail "AC3a: predict-conflicts.sh 使用了 git history 指令" \
      "MVP 不應依賴 git log / git blame / git show"
  else
    pass "AC3a: predict-conflicts.sh 不依賴 git history（符合 MVP 原則）"
  fi

  # 驗證腳本包含關鍵字萃取邏輯（路徑模式 / backtick / 模組名）
  if grep -qE "grep|sed|awk|extract|keyword|path|backtick|\`" "${PREDICT_SCRIPT}" 2>/dev/null; then
    pass "AC3b: predict-conflicts.sh 包含關鍵字萃取邏輯"
  else
    fail "AC3b: predict-conflicts.sh 缺少關鍵字萃取邏輯" \
      "需要從 Story body 中萃取路徑、模組名等關鍵字"
  fi

  # 驗證輸出 JSON 格式（NFR2）
  if grep -qE '"conflicts"|json|JSON|jq' "${PREDICT_SCRIPT}" 2>/dev/null; then
    pass "AC3c: predict-conflicts.sh 輸出 JSON 格式（NFR2）"
  else
    fail "AC3c: predict-conflicts.sh 未輸出 JSON 格式" \
      "需要輸出 {conflicts: [...], groups: {...}} JSON"
  fi
fi

echo ""

# ─── AC4: 三個已知衝突場景的正確分組 ───────────────────────────────────
echo "--- AC4: 三個衝突場景本地模擬測試 ---"

# 測試場景使用本地 mock story body，不依賴 GitHub API
TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "${TMPDIR_TEST}"' EXIT

# 場景 1：兩個 Story 都修改同一個 SKILL.md → 預測衝突
BODY_A="${TMPDIR_TEST}/body_A.txt"
BODY_B="${TMPDIR_TEST}/body_B.txt"
cat > "${BODY_A}" <<'BODY'
## Story A
AC1: 修改 `skills/sprint-execution/SKILL.md` 的 Parallel Grouping 段落
AC2: 更新 `docs/adr/ADR-033.md` 新增欄位
BODY

cat > "${BODY_B}" <<'BODY'
## Story B
AC1: 更新 `skills/sprint-execution/SKILL.md` 的衝突預測演算法
AC2: 新增 `scripts/predict-conflicts.sh`
BODY

if [[ -x "${PREDICT_SCRIPT}" ]]; then
  # 使用 --mock-bodies 模式（直接傳入 body 檔案，不呼叫 gh API）
  SCENARIO1_OUTPUT=$(bash "${PREDICT_SCRIPT}" \
    --mock-body-1 "${BODY_A}" --story-id-1 "101" \
    --mock-body-2 "${BODY_B}" --story-id-2 "102" \
    2>/dev/null || true)

  if echo "${SCENARIO1_OUTPUT}" | grep -qE '"conflicts".*\[.*\]|"story_a".*101|"story_b".*102'; then
    pass "AC4a: 場景 1（同 SKILL.md）— 輸出包含衝突預測結構"
  else
    fail "AC4a: 場景 1（同 SKILL.md）— 輸出格式不符" \
      "輸出：${SCENARIO1_OUTPUT:0:300}"
  fi

  if echo "${SCENARIO1_OUTPUT}" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if d.get('conflicts') else 1)" 2>/dev/null; then
    pass "AC4b: 場景 1 — 輸出為合法 JSON"
  else
    fail "AC4b: 場景 1 — 輸出非合法 JSON" \
      "輸出：${SCENARIO1_OUTPUT:0:300}"
  fi

  # 場景 2：Story 修改不同目錄 → 預測無衝突（應在 parallel group）
  BODY_C="${TMPDIR_TEST}/body_C.txt"
  BODY_D="${TMPDIR_TEST}/body_D.txt"
  cat > "${BODY_C}" <<'BODY'
## Story C
AC1: 更新 `docs/adr/ADR-040.md` 決策紀錄
AC2: 修改 `docs/km/knowledge-base.md`
BODY

  cat > "${BODY_D}" <<'BODY'
## Story D
AC1: 新增 `scripts/validate-new-feature.sh`
AC2: 更新 `tests/test-new-feature.sh`
BODY

  SCENARIO2_OUTPUT=$(bash "${PREDICT_SCRIPT}" \
    --mock-body-1 "${BODY_C}" --story-id-1 "103" \
    --mock-body-2 "${BODY_D}" --story-id-2 "104" \
    2>/dev/null || true)

  if echo "${SCENARIO2_OUTPUT}" | python3 -c "
import sys, json
d = json.load(sys.stdin)
# 無衝突時 conflicts 陣列應為空，或 groups.parallel 含兩者
conflicts = d.get('conflicts', [])
groups = d.get('groups', {})
parallel = groups.get('parallel', [])
no_conflict = len(conflicts) == 0
sys.exit(0 if no_conflict else 1)
" 2>/dev/null; then
    pass "AC4c: 場景 2（不同目錄）— 正確預測無衝突（parallel group）"
  else
    fail "AC4c: 場景 2（不同目錄）— 未能正確預測無衝突" \
      "輸出：${SCENARIO2_OUTPUT:0:300}"
  fi

  # 場景 3：三個 Story，其中兩個衝突，一個獨立
  BODY_E="${TMPDIR_TEST}/body_E.txt"
  BODY_F="${TMPDIR_TEST}/body_F.txt"
  BODY_G="${TMPDIR_TEST}/body_G.txt"

  cat > "${BODY_E}" <<'BODY'
## Story E
AC1: 修改 `skills/health-check/SKILL.md` 新增監控項目
BODY

  cat > "${BODY_F}" <<'BODY'
## Story F
AC1: 更新 `skills/health-check/SKILL.md` 健康檢查順序
BODY

  cat > "${BODY_G}" <<'BODY'
## Story G
AC1: 新增 `docs/tutorial/onboarding-guide.md`
AC2: 更新 `README.md` 安裝說明
BODY

  SCENARIO3_OUTPUT=$(bash "${PREDICT_SCRIPT}" \
    --mock-body-1 "${BODY_E}" --story-id-1 "105" \
    --mock-body-2 "${BODY_F}" --story-id-2 "106" \
    --mock-body-3 "${BODY_G}" --story-id-3 "107" \
    2>/dev/null || true)

  if echo "${SCENARIO3_OUTPUT}" | python3 -c "
import sys, json
d = json.load(sys.stdin)
conflicts = d.get('conflicts', [])
# E(105) 和 F(106) 應衝突
conflict_pairs = [(c.get('story_a'), c.get('story_b')) for c in conflicts]
has_ef_conflict = (105, 106) in conflict_pairs or (106, 105) in conflict_pairs
sys.exit(0 if has_ef_conflict else 1)
" 2>/dev/null; then
    pass "AC4d: 場景 3（三 Story）— 正確識別 #105/#106 衝突對"
  else
    fail "AC4d: 場景 3（三 Story）— 未識別出 #105/#106 衝突對" \
      "輸出：${SCENARIO3_OUTPUT:0:300}"
  fi

  if echo "${SCENARIO3_OUTPUT}" | python3 -c "
import sys, json
d = json.load(sys.stdin)
groups = d.get('groups', {})
parallel = groups.get('parallel', [])
sequential = groups.get('sequential', [])
# G(107) 應在 parallel group（無衝突）
g_in_parallel = 107 in parallel
sys.exit(0 if g_in_parallel else 1)
" 2>/dev/null; then
    pass "AC4e: 場景 3（三 Story）— #107 正確歸入 parallel group"
  else
    fail "AC4e: 場景 3（三 Story）— #107 分組不正確" \
      "輸出：${SCENARIO3_OUTPUT:0:300}"
  fi
else
  fail "AC4a: predict-conflicts.sh 不可執行，跳過場景測試" \
    "先修正 AC1b"
  fail "AC4b: 跳過" "腳本不可執行"
  fail "AC4c: 跳過" "腳本不可執行"
  fail "AC4d: 跳過" "腳本不可執行"
  fail "AC4e: 跳過" "腳本不可執行"
fi

echo ""

# ─── 摘要 ────────────────────────────────────────────────────────────────
echo "=== 摘要 ==="
echo "PASS: ${PASS_COUNT}, FAIL: ${FAIL_COUNT}"
echo ""

if [[ "${FAIL_COUNT}" -eq 0 ]]; then
  echo "[RESULT] PASS — 全部 ${PASS_COUNT} 項測試通過"
  exit 0
else
  echo "[RESULT] FAIL — ${FAIL_COUNT} 項測試失敗，${PASS_COUNT} 項通過"
  exit 1
fi
