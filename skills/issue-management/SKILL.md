---
name: issue-management
description: "Use when managing GitHub Issues — listing, creating, closing, labeling, triaging, commenting, or syncing issues to backlog"
---

# Issue Management — GitHub Issue 管理

## 1. 概述

透過 `gh` CLI 管理 GitHub Issues 的完整生命週期。支援列出、建立、關閉、標記、指派、回覆與分類。

所有操作遵循**專案等級自治策略**（見 scrum-master 第 6 節）：
- 低風險操作（查詢、label、assign）→ 自動執行
- 高風險操作（公開留言、關閉、建立）→ 依專案等級決定確認方式

**主要執行者**：Product Owner subagent（需求分類）、QA subagent（高風險審核）

---

## 2. 前置檢查

每次執行前，必須先確認 `gh` CLI 認證狀態：

```bash
gh auth status
```

若認證失效，中止流程並提示：「請執行 `gh auth login` 完成認證後重試。」

確認目標 Repo：

```bash
gh repo view --json nameWithOwner -q '.nameWithOwner'
```

所有操作預設針對當前 Git Repo。操作非當前 Repo 時，必須顯示目標 Repo 全名並依專案等級決定確認方式。

---

## 3. 操作選單

根據使用者意圖，進入對應子流程：

```
使用者意圖分析：
├── 列出/查詢 Issues → 第 4 節 List
├── 建立新 Issue → 第 5 節 Create
├── 關閉 Issue → 第 6 節 Close
├── 標記/移除 Label → 第 7 節 Label
├── 指派/取消指派 → 第 8 節 Assign
├── 回覆 Issue 留言 → 第 9 節 Comment
├── 分類無標籤 Issues → 第 10 節 Triage
├── Issue 轉 Backlog User Story → 第 11 節 Backlog Bridge
├── 前端 Story 識別與 AC 注入規則 → 第 12 節（由 Backlog Bridge 自動觸發）
└── Issue → Discovery Phase 閉環路由圖 → 第 14 節
```

---

## 4. List — 列出 Issues

**風險等級**：低（自動執行）

```bash
# 預設：列出所有 open issues
gh issue list --state open --json number,title,labels,assignees,createdAt

# 篩選（AND 邏輯，同時滿足所有條件）
gh issue list --state <open|closed|all> --label <name> --assignee <user> --limit <N>
```

未指定篩選條件時，預設返回所有 open issues。

輸出格式：以表格呈現 issue 編號、標題、labels、assignee、建立日期。

---

## 5. Create — 建立 Issue

**風險等級**：高（影響外部可見狀態）

```bash
gh issue create --title "<title>" --body "<body>" --label "<label>" --assignee "<user>"
```

**流程**：
1. 根據使用者描述生成 issue 標題與內容草稿
2. 依專案等級決定確認方式：
   - `low`：自動建立，事後通知
   - `medium`：QA subagent 審核草稿品質後自動建立
   - `high`：顯示草稿，人工確認後建立
3. 執行 `gh issue create`
4. 回報建立結果（issue URL）

---

## 6. Close — 關閉 Issue

**風險等級**：高（改變 Issue 公開狀態）

```bash
# 附理由留言後關閉
gh issue comment <number> --body "<reason>"
gh issue close <number> --reason <completed|"not planned">
```

**流程**：
1. 先讀取 issue 內容（`gh issue view <number>`）
2. 生成關閉理由
3. 依專案等級決定確認方式：
   - `low`：自動關閉，事後通知
   - `medium`：QA subagent 審核關閉理由後自動關閉
   - `high`：顯示關閉理由，人工確認後關閉
4. 留言說明關閉原因，然後關閉 issue

---

## 7. Label — 標記管理

**風險等級**：低（自動執行）

```bash
# 新增 label
gh issue edit <number> --add-label "<label1>,<label2>"

# 移除 label
gh issue edit <number> --remove-label "<label>"
```

**預檢**：執行前先確認 label 存在：

```bash
gh label list --json name -q '.[].name'
```

若目標 label 不存在，提示使用者是否建立新 label（`gh label create "<name>" --color "<hex>"`）。

---

## 8. Assign — 指派管理

**風險等級**：低（自動執行）

```bash
# 指派
gh issue edit <number> --add-assignee "<user>"

# 取消指派
gh issue edit <number> --remove-assignee "<user>"
```

---

## 9. Comment — 回覆留言

**風險等級**：高（公開發布 AI 生成內容）

```bash
gh issue comment <number> --body "<comment>"
```

**流程**：
1. 讀取 issue 內容與既有留言（`gh issue view <number> --comments`）
2. 根據場景生成回覆草稿：

| 場景 | 回覆模板方向 |
|------|-------------|
| 確認收到 | 感謝回報，已收到，團隊將評估處理 |
| 要求補充資訊 | 需要更多資訊以便排查（重現步驟、環境資訊等） |
| 說明已修復 | 已在 PR #N 修復，將於下次版本釋出 |
| Won't Fix | 說明原因，感謝回報 |

3. 依專案等級決定確認方式：
   - `low`：自動發布，事後通知
   - `medium`：QA subagent 審核留言品質與語氣後自動發布
   - `high`：顯示完整草稿，人工確認後發布
4. 執行 `gh issue comment`

---

## 10. Triage — 批次分類

**完整細節**：見 [`references/triage-routing.md`](references/triage-routing.md)

**摘要**：
- 列出無 label 的 open issues → 判定類型 → 套用 label → 視情況留言補充請求
- 分類後依類型路由：`question`/`invalid`/`documentation 小修` 快速通道，`bug`/`feature-request`/`documentation 大改` 進 Backlog Bridge
- `feature-request` 達閾值（≥3 thumbs-up 或 ≥5 comments）自動建議啟動 `/discovery-phase`

---

## 11. Backlog Bridge — Issue 入庫

**完整細節**：見 [`references/backlog-bridge.md`](references/backlog-bridge.md)（含 §12 前端 Story AC 注入）

**摘要**：
- ADR-010 單層 Issue 架構，直接改寫 Issue body
- Step 1 Injection 防護 → Step 2 前端識別 + AI 填補 Story template（以 `.github/ISSUE_TEMPLATE/` 對應模板為基礎，必含 `## 非功能性需求` 欄位）→ Step 3 RICE 驗證 → Step 4 改寫 body → Step 5-6 套用 labels + 冪等標記 → Step 7 PO Review Gate

---

## 12. 前端 Story 識別規則與 AC 注入

**完整細節**：見 [`references/backlog-bridge.md §12`](references/backlog-bridge.md)

**摘要**：Issue title/body 含 `UI`、`frontend`、`component`、`dashboard`、`前端`、`介面`、`畫面` 時，Backlog Bridge 自動在 AC 表格附加 AC-FE-1（元件庫符合性）與 AC-FE-2（Design Tokens 符合性）。

---

## 13. Hard Gates

<HARD-GATE>
操作預設僅針對當前 Git Repo。操作非當前 Repo 時，無論專案等級，必須顯示目標 Repo 全名（OWNER/REPO）並取得確認。
</HARD-GATE>

<HARD-GATE>
gh CLI 認證失效時，不得嘗試任何寫入操作。必須中止流程並提示使用者重新認證。
</HARD-GATE>

---

## 14. 閉環路徑：Issue → Discovery Phase 完整路由圖

**完整細節**：見 [`references/discovery-routing.md`](references/discovery-routing.md)

**摘要**：使用者回饋 → Triage → Backlog Bridge → Grooming → Discovery Phase → Sprint Planning → Sprint Execution → Issue Close。閉環驗證需：入庫完成、Product Brief 簽核、RICE 評分排入 Backlog、Story 完成後原始 Issue 附留言關閉。

---

## 15. 與其他 Skill 的關係

| 情境 | 觸發 |
|------|------|
| Issue 入庫（Backlog Bridge §11） | 直接完成 RICE 評分與 Issue body 改寫，不委派其他 Skill |
| Triage 發現安全漏洞相關 issue | 升級至 `security-review` |
| Issue 對應的 Story 完成後 | `sprint-execution` 結束時建議關閉對應 issue |
| `security-review` 需建立追蹤 Issue | 呼叫 `issue-management` Create 子流程 |
| Issue 需要技術評估 | 升級至 `architecture-decision` |
| `sprint-review` Retrospective Action Items | 呼叫 `issue-management` Create 子流程（`retro-action` label） |
| Sprint Review 檢查上期 Action Items | 呼叫 `issue-management` List 子流程（`--label retro-action`） |

---

## 16. Subagent 派遣

| 子流程 | 主要 Agent | 審核 Agent |
|--------|-----------|-----------|
| List | 主 Agent 直接執行 | — |
| Create | PO subagent | QA subagent（medium/high 等級） |
| Close | 主 Agent 直接執行 | QA subagent（medium/high 等級） |
| Label / Assign | 主 Agent 直接執行 | — |
| Comment | PO subagent（生成草稿） | QA subagent（medium/high 等級） |
| Triage | PO subagent（分類判定） | QA subagent（審核留言） |
| Backlog Bridge | PO subagent（格式轉換） | QA subagent（審核留言） |
