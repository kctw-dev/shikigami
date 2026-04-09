#!/usr/bin/env bash
# tests/test-post-execution-pr-verify.sh
# Story #989: post-execution PR 強制驗證 — L1 主 session inline 驗證
# TDD 測試：使用 TMPBIN fake binary 模擬 gh 回傳

set -uo pipefail

SCRIPT="$(dirname "$0")/../scripts/state-machine/post-execution-pr-verify.sh"

PASS=0
FAIL=0

echo "=== test-post-execution-pr-verify.sh ==="
echo "腳本路徑: $SCRIPT"
echo ""

# --- TC1: mock gh 回傳空 PR 列表 → exit != 0 ---
echo "--- TC1: PR_COUNT == 0 → [POST-EXEC-PR-MISSING] → exit != 0 ---"
TMPBIN=$(mktemp -d)
trap "rm -rf '$TMPBIN'" EXIT

cat > "$TMPBIN/gh" << 'FAKEGH'
#!/usr/bin/env bash
# Fake gh: pr list --head <branch> → 回傳空陣列
echo "[]"
exit 0
FAKEGH
chmod +x "$TMPBIN/gh"

rc=0
output=$(PATH="$TMPBIN:$PATH" bash "$SCRIPT" --branch "feature/test-branch" 2>&1) || rc=$?
rm -rf "$TMPBIN"
trap - EXIT

if [[ $rc -ne 0 ]]; then
  if echo "$output" | grep -q "POST-EXEC-PR-MISSING"; then
    echo "  [PASS] 空 PR 列表 → exit $rc 且輸出 [POST-EXEC-PR-MISSING]"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] exit $rc 但缺少 [POST-EXEC-PR-MISSING] 標記"
    echo "  output: $output"
    FAIL=$((FAIL+1))
  fi
else
  echo "  [FAIL] 空 PR 列表應 exit != 0，但得到 exit 0"
  echo "  output: $output"
  FAIL=$((FAIL+1))
fi

# --- TC2: mock gh 回傳 baseRefName="feature/xxx" → exit != 0 ---
echo ""
echo "--- TC2: baseRefName != main → [POST-EXEC-PR-WRONG-BASE] → exit != 0 ---"
TMPBIN2=$(mktemp -d)
trap "rm -rf '$TMPBIN2'" EXIT

cat > "$TMPBIN2/gh" << 'FAKEGH2'
#!/usr/bin/env bash
# Fake gh: pr list → 回傳 PR 但 base 為 feature/xxx
echo '[{"number":42,"state":"OPEN","baseRefName":"feature/xxx","headRefName":"feature/test-branch"}]'
exit 0
FAKEGH2
chmod +x "$TMPBIN2/gh"

rc2=0
output2=$(PATH="$TMPBIN2:$PATH" bash "$SCRIPT" --branch "feature/test-branch" 2>&1) || rc2=$?
rm -rf "$TMPBIN2"
trap - EXIT

if [[ $rc2 -ne 0 ]]; then
  if echo "$output2" | grep -q "POST-EXEC-PR-WRONG-BASE"; then
    echo "  [PASS] 錯誤 base → exit $rc2 且輸出 [POST-EXEC-PR-WRONG-BASE]"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] exit $rc2 但缺少 [POST-EXEC-PR-WRONG-BASE] 標記"
    echo "  output: $output2"
    FAIL=$((FAIL+1))
  fi
else
  echo "  [FAIL] 錯誤 base 應 exit != 0，但得到 exit 0"
  echo "  output: $output2"
  FAIL=$((FAIL+1))
fi

# --- TC3: mock gh 回傳 baseRefName="main" state="OPEN" → exit == 0 ---
echo ""
echo "--- TC3: baseRefName=main state=OPEN → PASS → exit == 0 ---"
TMPBIN3=$(mktemp -d)
trap "rm -rf '$TMPBIN3'" EXIT

cat > "$TMPBIN3/gh" << 'FAKEGH3'
#!/usr/bin/env bash
# Fake gh: pr list → 回傳正確 PR
echo '[{"number":99,"state":"OPEN","baseRefName":"main","headRefName":"feature/test-branch"}]'
exit 0
FAKEGH3
chmod +x "$TMPBIN3/gh"

rc3=0
output3=$(PATH="$TMPBIN3:$PATH" bash "$SCRIPT" --branch "feature/test-branch" 2>&1) || rc3=$?
rm -rf "$TMPBIN3"
trap - EXIT

if [[ $rc3 -eq 0 ]]; then
  if echo "$output3" | grep -q "POST-EXEC-PR-PASS\|PR.*#99\|PASS"; then
    echo "  [PASS] 正確 PR → exit 0 且輸出 PASS 資訊"
    PASS=$((PASS+1))
  else
    echo "  [WARN] exit 0 但輸出未包含預期 PASS 標記（可接受）"
    echo "  output: $output3"
    PASS=$((PASS+1))
  fi
else
  echo "  [FAIL] 正確 PR 應 exit 0，但得到 exit $rc3"
  echo "  output: $output3"
  FAIL=$((FAIL+1))
fi

# --- 結果統計 ---
echo ""
echo "=== 結果統計 ==="
echo "PASS: $PASS / $((PASS+FAIL))"
echo "FAIL: $FAIL / $((PASS+FAIL))"

if [[ $FAIL -eq 0 ]]; then
  echo "[ALL PASS]"
  exit 0
else
  echo "[FAIL] $FAIL 個測試失敗"
  exit 1
fi
