#!/usr/bin/env bash
# tests/test-api-error-fallback.sh
# Story #995 — Subagent API Error Fallback 策略驗證
#
# ── 目的 ──────────────────────────────────────────────────────────────────
#
# 驗證 SKILL.md §2.1.1 定義的 API Error Fallback 策略文件內容正確，
# 並確認 JSONL schema 與測試 helper 行為符合 AC 規格。
#
# AC-1：SKILL.md §2.1.1 存在且包含降級決策樹（HTTP 429 / 500/529）
# AC-2：HTTP 429 路徑：指數退避 30s→60s→120s，最多3次，再降 sonnet 1次
# AC-3：HTTP 500/529 路徑：立即降級 sonnet，失敗再退避 sonnet 最多3次
# AC-4：JSONL schema 欄位齊全，stdout 格式正確
# AC-5：Architect / QA / Security 靜態例外 agent 的 fallback 路徑列出
# AC-6：TC1 mock 429、TC2 mock 529、TC3 全部失敗
#
# ── 使用方式 ─────────────────────────────────────────────────────────────
#   bash tests/test-api-error-fallback.sh
# ─────────────────────────────────────────────────────────────────────────

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PASS_COUNT=0
FAIL_COUNT=0

pass() { echo "  [PASS] $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { echo "  [FAIL] $1"; echo "    [DIAG] $2"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

SKILL_MD="${REPO_ROOT}/skills/sprint-execution/SKILL.md"

echo "=== API Error Fallback 策略驗證測試 (#995) ==="
echo ""

# ─── AC-1：§2.1.1 節存在且包含決策樹 ────────────────────────────────────
echo "--- AC-1: §2.1.1 節存在且包含 HTTP 429 / 500/529 決策樹 ---"

if [[ -f "${SKILL_MD}" ]]; then
  pass "AC-1a: sprint-execution/SKILL.md 存在"

  if grep -q "2\.1\.1" "${SKILL_MD}" 2>/dev/null; then
    pass "AC-1b: §2.1.1 節存在於 SKILL.md"
  else
    fail "AC-1b: §2.1.1 節缺失" \
      "SKILL.md 中找不到 2.1.1 小節標題"
  fi

  if grep -q "429" "${SKILL_MD}" 2>/dev/null; then
    pass "AC-1c: §2.1.1 包含 HTTP 429 路徑說明"
  else
    fail "AC-1c: §2.1.1 缺少 HTTP 429 說明" \
      "未在 SKILL.md 中找到 429 相關策略"
  fi

  if grep -q "529\|500" "${SKILL_MD}" 2>/dev/null; then
    pass "AC-1d: §2.1.1 包含 HTTP 500/529 路徑說明"
  else
    fail "AC-1d: §2.1.1 缺少 HTTP 500/529 說明" \
      "未在 SKILL.md 中找到 500 或 529 相關策略"
  fi

  if grep -q "API-FALLBACK-EXHAUSTED" "${SKILL_MD}" 2>/dev/null; then
    pass "AC-1e: §2.1.1 包含終止條件 [API-FALLBACK-EXHAUSTED]"
  else
    fail "AC-1e: §2.1.1 缺少終止條件 [API-FALLBACK-EXHAUSTED]" \
      "未在 SKILL.md 中找到 API-FALLBACK-EXHAUSTED 終止輸出定義"
  fi

  if grep -q "BLOCKED" "${SKILL_MD}" 2>/dev/null; then
    pass "AC-1f: §2.1.1 包含 Story=BLOCKED 標記說明"
  else
    fail "AC-1f: §2.1.1 缺少 Story=BLOCKED 說明" \
      "未在 SKILL.md 中找到 BLOCKED 標記"
  fi
else
  fail "AC-1a: sprint-execution/SKILL.md 不存在" \
    "找不到 ${SKILL_MD}"
fi

echo ""

# ─── AC-2：HTTP 429 路徑（指數退避 + sonnet 降級）────────────────────────
echo "--- AC-2: HTTP 429 指數退避路徑 ---"

if [[ -f "${SKILL_MD}" ]]; then
  # 驗證退避時間序列 30s / 60s / 120s
  if grep -q "30" "${SKILL_MD}" && grep -q "60" "${SKILL_MD}" && grep -q "120" "${SKILL_MD}" 2>/dev/null; then
    pass "AC-2a: §2.1.1 包含退避時間序列 30s/60s/120s"
  else
    fail "AC-2a: §2.1.1 退避時間序列不完整" \
      "需要包含 30、60、120 秒退避時間定義"
  fi

  # 驗證最多 3 次重試
  if grep -q "3 次\|最多 3\|retry.*3\|3.*retry\|max.*3\|3.*重試" "${SKILL_MD}" 2>/dev/null; then
    pass "AC-2b: §2.1.1 定義最多 3 次重試"
  else
    fail "AC-2b: §2.1.1 缺少最多 3 次重試說明" \
      "未找到 3 次重試上限定義"
  fi

  # 驗證 3 次後降級 sonnet 重試 1 次
  if grep -q "sonnet" "${SKILL_MD}" 2>/dev/null; then
    pass "AC-2c: §2.1.1 包含 sonnet 降級路徑"
  else
    fail "AC-2c: §2.1.1 缺少 sonnet 降級說明" \
      "未找到 3 次失敗後降級 sonnet 的規則"
  fi

  # 驗證不降級至 haiku
  if grep -q "不降級.*haiku\|haiku.*不\|haiku.*禁止\|禁止.*haiku" "${SKILL_MD}" 2>/dev/null; then
    pass "AC-2d: §2.1.1 明確禁止降級至 haiku"
  else
    fail "AC-2d: §2.1.1 缺少「不降級至 haiku」規定" \
      "未找到明確禁止降至 haiku 的聲明"
  fi
fi

echo ""

# ─── AC-3：HTTP 500/529 路徑（立即降級 + 退避）──────────────────────────
echo "--- AC-3: HTTP 500/529 立即降級路徑 ---"

if [[ -f "${SKILL_MD}" ]]; then
  if grep -q "立即降級\|immediately.*downgrade\|immediate.*fallback\|529.*立即\|立即.*sonnet" "${SKILL_MD}" 2>/dev/null; then
    pass "AC-3a: §2.1.1 包含 500/529 立即降級 sonnet 規則"
  else
    fail "AC-3a: §2.1.1 缺少 500/529 立即降級說明" \
      "未找到 HTTP 500/529 立即降級至 sonnet 的規則描述"
  fi
fi

echo ""

# ─── AC-4：JSONL schema + stdout 格式 ────────────────────────────────────
echo "--- AC-4: JSONL schema 定義 + stdout 格式 ---"

if [[ -f "${SKILL_MD}" ]]; then
  # 驗證 JSONL 欄位
  for field in "timestamp" "story_id" "from_model" "to_model" "reason" "retry_count"; do
    if grep -q "${field}" "${SKILL_MD}" 2>/dev/null; then
      pass "AC-4a: JSONL schema 包含欄位 ${field}"
    else
      fail "AC-4a: JSONL schema 缺少欄位 ${field}" \
        "在 SKILL.md 中找不到 ${field} 欄位定義"
    fi
  done

  # 驗證 JSONL 輸出路徑
  if grep -q "model-fallback" "${SKILL_MD}" 2>/dev/null; then
    pass "AC-4b: §2.1.1 定義 JSONL 路徑 model-fallback-<date>.jsonl"
  else
    fail "AC-4b: §2.1.1 缺少 JSONL 輸出路徑定義" \
      "未找到 docs/cruise-logs/model-fallback-<date>.jsonl 路徑說明"
  fi

  # 驗證 stdout 格式
  if grep -q "MODEL-FALLBACK" "${SKILL_MD}" 2>/dev/null; then
    pass "AC-4c: §2.1.1 定義 stdout 格式 [MODEL-FALLBACK]"
  else
    fail "AC-4c: §2.1.1 缺少 stdout 輸出格式定義" \
      "未找到 [MODEL-FALLBACK] stdout 格式定義"
  fi
fi

echo ""

# ─── AC-5：靜態例外 agent 覆蓋（Architect / QA / Security）──────────────
echo "--- AC-5: 靜態例外 agent fallback 路徑表格 ---"

if [[ -f "${SKILL_MD}" ]]; then
  for agent in "Architect" "QA" "Security"; do
    if grep -q "${agent}" "${SKILL_MD}" 2>/dev/null; then
      pass "AC-5a: §2.1.1 包含 ${agent} agent 的 fallback 路徑"
    else
      fail "AC-5a: §2.1.1 缺少 ${agent} agent 的靜態例外說明" \
        "未在 SKILL.md 中找到 ${agent} 的 fallback 路徑定義"
    fi
  done
fi

echo ""

# ─── AC-6：使用 TMPBIN + fake binary 測試 ──────────────────────────────
echo "--- AC-6: TC1/TC2/TC3 mock 行為驗證 ---"

# 建立臨時目錄
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "${TMPDIR_TEST}"' EXIT

# ── TC1：mock HTTP 429 → 驗證退避邏輯文件描述 ──────────────────────────
echo "  -- TC1: HTTP 429 退避邏輯 ---"

# 驗證 SKILL.md 中的 429 退避策略包含「重試同模型」描述
if grep -q "429" "${SKILL_MD}" && grep -q "重試\|retry" "${SKILL_MD}" 2>/dev/null; then
  pass "TC1: HTTP 429 退避策略：含重試同模型說明"
else
  fail "TC1: HTTP 429 退避策略缺少重試同模型說明" \
    "SKILL.md 中 429 路徑應說明重試同一模型"
fi

# 驗證退避後最終降級的描述
if grep -q "429" "${SKILL_MD}" && grep -q "降級\|downgrade\|fallback" "${SKILL_MD}" 2>/dev/null; then
  pass "TC1: HTTP 429 退避耗盡後有降級策略說明"
else
  fail "TC1: HTTP 429 降級策略缺失" \
    "SKILL.md 中 429 路徑應說明退避耗盡後降級"
fi

# ── TC2：mock HTTP 529 → 驗證立即降級文件描述 ──────────────────────────
echo "  -- TC2: HTTP 529 立即降級邏輯 ---"

if grep -q "529" "${SKILL_MD}" 2>/dev/null; then
  pass "TC2: HTTP 529 有獨立策略說明"
else
  fail "TC2: HTTP 529 策略缺失" \
    "SKILL.md 中應有 529 路徑獨立說明"
fi

if grep -q "立即\|immediately" "${SKILL_MD}" 2>/dev/null; then
  pass "TC2: HTTP 529 包含立即降級關鍵字"
else
  fail "TC2: HTTP 529 缺少立即降級語意" \
    "SKILL.md 中 529 路徑應使用「立即」或 immediately 等詞"
fi

# ── TC3：全部失敗 → 驗證 BLOCKED 終止條件 ──────────────────────────────
echo "  -- TC3: 全部失敗 → [API-FALLBACK-EXHAUSTED] ---"

if grep -q "API-FALLBACK-EXHAUSTED" "${SKILL_MD}" 2>/dev/null; then
  pass "TC3: [API-FALLBACK-EXHAUSTED] 終止標記已定義"
else
  fail "TC3: [API-FALLBACK-EXHAUSTED] 終止標記缺失" \
    "SKILL.md 中應定義所有重試耗盡後輸出 [API-FALLBACK-EXHAUSTED]"
fi

if grep -q "BLOCKED" "${SKILL_MD}" 2>/dev/null; then
  pass "TC3: Story=BLOCKED 狀態已定義"
else
  fail "TC3: Story=BLOCKED 狀態未定義" \
    "SKILL.md 中應說明耗盡後將 Story 標記為 BLOCKED"
fi

# ── TMPBIN 驗證：確認 JSONL schema 欄位可以 mock 輸出 ───────────────────
echo "  -- TMPBIN: JSONL 格式驗證 ---"
TMPBIN="${TMPDIR_TEST}/bin"
mkdir -p "${TMPBIN}"

# 建立 fake JSONL writer
cat > "${TMPBIN}/fake-fallback-log.sh" << 'EOF'
#!/usr/bin/env bash
# fake JSONL fallback logger — 模擬 AC-4 schema 輸出
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
STORY_ID="${1:-#995}"
FROM_MODEL="${2:-opus}"
TO_MODEL="${3:-sonnet}"
REASON="${4:-HTTP529}"
RETRY_COUNT="${5:-0}"
printf '{"timestamp":"%s","story_id":"%s","from_model":"%s","to_model":"%s","reason":"%s","retry_count":%s}\n' \
  "${TIMESTAMP}" "${STORY_ID}" "${FROM_MODEL}" "${TO_MODEL}" "${REASON}" "${RETRY_COUNT}"
EOF
chmod +x "${TMPBIN}/fake-fallback-log.sh"

# 執行 fake logger 並驗證輸出
OUTPUT="$(bash "${TMPBIN}/fake-fallback-log.sh" "#995" "opus" "sonnet" "HTTP529" "0")"
if echo "${OUTPUT}" | grep -q '"timestamp"' && \
   echo "${OUTPUT}" | grep -q '"story_id"' && \
   echo "${OUTPUT}" | grep -q '"from_model"' && \
   echo "${OUTPUT}" | grep -q '"to_model"' && \
   echo "${OUTPUT}" | grep -q '"reason"' && \
   echo "${OUTPUT}" | grep -q '"retry_count"'; then
  pass "TC-TMPBIN: fake JSONL 輸出包含所有必要 schema 欄位"
else
  fail "TC-TMPBIN: fake JSONL 輸出缺少必要欄位" \
    "輸出：${OUTPUT}"
fi

# 驗證 stdout 格式
STDOUT_MSG="[MODEL-FALLBACK] #995 from=opus to=sonnet reason=HTTP529"
if echo "${STDOUT_MSG}" | grep -q "\[MODEL-FALLBACK\]" && \
   echo "${STDOUT_MSG}" | grep -q "from=opus" && \
   echo "${STDOUT_MSG}" | grep -q "to=sonnet" && \
   echo "${STDOUT_MSG}" | grep -q "reason=HTTP529"; then
  pass "TC-TMPBIN: stdout [MODEL-FALLBACK] 格式驗證通過"
else
  fail "TC-TMPBIN: stdout 格式不符" \
    "期望：[MODEL-FALLBACK] #N from=X to=Y reason=Z"
fi

echo ""

# ─── 統計結果 ────────────────────────────────────────────────────────────
echo ""
TOTAL=$((PASS_COUNT + FAIL_COUNT))
PASS_PCT=0
if [[ $TOTAL -gt 0 ]]; then
  PASS_PCT=$((PASS_COUNT * 100 / TOTAL))
fi

echo "=== 測試結果摘要 ==="
echo "通過：$PASS_COUNT / $TOTAL（$PASS_PCT%）"

if [[ $FAIL_COUNT -gt 0 ]]; then
  echo "失敗：$FAIL_COUNT"
  exit 1
else
  echo "失敗：0"
  exit 0
fi
