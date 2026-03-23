# Product Brief: Context Engineering（Just-in-Time Retrieval）

**PB ID**: PB-2026-03-23-context-engineering
**狀態**: Draft
**建立日期**: 2026-03-23
**來源議題**: #342 AI Agent 設計研究報告 §2.1
**產品負責人**: PO Agent

---

## 1. 問題陳述

Shikigami 各 agent 在 session 啟動時會預先載入大量 context（SKILL.md、ARCHITECTURE.md、Sprint 紀錄、PRD 等），這種「全量預載」策略造成以下問題：

- **Context rot**：隨著 token window 被非即時相關內容佔據，模型對關鍵指令的注意力品質下降
- **成本浪費**：每次呼叫都攜帶本次任務不需要的背景知識，token 消耗不成比例
- **更新滯後**：預載的文件快照可能已過期，但 agent 仍依賴舊版內容做決策
- **可觀測性差**：無法知道 agent 實際「讀了哪些」context，難以優化

Anthropic 官方 Context Engineering 文章明確指出：給模型「剛好夠用的資訊、在剛好需要的時機」才能維持高品質輸出。

---

## 2. 目標使用者

**主要**：使用 Shikigami 執行長時 Sprint（>4 小時）或 Cruise 的開發團隊
**次要**：需要 agent 跨多個 repo 或多個 Story 工作的 Power User

使用場景：
- Scrum Master 調度 10+ subagent 並行工作
- Developer agent 在同一 session 內處理多個不同領域的 Story
- Cruise agent 巡航多個 repo 時需要不同 repo 的專屬 context

---

## 3. 商業假設 [UNCERTAIN]

- [UNCERTAIN] agent 的輸出品質與 context 視窗中相關 token 比例正相關；提高相關比例可改善輸出品質 10–30%
- [UNCERTAIN] Just-in-Time 載入機制可在不犧牲品質的前提下降低每次呼叫的平均 token 成本 20% 以上
- [UNCERTAIN] 開發者願意接受「動態載入有 latency」的 trade-off，以換取更高品質的 agent 輸出
- [UNCERTAIN] 現有 Skill 架構可以透過「輕量引用索引 + read 工具」實現 JIT，無需改造 agent 定義格式

---

## 4. 提案解決方向

### 核心概念
每個 agent 在 session 啟動時只載入「引用索引」（輕量 manifest），執行具體任務時才動態 fetch 所需的 Skill、文件或 ADR。

### 方向 A：Agent Context Manifest
為每個 agent 定義 `context-manifest.yaml`，列舉可能需要的資源路徑與觸發條件。任務開始時依條件 lazy load。

### 方向 B：Skill 內嵌 JIT 指令
在 SKILL.md 中標記哪些區段是「執行時必讀」，哪些是「參考備查」。Agent 按標記決定是否預載。

### 方向 C：Read-on-Demand Hook
在 `session-start` hook 只注入路徑清單，agent 在執行任務前自行呼叫 Read 工具載入必要文件。

推薦方向：先做 **方向 C**（低侵入性，可快速驗證假設），再視結果決定是否做 A 或 B。

---

## 5. 成功指標

| 指標 | 基準線 | 目標 | 測量方式 |
|------|--------|------|----------|
| 每次 agent 呼叫平均 input token 數 | 待建立基準 | 降低 20% | token 計費紀錄 |
| Story 完成率（無需 PO 干預） | 待建立基準 | 持平或提升 | Sprint Review 統計 |
| Agent 引用錯誤舊版文件次數 | 待建立基準 | 降低 50% | QA 審查紀錄 |
| 開發者主觀滿意度（context 品質） | 待建立基準 | NPS +10 | Sprint Retro 問卷 |

---

## 6. 排除範圍

- 不改造現有 SKILL.md 格式（本次 PB 不觸及 Skill Schema）
- 不實作向量資料庫或嵌入搜尋（RAG 屬於獨立議題）
- 不處理 agent 之間的 context 共享（cross-agent memory 是另一個 PB）
- 不涉及 model 本身的 context window 大小優化

---

## 7. 依賴與風險

### 依賴
- `session-start` hook 機制必須支援動態注入路徑清單（現有 hooks.json 架構）
- agent 必須有能力在任務流程中自主呼叫 Read 工具（現有行為支援）
- 需要建立 context 使用量的 baseline 觀測（依賴 quality-observer MCP 或新增 telemetry）

### 風險
| 風險 | 可能性 | 影響 | 緩解策略 |
|------|--------|------|----------|
| JIT 載入增加 latency，影響 Sprint velocity | 中 | 中 | 先在低頻任務試點，測量 latency 影響 |
| Agent 誤判「不需要載入」，遺漏關鍵 context | 高 | 高 | 保留 fallback：若任務失敗率上升則回退全量預載 |
| Manifest 維護成本高，隨文件變動快速過期 | 中 | 中 | Manifest 自動化生成（依 SKILL.md 標記），減少手動維護 |
