# ADR-014：UIUX Agent 架構決策

**狀態**：Proposed
**日期**：2026-03-06
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
| OQ-1 | Playwright 截圖在 GitHub Actions self-hosted runner 的可行性 | 高 | 待解答 | self-hosted runner 的 headless browser 環境需確認；影響 Vision Critic Phase 3 的 CI 整合 |
| OQ-2 | Design Tokens 格式標準選型 | 高 | 待解答 | W3C Design Tokens Community Group 格式 vs. 自訂 JSON；影響與 UI Agent 的互通性 |
| OQ-3 | Vision Critic 審查的量化通過閾值定義 | 中 | 待解答 | PASS/FAIL 判定標準需量化（如對比度 WCAG AA、留白最小值）；避免主觀判定導致迴圈無法終止 |
| OQ-4 | UX Agent 骨架文件格式 JSON Schema 定義 | 中 | 待解答 | 需在 US-105 前確認骨架文件的標準結構，確保 UI Agent 可解析 |
| OQ-5 | 長對話 Context Window 管理策略 | 低 | 待解答 | Vision Critic 退件迴圈多輪後 context 可能超出限制；需定義截斷或摘要策略 |

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
