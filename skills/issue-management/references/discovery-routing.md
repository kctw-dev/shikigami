# §14 Issue → Discovery Phase 完整路由圖

> 此檔案由 `issue-management/SKILL.md §14` 拆出，主文件保留摘要與指針。

使用者回饋透過 Issue 系統流入，經由標準化路由最終閉環至 Discovery Phase，形成完整的回饋→需求探索閉環。

## 14.1 完整路由圖

```
使用者回饋（GitHub Issue）
  │
  ▼
[§10 Triage — 分類無標籤 Issues]
  │  PO subagent 判定類型，套用 label
  │
  ├─ feature-request ──────────────────────────────────────────┐
  │                                                             │
  ▼                                                             │
[§11 Backlog Bridge — Issue 入庫]                               │
  │  改寫 Issue body（Story template + RICE 評分）              │
  │  套用 labels：auto-triaged, status: backlog, priority: X   │
  │                                                             │
  ▼                                                             │
[/backlog-management §3 Grooming — Sprint 中段]                 │
  │  匯總 feature-request 趨勢（數量、重複主題、投票數排序）       │
  │  偵測達閾值 Issues（§10.2：≥3 thumbs-up 或 ≥5 comments）    │
  │                                                             │
  ├─ 未達閾值 ─→ 維持 Backlog，等待 Sprint Planning 排序         │
  │                                                             │
  └─ 達閾值 ──────────────────────────────────────────────────▶│
                                                               │
  ◀──────────────────────────────────────────────────────────┘
  │
  ▼
[/discovery-phase — Phase 0 產品探索]
  │  Issue 觸發入口（見 discovery-phase §2 Step 1 Issue 觸發）
  │  Step 1 背景分析 → Step 2 假設外顯化 → Step 3 Product Brief
  │  → Step 4 技術可行性 → Step 5 PO 簽核 → Step 6 轉化 Backlog
  │
  ▼
[GitHub Issue — Discovery 產出]
  │  新開 Issue（含 Product Brief 引用）
  │  套用 feature-request label
  │
  ▼
[/backlog-management §3 Grooming — RICE 評分與優先級排序]
  │
  ▼
[/sprint-planning — Sprint 週期選取]
  │
  ▼
[/sprint-execution — Story 開發]
  │
  ▼
Issue Close（對應 feature-request Issue 關閉）
```

## 14.2 路由節點說明

| 節點 | Skill / 章節 | 職責 |
|------|-------------|------|
| Triage | §10 | 為無 label Issue 分類，判定為 `feature-request` |
| Backlog Bridge | §11 | 將 Issue 轉換為 Story template，入庫至 Backlog |
| Grooming 匯總 | /backlog-management §3 | Sprint 中段匯總回饋趨勢，偵測 Discovery 觸發閾值 |
| Discovery Phase | /discovery-phase | 深度探索需求，產出 Product Brief 並簽核 |
| Sprint Planning | /sprint-planning | 從 Groomed Backlog 選取 Stories 進入 Sprint |

## 14.3 閉環驗證條件

一個完整的 Issue 閉環需滿足：

- [ ] 原始 `feature-request` Issue 已完成 Backlog Bridge 入庫（帶 `backlog-intake-done` label）
- [ ] Discovery Phase 已產出對應 Product Brief（狀態：PO 已簽核）
- [ ] Discovery 產出的 GitHub Issue 已完成 RICE 評分並排入 Backlog
- [ ] 對應 Story 完成開發後，原始 `feature-request` Issue 附留言說明閉環結果並關閉
