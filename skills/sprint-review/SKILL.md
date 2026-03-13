---
name: sprint-review
description: "Use when sprint ends, conducting sprint review and retrospective, or evaluating sprint outcomes"
---

# Sprint Review & Retrospective

## 1. 概述

Sprint Review（驗收成果）+ Retrospective（持續改進），依序進行。全程採用**精簡輸出**：每步驟輸出結論（PASS/FAIL + 一行摘要），Checklist 逐項打勾，不展開中間推理。

## 模型選用建議

| 角色 / 步驟 | 模型 | 說明 |
|------------|------|------|
| PO Subagent（Demo 展示、AC 驗收） | `sonnet` | 需要情境理解與商業判斷 |
| Stakeholder Subagent（商業期待確認） | `sonnet` | 需要情境理解與商業判斷 |
| Analytics Subagent（§3 步驟 0 趨勢分析） | `haiku` | 統計分析，規則明確可程式化 |
| Metrics Subagent（Sprint Metrics） | `haiku` | 數值計算，規則明確可程式化 |

## 1.3 合約載入

Sprint Review 開始前載入共用交付合約作為驗收基準：

```
Read: contracts/README.md
Read: contracts/sow-delivery-contract.md        （若本 Sprint 有 SOW 相關 Story）
Read: contracts/numerical-consistency-contract.md（若本 Sprint 有數值修改 Story）
```

載入時機：Sprint Review 流程開始後、§1.5 審查前。

## 1.5 交付物文案一致性審查（Sprint Review 前執行）

### 審查 Checklist

- [ ] **跨文件術語一致性**：sprint_N.md 各 Story 狀態與 PROJECT_BOARD.md 一致；ROADMAP.md 術語與 Sprint Backlog 一致
- [ ] **狀態標注一致性**：統一使用「完成 / 進行中 / 未完成」中文術語；PROJECT_BOARD.md 區塊劃分正確；未完成 Story 的 Issue 已回復 `status: backlog` label
- [ ] **Issue 連結有效性**：sprint_N.md Issue # 填寫完整；Issue 狀態符合預期；Retrospective Log Action Items 連結有效
- [ ] **版本與里程碑一致性**：ROADMAP.md 里程碑狀態與交付進度相符；版本 Tag 描述一致
- [ ] **CI 狀態確認**：`gh run list --limit 1 --json conclusion` 最新為 `success`

**FAIL 處理**：發現不一致立即修正，全部 PASS 後才進入 §2。

---

## 2. Sprint Review 流程

### Pre-Demo 部署驗證

確認生產環境已部署最新 commit。未部署 → 觸發 `deployment-readiness`，完成後才進入步驟 1。

### 步驟

1. **PO Subagent 展示 Demo 結果** — 角色 prompt：`skills/sprint-review/po-review-prompt.md`
2. **QA 主導邊界案例測試** — 在 Happy Path Demo 完成後，由 QA Subagent 執行「邊界案例測試」環節，測試清單參照 `skills/qa-engineer/SKILL.md §5 常見邊界案例清單`。QA 主導測試並產出邊界案例驗證結果，於步驟 3 前完成報告。
3. **Stakeholder Subagent 確認商業期待** — 角色 prompt：`skills/sprint-review/stakeholder-prompt.md`
4. **更新 `docs/PROJECT_BOARD.md`（已完成欄位）** — 通過驗收 Story 移至 Done，記錄完成日期與 Sprint 編號，更新 Sprint 統計數據
5. **未達 DoD 的 Story 處理** — 詳見 `po-review-prompt.md`
6. **回寫 `docs/sprints/sprint_N.md` Story 最終狀態** — 詳見 `po-review-prompt.md`

## 2.5 Sprint 外完成項目掃描

掃描 `docs/km/Shoot_Log.md` 取得本 Sprint 期間 PASS 的短衝記錄，列入「Sprint 外完成項目」。短衝記錄**不計入 Velocity**。檔案不存在時輸出「本 Sprint 無短衝記錄」。

## 2.6 Story Issue 狀態回寫（ADR-010 生命週期閉環）

Story 驗收判定完成後，依判定結果回寫 GitHub Issue 狀態。在 §2 步驟 5 之後、§3 之前執行。

### 操作規則

| 驗收判定 | Issue 操作 | 說明 |
|---------|-----------|------|
| Story PASS | 依 Issue 建立者判斷執行對應操作 | 內部 Issue 自動關閉；外部 Issue 保持 Open |
| Story FAIL | Issue 保持 open | 回流 Backlog，等待下次 Sprint 選取 |

### Issue 建立者判斷

**內部 Issue**：建立者為 `github-actions[bot]` 或 body 含 `backlog-intake`。其餘為**外部 Issue**。

### Story PASS — 操作步驟

| 情況 | 步驟 1（共通） | 步驟 2 |
|------|--------------|--------|
| **內部 Issue** | `gh issue edit` 加 `done` label、移除 `in-sprint` label | `gh issue close` 並留言 |
| **外部 Issue（階段 1）** | 同上 | `gh issue comment` 留言通知，**不執行 close** |
| **外部 Issue（階段 2）** | — | 觸發條件：**deployment-readiness PASS 且 E2E PASS**，方可執行 `gh issue comment` 補充留言 |

> **負面條件**：若 deployment-readiness 尚未完成（FAIL 或未執行），階段 2 留言**不得補發**，即使 Sprint Review 主流程已結束亦不例外。禁止在主流程結束前預先補發。

### Story FAIL — 操作步驟

Issue 保持 open，移除 `in-sprint` label 並加 `status: backlog` label，留言記錄未完成原因。

---

## 3. Sprint Retrospective 流程

### 步驟

0. **Retrospective Analytics** — 角色 prompt：`skills/sprint-review/analytics-prompt.md`。報告展示完畢前不得開始收集 Good / Problem / Action。
1. **在 `docs/km/Retrospective_Log.md` 新增記錄**
2. **使用 Good / Problem / Action 格式收集回饋**
3. **SPACE 五維度量測** — 詳見 `analytics-prompt.md`
4. **Quality Observer 診斷報告** — 詳見 `analytics-prompt.md`
5. **每個 Action 建立為 GitHub Issue** — 透過 `issue-management` Skill，標題 `retro:` 前綴，`retro-action` label
6. **同步記錄至 `docs/km/Retrospective_Log.md`**
7. **代理人校準儀式** — 角色 prompt：`skills/sprint-review/stakeholder-prompt.md`

## 4. Action Items 驗收機制

透過 GitHub Issues 追蹤（`retro-action` label）：
1. 每個 Action Item 透過 `issue-management` 建立為 Issue
2. 每次 Sprint Review 開始前，列出所有 open 的 `retro-action` Issues 並逐項確認
3. 已完成 → 關閉 Issue；未完成 → 加 `deferred` label
4. 連續兩個 Sprint 仍為 open → 升級至 Stakeholder

---

## 5. 產出文件

| 文件 | 更新內容 |
|------|----------|
| `docs/PROJECT_BOARD.md` | 已完成 Story 移至 Done；更新 Sprint 統計 |
| `docs/km/Retrospective_Log.md` | 新增 Good / Problem / Action 記錄 |
| `docs/km/Metrics_Log.md` | 追加 Velocity、完成率、趨勢分析 |
| `docs/sprints/sprint_N.md` | 回寫各 Story 最終驗收狀態 |
| `docs/prd/ROADMAP.md` | 更新版本里程碑狀態 |

### 5.1 ROADMAP 里程碑對齊檢查

執行時機：產出文件更新完成後、觸發 deployment-readiness 前。

1. 讀取 `docs/prd/ROADMAP.md`，確認各里程碑當前狀態
2. 逐一檢查活躍里程碑完成狀態，對照本 Sprint 交付 Stories
3. 判斷里程碑是否完成：完成 → Major bump 候選（需 PO 確認）；未完成 → Minor bump 候選
4. 更新里程碑狀態（若完成）
5. 將對齊檢查結果附帶至 deployment-readiness 觸發指令

---

## 6. 歸檔觸發檢查

Sprint Review & Retrospective 所有產出文件完成最後修改後，立即 git commit + push。範圍：`PROJECT_BOARD.md`、`Retrospective_Log.md`、`Metrics_Log.md`、`sprint_N.md`。其他 KM 文件不適用，避免觸發 ADR-003 Hard Gate。

---

## 7. 執行檢查清單

- [ ] **Systematic Debugging（HARD-GATE）**：Sprint Review 前執行 `invoke shikigami:systematic-debugging`，PASS 後方可繼續
- [ ] **Pre-Demo 部署驗證**（PASS 或 FAIL）
- [ ] **交付物文案一致性審查**（§1.5 全部 PASS）
- [ ] **Retrospective Analytics 報告**（§3 步驟 0，四區塊完整）
- [ ] PO Subagent 已展示所有已完成 Story 的 Demo
- [ ] **QA 邊界案例測試**（§2 步驟 2）：QA 已執行邊界案例測試環節，並產出「邊界案例驗證結果」報告
- [ ] Stakeholder Subagent 已確認商業期待符合度
- [ ] 通過驗收 Story 已移至 `PROJECT_BOARD.md` Done 欄位
- [ ] `sprint_N.md` Story 狀態欄已回寫最終驗收結果
- [ ] **Story Issue 狀態回寫**（§2.6，HARD-GATE）：
  - [ ] PASS Story：已查詢 Issue 建立者、判斷內部/外部、執行對應操作
  - [ ] 內部 Issue：done label + 移除 in-sprint + 關閉
  - [ ] 外部 Issue：done label + 移除 in-sprint + 階段 1 留言（保持 Open）
  - [ ] FAIL Story：已回復 backlog 狀態並留言
- [ ] 未達 DoD Story 已移回 Backlog 並標注原因
- [ ] `Retrospective_Log.md` 已新增記錄
- [ ] 每個 Action Item 已建立為 GitHub Issue
- [ ] 上個 Sprint 的 `retro-action` Issues 已逐項檢查
- [ ] 代理人校準儀式已完成
- [ ] 連續兩個 Sprint 未關閉 Action 已升級至 Stakeholder
- [ ] `ROADMAP.md` 已更新
- [ ] **ROADMAP 里程碑對齊檢查**（§5.1）
- [ ] 觸發 `deployment-readiness`（附帶里程碑對齊結果）
- [ ] **E2E 驗證結果已確認**
- [ ] 外部 Issue 階段 2 留言（**僅在 deployment-readiness PASS 且 E2E PASS 後執行**；否則不補發）
- [ ] Sprint Metrics 已計算並追加至 `Metrics_Log.md`（詳見 `po-review-prompt.md`）
- [ ] 角色制衡案例檢查（若有，更新 `ROLE_BALANCE_CASES.md`）
- [ ] **產出文件 git commit + push**（HARD-GATE）
