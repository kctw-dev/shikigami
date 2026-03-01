# Retrospective Log

---

## Sprint 1 — 2026-02-28

**Sprint Goal**：建立 Issue Management Skill 基礎 + 專案等級自治框架
**結果**：Goal 達成。全部 6 個 Story + 1 個 ADR 完成交付。

### 交付成果

| Story | Size | 狀態 | 驗收 |
|-------|------|------|------|
| Story 5：專案等級自治策略 | S | Done | AC 全通過 — low/medium/high 三等級已定義 |
| Story 1：Issue Lifecycle Management | M | Done | AC 全通過 — 7 個子流程已實作 |
| ADR-001：Backlog Bridge 編排模式 | S | Done | Accepted — 採用委派模式 |
| Story 2：Backlog Bridge 完整版 | M | Done | AC 全通過 — 委派 backlog-management 評分 |
| Story 3：Issue Comment 強化 | S | Done | AC 全通過 — 場景模板已定義 |
| Story 4：Issue Triage 強化 | S | Done | AC 全通過 — triage-prompt.md 已建立 |

**Velocity**：6 Stories（2S + 2M + 1S + 1S = 約 8 story points）

### Good（保持做的事）

- **Product Discovery 流程完整**：PO 分析 → Architect 評估 → QA 確認 AC，角色制衡有效運作
- **ADR 機制正常運作**：Story 2 被 Hard Gate 阻擋 → 先完成 ADR-001 → 解鎖，流程正確
- **使用者回饋即時納入**：「專案等級自治」和「不阻塞原則」都是使用者在過程中提出，立即轉為 Story 交付

### Problem（需改進的事）

- **Sprint Review 未自動觸發**：Sprint 所有 Story 完成後，scrum-master 沒有自動觸發 sprint-review，需要使用者提醒才補上
- **Plan Mode 與 Shikigami 衝突**：Session 開始時進了 Plan Mode，封印了式神調度，浪費了探索時間
- **AskUserQuestion 過多**：流程中多次用 AskUserQuestion 停下來問使用者，違反自治原則，被使用者拒絕多次

### Action Items

| # | Action | Owner | 驗收方式 | 狀態 |
|---|--------|-------|----------|------|
| 1 | scrum-master 決策樹加入「Sprint 完成自動觸發 sprint-review」邏輯 | Scrum Master | 下次 Sprint 完成後自動跑 Review | Closed（Sprint 3） |
| 2 | scrum-master 加入「不阻塞原則」強化指引，減少 AskUserQuestion 使用 | Scrum Master | 下次 Sprint 中 AskUserQuestion 次數 ≤ 1 | Closed（Sprint 2） |
| 3 | 文件中明確說明 Plan Mode 與 Shikigami 的互斥關係 | Developer | PLUGIN_DEV_NOTES.md 新增說明 | Closed（Sprint 2） |

---

## Sprint 2 — 2026-02-28

**Sprint Goal**：讓框架能感知自己的狀態
**結果**：Goal 達成。全部 2 個 Story + 2 個 Retro Action Items 完成交付。

### 交付成果

| Story | Size | 狀態 | 驗收 |
|-------|------|------|------|
| US-07：Health Check Skill | M | Done | AC 全通過（7/7）— 4 項結構化診斷 + 報告格式 |
| US-S01：Standup 遠端差距感知 | S | Done | AC 全通過（4/4）— Git 同步狀態 + 降級處理 |
| Retro #2：不阻塞原則強化 | S | Done | Done 定義全通過 — 4 節點決策樹 |
| Retro #3：Plan Mode 互斥說明 | S | Done | Done 定義全通過 — 問題/原因/避免 |

**Velocity**：4 Items（1M + 3S = 約 7 story points）

### Good（保持做的事）

- **Stakeholder 方向調整即時生效**：Sprint Planning 中途收到「感知優先」指示，PO 立即重選 Stories，沒有浪費已完成的分析
- **QA 審查品質高**：發現 14 個 AC 缺口（US-07 有 5 項需修正），全部在進 Sprint 前修補，避免了實作階段的返工
- **Sprint 1 Retro Action Items #2 #3 關閉**：不阻塞原則強化 + Plan Mode 互斥說明皆在本 Sprint 交付
- **角色制衡有效**：PO 選取 → Architect 確認 Size + ADR → QA 審 AC → PO 修補，四角色接力無阻塞

### Problem（需改進的事）

- **Standup 未偵測遠端差距**：Session 開始時 standup 沒發現本地落後遠端 19 個 commit，導致重做 Product Discovery，浪費約 15 分鐘（此問題已被 US-S01 解決）
- **ROADMAP vs Backlog 不同步**：ROADMAP v0.2.0 規劃了 US-06/07/08，但 Backlog 只有測試框架 Stories，PO 需要即時補寫 Story，增加了 Planning 複雜度
- **Health Check 只有被動查詢**：Stakeholder 回饋指出，使用者忘記執行 /health-check 時框架仍是盲區。需要掛鉤到 standup 或 Sprint 開始時自動觸發
- **Sprint Review 仍未自動觸發（重犯）**：Sprint Execution 完成所有 Story 後，Scrum Master 問了「要現在執行嗎？」而非直接觸發 sprint-review。這與 Sprint 1 Retro Action #1 是同一個問題 — 文件規則已寫入（5.2 狀態驅動）但行為未遵循。Sprint 2 新增的「不阻塞原則」6.1 章節也明確列為「絕對不問」的情境，但仍然問了。結論：Sprint 1 Action #1 的 Closed 判定有誤，問題未真正解決

### Action Items

| # | Action | Owner | 驗收方式 | 狀態 |
|---|--------|-------|----------|------|
| 1 | PO 補寫 ROADMAP v0.2.0 剩餘 Stories（US-06 Onboarding、US-08 Sprint Metrics）進 Backlog | PO | PRODUCT_BACKLOG.md 有對應完整 Story | Closed（Sprint 3 Planning） |
| 2 | Health Check 自動掛鉤：standup 或 Sprint 開始時自動執行輕量健康掃描 | Developer | standup.md 或 sprint-planning SKILL 含 health-check 呼叫 | Closed（Sprint 3） |
| 3 | Sprint Review 自動觸發重修：Sprint 1 Action #1 誤判 Closed，需重新開啟。規則存在但行為未遵循，需找出根因（是 prompt 不夠強？還是需要機制性保障？） | Scrum Master | 下次 Sprint 完成後 sprint-review 零詢問自動觸發 | Closed（Sprint 3） |

---

## Sprint 3 — 2026-03-01

**Sprint Goal**：完成 v0.2.0 自我感知，並修復跨兩個 Sprint 的行為性缺陷
**結果**：Goal 達成。全部 4 個 Story / Retro Action Items 完成交付。

### 交付成果

| Story | Size | 狀態 | 驗收 |
|-------|------|------|------|
| Story 1（Retro #3）：Sprint Review 自動觸發重修 | S | Done | AC 全通過 — sprint-execution 末端邏輯結構性修復，Sprint 3 零詢問自動觸發驗證通過 |
| US-06：Onboarding（專案初始化） | M | Done | AC 全通過（7/7）— 目錄建立 + 文件複製 + CLAUDE.md 生成 + 冪等性 + 錯誤處理 |
| Story 3（Retro #2）：Health Check 自動掛鉤 | S | Done | AC 全通過 — standup 輕量掃描（2 項）+ sprint-planning 完整掃描（4 項） |
| US-T04：版號一致性驗證 | S | Done | AC 全通過（3/3）— TDD Red-Green-Refactor，11 個測試案例全覆蓋 |

**Velocity**：5 points（1S + 1M + 1S + 1S；Retro Action Items 計入 S）

### Good（保持做的事）

- **Sprint Review 零詢問自動觸發**：Story 1 的結構性修復（把觸發邏輯移入 sprint-execution 流程末端）有效。Sprint 1/2 連續重犯的問題在 Sprint 3 正式修復
- **QA Planning 品質穩定**：Sprint 2 修了 14 個 AC 缺口，Sprint 3 修了 13 個，品質控制持續有效
- **Retro Action Items 全部關閉**：Sprint 2 的 3 個 Open Action Items 在 Sprint 3 全部處理完畢（#1 在 Planning 關閉，#2 和 #3 作為 Story 交付）
- **TDD 流程執行**：US-T04 嚴格遵循 Red-Green-Refactor，11 個測試案例全覆蓋

### Problem（需改進的事）

- **US-08 Sprint Metrics 推遲**：v0.2.0 的 ROADMAP 包含 US-08，但因容量與優先級決策推遲至 Sprint 4。v0.2.0 嚴格來說少了一個 Should Story
- **AC 品質系統性問題**：QA 連續兩個 Sprint 發現約 14 個 AC 缺陷。根因是 AC 混合文件結構條件（靜態）和 AI 行為條件（動態），兩種驗收方式不同但未在 AC 中區分
- **sprint-planning 第 6 節未同步更新**：Story 3 在 sprint-planning Checklist（第 2 節）加了健康檢查步驟，但第 6 節 Subagent 派遣說明未同步更新。QA 觀察到但未阻塞

### Action Items

| # | Action | Owner | 驗收方式 | 狀態 |
|---|--------|-------|----------|------|
| 1 | AC 分類標注：Backlog Grooming/Sprint Planning 時每個 AC 標注驗收類型：[靜態]（文件結構可直接驗證）或 [動態]（需執行 AI 流程觀測），降低 QA 審查量 | QA | 下次 Sprint Planning AC 表格含 [靜態]/[動態] 標注 | Closed（Sprint 4 Planning） |
| 2 | sprint-planning 第 6 節同步：補入步驟 0（健康檢查）使 Checklist 與派遣說明一致 | Developer | sprint-planning SKILL.md 第 6 節含步驟 0 健康檢查 | Closed（Sprint 4 Planning） |

---

## Sprint 4 — 2026-03-01

**Sprint Goal**：啟動 v0.3.0 知識沉澱，以 US-08 Sprint Metrics 完成 v0.2.0 收尾，並建立 Retrospective Analytics 的第一層能力
**結果**：Goal 達成。全部 3 個 Stories 完成交付。

### 交付成果

| Story | Size | 狀態 | 驗收 |
|-------|------|------|------|
| US-08：Sprint Metrics（Velocity 追蹤與趨勢分析） | S | Done | AC 全通過（7/7）— sprint-review 第 6 節 Metrics 計算指引 + Metrics_Log.md 歷史回溯 |
| US-09：Retrospective Analytics（問題趨勢分析） | M | Done | AC 全通過（9/9）— sprint-review 第 3 節 Analytics 步驟 0 + 四區塊報告格式 |
| US-T06：Command 路由驗證 | S | Done | AC 全通過（4/4）— TDD 16/16 assertions，scripts/validate-commands.sh |

**Velocity**：4 points（2S + 1M = 1+1+2）

### Good（保持做的事）

- **Sprint Goal 100% 達成，完成率維持 100%**：Architect 對 US-08 點數重新估算（M→S）顯示估點機制持續校正
- **Sprint Review 自動觸發連續第 2 個 Sprint 正常運作**：框架自動化行為穩定，不再依賴使用者觸發
- **Retro Action Items 追蹤機制有效**：Sprint 3 的 2 個 Action Items 在 Sprint 4 Planning 即關閉；Analytics 確認歷史 8 個 Items 全部已關閉
- **QA 在 Planning 發揮前置攔截價值**：發現 2 個 BLOCK（US-08 AC1 模糊、US-09 AC1 引用錯誤），PO 當場修正，阻止缺陷進入 Execution

### Problem（需改進的事）

- **Velocity 絕對值持續下降（8→5→5→4）**：雖在穩定閾值內（±20%），但框架強化工作（Issue Triage 路由、GitHub scan、standup）未計入 Velocity，實際產出被低估
- **Metrics_Log 更新未列入 DoD**：US-08 交付後 Metrics_Log 後續更新屬自由心證，Stakeholder 在 Review 才提出列入 DoD

### Action Items

| # | Action | Owner | 驗收方式 | 狀態 |
|---|--------|-------|----------|------|
| 1 | 框架工作計點機制：Sprint 5 Planning 評估是否為框架強化工作建立獨立計點類型（Framework Task），無論採用與否決策必須明文化 | PO + Architect | Sprint 5 Planning 結束前決策記錄於文件 | Closed（Sprint 5 Planning） |
| 2 | Metrics_Log 更新列入 DoD：在全局 DoD 定義新增「Metrics_Log.md 本 Sprint 數據已更新」 | PO | Sprint 5 Planning QA Health Check 確認 DoD 含此條目 | Closed（Sprint 5 Planning） |

---

## Sprint 5 — 2026-03-01

**Sprint Goal**：完成 v0.3.0 Tech Debt Registry，並同步建立 ADR-002 解鎖測試框架擴展路徑，並修復 16 項框架監控缺口
**結果**：Goal 達成。全部 4 個 Stories 完成交付。

### 交付成果

| Story | Size | 狀態 | 驗收 |
|-------|------|------|------|
| ADR-002：測試框架技術選型 | S | Done | AC 全通過（4/4）— 純 Bash + 共享函式庫，排除 BATS/ShellSpec |
| US-FIX-01：修復審計發現 | M | Done | AC 全通過（5/5）— 13 項框架文件修復，DoD 統一為 7 層 |
| US-10：Tech Debt Registry | M | Done | AC 全通過（7/7）— Registry + Developer prompt + DoD 自檢 + Grooming 流程 |
| US-T01：Skill 完整性驗證 | S | Done | AC 全通過（5/5）— TDD Red-Green-Refactor，16 skills 全通過 |

**Velocity**：6 points（2S + 2M = 1+2+2+1）

### Good（保持做的事）

- **Velocity 回升至歷史新高（4→6），完成率連續 5 個 Sprint 100%**：Sprint 5 計畫 6 points 全數交付，打破 Sprint 4 的下降趨勢。證明團隊在計畫超載（~1.4 Sprint 容量）的情況下仍能全數完成
- **ADR Hard Gate 機制運作良好**：ADR-002 先行完成，US-T01 在其後啟動，依賴鏈正確解鎖。零等待浪費
- **QA 雙階段審查穩定運作（第 2 個 Sprint）**：每個 Story 經 Spec Compliance + Code Quality 雙審查，US-T01 的 3 項 Low 發現即時修復後再次通過。品質閘門持續有效
- **共享函式庫（validate-helpers.sh）建立**：ADR-002 的關鍵產出，消除未來 9 個驗證腳本的重複實作風險。架構決策已實際落地

### Problem（需改進的事）

- **DoD 層數分歧（7 vs 8）**：US-10 新增技術債層（第 8 層）至 sprint-execution SKILL.md，但未同步更新 scrum-master SKILL.md，導致兩份 DoD 定義不一致。Stakeholder 在 Review 指出應同步
- **QA Code Quality Review false positive 率偏高**：US-FIX-01 的 Code Quality Review 3 項發現中有 2 項為 false positive（QA 讀取過時資料、將既存問題歸入當前 Story），需要改善 QA 對「本次變更範圍」的界定
- **Sprint 5 Planning 未納入 QA 審計資料的 GitHub Issues 掃描步驟**：Planning Skill 已更新（AC-A4）但實際 Sprint 5 Planning 執行時未觸發 Issue 掃描（因 checklist 在 Planning 完成後才更新）。這是時序問題，下個 Sprint 不會再發生

### Action Items

| # | Action | Owner | 驗收方式 | 狀態 |
|---|--------|-------|----------|------|
| 1 | DoD 第 8 層同步：scrum-master SKILL.md 補入「技術債」層，與 sprint-execution SKILL.md 對齊 | Developer | scrum-master SKILL.md DoD 包含技術債行 | Closed（Sprint 6） | [#7](https://github.com/KCTW/shikigami/issues/7) |
| 2 | QA Review 範圍界定：quality-reviewer-prompt.md 新增「僅審查本次 Story 變更範圍，既存問題不計入 FAIL」指引 | QA | quality-reviewer-prompt.md 含範圍界定條款 | Closed（Sprint 6） | [#8](https://github.com/KCTW/shikigami/issues/8) |

---

## Sprint 6 — 2026-03-01

**Sprint Goal**：建立 Hard Gate Checklist 機制（US-FIX-02），擴展測試框架覆蓋（US-T02、US-T03），並清零 Sprint 5 Retro 技術債
**結果**：Goal 達成。全部 5 個 Stories 完成交付。

### 交付成果

| Story | Size | 狀態 | 驗收 |
|-------|------|------|------|
| Retro #7：DoD 第 8 層同步 | S | Done | AC 全通過（2/2）— scrum-master SKILL.md 第 8 層「技術債」補入，兩份 DoD 8 層逐行一致；Issue #7 CLOSED |
| Retro #8：QA Review 範圍界定 | S | Done | AC 全通過（2/2）— quality-reviewer-prompt.md 新增「審查範圍界定」4 項條款，使用「應分類」；Issue #8 CLOSED |
| US-T02：Agent 完整性驗證 | S | Done | AC 全通過（5/5）— TDD Red-Green-Refactor，validate-agents.sh 35 項檢查全通過，7 個 Agent 合規 |
| US-T03：JSON Schema 驗證 | M | Done | AC 全通過（5/5）— TDD Red-Green-Refactor，validate-json.sh 15 項檢查全通過，plugin.json / marketplace.json 合規 |
| US-FIX-02：Hard Gate Checklist 機制 | L | Done | AC 全通過（6/6）— scrum-master SKILL.md §9 含 3 個 Hard Gate（9.1/9.2/9.3）、觸發條件、結果判定、Bootstrap 豁免條款 |

**Velocity**：8 points（2S + 1S + 1S + 1M + 1L = 1+1+1+2+3）

### Good（保持做的事）

- **Velocity 創歷史新高（8pt），完成率連續 6 個 Sprint 100%**：含 1 個 L Story（US-FIX-02），證明團隊可處理結構性複雜任務且不犧牲交付品質
- **Sprint 5 Retro Action Items 全部清零**：#7 和 #8 兩個 GitHub Issues 均在 Sprint 6 關閉，Retro 追蹤機制連續 6 個 Sprint 無逾期 Item
- **ADR 先行 → 實作跟進的依賴鏈管理無阻塞**：ADR-003（Sprint 5）→ US-FIX-02（Sprint 6），一個 Sprint 內從決策到落地，零等待浪費
- **測試框架覆蓋持續擴展**：5 支驗證腳本（skills, commands, version, agents, json）+ 共享函式庫，ADR-002 架構決策持續兌現
- **Bootstrap 自我引用風險被正確識別與處理**：QA Code Quality Review 發現 US-FIX-02 修改的文件即是定義規則的文件，Developer 以豁免條款解決，證明雙階段審查對邊界情境有效
- **Retro #8 審查範圍界定即時生效**：Sprint 6 的 3 個 Code Quality Review 中，QA 正確區分「本次變更」與「既存問題」，false positive 率歸零

### Problem（需改進的事）

- **sprint_N.md Sprint Backlog 狀態未同步更新**：Sprint Execution 更新 PROJECT_BOARD.md 時未回頭更新 sprint_6.md 的狀態欄（仍為「待開始」），造成兩份文件不一致。PROJECT_BOARD 是看板真相來源，sprint_N.md 是 Sprint 規劃文件，兩者狀態理應同步
- **知識文件散落風險**：PLUGIN_DEV_NOTES.md 位於 docs/ 根目錄而非 docs/km/，使用者提出應歸入知識管理目錄。框架無自動偵測知識散落的機制
- **US-T03 AC4 whitelist 規格與實際不一致**：PO 在 Sprint Planning 定義 8 個白名單欄位，但 Developer 實作時發現 plugin.json 實際使用 10 個欄位（多了 repository、keywords），需臨場擴充。根因是 AC 撰寫時未完整對照實際 JSON 檔案

### Action Items

| # | Action | Owner | 驗收方式 | 狀態 |
|---|--------|-------|----------|------|
| 1 | sprint_N.md 狀態回寫：Sprint Execution 更新 PROJECT_BOARD 時同步更新 sprint_N.md 的 Sprint Backlog 狀態欄 | Developer | 下次 Sprint Execution 完成後 sprint_N.md 狀態欄與 PROJECT_BOARD 一致 | Open | [#10](https://github.com/KCTW/shikigami/issues/10) |
| 2 | PLUGIN_DEV_NOTES.md 歸檔：移至 docs/km/，建立知識文件歸檔慣例 | Developer | PLUGIN_DEV_NOTES.md 位於 docs/km/ 目錄 | Open | [#11](https://github.com/KCTW/shikigami/issues/11) |
