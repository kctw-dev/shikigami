# 流程觸發規則

<!-- 本檔案由 scrum-master/SKILL.md §5 拆出，主文件以指針引用 -->

## 5.1 意圖驅動（使用者說了什麼）

根據使用者意圖，按以下決策樹觸發對應 Skill：

```
使用者意圖分析：
├── 新功能/需求 → invoke shikigami:backlog-management
├── 開始 Sprint → invoke shikigami:sprint-planning
├── 實作 Story → invoke shikigami:sprint-execution
├── 技術決策/架構 → invoke shikigami:architecture-decision
├── 代碼審查/PR → invoke shikigami:quality-gate
├── 安全相關 → invoke shikigami:security-review
├── 部署/發布 → invoke shikigami:deployment-readiness
├── 衝突/僵局 → invoke shikigami:escalation
├── Sprint 結束 → invoke shikigami:sprint-review
├── 解咒/考古/legacy 分析/不熟悉的 codebase → invoke shikigami:dispel
├── Bug/錯誤/測試失敗 → invoke shikigami:systematic-debugging
├── 分支隔離/worktree → invoke shikigami:git-workflow
├── 開發完成/合併/PR → invoke shikigami:git-workflow
├── 多個獨立任務 → invoke shikigami:parallel-dispatch
├── Issue 管理/分類/回覆 → invoke shikigami:issue-management
├── Issue 轉 User Story → invoke shikigami:issue-management
├── 框架狀態/健康檢查/自我診斷 → invoke shikigami:health-check
├── 初始化專案/第一次使用/scaffold/onboarding → invoke shikigami:onboarding
└── 日常開發 → 主 Agent 直接執行（不需觸發角色）
```

**路由邊界：dispel vs systematic-debugging**
- `dispel`：Legacy 或不活躍 codebase 的全面考古分析，使用者意圖是「理解這個系統」
- `systematic-debugging`：活躍開發中的特定 bug、測試失敗、非預期行為，使用者意圖是「修復這個問題」
- 兩者互斥，不得同時觸發

## 5.2 狀態驅動（自動觸發）

以下 Skill 不需要使用者明確要求，當條件滿足時 **Scrum Master 主動觸發**：

| 條件 | 自動觸發 |
|------|----------|
| 新 session 開始（使用者首次互動） | 執行 `/standup` slash command（Daily Standup — 健康快篩 + Git 同步 + Sprint 進度）+ 排程 PR 偵測（見 §5.3） |
| Sprint 中所有 Story 標記完成 | `invoke shikigami:sprint-review` |
| sprint-review 驗收通過 | `invoke shikigami:deployment-readiness`（版本 Tag + 部署就緒） |
| sprint-review 完成且 Backlog 有待選 Story | `invoke shikigami:sprint-planning`（下一個 Sprint） |
| Story 實作完成 | `invoke shikigami:quality-gate` |
| quality-gate 發現安全問題 | `invoke shikigami:security-review` |
| 升級鏈走完仍無解 | `invoke shikigami:escalation` |
| 偵測到 `SHIKIGAMI_SCHEDULED=1` 環境變數且 Skill 為 `sprint-execution` | worktree 隔離執行模式（見 schedule SKILL.md §5.7），不觸發互動式提醒 |
| 偵測到 `scheduled/*` 分支且無對應 open PR | 自動建立 PR + quality-gate 檢查（見 schedule SKILL.md §5.8） |
| **Sprint Review 流程開始前**（進入 §1.5 交付物一致性審查前） | `invoke shikigami:systematic-debugging`（**HARD-GATE**，確認系統健康後才繼續 Review；見 `sprint-review/SKILL.md` §7） |
| **deployment-readiness 完成後**（服務部署至生產環境後） | `invoke shikigami:systematic-debugging`（建議，post-deploy health check；見 `sprint-execution/SKILL.md` §7.1） |
| **Bug 修復完成後**（通過 Spec Compliance + Code Quality Review 後） | `invoke shikigami:systematic-debugging`（建議，確認無回歸；見 `sprint-execution/SKILL.md` §7.2） |
| **CI FAIL 時**（CI 狀態快掃或 CI Gate 回傳 FAIL） | `invoke shikigami:systematic-debugging`（建議，CI FAIL 根因排查；見 `sprint-execution/SKILL.md` §7.0） |

**原則**：Scrum Master 不只是被動路由器，也是**主動的流程守門員**。當偵測到流程轉折點時，自動推進到下一個環節，不等使用者提醒。

## 5.3 互動 Session 啟動：排程 PR 偵測

**觸發時機**：每次互動 Session 啟動（使用者首次互動），在 standup 完成後立即執行。

**偵測指令**：

```bash
gh pr list --label "scheduled" --state open --json number,title,createdAt
```

**執行邏輯**：

```
Session 啟動
  |
  v
執行 standup（健康快篩 + Git 同步 + Sprint 進度）
  |
  v
偵測待審排程 PR（gh pr list --label "scheduled" --state open）
  |-- 無待審 PR（空結果）→ 靜默通過，不顯示任何提醒
  +-- 偵測到待審 PR
        |
        v
      顯示標準提醒區塊（見下方格式）
      等待使用者選擇操作選項
```

**無待審 PR 時**：靜默通過，不輸出任何訊息，不干擾正常流程。

**偵測到待審 PR 時**，顯示以下標準提醒區塊：

```
[SCHEDULED-PR] 偵測到 N 個待審排程 PR

| # | PR 編號 | 標題 | 建立時間 |
|---|---------|------|----------|
| 1 | #XX     | ...  | YYYY-MM-DD HH:MM |
| 2 | #YY     | ...  | YYYY-MM-DD HH:MM |

選項：
1. 立即審核（逐一檢視並 merge/reject）
2. 本次略過（下次 session 再提醒）
3. 批次確認全部（全部 approve + merge）
```

**各選項行為說明**：

| 選項 | 行為 |
|------|------|
| 1. 立即審核 | 逐一開啟各 PR，執行 `quality-gate` 檢視，由使用者決定 merge 或 reject |
| 2. 本次略過 | 關閉提醒，繼續 session；下次 session 啟動時仍會偵測並再次提醒 |
| 3. 批次確認全部 | 對所有列出的 PR 執行 `gh pr merge --merge`，完成後輸出批次結果摘要 |

**規格來源**：US-54 AC1、AC2（Sprint 30）
