# ADR-045: 外部狀態機 + 短命 Agent 架構 — 解決 LLM 規則衰減

**狀態**：Accepted
**日期**：2026-04-09
**決策者**：Architect Agent + Developer Agent
**觸發 Story**：#962（feat: 解決 LLM 規則衰減 — 外部狀態機 + 短命 Agent 架構）
**Unblocks**：Sprint 177 PoC 實作

---

## 背景與問題

LLM agent 在長 context 下會出現「規則衰減」現象：隨著 conversation 增長，早期注入的流程規則（SKILL.md §3 執行流程、HARD-GATE 條件）逐漸被稀釋，導致：

1. **步驟跳過**：sprint-execution 的 gate 條件（如 checkpoint 偵測、CI 快掃）被靜默略過
2. **順序錯亂**：步驟執行順序不符 SKILL.md 定義（如未完成 Task List 初始化就開始 Story 選取）
3. **HARD-GATE 失效**：compact 後的 context 遺失 gate 條件，後續步驟缺乏正確前置驗證
4. **不可觀測**：步驟執行與否缺乏外部可驗證的 log，僅依賴 LLM 自述

### 與 scrum-master-state-graph.md 的關係（AC4）

現有 `docs/sdd/scrum-master-state-graph.md` 定義了 Scrum Master 的完整調度狀態機（§2-§5），覆蓋 Sprint lifecycle、exception path、意圖路由、自動觸發。該狀態圖為**文件化行為描述**（documentation），不直接驅動執行。

本 ADR 提出的外部狀態機是**執行層**的補充：將 sprint-execution §3 流程從「LLM 內部記憶」遷移至「外部腳本驗證」，與 scrum-master-state-graph.md 形成互補關係：

| 層級 | 文件 | 性質 |
|------|------|------|
| 設計層（Design） | scrum-master-state-graph.md | 行為文件化，描述「應該怎麼走」 |
| 執行層（Runtime） | scripts/state-machine/ | 外部驗證，確保「真的有走到」 |

兩層的狀態命名應保持一致。外部狀態機的 step name 應能對應到 scrum-master-state-graph.md §2 SprintExecution 子狀態。

---

## 評估方向

### 方向 1：外部狀態機（Shell Script 持有狀態）

**概念**：以 shell script 作為流程驅動器，每一步定義 gate condition（產出物存在性檢查），通過才放行下一步。狀態持久化至 JSON 檔案。

**優點**：
- 狀態外化，不依賴 LLM context 記憶
- Gate condition 為硬性檢查（file exists、exit code），不可被 LLM 繞過
- 可觀測：每步留下結構化 log（step_name、exit_code、timestamp、failure_reason）
- 冪等重入：重執行時自動跳過已完成步驟（NFR4）
- 執行時間 < 1s（純 shell 操作）
- 向後相容：新目錄隔離（scripts/state-machine/），不影響既有流程

**缺點**：
- Shell script 能力有限，複雜邏輯需回退至 LLM
- 需要 LLM 主動呼叫外部腳本（依賴 prompt 指令）

### 方向 2：短命 Agent（每步驟獨立 subagent）

**概念**：每個流程步驟派遣一個全新 subagent，確保 context 乾淨、無歷史污染。

**優點**：
- 徹底消除 context 衰減（每步驟從零開始）
- 每個 subagent 可用最小 prompt（僅注入該步驟所需規則）

**缺點**：
- 派遣成本高（每步驟建立 subagent 有啟動延遲）
- 步驟間狀態傳遞需要額外機制
- 增加 OOM 風險（更多 subagent 同時存在的可能性）
- 與現有 Story-Lifecycle subagent 模型（ADR-007）有架構衝突

### 方向 3：組合方案 — 外部腳本驅動 + 現有 subagent（選定）

**概念**：以外部 shell script 作為流程驅動器和 gate 守門人，但不改變現有 subagent 派遣模型。sprint-execution 主流程在執行每個步驟前，先呼叫外部腳本驗證 gate condition，通過才繼續。

**優點**：
- 結合方向 1 的「硬性 gate」與現有 subagent 模型的「成熟穩定」
- 不引入額外 subagent 派遣開銷
- Gate 驗證獨立於 LLM context（外部腳本持有狀態）
- 向後相容：既有流程不變，僅在步驟間插入 gate check
- 漸進式遷移：可逐步將更多步驟納入外部狀態機管控

**缺點**：
- LLM 仍需主動呼叫 gate check（需 prompt 約束）
- 不能徹底消除 context 衰減，僅能在關鍵點攔截

---

## 決策內容

**選擇方向 3：組合方案（外部腳本驅動 + 現有 subagent 模型）**

### 理由

1. **風險最小**：不改變 ADR-007 的 Story-Lifecycle subagent 封裝模型
2. **ROI 最高**：在最容易衰減的關鍵步驟（前 3 步）加入硬性 gate，以最小成本解決 80% 問題
3. **可觀測性**：每步產出結構化 log，可事後審計
4. **漸進式**：PoC 驗證成功後，可逐步擴展至全流程

### PoC 範圍

sprint-execution §3 前 3 步：
1. **Task List 初始化**（§2.13）— gate: task list 建立成功
2. **Sprint Checkpoint 偵測**（§2.12）— gate: checkpoint 檔案狀態已判定
3. **Issue/CI 快掃**（gh issue list + gh run list）— gate: 掃描結果已記錄

### 狀態機設計

```
State File: .state-machine/sprint-execution-state.json

{
  "sprint_number": N,
  "steps": {
    "task-list-init":       { "status": "pending|completed|failed", "completed_at": null, "exit_code": null },
    "checkpoint-detection": { "status": "pending|completed|failed", "completed_at": null, "exit_code": null },
    "issue-ci-scan":        { "status": "pending|completed|failed", "completed_at": null, "exit_code": null }
  },
  "last_updated": "ISO-8601"
}
```

### Gate 條件定義

| Step | Gate Condition | 驗證方式 |
|------|---------------|---------|
| task-list-init | state file 中 task-list-init.status == "completed" | `jq` 讀取 |
| checkpoint-detection | state file 中 checkpoint-detection.status == "completed" | `jq` 讀取 |
| issue-ci-scan | state file 中 issue-ci-scan.status == "completed" | `jq` 讀取 |

### 與 scrum-master-state-graph.md 的對應

| 外部狀態機 step name | scrum-master-state-graph.md 對應 |
|---------------------|----------------------------------|
| task-list-init | SprintExecution → [*] → StorySelection（前置準備） |
| checkpoint-detection | SprintExecution → StorySelection（斷點續跑判定） |
| issue-ci-scan | SprintExecution → PreflightCheck（環境掃描） |

---

## 後果

### 正面

- Sprint execution 關鍵步驟有外部可驗證的 gate
- 規則衰減導致的步驟跳過可被事後審計發現
- 冪等重入支援 crash recovery 場景

### 負面

- 增加 shell script 維護成本
- LLM 仍需主動呼叫 gate check（prompt 層面的約束）

### 風險

- 若 LLM 完全不呼叫 gate check 腳本，外部狀態機形同虛設
  - 緩解：未來可透過 hook 機制自動注入 gate check（Phase 2）

---

## 參考

- `docs/sdd/scrum-master-state-graph.md` — 現有 Scrum Master 調度狀態圖
- `skills/sprint-execution/SKILL.md` §3 — sprint-execution 執行流程
- ADR-007 — Story-Lifecycle subagent 封裝模型
- ADR-041 — Crash Recovery Side Effect Idempotency Guard
