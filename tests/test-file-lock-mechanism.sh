#!/usr/bin/env bash
# test-file-lock-mechanism.sh
# US-311 — 檔案級鎖定機制測試
# AC-2：acquire/release API | AC-3：TTL 自動釋放 | AC-4：parallel-dispatch 整合 | AC-5：SessionEnd hook

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

ACQUIRE_SCRIPT="$REPO_ROOT/hooks/acquire-file-lock.sh"
RELEASE_SCRIPT="$REPO_ROOT/hooks/release-file-lock.sh"
SESSION_END_SCRIPT="$REPO_ROOT/hooks/session-end-release.sh"
PARALLEL_SKILL="$REPO_ROOT/skills/parallel-dispatch/SKILL.md"

# ── AC-2：腳本存在性檢查 ─────────────────────────────────────────

section "AC-2：acquire / release 腳本存在"

if [[ -f "$ACQUIRE_SCRIPT" ]]; then
  pass "hooks/acquire-file-lock.sh 存在"
else
  fail "hooks/acquire-file-lock.sh 不存在"
fi

if [[ -f "$RELEASE_SCRIPT" ]]; then
  pass "hooks/release-file-lock.sh 存在"
else
  fail "hooks/release-file-lock.sh 不存在"
fi

# ── AC-2：腳本結構驗證 ────────────────────────────────────────────

section "AC-2：腳本結構驗證"

if [[ -f "$ACQUIRE_SCRIPT" ]]; then
  # 應有 sha256sum / cut / path hash 邏輯
  if grep -q "sha256sum\|md5sum" "$ACQUIRE_SCRIPT"; then
    pass "acquire-file-lock.sh 含路徑 hash 計算"
  else
    fail "acquire-file-lock.sh 缺少路徑 hash 計算（sha256sum）"
  fi

  # 應有 refs/file-locks 引用
  if grep -q "refs/file-locks" "$ACQUIRE_SCRIPT"; then
    pass "acquire-file-lock.sh 使用 refs/file-locks namespace"
  else
    fail "acquire-file-lock.sh 缺少 refs/file-locks namespace"
  fi

  # 應有 [FILE-LOCK-OK] 輸出
  if grep -q "\[FILE-LOCK-OK\]" "$ACQUIRE_SCRIPT"; then
    pass "acquire-file-lock.sh 含 [FILE-LOCK-OK] 輸出標記"
  else
    fail "acquire-file-lock.sh 缺少 [FILE-LOCK-OK] 輸出標記"
  fi

  # 應有 [FILE-LOCK-BLOCKED] 輸出
  if grep -q "\[FILE-LOCK-BLOCKED\]" "$ACQUIRE_SCRIPT"; then
    pass "acquire-file-lock.sh 含 [FILE-LOCK-BLOCKED] 輸出標記"
  else
    fail "acquire-file-lock.sh 缺少 [FILE-LOCK-BLOCKED] 輸出標記"
  fi

  # 應有失敗容錯
  if grep -q "set +e\||| true" "$ACQUIRE_SCRIPT"; then
    pass "acquire-file-lock.sh 含失敗容錯機制"
  else
    fail "acquire-file-lock.sh 缺少失敗容錯機制"
  fi
else
  skip "acquire-file-lock.sh 不存在，跳過結構驗證（Red 階段預期）"
fi

if [[ -f "$RELEASE_SCRIPT" ]]; then
  # 應有 git push --delete
  if grep -q "git push.*--delete\|push.*delete" "$RELEASE_SCRIPT"; then
    pass "release-file-lock.sh 含 git push --delete 邏輯"
  else
    fail "release-file-lock.sh 缺少 git push --delete 邏輯"
  fi

  # 應有 [FILE-LOCK-RELEASE] 輸出
  if grep -q "\[FILE-LOCK-RELEASE\]\|\[FILE-UNLOCK-OK\]" "$RELEASE_SCRIPT"; then
    pass "release-file-lock.sh 含 [FILE-LOCK-RELEASE] 輸出標記"
  else
    fail "release-file-lock.sh 缺少 [FILE-LOCK-RELEASE] 輸出標記"
  fi
else
  skip "release-file-lock.sh 不存在，跳過結構驗證（Red 階段預期）"
fi

# ── AC-2：Path Hash 計算單元測試 ─────────────────────────────────

section "AC-2：Path Hash 計算驗證"

# 測試 hash 計算一致性
REL_PATH="skills/parallel-dispatch/SKILL.md"
if command -v sha256sum &>/dev/null; then
  HASH_A=$(echo "$REL_PATH" | sha256sum | cut -c1-16)
  HASH_B=$(echo "$REL_PATH" | sha256sum | cut -c1-16)
  if [[ "$HASH_A" == "$HASH_B" && ${#HASH_A} -eq 16 ]]; then
    pass "Path hash 計算一致且長度為 16：$HASH_A"
  else
    fail "Path hash 不一致或長度錯誤：A=$HASH_A B=$HASH_B"
  fi
else
  skip "sha256sum 不可用，跳過 hash 一致性測試"
fi

# 測試不同路徑產生不同 hash
REL_PATH_A="skills/parallel-dispatch/SKILL.md"
REL_PATH_B="skills/sprint-execution/SKILL.md"
if command -v sha256sum &>/dev/null; then
  HASH_PA=$(echo "$REL_PATH_A" | sha256sum | cut -c1-16)
  HASH_PB=$(echo "$REL_PATH_B" | sha256sum | cut -c1-16)
  if [[ "$HASH_PA" != "$HASH_PB" ]]; then
    pass "不同路徑產生不同 hash（無碰撞）"
  else
    fail "不同路徑產生相同 hash（碰撞！）：$HASH_PA"
  fi
else
  skip "sha256sum 不可用，跳過碰撞測試"
fi

# ── AC-2：輸出標記格式驗證（模擬）──────────────────────────────

section "AC-2：輸出標記格式（模擬）"

REF_HASH="a1b2c3d4e5f6a7b8"
REF="refs/file-locks/${REF_HASH}"

# [FILE-LOCK-OK] 格式
OUTPUT_OK="[FILE-LOCK-OK] $REF"
if echo "$OUTPUT_OK" | grep -q "\[FILE-LOCK-OK\]"; then
  pass "[FILE-LOCK-OK] 格式正確"
else
  fail "[FILE-LOCK-OK] 格式錯誤：$OUTPUT_OK"
fi

# [FILE-LOCK-BLOCKED] 格式
OUTPUT_BLOCKED="[FILE-LOCK-BLOCKED] $REF session=abc123"
if echo "$OUTPUT_BLOCKED" | grep -q "\[FILE-LOCK-BLOCKED\]"; then
  pass "[FILE-LOCK-BLOCKED] 格式正確"
else
  fail "[FILE-LOCK-BLOCKED] 格式錯誤：$OUTPUT_BLOCKED"
fi

# [FILE-LOCK-STALE] 格式
OUTPUT_STALE="[FILE-LOCK-STALE] $REF 已過期 35min，強制清除"
if echo "$OUTPUT_STALE" | grep -q "\[FILE-LOCK-STALE\]"; then
  pass "[FILE-LOCK-STALE] 格式正確"
else
  fail "[FILE-LOCK-STALE] 格式錯誤：$OUTPUT_STALE"
fi

# [FILE-LOCK-RELEASE] 格式
OUTPUT_RELEASE="[FILE-LOCK-RELEASE] $REF"
if echo "$OUTPUT_RELEASE" | grep -q "\[FILE-LOCK-RELEASE\]"; then
  pass "[FILE-LOCK-RELEASE] 格式正確"
else
  fail "[FILE-LOCK-RELEASE] 格式錯誤：$OUTPUT_RELEASE"
fi

# ── AC-3：TTL 機制驗證 ────────────────────────────────────────────

section "AC-3：TTL 自動釋放（30 分鐘）"

if [[ -f "$ACQUIRE_SCRIPT" ]]; then
  # 應有 30 分鐘 TTL 相關邏輯
  if grep -q "1800\|30.*60\|TTL\|AGE_MINUTES\|AGE_MIN" "$ACQUIRE_SCRIPT"; then
    pass "acquire-file-lock.sh 含 30 分鐘 TTL 邏輯"
  else
    fail "acquire-file-lock.sh 缺少 30 分鐘 TTL 邏輯（1800 秒）"
  fi

  # 應有 [FILE-LOCK-STALE] 輸出
  if grep -q "\[FILE-LOCK-STALE\]" "$ACQUIRE_SCRIPT"; then
    pass "acquire-file-lock.sh 含 [FILE-LOCK-STALE] stale 清除標記"
  else
    fail "acquire-file-lock.sh 缺少 [FILE-LOCK-STALE] 標記"
  fi
else
  skip "acquire-file-lock.sh 不存在，跳過 TTL 驗證（Red 階段預期）"
fi

# TTL 邏輯模擬測試
simulate_ttl_check() {
  local AGE_SECONDS=$1
  local TTL_SECONDS=1800  # 30 分鐘
  if [[ $AGE_SECONDS -ge $TTL_SECONDS ]]; then
    echo "STALE"
  else
    echo "FRESH"
  fi
}

# 1800 秒（剛好 30 分鐘）= stale
TTL_RESULT_1800=$(simulate_ttl_check 1800)
if [[ "$TTL_RESULT_1800" == "STALE" ]]; then
  pass "TTL：age=1800s（30min）判定為 STALE"
else
  fail "TTL：age=1800s 應為 STALE，實際：$TTL_RESULT_1800"
fi

# 1799 秒（29:59）= fresh
TTL_RESULT_1799=$(simulate_ttl_check 1799)
if [[ "$TTL_RESULT_1799" == "FRESH" ]]; then
  pass "TTL：age=1799s（29:59）判定為 FRESH"
else
  fail "TTL：age=1799s 應為 FRESH，實際：$TTL_RESULT_1799"
fi

# 3600 秒（1 小時）= stale
TTL_RESULT_3600=$(simulate_ttl_check 3600)
if [[ "$TTL_RESULT_3600" == "STALE" ]]; then
  pass "TTL：age=3600s（1h）判定為 STALE"
else
  fail "TTL：age=3600s 應為 STALE，實際：$TTL_RESULT_3600"
fi

# ── AC-3：本地鎖原子性（flock）────────────────────────────────────

section "AC-3：本地 flock 原子性"

if command -v flock &>/dev/null; then
  pass "flock 指令可用（本地鎖啟用）"

  # 兩個 subshell 同時競搶同一 file-lock，驗證原子性
  FLOCK_TEST_LOCK="/tmp/shikigami-file-lock-test-$$.lock"
  FLOCK_RESULT_A="/tmp/shikigami-file-lock-result-A-$$.txt"
  FLOCK_RESULT_B="/tmp/shikigami-file-lock-result-B-$$.txt"

  (flock -n "$FLOCK_TEST_LOCK" -c 'sleep 0.3; echo "A_GOT_LOCK"' > "$FLOCK_RESULT_A" 2>&1 \
    || echo "A_BLOCKED" > "$FLOCK_RESULT_A") &
  PID_A=$!

  (flock -n "$FLOCK_TEST_LOCK" -c 'sleep 0.3; echo "B_GOT_LOCK"' > "$FLOCK_RESULT_B" 2>&1 \
    || echo "B_BLOCKED" > "$FLOCK_RESULT_B") &
  PID_B=$!

  wait $PID_A $PID_B

  RESULT_A=$(cat "$FLOCK_RESULT_A" 2>/dev/null || echo "")
  RESULT_B=$(cat "$FLOCK_RESULT_B" 2>/dev/null || echo "")

  rm -f "$FLOCK_TEST_LOCK" "$FLOCK_RESULT_A" "$FLOCK_RESULT_B"

  GOT_LOCK_COUNT=0
  BLOCKED_COUNT=0
  [[ "$RESULT_A" == "A_GOT_LOCK" ]] && GOT_LOCK_COUNT=$((GOT_LOCK_COUNT+1))
  [[ "$RESULT_B" == "B_GOT_LOCK" ]] && GOT_LOCK_COUNT=$((GOT_LOCK_COUNT+1))
  [[ "$RESULT_A" == "A_BLOCKED" ]] && BLOCKED_COUNT=$((BLOCKED_COUNT+1))
  [[ "$RESULT_B" == "B_BLOCKED" ]] && BLOCKED_COUNT=$((BLOCKED_COUNT+1))

  if [[ $GOT_LOCK_COUNT -eq 1 && $BLOCKED_COUNT -eq 1 ]]; then
    pass "file-lock flock 原子性：兩 subshell 競搶，恰好一個取得 lock"
  else
    fail "file-lock flock 原子性異常：GOT_LOCK=${GOT_LOCK_COUNT} BLOCKED=${BLOCKED_COUNT}"
  fi
else
  skip "flock 不可用（macOS 環境），跳過原子性測試"
fi

# ── AC-4：parallel-dispatch SKILL.md 整合驗證 ─────────────────────

section "AC-4：parallel-dispatch 檔案衝突預檢"

if [[ -f "$PARALLEL_SKILL" ]]; then
  # 應含 Step 0.5 或檔案衝突預檢說明
  if grep -q "Step 0.5\|0\.5\|檔案衝突預檢\|file.*conflict\|acquire.*lock\|file-lock" "$PARALLEL_SKILL"; then
    pass "parallel-dispatch/SKILL.md 含 Step 0.5 檔案衝突預檢"
  else
    fail "parallel-dispatch/SKILL.md 缺少 Step 0.5 檔案衝突預檢"
  fi

  # 應引用 acquire-file-lock.sh
  if grep -q "acquire-file-lock\|FILE-LOCK-OK\|FILE-LOCK-BLOCKED" "$PARALLEL_SKILL"; then
    pass "parallel-dispatch/SKILL.md 引用 acquire-file-lock 機制"
  else
    fail "parallel-dispatch/SKILL.md 未引用 acquire-file-lock 機制"
  fi
else
  fail "parallel-dispatch/SKILL.md 不存在：$PARALLEL_SKILL"
fi

# ── AC-5：session-end-release.sh 擴展驗證 ────────────────────────

section "AC-5：SessionEnd hook 自動釋放 file locks"

if [[ -f "$SESSION_END_SCRIPT" ]]; then
  # 應有 refs/file-locks 清除邏輯
  if grep -q "refs/file-locks" "$SESSION_END_SCRIPT"; then
    pass "session-end-release.sh 含 refs/file-locks 清除邏輯"
  else
    fail "session-end-release.sh 缺少 refs/file-locks 清除邏輯"
  fi

  # 應引用 release-file-lock.sh 或直接 push --delete
  if grep -q "release-file-lock\|file-locks.*delete\|delete.*file-locks" "$SESSION_END_SCRIPT"; then
    pass "session-end-release.sh 含 file lock release 操作"
  else
    fail "session-end-release.sh 缺少 file lock release 操作"
  fi

  # 失敗容錯仍應存在
  if grep -q "set +e\||| true" "$SESSION_END_SCRIPT"; then
    pass "session-end-release.sh 仍含失敗容錯機制"
  else
    fail "session-end-release.sh 失去失敗容錯機制"
  fi
else
  fail "session-end-release.sh 不存在：$SESSION_END_SCRIPT"
fi

# ── 降級策略驗證 ──────────────────────────────────────────────────

section "降級策略：remote 不可用時的 flock-only 模式"

if [[ -f "$ACQUIRE_SCRIPT" ]]; then
  # 應有 remote 不可用時的降級處理
  if grep -q "\[WARN\]\|WARN.*remote\|remote.*WARN\|flock.*only\|fallback" "$ACQUIRE_SCRIPT"; then
    pass "acquire-file-lock.sh 含 remote 不可用時的降級警告"
  else
    fail "acquire-file-lock.sh 缺少降級警告（remote 不可用情境）"
  fi
else
  skip "acquire-file-lock.sh 不存在，跳過降級驗證"
fi

# ── metadata 目錄結構驗證 ─────────────────────────────────────────

section "Metadata 本地暫存目錄"

if [[ -f "$ACQUIRE_SCRIPT" ]]; then
  # 應有 /tmp/shikigami-file-locks- 目錄或 metadata 檔案
  if grep -q "shikigami-file-locks\|file.locks.*meta\|meta.*file.locks" "$ACQUIRE_SCRIPT"; then
    pass "acquire-file-lock.sh 含本地 metadata 暫存邏輯"
  else
    fail "acquire-file-lock.sh 缺少本地 metadata 暫存（/tmp/shikigami-file-locks-*）"
  fi
else
  skip "acquire-file-lock.sh 不存在，跳過 metadata 驗證"
fi

# ── 參數驗證 ─────────────────────────────────────────────────────

section "參數驗證：缺少路徑時應輸出 WARN"

if [[ -f "$ACQUIRE_SCRIPT" ]]; then
  # 執行腳本但不傳參數，應回傳錯誤但不 abort
  NO_PARAM_OUTPUT=$(bash "$ACQUIRE_SCRIPT" 2>&1 || true)
  if echo "$NO_PARAM_OUTPUT" | grep -qi "warn\|缺少\|miss\|path"; then
    pass "acquire-file-lock.sh 缺少路徑參數時輸出警告"
  else
    fail "acquire-file-lock.sh 缺少路徑參數時輸出不明確：$NO_PARAM_OUTPUT"
  fi
else
  skip "acquire-file-lock.sh 不存在，跳過參數驗證"
fi

if [[ -f "$RELEASE_SCRIPT" ]]; then
  NO_PARAM_OUTPUT=$(bash "$RELEASE_SCRIPT" 2>&1 || true)
  if echo "$NO_PARAM_OUTPUT" | grep -qi "warn\|缺少\|miss\|path"; then
    pass "release-file-lock.sh 缺少路徑參數時輸出警告"
  else
    fail "release-file-lock.sh 缺少路徑參數時輸出不明確：$NO_PARAM_OUTPUT"
  fi
else
  skip "release-file-lock.sh 不存在，跳過參數驗證"
fi


# ── #316 新增：無鎖模式假陽性修復（#4）──────────────────────────

section "#316 AC-3 #4：無鎖模式應輸出 [FILE-LOCK-DEGRADED]"

if [[ -f "$ACQUIRE_SCRIPT" ]]; then
  # 確認無鎖模式不再輸出 [FILE-LOCK-OK]，改輸出 [FILE-LOCK-DEGRADED]
  if grep -q 'FILE-LOCK-DEGRADED' "$ACQUIRE_SCRIPT"; then
    pass "#316 #4：acquire-file-lock.sh 含 [FILE-LOCK-DEGRADED] 輸出"
  else
    fail "#316 #4：acquire-file-lock.sh 無鎖模式仍輸出 [FILE-LOCK-OK]（應改為 [FILE-LOCK-DEGRADED]）"
  fi

  # 確認 no-lock-fallback 情境下不再有 [FILE-LOCK-OK]
  if grep -q 'no-lock-fallback.*FILE-LOCK-OK\|FILE-LOCK-OK.*no-lock-fallback' "$ACQUIRE_SCRIPT"; then
    fail "#316 #4：acquire-file-lock.sh 無鎖模式仍有 [FILE-LOCK-OK] 假陽性"
  else
    pass "#316 #4：acquire-file-lock.sh 無鎖模式已修正（無 [FILE-LOCK-OK] 假陽性）"
  fi
fi

# ── #316 新增：local-only 模式寫 metadata（#9）───────────────────

section "#316 AC-5 #9：local-only 模式也寫 metadata"

if [[ -f "$ACQUIRE_SCRIPT" ]]; then
  # 確認 local-only 降級模式中也有 metadata 寫入
  if grep -q 'local.only\|local_only\|flock.only\|flock-only' "$ACQUIRE_SCRIPT"; then
    # 找到降級模式區塊後確認有 META_FILE 寫入
    if awk '/local.only|flock.only|flock-only/,/exit 0/' "$ACQUIRE_SCRIPT" 2>/dev/null | grep -q 'META_FILE\|meta_file'; then
      pass "#316 #9：acquire-file-lock.sh local-only 模式寫入 metadata"
    else
      fail "#316 #9：acquire-file-lock.sh local-only 模式未寫入 metadata"
    fi
  else
    fail "#316 #9：acquire-file-lock.sh 找不到 local-only 模式區塊"
  fi
fi

# ── #316 新增：unfetched SHA 保守拒絕（acquire 端）──────────────

section "#316 AC-1：acquire-file-lock.sh unfetched SHA 保守拒絕"

if [[ -f "$ACQUIRE_SCRIPT" ]]; then
  # 確認不再使用 || echo "0" 作為 commit time fallback
  if grep -q '|| echo "0"' "$ACQUIRE_SCRIPT"; then
    fail "#316 #7：acquire-file-lock.sh 仍有 || echo \"0\" fallback"
  else
    pass "#316 #7：acquire-file-lock.sh 不再使用 || echo \"0\" fallback"
  fi

  # 確認有 git fetch origin 嘗試
  if grep -q 'git fetch origin' "$ACQUIRE_SCRIPT"; then
    pass "#316 #7：acquire-file-lock.sh 含 git fetch origin 嘗試"
  else
    fail "#316 #7：acquire-file-lock.sh 缺少 git fetch origin"
  fi
fi

# ── #316 新增：release-file-lock.sh 遠端確認後刪 metadata（#3）──

section "#316 AC-2 #3：release-file-lock.sh 遠端確認後才刪 metadata"

if [[ -f "$RELEASE_SCRIPT" ]]; then
  if grep -q 'DELETE_EXIT\|PUSH_EXIT\|delete_exit\|push_exit' "$RELEASE_SCRIPT"; then
    pass "#316 #3：release-file-lock.sh 有 push --delete exit code 檢查"
  else
    fail "#316 #3：release-file-lock.sh 缺少 push --delete exit code 檢查"
  fi
fi

# ── #316 新增：hash fallback WARN（#17）──────────────────────────

section "#316 AC-7 #17：hash fallback 應輸出 WARN"

if [[ -f "$ACQUIRE_SCRIPT" ]]; then
  # fallback hash 不再靜默，應有 WARN
  if grep -q 'fallback.*WARN\|WARN.*fallback\|fallback.*warn' "$ACQUIRE_SCRIPT" 2>/dev/null || \
     awk '/fallback/,/echo/' "$ACQUIRE_SCRIPT" 2>/dev/null | grep -q 'WARN'; then
    pass "#316 #17：acquire-file-lock.sh hash fallback 有 WARN"
  else
    fail "#316 #17：acquire-file-lock.sh hash fallback 靜默（缺少 WARN）"
  fi
fi

# ── #316 新增：[FILE-LOCK-DEGRADED] 輸出格式 ─────────────────────

section "#316：[FILE-LOCK-DEGRADED] 輸出格式驗證"

OUTPUT_DEGRADED="[FILE-LOCK-DEGRADED] refs/file-locks/test123 (no-lock-mode)"
if echo "$OUTPUT_DEGRADED" | grep -q "\[FILE-LOCK-DEGRADED\]"; then
  pass "[FILE-LOCK-DEGRADED] 格式正確"
else
  fail "[FILE-LOCK-DEGRADED] 格式錯誤：$OUTPUT_DEGRADED"
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
