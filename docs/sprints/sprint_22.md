# Sprint 22

**狀態**：進行中
**期間**：2026-03-16 ~ 2026-03-22
**Sprint Goal**：強化框架安全性與排程智能化
**總計**：4 Stories / 6 Points

---

## Sprint Backlog

| Story ID | 標題 | Size | Points | 狀態 |
|----------|------|------|--------|------|
| US-33（Issue #33） | Onboarding 缺少 BACKLOG_DONE.md 模板 | S | 1 | 完成 |
| US-37（Issue #55） | 防範 Issue 提示注入攻擊 | S | 1 | 完成 |
| US-38（Issue #51） | 排程模式下 Velocity 自動調小 — 僅選 S size Stories | S | 1 | 完成 |
| US-39（Issue #45） | Sprint Execution context overflow — Story 生命週期封裝為 subagent | L | 3 | 完成 |

**Sprint 容量**：6 Points

---

## Story 詳細 AC

---

### US-33（Issue #33）：Onboarding 缺少 BACKLOG_DONE.md 模板

**來源**：GitHub Issue #33
**Size**：S / 1 Point
**Owner**：Developer

**User Story**
As a new user setting up Shikigami, I want the onboarding process to include a BACKLOG_DONE.md template, so that my repository has the correct archive structure ready from day one without needing to manually create it when first archiving completed Stories.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 模板存在性 | `skills/onboarding/SKILL.md` 包含建立 `docs/prd/BACKLOG_DONE.md` 的步驟指引，且該步驟位於 Onboarding 流程中 |
| AC2a | [靜態] | §2.1 前置條件檢查 | `skills/onboarding/SKILL.md` §2.1 或前置條件章節明確列出 `BACKLOG_DONE.md` 為 Onboarding 必要產出物之一 |
| AC2b | [靜態] | §2.3 複製表格 | `skills/onboarding/SKILL.md` §2.3 或工件清單章節包含 `BACKLOG_DONE.md` 模板的複製/建立操作說明 |
| AC3a | [靜態] | Header 格式 | 建立的 `BACKLOG_DONE.md` 模板標頭格式正確（含文件標題、最後更新欄位、管理者欄位） |
| AC3b | [靜態] | 佔位 Sprint 區段 | 模板包含至少一個佔位 Sprint 區段（如 `## Sprint N — 完成` 格式），供使用者了解預期格式 |
| AC3c | [靜態] | 表格格式與 sprint-review SKILL.md §5 Schema 一致 | `BACKLOG_DONE.md` 模板中的 Story 表格欄位須與 `skills/sprint-review/SKILL.md` §5 定義的歸檔 Schema 一致（至少包含：Story ID、標題、Size、Points、完成 Sprint） |

---

### US-37（Issue #55）：防範 Issue 提示注入攻擊

**來源**：GitHub Issue #55
**Size**：S / 1 Point
**Owner**：Developer

**User Story**
As a framework operator, I want the sprint-execution Issue Quick-Scan flow to use structured isolation markers when passing issue content to PO subagent, so that malicious content in issue titles or bodies cannot be interpreted as system instructions and compromise the Sprint execution process.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 結構化隔離標記實作 | `skills/sprint-execution/SKILL.md` §3 Issue 快掃「回覆流程」中，issue title 與 issue body 傳遞給 PO subagent 時使用結構化隔離標記（如 `<issue_title>...</issue_title>`、`<issue_body>...</issue_body>`），防止 issue 內容被當作系統指令執行；隔離模式須在 SKILL.md 中命名為規則（如「Prompt Injection Isolation Rule」） |
| AC2 | [靜態] | ADR-006 建立 | 新建 `docs/adr/ADR-006-prompt-injection-protection.md`，狀態為 Accepted，包含：(a) 威脅模型（LLM prompt injection via issue content）、(b) 至少 2 個緩解選項評估、(c) 選定方案與理由、(d) 範圍限定為 sprint-execution Issue Quick-Scan |
| AC3 | [靜態] | 現有觸發條件不受影響 | §3 現有三項觸發條件（label 過濾、sprint-N-replied 去重、top-5 oldest 限制）不受隔離標記改動影響；隔離標記僅出現在 PO subagent prompt 建構步驟，不修改觸發邏輯 |
| AC4 | [動態] | Security subagent 審查 PASS | 因涉及外部輸入處理，Security subagent 必須審查隔離實作並回傳 PASS |

---

### US-38（Issue #51）：排程模式下 Velocity 自動調小 — 僅選 S size Stories

**來源**：GitHub Issue #51
**Size**：S / 1 Point
**Owner**：Developer

**User Story**
As a Scrum Master running scheduled sprints, I want the sprint-planning skill to automatically restrict story selection to S size Stories only when operating in scheduled mode, so that automated sprint execution stays within safe context and time boundaries without requiring manual oversight.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 排程模式章節新增 | `skills/sprint-planning/SKILL.md` 新增「排程模式」（Scheduled Mode）章節，定義排程執行時僅 S size Stories 可納入 Sprint Backlog |
| AC2 | [靜態] | HARD-GATE 定義 | S-size 篩選規則以 HARD-GATE 形式定義：「排程模式下，M/L Stories 不得選入 Sprint Backlog，僅 S size Stories 可納入。」違反此規則時 Sprint Planning 必須中止 |
| AC3 | [靜態] | 非排程模式不受影響 | 非排程模式（手動 Sprint Planning）的 Story 選取邏輯不受影響，M/L Stories 仍可依原流程選入 |
| AC4 | [靜態] | 排程模式偵測機制明確定義 | 排程模式偵測機制須在 SKILL.md 中明確定義（如 `--scheduled` flag 或環境變數 `SHIKIGAMI_SCHEDULED=true`），供執行方確認當前模式 |

---

### US-39（Issue #45）：Sprint Execution context overflow — Story 生命週期封裝為 subagent

**來源**：GitHub Issue #45
**Size**：L / 3 Points
**Owner**：Developer

**User Story**
As a Scrum Master running sprint execution, I want each Story's complete lifecycle (planning, development, QA review, completion) to be encapsulated within a dedicated subagent, so that context overflow is prevented for M/L size Stories and the main session stays lean throughout multi-story sprint execution.

**備注**：Sprint 22 交付範圍為 ADR-007 + 可選 SDD（Solution Design Document），不包含實作。

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | ADR-007 建立 | 新建 `docs/adr/ADR-007-story-lifecycle-subagent.md`，狀態為 Accepted，包含至少 3 個選項評估：(A) 現有基準（current baseline）、(B) 完整 Story-Lifecycle subagent、(C) 至少一個替代方案（如部分封裝、分段委派等） |
| AC2 | [靜態] | 介面契約定義 | ADR-007 或附屬 SDD 包含 Story-Lifecycle subagent 最小介面契約：(a) 輸入格式（Story ID、AC 清單、相關檔案路徑等）、(b) 輸出格式（PASS/FAIL + 摘要 + 修改檔案清單 + commit SHA）、(c) 錯誤/升級輸出（escalation output，定義何時須回傳主 session 處理） |
| AC3 | [靜態] | 審查獨立性補償機制 | ADR-007 或附屬 SDD 定義 Review 獨立性補償機制，含可量測元素：抽樣百分比（sampling percentage）、觸發條件（何時啟動額外審查）、文件位置（機制定義所在文件路徑） |
| AC4 | [靜態] | Context overflow 回退策略 | ADR-007 或附屬 SDD 明確定義 M/L size Stories 的 context overflow 回退策略（fallback strategy），說明當 subagent context 接近上限時的處理方式 |

---

## 平行分群（Architect 建議）

### Phase 1（可平行執行）

| Story | 負責人 | 說明 |
|-------|--------|------|
| US-33（Issue #33） | Developer | 獨立，無依賴 |
| US-38（Issue #51） | Developer | 獨立，無依賴 |

### Phase 2（Phase 1 後或 ADR 審查後）

| Story | 負責人 | 說明 |
|-------|--------|------|
| US-37（Issue #55） | Developer | 需先建立 ADR-006 再實作隔離標記 |

### Independent（可獨立執行）

| Story | 負責人 | 說明 |
|-------|--------|------|
| US-39（Issue #45） | Developer | 交付 ADR-007 + 可選 SDD，無實作依賴 |

---

## 工作容量

| 項目 | 數值 |
|------|------|
| Sprint 期間 | 2026-03-16 ~ 2026-03-22（7 天） |
| 總 Stories | 4 |
| 總 Points | 6 |
| Phase 1 容量 | 2 Points（US-33 + US-38，可平行） |
| Phase 2 容量 | 1 Point（US-37） |
| Independent 容量 | 3 Points（US-39） |

---

## ADR 觸發清單

| Story | ADR 編號 | 說明 |
|-------|----------|------|
| US-33 | 無新 ADR | ADR-003 Checklist 適用（修改 skills/onboarding/SKILL.md）；非 doc-only |
| US-37 | ADR-006 | `docs/adr/ADR-006-prompt-injection-protection.md`；範圍限定 sprint-execution Issue Quick-Scan |
| US-38 | 無新 ADR | ADR-003 Checklist 適用（修改 skills/sprint-planning/SKILL.md） |
| US-39 | ADR-007 | `docs/adr/ADR-007-story-lifecycle-subagent.md`；Sprint 22 僅交付 ADR + 可選 SDD |

**預先分配**：
- ADR-006 = US-37（Prompt Injection Protection）
- ADR-007 = US-39（Story-Lifecycle Subagent）

---

## Sprint Planning 簽核

- **PO Round 1**：完成（Story 選取：US-33、US-37、US-38、US-39；初版 AC；Sprint Goal 確定）
- **Architect Round 1**：完成（估點確認：6pt；ADR 觸發：ADR-006、ADR-007；平行分群建議；US-39 Sprint 22 範圍限縮為 ADR + SDD）
- **QA Round 1**：完成（US-33 AC2/AC3 拆分修訂；US-37 AC 全新擬定（Issue #55 原無 AC）；US-38 目標檔案修正為 sprint-planning/SKILL.md；US-39 AC 精化含介面契約、審查獨立性、Fallback 策略）
- **PO Round 2**：完成（AC 修訂整合完成，Sprint 文件建立，ADR 預先分配確認）
