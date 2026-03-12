---
name: sprint-review
description: "Use when sprint ends, conducting sprint review and retrospective, or evaluating sprint outcomes"
---

# Sprint Review & Retrospective

## 1. 概述

Sprint Review + Retrospective 是 Sprint 的結束儀式，用於 **驗收成果** 和 **持續改進**。

- **Sprint Review**：展示本 Sprint 的可運行成果，確認是否達成 Sprint Goal。
- **Sprint Retrospective**：團隊回顧流程與協作，找出改進行動。

兩個活動依序進行，產出的文件將直接影響下個 Sprint 的規劃。

---

## 1.1 快思/慢想模式

Sprint Review 支援兩種執行模式，依 Velocity 或使用者指定決定深度：

### 快思模式

- **觸發條件**：Velocity < 3 pts，或使用者傳入 `/fast` flag，或明確說「快速 Review」
- **跳過或縮短的步驟**：
  - 跳過 Token 成本摘要（§7 最後兩項 Token 相關檢查清單）
  - 歸檔觸發檢查：僅在超過門檻時才執行，否則跳過
- **執行流程**：交付物一致性審查 → Demo 驗收 → Retrospective Analytics → Retrospective 記錄 → 文件更新 → Commit

### 慢想模式

- **觸發條件**：Velocity >= 3 pts，或使用者傳入 `--deep` 參數，或明確說「完整 Review」
- **執行流程**：交付物一致性審查 → Demo 驗收 → Retrospective Analytics → Retrospective 記錄 → 文件更新 → Token 成本記錄 → 歸檔觸發檢查 → Commit

---

## 模型選用建議

> **Sprint Review 的 subagent 依角色複雜度分層使用不同模型。**
>
> | 角色 / 步驟 | 模型 | 說明 |
> |------------|------|------|
> | PO Subagent（Demo 展示、AC 驗收） | `sonnet` | 需要情境理解與商業判斷 |
> | Stakeholder Subagent（商業期待確認） | `sonnet` | 需要情境理解與商業判斷 |
> | Analytics Subagent（§3 步驟 0 趨勢分析） | `haiku` | 統計分析，規則明確可程式化 |
> | Metrics Subagent（Sprint Metrics + Token 成本） | `haiku` | 數值計算，規則明確可程式化 |
> | 歸檔 Subagent（§6 Sprint 歸檔） | `haiku` | 文件剪貼操作，不需推理 |
>
> 使用者無需手動切換模型，框架在派遣 subagent 時自動指定。

---

## 1.3 合約載入（US-204）

<!-- US-204 統一合約位置 — Sprint 82 -->

Sprint Review 開始前，Review 主 session 須載入相關的共用交付合約，作為驗收基準。

### 載入指令

```
Read: contracts/README.md
Read: contracts/sow-delivery-contract.md        （若本 Sprint 有 SOW 相關 Story）
Read: contracts/numerical-consistency-contract.md（若本 Sprint 有數值修改 Story）
```

### 載入時機

| 情境 | 須載入的合約 |
|------|------------|
| Sprint Review 中驗收含 SOW 交付物的 Story | `contracts/sow-delivery-contract.md` |
| Sprint Review 中驗收含 Metrics、Points 數值更新的 Story | `contracts/numerical-consistency-contract.md` |
| PO Subagent Demo 驗收前（含跨文件一致性審查） | `contracts/numerical-consistency-contract.md` |

### 注意事項

- 合約載入為**Sprint Review 流程開始後、§1.5 交付物文案一致性審查前**執行
- 合約的「檢查清單」可作為 §1.5 跨文件一致性審查的補充基準
- 合約完整定義位於 `contracts/` 目錄，SKILL.md 中僅記錄載入步驟

---

## 1.5 交付物文案一致性審查（Sprint Review 前執行）

<!-- US-86：回應 Sprint 38-40 連續 Retro Problem — Issue #81 -->
<!-- ADR-003 合規：此子節依 ADR-003 Hard Gate 規範，於 Sprint 41 US-86 授權修改 -->

### 根因說明與預防措施

Sprint 38、39、40 連續三個 Retrospective 均發現「交付物文案不一致」問題，根因分析如下：

- **根因**：各 Story 的 Sprint Review 文件、PROJECT_BOARD.md、sprint_N.md、ROADMAP.md 等多文件並行更新時，跨文件的術語（如 Story 狀態標注、Issue 連結、版本號）未經統一審查即提交，導致不同文件間出現不一致。
- **預防措施**：在 Sprint Review 正式開始前（Demo 展示前），強制執行「交付物文案一致性審查」，確保所有交付物在展示前已達到跨文件一致性。

### 審查觸發時機

**執行時機**：Sprint Review 流程開始後、PO Subagent 展示 Demo 前（§2 步驟 1 之前）。此審查為 Done 定義的一部分，未通過審查前不得宣告 Sprint 完成。

### 審查 Checklist

執行主 session 依序完成以下審查項目：

**一、跨文件術語一致性**

- [ ] `docs/sprints/sprint_N.md` 中各 Story 的狀態標注（進行中 / 完成 / 未完成）與 `docs/PROJECT_BOARD.md` 中相同 Story 的狀態欄一致
- [ ] `docs/prd/ROADMAP.md` 中里程碑描述的術語與 Sprint Backlog 中 Story 標題一致（例如：功能名稱、版本號描述不得有差異）
- [ ] `docs/prd/PRODUCT_BACKLOG.md` 中已完成 Story 的狀態已移至 `docs/prd/BACKLOG_DONE.md`，兩文件間無重複或遺漏

**二、狀態標注一致性**

- [ ] Sprint Backlog 表格中每筆 Story 的「狀態」欄使用統一術語（「完成」、「進行中」、「未完成」三選一，不得混用「Done」、「PASS」等英文術語）
- [ ] `docs/PROJECT_BOARD.md` 中 Sprint 進行中 / 完成的區塊劃分與實際 Sprint 狀態相符
- [ ] 若有 Story 狀態為「未完成」，`docs/prd/PRODUCT_BACKLOG.md` 中已有對應的回填記錄（含未達標原因）

**三、Issue 連結有效性**

- [ ] `docs/sprints/sprint_N.md` Sprint Backlog 表格中各 Story 的 Issue # 欄位填寫完整（非空白）
- [ ] 對應的 GitHub Issue 存在且狀態符合預期：進行中 Story 的 Issue 應為 open；完成 Story 的 Issue 應已執行 §2.6 關閉流程
- [ ] Retrospective Log 中 Action Items 的 Issue 連結（若有）均指向存在的 GitHub Issue

**四、版本與里程碑一致性**

- [ ] `docs/prd/ROADMAP.md` 里程碑狀態與本 Sprint 交付進度相符（已完成里程碑已標注完成 Sprint）
- [ ] 若本 Sprint 有版本 Tag 操作（deployment-readiness 執行後），版本號在 ROADMAP 與 `docs/PROJECT_BOARD.md` 中的描述一致

**五、CI 狀態確認**

- [ ] CI 最新 run 狀態為 PASS（執行 `gh run list --limit 1 --json conclusion` 確認最新 conclusion 為 `success`；若 CI FAIL 則在進入 Demo 前先處理 CI 失敗）

### 審查結果記錄

審查完成後，在主 session 中輸出以下格式的審查摘要：

```
## 交付物文案一致性審查結果（Sprint N）

審查時間：YYYY-MM-DD
審查狀態：PASS / FAIL

不一致項目（若有）：
- [文件路徑]：[具體不一致描述]

修正動作（若有）：
- [已執行的修正描述]
```

**FAIL 處理**：若發現任何不一致，立即修正後重新勾選對應項目，確認全部 PASS 後才進入 §2 Sprint Review 流程。

---

## 2. Sprint Review 流程

Sprint Review 的目的是驗收本 Sprint 交付的成果，確認是否符合商業期待。

### Pre-Demo 部署驗證（Demo 展示前必要前置條件）

<!-- US-187：回應 Sprint Review 缺少生產環境部署驗證步驟 — Issue #179 -->

在 PO Subagent 展示 Demo 前，執行主 session 須確認生產環境已部署最新代碼，確保 Stakeholder 看到的是最新版本。

#### 驗證步驟

1. **取得最新 commit hash**

   ```bash
   git log --oneline -1
   ```

   記錄輸出的 commit hash（例：`abc1234 feat: 更新功能 X`）。

2. **確認生產環境部署狀態（Cloud Run）**

   若專案有 Cloud Run 部署，執行以下指令確認生產環境 image 包含最新 commit：

   ```bash
   # 確認最後部署時間是否晚於最後 Story commit 時間
   gcloud run services describe <SERVICE_NAME> --region=<REGION> \
     --format="value(status.conditions[0].lastTransitionTime,spec.template.metadata.annotations)"
   ```

   **判斷標準**：滿足以下任一條件即視為部署已完成：
   - 生產環境 image digest 包含最新 commit hash
   - 最後部署時間晚於 `git log --oneline -1` 對應 commit 的時間戳

3. **未部署時自動觸發部署**

   若確認生產環境未部署最新代碼，**在 Demo 展示前**先觸發 `deployment-readiness` skill 確保 Demo 基於最新代碼：

   ```
   觸發 deployment-readiness：確保 <最新 commit hash> 已部署至生產環境後再執行 Sprint Review Demo
   ```

   等待 `deployment-readiness` 完成並確認部署成功後，才進入步驟 1（PO Subagent Demo）。

#### 驗證結果輸出格式

```
## Pre-Demo 部署驗證結果

最新 commit：<hash> <訊息>
Cloud Run 部署狀態：已部署 / 未部署 / 不適用（無 Cloud Run）
最後部署時間：YYYY-MM-DDTHH:MM:SSZ（若適用）
驗證結論：PASS（可進行 Demo）/ FAIL（已觸發 deployment-readiness，等待完成）
```

> **注意**：若專案無 Cloud Run 部署，跳過步驟 2，直接輸出「不適用（無 Cloud Run）」並繼續。

---

### 步驟

1. **PO Subagent 展示 Demo 結果**
   - PO subagent prompt 中指定 `docs/sprints/sprint_N.md` 完整路徑，由 **PO subagent 自行讀取** Sprint 成果內容；**主 session 不直接讀取 sprint_N.md**
   - **【源碼路徑】** PO subagent 驗收 Story 時，須從 **repo working directory**（即 `skills/` 目錄下的實際檔案）讀取最新源碼，例如：讀取 `skills/sprint-review/SKILL.md` 應使用 working directory 下的完整絕對路徑
   - **【禁止項】** 不得依賴 plugin cache 版本。plugin cache 可能快取已過期的舊版本，若以 cache 版本驗收，將導致誤判「已完成」的 Story 為 FAIL
   - 針對每個已完成的 User Story，展示可運行的功能
   - Demo 應基於實際程式碼執行結果，而非文件描述
   - 逐一對照 Acceptance Criteria 確認通過狀態

2. **Stakeholder Subagent 確認商業期待**
   - Stakeholder subagent prompt 中指定 `docs/sprints/sprint_N.md` 完整路徑，由 **Stakeholder subagent 自行讀取** Sprint 成果；**主 session 不直接讀取 sprint_N.md**
   - 檢視 Demo 結果是否符合原始商業需求
   - 確認交付物是否達到預期的商業價值
   - 提出回饋意見或調整方向

3. **更新 `docs/PROJECT_BOARD.md`（已完成欄位）**
   - 將通過驗收的 Story 移至「Done」欄位
   - 記錄完成日期與 Sprint 編號
   - 更新 Sprint 統計數據（Velocity、完成率）

   **輸出格式規範**：Done 欄位每筆 Story 需包含以下欄位：

   ```markdown
   | Story ID | 標題 | Sprint | 完成日期 | Points |
   |----------|------|--------|----------|--------|
   | US-XX    | 功能標題 | Sprint N | YYYY-MM-DD | X |
   ```

   **Sprint 統計欄位**（PROJECT_BOARD.md 頂部或底部統計區塊）更新格式：

   ```markdown
   ## Sprint N 統計
   - Velocity：X points
   - 完成率：X%（完成 Y / 計畫 Z）
   - 日期：YYYY-MM-DD
   ```

4. **未達 DoD 的 Story 處理**
   - 未通過 Definition of Done 的 Story 移回 Backlog
   - 必須標注未達標的具體原因（例：測試未通過、安全驗證失敗、文件未更新）
   - PO Subagent 重新評估優先級，決定是否納入下個 Sprint

5. **回寫 `docs/sprints/sprint_N.md` Story 最終狀態**
   - 目標路徑：`docs/sprints/sprint_N.md`（N 為本 Sprint 編號）
   - 將 Sprint Backlog 表格中每個 Story 的「狀態」欄更新為最終驗收結果

   **操作步驟**：
   1. 讀取 `docs/sprints/sprint_N.md` 的 Sprint Backlog 表格
   2. 依 PO Subagent 驗收結果，逐一更新每筆 Story 的狀態欄：
      - 通過驗收 → 狀態改為「完成」
      - 未通過 DoD → 狀態改為「未完成」，並在備注欄補充未達標原因
   3. 若 Sprint 備注欄不存在，在狀態欄括號內簡記原因，例如：「未完成（測試未通過）」

   **必要輸出格式**（Sprint Backlog 表格更新後格式）：

   ```markdown
   | Story ID | 標題 | Size | Points | 狀態 |
   |----------|------|------|--------|------|
   | US-XX    | 功能標題 | S | 1 | 完成 |
   | US-YY    | 另一功能 | M | 2 | 未完成（測試未通過） |
   ```

   **注意**：sprint_N.md 狀態回寫需在 PROJECT_BOARD.md 更新完成後執行，確保兩處狀態一致。

---

## 2.5 Sprint 外完成項目掃描（/shoot 短衝記錄）

Sprint Review 進行時，掃描 `docs/km/Shoot_Log.md` 取得本 Sprint 期間的短衝記錄，列入「Sprint 外完成項目」區塊。

### 掃描步驟

1. 檢查 `docs/km/Shoot_Log.md` 是否存在
2. 若存在，篩選本 Sprint 期間（依日期欄位）且結果為 `PASS` 的記錄
3. 列出所有符合條件的短衝記錄

### 輸出格式

**有短衝記錄時**：

```markdown
## Sprint 外完成項目（/shoot 短衝記錄）

| 日期 | 來源 | 標題 | commit hash |
|------|------|------|-------------|
| YYYY-MM-DD | direct | 修復登入頁面 CORS 問題 | abc1234 |
| YYYY-MM-DD | #42 | 更新文件錯字 | def5678 |
```

**無短衝記錄時**：

```
本 Sprint 無短衝記錄
```

### 計入規則

- 短衝記錄**不計入 Velocity**（不影響 Sprint Points 統計）
- 短衝記錄僅作為「Sprint 外完成項目」附加呈現
- `docs/km/Shoot_Log.md` 不存在時，直接輸出「本 Sprint 無短衝記錄」，不視為錯誤

---

## 2.6 Story Issue 狀態回寫（ADR-010 生命週期閉環）

Story 驗收判定完成後，須依判定結果回寫對應 GitHub Issue 的狀態。此步驟在 §2 步驟 5（回寫 sprint_N.md 狀態）**之後**、§3 Retrospective **之前**執行。

### 前提

本節適用於以 GitHub Issue 形式管理的 Backlog Stories（ADR-010 體系）。Story 的 GitHub Issue 編號從 `docs/sprints/sprint_N.md` 中各 Story 的「Issue」欄位取得（或從 Issue 標題比對取得）。

### 操作規則

| 驗收判定 | Issue 操作 | 說明 |
|---------|-----------|------|
| Story PASS（已完成） | 依 Issue 建立者判斷（見下方「Issue 建立者判斷」）執行對應操作 | 內部 Issue 自動關閉；外部 Issue 保持 Open，僅加 label + 留言 |
| Story FAIL（未完成） | Issue 保持 open，不執行任何關閉操作 | 未完成的 Story 回流 Backlog，Issue 維持 open 狀態等待下次 Sprint 選取 |

### Issue 建立者判斷

Story PASS 時，在執行任何操作前，必須先判斷 Issue 的建立者類型：

**判斷方式：**

```bash
# 查詢 Issue 建立者
gh issue view <issue-number> --json author --jq '.author.login'
```

**內部 Issue（自動建立）定義：** 滿足以下任一條件即視為內部 Issue：
- Issue 建立者 login 為 `github-actions[bot]`
- Issue body 含有 `backlog-intake` 字串（由 backlog-intake workflow 自動建立的標記）

**外部 Issue（Stakeholder 建立）定義：** 不符合上述任一內部條件的 Issue，一律視為外部 Issue。

### Story PASS — 操作步驟

根據 Issue 建立者判斷結果，執行對應操作：

**情況一：內部 Issue（建立者為 `github-actions[bot]` 或 body 含 `backlog-intake`）**

維持現行邏輯，自動關閉 Issue：

```bash
# 步驟 1：套用 done label 並移除 in-sprint label
gh issue edit <issue-number> --add-label "done" --remove-label "status: in-sprint"

# 步驟 2：關閉 Issue，留言記錄完成 Sprint
gh issue close <issue-number> -c "Sprint N Review 驗收通過（PASS）。Story 已完成交付。"
```

**情況二：外部 Issue（Stakeholder 或其他外部使用者建立）**

Issue 保持 Open，僅加 label 並留言通知，等待 Stakeholder 確認後自行關閉：

```bash
# 步驟 1：套用 done label 並移除 in-sprint label
gh issue edit <issue-number> --add-label "done" --remove-label "status: in-sprint"

# 步驟 2：留言通知，Issue 保持 Open（不執行 gh issue close）
gh issue comment <issue-number> --body "Sprint N Review 驗收通過（PASS）。程式碼已完成內部審查，待部署驗證後正式交付。"
```

> **重要**：外部 Issue 不得執行 `gh issue close`。Issue 保持 Open 讓外部 Stakeholder 有機會在測試確認後自行關閉，避免在其尚未驗證前強制關閉。

**情況二（階段 2）：部署驗證通過後**

部署驗證完成（`deployment-readiness` 執行成功）後，對外部 Issue 補充留言：

```bash
# 部署驗證通過後，對外部 Issue 發送階段 2 通知
gh issue comment <issue-number> --body "已通過端對端驗證，功能已正式交付。請測試確認後關閉此 Issue。"
```

### Story FAIL — 操作步驟

對每個未通過驗收（FAIL）的 Story，Issue **保持 open**，執行以下操作：

```bash
# 移除 in-sprint label，回復 backlog 狀態（等待下次 Sprint 選取）
gh issue edit <issue-number> --remove-label "status: in-sprint" --add-label "status: backlog"

# 留言記錄未完成原因（保持 open 狀態）
gh issue comment <issue-number> --body "Sprint N Review 驗收未通過（FAIL）：[未達標原因]。Issue 保持 open，等待下次 Sprint 選取。"
```

> **重要**：Story FAIL 時 Issue **不得關閉**。open 狀態確保此 Story 在下次 Sprint Planning 的 `gh issue list --label "status: backlog"` 查詢中可見，能被重新納入 Sprint。

### 操作格式一致性

label 操作格式與 `skills/sprint-planning/SKILL.md` §5 保持一致，均使用 `gh issue edit --add-label / --remove-label` 單行指令格式。

---

## 3. Sprint Retrospective 流程

Sprint Retrospective 的目的是團隊自省，找出可改進之處並制定具體行動。

### 步驟

0. **Retrospective Analytics — 展示歷史趨勢分析報告**

   **觸發時機**：Retrospective 開始時第一步執行，**報告展示完畢前不得開始收集 Good / Problem / Action**。

   **指令**：派遣 Analytics subagent（`model: "haiku"`），在 prompt 中指定 `docs/km/Retrospective_Log.md` 完整路徑，由 **Analytics subagent 自行讀取**該檔案，依下列規則分析並回傳完整報告。**主 session 不直接讀取 Retrospective_Log.md**，僅接收 subagent 回傳的分析報告。

   #### 前置檢查

   - 若 `docs/km/Retrospective_Log.md` **不存在**：輸出「尚無 Retrospective 記錄」，正常結束 Analytics，繼續進行步驟 1。
   - 若檔案存在但只有 **1 個 Sprint 記錄**：頻率統計區塊輸出「資料不足（需至少 2 個 Sprint）」；Action Items 關閉速度與待關閉 Items 區塊正常計算輸出。

   #### 報告格式（四區塊，缺一不可）

   輸出標題格式如下，四個區塊依序呈現：

   ```
   ## Retrospective Analytics 報告（Sprint N 前）

   ### ① Good 趨勢

   ### ② Problem 趨勢

   ### ③ Action Items 關閉速度

   ### ④ 待關閉 Items
   ```

   #### ① Good 趨勢 — 分析規則

   1. 讀取所有 Sprint 的 `### Good` 區塊，逐條提取 Good 條列。
   2. 以**語義主題**為單位歸類（關鍵字相近即視為同一主題，不要求精確字串比對）。
   3. 出現 **2 次以上**的主題，輸出：
      - 主題關鍵字（簡短描述）
      - 出現次數
      - 最近出現的 Sprint 編號
   4. 無重複主題時，輸出「無重複 Good 趨勢」。

   範例輸出：
   ```
   - **QA 審查品質**：出現 2 次（最近：Sprint 3）
   - **角色制衡有效**：出現 2 次（最近：Sprint 2）
   ```

   #### ② Problem 趨勢 — 分析規則

   1. 讀取所有 Sprint 的 `### Problem` 區塊，逐條提取 Problem 條列。
   2. 以**語義主題**為單位歸類（關鍵字相近即視為同一主題）。
   3. 出現 **2 次以上**的主題，輸出：
      - 主題關鍵字（簡短描述）
      - 出現次數
      - 首次出現的 Sprint 編號
      - 最近出現的 Sprint 編號
      - 若「未解決」（定義：重複出現且最近一次無對應 Closed Action Item）：加上「跨 N 個 Sprint 未解決」
   4. **連續出現**判斷與警示：
      - **連續情境**（最近一次仍在最新的 Sprint 出現，且間無中斷）：醒目標注 `> ⚠️ **重複問題（連續 N 個 Sprint）**`
      - **間斷情境**（中間有 Sprint 未出現，或最近一次不是最新 Sprint）：輸出「曾連續 N 個 Sprint（Sprint X-Y）」，說明是否已解決，**不觸發醒目警示**
   5. 無重複主題時，輸出「無重複 Problem 趨勢」。

   範例輸出（連續情境）：
   ```
   - **ROADMAP 與 Backlog 不同步**：出現 2 次（首次：Sprint 2，最近：Sprint 3）
     > ⚠️ **重複問題（連續 2 個 Sprint）**
   ```

   範例輸出（間斷情境）：
   ```
   - **Sprint Review 自動觸發**：出現 2 次（首次：Sprint 1，最近：Sprint 2）
     曾連續 2 個 Sprint（Sprint 1-2），已於 Sprint 3 關閉
   ```

   #### ③ Action Items 關閉速度 — 分析規則

   1. 讀取所有 Sprint 的 `### Action Items` 表格，收集所有 Action Item。
   2. 對每個 Closed Item，計算**關閉速度** = 關閉 Sprint 編號 − 建立 Sprint 編號（Sprint 數差）。
   3. 輸出：
      - 平均關閉速度（Sprint 數，四捨五入至一位小數）
      - 最快關閉速度（Sprint 數 + 對應 Item 簡述）
      - 最慢關閉速度（Sprint 數 + 對應 Item 簡述）
   4. 若無任何 Closed Item，輸出「尚無已關閉 Action Item」。
   5. 對所有 **Open** 狀態的 Item，計算逾期 Sprint 數 = 目前 Sprint 編號 − 建立 Sprint 編號，並標注「逾期 N 個 Sprint」。

   範例輸出：
   ```
   - 平均關閉速度：1.0 個 Sprint
   - 最快：1 個 Sprint（Action：不阻塞原則強化，Sprint 1 建立，Sprint 2 關閉）
   - 最慢：2 個 Sprint（Action：Sprint Review 自動觸發，Sprint 1 建立，Sprint 3 關閉）
   ```

   #### ④ 待關閉 Items — 分析規則

   1. 列出所有狀態為 **Open**（非 Closed）的 Action Item。
   2. 每個 Item 輸出：
      - Item 內容（Action 欄）
      - Owner
      - 建立 Sprint
      - 逾期 Sprint 數
   3. 無 Open Item 時，輸出「目前無待關閉 Action Items」。

   範例輸出：
   ```
   | Action | Owner | 建立 Sprint | 逾期 |
   |--------|-------|-------------|------|
   | Health Check 自動掛鉤 | Developer | Sprint 2 | 逾期 1 個 Sprint |
   ```

   ---

1. **在 `docs/km/Retrospective_Log.md` 新增記錄**
   - 以 Sprint 編號為標題新增一筆記錄
   - 記錄日期與參與角色

2. **使用 Good / Problem / Action 格式**

   | 分類 | 說明 | 範例 |
   |------|------|------|
   | **Good**（保持做的事） | 本 Sprint 中做得好、值得繼續保持的實踐 | TDD 流程順暢、ADR 文件品質提升 |
   | **Problem**（需改進的事） | 遇到的問題、瓶頸或不順暢的地方 | Story 拆分粒度太大、安全審查太晚介入 |
   | **Action**（具體改進行動） | 針對 Problem 提出的可執行改善措施 | 下 Sprint 起 Story 點數上限設為 5 |

3. **每個 Action 建立為 GitHub Issue**

   透過 `issue-management` Skill 將每個 Action Item 建立為 GitHub Issue，方便追蹤：

   ```bash
   gh issue create --title "retro: Story 拆分粒度控制在 5 點以內" \
     --body "**來源**：Sprint N Retrospective\n**Owner**：PO\n**驗收方式**：下 Sprint Planning 時檢查" \
     --label "retro-action"
   ```

   **命名規則**：Issue 標題以 `retro:` 前綴，統一套用 `retro-action` label。

4. **同步記錄至 `docs/km/Retrospective_Log.md`**

   在 Retrospective Log 中記錄 Action Items 與對應的 Issue 編號：

   ```markdown
   ### Action Items

   | # | Action | Owner | 驗收方式 | Issue |
   |---|--------|-------|----------|-------|
   | 1 | Story 拆分粒度控制在 5 點以內 | PO | 下 Sprint Planning 時檢查 | #15 |
   | 2 | 安全審查提前至設計階段 | Security Engineer | 下 Sprint 有 Security Review 紀錄 | #16 |
   ```

5. **代理人校準儀式**

   **執行時機**：步驟 4（同步記錄至 `docs/km/Retrospective_Log.md`）完成後，Retrospective 結束前執行。

   **目的**：定期審查 Agent 對 Stakeholder 核心價值觀的理解，偵測語義漂移，確保代理人行為持續對齊 Stakeholder 意圖。

   **子步驟**：

   (a) **Agent 列出歸納的 Stakeholder 三個核心價值觀**
      - Agent 依本 Sprint 互動記錄與歷史 Retrospective，歸納 Stakeholder 最重視的三個核心價值觀，以條列方式呈現，例如：
        1. 交付速度優先於零風險保證
        2. 文件即代碼，文件品質等同程式品質
        3. 系統性除錯優先於快速補丁

   (b) **Agent 列出本 Sprint 最重要的一個決策及其依據**
      - Agent 指出本 Sprint 中最具代表性的一個決策（技術選型、流程調整、優先級取捨等），並說明做出此決策的理由與依據。

   (c) **Stakeholder 確認或修正**
      - Stakeholder 逐一審閱 (a) 列出的三個價值觀與 (b) 的決策依據。
      - **漂移偵測判定標準**：
        - Stakeholder 修正任一項價值觀描述 → **偵測到漂移**
        - 三項均確認無修正 → **無漂移**
      - 若判定為**偵測到漂移**，將差異點寫入 `docs/km/Decision_Journal.md`，依 US-219 AC2 格式建立新記錄，情境欄位標注「來源：Sprint N 校準儀式」。
      - 校準結果（含漂移判定與修正內容）記錄至 `docs/km/Calibration_Log.md`，格式為 H3 區塊（`### Sprint N 校準記錄`），必要欄位：`**日期**`、`**Agent 歸納的價值觀**`（條列三項）、`**Stakeholder 修正**`、`**漂移判定**`。

---

## 4. Action Items 驗收機制

Action Items 透過 **GitHub Issues** 追蹤（`retro-action` label），具備完整的生命週期管理。

### 規則

1. **建立為 GitHub Issue**
   - 每個 Action Item 透過 `issue-management` 建立為 Issue
   - 標題格式：`retro: [行動描述]`
   - Label：`retro-action`
   - Body 包含：來源 Sprint、Owner、驗收方式

2. **Sprint Review 時逐項檢查**
   - 每次 Sprint Review 開始前，列出所有 open 的 `retro-action` Issues：
     ```bash
     gh issue list --label "retro-action" --state open
     ```
   - 逐項確認執行狀況

3. **結論判定**
   - **已完成** → 執行 `gh issue close -c "Sprint N 驗收通過：[結論描述]"` 關閉 Issue 並留言記錄結論
   - **未完成** → 保持 open，執行 `gh issue edit --add-label deferred` 加上 `deferred` label

4. **升級機制**
   - 連續兩個 Sprint 仍為 open 的 `retro-action` Issue 自動升級至 Stakeholder
   - Stakeholder 決定：強制執行、調整方案、或關閉（`not planned`）

### 狀態流轉

```
gh issue create (retro-action)
  → Open
    → gh issue close (已完成驗收)
    → 加 deferred label（延遲一個 Sprint）
      → gh issue close（第二個 Sprint 完成驗收）
      → 升級至 Stakeholder（連續兩個 Sprint 未關閉）
```

---

## 5. 產出文件

Sprint Review & Retrospective 完成後，必須更新以下文件：

| 文件 | 更新內容 |
|------|----------|
| `docs/PROJECT_BOARD.md` | 已完成 Story 移至 Done 欄位；更新 Sprint 統計 |
| `docs/km/Retrospective_Log.md` | 新增本 Sprint 的 Good / Problem / Action 記錄 |
| `docs/km/Metrics_Log.md` | 追加本 Sprint Velocity、完成率、趨勢分析記錄 |
| `docs/prd/PRODUCT_BACKLOG.md` | 未完成 Story 回填至 Backlog，標注未達標原因與重新排序 |
| `docs/prd/BACKLOG_DONE.md` | 已完成 Story 從 Backlog 移至此處，按 Sprint 歸檔，保留完整 RICE 評分與 AC |
| `docs/sprints/sprint_N.md` | 回寫 Sprint Backlog 表格中各 Story 最終驗收狀態（完成 / 未完成）|
| `docs/prd/ROADMAP.md` | 更新版本里程碑狀態（進行中/已完成），反映本 Sprint 交付進度；確認版本 Tag 與里程碑一致 |

### ROADMAP 更新操作指引

**目標路徑**：`docs/prd/ROADMAP.md`

**操作步驟**：

1. 讀取 `docs/prd/ROADMAP.md` 的版本里程碑區塊（通常格式為 `## MX — 版本描述`）
2. 找到本 Sprint 對應的里程碑區塊（若有）
3. 依本 Sprint 交付成果更新狀態：
   - 本 Sprint 交付的 Story 條目，將狀態標注改為「已完成」或補充 Sprint 完成記錄
   - 若里程碑下所有 Story 均已完成，將里程碑狀態改為「已完成（Sprint N）」
   - 若里程碑仍有未完成項目，保持「進行中」並更新完成進度描述

4. **版本 Tag 與 ROADMAP 里程碑對齊檢查**（必要步驟）：
   - 確認 `deployment-readiness` 產生的版本 Tag（例：`v0.X.Y`）與 ROADMAP 里程碑版本號一致
   - 若版本 Tag 對應里程碑首次達成（例：vX.0.0 的里程碑 MX 全部完成），在 ROADMAP 對應里程碑標注：「達成版本：vX.0.0（Sprint N）」
   - 若版本 Tag 為 Patch 版本（vX.Y.Z，Z > 0），不需更新里程碑完成狀態，僅在對應里程碑的備注欄追加：「修訂記錄：vX.Y.Z（Sprint N）」

**必要輸出格式**（里程碑狀態更新後格式）：

```markdown
## MX — 里程碑標題

**狀態**：已完成（Sprint N）/ 進行中

| Story ID | 標題 | 狀態 | 完成 Sprint |
|----------|------|------|-------------|
| US-XX    | 功能標題 | 已完成 | Sprint N |
| US-YY    | 另一功能 | 進行中 | — |
```

若里程碑無表格格式，至少確保里程碑標題下方有狀態行與版本 Tag 對齊記錄。

---

## 5.1 ROADMAP 里程碑對齊檢查

本子節定義「觸發 deployment-readiness 前」必須執行的 ROADMAP 里程碑對齊檢查。此步驟的輸出決定 deployment-readiness 的版本 Tag 決策類型（Major bump 或 Minor bump）。

### 執行時機

執行時機：**產出文件更新完成後、觸發 deployment-readiness 前**。

### 執行步驟

1. **讀取 `docs/prd/ROADMAP.md`**，確認各里程碑當前狀態

2. **逐一檢查活躍里程碑的完成狀態**：
   - 找出狀態為「進行中」的里程碑
   - 對照本 Sprint 交付的 Stories，確認這些 Stories 是否為該里程碑的最後缺口
   - 若里程碑下的所有 Stories 均已標記完成，則該里程碑達成完成狀態

3. **判斷是否有里程碑因本 Sprint 交付而完成**：

   ```
   里程碑完成？
     ├── 否 → 版本 Tag 決策類型：Minor bump 候選
     │         傳達給 deployment-readiness：「本 Sprint 無里程碑完成，建議 Minor bump」
     └── 是 → 向 PO 確認里程碑完成
               ├── PO 確認 → 版本 Tag 決策類型：Major bump 候選
               │            傳達給 deployment-readiness：「里程碑 MX 完成，PO 確認，建議 Major bump」
               └── PO 未確認 → 版本 Tag 決策類型：Minor bump 候選
                              傳達給 deployment-readiness：「里程碑 MX 完成但 PO 未確認，建議 Minor bump」
   ```

4. **更新 `docs/prd/ROADMAP.md` 里程碑狀態**（若里程碑完成）：
   - 將里程碑狀態改為「已完成（Sprint N）」
   - 補充版本 Tag 對齊記錄（格式見 §5 ROADMAP 更新操作指引）

5. **將對齊檢查結果附帶至 deployment-readiness 觸發指令**：
   - 明確傳達「Major bump 候選」或「Minor bump 候選」判斷結果
   - deployment-readiness 依此結果套用 `skills/deployment-readiness/SKILL.md` §4 版本 Tag 決策規則

### 輸出格式

執行里程碑對齊檢查後，輸出以下格式的摘要：

```
## ROADMAP 里程碑對齊檢查結果（Sprint N）

檢查時間：YYYY-MM-DD
活躍里程碑：MX — <里程碑標題>

本 Sprint 交付 Stories：
- US-XX（已完成）— 屬於 MX
- US-YY（已完成）— 屬於 MX

MX 完成狀態：
- 已完成 Stories：N / 總計 M
- 未完成 Stories：（若有，列出）
- 里程碑完成：是 / 否

版本 Tag 決策類型：Major bump 候選 / Minor bump 候選
傳達給 deployment-readiness：<決策說明>
```

---

## 6. 歸檔觸發檢查

Sprint Review 完成、產出文件更新後，**派遣 subagent（`model: "haiku"`）** 執行歸檔觸發檢查與歸檔操作。主 session 僅接收歸檔結果摘要（歸檔了哪些 Sprint、更新了哪些文件），不直接操作歸檔文件。

### 觸發條件

- `docs/PROJECT_BOARD.md` 中已完成的歷史 Sprint 區塊（不含當前進行中 Sprint）超過 **5 個**
- 或 `docs/km/Retrospective_Log.md` 中的 Sprint 記錄（含歸檔連結行以外的記錄）超過 **5 個**
- 或 `docs/prd/BACKLOG_DONE.md` 中的歷史 Sprint 區塊（`## Sprint N` 標頭數量）超過 **5 個**

滿足任一條件即觸發歸檔作業。

### 歸檔規則

- **保留範圍**：以當次 Sprint Review 為基準，保留**當前 Sprint + 最近 2 個 Sprint**的完整記錄
- **移出範圍**：超出保留範圍的**所有**歷史 Sprint 記錄**一次性**移至對應歸檔文件（批量歸檔）

### 歸檔目標路徑

| 文件 | 歸檔目標 |
|------|----------|
| `docs/PROJECT_BOARD.md` | `docs/km/archive/PROJECT_BOARD_ARCHIVE.md` |
| `docs/km/Retrospective_Log.md` | `docs/km/archive/RETRO_ARCHIVE.md` |
| `docs/prd/BACKLOG_DONE.md` | `docs/km/archive/BACKLOG_DONE_ARCHIVE.md` |

### 歸檔操作（由 subagent 執行）

1. 計算超出保留範圍的 Sprint 數量（總數 - 3）
2. 從主文件剪下所有超出保留範圍的 Sprint 完整區塊（保持原始格式不變，按 Sprint 編號升序排列）
3. 附加至對應歸檔文件末尾
4. 確認主文件底部有歸檔連結（`PROJECT_BOARD.md`）或頂部有歸檔連結（`Retrospective_Log.md`）
5. 更新 `docs/km/archive/README.md` 的歸檔範圍欄位與最後更新日期
6. 回傳摘要給主 session：歸檔了 Sprint X–Y 共 N 個、更新了哪些文件

---

## 7. 執行檢查清單

> **模式選擇**：依 §1.1 說明，執行前先確認當前模式為**快思模式**或**慢想模式**。標注 *(慢想模式限定)* 的項目在快思模式下可跳過。標注 *(快思模式可跳過)* 的項目在快思模式下允許省略以節省時間。

完成 Sprint Review & Retrospective 前，確認以下項目全部完成：

- [ ] **模式確認**：依 §1.1 觸發條件判定當前執行模式（快思 / 慢想），並在執行前輸出「目前執行模式：快思模式 / 慢想模式」
- [ ] **Pre-Demo 部署驗證**（§2 Pre-Demo，Demo 展示前執行）：
  - [ ] 執行 `git log --oneline -1` 取得最新 commit hash
  - [ ] 確認生產環境部署狀態（Cloud Run 或標記「不適用」）
  - [ ] 若未部署：已觸發 `deployment-readiness` 並等待完成後才繼續 Demo
  - [ ] 輸出「Pre-Demo 部署驗證結果」摘要（PASS 或 FAIL + 處理說明）
- [ ] **交付物文案一致性審查**（§1.5，Sprint Review 前執行）：
  - [ ] 跨文件術語一致性審查通過（sprint_N.md / PROJECT_BOARD.md 狀態欄一致）
  - [ ] 狀態標注一致性審查通過（統一使用「完成 / 進行中 / 未完成」中文術語）
  - [ ] Issue 連結有效性審查通過（Issue # 填寫完整、狀態符合預期）
  - [ ] 版本與里程碑一致性審查通過（ROADMAP 里程碑狀態與交付進度相符）
  - [ ] 審查結果摘要已輸出（PASS 或 FAIL + 修正說明）
- [ ] **Retrospective Analytics 報告**（§3 步驟 0）：
  - [ ] Analytics 報告已展示（四區塊完整：Good 趨勢、Problem 趨勢、Action 關閉速度、待關閉 Items）
  - [ ] Analytics 完成後，才開始收集 Good / Problem / Action
- [ ] PO Subagent 已展示所有已完成 Story 的 Demo
- [ ] Stakeholder Subagent 已確認商業期待符合度
- [ ] 通過驗收的 Story 已移至 `PROJECT_BOARD.md` Done 欄位（含完成日期、Sprint 編號、Sprint 統計數據更新）
- [ ] `docs/sprints/sprint_N.md` Sprint Backlog 表格中每筆 Story 的狀態欄已回寫最終驗收結果（完成 / 未完成，未完成者標注原因）
- [ ] **Story Issue 狀態回寫**（§2.6，ADR-010 生命週期閉環）：
  - [ ] 每個 PASS Story：已執行 `gh issue view <number> --json author --jq '.author.login'` 查詢 Issue 建立者，判斷為內部或外部 Issue
  - [ ] 每個 PASS Story（內部 Issue — 建立者為 `github-actions[bot]` 或 body 含 `backlog-intake`）：已執行 `gh issue edit <number> --add-label "done" --remove-label "status: in-sprint"` 套用 done label，並執行 `gh issue close <number> -c "Sprint N Review 驗收通過（PASS）。Story 已完成交付。"` 關閉 Issue
  - [ ] 每個 PASS Story（外部 Issue — Stakeholder 或其他外部建立者）：已執行 `gh issue edit <number> --add-label "done" --remove-label "status: in-sprint"` 套用 done label，並執行階段 1 留言（見 §2.6 情況二）；**Issue 保持 Open，不執行 close**
    - [ ] 階段 1 留言已發送：`gh issue comment <number> --body "Sprint N Review 驗收通過（PASS）。程式碼已完成內部審查，待部署驗證後正式交付。"`
    - [ ] 階段 2 留言已發送（部署驗證通過後）：`gh issue comment <number> --body "已通過端對端驗證，功能已正式交付。請測試確認後關閉此 Issue。"`
  - [ ] 每個 FAIL Story：Issue 保持 open，已執行 `gh issue edit <number> --remove-label "status: in-sprint" --add-label "status: backlog"` 回復 backlog 狀態，並留言記錄未完成原因
- [ ] 未達 DoD 的 Story 已移回 Backlog 並標注原因
- [ ] `Retrospective_Log.md` 已新增 Good / Problem / Action 記錄
- [ ] 每個 Action Item 已建立為 GitHub Issue（`retro-action` label）
- [ ] 上個 Sprint 的 `retro-action` Issues 已逐項檢查並更新狀態
- [ ] 代理人校準儀式已完成（校準記錄已寫入 Calibration_Log.md，漂移判定已標注）
- [ ] 連續兩個 Sprint 未關閉的 Action 已升級至 Stakeholder
- [ ] `PRODUCT_BACKLOG.md` 已更新（未完成 Story 回填）
- [ ] 已完成 Story 從 `PRODUCT_BACKLOG.md` 移至 `BACKLOG_DONE.md`，按 Sprint 歸檔
- [ ] `ROADMAP.md` 已更新（版本里程碑狀態同步；版本 Tag 與里程碑對齊確認完成，見「ROADMAP 更新操作指引」）
- [ ] **歸檔觸發檢查**（見 §6）：確認 `PROJECT_BOARD.md` 與 `Retrospective_Log.md` 歷史 Sprint 區塊是否超過 5 個；若觸發則**派遣 subagent** 批量歸檔所有超出保留範圍的 Sprint 至 `docs/km/archive/`，主 session 僅接收摘要（快思模式下：未超過門檻可跳過）
- [ ] **Token 成本摘要** *(慢想模式限定)*（見下方子節）
- [ ] **記錄本次 Review 環節 Token 消耗至 `docs/km/Metrics_Log.md` Token 成本分環節記錄表格** *(慢想模式限定)*（對應 Review token 欄）：參照 `skills/sprint-execution/SKILL.md` §步驟詳解 步驟 7「記錄本次 Execution 環節 Token 消耗」的 Token 計算公式與降級方法執行，填入 Review token 欄。
- [ ] **ROADMAP 里程碑對齊檢查**（見 §5.1）：在觸發 deployment-readiness 前，確認本 Sprint 交付是否使某個 ROADMAP 里程碑達成完成狀態，並將結果傳達給 deployment-readiness 作為版本 Tag 決策依據
- [ ] 觸發 `deployment-readiness`，由 SRE subagent 執行版本 Tag 流程（bump version + git tag），並附帶 ROADMAP 里程碑對齊檢查結果（里程碑完成 → Major bump 候選；未完成 → Minor bump）
- [ ] **E2E 驗證結果已確認**：`deployment-readiness` §5.2 L3 E2E 驗證結果已確認（PASS 記錄至 Checklist；若輸出 `[E2E-SOFT-GATE]` 則已取得 PO 確認並記錄決策）
- [ ] Sprint Metrics 計算並追加至 `docs/km/Metrics_Log.md`（見下方計算指引）
- [ ] 是否有本 Sprint 值得記錄的角色制衡案例？若有，更新 `docs/km/ROLE_BALANCE_CASES.md`
- [ ] **產出文件（`PROJECT_BOARD.md`、`Retrospective_Log.md`、`Metrics_Log.md`、`sprint_N.md`）完成最後修改後，立即執行 git commit + git push**（僅限 Sprint 狀態文件；`Retrospective_Log.md` 與 `Metrics_Log.md` 雖位於 `docs/km/` 路徑，但屬 Sprint 狀態文件，適用本規範；`sprint_N.md` 為 Sprint 執行記錄，亦適用本規範。其他 Knowledge Management 文件如 `ROLE_BALANCE_CASES.md`、`Tech_Debt_Registry.md` 等不適用，避免觸發 ADR-003 Out-of-Sprint Hard Gate）：
  ```bash
  git add docs/PROJECT_BOARD.md docs/km/Retrospective_Log.md docs/km/Metrics_Log.md docs/sprints/sprint_N.md
  git commit -m "docs: Sprint N Review — 更新看板、Retro 記錄與 Metrics"
  git push
  ```

### Sprint Metrics 計算指引

Sprint Review 結束時，派遣 Metrics subagent（`model: "haiku"`）執行以下計算並將結果追加至 `docs/km/Metrics_Log.md`。**主 session 不直接讀取 sprint_N.md 或 Metrics_Log.md**，所有讀取與計算均由 Metrics subagent 負責，subagent 回傳計算結果後由主 session 確認並指示 subagent 寫入。

#### 步驟 1：讀取本 Sprint 資料

Metrics subagent 自行讀取 `docs/sprints/sprint_N.md`（N 為本 Sprint 編號），收集交付成果表格。

#### 步驟 2：Velocity 計算

統計狀態欄標記為「完成」或「Done」的 Stories，依 T-shirt Sizing 換算 Story Points：

| Size | Points |
|------|--------|
| S    | 1      |
| M    | 2      |
| L    | 3      |

**Velocity = 所有 Done Stories 的 Points 加總**

#### 步驟 3：完成率計算

- **分子**：狀態為 Done 的 Story 數量
- **分母**：Sprint Backlog 所有 Story 數量（含未完成）
- **完成率 = (Done 數 / 計畫總數) × 100%**
- **特殊情況**：若分母為 0，輸出「N/A」

#### 步驟 4：趨勢分析

Metrics subagent 自行讀取 `docs/km/Metrics_Log.md` 取得歷史 Velocity 資料，**僅讀取最近 30 個 Sprint 記錄**（若歷史記錄不足 30 個，則讀取全部）作為計算視窗：

- **Sprint 1–2（資料不足）**：輸出「資料不足」，不進行趨勢判斷
- **Sprint 3+（啟用趨勢）**：取最近三筆 Velocity，依下列優先順序判定：
  1. **連升**：最近 2 個 Sprint 的 Velocity 逐步上升 → 輸出「上升趨勢」
  2. **連降**：最近 2 個 Sprint 的 Velocity 逐步下降 → 輸出「下降趨勢」
  3. **穩定**：波動在 ±20% 以內（不符合連升或連降） → 輸出「穩定」
  4. **其他**：無法歸入以上三類 → 輸出「不規則」

#### 步驟 5：歷史回溯（首次建立或檔案為空時）

若 `docs/km/Metrics_Log.md` 不存在或內容為空（無任何資料列），Metrics subagent 執行以下操作：

1. 掃描 `docs/sprints/` 目錄下所有 `sprint_N.md`（依 N 升序），由 Metrics subagent 自行讀取各 sprint 檔案
2. 對每個 sprint 檔案執行步驟 2–3，計算歷史 Velocity 與完成率
3. 依序寫入 Metrics_Log.md 表格，趨勢欄填入「資料不足」（Sprint 1–2）或依步驟 4 計算

#### 步驟 6：追加記錄至 Metrics_Log.md

在 `docs/km/Metrics_Log.md` 的表格末尾追加一列：

```
| Sprint N | YYYY-MM-DD | V points | X% | 趨勢 | 備註 |
```

欄位說明：
- **Sprint 編號**：`Sprint N`
- **日期**：當日日期（YYYY-MM-DD）
- **Velocity**：步驟 2 計算結果，格式為「N points」
- **完成率**：步驟 3 計算結果，格式為「N%」或「N/A」
- **趨勢**：步驟 4 計算結果
- **備註**：可選填，例如特殊情況說明或 Sprint Goal 達成狀態

### Token 成本摘要指引

Sprint Review 結束時，派遣 Metrics subagent（`model: "haiku"`）依下列步驟產出 Token 成本摘要。**主 session 不直接讀取 Metrics_Log.md**，由 subagent 讀取並回傳摘要。

#### 步驟 1：讀取 Token 表格

Metrics subagent 自行讀取 `docs/km/Metrics_Log.md`，找到「Token 成本記錄」區塊的表格。

#### 步驟 2：Fallback 判斷

若 Token 表格中**無本 Sprint 對應的記錄列**（Sprint 編號不存在），或 **Token 計數器不可存取**，則輸出精確字串：

```
Token 資料不可用，需手動補充
```

並結束本子節，不繼續執行步驟 3。

#### 步驟 3：離群值分析

**前置條件**：Token 表格中本 Sprint **之前**已有 3 列以上的完整記錄（完整記錄定義：輸入 token 與輸出 token 均為正整數 > 0，且估算成本非空白、非 `N/A`）。

- 若不滿足前置條件，輸出：

  ```
  Token 歷史資料不足（需至少 3 個 Sprint 記錄），跳過離群值分析
  ```

- 若滿足前置條件，執行以下計算：

  1. 計算本 Sprint **之前**所有完整記錄的**平均輸入 token** 與**平均輸出 token**
  2. 對本 Sprint 的記錄執行比對：
     - 若本 Sprint 輸入 token > 平均輸入 token × 2，標記輸入欄為 `[OUTLIER]`
     - 若本 Sprint 輸出 token > 平均輸出 token × 2，標記輸出欄為 `[OUTLIER]`
  3. 輸出摘要，範例格式：

  ```
  Token 成本摘要（Sprint N）
  - 輸入 token：25000 [OUTLIER]（歷史平均：10500，超過 2 倍閾值）
  - 輸出 token：3100
  - 估算成本：$0.0312
  - 資料來源：Claude Code API
  ```

  若無任何 `[OUTLIER]`，範例格式：

  ```
  Token 成本摘要（Sprint N）
  - 輸入 token：9800
  - 輸出 token：2900
  - 估算成本：$0.0198
  - 資料來源：Claude Code API
  ```
