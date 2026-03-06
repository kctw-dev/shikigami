# Retrospective Log

> 歷史 Retro 記錄：[RETRO_ARCHIVE](archive/RETRO_ARCHIVE.md)（Sprint 1–48）

---

## Sprint 55 — 2026-03-06

**Sprint Goal**：建立 Figma 整合環境基礎 — 完成 MCP Server 選型與本地設定驗證、Figma 文件結構定義，並執行 AI 透過 Figma MCP 生成 Frame 的端對端 PoC，確認 ADR-015 Phase 1 技術路徑可落地。

### Good

1. ADR-015 Figma 整合方向確立後首個 Sprint，5 Stories / 8 Points 全數交付（100% 完成率），是 Sprint 54 中止後快速重新聚焦的成功案例
2. 平行分群策略有效：Phase 0（US-149 獨立先行）→ Phase 1（US-145 阻塞點優先）→ Phase 2（US-146 + US-148 並行）→ Phase 3（US-147 序列收尾）的四階段分群零衝突完成，整體依賴關係管理清晰
3. 靜態交付品質超出最低要求：docs/guides/figma-mcp-setup.md、docs/design/figma-structure-guide.md、docs/design/component-library-spec.md、docs/design/poc-frame-generation-guide.md 四份文件均包含完整 Step-by-Step 操作指引，使用者可直接依照指引完成本地驗證

### Problem

1. US-145/US-148/US-147 動態 AC 無法在 CLI 環境驗證：三個 M-size Story（共 6 Points，佔 Sprint 75%）的核心驗收條件（MCP 連接、Figma 寫入、截圖讀取）均需 Figma Desktop App + claude-talk-to-figma-mcp Plugin 連接才能執行，CLI 環境根本性無法完成動態驗證，導致靜態規格交付與動態驗收存在落差
2. Sprint 55 與 54 均為同日（2026-03-06）執行，DORA 變更失敗率 100%（Structural Validation 全數失敗，Issue #101 持續影響），CI 健康狀況持續惡化

### Action Items

| # | 行動 | 負責人 | 狀態 | Issue |
|---|------|--------|------|-------|
| 1 | 建立 Figma Desktop 本地驗證環境 SOP，標準化 MCP 連接與動態 AC 驗證流程 | Developer | Open | #151 |

---

## Sprint 54 — 2026-03-06（中止）

**中止原因**：ADR-015 架構轉型決策 — Figma 整合取代 ADR-014 三層 SSD 管線。20 個待辦 Story 中 14 個直接綁定舊管線（DROP），6 個需重寫 AC（MODIFY），繼續執行無意義。

### Good
- 架構方向轉型決策及時：在 Sprint 54 執行初期即完成 ADR-015 四個 OQ 調查（Figma MCP 能力邊界、REST API 限制、代碼生成路徑、授權成本），避免在過時的三層 SSD 管線上投入 37+ points 的無效工作量
- ADR-015 調查品質高：四個 OQ 均已產出可行性結論與具體限制摘要，為後續 Figma 整合 Phase 1 提供清晰的技術前提
- Sprint 54 已完成的 9 Stories（11 points）中，US-116（模型分層策略）、US-121（Gemini CLI 調查）、US-128（退件報告儲存）等概念在 Figma 方案下仍可延續

### Problem
- Sprint 54 規劃了 29 Stories / 50 points 的工作量，但架構方向在同日轉型，暴露出 Sprint Planning 與架構決策的時序問題：ADR-015 的四個 OQ 調查在 Sprint 54 Planning 之後才完成
- 14 個 GitHub Issues 需批次關閉，6 個需註記回 Backlog，Sprint 中止的行政成本不低

### Action Items

| # | 行動 | 負責人 | 狀態 |
|---|------|--------|------|
| 1 | ADR-015 狀態從 Proposed 升級為 Accepted | Architect | Open |
| 2 | Sprint 55 Planning 基於 Figma 整合演進路徑規劃 | Product Owner | Open |

---

## Sprint 53 — 2026-03-06

### Good
- Sprint 53 創下專案歷史最高 Velocity（10 points / 6 Stories），是前三個 Sprint（S51=2, S52=2）的 5 倍；三階段平行分群策略（Phase 1 三路並發 + Phase 2 雙路並發 + Phase 3 序列）零衝突完成
- 6 個 doc-only Stories 全部一次 PASS，Story-Lifecycle subagent 自審閉環有效，無修復循環
- ADR-014 從 Proposed 升級至 Accepted，三個 Open Questions（OQ-1/OQ-2/OQ-3）全部關閉，架構決策完整閉環
- 三層 Agent 管線（UX Agent / UI Agent / Vision Critic）SKILL.md 全部交付，含完整 JSON Schema 定義；SDD-UIUX-E2E 整合測試規格建立（5 個測試案例 + 三層降級策略），Phase 2/3 完整落地

### Problem
- DORA 變更失敗率 71.4% 偏高，CI Structural Validation 持續受 Issue #101 影響（已知基礎設施限制）
- Velocity 從 2 跳至 10（+400%），波動過大，反映前幾個 Sprint 容量偏低而非本 Sprint 過高；需在後續 Sprint 驗證 10+ points 是否為可持續的執行節奏

### Action Items

本 Sprint 無新增 Action Items。上述 Problem 說明：
- CI 失敗為 Issue #101 持續追蹤，非 Retro Action 範圍
- Velocity 波動為容量調整過程，下個 Sprint 目標 20 points 將驗證可持續性

---

## Sprint 52 — 2026-03-06

### Good
- 100% 完成率連續第 52 個 Sprint 維持，Sprint Goal 達成
- ADR-014 Phase 1 兩個基礎 Story（US-103/US-104）同日完成，平行分群策略零衝突
- Design Tokens 規格品質超出最低要求（各群組 3+ token，實際交付 40+ token），PO 驗收一次通過
- Story-Lifecycle subagent 自審閉環有效，US-103/US-104 均 PASS 無需修復循環

### Problem
- CI Structural Validation 持續失敗（run #22753333025），已知基礎設施限制（Issue #101 追蹤中）
- ADR-014 狀態仍為 Proposed，Phase 1 已落地但 ADR 生命週期未推進至 Accepted（Stakeholder 回饋）
- DORA Metrics 資料多為「資料不足」，Sprint 當日即執行 Review 導致資料採集不完整

### Action Items

本 Sprint 無新增 Action Items。上述 Problem 說明：
- CI 失敗為 Issue #101 持續追蹤，非 Retro Action 範圍
- ADR-014 狀態升級為 Sprint 53 Planning 前置任務，由 Architect 執行
- DORA 資料不足為結構性時間差問題，不需額外行動

---

## Sprint 51 — 2026-03-06

**Sprint Goal**：結案 backlog-intake 修正，並為 UIUX Agent 建立架構決策基礎（ADR-014）

### Good（保持做的事）

1. ADR-014 起草品質高：三方案對比（三層分工 / 統包 / 雙層分工）+ 四階段分期策略 + 6 個後續 Story 方向，Vision Critic 截圖技術可行性有明確三面向評估，Stakeholder 建議 Phase 1 Design Tokens 優先落地被立即採納
2. Issue #102 結案閉環完整：修正摘要 comment + 端對端 workflow 觸發驗證（17s 內 queued），Issue 生命週期管理到位
3. 連續 6 個 Sprint（Sprint 46–51）100% 完成率，Sprint Goal 均達成，執行紀律持續穩定
4. backlog-intake Skill 整併至 issue-management §11 的短衝（/shoot）在 Sprint 外完成，框架精簡化持續推進

### Problem（需改進的事）

1. CI Structural Validation 連續 3 次失敗：Sprint 51 Execution CI 快掃發現最近 3 次 workflow 均為 failure，變更失敗率 40.9%，需調查根因（可能與 backlog-intake 整併後的結構變更相關）
2. self-hosted runner 無可用節點：US-100 AC2 端對端驗證因 runner 不在線而無法完整執行 body 改寫驗證，僅能確認觸發機制。需確保 runner 持續可用或建立替代驗證方案

### Action Items

本 Sprint 無新增 Action Items。CI 失敗與 runner 問題為已知基礎設施限制（Issue #101 追蹤中），不需建立新的 retro-action。

---

## Sprint 50 — 2026-03-05

**Sprint Goal**：完成 shikigami:diagram 技能文件整合 — 補充自動嵌入 Markdown 步驟與 Issue 回覆附圖指引，使 diagram 技能達到完整可交付狀態，並關閉父 Issue #89

### Good（保持做的事）

1. Issue #89 三個子 Stories（US-97/98/99）跨 Sprint 48-50 完整交付：子 Story A（環境準備）→ 子 Story B（SKILL.md 實作）→ 子 Story C（文件整合）序列拆分清晰，每個 Sprint 各自聚焦，無 Scope Creep，父 Issue #89 在最終子 Story 交付後乾淨關閉
2. ADR-013 從 Proposed 升為 Accepted 閉環：架構決策與技能實作雙線收斂，Sprint 47 起草、Sprint 48 OQ 回填、Sprint 49 Accepted 升級路徑完整，知識管理形成完整閉環
3. 連續 5 個 Sprint（Sprint 46–50）100% 完成率，Sprint Goal 均達成，執行紀律持續穩定

### Problem（需改進的事）

目前無明顯問題。

### Action Items

本 Sprint 無新增 Action Items。

---

## Sprint 49 — 2026-03-05

**Sprint Goal**：實作 `shikigami:diagram` SKILL.md 核心功能 — 雙格式輸出、多圖標集切換、ADR-006 XML 隔離，讓 diagram 技能達到可執行狀態

### Good（保持做的事）

1. US-98 PASS，SKILL.md 完整涵蓋 AC1–AC5：雙格式輸出路徑（.drawio MCP 操控 + PNG/SVG 手動匯出）在 v1.8.0 能力邊界內清楚定義，--provider enum 驗證、ADR-006 XML 隔離均有具體實作宣告；ADR-013 順利從 Proposed 升為 Accepted
2. Sprint 48 Retro Action Item #1（AC2 雙格式輸出通過標準對齊 v1.8.0）在本 Sprint AC2 設計中完整落地，前一 Sprint 識別的問題得到直接回應
3. 連續 49 個 Sprint 100% 完成率，Sprint Goal 達成（1/1 Story PASS），執行紀律穩定

### Problem（需改進的事）

1. SKILL.md §5.2 PNG/SVG 匯出目前完全依賴手動操作（Draw.io UI 或桌面應用）；對於需要將圖表嵌入 Markdown 或回覆 GitHub Issue 的場景，缺乏明確的操作指引，需在子 Story C 補充文件整合步驟
2. Issue #89 父 Issue 尚未關閉，待子 Story C 完成後一併處理，避免 Issue 長期開著影響 Backlog 整潔度

### Action Items

1. Sprint 50 排入子 Story C：補充 SKILL.md 自動嵌入 Markdown 步驟與 GitHub Issue 回覆附圖指引，完成後關閉父 Issue #89

---
