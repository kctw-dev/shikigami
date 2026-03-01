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

## 2. Sprint Review 流程

Sprint Review 的目的是驗收本 Sprint 交付的成果，確認是否符合商業期待。

### 步驟

1. **PO Subagent 展示 Demo 結果**
   - 針對每個已完成的 User Story，展示可運行的功能
   - Demo 應基於實際程式碼執行結果，而非文件描述
   - 逐一對照 Acceptance Criteria 確認通過狀態

2. **Stakeholder Subagent 確認商業期待**
   - 檢視 Demo 結果是否符合原始商業需求
   - 確認交付物是否達到預期的商業價值
   - 提出回饋意見或調整方向

3. **更新 `docs/PROJECT_BOARD.md`（已完成欄位）**
   - 將通過驗收的 Story 移至「Done」欄位
   - 記錄完成日期與 Sprint 編號
   - 更新 Sprint 統計數據（Velocity、完成率）

4. **未達 DoD 的 Story 處理**
   - 未通過 Definition of Done 的 Story 移回 Backlog
   - 必須標注未達標的具體原因（例：測試未通過、安全驗證失敗、文件未更新）
   - PO Subagent 重新評估優先級，決定是否納入下個 Sprint

---

## 3. Sprint Retrospective 流程

Sprint Retrospective 的目的是團隊自省，找出可改進之處並制定具體行動。

### 步驟

0. **Retrospective Analytics — 展示歷史趨勢分析報告**

   **觸發時機**：Retrospective 開始時第一步執行，**報告展示完畢前不得開始收集 Good / Problem / Action**。

   **指令**：讀取 `docs/km/Retrospective_Log.md`，依下列規則分析並輸出完整報告。

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
| `docs/prd/ROADMAP.md` | 更新版本里程碑狀態（進行中/已完成），反映本 Sprint 交付進度 |

---

## 6. 執行檢查清單

完成 Sprint Review & Retrospective 前，確認以下項目全部完成：

- [ ] Retrospective Analytics 報告已展示（四區塊完整：Good 趨勢、Problem 趨勢、Action 關閉速度、待關閉 Items）
- [ ] Analytics 報告展示完畢後才開始收集 Good / Problem / Action
- [ ] PO Subagent 已展示所有已完成 Story 的 Demo
- [ ] Stakeholder Subagent 已確認商業期待符合度
- [ ] 通過驗收的 Story 已移至 `PROJECT_BOARD.md` Done 欄位
- [ ] 未達 DoD 的 Story 已移回 Backlog 並標注原因
- [ ] `Retrospective_Log.md` 已新增 Good / Problem / Action 記錄
- [ ] 每個 Action Item 已建立為 GitHub Issue（`retro-action` label）
- [ ] 上個 Sprint 的 `retro-action` Issues 已逐項檢查並更新狀態
- [ ] 連續兩個 Sprint 未關閉的 Action 已升級至 Stakeholder
- [ ] `PRODUCT_BACKLOG.md` 已更新（未完成 Story 回填）
- [ ] 已完成 Story 從 `PRODUCT_BACKLOG.md` 移至 `BACKLOG_DONE.md`，按 Sprint 歸檔
- [ ] `ROADMAP.md` 已更新（版本里程碑狀態同步）
- [ ] **Token 成本摘要**（見下方子節）
- [ ] 觸發 `deployment-readiness`，由 SRE subagent 執行版本 Tag 流程（bump version + git tag）
- [ ] Sprint Metrics 計算並追加至 `docs/km/Metrics_Log.md`（見下方計算指引）
- [ ] 是否有本 Sprint 值得記錄的角色制衡案例？若有，更新 `docs/km/ROLE_BALANCE_CASES.md`
- [ ] **產出文件（`PROJECT_BOARD.md`、`Retrospective_Log.md`、`Metrics_Log.md`）完成最後修改後，立即執行 git commit + git push**（僅限 Sprint 狀態文件；`Retrospective_Log.md` 與 `Metrics_Log.md` 雖位於 `docs/km/` 路徑，但屬 Sprint 狀態文件，適用本規範。其他 Knowledge Management 文件如 `ROLE_BALANCE_CASES.md`、`Tech_Debt_Registry.md` 等不適用，避免觸發 ADR-003 Out-of-Sprint Hard Gate）：
  ```bash
  git add docs/PROJECT_BOARD.md docs/km/Retrospective_Log.md docs/km/Metrics_Log.md
  git commit -m "docs: Sprint N Review — 更新看板、Retro 記錄與 Metrics"
  git push
  ```

### Sprint Metrics 計算指引

Sprint Review 結束時，依序執行以下計算並將結果追加至 `docs/km/Metrics_Log.md`。

#### 步驟 1：讀取本 Sprint 資料

讀取 `docs/sprints/sprint_N.md`（N 為本 Sprint 編號），收集交付成果表格。

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

讀取 `docs/km/Metrics_Log.md` 取得歷史 Velocity 資料：

- **Sprint 1–2（資料不足）**：輸出「資料不足」，不進行趨勢判斷
- **Sprint 3+（啟用趨勢）**：取最近三筆 Velocity，依下列優先順序判定：
  1. **連升**：最近 2 個 Sprint 的 Velocity 逐步上升 → 輸出「上升趨勢」
  2. **連降**：最近 2 個 Sprint 的 Velocity 逐步下降 → 輸出「下降趨勢」
  3. **穩定**：波動在 ±20% 以內（不符合連升或連降） → 輸出「穩定」
  4. **其他**：無法歸入以上三類 → 輸出「不規則」

#### 步驟 5：歷史回溯（首次建立或檔案為空時）

若 `docs/km/Metrics_Log.md` 不存在或內容為空（無任何資料列），則：

1. 掃描 `docs/sprints/` 目錄下所有 `sprint_N.md`（依 N 升序）
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

Sprint Review 結束時，依下列步驟產出 Token 成本摘要。

#### 步驟 1：讀取 Token 表格

開啟 `docs/km/Metrics_Log.md`，找到「Token 成本記錄」區塊的表格。

#### 步驟 2：Fallback 判斷

若 Token 表格中**無本 Sprint 對應的記錄列**（Sprint 編號不存在），或 **Token 計數器不可存取**，則輸出精確字串：

```
Token 資料不可用，需手動補充
```

並結束本子節，不繼續執行步驟 3。

#### 步驟 3：離群值分析

**前置條件**：Token 表格中本 Sprint **之前**已有 3 列以上的完整記錄（輸入 token、輸出 token、估算成本均非空白）。

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
