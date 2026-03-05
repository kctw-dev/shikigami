# Sprint 49

**狀態**：完成
**期間**：2026-03-05 ~ 2026-03-11
**Sprint Goal**：實作 `shikigami:diagram` SKILL.md 核心功能 — 雙格式輸出、多圖標集切換、ADR-006 XML 隔離，讓 diagram 技能達到可執行狀態。
**總計**：1 Story / 2 Points

---

## Sprint Backlog

| Story ID | Issue # | 標題 | Size | Points | Phase | 狀態 |
|----------|---------|------|------|--------|-------|------|
| US-98 | #97 | shikigami:diagram SKILL.md 實作 — 雙格式輸出、--provider、ADR-006 XML 隔離 | M | 2 | Phase 1 | 完成 |

**Sprint 容量**：2 Points

---

## 平行分群方案

| Phase | Stories | 說明 |
|-------|---------|------|
| Phase 1 | US-98 | 單一 Story，無並行需求 |

---

## Story 詳細 AC

---

### US-98：shikigami:diagram SKILL.md 實作 — 雙格式輸出、--provider、ADR-006 XML 隔離

**來源**：Issue #97（Issue #89 子 Story B）
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：Yes（SKILL.md 為靜態文件；AC5 ADR 狀態更新為文件操作）
**前置 ADR**：ADR-013（OQ-1/OQ-2 已回填，狀態 Proposed）
**父 Issue**：#89（feat: shikigami:diagram 技能）
**前置 Story**：US-97（#96）— Sprint 48 完成

**User Story**

As a Developer subagent, I want a `shikigami:diagram` SKILL.md that orchestrates drawio-mcp-server MCP tools to build architecture diagrams with official cloud icons, outputs both editable (.drawio) and embeddable (.png/.svg) formats, supports multi-provider icon sets, and applies ADR-006 XML isolation for all MCP tool outputs, so that diagram generation becomes a repeatable, automated skill within Sprint execution.

**背景（Sprint 48 重要發現）**

ADR-013 OQ-2 回答揭示：drawio-mcp-server v1.8.0 不直接產出 PNG/SVG（無 headless Chrome rendering）。技能設計需從「產出圖片檔案」調整為「操控 Draw.io diagram 狀態」，雙格式輸出路徑須在 v1.8.0 能力邊界內定義（手動匯出或替代方案）。

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | SKILL.md 建立 | `skills/diagram/SKILL.md` 存在，包含完整 skill 描述、觸發條件、步驟序列與 Done 定義 |
| AC2 | [靜態] | 雙格式輸出定義 | SKILL.md 明確定義雙格式輸出路徑：.drawio 透過 MCP tools 操控後由 Draw.io 編輯器匯出，PNG/SVG 嵌入方式明確；若 v1.8.0 工具集限制無法自動匯出，需在 SKILL.md 說明手動匯出步驟或替代方案 |
| AC3 | [靜態] | --provider 多圖標集切換 | SKILL.md 定義 `--provider gcp`、`--provider aws`、`--provider azure` 參數處理邏輯；參數值限制為 enum（gcp / aws / azure），拒絕允許清單外的輸入（ADR-013 §4.3 防護） |
| AC4 | [靜態] | ADR-006 XML 隔離標記 | SKILL.md 在「MCP tool 呼叫後處理」步驟中聲明：所有 drawio-mcp-server 回傳的 tool 輸出（type: "text" JSON）均以 `<mcp_tool_output>...</mcp_tool_output>` XML 標記包裹後傳入後續 prompt |
| AC5 | [文件] | ADR-013 狀態更新 | ADR-013 狀態從 Proposed 更新為 Accepted（本 Story 實作確認決策可執行） |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 2 | 影響所有需架構圖的 Sprint 執行場景 |
| Impact | 3 | 建立可重複執行的 diagram 自動化技能，消除手動繪圖瓶頸 |
| Confidence | 0.8 | ADR-013 決策已確立，技術路徑 Sprint 48 驗證可行；主要工作為 SKILL.md 設計與 v1.8.0 能力邊界對齊 |
| Effort | 2 | M-size；SKILL.md 設計 + --provider 邏輯 + ADR-006 整合 |
| **RICE Score** | **3.0** | R×I×C/E |

**Done 定義**

- [ ] `skills/diagram/SKILL.md` 建立完成（AC1）
- [ ] 雙格式輸出路徑（.drawio + PNG/SVG）在 v1.8.0 能力邊界內明確定義（AC2）
- [ ] --provider gcp/aws/azure 邏輯與 enum 驗證定義（AC3）
- [ ] ADR-006 `<mcp_tool_output>` XML 隔離標記應用宣告（AC4）
- [ ] ADR-013 狀態更新為 Accepted（AC5）

---

## ADR 觸發清單

| Story | ADR | 觸發原因 | 動作 |
|-------|-----|----------|------|
| US-98 | ADR-013 | 實作確認決策可執行，狀態應從 Proposed 升為 Accepted | 更新 ADR-013 §狀態 |
| US-98 | ADR-006 | SKILL.md 必須宣告 MCP tool 輸出 XML 隔離應用 | SKILL.md AC4 實作確認 |

---

## Issue #89 拆分進度

| 子 Story | Issue | Size | 主要工作 | 狀態 |
|----------|-------|------|----------|------|
| 子 Story A（US-97） | #96 | S | 環境準備 + OQ-1/OQ-2 解決 | 完成（Sprint 48） |
| 子 Story B（US-98） | #97 | M | SKILL.md 實作（雙格式輸出、--provider、ADR-006 XML 隔離） | 本 Sprint |
| 子 Story C | 待建立 | S | 文件整合（自動嵌入 Markdown、Issue 回覆附圖） | 待子 Story B 完成後規劃 |

---

## Sprint Planning 簽核記錄

| 角色 | 確認項目 | 狀態 |
|------|----------|------|
| Product Owner | Sprint Goal 對齊子 Story B 實作，Backlog 拆分序列一致，RICE Score 支持排序 | 已確認 |
| Architect | M-size 合理（SKILL.md 設計 + ADR-013 Accepted 更新），ADR-006 應用路徑清晰 | 已確認 |
| QA | doc-only 判定：AC1-AC5 均為靜態文件 AC，無動態執行需求 | 已確認 |
| Developer | Story 清晰度確認 | 待確認 |

**Sprint Planning 決策記錄**

- Sprint 49 選入 1 Story（US-98 #97），共 2 Points
- Issue #89 子 Story B 排入本 Sprint，與子 Story A 完成後的自然拆分序列一致
- 子 Story C 待子 Story B 完成後依序納入 Sprint 50
- 目標 Velocity：2 Points
- Sprint 48 Retro Action Item #1（AC2 雙格式輸出通過標準對齊 v1.8.0）已反映於本 Sprint AC2 設計
