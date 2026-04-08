---
name: backlog-management
description: "Use when backlog grooming is needed, requirements change, new stories need RICE scoring, or backlog health maintenance is due"
---

# Backlog Management — 需求管理與產品探索

## 1. 概述

Backlog Management 負責 **Backlog Grooming** 流程，由 **Product Owner (PO)** 主導 Backlog 的維護與優先級管理。

> **注意**：Product Discovery 流程已獨立為 `/discovery-phase` Skill（ADR-018 裁決）。里程碑啟動時請先執行 `/discovery-phase`，產出的 GitHub Issues 再由本 Skill 的 §3 Backlog Grooming 接手維護。

**目標**：確保 Product Backlog 始終反映最新的產品策略與優先級，讓每次 Sprint Planning 都能從健康的 Backlog 中選取 Stories。

---

## 2. Product Discovery 流程

> **注意**：完整的 Product Discovery 流程已獨立為 `/discovery-phase` Skill（ADR-018 裁決）。請使用 `/discovery-phase` 執行，本 Skill §3 Backlog Grooming 負責 Discovery 產出物的後續維護。

---

## 3. Backlog Grooming 流程（Sprint 中段執行）

### Pre-flight 錯誤恢復掃描

每次 Grooming 執行前，必須先完成以下兩項 Pre-flight 掃描（對應 ADR-010 §錯誤恢復策略）：

- [ ] **場景一：Label 操作中斷後掃描**
  ```bash
  gh issue list --label "status: backlog" --state open --json number,title,labels --limit 200
  ```
  若偵測到不一致（同時持有 `status: backlog` 與 `status: in-sprint`），以 `gh issue edit` 自動修復。

- [ ] **場景二：Sprint Planning milestone 中斷後掃描**
  ```bash
  gh issue list --label "status: backlog" --state open --json number,title,labels,milestone --limit 200
  ```
  若偵測到 label 與 milestone 不一致，自動修復後再繼續。

---

### Feature-Request 回饋匯總（每次 Grooming 自動執行）

每次 Grooming 前，PO subagent 必須自動匯總 `feature-request` Issues 的回饋趨勢，按 thumbs-up 降序排列，識別重複主題，並對達閾值（≥3 👍 或 ≥5 💬）的 Issues 自動套用 `discovery-candidate` label。

> 執行指令、輸出格式與閾值定義，見 [`references/feature-request-aggregation.md`](references/feature-request-aggregation.md)

---

### Grooming 主流程

以下步驟必須逐項完成，不可跳過：

- [ ] **PO subagent** 以下列指令查看目前 Backlog：
  ```bash
  gh issue list --label "status: backlog" --state open \
    --json number,title,body,labels --limit 200
  ```
- [ ] 關閉過時或已不再適用的 Story Issue（`gh issue close <number>`）
- [ ] 根據最新需求與回饋，新開 Issue 或套用 `status: backlog` label 並依 `.github/ISSUE_TEMPLATE/` 對應模板編寫 Story body（feature → feature.md、bug → bug.md、chore/refactor/docs/infra → story.md），確保 `## 非功能性需求` 欄位已填寫
- [ ] 以 `gh issue edit <number>` 調整優先級 label（`priority: must` / `priority: should` / `priority: could`）並更新 RICE 分數
- [ ] **AC 完整性檢查**（§3.1 新增）：對所有欲取得 `sprint-candidate` label 的 Issues，執行 AC 存在性與品質檢查；缺少 AC 或 AC 不完整的 Issue 不得取得 `sprint-candidate` label，PO 應留言提醒補齊
  > 詳細檢查規則、執行指令，見 [`references/ac-completeness-check.md`](references/ac-completeness-check.md)

---

## 4. User Story 格式

所有 User Story 必須遵循格式：`As a [role], I want [goal], so that [benefit]`

每個 Story 必須包含：Story 標題、User Story、Acceptance Criteria（至少 1 條）、RICE 分數、優先級標籤（MoSCoW）、ADR 標注（若涉及技術選型）。

---

## 5. 優先級框架

RICE（量化排序）與 MoSCoW（標籤分類）雙軌並行：RICE Score = (Reach × Impact × Confidence) ÷ Effort，分數越高優先級越高；MoSCoW 標籤（Must / Should / Could / Won't）用於里程碑範圍溝通。

> 詳細評分維度、範圍與使用原則，見 [`references/prioritization-framework.md`](references/prioritization-framework.md)

---

## 6. 產出文件

**核心產出（以 GitHub Issues 為 source of truth）**

| 產出 | 說明 |
|------|------|
| GitHub Issues 狀態（labels / body / milestone） | Backlog Issues 持有最新 MoSCoW labels、RICE 分數、Acceptance Criteria 及 status label |
| `docs/prd/ROADMAP.md` | 產品路線圖，反映里程碑規劃與 Story 時程分配 |
| `docs/adr/ADR-xxx.md` | 涉及技術選型的 Story，透過 `architecture-decision` Skill 建立 |

**非核心產出（唯讀歷史快照）**

| 產出 | 說明 |
|------|------|
| `docs/prd/PRODUCT_BACKLOG.md` | 自 ADR-010 起降格，不再被框架 Skills 寫入，保留作歷史參考 |
| `docs/prd/BACKLOG_DONE.md` | 已完成 Stories 歸檔，按 Sprint 整理 |

---

## 7. PO 審查積壓量

每次執行 `/backlog-management` 時，必須自動輸出 PO 審查積壓量摘要（帶有 `auto-triaged` label 的 open Issues），依齡期套用警示等級：0–6 天無警示、7–13 天 `[WARNING]`、14 天以上 `[CRITICAL]`。

> 計數指令、警示規則與輸出格式，見 [`references/backlog-health-metrics.md`](references/backlog-health-metrics.md)

---

## 8. Backlog 健康度閾值與提前預警機制（ADR-043）

<!-- #721 Backlog 補充頻率調整 — Sprint 154 -->
<!-- ADR-043 Backlog Replenishment Strategy (Accepted) -->

**閾值定義**（ADR-043 決策）：

| 指標 | 閾值 | 說明 |
|------|------|------|
| 預警閾值 | sprint-candidate < **10** | 觸發 [BACKLOG-REPLENISH-TRIGGER] 信號 |
| 目標庫存 | sprint-candidate >= **16** | 確保 2-Sprint 提前期（每 Sprint 選約 8pts，2 Sprint = 16 候選） |
| 觸發時機 | **當前 Sprint 執行中** | 主動觸發，不等到 Sprint Review 後（從「事後補充」改為「提前預警」） |

**預警流程**：

```
每次 Sprint Review § 2.7 執行時：
  BACKLOG_THRESHOLD = 10 (ADR-043)
  SPRINT_CANDIDATE_COUNT = gh issue list --label sprint-candidate --state open | jq length

  SPRINT_CANDIDATE_COUNT < BACKLOG_THRESHOLD
    → [BACKLOG-REPLENISH-TRIGGER]
    → project_level=low：自動觸發 /backlog-management 補充（在當前 Sprint 內，不等下一 Sprint）
    → 目標：補充至 sprint-candidate >= 16（2-Sprint 提前期）

  SPRINT_CANDIDATE_COUNT >= BACKLOG_THRESHOLD
    → [BACKLOG-HEALTH-OK]
```

> 決策依據：`docs/adr/ADR-043-backlog-replenishment-strategy.md`

---

## 9. Subagent 派遣順序

> **注意**：Product Discovery 流程已獨立為 `/discovery-phase` Skill，里程碑啟動時請使用 `/discovery-phase`。

```
0. PO → Pre-flight 錯誤恢復掃描（偵測並修復不一致 label / milestone 狀態）
1. PO → gh issue list 查看 Backlog Issues、關閉過時 Story
2. PO → gh issue edit 調整 RICE 分數與優先級 labels
3. PO → gh issue edit 確認 Acceptance Criteria（更新 Issue body）
4. PO → AC 完整性檢查（§3.1）：對欲取得 sprint-candidate 的 Issues 檢查 AC；缺 AC 者留言提醒，不給 label
5. PO → Backlog 健康度檢查（§8）：sprint-candidate 計數 vs 閾值 10（ADR-043）
```
