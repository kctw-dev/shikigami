# Sprint 53

**狀態**：進行中
**期間**：2026-03-06 ~ 2026-03-12
**Sprint Goal**：完成 ADR-014 全部三個 Phase 的 SKILL.md 定義（UX Agent / UI Agent / Vision Critic），決策 OQ-1 與 OQ-3 開放問題，並設計三層 Agent 管線端對端整合測試規格，使 UIUX Agent 工作流從架構決策走向完整的可執行 Skill 定義。
**總計**：6 Stories / 10 Points（含 1 前置任務 0pt）

---

## Sprint Backlog

| Story ID | Issue # | 標題 | Size | Points | Phase | 狀態 |
|----------|---------|------|------|--------|-------|------|
| 前置任務 | — | ADR-014 Proposed → Accepted | — | 0 | 前置 | 完成 |
| US-105 | #112 | UX Agent SKILL.md 實作 | M | 2 | Phase 1 | 完成 |
| OQ-1 | #109 | Playwright 截圖可行性調查 | S | 1 | Phase 1 | 完成 |
| OQ-3 | #111 | Vision Critic 通過閾值量化決策 | S | 1 | Phase 1 | 完成 |
| US-106 | #113 | UI Agent SKILL.md 實作 | M | 2 | Phase 2 | 完成 |
| US-107 | #114 | Vision Critic Agent SKILL.md 實作 | M | 2 | Phase 2 | 完成 |
| US-108 | #115 | 三層 Agent 管線端對端整合測試設計 | M | 2 | Phase 3 | 進行中 |

**Sprint 容量**：10 Points

---

## 平行分群方案

| Phase | Stories | 說明 |
|-------|---------|------|
| Phase 1（可平行） | US-105、OQ-1、OQ-3 | 三者無共同修改檔案。US-105 建立 `skills/ux-agent/SKILL.md`（新目錄）；OQ-1 填入 ADR-014 OQ-1 區塊；OQ-3 填入 ADR-014 OQ-3 區塊。OQ-1 與 OQ-3 雖同修改 ADR-014，但位於不同章節，可序列快速完成 |
| Phase 2（序列） | US-106、US-107 | US-106 依賴 US-105 骨架文件 JSON Schema；US-107 依賴 OQ-1、OQ-3 決策結果。兩者在 Phase 1 完成後可平行執行 |
| Phase 3（序列） | US-108 | 依賴 US-105/106/107 全部完成後才能定義完整資料流測試規格 |

**並發可行性說明**：Phase 1 三個 Story 無共同修改檔案，可完全並發執行。Phase 2 的 US-106 和 US-107 目標檔案分別為 `skills/ui-agent/SKILL.md` 和 `skills/vision-critic/SKILL.md`，無衝突，可在 Phase 1 完成後同時執行。

---

## Story 詳細 AC

---

### 前置任務：ADR-014 Proposed → Accepted

**Owner**：Product Owner
**Points**：0（前置任務，不計 Velocity）

**完成條件**
- [x] `docs/adr/ADR-014-uiux-agent-architecture.md` 狀態欄從 Proposed 更新為 Accepted
- [x] Phase 1 完成佐證已補充（Sprint 52 交付 design-tokens.json + issue-management §12）

---

### US-105：UX Agent SKILL.md 實作

**來源**：Issue #100（UIUX agent 功能需求）→ ADR-014 Phase 2 識別
**Issue**：#112
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：Yes（純 SKILL.md 規格定義，無動態執行需求）
**ADR 依賴**：ADR-014（Phase 2，UX Agent 分工架構決策）、ADR-006（XML 隔離標記規則）

**User Story**

As a Developer subagent receiving a User Story, I want a well-defined UX Agent skill (shikigami:ux) that transforms User Story text into a structured semantic skeleton document (JSON), so that the UI Agent can reliably consume a machine-readable layout specification without ambiguity.

**背景**

ADR-014 Phase 2 的第一步：建立三層 Agent 管線的最上游——UX Agent。UX Agent 負責將功能性 User Story 轉化為無樣式的語意化資訊架構骨架，作為 UI Agent 的標準化輸入。本 Story 定義 UX Agent 的完整 SKILL.md，包含骨架文件 JSON Schema、ADR-006 XML 隔離標記套用點、designToken 型別欄位規格。

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | SKILL.md 建立 | 建立 `skills/ux-agent/SKILL.md`，定義 `shikigami:ux` 技能，輸入 User Story 文字，輸出語意化骨架文件（JSON） |
| AC2 | 靜態 | 骨架文件 JSON Schema | SKILL.md 中定義骨架文件 JSON Schema，涵蓋 sections（版面區塊）、component hierarchy（元件層級）、interactions（互動說明） |
| AC3 | 靜態 | designToken 型別欄位 | 骨架文件 Schema 中定義 `designToken` 型別欄位，值格式為 `{category}.{key}` 字串（如 `color.primary.500`），對應 `docs/design/design-tokens.json` 具名路徑 |
| AC4 | 靜態 | ADR-006 XML 隔離標記 | SKILL.md 輸入處理段落明確標示 ADR-006 XML 隔離標記套用點（User Story 文字輸入須以 XML tag 包覆隔離） |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響所有後續前端 Story 的 UX 規格化流程 |
| Impact | 3 | 建立 Agent 管線上游，決定骨架文件品質 |
| Confidence | 1.0 | 純文件定義，無技術不確定性 |
| Effort | 2 | M-size；SKILL.md 完整定義 + JSON Schema 設計 |
| **RICE Score** | **4.5** | R×I×C/E |

**Done 定義**

- [ ] `skills/ux-agent/SKILL.md` 已建立，定義 shikigami:ux 技能（AC1）
- [ ] 骨架文件 JSON Schema 已定義，涵蓋 sections、component hierarchy、interactions（AC2）
- [ ] designToken 型別欄位已定義，值格式為 `{category}.{key}`，對應 design-tokens.json（AC3）
- [ ] ADR-006 XML 隔離標記套用點已標示（AC4）

---

### OQ-1：Playwright 截圖可行性調查

**來源**：ADR-014 開放問題 OQ-1
**Issue**：#109
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：Yes（調查 + ADR 文件填入，無動態執行需求）
**ADR 依賴**：ADR-014 OQ-1（高優先級，阻塞 US-107）

**User Story**

As a Developer subagent executing Vision Critic Agent, I want a confirmed feasibility decision on Playwright screenshot automation in our GCP self-hosted runner, so that US-107 (Vision Critic SKILL.md) can define a concrete screenshot integration approach without ambiguity.

**背景**

ADR-014 OQ-1 標記為「高優先級、待解答」。Vision Critic Agent（US-107）的 SKILL.md 需明確引用截圖整合方式，因此 OQ-1 的可行性決策必須先於 US-107 完成。本 Story 調查 GCP self-hosted runner 環境需求並在 ADR-014 填入決策。ADR-014 已評估 Playwright + Base64 為 MVP 建議路徑，本 Story 負責確認此路徑的環境可行性。

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 環境需求清單 | 調查 GCP self-hosted runner 安裝 headless Chromium 的環境需求，產出需求清單（OS 套件、記憶體/CPU 需求、GitHub Actions runner 設定） |
| AC2 | 靜態 | ADR-014 OQ-1 填入決策 | 在 `docs/adr/ADR-014-uiux-agent-architecture.md` 的 OQ-1 填入可行性決策（可行/不可行），附理由；OQ-1 狀態從「待解答」更新為「已決策」 |
| AC3 | 靜態 | 最小 PoC 腳本 | 若 AC2 判定可行，提供最小 Playwright 截圖 PoC 腳本（Node.js），記錄於 ADR-014 OQ-1 說明區塊，本機驗證即可 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 2 | 影響 Vision Critic Agent Phase 3 整合 |
| Impact | 3 | 解決架構不確定性，OQ-1 阻塞 US-107 |
| Confidence | 1.0 | 技術調查，結果可確認 |
| Effort | 1 | S-size；文件調查 + ADR 填入 |
| **RICE Score** | **6.0** | R×I×C/E |

**Done 定義**

- [ ] GCP self-hosted runner headless Chromium 環境需求清單已產出（AC1）
- [ ] ADR-014 OQ-1 填入可行性決策，狀態更新為「已決策」（AC2）
- [ ] 若可行，最小 PoC 腳本已記錄（AC3）

---

### OQ-3：Vision Critic 通過閾值量化決策

**來源**：ADR-014 開放問題 OQ-3
**Issue**：#111
**Size**：S / 1 Point
**Owner**：Product Owner
**QA doc-only 判定**：Yes（決策定義 + ADR 文件填入，無動態執行需求）
**ADR 依賴**：ADR-014 OQ-3（中優先級，阻塞 US-107 AC3）

**User Story**

As a Product Owner defining quality gates, I want a quantified pass/fail threshold for Vision Critic visual consistency scoring, so that US-107 (Vision Critic SKILL.md) can specify objective acceptance criteria that prevent infinite feedback loops.

**背景**

ADR-014 OQ-3 標記為「中優先級、待解答」。Vision Critic Agent 的 PASS/FAIL 判定若缺乏量化標準，將導致退件迴圈無法收斂。本 Story 在 ADR-014 填入閾值決策，為 US-107 SKILL.md 的 AC3 提供直接依據。閾值設計參考 WCAG 2.1 AA 標準與業界 UI 測試實踐。

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 閾值定義 | 定義 Vision Critic 視覺一致性評分的通過/不通過閾值（百分比或分數制），含評分維度定義（元件位置、色彩一致性、間距合規性） |
| AC2 | 靜態 | ADR-014 OQ-3 填入決策 | 在 `docs/adr/ADR-014-uiux-agent-architecture.md` 的 OQ-3 填入閾值決策，附理由與參考基準（如 WCAG AA 對比度標準）；OQ-3 狀態從「待解答」更新為「已決策」 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 2 | 影響 Vision Critic Agent 品質閘門 |
| Impact | 3 | 解決量化標準缺失，防止迴圈無法收斂 |
| Confidence | 1.0 | 決策性 Story，無技術不確定性 |
| Effort | 1 | S-size；閾值研究 + ADR 填入 |
| **RICE Score** | **6.0** | R×I×C/E |

**Done 定義**

- [ ] Vision Critic 視覺一致性評分閾值已定義，含各維度標準（AC1）
- [ ] ADR-014 OQ-3 填入閾值決策，狀態更新為「已決策」（AC2）

---

### US-106：UI Agent SKILL.md 實作

**來源**：Issue #100（UIUX agent 功能需求）→ ADR-014 Phase 2 識別
**Issue**：#113
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：Yes（純 SKILL.md 規格定義，無動態執行需求）
**ADR 依賴**：ADR-014（Phase 2，UI Agent 分工架構決策）
**前置依賴**：US-105（需要骨架文件 JSON Schema 定義）

**User Story**

As a Developer subagent implementing frontend code, I want a well-defined UI Agent skill (shikigami:ui) that transforms the UX Agent's skeleton document into frontend code using only Tailwind CSS and Shadcn UI, so that all generated UI components are constrained to approved libraries and design tokens without requiring manual review of every implementation choice.

**背景**

ADR-014 Phase 2 的第二步：建立三層 Agent 管線的實作層——UI Agent。UI Agent 接收 UX Agent 的骨架文件（JSON），套用 Design Tokens 和元件庫白名單約束，輸出前端代碼片段。本 Story 定義 UI Agent 的完整 SKILL.md，與 US-105 骨架文件 JSON Schema 嚴格對齊，確保兩層 Agent 的輸入/輸出相容。

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | SKILL.md 建立 | 建立 `skills/ui-agent/SKILL.md`，定義 `shikigami:ui` 技能，輸入 UX Agent 骨架文件（JSON），輸出前端代碼片段 |
| AC2 | 靜態 | Design Tokens 注入規則 | 定義 Design Tokens 注入規則：顏色、圓角、間距值必須引用 `docs/design/design-tokens.json` 具名 token，禁止 hardcode 數值 |
| AC3 | 靜態 | 元件庫白名單約束 | 定義元件庫白名單約束（Tailwind CSS + Shadcn UI），與 US-104 §12 AC 注入條目對齊 |
| AC4 | 靜態 | 輸入格式對齊 | 輸入格式定義與 US-105 骨架文件 JSON Schema 一致，UI Agent 可直接解析 UX Agent 輸出 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響所有前端 Story 的代碼產出品質 |
| Impact | 3 | 強制 Design Tokens + 元件庫白名單，消除設計漂移 |
| Confidence | 1.0 | 純文件定義，依賴 US-105 Schema |
| Effort | 2 | M-size；SKILL.md 完整定義 + 注入規則設計 |
| **RICE Score** | **4.5** | R×I×C/E |

**Done 定義**

- [ ] `skills/ui-agent/SKILL.md` 已建立，定義 shikigami:ui 技能（AC1）
- [ ] Design Tokens 注入規則已定義，禁止 hardcode 數值（AC2）
- [ ] 元件庫白名單（Tailwind CSS + Shadcn UI）已定義，與 US-104 對齊（AC3）
- [ ] 輸入格式與 US-105 JSON Schema 一致（AC4）

---

### US-107：Vision Critic Agent SKILL.md 實作

**來源**：Issue #100（UIUX agent 功能需求）→ ADR-014 Phase 3 識別
**Issue**：#114
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：Yes（純 SKILL.md 規格定義，無動態執行需求）
**ADR 依賴**：ADR-014（Phase 3，Vision Critic Agent 決策）、ADR-006（截圖輸入的 XML 隔離標記）
**前置依賴**：OQ-1（截圖整合方式決策）、OQ-3（通過閾值量化決策）

**User Story**

As a Quality Assurance process in the three-layer agent pipeline, I want a well-defined Vision Critic Agent skill (shikigami:vision-critic) that evaluates screenshot images against skeleton document specifications, so that UI Agent output is objectively validated against visual quality thresholds before delivery to downstream backend integration.

**背景**

ADR-014 Phase 3 的核心交付：三層 Agent 管線的視覺審查層——Vision Critic Agent。Claude Sonnet 4.6 原生支援多模態輸入，模型能力面無阻塞性障礙。本 Story 依賴 OQ-1（Playwright 截圖可行性）和 OQ-3（通過閾值量化）的決策結果，在 SKILL.md 中明確定義截圖整合方式與量化通過標準。

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | SKILL.md 建立 | 建立 `skills/vision-critic/SKILL.md`，定義 `shikigami:vision-critic` 技能，輸入截圖影像 + 骨架文件 JSON，輸出視覺一致性評分 |
| AC2 | 靜態 | 視覺比對規則 | 定義視覺比對規則：元件位置、色彩一致性、間距合規性（三個維度） |
| AC3 | 靜態 | 通過/不通過閾值 | 定義通過/不通過閾值量化標準（與 OQ-3 決策對齊） |
| AC4 | 靜態 | Playwright 截圖整合 | SKILL.md 說明 Playwright 截圖整合方式（與 OQ-1 決策對齊） |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響所有前端 Story 的視覺品質保證 |
| Impact | 3 | 引入獨立視覺審查，解決自審偏差問題 |
| Confidence | 0.8 | 依賴 OQ-1/OQ-3 決策，有少量不確定性 |
| Effort | 2 | M-size；SKILL.md 完整定義 + 比對規則設計 |
| **RICE Score** | **3.6** | R×I×C/E |

**Done 定義**

- [ ] `skills/vision-critic/SKILL.md` 已建立，定義 shikigami:vision-critic 技能（AC1）
- [ ] 視覺比對規則已定義，涵蓋元件位置、色彩一致性、間距合規性（AC2）
- [ ] 通過/不通過閾值已定義，與 OQ-3 決策對齊（AC3）
- [ ] Playwright 截圖整合方式已說明，與 OQ-1 決策對齊（AC4）

---

### US-108：三層 Agent 管線端對端整合測試設計

**來源**：Issue #100（UIUX agent 功能需求）→ ADR-014 Phase 3 識別
**Issue**：#115
**Size**：M / 2 Points
**Owner**：QA Engineer
**QA doc-only 判定**：Yes（純測試規格文件定義，無動態執行需求）
**ADR 依賴**：ADR-014（Phase 3，三層管線整合）
**前置依賴**：US-105、US-106、US-107 全部先完成

**User Story**

As a Quality Assurance engineer validating the UIUX Agent workflow, I want a comprehensive end-to-end test specification document for the three-layer agent pipeline (UX → UI → Vision Critic), so that integration issues can be detected early and each layer's failure can be isolated independently.

**背景**

ADR-014 Phase 3 的收尾：在三層 SKILL.md 均定義完成後，建立端對端整合測試規格文件（SDD-UIUX-E2E.md）。本 Story 定義完整資料流測試案例、mock 資料格式、以及各層失敗時的降級策略，為後續實際整合測試打下規格基礎，使工作流「從架構決策走向完整的可執行 Skill 定義」的目標最終閉環。

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | E2E 測試規格文件 | 建立 `docs/sdd/SDD-UIUX-E2E.md`，定義三層管線（UX → UI → Vision Critic）的端對端測試規格 |
| AC2 | 靜態 | 測試案例模板 | 定義測試案例模板：輸入 User Story → 骨架文件 → 代碼片段 → 截圖 → 視覺評分的完整資料流 |
| AC3 | 靜態 | mock 資料與預期輸出 | 定義 mock 資料與預期輸出格式，供後續實際整合測試使用 |
| AC4 | 靜態 | 降級策略 | 定義測試失敗的降級策略：哪一層失敗時如何隔離問題（UX 層失敗 / UI 層失敗 / Vision Critic 層失敗各自處理方式） |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 涵蓋整個三層 Agent 管線品質保證 |
| Impact | 3 | 建立可執行測試規格，使後續整合可驗證 |
| Confidence | 1.0 | 純文件定義，依賴 US-105/106/107 |
| Effort | 2 | M-size；E2E 測試規格文件設計 |
| **RICE Score** | **4.5** | R×I×C/E |

**Done 定義**

- [ ] `docs/sdd/SDD-UIUX-E2E.md` 已建立，定義三層管線 E2E 測試規格（AC1）
- [ ] 測試案例模板已定義，涵蓋完整資料流（AC2）
- [ ] mock 資料與預期輸出格式已定義（AC3）
- [ ] 降級策略已定義，三層各自失敗處理方式已說明（AC4）

---

## ADR 觸發清單

| ADR | 觸發 Story | 觸發原因 | 狀態 |
|-----|-----------|---------|------|
| ADR-014 | 前置任務 | Phase 1 完成佐證補充，ADR-014 狀態從 Proposed 升為 Accepted | Sprint 53 前置決策 |
| ADR-014 | OQ-1（#109） | 填入 Playwright 截圖可行性決策，OQ-1 從「待解答」升為「已決策」 | Sprint 53 目標 |
| ADR-014 | OQ-3（#111） | 填入 Vision Critic 通過閾值決策，OQ-3 從「待解答」升為「已決策」 | Sprint 53 目標 |

---

## Sprint Planning 簽核記錄

| 角色 | 確認項目 | 狀態 |
|------|----------|------|
| Product Owner | Sprint Goal 對齊 ADR-014 Phase 2/3 落地；6 Stories 總計 10 points；平行分群策略合理；RICE Score 支持優先順序排列 | 已確認 |
| Architect | US-105/106/107 均 M/2pt 合理；OQ-1/OQ-3 均 S/1pt 合理；US-108 M/2pt 合理；Phase 1 三 Story 無檔案衝突可平行；Phase 2 兩 Story 無衝突可平行；ADR-014 前置任務 0pt 合理 | 已確認 |
| QA | US-105/106/107/108 doc-only 判定通過（SKILL.md + SDD 靜態驗證）；OQ-1/OQ-3 doc-only 判定通過（ADR 靜態驗證）；前置任務 doc-only 判定通過 | 已確認 |
| Developer | US-105 Story 清晰度確認（骨架文件 JSON Schema 設計方向明確）；US-106 依賴 US-105 Schema 已說明；US-107 依賴 OQ-1/OQ-3 已說明；US-108 依賴全部 Phase 1/2 Story 已說明 | 已確認 |

**Sprint Planning 決策記錄**

- Sprint 53 選入 6 Stories（含 1 前置任務 0pt），共 10 Points
- 前置任務：ADR-014 Proposed → Accepted，在 Sprint 開始時即執行（PO 直接完成）
- Phase 1 並發：US-105、OQ-1、OQ-3 無檔案衝突，可同時執行
- OQ-1 與 OQ-3 雖同修改 ADR-014，但位於不同章節（OQ-1 區塊 vs OQ-3 區塊），可序列快速完成（各 5-10 分鐘）
- Phase 2 並發：US-106（`skills/ui-agent/SKILL.md`）與 US-107（`skills/vision-critic/SKILL.md`）無衝突，Phase 1 完成後可平行執行
- Phase 3 序列：US-108 需等 Phase 2 全部完成，方可定義完整資料流測試規格
- 目標 Velocity：10 Points
- Issue #101（/plugin 間歇性載入失敗）持續觀察中，不排入本 Sprint
- 本 Sprint 不 bump version（遵循連續衝刺策略，減少 plugin 快取失效風險）
