# §10 Triage — 批次分類（完整細節）

> 此檔案由 `issue-management/SKILL.md §10` 拆出，主文件保留摘要與指針。

**風險等級**：混合（查詢=低，標記=低，留言=高）
**分類標準與留言模板**：見 `triage-prompt.md`

## 流程

1. 列出所有無 label 的 open issues：
   ```bash
   gh issue list --search "no:label" --state open --json number,title,body
   ```
2. 讀取 repo 現有 labels，確認目標 labels 存在：
   ```bash
   gh label list --json name,description
   ```
   若 `bug`、`feature-request`、`question`、`documentation`、`invalid` 任一不存在，自動建立（低風險）。
3. 對每個 issue 依 `triage-prompt.md` 的分類規則判定類型（按優先順序匹配）：

| 類型 | 對應 Label | 判定依據 |
|------|-----------|----------|
| Bug 回報 | `bug` | 描述異常行為、錯誤訊息、重現步驟 |
| 功能請求 | `feature-request` | 期望新功能、改進建議 |
| 問題諮詢 | `question` | 使用方式、配置問題 |
| 文件相關 | `documentation` | 文件錯誤、缺少說明 |
| 無效 | `invalid` | 無法理解、明顯非本專案範圍 |

4. 生成分類建議清單（批次分析，一次呈現摘要表格）
5. 套用 labels（低風險，自動執行）
6. 若 bug 類型缺少重現步驟，或 feature-request 缺少驗收標準：
   - 依 `triage-prompt.md` 的留言模板生成補充資訊請求
   - 依專案等級處理留言（高風險操作）
7. 輸出 Triage 摘要報告：

```
Triage 結果摘要：
| # | Issue | 分類 | Label | 留言 |
|---|-------|------|-------|------|
| 1 | #123 修復登入問題 | Bug | bug | 已要求補充重現步驟 |
| 2 | #124 希望支援 dark mode | Feature | feature-request | — |
```

## 10.1 Triage 後路由（Post-Triage Routing）

分類完成後，依類型進入不同路徑：

```
Triage 分類結果
  │
  ├─ question        → 直接回覆（第 9 節 Comment）→ close → 結束
  ├─ documentation   → 小修（< 5 行）：直接修改 + close
  │                    大改：走 Backlog Bridge（第 11 節）
  ├─ bug             → 回覆「已收到」→ Backlog Bridge（第 11 節）
  ├─ feature-request → 回覆「已列入評估」→ Backlog Bridge（第 11 節）
  └─ invalid         → 回覆說明原因 → close（reason: "not planned"）→ 結束
```

**快速通道（不進 Backlog）**：

| 類型 | 處理方式 | 需要開發？ | 進 Backlog？ |
|------|---------|-----------|-------------|
| question | 直接在 issue comment 回答，回完 close | 否 | 否 |
| documentation（小修） | 直接修改文件，issue 留言說明已修正，close | 否 | 否 |
| invalid | 留言說明原因，close（not planned） | 否 | 否 |

**開發通道（進 Backlog）**：

| 類型 | 處理方式 | 進 Backlog？ | Sprint 排序？ |
|------|---------|-------------|--------------|
| bug | Triage 時回覆「已收到，團隊將評估」→ Backlog Bridge | 是 | PO 排優先級 |
| feature-request | Triage 時回覆「已列入評估」→ Backlog Bridge | 是 | PO 排優先級 |
| documentation（大改） | 走 Backlog Bridge，由 PO 決定 Sprint 排序 | 是 | PO 排優先級 |

**原則**：Sprint 進行中不插入新需求。所有進 Backlog 的 issue 由 PO 在下次 Sprint Planning 時排序決定是否納入。P0 緊急修復除外（由 Stakeholder 決策中斷當前 Sprint）。

## 10.2 Discovery 觸發路徑（feature-request 閾值自動建議）

`feature-request` label 的 Issue 在通過 Backlog Bridge 入庫後，系統將持續追蹤其互動熱度。當同一個 `feature-request` Issue 達到以下任一閾值時，系統**自動建議**啟動 `/discovery-phase`：

| 觸發條件 | 閾值 | 說明 |
|---------|------|------|
| Thumbs-up reactions（👍） | **≥ 3** | 代表多名使用者主動表達需求強度 |
| Comments 數量 | **≥ 5** | 代表使用者持續討論，需求有深度探索空間 |

**自動建議流程**：

```
feature-request Issue 達閾值
  │
  ├─ 在 Backlog Grooming（/backlog-management §3）匯總時偵測
  ├─ PO subagent 輸出建議：「Issue #N 已達 Discovery 觸發閾值，建議啟動 /discovery-phase」
  ├─ 附加 label：`discovery-candidate`（標示已達閾值，待 PO 決策）
  └─ PO 決策：啟動 /discovery-phase（Issue 觸發入口，見 discovery-phase §2 Step 1）
               或 維持 Backlog 等待下次 Sprint Planning 排序
```

**閾值偵測指令**（於 Grooming 或手動檢查時執行）：

```bash
# 取得所有 feature-request Issues 並篩選達閾值者
gh issue list --label "feature-request" --state open \
  --json number,title,url,reactionGroups,comments --limit 200 \
  | jq '[.[] | select(
      (.reactionGroups[] | select(.content == "THUMBS_UP") | .reactors.totalCount) >= 3
      or .comments >= 5
    )]'
```

**注意**：Discovery 觸發僅為「建議」，最終決策由 PO 執行。PO 可選擇啟動 `/discovery-phase` 或維持 Backlog 等待排序。
