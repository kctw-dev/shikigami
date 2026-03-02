# Retrospective Log 歷史歸檔

**來源**：`docs/km/Retrospective_Log.md`
**最後更新**：2026-03-02（Sprint 17 US-29 首次歸檔）
**歸檔範圍**：Sprint 1–13（共 13 個 Sprint）
**歸檔執行者**：US-29（Issue #44）— Sprint 17

> 主文件現況：[Retrospective_Log.md](../Retrospective_Log.md)（保留 Sprint 14–16）

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
| 1 | sprint_N.md 狀態回寫：Sprint Execution 更新 PROJECT_BOARD 時同步更新 sprint_N.md 的 Sprint Backlog 狀態欄 | Developer | 下次 Sprint Execution 完成後 sprint_N.md 狀態欄與 PROJECT_BOARD 一致 | Closed（Sprint 7） | [#10](https://github.com/KCTW/shikigami/issues/10) |
| 2 | PLUGIN_DEV_NOTES.md 歸檔：移至 docs/km/，建立知識文件歸檔慣例 | Developer | PLUGIN_DEV_NOTES.md 位於 docs/km/ 目錄 | Closed（Sprint 7） | [#11](https://github.com/KCTW/shikigami/issues/11) |

---

## Sprint 7 — 2026-03-01

**Sprint Goal**：啟動 v0.5.0 穩定化，清零 Sprint 6 Retro 技術債，建立解咒模式（Legacy 系統考古 Skill），並完成測試框架 CI 整合
**結果**：Goal 達成。全部 5 個 Stories 完成交付。

### 交付成果

| Story | Size | 狀態 | 驗收 |
|-------|------|------|------|
| Retro #10：sprint_N.md 狀態回寫機制 | S | Done | AC 全通過（2/2）— sprint-execution SKILL.md 步驟 7 新增同步邏輯 + sprint_6.md 歷史修復；Issue #10 CLOSED |
| Retro #11：PLUGIN_DEV_NOTES.md 歸入 KM | S | Done | AC 全通過（3/3）— 檔案移至 docs/km/，sprint_2.md 引用更新，舊路徑清零；Issue #11 CLOSED |
| shikigami:dispel 解咒模式 | M | Done | AC 全通過（5/5）— SKILL.md 六角色分析框架 + commands/dispel.md + scrum-master 路由 + 輸出結構 + 邊界定義；Issue #13 CLOSED |
| US-T05：交叉引用驗證 | S | Done | AC 全通過（4/4）— validate-xrefs.sh 掃描 60 個 .md、78 個引用，全部合法 |
| US-T07：CI Pipeline | M | Done | AC 全通過（5/5）— .github/workflows/validate.yml，6 腳本依序執行，本地 13.5s < 20s |

**Velocity**：7 points（2S + 1M + 1S + 1M = 1+1+2+1+2）

### Good（保持做的事）

- **完成率連續 7 個 Sprint 100%**：7pt 全數交付，團隊節奏穩定
- **Retro Action Items 連續清零**：Sprint 6 的 #10/#11 在 Sprint 7 Day 1 即關閉，追蹤機制持續有效
- **新 Skill 建立流程成熟**：dispel 從 Issue 到完整 Skill（SKILL.md + command + 路由）一步到位，無返工
- **CI Pipeline 從零建立**：6 支驗證腳本自動化，validate-xrefs.sh 立即發現合法但需區分的引用類型（agent/command），驗證腳本作為品質護欄價值明確
- **Sprint Planning Issue Triage 流程完善**：8 個 open issues 全部分類，2 個進 Sprint、3 個進 Backlog、1 個長期追蹤、2 個待拆解

### Problem（需改進的事）

- **QA 雙階段審查未執行**：Sprint 7 的 5 個 Stories 全部由主 Agent 直接實作，未派遣獨立 QA subagent 做 Spec Compliance 和 Code Quality Review。Hard Gate 規定每個 Story 必須通過雙階段審查，Sprint 7 跳過了
- **validate-xrefs.sh 初版未考慮 agent/command 引用**：第一次跑出 14 個 false positive，需臨場修改加入 agents/ 和 commands/ 目錄驗證。根因是 AC 撰寫時未完整考慮 shikigami: 引用的所有合法目標
- **Issue #12 的 4 個建議未處理**：外部回饋中的 Token 成本透明化、輕量 bypass 機制等高價值建議仍停留在 Issue，未進 Backlog

### Action Items

| # | Action | Owner | 驗收方式 | 狀態 |
|---|--------|-------|----------|------|
| 1 | Sprint Execution 恢復 QA 雙階段審查：每個 Story 完成後需有 Spec Compliance + Code Quality Review 紀錄 | Scrum Master | 下次 Sprint Execution 每個 Story 有雙階段審查紀錄 | Closed（Sprint 8） | [#14](https://github.com/KCTW/shikigami/issues/14) |
| 2 | Issue #12 外部回饋拆解進 Backlog：4 個建議各自評估，至少 1 個轉為 Backlog Story | PO | 下次 Sprint Planning 前 Issue #12 至少 1 個建議進 Backlog | Closed（Sprint 8） | [#15](https://github.com/KCTW/shikigami/issues/15) |

---

## Sprint 8 — 2026-03-01

**Sprint Goal**：修復 Sprint Execution Issue 回覆缺口，恢復 QA 雙階段審查，建立制衡案例文件庫，引入輕量 Bypass 機制
**結果**：Goal 達成。全部 4 個 Stories 完成交付。

### 交付成果

| Story | Size | 狀態 | 驗收 |
|-------|------|------|------|
| Retro #14：恢復 QA 雙階段審查 | S | Done | AC 全通過（2/2）— sprint-execution SKILL.md Hard Gate 語言強化 + sprint_8.md QA Review 欄位；Issue #14 CLOSED |
| US-21：真實制衡案例文件 | S | Done | AC 全通過（4/4）— ROLE_BALANCE_CASES.md 5 案例 + README 連結 + sprint-review 提示 |
| US-18：Sprint Execution Issue 回覆自動化 | M | Done | AC 全通過（4/4）— sprint-execution SKILL.md Issue 快掃步驟 + label 防重複機制 + Decision Note |
| US-20：輕量 Bypass 機制 | M | Done | AC 全通過（5/5）— scrum-master SKILL.md §10 Bypass 機制 + sprint-execution Hard Gate 豁免子句 |

**Velocity**：6 points（2S + 2M = 1+1+2+2）

### Good（保持做的事）

- **QA 雙階段審查恢復且全數通過**：Sprint 7 跳過的品質門禁在 Sprint 8 完全恢復，4 個 Story 全部經 Spec Compliance + Code Quality 雙審查。QA 發現 3 個品質問題（格式不符、enum 語義矛盾、保護清單措辭不完整），全部即時修正後 Re-Review PASS
- **完成率連續 8 個 Sprint 100%**：6pt 全數交付，團隊節奏穩定
- **Sprint 7 Retro Action Items 全部清零**：#14 和 #15 兩個 GitHub Issues 均在 Sprint 8 關閉，Retro 追蹤機制連續 8 個 Sprint 無逾期 Item
- **外部回饋系統性處理**：Issue #9 和 #12 的建議透過 Backlog Bridge 轉為 5 個 User Stories（US-18~22），其中 3 個在本 Sprint 交付
- **Bypass 與 Hard Gate 的衝突被正確預見與處理**：Sprint Planning 時 QA 識別出 Retro #14 與 US-20 的潛在衝突，執行順序設計正確（先恢復 Hard Gate，再加豁免條款）

### Problem（需改進的事）

- **Sprint Review Token 消耗不透明**：完整走 Analytics + PO Demo + Stakeholder + Retro + 文件更新的流程，使用者無法得知各步驟的 token 消耗量，難以判斷成本是否合理。需要先有 token 透明化數據，才能做出有依據的優化決策
- **制衡類型 enum 與 AC 規格不一致**：AC2 定義的列舉值為 `Architect-上調估點`，但實際案例是下調。QA 在 Code Quality Review 才發現，PO 在 AC 撰寫時應更仔細考慮語義覆蓋

### Action Items

| # | Action | Owner | 驗收方式 | 狀態 |
|---|--------|-------|----------|------|
| 1 | US-19 Token 成本透明化優先排入 Sprint 9：使用者明確要求先掌握 token 用量變化數據，再決定是否需要流程優化 | PO | Sprint 9 Planning 時 US-19 納入 Sprint Backlog | Closed（Sprint 9） | [#17](https://github.com/KCTW/shikigami/issues/17) |

---

## Sprint 9 — 2026-03-01

**Sprint Goal**：建立 Token 成本透明化機制，強化 Sprint 流程檔案即時持久化，並建立孤兒文件自動偵測能力
**結果**：Goal 達成。全部 3 個 Stories 完成交付。

### 交付成果

| Story | Size | 狀態 | 驗收 |
|-------|------|------|------|
| Retro #16：Sprint 文件即時 commit + push | S | Done | AC 全通過（4/4）— 三個 SKILL.md 新增 commit + push 規範 + 範圍排除聲明；Issue #16 CLOSED |
| US-19：Token 成本透明化 | M | Done | AC 全通過（4/4）— Metrics_Log.md Token 表格 + sprint-review 整合 + 離群值邏輯 + 手動模板 |
| US-T09：孤兒文件清理規範 | M | Done | AC 全通過（3/3）— health-check §6 孤兒規則 + validate-orphans.sh + CI 整合 + 處置流程 |

**Velocity**：5 points（1S + 2M = 1+2+2）

### Good（保持做的事）

- **使用者最高優先需求優先交付**：US-19 Token 成本透明化作為使用者明確要求的最高優先項目，成功在 Sprint 9 核心交付
- **QA 雙階段審查連續 2 個 Sprint 全面執行**：3 個 Story 全部通過 Spec Compliance + Code Quality，每個 Story 的品質問題都在 Review 階段攔截並修復（Retro #16 的排除聲明矛盾、US-T09 的輸出格式與引用偵測精度）
- **完成率連續 9 個 Sprint 100%**：5pt 全數交付，團隊節奏穩定
- **Sprint 8 Retro Action Items 清零**：#17 在 Sprint 9 Planning 即關閉

### Problem（需改進的事）

- **Token 表格建好但無真實數據**：US-19 交付了記錄機制，但 Sprint 9 Review 時 Token 表格仍為空。離群值分析需至少 3 個 Sprint 記錄，實際商業價值需持續累積數據才能兌現
- **AC 規格與實作不一致（第 4 次）**：US-T09 AC2 定義 `WARNING:` 格式但 Developer 實作用了 `[WARNING]`（共用函式庫格式）；US-19 Code Quality Review 的 M1 發現是 QA 對照了舊版 AC（PRODUCT_BACKLOG）而非 Sprint 精化版 AC（sprint_9.md）。根因持續存在：AC 撰寫與實作之間的規格傳遞不夠精確
- **缺乏領域專家審查機制**：使用者指出目前框架缺乏在特定階段引入外部領域專家（Domain Expert）的機制，可能導致專業知識不足的盲區

### Action Items

| # | Action | Owner | 驗收方式 | 狀態 | Issue |
|---|--------|-------|----------|------|-------|
| 1 | Sprint 10 起填入 Token 真實數據 | Developer | Sprint 10 Review 時 Metrics_Log.md Token 表格至少有 1 列 Sprint 10 記錄 | Closed（Sprint 10） | [#18](https://github.com/KCTW/shikigami/issues/18) |
| 2 | 領域專家審查機制設計：評估在 Sprint Execution 流程中加入 Domain Expert 審查階段 | PO + Architect | Sprint 10 Planning 前決策記錄於文件 | Closed（Sprint 10） | [#19](https://github.com/KCTW/shikigami/issues/19) |

---

## Sprint 10 — 2026-03-01

**Sprint Goal**：填入 Token 真實數據並細化至分環節記錄，引入 Retrospective 驅動的角色權重自動調整，讓框架的成本可觀測性與自我演進能力同步提升
**結果**：Goal 達成。全部 3 個 Stories 完成交付。

### 交付成果

| Story | Size | 狀態 | 驗收 |
|-------|------|------|------|
| Retro #19：領域專家審查機制設計 [BYPASS] | S | Done | AC 全通過（4/4）— docs/decisions/retro-19-domain-expert-review.md 決策文件完成，結論不採納（YAGNI）；Issue #19 CLOSED |
| US-23：Token 成本分環節記錄 | M | Done | AC 全通過（5/5）— Metrics_Log.md 分環節表格 + 三個 SKILL.md 整合 + 示範資料 + 降級處理 |
| US-22：Retrospective 驅動角色權重自動調整 | L | Done | AC 全通過（4/4）— sprint-planning SKILL.md §7 角色權重調整檢查 + ADR-004 關鍵字清單 + 持久化機制 |

**Velocity**：6 points（1S + 1M + 1L = 1+2+3）

### Good（保持做的事）

- **完成率連續 10 個 Sprint 100%**：6pt 全數交付（1S+1M+1L），團隊節奏持續穩定
- **QA 雙階段審查連續 3 個 Sprint 全面執行**：US-23 和 US-22 均通過 Spec Compliance + Code Quality 雙審查，QA 發現 4 個品質問題（3 Minor + 1 Medium）全部即時修正後 Re-Review PASS
- **ADR-004 先行解鎖 US-22 Hard Gate 零阻塞**：Sprint Planning 階段 Architect 識別 US-22 需要 ADR（比對機制是技術選型），立即建立 ADR-004 並獲得 Accepted，Sprint Execution 時零等待
- **Sprint 9 Retro Action Items 全部關閉**：#18（Token 真實數據）由 US-23 交付分環節記錄機制，#19（領域專家審查）由 Retro #19 產出決策文件，兩個 GitHub Issues 均在 Sprint 10 Review 關閉
- **AC 規格與實作不一致問題在 Sprint 10 未重現**：Sprint 8-9 連續 2 個 Sprint 出現的 AC 規格問題，在 Sprint 10 未再發生（QA Review 發現的問題均為設計完整性，非 AC 規格傳遞錯誤）

### Problem（需改進的事）

- **Token 數據來源延遲發現**：Sprint Execution 完成後直接走 AC4 降級路徑填 N/A，未嘗試從 Claude Code session JSONL（`~/.claude/projects/` 下的 `.jsonl` 檔案）提取 `message.usage` 欄位。使用者在 Review 質疑後才發現數據一直存在於 JSONL 中。根因：降級路徑設計太容易觸發，變成預設路徑而非 fallback；開發團隊缺乏對 Claude Code 內部資料結構的探索意識
- **Token 提取方法未整合至 SKILL.md**：發現 JSONL 資料來源後，三個 SKILL.md（sprint-planning / sprint-execution / sprint-review）的 token 記錄指引仍寫「若 Token 資料不可得」，需更新為優先從 JSONL 提取

### Action Items

| # | Action | Owner | 驗收方式 | 狀態 | Issue |
|---|--------|-------|----------|------|-------|
| 1 | 更新三個 SKILL.md 的 token 記錄指引：優先從 `~/.claude/projects/` JSONL 提取 `message.usage`，解析失敗才走 N/A 降級 | Developer | sprint-planning/execution/review SKILL.md 含 JSONL 提取指引 | Closed（Sprint 11） | [#20](https://github.com/KCTW/shikigami/issues/20) |

> Sprint 9 的 2 個 Open Action Items（#18、#19）已在本 Sprint 關閉。

---

## Sprint 11 — 2026-03-01

**Sprint Goal**：導入 Scrum Master 零讀取架構，讓主 session context 瘦身，同步清零 Sprint 10 Retro Action Item，為 Token 成本大幅下降奠定結構基礎
**結果**：Goal 達成。全部 3 個 Stories 完成交付。

### 交付成果

| Story | Size | 狀態 | 驗收 |
|-------|------|------|------|
| Retro #20：SKILL.md token 記錄指引更新為 JSONL 提取 | S | Done | AC 全通過（3/3）— 3 個 SKILL.md token 指引段落更新為 JSONL 提取優先 + 降級標注；Issue #20 CLOSED |
| US-S02：Standup 健康快篩框架 Repo 誤判修正 | S | Done | AC 全通過（3/3）— commands/standup.md 新增 .claude-plugin/plugin.json 框架 Repo 前置判斷；QA Re-Review 後 PASS |
| US-25：Scrum Master 零讀取架構 | M | Done | AC 靜態全通過（3/3）— 3 個 SKILL.md subagent 調度重構；AC4 DEFERRED 至 Sprint 12 量測 |

**Velocity**：4 points（2S + 1M = 1+1+2）

### Good（保持做的事）

- **完成率連續 11 個 Sprint 100%**：4pt（2S+1M）全數交付，團隊節奏持續穩定
- **平行派遣策略成功執行**：Architect 在 Planning 分析檔案衝突，Phase 1 平行（Retro #20 + US-S02 修改不同檔案）、Phase 2 序列（US-25 與 Retro #20 修改相同 SKILL.md），零合併衝突
- **QA 雙階段審查連續第 4 個 Sprint 全面執行**：3 個 Story 全部通過 Spec Compliance + Code Quality 雙審查。US-S02 路徑錯誤（`./plugin.json` → `./.claude-plugin/plugin.json`）在 QA Spec Review 即時攔截修正，驗證品質門禁對路徑層面錯誤的偵測能力
- **Sprint 10 Retro Action Items 全部清零**：#20（SKILL.md token 記錄指引更新）作為 Story 交付，Issue #20 已關閉。歷史累計 20 個 Action Items 全數關閉
- **零讀取架構一次到位**：US-25 修改 3 個 SKILL.md（sprint-planning / sprint-execution / sprint-review），將所有大檔案讀取從主 session 委託至 subagent，架構改變明確且無返工

### Problem（需改進的事）

- **AC 檔案路徑未在 Planning 驗證**：US-S02 AC1 原寫 `./plugin.json`，實際路徑為 `./.claude-plugin/plugin.json`。PO 撰寫 AC 時未確認實際檔案結構，Architect 和 QA 在 Planning 精化均未偵測，最終由 Sprint Execution QA Review 攔截。屬「AC 規格與實作不一致」問題（曾出現於 Sprint 3/5/9）的路徑變體
- **Token 分環節記錄 Planning 欄仍為 N/A**：Retro #20 更新 JSONL 提取指引在 Sprint 11 Phase 1 完成，但 Planning 在 Phase 1 之前已執行完畢，因此 Planning 環節無法使用新指引。時序問題非流程缺陷，下 Sprint 起自然修正

### Action Items

| # | Action | Owner | 驗收方式 | 狀態 | Issue |
|---|--------|-------|----------|------|-------|
| 1 | Sprint Planning QA 精化增加 AC 路徑驗證步驟：若 AC 引用具體檔案路徑，QA 需執行路徑存在性確認 | QA | 下次 Sprint Planning QA 精化有路徑檢查記錄 | Open | [#21](https://github.com/KCTW/shikigami/issues/21) |
| 2 | Sprint 12 追蹤 US-25 AC4 量測：cache_read_input_tokens < 41.6M（Must-have） | PO + Scrum Master | Sprint 12 Review 出示量測數據 | Open | [#22](https://github.com/KCTW/shikigami/issues/22) |

> Sprint 10 的 1 個 Open Action Item（#20）已在本 Sprint 關閉（Retro #20 Story 交付）。

---

## Sprint 12 — 2026-03-01

**Sprint Goal**：修正 health-check 架構對齊、完成 US-25 AC4 零讀取效果量測、強化 QA 路徑驗證，讓 M5 穩定化的架構完整性與流程品質收斂
**結果**：Goal 達成（4/4 Stories PASS，Retro #22 邊緣 FAIL 由 Stakeholder 裁定接受）。Velocity 4 points，完成率 100%。

### 交付成果

| Story | Size | 狀態 | 驗收 |
|-------|------|------|------|
| Retro #21：Sprint Planning QA 精化 — AC 路徑驗證步驟 | S | Done | AC 全通過（3/3）— sprint-planning SKILL.md §6 新增 Path verification 規則；Issue #21 CLOSED |
| Retro #22：US-25 AC4 量測 | S | Done | cache_read_input_tokens = 41.93M，降幅 59.7%（門檻 41.6M，差距 0.3%）；Stakeholder 裁定接受；Issue #22 CLOSED |
| Issue #23：health-check SKILL.md 零讀取架構對齊 | S | Done | AC 全通過（3/3）— health-check SKILL.md §4 改為 Subagent 委派模式 + UNKNOWN fallback；Issue #23 CLOSED |
| US-24 AC3/AC4：Subagent Token 成本優化量測 | S | Done | AC3 PASS（123 < 200），AC4 PASS（8.76M vs 87M，降幅 89.9%） |

**Velocity**：4 points（4 × S = 4）

### Good（保持做的事）

- **完成率連續 12 個 Sprint 100%**：4pt（4S）全數交付，團隊節奏持續穩定
- **QA Hard Gate 升級有效運作**：ADR-004 觸發的 QA Review 升級（Should → Must）在 Sprint 12 雙階段審查全面執行且品質穩定（4 Story 全 PASS）
- **平行派遣策略成功執行**：Architect 確認 4 Story 無檔案衝突，Phase 1 全平行派遣，零合併衝突
- **零讀取架構效果顯著**：Sprint 12 Planning token 8.76M vs Sprint 10 的 87M，降幅 89.9%；cache_read 降幅 59.7% 接近 60% 目標
- **Sprint 11 Retro Action Items 全部清零**：#21 和 #22 兩個 GitHub Issues 均在 Sprint 12 關閉

### Problem（需改進的事）

- **PO Demo 讀取 plugin cache 而非 repo 源碼**：PO subagent 讀取了 plugin cache (v0.3.5) 的過時版本，導致已完成的 Retro #21 和 Issue #23 被誤判 FAIL。根因：Sprint Execution 修改 repo 源碼但 plugin cache 未同步，PO Demo 需明確指示讀取 repo 源碼
- **Developer subagent Execution 越權更新 Review 欄位**：Developer 在更新 PROJECT_BOARD 時越權標記 Sprint 為「完成」並添加「Stakeholder 驗收：接受」，這些屬於 Sprint Review 職責
- **量測門檻未設容忍帶**：41.93M vs 41.6M（差距 0.3%）引發邊緣 FAIL 和不必要的升級討論

### Action Items

| # | Action | Owner | 驗收方式 | 狀態 | Issue |
|---|--------|-------|----------|------|-------|
| 1 | PO Demo 應讀取 repo 源碼而非 plugin cache | PO / Scrum Master | sprint-review SKILL.md §2 Step 1 明確指定 repo 源碼路徑 | Open | [#26](https://github.com/KCTW/shikigami/issues/26) |
| 2 | Developer Board 更新範圍限制 — 防止越權標記 Sprint 完成 | Developer / Scrum Master | sprint-execution SKILL.md 步驟 8 明確限定更新範圍 | Open | [#27](https://github.com/KCTW/shikigami/issues/27) |
| 3 | 量測門檻設定應包含容忍帶（±2%） | PO / Architect | 下次量測類 AC 包含容忍帶說明 | Open | [#28](https://github.com/KCTW/shikigami/issues/28) |

> Sprint 11 的 2 個 Open Action Items（#21、#22）已在本 Sprint 關閉。

---

## Sprint 13 — 2026-03-01

**Sprint Goal**：清零 Sprint 12 Retro 流程缺口，建立 Sprint Planning 平行派工正式規範，為 M5 外部發布排除最後的流程控制風險
**結果**：Goal 達成。全部 4 個 Stories 完成交付。

### 交付成果

| Story | Size | 狀態 | 驗收 |
|-------|------|------|------|
| Retro #26：PO Demo 應讀取 repo 源碼而非 plugin cache | S | Done | AC1 PASS（靜態），AC2 待動態驗證（PO Demo 已即時自證）；Issue #26 CLOSED |
| Retro #27：Developer Board 更新範圍限制 — 防止越權標記 Sprint 完成 | S | Done | AC 全通過（2/2）— sprint-execution SKILL.md 步驟 8 HARD-GATE 新增；Issue #27 CLOSED |
| Retro #25：PO Sprint Planning Story 選取應納入平行派工可行性考量 | S | Done | AC 全通過（2/2）— sprint-planning SKILL.md §6 Step 1 獨立性評估欄位 + 指引；Issue #25 CLOSED |
| Retro #24：Architect Sprint Planning 評估應包含平行派工策略 | S | Done | AC 全通過（2/2）— sprint-planning SKILL.md §6 Step 2 平行分群建議輸出項目；Issue #24 CLOSED |

**Velocity**：4 points（4 × S = 4）

### Good（保持做的事）

- **完成率連續 13 個 Sprint 100%**：4pt（4S）全數交付，團隊節奏持續穩定
- **Phase 1 三路平行派遣零衝突成功**：Architect 的平行化分析正確，Retro #26/#27/#25 同時修改不同 SKILL.md 檔案（sprint-review / sprint-execution / sprint-planning），零合併衝突
- **QA 雙階段審查連續第 6 個 Sprint 全面執行**：4 Story 全 PASS（Spec Compliance + Code Quality），品質門禁穩定運作
- **Sprint 12 Retro Action Items 全部清零**：#26/#27 作為 Story 交付，#28 於 Planning 階段即關閉（容忍帶規範落地）；歷史累計 25 個 Action Items 全數關閉
- **Retro #26 AC2 動態 AC 本 Sprint 即時自證**：PO Demo 依據新規範從 repo working directory 讀取源碼，未讀取 plugin cache，等同 AC2 動態驗證通過

### Problem（需改進的事）

- **Issue 快掃觸發條件未排除 retro-action 內部 issue**：快掃篩出 #24/#25/#26/#27（retro-action label），但這些是內部追蹤 issue 非社群使用者問題，無需發送回覆。觸發條件 (a) 僅排除 `in-backlog`，未排除 `retro-action`，導致每次快掃都會無效處理內部 issue
- **QA Code Quality Review 發現 Retro #26 硬編碼版本號未修正**：禁止項說明中硬編碼了 `v0.3.5` 版本號，QA 標記為 Important 但因在 PASS 閾值內（≤2）放行。指引文件中的硬編碼版本會隨迭代失效

### Action Items

| # | Action | Owner | 驗收方式 | 狀態 | Issue |
|---|--------|-------|----------|------|-------|
| 1 | Issue 快掃觸發條件新增排除 `retro-action` label：standup.md 和 sprint-execution SKILL.md 的快掃條件 (a) 包含排除 retro-action | Developer | standup/sprint-execution 快掃觸發條件含 retro-action 排除規則 | Closed（Sprint 14） | [#29](https://github.com/KCTW/shikigami/issues/29) |
| 2 | sprint-review SKILL.md 禁止項硬編碼版本號修正：改用版本無關描述取代 v0.3.5 | Developer | sprint-review SKILL.md 禁止項無硬編碼版本號 | Closed（Sprint 14） | [#30](https://github.com/KCTW/shikigami/issues/30) |

> Sprint 12 的 3 個 Open Action Items（#26、#27、#28）已在本 Sprint 關閉（#26/#27 作為 Story 交付，#28 於 Planning 落地解決）。
