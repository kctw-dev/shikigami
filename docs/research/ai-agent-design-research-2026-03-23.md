# AI Agent & Sub-agent 設計研究報告
**日期：** 2026-03-23｜**自動定時任務產出**

---

## 一、社群話題

### 1.1 近期最熱討論

**多 Agent 工具在兩週內同步爆發**

2026 年 2 月，幾乎所有主要 AI 程式工具在同一個兩週視窗內發佈了多 Agent 能力：Grok Build（8 個 agent）、Windsurf（5 個平行 agent）、Claude Code Agent Teams、Codex CLI（Agents SDK）、Devin（平行 session）。「同時運行多個 agent」已從亮點功能演變為業界基本標配。

來源：[Best AI Agent Builders in 2026: Production Scores, Reddit Reality](https://webcoursesbangkok.com/best-ai-agent-builders-in-2026/)

**中文社群主要討論**

知乎與 CSDN 社群的討論焦點集中在：
- 成本控制：API 密集調用導致帳單居高不下，仍是 multi-agent 落地最大痛點
- 延遲問題：每次 LLM 調用等待數秒，multi-step agent 的總體延遲難以接受
- 企業資料隱私：企業客戶不允許資料出境，自部署 LLM 能力受限
- LangGraph 因其明確的狀態管理機制，在技術社群中持續獲得推薦

來源：[如何看待 2026 年 AI Agent 六大趨勢？ - 知乎](https://www.zhihu.com/question/1964262739229802729) | [2026 完整指南：AI Agent 框架深度測評 - CSDN](https://blog.csdn.net/Python_cocola/article/details/156233771)

**Moltbook：AI Agent 自建社群網路**

2026 年 1 月 28 日，一個名為 Moltbook 的平台作為「只允許 AI agent 發文、留言、按讚」的類 Reddit 社交網路上線，三天內超過 15 萬個 AI agent 加入，引發業界廣泛討論——AI agent 何時應擁有自主的社交表達能力？

來源：[AI Agents Build Their Own Reddit: What Moltbook Reveals - Stark Insider](https://www.starkinsider.com/2026/02/ai-agents-moltbook-human-ai-collaboration.html)

### 1.2 反覆出現但缺乏共識的問題（潛在痛點）

| 問題 | 現況 |
|------|------|
| 多 agent 系統的 observability | 非確定性行為讓傳統日誌無法追蹤，被視為「最大未解問題之一」 |
| 成本爆炸控制 | 每次 agent action 都涉及 LLM call，token cost 在多步驟鏈中呈指數成長 |
| 狀態一致性 | agent 間的共享狀態缺乏同步機制，容易引發 race condition |
| 框架碎片化 | 各大廠框架（LangGraph、CrewAI、OpenAI SDK、Google ADK）APIs 不統一 |
| 測試驗證困難 | agent 輸出是行為而非精確值，傳統 pass/fail 測試不適用 |

### 1.3 框架版本重大動態（截至 2026-03-23）

| 框架 | 最新版本 / 動態 |
|------|----------------|
| **LangGraph** | v1.1.2（Mar 12）+ CLI v0.4.16（Mar 12），強化 Platform 部署工具 |
| **OpenAI Agents SDK** | v0.12.1（Mar 13）支援跨 resume flows 的 approval rejection message；v0.12.0（Mar 12）新增 opt-in retry 機制 |
| **CrewAI** | v1.10.1（Mar 4）整合 Gemini GenAI、修復 MCP tool loading、支援 A2A Jupyter；v1.10.2a1（Mar 11）alpha 版測試中 |
| **Microsoft Agent Framework** | AutoGen + Semantic Kernel 合併，Release Candidate（Feb 19，2026），目標 Q1 GA |
| **Google ADK** | 新增 TypeScript 支援、Graph-based workflow 2.0 Alpha、ADK Python Skills，約每兩週一版 |
| **Claude Code Agent Teams** | Feb 2026 發佈，實驗性功能，多 agent 可直接通訊，省去中心化瓶頸，牆鐘時間可縮短 3-5x |

來源：[Definitive Guide to Agentic Frameworks 2026](https://softmaxdata.com/blog/definitive-guide-to-agentic-frameworks-in-2026-langgraph-crewai-ag2-openai-and-more/) | [Top 9 AI Agent Frameworks as of March 2026 - Shakudo](https://www.shakudo.io/blog/top-9-ai-agent-frameworks) | [Claude Code Agent Teams - Sitepoint](https://www.sitepoint.com/anthropic-claude-code-agent-teams/)

---

## 二、應用技巧

### 2.1 通用技巧

#### Prompt 工程 → Context Engineering 的演進

2026 年最重要的概念轉移是從「prompt engineering」到「**context engineering**」。Anthropic 在官方工程部落格中明確指出：

> 真正的問題不是找到正確的詞，而是「**什麼樣的 context 配置最能讓模型產生期望行為？**」

Context 管理四大策略（LangChain 整理）：
1. **Write**：將 context 持久化到外部（資料庫、檔案）
2. **Select**：透過 RAG 按需取回相關內容
3. **Compress**：用摘要壓縮，減少 token 佔用
4. **Isolate**：為不同 agent 使用獨立 context window

關鍵洞察：
- **Context rot**：Context window 越長，模型注意力品質越低（研究已證實）
- **Agent 失敗多是 context 失敗**：取錯文件、塞太多歷史、忘記工具定義——而非模型能力不足
- **Just-in-Time Retrieval**：不要預先載入所有資料，讓 agent 保存輕量引用（路徑、連結），在執行時動態載入

來源：[Effective Context Engineering for AI Agents - Anthropic](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)

#### Tool 設計原則

- 工具集要**最小化且功能明確**，避免語義重疊讓 agent 選錯
- 工具名稱、參數、描述要清晰，這比調整 prompt 更能改善 agent 行為
- XML-like tags 作為 delimiter 是 2026 年的業界共識（人類可讀、跨平台穩定）
- 多 agent 系統中，大量 agent failure 源自 JSON schema 不一致、field name 不統一

#### 錯誤處理

- **Risk-based routing**：風險評分高於閾值才觸發人工審核，低風險可自動執行
- **Bounded autonomy**：明確定義操作邊界、設定 escalation path
- OpenAI Agents SDK v0.12.0 開始支援 opt-in retry 機制（`ModelSettings` 層級）

### 2.2 進階技巧

#### Multi-Agent 協調架構

目前業界成熟的 multi-agent 架構有兩個主流模式：

**1. Orchestrator-Workers（中心調度）**
- 一個主 orchestrator 分解任務、指派 subagent、綜合結果
- 優點：清晰的審計路徑（每一步都有 handoff report）
- 代表：Claude Code Agent Teams（team lead 模式）、Microsoft Agent Framework

**2. Peer-to-Peer（去中心 Agent Teams）**
- Agent 彼此直接通訊、共享發現——不需中心化瓶頸
- Claude Code Agent Teams（Feb 2026）採此模式
- 缺點：協調複雜度與 agent 數量呈指數成長

#### 平行任務派遣的關鍵法則

> **黃金法則：平行只在 agent 接觸不同檔案時有效。**

Google ADK ParallelAgent 及 Claude Code 的文件都強調：平行執行的前提是任務可獨立完成，否則需加鎖或用 external message queue 管理共享狀態。

- 執行結果的順序可能不確定，下游任務要設計為對順序不敏感
- 衝突偵測是剛需：同一檔案被多個 agent 同時修改必須序列化

來源：[Parallel agents - Google ADK](https://google.github.io/adk-docs/agents/workflow-agents/parallel-agents/) | [Claude Code Sub-Agents Parallel vs Sequential](https://claudefa.st/blog/guide/agents/sub-agent-best-practices)

#### 跨 session 協作與狀態持久化

- **LangGraph**：MemorySaver / SqliteSaver / PostgresSaver 在每個 node 後自動存檔，支援 crash 後斷點續跑
- **Temporal + OpenAI Agents**：透過 workflow engine 提供內建 retry、state persistence 和 crash recovery，replay 機制可精確還原 agent 狀態
- **斷點設計原則**：state 越細粒度，recover 越精準；但 state 過多也增加儲存成本

來源：[LangGraph Deep Dive - mager.co](https://www.mager.co/blog/2026-03-12-langgraph-deep-dive/) | [Multi-Agent AI Failure Recovery - Galileo](https://galileo.ai/blog/multi-agent-ai-system-failure-recovery)

#### Agent 間制衡（Adversarial / Debate 模式）

2026 年學術與產業界都在積極驗證「對抗性辯論」提升決策品質：

- **D3 Framework（EACL 2026）**：Debate-Deliberate-Decide，由 advocate、judge、jury 角色組成的成本感知對抗框架
- **Mitsubishi Electric**：製造業首個利用 argumentation framework 產生 adversarial debate 的 multi-agent AI，取代傳統協作 AI，讓透明推理過程可追蹤
- **FREE-MAD**：Consensus-Free Multi-Agent Debate，agent 只在有明確證據時才改變立場，避免盲目跟隨多數意見

來源：[Debate, Deliberate, Decide - ACL Anthology](https://aclanthology.org/2026.eacl-long.392/) | [Mitsubishi Electric Multi-Agent AI](https://us.mitsubishielectric.com/en/pr/global/2026/0120/)

---

## 三、技術趨勢（對標 Shikigami）

### 3.1 Orchestrator 模式：Scrum Master 自動調度 vs. 業界現況

**業界最新做法：**
- 主流趨勢從「單一中心 orchestrator」分化為兩種路徑：
  1. **Graph-based deterministic orchestration**（LangGraph、Google ADK 2.0）：明確的狀態轉換圖，可預測、可審計
  2. **Autonomous peer-to-peer teams**（Claude Code Agent Teams）：agent 自行溝通，適合非結構化探索任務
- Intent detection 觸發 routing 已是業界標準，LangGraph 與 Microsoft Agent Framework 均有內建分類-派遣機制

**Shikigami 對標：**
- ✅ **領先**：Scrum Master intent detection 觸發角色並非通用框架，而是針對軟體開發流程特化的 Orchestrator，業界少見此深度的領域特化設計
- 🔄 **可借鑑**：Graph-based workflow 讓調度邏輯更可視化、更易 debug，可考慮為 Scrum Master 補充狀態圖（flowchart）文件

來源：[AI Agent Orchestration in 2026 - Kanerika](https://kanerika.com/blogs/ai-agent-orchestration/) | [Orchestrator and subagent patterns - Microsoft Copilot Studio](https://learn.microsoft.com/en-us/microsoft-copilot-studio/guidance/architecture/multi-agent-orchestrator-sub-agent)

---

### 3.2 角色制衡機制：QA challenge Architect vs. 業界現況

**業界最新做法：**
- **D3 / FREE-MAD / Mitsubishi Electric** 等 2026 年研究均驗證：adversarial debate 比純協作模式產出更高品質決策
- 學術界已將「multi-agent debate」列為 LLM evaluation 的新正規方法（D3 在 EACL 2026 發表）
- 企業界（Mitsubishi Electric）已在製造業決策場景落地，透明推理是核心賣點

**Shikigami 對標：**
- ✅ **領先**：Shikigami 的 QA challenge Architect、Security review 外部輸入早於學術主流，架構思路與最新研究高度吻合
- 🔄 **可借鑑**：FREE-MAD 的「只在有明確反證時才改變立場」機制可防止 agent 被多數意見操縱，值得引入 QA/Security 角色的 challenge 規則中

來源：[FREE-MAD: Consensus-Free Multi-Agent Debate](https://arxiv.org/pdf/2509.11035) | [Multi-Agent Debate Strategies - Emergent Mind](https://www.emergentmind.com/topics/multi-agent-debate-mad-strategies)

---

### 3.3 Parallel Dispatch + 衝突偵測 vs. 業界現況

**業界最新做法：**
- Google ADK 的 ParallelAgent 是目前最系統化的平行 agent 框架，明確要求：若需共享狀態，必須外部加鎖或用 message queue
- Qwen-code 和 Gemini CLI 都在 2026 年 Q1 積極開發原生 parallel subagent 支援（issues 仍在進行中）
- Self-Manager（arxiv 2026-01）提出用 Thread Control Block（TCB）管理平行 subthread 的新架構

**Shikigami 對標：**
- ✅ **領先**：同檔案衝突偵測 + 自動序列化是 Shikigami 的核心特色，Google ADK 等框架雖有平行能力但需開發者自行處理衝突
- 🔄 **可借鑑**：TCB（Thread Control Block）概念可為 Shikigami 的 task tracking 提供更形式化的模型，便於 crash recovery 和 session 斷點管理

來源：[Parallel agents - Google ADK](https://google.github.io/adk-docs/agents/workflow-agents/parallel-agents/) | [Self-Manager Parallel Agent Loop - arxiv](https://arxiv.org/pdf/2601.17879)

---

### 3.4 跨機器多團隊協調：Issue 級 claim + 檔案級鎖定 vs. 業界現況

**業界最新做法：**
- **LangGraph** 的 PostgresSaver 支援跨 session 的持久化狀態，是目前生產環境最成熟的方案
- **Temporal + Agents** 組合：workflow engine 提供分散式系統級的 state replay 和 crash recovery，但複雜度較高
- **Microsoft Bulletproof Agents**（Feb 2026）：透過 Durable Task Extension 讓 Microsoft Agent Framework 支援長時間執行、crash-safe 的 agent workflow

**Shikigami 對標：**
- ✅ **領先**：Issue 級 claim + 檔案級鎖定是針對 Git-based 軟體開發場景的高度特化設計，通用框架不會提供此粒度的協調機制
- ⚠️ **需追蹤**：Temporal 的 workflow replay 模式在 high-availability 場景下表現優於 file-based lock，可評估是否作為 session crash 斷點續跑的備選方案

來源：[Bulletproof agents - Microsoft Community Hub](https://techcommunity.microsoft.com/blog/appsonazureblog/bulletproof-agents-with-the-durable-task-extension-for-microsoft-agent-framework/4467122) | [Temporal + LangGraph 兩層架構](https://www.cnblogs.com/lightsong/p/19530436)

---

### 3.5 TDD 驅動開發流程 vs. 業界現況

**業界最新做法：**
- **TDAD（Test-Driven Agentic Development）**（arxiv 2603.17973，2026 年 3 月）：建立 source code 與 test 的 dependency map，讓 agent 在 commit 前知道「哪些測試要驗」而非「怎麼做 TDD」，顯著降低 regression
- **Simon Willison 的 Red/Green TDD 指南**：將 TDD 列為 agentic engineering 的正規模式，認為 AI agent 天然適合 TDD（binary test = 清晰目標）
- **martinfowler.com**（Jan 2026）認可：TDD 在 AI 輔助開發中作為「forcing function」讓開發者保持理解

**Shikigami 對標：**
- ✅ **對齊**：Red→Green→Refactor 由 Developer subagent 執行，與業界 2026 年的新實踐高度吻合
- 🔄 **可借鑑**：TDAD 的 dependency map 思路（讓 agent 知道「影響哪些測試」）可提升 Shikigami Developer 的 TDD 執行精準度，減少不必要的全量測試執行

來源：[TDAD Paper - arxiv](https://arxiv.org/html/2603.17973v1) | [Red/green TDD - Simon Willison](https://simonwillison.net/guides/agentic-engineering-patterns/red-green-tdd/) | [AI Agents meet TDD - Latent Space](https://www.latent.space/p/anita-tdd)

---

### 3.6 品質門禁（Quality Gate）雙階段審查 vs. 業界現況

**業界最新做法：**
- **Risk-based routing**（2026 Q1 標準實踐）：依據風險評分決定是否觸發人工審核，高風險 → 全三層驗證
- **Layered guardrails**：OpenAI、Google、Anthropic 均建議用多個專門化 guardrail 疊加，而非單一大型 guardrail
- **重要警告**：63% 的組織無法有效控制自己的 AI，因為 model-level guardrail（system prompt）無法防 prompt injection，需要 infrastructure-level 的隔離

**Shikigami 對標：**
- ✅ **對齊**：雙階段審查（Spec Compliance + Code Quality）結構清晰，符合「layered guardrails」思路
- ⚠️ **需補強**：明確加入「prompt injection 防禦層」，特別是處理外部輸入的 Security 角色

來源：[AI Agent Guardrails: Production Guide 2026](https://authoritypartners.com/insights/ai-agent-guardrails-production-guide-for-2026/) | [8 Best AI Agent Guardrails Solutions - Galileo](https://galileo.ai/blog/best-ai-agent-guardrails-solutions)

---

### 3.7 多平台支援：MCP / A2A 協議標準化動態

**業界最新動態：**

| 協議 | 創建者 | 現況（2026-03） |
|------|--------|----------------|
| **MCP**（Model Context Protocol）| Anthropic → Linux Foundation（Dec 2025）| 每月 9700 萬次 SDK 下載；所有主要 AI 廠商（Anthropic、OpenAI、Google、Microsoft、Amazon）採用 |
| **A2A**（Agent-to-Agent Protocol）| Google → Linux Foundation（Jun 2025）| 50+ 技術夥伴（Atlassian、Box、Salesforce 等）+ 主要諮詢公司 |
| **ACP**（Agent Communication Protocol）| 社群提案 | 仍在標準制定討論中 |
| **Agent Skills** | Anthropic（開放標準）| 16+ AI 工具採用，Canva、Notion、Figma、Atlassian 有官方 skill |

**核心分工：**
- **MCP** = agent 如何連接工具、資料、服務（對外）
- **A2A** = agent 之間如何溝通協作（對 agent）

**Shikigami 對標：**
- ✅ **對齊**：支援 Claude Code / OpenCode / Gemini CLI / Cursor 多平台，方向符合業界標準化趨勢
- 🔄 **可借鑑**：A2A 協議的標準化讓不同框架的 agent 可互相通訊，未來 Shikigami 角色可考慮發布為 A2A-compatible agents，擴大生態系相容性

來源：[MCP vs A2A: Protocols for Multi-Agent Collaboration 2026](https://onereach.ai/blog/guide-choosing-mcp-vs-a2a-protocols/) | [Developer's Guide to AI Agent Protocols - Google](https://developers.googleblog.com/developers-guide-to-ai-agent-protocols/)

---

### 3.8 專案自治等級（low/medium/high）vs. 業界現況

**業界最新做法：**
- 主流觀念收斂到 **「bounded autonomy」**：90% 任務自主執行，但高風險操作（$10,000 以上交易、法律合約）強制 human confirmation
- **Gartner 2025 報告**：AI Agent Ecosystem 是 2026 年最關鍵的策略性技術趨勢，驅動力是 multi-agent 協作架構
- **從 compliance overhead → enabler**：組織已從「governance 是負擔」轉為「governance 讓我們敢部署更高價值任務」

**Shikigami 對標：**
- ✅ **對齊**：low/medium/high 自治等級控制與業界 bounded autonomy 思路高度吻合
- 🔄 **可借鑑**：加入明確的 kill switch capability（目前業界只有 40% 的組織有此能力），讓 high 自治模式有緊急停止機制

來源：[AI Agent Data Governance 2026 - Kiteworks](https://www.kiteworks.com/cybersecurity-risk-management/ai-agent-data-governance-why-organizations-cant-stop-their-own-ai/) | [7 Agentic AI Trends to Watch in 2026](https://machinelearningmastery.com/7-agentic-ai-trends-to-watch-in-2026/)

---

## 四、改進方向

### 4.1 官方最新動態摘要

#### Anthropic
- **Agent Skills 開放標準**（Dec 2025 → 持續擴展）：SKILL.md 架構讓能力可跨平台移植，已有 16+ 工具採用，Shikigami 的角色定義可考慮遵循此格式標準化
- **Context Engineering 官方文章**（2026 Q1）：強調「最小高訊號 token」，對 Shikigami 的 context 設計有直接指引意義
- **Claude Code Agent Teams**（Feb 2026）：Peer-to-peer agent 通訊，可能是未來 Shikigami 角色間通訊的演進方向
- **Anthropic 設計原則**：從最簡單架構開始，只在必要時加入複雜性；Shikigami 的複雜度需持續評估是否每個角色都帶來真實價值

來源：[Equipping Agents with Agent Skills - Anthropic](https://claude.com/blog/equipping-agents-for-the-real-world-with-agent-skills) | [Building Effective Agents - Anthropic](https://www.anthropic.com/research/building-effective-agents)

#### OpenAI
- **Agents SDK v0.12.x**（Mar 2026）：Opt-in retry、approval rejection persistence，生產穩定性持續提升
- **官方實踐指南**：不是每個任務都需要最強模型——routing + 任務分類後派遣合適大小的模型，可大幅降低成本
- **Safety 指南**：多個專門化 guardrail 疊加比單一大型 guardrail 更有彈性

來源：[A Practical Guide to Building Agents - OpenAI](https://openai.com/business/guides-and-resources/a-practical-guide-to-building-ai-agents/)

#### Google
- **ADK 2.0 Alpha**：Graph-based workflow + TypeScript 支援（2026 Q1）
- **A2A 協議**：已捐給 Linux Foundation，成為跨廠商 agent 通訊標準
- **A2UI（Agent-to-UI）**：標準化 AI agent 建立視覺化回應的方式，Apache 2.0 開源

#### Microsoft
- **Microsoft Agent Framework RC（Feb 19，2026）**：AutoGen + Semantic Kernel 合併，Q1 目標 GA
- **Durable Task Extension**：Bulletproof agents 的 crash-safe workflow，適合長時間運行的 multi-agent 系統

---

### 4.2 常見陷阱與失敗案例（2026 年新發現）

**1. "Bag of Agents" 反模式**
多個 LLM 無結構地串聯（flat topology），導致：circular logic 幻覺迴圈、資訊雜訊爆炸、17x 錯誤放大效應（Towards Data Science 研究）。

解法：明確定義 agent 拓撲結構（圖或樹），不允許自由互連。

**2. 任務粒度過大**
單一 agent 的任務範圍太廣，是多 agent 系統失敗的根本原因之一，而非模型能力不足。

解法：「任務分解是否到位」要先於「選什麼框架」。

**3. Agent-as-Business-Process 反模式**
用 agent 近似業務流程（走「最可能的路徑」），而非執行流程（走「必要的路徑」）。在高合規場景（金融、醫療）風險極高。

**4. 非確定性與 Observability 缺失**
相同輸入產生不同執行路徑，無法可靠地重現 bug，傳統監控無效。

解法：為每個 agent action 記錄 structured trace（輸入、輸出、選擇的工具、時間戳）。

**5. 跨規模行為崩潰**
100 req/min 完美運行的編排模式，在 10,000 req/min 時完全崩潰。

解法：早期壓力測試，不要等到上線才發現協調開銷是瓶頸。

來源：[AI Agent Anti-Patterns Part 1 - Medium](https://achan2013.medium.com/ai-agent-anti-patterns-part-1-architectural-pitfalls-that-break-enterprise-agents-before-they-32d211dded43) | [Why Your Multi-Agent System is Failing - Towards Data Science](https://towardsdatascience.com/why-your-multi-agent-system-is-failing-escaping-the-17x-error-trap-of-the-bag-of-agents/) | [12 Failure Patterns of Agentic AI Systems - Concentrix](https://www.concentrix.com/insights/blog/12-failure-patterns-of-agentic-ai-systems/)

---

### 4.3 具體可應用到 Shikigami 的改進建議

| 優先級 | 建議 | 依據 |
|--------|------|------|
| 🔴 高 | 為每個 agent action 加入 **structured trace log**（含 agent role、輸入摘要、輸出摘要、時間戳），解決 observability 問題 | 業界公認最大痛點 |
| 🔴 高 | 在 Security 角色加入 **prompt injection 防禦檢查**，特別是外部輸入（需求文件、使用者 story）進入 Architect/Developer pipeline 前 | 業界研究：model-level guardrail 不足以防禦 |
| 🟡 中 | 導入 **TDAD dependency map**：Developer 執行 TDD 前先建立 source↔test 依賴圖，只執行受影響的測試，降低 regression | TDAD 論文（2026-03）驗證有效 |
| 🟡 中 | 為 Scrum Master 的任務分解加入 **衝突預測**：在派遣 Parallel 任務前，分析潛在的檔案重疊，優化序列化策略 | 平行 agent 最常見失敗原因 |
| 🟡 中 | 評估 Shikigami 角色定義是否遵循 **Agent Skills 開放標準（agentskills.io）**，提升跨平台移植性 | Anthropic 開放標準，16+ 工具採用 |
| 🟢 低 | QA 角色的 challenge 規則加入 **FREE-MAD 的「只在有明確反證時才改變立場」** 約束，防止 QA 被 Architect 說服而撤回有效挑戰 | FREE-MAD 研究（2026）|
| 🟢 低 | 評估 high 自治模式下加入 **Kill Switch** 機制（緊急暫停所有 subagent 執行）| 業界只有 40% 組織具備此能力，卻是 governance 核心 |
| 🟢 低 | 研究 **A2A 協議相容性**：若 Shikigami 角色未來需跨框架協作，A2A 是業界方向 | Google + Linux Foundation 主導 |

---

## 附錄：完整來源清單

**社群話題**
- [Best AI Agent Builders in 2026: Production Scores, Reddit Reality](https://webcoursesbangkok.com/best-ai-agent-builders-in-2026/)
- [AI Agents Build Their Own Reddit: What Moltbook Reveals - Stark Insider](https://www.starkinsider.com/2026/02/ai-agents-moltbook-human-ai-collaboration.html)
- [如何看待 2026 年 AI Agent 六大趋势？ - 知乎](https://www.zhihu.com/question/1964262739229802729)
- [2026 AI Agent 框架深度测评 - CSDN](https://blog.csdn.net/Python_cocola/article/details/156233771)

**框架動態**
- [Definitive Guide to Agentic Frameworks 2026](https://softmaxdata.com/blog/definitive-guide-to-agentic-frameworks-in-2026-langgraph-crewai-ag2-openai-and-more/)
- [Top 9 AI Agent Frameworks as of March 2026 - Shakudo](https://www.shakudo.io/blog/top-9-ai-agent-frameworks)
- [Claude Code Agent Teams - Sitepoint](https://www.sitepoint.com/anthropic-claude-code-agent-teams/)
- [Claude Code Agent Teams Guide - Medium](https://bertomill.medium.com/tldr-agent-teams-multi-agent-coordination-in-claude-code-a73590d8453f)
- [Microsoft Agent Framework GA Strategy](https://jangwook.net/en/blog/en/microsoft-agent-framework-ga-production-strategy/)
- [AI Agent News March 2026 Roundup - Moltbook](https://moltbook-ai.com/posts/ai-agents-march-2026-roundup)

**技術研究**
- [Effective Context Engineering for AI Agents - Anthropic](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Building Effective Agents - Anthropic](https://www.anthropic.com/research/building-effective-agents)
- [Equipping Agents with Agent Skills - Anthropic](https://claude.com/blog/equipping-agents-for-the-real-world-with-agent-skills)
- [TDAD: Test-Driven Agentic Development - arxiv](https://arxiv.org/html/2603.17973v1)
- [Self-Manager Parallel Agent Loop - arxiv](https://arxiv.org/pdf/2601.17879)
- [Parallel agents - Google ADK](https://google.github.io/adk-docs/agents/workflow-agents/parallel-agents/)
- [Spring AI Agentic Patterns: Subagent Orchestration](https://spring.io/blog/2026/01/27/spring-ai-agentic-patterns-4-task-subagents)
- [Debate, Deliberate, Decide (D3) - ACL Anthology](https://aclanthology.org/2026.eacl-long.392/)
- [FREE-MAD Paper - arxiv](https://arxiv.org/pdf/2509.11035)

**協議標準**
- [MCP vs A2A: Protocols for Multi-Agent Collaboration 2026](https://onereach.ai/blog/guide-choosing-mcp-vs-a2a-protocols/)
- [A2A Protocol Explained - Codilime](https://codilime.com/blog/a2a-protocol-explained/)
- [Developer's Guide to AI Agent Protocols - Google](https://developers.googleblog.com/developers-guide-to-ai-agent-protocols/)
- [Anthropic Launches Skills Open Standard - AI Business](https://aibusiness.com/foundation-models/anthropic-launches-skills-open-standard-claude)

**Guardrails / 治理**
- [AI Agent Guardrails: Production Guide 2026](https://authoritypartners.com/insights/ai-agent-guardrails-production-guide-for-2026/)
- [8 Best AI Agent Guardrails Solutions - Galileo](https://galileo.ai/blog/best-ai-agent-guardrails-solutions)
- [AI Agent Data Governance 2026 - Kiteworks](https://www.kiteworks.com/cybersecurity-risk-management/ai-agent-data-governance-why-organizations-cant-stop-their-own-ai/)
- [Agentic AI in Production: Guardrails 2026 Guide - Medium](https://medium.com/@dewasheesh.rana/agentic-ai-in-production-designing-autonomous-multi-agent-systems-with-guardrails-2026-guide-a5a1c8461772)

**失敗案例**
- [AI Agent Anti-Patterns Part 1 - Medium](https://achan2013.medium.com/ai-agent-anti-patterns-part-1-architectural-pitfalls-that-break-enterprise-agents-before-they-32d211dded43)
- [Why Your Multi-Agent System is Failing - Towards Data Science](https://towardsdatascience.com/why-your-multi-agent-system-is-failing-escaping-the-17x-error-trap-of-the-bag-of-agents/)
- [12 Failure Patterns of Agentic AI Systems - Concentrix](https://www.concentrix.com/insights/blog/12-failure-patterns-of-agentic-ai-systems/)
- [Multi-Agent Workflows Often Fail - GitHub Blog](https://github.blog/ai-and-ml/generative-ai/multi-agent-workflows-often-fail-heres-how-to-engineer-ones-that-dont/)

**TDD**
- [Red/green TDD - Simon Willison](https://simonwillison.net/guides/agentic-engineering-patterns/red-green-tdd/)
- [AI Agents meet TDD - Latent Space](https://www.latent.space/p/anita-tdd)
- [Why TDD Works Well in AI-assisted Programming](https://codemanship.wordpress.com/2026/01/09/why-does-test-driven-development-work-so-well-in-ai-assisted-programming/)

**狀態持久化 / Crash Recovery**
- [LangGraph Deep Dive - mager.co](https://www.mager.co/blog/2026-03-12-langgraph-deep-dive/)
- [Bulletproof agents - Microsoft Community Hub](https://techcommunity.microsoft.com/blog/appsonazureblog/bulletproof-agents-with-the-durable-task-extension-for-microsoft-agent-framework/4467122)
- [Multi-Agent AI Failure Recovery - Galileo](https://galileo.ai/blog/multi-agent-ai-system-failure-recovery)

---

*本報告由自動定時任務產出，資料截止日：2026-03-23。次次執行將更新所有內容。*
