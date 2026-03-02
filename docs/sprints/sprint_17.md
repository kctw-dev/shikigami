# Sprint 17

**狀態**：進行中
**Sprint Goal**：檔案瘦身優先 — 建立 PROJECT_BOARD 與 Retrospective_Log 歷史歸檔機制（US-29），清零 Sprint 16 Retro Action Items（Retro #41 Token 記錄指引 cache tokens 修正、Retro #42 OpenCode POC 佔位候選入 Backlog），確保效能可觀測性與知識管理基礎就緒。
**期間**：2026-03-02 ~ 2026-03-08

---

## Sprint Backlog

| Story ID | 標題 | Size | Points | 狀態 |
|----------|------|------|--------|------|
| Retro #41 | Token 記錄指引更新 — 三個 SKILL.md 納入 cache tokens 加總計算 | S | 1 | 完成 |
| Retro #42 | OpenCode POC 可行性調查佔位入 Backlog | S | 1 | 完成 |
| US-29（Issue #44） | PROJECT_BOARD.md 與 Retrospective_Log.md 歷史歸檔機制 | M | 2 | 完成 |

**總計：3 Stories / 4 Points**

---

## Acceptance Criteria

### Retro #41：Token 記錄指引更新 — 三個 SKILL.md 納入 cache tokens 加總計算

**User Story**
As a framework user tracking API costs, I want the token recording guidance in all three SKILL.md files to include cache_read_input_tokens and cache_creation_input_tokens in the total calculation, so that the recorded token metrics reflect the true cost of each Sprint phase.

**背景**
Sprint 16 Retro Problem #1 確認：JSONL 中 `input_tokens` 僅 292，但 `cache_read_input_tokens` 達 25M，三個 SKILL.md 的 token 提取指引僅提及 `input_tokens` + `output_tokens`，導致 Execution token 記錄數值失真。

**QA 狀態**：APPROVED

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | sprint-planning SKILL.md 更新 | `skills/sprint-planning/SKILL.md` 的 token 提取指引段落，在主要方法描述中明確包含：`cache_read_input_tokens` + `cache_creation_input_tokens` 加總規則；計算公式為：有效 input tokens = input_tokens + cache_read_input_tokens + cache_creation_input_tokens |
| AC2 | [靜態] | sprint-execution SKILL.md 更新 | `skills/sprint-execution/SKILL.md` 的 token 提取指引段落，同 AC1 規格，包含 cache tokens 加總規則與計算公式 |
| AC3 | [靜態] | sprint-review SKILL.md 更新 | `skills/sprint-review/SKILL.md` 的 token 提取指引段落，同 AC1 規格，包含 cache tokens 加總規則與計算公式 |
| AC4 | [靜態] | 降級路徑不變 | 三個 SKILL.md 的降級路徑（JSONL 解析失敗 → 輸出「Token 資料不可用，需手動補充」）維持不變，僅主要方法描述新增 cache tokens 欄位 |
| AC5 | [靜態] | ADR-003 Checklist 通過 | 修改三個 `skills/*/SKILL.md` 前確認 ADR-003 Framework Document Change Audit Checklist 四項條件全部通過 |

**MoSCoW**：Must（Retro Action Item 強制列入） / **Size**：S / **Points**：1
**來源**：Sprint 16 Retro Action #1 / Issue #41
**ADR-003**：適用（修改三個 skills/*/SKILL.md）
**獨立性**：高（修改各 SKILL.md 的 token 指引段落，與 US-29 修改的歸檔觸發段落無交集）

---

### US-29（Issue #44）：PROJECT_BOARD.md 與 Retrospective_Log.md 歷史歸檔機制

**User Story**
As a Product Owner, I want a formal archiving mechanism for PROJECT_BOARD.md and Retrospective_Log.md historical records, so that these files stay lean and don't grow unboundedly, while historical data remains accessible via archive files.

**QA 狀態**：NEEDS_REVISION（已依 QA 回饋修正如下）

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 歸檔觸發條件與目標路徑定義 | `skills/sprint-review/SKILL.md`（或獨立歸檔指引文件）明確定義歸檔觸發時機：**Sprint Review 完成時**，若 `PROJECT_BOARD.md` 歷史 Sprint 區塊超過 5 個，或 `Retrospective_Log.md` Sprint 記錄超過 5 個，則觸發歸檔作業。歸檔目標路徑：`docs/km/archive/PROJECT_BOARD_ARCHIVE.md`（PROJECT_BOARD 歸檔）、`docs/km/archive/RETRO_ARCHIVE.md`（Retrospective_Log 歸檔）。觸發條件與目標路徑需明確標注於指引文件中 |
| AC2 | [靜態] | 歸檔後主文件保留範圍 | 主文件歸檔後的保留策略：以「Sprint Review 完成時」為計算基準，保留當前 Sprint + 最近 2 個 Sprint 的完整記錄；超出範圍的歷史記錄移至對應歸檔文件。主文件底部新增歸檔連結，指向 `docs/km/archive/PROJECT_BOARD_ARCHIVE.md`（及 `RETRO_ARCHIVE.md`），讓歷史紀錄仍可追蹤查閱 |
| AC3 | [靜態] | 首次歷史歸檔執行 | 本次為一次性歷史歸檔：**Sprint 1–13 的全部記錄移至歸檔文件**（`PROJECT_BOARD_ARCHIVE.md` 與 `RETRO_ARCHIVE.md`）。歸檔文件依 Sprint 編號遞增排列，包含原始完整內容。首次歸檔完成後，主文件僅保留 Sprint 14–17（當前）；後續每次 Sprint Review 時依 AC1 觸發條件漸進歸檔（每次最多移動 1 個最舊 Sprint 直到符合保留範圍） |
| AC4 | [靜態] | 歸檔文件建立 | 建立 `docs/km/archive/PROJECT_BOARD_ARCHIVE.md` 與 `docs/km/archive/RETRO_ARCHIVE.md`；每份歸檔文件包含文件標頭（說明歸檔來源、最後更新日期、歸檔範圍）；歸檔內容以原始格式保存，不刪減或重新格式化 |
| AC5 | [靜態] | docs/km/archive/ 目錄索引 | `docs/km/archive/` 目錄下建立 `README.md`，列出目錄內所有歸檔文件、歸檔範圍（Sprint 編號起迄）與最後更新日期，作為歸檔目錄的導覽起點 |

**RICE 評分**：18.0（Reach 6 × Impact 3 × Confidence 75% ÷ Effort 0.75）
**MoSCoW**：Should / **Size**：M / **Points**：2
**來源**：GitHub Issue #44
**依賴**：無前置阻塞（獨立可執行）
**ADR-003**：不適用（建立新文件 `docs/km/archive/`，修改 `docs/PROJECT_BOARD.md` 與 `docs/km/Retrospective_Log.md` 為文件內容更新而非 SKILL.md/commands/agents 修改；SKILL.md 的指引更新屬 Retro #41 範疇）

---

### Retro #42：OpenCode POC 可行性調查佔位入 Backlog

**User Story**
As a Product Owner, I want a placeholder backlog item for OpenCode POC feasibility investigation to be formally registered, so that the team's interest in OpenCode integration (surfaced in Sprint 16 Retro) is captured and can be prioritized in future Planning sessions.

**QA 狀態**：NEEDS_REVISION（已依 QA 回饋修正如下）

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | PRODUCT_BACKLOG.md 佔位條目新增 | `docs/prd/PRODUCT_BACKLOG.md` 新增 OpenCode POC 候選條目，位置放於最新 Sprint 後段的「候選 Stories」區塊 |
| AC2 | [靜態] | 佔位條目格式規範 | 佔位條目僅需最低規格內容，包含以下欄位：標題（OpenCode POC 可行性調查）、MoSCoW: Could、Size: 待定、來源: Retro #42 / Issue #3、狀態: 候選。完整 RICE 評分與 Acceptance Criteria 留待下次 Sprint Planning 精化，本 Story 不要求完整 AC |
| AC3 | [靜態] | 格式參照一致性 | 佔位條目格式參照 `docs/decisions/retro-19-domain-expert-review.md` 中的「若未來決定採納」欄位樣式，採用精簡表格或清單形式，不要求完整 User Story 格式 |

**MoSCoW**：Could / **Size**：S / **Points**：1
**依賴**：US-17（Sprint 16 多平台調查）已完成，OpenCode 評分資料可供參考
**ADR-003**：不適用（修改 `docs/prd/PRODUCT_BACKLOG.md`，非 skills/commands/agents 目錄）

---

## 平行分群策略

（Architect Sprint 17 Planning 建議）

### Phase 1（可平行）

| Story ID | 修改目標 | 說明 |
|----------|---------|------|
| Retro #41 | `skills/sprint-planning/SKILL.md`、`skills/sprint-execution/SKILL.md`、`skills/sprint-review/SKILL.md`（token 提取段落） | ADR-003 適用，三個 SKILL.md 的 token 計算公式更新 |
| Retro #42 | `docs/prd/PRODUCT_BACKLOG.md` | 新增佔位條目，不影響其他檔案 |

**平行化理由**：Retro #41 修改三個 SKILL.md 的 token 提取段落，Retro #42 修改 `docs/prd/PRODUCT_BACKLOG.md`，目標檔案完全不重疊，可完全平行執行。

### Phase 2（序列）

| 步驟 | Story ID | 修改目標 | 說明 |
|------|----------|---------|------|
| 2-1 | US-29 | `docs/km/archive/`（新建）+ `docs/PROJECT_BOARD.md` + `docs/km/Retrospective_Log.md` | 歸檔機制建立，需 Phase 1 完成後確認 SKILL.md 歸檔路徑定義一致，再執行實際歸檔作業 |

**序列理由**：US-29 修改 `skills/sprint-review/SKILL.md` 新增歸檔觸發步驟，與 Retro #41 修改同檔案的 token 段落屬不同段落但為避免 last-write-wins 風險，建議 Retro #41 先完成後再執行 US-29。

---

## 工作容量

| 指標 | 數值 |
|------|------|
| 計畫 Stories | 3 |
| 計畫 Points | 4（2S + 1M = 1+1+2） |
| 近 3 Sprint 平均 Velocity | 4.7pt（Sprint 14: 2、Sprint 15: 4、Sprint 16: 8） |
| Sprint 16 Velocity | 8pt |
| 緩衝率 | 85%（低於歷史平均，保守容量，適合 Sprint 16 高強度後的穩定恢復期） |

**容量決策說明**：
Sprint 17 選入 3 Stories（4 points），低於近 3 Sprint 平均 Velocity（4.7pt）。選入理由：
1. QA Hard Gate 已通過（Retro #41 APPROVED；US-29、Retro #42 NEEDS_REVISION 已由 PO Round 2 修訂 AC）
2. 3 個 Story 均為 S 或 M size，無高風險項目
3. Sprint 16 交付了 8 points（含 6 Stories），本 Sprint 採保守容量以確保品質
4. US-29 為首次建立歸檔機制，涉及多份文件操作，M size 合理評估
5. Stakeholder 優先級指示「檔案瘦身優先，效能與安全相關優先」已在 Sprint Goal 中體現

---

## ADR-003 觸發清單

| Story | 觸發原因 | 適用狀態 |
|-------|---------|---------|
| Retro #41 | 修改 `skills/sprint-planning/SKILL.md`、`skills/sprint-execution/SKILL.md`、`skills/sprint-review/SKILL.md`（token 提取段落） | 適用 |
| US-29 | 建立 `docs/km/archive/`（新文件），修改 `docs/PROJECT_BOARD.md` 與 `docs/km/Retrospective_Log.md`（文件內容更新） | 不適用（非 skills/commands/agents 目錄） |
| Retro #42 | 修改 `docs/prd/PRODUCT_BACKLOG.md`（非 skills/commands/agents/） | 不適用 |

---

## Token 記錄

| 環節 | Token | 備註 |
|------|-------|------|
| Planning | 待補 | Sprint 17 Planning 完成後從 JSONL 提取（或依 Retro #38 調查結論決定提取方式） |
| Execution | 待補 | Sprint 17 Execution 完成後填入 |
| Review | 待補 | Sprint 17 Review 完成後填入 |
