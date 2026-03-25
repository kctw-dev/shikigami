#!/usr/bin/env bash
# scripts/backlog-dashboard.sh — #824 Backlog 健康度儀表板
# 輸出 sprint-candidate 數量、年齡（最老候選的 updatedAt 距今天數）、MoSCoW 分布
#
# Usage: bash scripts/backlog-dashboard.sh [--owner-repo <org/repo>] [--threshold <N>]
# Output: sprint-candidate 統計表 + [BACKLOG-WARN] when count < threshold
# NFR1: 腳本執行時間 < 5 秒（含 gh API 呼叫）

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OWNER_REPO="${OWNER_REPO:-}"
THRESHOLD=10

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner-repo) OWNER_REPO="$2"; shift 2 ;;
    --threshold)  THRESHOLD="$2"; shift 2 ;;
    --dry-run)    echo "[DRY-RUN] backlog-dashboard.sh"; exit 0 ;;
    --help)       echo "Usage: $0 [--owner-repo <org/repo>] [--threshold <N>]"; exit 0 ;;
    *) shift ;;
  esac
done

# Auto-detect OWNER_REPO from git remote if not set
if [[ -z "$OWNER_REPO" ]]; then
  OWNER_REPO=$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null \
    | sed -E 's#^(https?://[^/]+/|git@[^:]+:)##; s#\.git$##' || echo "")
fi

TODAY_EPOCH=$(date '+%s')
TODAY_STR=$(date '+%Y-%m-%d')

echo "=== Backlog 健康度儀表板（Sprint Candidate Dashboard）==="
echo "日期：${TODAY_STR}"
echo "Threshold：>= ${THRESHOLD} sprint-candidate"
echo ""

# Fetch sprint-candidate issues
ISSUES_JSON="[]"
if [[ -n "$OWNER_REPO" ]]; then
  ISSUES_JSON=$(gh issue list -R "$OWNER_REPO" \
    --label "sprint-candidate" \
    --state open \
    --limit 100 \
    --json number,title,labels,updatedAt 2>/dev/null || echo "[]")
fi

CANDIDATE_COUNT=$(echo "$ISSUES_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d))" 2>/dev/null || echo "0")

# Calculate oldest candidate age in days
OLDEST_AGE=0
if [[ "$CANDIDATE_COUNT" -gt 0 ]]; then
  OLDEST_AGE=$(echo "$ISSUES_JSON" | python3 -c "
import sys, json
from datetime import datetime, timezone

data = json.load(sys.stdin)
if not data:
    print(0)
    exit(0)

today = datetime.now(timezone.utc)
max_age = 0
for issue in data:
    updated_str = issue.get('updatedAt', '')
    if not updated_str:
        continue
    try:
        updated = datetime.fromisoformat(updated_str.replace('Z', '+00:00'))
        age = (today - updated).days
        if age > max_age:
            max_age = age
    except Exception:
        pass
print(max_age)
" 2>/dev/null || echo "0")
fi

# MoSCoW distribution
MUST_COUNT=$(echo "$ISSUES_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(sum(1 for i in data if any(l['name'] == 'priority: must' for l in i.get('labels', []))))
" 2>/dev/null || echo "0")

SHOULD_COUNT=$(echo "$ISSUES_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(sum(1 for i in data if any(l['name'] == 'priority: should' for l in i.get('labels', []))))
" 2>/dev/null || echo "0")

COULD_COUNT=$(echo "$ISSUES_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(sum(1 for i in data if any(l['name'] == 'priority: could' for l in i.get('labels', []))))
" 2>/dev/null || echo "0")

# Output dashboard
echo "| 指標 | 數值 |"
echo "|------|------|"
echo "| sprint-candidate 總數 | ${CANDIDATE_COUNT} |"
echo "| 最老候選年齡（天） | ${OLDEST_AGE} 天 |"
echo "| priority: must | ${MUST_COUNT} |"
echo "| priority: should | ${SHOULD_COUNT} |"
echo "| priority: could | ${COULD_COUNT} |"
echo ""

# AC2: Warn if count < threshold
if [[ "$CANDIDATE_COUNT" -lt "$THRESHOLD" ]]; then
  echo "[BACKLOG-WARN] sprint-candidate 不足（${CANDIDATE_COUNT} < ${THRESHOLD}），建議補充 Backlog"
else
  echo "[BACKLOG-OK] sprint-candidate 健康（${CANDIDATE_COUNT} >= ${THRESHOLD}）"
fi

exit 0
