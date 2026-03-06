# Sprint 55

**狀態**：進行中
**期間**：2026-03-06 ~ 2026-03-12
**Sprint Goal**：建立 Figma 整合環境基礎 — 完成 MCP Server 選型與本地設定驗證、Figma 文件結構定義，並執行 AI 透過 Figma MCP 生成 Frame 的端對端 PoC，確認 ADR-015 Phase 1 技術路徑可落地。
**ADR 依賴**：ADR-015（Accepted）
**總計**：5 Stories / 8 Points

---

## Sprint Backlog

| Story ID | Issue # | 標題 | Size | Points | doc-only | 狀態 |
|----------|---------|------|------|--------|----------|------|
| US-149 | #147 | SDD 前端模板更新 — 新增 Figma 設計稿連結欄位 | S | 1 | 是 | 完成 |
| US-145 | #146 | Figma MCP Server 選型與本地設定驗證 | M | 2 | 否 | 待開始 |
| US-146 | #148 | Figma 文件結構定義 — Page 架構、Layer 命名規則、Frame 模板 | S | 1 | 是 | 待開始 |
| US-148 | #149 | Component Library 基礎建立 — Button / Input / Card | M | 2 | 否 | 待開始 |
| US-147 | #150 | AI 生成 Frame PoC — 透過 Figma MCP 生成帶 Auto Layout 的 Frame | M | 2 | 否 | 待開始 |

**Sprint 容量**：8 Points（5 Stories）

---

## 平行分群方案

| Phase | Stories | 說明 |
|-------|---------|------|
| Phase 0（獨立） | US-149 | 純文件更新，無外部依賴，可最先執行 |
| Phase 1（序列） | US-145 | MCP Server 選型與本地設定驗證，是 US-146/US-147/US-148 的前置條件 |
| Phase 2（並行） | US-146 + US-148 | 均依賴 US-145 完成，但兩者間無依賴關係，可並行執行 |
| Phase 3（序列） | US-147 | 依賴 US-145（MCP 連接）+ US-146（文件結構規則）完成後執行 |

---

## Story 詳細 AC

---

### US-149：SDD 前端模板更新 — 新增 Figma 設計稿連結欄位

**來源**：Sprint 55 Planning（PO 識別，Sprint 54 US-120 演進）
**Issue**：#147
**Size**：S / 1 Point
**Owner**：Product Owner
**QA doc-only 判定**：Yes（純模板文件更新）
**前置依賴**：無（Phase 0，最先執行）

**User Story**

As a Product Owner standardizing frontend Story completion criteria, I want the SDD frontend template to include a Figma Frame URL field and an updated Done Definition that reflects the Figma-based validation gate, so that all future frontend Stories have a clear path from design to implementation validation.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | Figma Frame URL 欄位新增 | 更新 `docs/templates/sdd-frontend-template.md`，新增「Figma 設計稿」區塊，包含 Figma Frame URL 欄位與填寫說明 |
| AC2 | 靜態 | Done Definition 過渡期定義 | Done Definition 新增 Figma 驗證 gate 說明：Phase 1（Figma 整合環境建立期）：Figma Frame URL 已填寫即視為滿足設計稿條件；Phase 2 起（Vision Critic 上線後）：Vision Critic Review 通過為必要條件 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 5 | 所有未來前端 Story 的 Done Definition 均受影響 |
| Impact | 2 | 建立設計稿連結標準，為 Phase 2 Vision Critic gate 鋪路 |
| Confidence | 1.0 | 純模板文件更新，無技術不確定性 |
| Effort | 1 | S-size；模板新增欄位與 Done Definition 更新 |
| **RICE Score** | **10.0** | R×I×C/E |

**Done 定義**

- [ ] `docs/templates/sdd-frontend-template.md` 已新增 Figma 設計稿區塊（AC1）
- [ ] Done Definition 已包含 Phase 1/Phase 2 過渡期說明（AC2）

---

### US-145：Figma MCP Server 選型與本地設定驗證

**來源**：ADR-015 OQ-1 決策輸出
**Issue**：#146
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：No（需實際安裝與連接驗證）
**ADR 依賴**：ADR-015 OQ-1（MCP Server 選型）
**前置依賴**：無（Phase 1 起始點）

**User Story**

As a Developer setting up the Figma integration, I want to evaluate and configure the optimal Figma MCP Server, so that Claude Code can communicate with Figma via MCP protocol and execute write operations (e.g., create_frame) that produce visible results in a real Figma document.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 動態 | MCP Server 安裝與連接成功 | Plugin 載入、CLI 啟動、Claude Code MCP 協議連接三步驟均成功，可在 Claude Code 中列出 Figma MCP 可用工具 |
| AC2 | 動態 | 寫入工具可用性驗證 | Claude Code 可呼叫至少一個寫入工具（如 create_frame）並在 Figma 文件中產生可見結果（Frame 出現於 Figma Canvas） |
| AC3 | 靜態 | 選型決策與安裝指南 | 選型決策與完整安裝指南記錄於 `docs/guides/figma-mcp-setup.md`，包含：選型理由、安裝步驟、驗證指令、已知限制 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 5 | 所有後續 Figma 整合 Story 的基礎依賴 |
| Impact | 3 | 驗證 ADR-015 Phase 1 技術路徑可落地 |
| Confidence | 0.8 | MCP Server 安裝有環境依賴不確定性 |
| Effort | 2 | M-size；選型評估 + 安裝驗證 + 文件 |
| **RICE Score** | **6.0** | R×I×C/E |

**Done 定義**

- [ ] Figma MCP Server 已安裝並成功連接（AC1）
- [ ] Claude Code 已呼叫寫入工具並在 Figma 產生可見結果（AC2）
- [ ] `docs/guides/figma-mcp-setup.md` 已建立並涵蓋完整安裝指南（AC3）

---

### US-146：Figma 文件結構定義 — Page 架構、Layer 命名規則、Frame 模板

**來源**：ADR-015 Phase 1 規範建立
**Issue**：#148
**Size**：S / 1 Point
**Owner**：Designer / Product Owner
**QA doc-only 判定**：Yes（純規範文件建立）
**前置依賴**：US-145（MCP 連接已建立，需確認可用工具清單）

**User Story**

As a Designer and Developer collaborating on Figma-based design workflows, I want a formally defined Figma document structure (Page architecture, Layer naming conventions, Frame templates), so that AI-generated Figma content follows consistent conventions and is easily navigable by human designers.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | Page 架構定義 | 定義 Figma 文件的 Page 架構，至少包含：Component Library Page（元件庫）、Design Tokens Page（Token 可視化）、Sprint Pages（各 Sprint 設計稿，命名規則：Sprint-{N}-{功能名}） |
| AC2 | 靜態 | Layer 命名規則定義 | 定義 Layer 命名規則，涵蓋：Frame 命名（{StoryID}-{功能描述}）、Group 命名、元件實例命名、語意化命名原則 |
| AC3 | 靜態 | Frame 模板定義 | 定義標準 Frame 模板規格，包含：預設尺寸（Desktop 1440px / Mobile 375px）、Auto Layout 預設設定（方向、間距、Padding）、命名慣例 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 4 | 所有 AI 生成 Figma 內容均需遵守此結構 |
| Impact | 2 | 建立一致性規範，防止 AI 生成內容散亂 |
| Confidence | 1.0 | 純規範文件定義，無技術不確定性 |
| Effort | 1 | S-size；結構規範文件建立 |
| **RICE Score** | **8.0** | R×I×C/E |

**Done 定義**

- [ ] `docs/design/figma-structure-guide.md` 已建立（AC1, AC2, AC3）
- [ ] Page 架構已定義（含 Component Library、Design Tokens、Sprint Pages）（AC1）
- [ ] Layer 命名規則已定義（AC2）
- [ ] Frame 模板規格已定義（AC3）

---

### US-148：Component Library 基礎建立 — Button / Input / Card

**來源**：ADR-015 Phase 1 元件庫建立
**Issue**：#149
**Size**：M / 2 Points
**Owner**：Designer / Developer
**QA doc-only 判定**：No（需實際在 Figma 建立元件並驗證 MCP 引用）
**前置依賴**：US-145（MCP 連接已建立）

**User Story**

As a Designer establishing the Figma Component Library, I want to create the foundational UI components (Button, Input, Card) in Figma with Auto Layout and Figma Variable bindings, so that AI can reference these components as instances when generating new Frames instead of creating duplicate raw elements.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 動態 | 三個元件建立 | 在 Figma Component Library Page 建立 Button、Input、Card 三個 Figma Component，各有明確命名（遵循 US-146 Layer 命名規則） |
| AC2 | 動態 | Auto Layout 與 Variable 綁定 | 三個元件均設定 Auto Layout（指定方向、間距、Padding），且各元件至少一個顏色屬性綁定 Figma Variable（對應 design-tokens.json 的 color token） |
| AC3 | 動態 | AI 可引用元件 | 透過 Figma MCP 工具，Claude Code 可以 Component Instance 方式引用三個元件（呼叫相應 MCP 工具，元件實例出現在指定 Frame 中） |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 4 | 未來所有 AI 生成 UI 均可複用這三個基礎元件 |
| Impact | 3 | 建立元件庫是 Figma 設計系統的核心基礎 |
| Confidence | 0.8 | AC3 依賴 MCP 工具是否支援 component_instance 操作 |
| Effort | 2 | M-size；三個元件建立 + Variable 綁定 + MCP 引用驗證 |
| **RICE Score** | **4.8** | R×I×C/E |

**Done 定義**

- [ ] Button、Input、Card 三個元件已建立於 Figma Component Library Page（AC1）
- [ ] 三個元件均設定 Auto Layout 與顏色 Variable 綁定（AC2）
- [ ] Claude Code 已透過 MCP 成功以 Component Instance 方式引用三個元件（AC3）

---

### US-147：AI 生成 Frame PoC — 透過 Figma MCP 生成帶 Auto Layout 的 Frame

**來源**：ADR-015 Phase 1 端對端 PoC
**Issue**：#150
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：No（需實際執行 MCP 操作並驗證 Figma 結果）
**前置依賴**：US-145（MCP 連接已建立）、US-146（文件結構規則已定義）

**User Story**

As a Developer validating the ADR-015 Phase 1 end-to-end technical path, I want to use Claude Code + Figma MCP to generate a Frame based on a real User Story input (with Auto Layout and at least one Figma Variable binding), so that the feasibility of AI-driven Figma design generation is confirmed and documented as a reproducible PoC.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 動態 | PoC 輸入為真實 User Story | 以本專案現有 User Story（如 US-145 或 US-147 本身）為輸入，透過 Claude Code 呼叫 Figma MCP 生成對應 Frame |
| AC2 | 動態 | Frame 存在於指定 Page | 生成的 Frame 出現在 Figma 文件的指定 Sprint Page（遵循 US-146 Page 架構規則），Frame 命名符合命名規則 |
| AC3 | 動態 | Auto Layout 已設定 | 生成的 Frame 已設定 Auto Layout，包含方向（horizontal/vertical）與間距（gap）設定，可在 Figma 中驗證 |
| AC4 | 動態 | Figma Variable 綁定 | Frame 內至少一個視覺元素的顏色屬性綁定 Figma Variable（對應 design-tokens.json 中的 color token，如 brand-primary） |
| AC5 | 動態 | 截圖可讀取 | 透過 Figma MCP 工具或 Figma REST API，可讀取生成 Frame 的截圖（PNG 格式），截圖存放於 `docs/design/poc-screenshots/` |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 5 | 驗證 ADR-015 Phase 1 核心技術路徑，影響所有後續 Figma 整合工作 |
| Impact | 3 | PoC 成功確認整合可行，失敗則需調整 ADR-015 決策 |
| Confidence | 0.7 | Auto Layout 與 Variable 綁定的 MCP 工具支援有不確定性 |
| Effort | 2 | M-size；PoC 實作 + 驗證 + 截圖讀取 |
| **RICE Score** | **5.25** | R×I×C/E |

**Done 定義**

- [ ] 以真實 User Story 為輸入，透過 Figma MCP 生成 Frame（AC1）
- [ ] Frame 存在於 Figma 文件指定 Sprint Page，命名符合規則（AC2）
- [ ] Auto Layout 已設定（方向 + 間距）（AC3）
- [ ] 至少一個視覺元素綁定 Figma Variable（AC4）
- [ ] 截圖已透過 MCP 或 REST API 讀取並存放於 `docs/design/poc-screenshots/`（AC5）

---

## ADR 觸發清單

| ADR | 觸發 Story | 觸發原因 | 狀態 |
|-----|-----------|---------|------|
| ADR-015 | US-145（#146） | MCP Server 選型決策落地，OQ-1 最終確認 | Sprint 55 目標 |
| ADR-015 | US-147（#150） | Phase 1 PoC 結果記錄，驗證 Phase 1 技術路徑 | Sprint 55 目標 |

---

## Sprint Planning 簽核記錄

| 角色 | 確認項目 | 狀態 |
|------|----------|------|
| Product Owner | Sprint Goal 對齊 ADR-015 Phase 1；5 Stories 共 8 Points；平行分群（Phase 0/1/2/3）依賴關係正確；RICE Score 支持優先順序排列 | 已確認 |
| Architect | Phase 0/1/2/3 依賴關係正確；US-147 必須在 US-145+US-146 之後執行；US-146 和 US-148 可並行（Phase 2）的無衝突性已驗證 | 已確認 |
| QA | 各 Story doc-only 判定正確；AC 驗證標準清晰；US-145/US-147/US-148 動態 AC 具體可驗證 | 已確認 |
| Developer | Story 清晰度確認；前置依賴已說明；MCP 工具不確定性（Confidence 0.7-0.8）已知悉 | 已確認 |

**Sprint Planning 決策記錄**

- Sprint 55 選入 5 Stories，共 8 Points
- Phase 0：US-149 無依賴，最先獨立執行
- Phase 1：US-145 是後續所有 Figma Story 的阻塞點，優先執行
- Phase 2：US-146（doc-only）+ US-148 可並行，均依賴 US-145
- Phase 3：US-147（PoC）需 US-145 + US-146 均完成後執行
- 目標 Velocity：8 Points
- 本 Sprint 不 bump version（遵循連續衝刺策略，減少 plugin 快取失效風險）
- Issue #101（/plugin 間歇性載入失敗）持續觀察中，不排入本 Sprint
