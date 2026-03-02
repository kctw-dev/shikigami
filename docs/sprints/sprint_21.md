# Sprint 21

**狀態**：進行中
**期間**：2026-03-09 ~ 2026-03-15
**Sprint Goal**：清零 Sprint 20 Retro Action Item（#58）+ parallel-dispatch 衝突偵測（US-32）+ Onboarding Labels 補完（US-34）
**總計**：3 Stories / 4 Points

---

## Sprint Backlog

| Story ID | 標題 | Size | Points | 狀態 |
|----------|------|------|--------|------|
| Retro #58（Issue #58） | L-size Story QA checklist 強化 — SKILL.md 新增大型 Story 審查增強項 | S | 1 | 待執行 |
| US-32（Issue #40） | parallel-dispatch 應內建同檔案衝突偵測與自動序列化 | M | 2 | 待執行 |
| US-34（Issue #32） | Onboarding 應預建常用 GitHub Labels | S | 1 | 待執行 |

**Sprint 容量**：4 Points

---

## Story 詳細 AC

---

### Retro #58（Issue #58）：L-size Story QA checklist 強化 — SKILL.md 新增大型 Story 審查增強項

**來源**：Sprint 20 Retrospective
**Size**：S / 1 Point
**Owner**：Developer

**User Story**
As a QA subagent, I want sprint-execution SKILL.md to include an enhanced review checklist for L-size Stories, so that large, high-risk Stories receive more thorough quality gates that reduce the chance of incomplete or incorrect deliveries.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | Checklist 新增 | `skills/sprint-execution/SKILL.md` §4 Hard Gates 或 §6 審查流程區塊新增「L-size Story 審查增強」Checklist 條目（至少 2 項增強檢查項） |
| AC2 | [靜態] | 觸發條件明確 | Checklist 明確定義觸發條件：Story Size 為 L（3 points）時自動啟用增強審查 |
| AC3 | [靜態] | 格式一致性 | 新增的 Checklist 條目格式須與現有條目一致（無序列表 `- [ ]` + 粗體項目名稱 + 說明文字） |

---

### US-32（Issue #40）：parallel-dispatch 應內建同檔案衝突偵測與自動序列化

**來源**：GitHub Issue #40
**Size**：M / 2 Points
**Owner**：Developer

**User Story**
As a Scrum Master dispatching parallel Stories, I want the parallel-dispatch skill to automatically detect when two Stories modify the same file and serialize their execution, so that file-level conflicts are prevented without requiring manual coordination.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 偵測邏輯存在 | `skills/sprint-execution/prompts/developer-prompt.md` 新增「同檔案衝突偵測」區段，定義偵測邏輯（輸入：Story 修改檔案清單 + 其他平行 Story 修改清單 → 輸出：衝突檔案列表） |
| AC2 | [靜態] | 自動序列化結構性驗證 | developer-prompt.md 定義衝突發生時的自動序列化處理邏輯，且須包含以下三個結構性要素：(a) 衝突偵測觸發條件定義存在（明確說明何種情況視為衝突）；(b) 序列化切換指引存在（定義衝突時如何從平行切換為序列執行）；(c) 使用者告警格式定義存在（明確規定告警訊息的必要欄位） |
| AC3 | [靜態] | 告警格式 | 偵測到衝突時，Developer subagent 須輸出標準化告警，格式包含：衝突檔案路徑、涉及 Story ID、建議執行順序 |
| AC4 | [動態] | 回歸驗證 | 無衝突場景下（所有 Story 修改不同檔案），Developer 行為與現行版本完全一致（回歸不破壞） |

---

### US-34（Issue #32）：Onboarding 應預建常用 GitHub Labels

**來源**：GitHub Issue #32
**Size**：S / 1 Point
**Owner**：Developer

**User Story**
As a new user setting up Shikigami, I want the onboarding process to include a script that creates common GitHub Labels automatically, so that my repository is immediately ready for Shikigami's label-based workflows without manual label configuration.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [動態] | Label 建立腳本 | Onboarding 新增 `scripts/setup-labels.sh`，執行後透過 `gh label create` 建立常用 Labels（至少包含：bug、feature-request、retro-action、in-backlog、needs-info、priority-high、priority-low） |
| AC2 | [靜態] | 冪等性 | 腳本支援冪等執行：已存在的 Label 不重複建立，不報錯（使用 `--force` 或先檢查再建立） |
| AC3 | [靜態] | 文件更新 | `docs/tutorial/GETTING_STARTED.md` 新增 Label 設定步驟，引導使用者執行 `scripts/setup-labels.sh` |

---

## 平行分群（Architect 建議）

### Phase 1（可平行執行）

| Story | 負責人 |
|-------|--------|
| Retro #58（Issue #58） | Developer |
| US-32（Issue #40） | Developer |
| US-34（Issue #32） | Developer |

---

## 工作容量

| 項目 | 數值 |
|------|------|
| Sprint 期間 | 2026-03-09 ~ 2026-03-15（7 天） |
| 總 Stories | 3 |
| 總 Points | 4 |
| Phase 1 容量 | 4 Points（可平行） |

---

## ADR 觸發清單

| Story | ADR 需求 | 說明 |
|-------|----------|------|
| Retro #58 | 無 | 流程指引修改，不涉及技術選型 |
| US-32 | 無 | Prompt 指引修改，不涉及架構決策 |
| US-34 | 無 | 新增腳本，採既有 gh CLI 模式，無需新 ADR |

---

## Sprint Planning 簽核

- **PO Round 1**：完成（Story 選取、初版 AC）
- **Architect Round 1**：完成（估點確認：4pt；無 ADR 觸發；平行分群建議）
- **QA Round 1**：完成（Retro #58 AC3 修訂要求；US-32 AC2 修訂要求）
- **PO Round 2**：完成（AC 修訂完成，Sprint 文件建立）
