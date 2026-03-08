# Retrospective Log

> 歷史 Retro 記錄：[RETRO_ARCHIVE](archive/RETRO_ARCHIVE.md)（Sprint 1–53）

---

## Sprint 57 — 2026-03-08

**Sprint Goal**：鞏固 ADR-015 Phase 1 文件一致性 — 同步 Vision Critic SKILL.md 至 Figma 架構、標記舊 UX/UI Agent 文件為 Deprecated。

### Good

1. Sprint 57 2/2 Stories PASS，2 Points，100% 完成率。ADR-015 Phase 1 文件一致性目標完整達成，Vision Critic SKILL.md 已同步 Figma 架構、UX/UI Agent SKILL.md 已標記 Deprecated
2. 平行執行有效：US-153 + US-154 兩個獨立 doc-only Story 同時派遣 Developer subagent，零衝突完成
3. Sprint Planning 期間主動執行 Backlog 批次清理，關閉 5 個 ADR-014 汙染的 Issues（#142、#143、#130、#140、#144），為 Sprint 58 建立乾淨的 Backlog 管線

### Problem

1. CI Structural Validation 持續失敗（Issue #101），DORA 變更失敗率維持 100%（連續 Sprint 55-56-57 三個 Sprint），部署頻率 0.00 次/天，CI 健康狀況連續三個 Sprint 未改善
2. Sprint 容量嚴重受限（2 pts，遠低於歷史平均 5-8 pts）：ADR-014→015 架構轉型導致多數 Backlog 候選 Story 的 AC 過時，Planning 階段 3 個候選 Story 被退回（US-120 已完成、US-118/US-143 架構衝突），可選入的 Story 池過淺

### Action Items

本 Sprint 無新增 Action Items。上述 Problem 說明：
- CI 失敗為 Issue #101 持續追蹤，非 Retro Action 範圍
- Backlog 汙染已在 Sprint 57 Planning 期間批次清理完成（5 個 Issues 關閉），下 Sprint 建議優先建立 ADR-015 對齊的新 Backlog Items

---

## Sprint 56 — 2026-03-06

**Sprint Goal**：驗證 UIUX Figma 管線可運作性 — 建立 Figma Desktop 本地驗證環境 SOP、定義 Vision Critic Frame 截圖審查 PoC 規格、撰寫 Figma 管線使用指南，使 ADR-015 Phase 1 從技術文件走向可操作的驗證與使用文件。

### Good

1. Sprint 56 3/3 Stories PASS，5 Points，100% 完成率。ADR-015 Phase 1 從技術基礎完整轉化為可操作的驗證與使用文件，Sprint Goal 完整達成
2. 平行分群策略有效：Phase A（US-150 獨立先行）→ Phase B（US-151 + US-152 並行）兩階段分群零衝突完成
3. Sprint 55 Retro Action Item #1（Issue #151，Figma Desktop SOP）在 Sprint 56 即時交付（1 Sprint 關閉速度），閉環有效

### Problem

1. CI Structural Validation 持續失敗（Issue #101），DORA 變更失敗率維持 100%（連續 Sprint 55-56），部署頻率 0.00 次/天，CI 健康狀況持續惡化
2. Sprint 54 的兩個 Retro Action Items（ADR-015 升級為 Accepted、Sprint 55 Planning 規劃）已實質完成但未在 Sprint 55 Retro 中明確標記 Closed，生命週期管理有缺口

### Action Items

本 Sprint 無新增 Action Items。上述 Problem 說明：
- CI 失敗為 Issue #101 持續追蹤，非 Retro Action 範圍
- Sprint 54 Action Items 已實質完成（ADR-015 已 Accepted、Sprint 55 已基於 Figma 整合路徑規劃並交付），於本 Sprint Retro 正式確認 Closed

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
| 1 | 建立 Figma Desktop 本地驗證環境 SOP，標準化 MCP 連接與動態 AC 驗證流程 | Developer | Closed（Sprint 56 US-150 交付） | #151 |

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
| 1 | ADR-015 狀態從 Proposed 升級為 Accepted | Architect | Closed（Sprint 55 前已完成，Sprint 56 Retro 正式確認） |
| 2 | Sprint 55 Planning 基於 Figma 整合演進路徑規劃 | Product Owner | Closed（Sprint 55 已執行 Figma 整合 Phase 1，Sprint 56 Retro 正式確認） |

---

