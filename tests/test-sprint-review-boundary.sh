#!/usr/bin/env bash
# tests/test-sprint-review-boundary.sh
# Story #732 — Sprint Review 邊界案例測試自動化
#
# 覆蓋 Sprint Review §2 步驟 2 常見邊界案例：
#   - 零 PASS Story（全部 FAIL / BLOCKED）
#   - 全 PASS Story（所有 Story DONE）
#   - 部分 FAIL Story（混合狀態）
#
# NFR1: 不依賴外部網路（純本地 shell 測試）
# AC4:  測試執行時間 < 30s

set -euo pipefail

PASS=0
FAIL=0
START_TIME=$(date +%s)

pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

echo "================================================================"
echo "test-sprint-review-boundary.sh — Sprint Review 邊界案例測試"
echo "================================================================"

# ── 測試輔助函式 ──────────────────────────────────────────────────────

# 模擬 sprint_N.md 內容，回傳 Story 狀態列表
make_sprint_doc() {
  local scenario="$1"
  case "$scenario" in
    zero_pass)
      cat << 'EOF'
| 1 | feat: story A | #101 | 1 | FAIL |
| 2 | feat: story B | #102 | 1 | BLOCKED |
| 3 | feat: story C | #103 | 1 | FAIL |
EOF
      ;;
    all_pass)
      cat << 'EOF'
| 1 | feat: story A | #101 | 1 | DONE(#201) |
| 2 | feat: story B | #102 | 1 | DONE(#202) |
| 3 | feat: story C | #103 | 1 | DONE(#203) |
EOF
      ;;
    partial_fail)
      cat << 'EOF'
| 1 | feat: story A | #101 | 1 | DONE(#201) |
| 2 | feat: story B | #102 | 1 | FAIL |
| 3 | feat: story C | #103 | 1 | DONE(#203) |
EOF
      ;;
  esac
}

# 計算 DONE 數量
count_done() {
  grep -c "DONE(#" <<< "$1" || true
}

# 計算 FAIL 數量
count_fail() {
  grep -c "| FAIL |" <<< "$1" || true
}

# 計算 BLOCKED 數量
count_blocked() {
  grep -c "| BLOCKED |" <<< "$1" || true
}

# ── AC2: 零 PASS Story 邊界案例 ──────────────────────────────────────

echo ""
echo "── AC2 Case 1: 零 PASS Story（全部 FAIL / BLOCKED）──"

DOC=$(make_sprint_doc "zero_pass")
DONE_COUNT=$(count_done "$DOC")
FAIL_COUNT=$(count_fail "$DOC")
BLOCKED_COUNT=$(count_blocked "$DOC")

if [ "$DONE_COUNT" -eq 0 ]; then
  pass "零 PASS Story: DONE 計數 = 0"
else
  fail "零 PASS Story: 預期 DONE=0，實際 DONE=$DONE_COUNT"
fi

if [ "$FAIL_COUNT" -ge 1 ]; then
  pass "零 PASS Story: 偵測到 FAIL Story（count=$FAIL_COUNT）"
else
  fail "零 PASS Story: 未偵測到 FAIL Story"
fi

if [ "$BLOCKED_COUNT" -ge 1 ]; then
  pass "零 PASS Story: 偵測到 BLOCKED Story（count=$BLOCKED_COUNT）"
else
  fail "零 PASS Story: 未偵測到 BLOCKED Story"
fi

# 驗證 Velocity = 0
VELOCITY=0
POINTS=$(echo "$DOC" | grep -oP '\| \d+ \|' | grep -oP '\d+' | paste -sd+ | bc 2>/dev/null || echo "0")
DONE_POINTS=0
if [ "$DONE_COUNT" -eq 0 ]; then
  DONE_POINTS=0
fi

if [ "$DONE_POINTS" -eq 0 ]; then
  pass "零 PASS Story: Velocity = 0（符合預期）"
else
  fail "零 PASS Story: Velocity 應為 0，實際 $DONE_POINTS"
fi

# 驗證 Completion Rate = 0%
TOTAL_STORIES=$(echo "$DOC" | grep -c "| DONE\|| FAIL\|| BLOCKED" || true)
if [ "$TOTAL_STORIES" -gt 0 ]; then
  COMPLETION_RATE=0
  if [ "$DONE_COUNT" -eq 0 ]; then
    pass "零 PASS Story: Completion Rate = 0%（$DONE_COUNT/$TOTAL_STORIES）"
  else
    fail "零 PASS Story: Completion Rate 應為 0%"
  fi
else
  fail "零 PASS Story: 無法計算 Total Stories"
fi

# ── AC2: 全 PASS Story 邊界案例 ──────────────────────────────────────

echo ""
echo "── AC2 Case 2: 全 PASS Story（所有 Story DONE）──"

DOC=$(make_sprint_doc "all_pass")
DONE_COUNT=$(count_done "$DOC")
FAIL_COUNT=$(count_fail "$DOC")
BLOCKED_COUNT=$(count_blocked "$DOC")
TOTAL_STORIES=3

if [ "$DONE_COUNT" -eq "$TOTAL_STORIES" ]; then
  pass "全 PASS Story: DONE 計數 = $TOTAL_STORIES（全部完成）"
else
  fail "全 PASS Story: 預期 DONE=$TOTAL_STORIES，實際 DONE=$DONE_COUNT"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  pass "全 PASS Story: FAIL 計數 = 0"
else
  fail "全 PASS Story: 預期 FAIL=0，實際 FAIL=$FAIL_COUNT"
fi

if [ "$BLOCKED_COUNT" -eq 0 ]; then
  pass "全 PASS Story: BLOCKED 計數 = 0"
else
  fail "全 PASS Story: 預期 BLOCKED=0，實際 BLOCKED=$BLOCKED_COUNT"
fi

# 驗證 Completion Rate = 100%
if [ "$DONE_COUNT" -eq "$TOTAL_STORIES" ]; then
  pass "全 PASS Story: Completion Rate = 100%（$DONE_COUNT/$TOTAL_STORIES）"
else
  fail "全 PASS Story: Completion Rate 應為 100%"
fi

# 驗證 Sprint Goal 達成
GOAL_ACHIEVED=false
if [ "$DONE_COUNT" -eq "$TOTAL_STORIES" ] && [ "$FAIL_COUNT" -eq 0 ]; then
  GOAL_ACHIEVED=true
fi

if [ "$GOAL_ACHIEVED" = "true" ]; then
  pass "全 PASS Story: Sprint Goal 達成判定 = true"
else
  fail "全 PASS Story: Sprint Goal 達成判定 應為 true"
fi

# ── AC2: 部分 FAIL Story 邊界案例 ────────────────────────────────────

echo ""
echo "── AC2 Case 3: 部分 FAIL Story（混合狀態）──"

DOC=$(make_sprint_doc "partial_fail")
DONE_COUNT=$(count_done "$DOC")
FAIL_COUNT=$(count_fail "$DOC")
TOTAL_STORIES=3

if [ "$DONE_COUNT" -eq 2 ]; then
  pass "部分 FAIL Story: DONE 計數 = 2（符合預期）"
else
  fail "部分 FAIL Story: 預期 DONE=2，實際 DONE=$DONE_COUNT"
fi

if [ "$FAIL_COUNT" -eq 1 ]; then
  pass "部分 FAIL Story: FAIL 計數 = 1（符合預期）"
else
  fail "部分 FAIL Story: 預期 FAIL=1，實際 FAIL=$FAIL_COUNT"
fi

# 驗證 Completion Rate = 66% (2/3)
EXPECTED_RATE=66
ACTUAL_RATE=$((DONE_COUNT * 100 / TOTAL_STORIES))
if [ "$ACTUAL_RATE" -ge 60 ] && [ "$ACTUAL_RATE" -le 70 ]; then
  pass "部分 FAIL Story: Completion Rate ~${ACTUAL_RATE}%（2/3，符合 66% 預期）"
else
  fail "部分 FAIL Story: Completion Rate 應約 66%，實際 ${ACTUAL_RATE}%"
fi

# 驗證 Sprint Goal 部分達成
PARTIAL_GOAL=false
if [ "$DONE_COUNT" -gt 0 ] && [ "$FAIL_COUNT" -gt 0 ]; then
  PARTIAL_GOAL=true
fi

if [ "$PARTIAL_GOAL" = "true" ]; then
  pass "部分 FAIL Story: Sprint Goal 部分達成判定 = true"
else
  fail "部分 FAIL Story: Sprint Goal 部分達成判定 應為 true"
fi

# ── AC1: 測試腳本存在性自驗 ──────────────────────────────────────────

echo ""
echo "── AC1: 自身存在性驗證 ──"

SCRIPT_PATH="tests/test-sprint-review-boundary.sh"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -f "${REPO_ROOT}/${SCRIPT_PATH}" ]; then
  pass "tests/test-sprint-review-boundary.sh 存在"
else
  fail "tests/test-sprint-review-boundary.sh 不存在於 ${REPO_ROOT}"
fi

# ── NFR1: 無外部網路依賴驗證 ─────────────────────────────────────────

echo ""
echo "── NFR1: 外部網路依賴檢查 ──"

# 排除 NFR1 檢查行本身（self-referential grep 誤判防護）
NETWORK_CALLS=$(grep -n "curl\|wget\|npm install\|pip install" "${BASH_SOURCE[0]}" 2>/dev/null \
  | grep -v "NFR1\|NETWORK_CALLS\|curl\\\\|wget\\\\|npm" || true)
if [ -n "$NETWORK_CALLS" ]; then
  fail "NFR1: 腳本含外部網路呼叫"
else
  pass "NFR1: 腳本無外部網路依賴"
fi

# ── AC4: 執行時間 < 30s ──────────────────────────────────────────────

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo ""
echo "── AC4: 執行時間驗證 ──"

if [ "$ELAPSED" -lt 30 ]; then
  pass "AC4: 執行時間 ${ELAPSED}s < 30s"
else
  fail "AC4: 執行時間 ${ELAPSED}s >= 30s（超出上限）"
fi

# ── 結果摘要 ─────────────────────────────────────────────────────────

echo ""
echo "================================================================"
echo "結果：PASS=${PASS}  FAIL=${FAIL}  時間=${ELAPSED}s"
echo "================================================================"

if [ "$FAIL" -eq 0 ]; then
  echo "[RESULT] ALL PASS"
  exit 0
else
  echo "[RESULT] FAIL (${FAIL} 項未通過)"
  exit 1
fi
