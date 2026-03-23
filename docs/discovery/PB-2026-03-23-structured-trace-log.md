# Product Brief: Structured Trace Log — Multi-Agent Observability

**Issue 來源：** #342 研究報告 Issue #1
**優先級：** 🔴 高
**日期：** 2026-03-23
**PB 狀態：** Draft

---

## 1. 問題陳述

Shikigami 目前缺乏每個 agent action 的結構化執行記錄。當多角色並行執行 Sprint 任務時，若發生錯誤或意外行為，無法從現有日誌中還原完整決策鏈。非確定性的 agent 行為導致相同輸入可能產生不同執行路徑，傳統文字日誌無法支援問題重現與根因分析，使 Debug 成本極高且難以收斂。

具體痛點：
- subagent 執行失敗時，僅能從對話記錄推斷，無精確時間戳記與 input/output 摘要
- 多角色同時執行時，無法確定「是哪個 agent 的哪個 action 導致後續異常」
- High 自治模式下長時間執行缺乏持久化追蹤，session 結束後資訊遺失

---

## 2. 目標使用者

**主要使用者：** 使用 Shikigami 進行 Sprint 執行的開發者與 AI 團隊 Operator
- 需要在 Sprint 出現問題後快速定位根因
- 在 High 自治模式下需要事後審計 agent 的決策歷程

**次要使用者：** 框架維護者
- 需要評估新 Skill / Agent 行為是否符合預期
- 需要量化 agent 執行效率（duration_ms 分佈）

---

## 3. 商業假設

**假設外顯化（三問）：**

1. **我們假設使用者在意 Observability** — 使用者遇到 agent 執行異常時，有強烈動機查閱結構化日誌而非放棄追蹤。[UNCERTAIN] 若使用者習慣直接重跑 Sprint，日誌查閱行為可能不足以驗證此假設，需透過使用者訪談確認。

2. **我們假設結構化日誌能降低 Debug 時間** — 加入 trace log 後，平均根因分析時間（MTTR）會顯著下降。[UNCERTAIN] 若大多數問題出在 prompt 品質而非執行流程，trace log 對縮短 Debug 時間的貢獻可能有限。

3. **我們假設 JSON 結構化格式是合適的呈現方式** — 開發者能直接消費 JSON trace 進行分析，無需額外視覺化工具。[UNCERTAIN] 若使用者偏好人類可讀格式，純 JSON 輸出的採用率可能偏低。

---

## 4. 提案解決方向

為所有 8 個 agent 角色的每次 action 產生結構化 trace 記錄，欄位包含：timestamp（ISO8601）、agent_role、action_type（tool_call / message / decision）、input_summary、output_summary、tool_used、duration_ms、session_id、parent_task_id。

實作要點：
- Trace log 寫入 per-session 獨立檔案（命名格式：`trace-{session_id}-{date}.jsonl`），避免多機器 append 衝突
- 支援依 session_id 過濾，可重建單次 Sprint 的完整執行路徑
- High 自治模式下自動持久化至本地檔案，session 結束後不遺失
- 寫入邏輯僅在 agent YAML 的 hook 層加入，不修改各角色核心 prompt 邏輯

---

## 5. 成功指標

- **主要指標（可量化）：** 所有 8 個 agent 角色 100% 的 action 均有對應 trace 記錄（Coverage Rate）
- **次要指標：** 具備 trace log 的 Sprint 發生異常後，根因定位時間相較無 trace 的基準縮短 50% 以上（需建立基準線後評估）
- **採用指標：** 開發者在發生問題時主動查閱 trace log 的比率（Adoption，透過問卷或使用者訪談收集）
- **品質指標：** trace log 本身的完整性（無欄位缺漏 > 99%）

---

## 6. 排除範圍

- **不含視覺化 Dashboard**：本 PB 僅定義結構化資料輸出，UI 呈現屬獨立需求
- **不含即時串流介面**：trace 以 append-only 檔案為主，不建立 WebSocket 或 Server-Sent Events
- **不含跨 Sprint 聚合分析**：多個 Sprint 的 trace 比較與趨勢分析不在本次範圍
- **不含 PII 過濾機制**：若需求文件含個資，trace log 的資料遮罩屬獨立 Security 課題

---

## 7. 依賴與風險

**依賴：**
- Issue #7（Kill Switch）：High 自治模式的緊急停止後，需確認 trace 能在停止前完整 flush
- Issue #2（Prompt Injection Defense）：Security scan 結果應納入 trace log，形成完整審計鏈

**風險：**
- **效能風險**：每個 action 寫入 JSONL 可能增加 agent 回應延遲。[UNCERTAIN] 若 I/O 成為瓶頸，需評估非同步寫入策略
- **儲存成本風險**：長時間 High 自治模式的 trace 檔案可能累積至 GB 級。需定義 retention policy（建議預設保留 30 天）
- **維護風險**：新增 Agent 或 Skill 時，需確保 trace hook 同步更新，否則 Coverage Rate 會悄悄下降

