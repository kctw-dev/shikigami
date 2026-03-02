# Sprint 18

**狀態**：進行中
**Sprint Goal**：框架工程化品質提升 — 修正 PO subagent 跨輪次偏離風險、強化 parallel-dispatch 自動衝突防護、補齊 Onboarding 缺口
**期間**：2026-03-02 ~ 2026-03-08

---

## Sprint Backlog

| Story ID | 標題 | Size | Points | 狀態 |
|----------|------|------|--------|------|
| US-30（Issue #48） | PO subagent 多輪派遣時 Story 內容偏離修正機制 | S | 1 | 進行中 |
| US-32（Issue #40） | parallel-dispatch 應內建同檔案衝突偵測與自動序列化 | M | 2 | 進行中 |
| US-33（Issue #33） | Onboarding 缺少 BACKLOG_DONE.md 模板 | S | 1 | 進行中 |
| US-34（Issue #32） | Onboarding 應預建常用 GitHub Labels | S | 1 | 進行中 |

**總計：4 Stories / 5 Points**

---

## Acceptance Criteria

### US-30（Issue #48）：PO subagent 多輪派遣時 Story 內容偏離修正機制

**User Story**
As a Scrum Master, I want the PO subagent to detect and correct Story content drift when dispatched across multiple rounds, so that the Sprint Backlog remains consistent with the original Planning intent across all PO planning rounds.

**背景**
Sprint 17 Retro 確認：PO subagent 在 Round 2（精化輪次）可能對 Round 1 輸出的 Story 摘要產生無意的重新詮釋，導致 AC 或 Story 範圍悄然偏離。本 Story 在 `skills/sprint-planning/SKILL.md` 建立正式的跨輪次一致性檢查機制。

**QA 狀態**：待審查

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | Round 2 啟動時比對觸發 | `skills/sprint-planning/SKILL.md` 明確規定：PO Round 2 subagent 啟動時，必須先讀取 Round 1 輸出的 Story 摘要表格（欄位：Story ID、標題、T-shirt、主要 AC 關鍵字），逐項與本輪輸出比對後才得輸出精化結果 |
| AC2 | [靜態] | 偵測到偏離時的處理行為 | 偵測到偏離時，PO Round 2 輸出須包含「偏離警告」區塊，明確標示：(a) 偏離項目（Story ID + 偏離欄位）；(b) Round 1 原始內容 vs Round 2 修改內容；(c) 偏離類型（AC 變更 / 標題重新詮釋 / 範圍擴張 / 範圍縮減）；PO Round 2 不得自行消化偏離，必須於偏離警告後暫停並等待 Scrum Master 確認 |
| AC3 | [靜態] | 偏離容忍標準定義 | SKILL.md 明確定義容忍標準：以下變更視為「容忍範圍內」，不觸發偏離警告：(a) 純文字潤飾（未改變語意）；(b) AC 格式調整（未改變驗收標準）；(c) 錯別字修正。以下變更視為「偏離」，必須觸發警告：(a) AC 數量增減；(b) Story 標題語意改變；(c) 主要修改檔案路徑變更；(d) MoSCoW 等級改變 |

**RICE 評分**

| 維度 | 分數 |
|------|------|
| Reach | 8 |
| Impact | 2 |
| Confidence | 80% |
| Effort | 0.5 人週 |
| **RICE Score** | **25.6** |

**MoSCoW**：Should / **Size**：S / **Points**：1
**來源**：Sprint 17 Retro / Issue #48
**ADR-003**：適用（修改 `skills/sprint-planning/SKILL.md`）
**依賴**：無前置阻塞（獨立可執行）

---

### US-32（Issue #40）：parallel-dispatch 應內建同檔案衝突偵測與自動序列化

**User Story**
As a Scrum Master, I want the parallel-dispatch skill to automatically detect when multiple subagents are assigned to modify the same file and serialize those assignments, so that last-write-wins conflicts are prevented without requiring manual scheduling awareness.

**背景**
Issue #40 確認：parallel-dispatch 目前沒有內建的同檔案衝突偵測機制。Scrum Master 需手動分析平行分群以避免衝突，屬於 human-error-prone 流程。本 Story 讓 `skills/parallel-dispatch/SKILL.md` 內建衝突偵測規則，並明確採用序列執行策略（Architect 建議，較簡單安全）。

**QA 狀態**：待審查

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 衝突偵測規則定義 | `skills/parallel-dispatch/SKILL.md` 新增「同檔案衝突偵測」段落，明確規定：派遣前必須建立「修改目標檔案清單」，逐一比對所有待派遣 subagent 的目標檔案；若任意兩個 subagent 的目標檔案有交集，判定為衝突 |
| AC2 | [靜態] | 衝突處理採序列執行 | 偵測到衝突時，SKILL.md 明確規定採用序列執行策略（不使用 worktree 隔離）：衝突的 subagent 群組退出平行派遣佇列，改為依 Story 優先順序逐一序列執行；SKILL.md 須明確說明序列化排序依據（依 Sprint Backlog 中 Story ID 由小到大） |
| AC3 | [靜態] | 無衝突時維持平行 | SKILL.md 明確規定：目標檔案無交集的 subagent 群組仍維持平行派遣，不受序列化邏輯影響；衝突偵測結果輸出格式：列出平行群組與序列群組的分群結果 |
| AC4 | [靜態] | 衝突偵測輸出格式 | Scrum Master 執行 parallel-dispatch 前，必須輸出「衝突分析摘要」，格式包含：(a) 平行執行群組（各組目標檔案無交集）；(b) 序列執行群組（衝突檔案 + 受影響 Story ID）；(c) 序列執行順序 |

**RICE 評分**

| 維度 | 分數 |
|------|------|
| Reach | 8 |
| Impact | 3 |
| Confidence | 75% |
| Effort | 0.75 人週 |
| **RICE Score** | **24.0** |

**MoSCoW**：Should / **Size**：M / **Points**：2
**來源**：GitHub Issue #40
**ADR-003**：適用（修改 `skills/parallel-dispatch/SKILL.md`）
**依賴**：無前置阻塞（獨立可執行）

---

### US-33（Issue #33）：Onboarding 缺少 BACKLOG_DONE.md 模板

**User Story**
As a new project team using Shikigami onboarding, I want the onboarding process to create a BACKLOG_DONE.md template and reference it in the pre-flight checklist, so that completed Stories have a designated archiving location from day one.

**背景**
Issue #33 確認：`shikigami:onboarding` 建立新專案時，未包含 `BACKLOG_DONE.md` 模板，導致新專案缺少已完成 Story 的歸檔落點。本 Story 新建 `templates/BACKLOG_DONE.md` 模板並同步更新 onboarding SKILL.md 的前置檢查與複製清單。

**QA 狀態**：待審查

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 新建 BACKLOG_DONE.md 模板必要欄位 | 新建 `templates/BACKLOG_DONE.md`，文件必須包含以下欄位：(a) 文件標頭（說明用途：已完成 Story 歸檔，管理者，最後更新日期佔位符）；(b) 依 Sprint 分組的表格欄位（Story ID、標題、Size、Points、完成 Sprint、Done 定義驗收結果）；(c) 至少一列示範資料（可使用佔位符如 `US-XX`）；(d) 頁尾說明歸檔觸發時機（Sprint Review 完成後，Story 狀態標記 Done 時移入） |
| AC2 | [靜態] | onboarding SKILL.md 同步更新 | `skills/onboarding/SKILL.md` 同步更新兩處：(a) §2.1 前置檢查區塊新增「`docs/prd/BACKLOG_DONE.md` 是否存在」檢查項，缺失時標記警告（不阻斷流程）；(b) §2.3 複製清單新增 `templates/BACKLOG_DONE.md → docs/prd/BACKLOG_DONE.md` 複製指令 |

**RICE 評分**

| 維度 | 分數 |
|------|------|
| Reach | 7 |
| Impact | 2 |
| Confidence | 90% |
| Effort | 0.5 人週 |
| **RICE Score** | **25.2** |

**MoSCoW**：Should / **Size**：S / **Points**：1
**來源**：GitHub Issue #33
**ADR-003**：適用（修改 `skills/onboarding/SKILL.md`）
**依賴**：無前置阻塞（US-34 等本 Story 完成後執行，同修改 `skills/onboarding/SKILL.md`）

---

### US-34（Issue #32）：Onboarding 應預建常用 GitHub Labels

**User Story**
As a new project team using Shikigami onboarding, I want the onboarding process to automatically create standard GitHub Labels, so that Issues and PRs can be triaged consistently from the start without manual label setup.

**背景**
Issue #32 確認：`shikigami:onboarding` 未包含 GitHub Label 預建步驟，導致新專案需手動建立標準標籤（如 `in-backlog`、`in-sprint`、`retro-action` 等），容易遺漏或命名不一致。本 Story 在 `skills/onboarding/SKILL.md` 加入冪等性 Label 建立指令。

**QA 狀態**：待審查

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | Label 建立指令新增 | `skills/onboarding/SKILL.md` 新增「GitHub Labels 預建」步驟，包含以下必要 Labels 的 `gh label create` 指令：`in-backlog`、`in-sprint`、`in-progress`、`retro-action`、`blocked`、`doc-only`；每個 Label 指令包含 name、color、description 三個參數 |
| AC2 | [靜態] | 冪等性保證（使用 `|| true`） | 每個 `gh label create` 指令末尾加上 `|| true`，確保 Label 已存在時指令不回傳錯誤，整個 onboarding 流程可重複執行而不中止 |
| AC3 | [靜態] | 失敗時警告但不中止 | SKILL.md 明確規定：若 `gh label create` 因認證失敗或網路問題整批失敗（非 Label 已存在），輸出「GitHub Labels 建立失敗，請手動執行以下指令」並列出完整指令清單，不中止 onboarding 後續步驟 |

**RICE 評分**

| 維度 | 分數 |
|------|------|
| Reach | 7 |
| Impact | 2 |
| Confidence | 90% |
| Effort | 0.25 人週 |
| **RICE Score** | **50.4** |

**MoSCoW**：Should / **Size**：S / **Points**：1
**來源**：GitHub Issue #32
**ADR-003**：適用（修改 `skills/onboarding/SKILL.md`）
**依賴**：US-33 必須先完成（兩者同修改 `skills/onboarding/SKILL.md`，序列執行避免 last-write-wins）

---

## 平行分群策略

（Sprint 18 Planning — Architect 建議，PO 確認）

### Phase 1（可平行）

| Story ID | 修改目標 | 說明 |
|----------|---------|------|
| US-30 | `skills/sprint-planning/SKILL.md` | 修改 sprint-planning 跨輪次比對段落，與其他 Story 目標檔案無交集 |
| US-32 | `skills/parallel-dispatch/SKILL.md` | 修改 parallel-dispatch 衝突偵測段落，獨立目標檔案 |
| US-33 | `templates/BACKLOG_DONE.md`（新建）+ `skills/onboarding/SKILL.md`（§2.1、§2.3） | 新建模板並更新 onboarding，需在 US-34 前完成 |

**平行化理由**：US-30 修改 `skills/sprint-planning/SKILL.md`，US-32 修改 `skills/parallel-dispatch/SKILL.md`，US-33 主要新建 `templates/BACKLOG_DONE.md` 並更新 `skills/onboarding/SKILL.md`，三者目標檔案無交集，可完全平行執行。

### Phase 2（序列）

| 步驟 | Story ID | 修改目標 | 說明 |
|------|----------|---------|------|
| 2-1 | US-34 | `skills/onboarding/SKILL.md` | 等 US-33 完成後執行，避免同檔案 last-write-wins 風險 |

**序列理由**：US-34 修改 `skills/onboarding/SKILL.md` 與 US-33 修改同一檔案，依據 US-32 建立的衝突偵測機制，序列執行為正確策略。

---

## 工作容量

| 指標 | 數值 |
|------|------|
| 計畫 Stories | 4 |
| 計畫 Points | 5（3S + 1M = 1+1+1+2） |
| 近 3 Sprint 平均 Velocity | 5.3pt（Sprint 15: 4、Sprint 16: 8、Sprint 17: 4） |
| Sprint 17 Velocity | 4pt |
| 緩衝率 | 94%（接近近三 Sprint 平均，適中容量） |

**容量決策說明**：
Sprint 18 選入 4 Stories（5 points），與近 3 Sprint 平均 Velocity（5.3pt）相近。選入理由：
1. US-31（/shoot 短衝模式）退回 Backlog，4 項設計決策未完成，不選入本 Sprint
2. 4 個 Story 均為 S 或 M size，技術風險低
3. US-30、US-32 為框架工程化品質修正，RICE 評分高（25.6、24.0）
4. US-33、US-34 為 Onboarding 補齊，對新使用者高影響（Reach 7，Confidence 90%）
5. Phase 1 三個 Story 可完全平行，執行效率高

---

## Retro Action Items 追蹤

| Action Item | 來源 | 對應 Story | 狀態 |
|-------------|------|-----------|------|
| Retro #47：/shoot 短衝模式設計與實作 | Sprint 17 Retro / Issue #47 | US-31 | 退回 Backlog（4 項設計決策未完成，待 Refinement） |
| Retro #48：PO subagent 跨輪次一致性檢查 | Sprint 17 Retro / Issue #48 | US-30 | 選入 Sprint 18（S / 1pt） |

---

## ADR-003 觸發清單

| Story | 觸發原因 | 適用狀態 |
|-------|---------|---------|
| US-30 | 修改 `skills/sprint-planning/SKILL.md` | 適用 |
| US-32 | 修改 `skills/parallel-dispatch/SKILL.md` | 適用 |
| US-33 | 修改 `skills/onboarding/SKILL.md`（新建 `templates/BACKLOG_DONE.md` 為新文件，不適用 ADR-003） | 適用（僅 SKILL.md 修改部分） |
| US-34 | 修改 `skills/onboarding/SKILL.md` | 適用 |

---

## Token 記錄

| 環節 | Token | 備註 |
|------|-------|------|
| Planning | 待補 | Sprint 18 Planning 完成後從 JSONL 提取（有效 input = input_tokens + cache_read_input_tokens + cache_creation_input_tokens） |
| Execution | 待補 | Sprint 18 Execution 完成後填入 |
| Review | 待補 | Sprint 18 Review 完成後填入 |
