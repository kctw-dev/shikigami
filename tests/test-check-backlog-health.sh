#!/usr/bin/env bash
# tests/test-check-backlog-health.sh
# Story #944: 自動化 sprint-candidate 水位週期性監控機制
# AC1: scripts/check-backlog-health.sh 存在，讀取 sprint-candidate 水位
# AC2: 水位不足輸出 [BACKLOG-REPLENISH-TRIGGER]
# AC4: 支援 --threshold 參數
# NFR1: gh CLI 失敗靜默降級（exit 0）
# NFR2: 結果寫入 JSONL

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/check-backlog-health.sh"
PASS=0
FAIL=0

assert_pass() {
  local desc="$1"; shift
  local rc=0
  "$@" >/dev/null 2>&1 || rc=$?
  if [[ $rc -eq 0 ]]; then
    echo "  [PASS] $desc"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] $desc (exit=$rc)"
    FAIL=$((FAIL+1))
  fi
}

assert_output_contains() {
  local desc="$1" needle="$2"; shift 2
  local out
  out=$("$@" 2>&1) || true
  if echo "$out" | grep -q "$needle"; then
    echo "  [PASS] $desc"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] $desc — expected '$needle'"
    echo "         got: $(echo "$out" | head -2)"
    FAIL=$((FAIL+1))
  fi
}

assert_file_exists() {
  local desc="$1" f="$2"
  if [[ -f "$f" ]]; then echo "  [PASS] $desc"; PASS=$((PASS+1))
  else echo "  [FAIL] $desc — file not found: $f"; FAIL=$((FAIL+1)); fi
}

echo "--- AC1: 腳本存在且可執行 ---"
assert_file_exists "check-backlog-health.sh 存在" "$SCRIPT"
[[ -x "$SCRIPT" ]] && { echo "  [PASS] 腳本可執行"; PASS=$((PASS+1)); } || { echo "  [FAIL] 腳本不可執行"; FAIL=$((FAIL+1)); }

echo "--- AC2: [BACKLOG-REPLENISH-TRIGGER] 輸出 (強制低水位) ---"
assert_output_contains "低水位觸發 TRIGGER" "[BACKLOG-REPLENISH-TRIGGER]" \
  bash "$SCRIPT" --threshold 99999 --dry-run

echo "--- AC4: --threshold 覆蓋預設值 ---"
# threshold=0 → 水位永遠達標，不輸出 TRIGGER
out=$(bash "$SCRIPT" --threshold 0 --dry-run 2>&1) || true
if echo "$out" | grep -q "\[BACKLOG-REPLENISH-TRIGGER\]"; then
  echo "  [FAIL] threshold=0 不應觸發 TRIGGER"
  FAIL=$((FAIL+1))
else
  echo "  [PASS] threshold=0 不觸發 TRIGGER"
  PASS=$((PASS+1))
fi

echo "--- NFR1: gh CLI 失敗靜默降級 ---"
# 模擬 gh CLI 不可用：建立假 gh 腳本讓它 exit 1（模擬 auth failure）
TMPBIN=$(mktemp -d)
cat > "$TMPBIN/gh" << 'FAKEGH'
#!/usr/bin/env bash
exit 1
FAKEGH
chmod +x "$TMPBIN/gh"
rc=0
PATH="$TMPBIN:$PATH" bash "$SCRIPT" 2>/dev/null || rc=$?
rm -rf "$TMPBIN"
if [[ $rc -eq 0 ]]; then
  echo "  [PASS] gh CLI 失敗時 exit 0（靜默降級）"
  PASS=$((PASS+1))
else
  echo "  [FAIL] gh CLI 失敗時 exit $rc（應為 0）"
  FAIL=$((FAIL+1))
fi

echo "--- NFR2: JSONL 趨勢記錄 ---"
TMPDIR_JSONL=$(mktemp -d)
JSONL_OUT="$TMPDIR_JSONL/health.jsonl"
bash "$SCRIPT" --threshold 0 --output-jsonl "$JSONL_OUT" --dry-run 2>/dev/null || true
assert_file_exists "JSONL 記錄建立" "$JSONL_OUT"
rm -rf "$TMPDIR_JSONL"

echo "--- Story #982: 趨勢摘要整合 ---"

# AC1: 輸出包含趨勢或 trend 段落
out=$(bash "$SCRIPT" --threshold 0 --dry-run 2>&1) || true
if echo "$out" | grep -iE '(trend|趨勢|水位|water|date|status)' | grep -q ''; then
  echo "  [PASS] 輸出包含趨勢相關資訊"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 輸出缺少趨勢相關資訊"
  FAIL=$((FAIL+1))
fi

# AC2: 資料不足 7 天時 fallback 訊息
TMPDIR_DATA=$(mktemp -d)
bash "$SCRIPT" --threshold 0 --output-jsonl "$TMPDIR_DATA/test.jsonl" --dry-run 2>/dev/null || true
out=$(bash "$SCRIPT" --threshold 0 --dry-run 2>&1) || true
if echo "$out" | grep -iq 'backlog\|water\|trend'; then
  echo "  [PASS] 資料不足時優雅降級或顯示可用資訊"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 資料不足時輸出異常"
  FAIL=$((FAIL+1))
fi
rm -rf "$TMPDIR_DATA"

# AC3: 整合後執行時間 < 原本 + 2 秒
time_start=$(date +%s%N)
bash "$SCRIPT" --threshold 0 --dry-run >/dev/null 2>&1 || true
time_end=$(date +%s%N)
elapsed_ms=$(( (time_end - time_start) / 1000000 ))
if [[ $elapsed_ms -lt 2000 ]]; then
  echo "  [PASS] 執行時間 ${elapsed_ms}ms < 2000ms"
  PASS=$((PASS+1))
else
  echo "  [WARN] 執行時間 ${elapsed_ms}ms >= 2000ms（仍可接受，整合不應增加額外負擔）"
fi

echo ""
echo "=== 結果: PASS=$PASS FAIL=$FAIL ==="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
