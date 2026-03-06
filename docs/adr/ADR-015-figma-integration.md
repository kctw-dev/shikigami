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
| OQ-1 | Figma MCP Server 能力邊界 | 高 | 待調查 | 是 |
| OQ-2 | Figma REST API 限制 | 高 | 待調查 | 是 |
| OQ-3 | 從 Figma 到代碼的最佳路徑 | 中 | 待調查 | 否（可有多選項） |
| OQ-4 | Figma 授權與成本 | 中 | 待調查 | 視成本規模而定 |

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

- Rate limit：自動化生成多個 US 的 Frame 時，是否會觸發 API 限制？
- 檔案大小：單一 Figma 文件的 Frame 數量上限為何？多個 Sprint 的 US 累積後是否超限？
- 操作粒度：REST API 的節點操作能否達到 MCP Server 工具所需的精細度？
- Write API 限制：Figma REST API 的寫入操作（建立/修改節點）與讀取操作的限制是否對稱？

**調查方向**：

- Figma REST API 官方文件的 Rate Limit 規格（requests per minute、per day）
- 社群報告的 API 操作上限與已知限制
- Figma Plugin API（在 Figma 應用程式內執行）與 REST API 的能力差異

**判定標準**：Rate limit 應支援每分鐘至少 10 次節點寫入操作（單一 US 的 UI 生成估計需 5-15 次 API 呼叫）。

### OQ-3：從 Figma 到代碼的最佳路徑

**問題**：在 Figma 設計完成後，哪種代碼生成路徑能以最低維護成本輸出符合本專案技術棧（React + Tailwind CSS + Shadcn UI）的前端代碼？

**候選路徑評估方向**：

| 候選路徑 | 說明 | 評估重點 |
|---------|------|---------|
| Figma Dev Mode API | Figma 官方提供的設計標注 API，輸出 CSS 值與元件資訊 | 是否能直接輸出 Tailwind class；是否需要自訂後處理 |
| Builder.io / Anima | 第三方 Figma-to-code 工具，支援 React 輸出 | 輸出代碼品質；Tailwind 支援程度；授權費用 |
| 自訂 codegen | 透過 Figma REST API 讀取節點結構，自行生成 React + Tailwind | 維護成本；準確度；對 Shadcn UI 的支援能力 |
| AI 讀取 Figma Export | AI 讀取 Figma Frame 截圖或 SVG export，直接生成代碼 | 準確度；是否需要額外 Figma API 整合 |

**判定標準**：選定路徑應能在無大量人工干預的情況下，生成通過 Vision Critic 審查（≥ 80 分）的前端代碼。

### OQ-4：Figma 授權與成本

**問題**：Figma API 的使用是否存在授權門檻或成本限制，影響本方案的可行性？

**調查方向**：

- Figma REST API 的免費方案限制（每日/每月 API 呼叫數）
- Figma 組織方案（Organization/Enterprise）的 API 配額
- Figma Variables API 的存取限制（Variables API 在 Figma 的定價層級要求）
- MCP Server 整合是否需要特殊的 API token 類型（Personal Access Token vs OAuth App）

**判定標準**：總體授權成本應在專案可承受範圍內（具體閾值待 OQ-4 調查結果後評估）。

---

## 風險與緩解

| 風險 | 可能性 | 影響 | 緩解策略 |
|------|--------|------|---------|
| Figma MCP Server 能力不足（OQ-1 阻塞） | 中 | 高（此 ADR 降級） | 降級回 ADR-014 三層管線（選項 A），Phase 2 繼續推進 SSD JSON 路徑 |
| Figma REST API Rate Limit 阻塞自動化（OQ-2 阻塞） | 低至中 | 高 | 引入請求佇列與重試機制；考慮 Figma Plugin API 作為替代寫入路徑 |
| AI 生成的 Figma Frame 品質不達標 | 中 | 中 | 強化 AI Prompt 設計（引用 Component Library、明確 Auto Layout 規則）；引入人工設計師介入修正環節 |
| 從 Figma 到代碼的路徑無法輸出 Tailwind（OQ-3） | 低至中 | 中 | 自訂 codegen 作為備選路徑；ADR-014 Phase 1 確立的元件庫白名單原則不因代碼生成路徑而改變 |
| Figma Variables API 授權成本過高（OQ-4） | 低 | 中 | 評估降級使用 `design-tokens.json` 靜態管理；僅在 Figma 中使用 Styles 而非 Variables |
| Figma 服務中斷影響設計流程 | 低 | 中 | 本地快取最近 Sprint 的 Figma 設計稿（export 為 SVG / PNG）；定義服務中斷時的人工替代流程 |
| 與 ADR-014 Phase 1 成果的相容性問題 | 低 | 低 | ADR-014 Phase 1 交付物（Design Tokens、元件庫白名單、AC 模板）均可在新管線中繼續適用 |

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
- [Figma REST API 文件](https://www.figma.com/developers/api)
- [Figma Plugin API 文件](https://www.figma.com/plugin-docs/)
- [Figma Variables API](https://www.figma.com/developers/api#variables)
- [Claude API — Vision capabilities](https://docs.anthropic.com/en/docs/build-with-claude/vision)
