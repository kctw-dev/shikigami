---
name: backlog-management
description: "Use when new feature requests arrive, requirements change, backlog grooming is needed, or product discovery begins"
---

# Backlog Management — 需求管理與產品探索

## 1. 概述

Backlog Management 合併 **Product Discovery** 與 **Backlog Grooming** 兩個流程，由 **Product Owner (PO)** 主導需求管理的全生命週期。

- **Product Discovery**：在里程碑啟動時執行，從願景文件中發掘需求、識別功能缺口與技術債，並透過 RICE 框架收斂排序，產出可執行的 Product Backlog。
- **Backlog Grooming**：在 Sprint 中段定期執行，維護 Backlog 的健康度——移除過時 Story、補充新 Story、調整優先級、確保驗收標準清晰。

**目標**：確保 Product Backlog 始終反映最新的產品策略與優先級，讓每次 Sprint Planning 都能從健康的 Backlog 中選取 Stories。

---

## 2. Product Discovery 流程（里程碑啟動時）

以下步驟必須逐項完成，不可跳過：

- [ ] **PO subagent** 分析願景文件（PRD、產品文件），理解里程碑目標與產品方向
- [ ] **PO subagent** 盤點現有功能缺口與技術債，比對目前產品狀態與目標之間的差距
- [ ] **PO + Architect subagent 討論**：探討功能可能性與技術可行性，識別潛在風險與依賴
- [ ] **Architect subagent** 識別需要 ADR（Architecture Decision Record）的 Story，標注「需要 ADR」
- [ ] **PO subagent** 使用 RICE 框架對所有候選 Story 進行評分與排序，收斂為優先級清單
- [ ] **PO subagent** 為每個新需求直接開 GitHub Issue，套用原始 Issue labels（`feature-request` / `bug` / `question`），並更新 `docs/prd/ROADMAP.md`

**產出**：GitHub Issues（新需求開 Issue + 套用 label），不再寫入 `PRODUCT_BACKLOG.md`。里程碑規劃仍以 `docs/prd/ROADMAP.md` 為準。

---

## 3. Backlog Grooming 流程（Sprint 中段執行）

### Pre-flight 錯誤恢復掃描

每次 Grooming 執行前，必須先完成以下三項 Pre-flight 掃描，偵測並修復可能的不一致狀態（對應 ADR-010 §錯誤恢復策略）：

- [ ] **場景一：Label 操作中斷後掃描**
  執行以下指令，偵測 label 狀態不一致的 Issues（例如同時持有 `status: backlog` 與 `status: in-sprint`，或缺少必要 label）：
  ```bash
  gh issue list --label "type: backlog-item" --state open --json number,title,labels --limit 200
  ```
  若偵測到不一致，以 `gh issue edit <number> --add-label "<label>"` / `--remove-label "<label>"` 自動修復至目標狀態。

- [ ] **場景二：Backlog Issue 建立部分完成後掃描**
  掃描所有 Backlog Issues 的 body 中「來源：#N」欄位，偵測已存在對應關係的原始 Issue，跳過重複建立：
  ```bash
  gh issue list --label "type: backlog-item" --state open --json number,body --limit 200
  ```
  若發現 body 包含「來源：#N」但原始 Issue #N 尚未套用 `backlog-linked` label，則補套用該 label。

- [ ] **場景三：Sprint Planning milestone 中斷後掃描**
  掃描 label 與 milestone 狀態不一致的 Issues（例如具有 `status: in-sprint` 但未關聯 milestone，或已關聯 milestone 但仍有 `status: backlog`）：
  ```bash
  gh issue list --label "type: backlog-item" --state open --json number,title,labels,milestone --limit 200
  ```
  若偵測到不一致，自動修復後再繼續 Grooming 主流程。

---

### Grooming 主流程

以下步驟必須逐項完成，不可跳過：

- [ ] **PO subagent** 以下列指令查看目前 Backlog：
  ```bash
  gh issue list --label "type: backlog-item" --label "status: backlog" --state open \
    --json number,title,body,labels --limit 200
  ```
- [ ] 關閉過時或已不再適用的 Story Issue（`gh issue close <number>`）
- [ ] 根據最新需求與回饋，新開 Backlog Issue 並套用 `type: backlog-item` + `status: backlog` labels
- [ ] 以 `gh issue edit <number>` 調整優先級 label（`priority: must` / `priority: should` / `priority: could`）並更新 Issue body 中的 RICE 分數
- [ ] 確保每個 Backlog Issue body 有清楚的 Acceptance Criteria（驗收標準）

---

## 4. User Story 格式

所有 User Story 必須遵循以下標準格式：

```
As a [role], I want [goal], so that [benefit]
```

**範例**：

```
As a developer, I want automated test coverage reports, so that I can identify untested code paths quickly.
```

每個 Story 必須包含：

| 欄位 | 說明 |
|------|------|
| Story 標題 | 簡潔描述功能 |
| User Story | 遵循 `As a / I want / so that` 格式 |
| Acceptance Criteria | 明確、可測試的驗收條件（至少 1 條） |
| RICE 分數 | Reach、Impact、Confidence、Effort 各項評分與總分 |
| 優先級標籤 | MoSCoW 分類（Must / Should / Could / Won't） |
| ADR 標注 | 是否需要 ADR（若涉及技術選型） |

---

## 5. 優先級框架

### 5.1 RICE Scoring

RICE 是主要的量化排序框架，用於客觀比較 Story 的優先級：

| 維度 | 說明 | 評分範圍 |
|------|------|----------|
| **Reach** | 影響的使用者或場景數量 | 1–10 |
| **Impact** | 對使用者/產品的影響程度 | 0.25 / 0.5 / 1 / 2 / 3 |
| **Confidence** | 對評估的信心程度 | 50% / 80% / 100% |
| **Effort** | 所需工作量（人週） | 0.5–10 |

**計算公式**：

```
RICE Score = (Reach × Impact × Confidence) ÷ Effort
```

分數越高，優先級越高。

### 5.2 MoSCoW 分類

MoSCoW 作為輔助標籤，提供直覺式的優先級分類：

| 分類 | 說明 |
|------|------|
| **Must** | 本里程碑必須完成，缺少會導致產品無法交付 |
| **Should** | 重要但非必要，應盡量納入 |
| **Could** | 有價值但可延後，若有餘力則納入 |
| **Won't** | 本里程碑明確不做，記錄以備未來參考 |

**使用原則**：RICE 分數用於 Backlog 內部排序，MoSCoW 標籤用於與 Stakeholder 溝通與里程碑範圍管理。

---

## 6. 產出文件

Backlog Management 完成後，必須確認以下產出狀態：

**核心產出（以 GitHub Issues 為 source of truth）**

| 產出 | 說明 |
|------|------|
| GitHub Issues 狀態（labels / body / milestone） | 核心產出。Backlog Issues 持有最新的 MoSCoW labels（`priority: must/should/could`）、RICE 分數（body 內 RICE 評分表格）、Acceptance Criteria，以及 `status: backlog` / `status: in-sprint` 狀態 |
| `docs/prd/ROADMAP.md` | 產品路線圖，反映里程碑規劃與 Story 的時程分配（仍以 .md 檔案為準） |
| `docs/adr/ADR-xxx.md` | 若有涉及技術選型的 Story，需透過 `architecture-decision` Skill 建立對應的 ADR |

**非核心產出（唯讀歷史快照）**

| 產出 | 說明 |
|------|------|
| `docs/prd/PRODUCT_BACKLOG.md` | 非核心產出（唯讀歷史快照）。自 ADR-010 起降格，Backlog 的 source of truth 已遷移至 GitHub Issues。本文件不再被框架 Skills 寫入，保留作為歷史參考。 |
| `docs/prd/BACKLOG_DONE.md` | 已完成 Stories 歸檔。按 Sprint 整理，保留完整 RICE 評分與 AC（歷史記錄，持續有效）。 |

---

## 7. Subagent 派遣順序

### Product Discovery（里程碑啟動）

```
1. PO        → 分析願景文件、盤點功能缺口與技術債
2. PO + Arch → 討論功能可能性與技術可行性
3. Architect → 識別需要 ADR 的 Story
4. PO        → RICE 評分排序、產出 Backlog 與 Roadmap
```

### Backlog Grooming（Sprint 中段）

```
0. PO → Pre-flight 錯誤恢復掃描（偵測並修復不一致 label / milestone 狀態）
1. PO → gh issue list 查看 Backlog Issues、關閉過時 Story
2. PO → gh issue edit 調整 RICE 分數與優先級 labels
3. PO → gh issue edit 確認 Acceptance Criteria（更新 Issue body）
```

**派遣說明**：

1. **PO（分析階段）**：讀取 PRD 與產品相關文件，理解里程碑目標。同時透過 `gh issue list --label "type: backlog-item" --label "status: backlog" --state open` 盤點現有 Backlog Issues 與已知技術債，建立候選 Story 清單。
2. **PO + Architect（協作階段）**：PO 提出功能需求，Architect 評估技術可行性。雙方共同討論每個候選 Story 的實現方式與潛在風險。Architect 在此階段標注需要 ADR 的 Story。
3. **PO（收斂階段）**：根據 Architect 的回饋，使用 RICE 框架為每個 Story 評分排序，以 `gh issue edit` 套用 MoSCoW priority labels（`priority: must/should/could`）並更新 Issue body 中的 RICE 評分表格。里程碑規劃更新至 ROADMAP.md。
