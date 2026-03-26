#!/usr/bin/env bash
# scripts/check-backlog-health.sh
# Story #944: 自動化 sprint-candidate 水位週期性監控機制
#
# 讀取 sprint-candidate 水位，低於閾值時輸出 [BACKLOG-REPLENISH-TRIGGER]
# 可被 CI workflow 捕捉並觸發補充動作
#
# Usage:
#   bash scripts/check-backlog-health.sh [options]
#
# Options:
#   --threshold N        水位閾值（預設 10）    [AC4]
#   --dry-run            使用模擬資料（gh CLI 失敗時的降級模式）
#   --output-jsonl PATH  將結果追加寫入 JSONL 趨勢記錄  [NFR2]
#   --repo OWNER/REPO    目標 repo（預設從 git remote 解析）
#
# Exit codes:
#   0  正常（含 gh CLI 失敗靜默降級）[NFR1]
#   0  水位不足（輸出 [BACKLOG-REPLENISH-TRIGGER]，供 CI 用 grep 捕捉）

set -uo pipefail

# ── 預設值 ────────────────────────────────────────────────────────────────

THRESHOLD=10
DRY_RUN=false
OUTPUT_JSONL=""
REPO=""

# ── 參數解析 ──────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --threshold)   THRESHOLD="$2";    shift 2 ;;
    --dry-run)     DRY_RUN=true;      shift   ;;
    --output-jsonl) OUTPUT_JSONL="$2"; shift 2 ;;
    --repo)        REPO="$2";         shift 2 ;;
    *) shift ;;
  esac
done

# ── Repo 偵測 ─────────────────────────────────────────────────────────────

if [[ -z "$REPO" ]]; then
  REPO=$(git remote get-url origin 2>/dev/null \
    | sed -E 's#^(https?://[^/]+/|git@[^:]+:)##; s#\.git$##') || REPO=""
fi

# ── sprint-candidate 水位取得 ─────────────────────────────────────────────

CANDIDATE_COUNT=0
GH_OK=false

if [[ "$DRY_RUN" == "true" ]]; then
  # dry-run 模式：使用 0 作為模擬水位（用於測試 TRIGGER 輸出）
  CANDIDATE_COUNT=0
  GH_OK=true
else
  # NFR1：gh CLI 失敗靜默降級 — 整個區塊用 || true 防止 pipefail 終止
  if command -v gh >/dev/null 2>&1; then
    COUNT_RAW=$(gh issue list \
      ${REPO:+-R "$REPO"} \
      --label "sprint-candidate" \
      --state open \
      --json number \
      --jq 'length' 2>/dev/null) || COUNT_RAW=""
    if [[ -n "$COUNT_RAW" && "$COUNT_RAW" =~ ^[0-9]+$ ]]; then
      CANDIDATE_COUNT="$COUNT_RAW"
      GH_OK=true
    fi
  fi
fi

# NFR1：gh CLI 不可用時靜默離開（exit 0）
if [[ "$GH_OK" == "false" && "$DRY_RUN" == "false" ]]; then
  echo "[BACKLOG-HEALTH] WARNING: gh CLI unavailable or failed — skipping check (NFR1 silent degradation)"
  exit 0
fi

# ── 閾值比對 ──────────────────────────────────────────────────────────────

TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date '+%Y-%m-%dT%H:%M:%SZ')
STATUS="ok"

if [[ "$CANDIDATE_COUNT" -lt "$THRESHOLD" ]]; then
  STATUS="low"
  echo "[BACKLOG-REPLENISH-TRIGGER] sprint-candidate 水位不足：${CANDIDATE_COUNT} < ${THRESHOLD}（閾值）"
else
  echo "[BACKLOG-HEALTH] sprint-candidate 水位正常：${CANDIDATE_COUNT} >= ${THRESHOLD}（閾值）"
fi

# ── NFR2：JSONL 趨勢記錄 ──────────────────────────────────────────────────

# 預設 JSONL 路徑（若未指定）
if [[ -z "$OUTPUT_JSONL" ]]; then
  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  OUTPUT_JSONL="${REPO_ROOT}/docs/cruise-logs/backlog-water-$(date '+%Y%m%d').jsonl"
fi

# 確保目錄存在
JSONL_DIR="$(dirname "$OUTPUT_JSONL")"
mkdir -p "$JSONL_DIR" 2>/dev/null || true

ENTRY=$(printf '{"timestamp":"%s","sprint_candidate_count":%d,"threshold":%d,"status":"%s","repo":"%s"}\n' \
  "$TIMESTAMP" "$CANDIDATE_COUNT" "$THRESHOLD" "$STATUS" "${REPO:-unknown}")

# 寫入失敗靜默忽略（不阻塞主流程）
echo "$ENTRY" >> "$OUTPUT_JSONL" 2>/dev/null || true

# exit 0 — CI 以 grep [BACKLOG-REPLENISH-TRIGGER] 判斷狀態，不依賴 exit code
exit 0
