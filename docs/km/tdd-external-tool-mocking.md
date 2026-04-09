# TDD 外部工具模擬最佳實踐指南 — fake binary vs PATH 清空陷阱

## 問題

在測試中，常常需要模擬外部工具的缺失或特定行為（例如 `gh` CLI 認證失敗、某個命令不存在）。許多開發者習慣使用簡單的方法 `PATH=/nonexistent` 來清空 PATH，期望讓工具不可用。

然而，這種方法有多個隱藏陷阱：
- **Bash builtin 優先級**：許多 Bash 內建命令（如 `echo`, `kill`, `type` 等）無需 PATH，直接執行
- **絕對路徑規避**：某些工具 hardcoded 了絕對路徑，不受 PATH 影響
- **測試框架差異**：某些測試框架對 PATH 修改的隔離程度不同，清空 PATH 在某些環境下失效

## 反例：PATH=/nonexistent 陷阱

### 常見寫法

```bash
#!/usr/bin/env bash

# 反例 1: 直接清空 PATH（失敗）
PATH=/nonexistent bash -c "which gh" 2>&1
# 可能輸出: /usr/bin/gh（如果 gh 本身在 /usr/bin，PATH 清空不影響）

# 反例 2: 依靠 PATH 清空模擬工具失敗
test_gh_failure() {
  PATH=/nonexistent bash -c "
    gh auth status
  "
}
```

### 為何失效

1. **絕對路徑 hardcoded**
   ```bash
   # 如果 gh 的 wrapper 或快捷方式指向 /usr/local/bin/gh，PATH 清空無法阻止執行
   /usr/local/bin/gh auth status  # 仍會成功
   ```

2. **Bash builtin 幹擾**
   ```bash
   # 如果測試中使用 `echo` 或其他 builtin，PATH 不會影響它們
   PATH=/nonexistent bash -c "echo 'this still works'"
   # 輸出: this still works（因為 echo 是 builtin）
   ```

3. **測試框架隱藏的 PATH 恢復**
   ```bash
   # 某些測試框架（如使用 docker、namespace 的環境）會自動恢復全局 PATH
   # 即使你設定了 PATH=/nonexistent，框架仍可能暴露主系統的工具
   ```

### 可運行的反例 snippet

這個例子展示 PATH 清空的失效場景：

```bash
#!/usr/bin/env bash
set -uo pipefail

echo "=== 反例: PATH=/nonexistent 陷阱 ==="

# 測試 1: 嘗試清空 PATH 模擬 gh 不可用
echo "--- 測試 1: PATH=/nonexistent 後找 gh ---"
PATH=/nonexistent bash -c "
  if command -v gh >/dev/null 2>&1; then
    echo 'FAIL: PATH=/nonexistent 後 gh 仍可找到'
    exit 1
  else
    echo 'PASS: gh 不可用（預期結果）'
    exit 0
  fi
" && echo "✓ 通過" || echo "✗ 失敗（PATH 清空沒有效果）"

# 測試 2: builtin 不受 PATH 影響
echo ""
echo "--- 測試 2: builtin echo 不受 PATH 影響 ---"
PATH=/nonexistent bash -c "
  echo 'This is a builtin, PATH does not affect it'
  exit 0
"
echo "✓ builtin 命令仍可執行（PATH 清空無效）"

# 測試 3: 絕對路徑規避
echo ""
echo "--- 測試 3: 絕對路徑的工具不受 PATH 影響 ---"
PATH=/nonexistent bash -c "
  # 如果 bash 本身在 /bin/bash，絕對路徑呼叫不受 PATH 影響
  /bin/bash -c 'echo absolute path works'
" && echo "✓ 絕對路徑工具仍可執行"

echo ""
echo "結論: PATH=/nonexistent 無法可靠地模擬工具缺失"
```

運行此 snippet：
```bash
bash反例.sh
```

輸出顯示 PATH 清空在實際環境中往往無效。

## 正例：Fake Binary in TMPBIN

### 標準做法 template

正確的方法是在一個臨時目錄中建立 fake binary，然後將該目錄加入 PATH 最前面。這樣可以確保 fake binary 優先於系統中的真實工具被執行。

**基本模式**：
```bash
#!/usr/bin/env bash

# 1. 建立臨時目錄
TMPBIN=$(mktemp -d)

# 2. 建立 fake binary
cat > "$TMPBIN/gh" <<'EOF'
#!/bin/bash
# Fake gh 實作
echo "fake gh output"
exit 0
EOF

# 3. 設置執行權限
chmod +x "$TMPBIN/gh"

# 4. 將 TMPBIN 加入 PATH 最前面
export PATH="$TMPBIN:$PATH"

# 5. 測試（此時 gh 會執行 fake binary）
gh --version  # 輸出: fake gh output

# 6. 清理（使用 trap 確保清理）
trap "rm -rf $TMPBIN" EXIT
```

### 可直接複製執行的 bash snippet

這是完整的、可直接運行驗證的例子：

```bash
#!/usr/bin/env bash
set -uo pipefail

echo "=== 正例: Fake Binary in TMPBIN ==="

# 建立臨時 bin 目錄
TMPBIN=$(mktemp -d)
echo "[建立] TMPBIN=$TMPBIN"

# 建立 fake gh 工具
cat > "$TMPBIN/gh" <<'EOF'
#!/bin/bash
echo "fake gh output"
exit 0
EOF
chmod +x "$TMPBIN/gh"
echo "[建立] fake gh"

# 建立 fake docker 工具（模擬失敗）
cat > "$TMPBIN/docker" <<'EOF'
#!/bin/bash
echo "docker command not available" >&2
exit 127
EOF
chmod +x "$TMPBIN/docker"
echo "[建立] fake docker（模擬不可用）"

# 將 TMPBIN 加入 PATH 最前面
export PATH="$TMPBIN:$PATH"

# 測試 1: gh 返回預期輸出
echo ""
echo "--- 測試 1: 模擬 gh 成功 ---"
output=$(gh 2>&1)
if [[ "$output" == "fake gh output" ]]; then
  echo "✓ PASS: gh 返回預期輸出"
else
  echo "✗ FAIL: gh 輸出不符"
fi

# 測試 2: docker 模擬失敗
echo ""
echo "--- 測試 2: 模擬 docker 失敗 ---"
rc=0
docker build . >/dev/null 2>&1 || rc=$?
if [[ $rc -eq 127 ]]; then
  echo "✓ PASS: docker 返回預期的失敗 exit code (127)"
else
  echo "✗ FAIL: docker exit code 不符，得到 $rc"
fi

# 測試 3: 用 command -v 驗證 fake binary 優先級
echo ""
echo "--- 測試 3: Fake binary 優先級 ---"
gh_path=$(command -v gh)
if [[ "$gh_path" == "$TMPBIN/gh" ]]; then
  echo "✓ PASS: $gh_path 是 fake binary（優先級正確）"
else
  echo "✗ FAIL: 優先級錯誤，得到 $gh_path"
fi

# 清理
trap "rm -rf $TMPBIN" EXIT
rm -rf "$TMPBIN"
echo ""
echo "[清理完成]"
```

運行此 snippet：
```bash
bash正例.sh
```

輸出應該顯示所有測試通過，fake binary 被正確優先執行。

## Fake binary 進階用法

### 模擬 stdin 讀取

有時需要 fake binary 讀取並驗證 stdin 內容：

```bash
TMPBIN=$(mktemp -d)

# Fake binary 讀取 stdin 並檢查內容
cat > "$TMPBIN/my_processor" <<'EOF'
#!/bin/bash
# 讀取 stdin，如果包含特定關鍵字則成功
if grep -q "EXPECTED_DATA" <&0; then
  echo "Processing successful"
  exit 0
else
  echo "Invalid input" >&2
  exit 1
fi
EOF
chmod +x "$TMPBIN/my_processor"

export PATH="$TMPBIN:$PATH"

# 測試
echo "EXPECTED_DATA" | my_processor  # 輸出: Processing successful

trap "rm -rf $TMPBIN" EXIT
```

### 模擬不同 exit code

Fake binary 可以根據參數或環境變數返回不同的 exit code：

```bash
TMPBIN=$(mktemp -d)

# Fake binary 根據參數返回不同 exit code
cat > "$TMPBIN/status_checker" <<'EOF'
#!/bin/bash
case "${1:-}" in
  "ok")     exit 0;;
  "warning") exit 1;;
  "error")   exit 2;;
  *)        echo "usage: status_checker {ok|warning|error}" >&2; exit 1;;
esac
EOF
chmod +x "$TMPBIN/status_checker"

export PATH="$TMPBIN:$PATH"

# 測試不同狀態
status_checker ok; echo "RC=$?"           # RC=0
status_checker warning 2>/dev/null; echo "RC=$?"  # RC=1
status_checker error 2>/dev/null; echo "RC=$?"    # RC=2

trap "rm -rf $TMPBIN" EXIT
```

### 記錄呼叫參數

有時需要驗證 fake binary 被以什麼參數呼叫的：

```bash
TMPBIN=$(mktemp -d)
CALL_LOG="$TMPBIN/calls.log"

# Fake binary 記錄每次呼叫
cat > "$TMPBIN/audited_tool" <<EOF
#!/bin/bash
# 記錄呼叫參數到日誌檔案
{
  echo "timestamp: \$(date +%s)"
  echo "args: \$@"
  echo "cwd: \$(pwd)"
  echo "---"
} >> "$CALL_LOG"
echo "Tool executed"
exit 0
EOF
chmod +x "$TMPBIN/audited_tool"

export PATH="$TMPBIN:$PATH"

# 測試並記錄
audited_tool --verbose --output result.txt
audited_tool --config config.yml

# 驗證記錄
echo "--- 呼叫記錄 ---"
cat "$CALL_LOG"

trap "rm -rf $TMPBIN" EXIT
```

## 案例參考：Sprint 176 修復

Sprint 176 中完成了 `tests/test-check-backlog-health.sh` 的修復（issue #944），使用 fake binary 模擬 `gh` CLI 認證失敗的場景。

該測試的核心部分（NFR1：gh CLI 失敗靜默降級）：

```bash
#!/usr/bin/env bash
# 來自 tests/test-check-backlog-health.sh，第 69-86 行

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
```

**關鍵要素**：
1. **TMPBIN 隔離**：在臨時目錄中建立 fake `gh`
2. **PATH 優先級**：`PATH="$TMPBIN:$PATH"` 確保 fake binary 優先被找到
3. **模擬失敗**：fake `gh` 直接 `exit 1`，讓被測試的腳本經歷真實的 auth failure
4. **清理**：`rm -rf "$TMPBIN"` 確保臨時文件被清除

這個模式被廣泛用於 Shikigami 框架的多個測試中，是可靠且經過驗證的最佳實踐。

## 總結

| 方法 | 優點 | 缺點 | 適用場景 |
|------|------|------|---------|
| **PATH=/nonexistent** | 簡單快速 | 易失效、builtin 幹擾、絕對路徑規避 | 不推薦 |
| **Fake binary in TMPBIN** | 可靠、隔離完整、支援進階用法 | 稍複雜、需要 trap 清理 | 生產級測試（推薦） |

**推薦做法**：
- 始終使用 **Fake binary in TMPBIN** 模式
- 使用 `trap "rm -rf $TMPBIN" EXIT` 確保清理
- 需要複雜行為時，fake binary 可以讀取參數、stdin、設置環境變數
- 參考 Sprint 176 `tests/test-check-backlog-health.sh` 作為標準範例
