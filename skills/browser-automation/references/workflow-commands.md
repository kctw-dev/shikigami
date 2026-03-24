# Browser Automation — 核心工作流程與常用命令

## 核心工作流程

所有瀏覽器操作遵循統一模式：

```bash
# 1. 導航
agent-browser open <url>

# 2. 取得互動元素（@e refs）
agent-browser snapshot -i

# 3. 互動（用 refs 操作）
agent-browser click @e1
agent-browser fill @e2 "value"

# 4. 驗證結果
agent-browser diff snapshot          # 操作前後差異
agent-browser screenshot result.png  # 截圖存證

# 5. 關閉
agent-browser close
```

**命令串接**：多個命令可用 `&&` 串在一個 Bash call 中，減少 context 消耗：

```bash
agent-browser open https://app.example.com && agent-browser wait --load networkidle && agent-browser snapshot -i
```

**何時分開呼叫**：需要讀取 snapshot 輸出取得 refs 後再操作時，必須分開。

---

## 常用命令速查

```bash
# 導航
agent-browser open <url>
agent-browser close

# 快照與互動
agent-browser snapshot -i              # 互動元素 + refs
agent-browser snapshot -i -C           # 含 cursor-interactive 元素
agent-browser click @e1
agent-browser fill @e1 "text"
agent-browser select @e1 "option"
agent-browser press Enter

# 取得資訊
agent-browser get text @e1
agent-browser get url
agent-browser get styles @e1           # CSS computed styles
agent-browser is visible ".selector"
agent-browser is enabled @e1

# 截圖與 Diff
agent-browser screenshot [path]
agent-browser screenshot --annotate
agent-browser screenshot --full
agent-browser diff snapshot
agent-browser diff screenshot --baseline before.png

# Device Emulation
agent-browser set device "iPhone 14"
agent-browser set viewport 1920 1080

# 認證
agent-browser --session-name <name> open <url>
agent-browser state save <path>
agent-browser state load <path>

# 除錯
agent-browser console
agent-browser errors
agent-browser profiler start / stop
```
