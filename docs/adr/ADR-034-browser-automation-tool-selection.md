# ADR-034：Browser Automation 工具選型

**日期**：2026-03-24
**狀態**：Proposed
**相關 Issue**：#386、#272、#385
**提案者**：Architect Agent
**關聯 ADR**：ADR-033（Structured Trace Log）

---

## 背景

### 問題陳述

Shikigami 框架的 QA Engineer、UX Designer、SRE Engineer 三個 Agent 角色在涉及 Web UI 驗證的場景中存在能力盲點：

| 角色 | 缺口描述 |
|------|---------|
| QA Engineer | 只能執行靜態程式碼審查，無法執行 E2E 測試或視覺回歸測試 |
| UX Designer | 只能產出 Figma Prototype，無法在真實瀏覽器中驗證 Contract 實作結果 |
| SRE Engineer | 只能分析日誌與 metrics，無法模擬使用者路徑進行可用性監控 |

Issue #271 競品分析發現 gstack 透過持久化 Chromium daemon 賦予其框架角色「看得到畫面」的能力。Issue #272 Spike 在 Sprint 53 驗證了 GCP self-hosted headless Chromium 的基礎可行性，並初步評估了多個工具方案。

`skills/browser-automation/SKILL.md` 目前已採用 agent-browser（Vercel，Rust native daemon），但工具選型決策尚未有正式 ADR 固化，導致 #385 GAD Delivery Phase 的視覺對比方案缺乏架構依據。

### 驅動力

- #272 Spike 結論需固化為正式 ADR（#386 目標）
- #385 GAD Delivery Phase 需要明確的 browser automation 工具方案作為前置依賴
- `skills/browser-automation/SKILL.md` 中的工具選型記錄（`待補 ADR-022`）需補上正式 ADR
- 需在 CI/CD 環境（self-hosted runner）中可靠執行

---

## 決策問題

在 Shikigami 框架的 Agent 環境（Claude Code subagent）中，選用哪種 browser automation 工具作為 QA/UX/SRE 三角色的瀏覽器操作基礎？

---

## 評估維度定義

所有方案以下列統一維度比較：

| 維度 | 說明 |
|------|------|
| **CI 整合性** | 在 self-hosted runner（Linux headless）環境的安裝難度與穩定性 |
| **穩定性** | 多步驟操作的 session 狀態連續性；跨 tool call 維持 browser session 的能力 |
| **維護成本** | 依賴管理、更新頻率、與 Shikigami 技術棧的相容性 |
| **社群支援** | 文件品質、Issue 回應速度、採用率 |
| **Agent 友善度** | CLI 介面對 Agent 文字指令的適用性；context token 消耗 |

---

## 考慮的選項

### 方案 A：Playwright MCP（`mcp__plugin_playwright_playwright__*`）

Claude Code available deferred tools 中的原生 MCP 工具，透過 `browser_navigate`、`browser_snapshot`、`browser_click`、`browser_fill` 等 MCP tool call 操作瀏覽器。

#### CI 整合性

- **優點**：Claude Code 環境原生支援，無需額外安裝
- **缺點**：
  - MCP server 需要 `browser_install` 初始化，self-hosted runner 每次冷啟動需重新初始化
  - 非 Claude Code 平台（OpenCode / Gemini CLI / Cursor）不可用；無法保障跨平台一致性
  - CI 環境中 MCP server 生命週期管理不明確，無現成 CI recipe

#### 穩定性

- **問題（Sprint 53 + #272 Spike 結論）**：每個 MCP tool call 之間缺乏持久化 daemon，無法保證多步驟操作的 browser session 連續性（如登入後操作是否保持 session）
- 截圖操作（`browser_take_screenshot`）回傳 base64 圖片資料，單張截圖可消耗數千至數萬 token，多步驟場景 context 消耗嚴重
- MCP tool call 架構每次都是獨立呼叫，無狀態連續性保證

#### 維護成本

- 無外部依賴，但依賴 Anthropic 的 Playwright MCP 更新節奏
- Agent YAML / Skill.md 需以 MCP tool call 語法定義，學習曲線中等

#### 社群支援

- Anthropic 官方維護，文件在 Claude Code 官方文件中
- 社群採用率增長中，但 Shikigami 的 multi-agent subagent 使用情境較少見案例

#### Agent 友善度

- MCP tool call 介面對 Agent 自然，但截圖 base64 造成 context flooding
- 無 CLI chaining，每步驟都是獨立 tool call，效率低

**綜合評分**：

| 維度 | 評分（1-5） | 說明 |
|------|-----------|------|
| CI 整合性 | 2 | 跨平台不支援；CI 安裝流程不明 |
| 穩定性 | 2 | 無持久化 daemon；跨 tool call session 不連續 |
| 維護成本 | 4 | 無外部依賴，Anthropic 維護 |
| 社群支援 | 3 | 官方文件存在，subagent 情境案例少 |
| Agent 友善度 | 2 | Context 消耗高；無 chaining |
| **加權總分** | **2.6** | |

---

### 方案 B：Puppeteer（直接使用或透過 MCP wrapper）

Google 維護的 Node.js 瀏覽器自動化函式庫，可直接在 Shell script 中透過 `npx puppeteer` 使用，或透過 [puppeteer-mcp](https://github.com/apify/mcp-server-puppeteer) 等第三方 MCP wrapper 整合。

#### CI 整合性

- **優點**：
  - Node.js 生態系完整，self-hosted runner 通常已有 Node.js 環境
  - `npx puppeteer browsers install chrome` 可自動安裝 Chromium
  - CI recipe 成熟（GitHub Actions、GitLab CI 均有大量案例）
- **缺點**：
  - 需安裝 Node.js 依賴（`npm install puppeteer`），增加 runner 環境管理負擔
  - MCP wrapper 為第三方維護，品質參差不齊

#### 穩定性

- **優點**：Puppeteer 本身是持久化 Node.js 進程，同一腳本內 session 完全連續
- **缺點**：
  - 若透過 MCP wrapper 使用，仍面臨跨 tool call 的 session 連續性問題
  - 直接使用（非 MCP）需要 Agent 生成 Node.js 腳本並執行，錯誤處理複雜

#### 維護成本

- Puppeteer 核心由 Google 維護，穩定性高
- 但 Agent 需透過「生成腳本→執行腳本→解析輸出」的間接路徑操作，認知負擔高
- MCP wrapper 為第三方，版本更新不穩定

#### 社群支援

- Puppeteer 社群龐大，Stack Overflow / GitHub Issues 資源豐富
- MCP wrapper 社群較小，Shikigami 框架整合案例近乎為零

#### Agent 友善度

- 直接使用需生成完整 Node.js 腳本，Agent 指令複雜度高
- MCP wrapper 介面設計差異大，無標準化命令語法
- 截圖同樣面臨 base64 回傳問題（若透過 MCP）

**綜合評分**：

| 維度 | 評分（1-5） | 說明 |
|------|-----------|------|
| CI 整合性 | 3 | Node.js 生態成熟，但需管理依賴 |
| 穩定性 | 3 | 直接使用穩定；MCP wrapper 不確定 |
| 維護成本 | 2 | 腳本生成路徑複雜；MCP wrapper 第三方風險 |
| 社群支援 | 4 | 社群龐大，但框架整合案例少 |
| Agent 友善度 | 2 | 腳本生成複雜；無標準 CLI |
| **加權總分** | **2.8** | |

---

### 方案 C：agent-browser（Vercel，Rust native daemon）

Vercel 開發的 CLI 瀏覽器自動化工具，基於 Rust 原生實作，透過 CDP（Chrome DevTools Protocol）直接操作 Chrome/Chromium。提供背景 daemon 持久化 browser session，支援 CLI chaining。

```bash
# 安裝
npm install -g agent-browser
agent-browser install  # 下載 Chrome
```

官方文件：https://docs.anthropic.com/en/docs/claude-code/sub-agents

#### CI 整合性

- **優點**：
  - `npm install -g agent-browser && agent-browser install` 一行安裝，self-hosted runner 友好
  - headless 模式原生支援（`--headless` flag），無需 Xvfb 等虛擬顯示環境
  - 亦支援 Lightpanda 引擎（`--engine lightpanda`），10x 更快、10x 更省記憶體，適合 CI 環境
  - 跨平台：Linux（CI runner）/ macOS（本地開發）均支援
  - 已是 Claude Code Plugin（Vercel 生態），與 Shikigami 作為 Claude Code Plugin 同屬一個 Plugin 生態

- **缺點**：
  - 需要 npm 全局安裝；若 runner 有 npm registry 限制需額外設定

#### 穩定性

- **核心優勢**：背景 daemon 持久化 browser session，跨多個 shell 指令維持同一 browser context
  ```bash
  agent-browser open https://app.example.com/login
  agent-browser fill @e1 "user@example.com"  # 同一 session
  agent-browser click @e3                    # 同一 session，認證狀態保持
  ```
- **多步驟 E2E 測試完全支援**：登入後操作、跨頁面跳轉，session 狀態連續
- **Session 命名**：`--session-name` 支援多個並行 session，適合多 agent 平行場景

#### 維護成本

- Rust 原生實作，效能高、記憶體用量低
- Vercel 與 Anthropic 生態整合（官方文件已在 Anthropic docs 中）
- CLI 介面語意清晰，Skill.md 撰寫簡潔
- 版本更新透過 `agent-browser upgrade` 一行完成
- Shikigami 框架已存在 `skills/browser-automation/SKILL.md` 以此工具定義使用規範（Issue #272 Spike 結論）

#### 社群支援

- Vercel 官方維護，與 Claude Code 整合有官方文件
- agent-browser Skill 已在 Shikigami 框架的 `.claude/plugins/` 中存在（本地 cache 確認）
- 社群成長中，Vercel 生態（Next.js / v0 / Vercel AI）使用者基礎

#### Agent 友善度

- **CLI chaining**：可在單一 Bash tool call 中 `&&` 連接多個操作，減少 tool call 次數
  ```bash
  agent-browser open https://example.com && agent-browser wait --load networkidle && agent-browser screenshot result.png
  ```
- **截圖儲存為檔案**（而非 base64 回傳），大幅降低 context token 消耗
- **Ref 系統**（`@e1`, `@e2`）：snapshot 回傳語意化元素參照，Agent 指令自然語言友善
- **Annotated screenshot**（`--annotate`）：截圖帶編號標籤，直接對應 ref，視覺除錯效率高
- **Batch 指令**：已知操作序列可用 JSON pipe 批次執行，零 round-trip 開銷

**綜合評分**：

| 維度 | 評分（1-5） | 說明 |
|------|-----------|------|
| CI 整合性 | 4 | 一行安裝；headless 原生支援；Lightpanda 可選 |
| 穩定性 | 5 | daemon 持久化；session 完全連續 |
| 維護成本 | 4 | Rust 高效；CLI 語意清晰；Vercel/Anthropic 雙重支援 |
| 社群支援 | 4 | 官方文件在 Anthropic docs；Plugin 生態整合 |
| Agent 友善度 | 5 | CLI chaining；檔案截圖；Ref 系統；Batch 指令 |
| **加權總分** | **4.4** | |

---

### 方案 D：Selenium WebDriver

老牌 Web 自動化框架，支援多種語言（Python、Java、Node.js）和多種瀏覽器（Chrome、Firefox、Safari）。

#### 主要評估結論

- **CI 整合性（2/5）**：需要安裝 WebDriver（ChromeDriver）並管理版本相容性，CI 設定複雜
- **穩定性（3/5）**：成熟穩定，但 WebDriver 協定比 CDP 慢，更新節奏保守
- **維護成本（2/5）**：需要選擇語言綁定（Python/Node.js），Agent 需生成完整腳本執行，與 Shikigami 的 Shell/Markdown 技術棧不符
- **社群支援（5/5）**：最成熟的瀏覽器自動化社群，文件極為豐富
- **Agent 友善度（1/5）**：無 CLI 介面，必須生成完整程式碼，不適合 Agent 環境

**結論**：否決。技術棧不匹配，Agent 生成腳本路徑複雜，無 CLI 介面無法在 Skill.md 中直接定義命令。

---

## 方案比較總覽

| 方案 | CI 整合性 | 穩定性 | 維護成本 | 社群支援 | Agent 友善度 | **加權總分** |
|------|---------|--------|---------|---------|------------|------------|
| A: Playwright MCP | 2 | 2 | 4 | 3 | 2 | 2.6 |
| B: Puppeteer | 3 | 3 | 2 | 4 | 2 | 2.8 |
| **C: agent-browser** | **4** | **5** | **4** | **4** | **5** | **4.4** |
| D: Selenium | 2 | 3 | 2 | 5 | 1 | 2.6 |

---

## 決策

**選定方案：方案 C — agent-browser（Vercel，Rust native daemon）**

### 決策摘要

| 決策項 | 結論 |
|--------|------|
| 主工具 | agent-browser（`npm install -g agent-browser`）|
| 瀏覽器引擎 | Chrome/Chromium（預設）；CI 環境可選 Lightpanda 加速 |
| Session 管理 | daemon 持久化；多 agent 場景使用 `--session-name` 隔離 |
| 截圖策略 | 儲存為檔案（`/tmp/qa-e2e/`、`/tmp/ux-verify/`、`/tmp/sre-smoke/`），不回傳 base64 |
| 降級行為 | agent-browser 未安裝時輸出 WARN 並跳過，不阻擋流程 |
| CI 安裝方式 | `npm install -g agent-browser && agent-browser install` |
| 平台支援 | Claude Code（主要）；其他平台降級處理 |

### 選定理由

1. **持久化 daemon 解決 session 連續性問題**：Issue #272 Spike 識別的核心風險（MCP 跨 tool call session 不連續）在 agent-browser 的 daemon 架構中不存在。多步驟 E2E 測試（登入→操作→驗證）可在同一 session 中完整執行。

2. **CLI chaining 降低 context 消耗**：單一 Bash tool call 可串接多個操作，相比 Playwright MCP 每步驟獨立 tool call，顯著減少 Agent 與系統的 round-trip 次數。

3. **截圖儲存為檔案而非 base64**：解決 Playwright MCP 的 context flooding 問題。截圖結果以檔案路徑回傳，不佔用 Agent context。

4. **Ref 系統語意清晰**：`snapshot -i` 產出語意化 element ref（`@e1`, `@e2`），直接在後續指令中引用，Skill.md 撰寫自然。

5. **Vercel + Anthropic 雙重生態整合**：agent-browser 官方文件已收錄在 Anthropic Claude Code 文件中，與 Shikigami 作為 Claude Code Plugin 的生態定位一致。

6. **現有 Skill 已採用此方案**：`skills/browser-automation/SKILL.md` 中已以 agent-browser 定義完整使用規範，選定此方案為延續既有決策、不引入新工具。

---

## CI/CD 安裝與設定方式

### Self-Hosted Runner 安裝

```bash
# Step 1: 安裝 agent-browser CLI
npm install -g agent-browser

# Step 2: 下載 Chrome（首次執行需要）
agent-browser install

# Step 3: 驗證安裝
agent-browser --version
which agent-browser
```

### CI Workflow 範例（GitHub Actions）

```yaml
- name: Install agent-browser
  run: |
    npm install -g agent-browser
    agent-browser install

- name: Run browser smoke test
  run: |
    agent-browser open https://staging.example.com && \
    agent-browser wait --load networkidle && \
    agent-browser screenshot /tmp/sre-smoke/deploy-check.png
  env:
    AGENT_BROWSER_IDLE_TIMEOUT_MS: 60000  # CI 環境自動關閉 daemon
```

### Lightpanda（CI 加速選項）

在純 headless CI 環境，可使用 Lightpanda 引擎降低資源消耗：

```bash
# 安裝 Lightpanda（詳見 https://lightpanda.io/docs/open-source/installation）
agent-browser --engine lightpanda open https://example.com
```

注意：Lightpanda 不支援 `--extension`、`--profile`、`--state`、`--allow-file-access`。

### 環境變數配置

| 變數 | 說明 | 建議值 |
|------|------|--------|
| `AGENT_BROWSER_IDLE_TIMEOUT_MS` | daemon 閒置自動關閉（ms）| CI: `60000`；本地: 不設定 |
| `AGENT_BROWSER_MAX_OUTPUT` | 輸出字元上限，防止 context flooding | `50000` |
| `AGENT_BROWSER_CONTENT_BOUNDARIES` | 啟用內容邊界標記（防 prompt injection）| `1`（建議啟用）|
| `AGENT_BROWSER_DEFAULT_TIMEOUT` | 預設逾時（ms）| `25000`（預設）|

---

## 對 #385 GAD Delivery 的影響

本 ADR 直接 unblock #385（GAD Delivery Phase）中的視覺對比需求：

| #385 需求 | 對應 agent-browser 方案 |
|-----------|----------------------|
| 視覺截圖比對 | `diff screenshot --baseline before.png` |
| DOM 結構 diff | `diff snapshot` |
| Responsive 驗證 | `set device "iPhone 14"` + `screenshot` |
| 部署後 smoke test | `open → wait --load networkidle → screenshot` |

GAD Delivery 的視覺對比 pipeline 建議採用：

```bash
# GAD 視覺對比流程
agent-browser open <baseline_url> && agent-browser screenshot /tmp/gad-baseline.png
agent-browser open <current_url> && agent-browser screenshot /tmp/gad-current.png
agent-browser diff screenshot --baseline /tmp/gad-baseline.png
```

---

## 後果

### 正面

- **#385 unblocked**：GAD Delivery 的視覺對比方案明確，可直接進入 Delivery Phase
- **Session 連續性保證**：多步驟 E2E 測試（登入→操作→驗證）可靠執行
- **Context 效率提升**：CLI chaining + 檔案截圖，相比 Playwright MCP 大幅降低 token 消耗
- **CI 可靠性**：一行安裝，headless 原生支援，無環境設定複雜度
- **現有 Skill 相容**：`skills/browser-automation/SKILL.md` 無需修改，本 ADR 補上其缺少的正式決策依據

### 負面

- **單一工具依賴**：若 agent-browser 停止維護（低概率，Vercel 活躍維護），需評估遷移成本
- **非 Claude Code 平台**：OpenCode / Gemini CLI / Cursor 平台上 agent-browser 可用性取決於各平台的 tool 支援；Shikigami 對此場景的降級行為為 WARN + 跳過

### 風險緩解

| 風險 | 可能性 | 影響 | 緩解措施 |
|------|-------|------|---------|
| agent-browser 在特定 runner 安裝失敗 | 低 | 中 | 降級行為：WARN + 跳過瀏覽器驗證，不阻擋主流程 |
| Lightpanda 功能不完整（不支援 state/profile）| 中 | 低 | Lightpanda 僅用於純截圖/smoke test 場景；需 auth 的場景用 Chrome 引擎 |
| daemon 進程殘留（CI 環境）| 中 | 低 | 設定 `AGENT_BROWSER_IDLE_TIMEOUT_MS=60000` 確保 CI job 結束後自動清理 |
| self-hosted runner 無 npm 存取 | 低 | 高 | 提前在 runner image 中預裝 agent-browser；或設定 npm registry mirror |

---

## 附錄：工具安裝快速參考

```bash
# 安裝
npm install -g agent-browser
agent-browser install  # 下載 Chrome

# 升級
agent-browser upgrade

# 驗證
agent-browser --version
which agent-browser || echo "NEEDS_INSTALL"

# WSL / 無顯示環境
agent-browser open <url> --headless

# CI 環境（自動清理 daemon）
AGENT_BROWSER_IDLE_TIMEOUT_MS=60000 agent-browser open <url>
```
