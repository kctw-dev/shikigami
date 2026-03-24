#!/usr/bin/env bash
# tests/test-sprint-status-update.sh
# Issue #644 — retro: sprint_N.md TODO→DONE 狀態更新邏輯驗證
# 驗證以 Issue ID 定位資料列、取代最後一欄（狀態欄）的替換邏輯

set -uo pipefail

# ---------------------------------------------------------------------------
# 測試框架
# ---------------------------------------------------------------------------
PASS_COUNT=0
FAIL_COUNT=0

pass() {
  echo "PASS: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "FAIL: $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

# ---------------------------------------------------------------------------
# 替換函式：以 Issue ID 定位列，取代最後一欄值
# 用法：update_sprint_status <file> <issue_id> <new_status>
# ---------------------------------------------------------------------------
update_sprint_status() {
  local file="$1"
  local issue_id="$2"
  local new_status="$3"

  # 找到含 Issue ID 的精確欄位（| #NNN |），將最後一欄值替換
  # 使用 pipe-delimited 匹配避免 substring 誤命中（如 #63 不會匹配 #637）
  sed -i -E "/\\| ${issue_id} \\|/s/\\| [^|]+ \\|$/| ${new_status} |/" "$file"
}

# ---------------------------------------------------------------------------
# Setup: 建立暫存測試目錄
# ---------------------------------------------------------------------------
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "=== test-sprint-status-update.sh ==="
echo ""

# ---------------------------------------------------------------------------
# TC-1: 正常情境 — 8 欄表格（含 ADR 欄），TODO → DONE(#640)
# ---------------------------------------------------------------------------
cat > "$TMPDIR/sprint_140.md" << 'EOF'
## Sprint Backlog

| Story | Issue | Type | Size | Points | ADR | 負責人 | 狀態 |
|-------|-------|------|------|--------|-----|--------|------|
| retro: CI Token 輪換 | #637 | INFRA | S | 1 | 無需 | Developer | TODO |
| feat: Crash Recovery | #405 | FEATURE | M | 2 | ADR-041 ✓ | Developer | TODO |
| feat: Session Watchdog | #408 | FEATURE | M | 2 | ADR-042 ✓ | Developer | TODO |
EOF

update_sprint_status "$TMPDIR/sprint_140.md" "#637" "DONE(#640)"

if grep -q '| #637 |.*| DONE(#640) |' "$TMPDIR/sprint_140.md"; then
  pass "TC-1: 8 欄表格 #637 TODO → DONE(#640) 替換成功"
else
  fail "TC-1: 8 欄表格 #637 TODO → DONE(#640) 替換失敗"
fi

# 確認其他列未被修改
if grep -q '| #405 |.*| TODO |' "$TMPDIR/sprint_140.md"; then
  pass "TC-1b: #405 列未受影響"
else
  fail "TC-1b: #405 列被意外修改"
fi

# ---------------------------------------------------------------------------
# TC-2: 邊界情境 — ADR 欄含特殊字元（ADR-041 ✓）
# ---------------------------------------------------------------------------
update_sprint_status "$TMPDIR/sprint_140.md" "#405" "DONE(#641)"

if grep -q '| #405 |.*| ADR-041 ✓ |.*| DONE(#641) |' "$TMPDIR/sprint_140.md"; then
  pass "TC-2: ADR 含特殊字元時替換正確"
else
  fail "TC-2: ADR 含特殊字元時替換失敗"
fi

# ---------------------------------------------------------------------------
# TC-3: 負向情境 — Issue ID 不存在時不修改
# ---------------------------------------------------------------------------
BEFORE=$(cat "$TMPDIR/sprint_140.md")
update_sprint_status "$TMPDIR/sprint_140.md" "#999" "DONE(#999)"
AFTER=$(cat "$TMPDIR/sprint_140.md")

if [[ "$BEFORE" == "$AFTER" ]]; then
  pass "TC-3: 不存在的 Issue ID #999 未修改任何列"
else
  fail "TC-3: 不存在的 Issue ID #999 意外修改了內容"
fi

# ---------------------------------------------------------------------------
# TC-4: 7 欄舊格式表格（無 ADR 欄）也能正確替換
# ---------------------------------------------------------------------------
cat > "$TMPDIR/sprint_old.md" << 'EOF'
| Story | Issue | Type | Size | Points | 負責人 | 狀態 |
|-------|-------|------|------|--------|--------|------|
| fix: Bug | #100 | BUG | S | 1 | Developer | TODO |
EOF

update_sprint_status "$TMPDIR/sprint_old.md" "#100" "DONE(#200)"

if grep -q '| #100 |.*| DONE(#200) |' "$TMPDIR/sprint_old.md"; then
  pass "TC-4: 7 欄舊格式替換成功（向後相容）"
else
  fail "TC-4: 7 欄舊格式替換失敗"
fi

# ---------------------------------------------------------------------------
# TC-5: 多個 Story 連續替換
# ---------------------------------------------------------------------------
update_sprint_status "$TMPDIR/sprint_140.md" "#408" "DONE(#642)"

DONE_COUNT=$(grep -c 'DONE(#' "$TMPDIR/sprint_140.md")
if [[ "$DONE_COUNT" -eq 3 ]]; then
  pass "TC-5: 3 個 Story 全部替換為 DONE"
else
  fail "TC-5: 預期 3 個 DONE，實際 ${DONE_COUNT} 個"
fi

# ---------------------------------------------------------------------------
# TC-6: 表頭行（| 狀態 |）不被替換
# ---------------------------------------------------------------------------
if grep -q '| 狀態 |' "$TMPDIR/sprint_140.md"; then
  pass "TC-6: 表頭行未被替換"
else
  fail "TC-6: 表頭行被意外修改"
fi

# ---------------------------------------------------------------------------
# TC-7: Substring 防護 — #63 不會誤命中 #637
# ---------------------------------------------------------------------------
cat > "$TMPDIR/sprint_substring.md" << 'EOF'
| Story | Issue | Type | Size | Points | ADR | 負責人 | 狀態 |
|-------|-------|------|------|--------|-----|--------|------|
| feat: Short ID | #63 | FEATURE | S | 1 | 無需 | Developer | TODO |
| feat: Long ID | #637 | FEATURE | S | 1 | 無需 | Developer | TODO |
EOF

update_sprint_status "$TMPDIR/sprint_substring.md" "#63" "DONE(#700)"

if grep -q '| #63 |.*| DONE(#700) |' "$TMPDIR/sprint_substring.md"; then
  pass "TC-7a: #63 正確替換為 DONE(#700)"
else
  fail "TC-7a: #63 替換失敗"
fi

if grep -q '| #637 |.*| TODO |' "$TMPDIR/sprint_substring.md"; then
  pass "TC-7b: #637 未被 #63 的 substring 誤命中"
else
  fail "TC-7b: #637 被 #63 的 substring 誤命中"
fi

# ---------------------------------------------------------------------------
# 結果摘要
# ---------------------------------------------------------------------------
echo ""
echo "=== 結果：${PASS_COUNT} PASS / ${FAIL_COUNT} FAIL ==="

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi
exit 0
