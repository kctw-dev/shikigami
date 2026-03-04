# Sprint 41

**狀態**：進行中
**期間**：2026-03-04 ~ 2026-03-10
**Sprint Goal**：M4 收尾與文件一致性強化 — 更新 ROADMAP M4 完成狀態、TD-002 技術債結案、建立交付物文案一致性審查機制回應 Sprint 38-40 連續 Retro Problem。
**總計**：4 Stories / 5 Points

---

## Sprint Backlog

| Story ID | Issue # | 標題 | Size | Points | Phase | 狀態 |
|----------|---------|------|------|--------|-------|------|
| US-84 | #79 | M4 里程碑正式收尾 — ROADMAP US-14 完成標注 + M4 結案評估 | S | 1 | Phase 1（平行） | 完成 |
| US-85 | #80 | TD-002 技術債結案 + Schema 文案修正 | S | 1 | Phase 1（平行） | 完成 |
| US-86 | #81 | 交付物文案一致性審查機制 — 回應 Sprint 38-40 連續 Retro Problem | M | 2 | Phase 1（平行） | 完成 |
| US-87 | #82 | GitHub Action 自動觸發 backlog-intake — Issue labeled 事件驅動入庫 | S | 1 | Phase 1（平行） | 完成 |

**Sprint 容量**：5 Points

---

## 平行分群方案

| Phase | Stories | 說明 |
|-------|---------|------|
| Phase 1（全平行） | US-84、US-85、US-86、US-87 | 修改檔案不重疊：US-84 修改 docs/prd/ROADMAP.md；US-85 修改 docs/Tech_Debt_Registry.md + schemas/；US-86 修改 skills/；US-87 修改 .github/workflows/ |

**平行可行性判定**：APPROVED — 三個 Story 的檔案修改路徑無交集，可同時執行。

---

## Story 詳細 AC

---

### US-84：M4 里程碑正式收尾 — ROADMAP US-14 完成標注 + M4 結案評估

**來源**：ROADMAP.md M4 收尾 — Issue #79
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：Yes（僅修改 docs/ 文件）
**ADR 參考**：無

**User Story**

As a Product Owner closing out M4, I want the ROADMAP updated to mark US-14 and all M4 deliverables as complete, with a formal M4 milestone assessment recorded, so that stakeholders have a clear and accurate view of what was delivered in M4.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | ROADMAP.md M4 區段標注 US-14 完成 | ROADMAP.md 中 US-14 狀態更新為完成，M4 里程碑標注為已達成 |
| AC2 | [靜態] | M4 結案評估記錄 | ROADMAP.md 或對應文件包含 M4 交付總結（已完成 Stories 清單、實際 Velocity、Goal 達成結果） |
| AC3 | [靜態] | Issue #79 狀態回寫 | Issue #79 關閉並標注 status: done |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響所有查閱 ROADMAP 的 Stakeholder |
| Impact | 2 | 確保里程碑記錄準確性 |
| Confidence | 1.0 | 純文件更新，高確信度 |
| Effort | 1 | 僅需更新 ROADMAP 文件 |
| **RICE Score** | **6.0** | R×I×C/E |

**Done 定義**

- [x] ROADMAP.md M4 區段 US-14 狀態標注為完成
- [x] M4 結案評估摘要寫入對應文件
- [x] Issue #79 關閉

---

### US-85：TD-002 技術債結案 + Schema 文案修正

**來源**：Tech_Debt_Registry.md TD-002 結案 — Issue #80
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：No（涉及 schemas/ 文案修正）
**ADR 參考**：ADR-006（JSON Schema 驗證決策）

**User Story**

As a Product Owner maintaining the Tech Debt Registry, I want TD-002 formally closed with any outstanding schema documentation corrections applied, so that the tech debt backlog accurately reflects the current state of the codebase.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | Tech_Debt_Registry.md TD-002 標注為已結案 | Tech_Debt_Registry.md 中 TD-002 狀態更新為「已結案」，並記錄結案 Sprint（Sprint 41） |
| AC2 | [靜態] | Schema 文案修正完成 | `schemas/po-subagent-output.schema.json` 中任何文案不一致項目已修正，欄位說明清晰 |
| AC3 | [靜態] | Issue #80 狀態回寫 | Issue #80 關閉並標注 status: done |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 2 | 影響使用 TD Registry 的工程團隊 |
| Impact | 2 | 清除積壓技術債，維持 Registry 準確性 |
| Confidence | 1.0 | 結案動作明確，高確信度 |
| Effort | 1 | 文件更新 + 小幅文案修正 |
| **RICE Score** | **4.0** | R×I×C/E |

**Done 定義**

- [x] Tech_Debt_Registry.md TD-002 狀態更新為已結案（Sprint 41）
- [x] schemas/po-subagent-output.schema.json 文案修正完成
- [x] Issue #80 關閉

---

### US-86：交付物文案一致性審查機制 — 回應 Sprint 38-40 連續 Retro Problem

**來源**：Sprint 38-40 連續 Retro Problem — Issue #81
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：No（涉及 skills/ 新增審查機制）
**ADR 參考**：ADR-003（SKILL.md 修改規範）

**User Story**

As a Product Owner who observed documentation inconsistencies flagged in Sprint 38, 39, and 40 retrospectives, I want a formal deliverable copy consistency review mechanism added to the sprint workflow, so that cross-document terminology and status discrepancies are caught before Sprint Review rather than discovered as retro problems.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 一致性審查 Checklist 寫入 SKILL.md | sprint-review 或 sprint-execution SKILL.md 包含「交付物文案一致性審查」子節，定義審查項目清單（跨文件術語、狀態標注、Issue 連結有效性） |
| AC2 | [靜態] | 審查觸發時機明確 | SKILL.md 明確定義審查在 Sprint Review 前執行，作為 Done 定義的一部分 |
| AC3 | [靜態] | 連結 Retro Problem 根因 | 文件中說明此機制回應 Sprint 38-40 連續 Retro 發現的文案不一致問題，記錄根因與預防措施 |
| AC4 | [靜態] | Issue #81 狀態回寫 | Issue #81 關閉並標注 status: done |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 4 | 影響每個 Sprint 的所有交付物審查 |
| Impact | 3 | 直接解決連續三個 Sprint 的 Retro Problem |
| Confidence | 0.8 | 機制設計合理，實作可信度高 |
| Effort | 2 | 需新增審查機制至 SKILL.md + 文件根因說明 |
| **RICE Score** | **4.8** | R×I×C/E |

**Done 定義**

- [x] sprint-review SKILL.md 新增「交付物文案一致性審查」子節（含審查 Checklist）
- [x] 審查觸發時機明確定義（Sprint Review 前）
- [x] 根因說明與預防措施記錄於文件
- [x] ADR-003 合規性確認（修改 SKILL.md）
- [x] Issue #81 關閉

---

### US-87：GitHub Action 自動觸發 backlog-intake — Issue labeled 事件驅動入庫

**來源**：backlog-intake 自動化 — Issue #82
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：No（新增 .github/workflows/ YAML）
**ADR 參考**：ADR-011（GitHub Actions 整合架構）

**User Story**

身為開發團隊成員，我希望在 Issue 被加上 backlog-intake label 的當下自動觸發需求入庫流程，以便消除手動執行步驟、縮短需求從提出到進入 Backlog 的等待時間。

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [動態] | Workflow 觸發條件正確 | 當 Issue 被加上 `backlog-intake` label 時自動觸發，不因其他 label 誤觸 |
| AC2 | [動態] | AI 填補 Story template | 呼叫 `anthropics/claude-code-action@v1`，成功填寫 Story template 回 Issue body |
| AC3 | [靜態] | Labels 自動套用 | 執行完成後 Issue 自動套用 `auto-triaged`、`status: backlog`、`type: backlog-item`、`priority: <MoSCoW>`、`backlog-intake-done` |
| AC4 | [靜態] | 冪等性保護 | 若 Issue 已有 `backlog-intake-done` label，Workflow 不觸發 |
| AC5 | [靜態] | Issue #82 狀態回寫 | Issue #82 關閉並標注 status: done |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 10 | 影響所有提出需求的貢獻者 |
| Impact | 2 | 縮短需求入庫等待時間 |
| Confidence | 0.8 | claude-code-action 已有前例，ADR-011 已定義架構 |
| Effort | 1 | 建立一個 workflow YAML |
| **RICE Score** | **16** | R×I×C/E |

**Done 定義**

- [x] `.github/workflows/backlog-intake.yml` 建立並推送至 main
- [x] Workflow YAML 語法正確（通過 GitHub Actions 語法驗證）
- [x] ADR-011 架構對齊（Push-Based 事件觸發）
- [x] Issue #82 關閉

---

## ADR 觸發清單

| Story | ADR | 觸發原因 | 動作 |
|-------|-----|----------|------|
| US-85 | ADR-006 | TD-002 結案涉及 JSON Schema 驗證層文案確認 | 確認 ADR-006 Addendum 與 Schema 文案一致 |
| US-86 | ADR-003 | 修改 skills/sprint-review SKILL.md（新增一致性審查子節） | 遵循 ADR-003 SKILL.md 修改規範 |
| US-87 | ADR-011 | 新增 GitHub Actions workflow（backlog-intake 事件觸發） | 遵循 ADR-011 Push-Based 事件觸發架構 |

---

## Sprint Planning 簽核記錄

| 角色 | 確認項目 | 狀態 |
|------|----------|------|
| Product Owner | Sprint Goal 對齊 M4 收尾與文案一致性，US-84（M4 收尾）+ US-85（TD-002 結案）+ US-86（一致性機制）優先級確認 | 已確認 |
| Architect | US-84 S-size 技術可行性（ROADMAP 文件更新）；US-85 S-size 技術可行性（TD Registry + Schema 文案）；US-86 M-size 技術可行性（SKILL.md 新增審查機制） | 已確認 |
| QA | US-84 AC1-AC3 驗收標準；US-85 AC1-AC3 驗收標準；US-86 AC1-AC4 驗收標準 | 已確認 |
| Developer | Story 清晰度確認，Phase 1 全平行執行可行 | 待確認 |

**Sprint Planning 決策記錄**

- Sprint 41 選入 4 Stories（US-84 + US-85 + US-86 + US-87），共 5 Points
- 平行分群：Phase 1 全平行（檔案範圍無重疊）
- US-84 doc-only 判定：Yes（僅修改 docs/prd/ROADMAP.md）
- US-85 doc-only 判定：No（涉及 schemas/ 文案修正，ADR-006 適用）
- US-86 doc-only 判定：No（涉及 skills/ 修改，ADR-003 適用）
- Milestone "Sprint 41" 建立於 GitHub，Issue #79、#80、#81 已設定 in-sprint 標籤
