# Sprint 38

**狀態**：完成
**期間**：2026-05-11 ~ 2026-05-17
**Sprint Goal**：解封 M4 GitHub Actions 整合主線（ADR-011 起草）、交付 Decision Knowledge Base 初版，並回應 Stakeholder 對 PO 審查積壓量可視化的需求。
**總計**：3 Stories / 4 Points

---

## Sprint Backlog

| Story ID | Issue # | 標題 | Size | Points | Phase | 狀態 |
|----------|---------|------|------|--------|-------|------|
| US-81 | #76 | ADR-011 起草 — GitHub Actions 整合架構決策 | S | 1 | Phase 1（可並行） | 完成 |
| US-11 | #64 | Decision Knowledge Base — ADR 查詢與決策影響追蹤 | M | 2 | Phase 1（可並行） | 完成 |
| US-82 | #77 | PO 審查積壓量可視化 — backlog-management 新增待審 Issues 計數與老齡警示 | S | 1 | Phase 1（可並行） | 完成 |

**Sprint 容量**：4 Points

---

## Story 詳細 AC

---

### US-81：ADR-011 起草 — GitHub Actions 整合架構決策

**來源**：ADR-011 起草 — Issue #76
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：Yes
**ADR 參考**：ADR-003（ADR 建立規範）
**ADR-003 Checklist**：適用（建立新 ADR 文件）

**User Story**

As a Product Owner preparing to unblock the M4 GitHub Actions integration milestone, I want an ADR-011 drafted documenting the architectural decision for GitHub Actions integration, so that the team has a clear decision record with evaluated alternatives before implementation begins.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | `docs/adr/ADR-011-github-actions-integration.md` 存在且包含標準 ADR template（Context/Decision/Consequences） | 檔案存在，且包含 Context、Decision、Consequences 三個區塊 |
| AC2 | [靜態] | ADR-011 Status 為 `Proposed`，Decision 區塊列出至少 2 個備選方案（含推薦方案標注） | Status 欄位值為 `Proposed`；Decision 區塊可找到至少 2 個備選方案，且推薦方案有明確標注 |
| AC3 | [靜態] | ADR-011 Context 區塊引用 Issue #46 原始需求與 ROADMAP M4 里程碑關聯 | Context 區塊中可找到 Issue #46 與 M4 的引用或提及 |
| AC4 | [靜態] | `docs/prd/ROADMAP.md` M4 區塊中 ADR-011 對應條目狀態更新為「ADR 起草中」或等效標注 | ROADMAP.md M4 區塊中 ADR-011 條目包含「ADR 起草中」或等效文字 |

---

### US-11：Decision Knowledge Base — ADR 查詢與決策影響追蹤

**來源**：Decision Knowledge Base — Issue #64
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：No
**ADR 參考**：ADR-003（ADR 建立規範）
**ADR-003 Checklist**：適用（修改 skills/ 目錄）

**User Story**

As a Developer or Product Owner looking up past architectural decisions, I want a Decision Knowledge Base that allows querying ADRs by keyword, status, and date, with decision impact tracking showing which skills and documents are affected by each Accepted ADR, so that institutional knowledge is preserved and decisions remain accessible over time.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | `skills/architecture-decision/SKILL.md` 新增「Decision Knowledge Base 查詢」區段，定義 ADR 查詢介面（依關鍵字/狀態/日期篩選） | SKILL.md 中可找到「Decision Knowledge Base 查詢」或等效區段標題，且說明關鍵字、狀態、日期三種篩選方式 |
| AC2 | [靜態] | `docs/km/` 目錄下新增 `Decision_KB_Index.md`，自動彙整所有 `docs/adr/ADR-*.md` 的標題、狀態、日期、關聯 Story | 檔案存在，且包含現有所有 ADR 的標題、狀態、日期、關聯 Story 欄位 |
| AC3 | [靜態] | `Decision_KB_Index.md` 包含「決策影響追蹤」區段，列出每個 Accepted ADR 影響的 Skills/文件路徑（靜態手動維護，本 Sprint 不要求自動化） | Decision_KB_Index.md 中可找到「決策影響追蹤」區段，且每個 Accepted ADR 至少有一筆影響路徑記錄 |
| AC4 | [靜態] | `skills/architecture-decision/SKILL.md` 的 ADR 建立流程中新增步驟「同步更新 Decision_KB_Index.md」 | SKILL.md 的 ADR 建立流程步驟中，可找到同步更新 Decision_KB_Index.md 的步驟 |

---

### US-82：PO 審查積壓量可視化 — backlog-management 新增待審 Issues 計數與老齡警示

**來源**：PO 審查積壓量可視化 — Issue #77
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：No
**ADR 參考**：ADR-010（§Label 設計；§backlog-management 工作流程）
**ADR-003 Checklist**：適用（修改 skills/ 目錄）

**User Story**

As a Product Owner running the backlog-management skill, I want to see a PO Review Backlog summary showing the count of auto-triaged Issues pending review, the age of the oldest pending Issue, and warning alerts when Issues are overdue, so that I can prioritize review work and prevent Issues from languishing without attention.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | `skills/backlog-management/SKILL.md` 新增「PO 審查積壓量」檢查區段 | SKILL.md 中可找到「PO 審查積壓量」或等效區段標題 |
| AC2 | [靜態] | 檢查區段定義計數邏輯：`gh issue list --label "auto-triaged" --state open` 取得待審 Issue 數量 | SKILL.md 中可找到上述 `gh issue list` 指令作為計數來源 |
| AC3 | [靜態] | 老齡警示規則：待審 Issue 建立超過 7 天觸發 `[WARNING]`，超過 14 天觸發 `[CRITICAL]` | SKILL.md 中明確記載 7 天 `[WARNING]`、14 天 `[CRITICAL]` 的觸發規則 |
| AC4 | [靜態] | `/backlog-management` 執行時自動輸出積壓量摘要（計數 + 最老 Issue 齡期 + 警示等級） | SKILL.md 中明確說明執行時輸出格式，包含計數、最老 Issue 齡期、警示等級三項 |

---

## 平行分群（Architect 確認）

### Phase 1 — 可並行執行

| 群組 | Stories | 說明 |
|------|---------|------|
| Phase 1（並行） | US-81 | docs/adr/ 新建 ADR-011 文件 + ROADMAP.md 更新；與其他 Story 無檔案衝突 |
| Phase 1（並行） | US-11 | skills/architecture-decision/SKILL.md 新增區段 + docs/km/Decision_KB_Index.md 新建；獨立檔案 |
| Phase 1（並行） | US-82 | skills/backlog-management/SKILL.md 新增區段；與 US-11 無衝突 |

**執行順序說明**：
- 全部三個 Stories 可同時啟動（Phase 1 並行）
- 無跨 Story 檔案衝突，無序列依賴
- 3 路並行執行，最大化 wall-clock 效率

---

## 工作容量

| 項目 | 數值 |
|------|------|
| Sprint 期間 | 2026-05-11 ~ 2026-05-17（7 天） |
| 總 Stories | 3 |
| 總 Points | 4 |
| 平行分群 | Phase 1（US-81 + US-11 + US-82 全部並行） |
| 退回 Backlog | 無 |

---

## ADR 觸發清單

| Story | ADR 編號 | 說明 |
|-------|----------|------|
| US-81 | ADR-011（新建） | GitHub Actions 整合架構決策，狀態 Proposed；本 Sprint 交付起草文件 |
| US-11 | 無新 ADR | Decision Knowledge Base 為知識管理功能強化；ADR-003 Checklist 適用（skills/ 修改） |
| US-82 | 無新 ADR | PO 審查積壓量可視化為 backlog-management 工作流程強化；ADR-010 label 設計已涵蓋；ADR-003 Checklist 適用（skills/ 修改） |

---

## Sprint Planning 簽核

- **PO Round 1**：完成（Story 選取：US-81 S/1pt + US-11 M/2pt + US-82 S/1pt；Sprint Goal 確定；總計 4pt / 3 Stories）
- **Architect Round 1**：完成（三個 Stories PASS；全部 Phase 1 可並行；無檔案衝突）
- **QA Round 1**：完成（所有 AC 可測試性 PASS；doc-only：US-81 Yes / US-11 No / US-82 No；US-81 共 4 條 AC；US-11 共 4 條 AC；US-82 共 4 條 AC）
- **PO Round 2**：完成（整合 Architect/QA 反饋；防漂移驗證通過；AC 最終確認；Sprint Backlog 最終確認；總計 4pt / 3 Stories）
