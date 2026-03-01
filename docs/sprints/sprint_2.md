# Sprint 2

> 週期：2026-02-28 ~ 2026-03-07
> 狀態：已完成
> 專案等級：low（完全自治）

---

## Sprint Goal

**「讓框架能感知自己的狀態」**

框架目前缺乏自我感知能力，許多問題需要人工提醒才被發現（如本地落後遠端 19 個 commit）。本 Sprint 建立兩個感知機制：Health Check（全面診斷）和 Standup 遠端差距感知（日常快篩），同時關閉 Sprint 1 遺留的 Retro Action Items。

對應 ROADMAP：v0.2.0「自我感知」主題。

---

## Sprint Backlog

| Story | 任務 | 負責 | 狀態 |
|---|---|---|---|
| US-07：Health Check Skill | 新建 `skills/health-check/SKILL.md`，實作 4 項結構化診斷 | Developer + QA | 待開發 |
| US-07：Health Check 路由 | 更新 `skills/scrum-master/SKILL.md` 決策樹，新增 health-check 路由 | Developer | 待開發 |
| US-S01：Standup 遠端差距感知 | 修改 `commands/standup.md`，新增 Git 同步狀態區塊 | Developer | 待開發 |
| Retro #2：不阻塞原則強化 | `skills/scrum-master/SKILL.md` 新增獨立章節 | Scrum Master | 待開發 |
| Retro #3：Plan Mode 互斥說明 | `docs/km/PLUGIN_DEV_NOTES.md` 新增章節 | Developer | 待開發 |

---

## 工作容量

- US-07：~0.7 Sprint（M，新建 Skill + 4 項檢查邏輯 + 報告格式）
- US-S01：~0.3 Sprint（S，修改現有 command，git 指令組合）
- Retro #2：~0.3 Sprint（S，文件結構改善）
- Retro #3：~0.3 Sprint（S，文件新增章節）
- 合計：1.6 Sprint（保留 0.2-0.4 緩衝，應對 US-07 不確定性）

> **T-shirt Sizing 參考**：
> - S（< 0.3 Sprint）：單一模組小改動，路徑清晰
> - M（0.3-0.7 Sprint）：跨模組，需設計但風險可控
> - L（> 0.7 Sprint）：跨層、新架構、高不確定性

---

## 風險

| 風險 | 可能性 | 影響 | 應對 |
|---|---|---|---|
| US-07 是首個「主動診斷」類 Skill，無先例可循 | 中 | 中 | 保留容量緩衝；若超載可從 Backlog 移除低優先項 |
| PRODUCT_BACKLOG.md 格式不含 Sprint 編號，AC3 孤兒偵測需調整 | 低 | 低 | 孤兒偵測改為掃描 sprint_N.md 反向驗證 |
| Retro #2 的行為驗收（AskUserQuestion 次數）無法精確量化 | 中 | 低 | 改為文件結構驗收 + Sprint Review 觀察性評估 |

---

## Story 詳情

### US-07：Health Check Skill

**User Story**
As a Scrum Master, I want to check the framework's health status with a single command, so that I can immediately identify broken configurations, orphan artifacts, and overdue action items without manually inspecting each file.

**Acceptance Criteria**（已納入 QA 回饋修正）

| # | 條件 | 通過標準 |
|---|------|----------|
| AC1 | 觸發與路由 | `skills/health-check/SKILL.md` 存在且含有效 frontmatter；`skills/scrum-master/SKILL.md` 決策樹包含「框架狀態 / 健康檢查」→ health-check 的路由條目 |
| AC2 | 必要文件檢查 | 檢查 `./CLAUDE.md`（專案根目錄）、`docs/PROJECT_BOARD.md`、`docs/prd/PRODUCT_BACKLOG.md` 是否存在；任一缺失標記 FAIL；文件存在但為空（0 bytes）亦視同 FAIL |
| AC3 | 孤兒 Story 偵測 | 掃描 `docs/sprints/sprint_N.md` 中列出的 Story，反向驗證該 Story 存在於 `PRODUCT_BACKLOG.md` 或 `BACKLOG_DONE.md`；不存在者列為孤兒並標記 WARN |
| AC4 | ADR 一致性檢查 | 掃描 PRODUCT_BACKLOG.md 中 ADR 欄位非「—」且非空的 Story；驗證對應 `docs/adr/ADR-XXX.md` 存在且含「**狀態**：Accepted」；不一致者標記 FAIL。多個 ADR 引用（逗號分隔）逐一檢查 |
| AC5 | Retro Action Items 逾期偵測 | 讀取 `docs/km/Retrospective_Log.md`，找出狀態為 Open 的 Action Items；以 Sprint 區塊標題日期（`## Sprint N — YYYY-MM-DD`）作為基準，距今超過 14 天標記 OVERDUE |
| AC6 | 報告格式 | 報告包含 Overall Status + 4 項檢查結果。判定規則：任一 FAIL → CRITICAL；有 WARN/OVERDUE 但無 FAIL → WARNING；全 PASS → HEALTHY。每個 FAIL/WARN 附可執行修復建議 |
| AC7 | 完整呈現 | 4 項檢查（必要文件 / 孤兒 Story / ADR 一致性 / Retro 逾期）全部出現在報告中，即使全部通過亦顯示 PASS |

### US-S01：Standup 遠端差距感知

**User Story**
As a Developer, I want the daily standup to show the git sync status between local and remote, so that I can immediately know if I need to pull or push before starting work and avoid building on a stale codebase.

**修改目標**：`commands/standup.md`

**Acceptance Criteria**（已納入 QA 回饋修正）

| # | 條件 | 通過標準 |
|---|------|----------|
| AC1 | 未推送 commits | standup 報告新增「Git 同步狀態」區塊；執行 `git rev-list --count @{u}..HEAD` 顯示本地未推送 commits 數量；若有 remote 但當前 branch 無 tracking branch，顯示「本地分支尚未設定遠端追蹤」 |
| AC2 | 未拉取 commits | 先執行 `git fetch --quiet`（超時 5 秒），再執行 `git rev-list --count HEAD..@{u}` 顯示遠端未拉取 commits 數量；N > 0 時附警告「建議執行 git pull」 |
| AC3 | 無遠端時靜默略過 | `git remote` 輸出為空時，Git 同步狀態區塊顯示「無遠端設定，略過同步檢查」；不報錯，不影響其餘欄位 |
| AC4 | 網路失敗時降級 | git fetch 超時或失敗時，顯示「無法連線遠端，同步狀態未知」；standup 其餘欄位照常呈現 |

### Retro #2：不阻塞原則強化

**任務**：在 `skills/scrum-master/SKILL.md` 新增「不阻塞原則」獨立章節

**Done 定義**（QA 修正後）：
- 文件層（客觀可驗證）：新增獨立章節，含決策樹或判斷清單（至少 3 個判斷節點），明確列出哪些情境可自行決策、哪些必須暫停
- 行為層（Sprint Review 觀察性驗證）：Sprint Review 時由 Scrum Master 評估本 Sprint 中是否有不必要的中斷

### Retro #3：Plan Mode 互斥說明

**任務**：在 `docs/km/PLUGIN_DEV_NOTES.md` 新增「Plan Mode 與 Shikigami 的互斥關係」章節

**Done 定義**：
- 含問題描述（Plan Mode 啟用時 Skill 調度被封印）
- 含原因說明（Claude Code 的 Plan Mode 機制限制）
- 含避免方式（如何避免進入 Plan Mode）

---

## Retro Action Items（從 Sprint 1 帶入）

| # | Action | Owner | 驗收方式 | 來源 |
|---|--------|-------|----------|------|
| 2 | 不阻塞原則強化 | Scrum Master | 文件結構驗收 + 觀察性評估 | Sprint 1 Retro |
| 3 | Plan Mode 互斥說明 | Developer | PLUGIN_DEV_NOTES.md 有對應章節 | Sprint 1 Retro |

---

## 驗收標準

- [ ] US-07：Health Check Skill 全部 AC 通過
- [ ] US-S01：Standup 遠端差距感知全部 AC 通過
- [ ] Retro #2：scrum-master SKILL.md 有獨立「不阻塞原則」章節
- [ ] Retro #3：PLUGIN_DEV_NOTES.md 有「Plan Mode 互斥」章節
- [ ] 既有功能不受影響（反回歸）

---

## Sprint Review 記錄

### Demo 結果
- US-07 Health Check：**通過**（7/7 AC PASS）
- US-S01 Standup 感知：**通過**（4/4 AC PASS）
- Retro #2：**通過**（Done 定義 4/4 PASS）
- Retro #3：**通過**（Done 定義 3/3 PASS）

### Stakeholder 驗收：接受
回饋：Health Check 目前是被動查詢，建議掛鉤到 standup 或 Sprint 開始時自動觸發。

### 未完成項目
（無 — 全部完成）

---

## Sprint Retrospective

> 完整記錄見 `docs/km/Retrospective_Log.md`

### Good（繼續做）
- Stakeholder 方向調整即時生效
- QA 審查品質高（14 個 AC 缺口在 Planning 階段修補）
- Sprint 1 Retro Action Items 全部關閉

### Problem（需改善）
- Standup 未偵測遠端差距（已被 US-S01 解決）
- ROADMAP vs Backlog 不同步
- Health Check 只有被動查詢
- Sprint Review 仍未自動觸發（Sprint 1 Action #1 重犯，規則存在但行為未遵循）

### Action（下個 Sprint 執行）
- [ ] PO 補寫 US-06、US-08 進 Backlog
- [ ] Health Check 自動掛鉤到 standup 或 Sprint 開始
- [ ] Sprint Review 自動觸發重修（Sprint 1 Action #1 Reopened）
