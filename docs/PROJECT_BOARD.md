# Project Board

**最後更新**：2026-03-06（Sprint 55 Planning 完成）
**當前 Sprint**：Sprint 55（進行中）

工件導覽：[ROADMAP](prd/ROADMAP.md) → [Backlog](prd/PRODUCT_BACKLOG.md) → [Sprint 55](sprints/sprint_55.md) → 本看板 | [Tutorial](tutorial/README.md)

---

## Sprint 55 — 進行中

**Sprint Goal**：建立 Figma 整合環境基礎 — 完成 MCP Server 選型與本地設定驗證、Figma 文件結構定義，並執行 AI 透過 Figma MCP 生成 Frame 的端對端 PoC，確認 ADR-015 Phase 1 技術路徑可落地。
**期間**：2026-03-06 ~ 2026-03-12
**ADR 依賴**：ADR-015（Accepted）

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-149：SDD 前端模板更新 — 新增 Figma 設計稿連結欄位 | #147 | S | 1 | 完成 |
| US-145：Figma MCP Server 選型與本地設定驗證 | #146 | M | 2 | 待開始 |
| US-146：Figma 文件結構定義 — Page 架構、Layer 命名規則、Frame 模板 | #148 | S | 1 | 待開始 |
| US-148：Component Library 基礎建立 — Button / Input / Card | #149 | M | 2 | 待開始 |
| US-147：AI 生成 Frame PoC — 透過 Figma MCP 生成帶 Auto Layout 的 Frame | #150 | M | 2 | 待開始 |

**目標 Velocity**：8 points（5 Stories）

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

## Sprint 53 — 完成

**Sprint Goal**：完成 ADR-014 全部三個 Phase 的 SKILL.md 定義（UX Agent / UI Agent / Vision Critic），決策 OQ-1 與 OQ-3 開放問題，並設計三層 Agent 管線端對端整合測試規格，使 UIUX Agent 工作流從架構決策走向完整的可執行 Skill 定義。
**期間**：2026-03-06 ~ 2026-03-12
**結果**：Goal 達成（6/6 Stories PASS）。Velocity 10 points，完成率 100%。三層 Agent 管線 SKILL.md 全部交付（UX Agent / UI Agent / Vision Critic），ADR-014 OQ-1/OQ-3 決策完成，SDD-UIUX-E2E 整合測試規格建立。
**Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| 前置任務：ADR-014 Proposed → Accepted | — | — | 0 | 完成 |
| US-105：UX Agent SKILL.md 實作 | #112 | M | 2 | 完成 |
| OQ-1：Playwright 截圖可行性調查 | #109 | S | 1 | 完成 |
| OQ-3：Vision Critic 通過閾值量化決策 | #111 | S | 1 | 完成 |
| US-106：UI Agent SKILL.md 實作 | #113 | M | 2 | 完成 |
| US-107：Vision Critic Agent SKILL.md 實作 | #114 | M | 2 | 完成 |
| US-108：三層 Agent 管線端對端整合測試設計 | #115 | M | 2 | 完成 |

**目標 Velocity**：10 points（6 Stories）

## Sprint 53 統計
- Velocity：10 points
- 完成率：100%（完成 6 / 計畫 6）
- 日期：2026-03-06

---

## Sprint 52 — 完成

**Sprint Goal**：建立 UIUX Agent 工作流的「防呆設計基礎」—— 定義機器可讀的 Design Tokens 規格、強制元件庫白名單，以及前端 Story AC 模板注入機制，使 ADR-014 Phase 1 具體落地。
**期間**：2026-03-06 ~ 2026-03-12
**結果**：Goal 達成（2/2 Stories PASS）。Velocity 2 points，完成率 100%。ADR-014 Phase 1 具體落地：Design Tokens 機器可讀規格（design-tokens.json）建立、前端 SDD 模板標準化、issue-management 前端 Story AC 自動注入機制上線。
**Stakeholder 驗收**：接受

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-103（#104）：Design Tokens 定義檔建立 | S | 1 | 完成 |
| US-104（#105）：元件庫白名單 AC 注入機制 | S | 1 | 完成 |

**目標 Velocity**：2 points（2 Stories）

## Sprint 52 統計
- Velocity：2 points
- 完成率：100%（完成 2 / 計畫 2）
- 日期：2026-03-06

---

## Sprint 51 — 完成

**Sprint Goal**：結案 backlog-intake 修正，並為 UIUX Agent 建立架構決策基礎（ADR-014），為後續 UI/UX 自動化實作鋪路。
**結果**：Goal 達成（2/2 Stories PASS）。Velocity 2 points，完成率 100%。Issue #102 正式結案；ADR-014（UIUX Agent 架構決策）Proposed，識別 6 個後續 Story 方向。
**Stakeholder 驗收**：接受
**期間**：2026-03-06 ~ 2026-03-12

## Sprint 51 統計
- Velocity：2 points
- 完成率：100%（完成 2 / 計畫 2）
- 日期：2026-03-06

## Sprint 外完成項目（/shoot 短衝記錄）

| 日期 | 來源 | 標題 | commit hash |
|------|------|------|-------------|
| 2026-03-06 | direct | backlog-intake Skill 整併至 issue-management §11，消除重複邏輯 | 174b86b |

---

## Sprint 50 — 完成

**Sprint Goal**：完成 shikigami:diagram 技能文件整合 — 補充自動嵌入 Markdown 步驟與 Issue 回覆附圖指引，使 diagram 技能達到完整可交付狀態，並關閉父 Issue #89。
**結果**：Goal 達成（1/1 Stories PASS）。Velocity 1 point，完成率 100%。Issue #89 三個子 Stories（US-97/98/99）跨 Sprint 48-50 完整交付，ADR-013 從 Proposed 升為 Accepted 閉環。
**Stakeholder 驗收**：接受
**期間**：2026-03-05 ~ 2026-03-11

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-99（#98）：shikigami:diagram 文件整合 — 自動嵌入 Markdown、Issue 回覆附圖、關閉 #89 | S | 1 | 完成 |

**目標 Velocity**：1 point（1 Story）
**實際 Velocity**：1 point（1 Story）

---

## Sprint 49 — 完成

**Sprint Goal**：實作 `shikigami:diagram` SKILL.md 核心功能 — 雙格式輸出、多圖標集切換、ADR-006 XML 隔離，讓 diagram 技能達到可執行狀態。
**結果**：Goal 達成（1/1 Stories PASS）。Velocity 2 points，完成率 100%。ADR-013 升級為 Accepted，SKILL.md 雙格式輸出路徑（.drawio MCP 操控 + PNG/SVG 手動匯出）在 v1.8.0 能力邊界內完整定義。
**Stakeholder 驗收**：接受
**期間**：2026-03-05 ~ 2026-03-11

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-98（#97）：shikigami:diagram SKILL.md 實作 — 雙格式輸出、--provider、ADR-006 XML 隔離 | M | 2 | 完成 |

**目標 Velocity**：2 points（1 Story）
**實際 Velocity**：2 points（1 Story）

---

> 歷史 Sprint 記錄：[PROJECT_BOARD_ARCHIVE](km/archive/PROJECT_BOARD_ARCHIVE.md)（Sprint 1–48）
