# Sprint 52

**狀態**：進行中
**期間**：2026-03-06 ~ 2026-03-12
**Sprint Goal**：建立 UIUX Agent 工作流的「防呆設計基礎」—— 定義機器可讀的 Design Tokens 規格、強制元件庫白名單，以及前端 Story AC 模板注入機制，使 ADR-014 Phase 1 具體落地。
**總計**：2 Stories / 2 Points

---

## Sprint Backlog

| Story ID | Issue # | 標題 | Size | Points | Phase | 狀態 |
|----------|---------|------|------|--------|-------|------|
| US-103 | #104 | Design Tokens 定義檔建立 | S | 1 | Phase 1 | 完成 |
| US-104 | #105 | 元件庫白名單 AC 注入機制 | S | 1 | Phase 1 | 待開發 |

**Sprint 容量**：2 Points

---

## 平行分群方案

| Phase | Stories | 說明 |
|-------|---------|------|
| Phase 1 | US-103、US-104 | 兩 Story 無檔案衝突，可完全並發執行 |

**並發可行性說明**：US-103 修改目標為建立 `docs/design/design-tokens.json` 與 `docs/templates/sdd-frontend-template.md`，以及更新 ADR-014；US-104 修改目標為更新 `skills/issue-management/SKILL.md`。兩者無共同修改檔案，無合併衝突風險。

---

## Story 詳細 AC

---

### US-103：Design Tokens 定義檔建立

**來源**：Issue #100（UIUX agent 功能需求）
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：Yes（純文件與 JSON 規格建立，無動態執行需求）
**ADR 依賴**：ADR-014（Sprint 51 已起草，Phase 1 具體落地）

**User Story**

As a Developer subagent, I want a machine-readable Design Tokens definition file and a frontend SDD template with constraint fields, so that UIUX Agent can consistently enforce design standards and ADR-014 Phase 1 is concretely implemented.

**背景**

ADR-014 決策了 UIUX Agent 工作流的四階段分期策略。Phase 1 的核心任務是建立「防呆設計基礎」：定義機器可讀的 Design Tokens 規格，讓後續所有前端 Story 在 AC 中能引用具名 token，禁止 hardcode 數值；同時建立 SDD 前端模板，將元件庫白名單與 Human-in-the-loop 觸發條件標準化。ADR-014 的 Open Question 2（OQ-2）關於 Token 格式選擇也需在本 Story 中一併決策並回填。

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | `design-tokens.json` 建立 | 建立 `docs/design/` 目錄，新建 `docs/design/design-tokens.json`，格式機器可讀（JSON），涵蓋主色（primary/secondary/danger/neutral）、字型（font-family、font-size scale）、圓角（border-radius scale）、間距（spacing scale）、陰影（shadow scale）五個核心設計變數群組，至少各含 3 個具名 token |
| AC2 | 靜態 | SDD 模板新增「前端技術約束」欄位 | 建立 `docs/templates/sdd-frontend-template.md`，包含「Frontend Constraints」區段：元件庫白名單欄位（預填 Tailwind CSS + Shadcn UI）、Design Tokens 引用路徑欄位、Human-in-the-loop 觸發條件欄位 |
| AC3 | 靜態 | ADR-014 OQ-2 解答 | 在 `docs/adr/ADR-014-uiux-agent-architecture.md` 的 OQ-2 填入格式決策：選擇自訂 JSON（YAGNI 原則），附理由；OQ-2 狀態從「待解答」更新為「已決策」 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響所有後續前端 Story 的 AC 規格（UIUX Agent Phase 1+） |
| Impact | 3 | 建立機器可讀規格基礎，使 Agent 能強制執行設計約束 |
| Confidence | 1.0 | 純文件建立，無技術不確定性 |
| Effort | 1 | S-size；JSON 規格建立 + SDD 模板 + ADR-014 OQ-2 回填 |
| **RICE Score** | **9.0** | R×I×C/E |

**Done 定義**

- [x] `docs/design/design-tokens.json` 已建立，涵蓋五個設計變數群組，各含 3+ 具名 token（AC1）
- [x] `docs/templates/sdd-frontend-template.md` 已建立，包含 Frontend Constraints 區段（AC2）
- [x] ADR-014 OQ-2 已填入自訂 JSON 決策，狀態更新為「已決策」（AC3）

---

### US-104：元件庫白名單 AC 注入機制

**來源**：Issue #100（UIUX agent 功能需求）
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：Yes（純 SKILL.md 規格更新，無動態執行需求）
**前置依賴**：US-103（邏輯上依賴 Design Tokens 路徑定義，但可並發執行）

**User Story**

As a Developer subagent executing issue-management, I want the SKILL.md to include frontend Story identification rules and auto-injected AC templates, so that any frontend Story automatically receives component library and Design Tokens compliance criteria without manual PO intervention.

**背景**

ADR-014 Phase 1 的第二個防呆機制是「AC 注入」：當 issue-management Skill 處理前端相關 Story 時，應自動識別並注入標準化的元件庫白名單和 Design Tokens 符合性 AC 條目。此機制讓 UIUX Agent 工作流從源頭就帶有設計約束，不需每次依賴人工填寫。本 Story 在 SKILL.md 中定義識別規則與注入模板。

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 前端 Story 識別規則定義 | 在 `skills/issue-management/SKILL.md` 新增「前端 Story 識別規則」段落，定義觸發條件（Story 標題或 body 含 UI / 前端 / frontend / component / 介面 / dashboard / 畫面 等關鍵字時觸發） |
| AC2 | 靜態 | 自動注入 AC 模板 | 定義前端 Story 觸發後應自動注入的 2 條標準 AC 條目：(a)「元件庫符合性：前端實作僅使用 Tailwind CSS 或 Shadcn UI 元件，禁止自訂 CSS」(b)「Design Tokens 符合性：所有顏色、圓角、間距值須引用 `docs/design/design-tokens.json` 中的具名 token，禁止 hardcode 數值」 |
| AC3 | 靜態 | Backlog Intake 流程指引更新 | 在 `skills/issue-management/SKILL.md` 的 Backlog Bridge 相關段落新增「前端 Story 辨識後 AC 注入」步驟說明 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響所有後續前端 Story 的自動入庫流程 |
| Impact | 3 | 從工作流源頭植入設計約束，減少人工干預與 AC 遺漏風險 |
| Confidence | 1.0 | 純 SKILL.md 文件更新，無技術不確定性 |
| Effort | 1 | S-size；SKILL.md 新增段落與規則定義 |
| **RICE Score** | **9.0** | R×I×C/E |

**Done 定義**

- [ ] `skills/issue-management/SKILL.md` 新增「前端 Story 識別規則」段落，含觸發關鍵字列表（AC1）
- [ ] SKILL.md 定義 2 條標準注入 AC 條目（元件庫符合性 + Design Tokens 符合性）（AC2）
- [ ] SKILL.md Backlog Bridge 段落新增「前端 Story 辨識後 AC 注入」步驟說明（AC3）

---

## ADR 觸發清單

| ADR | 觸發 Story | 觸發原因 | 狀態 |
|-----|-----------|---------|------|
| ADR-014 | US-103（#100） | OQ-2 Token 格式決策（自訂 JSON vs W3C/Style Dictionary），本 Sprint 回填 | Sprint 52 決策 |

---

## Sprint Planning 簽核記錄

| 角色 | 確認項目 | 狀態 |
|------|----------|------|
| Product Owner | Sprint Goal 對齊 ADR-014 Phase 1 落地；RICE Score 9.0 支持排序；2 Stories 無相依性適合並發 | 已確認 |
| Architect | US-103、US-104 均 S/1pt 合理；無檔案衝突可平行執行；無需額外 ADR | 已確認 |
| QA | US-103 doc-only 判定通過（JSON + Markdown 靜態驗證）；US-104 doc-only 判定通過（SKILL.md 靜態驗證） | 已確認 |
| Developer | US-103 Story 清晰度確認；US-104 SKILL.md 修改範疇確認 | 已確認 |

**Sprint Planning 決策記錄**

- Sprint 52 選入 2 Stories（US-103、US-104，均來自 Issue #100），共 2 Points
- Phase 1 並發：兩 Story 無檔案衝突，可同時執行（US-103 改 `docs/`，US-104 改 `skills/`）
- US-103、US-104 均為 ADR-014 Phase 1 具體落地，無架構不確定性
- 目標 Velocity：2 Points
- Issue #101（/plugin 間歇性載入失敗）持續觀察中，不排入本 Sprint
