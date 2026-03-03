# Sprint 32

**狀態**：進行中
**期間**：2026-03-30 ~ 2026-04-05
**Sprint Goal**：完成 Issue #46 自動化排程框架的程式碼入庫 QA 閉環（子 Story #3），同步推進 M5 條件 (a) 外部使用者觸及強化與 Issue #35 Token Baseline 精確化，使排程 Sprint 週期具備端對端自動化能力
**總計**：3 Stories / 4 Points

---

## Sprint Backlog

| Story ID | 標題 | Size | Points | QA doc-only 判定 | 狀態 |
|----------|------|------|--------|-----------------|------|
| US-60 | Issue #46 子 Story #3 — 排程衝刺程式碼入庫 QA 自動化（schedule SKILL.md + scrum-master/sprint-review SKILL.md） | M | 2 | No | 完成 |
| US-61 | M5 條件 (a) 外部使用者觸及強化 — Onboarding 低摩擦路徑最佳化（README + tutorial + M5 追蹤更新） | S | 1 | Yes | 完成 |
| US-62 | Issue #35 — Token 追蹤 Baseline Snapshot 機制（Metrics_Log.md + sprint-planning/execution SKILL.md） | S | 1 | No | 完成 |

**Sprint 容量**：4 Points

---

## Story 詳細 AC

---

### US-60：Issue #46 子 Story #3 — 排程衝刺程式碼入庫 QA 自動化

**來源**：GitHub Issue #46 子 Story #3
**Size**：M / 2 Points
**Owner**：Developer

**User Story**
As a Scrum Master running a scheduled sprint-execution, I want the schedule skill and scrum-master skill to define a QA-gated code commit workflow so that code produced by scheduled sprints is automatically validated and submitted for review via PR, completing the end-to-end automated sprint loop.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 程式碼入庫 QA 自動化子節 | `skills/schedule/SKILL.md` §5 下新增「程式碼入庫 QA 自動化」子節（編號由 Developer 決定），定義：偵測條件（`scheduled/*` 分支命名規則）、PR 建立流程（gh pr create 語法）、quality-gate 檢查項目清單（至少 3 項） |
| AC2 | [靜態] | scrum-master 狀態驅動表格新增行 | `skills/scrum-master/SKILL.md` §5.2 狀態驅動表格新增一行：條件欄填「偵測到 `scheduled/*` 分支且無對應 open PR」→ 觸發欄填「自動建立 PR + quality-gate 檢查（見 schedule SKILL.md 對應子節）」；Developer 依現有結構選定目標檔案（建議 `skills/scrum-master/SKILL.md` §5.2，因已有排程觸發表格），並在 commit message 記錄選擇 |
| AC3 | [靜態] | quality-gate 三條規則 | 三條 quality-gate 規則明確寫入 schedule SKILL.md 同一子節：(a) CI 驗證通過（bash syntax check + 現有測試）；(b) PR body 包含 Story ID 與 Sprint 編號標注；(c) merge 前確認無衝突（non-conflicting） |
| AC4 | [靜態] | ADR-003 Checklist 通過 | 修改兩個 `skills/` 下 SKILL.md 前確認 ADR-003 四項條件全部通過；無新架構決策，無需新建 ADR |

---

### US-61：M5 條件 (a) 外部使用者觸及強化 — Onboarding 低摩擦路徑最佳化

**來源**：M5 條件 (a) 外部使用者觸及 / Architect 建議（Sprint 32 Planning）
**Size**：S / 1 Point
**Owner**：Developer

**User Story**
As a Product Owner tracking M5 completion, I want the onboarding documentation to have clearly identified and corrected high-friction steps, and a 5-minute quick-start path in the README, so that external users can reach their first successful run with minimal friction and we maximize the chance of achieving M5 condition (a).

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 高摩擦步驟識別與修正 | 審查 `docs/tutorial/GETTING_STARTED.md` 與 `docs/INSTALL_OPENCODE.md`，至少識別並修正 2 處高摩擦步驟（判定標準：步驟需要查詢外部文件、步驟數超過 3 個子指令、或預期時間超過 10 分鐘）；修正處標注修正理由 |
| AC2 | [靜態] | README 5 分鐘快速試用路徑 | `README.md` Beta 招募區段或快速開始區段新增「5 分鐘快速試用」指引路徑（從安裝到第一次執行的最少步驟，不超過 5 步） |
| AC3 | [動態] | M5_COMPLETION_ASSESSMENT.md 更新 | 執行 `gh issue view 59 --comments` 確認目前累積回饋數，更新 `docs/prd/M5_COMPLETION_ASSESSMENT.md` 條件 (a) 追蹤表格（最後更新日期與累積回饋數） |
| AC4 | [靜態] | ADR-003 不適用確認 | ADR-003 不適用（修改範圍為 README.md + docs/ 目錄，不在 skills/commands/agents/ 範圍內） |

---

### US-62：Issue #35 — Token 追蹤 Baseline Snapshot 機制

**來源**：GitHub Issue #35 / Sprint 32 Planning
**Size**：S / 1 Point
**Owner**：Developer

**User Story**
As a Product Owner monitoring token consumption, I want a baseline snapshot mechanism that records cumulative token counts at the start of each sprint phase, so that I can calculate accurate per-phase token deltas and make data-driven decisions about framework optimization.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | Metrics_Log.md Token Baseline Snapshots 表格 | `docs/km/Metrics_Log.md` 新增「## Token Baseline Snapshots」輔助表格，欄位：Sprint 編號、環節名稱、環節開始時累計 input tokens、環節開始時累計 output tokens |
| AC2 | [靜態] | sprint-planning SKILL.md 新增 baseline 記錄步驟 | `skills/sprint-planning/SKILL.md` §2 流程 Checklist 新增一條：「Planning 環節開始前記錄 baseline snapshot 至 Metrics_Log.md Token Baseline Snapshots 表格」，含操作步驟說明（讀取 JSONL 當前累計值並填入表格） |
| AC3 | [靜態] | sprint-execution SKILL.md 新增 baseline 記錄步驟 | `skills/sprint-execution/SKILL.md` §3 執行流程新增：「Execution 環節開始前（取出第一個 Story 之前）記錄 baseline snapshot 至 Metrics_Log.md Token Baseline Snapshots 表格」，含操作步驟說明 |
| AC4 | [靜態] | ADR-003 Checklist 通過 | 修改兩個 `skills/` 下 SKILL.md 前確認 ADR-003 四項條件全部通過；Metrics_Log.md 不在 ADR-003 範圍 |

---

## 平行分群（Architect 建議）

### Phase 1 — 全部可平行執行

| 群組 | Stories | 說明 |
|------|---------|------|
| Phase 1（平行） | US-60 | 修改 skills/schedule/SKILL.md + skills/scrum-master/SKILL.md；需 ADR-003 Checklist 通過 |
| Phase 1（平行） | US-61 | 修改 README.md + docs/tutorial/GETTING_STARTED.md + docs/INSTALL_OPENCODE.md + docs/prd/M5_COMPLETION_ASSESSMENT.md；與 US-60 / US-62 無共同修改檔案，可平行 |
| Phase 1（平行） | US-62 | 修改 docs/km/Metrics_Log.md + skills/sprint-planning/SKILL.md + skills/sprint-execution/SKILL.md；與 US-60 / US-61 無共同修改檔案，可平行 |

**執行順序說明**：
- 所有 3 Stories 可完全平行執行，無共同修改檔案
- 本 Sprint 無 Phase 2

---

## 工作容量

| 項目 | 數值 |
|------|------|
| Sprint 期間 | 2026-03-30 ~ 2026-04-05（7 天） |
| 總 Stories | 3 |
| 總 Points | 4 |
| 平行分群 | Phase 1（US-60 + US-61 + US-62 全部平行）；無 Phase 2 |

---

## ADR 觸發清單

| Story | ADR 編號 | 說明 |
|-------|----------|------|
| US-60 | 無新 ADR | 修改兩個 SKILL.md，需通過 ADR-003 Checklist；無新架構決策 |
| US-61 | 無新 ADR | ADR-003 不適用（修改範圍為 README.md + docs/ 目錄） |
| US-62 | 無新 ADR | 修改兩個 SKILL.md，需通過 ADR-003 Checklist；Metrics_Log.md 不在 ADR-003 範圍 |

**本 Sprint 無新建 ADR。**

---

## Sprint Planning 簽核

- **PO Round 1**：完成（Story 選取：US-60 M/2pt + US-61 S/1pt + US-62 S/1pt；Sprint Goal 確定；總計 4pt）
- **Architect Round 1**：完成（技術可行性確認；平行分群：全部 Phase 1 平行，無 Phase 2；AC 路徑與衝突分析通過）
- **QA Round 1**：完成（US-60/US-61/US-62 AC 條目審查 PASS；QA doc-only 判定：US-60 No / US-61 Yes / US-62 No；US-61 AC1 高摩擦步驟判定標準明確化；US-60 AC2 選定目標檔案條件納入；US-60 AC1 quality-gate 至少 3 項要求納入）
- **PO Round 2**：完成（整合 Architect/QA 反饋；US-61 AC1 加入客觀判定標準；US-60 AC2 改為具體建議目標；US-60 AC1 quality-gate 數量下限對齊 AC3；Sprint Backlog 最終確認；總計 4pt / 3 Stories）
