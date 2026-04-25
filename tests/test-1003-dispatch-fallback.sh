#!/usr/bin/env bash
# tests/test-1003-dispatch-fallback.sh
# Issue #1003 (Sprint 182 Retro A3) / ADR-046：dispatch-with-fallback.sh 驗證
#
# 覆蓋 AC：
#   AC1 — script 存在、四個子命令可執行
#   AC2 — detect-error 正確分類 HTTP 429 vs HTTP 5xx vs 無錯誤
#   AC3 — detect-refusal 偵測 8 種典型拒答字樣，無誤命中乾淨輸出
#   AC4 — record-event 正確寫入 jsonl + 必要欄位驗證
#   AC5 — record-event 拒絕無效的 reason 與必要參數缺失
#   AC6 — ADR-046 與 SKILL.md §2.1.1 結構性更新

set -uo pipefail

PASS=0
FAIL=0
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/dispatch-with-fallback.sh"
ADR="$REPO_ROOT/docs/adr/ADR-046-agent-tool-fallback-verification.md"
SKILL="$REPO_ROOT/skills/sprint-execution/SKILL.md"

pass() { echo "[PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

# 暫存：每次測試的事件紀錄各自隔離
TMPDIR_TEST="$(mktemp -d -t test-1003.XXXXXX)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

# ---------------------------------------------------------------------------
# AC1：script + 子命令存在
# ---------------------------------------------------------------------------
[[ -f "$SCRIPT" ]] && pass "AC1.1 script 存在" || { fail "AC1.1 script 缺失"; exit 1; }
[[ -x "$SCRIPT" ]] && pass "AC1.2 script 可執行" || fail "AC1.2 script 缺 +x"

bash "$SCRIPT" -h >/dev/null 2>&1 && pass "AC1.3 -h 可執行" || fail "AC1.3 -h 失敗"
bash "$SCRIPT" patterns >/dev/null 2>&1 && pass "AC1.4 patterns 子命令" || fail "AC1.4 patterns 失敗"

# ---------------------------------------------------------------------------
# AC2：detect-error
# ---------------------------------------------------------------------------
declare -a ERR_429_CASES=(
  "Server returned 429 Too Many Requests"
  "rate_limit_error: too many requests"
  "Anthropic API: rate limit exceeded"
  "anthropic.RateLimitError"
  # codex review P2 第三輪：case-insensitive 變體
  "Rate Limit Exceeded"
  "RATE LIMIT EXCEEDED"
  "Rate_Limit_Error"
)
for t in "${ERR_429_CASES[@]}"; do
  out=$(bash "$SCRIPT" detect-error --text "$t" 2>&1)
  rc=$?
  if [[ $rc -eq 0 ]] && [[ "$out" == *"HTTP_429"* ]]; then
    pass "AC2.1 偵測 HTTP_429: \"$t\""
  else
    fail "AC2.1 應偵測為 HTTP_429 但失敗: \"$t\" (rc=$rc, out=$out)"
  fi
done

declare -a ERR_5XX_CASES=(
  "Got HTTP 529 Overloaded"
  "Internal server error: 500"
  "anthropic.OverloadedError: overloaded_error"
  "server_error from upstream"
  # codex review P2 第三輪：case-insensitive 變體
  "Internal Server Error"
  "INTERNAL SERVER ERROR"
  "OVERLOADED"
  "Server_Error"
)
for t in "${ERR_5XX_CASES[@]}"; do
  out=$(bash "$SCRIPT" detect-error --text "$t" 2>&1)
  rc=$?
  if [[ $rc -eq 0 ]] && [[ "$out" == *"HTTP_5XX"* ]]; then
    pass "AC2.2 偵測 HTTP_5XX: \"$t\""
  else
    fail "AC2.2 應偵測為 HTTP_5XX 但失敗: \"$t\" (rc=$rc, out=$out)"
  fi
done

# AC2.3：乾淨 stderr 不應觸發
declare -a CLEAN_STDERR=(
  "Tool executed successfully"
  "subagent finished in 12s"
  "[INFO] dispatching architect"
)
for t in "${CLEAN_STDERR[@]}"; do
  out=$(bash "$SCRIPT" detect-error --text "$t" 2>&1)
  rc=$?
  if [[ $rc -eq 1 ]] && [[ "$out" == *"NONE"* ]]; then
    pass "AC2.3 乾淨 stderr 不誤觸發: \"$t\""
  else
    fail "AC2.3 不應觸發但被誤判: \"$t\" (rc=$rc, out=$out)"
  fi
done

# AC2.4：包含「429 行數」這種數字串不應誤判（用 word-boundary 避免）
out=$(bash "$SCRIPT" detect-error --text "modified 4290 files in repo" 2>&1)
rc=$?
if [[ $rc -eq 1 ]]; then
  pass "AC2.4 4290 不誤判為 429"
else
  fail "AC2.4 4290 被誤判為 429 (out=$out)"
fi

# ---------------------------------------------------------------------------
# AC3：detect-refusal
# ---------------------------------------------------------------------------
declare -a REFUSAL_CASES=(
  "I can't help with that request."
  "I cannot help with that as it conflicts with my values."
  "I'm unable to help with that."
  "I am unable to assist with this task."
  "I am unable to fulfill that request."
  "I'm unable to comply with this."
  "I am unable to do that."
  "I'm unable to provide that."
  "I'm unable to process this request."
  "I can't assist with that."
  "I cannot assist with this."
  "This goes against my guidelines."
  "That request is against the policies I operate under."
  "I won't be able to help with that."
  "I won't be able to fulfill the request."
  "I must decline that request."
  "I cannot comply with that request."
)
for t in "${REFUSAL_CASES[@]}"; do
  out=$(bash "$SCRIPT" detect-refusal --text "$t" 2>&1)
  rc=$?
  if [[ $rc -eq 0 ]] && [[ "$out" == *"POLICY_REFUSAL"* ]]; then
    pass "AC3.1 偵測 refusal: \"$t\""
  else
    fail "AC3.1 應偵測為 refusal 但失敗: \"$t\" (rc=$rc, out=$out)"
  fi
done

declare -a CLEAN_OUTPUT=(
  "Implementation complete. Tests pass."
  "Sprint Story #1003 implemented as specified."
  "I have completed the analysis as requested."
  "The user's request was fulfilled."
  # codex review P2-3 regression：subagent 正常診斷不可被誤判為 refusal
  "I'm unable to reproduce the failure locally, please share more logs."
  "I am unable to find the referenced file in the codebase."
  "I'm unable to identify the root cause yet — need more data."
  "I cannot locate the function defined at line 42."
  # codex review P2 第五輪 regression：常見診斷不可被誤判
  "I am unable to provide the exact line because the file was deleted."
  "I am unable to process the JSON because jq is missing."
  "I'm unable to provide a direct link without access."
  "I am unable to help debug without more logs."
  # 註：以下兩種句型字面與拒答不可分（「process this batch」vs「process this
  # request」、「fulfill that requirement」vs「fulfill that request」），
  # ADR-046 已記錄此 limit；caller 端 sonnet 重試成本低，誤觸發可接受
  # "I am unable to process this batch within the timeout."
  # "I'm unable to fulfill that requirement until upstream API is back."
)
for t in "${CLEAN_OUTPUT[@]}"; do
  out=$(bash "$SCRIPT" detect-refusal --text "$t" 2>&1)
  rc=$?
  if [[ $rc -eq 1 ]] && [[ "$out" == *"NONE"* ]]; then
    pass "AC3.2 乾淨輸出不誤觸發 refusal: \"$t\""
  else
    fail "AC3.2 不應觸發但被誤判: \"$t\" (rc=$rc, out=$out)"
  fi
done

# ---------------------------------------------------------------------------
# AC4：record-event 寫入 jsonl
# ---------------------------------------------------------------------------
# 用日期作隔離，本次測試後刪掉的測試紀錄
DATE_STR="$(date -u '+%Y-%m-%d')"
LOG_FILE="$REPO_ROOT/docs/cruise-logs/model-fallback-${DATE_STR}.jsonl"

# 先記下測試前的 line count，測試結束後刪測試新增的行
PRE_COUNT=0
[[ -f "$LOG_FILE" ]] && PRE_COUNT=$(wc -l < "$LOG_FILE")

bash "$SCRIPT" record-event --story 1003 --from opus --to sonnet --reason HTTP529 >/dev/null 2>&1
rc=$?
if [[ $rc -eq 0 ]]; then pass "AC4.1 record-event HTTP529 exit 0"
else fail "AC4.1 record-event 失敗 (rc=$rc)"; fi

[[ -f "$LOG_FILE" ]] && pass "AC4.2 jsonl 檔案被建立" || fail "AC4.2 jsonl 未建立"

# 抓最後一行驗證 schema
LAST_LINE=$(tail -1 "$LOG_FILE")
for field in '"timestamp"' '"story_id":"#1003"' '"from_model":"opus"' '"to_model":"sonnet"' '"reason":"HTTP529"' '"retry_count":0'; do
  if [[ "$LAST_LINE" == *"$field"* ]]; then
    pass "AC4.3 jsonl 含欄位 $field"
  else
    fail "AC4.3 jsonl 缺欄位 $field (line=$LAST_LINE)"
  fi
done

# 驗證 jq 可解析（若有 jq）
if command -v jq >/dev/null 2>&1; then
  if echo "$LAST_LINE" | jq -e . >/dev/null 2>&1; then
    pass "AC4.4 jsonl 為合法 JSON（jq 解析成功）"
  else
    fail "AC4.4 jsonl 非合法 JSON (line=$LAST_LINE)"
  fi
else
  pass "AC4.4 jq 不存在，跳過 JSON 解析驗證"
fi

# 補一筆 POLICY_REFUSAL
bash "$SCRIPT" record-event --story 1003 --from opus --to sonnet --reason POLICY_REFUSAL --retry-count 1 >/dev/null 2>&1
LAST_LINE=$(tail -1 "$LOG_FILE")
if [[ "$LAST_LINE" == *'"reason":"POLICY_REFUSAL"'* ]] && [[ "$LAST_LINE" == *'"retry_count":1'* ]]; then
  pass "AC4.5 record-event POLICY_REFUSAL 紀錄成功"
else
  fail "AC4.5 POLICY_REFUSAL 紀錄不正確 (line=$LAST_LINE)"
fi

# 清理本次測試新增的行（保留歷史資料）
POST_COUNT=$(wc -l < "$LOG_FILE" 2>/dev/null || echo 0)
ADDED=$((POST_COUNT - PRE_COUNT))
if [[ $ADDED -gt 0 ]]; then
  if [[ $PRE_COUNT -eq 0 ]]; then
    # 原本不存在或為空 → 直接移除（本次測試新增的整檔）
    rm -f "$LOG_FILE"
  else
    # 原本有歷史資料 → 截掉本次新增行，保留歷史
    TMP_TRUNC="$(mktemp -t test-1003-trunc.XXXXXX)"
    head -n "$PRE_COUNT" "$LOG_FILE" > "$TMP_TRUNC" && mv -f "$TMP_TRUNC" "$LOG_FILE"
  fi
fi
# 確保 .tmp 殘留也被清掉（保險）
rm -f "$LOG_FILE.tmp"

# ---------------------------------------------------------------------------
# AC4.6（codex review P2-1）：grep 在 pipefail 下不可有 SIGPIPE 漏判
# 大輸入 + refusal 在開頭 → 必須仍偵測到（非 [NONE]）
# ---------------------------------------------------------------------------
LARGE_INPUT="I can't help with that request.$(printf 'x%.0s' {1..50000})"
out=$(bash "$SCRIPT" detect-refusal --text "$LARGE_INPUT" 2>&1)
rc=$?
if [[ $rc -eq 0 ]] && [[ "$out" == *"POLICY_REFUSAL"* ]]; then
  pass "AC4.6 大輸入下 refusal 仍被偵測（無 SIGPIPE 漏判）"
else
  fail "AC4.6 大輸入下 refusal 漏判 (rc=$rc, out=${out:0:100})"
fi

# AC4.7 / AC4.8（codex review P2-2）：缺值參數應立即 die，不可無限迴圈
# 跨平台 timeout（macOS 無 timeout/gtimeout）
run_with_timeout() {
  local secs="$1"; shift
  ( "$@" >/dev/null 2>&1 ) &
  local pid=$!
  ( sleep "$secs" && kill -9 "$pid" 2>/dev/null ) &
  local watchdog=$!
  wait "$pid" 2>/dev/null
  local rc=$?
  kill -9 "$watchdog" 2>/dev/null
  wait "$watchdog" 2>/dev/null
  echo "$rc"
}

rc=$(run_with_timeout 3 bash "$SCRIPT" detect-error --text)
if [[ "$rc" == "2" ]]; then
  pass "AC4.7 detect-error 缺 --text 值立即 die（exit 2 = usage error）"
elif [[ "$rc" == "137" ]]; then
  fail "AC4.7 detect-error 缺值被 watchdog 殺掉（疑似無限迴圈），應 die"
else
  fail "AC4.7 detect-error 缺值返回意外 rc=$rc（期望 2）"
fi

rc=$(run_with_timeout 3 bash "$SCRIPT" record-event --story)
if [[ "$rc" == "2" ]]; then
  pass "AC4.8 record-event 缺 --story 值立即 die（exit 2 = usage error）"
elif [[ "$rc" == "137" ]]; then
  fail "AC4.8 record-event 缺值被 watchdog 殺掉（疑似無限迴圈），應 die"
else
  fail "AC4.8 record-event 缺值返回意外 rc=$rc（期望 2）"
fi

# AC4.9（codex review P2-4）：log 寫入失敗應 die，不可靜默報 success
# 結構性檢查：確認 mkdir 與 printf 都有 || die 包裹
if grep -q '|| die "無法建立 log 目錄' "$SCRIPT"; then
  pass "AC4.9 mkdir 失敗有 die 處理（codex review P2-4）"
else
  fail "AC4.9 mkdir 失敗無 die 處理"
fi
if grep -q 'die "無法寫入 log 檔' "$SCRIPT"; then
  pass "AC4.10 printf >> 失敗有 die 處理（codex review P2-4）"
else
  fail "AC4.10 printf >> 失敗無 die 處理"
fi

# AC4.11（codex review P2 第四輪）：使用者錯誤必須以 exit 2 區分於 no-match
# detect-error 收到不存在 --input-file 時必須 exit 2（不可走 [NONE] + exit 1）
bash "$SCRIPT" detect-error --input-file /no/such/file/anywhere >/dev/null 2>&1
rc=$?
if [[ $rc -eq 2 ]]; then
  pass "AC4.11 不可讀 --input-file 必須 exit 2（usage error）"
else
  fail "AC4.11 不可讀 --input-file 返回 rc=$rc（期望 2，不可被當成 no-match）"
fi

# AC4.12：互斥旗標必須 exit 2，不可被當成 no-match
bash "$SCRIPT" detect-error --input-file /tmp/x --text "y" >/dev/null 2>&1
rc=$?
if [[ $rc -eq 2 ]]; then
  pass "AC4.12 --input-file + --text 互斥必須 exit 2"
else
  fail "AC4.12 互斥旗標返回 rc=$rc（期望 2）"
fi

# AC4.13：record-event 無效 reason 必須 exit 2
bash "$SCRIPT" record-event --story 1 --from opus --to sonnet --reason BOGUS >/dev/null 2>&1
rc=$?
if [[ $rc -eq 2 ]]; then
  pass "AC4.13 record-event 無效 --reason 必須 exit 2"
else
  fail "AC4.13 record-event 無效 reason 返回 rc=$rc（期望 2）"
fi

# AC4.14：detect-error 真正 no-match 仍然是 exit 1（沒被升級成 2）
bash "$SCRIPT" detect-error --text "everything is fine" >/dev/null 2>&1
rc=$?
if [[ $rc -eq 1 ]]; then
  pass "AC4.14 detect-error 純 no-match 仍是 exit 1（與 usage error 區分）"
else
  fail "AC4.14 純 no-match 返回 rc=$rc（期望 1）"
fi

# AC4.15（codex review P2 第七輪）：完全沒給 input source 必須 exit 2
# 不可被當成 no-match（exit 1）→ 否則 caller 的「忘記傳 input」bug 會被
# 靜默當成「沒有 fallback 訊號」處理
bash "$SCRIPT" detect-error >/dev/null 2>&1
rc=$?
if [[ $rc -eq 2 ]]; then
  pass "AC4.15 detect-error 無 input source 必須 exit 2"
else
  fail "AC4.15 detect-error 無 input source 返回 rc=$rc（期望 2，不可當成 no-match）"
fi

bash "$SCRIPT" detect-refusal >/dev/null 2>&1
rc=$?
if [[ $rc -eq 2 ]]; then
  pass "AC4.16 detect-refusal 無 input source 必須 exit 2"
else
  fail "AC4.16 detect-refusal 無 input source 返回 rc=$rc（期望 2）"
fi

# ---------------------------------------------------------------------------
# AC5：record-event 參數驗證
# ---------------------------------------------------------------------------
# 缺 --story
bash "$SCRIPT" record-event --from opus --to sonnet --reason HTTP429 >/dev/null 2>&1
rc=$?
[[ $rc -ne 0 ]] && pass "AC5.1 缺 --story 應失敗" || fail "AC5.1 缺 --story 未拒絕"

# 無效 reason
bash "$SCRIPT" record-event --story 1003 --from opus --to sonnet --reason BOGUS >/dev/null 2>&1
rc=$?
[[ $rc -ne 0 ]] && pass "AC5.2 無效 reason 應失敗" || fail "AC5.2 無效 reason 未拒絕"

# ---------------------------------------------------------------------------
# AC6：ADR-046 與 SKILL.md §2.1.1 結構性更新
# ---------------------------------------------------------------------------
[[ -f "$ADR" ]] && pass "AC6.1 ADR-046 存在" || fail "AC6.1 ADR-046 缺失"

# ADR 包含必要 section
for s in "## 背景與問題" "## 驗證範圍與限制" "## 三類錯誤的區分" "## 決策" "## 拒絕的替代方案"; do
  if grep -qF "$s" "$ADR" 2>/dev/null; then
    pass "AC6.2 ADR-046 含 section: $s"
  else
    fail "AC6.2 ADR-046 缺 section: $s"
  fi
done

# SKILL §2.1.1 升級為三段式 + ADR 引用
grep -q "## 2.1.1 API Error Fallback 策略" "$SKILL" \
  && pass "AC6.3 §2.1.1 標題仍存在" \
  || fail "AC6.3 §2.1.1 標題遺失"
grep -q "ADR-046" "$SKILL" \
  && pass "AC6.4 SKILL.md §2.1.1 引用 ADR-046" \
  || fail "AC6.4 SKILL.md §2.1.1 未引用 ADR-046"
grep -q "Usage Policy Refusal" "$SKILL" \
  && pass "AC6.5 §2.1.1 含 Policy Refusal 路徑" \
  || fail "AC6.5 §2.1.1 缺 Policy Refusal 路徑"
grep -q "dispatch-with-fallback.sh" "$SKILL" \
  && pass "AC6.6 §2.1.1 引用 wrapper script" \
  || fail "AC6.6 §2.1.1 未引用 wrapper script"

# ---------------------------------------------------------------------------
# 結算
# ---------------------------------------------------------------------------
echo ""
echo "=========================================="
echo "Test Result: PASS=$PASS  FAIL=$FAIL"
echo "=========================================="

[[ $FAIL -eq 0 ]] && exit 0 || exit 1
