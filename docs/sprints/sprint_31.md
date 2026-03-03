# Sprint 31

**狀態**：完成
**期間**：2026-03-23 ~ 2026-03-29
**Sprint Goal**：繼續推進 Issue #46 自動化排程框架第二子 Story — 建立排程衝刺 worktree 隔離執行指引，並補強 M5 外部使用者招募的回饋閉環機制，使排程驅動的 Sprint 週期進入可驗證階段
**總計**：3 Stories / 4 Points

---

## Sprint Backlog

| Story ID | 標題 | Size | Points | QA doc-only 判定 | 狀態 |
|----------|------|------|--------|-----------------|------|
| US-57 | Issue #46 子 Story #2 — 排程衝刺 worktree 隔離執行框架（schedule SKILL.md + scrum-master SKILL.md） | M | 2 | No | 完成 |
| US-58 | M5 Beta 回饋閉環強化 — Issue #59 追蹤機制與 README 招募文案精化 | S | 1 | No | 完成 |
| US-59 | Issue #52 — README 自動更新排程設定指引（schedule SKILL.md 使用範例） | S | 1 | No | 完成 |

**Sprint 容量**：4 Points

---

## Story 詳細 AC

---

### US-57：Issue #46 子 Story #2 — 排程衝刺 worktree 隔離執行框架

**來源**：GitHub Issue #46 子 Story #2
**Size**：M / 2 Points
**Owner**：Developer

**User Story**
As a Scrum Master running a scheduled sprint-execution, I want the schedule skill to document worktree isolation requirements so that scheduled execution never conflicts with an active interactive session, and the result is committed and pushed as a branch ready for PR review.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | worktree 隔離執行指引 | `skills/schedule/SKILL.md` §5 下新增子節「排程衝刺 worktree 隔離執行」（編號由 Developer 依現有結構決定，避免與 §6 衝突），說明：(a) 排程觸發 `sprint-execution` 時須建立獨立 worktree（路徑格式：`.claude/worktrees/scheduled-<skill>-<timestamp>`）；(b) 執行完成後 commit + push 至 `scheduled/<skill>/<date>` 分支；(c) worktree 執行完成後清除 |
| AC2 | [靜態] | scrum-master 排程衝刺觸發條件 | `skills/scrum-master/SKILL.md` §5.2 狀態驅動表格新增一行：條件欄填「偵測到 `SHIKIGAMI_SCHEDULED=1` 環境變數且 Skill 為 `sprint-execution`」→ 觸發欄填「worktree 隔離執行模式（見 schedule SKILL.md 對應子節）」，不觸發互動式提醒 |
| AC3 | [靜態] | 衝突防護規則精確定義 | `skills/schedule/SKILL.md` 同一新增子節明確說明三條防護規則：(a) 靜默模式 = 排程觸發時跳過 §5.3 互動式 PR 偵測提醒，僅寫入 `logs/<skill>_cron.log`；(b) timestamp 防重複 = worktree 路徑含 timestamp（格式 `YYYYMMDD-HHMMSS`）確保不重複建立；(c) 失敗處理 = worktree 建立失敗時 exit 1 並寫入 log 錯誤記錄，不保留殘留 worktree |
| AC4 | [靜態] | ADR-003 Checklist 通過 | 修改兩個 `skills/` 下 SKILL.md 前確認 ADR-003 四項條件全部通過；無新架構決策，無需新建 ADR |

---

### US-58：M5 Beta 回饋閉環強化 — Issue #59 追蹤機制與 README 招募文案精化

**來源**：M5 條件 (a) 缺口 / Architect 建議
**Size**：S / 1 Point
**Owner**：Developer

**User Story**
As a Product Owner tracking M5 completion, I want a clear tracking mechanism for Beta user feedback and an improved README call-to-action that reduces friction for external users, so that we maximize the probability of receiving the first verified external user response.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | README Beta 招募文案精化 | `README.md` Beta 招募區段更新：(a) 加入 OpenCode 安裝路徑直連（`docs/INSTALL_OPENCODE.md`）；(b) 移除「AI 輔助開發實踐者」限定語，新增「完成安裝後留言即可」降低門檻；(c) Issue #59 連結置頂（移至區段首行）；文案變更後 Beta 招募區段長度不超過 15 行 |
| AC2 | [靜態] | M5_COMPLETION_ASSESSMENT.md 追蹤欄位 | `docs/prd/M5_COMPLETION_ASSESSMENT.md` 條件 (a) 招募行動記錄表格新增「最後更新日期」欄與「累積回饋數」欄，當前值填入（日期：2026-03-03，累積回饋數：0）；說明「累積回饋數 >= 1 則條件 (a) 達成」 |
| AC3 | [靜態] | sprint-review Beta 檢查提示 | `skills/sprint-review/SKILL.md` §7 執行檢查清單新增一條 checkbox：「確認 Issue #59 是否有新的外部使用者回饋（`gh issue view 59 --comments`）；若有，更新 M5_COMPLETION_ASSESSMENT.md 條件 (a) 狀態」 |
| AC4 | [靜態] | ADR-003 Checklist | `skills/sprint-review/SKILL.md` 修改需通過 ADR-003 四項條件；`README.md` 與 `docs/prd/M5_COMPLETION_ASSESSMENT.md` 不在 ADR-003 範圍 |

---

### US-59：Issue #52 — README 自動更新排程設定指引

**來源**：GitHub Issue #52 / Architect 建議
**Size**：S / 1 Point
**Owner**：Developer

**User Story**
As a framework user, I want the schedule skill documentation to include concrete usage examples including README auto-update, so that I can set up automated periodic tasks using the existing schedule skill.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 使用範例區塊 | `skills/schedule/SKILL.md` 末尾（§14 之後）新增「## 使用範例」區塊；包含至少 2 個完整範例：(a) README 統計自動更新排程；(b) Daily Standup 自動排程 |
| AC2 | [動態] | Issue #52 關閉 | 範例 (a) 包含完整 `/schedule` 指令語法與前提條件說明（至少涵蓋 OAuth 認證與目標 Skill 存在性）；Issue #52 留言說明解決方案並關閉 |
| AC3 | [靜態] | ADR-003 Checklist 通過 | `skills/schedule/SKILL.md` 修改前確認 ADR-003 四項條件通過 |

---

## 平行分群（Architect 建議）

### Phase 1 — 可平行執行

| 群組 | Stories | 說明 |
|------|---------|------|
| Phase 1（平行） | US-57 | 修改 skills/schedule/SKILL.md + skills/scrum-master/SKILL.md；需 ADR-003 Checklist 通過 |
| Phase 1（平行） | US-58 | 修改 README.md + docs/prd/M5_COMPLETION_ASSESSMENT.md + skills/sprint-review/SKILL.md；與 US-57 無共同修改檔案，可平行 |

### Phase 2 — US-57 完成後執行

| 群組 | Stories | 說明 |
|------|---------|------|
| Phase 2 | US-59 | 修改 skills/schedule/SKILL.md；同修改 US-57 已處理的檔案，序列執行避免衝突 |

**執行順序說明**：
- US-57 與 US-58 可平行執行，無共同修改檔案
- US-59 需在 US-57 完成後啟動，因同修改 skills/schedule/SKILL.md

---

## 工作容量

| 項目 | 數值 |
|------|------|
| Sprint 期間 | 2026-03-23 ~ 2026-03-29（7 天） |
| 總 Stories | 3 |
| 總 Points | 4 |
| 平行分群 | Phase 1（US-57 + US-58 平行）→ Phase 2（US-59，US-57 完成後） |

---

## ADR 觸發清單

| Story | ADR 編號 | 說明 |
|-------|----------|------|
| US-57 | 無新 ADR | 修改兩個 SKILL.md，需通過 ADR-003 Checklist；無新架構決策 |
| US-58 | 無新 ADR | skills/sprint-review/SKILL.md 修改需通過 ADR-003 Checklist；README.md 與 M5_COMPLETION_ASSESSMENT.md 不在 ADR-003 範圍 |
| US-59 | 無新 ADR | 修改 skills/schedule/SKILL.md，需通過 ADR-003 Checklist；無新架構決策 |

**本 Sprint 無新建 ADR。**

---

## Sprint Planning 簽核

- **PO Round 1**：完成（Story 選取：US-57 M/2pt + US-58 S/1pt + US-59 S/1pt；Sprint Goal 確定；總計 4pt）
- **Architect Round 1**：完成（技術可行性確認；平行分群：Phase 1 US-57+US-58 平行，Phase 2 US-59；AC 路徑與衝突分析通過）
- **QA Round 1**：完成（US-57/US-58/US-59 AC 條目審查 PASS；doc-only 判定：No — US-57/US-58/US-59 均修改 skills/ 目錄 SKILL.md）
- **PO Round 2**：完成（整合 Architect/QA 反饋；US-57 AC1 編號由 Developer 決定條件納入；Sprint Backlog 最終確認；總計 4pt / 3 Stories）
