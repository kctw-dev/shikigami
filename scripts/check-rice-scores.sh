#!/usr/bin/env bash
# scripts/check-rice-scores.sh — #826 RICE Score 缺漏掃描
# 掃描所有 sprint-candidate open Issues，列出缺少 RICE Score 的清單
#
# Usage: bash scripts/check-rice-scores.sh [--owner-repo <org/repo>] [--output-format <text|json>]
# Output: [RICE-MISSING] 告警清單 + 建議補充格式
# NFR1: gh API 失敗時靜默略過，不阻塞主流程
# AC3: 可被 backlog-health-report.sh 呼叫

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OWNER_REPO="${OWNER_REPO:-}"
OUTPUT_FORMAT="text"
RICE_STANDARD_DOC="docs/km/rice-scoring-standard.md"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner-repo)     OWNER_REPO="$2"; shift 2 ;;
    --output-format)  OUTPUT_FORMAT="$2"; shift 2 ;;
    --help)
      echo "Usage: $0 [--owner-repo <org/repo>] [--output-format text|json]"
      echo "AC3: This script can be called by backlog-health-report.sh for integration"
      exit 0
      ;;
    *) shift ;;
  esac
done

# Auto-detect OWNER_REPO from git remote if not set
if [[ -z "$OWNER_REPO" ]]; then
  OWNER_REPO=$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null \
    | sed -E 's#^(https?://[^/]+/|git@[^:]+:)##; s#\.git$##' || echo "")
fi

# Fetch sprint-candidate issues — NFR1: fail silently
ISSUES_JSON="[]"
if [[ -n "$OWNER_REPO" ]]; then
  ISSUES_JSON=$(gh issue list -R "$OWNER_REPO" \
    --label "sprint-candidate" \
    --state open \
    --limit 100 \
    --json number,title,body 2>/dev/null || echo "[]")
fi

# Detect RICE Score presence
# Expected patterns: "RICE Score", "RICE =", "Reach:", "**RICE Score**"
MISSING_ISSUES=()
HAS_RICE_ISSUES=()

while IFS= read -r line; do
  NUM=$(echo "$line" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d['number'])" 2>/dev/null)
  TITLE=$(echo "$line" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d['title'])" 2>/dev/null)
  BODY=$(echo "$line" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('body',''))" 2>/dev/null)

  [[ -z "$NUM" ]] && continue

  if echo "$BODY" | grep -qiE "(RICE Score|RICE =|Reach:.*Impact:|## RICE)"; then
    HAS_RICE_ISSUES+=("#${NUM} ${TITLE}")
  else
    MISSING_ISSUES+=("#${NUM} ${TITLE}")
  fi
done < <(echo "$ISSUES_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for item in data:
    print(json.dumps(item))
" 2>/dev/null)

MISSING_COUNT=${#MISSING_ISSUES[@]}
TOTAL_COUNT=$(( ${#MISSING_ISSUES[@]} + ${#HAS_RICE_ISSUES[@]} ))

if [[ "$OUTPUT_FORMAT" == "json" ]]; then
  python3 -c "
import json
missing = $(python3 -c "import json; print(json.dumps([x for x in '${MISSING_ISSUES[*]}'.split('\n') if x]))" 2>/dev/null || echo "[]")
print(json.dumps({'total': $TOTAL_COUNT, 'missing': $MISSING_COUNT, 'missing_issues': missing}))
" 2>/dev/null || echo "{\"total\":$TOTAL_COUNT,\"missing\":$MISSING_COUNT}"
  exit 0
fi

echo "=== RICE Score 缺漏掃描 ==="
echo "掃描範圍：sprint-candidate open Issues（共 ${TOTAL_COUNT} 個）"
echo ""

if [[ $MISSING_COUNT -eq 0 ]]; then
  echo "[RICE-OK] 所有 sprint-candidate Issues 均有 RICE Score"
else
  echo "[RICE-MISSING] 以下 ${MISSING_COUNT} 個 Issues 缺少 RICE Score："
  echo ""
  for ISSUE in "${MISSING_ISSUES[@]}"; do
    echo "  - ${ISSUE}"
  done
  echo ""
  echo "建議補充格式（依據 ${RICE_STANDARD_DOC}）："
  echo ""
  echo "  ## RICE Score"
  echo "  Reach: <1-4> | Impact: <1-5> | Confidence: <50-100>% | Effort: <Story Points>"
  echo "  RICE = (Reach × Impact × Confidence%) / Effort"
fi

exit 0
