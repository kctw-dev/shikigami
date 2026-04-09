# ADR-045: Short-lived Subagent + Progress Tracker — 解決 LLM 規則衰減

**狀態**：Accepted
**日期**：2026-04-09
**修訂日期**：2026-04-09
**修訂理由**：原方案誤判問題根因為「記憶力」（忘記規則），實際為「注意力」（知道規則但權重不足而忽略）。State machine gate 解的是記憶力問題，對注意力問題無效。改用 short-lived subagent（每步驟獨立 context）直接解決注意力佔比問題，state machine 降級為 progress tracker。
**決策者**：Architect Agent + Developer Agent
**觸發 Story**：#962（原始）→ #977（方向修正）
**Unblocks**：Sprint 179 細粒度 subagent 派遣

---

## 背景與問題

LLM agent 在長 context 下會出現「規則衰減」現象。**此問題的根因是注意力（attention），不是記憶力（memory）**。

### 正確診斷：注意力權重稀釋

1. **LLM 知道規則存在，但選擇不遵守**：規則仍在 context 中（未被 compact 丟棄），但 attention 機制在長 context 中分散注意力，導致規則的權重不足以影響輸出
2. **佔比是關鍵**：2000 token 的流程規則在 100K token context 中僅佔 ~2%，被忽略是 transformer attention 機制的本質行為
3. **LLM 會自圓其說**：不是靜默跳過步驟，而是編造合理理由（「考慮到效率，這個步驟可以合併」「這兩步可以同時進行」），將違規偽裝成合理決策
4. **不可觀測**：步驟執行與否缺乏外部可驗證的 log，僅依賴 LLM 自述

### 原始診斷的錯誤

原方案（方向 3：外部腳本驅動 + 現有 subagent 模型）假設問題是「LLM 忘記做到哪一步」，因此用 state machine gate 來「提醒」。但實際上：

- Gate 驅動仍依賴 LLM 主動呼叫 — 若 LLM 注意力不足以遵守「每步呼叫 gate」的指令，gate 本身就會被跳過
- 「LLM 不呼叫 gate check 則形同虛設」在原 ADR 已被列為風險，但未認識到這正是核心矛盾

### 與 scrum-master-state-graph.md 的關係

現有 `docs/sdd/scrum-master-state-graph.md` 定義了 Scrum Master 的完整調度狀態機（§2-§5），覆蓋 Sprint lifecycle、exception path、意圖路由、自動觸發。該狀態圖為**文件化行為描述**（documentation），不直接驅動執行。

本 ADR 修訂版的 progress tracker 與 scrum-master-state-graph.md 形成互補：

| 層級 | 文件 | 性質 |
|------|------|------|
| 設計層（Design） | scrum-master-state-graph.md | 行為文件化，描述「應該怎麼走」 |
| 執行層（Runtime） | scripts/state-machine/ | 進度追蹤，記錄「實際走到哪」 |

---

## 評估方向

### 方向 1：外部狀態機（Shell Script 持有狀態）

**概念**：以 shell script 作為流程驅動器，每一步定義 gate condition，通過才放行下一步。

**問題**：解的是「記憶力」問題（怕忘了做到哪），但真正的問題是「注意力」。Gate 驅動仍依賴 LLM 主動呼叫，在注意力衰減時 gate 本身就會被跳過。

### 方向 2：短命 Agent（每步驟獨立 subagent）

**概念**：每個流程步驟派遣一個全新 subagent，確保 context 乾淨、規則佔比高。

**優點**：
- 徹底消除 context 衰減（每步驟從零開始）
- 每個 subagent 的 prompt 中規則佔比 ~17%（2K/12K），遠高於長 context 的 ~2%（2K/100K）
- Attention 權重集中在少數規則上，遵守率顯著提高

**缺點**：
- 派遣成本高（每步驟建立 subagent 有啟動延遲）
- 步驟間狀態傳遞需要額外機制

### 方向 3：組合方案 — 外部腳本驅動 + 現有 subagent（原選定，已廢棄）

原方案，不再贅述。核心問題：gate 驅動依賴 LLM 主動呼叫，無法解決注意力衰減。

### 方向 4：Short-lived Subagent + Progress Tracker（修訂版，選定）

**概念**：
- **核心機制**：將執行性步驟拆為細粒度 short-lived subagent，每個 subagent 的 context 只包含該步驟所需的規則和輸入，確保規則佔比高
- **輔助機制**：state-machine.sh 降級為 progress tracker，僅記錄進度（做到哪）和狀態（成功/失敗），不驅動流程、不做 gate 攔截

**優點**：
- 直接解決注意力問題 — 短 context 中規則佔比高，LLM 被迫關注
- Progress tracker 提供可觀測性 — 事後可審計每步執行結果
- 與 ADR-007 Story-Lifecycle subagent 共存 — Story-level 和 Step-level 是不同粒度
- 冪等重入 — progress tracker 記錄斷點，crash recovery 可從斷點續跑

**缺點**：
- 步驟間狀態傳遞需要明確契約（JSON 結果回傳）
- 增加 subagent 派遣開銷（但每個 subagent 更小更快完成）

---

## 決策內容

**選擇方向 4：Short-lived Subagent + Progress Tracker（修訂版）**

### 理由

1. **對症下藥**：注意力問題用「縮短 context + 提高規則佔比」解決，而非「外部 gate 提醒」
2. **不依賴 LLM 自律**：派遣 subagent 是主 session 的行為，subagent 本身只需完成一個小任務
3. **可觀測性**：progress tracker 記錄每步結果，事後可審計
4. **漸進式**：可逐步將步驟改為 subagent 派遣，不必一次全改

### 架構概覽

```
主 Session（Orchestrator）
  │
  ├─ 讀取 progress tracker → 判斷從哪一步續跑
  │
  ├─ Step 1: 派遣 subagent（task-list-init）
  │    └─ subagent 完成 → 回傳 JSON 結果
  │    └─ 主 session 更新 progress tracker
  │
  ├─ Step 2: 派遣 subagent（story-selection）
  │    └─ ...
  │
  └─ Step N: 純檢查步驟（可留在主 session）
       └─ checkpoint 偵測、CI 快掃等
```

### Progress Tracker（原 state-machine.sh 降級）

state-machine.sh 保留以下功能：
- `init` — 初始化進度檔
- `complete` — 標記步驟完成
- `fail` — 標記步驟失敗
- `status` — 查詢目前進度
- `check` — 查詢某步驟狀態（純 query，不 block）

移除：
- `gate` — 不再做流程攔截（gate 依賴 LLM 主動呼叫，是注意力問題的另一種表現）

---

## § 細粒度 Short-lived Subagent 派遣方案

### 1. 適用步驟選擇

sprint-execution §3 流程中的步驟分類：

| 步驟 | 類型 | 派遣方式 | 理由 |
|------|------|---------|------|
| Task List 初始化 | 執行性 | **subagent** | 需要讀取 Sprint 資訊、建立結構化 task list |
| Sprint Checkpoint 偵測 | 純檢查 | 主 session | 僅讀取 checkpoint 檔案判斷狀態，無複雜邏輯 |
| Issue/CI 快掃 | 純檢查 | 主 session | 僅呼叫 gh CLI 取得狀態 |
| Story 選取 | 執行性 | **subagent** | 需要 RICE 評分、依賴分析等判斷 |
| Story 實作 | 執行性 | **subagent** | ADR-007 Story-Lifecycle subagent（已存在） |
| Story 審查 | 執行性 | **subagent** | 需要獨立 QA 審查，已存在 |
| Sprint Review | 執行性 | **subagent** | 需要統計、產出報告 |

**選擇原則**：
- 執行性步驟（需要判斷、生成、修改檔案）→ 獨立 subagent
- 純檢查步驟（僅讀取狀態、回傳布林值）→ 留在主 session
- 已有 subagent 的步驟（Story 實作、審查）→ 維持現狀

### 2. Prompt 模板格式

每個 step subagent 的 prompt 應包含四個區塊：

```markdown
# Step Subagent: {step_name}

## 規則片段
{從 SKILL.md 提取該步驟的相關規則，限制在 2K token 以內}

## 輸入契約
- 前一步驟產出物路徑：{file_path}
- Sprint 編號：{sprint_number}
- 其他必要 context：{...}

## 輸出契約
- 必須產出的檔案：{output_files}
- 必須回傳的 JSON 結果（寫入 {result_file}）

## 成功/失敗判定
- 成功條件：{success_criteria}
- 失敗條件：{failure_criteria}
- 遇到失敗時：寫入失敗 JSON 並結束，不嘗試自行修復
```

### 3. 結果回傳 JSON 契約

每個 step subagent 完成後，必須寫入標準化結果 JSON：

```json
{
  "step_name": "task-list-init",
  "status": "completed|failed|escalate",
  "output_artifacts": [
    "docs/sprints/sprint-179/task-list.md"
  ],
  "duration_ms": 3200,
  "error": null
}
```

欄位說明：
- `step_name`：步驟名稱，與 progress tracker 的 step name 一致
- `status`：`completed`（成功）、`failed`（失敗，可重試）、`escalate`（需人工介入）
- `output_artifacts`：本步驟產出的檔案路徑列表
- `duration_ms`：執行耗時（毫秒）
- `error`：失敗時的錯誤訊息，成功時為 `null`

主 session 收到結果後：
1. 驗證 `output_artifacts` 中的檔案是否存在
2. 根據 `status` 更新 progress tracker
3. 若 `status` 為 `failed`，可重試或 escalate
4. 若 `status` 為 `escalate`，停止流程等待人工介入

### 4. 與 ADR-007 的關係

ADR-007 定義了 Story-Lifecycle subagent：每個 Story 一個 subagent，在 worktree 中獨立工作。

本方案引入 Step-level subagent，與 Story-level subagent 共存：

| 粒度 | 定義 | 典型 context 大小 | 典型壽命 |
|------|------|------------------|---------|
| Story-level（ADR-007） | 一個 Story 的完整生命週期 | 50-100K token | 10-30 分鐘 |
| Step-level（本 ADR） | Sprint 流程中的一個步驟 | 10-15K token | 1-5 分鐘 |

Step-level subagent 的 context 小、壽命短，規則佔比高，正是解決注意力衰減的核心。

---

## 後果

### 正面

- 規則遵守率提高 — 短 context 中規則佔比從 ~2% 提升至 ~17%
- 可觀測 — progress tracker 記錄每步狀態，可事後審計
- 冪等重入 — crash recovery 可從 progress tracker 的斷點續跑
- 漸進遷移 — 可逐步將步驟改為 subagent 派遣

### 負面

- 步驟間狀態傳遞需要額外的 JSON 契約維護
- 增加 subagent 派遣開銷（但每個 subagent 更快完成）

### 風險

- Step subagent 過多導致 OOM — 緩解：遵守 SHIKIGAMI_MAX_PARALLEL 限制，step subagent 為序列執行（非平行）
- Prompt 模板維護成本 — 緩解：模板可由腳本從 SKILL.md 自動提取

---

## 參考

- `docs/sdd/scrum-master-state-graph.md` — 現有 Scrum Master 調度狀態圖
- `skills/sprint-execution/SKILL.md` §3 — sprint-execution 執行流程
- ADR-007 — Story-Lifecycle subagent 封裝模型
- ADR-041 — Crash Recovery Side Effect Idempotency Guard
