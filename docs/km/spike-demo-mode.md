# Spike Report：演示模式 / 火力展示 技術可行性評估

**Story ID**：US-268
**Sprint**：96
**類型**：RESEARCH（Spike）
**作者**：Story-Lifecycle Subagent
**日期**：2026-03-14
**狀態**：完成

---

## 1. 背景與動機

Shikigami 作為 AI Agent Scrum Team 框架，其核心價值在於多角色協作、自動化 Sprint 流程、TDD 驅動開發等能力。然而，這些能力對外部觀察者（新使用者、技術評估者、管理層）而言難以直觀感受——Sprint 執行過程發生在 Claude Code 的對話 context 中，外部無法即時觀看，執行完畢後也缺乏可回放的紀錄。

「演示模式 / 火力展示」的需求來自 Sprint 93 Review 後的 issue 討論（`docs/km/project_demo_mode_idea.md`）：希望能有一種方式，讓人可以**直觀地看到 Shikigami 在工作**。

本 Spike 評估三個技術方向的可行性，並給出建議方案。

---

## 2. Claude Code Plugin 架構限制分析

在評估各方向前，必須先理解 Shikigami 作為 Claude Code Plugin 的能力邊界。

### 2.1 Plugin 能力邊界

| 元件 | 能力 | 限制 |
|------|------|------|
| **Hooks（SessionStart / PreToolUse / PostToolUse）** | 執行 Shell script，注入 context | 無法持續監聽；僅在特定事件點觸發，不支援長跑守護程序 |
| **Agent（subagent 派遣）** | 呼叫 Tool（Read / Edit / Bash / Write）、派遣 subagent | 無法直接控制 terminal UI；所有輸出回到 Claude Code 對話框 |
| **Skill（SKILL.md 指令）** | 定義 LLM 執行的流程邏輯 | 純 prompt，無程式碼執行能力 |
| **MCP Server（Node.js）** | 提供結構化工具、資源查詢 | 以 stdio transport 運行，不持有 terminal 控制權 |
| **Bash Tool** | 執行任意 shell 命令 | 輸出回到 Claude Code 對話框；無法持續輸出到獨立 terminal |

### 2.2 關鍵限制

1. **Terminal 控制權歸 Claude Code**：Shikigami 所有執行都在 Claude Code 的對話 context 中，無法繞過 Claude Code 直接控制 terminal 視窗或開啟 TUI（Terminal UI）。
2. **Subagent 不回傳串流**：Story-Lifecycle subagent 執行完畢後才回傳摘要，執行過程中間狀態對主 session 不透明。
3. **Hook 為事件驅動，非持續監聽**：SessionStart hook 僅在 session 開始時觸發，無法作為 Sprint 執行期間的持續監控機制。
4. **MCP Server 為請求-回應模式**：MCP Server 以 stdio 運行，回應 Claude 的工具呼叫，無法主動推送（push）資料到外部。

---

## 3. 三個方向的可行性評估

### 3.1 方向一：Terminal Dashboard

**概念**：在 Sprint 執行過程中，即時顯示進度面板——Story 狀態、當前步驟、已完成/待辦清單。

#### 技術路徑分析

**路徑 A：純 Bash TUI（`tput` / ANSI escape code）**

透過 Bash Tool 呼叫 `tput` 或輸出 ANSI 控制碼，在 Claude Code 對話框中模擬進度面板。

- **問題**：Claude Code 的對話框為純文字渲染（Markdown），不支援 ANSI escape code 的游標控制（`\033[H\033[2J` 清屏等），輸出會以 raw 字元呈現。
- **結論**：不可行。Claude Code 對話框不是真正的 terminal emulator。

**路徑 B：外部 terminal 進程（tmux / screen split）**

在 Sprint 執行開始時，透過 Bash Tool 啟動一個 tmux 或 screen 分割視窗，並在其中渲染 dashboard。

- **問題**：
  1. 依賴使用者環境（tmux / screen 是否安裝、是否在 tmux session 中執行）。
  2. Shikigami Subagent 無法直接寫入另一個 tmux 視窗（需要額外的 IPC 機制，如 named pipe 或 file polling）。
  3. 使用者需要手動切換終端視窗，互動性差。
- **結論**：部分可行（需額外 IPC），但依賴環境、設定複雜，使用者體驗差。

**路徑 C：外部 Web Dashboard（localhost HTTP server）**

在 Sprint 執行開始時，透過 Bash Tool 啟動一個 `python3 -m http.server` 或 Node.js HTTP server，Subagent 透過寫入 JSON 狀態文件更新進度，瀏覽器自動輪詢（polling）顯示。

- **優點**：
  1. 不依賴 terminal 特性，只要有瀏覽器即可。
  2. Subagent 只需寫入狀態文件（`docs/sprints/demo-status.json`），HTTP server 靜態提供文件。
  3. 瀏覽器端可用 `setInterval` 每 2 秒輪詢，實現近即時更新。
- **缺點**：
  1. 啟動步驟繁瑣（需手動開啟瀏覽器、使用者可能不習慣）。
  2. HTTP server 為 background process，需要 cleanup（Sprint 結束後關閉）。
  3. Story-Lifecycle subagent 必須每個關鍵步驟都寫入狀態文件，增加 Skill 複雜度。
- **可行性評估**：**M（技術可行，但整合成本偏高）**

#### 總評

| 路徑 | 可行性 | 實作複雜度 | 使用者體驗 | 建議 |
|------|--------|-----------|-----------|------|
| A（ANSI TUI） | 不可行 | — | — | 排除 |
| B（tmux split） | 低度可行 | L | 差 | 不建議 |
| C（Web Dashboard） | 可行 | M | 中等 | 可考慮（長期） |

---

### 3.2 方向二：錄影回放

**概念**：記錄 Sprint 執行過程，事後可回放展示給他人觀看。

#### 技術路徑分析

**路徑 A：asciinema 錄製**

`asciinema` 是一個廣泛使用的 terminal 錄製工具，可記錄 terminal 的所有輸入/輸出，生成 `.cast` 文件，可在網頁或 terminal 中回放。

- **整合方式**：
  1. 使用者在執行 Shikigami 前，以 `asciinema rec sprint-96.cast` 開始錄製。
  2. 正常執行 Sprint（`/sprint run` 或類似指令）。
  3. 執行完成後，`asciinema` 自動停止錄製，生成 `.cast` 文件。
  4. 可上傳至 asciinema.org 或本地回放（`asciinema play sprint-96.cast`）。
- **優點**：
  1. **零侵入性**：Shikigami 框架完全不需要修改，由使用者在外部錄製。
  2. **成熟工具**：asciinema 廣泛使用，有線上分享功能（asciinema.org）。
  3. **忠實記錄**：完整記錄 Claude Code 對話框的所有輸出。
- **缺點**：
  1. **無法錄製 Claude Code GUI**：若使用者用 Claude Code 的 GUI（非 terminal 版），asciinema 無法錄製。
  2. **依賴 terminal 版 Claude Code**：需要 Claude Code CLI，而非桌面 App。
  3. **文件大小**：長 Sprint 的 `.cast` 文件可能很大（幾十 MB），分享需要上傳。
  4. **無法回放 AI 思考過程**：只記錄文字輸出，看不到 subagent 內部的思考鏈。

**路徑 B：Structured Log 後製回放**

Sprint 執行過程中，Story-Lifecycle subagent 在關鍵步驟寫入結構化事件日誌（JSON），事後可透過一個回放腳本模擬執行過程。

- **問題**：「回放」的意義不大——如果只是重複輸出文字，不如直接讀取 Sprint 文件或 git log。無法重現 AI 的即時推理過程。
- **結論**：技術可行，但價值有限。

**路徑 C：Screen recording（OBS / QuickTime）**

使用者用螢幕錄製軟體錄製 Claude Code 的完整操作過程。

- **優點**：完整記錄視覺體驗（包含 GUI 互動）、零框架修改。
- **缺點**：文件巨大（影片）、分享困難、無程式化整合。

#### 總評

| 路徑 | 可行性 | 實作複雜度 | 框架修改量 | 建議 |
|------|--------|-----------|-----------|------|
| A（asciinema） | 高（terminal 版） | S | 零 | **推薦作為短期方案** |
| B（Structured Log 回放） | 中 | M | M | 不建議（價值有限） |
| C（螢幕錄製） | 高 | S | 零 | 輔助手段（非程式化） |

---

### 3.3 方向三：Live Log Streaming

**概念**：即時串流 agent 執行日誌到外部觀看（如瀏覽器、另一個 terminal 視窗）。

#### 技術路徑分析

**路徑 A：Log file tail（文件輪詢 + tail -f）**

Story-Lifecycle subagent 在每個關鍵步驟寫入一個日誌文件（`docs/sprints/sprint-96.live.log`），使用者在另一個 terminal 視窗執行 `tail -f docs/sprints/sprint-96.live.log` 觀看串流。

- **優點**：
  1. 零外部依賴（`tail -f` 是標準 Unix 工具）。
  2. 實作簡單：Subagent 在 Skill 定義中加入「關鍵步驟寫入日誌」指令。
  3. 使用者可以在任何 terminal 視窗觀看，不需要瀏覽器。
- **缺點**：
  1. 需要修改 Skill（story-lifecycle-prompt.md、sprint-execution/SKILL.md），在每個關鍵步驟加入日誌寫入指令。
  2. 每個 subagent 都要執行額外的 Write/Bash 操作（輕微效能影響）。
  3. 日誌格式設計需要仔細規劃（過於冗長或格式不佳會降低可讀性）。
  4. `tail -f` 在 Windows 環境需要 WSL 或 Git Bash。
- **可行性評估**：**S（技術直接可行）**

**路徑 B：WebSocket Streaming Server**

MCP Server 或獨立 Node.js server 持有 WebSocket 連線，subagent 透過呼叫 MCP tool 推送事件，瀏覽器即時接收。

- **問題**：
  1. 架構複雜（需要持久 WebSocket server + MCP 工具包裝）。
  2. MCP Server 以請求-回應模式運行，Subagent 每次呼叫 MCP tool 才推送；若 subagent 不主動呼叫，無法自動推送。
  3. 建立完整 WebSocket 基礎設施的工時顯著（M-L）。
- **結論**：技術可行但過度複雜，不建議。

**路徑 C：SSE（Server-Sent Events）+ 輕量 HTTP Server**

類似路徑 A，但將日誌以 SSE 格式推送到瀏覽器。輕量 HTTP Server（50 行 Node.js）監聽日誌文件變動（`fs.watch`），透過 SSE 即時推送。

- **可行性**：高，但比路徑 A 多了 Node.js server 依賴。
- **結論**：對 terminal 不友善的環境有優勢，但複雜度較 tail -f 高。

#### 總評

| 路徑 | 可行性 | 實作複雜度 | 依賴 | 建議 |
|------|--------|-----------|------|------|
| A（tail -f） | 高 | S | 零（Unix 標準工具） | **推薦（最小可行方案）** |
| B（WebSocket） | 中 | L | WebSocket server | 不建議（過度複雜） |
| C（SSE server） | 中 | M | Node.js + http | 可作為 tail -f 的強化版 |

---

## 4. 三方向對比總表

| 評估維度 | Terminal Dashboard | 錄影回放 | Live Log Streaming |
|---------|-------------------|---------|-------------------|
| **技術可行性** | 低（Claude Code 限制） | 高（外部工具） | 高 |
| **框架修改量** | 高（侵入性） | 零（外部錄製） | 低-中（加日誌寫入） |
| **實作複雜度** | M-L | S（asciinema 方案） | S（tail -f 方案） |
| **外部依賴** | tmux / Web server | asciinema 工具 | 無（tail -f） |
| **即時性** | 高 | 低（事後回放） | 高 |
| **可分享性** | 中 | 高（.cast / 影片） | 低（需對方也 tail） |
| **使用者體驗** | 中（切換視窗） | 高（非同步觀看） | 中（需雙視窗） |
| **Claude Code 相容性** | 低 | 高（terminal 版） | 高 |

---

## 5. 技術風險評估

| 風險 | 方向 | 嚴重度 | 機率 | 緩解措施 |
|------|------|--------|------|---------|
| Claude Code GUI 不支援 ANSI | Terminal Dashboard | 高 | 確定 | 排除此路徑 |
| asciinema 在非 terminal 環境失效 | 錄影回放 | 中 | 中 | 文件說明需求；提供螢幕錄製替代 |
| tail -f 在 Windows 不原生支援 | Live Log Streaming | 低 | 低 | 文件說明 WSL 使用方式 |
| Skill 修改增加 subagent Token 使用量 | Live Log Streaming | 低 | 低 | 日誌寫入指令精簡化 |
| HTTP server background process 忘記關閉 | Terminal Dashboard / Web | 低 | 中 | Sprint 結束時 Skill 自動 cleanup |
| 日誌文件過大（長 Sprint） | Live Log Streaming | 低 | 低 | 每次 Sprint 覆蓋或輪替日誌 |

---

## 6. 建議方案

### 6.1 主要建議：Phase 1 + Phase 2 分階段實作

#### Phase 1（立即可行，S-size）：Live Log Streaming（tail -f 方案）

**方案描述**：
在 Story-Lifecycle subagent 的關鍵步驟加入日誌寫入指令，讓使用者可以在另一個 terminal 視窗即時觀看 Sprint 執行過程。

**實作細節**：
1. 在 `skills/sprint-execution/SKILL.md` 加入 Sprint Live Log 說明段落（使用指引）。
2. 在 `skills/sprint-execution/story-lifecycle-prompt.md` 的每個關鍵步驟加入日誌寫入指令：
   - Story 取出時：`echo "[$(date +%H:%M:%S)] [US-XXX] 開始執行" >> docs/sprints/sprint.live.log`
   - TDD 循環開始：記錄 Red/Green/Refactor 階段
   - Spec Compliance Review 開始/結束
   - Code Quality Review 開始/結束
   - PASS/FAIL/ESCALATE 回傳
3. 使用者在另一個 terminal 執行：`tail -f docs/sprints/sprint.live.log`

**使用者體驗**：
```
[18:15:01] [US-268] 開始執行 RESEARCH Story
[18:15:02] [US-268] 讀取 sprint_96.md AC
[18:15:05] [US-268] 開始 Spike Report 撰寫
[18:16:23] [US-268] Spec Compliance self-review — 開始
[18:16:30] [US-268] Spec Compliance self-review — PASS
[18:16:31] [US-268] 結果：PASS，寫入 docs/sprints/subagent-results/US-268.md
```

**估算工時**：1 Sprint（S-size，1 point）
**技術風險**：低
**框架修改量**：低（加入日誌寫入指令，不影響現有邏輯）

#### Phase 2（可選增強，M-size）：錄影回放（asciinema + 腳本整合）

**方案描述**：
提供一個 `scripts/demo-record.sh` 腳本，自動啟動 asciinema 錄製並在 Sprint 結束後儲存 `.cast` 文件。

**實作細節**：
1. `scripts/demo-record.sh`：包裝 `asciinema rec` + 時間戳命名（`sprint-96-YYYYMMDD-HHMMSS.cast`）。
2. 錄製文件儲存至 `docs/demos/`（.gitignore 中排除）。
3. `README.md` 加入「演示模式」章節說明如何使用。

**估算工時**：0.5-1 Sprint（S-size，1 point）
**技術風險**：中（依賴 asciinema 安裝）
**前置條件**：Phase 1 完成

### 6.2 不建議方向

- **Terminal Dashboard**：因 Claude Code Plugin 限制（不支援 ANSI 控制、無法控制 terminal 視窗），核心功能無法實現，不建議投入。
- **WebSocket Streaming Server**：過度複雜，與框架的輕量設計理念不符。

---

## 7. Spec Compliance Self-Review

### AC1：產出技術可行性報告（Spike Report）
- [x] 本文件即為技術可行性報告，包含背景、架構分析、三方向評估、建議方案

### AC2：評估三個方向（terminal dashboard / 錄影回放 / live log streaming）
- [x] 第 3.1 節：Terminal Dashboard（3 個路徑 A/B/C）
- [x] 第 3.2 節：錄影回放（3 個路徑 A/B/C）
- [x] 第 3.3 節：Live Log Streaming（3 個路徑 A/B/C）

### AC3：報告含建議方案、估算工時、技術風險
- [x] 第 6 節：建議方案（Phase 1 + Phase 2）
- [x] 估算工時：Phase 1 = S-size 1pt，Phase 2 = S-size 1pt
- [x] 第 5 節：技術風險評估（6 個風險點）

**Spec Compliance Review 結論：PASS（3/3 AC 全部覆蓋）**

---

## 8. 附錄：快速參考

### 推薦方案摘要

| 優先順序 | 方案 | 大小 | 工時 | 說明 |
|---------|------|------|------|------|
| 1（優先） | Live Log Streaming（tail -f） | S | 1pt | 零依賴、即時、低侵入性 |
| 2（可選） | 錄影回放（asciinema 腳本） | S | 1pt | 可分享、適合外部展示 |
| 3（排除） | Terminal Dashboard | — | — | Claude Code 架構限制，不可行 |

### 核心架構限制（一句話總結）

> Claude Code Plugin 的 agent/subagent 所有輸出回到對話框，不具備 terminal 控制權，因此需要透過**文件作為 IPC 橋梁**（寫入日誌文件 → 外部工具讀取）來實現「外部可見性」。
