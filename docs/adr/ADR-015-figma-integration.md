# ADR-015：UIUX 管線架構轉型 — Figma 整合取代三層 SSD 管線

**狀態**：Proposed
**日期**：2026-03-06
**決策者**：Architect
**關聯 ADR**：ADR-014（UIUX Agent 架構決策）
**關聯 Issue**：#100（UIUX agent 功能需求）

---

## 背景

ADR-014 確立了三層 Agent 分工架構，並已完成 Phase 1（Sprint 52）的基礎建設。Phase 2（Sprint 54-56）原訂實作 UX Agent 與 UI Agent，其核心是一個自發明的中間格式：**SSD JSON（Skeleton Structure Document）**。

在準備進入 Phase 2 之前，對現行三層管線的設計進行全面審查，識別出以下結構性問題：

### 現行三層管線的問題

**問題一：自發明中間格式的維護成本**

SSD JSON 是 Shikigami 專案自行定義的語意骨架格式，不對應任何業界標準工具。它的存在僅為了在 UX Agent 與 UI Agent 之間傳遞設計意圖，但：

- 格式演進完全由本專案承擔，無社群維護支援
- UX Agent 需學習生產正確的 SSD JSON；UI Agent 需學習消費它；Vision Critic 需理解它來審查截圖
- 每次業務需求變動（如新增互動類型、元件類型），都需同步更新 Schema、兩個 Agent 的 SKILL.md、以及驗證工具設定

**問題二：跨 User Story 頁面佈局不連貫**

SSD JSON 格式以單一 User Story 為範圍，沒有跨頁面的 layout 約束機制。當多個 US 分別生成各自的前端代碼時，缺乏確保整體頁面體驗一致性的結構性手段：

- 導航欄可能在不同頁面有微妙差異
- 同類型元件的間距、字型可能在不同 US 產出中不一致
- SSD JSON 無法表達「頁面 A 的側欄與頁面 B 的側欄是同一個 Layout Pattern」

**問題三：設計師無法介入**

SSD JSON 是 AI 生成、AI 消費的格式，對人類設計師不透明：

- 設計師無法在 SSD JSON 階段進行有意義的視覺校正
- 設計師的介入點只能在最終前端代碼（過晚，修改成本高）或在自然語言 User Story（過早，表達精度低）
- 不存在「設計師看得懂、AI 也能操作」的共同工作空間

**問題四：元件無法跨 US 重用**

每個 US 的 UI Agent 獨立執行，各自從 Design Tokens 組裝元件，無法累積跨 Story 的元件實例庫：

- 相似的表單元件在不同 US 中重複生成，無重用機制
- 元件的設計決策（如「主要按鈕的最小寬度應為 120px」）無法從一個 US 傳遞到下一個 US
- Vision Critic 無法比較「此 US 的元件與前一個 US 的相同元件是否一致」

---

## 決策問題

在進入 ADR-014 Phase 2 實作之前，是否應以 Figma 整合取代 SSD JSON 中間格式，讓 AI 直接在 Figma 中設計 UI，並以 Figma 作為 AI 與設計師的共同協作工作空間？

---

## 決策驅動力

### 驅動力一：AI 多模態能力已成熟

Claude Sonnet 4.6 不僅能讀取圖片（Vision Critic 已依賴此能力），更能理解視覺設計的語意層次。AI 直接操作設計工具、閱讀設計稿的技術前提已具備。Figma MCP Server 的出現使 AI 可透過標準協議操作 Figma 文件，降低整合門檻。

### 驅動力二：Figma 是業界標準設計工具

Figma 具備以下 SSD JSON 無法提供的結構性優勢：

- **Auto Layout**：確保元件間距與排列的一致性，跨 Frame 可繼承規則
- **Component Library**：元件實例化與重用，跨 Story 設計決策持久化
- **Variables（原 Design Tokens）**：Figma Variables API 直接對應 Design Tokens 概念，消除本專案自維護 `design-tokens.json` 的需求
- **Figma Dev Mode**：設計稿直接輸出帶有 CSS 值的標注，前端代碼生成路徑清晰

### 驅動力三：減少自發明格式的維護成本

以 Figma 取代 SSD JSON，可消除以下維護負擔：

- `docs/schemas/skeleton-document-schema.json`（ADR-014 OQ-4 決策產出）
- `ajv` v6.x 驗證工具依賴
- UX Agent 的 SSD JSON 生成邏輯
- UI Agent 的 SSD JSON 消費邏輯
- Vision Critic 的 SSD JSON 對照審查邏輯

所有這些複雜度都可由 Figma 的標準化資料結構與 API 取代。

### 驅動力四：設計師與 AI 在同一工具協作

Figma 是設計師的原生工作環境。以 Figma 作為設計中間層，意味著：

- AI 畫出的 Frame 對設計師即時可見，設計師可直接在 Figma 中修正
- 設計師的修正對 AI 即時可見（下一次 AI 操作前可讀取最新設計稿）
- Human-in-the-loop 的介入點從「閱讀 SSD JSON」升級為「直接操作 Figma」，介入效率大幅提升

---

## 選項比較

| 評估維度 | 選項 A：維持現行三層管線 | 選項 B：Figma 整合（推薦） | 選項 C：混合模式 |
|---------|----------------------|--------------------------|----------------|
| **描述** | 維持 SSD JSON + UI Agent + Vision Critic，按 ADR-014 Phase 2-3 規劃推進 | AI 直接透過 Figma MCP/REST API 畫 UI，審查 Figma Frame，從 Figma 生成前端代碼 | 保留 UX Agent 生成 SSD JSON，但 UI Agent 改為讀取 SSD JSON 並寫入 Figma，從 Figma 出代碼 |
| **中間格式** | SSD JSON（自發明，需自行維護 Schema） | Figma 文件（業界標準，由 Figma 維護） | SSD JSON + Figma（兩種格式並存） |
| **設計師介入點** | 最終代碼（過晚）或自然語言（過早） | Figma Frame（最佳介入點，設計師原生環境） | Figma Frame（介入點改善，但 SSD JSON 仍存在） |
| **跨 US 一致性** | 低（每個 SSD 獨立，無共享 Layout Pattern） | 高（Figma Component Library 跨 Frame 強制一致） | 中（Figma 層面可一致，但 SSD 層面仍各自獨立） |
| **元件重用** | 無（每個 UI Agent 執行獨立） | 高（Figma Component Instance 機制） | 中（Figma 層面支援，SSD 層面無） |
| **Design Tokens 管理** | 本專案自維護 `design-tokens.json` | Figma Variables API（Figma 維護，AI 同步） | 兩套並存（同步負擔高） |
| **維護成本** | 高（Schema、兩個 SKILL.md、驗證工具） | 中（Figma API 整合、codegen 工具選型） | 最高（SSD JSON + Figma 雙層維護） |
| **技術不確定性** | 低（技術路徑已在 ADR-014 確認） | 高（Figma MCP 能力邊界待驗證） | 高（繼承 Figma 整合的不確定性，同時保留 SSD 複雜度） |
| **Phase 2 已投入成本** | 低（US-105/US-106 尚未實作） | 低（SSD JSON 相關工作尚在規劃階段） | 低（同上） |
| **Vision Critic 角色** | 截圖 vs SSD 骨架對照審查 | Figma Frame vs 截圖比對（簡化） | 截圖 vs SSD 骨架對照（維持複雜度） |

**選項 C 劣勢分析**：混合模式看似兼顧兩者優點，實則放大了兩者的缺點。SSD JSON 仍需維護；Figma 整合的技術不確定性也同樣存在。若 Figma MCP 能力足以直接讀取 User Story 並設計 Frame，則 UX Agent + SSD JSON 的存在價值降為零，混合模式只是在浪費過渡成本。

---

## 決策

**選項 B — Figma 整合**

以 Figma 作為 UIUX 管線的核心設計工作空間，取代 SSD JSON 中間格式。

此決策在 Open Questions（OQ-1 至 OQ-4）技術前置調查完成並確認可行後正式生效。若調查結果顯示 Figma MCP 能力不足，則降級回選項 A 並繼續 ADR-014 Phase 2 規劃。

---

## 新流程定義

```
User Story
    │
    ▼
AI 讀取 User Story（分析功能需求、互動說明、頁面目標）
    │
    ▼
AI 透過 Figma MCP / REST API 畫 UI
    │ 建立 Frame、設定 Auto Layout
    │ 引用 Component Library 中的現有元件
    │ 套用 Figma Variables（對應 Design Tokens）
    │ 標注互動說明（Prototype / Annotation Layer）
    ▼
審查機制（二擇一，依 Story 風險等級決定）
    ├─ 人工 Review：設計師直接在 Figma 中審查並修正
    └─ AI Vision Review：Vision Critic 讀取 Figma Frame 截圖並評分
    │
    ▼（審查通過）
從 Figma 生成前端代碼
    ├─ 路徑 A：Figma Dev Mode API（官方標注轉代碼）
    ├─ 路徑 B：第三方工具（如 Builder.io、Anima）
    └─ 路徑 C：自訂 codegen（讀取 Figma REST API 節點結構，生成 React + Tailwind）
```

### 各步驟職責定義

**步驟 1：AI 讀取 User Story**

- 輸入：User Story（GitHub Issue 或 SDD 章節）
- 職責：分析功能目標、使用者角色、AC 清單、互動流程
- 無需生成 SSD JSON；直接進入 Figma 設計步驟

**步驟 2：AI 透過 Figma MCP 畫 UI**

- AI 呼叫 Figma MCP Server 的 tool（如 `create_frame`、`add_component`、`set_auto_layout`、`apply_variable`）
- 優先引用 Component Library 中已存在的元件（確保跨 US 一致性）
- 若需要新元件，在 Component Library 中建立，而非在 Frame 中一次性定義
- 套用 Figma Variables 對應 Design Token（顏色、間距、字型）

**步驟 3：審查機制**

- **高風險 UI**（付款流程、資料刪除、權限設定）：強制人工 Review
- **標準 UI**：AI Vision Review（Vision Critic 讀取 Frame 截圖，評分 ≥ 80 視為通過）
- Vision Critic 的審查基準從「截圖 vs SSD 骨架」簡化為「Frame 截圖 vs Design System 規範」

**步驟 4：從 Figma 生成前端代碼**

- 優先路徑待 OQ-3 調查後確認
- 代碼須符合 ADR-014 Phase 1 確立的元件庫白名單（Tailwind CSS + Shadcn UI）
- 生成後由 Developer Subagent 執行功能性 AC 驗證

---

## 對現有工作的影響

### ADR-014 相關規格

| ADR-014 工件 | 影響 | 說明 |
|------------|------|------|
| Phase 1 交付物（Design Tokens、元件庫白名單、AC 模板） | **保留** | Design Tokens 概念遷移至 Figma Variables；白名單原則不變；AC 模板繼續適用 |
| Phase 2 規劃（UX Agent SKILL.md、UI Agent SKILL.md） | **廢棄** | 不再實作 UX Agent 的 SSD JSON 生成邏輯與 UI Agent 的 SSD JSON 消費邏輯 |
| Phase 3 規劃（Vision Critic Agent） | **簡化** | Vision Critic 保留，但審查基準從「SSD 對照」改為「Design System 規範對照」 |
| Phase 4 規劃（品味注入） | **保留** | 不受本 ADR 影響，屬長期演進方向 |
| OQ-4 決策（JSON Schema Draft-07，ajv v6.x） | **廢棄** | `docs/schemas/skeleton-document-schema.json` 不再需要建立 |
| OQ-3 決策（Vision Critic 三維度評分） | **部分保留** | 評分框架保留，審查輸入從「截圖 + SSD」改為「截圖 + Design System 規範」 |

### Sprint 54 SSD 相關 Stories

| Story | 原規劃 | 新處置 |
|-------|--------|--------|
| US-105（UX Agent SKILL.md 實作） | Phase 2 核心 | 需重新評估，原 SSD JSON 生成邏輯不再適用 |
| US-106（UI Agent SKILL.md 實作） | Phase 2 核心 | 需重新評估，原 SSD JSON 消費邏輯不再適用 |
| US-112（UX Agent Schema 驗證） | Phase 2 延伸 | 廢棄，不再需要 Schema 驗證 SSD JSON |
| US-117（OQ-4 骨架文件 Schema 標準化） | Phase 2 調查 | 廢棄，Figma 取代骨架文件 |
| US-118（OQ-5 Context Window 管理） | Phase 2 調查 | 待重新評估，新管線的 Context 使用模式不同 |

### Design Tokens 管理

- **現行**：本專案自維護 `docs/design/design-tokens.json`（ADR-014 Phase 1 交付）
- **新方案**：Design Tokens 遷移至 Figma Variables API；`design-tokens.json` 成為 Figma Variables 的導出快照，而非主要來源
- **遷移路徑**：待 OQ-1 確認 Figma Variables API 能力後，制定具體遷移計畫

### Vision Critic 角色簡化

- **現行設計**：截圖 + SSD JSON 骨架 → 三維度加權評分（色彩一致性 40%、元件位置 35%、間距合規 25%）
- **新設計**：Figma Frame 截圖 + Design System 規範 → 相同三維度評分框架，但審查基準改為 Figma Component Library 規範，不再需要 SSD JSON 作為比對錨點
- **評分框架保留**：ADR-014 OQ-3 的量化閾值（總分 ≥ 80、三項 Hard Gate）繼續適用

---

## 技術前置調查（Open Questions）

本 ADR 的決策生效依賴以下四個 Open Questions 的調查結果。若 OQ-1 或 OQ-2 調查結果顯示技術阻塞，本 ADR 降級為 Rejected，回歸 ADR-014 Phase 2 執行路徑。

| # | 問題 | 優先級 | 狀態 | 阻塞性 |
|---|------|--------|------|--------|
| OQ-1 | Figma MCP Server 能力邊界 | 高 | **已調查（2026-03-06）** | 是 |
| OQ-2 | Figma REST API 限制 | 高 | **已調查（2026-03-06）** | 是 |
| OQ-3 | 從 Figma 到代碼的最佳路徑 | 中 | **已調查（2026-03-06）** | 否（可有多選項） |
| OQ-4 | Figma 授權與成本 | 中 | **已調查（2026-03-06）** | 視成本規模而定 |

### OQ-1：Figma MCP Server 能力邊界

**問題**：現有 Figma MCP Server 實作（官方或第三方）能否支援以下操作？

- 建立 Frame 並設定尺寸、命名
- 在 Frame 中排列 Auto Layout（方向、間距、對齊）
- 引用 Component Library 中的既有元件，建立 Component Instance
- 套用 Figma Variables（對應 Design Tokens 的顏色、間距、字型）
- 在 Component Library 中建立新元件

**調查方向**：

- 官方 Figma Plugin API 的 MCP 封裝現狀
- 社群實作（如 `figma-mcp`、`figma-developer-mcp`）的功能覆蓋率
- Figma Plugin API 與 Figma REST API 的操作邊界差異

**判定標準**：至少支援「建立 Frame、Auto Layout、套用 Variables、引用 Component Instance」四項核心操作，才能判定 OQ-1 為可行。

### OQ-2：Figma REST API 限制

**問題**：Figma REST API 的操作限制是否對本管線的自動化生成構成阻礙？

**調查日期**：2026-03-06
**調查結論**：REST API 寫入能力存在根本性限制，構成架構決策的核心約束。

---

#### A. REST API 寫入能力：根本性限制

**Figma REST API 為讀取導向設計，不支援節點層級的寫入操作。**

官方 API 比較文件（`developers.figma.com/compare-apis/`）明確說明：

- **REST API 寫入範疇**：僅限於 Comments（留言）、Variables（Figma Enterprise 限定）、Dev Resources、Webhooks
- **REST API 無法執行**：建立 Frame、修改節點屬性、設定 Auto Layout、建立/引用 Component Instance
- **`file_content:write` scope**：雖存在於 OAuth 規格，但為內部保留，不對外開放使用

這意味著「AI 透過 REST API 直接畫 Figma UI」在技術上不可行。任何對 Figma 文件的設計內容修改，必須透過 Plugin API 執行（需在 Figma 應用程式內運行）。

#### B. Rate Limit 矩陣

Rate Limit 於 2025-11-17 更新，採用 Leaky Bucket 演算法，依「方案層級 × 座位類型 × API 端點層級」三維度決定限額。

**Tier 定義**：
- **Tier 1**：高成本端點（讀取整個 Figma 文件 `/v1/files/{key}`）
- **Tier 2**：中成本端點（讀取特定節點、元件、樣式）
- **Tier 3**：低成本端點（讀取評論、元資料、版本列表）

| 端點層級 | 座位類型 | Starter | Professional | Organization | Enterprise |
|---------|---------|---------|--------------|--------------|------------|
| **Tier 1** | View / Collab | 6 次/月 | 6 次/月 | 6 次/月 | 6 次/月 |
| **Tier 1** | Dev / Full | 10 次/分 | 15 次/分 | 20 次/分 | 無限制 |
| **Tier 2** | View / Collab | 5 次/分 | 5 次/分 | 5 次/分 | 5 次/分 |
| **Tier 2** | Dev / Full | 25 次/分 | 50 次/分 | 100 次/分 | 無限制 |
| **Tier 3** | View / Collab | 10 次/分 | 10 次/分 | 10 次/分 | 10 次/分 |
| **Tier 3** | Dev / Full | 50 次/分 | 100 次/分 | 150 次/分 | 無限制 |

**對本管線的影響評估**：管線的 REST API 使用場景主要為讀取（Vision Critic 讀取 Frame 截圖 export、AI 讀取 Component Library 節點結構）。單一 US 的審查預估需要 3-8 次 Tier 1/Tier 2 讀取操作。Professional 方案的 15-50 次/分配額足以支撐。

**已知問題**：Tier 1 端點的圖片 export（`/v1/images`）在高流量時有 429 報告，即使配額充足仍可能觸發 CloudFront 端的流量管制，實際可用配額可能低於文件值。

#### C. 檔案大小與節點粒度

| 限制類型 | 規格 | 說明 |
|---------|------|------|
| 回應超時 | 55 秒 | `/v1/files/{key}` 與圖片端點的最大等待時間 |
| 建議回應大小 | < 500 KB | 超過此大小需加 `depth=2-3` 參數限制節點深度 |
| 實際最大回應 | ~280-320 MB | 超大型文件可能觸發 CloudFlare 錯誤 |
| 節點批次請求 | 支援（計 1 次） | 單一 `/v1/files/{key}/nodes?ids=...` 可包含多個 node ID，計為 1 次 API 呼叫 |

**對本管線建議**：讀取 Frame 時使用 `depth=2` 配合指定 node ID，避免拉取整個文件。

#### D. Plugin API vs REST API 能力對比

| 能力 | REST API | Plugin API |
|------|---------|-----------|
| 讀取文件節點 | 支援（多文件） | 支援（僅當前開啟文件） |
| 建立 Frame | **不支援** | 支援 |
| 修改節點屬性（顏色、大小、位置） | **不支援** | 支援 |
| 設定 Auto Layout | **不支援** | 支援 |
| 建立 Component Instance | **不支援** | 支援 |
| 建立新 Component | **不支援** | 支援 |
| 套用 Variables | **Enterprise 限定** | 支援（所有方案） |
| 讀取 Variables | **Enterprise 限定** | 支援（所有方案） |
| 讀取 Styles / Component 元資料 | 支援 | 支援 |
| 新增 Comment | 支援 | 支援 |
| 無需 Figma 開啟即可執行 | 支援 | **不支援** |
| 多文件批次處理 | 支援 | **不支援** |

**架構含義**：AI 若要對 Figma 文件進行設計操作（建立 Frame、排版、套用元件），必須透過 Plugin API，而非 REST API。Figma MCP Server 的官方實作即基於 Plugin API（透過 Figma 桌面應用程式的 local server 轉發）。

#### E. Variables API 授權限制

Figma Variables REST API 僅限 Enterprise 方案，且需要具備 `variables:read` / `variables:write` scope 的 Personal Access Token。此為硬性限制，Professional 及 Organization 方案無法透過 REST API 存取 Variables。

**替代方案**：Plugin API 可在所有方案讀寫 Variables，不受方案層級限制。透過 Figma MCP Server（Plugin API 封裝）操作 Variables 不受此限制。

#### F. OQ-2 判定結論

**REST API 寫入限制對本管線構成技術約束，但不構成整體方案的否決因素。**

1. **寫入路徑確認**：本管線的所有設計寫入操作必須經由 Figma MCP Server（Plugin API），不得依賴 REST API 寫入端點
2. **讀取配額充足**：REST API 在 Professional 方案（Dev/Full seat）的讀取配額（Tier 2：50 次/分）可支撐 Vision Critic 審查需求
3. **Variables 限制可繞過**：透過 MCP Server（Plugin API 路徑）操作 Variables 不受 Enterprise 限制

**OQ-2 判定：條件性可行。** 架構設計須明確區分「讀取路徑（REST API）」與「寫入路徑（Plugin API via MCP Server）」。此結論強化了 OQ-1（Figma MCP Server 能力邊界）是本架構決策的核心阻塞性依賴。

**判定標準對照**：原判定標準為「Rate limit 應支援每分鐘至少 10 次節點寫入操作」。修正後認知為：REST API 不支援節點寫入，但寫入操作透過 MCP Server（Plugin API）執行，不受 REST API Rate Limit 限制；寫入路徑的實際限制由 Figma Plugin 執行環境決定（非 API 呼叫頻率問題）。

### OQ-3：從 Figma 到代碼的最佳路徑

**問題**：在 Figma 設計完成後，哪種代碼生成路徑能以最低維護成本輸出符合本專案技術棧（React + Tailwind CSS + Shadcn UI）的前端代碼？

**調查日期**：2026-03-06
**調查結論**：AI + Figma MCP Server 輔助的 AI 直接代碼生成（Path D）為本專案最佳路徑；Code Connect 作為輔助加值機制。

---

#### A. 候選路徑詳細評估

**路徑一：Figma Dev Mode + Codegen Plugin（官方路徑）**

Dev Mode 是 Figma 官方提供的開發者協作環境，支援直接輸出 CSS 值（含變數名稱）、提供元件 Spec 標注、支援 Code Connect 連結。

Codegen Plugin 機制允許開發者建立自訂代碼生成 Plugin，在 Dev Mode 中選取節點即可觸發代碼輸出。Figma 官方支援的語言包含 CSS、Swift、XML，但原生不輸出 Tailwind class。

| 評估維度 | 說明 |
|---------|------|
| Tailwind 支援 | 原生不支援，需自行建立 Codegen Plugin 做 CSS → Tailwind 轉換 |
| Shadcn UI 感知 | 無原生支援，需透過 Code Connect 手動定義映射關係 |
| 自動化程度 | 低（需人工在 Dev Mode 操作，無法無人值守批次生成） |
| 維護成本 | 中（需維護自訂 Codegen Plugin 邏輯） |
| 方案要求 | Dev Mode 需 Dev seat 或 Full seat；Codegen Plugin 本身免費 |

**路徑二：第三方工具（Builder.io Visual Copilot / Anima）**

Builder.io Visual Copilot 是目前最成熟的 Figma-to-React + Tailwind 商業工具，以 AI 模型分析 Figma 節點樹並輸出結構化 React 元件。支援多框架（React、Vue、Svelte）和 Tailwind CSS 輸出。

| 評估維度 | 說明 |
|---------|------|
| Tailwind 支援 | 原生支援（一鍵輸出 React + Tailwind） |
| Shadcn UI 支援 | 無直接映射，輸出為 Tailwind utility class，需人工替換為 Shadcn 元件 |
| 代碼品質 | Fast mode 約 80% 可用；Quality mode（付費）可達更高品質，但動態互動仍需人工修正 |
| 自動化程度 | 中（Plugin 操作仍需人工觸發；無 CLI/API 無人值守模式） |
| 維護成本 | 低（維護由 Builder.io 負責） |
| 費用 | 付費方案；Quality mode 需額外費用；具體定價需查詢 |

Anima 能力相近，同支援 React + Tailwind，但 Shadcn UI 感知同樣缺失。

**路徑三：自訂 Codegen（REST API 節點樹 → React + Tailwind）**

透過 Figma REST API 讀取節點結構（JSON），自行解析 Auto Layout、Typography、Color 等屬性，生成 React + Tailwind 代碼。開源實作參考：`bernaferrari/FigmaToCode`（GitHub）。

| 評估維度 | 說明 |
|---------|------|
| Tailwind 支援 | 完全可控，可自訂 Tailwind class 映射規則 |
| Shadcn UI 支援 | 可自訂映射邏輯，理論上可達最高契合度 |
| 代碼品質 | 高度依賴映射邏輯品質；初期需大量調試 |
| 自動化程度 | 高（可完全無人值守，REST API 讀取 + codegen 腳本） |
| 維護成本 | 高（節點結構解析邏輯、映射表、Tailwind 版本相容性均需自行維護） |
| 費用 | 無第三方授權費用，但工程投入成本高 |

**路徑四：AI 直接代碼生成（Figma MCP Server 輔助）**

AI（Claude）透過 Figma MCP Server 取得 Frame 的完整 context（節點結構 JSON + Design Token 映射 + Code Connect 元件定義），直接生成符合本專案技術棧的 React + Tailwind + Shadcn UI 代碼。這是 Figma 官方 2025-2026 推廣的設計到代碼新正規。

| 評估維度 | 說明 |
|---------|------|
| Tailwind 支援 | AI 直接理解設計意圖並輸出 Tailwind class，可指定偏好的 class 命名模式 |
| Shadcn UI 支援 | AI 可直接使用 Shadcn 元件，結合 Code Connect 映射，達成最高的語意準確度 |
| 代碼品質 | 依賴 AI 模型能力，現實測試顯示對靜態版型準確度高；複雜互動仍需少量修正 |
| 自動化程度 | 高（可整合至 CI/CD 流程；AI Agent 呼叫 MCP tools 無人值守）|
| 維護成本 | 低（無自訂解析邏輯；隨 AI 模型升級自動改善） |
| 費用 | Figma MCP Server 免費（所有方案）；AI API 使用費用另計 |

**Shadcn Studio 驗證**：已有 `shadcnstudio.com` 實際示範透過 Figma MCP Server + AI 生成 Shadcn UI 元件的端對端流程，確認技術路徑可行。

#### B. Code Connect 的角色定位

Code Connect 是 Figma 的元件映射機制，可將 Figma Component 節點與實際代碼庫中的元件定義連結。透過 CLI 發布連結後，MCP Server 在提供 context 時會自動附帶 Code Connect 定義的代碼片段，讓 AI 生成的代碼直接引用正確的 Shadcn 元件語法。

**限制**：Code Connect 完整 UI 功能（Connect UI）需 Organization 或 Enterprise 方案。CLI 方式可在 Professional 方案使用。

| Code Connect 功能 | Professional | Organization | Enterprise |
|-----------------|-------------|--------------|------------|
| Code Connect CLI（本地發布） | 支援 | 支援 | 支援 |
| Code Connect UI（Figma 介面操作） | 不支援 | 支援 | 支援 |
| 一對多元件映射 | 支援（CLI） | 支援 | 支援 |

#### C. 代碼生成路徑比較矩陣

| 評估維度 | 路徑一：Dev Mode Codegen | 路徑二：Builder.io | 路徑三：自訂 Codegen | 路徑四：AI + MCP（推薦） |
|---------|------------------------|------------------|-------------------|-----------------------|
| Tailwind 原生支援 | 需自訂 Plugin | 支援 | 完全可控 | AI 直接輸出 |
| Shadcn UI 感知 | 需 Code Connect 手動定義 | 不支援（需人工替換） | 可自訂（工程成本高） | 結合 Code Connect 支援 |
| 自動化程度 | 低（需人工觸發） | 中（Plugin 觸發） | 高 | 高（Agent 無人值守） |
| 維護成本 | 中 | 低 | 高 | 低 |
| 初始設定成本 | 低 | 低 | 高 | 中（需建立 Code Connect 映射） |
| 代碼品質上限 | 中（CSS 值轉換精度高，語意低） | 中高（AI 優化，但非針對 Shadcn） | 高（完全可控） | 高（語意最準確） |
| 與 Vision Critic 整合 | 無直接整合 | 無直接整合 | 可整合 | 天然整合（同一 AI 上下文） |
| 方案要求 | Dev seat | 第三方付費 | 無（REST API） | MCP Server 免費 |

#### D. OQ-3 判定結論與建議

**推薦路徑：路徑四（AI + Figma MCP Server），搭配 Code Connect CLI 作為元件映射機制。**

理由：
1. **最高 Shadcn UI 契合度**：AI 可直接理解 Code Connect 映射，輸出直接引用 `<Button variant="default">` 等 Shadcn 語法，而非通用 Tailwind utility class 的堆疊
2. **最低維護成本**：無自訂解析邏輯；AI 模型升級後代碼品質自動改善；不依賴第三方商業工具授權
3. **與管線天然整合**：AI Agent 在同一次執行中可完成「讀取 User Story → Figma MCP 畫 UI → MCP 讀取 Frame context → 生成代碼」四步驟，無需外部工具切換
4. **Vision Critic 審查一致性**：由同一 AI Agent 生成代碼後自我審查，或由 Vision Critic 讀取截圖審查，上下文完整

**前置條件**：需在 Figma 文件中建立 Code Connect 映射，將 Shadcn UI 元件（Button、Input、Card 等）與 Figma Component Library 中的元件節點連結。此為一次性工程投入（預估 2-3 Sprint）。

**降級路徑**：若 AI + MCP 的代碼品質在實際驗證中不達 Vision Critic ≥ 80 分，以路徑三（自訂 Codegen）作為備選，利用 REST API 讀取節點樹並產出可預測的結構化代碼。

### OQ-4：Figma 授權與成本

**問題**：Figma API 的使用是否存在授權門檻或成本限制，影響本方案的可行性？

**調查日期**：2026-03-06
**調查結論**：Professional 方案（Dev seat）可覆蓋本管線 80% 的技術需求；Variables REST API 的 Enterprise 限制可透過 Plugin API（MCP Server）完全繞過。

---

#### A. 方案功能矩陣（2026 年 3 月現況）

Figma 於 2025 年 3 月重新設計定價結構，引入三種座位類型（Full / Dev / Collab）與四個方案層級（Starter / Professional / Organization / Enterprise）。

**方案費用（年繳）**：

| 方案 | Full seat | Dev seat | Collab seat | View（免費） |
|------|----------|----------|------------|-------------|
| Starter | 免費 | 免費 | 免費 | 免費 |
| Professional | $20/月 | $15/月 | $5/月 | 免費 |
| Organization | $55/月 | $25/月 | $5/月 | 免費 |
| Enterprise | $90/月 | $35/月 | $5/月 | 免費 |

注意：Organization 及 Enterprise 方案僅支援年繳，不提供月繳選項。

**API 功能與方案對照**：

| 功能 | Starter | Professional | Organization | Enterprise |
|------|---------|--------------|--------------|------------|
| REST API 基本讀取 | 支援（Tier 1 僅 6 次/月） | 支援（Dev/Full seat 15-50 次/分） | 支援（20-100 次/分） | 無限制 |
| Figma MCP Server | 支援（所有方案免費） | 支援 | 支援 | 支援 |
| Code Connect CLI | 支援 | 支援 | 支援 | 支援 |
| Code Connect UI | **不支援** | **不支援** | 支援 | 支援 |
| Variables REST API | **不支援** | **不支援** | **不支援** | **僅限 Enterprise** |
| Variables（Plugin API / MCP） | 支援 | 支援 | 支援 | 支援 |
| Dev Mode（CSS Spec 標注） | 支援（Dev seat） | 支援 | 支援 | 支援 |
| 無限制檔案數 | **不支援（3 個草稿）** | 支援 | 支援 | 支援 |

#### B. API Token 類型

**Personal Access Token（PAT）**：

- 所有方案均可建立，適用於個人自動化腳本與本地開發
- Scope 可精細設定（`file_content:read`、`variables:read` 等）
- 最大有效期 90 天（2025 更新後強制）；需定期輪換
- Variables scope（`variables:read` / `variables:write`）僅在 Enterprise 方案的 token 上可用

**OAuth 2.0**：

- 適用於需要代表多位使用者的應用程式
- 所有方案均可使用，但公開 OAuth App 需完成 App 發布流程（2025-11-17 起生效）
- 本管線為 AI Agent 內部自動化，PAT 即已足夠，無需 OAuth

**MCP Server 認證**：

- Figma 官方遠端 MCP Server 僅支援 OAuth（目前限 Claude Code 和 OpenAI Codex）
- Figma 桌面應用程式本地 MCP Server 透過桌面 App 的已登入帳號授權，無需額外 token

#### C. 成本分析（本管線場景）

**最小可行方案（Professional + Dev seat）**：

本管線的 AI 操作者需要：
- REST API 讀取能力（Tier 2：50 次/分）
- Figma MCP Server 存取（免費）
- Code Connect CLI 支援
- Dev Mode 查看設計稿

→ 1 x Dev seat（Professional）= **$15/月**

**設計師協作（選配）**：若需要人工設計師在 Figma 中直接協作修改，需額外 Full seat（Professional $20/月）。

**Code Connect UI（選配）**：若希望在 Figma 介面直接操作元件映射（而非 CLI），需升級至 Organization 方案（$55/月 Full seat）。OQ-3 推薦的路徑不強制需要此功能。

**Variables REST API（暫不需要）**：OQ-2 已確認透過 MCP Server（Plugin API）可在 Professional 方案操作 Variables，不需為 Variables REST API 升級至 Enterprise。

#### D. OQ-4 判定結論

**最低可行成本：Professional 方案 + 1 Dev seat = $15/月（年繳）。**

此配置可支援：
- REST API 讀取（Vision Critic 審查、Component Library 讀取）
- Figma MCP Server（AI 設計操作的寫入路徑）
- Code Connect CLI（Shadcn 元件映射）
- Variables 操作（透過 MCP Server，非 REST API）

**Enterprise 非必要**：Variables REST API 為 Enterprise 限定，但本管線的 Variables 操作路徑為 Plugin API（MCP Server），不需要 REST API 寫入 Variables，因此 Enterprise 升級對本管線無必要性。

**OQ-4 判定：授權成本可接受。** 月費 $15（AI 操作帳號）+ 可選 $20（設計師協作帳號），相對於本管線的工程投入，成本無阻塞性。

**風險提示**：Personal Access Token 90 天到期機制需建立自動輪換流程，避免 CI/CD 中 API 呼叫因 Token 過期而失敗。

---

## 風險與緩解

| 風險 | 可能性 | 影響 | 緩解策略 | OQ 更新 |
|------|--------|------|---------|---------|
| Figma MCP Server 能力不足（OQ-1 阻塞） | 中 | 高（此 ADR 降級） | 降級回 ADR-014 三層管線（選項 A），Phase 2 繼續推進 SSD JSON 路徑 | 待 OQ-1 調查完成 |
| Figma REST API 寫入限制阻塞設計操作（OQ-2） | **已確認**（非風險，為已知約束） | 高 → **已緩解** | OQ-2 調查確認：寫入操作路徑已明確為 Plugin API via MCP Server；REST API 僅用於讀取 | OQ-2 已解決 |
| REST API Rate Limit 阻塞讀取操作（OQ-2） | 低（Professional Dev seat 50次/分） | 低（讀取配額充足） | 讀取時使用 `depth=2` + 指定 node ID 節省配額；圖片 export 加入指數退避重試 | OQ-2 已解決 |
| AI 生成的 Figma Frame 品質不達標 | 中 | 中 | 強化 AI Prompt 設計（引用 Component Library、明確 Auto Layout 規則）；引入人工設計師介入修正環節 | 無關聯 |
| AI 代碼生成品質不達 Vision Critic ≥ 80 分（OQ-3） | 低至中 | 中 | 建立 Code Connect 映射（Shadcn 元件）提升語意準確度；降級路徑為自訂 Codegen（路徑三） | OQ-3 已解決 |
| Code Connect 映射建立工程成本超預期 | 低至中 | 低 | 僅映射核心元件（Button、Input、Card、Dialog 等約 15 個）；長尾元件可延遲映射 | OQ-3 已解決 |
| Figma Variables API 需 Enterprise（OQ-4） | **已確認**（非風險，為已知約束） | 低 → **已緩解** | Variables 操作透過 MCP Server（Plugin API）執行，不需 Enterprise；REST API Variables 路徑放棄 | OQ-4 已解決 |
| PAT Token 90 天到期導致 CI/CD 失敗 | 中 | 中 | 建立 Token 輪換提醒機制（60 天警告）；或使用 OAuth App token（無強制過期） | OQ-4 已解決 |
| Figma 服務中斷影響設計流程 | 低 | 中 | 本地快取最近 Sprint 的 Figma 設計稿（export 為 SVG / PNG）；定義服務中斷時的人工替代流程 | 無關聯 |
| 與 ADR-014 Phase 1 成果的相容性問題 | 低 | 低 | ADR-014 Phase 1 交付物（Design Tokens、元件庫白名單、AC 模板）均可在新管線中繼續適用 | 無關聯 |

---

## 演進路徑

本 ADR 採用漸進式驗證策略，避免在技術不確定性消除前大規模投入實作：

```
當前狀態（ADR-014 Phase 1 完成）
    │
    ▼
OQ-1/OQ-2 技術前置調查（Sprint 54）
    ├─ 可行 → ADR-015 狀態升為 Accepted，進入 Figma 整合實作
    └─ 不可行 → ADR-015 狀態更新為 Rejected，ADR-014 Phase 2 繼續執行
    │
    ▼（可行時）
Figma 整合 Phase 1：AI 畫 UI（Sprint 55-56）
    │ 建立 Figma 文件結構、Component Library 基礎
    │ 驗證 AI 透過 Figma MCP 生成 Frame 的品質
    ▼
Figma 整合 Phase 2：審查機制（Sprint 57-58）
    │ Vision Critic 整合 Figma Frame 截圖審查
    │ 人工 Review 流程定義
    ▼
Figma 整合 Phase 3：代碼生成（Sprint 59-60）
    │ OQ-3 選定路徑實作
    │ 端對端驗證（US → Figma → 代碼 → Vision Critic PASS）
    ▼
長期演進（Sprint 61+）
    │ Design Tokens 完全遷移至 Figma Variables
    │ Component Library 累積與維護機制
    └─ 品味注入（Reference Design 庫）
```

---

## 影響

### 對 ADR-014 的影響

本 ADR Proposed 狀態不影響 ADR-014 的 Accepted 狀態。ADR-014 Phase 1 交付物保持有效。ADR-014 Phase 2-3 的實作規劃在本 ADR 確認為 Accepted 後進入凍結狀態，不再推進 SSD JSON 相關 Story。

### 對現有文件的影響

| 文件 | 影響 | 處置時機 |
|------|------|---------|
| `docs/design/design-tokens.json` | 定位調整為 Figma Variables 的導出快照 | ADR-015 Accepted 後逐步遷移 |
| `docs/schemas/skeleton-document-schema.json`（未建立） | 不再需要建立 | 直接取消，無需清理 |
| `docs/templates/sdd-frontend-template.md` | Frontend Constraints 區段繼續適用，Figma 設計稿連結欄位待新增 | ADR-015 Accepted 後更新 |
| `skills/issue-management/SKILL.md` §12 | 前端 Story AC 注入邏輯繼續適用 | 不需調整 |

---

## 參考

- ADR-014：UIUX Agent 架構決策（三層管線原始設計）
- ADR-006：Issue 內容提示注入防護（Vision Critic 外部資料處理規則）
- ADR-013：shikigami:diagram MCP 整合架構決策（MCP 整合參考模式）
- GitHub Issue #100：UIUX agent 功能需求（原始需求與四階段藍圖）

### OQ-2/OQ-3/OQ-4 調查來源（2026-03-06）

- [Figma REST API 文件](https://www.figma.com/developers/api)
- [Figma Plugin API 文件](https://www.figma.com/plugin-docs/)
- [Figma Compare APIs — REST vs Plugin vs Widget](https://developers.figma.com/compare-apis/)
- [Figma REST API Rate Limits（2025-11-17 更新）](https://developers.figma.com/docs/rest-api/rate-limits/)
- [Figma REST API Scopes](https://developers.figma.com/docs/rest-api/scopes/)
- [Figma Variables API（Enterprise 限定）](https://www.figma.com/developers/api#variables)
- [Figma Variables API 方案限制 — 社群討論](https://forum.figma.com/suggest-a-feature-11/why-s-the-variables-api-only-available-on-enterprise-plans-36426)
- [Figma MCP Server 官方介紹](https://www.figma.com/blog/introducing-figma-mcp-server/)
- [Figma MCP Server 方案與存取權限](https://developers.figma.com/docs/figma-mcp-server/plans-access-and-permissions/)
- [Figma Dev Mode 指南（2025）](https://help.figma.com/hc/en-us/articles/15023124644247-Guide-to-Dev-Mode)
- [Figma Code Connect 介紹](https://developers.figma.com/docs/code-connect/)
- [Figma Codegen Plugins](https://developers.figma.com/docs/plugins/codegen-plugins/)
- [Builder.io Visual Copilot — Figma to React + Tailwind](https://www.builder.io/figma-to-code)
- [Shadcn Studio — Figma to Code via MCP Server](https://shadcnstudio.com/docs/getting-started/figma-to-code-mcp-server)
- [Figma MCP Server 2026 實際測試](https://research.aimultiple.com/figma-to-code/)
- [Figma 定價方案（2026 現況）](https://www.figma.com/pricing/)
- [Manage Personal Access Tokens](https://help.figma.com/hc/en-us/articles/8085703771159-Manage-personal-access-tokens)
- [Claude API — Vision capabilities](https://docs.anthropic.com/en/docs/build-with-claude/vision)
