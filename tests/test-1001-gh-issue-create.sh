#!/usr/bin/env bash
# tests/test-1001-gh-issue-create.sh
# Issue #1001：gh-issue-create.sh helper 測試
#
# 覆蓋 AC：
#   AC1 — script 存在、可執行、封裝 --body-file 模式
#   AC2 — 自動建立暫存檔、寫入 body、清理暫存檔（trap）
#   AC3 — 含冒號 / 星號 / 引號 / 反引號的 body 完整保留（dry-run 驗證）
#   AC4 — body 來源三選一互斥檢查（--body / --body-file / stdin）
#   AC5 — 必要參數缺失 / 未知參數時應失敗

set -uo pipefail

# ---------------------------------------------------------------------------
# 測試框架
# ---------------------------------------------------------------------------
PASS_COUNT=0
FAIL_COUNT=0

pass() { echo "PASS: $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { echo "FAIL: $1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

assert_eq() {
  local expected="$1" actual="$2" label="$3"
  if [[ "$expected" == "$actual" ]]; then
    pass "$label"
  else
    fail "$label (期望 [$expected]，實際 [$actual])"
  fi
}

assert_contains() {
  local haystack="$1" needle="$2" label="$3"
  if printf '%s' "$haystack" | grep -qF -- "$needle"; then
    pass "$label"
  else
    fail "$label (找不到子字串：[$needle])"
  fi
}

assert_not_contains() {
  local haystack="$1" needle="$2" label="$3"
  if printf '%s' "$haystack" | grep -qF -- "$needle"; then
    fail "$label (不應出現的子字串：[$needle])"
  else
    pass "$label"
  fi
}

# ---------------------------------------------------------------------------
# 設定
# ---------------------------------------------------------------------------
SCRIPT_PATH="$(cd "$(dirname "$0")/.." && pwd)/scripts/gh-issue-create.sh"

# AC1：script 存在 + 可執行
[[ -f "$SCRIPT_PATH" ]] && pass "AC1.1 script 存在：$SCRIPT_PATH" \
  || { fail "AC1.1 script 不存在：$SCRIPT_PATH"; exit 1; }
[[ -x "$SCRIPT_PATH" ]] && pass "AC1.2 script 可執行" \
  || fail "AC1.2 script 缺少 +x 權限"

# AC1.3：原始檔有呼叫 --body-file
if grep -q -- "--body-file" "$SCRIPT_PATH"; then
  pass "AC1.3 內部使用 --body-file 模式"
else
  fail "AC1.3 內部未使用 --body-file 模式"
fi

# ---------------------------------------------------------------------------
# AC3：特殊字元 dry-run 驗證
# ---------------------------------------------------------------------------
SPECIAL_BODY=$'冒號：以及 *星號*\n單引號 \' 雙引號 " 反引號 `code`\n還有 YAML 危險的 - dash 開頭'

OUT=$(bash "$SCRIPT_PATH" --title "test: 特殊字元 dry-run" --body "$SPECIAL_BODY" --dry-run 2>&1)

assert_contains "$OUT" "冒號："                   "AC3.1 dry-run 保留冒號"
assert_contains "$OUT" "*星號*"                   "AC3.2 dry-run 保留星號"
assert_contains "$OUT" "單引號 '"                 "AC3.3 dry-run 保留單引號"
assert_contains "$OUT" '雙引號 "'                 "AC3.4 dry-run 保留雙引號"
assert_contains "$OUT" '反引號 `code`'            "AC3.5 dry-run 保留反引號"
assert_contains "$OUT" "- dash 開頭"              "AC3.6 dry-run 保留 dash 開頭行"
assert_contains "$OUT" "----- BEGIN BODY -----"   "AC3.7 dry-run 輸出包含 body 區塊"
assert_contains "$OUT" "--body-file"              "AC3.8 dry-run 顯示的指令含 --body-file"

# AC2：dry-run 提到暫存檔；正式呼叫透過 trap 清理（無法直接驗 trap，但可驗 dry-run 顯示路徑）
assert_contains "$OUT" "[DRY-RUN] 暫存 body 檔案：" "AC2.1 dry-run 顯示暫存檔路徑"

# ---------------------------------------------------------------------------
# AC3 補強：用 --body-file 來源也應保留特殊字元
# ---------------------------------------------------------------------------
TMP_INPUT=$(mktemp -t test-1001-input.XXXXXX)
trap 'rm -f "$TMP_INPUT"' EXIT
printf '%s\n' "$SPECIAL_BODY" > "$TMP_INPUT"

OUT2=$(bash "$SCRIPT_PATH" --title "test: body-file" --body-file "$TMP_INPUT" --dry-run 2>&1)
assert_contains "$OUT2" "冒號："  "AC3.9 --body-file 來源保留冒號"
assert_contains "$OUT2" "*星號*"  "AC3.10 --body-file 來源保留星號"

# AC3 補強：stdin 來源
OUT3=$(printf '%s\n' "$SPECIAL_BODY" | bash "$SCRIPT_PATH" --title "test: stdin" - --dry-run 2>&1)
assert_contains "$OUT3" "冒號："  "AC3.11 stdin 來源保留冒號"
assert_contains "$OUT3" "*星號*"  "AC3.12 stdin 來源保留星號"

# ---------------------------------------------------------------------------
# AC4：body 來源互斥
# ---------------------------------------------------------------------------
OUT4=$(bash "$SCRIPT_PATH" --title "x" --body "a" --body-file "$TMP_INPUT" --dry-run 2>&1 || true)
assert_contains "$OUT4" "需且僅需指定一種 body 來源" "AC4.1 同時給 --body + --body-file 應拒絕"

OUT5=$(bash "$SCRIPT_PATH" --title "x" --dry-run 2>&1 || true)
assert_contains "$OUT5" "需且僅需指定一種 body 來源" "AC4.2 完全沒給 body 應拒絕"

# ---------------------------------------------------------------------------
# AC5：必要參數缺失 / 未知參數
# ---------------------------------------------------------------------------
OUT6=$(bash "$SCRIPT_PATH" --body "x" --dry-run 2>&1 || true)
assert_contains "$OUT6" "缺少必要參數 --title" "AC5.1 缺 --title 應拒絕"

OUT7=$(bash "$SCRIPT_PATH" --title "x" --body "y" --weird-flag --dry-run 2>&1 || true)
assert_contains "$OUT7" "未知參數" "AC5.2 未知 flag 應拒絕"

# AC5.3（codex review P2-2 regression）：缺值參數應立即 die，不可無限迴圈
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
  # 若被 watchdog 殺掉，bash wait 會回傳 137（128 + SIGKILL=9）
  echo "$rc"
}

rc=$(run_with_timeout 3 bash "$SCRIPT_PATH" --title)
if [[ "$rc" == "2" ]]; then
  pass "AC5.3 --title 缺值立即 die（exit 2 = usage error，codex P2-2 regression）"
elif [[ "$rc" == "137" ]]; then
  fail "AC5.3 --title 缺值被 watchdog 殺掉（疑似無限迴圈），應 die"
else
  fail "AC5.3 --title 缺值返回意外 rc=$rc（期望 2）"
fi

# AC5.4 / AC5.5（codex review P3 + 第六輪 P2 + 第八輪 sandbox）
# 用 tmp dir + symlink 建立確定不含 gh 的 PATH。對 mktemp 失敗 / sandbox
# 限制等異常做防呆，避免測試自身因環境問題而誤報 fail。
NO_GH_DIR=""
if NO_GH_DIR="$(mktemp -d 2>/dev/null)" && [[ -n "$NO_GH_DIR" && -d "$NO_GH_DIR" ]]; then
  trap 'rm -rf "$NO_GH_DIR" "$TMP_INPUT"' EXIT INT TERM
  # 只 link script 需要的工具（gh 故意不 link）
  for cmd in bash cat mktemp wc tail rm printf; do
    src=$(command -v "$cmd" 2>/dev/null || true)
    [[ -n "$src" && -x "$src" ]] && ln -s "$src" "$NO_GH_DIR/$cmd" 2>/dev/null
  done

  # 前置：NO_GH_DIR 真的不含 gh + bash symlink 真的可執行
  if PATH="$NO_GH_DIR" command -v gh >/dev/null 2>&1; then
    fail "AC5.4 前置：NO_GH_DIR 不應含 gh"
  elif [[ ! -x "$NO_GH_DIR/bash" ]]; then
    fail "AC5.4 前置：NO_GH_DIR/bash symlink 失效，跳過此情境"
  else
    pass "AC5.4 前置：NO_GH_DIR 不含 gh 且 bash 可用"

    OUT9=$(PATH="$NO_GH_DIR" "$NO_GH_DIR/bash" "$SCRIPT_PATH" --title "no-gh test" --body "should still work" --dry-run 2>&1)
    rc=$?
    if [[ $rc -eq 0 ]] && [[ "$OUT9" == *"DRY-RUN"* ]]; then
      pass "AC5.4 dry-run 在無 gh 環境仍可執行（codex review P3 regression）"
    else
      fail "AC5.4 dry-run 在無 gh 環境失敗 (rc=$rc, out=${OUT9:0:200})"
    fi

    OUT10=$(PATH="$NO_GH_DIR" "$NO_GH_DIR/bash" "$SCRIPT_PATH" --title "no-gh real" --body "fails without gh" 2>&1 || true)
    if [[ "$OUT10" == *"找不到 gh CLI"* ]]; then
      pass "AC5.5 非 dry-run 在無 gh 環境必須 die"
    else
      fail "AC5.5 非 dry-run 在無 gh 環境未拒絕 (out=${OUT10:0:200})"
    fi
  fi
else
  # mktemp 失敗 / sandbox 限制 → 標記跳過，不誤報 fail
  pass "AC5.4/5.5 mktemp -d 在當前環境不可用，跳過 no-gh 情境驗證"
fi

# ---------------------------------------------------------------------------
# AC6：選用參數會被帶入 dry-run 顯示的指令中
# ---------------------------------------------------------------------------
OUT8=$(bash "$SCRIPT_PATH" --title "x" --body "y" \
  --repo kctw-dev/shikigami --label "enhancement,retro-action" \
  --milestone 5 --assignee KCTW --dry-run 2>&1)
assert_contains "$OUT8" "--repo"      "AC6.1 dry-run 指令含 --repo"
assert_contains "$OUT8" "--label"     "AC6.2 dry-run 指令含 --label"
assert_contains "$OUT8" "--milestone" "AC6.3 dry-run 指令含 --milestone"
assert_contains "$OUT8" "--assignee"  "AC6.4 dry-run 指令含 --assignee"

# ---------------------------------------------------------------------------
# 測試結果總結
# ---------------------------------------------------------------------------
echo ""
echo "=========================================="
echo "Test Result: PASS=$PASS_COUNT  FAIL=$FAIL_COUNT"
echo "=========================================="

[[ "$FAIL_COUNT" -eq 0 ]] && exit 0 || exit 1
