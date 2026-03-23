# Product Brief: Scrum Master 調度狀態圖文件

**PB ID**: PB-2026-03-23-scrum-master-state-graph
**狀態**: Draft
**建立日期**: 2026-03-23
**來源議題**: #342 AI Agent 設計研究報告 §3.1
**產品負責人**: PO Agent

---

## 1. 問題陳述

Shikigami 的 Scrum Master agent 負責整個 Sprint lifecycle 的調度：Planning → Execution → Review → Retro。這套調度邏輯目前以「偽碼 + 條件說明」散落在 `agents/scrum-master.md` 與相關 SKILL.md 中。

核心問題：

- **不可視化**：調度邏輯以自然語言描述，沒有狀態圖，新協作者（含 AI agent）難以快速理解整體 flow
- **Debug 困難**：Sprint 卡住時，無法定位「現在是哪個 state，transition 條件是什麼沒有滿足」
- **邊界條件隱藏**：例外處理（Story blocked、subagent crash、PO 介入）的轉換規則分散，容易遺漏
- **跨角色對齊成本高**：Architect、Developer 若需理解 SM 的決策邏輯，必須讀大量自然語言

LangGraph 與 Google ADK 2.0 的實踐顯示：明確的 state graph 定義是 multi-agent system 可維護性的基礎。

---

## 2. 目標使用者

**主要**：負責維護與擴充 Shikigami 框架的 Architect agent 與 Developer agent
**次要**：遭遇 Sprint 異常需要 debug 的 Power User（含使用者本人）

使用場景：
- Sprint 卡住時，使用者查看狀態圖定位問題
- Architect 評估新功能（如 TCB 斷點、Crash Recovery）是否需要新增 state 或 transition
- 新 Skill 開發時，Developer 確認 SM 何時、以何條件呼叫此 Skill

---

## 3. 商業假設 [UNCERTAIN]

- [UNCERTAIN] 有了可視化狀態圖，Sprint debug 時間可縮短 40% 以上
- [UNCERTAIN] 狀態圖文件可以作為 Architect 設計新功能時的「共同語言」，減少設計來回溝通成本
- [UNCERTAIN] graph-based 文件格式（Mermaid / DOT）可由 agent 自動更新，維護成本不會高於現有偽碼
- [UNCERTAIN] 使用者願意在每次 SM 邏輯變更時同步更新狀態圖（接受這個新規範）

---

## 4. 提案解決方向

### 核心概念
將 SM 的調度邏輯從「自然語言偽碼」轉換為「明確 state graph」，並以機器可讀格式（Mermaid）嵌入文件。

### 方向 A：純文件補充（Mermaid 狀態圖）
在 `docs/sdd/` 新增 `scrum-master-state-graph.md`，用 Mermaid `stateDiagram-v2` 描述完整 lifecycle，包含所有 state、transition 條件、exception path。

### 方向 B：Skill 內嵌狀態圖片段
每個相關 SKILL.md 的開頭嵌入局部狀態圖，顯示「此 Skill 在整體 flow 中的位置」。

### 方向 C：狀態圖 + 決策樹
除了狀態圖，補充關鍵轉換節點的決策樹（例：「Story blocked」時 SM 的判斷邏輯）。

推薦方向：**方向 A + C**（先建立完整狀態圖，再補關鍵決策樹），方向 B 可後續漸進加入。

---

## 5. 成功指標

| 指標 | 基準線 | 目標 | 測量方式 |
|------|--------|------|----------|
| Sprint debug 時使用者需要閱讀的文件數 | 待建立基準 | 減少 50% | Sprint Retro 紀錄 |
| Architect 新功能設計需要來回確認 SM 邏輯的次數 | 待建立基準 | 減少 30% | Sprint Review 統計 |
| 狀態圖與實際 SM 行為的一致性（QA 審查） | 0%（無文件） | 90% 以上 | 每 Sprint QA 抽測 |
| 框架貢獻者理解 SM flow 所需時間 | 待建立基準 | < 15 分鐘 | 新協作者訪談 |

---

## 6. 排除範圍

- 不改變 SM 的實際調度行為（本次只是文件化，不是重構）
- 不實作 runtime state tracking（不在 session 中維護 state 機器實例）
- 不涉及其他 agent（QA、Developer）的狀態文件化（各自有獨立 PB 機會）
- 不產生 HTML/PDF 互動式圖表（Mermaid 文字格式即可，符合「.md 給 agent 消費」原則）

---

## 7. 依賴與風險

### 依賴
- 需要 SM 現有調度邏輯的完整盤點（涉及 `agents/scrum-master.md` 與相關 SKILL.md 的深度閱讀）
- Mermaid 語法需要 agent 能正確生成並驗證（現有能力支援）
- 狀態圖需要 PO 與 SM agent 共同審查，確認與實際行為一致

### 風險
| 風險 | 可能性 | 影響 | 緩解策略 |
|------|--------|------|----------|
| 狀態圖與實際行為出現 drift（文件與代碼不同步） | 高 | 中 | 將狀態圖更新列為 SM Skill 變更的 DoD 條件 |
| SM 邏輯本身有隱藏的邊界條件，文件化後暴露設計缺陷 | 中 | 中 | 視為正向結果，發現缺陷則開新 issue 修復 |
| Mermaid 複雜度過高導致圖不可讀 | 低 | 中 | 分拆為多個局部圖，各自聚焦一個 lifecycle 階段 |
