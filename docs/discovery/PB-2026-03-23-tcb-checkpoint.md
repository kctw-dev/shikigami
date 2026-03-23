# Product Brief: TCB（Thread Control Block）斷點管理

**PB ID**: PB-2026-03-23-tcb-checkpoint
**狀態**: Draft
**建立日期**: 2026-03-23
**來源議題**: #342 AI Agent 設計研究報告 §3.3（Self-Manager arxiv 論文）
**產品負責人**: PO Agent

---

## 1. 問題陳述

Shikigami 目前的 Sprint checkpoint 機制以「Story」為最小粒度：`checkpoint.json` 記錄哪些 Story 已完成、哪些進行中。這個設計在以下場景出現明顯缺陷：

- **長任務恢復損失大**：一個 Story 可能包含 10+ 個 agent action（分析 → 設計 → 實作 → 測試 → 提 PR），中斷後必須從 Story 開頭重做
- **並行任務無法細粒度追蹤**：多個 subagent 並行執行時，只能知道 Story 狀態，不知道哪個具體 action 在執行
- **重複計算無法跳過**：已完成的 analysis step 在重啟後可能被重新執行，浪費 token 與時間
- **錯誤歸因困難**：Sprint 失敗時只知道哪個 Story 失敗，不知道是哪個 action 造成的

Self-Manager 論文（arxiv）的 TCB 概念借鑑作業系統中 Thread Control Block 的思路：每個 agent task 有獨立的 control block，記錄其狀態、依賴、輸入輸出，支援細粒度暫停與恢復。

---

## 2. 目標使用者

**主要**：使用 Shikigami 執行長時 Sprint（>2 小時、>5 個 Story）的開發者
**次要**：需要在不穩定環境（網路不穩、API rate limit 頻繁觸發）中使用 Shikigami 的使用者

使用場景：
- Sprint 在 Story #3 的「實作」phase 被中斷，重啟後直接從「實作」phase 繼續
- 多個 subagent 並行時，SM 可以查看每個 agent 的具體 action 狀態
- Sprint 失敗後，透過 TCB log 快速定位是哪個具體 action 出錯

---

## 3. 商業假設 [UNCERTAIN]

- [UNCERTAIN] 中斷恢復的 token 浪費（重做 Story）佔所有 Sprint token 消耗的 15–25%
- [UNCERTAIN] TCB 細粒度 checkpoint 可將中斷恢復損失從「整個 Story」降低到「單一 action」
- [UNCERTAIN] TCB control block 的寫入成本（每個 action 前後各寫一次）不超過節省成本的 10%
- [UNCERTAIN] 開發者願意接受 TCB 帶來的輕微 latency overhead，以換取更精確的恢復能力

---

## 4. 提案解決方向

### 核心概念
為每個 agent task（action 級別）建立獨立的 Thread Control Block，記錄：task ID、狀態（pending/running/completed/failed）、依賴的前置 task、輸入摘要、輸出摘要、開始/結束時間。

### TCB 資料結構（草案）
```json
{
  "tcb_id": "story-42-action-3",
  "story_id": "US-42",
  "agent": "developer",
  "action": "implement-core-logic",
  "status": "completed",
  "depends_on": ["story-42-action-2"],
  "input_digest": "sha256:...",
  "output_ref": "docs/sprints/subagent-results/US-42-action-3.md",
  "started_at": "2026-03-23T10:15:00Z",
  "completed_at": "2026-03-23T10:23:00Z"
}
```

### TCB 儲存位置
每個 Sprint session 建立一個 `tcb/` 目錄，按 Story 分子目錄，避免多機器 git conflict（符合「per-session 檔案」原則）。

### 方向 A：全量 TCB（所有 action 都記錄）
最完整，但寫入頻繁，TCB 文件量大。

### 方向 B：關鍵路徑 TCB（只記錄高成本或有副作用的 action）
選擇性記錄（如：git commit、API 呼叫、文件生成），低成本 action 不記錄。

### 方向 C：Story-level TCB + Action 摘要
保留現有 Story-level checkpoint，在其中增加 action 清單與狀態，不建立獨立 TCB 文件。

推薦方向：**方向 B**（關鍵路徑 TCB，平衡細粒度與開銷），可在 Sprint 中逐步驗證覆蓋範圍。

---

## 5. 成功指標

| 指標 | 基準線 | 目標 | 測量方式 |
|------|--------|------|----------|
| 中斷重啟後重做的平均 action 數 | 待建立基準（估計 5–10）| 降低到 1–2 | Sprint 重啟測試 |
| 中斷恢復的 token 浪費率 | 待建立基準 | 降低 60% | token 計費紀錄 |
| Sprint 失敗根因定位時間 | 待建立基準 | 降低 50% | Sprint Retro 紀錄 |
| TCB 寫入的額外 token overhead | N/A | < 5% 總 token 量 | token 計費紀錄 |

---

## 6. 排除範圍

- 不實作 runtime task scheduler（TCB 是記錄工具，不是調度引擎）
- 不涉及 agent 之間的 task dependency graph 可視化（此為獨立功能）
- 不處理 TCB 的長期歸檔與清理策略（此為 housekeeping 議題）
- 不替代現有 `checkpoint.json`（TCB 是補充，不是取代）

---

## 7. 依賴與風險

### 依賴
- 需要定義 agent action 的標準化邊界（什麼算一個「action」），需要 Architect 參與設計
- 多機器 per-session TCB 目錄需要 git 策略確認（避免 conflict）
- Scrum Master 需要支援讀取 TCB 狀態以決定恢復點（SM Skill 修改）

### 風險
| 風險 | 可能性 | 影響 | 緩解策略 |
|------|--------|------|----------|
| TCB 定義「action 邊界」困難，各 agent 定義不一致 | 高 | 高 | 先定義統一的 action 標準（Architect ADR），再實作 |
| TCB 文件量快速增長，影響 repo 體積 | 中 | 低 | TCB 文件加入 .gitignore，只存 session 本地 |
| TCB 寫入失敗本身成為新的故障點 | 低 | 中 | TCB 寫入為 best-effort，失敗不阻塞主流程 |
| 與 Crash Recovery PB（同批次）的功能重疊 | 中 | 中 | 明確分工：TCB 提供細粒度記錄，Crash Recovery 提供重啟邏輯 |
