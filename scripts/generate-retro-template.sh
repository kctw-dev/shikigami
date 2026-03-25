#!/usr/bin/env bash
# scripts/generate-retro-template.sh — #827 Sprint Retrospective 自動模板生成
# 接收 sprint_N.md 路徑，輸出預填 Retrospective Markdown 模板
#
# Usage: bash scripts/generate-retro-template.sh <sprint_N.md>
# Output: 預填 Retrospective Markdown（Sprint Goal、velocity、完成率、DONE Stories 清單）
# NFR1: 腳本無需網路連線（純本地文件解析）
# NFR2: 當 sprint_N.md 格式不符預期時，輸出 [RETRO-TEMPLATE-WARN] 而非 crash

set -u

SPRINT_FILE="${1:-}"

if [[ -z "$SPRINT_FILE" ]]; then
  echo "[RETRO-TEMPLATE-WARN] Usage: $0 <sprint_N.md>" >&2
  exit 1
fi

if [[ ! -f "$SPRINT_FILE" ]]; then
  echo "[RETRO-TEMPLATE-WARN] Sprint file not found: $SPRINT_FILE" >&2
  exit 1
fi

# Extract Sprint number from filename
SPRINT_NUM=$(basename "$SPRINT_FILE" .md | grep -oE '[0-9]+$' || echo "N")

# Parse Sprint Goal
SPRINT_GOAL=$(grep -E "\*\*Sprint Goal\*\*" "$SPRINT_FILE" 2>/dev/null | head -1 \
  | sed 's/.*\*\*Sprint Goal\*\*[：:]\s*//' | sed 's/^> *//' || echo "")

if [[ -z "$SPRINT_GOAL" ]]; then
  echo "[RETRO-TEMPLATE-WARN] Could not parse Sprint Goal from: $SPRINT_FILE" >&2
  SPRINT_GOAL="（未能解析 Sprint Goal）"
fi

# Parse Total points (velocity)
VELOCITY=$(grep -oE '\*\*Total: [0-9]+ pts\*\*' "$SPRINT_FILE" 2>/dev/null | head -1 \
  | grep -oE '[0-9]+' || echo "")

if [[ -z "$VELOCITY" ]]; then
  echo "[RETRO-TEMPLATE-WARN] Could not parse velocity from: $SPRINT_FILE" >&2
  VELOCITY="N/A"
fi

# Parse capacity
CAPACITY=$(grep -E "\*\*容量\*\*" "$SPRINT_FILE" 2>/dev/null | head -1 \
  | grep -oE '[0-9]+' | head -1 || echo "$VELOCITY")

# Parse DONE stories
DONE_STORIES=()
while IFS= read -r line; do
  DONE_STORIES+=("$line")
done < <(grep "| DONE" "$SPRINT_FILE" 2>/dev/null \
  | sed 's/^| [0-9]* | //' \
  | sed 's/ | [^ ]* | [0-9]* | DONE.*//' \
  | sed 's/ *$$//')

DONE_COUNT=${#DONE_STORIES[@]}

# Parse FAIL stories
FAIL_STORIES=()
while IFS= read -r line; do
  FAIL_STORIES+=("$line")
done < <(grep "| FAIL" "$SPRINT_FILE" 2>/dev/null \
  | sed 's/^| [0-9]* | //' \
  | sed 's/ | [^ ]* | [0-9]* | FAIL.*//' \
  | sed 's/ *$$//')

FAIL_COUNT=${#FAIL_STORIES[@]}
TOTAL_STORIES=$((DONE_COUNT + FAIL_COUNT))

if [[ $TOTAL_STORIES -gt 0 ]]; then
  COMPLETION_RATE=$(python3 -c "print(f'{$DONE_COUNT/$TOTAL_STORIES*100:.0f}%')" 2>/dev/null || echo "${DONE_COUNT}/${TOTAL_STORIES}")
else
  COMPLETION_RATE="N/A"
fi

# Get current date
TODAY=$(date '+%Y-%m-%d')

# Output Retrospective Template
cat << EOF
# Sprint ${SPRINT_NUM} Retrospective

**日期**：${TODAY}
**Sprint**：${SPRINT_NUM}

---

## Sprint Summary（自動預填）

| 指標 | 數值 |
|------|------|
| Sprint Goal | ${SPRINT_GOAL} |
| Velocity | ${VELOCITY} pts |
| 容量 | ${CAPACITY} pts |
| 完成率 | ${COMPLETION_RATE} |
| DONE Stories | ${DONE_COUNT} |
| FAIL Stories | ${FAIL_COUNT} |

## DONE Stories

EOF

if [[ ${#DONE_STORIES[@]} -gt 0 ]]; then
  for STORY in "${DONE_STORIES[@]}"; do
    echo "- ${STORY}"
  done
else
  echo "_（無 DONE Stories）_"
fi

cat << 'EOF'

---

## Retrospective

### What went well（做得好的）

-

### What could be improved（可以改善的）

-

### Problems（問題點）

-

### Action Items（下一 Sprint 改善行動）

| # | Action | Owner | Priority |
|---|--------|-------|---------|
| 1 |  |  | must |

---

> _此模板由 generate-retro-template.sh 自動生成，請補充各欄位。_
EOF

exit 0
