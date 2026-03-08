# Project Board

**最後更新**：2026-03-08（Sprint 57 Planning 完成，Velocity 2 points）
**當前 Sprint**：Sprint 57（進行中）

工件導覽：[ROADMAP](prd/ROADMAP.md) → [Backlog](prd/PRODUCT_BACKLOG.md) → [Sprint 57](sprints/sprint_57.md) → 本看板 | [Tutorial](tutorial/README.md)

---

## Sprint 57 — 進行中

**Sprint Goal**：鞏固 ADR-015 Phase 1 文件一致性 — 同步 Vision Critic SKILL.md 至 Figma 架構、標記舊 UX/UI Agent 文件為 Deprecated。
**期間**：2026-03-08 ~ 2026-03-14
**ADR 依賴**：ADR-015（Accepted）

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-153：Vision Critic SKILL.md 同步 ADR-015 Figma 架構更新 | #153 | S | 1 | 完成 |
| US-154：UX Agent / UI Agent SKILL.md 標記 Deprecated | #152 | S | 1 | 完成 |

## Sprint 57 統計
- Velocity 目標：2 points
- 計畫：2 Stories / 2 Points
- 日期：2026-03-08

---

## Sprint 56 — 完成

**Sprint Goal**：驗證 UIUX Figma 管線可運作性 — 建立 Figma Desktop 本地驗證環境 SOP、定義 Vision Critic Frame 截圖審查 PoC 規格、撰寫 Figma 管線使用指南，使 ADR-015 Phase 1 從技術文件走向可操作的驗證與使用文件。
**期間**：2026-03-06 ~ 2026-03-12
**ADR 依賴**：ADR-015（Accepted）
**結果**：Goal 達成（3/3 Stories PASS）。Velocity 5 points，完成率 100%。ADR-015 Phase 1 從技術基礎完整轉化為可操作的驗證與使用文件。
**Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-150：Figma Desktop 本地驗證環境 SOP | #151 | S | 1 | 完成 |
| US-151：Vision Critic PoC — Figma Frame 截圖審查 | #118 | M | 2 | 完成 |
| US-152：Figma 管線使用指南 | #123 | M | 2 | 完成 |

## Sprint 56 統計
- Velocity：5 points
- 完成率：100%（完成 3 / 計畫 3）
- 日期：2026-03-06

---

## Sprint 55 — 完成

**Sprint Goal**：建立 Figma 整合環境基礎 — 完成 MCP Server 選型與本地設定驗證、Figma 文件結構定義，並執行 AI 透過 Figma MCP 生成 Frame 的端對端 PoC，確認 ADR-015 Phase 1 技術路徑可落地。
**期間**：2026-03-06 ~ 2026-03-12
**ADR 依賴**：ADR-015（Accepted）
**結果**：Goal 達成（5/5 Stories PASS）。Velocity 8 points，完成率 100%。ADR-015 Figma 整合方向確立後首個 Sprint 全數交付。
**Stakeholder 驗收**：接受（動態 AC 標記為「需使用者本地驗證」可接受）

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-149：SDD 前端模板更新 — 新增 Figma 設計稿連結欄位 | #147 | S | 1 | 完成 |
| US-145：Figma MCP Server 選型與本地設定驗證 | #146 | M | 2 | 完成 |
| US-146：Figma 文件結構定義 — Page 架構、Layer 命名規則、Frame 模板 | #148 | S | 1 | 完成 |
| US-148：Component Library 基礎建立 — Button / Input / Card | #149 | M | 2 | 完成 |
| US-147：AI 生成 Frame PoC — 透過 Figma MCP 生成帶 Auto Layout 的 Frame | #150 | M | 2 | 完成 |

## Sprint 55 統計
- Velocity：8 points
- 完成率：100%（完成 5 / 計畫 5）
- 日期：2026-03-06

---

## Sprint 54 — 中止

**Sprint Goal**：~~完成 ADR-014 全部開放問題（OQ-4/OQ-5）的正式決策，建立三層 UIUX 管線的端對端可執行測試腳本與 CI 整合框架，並對齊三個 SKILL.md 的 CLI 輸出標準，使 UIUX Agent 管線從文件規格走向可驗證的整合工件。~~
**期間**：2026-03-06 ~ 2026-03-12
**中止原因**：架構方向轉型 — ADR-015（Figma 整合）取代 ADR-014 三層 SSD 管線。Sprint 54 的 20 個待辦 Story 中，14 個直接綁定舊管線（DROP），6 個需重寫 AC（MODIFY）。繼續執行無意義。
**中止日期**：2026-03-06

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-109：CLI 輸出設計原則符合性評估 | #116 | M | 2 | 完成 |
| US-110：ADR-014 OQ-4 骨架文件 JSON Schema 標準化決策 | #117 | S | 1 | 中止（DROP — SSD JSON 被 Figma 取代） |
| US-111：Vision Critic PoC 腳本建立 | #118 | M | 2 | 中止（MODIFY — 需改為 Figma Frame 審查 PoC） |
| US-112：UX Agent 實際觸發驗證 | #119 | M | 2 | 中止（DROP — UX Agent SSD 生成已廢棄） |
| US-113：UI Agent Design Tokens 注入驗證 | #120 | M | 2 | 中止（DROP — Figma Variables 取代） |
| US-114：Playwright CI 整合腳本建立 | #121 | L | 3 | 中止（DROP — Figma MCP 提供截圖） |
| US-115：SDD-UIUX-E2E TC-001 Happy Path 端對端驗證 | #122 | L | 3 | 中止（DROP — 舊三層管線 E2E） |
| US-116：UIUX Agent 模型分層策略調查 | #107 | S | 1 | 完成 |
| US-117：ADR-014 OQ-4 骨架文件 Schema 標準化 | #141 | S | 1 | 中止（DROP — ADR-015 明確廢棄） |
| US-118：ADR-014 OQ-5 Context Window 管理策略 | #142 | S | 1 | 中止（MODIFY — 新管線 context 模式不同） |
| US-119：UIUX Agent 使用者文件補充 | #123 | M | 2 | 中止（MODIFY — 改為 Figma 管線使用指南） |
| US-120：SDD 前端模板 Done Definition 更新 | #124 | S | 1 | 中止（MODIFY — 改為 Figma 驗證 gate） |
| US-121：Gemini CLI 能力邊界調查 | #108 | S | 1 | 完成 |
| US-122：Playwright 截圖 PoC 腳本正式化 | #125 | S | 1 | 中止（DROP — Figma 截圖取代） |
| US-123：SDD-UIUX-E2E TC-02 退件迴圈腳本建立 | #126 | L | 3 | 中止（DROP — 舊管線測試） |
| US-124：SDD-UIUX-E2E TC-03 條件通過邊界測試腳本 | #127 | M | 2 | 中止（DROP — 舊管線測試） |
| US-125：ADR-014 OQ-4 正式決策文件 | #128 | S | 1 | 完成 |
| US-126：ADR-014 OQ-5 Context Window 管理決策 | #129 | S | 1 | 完成 |
| US-127：ADR-007 延伸 — 前端 Story 觸發 UIUX 管線決策點 | #130 | M | 2 | 中止（MODIFY — 觸發機制改為 Figma 流程） |
| US-128：Vision Critic 退件報告儲存機制 | #131 | S | 1 | 完成 |
| US-129：UX Agent SKILL.md CLI 輸出設計符合性審查 | #132 | M | 2 | 中止（DROP — UX Agent 被取代） |
| US-130：UI Agent CLI 輸出設計符合性審查 | #133 | M | 2 | 中止（DROP — UI Agent 被取代） |
| US-131：Vision Critic CLI 輸出設計符合性審查 | #134 | S | 1 | 中止（DROP — SKILL.md 需全面重寫） |
| US-132：設計 Token 版本控制機制建立 | #135 | M | 2 | 完成 |
| US-133：SDD-UIUX-E2E TC-04 UX Agent 輸入驗證測試腳本 | #136 | S | 1 | 中止（DROP — UX Agent 不再存在） |
| US-134：UIUX Agent 三層管線整合文件補充 | #137 | M | 2 | 中止（DROP — 三層管線已廢棄） |
| US-135：SDD 前端模板 Design Token 路徑驗證規則 | #138 | S | 1 | 完成 |
| US-136：Issue #107 UIUX Agent 模型分層策略實作規劃 | #139 | S | 1 | 完成 |
| US-137：UIUX 管線 CI GitHub Action 整合框架 | #140 | L | 3 | 中止（MODIFY — 需重新設計為 Figma 管線 CI） |

## Sprint 54 統計
- 完成：9 Stories / 11 points
- 中止（DROP）：14 Stories / 26 points
- 中止（MODIFY → 回 Backlog）：6 Stories / 11 points
- 完成率：9/29（31%，因架構轉型中止）
- 日期：2026-03-06

---

> 歷史 Sprint 記錄：[PROJECT_BOARD_ARCHIVE](km/archive/PROJECT_BOARD_ARCHIVE.md)（Sprint 1–53）
