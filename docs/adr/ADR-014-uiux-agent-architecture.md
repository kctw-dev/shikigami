# ADR-014：UIUX Agent 架構決策

**狀態**：Accepted
**日期**：2026-03-06
**接受日期**：2026-03-06（Sprint 53 前置任務）
**決策者**：Architect
**關聯 Issue**：#100（UIUX agent 功能需求）、#95（US-102 本 ADR 起草）
**關聯 ADR**：ADR-006（Prompt Injection 防護）、ADR-007（Story Lifecycle Subagent）、ADR-011（GitHub Actions 整合）、ADR-013（Diagram Skill MCP 整合）

---

## 背景

Issue #100 提出在 Shikigami Agent 工作流中引入分層 UI/UX Agent 機制，以系統性解決全自動 AI 開發團隊產出「工程師美學」介面的問題。

現有 Shikigami 框架（截至 v0.29.0）的 Agent 工作流聚焦於文字規格驅動的開發生命週期（Backlog Intake、Story Lifecycle、Diagram 生成等），尚無任何前端產出品質保證機制。當 Developer subagent 接到前端 Story 時，僅有功能性 AC 約束，缺乏：

1. **視覺設計約束**：無強制的元件庫白名單、Design Tokens 規格
2. **多 Agent 制衡**：無獨立審查 Agent 驗證前端產出品質
3. **人機協作機制**：高風險 UI 操作缺乏 Human-in-the-loop 攔截點
4. **上游設計規格化**：設計意圖以自然語言傳遞，無結構化規格轉換流程

Issue #100 的核心洞察是：「不相信 AI 的自由發揮，只相信嚴格定義的約束與審查工作流」。此洞察導向以下三層 Agent 分工概念：

- **UX Agent**：解析功能規格，產出語意化資訊架構骨架（無樣式）
- **UI Agent**：將骨架套入元件庫與 Design Tokens，產出前端代碼
- **Vision Critic Agent**：透過截圖審查視覺品質，不合格退回 UI Agent 重做

本 ADR 評估此三層架構的可行性，比較替代方案，並制定分期實作策略。

### 約束條件

| 約束 | 來源 | 說明 |
|------|------|------|
| 多模態模型支援 | Claude Sonnet 4.6 能力 | Vision Critic Agent 截圖審查依賴模型圖片輸入能力，Claude Sonnet 4.6 原生支援 |
| ADR-006 Injection 防護繼承 | ADR-006 §影響 | 任何外部資料（截圖、元件庫輸出）進入 Agent prompt 時，須套用 XML 隔離標記 |
| 小團隊 / MVP 階段 | 專案現狀 | 維護負擔需控制，避免引入持續性 Ops 複雜度 |
| YAGNI 原則 | ADR-011、ADR-012 共同確立 | MVP 階段不實作超出當前需求的複雜度 |
| SDD 優先 | 框架核心設計 | 所有 Agent 行為以 Spec-Driven Development 為基礎，文件先行 |

---

## 決策問題

Shikigami 框架應以何種 Agent 架構整合 UI/UX 設計能力，在技術可行性、實作複雜度、維護成本與品質保證效果之間取得最佳平衡？

---

## 決策域 1：Agent 分工架構

### Option A：三層 Agent 分工（UX Agent → UI Agent → Vision Critic Agent）

建立三個獨立 subagent 角色，形成串行品質管線（Quality Pipeline）。

#### 架構示意

```
功能規格 (User Story / SDD)
    │
    ▼
UX Agent（角色：資訊架構師）
    │ 輸出：語意化骨架文件（無樣式）
    │ 包含：版面區塊、元件層級、互動說明
    ▼
UI Agent（角色：前端實作者）
    │ 約束：僅用 Tailwind CSS + Shadcn UI
    │ 約束：所有設計變數來自 Design Tokens JSON
    │ 輸出：前端代碼（React / HTML）
    ▼
Vision Critic Agent（角色：視覺總監）
    │ 輸入：前端截圖 + Design Tokens 規格
    │ 審查：對齊、對比度、留白、元件一致性
    ├─ PASS → 交付後端串接
    └─ FAIL → 結構化退件報告 → 回到 UI Agent
```

#### 優缺點矩陣

| 面向 | 評估 | 說明 |
|------|------|------|
| 關注點分離 | 優 | UX（架構）、UI（實作）、Quality（審查）職責明確，符合 Single Responsibility Principle |
| 品質保證強度 | 優 | Vision Critic Agent 作為獨立守門人，有效防止低品質產出流入下游 |
| 可追溯性 | 優 | 三層各自輸出工件（骨架文件、代碼、審查報告），問題可回溯至特定層 |
| 實作複雜度 | 劣 | 需設計三個 SKILL.md、Agent 間溝通協議、退件重做迴圈機制 |
| 執行延遲 | 劣 | 串行管線增加端對端執行時間（UX + UI + Vision Critic 三次 LLM 呼叫） |
| Vision Critic 截圖觸發 | 中 | 需解決「如何在 CLI 工作流中擷取前端截圖」的技術問題（見技術可行性評估） |
| 元件庫白名單強制性 | 優 | UI Agent 約束明確，設計漂移風險低 |

---

### Option B：單一 UIUX Agent 統包

由單一 Agent 承擔從規格解析到前端代碼產出的完整職責，透過詳細的系統提示（System Prompt）和設計規格約束品質。

#### 架構示意

```
功能規格 (User Story / SDD)
    │
    ▼
UIUX Agent（統包角色）
    │ 系統提示包含：
    │ - 資訊架構方法論
    │ - 元件庫白名單（Tailwind CSS + Shadcn UI）
    │ - Design Tokens 引用
    │ - 視覺審查 Checklist（自審）
    ▼
前端代碼輸出
```

#### 優缺點矩陣

| 面向 | 評估 | 說明 |
|------|------|------|
| 實作簡單 | 優 | 單一 SKILL.md；無 Agent 間協調複雜度 |
| 執行速度 | 優 | 單次 LLM 呼叫；無管線等待 |
| 品質保證強度 | 劣 | 自審偏差（Self-review Bias）：負責產出的 Agent 同時負責審查，批評自身工作品質有限 |
| 關注點分離 | 劣 | UX 架構思維與 UI 實作細節混合，兩種認知模式競爭同一 context window |
| 可擴展性 | 劣 | 單一 Agent 難以獨立演進各層能力（如替換視覺審查模型） |
| Design Tokens 強制性 | 中 | System Prompt 約束可能被 Agent 繞過（無獨立驗證機制） |

---

### Option C：雙層分工（Design Agent + Implementation Agent）

將 UX 與視覺審查合併為 Design Agent，保留獨立的 Implementation Agent。

#### 架構示意

```
功能規格
    │
    ▼
Design Agent（UX 規格 + 視覺標準定義）
    │ 輸出：完整設計規格（骨架 + 視覺規格 + 驗收標準）
    ▼
Implementation Agent（前端代碼實作）
    │ 約束：Design Agent 輸出的規格書
    ▼
前端代碼輸出（由 Design Agent 驗收）
```

#### 優缺點矩陣

| 面向 | 評估 | 說明 |
|------|------|------|
| 平衡複雜度與品質 | 中 | 兩層分工比三層簡單，但自審問題仍存在（Design Agent 同時定義標準與驗收） |
| 設計思維集中 | 優 | Design Agent 在規格階段投入完整設計思維，不被實作細節干擾 |
| 視覺審查缺陷 | 劣 | 缺乏截圖層面的客觀審查；Design Agent 審查的是規格符合性，非視覺輸出品質 |
| 實作複雜度 | 中 | 兩個 SKILL.md；Agent 間協調比三層簡單 |

---

### 決策域 1 評估矩陣

| 評估維度 | Option A（三層分工） | Option B（統包） | Option C（雙層分工） |
|---------|---------------------|-----------------|---------------------|
| 品質保證強度 | 高（獨立視覺審查） | 低（自審偏差） | 中（無截圖審查） |
| 實作複雜度 | 高 | 低 | 中 |
| 關注點分離 | 高 | 低 | 中 |
| 可擴展性 | 高 | 低 | 中 |
| 執行延遲 | 高（串行管線） | 低 | 中 |
| Design Tokens 強制性 | 高（獨立驗證） | 中（System Prompt 約束） | 中 |
| Vision Critic 技術可行性 | 需驗證 | 不適用 | 不適用 |
| MVP 階段適當性 | 中（分期實作可降低風險） | 高（簡單但品質風險高） | 中 |

---

## 技術可行性評估

### Vision Critic Agent 截圖審查能力

Vision Critic Agent 是 Option A 的核心技術不確定性。以下從三個面向評估。

#### 1. 模型多模態能力（Claude Sonnet 4.6）

| 能力 | 評估 | 說明 |
|------|------|------|
| 圖片輸入支援 | 已確認 | Claude Sonnet 4.6 原生支援圖片輸入（PNG、JPEG、WebP、GIF） |
| 視覺分析能力 | 已確認 | 能識別 UI 元素佈局、顏色對比、留白品質、元件一致性等視覺屬性 |
| 設計規格對照 | 已確認 | 可接受 Design Tokens JSON + 截圖，對照規格進行審查 |
| 截圖解析度需求 | 需驗證 | UI 截圖需足夠解析度以識別細節；低解析度截圖可能影響審查精確性 |
| Reference Image 比對 | 已確認 | 可接受高質感 Reference 截圖（如 Stripe、Apple 設計），提取並對照品味標準 |

**結論**：模型能力面無阻塞性技術障礙，Claude Sonnet 4.6 可勝任視覺審查任務。

#### 2. 截圖觸發機制可行性

Vision Critic Agent 需要「前端渲染結果的截圖」作為輸入。在 Shikigami CLI 工作流中，截圖觸發有以下可行路徑：

| 路徑 | 可行性 | 說明 |
|------|--------|------|
| **Playwright / Puppeteer 自動截圖** | 高 | UI Agent 輸出前端代碼後，由自動化測試工具渲染並截圖；與 CI 整合自然；需安裝 browser runtime |
| **開發者手動截圖** | 中 | Human-in-the-loop 步驟：開發者在本機預覽後提供截圖給 Vision Critic Agent；無需額外工具，但打破全自動流程 |
| **Storybook 截圖** | 中 | 若專案使用 Storybook，可透過 Storybook Test Runner 自動截圖；需 Storybook 環境 |
| **Base64 直接傳遞** | 高 | Playwright 截圖輸出為 PNG bytes，可直接 Base64 編碼後傳入 Claude API；無需額外儲存 |

**MVP 建議路徑**：Playwright 自動截圖 + Base64 傳遞，在 CI 環境中可靠且可自動化。

#### 3. 退件迴圈（Feedback Loop）設計

| 面向 | 評估 | 說明 |
|------|------|------|
| 迴圈終止條件 | 需定義 | 最多重試次數（建議 3 次）或達到通過閾值即終止，防止無限迴圈 |
| 退件報告結構 | 可設計 | Vision Critic 輸出結構化 JSON 退件報告（問題分類、位置、改善建議），UI Agent 依此修正 |
| 上下文傳遞 | 需考慮 | 每次重試需帶入原始規格 + 歷次審查報告，避免 UI Agent 重複相同錯誤 |
| Context Window 限制 | 需注意 | 多輪迴圈可能消耗大量 context；需考慮長 conversation 的 token 管理策略 |

---

## 四階段分期策略

依據 Issue #100 留言的核心藍圖，將 UIUX Agent 建設分為四個階段，並對應到 Shikigami Sprint 實作節奏。

### Phase 1（Sprint 52-53，2-4 Weeks）：UI/UX 角色重定義與防呆基礎

**目標**：建立基礎設計約束機制，確立 Agent 工作流中 UI/UX 的最小可行角色。

| 工作項目 | 類型 | 說明 |
|---------|------|------|
| **Design Tokens 定義檔建立** | 文件 | 建立機器可讀的 `design-tokens.json`（主色、字型、圓角、間距、陰影），作為所有後續前端 Story 的強制約束輸入 |
| **元件庫白名單 SDD** | 文件 | 在 SDD 模板中新增「前端技術約束」欄位：強制使用 Tailwind CSS + Shadcn UI，禁止自訂 CSS（需 AC 驗證） |
| **Human-in-the-loop 攔截規範** | 文件 | 定義「高風險 UI 操作」清單（寫入、重啟、付款）；在 Story AC 模板中加入 HITL 確認點 |
| **前端 Story AC 模板強化** | 文件 | 更新 Backlog Intake 流程，前端相關 Story 自動注入設計約束 AC（元件庫符合性、Design Tokens 使用） |

**預計後續 Story 方向（Phase 1）**：
- **US-103**：Design Tokens 定義檔建立（`design-tokens.json` + SDD 欄位模板）
- **US-104**：元件庫白名單 AC 模板注入機制（Backlog Intake 自動化）

**Phase 1 完成佐證（Sprint 52，2026-03-06）**：

| 工作項目 | 交付工件 | 狀態 |
|---------|---------|------|
| Design Tokens 定義檔建立 | `docs/design/design-tokens.json`（五個設計變數群組，各含 3+ 具名 token） | 完成 |
| 元件庫白名單 SDD | `docs/templates/sdd-frontend-template.md`（Frontend Constraints 區段） | 完成 |
| 前端 Story AC 模板強化 | `skills/issue-management/SKILL.md` §12（前端 Story 識別 + 自動 AC 注入） | 完成 |
| ADR-014 OQ-2 決策 | 自訂 JSON 格式（YAGNI 原則），已填入 OQ-2 說明區塊 | 完成 |

Phase 1 全部 2 Stories（US-103/US-104）於 Sprint 52 完成，Velocity 2 points，完成率 100%。本 ADR 狀態從 Proposed 升為 Accepted。

---

### Phase 2（Sprint 54-56，4-6 Weeks）：上游設計 Agent 化（UX Agent + UI Agent）

**目標**：實作三層 Agent 管線的前兩層，建立 UX 規格化與 UI 實作的分工機制。

| 工作項目 | 類型 | 說明 |
|---------|------|------|
| **UX Agent SKILL.md 實作** | 代碼 | 定義 `shikigami:ux` 技能：輸入 User Story，輸出語意化資訊架構骨架（版面區塊、元件層級、互動說明），無樣式 |
| **UI Agent SKILL.md 實作** | 代碼 | 定義 `shikigami:ui` 技能：輸入 UX 骨架 + Design Tokens，輸出僅用 Tailwind CSS + Shadcn UI 的前端代碼 |
| **Playwright 截圖整合** | 代碼 | 在 CI 工作流中加入 Playwright 截圖步驟，為 Phase 3 Vision Critic 準備基礎設施 |
| **Agent 間溝通協議定義** | 文件 | 定義 UX → UI 的骨架文件格式規範（JSON Schema），確保兩 Agent 輸入/輸出相容 |

**預計後續 Story 方向（Phase 2）**：
- **US-105**：UX Agent SKILL.md 實作（含骨架文件 JSON Schema 定義）
- **US-106**：UI Agent SKILL.md 實作（含 Design Tokens 注入機制）

---

### Phase 3（Sprint 57-60，6-8 Weeks）：Vision Critic Agent 整合

**目標**：完成三層 Agent 管線，引入截圖視覺審查與退件迴圈。

| 工作項目 | 類型 | 說明 |
|---------|------|------|
| **Vision Critic Agent SKILL.md 實作** | 代碼 | 定義 `shikigami:vision-critic` 技能：輸入截圖 + Design Tokens，輸出結構化審查報告（PASS/FAIL + 退件說明） |
| **退件迴圈機制** | 代碼 | 在 Story Lifecycle 中整合 Vision Critic 觸發點；UI Agent 接收退件報告後修正並重試（最多 3 次） |
| **Reference Image 品味注入** | 代碼 | Vision Critic 接受 Reference 截圖（Stripe、Apple 設計）作為品味標準參照 |
| **ADR-006 延伸** | 文件 | 截圖（外部視覺資料）進入 Vision Critic prompt 須套用適當隔離標記；更新 ADR-006 Addendum |

**預計後續 Story 方向（Phase 3）**：
- **US-107**：Vision Critic Agent SKILL.md 實作（含退件報告 JSON Schema）
- **US-108**：三層 Agent 管線端對端整合測試

---

### Phase 4（Sprint 61+，長期）：品味注入機制

**目標**：建立 AI 品味機制，讓產出超越「安全的平均值」，達到高質感設計水準。

| 工作項目 | 類型 | 說明 |
|---------|------|------|
| **Reference-Driven Design 機制** | 代碼 | 建立 Reference 截圖庫（高質感設計範例），Vision Critic 自動引用作為審查基準 |
| **微互動規格注入** | 文件 | 在 Design Tokens 中加入動畫規格（貝茲曲線、過場延遲），強制前端代碼遵循 |
| **語氣 Agent** | 代碼 | 定義 `shikigami:tone` 技能：潤飾所有錯誤提示與 UI 文案，消除「機器人味」 |
| **PM Agent / Flow Agent / Spec Compiler Agent** | 代碼 | 上游設計 Agent 化：從一句話需求自動產出 Edge Cases 狀態機、頁面跳轉邏輯、結構化 JSON 規格書 |

**Phase 4 屬長期演進，不排入近期 Sprint 規劃。**

---

### 分期策略總覽

| 階段 | Sprint 範圍 | 核心交付 | 優先級 |
|------|-----------|---------|-------|
| **Phase 1**：角色重定義與防呆基礎 | Sprint 52-53 | Design Tokens + 元件庫白名單 + AC 模板 | **先做** |
| **Phase 2**：UX + UI Agent 實作 | Sprint 54-56 | UX Agent SKILL.md + UI Agent SKILL.md | **先做** |
| **Phase 3**：Vision Critic Agent | Sprint 57-60 | Vision Critic + 退件迴圈 | 後做 |
| **Phase 4**：品味注入 | Sprint 61+ | Reference Design + 微互動 + 語氣 Agent | 後做 |

---

## 後續 Story 方向清單

基於本 ADR 的分析，識別以下後續 Story 方向（至少 3 個）：

| Story 方向 | 對應階段 | 大小估計 | 觸發 Issue |
|-----------|---------|---------|-----------|
| **US-103**：Design Tokens 定義檔建立（`design-tokens.json` + SDD 欄位模板更新） | Phase 1 | S | #100 |
| **US-104**：元件庫白名單 AC 注入機制（Backlog Intake 自動注入前端約束 AC） | Phase 1 | S | #100 |
| **US-105**：UX Agent SKILL.md 實作（骨架文件 JSON Schema + 技能定義） | Phase 2 | M | #100 |
| **US-106**：UI Agent SKILL.md 實作（Design Tokens 注入 + 元件庫白名單強制） | Phase 2 | M | #100 |
| **US-107**：Vision Critic Agent SKILL.md 實作（截圖輸入 + 退件報告 JSON Schema） | Phase 3 | L | #100 |
| **US-108**：三層 Agent 管線端對端整合測試 | Phase 3 | M | #100 |

---

## 建議方案

### 建議：Option A（三層 Agent 分工）+ 分期實作策略

基於以下理由，本 ADR 建議採用 Option A（三層 Agent 分工），但透過四階段分期策略控制實作風險：

#### 1. 品質保證需要獨立審查機制

Option B（統包）的自審偏差問題是根本性的架構缺陷：負責產出的 Agent 在審查自身工作時天生具有盲點，這在軟體品質工程領域有充分的研究佐證。Option A 透過獨立的 Vision Critic Agent 建立客觀的品質守門機制，符合 Separation of Concerns 原則。

#### 2. Vision Critic Agent 技術可行性已確認

Claude Sonnet 4.6 原生支援多模態輸入，截圖審查的模型能力面無阻塞性障礙。截圖觸發機制可透過 Playwright 自動化解決，技術路徑明確。主要風險為實作複雜度，可透過分期策略（Phase 3 才實作 Vision Critic）管理。

#### 3. 分期策略降低初始風險

Phase 1 和 Phase 2 不依賴 Vision Critic Agent 的截圖機制，可先交付 Design Tokens 約束和雙層 Agent 分工，在 Phase 3 才引入完整三層管線。此演進路徑符合演進式架構的可逆性與漸進式實現原則。

#### 4. 元件庫白名單的強制性更高

三層架構中，UI Agent 的設計約束可由 Vision Critic Agent 獨立驗證，形成雙重保護（規格約束 + 視覺驗證）。Option B 的統包架構中，約束強制性僅依賴系統提示，缺乏獨立驗證。

---

## 開放問題

| # | 問題 | 優先級 | 狀態 | 說明 |
|---|------|--------|------|------|
| OQ-1 | Playwright 截圖在 GitHub Actions self-hosted runner 的可行性 | 高 | 已決策（2026-03-06） | 可行。GCP Ubuntu 22.04/24.04 VM 可透過 `npx playwright install chromium --with-deps` 完成安裝；建議 2 vCPU / 4 GB RAM；詳見下方 OQ-1 決策說明。 |
| OQ-2 | Design Tokens 格式標準選型 | 高 | 已決策（2026-03-06） | 選擇自訂 JSON（YAGNI 原則）。詳見下方 OQ-2 決策說明。 |
| OQ-3 | Vision Critic 審查的量化通過閾值定義 | 中 | 已決策（2026-03-06） | 採用三維度加權評分制（色彩一致性 40%、元件位置 35%、間距合規性 25%），總分 ≥ 80 為 PASS。詳見下方 OQ-3 決策說明。 |
| OQ-4 | UX Agent 骨架文件格式 JSON Schema 定義 | 中 | 已決策（2026-03-06） | 採用 JSON Schema Draft-07，以 `ajv` 為驗證工具。詳見下方 OQ-4 決策說明。 |
| OQ-5 | 長對話 Context Window 管理策略 | 低 | 已決策（2026-03-06） | 採用「新對話隔離 + 結構化摘要接力」策略，每層 Agent 啟動獨立對話；退件報告以 JSON 摘要格式傳遞而非全文 context 累積。詳見下方 OQ-5 決策說明。 |

### OQ-1 決策說明：Playwright 截圖在 GCP self-hosted runner 可行性（2026-03-06）

**問題**：在 GCP self-hosted GitHub Actions runner 上安裝 headless Chromium 並執行 Playwright 截圖，環境需求為何？是否可行？

**決策：可行**

GCP 上的 Ubuntu 22.04 / 24.04 VM 與 Playwright 官方支援清單完全吻合，一行指令即可完成 Chromium 及全部 OS 層相依套件的安裝，技術路徑明確無阻塞性障礙。

#### AC1 — 環境需求清單

**OS 套件（Playwright 自動管理）**

`npx playwright install chromium --with-deps` 會自動安裝以下 apt 套件（Ubuntu 22.04 / 24.04）：

| 套件 | 用途 |
|------|------|
| `libnss3` | Network Security Services |
| `libatk-bridge2.0-0` | Accessibility Toolkit Bridge |
| `libdrm2` | Direct Rendering Manager |
| `libxkbcommon0` | X keyboard extension |
| `libxcomposite1` | X composite extension |
| `libxdamage1` | X damage extension |
| `libxrandr2` | X RandR extension |
| `libgbm1` | Generic Buffer Management |
| `libxss1` | X11 screensaver extension |
| `libasound2` | ALSA sound library |

不需要額外安裝 Xvfb（headless 模式不需要顯示伺服器）。

**記憶體 / CPU 需求（建議規格）**

| 規格項目 | 最低需求 | 建議規格 | 說明 |
|---------|---------|---------|------|
| CPU | 1 vCPU | 2 vCPU | Chromium 啟動時 CPU 峰值約 1 核；並發渲染需 2 核以上 |
| RAM | 2 GB | 4 GB | 單一 Chromium instance 約佔 200-400 MB；加上 Node.js + Actions runner 共需 2 GB 以上 |
| Disk | 2 GB free | 5 GB free | Playwright Chromium bundle 約 300 MB；build artifacts 額外消耗 |
| OS | Ubuntu 22.04 | Ubuntu 24.04 LTS | 兩版本均在 Playwright 官方支援清單內 |

**GCP VM 對應機型建議**：`e2-medium`（2 vCPU / 4 GB）即可滿足單一截圖工作負載；如需並行多個 Agent 截圖任務，升級為 `e2-standard-4`（4 vCPU / 16 GB）。

**GitHub Actions runner 設定**

```yaml
# .github/workflows/vision-critic.yml（片段）
jobs:
  screenshot:
    runs-on: [self-hosted, linux, gcp]   # 使用 GCP self-hosted runner
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - name: Install Playwright Chromium + deps
        run: npx playwright install chromium --with-deps
      - name: Run screenshot capture
        run: node scripts/capture-screenshot.js
        env:
          # 在 Container/VM 環境必須設定，繞過 Chrome sandbox 限制
          PLAYWRIGHT_CHROMIUM_LAUNCH_ARGS: "--no-sandbox --disable-dev-shm-usage"
```

關鍵設定要點：
- `--no-sandbox`：GCP VM 上執行 Chromium 必須設定（非 root 但無 kernel user namespace 時）
- `--disable-dev-shm-usage`：避免 `/dev/shm` 空間不足導致渲染失敗（GCP VM 預設 `/dev/shm` 較小）
- runner label 加入 `gcp` tag 以路由到正確 runner pool

#### AC2 — 可行性判定

**判定：可行**

| 面向 | 評估 | 說明 |
|------|------|------|
| OS 相容性 | 通過 | GCP Ubuntu 22.04/24.04 在 Playwright 官方支援矩陣內 |
| 套件安裝 | 通過 | `--with-deps` 一行指令自動解析全部相依，無需手動維護套件清單 |
| Headless 執行 | 通過 | 無需 Xvfb；`--no-sandbox --disable-dev-shm-usage` 解決 VM 限制 |
| Base64 傳遞 | 通過 | `page.screenshot()` 直接返回 Buffer，`.toString('base64')` 即可傳入 Claude API |
| CI 整合 | 通過 | 標準 GitHub Actions step，與現有工作流無衝突 |
| 資源需求 | 通過 | `e2-medium`（2 vCPU / 4 GB）即可滿足 MVP 階段單次截圖工作負載 |

#### AC3 — 最小 Playwright 截圖 PoC 腳本（Node.js）

以下腳本示範 Vision Critic Agent 的截圖整合核心邏輯：渲染 HTML 片段、截圖、輸出 Base64 字串，可直接傳入 Claude API `image` 類型訊息。

```javascript
// scripts/capture-screenshot.js
// 最小 Playwright 截圖 PoC — Vision Critic Agent 整合路徑
// 用途：渲染 UI Agent 輸出的 HTML 片段，截圖後以 Base64 傳入 Claude API
// 本機驗證：node scripts/capture-screenshot.js

import { chromium } from 'playwright';
import { readFileSync } from 'fs';
import path from 'path';

// 環境設定
const LAUNCH_ARGS = [
  '--no-sandbox',          // 必要：VM/Container 環境
  '--disable-dev-shm-usage', // 必要：避免 /dev/shm 不足
  '--disable-gpu',         // 建議：headless 模式不需要 GPU
];

/**
 * 截圖並返回 Base64 字串
 * @param {string} htmlContent - UI Agent 輸出的 HTML 片段
 * @param {Object} options
 * @param {number} options.width - viewport 寬度（預設 1280）
 * @param {number} options.height - viewport 高度（預設 720）
 * @returns {Promise<string>} Base64 編碼的 PNG 截圖
 */
async function captureScreenshot(htmlContent, { width = 1280, height = 720 } = {}) {
  const browser = await chromium.launch({
    headless: true,
    args: LAUNCH_ARGS,
  });

  try {
    const page = await browser.newPage();
    await page.setViewportSize({ width, height });

    // 直接設定 HTML 內容（無需 HTTP server）
    await page.setContent(htmlContent, { waitUntil: 'networkidle' });

    // 截圖返回 Buffer（不寫入檔案）
    const buffer = await page.screenshot({
      type: 'png',
      fullPage: false, // Vision Critic 審查 viewport 範圍即可
    });

    // 轉換為 Base64（Claude API 接受格式）
    return buffer.toString('base64');
  } finally {
    await browser.close();
  }
}

/**
 * 組裝 Claude API 多模態訊息 payload（示範用）
 * @param {string} base64Image - Base64 PNG 字串
 * @param {Object} skeletonDoc - UX Agent 輸出的骨架文件 JSON
 * @returns {Object} Claude API messages 格式
 */
function buildVisionCriticPayload(base64Image, skeletonDoc) {
  return {
    role: 'user',
    content: [
      {
        type: 'image',
        source: {
          type: 'base64',
          media_type: 'image/png',
          data: base64Image,
        },
      },
      {
        type: 'text',
        // ADR-006 XML 隔離標記：骨架文件作為外部資料須包覆隔離
        text: `<skeleton_document>\n${JSON.stringify(skeletonDoc, null, 2)}\n</skeleton_document>\n\n請對照骨架文件審查截圖的視覺一致性。`,
      },
    ],
  };
}

// 本機驗證入口
async function main() {
  // 模擬 UI Agent 輸出的 HTML 片段
  const sampleHtml = `
    <!DOCTYPE html>
    <html>
    <head>
      <script src="https://cdn.tailwindcss.com"></script>
    </head>
    <body class="bg-white p-8">
      <div class="max-w-md mx-auto">
        <h1 class="text-2xl font-bold text-gray-900 mb-4">使用者登入</h1>
        <input type="email" placeholder="電子郵件"
               class="w-full border border-gray-300 rounded-lg px-4 py-2 mb-3" />
        <button class="w-full bg-blue-600 text-white rounded-lg px-4 py-2 font-medium">
          登入
        </button>
      </div>
    </body>
    </html>
  `;

  // 模擬骨架文件（UX Agent 輸出）
  const skeletonDoc = {
    sections: [
      {
        id: 'login-form',
        label: '登入表單',
        components: [
          { type: 'heading', level: 1, content: '使用者登入' },
          { type: 'input', inputType: 'email', placeholder: '電子郵件',
            designToken: 'color.border.default' },
          { type: 'button', variant: 'primary', label: '登入',
            designToken: 'color.primary.600' },
        ],
      },
    ],
  };

  console.log('正在啟動 Playwright Chromium...');
  const base64 = await captureScreenshot(sampleHtml);
  console.log(`截圖完成，Base64 長度：${base64.length} 字元`);

  const payload = buildVisionCriticPayload(base64, skeletonDoc);
  console.log('Claude API payload 結構：');
  console.log(JSON.stringify({
    role: payload.role,
    content: [
      { type: 'image', source: { type: 'base64', media_type: 'image/png', data: '[...BASE64...]' } },
      { type: 'text', text: payload.content[1].text.substring(0, 100) + '...' },
    ],
  }, null, 2));

  console.log('\nPoC 驗證成功。Base64 截圖可直接傳入 Claude API vision-critic 呼叫。');
}

main().catch(console.error);
```

**本機驗證步驟**：
```bash
# 1. 安裝 Playwright（專案根目錄）
npm install playwright

# 2. 安裝 Chromium（含 OS 相依套件）
npx playwright install chromium --with-deps

# 3. 執行 PoC
node scripts/capture-screenshot.js
```

**預期輸出**：
```
正在啟動 Playwright Chromium...
截圖完成，Base64 長度：XXXXXX 字元
Claude API payload 結構：{ ... }
PoC 驗證成功。Base64 截圖可直接傳入 Claude API vision-critic 呼叫。
```

---

### OQ-2 決策說明：Design Tokens 格式選型（2026-03-06）

**問題**：應採用 W3C Design Tokens Community Group（DTCG）格式還是自訂 JSON 格式作為 `design-tokens.json` 的規格標準？

**候選方案比較**

| 面向 | W3C DTCG 格式 | 自訂 JSON（選定） |
|------|-------------|----------------|
| 標準化程度 | 高（業界標準草案） | 低（專案私有格式） |
| 工具生態相容性 | 高（Style Dictionary、Token Transformer 等工具原生支援） | 低（需自行解析） |
| 學習成本 | 中（需遵循 `$type`、`$value`、`$extensions` 規範） | 低（直觀 JSON 鍵值對） |
| MVP 階段所需複雜度 | 過高（DTCG spec 尚為 W3C Draft，實作細節持續演進） | 適當（當前僅需 Agent 可讀的靜態規格） |
| 與 UI Agent 互通性 | 高（未來工具鏈整合更容易） | 中（後續若需互通，可遷移至 DTCG） |
| YAGNI 符合性 | 不符合（Phase 1 無工具鏈整合需求） | 符合 |

**決策**：選擇**自訂 JSON 格式**。

**理由**：

1. **YAGNI 原則**：ADR-011、ADR-012 共同確立的 MVP 階段 YAGNI 約束適用於本決策。Phase 1 的 Design Tokens 用途僅為「Agent 可讀的靜態設計規格」，不涉及工具鏈轉換（Token Transformer、Style Dictionary）或跨工具輸出（CSS Custom Properties、iOS Tokens）。W3C DTCG 格式的完整規範在此階段帶來不必要的複雜度。

2. **W3C DTCG 仍為 Draft 規格**：截至 2026-03-06，W3C Design Tokens Community Group 格式仍為草案階段（未正式發布），採用 Draft 規格作為生產環境標準存在格式漂移風險。

3. **自訂 JSON 已充分滿足 Phase 1 需求**：`docs/design/design-tokens.json` 採用直觀的群組 → token 鍵值對結構（`color.primary.500`、`spacing.4`），UI Agent 與 Developer Subagent 均可直接解析，無需額外 schema 學習。

4. **低遷移成本**：自訂 JSON 的扁平化結構若未來需遷移至 DTCG，轉換腳本可在 1-2 小時內完成，遷移風險可控。

**影響**：

- `docs/design/design-tokens.json` v1.0.0 採用自訂 JSON 格式，以 `$value`、`$description` 作為 token 物件的標準欄位名稱（與 DTCG 慣例部分對齊，降低未來遷移成本）。
- Phase 2 的 UI Agent 實作（US-106）須以此格式解析 Design Tokens，不依賴外部 Token 轉換工具。
- 若 Phase 3 或以後引入跨平台 Token 輸出需求，應透過新 ADR 評估是否遷移至 W3C DTCG 或採用 Style Dictionary。

---

### OQ-3 決策說明：Vision Critic 通過閾值量化（2026-03-06）

**問題**：Vision Critic Agent 的視覺一致性審查應以何種量化標準判定 PASS/FAIL，以防止主觀判定導致退件迴圈無法收斂？

**背景**

退件迴圈終止條件若缺乏量化基準，Vision Critic Agent 將陷入主觀評判，導致兩個問題：（1）無法收斂：Agent 每輪審查結論不一致；（2）過度嚴苛：輕微差異觸發不必要的退件，浪費 LLM 呼叫成本。本決策參考 WCAG 2.1 AA 標準與業界視覺迴歸測試實踐，為三個評分維度定義可操作的量化閾值。

**參考基準**

| 參考來源 | 適用維度 | 關鍵指標 |
|---------|---------|---------|
| WCAG 2.1 AA SC 1.4.3 | 色彩一致性 | 文字與背景對比度 ≥ 4.5:1（正常字）、≥ 3:1（大字 / UI 元件） |
| WCAG 2.1 AA SC 2.5.5 | 元件位置 | 可互動目標最小尺寸 44×44 CSS px |
| WCAG 2.1 AA SC 1.4.12 | 間距合規性 | 行高 ≥ 1.5 倍字體大小；段落間距 ≥ 2 倍字體大小 |
| Playwright maxDiffPixelRatio | 元件位置 | 業界常見像素差異容忍率 0.1%–1% |
| Percy / Chromatic | 元件位置 | 設計系統層級採用更嚴格閾值（接近 0%）；應用層級可放寬 |
| Design Tokens 約束 | 色彩一致性 | 所有色彩值須引用 `docs/design/design-tokens.json` 具名 token |

**評分維度定義**

Vision Critic 對每個維度輸出 0–100 分，加權合算為總分。

#### 維度一：色彩一致性（權重 40%）

評估 UI 輸出的色彩使用是否符合 Design Tokens 規格與 WCAG 對比度要求。

| 分數範圍 | 判定說明 |
|---------|---------|
| 90–100 | 所有色彩均引用 Design Tokens 具名 token；文字對比度 ≥ 4.5:1；UI 元件邊框對比度 ≥ 3:1 |
| 70–89 | 色彩值偏差 ≤ 5%（如 hardcode 值與 token 值接近）；對比度符合 WCAG AA |
| 50–69 | 存在 1–2 處色彩 hardcode，但不違反 WCAG AA 對比度 |
| 0–49 | 存在 WCAG AA 對比度違規（< 4.5:1 正常字 或 < 3:1 UI 元件），或大量 hardcode 色彩 |

**PASS 閾值**：維度分 ≥ 70（對比度達標為必要條件，未達 WCAG AA 直接判 0–49）

#### 維度二：元件位置（權重 35%）

評估 UI 元件的佈局位置是否符合骨架文件（UX Agent 輸出）的版面規格。

| 分數範圍 | 判定說明 |
|---------|---------|
| 90–100 | 所有元件位置與骨架文件規格完全對齊；可互動元件尺寸 ≥ 44×44 CSS px |
| 70–89 | 元件位置偏移 ≤ 8px（對應 Tailwind 2 個間距單位）；層級結構符合骨架文件 |
| 50–69 | 元件位置偏移 9–16px，或 1–2 個元件層級錯置，但整體視覺可辨 |
| 0–49 | 元件位置偏移 > 16px，或元件層級嚴重錯置，或可互動元件低於 44×44 CSS px |

**PASS 閾值**：維度分 ≥ 70（對應像素偏移容忍 ≤ 8px，略高於業界 Playwright 1% 但更適合設計系統語意審查場景）

#### 維度三：間距合規性（權重 25%）

評估元件間距、行高、留白是否符合 Design Tokens 間距規格與 WCAG 可讀性要求。

| 分數範圍 | 判定說明 |
|---------|---------|
| 90–100 | 所有間距值引用 Design Tokens 間距 token；行高 ≥ 1.5 倍字體大小；段落間距 ≥ 2 倍字體大小 |
| 70–89 | 間距值偏差 ≤ 4px（1 個 Tailwind 基礎單位），或 1 處行高略低但不低於 1.3 倍 |
| 50–69 | 2–3 處間距 hardcode，但整體視覺節奏可接受 |
| 0–49 | 大量間距 hardcode 或行高 < 1.3 倍字體大小（嚴重影響可讀性） |

**PASS 閾值**：維度分 ≥ 70（對應間距偏差容忍 ≤ 4px）

**總分計算與 PASS/FAIL 判定**

```
總分 = (色彩一致性分 × 0.40) + (元件位置分 × 0.35) + (間距合規性分 × 0.25)
```

| 總分範圍 | 判定結果 | 後續行動 |
|---------|---------|---------|
| ≥ 80 | **PASS** | 交付後端串接 |
| 70–79 | **條件通過** | 附改善建議，可選擇性修正後重提；不強制退件 |
| < 70 | **FAIL** | 發出結構化退件報告，要求 UI Agent 修正並重試（最多 3 次） |

**PASS 附帶必要條件（Hard Gate）**

以下任一條件觸發，無論總分多高均強制判 FAIL：

1. 任一文字色彩對比度 < 4.5:1（WCAG 2.1 AA SC 1.4.3 硬性要求）
2. 任一 UI 元件邊框對比度 < 3:1（WCAG 2.1 AA SC 1.4.11 硬性要求）
3. 骨架文件中標記為「必要」的元件在截圖中完全缺失

**候選方案比較**

| 方案 | 總分 PASS 閾值 | 優點 | 缺點 |
|------|-------------|------|------|
| 嚴格方案（≥ 90） | 各維度均需接近滿分 | 最高品質保證 | 誤退率高，迴圈成本高 |
| **標準方案（≥ 80）（選定）** | 允許少量偏差 | 平衡品質與效率；業界 QA 常見「80分及格」慣例 | — |
| 寬鬆方案（≥ 70） | 接受中等品質 | 退件率低 | 可能放過明顯視覺問題 |

**決策**：選擇**三維度加權評分制，總分 ≥ 80 為 PASS**，並附三項 Hard Gate 必要條件。

**理由**

1. **量化可重現**：LLM 審查時以分數代替主觀詞彙（「良好」、「可接受」），每次審查結果有明確數字錨點，大幅降低不一致性。

2. **WCAG AA 作為 Hard Gate**：色彩對比度違規屬無障礙合規問題，不允許用分數「平均掉」，故獨立為強制條件，與維度分數邏輯分離。

3. **加權設計反映商業重要性**：色彩一致性（40%）影響品牌識別與可及性，為最高權重；元件位置（35%）決定功能可用性；間距合規性（25%）影響閱讀舒適度，為最低但不可忽視的維度。

4. **80 分閾值符合業界慣例**：Chromatic 和 Percy 在設計系統層級設定接近 0 差異，但此為像素級比對工具；Vision Critic 以 LLM 語意審查為主，80 分閾值提供適當容錯空間，避免因渲染細節導致的誤退。

5. **條件通過區間（70–79）防止二元極端化**：給出改善建議但不強制退件，減少迴圈次數，符合 YAGNI 精神（不為邊界案例建立複雜退件流程）。

**影響**

- US-107（Vision Critic SKILL.md）的 AC3 直接引用本決策，定義通過/不通過閾值量化標準。
- Vision Critic Agent 的退件報告 JSON Schema 須包含三個維度分數欄位（`colorConsistencyScore`、`componentPositionScore`、`spacingComplianceScore`）及總分（`totalScore`）。
- Hard Gate 違規須在退件報告中以獨立欄位標記（`hardGateViolations: []`），與分數邏輯分離。
- 最多重試 3 次的限制（見技術可行性評估迴圈終止條件）不受本決策修改，維持原設計。

---

### OQ-4 決策說明：骨架文件 JSON Schema 標準（2026-03-06）

**問題**：UX Agent 輸出的骨架文件（Skeleton Document）應採用哪種 JSON Schema 標準加以定義與驗證，以確保 UI Agent 可解析、可驗證，並符合 MVP 階段的複雜度約束？

**候選方案比較**

| 面向 | JSON Schema Draft-07（選定） | JSON Schema Draft-2020-12 | OpenAPI 3.1 |
|------|--------------------------|--------------------------|-------------|
| 瀏覽器 / Node.js 工具鏈支援 | 最廣泛（ajv 6.x 原生支援，生態成熟） | 廣泛（ajv 8.x 支援，但部分功能仍有實作差異） | 廣泛（openapi-validator、swagger-parser） |
| 規格穩定性 | 高（Draft-07 為業界長期穩定基準） | 高（W3C 正式發布，但 ajv 8.x 尚有實作邊緣案例） | 高（OpenAPI 3.1 已正式發布，但語意範圍偏向 API 描述） |
| 學習成本 | 低（開發者廣泛熟悉） | 中（引入 `$defs`、`unevaluatedProperties` 等新語意） | 中（原為 API 規格格式，用於 JSON 資料驗證屬非預設用途） |
| YAGNI 符合性 | 高（Draft-07 功能足以滿足骨架文件驗證需求） | 中（新功能在 MVP 階段無明確需求） | 低（OpenAPI 設計目標為 API endpoint 描述，語意與骨架文件驗證存在概念錯位） |
| 驗證工具 | `ajv` v6.x（最成熟，npm 週下載量 1.5 億+） | `ajv` v8.x（需設定 `strict: false` 以相容部分 Draft 行為） | `openapi-validator`（需額外包裝才能用於一般 JSON 驗證） |
| 版本遷移彈性 | 高（Draft-07 → 2020-12 遷移路徑清晰） | — | — |

**決策**：選擇 **JSON Schema Draft-07**，以 **`ajv` v6.x** 為標準驗證工具。

**理由**

1. **工具生態最成熟**：`ajv`（Another JSON Schema Validator）是 Node.js 生態中下載量最大的 JSON Schema 驗證函式庫，Draft-07 為其最穩定的長期支援版本，開箱即用，無需額外設定。

2. **YAGNI 原則**：骨架文件的驗證需求為「欄位型別正確、必要欄位存在、元件陣列格式合規」，Draft-07 的 `type`、`required`、`items`、`enum` 等關鍵字已完全滿足此範圍。Draft-2020-12 的新功能（`$defs`、`unevaluatedProperties`、`prefixItems` 等）在 MVP 階段無明確應用場景，引入只會增加學習成本與工具依賴版本分歧。

3. **OpenAPI 3.1 語意不匹配**：OpenAPI 3.1 的設計目標是描述 REST API endpoint，骨架文件是純 JSON 資料結構，使用 OpenAPI 3.1 驗證純 JSON 資料屬概念錯位，且需要額外包裝層才能提取 `components/schemas` 進行獨立驗證，增加無謂複雜度。

4. **版本遷移路徑清晰**：若未來骨架文件複雜度提升需要 Draft-2020-12 功能，`ajv` 的遷移路徑明確（更換版本號 + 調整 `$schema` URI），遷移風險可控。

**Schema 版本標識規範**

骨架文件 JSON Schema 定義檔（`docs/schemas/skeleton-document-schema.json`）須包含以下欄位：

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://github.com/shikigami/schemas/skeleton-document-schema.json",
  "version": "1.0.0",
  "title": "Skeleton Document Schema"
}
```

**驗證工具規範**

| 工具 | 版本 | 用途 |
|------|------|------|
| `ajv` | v6.x（最新穩定 Draft-07 版本） | 骨架文件 JSON Schema 驗證 |
| `ajv-formats` | v1.x | 支援 `format` 關鍵字（如 `uri`、`date-time`） |

**影響**

- US-117（OQ-4 骨架文件 Schema 標準化）的實作直接引用本決策，建立 `docs/schemas/skeleton-document-schema.json`，採用 JSON Schema Draft-07 格式。
- US-112（UX Agent 實際觸發驗證）的 AC2 Schema 驗證須使用 `ajv` v6.x 執行，驗證 UX Agent 輸出的骨架文件。
- UX Agent（US-105）與 UI Agent（US-106）的 SKILL.md 應引用 `docs/schemas/skeleton-document-schema.json` 作為骨架文件的標準定義來源。
- 若 Phase 3 或以後骨架文件欄位複雜度提升需要 Draft-2020-12 功能，應透過新 ADR Addendum 評估遷移。

---

### OQ-5 決策說明：長對話 Context Window 管理策略（2026-03-06）

**問題**：三層 Agent 管線（UX → UI → Vision Critic）串接執行時，多輪退件迴圈可能導致 context window 累積消耗過大；Vision Critic 每輪重試需攜帶「原始 SSD + 歷次 VRR」（SKILL.md §9.2），退件報告不斷累積有超出 context 限制的風險。

#### AC1 — 三層管線 Context Window 累積問題調查

**各層 Token 消耗估算（基於 Claude Sonnet 4.6，200K context window）**

| 管線層 | 輸入 Token 估算 | 輸出 Token 估算 | 累積風險 |
|--------|--------------|--------------|---------|
| UX Agent | 系統提示（~1,000）+ User Story（~500）+ XML 隔離（~50）= **~1,550** | SSD JSON（~1,000–3,000） | 低：單次對話，無累積 |
| UI Agent（首次） | 系統提示（~1,500）+ SSD JSON（~3,000）+ design-tokens.json（~500）+ XML 隔離（~100）= **~5,100** | React 代碼（~2,000–5,000） | 低：單次對話，無累積 |
| UI Agent（退件重試，每輪） | 首次基礎（~5,100）+ 退件報告（~500–1,000 × 退件次數）= **最多 ~8,100** | React 代碼（~2,000–5,000） | 中：3 輪退件後累積 ~3,000 token 退件歷史 |
| Vision Critic（每輪） | 系統提示（~1,000）+ SSD JSON（~3,000）+ PNG Base64（~2,000–8,000）= **~6,000–12,000** | VRR JSON（~500–1,000） | 中：截圖是最大消耗來源；3 輪退件時累積歷史 VRR ~3,000 |

**關鍵風險識別**：

1. **退件迴圈累積**：Vision Critic SKILL.md §9.2 規定「每次重試須帶入原始 SSD + 歷次 VRR」，3 輪退件後累積 VRR 約 1,500–3,000 tokens，在 200K context 限制下可控，但需設計清晰的摘要策略以避免邊界情況。

2. **截圖 token 佔用**：PNG Base64 編碼圖片在 Claude API 中依解析度不同消耗 2,000–8,000 tokens（1280×720 典型 UI 截圖估計 3,000–6,000 tokens）。全流程 3 輪截圖審查累積最多 ~18,000 tokens，不構成溢出風險，但對成本有影響。

3. **最壞情況估算**：三層全管線（含 3 輪退件）的總 context 消耗估算：UX（~5K）+ UI × 4 輪（~32K）+ Vision Critic × 3 輪（~36K）= **~73K tokens**，遠低於 200K 限制，正常場景不會觸發 context 溢出。

4. **異常場景風險**：若 User Story 超長（>5,000 tokens）或 SSD JSON 異常複雜（>10,000 tokens），可能在退件迴圈末期接近限制，需備援截斷策略。

**結論**：在 Claude Sonnet 4.6 的 200K context window 下，標準使用場景不會觸發 context 溢出。管理策略以「防禦性設計」為主，為異常場景提供降級機制。

#### 候選方案比較

| 方案 | 描述 | 優點 | 缺點 |
|------|------|------|------|
| **方案 A：新對話隔離 + 結構化摘要接力（選定）** | 每層啟動獨立對話；VRR JSON 作為唯一層間傳遞媒介 | 每層 context 乾淨；易於推理和除錯；符合 SKILL.md 現有設計 | 層間無法共享對話上下文（但層間本不需要對話連續性） |
| 方案 B：單一長對話串接三層 | 三層 Agent 在同一對話中依序執行 | 保留完整對話歷史 | 退件迴圈後 context 快速膨脹；截圖三輪後累積 ~18K tokens 圖片 context；難以維護 |
| 方案 C：對話摘要（Summarization） | 每隔 N 輪自動呼叫 LLM 壓縮 context | 理論上無限擴展 | 需要額外 LLM 呼叫（成本增加）；摘要可能遺失關鍵退件細節；實作複雜度高 |

**決策**：選擇**方案 A（新對話隔離 + 結構化摘要接力）**。

**理由**：

1. **Claude Sonnet 4.6 的 200K context window 充足**：標準使用場景的最壞情況估算 ~73K tokens，遠低於 200K 限制。方案 A 的新對話隔離使每層實際 context 維持在 ≤20K，更為安全。

2. **符合現有 SKILL.md 設計**：三個 SKILL.md 均已定義以 JSON 工件（SSD JSON、VRR JSON）為層間傳遞格式，方案 A 與現有設計天然一致，無需修改 SKILL.md 核心邏輯。

3. **YAGNI 原則**：方案 C（對話摘要）引入額外 LLM 呼叫和複雜實作，在當前問題規模下屬過度工程（over-engineering）。方案 A 以簡單的「新對話 + JSON 傳遞」解決同樣的問題。

4. **可測試性**：每層獨立對話使各層的 context 邊界清晰，易於在測試場景中定義 budget 上限並驗證降級行為。

#### 各層 Context Budget（每次對話的 token 分配）

| 管線層 | Context Budget | 超出時降級行為 |
|--------|---------------|--------------|
| **UX Agent** | 系統提示（≤2K）+ User Story（≤5K）+ XML 隔離（≤0.5K）= **上限 7.5K** | 截斷 User Story 至 5K，輸出 `[UX-WARN] input truncated` |
| **UI Agent（每輪）** | 系統提示（≤2K）+ SSD JSON（≤5K）+ Design Tokens（≤1K）+ 退件報告摘要（≤3K）= **上限 11K** | 壓縮退件報告：僅保留 `issues[].description`，移除 `findings` 冗餘欄位；超出時僅保留最新一份 VRR |
| **Vision Critic（每輪）** | 系統提示（≤2K）+ SSD JSON（≤5K）+ PNG 截圖（≤10K）+ 歷史 VRR 摘要（≤3K）= **上限 20K** | 降低截圖解析度（1280×720 → 800×600 → 640×480）；640×480 仍超出時升級人工審查 |

**影響**：

- US-118（OQ-5 Context Window 管理策略 SKILL.md 實作）的 AC1/AC2/AC3 直接引用本決策：在三個 SKILL.md 中新增 Context Window 管理段落、定義各層 context budget、說明降級策略。
- Vision Critic SKILL.md §9.2「每次重試須帶入原始 SSD + 歷次 VRR」的實作方式確認為：**VRR JSON 的結構化摘要傳遞**（非對話 context 累積），與方案 A 一致。
- 退件報告 JSON Schema（§8.1）的 `findings` 詳細欄位設計為選填（`optional`），支援 UI Agent 降級時僅傳遞 `issues[]` 核心欄位。

---

## 影響

### 對現有 ADR 的影響

| ADR | 影響類型 | 說明 |
|-----|---------|------|
| ADR-006 | 延伸 | Vision Critic Agent 接收的截圖（外部視覺資料）需定義安全處理規則；截圖本身不含 LLM 可解析文字，注入風險低，但 MCP tool 輸出仍需 XML 隔離標記 |
| ADR-007 | 擴展 | Story Lifecycle Subagent 需新增「前端品質管線觸發」決策點：若 Story 涉及前端，自動觸發 UX Agent → UI Agent → Vision Critic Agent 管線 |
| ADR-011 | 補充 | CI 整合策略需考慮 Playwright 截圖步驟的 CI 環境需求（Phase 3）；Phase 1-2 不影響現有 CI 工作流 |
| ADR-013 | 相關 | Diagram Skill 的 stdio local 方案為本 ADR 的參考架構：局部 Agent 工具（UX/UI/Vision Critic Skill）優先採用 stdio local 整合模式 |

### 對 Shikigami 框架核心的影響

| 面向 | 影響 | 說明 |
|------|------|------|
| Backlog Intake | 需更新 | 前端相關 Story 需自動識別並注入設計約束 AC（Phase 1） |
| Story Lifecycle | 需更新 | 前端 Story 的 Done Definition 需包含 Design Tokens 符合性、元件庫合規性（Phase 1） |
| SDD 模板 | 需更新 | 新增「前端技術約束」章節：元件庫白名單、Design Tokens 引用、Human-in-the-loop 觸發條件 |
| Plugin marketplace | 不影響 | 現有插件架構不變；新 Agent 技能以 SKILL.md 形式納入現有插件體系 |

---

## 參考

- GitHub Issue #100：UIUX agent 功能需求（原始需求與四階段藍圖）
- ADR-006：Issue 內容提示注入防護（XML 隔離標記規則）
- ADR-007：Story Lifecycle Subagent 架構決策
- ADR-011：GitHub Actions 整合架構決策
- ADR-012：Claude Max 多開發環境認證架構決策
- ADR-013：shikigami:diagram MCP 整合架構決策（stdio local 參考模式）
- [Claude API — Vision capabilities](https://docs.anthropic.com/en/docs/build-with-claude/vision)（Claude Sonnet 4.6 多模態支援）
- [Playwright — Screenshots](https://playwright.dev/docs/screenshots)（自動截圖方案）
- [W3C Design Tokens Community Group](https://www.w3.org/community/design-tokens/)（Design Tokens 格式標準）
- [Shadcn UI](https://ui.shadcn.com/)（建議元件庫）
- [Tailwind CSS](https://tailwindcss.com/)（建議樣式框架）
- WCAG 2.1 AA（對比度審查標準，Vision Critic Agent 應用）
