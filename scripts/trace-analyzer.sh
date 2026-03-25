#!/usr/bin/env bash
# trace-analyzer.sh — #782 Structured Trace Log 分析工具
#
# 用途（Post-hoc analysis，非 Sprint 中執行）：
#   讀取 cruise log JSONL，篩選 [TRACE] 條目，
#   按 Story 分組輸出 action timeline 與統計摘要。
#
# NFR2: 本工具為後分析（post-hoc）用途，不在 Sprint 執行期間載入，永不阻塞執行路徑。
#
# 使用方式：
#   bash scripts/trace-analyzer.sh <session-id>
#   CRUISE_LOG_DIR=<dir> bash scripts/trace-analyzer.sh <session-id>
#
# 環境變數：
#   CRUISE_LOG_DIR  — cruise log 目錄（預設：docs/cruise-logs）

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 預設 cruise log 目錄（可透過環境變數覆蓋，用於測試）
CRUISE_LOG_DIR="${CRUISE_LOG_DIR:-${REPO_ROOT}/docs/cruise-logs}"

# ── 用法說明 ─────────────────────────────────────────────────────────────

usage() {
  cat <<USAGE
用法：bash scripts/trace-analyzer.sh <session-id>

  <session-id>    cruise log 的 session 識別碼

  讀取 CRUISE_LOG_DIR（預設：docs/cruise-logs）中符合
  *-session-<session-id>.jsonl 的檔案，篩選 [TRACE] 條目，
  輸出每個 Story 的 action timeline 與統計摘要。

環境變數：
  CRUISE_LOG_DIR  覆蓋 cruise log 目錄路徑（用於測試）

範例：
  bash scripts/trace-analyzer.sh 20260325-153501
  CRUISE_LOG_DIR=/tmp/test-logs bash scripts/trace-analyzer.sh test-session

USAGE
}

# ── 參數檢查 ──────────────────────────────────────────────────────────────

if [[ $# -eq 0 ]]; then
  usage >&2
  exit 1
fi

SESSION_ID="$1"

# ── 找出對應的 JSONL 檔案 ─────────────────────────────────────────────────

JSONL_FILE=""

# 精確比對：*-session-<session-id>.jsonl
if ls "${CRUISE_LOG_DIR}"/*-session-"${SESSION_ID}".jsonl 2>/dev/null | head -1 | grep -q .; then
  JSONL_FILE="$(ls "${CRUISE_LOG_DIR}"/*-session-"${SESSION_ID}".jsonl 2>/dev/null | head -1)"
fi

# 若找不到，嘗試模糊比對（session-id 為部分字串）
if [[ -z "${JSONL_FILE}" ]]; then
  JSONL_FILE="$(ls "${CRUISE_LOG_DIR}"/*"${SESSION_ID}"*.jsonl 2>/dev/null | head -1 || true)"
fi

if [[ -z "${JSONL_FILE}" ]] || [[ ! -f "${JSONL_FILE}" ]]; then
  echo "[ERROR] 找不到 session '${SESSION_ID}' 的 cruise log JSONL 檔案" >&2
  echo "        搜尋目錄：${CRUISE_LOG_DIR}" >&2
  echo "        請確認 session-id 正確，或設定 CRUISE_LOG_DIR 環境變數" >&2
  exit 1
fi

# ── 擷取 [TRACE] 條目 ─────────────────────────────────────────────────────

# 從 JSONL 中篩選含 [TRACE] 的行，提取 JSON 部分
TRACE_LINES="$(grep '^\[TRACE\]' "${JSONL_FILE}" || true)"

if [[ -z "${TRACE_LINES}" ]]; then
  echo "=== Trace Analyzer — Session: ${SESSION_ID} ==="
  echo ""
  echo "[INFO] 此 session 的 cruise log 無 [TRACE] 條目"
  echo "       檔案：${JSONL_FILE}"
  exit 0
fi

# ── 解析並分組 ────────────────────────────────────────────────────────────

# 取得所有出現的 story ID（去重排序）
# [TRACE] {"type":"...","story":782,...}  =>  抽出 "story":N 的 N
STORY_IDS="$(echo "${TRACE_LINES}" | grep -oE '"story":[0-9]+' | grep -oE '[0-9]+' | sort -un)"

# ── 輸出 ─────────────────────────────────────────────────────────────────

echo "=== Trace Analyzer — Session: ${SESSION_ID} ==="
echo "    來源檔案：$(basename "${JSONL_FILE}")"
echo ""

for STORY_NUM in ${STORY_IDS}; do
  # 篩選本 Story 的所有 TRACE 條目
  STORY_TRACES="$(echo "${TRACE_LINES}" | grep "\"story\":${STORY_NUM}[^0-9]")"

  # 統計各動作類型數量（grep -c 回傳 0 時 exit code 為 1，用 || true 避免 pipefail）
  TOTAL=$(echo "${STORY_TRACES}" | wc -l | tr -d ' ')
  FILE_WRITE=$(echo "${STORY_TRACES}" | grep -c '"action":"file-write"' || true)
  FILE_READ=$(echo "${STORY_TRACES}" | grep -c '"action":"file-read"' || true)
  TEST_RUN=$(echo "${STORY_TRACES}" | grep -c '"action":"test-run"' || true)
  REVIEW_START=$(echo "${STORY_TRACES}" | grep -c '"action":"review-start"' || true)
  REVIEW_COMPLETE=$(echo "${STORY_TRACES}" | grep -c '"action":"review-complete"' || true)
  DECISION=$(echo "${STORY_TRACES}" | grep -c '"action":"decision"' || true)
  ERROR_COUNT=$(echo "${STORY_TRACES}" | grep -c '"action":"error"' || true)

  echo "┌─ Story ${STORY_NUM} ─────────────────────────────────────────"
  echo "│  total actions：${TOTAL}"
  echo "│  file-write：${FILE_WRITE}   file-read：${FILE_READ}"
  echo "│  test-run：${TEST_RUN}   review-start：${REVIEW_START}   review-complete：${REVIEW_COMPLETE}"
  echo "│  decision：${DECISION}   error：${ERROR_COUNT}"
  echo "│"
  echo "│  Action Timeline："

  # 輸出每筆 TRACE 條目（timestamp + actor + action + target）
  while IFS= read -r LINE; do
    JSON_PART="${LINE#\[TRACE\] }"

    # 擷取各欄位（使用 grep，不依賴 jq）
    TS="$(echo "${JSON_PART}" | grep -oE '"timestamp":"[^"]*"' | head -1 | sed 's/"timestamp":"//;s/"//')"
    ACTOR="$(echo "${JSON_PART}" | grep -oE '"actor":"[^"]*"' | head -1 | sed 's/"actor":"//;s/"//')"
    ACTION="$(echo "${JSON_PART}" | grep -oE '"action":"[^"]*"' | head -1 | sed 's/"action":"//;s/"//')"
    TARGET="$(echo "${JSON_PART}" | grep -oE '"target":"[^"]*"' | head -1 | sed 's/"target":"//;s/"//')"

    printf "│    [%s] %s (%s) => %s\n" \
      "${TS:-unknown}" \
      "${ACTION:-unknown}" \
      "${ACTOR:-unknown}" \
      "${TARGET:-unknown}"
  done <<< "${STORY_TRACES}"

  echo "└──────────────────────────────────────────────────────────"
  echo ""
done

echo "=== 分析完成 ==="
