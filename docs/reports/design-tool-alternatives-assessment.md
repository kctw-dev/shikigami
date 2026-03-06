# 設計工具替代品調查報告
## Figma vs 開源 / AI-native 選項評估

**調查日期**：2026-03-06
**調查範圍**：AI 直接操作設計工具畫 UI 的最佳選擇評估
**核心需求**：AI 讀取 User Story → 直接在設計工具中畫 UI → 審查 → 出代碼

---

## 1. 候選工具比較矩陣

評分尺度：★★★★★（優秀）/ ★★★★（良好）/ ★★★（中等）/ ★★（薄弱）/ ★（幾乎不支援）/ ✗（不支援）

| 評估維度 | **Figma** | **Penpot** | **Framer** | **Plasmic** | **Builder.io** | **v0 (Vercel)** | **Subframe** | **Google Stitch** |
|---------|-----------|-----------|-----------|------------|---------------|----------------|-------------|-----------------|
| **API/MCP 可操作性** | ★★★★ | ★★★★ | ★★★ | ★★★ | ★★★ | ★★★★ | ★★★★★ | ★★ |
| **Design Token 支援** | ★★★★★ | ★★★★ | ★★ | ★★★ | ★★★ | ✗ | ★★★★ | ★★ |
| **Component Library** | ★★★★★ | ★★★★ | ★★★★ | ★★★★★ | ★★★★ | ★★★★ | ★★★★★ | ★★★ |
| **代碼生成能力** | ★★★ | ★★★ | ★★ | ★★★★ | ★★★★★ | ★★★★★ | ★★★★★ | ★★★★ |
| **開源/自建可行性** | ✗ | ★★★★★ | ✗ | ★★★ | ✗ | ✗ | ✗ | ✗ |
| **成本** | ★★★ | ★★★★★ | ★★ | ★★★ | ★★★ | ★★★★ | ★★★★ | ★★★★★ |
| **AI 整合生態** | ★★★★ | ★★★★ | ★★★ | ★★ | ★★★★ | ★★★★★ | ★★★★★ | ★★★★ |
| **協作能力** | ★★★★★ | ★★★★ | ★★★★ | ★★★ | ★★★ | ✗ | ★★★ | ✗ |

---

## 2. 各工具 AI 可操作性詳細分析

### 2.1 Figma

**AI 可操作性**：中高

Figma 在 2025 年推出官方 MCP Server，允許 AI agent 透過 Model Context Protocol 直接讀取設計文件的結構化資料——包含 frame 層級、layout 規則、文字樣式、component properties 與 design token。

**關鍵能力**：
- **讀取面**：MCP Server 可向 AI 提供完整的 Figma 文件 JSON，包含 Variables（Design Token）定義
- **寫入面（受限）**：REST API 支援透過程式建立/更新 Variable Collections、Variables，但直接建立視覺元件仍需透過 Plugin API（需在 Figma 應用程式環境中執行），無法純由外部 HTTP 請求完成
- **代碼生成**：透過 MCP，AI agent 可從設計稿生成框架代碼（React/HTML/CSS），Figma Make 也支援 AI 直接生成 UI 並轉為代碼
- **Design System**：MCP Server 可掃描代碼庫並生成 Design System 規則檔，為 AI agent 提供 Token、Component 層級的引導

**限制**：
- 純程式化「建立視覺元件並排版」的能力依賴 Plugin API，必須在 Figma 客戶端內執行，不支援 headless 操作
- 閉源 SaaS，無法自建
- 付費方案：Free（3 個 Figma 文件）/ Starter $15/月 / Professional $45/月

**MCP 整合**：官方 MCP Server（2025 Q1 上線），支援 Claude Code、Cursor、Windsurf、VS Code Copilot

---

### 2.2 Penpot

**AI 可操作性**：中高，且具開源優勢

Penpot 是目前唯一同時具備：（a）官方 MCP Server、（b）完整 Plugin API、（c）開源可自建 三者兼備的設計工具。

**關鍵能力**：
- **MCP Server（官方）**：2025 年 12 月正式釋出，整合至 Penpot 主倉庫。LLM 可透過 MCP 執行資料查詢、元件建立、樣式套用等操作
- **Plugin API**：提供對 Penpot 文件的程式化操作介面，可建立形狀、元件、套用樣式
- **Design Token（W3C DTCG 標準）**：Penpot 是**業界第一個**實作 W3C DTCG Design Token 標準的設計工具。Penpot 2.9（2025 年 8 月）加入 typography tokens；支援 Color、Spacing、Radius、Typography 等型別。Tokens Studio 也已整合 Penpot
- **開源自建**：完整 Docker / Kubernetes 部署，授權費用為零。一鍵部署（Docker Desktop Extension）
- **代碼生成**：透過 MCP 可實現設計稿轉代碼流程

**限制**：
- Plugin API 的 Design Token 程式化寫入（透過插件）仍在開發中（GitHub Issue #7916，2026 年積壓中）
- 生態系統成熟度低於 Figma，社群插件較少
- 效能與 UI 流暢度與 Figma 仍有差距

**成本**：完全免費（自建）或使用 Penpot Cloud（免費方案含完整功能）

---

### 2.3 Framer

**AI 可操作性**：中

Framer 定位為「設計即網站」，強調視覺設計與最終部署一體化，2025 年底推出官方 MCP Server。

**關鍵能力**：
- **Framer MCP**：作為安全橋接層，允許 AI assistant 自動化設計更新並匯出 React 代碼（自然語言指令）
- **AI 功能**：Wireframer（AI 生成線框稿）、Workshop（AI 元件建立）
- **Server API**：2025-2026 年新增，支援進階整合

**嚴重限制**：
- **無可匯出代碼**：網站僅存在於 Framer 伺服器上，取消訂閱即消失
- **設計師協作工具有限**：偏向網站建構而非 UI 設計規格制定
- **Design Token 支援薄弱**：無完整 Token 管理機制
- **付費門檻高**：MCP 的 React Export 功能為付費功能

**成本**：Free（基本）/ Mini $5/月 / Basic $15/月，但進階 AI 功能需付費

---

### 2.4 Plasmic

**AI 可操作性**：中

Plasmic 定位為「程式碼可選的視覺建構器」，強項在於與現有 React 代碼庫的雙向整合。

**關鍵能力**：
- **代碼整合**：可將既有 React 元件拖入視覺編輯器，並雙向同步
- **Plasmic API**：支援程式化操作（查詢、發布），但 AI 直接建立元件的能力有限
- **AI 輔助**：可在 AI 生成元件後，拖入 Plasmic 畫布使用

**限制**：
- AI 無法直接在 Plasmic 中建立完整 UI 設計（需人工拖拉）
- 無原生 MCP Server
- Design Token 支援有限

**成本**：Free / Growth $149/月 / Enterprise 議價

---

### 2.5 Builder.io

**AI 可操作性**：中高（聚焦設計→代碼轉換）

Builder.io 強項在於「視覺內容管理 + AI 代碼生成」，2025 年推出 Fusion 1.0 Agent。

**關鍵能力**：
- **Figma-to-Code**：可從 Figma 設計稿直接轉為 React/Vue/Svelte/Angular 代碼
- **Fusion 1.0**：連接產品—設計—代碼的 AI Agent，一體化工作流
- **Visual Editor 3.0**（2025 Q2）：AI 輔助將 UI 設計轉為互動應用
- **Headless CMS**：內容管理層適合行銷頁面場景

**限制**：
- 本質是「設計-to-代碼轉換工具」而非「AI 在設計工具中直接畫 UI」
- 設計端仍依賴 Figma，本身不是獨立設計環境
- 對設計師協作友善度一般

**成本**：Free / $19/月起

---

### 2.6 v0 by Vercel

**AI 可操作性**：高（代碼生成層面）

v0 是純 AI 代碼生成工具，不是設計工具。但其 Platform API 允許程式化呼叫生成 UI 代碼。

**關鍵能力**：
- **v0 Platform API**：文字提示直接生成 React + Tailwind + shadcn/ui 代碼，模型 v0-1.5-lg 支援 512K context
- **程式化整合**：支援 Slack Bot、VSCode 插件、CI/CD 流水線等嵌入場景
- **代碼品質高**：生成的 React 組件遵循最佳實踐，適合直接進入代碼庫

**本質限制**：
- **無設計工具介面**：v0 生成的是代碼而非可視覺審查的設計稿，缺乏「設計師審查」層
- **無 Design Token 概念**：生成結果基於 shadcn/ui 預設樣式，自定義性受限
- **無協作設計層**：不能滿足「設計師在同工具中介入」的需求

**成本**：Free（$5 額度/月）/ Premium $20/月 / Team $30/用戶/月

---

### 2.7 Subframe（重點新工具）

**AI 可操作性**：最高（AI-native 設計工具）

Subframe 是 2024-2025 年出現的「為 AI 時代而生」的設計工具，最貼近「AI 直接在設計工具畫 UI」的需求。

**關鍵能力**：
- **MCP Server（官方）**：允許 Claude Code、Cursor、Codex 等 AI agent 直接存取 Subframe 設計，自動取得元件、頁面、主題資料，無需手動複製
- **Design System 綁定**：所有 AI 生成的設計，強制在既定的 Design System 範圍內生成，確保一致性
- **設計即代碼**：視覺編輯的同時同步生成 React + Tailwind 代碼，設計與代碼永遠同步
- **AI 生成 UI**：AI 可在設計工具內直接生成並迭代 UI 方案，並可在代碼確認前先預覽
- **Component Library**：內建完整元件庫，所有元件都對應真實可用的 React 代碼

**限制**：
- SaaS 閉源，無法自建
- 相對新工具（2023 年成立），生態系統尚在建立中
- 傳統設計師可能需要適應工具哲學

**成本**：有免費方案（AI 生成次數無限制）；付費方案細節待確認

---

### 2.8 Google Stitch（原 Galileo AI）

**AI 可操作性**：中高（prompt-to-UI）

Galileo AI 於 2025 年 5 月被 Google 收購，重新命名為 Google Stitch，以 Gemini 2.5 為驅動引擎。

**關鍵能力**：
- **Prompt-to-UI**：文字或線框稿 → 完整 Mobile/Web UI 設計（使用 Gemini 2.5）
- **Figma 整合**：生成的設計可直接貼入 Figma
- **代碼匯出**：可匯出 HTML/CSS 代碼
- **免費**：目前為 Google Labs 免費工具

**限制**：
- **程式化 API 有限**：目前主要是對話式介面，無公開的程式化 API 供 AI agent 呼叫
- **生態尚早期**：2025 年中才推出，穩定性與功能深度仍在成熟中
- **Design Token 支援薄弱**：無完整 Token 管理

---

## 3. 架構決策分析：最適合「AI 直接畫 UI」工作流

### 3.1 工作流需求分解

```
User Story → [AI 解析需求] → [AI 在設計工具中建立 UI] → [設計師/AI 審查] → [代碼生成]
```

這個工作流對設計工具的要求：

| 需求層次 | 具體要求 |
|---------|---------|
| AI 寫入能力 | AI 能在設計工具中程式化建立元件、套樣式、排版 |
| 設計可審查性 | 生成的 UI 有視覺呈現，人可以審查修改 |
| Design System 對齊 | AI 生成時遵守 Token / Component 規範 |
| 代碼輸出 | 最終可匯出框架代碼（React） |

### 3.2 各工具對工作流的適配度

**Figma + Figma MCP**：
- 讀取優秀（MCP 可讀完整設計資料）
- **寫入受限**：外部 API 無法直接建立視覺層元件，只能透過 Plugin API（需在 Figma 客戶端內執行）
- 適合場景：「AI 讀取 Figma 設計稿，生成代碼」—即**設計→代碼**方向，而非**AI 直接建立設計**

**Penpot + Penpot MCP**：
- MCP Server 支援 LLM 執行**建立與轉換操作**（不只是讀取）
- 開源可自建，可深度整合至 CI/CD
- Design Token 採 W3C 標準，有利於跨工具同步
- 適合場景：**完整的 AI→設計→審查→代碼流程**，且需要自建控制權

**Subframe + Subframe MCP**：
- AI agent 透過 MCP 可直接在 Subframe 中操作設計（建立元件、套用 Design System）
- 設計與代碼永遠同步（設計即代碼哲學）
- 適合場景：**最符合「AI 直接畫 UI 並即時看到代碼」** 的工作流

**v0 Platform API**：
- 適合**純代碼生成**，跳過設計階段
- 若不需要視覺設計審查層，v0 API 是最快的路徑
- 適合場景：「AI 讀取 User Story，直接生成 React 代碼，無設計師審查」

---

## 4. 建議

### 4.1 主要結論

**Figma 在「AI 直接操作設計工具畫 UI」這個具體需求上，並非最佳選擇。**

Figma 的 MCP Server 主要是**讀取導向**（設計→代碼），而非**寫入導向**（AI→設計）。Plugin API 雖然支援程式化操作，但必須在 Figma 客戶端環境中執行，無法實現 AI headless 操作設計工具的架構。

### 4.2 分場景建議

**場景 A：想要最符合 AI-native 設計工作流，接受 SaaS 工具**

推薦 **Subframe + Subframe MCP**

理由：
- 是目前唯一真正為「AI agent 操作設計工具」而設計的工具
- MCP Server 允許 Claude Code 等 agent 直接在 Subframe 建立、迭代 UI
- Design System 約束確保生成一致性
- 設計與代碼同步，無轉換成本
- 設計師可在同工具中介入審查

---

**場景 B：需要完全自建控制、有資安或資料主權考量**

推薦 **Penpot（自建）+ Penpot MCP**

理由：
- 唯一兼具「官方 MCP + 完整 Plugin API + 開源自建」的設計工具
- 授權費用為零，Docker 部署即可
- Design Token 採 W3C DTCG 標準，有利於長期維護
- MCP Server 支援 AI 執行建立與轉換操作（非僅讀取）
- 缺點：生態系成熟度低於 Figma，Plugin Token API 尚在開發中

---

**場景 C：不需要視覺設計審查層，只要最快從 User Story 到代碼**

推薦 **v0 Platform API**

理由：
- 程式化 API 設計完整，適合 pipeline 整合
- 生成 React + Tailwind + shadcn/ui，代碼品質高
- 最短路徑：User Story → v0 API → React 代碼

缺點：跳過設計師審查層，不適合需要設計規格對齊的產品

---

**場景 D：維持 Figma 為設計工具，強化 AI 代碼生成能力**

推薦 **Figma + Builder.io Fusion（或 Locofy）**

理由：
- 若團隊已深度使用 Figma，遷移成本高
- Builder.io Fusion 可作為「Figma 設計稿→乾淨代碼」的 AI 轉換層
- 短期最低風險的漸進式路徑

---

### 4.3 對 Shikigami 專案的具體建議

考量 Shikigami 的現有架構（Design Token 規範、SDD 文件體系、AI 多 Agent 架構），建議：

**短期（v0.29.x）**：維持 Figma 作為設計基準，透過 Figma MCP 實現「設計→代碼」方向

**中期（v0.30+）**：評估 Penpot 自建作為替代路線
- Penpot MCP 已支援 AI 建立設計元件的操作
- 與現有 W3C DTCG Design Token 規範（ADR-014）天然對齊
- 自建版本可整合至 Shikigami CI/CD 工作流

**長期**：觀察 Subframe 的設計系統成熟度，若其 Design System 規範能與現有 Token 體系對齊，可作為「AI agent 直接操作設計」的主要平台

---

## 5. 附錄：調查資料來源

- [Penpot MCP Server 官方 GitHub](https://github.com/penpot/penpot-mcp)
- [Penpot Experimenting With MCP Servers — Smashing Magazine](https://www.smashingmagazine.com/2026/01/penpot-experimenting-mcp-servers-ai-powered-design-workflows/)
- [Figma MCP Server 官方文件](https://developers.figma.com/docs/figma-mcp-server/)
- [Figma: Design Systems And AI — MCP Servers Are The Unlock](https://www.figma.com/blog/design-systems-ai-mcp/)
- [Subframe MCP Server 文件](https://docs.subframe.com/guides/mcp-server)
- [Subframe: AI Design Tool With MCP — Banani 評測](https://www.banani.co/blog/subframe-ai-review)
- [v0 Platform API — Vercel Blog](https://vercel.com/blog/build-your-own-ai-app-builder-with-the-v0-platform-api)
- [Google Stitch — Google Developers Blog](https://developers.googleblog.com/stitch-a-new-way-to-design-uis/)
- [Builder.io Fusion 1.0 發布公告](https://www.prnewswire.com/news-releases/builderio-launches-fusion-1-0--the-first-ai-agent-for-product-design-and-code-302615215.html)
- [Integrating Design And Code With Native Design Tokens In Penpot — Smashing Magazine](https://www.smashingmagazine.com/2025/05/integrating-design-code-native-design-tokens-penpot/)
- [Framer MCP Server — Skywork AI 分析](https://skywork.ai/skypage/en/Mastering-Agentic-Design-A-Deep-Dive-into-the-Framer-MCP-Server/1971398927354032128)
- [Galileo AI → Google Stitch — Banani 評測](https://www.banani.co/blog/galileo-ai-features-and-alternatives)
- [Figma Alternatives AI Integration — Figma Make Alternatives](https://www.magicpatterns.com/blog/figma-make-alternatives)
- [Top Figma Alternatives 2026 — DesignRush](https://www.designrush.com/best-designs/websites/trends/figma-competitors)
