# Sprint 54

**狀態**：進行中
**期間**：2026-03-06 ~ 2026-03-12
**Sprint Goal**：完成 ADR-014 全部開放問題（OQ-4/OQ-5）的正式決策，建立三層 UIUX 管線的端對端可執行測試腳本與 CI 整合框架，並對齊三個 SKILL.md 的 CLI 輸出標準，使 UIUX Agent 管線從文件規格走向可驗證的整合工件。
**總計**：29 Stories / 50 Points

---

## Sprint Backlog

| Story ID | Issue # | 標題 | Size | Points | doc-only | 狀態 |
|----------|---------|------|------|--------|----------|------|
| US-109 | #116 | CLI 輸出設計原則符合性評估 | M | 2 | 是 | 完成 |
| US-110 | #117 | ADR-014 OQ-4 骨架文件 JSON Schema 標準化決策 | S | 1 | 是 | 待開始 |
| US-111 | #118 | Vision Critic PoC 腳本建立 | M | 2 | 否 | 待開始 |
| US-112 | #119 | UX Agent 實際觸發驗證 | M | 2 | 否 | 待開始 |
| US-113 | #120 | UI Agent Design Tokens 注入驗證 | M | 2 | 否 | 待開始 |
| US-114 | #121 | Playwright CI 整合腳本建立 | L | 3 | 否 | 待開始 |
| US-115 | #122 | SDD-UIUX-E2E TC-001 Happy Path 端對端驗證 | L | 3 | 否 | 待開始 |
| US-116 | #107 | UIUX Agent 模型分層策略調查 | S | 1 | 是 | 完成 |
| US-117 | #141 | ADR-014 OQ-4 骨架文件 Schema 標準化 | S | 1 | 是 | 待開始 |
| US-118 | #142 | ADR-014 OQ-5 Context Window 管理策略 | S | 1 | 是 | 待開始 |
| US-119 | #123 | UIUX Agent 使用者文件補充 | M | 2 | 是 | 待開始 |
| US-120 | #124 | SDD 前端模板 Done Definition 更新 | S | 1 | 是 | 待開始 |
| US-121 | #108 | Gemini CLI 能力邊界調查 | S | 1 | 是 | 待開始 |
| US-122 | #125 | Playwright 截圖 PoC 腳本正式化 | S | 1 | 否 | 待開始 |
| US-123 | #126 | SDD-UIUX-E2E TC-02 退件迴圈腳本建立 | L | 3 | 否 | 待開始 |
| US-124 | #127 | SDD-UIUX-E2E TC-03 條件通過邊界測試腳本 | M | 2 | 否 | 待開始 |
| US-125 | #128 | ADR-014 OQ-4 正式決策文件 | S | 1 | 是 | 完成 |
| US-126 | #129 | ADR-014 OQ-5 Context Window 管理決策 | S | 1 | 是 | 完成 |
| US-127 | #130 | ADR-007 延伸 — 前端 Story 觸發 UIUX 管線決策點 | M | 2 | 是 | 待開始 |
| US-128 | #131 | Vision Critic 退件報告儲存機制 | S | 1 | 是 | 完成 |
| US-129 | #132 | UX Agent SKILL.md CLI 輸出設計符合性審查 | M | 2 | 是 | 待開始 |
| US-130 | #133 | UI Agent CLI 輸出設計符合性審查 | M | 2 | 是 | 待開始 |
| US-131 | #134 | Vision Critic CLI 輸出設計符合性審查 | S | 1 | 是 | 待開始 |
| US-132 | #135 | 設計 Token 版本控制機制建立 | M | 2 | 是 | 完成 |
| US-133 | #136 | SDD-UIUX-E2E TC-04 UX Agent 輸入驗證測試腳本 | S | 1 | 否 | 待開始 |
| US-134 | #137 | UIUX Agent 三層管線整合文件補充 | M | 2 | 是 | 待開始 |
| US-135 | #138 | SDD 前端模板 Design Token 路徑驗證規則 | S | 1 | 是 | 完成 |
| US-136 | #139 | Issue #107 UIUX Agent 模型分層策略實作規劃 | S | 1 | 是 | 完成 |
| US-137 | #140 | UIUX 管線 CI GitHub Action 整合框架 | L | 3 | 否 | 待開始 |

**Sprint 容量**：50 Points

---

## 平行分群方案

| Phase | Stories | 說明 |
|-------|---------|------|
| Phase 1（並行，8pt） | US-125, US-126, US-128, US-132, US-135, US-136 | 無共同修改檔案，可完全並發。US-125/126 填入 ADR-014 OQ-4/OQ-5 正式決策；US-128 定義退件報告儲存機制；US-132 建立 design-tokens 版本控制；US-135 補充 SDD 路徑驗證規則；US-136 完成模型分層實作規劃 |
| Phase 2 Group A（並行） | US-109, US-110, US-116, US-119, US-120, US-121, US-122, US-133 | 各自獨立，無前置依賴。並發可執行 |
| Phase 2 Group B（序列） | US-117, US-118, US-129, US-130, US-131 | 依賴 OQ-4/OQ-5 決策（Phase 1）及 US-109 CLI 設計原則報告（Group A） |
| Phase 2 Group C（並行） | US-111, US-112, US-127 | 無共同修改檔案，可並發 |
| Phase 3（序列） | US-113, US-123, US-124, US-134 | 依賴 US-116 模型策略、US-115 TC-01、Phase 2 完成 |
| Phase 4（序列） | US-114, US-115, US-137 | 依賴 Phase 3 完成；US-114 Playwright CI 腳本、US-115 TC-001 Happy Path、US-137 CI GitHub Action |

---

## Story 詳細 AC

---

### US-109：CLI 輸出設計原則符合性評估

**來源**：Issue #116（UIUX Agent 框架 CLI 輸出設計原則符合性）
**Issue**：#116
**Size**：M / 2 Points
**Owner**：Product Owner
**QA doc-only 判定**：Yes（純評估報告，無動態執行需求）
**ADR 依賴**：ADR-014（三層管線 CLI 輸出規格）

**User Story**

As a Product Owner overseeing UIUX Agent CLI output quality, I want to evaluate whether all three agent skills (shikigami:ux, shikigami:ui, shikigami:vision-critic) conform to established CLI output design principles, so that I have a baseline assessment to drive alignment work in US-129/130/131.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 評估報告建立 | 產出 CLI 輸出設計原則符合性評估報告，涵蓋三層管線各技能 |
| AC2 | 靜態 | 不符合項目清單 | 列出每個技能的不符合設計原則項目，含具體改善建議 |
| AC3 | 靜態 | 優先順序排序 | 不符合項目依影響範圍排序，指引 US-129/130/131 執行順序 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響三層管線所有使用者的 CLI 體驗 |
| Impact | 2 | 建立基線評估，驅動後續對齊工作 |
| Confidence | 1.0 | 純文件評估，無技術不確定性 |
| Effort | 2 | M-size；三個 SKILL.md 逐一評估 |
| **RICE Score** | **3.0** | R×I×C/E |

**Done 定義**

- [x] CLI 輸出設計原則符合性評估報告已產出（AC1）
- [x] 三層管線不符合項目清單已列出，含改善建議（AC2）
- [x] 不符合項目已依影響範圍排序（AC3）

---

### US-110：ADR-014 OQ-4 骨架文件 JSON Schema 標準化決策

**來源**：ADR-014 開放問題 OQ-4
**Issue**：#117
**Size**：S / 1 Point
**Owner**：Product Owner
**QA doc-only 判定**：Yes（決策調查 + ADR 文件填入）
**ADR 依賴**：ADR-014 OQ-4（阻塞 US-117）

**User Story**

As a Product Owner resolving ADR-014 open questions, I want to investigate and decide on the JSON Schema standardization approach for skeleton documents, so that US-117 can implement a formal schema with a clear authoritative decision backing.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 調查 JSON Schema 標準選項 | 比較 JSON Schema Draft-07 / Draft-2020-12 / OpenAPI 3.1 等選項，產出比較分析 |
| AC2 | 靜態 | ADR-014 OQ-4 填入初步決策方向 | 在 ADR-014 OQ-4 區塊填入調查結論與推薦方向，供 US-125 正式決策參考 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響骨架文件 Schema 驗證機制 |
| Impact | 3 | 解決 OQ-4 不確定性，阻塞 US-117 |
| Confidence | 1.0 | 調查性 Story，結果可確認 |
| Effort | 1 | S-size；標準比較調查 |
| **RICE Score** | **9.0** | R×I×C/E |

**Done 定義**

- [ ] JSON Schema 標準選項比較分析已完成（AC1）
- [ ] ADR-014 OQ-4 初步決策方向已填入（AC2）

---

### US-111：Vision Critic PoC 腳本建立

**來源**：Sprint 54 Planning（Architect 識別）
**Issue**：#118
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：No（需實作 PoC 腳本，TDD）
**ADR 依賴**：ADR-014 OQ-1（截圖整合方式）、ADR-014 OQ-3（通過閾值）

**User Story**

As a QA engineer validating the Vision Critic Agent, I want a working PoC script that demonstrates screenshot-based visual validation, so that the E2E pipeline can be verified against real screenshot inputs.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 動態 | PoC 腳本建立 | 建立 `scripts/vision-critic-poc.js`，可接受截圖路徑與骨架文件 JSON 作為輸入 |
| AC2 | 動態 | 輸出視覺評分 | 腳本輸出視覺一致性評分（0~100），並標示 PASS/FAIL 判定 |
| AC3 | 靜態 | 執行說明文件 | 附 README 說明執行方式與環境需求 |
| AC4 | 動態 | TDD | 先寫測試案例，再實作腳本 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 驗證 Vision Critic 核心功能可行性 |
| Impact | 3 | PoC 確認後解除 E2E 測試阻塞 |
| Confidence | 0.8 | 依賴 OQ-1/OQ-3 決策 |
| Effort | 2 | M-size；腳本實作 + TDD |
| **RICE Score** | **3.6** | R×I×C/E |

**Done 定義**

- [ ] `scripts/vision-critic-poc.js` 已建立並可執行（AC1）
- [ ] 視覺評分輸出（0~100）與 PASS/FAIL 判定正確（AC2）
- [ ] 執行說明 README 已附上（AC3）
- [ ] 測試案例先於腳本實作完成（AC4）

---

### US-112：UX Agent 實際觸發驗證

**來源**：Sprint 54 Planning（Architect 識別）
**Issue**：#119
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：No（需實際觸發技能執行）
**ADR 依賴**：ADR-014（US-105 UX Agent SKILL.md）

**User Story**

As a Developer validating the UX Agent skill, I want to trigger shikigami:ux with a real User Story input and verify the skeleton document output conforms to the JSON Schema, so that the first layer of the UIUX pipeline is confirmed operational.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 動態 | 技能觸發 | 提供標準 User Story 輸入，觸發 shikigami:ux 技能執行 |
| AC2 | 動態 | Schema 驗證 | 輸出骨架文件 JSON 可通過 JSON Schema 驗證（US-105 定義的 Schema） |
| AC3 | 靜態 | 執行記錄 | 驗證結果記錄於 `docs/sdd/SDD-UIUX-E2E.md` TC-001 執行記錄欄位 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 確認管線第一層可用性 |
| Impact | 3 | 觸發驗證是 E2E 前提 |
| Confidence | 0.9 | 依賴 SKILL.md 已完整定義 |
| Effort | 2 | M-size；實際觸發 + Schema 驗證 |
| **RICE Score** | **4.05** | R×I×C/E |

**Done 定義**

- [ ] shikigami:ux 技能已成功觸發並回傳骨架文件（AC1）
- [ ] 骨架文件 JSON 通過 Schema 驗證（AC2）
- [ ] 執行記錄已寫入 SDD-UIUX-E2E.md TC-001（AC3）

---

### US-113：UI Agent Design Tokens 注入驗證

**來源**：Sprint 54 Planning（Architect 識別）
**Issue**：#120
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：No（需實際觸發技能並驗證產出）
**ADR 依賴**：ADR-014（US-106 UI Agent SKILL.md）
**前置依賴**：US-116（模型分層策略確認後執行）

**User Story**

As a Developer validating the UI Agent skill, I want to verify that shikigami:ui correctly injects Design Tokens from design-tokens.json when generating frontend code from a skeleton document, so that hardcoded values are eliminated and token references are confirmed.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 動態 | 技能觸發 | 提供標準骨架文件 JSON 輸入，觸發 shikigami:ui 技能執行 |
| AC2 | 動態 | Token 注入驗證 | 輸出的前端代碼不含 hardcode 顏色/間距數值，所有樣式引用 design-tokens.json 中的具名 token |
| AC3 | 動態 | 多類別驗證 | 驗證至少 3 個 Design Token 類別（color、spacing、radius）正確注入 |
| AC4 | 靜態 | 執行記錄 | 驗證結果記錄於 SDD-UIUX-E2E.md TC-001 執行記錄 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 確認 Design Token 約束有效執行 |
| Impact | 3 | 消除設計漂移的關鍵驗證 |
| Confidence | 0.9 | 依賴 US-116 模型策略 |
| Effort | 2 | M-size；實際觸發 + Token 驗證 |
| **RICE Score** | **4.05** | R×I×C/E |

**Done 定義**

- [ ] shikigami:ui 技能已成功觸發並回傳前端代碼（AC1）
- [ ] 前端代碼不含 hardcode 數值（AC2）
- [ ] 至少 3 個 Token 類別注入驗證通過（AC3）
- [ ] 執行記錄已寫入 SDD-UIUX-E2E.md（AC4）

---

### US-114：Playwright CI 整合腳本建立

**來源**：Sprint 54 Planning（Architect 識別）
**Issue**：#121
**Size**：L / 3 Points
**Owner**：Developer
**QA doc-only 判定**：No（需實作 CI 腳本，TDD）
**ADR 依賴**：ADR-014 OQ-1（GCP self-hosted runner 可行性）
**前置依賴**：Phase 3 完成

**User Story**

As a CI/CD engineer automating visual validation, I want a Playwright script that captures screenshots in the GitHub Actions environment, so that Vision Critic can receive consistent screenshot inputs without manual intervention.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 動態 | 截圖腳本建立 | 建立 `scripts/playwright-screenshot.js`，可在 headless 模式下截取指定 URL 或 HTML 檔案的截圖 |
| AC2 | 動態 | GCP runner 相容 | 腳本可在 GCP self-hosted runner 上成功執行（依據 OQ-1 決策） |
| AC3 | 動態 | Base64 輸出 | 截圖輸出為 PNG，存放於指定路徑，Base64 編碼供 Vision Critic 消費 |
| AC4 | 動態 | TDD | 先定義測試案例，再實作腳本 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響所有前端 Story 的 CI 視覺驗證 |
| Impact | 3 | CI 自動化截圖是 US-137 的基礎 |
| Confidence | 0.8 | 依賴 GCP runner 環境 |
| Effort | 3 | L-size；CI 腳本 + TDD + 環境測試 |
| **RICE Score** | **2.4** | R×I×C/E |

**Done 定義**

- [ ] `scripts/playwright-screenshot.js` 已建立並可執行（AC1）
- [ ] GCP self-hosted runner 上執行驗證通過（AC2）
- [ ] Base64 PNG 輸出格式正確（AC3）
- [ ] 測試案例先於腳本實作完成（AC4）

---

### US-115：SDD-UIUX-E2E TC-001 Happy Path 端對端驗證

**來源**：Sprint 54 Planning（Architect 識別）
**Issue**：#122
**Size**：L / 3 Points
**Owner**：QA Engineer
**QA doc-only 判定**：No（需執行 E2E 測試，TDD）
**ADR 依賴**：ADR-014（三層管線整合）
**前置依賴**：Phase 3 完成（US-113、US-123、US-124、US-134）

**User Story**

As a QA engineer validating the complete UIUX pipeline, I want to execute TC-001 Happy Path end-to-end test that runs User Story → UX Agent → UI Agent → Vision Critic in sequence, so that the three-layer pipeline integration is confirmed operational.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 動態 | TC-001 執行 | 依據 SDD-UIUX-E2E.md TC-001 規格，執行完整三層管線 Happy Path |
| AC2 | 動態 | 全層通過 | 所有三層輸出符合各自 AC（骨架文件 Schema 合規、Design Token 注入、視覺評分 PASS） |
| AC3 | 靜態 | 執行記錄 | 執行結果記錄於 SDD-UIUX-E2E.md TC-001 執行記錄 |
| AC4 | 動態 | TDD | 先確認測試案例輸入/輸出規格，再執行驗證 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 涵蓋整個三層管線 Happy Path 驗證 |
| Impact | 3 | 端對端確認管線可運作 |
| Confidence | 0.8 | 依賴所有前置 Story 完成 |
| Effort | 3 | L-size；E2E 執行 + TDD |
| **RICE Score** | **2.4** | R×I×C/E |

**Done 定義**

- [ ] TC-001 Happy Path 完整執行無報錯（AC1）
- [ ] 三層輸出均通過各自驗收標準（AC2）
- [ ] 執行記錄已寫入 SDD-UIUX-E2E.md（AC3）
- [ ] 測試規格先於執行確認完成（AC4）

---

### US-116：UIUX Agent 模型分層策略調查

**來源**：Issue #107（UIUX Agent 模型分層策略）
**Issue**：#107
**Size**：S / 1 Point
**Owner**：Architect
**QA doc-only 判定**：Yes（調查報告，無動態執行需求）
**ADR 依賴**：ADR-014（模型使用策略）

**User Story**

As an Architect designing the UIUX Agent pipeline, I want to investigate the optimal model tiering strategy for each layer (UX Agent / UI Agent / Vision Critic), so that high-reasoning tasks use high-capability models while routine generation tasks use cost-effective models.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 各層任務複雜度分析 | 分析三層管線各層的任務複雜度（推理需求、創意需求、驗證需求） |
| AC2 | 靜態 | 模型推薦清單 | 產出每層推薦模型（或模型類型）清單，附成本/品質權衡說明 |
| AC3 | 靜態 | ADR-014 填入 | 將模型分層策略建議填入 ADR-014 相關區塊 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響三層管線的模型選用成本與品質 |
| Impact | 2 | 策略調查；實際成本優化在 US-136 |
| Confidence | 1.0 | 調查性 Story，無技術不確定性 |
| Effort | 1 | S-size；模型比較分析 |
| **RICE Score** | **6.0** | R×I×C/E |

**Done 定義**

- [x] 三層管線任務複雜度分析已完成（AC1）
- [x] 模型推薦清單已產出（AC2）
- [x] ADR-014 相關區塊已填入建議（AC3）

---

### US-117：ADR-014 OQ-4 骨架文件 Schema 標準化

**來源**：Sprint 54 Planning（US-110 後置）
**Issue**：#141
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：Yes（Schema 文件建立）
**ADR 依賴**：ADR-014 OQ-4（US-125 正式決策）
**前置依賴**：US-110 → US-125

**User Story**

As a Developer implementing the UX Agent, I want the skeleton document JSON Schema to be formally standardized with a versioned schema definition file, so that all agents consuming the skeleton document can validate inputs against a single authoritative source.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | Schema 文件建立 | 建立 `docs/schemas/skeleton-document-schema.json` 作為骨架文件 JSON Schema 的標準定義 |
| AC2 | 靜態 | Schema 版本化 | Schema 包含 `$schema` 和 `version` 欄位 |
| AC3 | 靜態 | SKILL.md 引用更新 | UX Agent 和 UI Agent SKILL.md 引用此標準 Schema 路徑 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 所有消費骨架文件的元件均受影響 |
| Impact | 3 | 建立唯一權威 Schema 來源 |
| Confidence | 1.0 | 純文件定義，依賴 OQ-4 決策 |
| Effort | 1 | S-size；Schema 文件建立 |
| **RICE Score** | **9.0** | R×I×C/E |

**Done 定義**

- [ ] `docs/schemas/skeleton-document-schema.json` 已建立（AC1）
- [ ] Schema 含版本欄位（AC2）
- [ ] 兩個 SKILL.md 已更新引用路徑（AC3）

---

### US-118：ADR-014 OQ-5 Context Window 管理策略

**來源**：Sprint 54 Planning（US-126 後置）
**Issue**：#142
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：Yes（SKILL.md 文件更新）
**ADR 依賴**：ADR-014 OQ-5（US-126 決策）
**前置依賴**：US-126

**User Story**

As a Developer implementing multi-agent pipelines, I want OQ-5 Context Window management strategy to be implemented in the SKILL.md files, so that the pipeline does not fail due to context overflow when processing large User Stories through all three layers.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | SKILL.md 更新 | 依據 US-126 OQ-5 決策，在三個 SKILL.md 中新增 Context Window 管理說明段落 |
| AC2 | 靜態 | Context Budget | 定義每層的 context budget（預估 token 分配） |
| AC3 | 靜態 | 降級策略 | 說明 context 超出時的降級策略（截斷規則或分段處理） |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響所有使用三層管線的場景 |
| Impact | 2 | 防止 context overflow 失敗 |
| Confidence | 0.9 | 依賴 OQ-5 決策 |
| Effort | 1 | S-size；三個 SKILL.md 補充段落 |
| **RICE Score** | **5.4** | R×I×C/E |

**Done 定義**

- [ ] 三個 SKILL.md 已新增 Context Window 管理段落（AC1）
- [ ] 每層 context budget 已定義（AC2）
- [ ] 降級策略已說明（AC3）

---

### US-119：UIUX Agent 使用者文件補充

**來源**：Sprint 54 Planning（Architect 識別）
**Issue**：#123
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：Yes（使用者文件建立）

**User Story**

As a developer onboarding to the UIUX Agent workflow, I want comprehensive user documentation that explains how to invoke each agent in the three-layer pipeline, so that I can use shikigami:ux, shikigami:ui, and shikigami:vision-critic without reading the internal SKILL.md files.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 使用者文件建立 | 更新 README.md 或建立 `docs/guides/uiux-agent-guide.md`，說明三層管線各技能的調用方式 |
| AC2 | 靜態 | 完整範例 | 包含完整範例：從 User Story 輸入到最終視覺評分的逐步操作流程 |
| AC3 | 靜態 | 前置需求說明 | 說明前置需求（design-tokens.json 路徑、Playwright 環境） |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 所有新使用者 onboarding 均受益 |
| Impact | 2 | 降低使用門檻 |
| Confidence | 1.0 | 純文件建立 |
| Effort | 2 | M-size；完整使用者指南 |
| **RICE Score** | **3.0** | R×I×C/E |

**Done 定義**

- [ ] 使用者文件已建立或更新（AC1）
- [ ] 完整逐步範例已包含（AC2）
- [ ] 前置需求已說明（AC3）

---

### US-120：SDD 前端模板 Done Definition 更新

**來源**：Sprint 54 Planning（PO 識別）
**Issue**：#124
**Size**：S / 1 Point
**Owner**：Product Owner
**QA doc-only 判定**：Yes（模板文件更新）

**User Story**

As a Product Owner defining frontend Story completion criteria, I want the SDD frontend template to include UIUX Agent pipeline as a mandatory gate in the Done Definition, so that all future frontend Stories must pass the three-layer visual validation before being marked complete.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | Done Definition 更新 | 更新 `docs/sdd/SDD-frontend-template.md`，在 Done Definition 中新增 UIUX Agent 管線通過作為必要條件 |
| AC2 | 靜態 | 條件明確列出 | Done Definition 明確列出：UX Agent 骨架文件 Schema 合規、UI Agent Design Token 注入、Vision Critic PASS |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 4 | 所有未來前端 Story 均受影響 |
| Impact | 2 | 強制管線通過作為完成條件 |
| Confidence | 1.0 | 純模板更新 |
| Effort | 1 | S-size；Done Definition 條件新增 |
| **RICE Score** | **8.0** | R×I×C/E |

**Done 定義**

- [ ] SDD-frontend-template.md Done Definition 已更新（AC1）
- [ ] 三層管線通過條件已明確列出（AC2）

---

### US-121：Gemini CLI 能力邊界調查

**來源**：Issue #108（多 AI CLI 協作策略）
**Issue**：#108
**Size**：S / 1 Point
**Owner**：Architect
**QA doc-only 判定**：Yes（調查報告）
**ADR 依賴**：ADR-014（多模型協作策略參考）

**User Story**

As an Architect evaluating multi-CLI collaboration, I want to investigate Gemini CLI's capability boundaries in the context of UIUX Agent tasks, so that we can make informed decisions about when Gemini CLI adds value versus when Claude Code handles everything.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 能力邊界調查 | 調查 Gemini CLI 在三層管線各任務中的能力邊界（UX 分析、UI 代碼生成、視覺評分） |
| AC2 | 靜態 | 協作場景定義 | 定義 Claude Code + Gemini CLI 最有價值的協作場景（若有）|
| AC3 | 靜態 | 決策建議 | 產出是否整合 Gemini CLI 的決策建議，附 RICE 評估 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響多 AI 協作策略方向 |
| Impact | 2 | 調查性 Story，實際整合為後續決策 |
| Confidence | 1.0 | 調查性 Story |
| Effort | 1 | S-size；能力邊界文獻調查 |
| **RICE Score** | **6.0** | R×I×C/E |

**Done 定義**

- [ ] Gemini CLI 能力邊界調查已完成（AC1）
- [ ] 協作場景已定義（AC2）
- [ ] 決策建議已產出（AC3）

---

### US-122：Playwright 截圖 PoC 腳本正式化

**來源**：Sprint 54 Planning（OQ-1 後置）
**Issue**：#125
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：No（需修改腳本代碼）

**User Story**

As a Developer building on the OQ-1 PoC, I want to formalize the Playwright screenshot PoC script into a reusable module with proper error handling and documentation, so that the CI integration in US-114 can build on a stable foundation.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 動態 | 腳本正式化 | 將 OQ-1 PoC 腳本正式化為 `scripts/playwright-poc-formal.js`，加入錯誤處理和參數驗證 |
| AC2 | 靜態 | JSDoc 文件 | 腳本包含 JSDoc 文件說明 |
| AC3 | 靜態 | npm script | 提供 npm script 入口點於 package.json（若適用） |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | US-114 CI 腳本的基礎 |
| Impact | 2 | 提升 PoC 可靠性和可重用性 |
| Confidence | 1.0 | 正式化既有 PoC |
| Effort | 1 | S-size；腳本重構 + 文件補充 |
| **RICE Score** | **6.0** | R×I×C/E |

**Done 定義**

- [ ] `scripts/playwright-poc-formal.js` 已建立，含錯誤處理（AC1）
- [ ] JSDoc 文件已補充（AC2）
- [ ] npm script 入口點已設定（AC3）

---

### US-123：SDD-UIUX-E2E TC-02 退件迴圈腳本建立

**來源**：Sprint 54 Planning（Architect 識別）
**Issue**：#126
**Size**：L / 3 Points
**Owner**：QA Engineer
**QA doc-only 判定**：No（需建立測試腳本，TDD）
**前置依賴**：Phase 3 部分完成

**User Story**

As a QA engineer validating pipeline resilience, I want a test script for TC-02 that exercises the rejection loop where Vision Critic fails and triggers UI Agent re-generation, so that the pipeline's feedback mechanism is confirmed to converge within the defined retry limit.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 動態 | TC-02 腳本建立 | 建立 TC-02 測試腳本，模擬 Vision Critic 評分低於閾值的情境 |
| AC2 | 動態 | 迴圈收斂驗證 | 驗證 UI Agent 重新生成後，第二次視覺評分提升（相對改善 ≥ 10%） |
| AC3 | 動態 | 退件限制 | 驗證退件迴圈在 3 次以內收斂（依 SDD-UIUX-E2E 規格） |
| AC4 | 動態 | TDD | 先定義失敗情境的輸入，再實作測試腳本 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 驗證管線退件迴圈機制 |
| Impact | 3 | 防止無限迴圈的關鍵測試 |
| Confidence | 0.7 | 退件改善量化有不確定性 |
| Effort | 3 | L-size；測試腳本 + TDD + 迴圈驗證 |
| **RICE Score** | **2.1** | R×I×C/E |

**Done 定義**

- [ ] TC-02 測試腳本已建立（AC1）
- [ ] 第二次評分相對改善 ≥ 10% 驗證通過（AC2）
- [ ] 退件迴圈在 3 次內收斂確認（AC3）
- [ ] 測試案例先於腳本實作完成（AC4）

---

### US-124：SDD-UIUX-E2E TC-03 條件通過邊界測試腳本

**來源**：Sprint 54 Planning（Architect 識別）
**Issue**：#127
**Size**：M / 2 Points
**Owner**：QA Engineer
**QA doc-only 判定**：No（需建立測試腳本）

**User Story**

As a QA engineer validating boundary conditions, I want a test script for TC-03 that tests the exact threshold boundary where Vision Critic scores exactly at the pass/fail threshold, so that the scoring algorithm's boundary behavior is confirmed deterministic.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 動態 | TC-03 腳本建立 | 建立 TC-03 測試腳本，設計輸入使視覺評分落在閾值邊界（±5%） |
| AC2 | 動態 | 確定性驗證 | 驗證閾值判定為確定性（同一輸入多次執行結果一致） |
| AC3 | 靜態 | 執行記錄 | 測試結果記錄於 SDD-UIUX-E2E.md TC-03 執行記錄 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 2 | 驗證閾值邊界行為 |
| Impact | 2 | 確保評分確定性 |
| Confidence | 0.8 | 邊界輸入設計有不確定性 |
| Effort | 2 | M-size；邊界測試腳本 |
| **RICE Score** | **1.6** | R×I×C/E |

**Done 定義**

- [ ] TC-03 測試腳本已建立（AC1）
- [ ] 確定性驗證通過（AC2）
- [ ] 執行記錄已寫入 SDD-UIUX-E2E.md（AC3）

---

### US-125：ADR-014 OQ-4 正式決策文件

**來源**：Sprint 54 Planning（US-110 後置）
**Issue**：#128
**Size**：S / 1 Point
**Owner**：Product Owner
**QA doc-only 判定**：Yes（ADR 文件更新）
**前置依賴**：US-110

**User Story**

As a Product Owner closing open questions in ADR-014, I want OQ-4 (Skeleton Document JSON Schema standardization) to be formally decided and documented, so that US-117 can implement the standardization with a clear authoritative basis.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | OQ-4 正式決策 | 在 ADR-014 OQ-4 區塊填入正式決策（選定 Schema 標準），附理由 |
| AC2 | 靜態 | OQ-4 狀態更新 | OQ-4 狀態從「待解答」更新為「已決策」 |
| AC3 | 靜態 | Schema 版本指定 | 決策須明確指定 Schema 版本與驗證工具 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響骨架文件 Schema 標準化 |
| Impact | 3 | 正式決策解除 US-117 阻塞 |
| Confidence | 1.0 | 決策性 Story，依賴 US-110 調查 |
| Effort | 1 | S-size；ADR 文件填入 |
| **RICE Score** | **9.0** | R×I×C/E |

**Done 定義**

- [x] ADR-014 OQ-4 正式決策已填入，附理由（AC1）
- [x] OQ-4 狀態已更新為「已決策」（AC2）
- [x] Schema 版本與驗證工具已指定（AC3）

---

### US-126：ADR-014 OQ-5 Context Window 管理決策

**來源**：Sprint 54 Planning（Architect 識別）
**Issue**：#129
**Size**：S / 1 Point
**Owner**：Product Owner
**QA doc-only 判定**：Yes（ADR 文件更新）

**User Story**

As a Product Owner closing open questions in ADR-014, I want OQ-5 (Context Window management strategy for multi-agent pipeline) to be formally decided, so that all three SKILL.md files can reference a consistent context management approach.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | Context Window 問題調查 | 調查三層管線的 Context Window 累積問題（UX → UI → Vision Critic 串接時的 token 消耗） |
| AC2 | 靜態 | OQ-5 正式決策 | 在 ADR-014 OQ-5 區塊填入 Context Window 管理策略決策 |
| AC3 | 靜態 | OQ-5 狀態更新 | OQ-5 狀態從「待解答」更新為「已決策」 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響三層管線所有使用場景 |
| Impact | 3 | 解決 context overflow 潛在失敗 |
| Confidence | 0.9 | 調查 + 決策，低不確定性 |
| Effort | 1 | S-size；調查 + ADR 填入 |
| **RICE Score** | **8.1** | R×I×C/E |

**Done 定義**

- [x] Context Window 累積問題調查已完成（AC1）
- [x] ADR-014 OQ-5 Context Window 管理策略決策已填入（AC2）
- [x] OQ-5 狀態已更新為「已決策」（AC3）

---

### US-127：ADR-007 延伸 — 前端 Story 觸發 UIUX 管線決策點

**來源**：Sprint 54 Planning（PO 識別）
**Issue**：#130
**Size**：M / 2 Points
**Owner**：Product Owner
**QA doc-only 判定**：Yes（ADR 文件更新）

**User Story**

As a Product Owner extending ADR-007 (issue-management workflow), I want a formal decision on when frontend Stories should automatically trigger the UIUX pipeline, so that the trigger condition is explicit and does not require manual PO judgment for every frontend Story.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 觸發決策點分析 | 分析 ADR-007 現行前端 Story 流程，識別 UIUX 管線觸發的決策點 |
| AC2 | 靜態 | 觸發條件規則 | 定義觸發條件規則（例如：Story 標籤包含 frontend 且 UI 元件數 ≥ 1） |
| AC3 | 靜態 | ADR 決策記錄 | 在 ADR-007 附錄或新 ADR 中記錄決策 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 4 | 影響所有前端 Story 的工作流 |
| Impact | 2 | 自動化觸發條件，減少手動判斷 |
| Confidence | 0.9 | 決策性 Story |
| Effort | 2 | M-size；工作流分析 + ADR 更新 |
| **RICE Score** | **3.6** | R×I×C/E |

**Done 定義**

- [ ] ADR-007 前端 Story 觸發決策點分析已完成（AC1）
- [ ] 觸發條件規則已定義（AC2）
- [ ] ADR 文件已更新記錄決策（AC3）

---

### US-128：Vision Critic 退件報告儲存機制

**來源**：Sprint 54 Planning（Architect 識別）
**Issue**：#131
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：Yes（SKILL.md + 路徑規則文件更新）

**User Story**

As a Developer using the Vision Critic Agent, I want rejection reports to be automatically saved to a structured location, so that failed visual validations can be reviewed and the feedback loop can be traced.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 儲存路徑規則 | 定義退件報告儲存路徑規則（如 `docs/vision-critic-reports/YYYY-MM-DD-{story-id}.json`） |
| AC2 | 靜態 | 報告格式定義 | 退件報告格式包含：評分詳情、失敗維度、改善建議 |
| AC3 | 靜態 | SKILL.md 更新 | 更新 vision-critic SKILL.md，說明退件報告的自動儲存行為 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 所有 Vision Critic 退件場景均受益 |
| Impact | 2 | 改善退件可追溯性 |
| Confidence | 1.0 | 純規則和文件定義 |
| Effort | 1 | S-size；路徑規則 + SKILL.md 補充 |
| **RICE Score** | **6.0** | R×I×C/E |

**Done 定義**

- [x] 退件報告儲存路徑規則已定義（AC1）
- [x] 退件報告 JSON 格式已定義（AC2）
- [x] Vision Critic SKILL.md 已更新說明自動儲存行為（AC3）

---

### US-129：UX Agent SKILL.md CLI 輸出設計符合性審查

**來源**：Sprint 54 Planning（US-109 後置）
**Issue**：#132
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：Yes（SKILL.md 更新）
**前置依賴**：US-109

**User Story**

As a Product Owner ensuring CLI output consistency, I want the UX Agent SKILL.md to be reviewed against CLI output design principles established in US-109, so that shikigami:ux CLI output conforms to the standard output format.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 符合性審查 | 依據 US-109 的 CLI 輸出設計原則評估報告，審查 UX Agent SKILL.md 的輸出格式定義 |
| AC2 | 靜態 | 不符合項目清單 | 識別不符合設計原則的輸出格式，列出改善項目 |
| AC3 | 靜態 | SKILL.md 更新 | 更新 UX Agent SKILL.md 使輸出格式符合設計原則 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響所有使用 shikigami:ux 的場景 |
| Impact | 2 | CLI 輸出一致性 |
| Confidence | 1.0 | 依賴 US-109 評估報告 |
| Effort | 2 | M-size；審查 + SKILL.md 更新 |
| **RICE Score** | **3.0** | R×I×C/E |

**Done 定義**

- [ ] UX Agent SKILL.md CLI 輸出格式已審查（AC1）
- [ ] 不符合項目已識別並列出（AC2）
- [ ] SKILL.md 已更新符合設計原則（AC3）

---

### US-130：UI Agent CLI 輸出設計符合性審查

**來源**：Sprint 54 Planning（US-109 後置）
**Issue**：#133
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：Yes（SKILL.md 更新）
**前置依賴**：US-109

**User Story**

As a Product Owner ensuring CLI output consistency, I want the UI Agent SKILL.md to be reviewed against CLI output design principles, so that shikigami:ui CLI output conforms to the standard output format.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 符合性審查 | 依據 US-109 的 CLI 輸出設計原則評估報告，審查 UI Agent SKILL.md 的輸出格式定義 |
| AC2 | 靜態 | 不符合項目清單 | 識別不符合設計原則的輸出格式，列出改善項目 |
| AC3 | 靜態 | SKILL.md 更新 | 更新 UI Agent SKILL.md 使輸出格式符合設計原則 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響所有使用 shikigami:ui 的場景 |
| Impact | 2 | CLI 輸出一致性 |
| Confidence | 1.0 | 依賴 US-109 評估報告 |
| Effort | 2 | M-size；審查 + SKILL.md 更新 |
| **RICE Score** | **3.0** | R×I×C/E |

**Done 定義**

- [ ] UI Agent SKILL.md CLI 輸出格式已審查（AC1）
- [ ] 不符合項目已識別並列出（AC2）
- [ ] SKILL.md 已更新符合設計原則（AC3）

---

### US-131：Vision Critic CLI 輸出設計符合性審查

**來源**：Sprint 54 Planning（US-109 後置）
**Issue**：#134
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：Yes（SKILL.md 更新）
**前置依賴**：US-109

**User Story**

As a Product Owner ensuring CLI output consistency, I want the Vision Critic SKILL.md to be reviewed against CLI output design principles, so that shikigami:vision-critic CLI output conforms to the standard output format.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 符合性審查 | 依據 US-109 的 CLI 輸出設計原則評估報告，審查 Vision Critic SKILL.md 的輸出格式定義 |
| AC2 | 靜態 | 不符合項目清單 | 識別不符合設計原則的輸出格式，列出改善項目 |
| AC3 | 靜態 | SKILL.md 更新 | 更新 Vision Critic SKILL.md 使輸出格式符合設計原則 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響所有使用 shikigami:vision-critic 的場景 |
| Impact | 2 | CLI 輸出一致性 |
| Confidence | 1.0 | 依賴 US-109 評估報告 |
| Effort | 1 | S-size；審查 + SKILL.md 更新 |
| **RICE Score** | **6.0** | R×I×C/E |

**Done 定義**

- [ ] Vision Critic SKILL.md CLI 輸出格式已審查（AC1）
- [ ] 不符合項目已識別並列出（AC2）
- [ ] SKILL.md 已更新符合設計原則（AC3）

---

### US-132：設計 Token 版本控制機制建立

**來源**：Sprint 54 Planning（Architect 識別）
**Issue**：#135
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：Yes（版本控制策略文件 + design-tokens.json 更新）

**User Story**

As a Designer managing design tokens, I want a versioning mechanism for design-tokens.json that tracks changes and allows rolling back to previous token sets, so that UIUX pipeline outputs can be traced to the token version used during generation.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 版本控制策略文件 | 建立 `docs/design/design-tokens-versioning.md`，定義版本控制策略 |
| AC2 | 靜態 | 版本號格式 | 定義版本號格式（semver）與變更記錄規則 |
| AC3 | 靜態 | version 欄位 | 在 design-tokens.json 中新增 `version` 欄位 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響所有使用 Design Token 的場景 |
| Impact | 2 | 建立 Token 可追溯性 |
| Confidence | 1.0 | 純文件定義 |
| Effort | 2 | M-size；策略文件 + JSON 更新 |
| **RICE Score** | **3.0** | R×I×C/E |

**Done 定義**

- [x] `docs/design/design-tokens-versioning.md` 已建立（AC1）
- [x] 版本號格式與變更記錄規則已定義（AC2）
- [x] design-tokens.json 已新增 version 欄位（AC3）

---

### US-133：SDD-UIUX-E2E TC-04 UX Agent 輸入驗證測試腳本

**來源**：Sprint 54 Planning（QA 識別）
**Issue**：#136
**Size**：S / 1 Point
**Owner**：QA Engineer
**QA doc-only 判定**：No（需建立測試腳本）

**User Story**

As a QA engineer validating input handling, I want a test script for TC-04 that tests UX Agent behavior when receiving malformed or incomplete User Story inputs, so that input validation errors are handled gracefully with clear error messages.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 動態 | TC-04 腳本建立 | 建立 TC-04 測試腳本，測試至少 3 種異常輸入情境（空白輸入、格式錯誤、缺少必要欄位） |
| AC2 | 動態 | 錯誤處理驗證 | 驗證 UX Agent 對異常輸入回傳結構化錯誤訊息（而非崩潰） |
| AC3 | 靜態 | 執行記錄 | 測試結果記錄於 SDD-UIUX-E2E.md TC-04 執行記錄 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 2 | 驗證輸入邊界處理 |
| Impact | 2 | 提升管線健壯性 |
| Confidence | 0.9 | 標準錯誤處理測試 |
| Effort | 1 | S-size；異常輸入測試腳本 |
| **RICE Score** | **3.6** | R×I×C/E |

**Done 定義**

- [ ] TC-04 測試腳本已建立，含 3 種異常輸入情境（AC1）
- [ ] 結構化錯誤訊息回傳驗證通過（AC2）
- [ ] 執行記錄已寫入 SDD-UIUX-E2E.md（AC3）

---

### US-134：UIUX Agent 三層管線整合文件補充

**來源**：Sprint 54 Planning（Architect 識別）
**Issue**：#137
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：Yes（整合文件建立）

**User Story**

As a Developer integrating the UIUX pipeline into a project, I want comprehensive integration documentation that explains the data flow between all three agents with concrete examples, so that I can implement the pipeline without having to reverse-engineer the SKILL.md files.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 整合文件建立 | 建立或更新 `docs/guides/uiux-pipeline-integration.md`，說明三層管線完整資料流 |
| AC2 | 靜態 | 序列圖 | 包含 Mermaid 序列圖展示 UX → UI → Vision Critic 資料流 |
| AC3 | 靜態 | 具體範例 | 包含每層輸入/輸出的具體範例（含 JSON 示例） |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 所有整合三層管線的開發者受益 |
| Impact | 2 | 降低整合門檻 |
| Confidence | 1.0 | 純文件建立 |
| Effort | 2 | M-size；完整整合文件 + 序列圖 |
| **RICE Score** | **3.0** | R×I×C/E |

**Done 定義**

- [ ] `docs/guides/uiux-pipeline-integration.md` 已建立（AC1）
- [ ] Mermaid 序列圖已包含（AC2）
- [ ] 每層 JSON 範例已包含（AC3）

---

### US-135：SDD 前端模板 Design Token 路徑驗證規則

**來源**：Sprint 54 Planning（US-120 後置）
**Issue**：#138
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：Yes（模板文件更新）
**前置依賴**：US-120

**User Story**

As a Developer implementing frontend components, I want the SDD frontend template to include explicit Design Token path validation rules, so that PR reviews can automatically detect hardcoded values that should be token references.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 路徑驗證規則 | 更新 `docs/sdd/SDD-frontend-template.md`，新增 Design Token 路徑驗證規則（正規表示式或 linting 規則） |
| AC2 | 靜態 | 範例對照 | 提供違規範例與正確範例對照 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 4 | 所有前端 Story 的代碼審查受益 |
| Impact | 2 | 自動化 Token 路徑驗證 |
| Confidence | 1.0 | 純模板更新 |
| Effort | 1 | S-size；驗證規則補充 |
| **RICE Score** | **8.0** | R×I×C/E |

**Done 定義**

- [x] SDD-frontend-template.md 已新增 Design Token 路徑驗證規則（AC1）
- [x] 違規範例與正確範例對照已提供（AC2）

---

### US-136：Issue #107 UIUX Agent 模型分層策略實作規劃

**來源**：Issue #107（UIUX Agent 模型分層策略）→ Sprint 54 Planning
**Issue**：#139
**Size**：S / 1 Point
**Owner**：Product Owner
**QA doc-only 判定**：Yes（SKILL.md 更新 + 規劃文件）
**前置依賴**：US-116

**User Story**

As a Product Owner translating the model tiering strategy decision into actionable implementation tasks, I want a concrete implementation plan for applying model tiering across the three-layer UIUX pipeline, so that Developer subagents know which model to use at each pipeline stage.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 推薦模型清單 | 基於 US-116 模型分層策略調查結果，產出三層管線各層的推薦模型清單 |
| AC2 | 靜態 | SKILL.md 標注 | 更新三個 SKILL.md，明確標注每層推薦使用的模型（或模型類型） |
| AC3 | 靜態 | 切換判斷條件 | 記錄切換模型的判斷條件（何時使用高階模型 vs 標準模型） |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響三層管線的模型選用 |
| Impact | 2 | 將策略轉為可執行的 SKILL.md 標注 |
| Confidence | 0.9 | 依賴 US-116 調查結果 |
| Effort | 1 | S-size；SKILL.md 標注更新 |
| **RICE Score** | **5.4** | R×I×C/E |

**Done 定義**

- [x] 三層管線推薦模型清單已產出（AC1）
- [x] 三個 SKILL.md 已更新模型標注（AC2）
- [x] 切換判斷條件已記錄（AC3）

---

### US-137：UIUX 管線 CI GitHub Action 整合框架

**來源**：Sprint 54 Planning（Architect 識別）
**Issue**：#140
**Size**：L / 3 Points
**Owner**：Developer
**QA doc-only 判定**：No（需建立 GitHub Actions workflow）
**ADR 依賴**：ADR-014（CI 整合策略）
**前置依賴**：Phase 4（US-114 完成後）

**User Story**

As a CI/CD engineer automating the UIUX validation pipeline, I want a GitHub Actions workflow that runs the three-layer UIUX pipeline as part of the CI pipeline for frontend Stories, so that visual validation happens automatically on every PR that includes frontend changes.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 動態 | Workflow 建立 | 建立 `.github/workflows/uiux-pipeline.yml`，定義 UIUX 管線 CI 觸發條件（PR 含前端變更） |
| AC2 | 動態 | 執行順序 | Workflow 執行順序：截圖 → Vision Critic 評分 → PASS/FAIL 作為 PR Check |
| AC3 | 動態 | 失敗報告 | FAIL 時在 PR 附加 Vision Critic 退件報告摘要 |
| AC4 | 動態 | GCP runner | Workflow 在 GCP self-hosted runner 上可執行（依 OQ-1 決策） |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 4 | 所有前端 PR 均自動觸發視覺驗證 |
| Impact | 3 | CI 自動化是管線可驗證化的最終形式 |
| Confidence | 0.7 | 依賴 GCP runner + Playwright 整合 |
| Effort | 3 | L-size；GitHub Actions workflow 建立 |
| **RICE Score** | **2.8** | R×I×C/E |

**Done 定義**

- [ ] `.github/workflows/uiux-pipeline.yml` 已建立（AC1）
- [ ] 執行順序正確（截圖 → Vision Critic → PR Check）（AC2）
- [ ] FAIL 時 PR 退件報告摘要附加正確（AC3）
- [ ] GCP self-hosted runner 上執行驗證通過（AC4）

---

## ADR 觸發清單

| ADR | 觸發 Story | 觸發原因 | 狀態 |
|-----|-----------|---------|------|
| ADR-014 | US-110（#117） | OQ-4 骨架文件 JSON Schema 標準化調查，填入初步決策方向 | Sprint 54 目標 |
| ADR-014 | US-125（#128） | OQ-4 正式決策填入，狀態從「待解答」升為「已決策」 | Sprint 54 目標 |
| ADR-014 | US-126（#129） | OQ-5 Context Window 管理決策填入，狀態從「待解答」升為「已決策」 | Sprint 54 目標 |
| ADR-014 | US-116（#107） | 模型分層策略建議填入 ADR-014 | Sprint 54 目標 |
| ADR-007 | US-127（#130） | 前端 Story 觸發 UIUX 管線決策點，延伸 ADR-007 | Sprint 54 目標 |

---

## Sprint Planning 簽核記錄

| 角色 | 確認項目 | 狀態 |
|------|----------|------|
| Product Owner | Sprint Goal 對齊 ADR-014 OQ-4/OQ-5 決策閉環與管線可驗證化；29 Stories 總計 50 points；平行分群策略合理；RICE Score 支持優先順序排列 | 已確認 |
| Architect | Phase 1-4 依賴關係正確；US-114/115/137 L-size 合理；Phase 1 6 Stories 無檔案衝突可平行；平行可行性已驗證 | 已確認 |
| QA | 各 Story doc-only 判定通過；TDD Story（US-111/114/115/123）先寫測試案例的 AC4 已明確 | 已確認 |
| Developer | Story 清晰度確認；前置依賴已說明；US-113 序列於 US-116 之後已理解 | 已確認 |

**Sprint Planning 決策記錄**

- Sprint 54 選入 29 Stories，共 50 Points
- Phase 1（8pt）：US-125/126/128/132/135/136 無檔案衝突，可完全並發執行
- Phase 2 Group A：8 Stories 各自獨立，可並發執行
- Phase 2 Group B：依賴 Phase 1 OQ-4/OQ-5 決策及 US-109 CLI 設計原則報告，序列執行
- Phase 2 Group C：US-111/112/127 無衝突，可並發執行
- Phase 3：US-113/123/124/134 需前置完成
- Phase 4：US-114/115/137 最終整合，序列執行
- 目標 Velocity：50 Points
- Issue #101（/plugin 間歇性載入失敗）持續觀察中，不排入本 Sprint
- 本 Sprint 不 bump version（遵循連續衝刺策略，減少 plugin 快取失效風險）
