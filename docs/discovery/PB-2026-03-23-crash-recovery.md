# Product Brief: Temporal-style Crash Recovery

**PB ID**: PB-2026-03-23-crash-recovery
**狀態**: Draft
**建立日期**: 2026-03-23
**來源議題**: #342 AI Agent 設計研究報告 §3.4（LangGraph + Microsoft Bulletproof Agents）
**相關 PB**: PB-2026-03-23-tcb-checkpoint（TCB 提供記錄，本 PB 提供重啟邏輯）
**產品負責人**: PO Agent

---

## 1. 問題陳述

Shikigami 的 session crash recovery 目前依賴 `checkpoint.json`（Story 級別）。當 session 意外中斷時：

- **恢復粒度粗糙**：只能從上一個完成的 Story 重啟，進行中 Story 的工作全部丟失
- **無 replay 機制**：沒有像 Temporal workflow 那樣的「確定性 replay」能力，重啟後可能產生不同結果
- **Side effect 重複執行**：git commit、GitHub issue 操作等 side effect 在重啟後可能被重複觸發
- **恢復流程手動**：使用者必須手動重啟並告知 SM「從哪裡繼續」，沒有自動化機制
- **跨 session 狀態遺失**：Session 上下文（決策脈絡、中間計算結果）無法跨 session 傳遞

Microsoft Bulletproof Agents 指出：可靠的 agent 系統需要「at-least-once 執行保證」加上「idempotency 設計」。LangGraph MemorySaver 提供了 checkpoint-based replay 的參考實作。

---

## 2. 目標使用者

**主要**：執行長時 Sprint（>3 小時）且環境不穩定（網路、API timeout）的開發者
**次要**：需要跨天繼續 Sprint 的使用者（今天做到一半，明天繼續）

使用場景：
- API rate limit 觸發導致 session 強制結束，隔天早上自動恢復到昨天的進度
- 網路中斷後重新連線，Sprint 從最後成功的 checkpoint 繼續
- 使用者主動關閉 session（收工），下次開啟時 Sprint 狀態完整保留

---

## 3. 商業假設 [UNCERTAIN]

- [UNCERTAIN] 目前 Sprint 因 session crash 造成的重做損失佔所有 Sprint 時間的 10–20%
- [UNCERTAIN] Temporal-style replay 可實現 95% 以上的 crash 無損恢復（不丟失已完成工作）
- [UNCERTAIN] Side effect 冪等設計可在不增加複雜度的前提下防止重複執行（GitHub API 已支援冪等性）
- [UNCERTAIN] 跨天 Sprint 恢復的使用頻率足以支撐實作投資（每月至少 5 次以上）

---

## 4. 提案解決方向

### 核心概念
借鑑 Temporal workflow replay 與 LangGraph MemorySaver：將 Sprint 執行歷史以 event log 形式持久化，重啟時 replay event log 而非重新執行。

### 關鍵設計原則
1. **Event Log 持久化**：每個 agent action 的輸入、輸出、決策以 append-only log 記錄
2. **確定性 Replay**：Replay 時使用已記錄的輸出，不重新呼叫 LLM（避免不確定性）
3. **Side Effect 隔離**：git commit、API 呼叫等 side effect 在 replay 時跳過（已記錄的 side effect 不重複執行）
4. **Checkpoint 標記**：在 log 中標記 checkpoint 點，重啟時從最近 checkpoint 開始 replay

### Event Log 格式（草案）
```jsonl
{"event": "action_start", "action_id": "story-42-action-3", "inputs": {...}, "ts": "..."}
{"event": "llm_response", "action_id": "story-42-action-3", "response_digest": "...", "ts": "..."}
{"event": "side_effect", "action_id": "story-42-action-3", "type": "git_commit", "result": "abc123", "ts": "..."}
{"event": "action_complete", "action_id": "story-42-action-3", "ts": "..."}
{"event": "checkpoint", "checkpoint_id": "cp-42", "sprint_state": {...}, "ts": "..."}
```

### 方向 A：完整 Temporal-style（Event Sourcing + Replay）
最完整，但實作成本高，需要設計 replay engine。

### 方向 B：MemorySaver-style（Checkpoint + Resume）
只記錄 checkpoint 快照（不做 replay），重啟時從最近 checkpoint 載入狀態。比方向 A 簡單，但有些狀態可能遺失。

### 方向 C：Hybrid（Checkpoint + Side Effect Log）
Checkpoint 記錄 Sprint 狀態，額外記錄 side effect log 防止重複執行。不做完整 replay，但防止最常見的危害（重複 commit、重複 create issue）。

推薦方向：**方向 C**（最高 ROI，解決最關鍵痛點，實作成本可控）。方向 A 列為長期演進方向。

---

## 5. 成功指標

| 指標 | 基準線 | 目標 | 測量方式 |
|------|--------|------|----------|
| Crash 後工作損失率（丟失的 completed action 比例） | 待建立基準 | 降低 80% | Sprint 重啟測試 |
| Side effect 重複執行次數 / Sprint | 待建立基準 | 降低到 0 | Sprint 審查紀錄 |
| 跨 session 恢復成功率 | 待建立基準 | ≥ 90% | 受控測試 |
| 使用者手動干預恢復的次數 | 待建立基準 | 降低 70% | Sprint Retro 紀錄 |

---

## 6. 排除範圍

- 不實作完整 Temporal workflow engine（過度工程，超出 Shikigami 當前規模）
- 不處理 event log 的長期儲存與查詢（此為可觀測性基礎設施議題）
- 不涉及分散式鎖或多 session 同步（單一 session 場景優先）
- 不替代 TCB checkpoint（TCB 是 action 級記錄，Crash Recovery 是 session 級恢復邏輯）

---

## 7. 依賴與風險

### 依賴
- TCB checkpoint（PB-2026-03-23-tcb-checkpoint）的 action 記錄格式需要先定義，Crash Recovery 的 event log 建立在此之上
- Side effect 清單需要盤點（哪些操作是 side effect，哪些是純查詢）
- Session Watchdog（PB-2026-03-23-session-watchdog）偵測 crash 後需要觸發 recovery 流程

### 風險
| 風險 | 可能性 | 影響 | 緩解策略 |
|------|--------|------|----------|
| Event log 體積過大，影響 session 啟動速度 | 中 | 中 | 定期 compact log（只保留最近 N 個 checkpoint 之後的 events） |
| Replay 時 LLM 回應不確定性導致狀態分歧 | 高 | 高 | 方向 C 不做 LLM replay，只記錄 side effect，規避此問題 |
| Side effect 隔離邏輯複雜，容易出現遺漏 | 中 | 高 | 建立 side effect registry，所有 side effect 必須在 registry 登記才能執行 |
| 與 TCB PB 同期開發，設計決策需要高度協調 | 高 | 中 | 優先做 TCB（提供記錄基礎），Crash Recovery 在 TCB 穩定後再實作 |
