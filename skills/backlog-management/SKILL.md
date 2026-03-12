---
name: backlog-management
description: "Use when new feature requests arrive, requirements change, backlog grooming is needed, or product discovery begins"
---

# Backlog Management — 需求管理與產品探索

## 1. 概述

Backlog Management 負責 **Backlog Grooming** 流程，由 **Product Owner (PO)** 主導 Backlog 的維護與優先級管理。

> **注意**：Product Discovery 流程已獨立為 `/discovery-phase` Skill（ADR-018 裁決）。里程碑啟動時請先執行 `/discovery-phase`，產出的 GitHub Issues 再由本 Skill 的 §3 Backlog Grooming 接手維護。

- **Backlog Grooming**：在 Sprint 中段定期執行，維護 Backlog 的健康度——移除過時 Story、補充新 Story、調整優先級、確保驗收標準清晰。

**目標**：確保 Product Backlog 始終反映最新的產品策略與優先級，讓每次 Sprint Planning 都能從健康的 Backlog 中選取 Stories。

---

## 2. Product Discovery 流程

> **注意**：完整的 Product Discovery 流程已獨立為 `/discovery-phase` Skill（ADR-018 裁決）。
>
> 請使用 `/discovery-phase` 執行完整的產品探索流程，包含 Product Brief 標準化格式、假設外顯化機制與 PO 確認關卡。
>
> 本 Skill 的 §3 Backlog Grooming 仍負責 Discovery 產出物的後續維護。

---

## 3. Backlog Grooming 流程（Sprint 中段執行）

### Pre-flight 錯誤恢復掃描

每次 Grooming 執行前，必須先完成以下兩項 Pre-flight 掃描，偵測並修復可能的不一致狀態（對應 ADR-010 §錯誤恢復策略）：

- [ ] **場景一：Label 操作中斷後掃描**
  執行以下指令，偵測 label 狀態不一致的 Issues（例如同時持有 `status: backlog` 與 `status: in-sprint`，或缺少必要 label）：
  ```bash
  gh issue list --label "status: backlog" --state open --json number,title,labels --limit 200
  ```
  若偵測到不一致，以 `gh issue edit <number> --add-label "<label>"` / `--remove-label "<label>"` 自動修復至目標狀態。

- [ ] **場景二：Sprint Planning milestone 中斷後掃描**
  掃描 label 與 milestone 狀態不一致的 Issues（例如具有 `status: in-sprint` 但未關聯 milestone，或已關聯 milestone 但仍有 `status: backlog`）：
  ```bash
  gh issue list --label "status: backlog" --state open --json number,title,labels,milestone --limit 200
  ```
  若偵測到不一致，自動修復後再繼續 Grooming 主流程。

---

### Feature-Request 回饋匯總（每次 Grooming 自動執行）

每次 Sprint Grooming 執行時，PO subagent 必須**自動匯總** `feature-request` Issue 的回饋趨勢，作為 Grooming 主流程的前置輸出。

**執行指令**：

```bash
# Step A：取得所有 feature-request Issues（含 reactions 與 comments 數量）
gh issue list --label "feature-request" --state open \
  --json number,title,url,reactionGroups,comments,createdAt --limit 200

# Step B：解析 thumbs-up 數量並排序
# （由 PO subagent 解析 reactionGroups[].content == "THUMBS_UP" 的 reactors.totalCount）
```

**匯總輸出格式**（必須在 Grooming 主流程前呈現）：

```
## Feature-Request 回饋趨勢匯總（Sprint Grooming）

### 投票數排序 Top-N（按 thumbs-up 降序）
| # | Issue | 👍 Reactions | 💬 Comments | 建議動作 |
|---|-------|-------------|------------|---------|
| 1 | #<N> <標題> | <數> | <數> | [達閾值] 建議啟動 /discovery-phase |
| 2 | #<N> <標題> | <數> | <數> | 維持 Backlog |
| … |

### 重複主題識別
- 主題「<主題描述>」：涉及 Issue #<N1>, #<N2>（共 <X> 個，合計 <Y> 票）
- （若無重複主題，輸出：未識別到重複主題）

### Discovery 觸發建議
- 達閾值（≥3 👍 或 ≥5 💬）Issues：<N> 筆
- 建議啟動 /discovery-phase：<列出 Issue #N 與標題>
- 已帶 `discovery-candidate` label：<N> 筆
```

**閾值定義**（對應 `/issue-management §10.2`）：

| 觸發條件 | 閾值 |
|---------|------|
| Thumbs-up reactions（👍） | ≥ 3 |
| Comments 數量 | ≥ 5 |

達閾值的 Issue 自動套用 `discovery-candidate` label（低風險操作，自動執行）：

```bash
gh issue edit <N> --add-label "discovery-candidate"
```

---

### Grooming 主流程

以下步驟必須逐項完成，不可跳過：

- [ ] **PO subagent** 以下列指令查看目前 Backlog：
  ```bash
  gh issue list --label "status: backlog" --state open \
    --json number,title,body,labels --limit 200
  ```
- [ ] 關閉過時或已不再適用的 Story Issue（`gh issue close <number>`）
- [ ] 根據最新需求與回饋，新開 Issue（系統自動觸發入庫，不需手動貼 label），或直接套用 `status: backlog` label 並編寫 Story template（User Story、Acceptance Criteria、RICE 評分）
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

## 7. PO 審查積壓量

每次執行 `/backlog-management` 時，必須自動輸出 PO 審查積壓量摘要，以便 PO 掌握待審 Issue 數量與老齡狀態。

### 7.1 計數指令

執行以下指令取得所有待審 Issues（帶有 `auto-triaged` label、狀態為 open）：

```bash
gh issue list --label "auto-triaged" --state open \
  --json number,title,createdAt --limit 200
```

### 7.2 老齡警示規則

根據 Issue 建立時間（`createdAt`）計算齡期，套用以下警示等級：

| 齡期 | 警示等級 | 說明 |
|------|----------|------|
| 0–6 天 | 無警示 | 正常積壓範圍 |
| 7–13 天 | `[WARNING]` | 待審超過 7 天，應優先安排審查 |
| 14 天以上 | `[CRITICAL]` | 待審超過 14 天，需立即處理以防止需求流失 |

### 7.3 輸出格式

執行 `/backlog-management` 時，必須在輸出開頭呈現以下摘要區塊：

```
## PO 審查積壓量摘要

- 待審 Issues 計數：<N> 筆
- 最老 Issue 齡期：<D> 天（Issue #<number>：<title>）
- 警示等級：<無警示 / [WARNING] / [CRITICAL]>
```

若無任何待審 Issue，輸出：

```
## PO 審查積壓量摘要

- 待審 Issues 計數：0 筆
- 警示等級：無警示
```

---

## 8. Subagent 派遣順序

> **注意**：Product Discovery 流程已獨立為 `/discovery-phase` Skill，里程碑啟動時請使用 `/discovery-phase`。

### Backlog Grooming（Sprint 中段）

```
0. PO → Pre-flight 錯誤恢復掃描（偵測並修復不一致 label / milestone 狀態）
1. PO → gh issue list 查看 Backlog Issues、關閉過時 Story
2. PO → gh issue edit 調整 RICE 分數與優先級 labels
3. PO → gh issue edit 確認 Acceptance Criteria（更新 Issue body）
```

**派遣說明**：

1. **PO（Pre-flight 掃描）**：執行 Pre-flight 錯誤恢復掃描，偵測並修復 label / milestone 不一致狀態，確保 Backlog 健康度。
2. **PO（Grooming 主流程）**：透過 `gh issue list --label "status: backlog" --state open` 盤點 Backlog Issues，關閉過時 Story，調整 RICE 分數與優先級 labels，確認 Acceptance Criteria。
