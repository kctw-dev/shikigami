#!/usr/bin/env bash
# test-588-live-log-file-var.sh
# AC3: 確認 story-lifecycle-prompt.md 含有 LIVE_LOG_FILE 變數定義

set -euo pipefail

FILE="skills/sprint-execution/story-lifecycle-prompt.md"
PASS=0
FAIL=0

assert() {
  local desc="$1"
  local result="$2"
  if [[ "$result" == "0" ]]; then
    echo "PASS: $desc"
    ((PASS++)) || true
  else
    echo "FAIL: $desc"
    ((FAIL++)) || true
  fi
}

# AC1: 確認 LIVE_LOG_FILE 定義存在
grep -q 'LIVE_LOG_FILE="logs/live/\$(date' "$FILE"
assert "AC1: LIVE_LOG_FILE 定義存在" "$?"

# AC1: 確認 mkdir -p logs/live 存在
grep -q 'mkdir -p logs/live' "$FILE"
assert "AC1: mkdir -p logs/live 存在" "$?"

# AC1: 確認使用 SHIKIGAMI_SESSION_ID:-unknown
grep -q 'SHIKIGAMI_SESSION_ID:-unknown' "$FILE"
assert "AC1: SHIKIGAMI_SESSION_ID:-unknown 存在" "$?"

# AC2: 定義必須在第一個引用之前
DEF_LINE=$(grep -n 'LIVE_LOG_FILE="logs/live/' "$FILE" | head -1 | cut -d: -f1)
FIRST_REF_LINE=$(grep -n '>> "${LIVE_LOG_FILE}"' "$FILE" | head -1 | cut -d: -f1)

if [[ -n "$DEF_LINE" && -n "$FIRST_REF_LINE" && "$DEF_LINE" -lt "$FIRST_REF_LINE" ]]; then
  echo "PASS: AC2: 定義 (L${DEF_LINE}) 在第一個引用 (L${FIRST_REF_LINE}) 之前"
  ((PASS++)) || true
else
  echo "FAIL: AC2: 定義 (L${DEF_LINE:-?}) 不在第一個引用 (L${FIRST_REF_LINE:-?}) 之前"
  ((FAIL++)) || true
fi

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[[ "$FAIL" -eq 0 ]]
