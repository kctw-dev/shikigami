# Sprint 64

**Sprint Goal**：清空 Backlog，終結所有懸而未決的 Open Issues — 評估並結案或推進 #159（多模型 CLI Phase 3 方向決策）、#59（Beta 回饋機制評估結案）、#5（Marketplace 上架現狀評估）、#4（Cursor 平台現狀評估）。

**期間**：2026-03-08 ~ 2026-03-14
**狀態**：完成
**ADR 依賴**：無

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-171：多模型 CLI 路由 Phase 3 方向決策 — Issue #159 結案或規劃後續 | #159 | S | 1 | 完成 |
| US-172：Beta 回饋機制評估與結案 — Issue #59 現狀審查 | #59 | S | 1 | 完成 |
| US-173：Marketplace 上架現狀審查 — Issue #5 結案決策 | #5 | S | 1 | 完成 |
| US-174：Cursor 平台現狀審查 — Issue #4 結案決策 | #4 | S | 1 | 完成 |

## 平行分群

Phase 1（平行）：US-171、US-172、US-174
Phase 2（序列）：US-173（待 Phase 1 完成後執行）

## 方法論適用性評估

| Story ID | BDD 建議 | DDD 建議 | 說明 |
|----------|---------|---------|------|
| US-171 | 不適用 | 不適用 | 決策文件化，無行為規格需求 |
| US-172 | 不適用 | 不適用 | 評估 + GitHub Issue 操作 |
| US-173 | 不適用 | 不適用 | 評估 + GitHub Issue 操作 |
| US-174 | 不適用 | 不適用 | WebSearch 調查 + 決策文件化 |

## Acceptance Criteria

### US-171：多模型 CLI 路由 Phase 3 方向決策

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | [靜態] Phase 0-2 成果彙整 | 在 Issue #159 留下評論，彙整 Phase 0（Gemini CLI 調查）、Phase 1（Adapter 介面設計與實作）、Phase 2（開源評估，維持自建）三個 Phase 的完成成果摘要 |
| AC2 | [靜態] Phase 3 必要性評估 | 評估是否有明確的 Phase 3 需求（例如：新增第二個 CLI 整合、路由規則設計、或 Codex CLI 整合）；若無立即業務需求，記錄延後理由 |
| AC3 | [動態] 結案或後續 Story 提案二選一 | 若評估結論為「目前不需要 Phase 3」：關閉 Issue #159，並在 ROADMAP.md 補記結案狀態。若評估結論為「需要 Phase 3」：在 Issue #159 新增 Phase 3 具體 Story 提案（標題 + AC 草稿），Issue 維持 OPEN |
| AC4 | [靜態] 框架文件對齊 | docs/PROJECT_BOARD.md 中記錄 Sprint 64 US-171 完成狀態 |

### US-172：Beta 回饋機制評估與結案

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | [動態] 現狀審查 | 確認 Issue #59 自建立以來是否收到任何外部使用者回饋（留言數、回饋質量）；紀錄審查結果 |
| AC2 | [靜態] 策略對齊評估 | 對照 2026-03-06 PO 決策（開源延後 2 年、M5 condition (a) 不再主動推進）評估 Issue #59 繼續保持 OPEN 的必要性 |
| AC3 | [動態] 結案決策執行 | 在 Issue #59 留下 PO 評論說明結案理由（策略調整 + 現狀記錄），關閉 Issue #59；或若有明確理由保持開放，記錄保持 OPEN 的具體條件 |
| AC4 | [動態] README 連結處理 | 若 Issue #59 關閉：確認 README 中是否有引導使用者至 #59 的連結，若有則移除或更新為更合適的聯絡方式 |

### US-173：Marketplace 上架現狀審查

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | [動態] 前置條件現狀核查 | 逐項核查 Issue #5 中列出的上架前置清單（版本號、安裝文件、外部回饋、README、plugin.json schema），記錄當前狀態（達成 / 未達成 / 已過時） |
| AC2 | [靜態] 策略對齊評估 | 對照 2026-03-06 PO 決策（開源延後 2 年）評估：現階段追求官方 Marketplace 上架是否仍符合產品策略 |
| AC3 | [動態] 結案或延後決策執行 | 若評估結論為「現階段上架不符策略」：在 Issue #5 留下 PO 評論說明延後（或結案）理由，關閉或標注延後至具體里程碑；若評估結論為「條件成熟可準備申請」：列出具體下一步行動項目 |
| AC4 | [靜態] ROADMAP 對齊 | docs/prd/ROADMAP.md 中 v1.0.0 區塊的 Issue #5 狀態記錄與本次決策結果一致 |

### US-174：Cursor 平台現狀審查

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | [動態] Cursor 版本現狀調查 | 透過公開資訊（release notes、官網、社群）確認 Cursor 目前最新版本號，以及程式化 Task tool API 是否已開放；紀錄調查結果與資料來源 |
| AC2 | [靜態] 策略對齊評估 | 對照 2026-03-06 PO 決策（框架方向：輕量化、好上手、人機協作）評估多平台擴張的優先性 |
| AC3 | [動態] 繼續等待或結案決策 | 若 Cursor v2.5+ Task tool API 已開放：在 Issue #4 留下評論說明現狀，並提出 POC Sprint Story 草稿，Issue 維持 OPEN；若尚未開放且策略優先性低：在 Issue #4 留下 PO 評論說明結案理由，關閉 Issue #4 |
| AC4 | [靜態] ROADMAP 對齊 | docs/prd/ROADMAP.md 中 Cursor 平台決策記錄與本次評估結論一致 |
