# Product Brief: A2A 協議相容性評估 — 跨框架 Agent 協作路線

**Issue 來源：** #342 研究報告 Issue #8
**優先級：** 低
**日期：** 2026-03-23
**PB 狀態：** Draft

---

## 1. 問題陳述

Shikigami 的 8 個角色目前緊密耦合在單一框架內（Claude Code Plugin），若使用者需要：
- 與外部 CrewAI / LangGraph agent 協作執行任務
- 將 Shikigami 的特定角色（例如 QA 或 Security）暴露為外部 orchestrator 可調用的 subagent
- 在多機器分散式環境中跨框架部署 AI 團隊

現有框架缺乏標準化的 agent 通訊協議，所有整合需要客製化銜接，維護成本高且難以擴展。

Google 主導的 A2A（Agent-to-Agent）協議已於 2025 年 6 月捐給 Linux Foundation，截至 2026 年 3 月有 50+ 技術夥伴採用（Atlassian、Box、Salesforce、SAP、ServiceNow 等），成為事實上的跨框架 agent 通訊標準。此 Issue 的核心是「先研究評估，再決定是否跟進」。

---

## 2. 目標使用者

**主要使用者：** 需要跨框架整合的進階 Shikigami 使用者
- 企業環境中已有其他 AI agent 框架（CrewAI、LangGraph）在運行，希望 Shikigami 能無縫銜接
- 希望將 Shikigami 的 Scrum Master 作為 orchestrator，調用外部專業 agent 執行特定任務

**次要使用者：** Shikigami 框架維護者
- 需要評估框架長期技術路線，決定是否擁抱 A2A 成為生態系的一部分
- 需要一份可操作的相容性評估報告，作為後續架構決策的基礎

---

## 3. 商業假設

**假設外顯化（三問）：**

1. **我們假設跨框架協作是 Shikigami 使用者實際存在的需求** — 部分使用者已在生產環境中同時運行多個 AI agent 框架，且希望這些框架能互相通訊，而非各自孤立。[UNCERTAIN] 若目前使用者均為個人開發者、僅使用 Shikigami 作為唯一 AI 框架，此需求可能屬於未來場景，現在評估時機過早。需透過使用者調查確認是否有跨框架需求。

2. **我們假設 A2A 協議相容性不會從根本上改變 Shikigami 的角色設計** — 為 Shikigami 角色加入 A2A 相容 interface 是漸進式擴充，不需要重寫現有角色定義。[UNCERTAIN] 若 A2A 協議要求 agent 以 HTTP service 形式暴露，而 Shikigami 角色是 Claude Code Plugin 內的 Markdown 定義，兩者的架構差距可能超過「漸進擴充」的範疇，需 Architect 深度評估。

3. **我們假設評估報告能在一個 Sprint 內完成且具備足夠深度** — 包含技術可行性分析、interface 清單、安全考量（agent 身份驗證）的完整評估報告，可由 Architect 角色在一個 Sprint 內輸出。[UNCERTAIN] A2A 協議規格複雜度（包含 Agent Card、Task Protocol、Streaming 等）可能需要更長的研究時間。

---

## 4. 提案解決方向

此 PB 為 Research / Discovery 性質，主要輸出為相容性評估報告，不含實際實作。執行步驟：

1. **研讀 A2A 協議規格：** 完整閱讀 [google.github.io/A2A](https://google.github.io/A2A/)，重點理解：
   - Agent Card（agent 能力宣告格式）
   - Task Protocol（任務委派與狀態追蹤）
   - Streaming 與非同步任務支援
   - 身份驗證機制（agent-to-agent 的信任模型）

2. **識別 Shikigami 候選角色：** 評估哪 2-3 個 Shikigami 角色最適合作為 A2A-compatible agent 暴露
   - 候選標準：介面清晰、輸出結構化、可被外部 orchestrator 明確調用
   - 建議候選：QA（測試驗證任務）、Security（掃描任務）、Developer（程式碼實作任務）

3. **評估 Scrum Master 作為 A2A orchestrator 的可行性：** Scrum Master 透過 A2A 調用外部 agent（非 Shikigami 框架），擴充 AI 團隊能力

4. **輸出相容性評估報告：**
   - 技術可行性分析（逐項對照）
   - 需要新增或修改的 interface 清單
   - 潛在安全考量（agent 身份驗證、防止外部 agent 劫持框架行為）
   - 建議的實作優先序（若決定推進）

---

## 5. 成功指標

**Discovery 階段指標（此 PB 範圍）：**
- 完成 A2A 相容性評估報告（完成即達標）
- 識別出 Shikigami 最適合作為 A2A agent 暴露的 2-3 個角色（含理由說明）
- 若技術上可行，輸出 Phase 1 PoC 的範圍定義（至少一個角色的 A2A endpoint 設計）

**後續指標（依決策而定，本 PB 不含）：**
- 若決定實作 PoC：目標角色可透過 A2A 協議接受外部任務，並回傳結構化結果
- 若決定不實作：明確文件化原因，作為未來重新評估的基準

---

## 6. 排除範圍

- **不含實際 A2A endpoint 實作：** 此 PB 僅完成評估報告，不實作任何 agent 的 A2A interface
- **不含與特定第三方框架的整合測試：** 不實際與 CrewAI / LangGraph 建立連線測試
- **不含 A2A 的 UI 管理介面：** agent 連線管理 dashboard 為後續需求
- **不含現有 MCP server 的 A2A 化：** `mcp-servers/quality-observer` 的改造為獨立 Issue

---

## 7. 依賴與風險

**依賴：**
- A2A 協議規格（google.github.io/A2A）必須穩定可查閱
- Architect 角色負責執行技術相容性分析
- Issue #5（Agent Skills 標準對齊）：若 Shikigami 角色已對齊 Agent Skills 標準，A2A 整合的 interface 設計會更清晰；兩個評估可以並行但需對齊結論

**技術風險：**
- **架構不相容風險：** A2A 協議假設 agent 是 HTTP service，而 Shikigami 角色是 Claude Code Plugin 內的 Markdown 定義，兩者架構差距可能導致相容性成本極高，甚至需要引入獨立的 adapter service 層
- **安全面未知風險：** 將 Shikigami 角色暴露為外部可調用的 A2A endpoint 後，外部 agent 可能成為 prompt injection 的新攻擊向量。與 Issue #2（Prompt Injection Defense）高度相關，應在 Security gate 到位後才考慮實作

**商業風險：**
- **標準成熟度風險：** A2A 協議雖有 50+ 採用者，但相對年輕，規格可能持續演進。現在投入實作可能在標準穩定前產生技術債
- **優先級競爭風險：** 此 Issue 優先級為「低」，若框架核心問題（Issue #1 至 #4）尚未解決，A2A 研究的 opportunity cost 需要明確權衡
- **時機風險：** 相較於 Issue #5（Agent Skills 標準），A2A 涉及更深的架構變更，建議在 Issue #5 完成評估後再進行，以利兩份報告互為補充
