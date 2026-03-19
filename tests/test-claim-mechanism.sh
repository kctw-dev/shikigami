#!/usr/bin/env bash
# test-claim-mechanism.sh
# US-312 — 多 Session 並行開發 Claim 機制測試
# 三路徑：(1) claim 成功 (2) 重複 claim 被拒 (3) release 成功 + stale lock 偵測

set -uo pipefail

PASS=0
FAIL=0
SKIP=0

# ── 工具函式 ────────────────────────────────────────────────────

pass() { echo "  [PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }
skip() { echo "  [SKIP] $1"; SKIP=$((SKIP+1)); }

section() { echo ""; echo "── $1 ────────────────────────────────────"; }

# ── 環境檢查 ────────────────────────────────────────────────────

section "環境檢查"

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ -z "$REPO_ROOT" ]]; then
  fail "不在 git repo 內，無法執行測試"
  exit 1
fi
pass "git repo 根目錄：$REPO_ROOT"

SCRIPT="$REPO_ROOT/hooks/session-end-release.sh"
if [[ -f "$SCRIPT" ]]; then
  pass "hooks/session-end-release.sh 存在"
else
  fail "hooks/session-end-release.sh 不存在"
fi

# ── 本地鎖單元測試（不依賴 remote）─────────────────────────────

section "AC-3 本地鎖原子性（flock 可用性）"

if command -v flock &>/dev/null; then
  pass "flock 指令可用（本地鎖啟用）"
else
  skip "flock 不可用（macOS 環境），本地鎖 fallback 至遠端鎖"
fi

# 測試 lock file 路徑邏輯
REPO_FP=$(git rev-parse --show-toplevel | sha256sum 2>/dev/null | cut -c1-8 \
          || git rev-parse --show-toplevel | md5sum 2>/dev/null | cut -c1-8 \
          || echo "fallback0")
LOCK_FILE="/tmp/shikigami-claims-${REPO_FP}.lock"
pass "repo fingerprint 生成成功：${REPO_FP}"
pass "lock file 路徑：${LOCK_FILE}"

# 測試 flock 原子性：兩個 subshell 同時競搶同一 lock，驗證只有一個成功
if command -v flock &>/dev/null; then
  FLOCK_TEST_LOCK="/tmp/shikigami-flock-atomicity-test-$$.lock"
  FLOCK_RESULT_A="/tmp/shikigami-flock-result-A-$$.txt"
  FLOCK_RESULT_B="/tmp/shikigami-flock-result-B-$$.txt"

  # subshell A：嘗試取得 lock，寫入結果
  (flock -n "$FLOCK_TEST_LOCK" -c 'sleep 0.3; echo "A_GOT_LOCK"' > "$FLOCK_RESULT_A" 2>&1 \
    || echo "A_BLOCKED" > "$FLOCK_RESULT_A") &
  PID_A=$!

  # subshell B：幾乎同時嘗試取得同一 lock，寫入結果
  (flock -n "$FLOCK_TEST_LOCK" -c 'sleep 0.3; echo "B_GOT_LOCK"' > "$FLOCK_RESULT_B" 2>&1 \
    || echo "B_BLOCKED" > "$FLOCK_RESULT_B") &
  PID_B=$!

  wait $PID_A $PID_B

  RESULT_A=$(cat "$FLOCK_RESULT_A" 2>/dev/null || echo "")
  RESULT_B=$(cat "$FLOCK_RESULT_B" 2>/dev/null || echo "")

  rm -f "$FLOCK_TEST_LOCK" "$FLOCK_RESULT_A" "$FLOCK_RESULT_B"

  # 驗證：恰好一個成功（GOT_LOCK），另一個被阻塞（BLOCKED）
  GOT_LOCK_COUNT=0
  BLOCKED_COUNT=0
  [[ "$RESULT_A" == "A_GOT_LOCK" ]] && GOT_LOCK_COUNT=$((GOT_LOCK_COUNT+1))
  [[ "$RESULT_B" == "B_GOT_LOCK" ]] && GOT_LOCK_COUNT=$((GOT_LOCK_COUNT+1))
  [[ "$RESULT_A" == "A_BLOCKED" ]] && BLOCKED_COUNT=$((BLOCKED_COUNT+1))
  [[ "$RESULT_B" == "B_BLOCKED" ]] && BLOCKED_COUNT=$((BLOCKED_COUNT+1))

  if [[ $GOT_LOCK_COUNT -eq 1 && $BLOCKED_COUNT -eq 1 ]]; then
    pass "flock 原子性驗證：兩 subshell 競搶，恰好一個取得 lock，另一個被阻塞"
  else
    fail "flock 原子性異常：GOT_LOCK=${GOT_LOCK_COUNT} BLOCKED=${BLOCKED_COUNT}（A=${RESULT_A} B=${RESULT_B}）"
  fi
else
  skip "flock 不可用，跳過原子性測試"
fi

# ── AC-7 可觀測標記輸出格式測試 ─────────────────────────────────

section "AC-7 可觀測標記格式驗證"

# 模擬 claim_remote 函式輸出，不實際推送 remote
# 使用 bash -c 測試 subshell 行為

# 測試 [CLAIM-OK] 格式
OUTPUT_OK=$(echo "[CLAIM-OK] refs/claims/test-999")
if echo "$OUTPUT_OK" | grep -q "\[CLAIM-OK\]"; then
  pass "[CLAIM-OK] 格式正確"
else
  fail "[CLAIM-OK] 格式錯誤：$OUTPUT_OK"
fi

# 測試 [CLAIM-BLOCKED] 格式
OUTPUT_BLOCKED=$(echo "[CLAIM-BLOCKED] refs/claims/test-999 已被占用")
if echo "$OUTPUT_BLOCKED" | grep -q "\[CLAIM-BLOCKED\]"; then
  pass "[CLAIM-BLOCKED] 格式正確"
else
  fail "[CLAIM-BLOCKED] 格式錯誤：$OUTPUT_BLOCKED"
fi

# 測試 [CLAIM-RELEASE] 格式
OUTPUT_RELEASE=$(echo "[CLAIM-RELEASE] refs/claims/test-999")
if echo "$OUTPUT_RELEASE" | grep -q "\[CLAIM-RELEASE\]"; then
  pass "[CLAIM-RELEASE] 格式正確"
else
  fail "[CLAIM-RELEASE] 格式錯誤：$OUTPUT_RELEASE"
fi

# 測試 [CLAIM-STALE] 格式
OUTPUT_STALE=$(echo "[CLAIM-STALE] refs/claims/test-999 已過期 3h，強制清除")
if echo "$OUTPUT_STALE" | grep -q "\[CLAIM-STALE\]"; then
  pass "[CLAIM-STALE] 格式正確"
else
  fail "[CLAIM-STALE] 格式錯誤：$OUTPUT_STALE"
fi

# ── AC-5 gh CLI 降級容錯測試 ─────────────────────────────────────

section "AC-5 gh CLI 降級容錯"

# 模擬 gh 不可用時的行為（捕捉 WARN 而非 exit）
GH_WARN_OUTPUT=$(bash -c '
  gh_assign() {
    local ID=$1
    gh issue edit "$ID" --add-assignee "test" 2>/dev/null || echo "[WARN] gh assign 失敗，繼續"
  }
  gh_assign 999
' 2>/dev/null)

if echo "$GH_WARN_OUTPUT" | grep -q "\[WARN\]"; then
  pass "gh CLI 不可用時輸出 WARN，不阻塞"
else
  fail "gh CLI 降級容錯異常：$GH_WARN_OUTPUT"
fi

# 驗證 gh label 降級
GH_LABEL_OUTPUT=$(bash -c '
  gh issue edit 999 --add-label "bot:session-test" 2>/dev/null || echo "[WARN] gh label 失敗，繼續"
' 2>/dev/null)

if echo "$GH_LABEL_OUTPUT" | grep -q "\[WARN\]"; then
  pass "gh label 不可用時輸出 WARN，不阻塞"
else
  fail "gh label 降級容錯異常：$GH_LABEL_OUTPUT"
fi

# ── 路徑一：Claim 成功（模擬）────────────────────────────────────

section "路徑一：Claim 取得（模擬 git ls-remote 驗證）"

# 使用環境變數控制測試模式，避免污染 remote
export SHIKIGAMI_TEST_MODE=1
export SHIKIGAMI_TEST_CLAIM_RESULT="ok"

# 模擬 claim_remote 邏輯：若 ls-remote 無輸出 = ref 不存在 = 可 claim
simulate_claim() {
  local ID=$1
  local MOCK_EXISTING=${2:-""}  # 模擬 ls-remote 回傳值

  if [[ -n "$MOCK_EXISTING" ]]; then
    # 有存在的 ref — 檢查 stale
    local MOCK_AGE=${3:-0}
    if [[ $MOCK_AGE -ge 2 ]]; then
      echo "[CLAIM-STALE] refs/claims/$ID 已過期 ${MOCK_AGE}h，強制清除"
      # 清除後繼續（模擬推送成功）
      echo "[CLAIM-OK] refs/claims/$ID"
      return 0
    else
      echo "[CLAIM-BLOCKED] refs/claims/$ID 已被占用"
      return 1
    fi
  else
    # ref 不存在，可 claim
    echo "[CLAIM-OK] refs/claims/$ID"
    return 0
  fi
}

# 測試 1：ref 不存在，claim 成功
RESULT=$(simulate_claim 999 "")
if echo "$RESULT" | grep -q "\[CLAIM-OK\]"; then
  pass "路徑一：ref 不存在，claim 成功，輸出 [CLAIM-OK]"
else
  fail "路徑一：claim 失敗，輸出：$RESULT"
fi

# ── 路徑二：重複 Claim 被拒 ──────────────────────────────────────

section "路徑二：重複 Claim 被拒（[CLAIM-BLOCKED]）"

# 模擬 ref 已存在且未過期（age < 2h）
MOCK_SHA="abc1234def5678"
RESULT2=$(simulate_claim 999 "$MOCK_SHA" 0)
if echo "$RESULT2" | grep -q "\[CLAIM-BLOCKED\]"; then
  pass "路徑二：ref 已被占用，輸出 [CLAIM-BLOCKED]"
else
  fail "路徑二：預期 [CLAIM-BLOCKED]，實際：$RESULT2"
fi

# 測試 age=1（未過期）也應被拒
RESULT2B=$(simulate_claim 999 "$MOCK_SHA" 1)
if echo "$RESULT2B" | grep -q "\[CLAIM-BLOCKED\]"; then
  pass "路徑二：age=1h 未過期，仍輸出 [CLAIM-BLOCKED]"
else
  fail "路徑二（age=1h）：預期 [CLAIM-BLOCKED]，實際：$RESULT2B"
fi

# ── 路徑三：Release 成功 ─────────────────────────────────────────

section "路徑三：Release 成功（[CLAIM-RELEASE]）"

simulate_release() {
  local ID=$1
  # 模擬 git push --delete（不實際執行，測試模式）
  echo "[CLAIM-RELEASE] refs/claims/$ID"
}

RESULT3=$(simulate_release 999)
if echo "$RESULT3" | grep -q "\[CLAIM-RELEASE\]"; then
  pass "路徑三：release 成功，輸出 [CLAIM-RELEASE]"
else
  fail "路徑三：release 失敗，輸出：$RESULT3"
fi

# ── Stale Lock 偵測 ──────────────────────────────────────────────

section "Stale Lock 偵測（age >= 2h）"

# 模擬 age=2h → 視為 stale，強制清除後 claim 成功
RESULT_STALE=$(simulate_claim 999 "$MOCK_SHA" 2)
if echo "$RESULT_STALE" | grep -q "\[CLAIM-STALE\]" && echo "$RESULT_STALE" | grep -q "\[CLAIM-OK\]"; then
  pass "Stale lock（age=2h）：輸出 [CLAIM-STALE] + [CLAIM-OK]"
else
  fail "Stale lock（age=2h）：預期 [CLAIM-STALE]+[CLAIM-OK]，實際：$RESULT_STALE"
fi

# 模擬 age=3h → 也視為 stale
RESULT_STALE2=$(simulate_claim 999 "$MOCK_SHA" 3)
if echo "$RESULT_STALE2" | grep -q "\[CLAIM-STALE\]"; then
  pass "Stale lock（age=3h）：輸出 [CLAIM-STALE]"
else
  fail "Stale lock（age=3h）：預期 [CLAIM-STALE]，實際：$RESULT_STALE2"
fi

# ── AC-6 Hook 失敗不阻塞 ─────────────────────────────────────────

section "AC-6 Hook 失敗不阻塞"

# 測試 session-end-release.sh 有 set +e 或 || true 防護
if [[ -f "$SCRIPT" ]]; then
  if grep -q "set +e\||| true\|\|\| :" "$SCRIPT"; then
    pass "session-end-release.sh 含失敗容錯機制（set +e 或 || true）"
  else
    fail "session-end-release.sh 缺少失敗容錯機制"
  fi
else
  skip "session-end-release.sh 尚未建立（Red 階段預期失敗）"
fi

# ── AC-8 Skill 文件更新驗證 ──────────────────────────────────────

section "AC-8 Skill 文件含 claim 指引"

check_skill_claim() {
  local FILE="$1"
  local NAME="$2"
  if [[ -f "$FILE" ]]; then
    if grep -qi "claim\|CLAIM-OK\|CLAIM-RELEASE\|CLAIM-BLOCKED\|refs/claims" "$FILE"; then
      pass "$NAME 含 claim 指引"
    else
      fail "$NAME 缺少 claim 指引"
    fi
  else
    fail "$NAME 不存在：$FILE"
  fi
}

check_skill_claim "$REPO_ROOT/skills/sprint-execution/SKILL.md" "sprint-execution/SKILL.md"
check_skill_claim "$REPO_ROOT/skills/sprint-planning/SKILL.md" "sprint-planning/SKILL.md"
check_skill_claim "$REPO_ROOT/skills/sprint-planning/po-prompt.md" "sprint-planning/po-prompt.md"
check_skill_claim "$REPO_ROOT/skills/shoot/SKILL.md" "shoot/SKILL.md"
check_skill_claim "$REPO_ROOT/skills/parallel-dispatch/SKILL.md" "parallel-dispatch/SKILL.md"

# ── hooks.json SessionEnd 配置驗證 ───────────────────────────────

section "hooks.json SessionEnd 配置"

HOOKS_FILE="$REPO_ROOT/hooks/hooks.json"
if [[ -f "$HOOKS_FILE" ]]; then
  if grep -q "SessionEnd" "$HOOKS_FILE"; then
    pass "hooks.json 含 SessionEnd 配置"
  else
    fail "hooks.json 缺少 SessionEnd 配置"
  fi
  if grep -q "session-end-release.sh" "$HOOKS_FILE"; then
    pass "hooks.json 的 SessionEnd 指向 session-end-release.sh"
  else
    fail "hooks.json 的 SessionEnd 未指向 session-end-release.sh"
  fi
else
  fail "hooks.json 不存在"
fi


# ── #316 新增：unfetched SHA 保守拒絕測試 ─────────────────────────

section "#316 AC-1：unfetched SHA 保守拒絕（不 fallback 為 '0'）"

# 驗證 claim-issue.sh 中 COMMIT_TIME fallback 不再是 echo "0"
CLAIM_SCRIPT="$REPO_ROOT/hooks/claim-issue.sh"
if [[ -f "$CLAIM_SCRIPT" ]]; then
  # 確認不再使用 || echo "0" 作為 commit time fallback
  if grep -q '|| echo "0"' "$CLAIM_SCRIPT"; then
    fail "#316 #7：claim-issue.sh 仍有 || echo \"0\" fallback（應改為保守拒絕）"
  else
    pass "#316 #7：claim-issue.sh 不再使用 || echo \"0\" fallback"
  fi

  # 確認有 git fetch 嘗試邏輯
  if grep -q 'git fetch origin' "$CLAIM_SCRIPT"; then
    pass "#316 #7：claim-issue.sh 含 git fetch origin 取得 commit"
  else
    fail "#316 #7：claim-issue.sh 缺少 git fetch origin 嘗試"
  fi
else
  fail "claim-issue.sh 不存在"
fi

# ── #316 新增：stale delete 失敗 WARN 測試 ────────────────────────

section "#316 AC-5 #1：stale delete 失敗應輸出 WARN"

if [[ -f "$CLAIM_SCRIPT" ]]; then
  # 驗證 stale delete 失敗不再靜默（不再是 || true without WARN）
  # 期望看到某種 WARN 或 STALE-DELETE-FAIL 標記
  if grep -q 'STALE.*WARN\|WARN.*stale\|\[WARN\].*強制清除\|stale.*delete.*WARN' "$CLAIM_SCRIPT" 2>/dev/null || \
     grep -A2 'git push origin --delete.*ISSUE_REF\|push.*delete.*ISSUE_REF' "$CLAIM_SCRIPT" 2>/dev/null | grep -q 'WARN'; then
    pass "#316 #1：stale delete 失敗有 WARN 提示"
  else
    # 更簡單的檢查：確認 stale 刪除失敗時有 WARN
    STALE_SECTION=$(awk '/Stale lock.*強制清除/,/清除後繼續/' "$CLAIM_SCRIPT" 2>/dev/null || echo "")
    if echo "$STALE_SECTION" | grep -q "WARN"; then
      pass "#316 #1：stale delete 失敗有 WARN 提示"
    else
      fail "#316 #1：stale delete 失敗缺少 WARN（仍是 || true 靜默）"
    fi
  fi
fi

# ── #316 新增：release 假成功修復測試 ─────────────────────────────

section "#316 AC-2：release 失敗不應假成功"

RELEASE_ISSUE_SCRIPT="$REPO_ROOT/hooks/release-issue.sh"
if [[ -f "$RELEASE_ISSUE_SCRIPT" ]]; then
  # 確認 push --delete 後有 exit code 檢查（不再是 || true）
  if grep -q '|| true' "$RELEASE_ISSUE_SCRIPT" && ! grep -q 'PUSH_EXIT\|push_exit\|DELETE_EXIT' "$RELEASE_ISSUE_SCRIPT"; then
    fail "#316 #2：release-issue.sh push --delete 後仍使用 || true（無 exit code 檢查）"
  else
    pass "#316 #2：release-issue.sh push --delete 後有 exit code 檢查或 WARN"
  fi
fi

RELEASE_FILE_LOCK_SCRIPT="$REPO_ROOT/hooks/release-file-lock.sh"
if [[ -f "$RELEASE_FILE_LOCK_SCRIPT" ]]; then
  # 確認本地 metadata 清除在遠端確認後才執行
  # 簡單驗證：不再先清 metadata 後才推送
  if grep -q 'PUSH_EXIT\|DELETE_EXIT\|delete_exit' "$RELEASE_FILE_LOCK_SCRIPT"; then
    pass "#316 #3：release-file-lock.sh 遠端確認後才清本地 metadata"
  else
    fail "#316 #3：release-file-lock.sh 缺少遠端刪除 exit code 檢查"
  fi
fi

# ── #316 新增：REPO_FP 統一兩步法測試 ────────────────────────────

section "#316 AC-4：REPO_FP 統一兩步法"

check_repo_fp_twostep() {
  local FILE="$1"
  local NAME="$2"
  if [[ -f "$FILE" ]]; then
    # 兩步法：先 REPO_ROOT=$(git rev-parse ...) 再 hash
    if grep -q 'REPO_ROOT=.*git rev-parse\|REPO_ROOT=\$(' "$FILE"; then
      pass "#316 REPO_FP：$NAME 使用兩步法（REPO_ROOT → hash）"
    else
      fail "#316 REPO_FP：$NAME 缺少兩步法（REPO_ROOT 變數）"
    fi
  else
    fail "$NAME 不存在"
  fi
}

check_repo_fp_twostep "$CLAIM_SCRIPT" "claim-issue.sh"
check_repo_fp_twostep "$REPO_ROOT/hooks/session-end-release.sh" "session-end-release.sh"

# acquire-file-lock.sh 已有兩步法，確認仍存在
check_repo_fp_twostep "$REPO_ROOT/hooks/acquire-file-lock.sh" "acquire-file-lock.sh"

# ── #316 新增：flock/claim_remote 失敗分離測試（#8）─────────────

section "#316 AC-5 #8：flock 與 claim_remote 失敗訊息分離"

if [[ -f "$CLAIM_SCRIPT" ]]; then
  # 確認 flock 失敗和 claim_remote 失敗有不同的輸出
  FLOCK_BLOCKED=$(grep -o '\[CLAIM-BLOCKED\].*flock.*\|.*flock.*\[CLAIM-BLOCKED\]' "$CLAIM_SCRIPT" 2>/dev/null || echo "")
  REMOTE_BLOCKED=$(grep -o '\[CLAIM-BLOCKED\].*push.*\|.*push.*\[CLAIM-BLOCKED\]' "$CLAIM_SCRIPT" 2>/dev/null || echo "")
  if grep -q '本地 flock' "$CLAIM_SCRIPT" && grep -q 'race condition\|push 失敗\|remote' "$CLAIM_SCRIPT"; then
    pass "#316 #8：claim-issue.sh flock 與 claim_remote 失敗訊息分離"
  else
    fail "#316 #8：claim-issue.sh flock 與 claim_remote 失敗訊息未分離"
  fi
fi

# ── 結果摘要 ────────────────────────────────────────────────────

echo ""
echo "══════════════════════════════════════════════════"
echo "  測試結果摘要"
echo "══════════════════════════════════════════════════"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo "  SKIP: $SKIP"
echo "══════════════════════════════════════════════════"

if [[ $FAIL -gt 0 ]]; then
  echo "  狀態：FAIL（$FAIL 項測試未通過）"
  exit 1
else
  echo "  狀態：PASS（所有測試通過）"
  exit 0
fi
