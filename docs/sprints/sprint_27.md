# Sprint 27

**狀態**：完成
**期間**：2026-03-09 ~ 2026-03-15
**Sprint Goal**：完成 ADR-008 架構決策 + 啟動 OpenCode Phase 2，為 M5 條件 (a) 外部使用者觸及提供完整平台整合策略與首個角色移植驗證
**總計**：2 Stories / 4 Points

---

## Sprint Backlog

| Story ID | 標題 | Size | Points | 狀態 |
|----------|------|------|--------|------|
| US-47 | ADR-008: OpenCode 平台整合策略架構決策 | S | 1 | 完成 |
| US-48 | OpenCode Phase 2 — Subagent 角色移植與派遣驗證 | L | 3 | 完成 |

**Sprint 容量**：4 Points

---

## Story 詳細 AC

---

### US-47：ADR-008: OpenCode 平台整合策略架構決策

**來源**：US-46 Phase 1 建議 / OPENCODE_POC.md §8.4
**Size**：S / 1 Point
**Owner**：Architect

**User Story**
As a Product Owner and Architect, I want ADR-008 formally documenting the OpenCode platform integration strategy and architecture decision, so that the team has a clear, accepted technical foundation before committing to Phase 2 subagent migration effort.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | ADR-008 文件建立 | 新建 `docs/adr/ADR-008.md`，含 Context、Decision、Consequences 三大區塊；Context 區塊涵蓋 subagent 設定檔路徑策略（含路徑規範與格式選型依據） |
| AC2 | [靜態] | Decision 區塊完整性 | Decision 區塊明確記錄 OpenCode 平台整合的技術策略選擇，含：(a) 目錄結構策略、(b) SKILL.md 對映方式、(c) subagent 派遣方式 |
| AC3 | [靜態] | Consequences 區塊完整性 | Consequences 區塊列出正面／負面影響，並具體列出每項負面影響的風險緩解策略（mitigation），不得僅列風險而無 mitigation |
| AC4 | [靜態] | ADR 狀態 | ADR-008 狀態欄位標記為 `Accepted` |

---

### US-48：OpenCode Phase 2 — Subagent 角色移植與派遣驗證

**來源**：OPENCODE_POC.md Phase 2 定義 / M5 外部使用者觸及
**Size**：L / 3 Points
**Owner**：Developer
**依賴**：US-47（ADR-008 Accepted 後方可進入 Group B）

**User Story**
As a Product Owner targeting OpenCode platform expansion, I want the first Shikigami subagent role ported to OpenCode format and dispatch-verified, so that Phase 2 establishes a validated subagent migration pattern before full five-role migration.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | Subagent 設定檔審查 | 審查現有 subagent 角色設定，產出 OpenCode 相容性差異清單；設定檔依 ADR-008 定義的設定檔路徑與格式規範建立；審查結果記錄於 `docs/km/OPENCODE_POC.md` §9 |
| AC2 | [靜態] | 首個角色 prompt 移植 | 選取一個代表性角色（如 Developer），移植至 OpenCode subagent 格式；設定檔依 ADR-008 定義的設定檔路徑與格式規範存放 |
| AC3 | [靜態] | Phase 1 殘留項修正 | 修正 US-46 AC3 識別的殘留項（R-1~R-7）；「修正」定義為以下兩種方式之一：(a) 替換為 OpenCode 等效語法（replace）；(b) 雙平台標注（dual-platform annotation，保留原 Claude Code 語法並補充 OpenCode 對應說明），不可僅刪除原語法而不補充替代 |
| AC4 | [靜態] | 移植靜態驗證 | 靜態審查移植後的角色 prompt，確認其符合 OpenCode subagent 設定規範（格式、必填欄位、路徑）；完成記錄於 `docs/km/OPENCODE_POC.md` §9 |
| AC5 | [靜態] | Phase 2 結論文件更新 | 於 `docs/km/OPENCODE_POC.md` §9 新增 Phase 2 完成記錄，包含：(a) 移植差異清單；(b) 選取角色與移植結果摘要；(c) 殘留項修正方式說明；(d) 靜態驗證結論 |

---

## 平行分群（Architect 建議）

### Group A → Group B 序列執行

| 群組 | Stories / ACs | 說明 |
|------|--------------|------|
| Group A | US-47（全部 AC1~AC4）+ US-48 AC1 | 先完成 ADR-008，同時執行 US-48 AC1 的設定檔審查（審查可獨立進行，不依賴 ADR-008 最終內容） |
| Group B | US-48 AC2~AC5 | ADR-008 Accepted 後執行；AC2 依據 ADR-008 的設定檔路徑規範進行移植，AC3~AC5 依序完成 |

**執行順序說明**：
- Group A：US-47 AC1 → AC2 → AC3 → AC4（ADR-008 建立到 Accepted）；US-48 AC1 可與 US-47 平行執行（審查不依賴 ADR-008 最終內容，但建立設定檔時需等 ADR-008 Accepted）
- Group B（觸發條件：ADR-008 狀態 = Accepted）：US-48 AC2 → AC3 → AC4 → AC5
- US-48 AC4 為靜態驗證，與 US-46 AC4 同等模式（不含動態實機執行）

---

## 工作容量

| 項目 | 數值 |
|------|------|
| Sprint 期間 | 2026-03-09 ~ 2026-03-15（7 天） |
| 總 Stories | 2 |
| 總 Points | 4 |
| 平行分群 | Group A（US-47 全部 + US-48 AC1）→ Group B（US-48 AC2-AC5） |

---

## ADR 觸發清單

| Story | ADR 編號 | 說明 |
|-------|----------|------|
| US-47 | ADR-008 | 本 Story 即為 ADR-008 建立 Story；無前置 ADR 依賴 |
| US-48 | ADR-008（引用） | US-48 AC1/AC2 依據 ADR-008 定義的設定檔路徑與格式規範執行；ADR-008 為前置條件 |

**本 Sprint 新建 ADR-008（OpenCode 平台整合策略）。**

---

## Sprint Planning 簽核

- **PO Round 1**：完成（Story 選取：US-47 S/1pt + US-48 L/3pt；Sprint Goal 確定；總計 4pt；US-47 AC 確認 PASS；US-48 AC 待確認；US-47 獨立，US-48 與 US-47 序列依賴）
- **Architect Round 1**：完成（US-47 S/1pt 確認，無 ADR 前置依賴；US-48 L/3pt 確認，AC4 降級為靜態驗證；平行分群 Group A = US-47 全部 AC + US-48 AC1，Group B = US-48 AC2-AC5，觸發條件為 ADR-008 Accepted；建議 ADR-008 涵蓋 subagent 設定檔路徑策略）
- **QA Round 1**：完成（US-47 PASS 附條件：AC1 subagent 路徑策略深度為條件，AC3 mitigation 明確性已標注；US-48 NEEDS_REVISION 3 項：NEEDS_REVISION-1 設定檔路徑與格式規範依據缺失，NEEDS_REVISION-2「修正」定義模糊，NEEDS_REVISION-3 記錄位置未指定節號）
- **PO Round 2**：完成（整合 QA NEEDS_REVISION 反饋與 Architect 建議：US-48 AC1/AC2 補述「依 ADR-008 定義的設定檔路徑與格式規範」；AC3 明確「修正」定義為 replace 或 dual-platform annotation；AC4 降級為靜態驗證並指定記錄位置 OPENCODE_POC.md §9；AC5 指定記錄位置 OPENCODE_POC.md §9；Sprint Backlog 最終確認）
