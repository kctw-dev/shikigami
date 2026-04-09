#!/usr/bin/env bash
# dispatch-preflight.sh — 派遣前 preflight 檢查：rule-ratio 強制閾值檢查 (Story #990)
#
# 機械化量測派遣給 subagent 的 full prompt 中規則片段的 token 佔比。
# 根據三段式硬性門檻進行阻斷或告警。
#
# 用法：
#   dispatch-preflight.sh --prompt <prompt_file> --story-id <story_id> [--output-log <log_file>]
#
# 退出碼：
#   0 — PASS 或 WARN（繼續派遣）
#   1 — BLOCK（拒絕派遣）
#
# 三段式門檻：
#   ratio >= 0.10 → PASS
#   0.05 <= ratio < 0.10 → WARN
#   ratio < 0.05 → BLOCK

set -euo pipefail

# ── 常數定義 ──

RULE_RATIO_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/rule-ratio-measure.sh"
THRESHOLD_PASS=0.10
THRESHOLD_WARN=0.05

# ── 使用說明 ──

usage() {
  cat >&2 <<'EOF'
Usage: dispatch-preflight.sh --prompt <file> --story-id <story_id> [--output-log <log_file>]

Required:
  --prompt <file>        Full prompt file (assembled by main session)
  --story-id <id>        Issue ID (e.g., #990)

Optional:
  --output-log <file>    Log file for recording the check result (default: docs/cruise-logs/dispatch-rule-ratio-<date>.jsonl)

Example:
  dispatch-preflight.sh --prompt /tmp/full-prompt.md --story-id '#990'

Thresholds (hard gates):
  ratio >= 0.10   → PASS (continue)
  0.05 ≤ ratio < 0.10 → WARN (log + continue)
  ratio < 0.05    → BLOCK (exit 1, refuse dispatch)
EOF
  exit 1
}

# ── 引數解析 ──

PROMPT_FILE=""
STORY_ID=""
OUTPUT_LOG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prompt)
      PROMPT_FILE="$2"
      shift 2
      ;;
    --story-id)
      STORY_ID="$2"
      shift 2
      ;;
    --output-log)
      OUTPUT_LOG="$2"
      shift 2
      ;;
    *)
      echo "[ERROR] Unknown option: $1" >&2
      usage
      ;;
  esac
done

if [[ -z "${PROMPT_FILE}" ]] || [[ -z "${STORY_ID}" ]]; then
  echo "[ERROR] Missing required options: --prompt and --story-id" >&2
  usage
fi

if [[ ! -f "${PROMPT_FILE}" ]]; then
  echo "[ERROR] Prompt file not found: ${PROMPT_FILE}" >&2
  exit 1
fi

if [[ ! -f "${RULE_RATIO_SCRIPT}" ]]; then
  echo "[ERROR] rule-ratio-measure.sh not found at: ${RULE_RATIO_SCRIPT}" >&2
  echo "[BLOCK] Fail-safe: script missing, refuse dispatch" >&2
  exit 1
fi

# ── 執行規則佔比量測 ──

echo "[PREFLIGHT] Measuring rule-ratio for ${STORY_ID}..."

MEASURE_OUTPUT=""
MEASURE_EXIT=0
if ! MEASURE_OUTPUT=$(bash "${RULE_RATIO_SCRIPT}" "${PROMPT_FILE}" 2>&1); then
  MEASURE_EXIT=$?
  echo "[ERROR] rule-ratio-measure.sh failed with exit code ${MEASURE_EXIT}" >&2
  echo "[BLOCK] Fail-safe: measure script failed, refuse dispatch" >&2
  exit 1
fi

# ── 解析量測結果 ──

RULE_TOKENS=$(echo "${MEASURE_OUTPUT}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['rule_tokens'])" 2>/dev/null || echo "0")
TOTAL_TOKENS=$(echo "${MEASURE_OUTPUT}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['total_tokens'])" 2>/dev/null || echo "0")
RATIO=$(echo "${MEASURE_OUTPUT}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['ratio'])" 2>/dev/null || echo "0.0")

if [[ -z "${RATIO}" ]] || [[ "${RATIO}" == "0.0" && "${TOTAL_TOKENS}" -eq 0 ]]; then
  echo "[ERROR] Failed to extract ratio from measure output" >&2
  echo "[BLOCK] Fail-safe: ratio parse failed, refuse dispatch" >&2
  exit 1
fi

# ── 判斷門檻級別 ──

THRESHOLD_LEVEL=""
ACTION=""

# 使用 awk 進行浮點比較（bash 不支援浮點運算）
THRESHOLD_LEVEL=$(awk -v r="${RATIO}" \
  "BEGIN {
    if (r >= 0.10) print \"PASS\"
    else if (r >= 0.05) print \"WARN\"
    else print \"BLOCK\"
  }")

case "${THRESHOLD_LEVEL}" in
  PASS)
    ACTION="continue"
    echo "[PASS] Rule ratio ${RATIO} >= 0.10 (threshold PASS)"
    ;;
  WARN)
    ACTION="continue"
    echo "[WARN] Rule ratio ${RATIO} is between 0.05-0.10 (threshold WARN)"
    >&2 echo "[WARN] Rule ratio below optimal (0.10), but continuing dispatch"
    ;;
  BLOCK)
    ACTION="block"
    echo "[BLOCK] Rule ratio ${RATIO} < 0.05 (threshold BLOCK, refuse dispatch)"
    >&2 echo "[ERROR] Dispatch blocked: rule ratio ${RATIO} below 0.05 threshold"
    ;;
esac

# ── 寫入 Log 紀錄 ──

if [[ -z "${OUTPUT_LOG}" ]]; then
  # 預設路徑：docs/cruise-logs/dispatch-rule-ratio-YYYY-MM-DD.jsonl
  SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  LOG_DIR="${SCRIPT_ROOT}/docs/cruise-logs"
  mkdir -p "${LOG_DIR}"
  OUTPUT_LOG="${LOG_DIR}/dispatch-rule-ratio-$(date +%Y-%m-%d).jsonl"
fi

# 組織 timestamp（ISO-8601）
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 組織 log entry（JSONL 格式）
cat >> "${OUTPUT_LOG}" <<LOG_ENTRY
{
  "timestamp": "${TIMESTAMP}",
  "story_id": "${STORY_ID}",
  "prompt_size_chars": $(wc -c < "${PROMPT_FILE}"),
  "rule_tokens": ${RULE_TOKENS},
  "total_tokens": ${TOTAL_TOKENS},
  "ratio": ${RATIO},
  "threshold": "${THRESHOLD_LEVEL}",
  "action": "${ACTION}"
}
LOG_ENTRY

echo "[PREFLIGHT-LOG] Recorded to ${OUTPUT_LOG}"

# ── 根據門檻級別決定是否阻斷 ──

if [[ "${THRESHOLD_LEVEL}" == "BLOCK" ]]; then
  exit 1
fi

exit 0
