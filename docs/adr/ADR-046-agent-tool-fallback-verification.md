# ADR-046: Agent Tool Fallback 機制實際驗證 — 區分可控層與依賴層

**狀態**：Accepted
**日期**：2026-04-26
**決策者**：Architect Agent
**觸發 Story**：#1003（Sprint 182 Retro Action A3）
**前置 ADR**：ADR-039（Token Cost Routing）
**前置 Story**：#995（API Error Fallback 策略文件）
**Unblocks**：#1003 收尾、未來政策性錯誤的處理路徑

---

## 背景與問題

#995（Sprint 181 Action A2）建立了 `skills/sprint-execution/SKILL.md §2.1.1` 「API Error Fallback 策略」，內容為決策樹文件 + JSONL schema + 靜態例外 agent 表格。**但該 Story 並未驗證 Claude Code Agent tool 在實際遭遇 429/529 時是否會自動降級**，文件僅描述「期望行為」。

Sprint 182 Planning 期間 Architect + QA subagent 同時遭 **usage policy refusal**（非 rate limit，非 server overload），主 session 才**手動**介入降級。此事件揭露三個未驗證的假設：

1. Claude Code Agent tool 收到 HTTP 429 時，是否會自動指數退避並重試？
2. Claude Code Agent tool 收到 HTTP 529 時，是否會自動降級至 sonnet？
3. **Usage policy refusal** 與 HTTP error 是不同錯誤類型 — §2.1.1 完全沒涵蓋。

---

## 驗證範圍與限制

### 可驗證項目

| 項目 | 方法 | 結果 |
|------|------|------|
| `docs/cruise-logs/model-fallback-*.jsonl` 是否存在 | `ls` | **不存在** — 自 #995 落地以來從未觸發過 |
| 主 session 是否實作降級程式碼 | `grep -r 429 scripts/ hooks/` | **無** — 只有 §2.1.1 文件，無實作 |
| Sprint 182 事件處理路徑 | 翻 sprint_182.md 與會議紀錄 | 主 session **手動**降級，非自動 |

**結論**：§2.1.1 是純策略文件，沒有任何自動化機制支撐。

### 不可驗證項目（依賴 Anthropic / Claude Code 內部）

| 項目 | 為何不可驗證 |
|------|-------------|
| Claude Code Agent tool 是否內建 retry on 429 | 無公開 SDK 行為文件；無法穩定觸發真實 429 |
| Claude Code Agent tool 是否回傳結構化錯誤碼 | 取決於 Claude Code 版本；可能直接 throw、可能傳回字串、可能在 result 內嵌錯誤 |
| Usage policy refusal 的觸發條件 | 內容相關，無法穩定模擬 |

→ 框架必須採取**防禦性設計**：假設 Agent tool 不自動 fallback，於主 session 派遣層自行處理。

---

## 三類錯誤的區分

| 錯誤類型 | 訊號特徵 | 偵測來源 | 處理路徑 |
|---------|---------|---------|---------|
| **HTTP 429** Rate Limit | exception 訊息含 `429` / `rate_limit_error` / `rate limit` | tool error stderr | 指數退避同模型 → 耗盡降級 sonnet（§2.1.1 既有） |
| **HTTP 500/529** Server / Overload | exception 訊息含 `529` / `Overloaded` / `overloaded_error` / `server_error` / `Internal server error` | tool error stderr | 立即降級 sonnet（§2.1.1 既有） |
| **Usage Policy Refusal** | subagent **正常完成** 但 result 內含 `I can't help with that` / `I'm unable to` / `I cannot assist` / `against my guidelines` 等典型拒答字樣 | tool result stdout | **新增**：偵測拒答 → 換用較寬鬆模型（sonnet）重試一次，仍拒答 → 標 `[POLICY-REFUSAL]` 並轉人工 |

**關鍵差異**：
- 前兩類：tool 拋例外，try-catch 即可
- 第三類：**tool 成功完成**，回傳一段拒答文字 → try-catch 抓不到，必須**比對輸出內容**

---

## 決策

### D1 — 主 session 派遣層加入防禦性 wrapper

新增 `scripts/dispatch-with-fallback.sh`，提供主 session 可呼叫的工具函式：

- `should_fallback_on_error <stderr>` — 偵測 stderr 是否符合 429/529/500 模式 → 回傳 `RETRY_SAME` / `DOWNGRADE_SONNET` / `NONE`
- `should_fallback_on_refusal <stdout>` — 偵測 stdout 是否含 policy refusal 字樣 → 回傳 `DOWNGRADE_AND_RETRY` / `NONE`
- `record_fallback_event <jsonl>` — 將 fallback 事件寫入 `docs/cruise-logs/model-fallback-<date>.jsonl`
- `--patterns` — 顯示三類錯誤的偵測 pattern（debug 用）

**注意**：實際的 Agent tool 重新派遣只能由主 session 透過 LLM 呼叫，shell script 無法替代。Wrapper 提供的是**判斷與記錄**功能，重派決策由主 session 依 wrapper 結果執行。

### D2 — §2.1.1 升級為「策略 + 偵測 + 限制」三段式

更新 `skills/sprint-execution/SKILL.md §2.1.1`：

1. 保留既有 429 / 500 / 529 決策樹
2. **新增 §2.1.1 (c)**：Usage Policy Refusal 偵測與處理路徑
3. **新增「驗證狀態」標記**：每段策略明示「已驗證 / 依賴 Claude Code 行為 / 防禦性假設」
4. 引用 ADR-046 作為決策依據

### D3 — 偵測 pattern 集中於 wrapper，非散在多處

所有 retry/refusal pattern 的字串集中在 `scripts/dispatch-with-fallback.sh`，避免散落在 SKILL.md / Agent prompt / hooks 各處而 drift。SKILL.md 引用 wrapper 名稱即可，不重複 pattern 字面。

---

## 拒絕的替代方案

### 替代 A：相信 Claude Code Agent tool 會自動 fallback

拒絕原因：Sprint 182 真實事件已證偽。Architect + QA 同時拒答時主 session 才手動處理 → 若有自動降級，不會走到主 session 介入。

### 替代 B：用 mock 模擬 429/529/refusal 寫整合測試

拒絕原因：mock 出來的「期望行為」與真實 Claude Code Agent 行為脫節，會給出虛假信心。**寧可承認不可驗證，採防禦性設計。**

### 替代 C：把策略下放到 Agent prompt（讓 subagent 自己處理）

拒絕原因：subagent 拿到 429 是當下這個 LLM call 失敗 — 它已無法執行任何邏輯。只有主 session 能 retry。Policy refusal 雖能讓 subagent 自陳，但「拒答的 subagent 自己評估自己應不應該重試」是有偏的。

---

## 已知限制（codex review 第 5 輪後）

正則式區分「拒答」與「診斷」存在語言固有歧義：

| 句型 | 視為 | 為何 |
|------|------|------|
| `I am unable to process this batch within the timeout.` | 診斷（無法區分） | `process this` 字面與「process this request」相同 |
| `I'm unable to fulfill that requirement until upstream API is back.` | 診斷（無法區分） | `fulfill that` 字面與「fulfill that request」相同 |

當前選擇：**寬鬆 → 偏向觸發 sonnet 重試一次**。理由：
- 一次 sonnet 重試成本低（~1 秒延遲、模型費用）
- 若 sonnet 也「拒答」（=同樣 pattern 命中診斷文字）→ 升級人工 → 人工確認後若是診斷，標記 `[FALSE-POSITIVE]` 並結束
- 反向（漏判真實 refusal）成本較高：subagent 卡住，主 session 不知道為何

caller 端如果觀測到大量 false positive，可在 ADR-046 後續迭代加入「診斷標誌詞」（because / until / without / missing）作為負向過濾。

## 後續工作

| 項目 | 觸發條件 | Owner |
|------|---------|-------|
| 第一次 fallback 事件發生後，分析 jsonl 記錄調整 pattern | `model-fallback-*.jsonl` 出現第 1 筆 | SRE / Architect |
| 觀察 3 個月 — pattern 命中率 | 季度回顧 | PO |
| 若 Anthropic 公開 Claude Code Agent 內建 retry 行為 | 公開文件出現 | Architect 重啟驗證 |

---

## 驗收（與 Issue #1003 AC 對照）

| #1003 AC | 本 ADR / D1–D3 對應 |
|----------|---------------------|
| 建立測試情境模擬 429 / policy refusal | ADR §「驗證範圍與限制」明示**不可穩定模擬**，改採 pattern 偵測測試 |
| 確認 Claude Code Agent tool 實際行為 | ADR §「不可驗證項目」明示三項依賴假設；以 Sprint 182 真實事件為唯一資料點 |
| 若無自動降級，主 session 加入 try-catch wrapper | D1 — `scripts/dispatch-with-fallback.sh` 提供 wrapper 函式 |
| 驗證報告寫入 docs/adr/ | 本 ADR-046 |
| §2.1.1 根據驗證結果更新 | D2 — §2.1.1 升級為三段式（策略 + 偵測 + 限制），新增 policy refusal 路徑 |
