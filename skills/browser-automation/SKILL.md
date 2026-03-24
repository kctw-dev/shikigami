---
name: browser-automation
description: "Use when browser-based testing or verification is needed — E2E tests, visual regression, form validation, responsive checks, or deployment smoke tests via agent-browser"
---

# Browser Automation — agent-browser 整合

## 1. 概述

本 Skill 為 QA Engineer、UX Designer、SRE Engineer 三個角色提供瀏覽器自動化能力，基於 [agent-browser](https://github.com/vercel-labs/agent-browser)（Vercel，Rust native daemon）。

**前置條件**：需安裝 agent-browser。

```bash
# 檢查是否已安裝
which agent-browser || echo "NEEDS_INSTALL"
```

若未安裝，提示使用者執行：
```bash
npm install -g agent-browser && agent-browser install
```

**降級行為**：若 agent-browser 不可用，輸出 `[WARN] agent-browser 未安裝，跳過瀏覽器驗證` 並繼續流程，不阻擋。

**工具選型記錄**（Issue #272 Spike 結論，待補 ADR-022）：

| 候選方案 | 結論 | 理由 |
|---------|------|------|
| Playwright MCP（Claude Code 內建） | 不採用 | 每個操作獨立 MCP tool call，context 消耗高；無認證管理；無 diff 能力 |
| agent-browser（Vercel，Rust） | **採用** | CLI chaining 減少 context 消耗；5 種認證方式；snapshot diff + pixel diff；已是 Claude Code Plugin |
| gstack browse（Bun + Playwright） | 不採用 | 需要 Bun 依賴；與 Shikigami 技術棧不相容；不是獨立 Plugin |

**WSL / 無顯示環境**：若 `open` 失敗（如 `Event stream closed`），加 `--headless` flag：
```bash
agent-browser open <url> --headless
```
後續命令不需要再加 `--headless`，daemon 會記住設定。多數 WSL2 環境不加也能動（Chrome for Testing 會自動偵測）。

---

## 2. 核心工作流程

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

## 3. 三角色使用情境矩陣

| 情境 | 角色 | 典型命令序列 |
|------|------|------------|
| E2E 測試（登入→操作→驗證） | QA | `open → snapshot -i → fill → click → diff snapshot → screenshot` |
| 表單驗證測試 | QA | `open → snapshot -i → click submit → snapshot -i`（檢查錯誤訊息） |
| 視覺回歸 | QA | `diff screenshot --baseline before.png` |
| CSS Token 驗證 | UX | `open → get styles @e1`（比對 Design Token） |
| Responsive 驗證 | UX | `set device "iPhone 14" && screenshot mobile.png` |
| 元件狀態驗證 | UX | `snapshot -i`（確認 ARIA role 與 accessible name 符合 Contract） |
| 部署後 Smoke Test | SRE | `open → wait --load networkidle → console → is visible ".app-root"` |
| 效能探測 | SRE | `profiler start → open <url> → profiler stop perf.json` |

---

## 4. 認證策略

測試需要登入的頁面時，依場景選擇：

| 方式 | 適用場景 | 命令 |
|------|---------|------|
| **Session Name** | 同一測試 session 內重複訪問 | `agent-browser --session-name qa-test open <url>` |
| **State Save/Load** | 跨 session 複用認證狀態 | `agent-browser state save auth.json` / `state load auth.json` |
| **手動登入流程** | 每次測試獨立登入 | `open login → fill → click → wait` |

> 注意：state file 包含 session token，加入 `.gitignore`，測試完成後刪除。

---

## 5. 截圖規範

| 用途 | 路徑格式 | 範例 |
|------|---------|------|
| E2E 測試證據 | `/tmp/qa-e2e/{story-id}-{step}.png` | `/tmp/qa-e2e/US-273-login-success.png` |
| UX Contract 驗證 | `/tmp/ux-verify/{component}-{device}.png` | `/tmp/ux-verify/button-iphone14.png` |
| SRE Smoke Test | `/tmp/sre-smoke/{date}-{env}.png` | `/tmp/sre-smoke/2026-03-15-staging.png` |
| SRE 效能探測 | `/tmp/sre-perf/{date}.json` | `/tmp/sre-perf/2026-03-15.json` |
| Annotated 截圖 | 加 `--annotate` flag | `agent-browser screenshot --annotate` |

---

## 6. 錯誤處理

| 錯誤 | 處理 |
|------|------|
| agent-browser 未安裝 | WARN + 跳過瀏覽器驗證，不阻擋流程 |
| URL 無法訪問 | 記錄錯誤，標記為 FAIL，繼續其他測試項目 |
| Element ref 找不到 | 重新 `snapshot -i` 取得最新 refs |
| 認證失敗 | 記錄錯誤，提示使用者檢查認證設定 |

---

## 7. 常用命令速查

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
