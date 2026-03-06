# Sprint 56

**狀態**：進行中
**期間**：2026-03-06 ~ 2026-03-12
**Sprint Goal**：驗證 UIUX Figma 管線可運作性 — 建立 Figma Desktop 本地驗證環境 SOP、定義 Vision Critic Frame 截圖審查 PoC 規格、撰寫 Figma 管線使用指南，使 ADR-015 Phase 1 從技術文件走向可操作的驗證與使用文件。
**ADR 依賴**：ADR-015（Accepted）
**總計**：3 Stories / 5 Points

---

## Sprint Backlog

| Story ID | Issue # | 標題 | Size | Points | doc-only | 狀態 |
|----------|---------|------|------|--------|----------|------|
| US-150 | #151 | Figma Desktop 本地驗證環境 SOP | S | 1 | 是 | 完成 |
| US-151 | #118 | Vision Critic PoC — Figma Frame 截圖審查 | M | 2 | 是 | 完成 |
| US-152 | #123 | Figma 管線使用指南 | M | 2 | 是 | 完成 |

**Sprint 容量**：5 Points（3 Stories）

---

## 平行分群方案

| Phase | Stories | 說明 |
|-------|---------|------|
| Phase A（獨立先行） | US-150 | Figma Desktop SOP，無前置依賴，最先執行 |
| Phase B（並行） | US-151 + US-152 | 均依賴 Sprint 55 交付物（figma-mcp-setup.md、component-library-spec.md），但兩者間無依賴關係，可並行執行 |

---

## Story 詳細 AC

---

### US-150：Figma Desktop 本地驗證環境 SOP

**來源**：Sprint 55 Retro Action Item #1（Issue #151）
**Issue**：#151
**Size**：S / 1 Point
**QA doc-only 判定**：Yes（純文件建立）
**前置依賴**：無（Phase A，最先執行）

**User Story**

As a developer setting up the Figma integration environment for the first time, I want a step-by-step SOP document that covers Figma Desktop App installation, claude-talk-to-figma-mcp Plugin connection, and MCP Server verification, so that I can complete the local setup without guesswork and verify all dynamic ACs from Sprint 55.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | SOP 文件建立 | 新建 `docs/guides/figma-desktop-verification-sop.md`；包含完整 Step-by-Step 操作指引，涵蓋：(1) Figma Desktop App 安裝與帳號設定、(2) claude-talk-to-figma-mcp Plugin 安裝與 WebSocket 連接、(3) 官方 Figma MCP Server 設定（API Token 取得與環境變數配置）、(4) MCP 連線驗證步驟（至少 3 個驗證指令：create_frame、get_variables、export_node_as_image） |
| AC2 | 靜態 | Sprint 55 動態 AC 驗證清單 | SOP 文件包含「Sprint 55 動態 AC 驗證清單」區塊，逐一對應 US-145/US-148/US-147 的動態 AC，提供可執行的驗證步驟與預期結果 |
| AC3 | 靜態 | 故障排除指引 | SOP 文件包含「常見問題排除」區塊，至少涵蓋 3 個故障情境：(a) WebSocket 連接失敗、(b) Figma API Token 無效、(c) Plugin 未載入 |

**Done 定義**

- [ ] `docs/guides/figma-desktop-verification-sop.md` 已建立且內容完整（AC1）
- [ ] Sprint 55 動態 AC 驗證清單已包含（AC2）
- [ ] 常見問題排除區塊已包含 3+ 故障情境（AC3）

---

### US-151：Vision Critic PoC — Figma Frame 截圖審查

**來源**：Sprint 54 US-111 MODIFY — 從 SSD 審查改為 Figma Frame 審查
**Issue**：#118
**Size**：M / 2 Points
**QA doc-only 判定**：Yes（PoC 規格文件建立）
**前置依賴**：Sprint 55 US-145（MCP Server 選型）、US-148（Component Library 規格）

**User Story**

As an Architect designing the UIUX pipeline's quality gate, I want a Vision Critic PoC specification that defines how to capture Figma Frame screenshots via MCP and evaluate them against Design System rules using a three-dimensional scoring model, so that the automated design review pipeline has a concrete, implementable quality assessment specification.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | PoC 規格文件建立 | 新建 `docs/design/vision-critic-poc-spec.md`；包含：(1) Vision Critic 角色定義（Figma Frame 截圖 + Design System 規範 → 三維度評分）、(2) 截圖取得流程（使用官方 Figma MCP `get_screenshot` 或 `export_node_as_image`）、(3) 三維度評分模型定義（佈局一致性、Design Token 符合度、元件規範符合度）、(4) 評分公式與閾值（≥80 PASS，60-79 CONDITIONAL，<60 FAIL） |
| AC2 | 靜態 | 評分維度與權重定義 | 三維度評分模型包含具體權重分配：(a) 佈局一致性（Auto Layout 結構、間距規則）權重、(b) Design Token 符合度（顏色、字型、間距 Variable 綁定）權重、(c) 元件規範符合度（Button/Input/Card 規格匹配）權重；三維度權重總和 = 100% |
| AC3 | 靜態 | MCP 工具呼叫序列定義 | PoC 規格包含 Vision Critic 執行時的 MCP 工具呼叫序列（至少涵蓋：截圖取得 → 節點結構讀取 → Variable 綁定驗證 → 評分輸出），每步驟標注使用的 MCP 工具名稱與參數 |
| AC4 | 靜態 | 退件報告格式定義 | PoC 規格包含退件報告（FAIL/CONDITIONAL）的輸出格式定義，含：失敗維度、扣分項目、具體修正建議、對應 MCP 修正操作 |

**Done 定義**

- [ ] `docs/design/vision-critic-poc-spec.md` 已建立（AC1）
- [ ] 三維度評分權重分配已定義且總和 100%（AC2）
- [ ] MCP 工具呼叫序列已定義（AC3）
- [ ] 退件報告格式已定義（AC4）

---

### US-152：Figma 管線使用指南

**來源**：Sprint 54 US-119 MODIFY — 從三層管線使用指南改為 Figma 管線使用指南
**Issue**：#123
**Size**：M / 2 Points
**QA doc-only 判定**：Yes（使用指南文件建立）
**前置依賴**：Sprint 55 全部交付物（figma-mcp-setup.md、figma-structure-guide.md、component-library-spec.md、poc-frame-generation-guide.md）

**User Story**

As a developer using the Figma-integrated UIUX pipeline for the first time, I want a comprehensive usage guide that covers the end-to-end workflow from receiving a frontend Story to delivering a Figma Frame that passes Vision Critic review, so that I can follow the pipeline without needing to piece together information from multiple specification documents.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 使用指南文件建立 | 新建 `docs/guides/figma-pipeline-usage-guide.md`；包含端對端工作流程：(1) 前端 Story 接收與 SDD 模板填寫、(2) Figma 文件建立（Page/Frame/Layer 命名）、(3) Component Library 元件選用、(4) Design Token 綁定（Figma Variables）、(5) AI Frame 生成（MCP 工具呼叫）、(6) Vision Critic 審查（評分與退件處理） |
| AC2 | 靜態 | 快速參考卡 | 使用指南包含「快速參考卡」區塊，以表格形式列出：(a) 常用 MCP 工具與用途對照、(b) Figma 命名規則速查、(c) Design Token 變數名稱速查 |
| AC3 | 靜態 | 跨文件導覽索引 | 使用指南包含「相關文件索引」區塊，以連結形式指向所有 Sprint 55 產出的規格文件（figma-mcp-setup.md、figma-structure-guide.md、component-library-spec.md、poc-frame-generation-guide.md）與 Sprint 56 的 SOP 和 Vision Critic 規格 |
| AC4 | 靜態 | 管線限制與 Fallback 策略 | 使用指南包含「已知限制與 Fallback」區塊，整合 Sprint 55 各文件中記載的限制事項（Plugin API 限制、社群套件版本鎖定、Desktop App 依賴），並提供替代方案 |

**Done 定義**

- [ ] `docs/guides/figma-pipeline-usage-guide.md` 已建立（AC1）
- [ ] 快速參考卡已包含（AC2）
- [ ] 跨文件導覽索引已包含且連結正確（AC3）
- [ ] 管線限制與 Fallback 策略已包含（AC4）
