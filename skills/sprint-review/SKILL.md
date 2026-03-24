---
name: sprint-review
description: "Use when sprint ends, conducting sprint review and retrospective, or evaluating sprint outcomes"
---

# Sprint Review & Retrospective

## 1. 概述

Sprint Review（驗收成果）+ Retrospective（持續改進），採用**兩個平行 subagent** 執行，總時間約減半。全程採用**精簡輸出**：每步驟輸出結論（PASS/FAIL + 一行摘要），Checklist 逐項打勾，不展開中間推理。

### 1.1 平行 Subagent 職責拆分

| Subagent | 負責範圍 | 說明 |
|----------|----------|------|
| **Review subagent** | §1.5 + §2 全部步驟（含 §2.6 Issue 回寫） | 驗收成果、Issue 狀態更新 |
| **Retro subagent** | §3 全部步驟 | Retrospective 分析與記錄 |

### 1.2 平行執行與同步點

```
啟動時：Review subagent → §1.5 + §2；Retro subagent → §3 步驟 0（Analytics，可平行）
同步點：Review §2.6 完成後寫入 docs/sprints/.review-signal-<SESSION_ID>（REVIEW_DONE=<ts>）
        Retro subagent 讀到 signal 後繼續 §3 步驟 1
最終：主流程驗收兩份產出完整性
```

### 1.3 錯誤處理

各 subagent 失敗互不影響已完成產出。Review 失敗：Retro §3 步驟 0 產出保留，步驟 1 後等待重試完成的 signal。Retro 失敗：Review 產出全保留，可獨立重試。兩者失敗：均從最後失敗步驟繼續。

## 模型選用建議

| 角色 / 步驟 | Subagent | 模型 | 說明 |
|------------|----------|------|------|
| PO Subagent（Demo 展示、AC 驗收） | Review | `sonnet` | 需要情境理解與商業判斷 |
| Stakeholder Subagent（商業期待確認） | Review | `sonnet` | 需要情境理解與商業判斷 |
| Analytics Subagent（§3 步驟 0 趨勢分析） | Retro | `haiku` | 統計分析，規則明確可程式化；可與 Review 平行 |
| Metrics Subagent（Sprint Metrics） | Review | `haiku` | 數值計算，規則明確可程式化 |

## 1.4 合約載入

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

記錄 Sprint Review 開始時間：`REVIEW_START_TIME=$(date '+%Y-%m-%dT%H:%M+08:00')`

### 步驟

1. **PO Subagent 展示 Demo 結果** — 角色 prompt：`skills/sprint-review/references/po-review-prompt.md`
2. **QA 主導邊界案例測試** — 在 Happy Path Demo 完成後，由 QA Subagent 執行「邊界案例測試」環節，測試清單參照 `skills/qa-engineer/SKILL.md §5 常見邊界案例清單`。QA 主導測試並產出初步邊界案例驗證結果。若全部 PASS，直接進入步驟 3。若發現問題，進入步驟 2a。
<!-- #265 Sprint Review QA 缺陷修復複驗流程 -->
2a. **Developer 修復 QA 發現的問題** — Developer Subagent 接收 QA 邊界測試的缺陷清單，逐一修復並 commit。修復完成後進入步驟 2b。
2b. **QA 複驗修復有效性（Hard Gate）** — QA Subagent 針對步驟 2a 的修復執行 targeted regression：(1) 確認原始缺陷已修復、(2) 確認修復未引入新問題（regression）。全部 PASS 方可進入步驟 3。若複驗發現新問題，回到步驟 2a（循環直到 QA PASS）。
3. **Stakeholder Subagent 確認商業期待** — 角色 prompt：`skills/sprint-review/references/stakeholder-prompt.md`
4. **更新 `docs/PROJECT_BOARD.md`（已完成欄位）** — 通過驗收 Story 移至 Done，記錄完成日期與 Sprint 編號，更新 Sprint 統計數據
5. **未達 DoD 的 Story 處理** — 詳見 `references/po-review-prompt.md`
6. **回寫 `docs/sprints/sprint_N.md` Story 最終狀態** — 詳見 `references/po-review-prompt.md`
7. **寫入 Sprint Review 會議紀錄** — 寫入 `docs/meetings/YYYY-MM-DD-sprint-review.md`（詳見 `references/meeting-format.md`）

## 2.5 Sprint 外完成項目掃描

掃描 `docs/km/Shoot_Log.md` 取得本 Sprint 期間 PASS 的短衝記錄，列入「Sprint 外完成項目」。短衝記錄**不計入 Velocity**。檔案不存在時輸出「本 Sprint 無短衝記錄」。

## 2.6 Story Issue 狀態回寫（ADR-010 生命週期閉環）

詳見 `skills/sprint-review/references/issue-writeback.md`。在 §2 步驟 5 之後、§3 之前執行。

**§2.6 完成後**：Review subagent 立即寫入同步 signal（`docs/sprints/.review-signal-<SESSION_ID>`）。

---

<!-- ======================================================= -->
<!-- 平行化邊界：Review subagent 結束，Retro subagent 開始 §3 步驟 1 -->
<!-- Retro subagent §3 步驟 0 已在 Review 進行中平行啟動       -->
<!-- ======================================================= -->

## 3. Sprint Retrospective 流程

記錄 Retro 開始時間：`RETRO_START_TIME=$(date '+%Y-%m-%dT%H:%M+08:00')`

### 步驟

0. **Retrospective Analytics**（**可與 Review 平行執行**）— 角色 prompt：`skills/sprint-review/references/analytics-prompt.md`。僅讀取歷史數據，不依賴 Review 結果。報告完成後等待同步 signal（`docs/sprints/.review-signal-<SESSION_ID>`），signal 到達且報告展示完畢後，才開始步驟 1。
1. **在 `docs/km/retro-log/YYYY-MM-DD-session-<SESSION_ID>.md` 新增記錄**（per-session 檔案，US-322 AC-4）
2. **使用 Good / Problem / Action 格式收集回饋**
3. **SPACE 五維度量測** — 詳見 `references/analytics-prompt.md`
4. **Quality Observer 診斷報告** — 詳見 `references/analytics-prompt.md`
5. **每個 Action 建立為 GitHub Issue（Hard Gate）** — 透過 `issue-management` Skill，標題 `retro:` 前綴，`retro-action` label。**每個 Action 必須在步驟 5 執行期間完成 Issue 建立，取得實際 Issue 編號（#N），不允許標記「待建立」或留空。步驟 5 完成標準：Action Items 清單中每一項均有對應的 GitHub Issue 編號。** 回傳格式：
   ```
   Action Issues 建立清單：
   - [Action 描述] → #N
   - [Action 描述] → #N
   ```
   若任何 Action 無法取得 Issue 編號，步驟 5 **未完成**，必須重試直到所有 Action 均有 Issue 編號。
6. **同步記錄至 `docs/km/retro-log/YYYY-MM-DD-session-<SESSION_ID>.md`**（per-session 檔案，US-322 AC-4）
7. **代理人校準儀式** — 角色 prompt：`skills/sprint-review/references/stakeholder-prompt.md`
8. **寫入 Retro 會議紀錄** — 寫入 `docs/meetings/YYYY-MM-DD-retro.md`（詳見 `references/meeting-format.md`）

## 4. Action Items 驗收機制

GitHub Issues 追蹤（`retro-action` label）：每個 Action 透過 `issue-management` 建 Issue，並取得實際 Issue 編號（#N）；**Retro 結束前，所有 Action 必須有對應 Issue 編號，不得有「待建立」項目**。每次 Sprint Review 前逐項確認：完成 → close；未完成 → `deferred` label；連續兩 Sprint open → 升級 Stakeholder。

---

## 5. 產出文件

| 文件 | 更新內容 |
|------|----------|
| `docs/PROJECT_BOARD.md` | 已完成 Story 移至 Done；更新 Sprint 統計 |
| `docs/km/retro-log/…-session-<ID>.md` | Good / Problem / Action（per-session，US-322 AC-4） |
| `docs/km/metrics-log/…-session-<ID>.md` | Velocity、完成率、趨勢（per-session，US-322 AC-3） |
| `docs/sprints/sprint_N.md` | 各 Story 最終驗收狀態 |
| `docs/prd/ROADMAP.md` | 版本里程碑狀態 |
| `docs/meetings/YYYY-MM-DD-sprint-review.md` | 格式詳見 `references/meeting-format.md` |
| `docs/meetings/YYYY-MM-DD-retro.md` | 格式詳見 `references/meeting-format.md` |

### 5.1 ROADMAP 里程碑對齊檢查

執行時機：產出文件更新完成後、觸發 deployment-readiness 前。讀取 ROADMAP → 逐一核對活躍里程碑 → 完成則 Major bump 候選（需 PO 確認）；未完成則 Minor bump 候選 → 更新狀態 → 結果附帶至 `invoke shikigami:deployment-readiness`。

---

## 6. 歸檔觸發檢查

所有產出文件完成後立即 git commit + push（範圍：`PROJECT_BOARD.md`、retro-log、metrics-log、`sprint_N.md`、`docs/meetings/*.md`；其他 KM 文件不適用，避免觸發 ADR-003 Hard Gate）。

commit + push 完成後清理同步 signal：`rm -f docs/sprints/.review-signal-${CLAUDE_SESSION_ID:-unknown}`

> per-session 路徑：`docs/km/retro-log/$(date '+%Y-%m-%d')-session-${CLAUDE_SESSION_ID:-unknown}.md`（retro）、`docs/km/metrics-log/…`（metrics）。結算腳本：`hooks/retro-settle.sh`、`hooks/metrics-settle.sh`（US-322 AC-3/AC-4）。

---

## 7. 執行檢查清單

### 啟動階段（兩個 subagent 同時啟動）

- [ ] **Systematic Debugging（HARD-GATE）**：Sprint Review 前執行 `invoke shikigami:systematic-debugging`，PASS 後方可繼續
- [ ] **Review subagent 已啟動**（負責 §1.5 + §2）
- [ ] **Retro subagent 已啟動**（負責 §3，步驟 0 立即開始）

### Review subagent Checklist

- [ ] **Pre-Demo 部署驗證**（PASS 或 FAIL）
- [ ] **交付物文案一致性審查**（§1.5 全部 PASS）
- [ ] PO Subagent 已展示所有已完成 Story 的 Demo
- [ ] **QA 邊界案例測試**（§2 步驟 2）：QA 已執行邊界案例測試環節，並產出初步驗證結果
- [ ] **QA 複驗修復有效性（HARD-GATE）**（§2 步驟 2b）：若步驟 2 發現缺陷，Developer 修復後 QA 已執行 targeted regression 複驗，確認缺陷已修復且無 regression。PASS 方可進入步驟 3
- [ ] Stakeholder Subagent 已確認商業期待符合度
- [ ] 通過驗收 Story 已移至 `PROJECT_BOARD.md` Done 欄位
- [ ] `sprint_N.md` Story 狀態欄已回寫最終驗收結果
- [ ] **Story Issue 狀態回寫**（§2.6，HARD-GATE）：按 `references/issue-writeback.md` 操作規則執行；Epic/內部/外部 Issue 分流完成；FAIL Story 已回復 backlog
- [ ] 未達 DoD Story 已移回 Backlog 並標注原因
- [ ] retro-log per-session 檔案已新增記錄；Action Items 已建 GitHub Issue（所有 Action 均有 Issue 編號 #N，無「待建立」）
- [ ] 上個 Sprint `retro-action` Issues 逐項確認；連續兩 Sprint open → 升級 Stakeholder
- [ ] `ROADMAP.md` 已更新
- [ ] **ROADMAP 里程碑對齊檢查**（§5.1）
- [ ] `invoke shikigami:deployment-readiness`（附帶 §5.1 里程碑對齊結果）
- [ ] **E2E 驗證結果已確認**
- [ ] 外部 Issue 階段 2 留言（**僅在 deployment-readiness PASS 且 E2E PASS 後執行**；否則不補發）
- [ ] Sprint Metrics 已計算並追加至 `docs/km/metrics-log/YYYY-MM-DD-session-<SESSION_ID>.md`（詳見 `references/po-review-prompt.md`；US-322 AC-3）
- [ ] 角色制衡案例檢查（若有，更新 `ROLE_BALANCE_CASES.md`）

### Retro subagent Checklist（§3 步驟 0–8 逐項勾選）

- [ ] Analytics 報告完成（步驟 0，平行）；已讀取同步 signal
- [ ] Good / Problem / Action 收集（步驟 1-2）；SPACE 量測（步驟 3）；QO 診斷（步驟 4）
- [ ] 每個 Action 已建 GitHub Issue（步驟 5，**HARD-GATE**）：所有 Action 均有 Issue 編號（#N），無「待建立」；回傳 Action Issues 建立清單（含每項 #N）；retro-log 已同步（步驟 6）
- [ ] 代理人校準儀式（步驟 7）；Retro 會議紀錄寫入（步驟 8）

### 最終收尾（兩個 subagent 均完成後）

- [ ] **產出文件 git commit + push**（HARD-GATE）
- [ ] 同步 signal 已清理（`docs/sprints/.review-signal-<SESSION_ID>`）
- [ ] **Sprint Task cleanup（#538 AC5）**：Sprint Review 完成後，將本 Sprint 的三個 Task 標記為 completed
  ```
  OWNER_REPO=$(git remote get-url origin | sed -E 's#^(https?://[^/]+/|git@[^:]+:)##; s#\.git$##')
  # 標記 planning / execution / review 三個 Task 為 completed
  for PHASE in planning execution review; do
    TASK=$(TaskList | filter subject="${OWNER_REPO}/sprint-${SPRINT_NUM}-${PHASE}")
    if TASK exists: TaskUpdate id=TASK.id status="completed"
  done
  ```
- [ ] **Sprint 後繼續提醒（#538 AC6）**：若有待執行工作（cruise actionable、下一 Sprint 已規劃），建立 continuation reminder Task
  ```
  # 檢查是否有下一 Sprint 或 cruise actionable
  NEXT_SPRINT_ISSUES=$(gh issue list --label "sprint-candidate" --limit 5 --json number,title 2>/dev/null || echo "[]")
  if NEXT_SPRINT_ISSUES is not empty OR cruise_actionable_detected:
    TaskCreate subject="${OWNER_REPO}/sprint-${SPRINT_NUM}-done-next-action" status="in-progress"
    # subject 清楚告知 compact 後該做什麼
    # 範例：kctw-dev/shikigami/sprint-129-done-next-action
    # agent compact 後看到此 Task 即知道要繼續 Sprint Planning 或 Cruise
  ```
