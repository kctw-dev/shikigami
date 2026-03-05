# ADR-013：shikigami:diagram MCP 整合架構決策

**狀態**：Proposed
**日期**：2026-03-05
**決策者**：Architect
**關聯 Issue**：#89（feat: shikigami:diagram 技能）、#95（US-96 本 ADR 起草）
**關聯 ADR**：ADR-006（Prompt Injection 防護）、ADR-011（GitHub Actions 整合）、ADR-012（Claude Max 多開發環境認證架構）

---

## 背景

Issue #89（feat: shikigami:diagram 技能）提出在 Sprint 執行期間遇到架構圖需求時，能自動調度 `shikigami:diagram` 技能，產出帶有 GCP/AWS/Azure 官方圖標的 draw.io 架構圖並嵌入文件。技術方向定義為以 `lgazo/drawio-mcp-server` 為基底，整合 Claude Code MCP 機制。

Issue #89 的原始設計明確偏向 Cloud Run + HTTP+SSE 的遠端 MCP 架構。然而，該方案的 RICE Confidence 評分僅 0.5（「Cloud Run 部署 + MCP HTTP+SSE 整合技術複雜度高，實作風險不低」），Story Size 標記為 L。

本 ADR 依據以下四個決策域進行系統性評估，為實作階段提供有理據的架構選擇：

1. **部署形態**：Cloud Run（scale-to-zero）vs. stdio local
2. **MCP Transport**：HTTP+SSE（remote）vs. stdio（local）
3. **CI 整合策略**：Cloud Run 直呼叫 vs. 跳過 vs. Mock
4. **安全考量**：認證機制、Secrets 管理、Injection 防護、Supply Chain

### 約束條件

| 約束 | 來源 | 說明 |
|------|------|------|
| ADR-006 Injection 防護繼承 | ADR-006 §影響 | 任何外部資料（MCP server 輸出、圖標套件內容）進入 Skill prompt 時，必須套用 XML 隔離標記 |
| ADR-011 GitHub Actions 整合 | ADR-011 §決策 | CI 環境認證採用 GITHUB_TOKEN + ANTHROPIC_API_KEY，無互動式瀏覽器登入能力 |
| ADR-012 零硬編碼 Secrets | ADR-012 §約束條件 | 所有認證資訊（Cloud Run URL、API Key）必須透過 GitHub Secrets 或環境變數注入 |
| YAGNI 原則 | ADR-011、ADR-012 共同確立 | MVP 階段不實作超出當前需求的複雜度 |
| 小團隊 / M5 穩定化階段 | 專案現狀 | 維護負擔需控制在合理範圍，避免引入持續性 Ops 成本 |

---

## 決策問題

Shikigami 框架在 MVP 階段，應以何種部署架構與 MCP 整合方案實現 `shikigami:diagram` 技能，在技術可行性、維護成本、CI 相容性與安全性之間取得最佳平衡？

---

## 決策域 1：部署形態

### Option A：Cloud Run（scale-to-zero 遠端服務）

drawio-mcp-server 容器化後部署至 Google Cloud Run，設定 scale-to-zero。Claude Code 透過 HTTP+SSE transport 連接遠端 MCP server。

#### 架構示意

```
Claude Code（本機 / CI）
    │
    │ HTTP+SSE（MCP remote transport）
    ▼
Cloud Run：drawio-mcp-server
    │
    ├── headless Chrome（draw.io rendering）
    ├── GCP / AWS / Azure icon set
    └── .drawio + .png / .svg 輸出
```

#### 優缺點矩陣

| 面向 | 評估 | 說明 |
|------|------|------|
| 消除本機環境分歧 | 優 | 所有開發機（多 GCE）與 CI 共用同一 rendering 環境，輸出一致 |
| Scale-to-zero 成本 | 優 | 無用量時不計費，適合低頻使用場景 |
| 首次啟動延遲（Cold Start） | 劣 | headless Chrome Container Cold Start 可達 5-15 秒，影響互動體驗 |
| 部署複雜度 | 劣 | 需 Dockerfile、Cloud Run 設定、IAM 權限、VPC 連線等；初始建置工作量 M-L |
| 持續維護成本 | 劣 | Cloud Run 服務需監控、更新、版本管理；headless Chrome 安全更新需追蹤 |
| CI 整合 | 需額外設計 | CI 需 Cloud Run URL + 認證（詳見決策域 3） |
| 本機開發依賴網路 | 劣 | 離線開發環境無法使用 |
| 技術成熟度 | 中 | Cloud Run MCP 模式為新興用法，社群案例有限 |

---

### Option B：stdio local（本機程序）

drawio-mcp-server 安裝於本機（或 CI runner），Claude Code 透過 stdio transport 直接 spawn 程序，無需網路。

#### 架構示意

```
Claude Code（本機 / CI runner）
    │
    │ stdio（MCP local transport）
    ▼
drawio-mcp-server（本機程序）
    │
    ├── headless Chrome（本機安裝或 CI runner 安裝）
    └── .drawio + .png / .svg 輸出
```

#### .mcp.json 設定示意

```json
{
  "mcpServers": {
    "drawio": {
      "type": "stdio",
      "command": "npx",
      "args": ["drawio-mcp-server"]
    }
  }
}
```

#### 優缺點矩陣

| 面向 | 評估 | 說明 |
|------|------|------|
| 無網路依賴 | 優 | 離線環境可用；延遲最低（本機程序通訊） |
| 無 Cold Start | 優 | Claude Code spawn 程序即可使用，無等待窗口 |
| 部署複雜度低 | 優 | `.mcp.json` 設定即完成整合；無需 Cloud / GCP 基礎設施知識 |
| 持續維護成本低 | 優 | 工具以 npm package 管理，版本升級同一般依賴 |
| 本機環境分歧 | 劣 | 多 GCE 開發機需個別安裝（ADR-012 多 GCE 場景），工具版本可能分歧 |
| headless Chrome 本機需求 | 劣 | 各開發機與 CI runner 需安裝 headless Chrome（Puppeteer 相依） |
| MCP stdio 技術成熟度 | 優 | stdio 為 MCP spec 最早定義的 transport；Claude Code 原生支援，穩定性高 |
| CI 整合 | 直接可用 | CI runner 安裝相同 npm package 即可，無需額外認證基礎設施 |

---

### 決策域 1 評估矩陣

| 評估維度 | Option A（Cloud Run） | Option B（stdio local） |
|---------|---------------------|------------------------|
| 初始建置成本 | 高（Cloud Run + IAM + Dockerfile） | 低（npm install + .mcp.json） |
| 持續維護成本 | 中（Cloud Run 監控、Chrome 安全更新） | 低（npm update） |
| 執行延遲 | 高（Cold Start 5-15s） | 低（本機程序啟動 <1s） |
| 環境一致性 | 高（單一中央服務） | 中（需各環境同步安裝） |
| CI 整合難度 | 高（需 Cloud Run URL + 認證） | 低（npm install 即可） |
| 離線可用性 | 無 | 完整 |
| YAGNI 符合度 | 低（Over-engineering for MVP） | 高 |
| ADR-012 多 GCE 相容性 | 完全相容（中央服務） | 需各 GCE 個別安裝 |
| 技術成熟度 | 低（新興模式） | 高（MCP stdio 規格穩定） |

---

## 決策域 2：MCP Transport

本決策域與決策域 1 強耦合：部署形態決定可用的 transport。

### Option A：HTTP+SSE（Remote MCP Transport）

適用於 Option 1A（Cloud Run）。Claude Code 連接遠端 MCP server，透過 SSE（Server-Sent Events）接收串流回應。

#### 優缺點矩陣

| 面向 | 評估 | 說明 |
|------|------|------|
| 多客戶端共享 | 優 | 多個 Claude Code 實例可連接同一 MCP server |
| 認證機制完整 | 優 | HTTP Bearer Token / OIDC 認證，可精細控管存取 |
| 網路依賴 | 劣 | 需穩定網路；GCP 服務中斷影響所有客戶端 |
| .mcp.json Secrets 管理 | 複雜 | URL、Auth Token 需安全管理（ADR-012 §零硬編碼 Secrets） |
| 除錯難度 | 高 | SSE 連線問題、Cloud Run timeout、網路錯誤需額外 logging |
| Claude Code 支援 | 支援 | Claude Code 0.2.x+ 支援 HTTP+SSE remote MCP（`type: "http"`） |

---

### Option B：stdio（Local MCP Transport）

適用於 Option 1B（stdio local）。Claude Code 直接 spawn 本機程序，透過 stdin/stdout 溝通。

#### 優缺點矩陣

| 面向 | 評估 | 說明 |
|------|------|------|
| 最簡單整合路徑 | 優 | Claude Code 原生支援；`.mcp.json` 設定 `type: "stdio"` 即完成 |
| 無認證複雜度 | 優 | 本機程序無需網路認證；Secrets 管理需求最低 |
| 程序生命週期管理 | 中 | Claude Code 負責 spawn/teardown；crash 自動重啟需設定 |
| 除錯容易 | 優 | stderr 直接輸出；本機 log 易存取 |
| 不支援多客戶端共享 | 劣 | 每個 Claude Code 實例獨立 spawn，無法共用 rendering 資源 |
| ADR-006 Injection 延伸 | 需注意 | MCP server 回傳的 tool 輸出視為外部資料，須套用 XML 隔離標記（見決策域 4） |

---

### 決策域 2 評估矩陣

| 評估維度 | Option A（HTTP+SSE） | Option B（stdio） |
|---------|---------------------|-----------------|
| 整合複雜度 | 高 | 低 |
| 認證需求 | 高（Bearer Token / OIDC） | 無 |
| Secrets 管理 | 需要（URL + Token） | 不需要 |
| 除錯難度 | 高 | 低 |
| 穩定性 | 依賴網路與 Cloud Run | 依賴本機程序（成熟） |
| Claude Code 原生支援程度 | 中（較新功能） | 高（規格最早定義） |
| ADR-012 CI 環境相容性 | 需額外 Secret 管理 | 直接可用 |

---

## 決策域 3：CI 整合策略

本決策域評估在 GitHub Actions CI（ADR-011 §決策：Push-Based 事件觸發）中如何處理 `shikigami:diagram` 技能。

### 背景約束

ADR-011 §OQ-2 已決策「US-12 MVP 採用輕量化 CI-specific 子集模式，僅執行 CI 狀態感知與 Issue 回寫兩個步驟」。diagram 技能屬於內容生成技能，非 CI 驗證流程的必要組成。

---

### Option A：CI 直接呼叫 drawio-mcp-server

在 GitHub Actions runner 中直接執行 diagram 生成（無論部署形態為 Cloud Run 或 stdio）。

#### 優缺點矩陣（Cloud Run 子情境）

| 面向 | 評估 | 說明 |
|------|------|------|
| 圖表在 CI 中自動更新 | 優 | PR 合併後自動重建圖表，確保文件同步 |
| Cloud Run 認證 | 劣 | 需在 GitHub Secrets 管理 Cloud Run URL 和 IAM Service Account Key |
| Cold Start 影響 CI 時間 | 劣 | 每次 CI 執行需等待 Cloud Start（5-15s） |
| CI 成本 | 劣 | headless Chrome rendering 增加 CI 執行時間與費用 |

#### 優缺點矩陣（stdio 子情境）

| 面向 | 評估 | 說明 |
|------|------|------|
| 設置相對簡單 | 中 | npm install + headless Chrome 安裝步驟需加入 workflow |
| CI runner headless Chrome 需求 | 劣 | ubuntu-latest 需額外安裝 Chromium；增加 CI 設置複雜度 |
| 非測試性操作在 CI 中執行 | 劣 | 圖表生成為內容產出，與 CI 驗證職責不符 |

---

### Option B：CI 跳過 diagram 生成

在 CI 環境中識別 diagram 技能呼叫並跳過，僅執行語法 / 結構驗證。

#### 優缺點矩陣

| 面向 | 評估 | 說明 |
|------|------|------|
| CI 執行簡潔 | 優 | CI 流程不包含圖表生成，執行時間短 |
| 無額外基礎設施需求 | 優 | 不需 Cloud Run URL、headless Chrome |
| 圖表可能過時 | 劣 | CI 不驗證圖表是否與文件同步，需人工紀律維護 |
| ADR-011 輕量 CI 子集一致 | 優 | 符合 ADR-011 §OQ-2 決策：CI 僅執行驗證性步驟 |

---

### Option C：CI 以 Mock 替代

在 CI 環境中替換 drawio-mcp-server 為 mock，輸出固定格式的假回應，僅驗證技能調用流程。

#### 優缺點矩陣

| 面向 | 評估 | 說明 |
|------|------|------|
| 技能調用路徑可驗證 | 優 | MCP 協議整合、參數傳遞可在 CI 中驗證 |
| 無 headless Chrome 需求 | 優 | Mock 無渲染邏輯，CI 輕量 |
| Mock 維護成本 | 劣 | 需維護 mock server；MCP server API 變更需同步更新 mock |
| 無法驗證實際圖表輸出 | 劣 | 圖表正確性仍需人工驗證 |
| 實作成本中等 | 劣 | 需建立 mock server 或 stub 機制；超出 MVP 範疇 |

---

### 決策域 3 評估矩陣

| 評估維度 | Option A（直接呼叫） | Option B（跳過） | Option C（Mock） |
|---------|-------------------|----------------|----------------|
| CI 執行時間影響 | 高（+rendering 時間） | 無 | 低 |
| 基礎設施需求 | 高 | 無 | 中 |
| ADR-011 輕量 CI 原則符合度 | 低 | 高 | 中 |
| 實作複雜度 | 高 | 無 | 中 |
| 圖表同步驗證 | 完整 | 無 | 部分（路徑驗證） |
| MVP 階段適當性 | 低 | 高 | 中 |

---

## 決策域 4：安全考量

### 4.1 認證機制

#### 情境 A：Cloud Run 認證（Option 1A）

Cloud Run 服務需存取控制，防止未授權呼叫。

| 方案 | 說明 | 評估 |
|------|------|------|
| IAM OIDC（Cloud Run Invoker role） | GCP IAM 細粒度控管；CI 透過 Workload Identity 認證 | 安全性高；設置複雜；需 GCP IAM 知識 |
| Bearer Token（API Key in URL params） | 簡單但 Token 暴露在 URL log 中 | 不推薦用於生產 |
| allUsers（公開存取） | 無認證；任何人可呼叫 | 安全風險高；不可接受 |

Cloud Run 認證方案若選 IAM OIDC，需與 ADR-012 §GitHub Actions 環境的 `ANTHROPIC_API_KEY` Secrets 管理並列，增加 GitHub Secrets 管理複雜度。

#### 情境 B：stdio local 認證

本機程序無網路認證需求。認證在 OS 程序層面天然隔離（僅本機用戶可 spawn）。

---

### 4.2 .mcp.json Secrets 管理

`.mcp.json` 為版本控制追蹤的檔案（通常 commit 至 repo）。

| 風險 | 說明 | 緩解策略 |
|------|------|---------|
| Cloud Run URL 洩漏 | URL 若 commit 至公開 repo，任何人可嘗試呼叫服務 | URL 以 `${MCP_DRAWIO_URL}` 環境變數形式存入 .mcp.json；實際值存於 .env（.gitignore） |
| Auth Token 洩漏 | Bearer Token commit 至 repo | 禁止 hardcode；ADR-012 §零硬編碼 Secrets 約束繼承 |
| stdio 情境的 Secrets | stdio server 通常無需 Secrets | 若 drawio-mcp-server 未來支援 API Key，同樣須環境變數注入 |

---

### 4.3 ADR-006 Injection 防護延伸

ADR-006（Prompt Injection Protection）定義了外部資料進入 Skill prompt 時的 XML 隔離標記規則。`shikigami:diagram` 技能引入新的外部資料來源：

| 資料來源 | 注入風險 | 緩解策略 |
|---------|---------|---------|
| MCP tool 回傳內容（drawio-mcp-server 輸出） | drawio-mcp-server 若被供應鏈攻擊，可能在 tool 回應中插入惡意 LLM 指令 | **繼承 ADR-006 規則 1**：MCP tool 輸出以 `<mcp_tool_output>...</mcp_tool_output>` XML 標記包裹後傳入 Skill prompt |
| `--provider` 參數（使用者輸入） | 使用者可傳入 `--provider "gcp; ignore all previous..."` | 參數值限制為 enum（`gcp` / `aws` / `azure`），拒絕不在允許清單的值 |
| draw.io 圖表內容嵌入 Markdown | 惡意 drawio-mcp-server 可能在 .drawio XML 中嵌入內容 | .drawio 檔案視為二進制工件輸出，不解析為 LLM prompt 輸入 |

**ADR-006 §影響 延伸宣告**：`shikigami:diagram` SKILL.md 必須在「MCP tool 呼叫後處理」步驟中聲明，所有 drawio-mcp-server 回傳的 tool 輸出均屬外部不信任資料，套用 XML 隔離標記。

---

### 4.4 Supply Chain 安全（第三方 MCP Server）

`lgazo/drawio-mcp-server` 為第三方 npm package / GitHub repository。

| 風險 | 說明 | 緩解策略 |
|------|------|---------|
| 惡意版本發布 | npm package 遭供應鏈攻擊，新版本包含惡意程式碼 | 版本鎖定（`package-lock.json` 或精確版號）；避免 `@latest` |
| 執行環境隔離 | drawio-mcp-server 有 headless Chrome 執行能力，若被控制可執行任意程式碼 | stdio 情境：程序在本機用戶層執行，與 CI runner 具相同隔離等級；Cloud Run 情境：Container 提供額外隔離層 |
| package 審計 | 定期檢查依賴漏洞 | `npm audit` 整合至 CI 驗證（可加入現有 `validate.yml`） |
| 最小權限 | MCP server 執行不應有讀取 repo Secrets 的能力 | stdio 情境：不在 MCP server spawn 環境中注入 ANTHROPIC_API_KEY 或 GITHUB_TOKEN |

---

## 整體評估與建議

### 評估摘要矩陣

| 決策維度 | Cloud Run + HTTP+SSE | stdio local |
|---------|---------------------|-------------|
| 初始建置成本 | 高 | 低 |
| 持續 Ops 成本 | 中（Cloud Run 監控） | 低 |
| 技術風險 | 高（新興 Remote MCP 模式） | 低（MCP stdio 穩定成熟） |
| CI 整合 | 複雜（需額外 Secrets） | 簡單（npm install） |
| 安全考量複雜度 | 高（IAM、SSE 認證、URL Secrets） | 低（OS 層隔離） |
| RICE Confidence 影響 | 降低（0.5 反映此風險） | 提升（成熟路徑） |
| YAGNI 符合度 | 低 | 高 |
| Issue #89 原始偏好 | 明確偏向 | 未明確偏好 |

---

## 決策結果（Proposed）

### 建議方案：stdio local + MCP stdio transport + CI 跳過 + 最小 Secrets

基於 Shikigami 專案現況（小團隊、MVP 階段、M5 穩定化目標）與各決策域評估，本 ADR **建議採用以下組合方案**：

| 決策域 | 建議選項 | 理由 |
|--------|---------|------|
| 決策域 1：部署形態 | **Option B — stdio local** | 零基礎設施需求；無 Cold Start；維護成本低；符合 YAGNI |
| 決策域 2：MCP Transport | **Option B — stdio** | 與部署形態強耦合；MCP stdio 技術成熟穩定；整合複雜度最低 |
| 決策域 3：CI 整合 | **Option B — 跳過 diagram 生成** | 符合 ADR-011 §OQ-2 輕量 CI 子集原則；CI 職責清晰（驗證而非生成） |
| 決策域 4：安全考量 | **最小 Secrets + ADR-006 延伸** | 繼承 ADR-006 XML 隔離；版本鎖定 drawio-mcp-server；`--provider` enum 驗證 |

### 決策理由

#### 1. 技術成熟度優先（MVP 原則）

Cloud Run + HTTP+SSE 為 MCP 規格的新興遠端模式，社群案例有限。stdio 為 MCP spec 最早定義且最廣泛使用的 transport，Claude Code 原生支援穩定。在 RICE Confidence 僅 0.5 的情況下，選擇技術成熟的路徑可將 Confidence 提升至 0.7-0.8，顯著降低實作風險。

#### 2. 維護成本可控

小團隊（單一開發者）環境中，Cloud Run 服務的持續維護（監控、headless Chrome 安全更新、Container 版本管理、GCP IAM 設定）會成為持續性 Ops 負擔。stdio 方案將維護範圍縮減至 npm package 版本更新，與現有開發工具鏈管理模式一致。

#### 3. ADR-012 多 GCE 環境相容性

ADR-012 決策的多 GCE 開發環境中，stdio 方案需各 GCE 個別安裝 drawio-mcp-server（npm install）。這一輕量操作可納入 ADR-012 §環境可重建性建議（Issue #90 追蹤的 dotfiles/IaC 範疇），不構成額外架構複雜度。

#### 4. CI 跳過符合職責分離

`shikigami:diagram` 是內容生成技能，在 CI 中執行圖表生成不符合 CI 驗證職責定義（ADR-011 §OQ-2）。圖表的正確性驗證屬於 Sprint Review 人工確認範疇，CI 不應承擔此職責。

#### 5. 演進路徑清晰

若未來需求確實需要 Cloud Run（如多專案共享同一 rendering 服務、CI 中自動更新圖表），可在此時升級架構。stdio 方案不阻礙未來遷移至 Cloud Run，演進成本低（更換 `.mcp.json` transport 設定 + 建立 Cloud Run service）。此符合演進式架構的可逆性原則。

---

## 影響

### 對 Issue #89 實作範圍的影響

| 面向 | 原始設計（Issue #89） | 本 ADR 建議 |
|------|---------------------|------------|
| 部署形態 | Cloud Run | stdio local（降低初始複雜度） |
| MCP Transport | HTTP+SSE | stdio |
| CI 整合 | 未明確定義 | 跳過 diagram 生成 |
| 安全基礎 | 未詳細定義 | ADR-006 延伸 + 版本鎖定 |
| Story Size 影響 | L（RICE Effort = 3） | 預期可降至 M（Cloud Run 去除後主要工作量為 headless Chrome 設定與 MCP 整合測試） |

### 對現有 ADR 的影響

| ADR | 影響類型 | 說明 |
|-----|---------|------|
| ADR-006 | 延伸 | `shikigami:diagram` SKILL.md 必須宣告 drawio-mcp-server tool 輸出為不信任外部資料，套用 XML 隔離標記 |
| ADR-011 | 繼承 | CI 跳過 diagram 生成，與 ADR-011 輕量 CI 子集決策一致；无新增衝突 |
| ADR-012 | 補充 | stdio local 安裝需納入 Issue #90 多 GCE 環境可重建性清單（`npm install drawio-mcp-server@<version>`） |

### 對 .mcp.json 的影響

```json
{
  "mcpServers": {
    "drawio": {
      "type": "stdio",
      "command": "npx",
      "args": ["drawio-mcp-server@<pinned-version>"]
    }
  }
}
```

`.mcp.json` 版本鎖定（精確版號取代 `@latest`），符合 §4.4 Supply Chain 安全建議。

---

## 開放問題

本 ADR 起草階段識別以下開放問題，待 Issue #89 實作前解決：

| # | 問題 | 優先級 | 說明 |
|---|------|--------|------|
| OQ-1 | drawio-mcp-server headless Chrome 在 GCE 環境的安裝方式 | 高 | ubuntu-based GCE 通常需 `apt install chromium-browser`；需確認與 drawio-mcp-server 的 Chrome 路徑期望是否一致 |
| OQ-2 | drawio-mcp-server 輸出格式確認 | 高 | 需確認 tool 回傳的是檔案路徑還是 Base64 內容，影響 ADR-006 隔離標記的設計 |
| OQ-3 | 多圖標集（--provider）的本機 icon set 資源管理 | 中 | GCP / AWS / Azure icon set 是否包含於 npm package 中，或需另行下載；影響安裝指引 |
| OQ-4 | 未來 Cloud Run 升級觸發條件 | 低 | 若 stdio 方案有明確不足（如多 CI parallel 競爭、跨專案共享），重新評估 Cloud Run 方案的觸發條件需明確定義 |

---

## 升級路徑（Cloud Run 評估觸發條件）

本 ADR 建議 stdio local 為 MVP 方案，但以下條件成立時應重新評估 Cloud Run 方案：

1. **多專案共享需求**：2 個以上 Shikigami 框架專案需要共享同一 rendering 服務
2. **CI 圖表自動更新需求**：Sprint Review 確認需要 CI 自動重建圖表以驗證同步性
3. **本機安裝維護負擔超出預期**：多 GCE 環境中 headless Chrome 版本分歧問題頻繁出現
4. **drawio-mcp-server 官方提供 Cloud Run 部署指引**：官方支援降低技術風險，RICE Confidence 提升至 0.7+

---

## 參考

- GitHub Issue #89：feat: shikigami:diagram 技能 — draw.io MCP + Cloud Run 架構圖自動化
- GitHub Issue #95：US-96 ADR-013 起草（本 ADR 起源）
- ADR-006：Issue 內容提示注入防護（§影響、§Prompt Injection Isolation Rule）
- ADR-006 Addendum：JSON Schema 驗證決策（TD-002）
- ADR-011：GitHub Actions 整合架構決策（§OQ-2 CI 輕量子集決策）
- ADR-012：Claude Max 多開發環境認證架構決策（§約束條件、§環境管理考量）
- [MCP Specification — Transports](https://spec.modelcontextprotocol.io/specification/basic/transports/)（stdio vs HTTP+SSE）
- [lgazo/drawio-mcp-server](https://github.com/lgazo/drawio-mcp-server)（第三方 MCP server 基底）
- OWASP Top 10 for LLM Applications — LLM03: Supply Chain（第三方 MCP server 風險）
