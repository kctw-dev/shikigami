# A2A 協議相容性評估報告

**文件類型**：Research
**日期**：2026-03-24
**作者**：Architect Agent（Sprint 139 #399）
**PB 來源**：docs/discovery/PB-2026-03-23-a2a-protocol.md
**Issue**：#399（來自 #342 研究報告 Issue #8）

---

## 1. A2A 協議規格摘要

### 1.1 基本資訊

**A2A（Agent-to-Agent Protocol）**由 Google 主導，於 2025 年 5 月在 Google Cloud Next 發佈，同年 6 月捐贈給 Linux Foundation。截至 2026 年 3 月：

- **規格位置**：[google.github.io/A2A](https://google.github.io/A2A)
- **技術夥伴**：50+ 企業（Atlassian、Box、Salesforce、SAP、ServiceNow、MongoDB 等）
- **生態狀態**：CrewAI v1.10.1 已宣布整合 A2A；Google ADK 原生支援；LangChain/LangGraph 正在評估

### 1.2 核心概念

A2A 定義了 Agent 間通訊的標準化介面，核心元素：

| 元素 | 說明 |
|------|------|
| **Agent Card** | JSON 格式的 Agent 能力描述文件（類似 OpenAPI spec for agents），描述 Agent 能執行的任務類型、輸入/輸出格式 |
| **Task** | Agent 間委託的工作單元，含 task_id、message、context |
| **Message** | 通訊訊息格式（role: user/agent + Parts: text/data/file）|
| **Artifact** | Task 的輸出物（file、data、text）|
| **Transport** | HTTP（HTTPS REST）+ Server-Sent Events（streaming）|
| **Authentication** | OpenID Connect / API Key / OAuth 2.0 |

### 1.3 A2A 的設計哲學

A2A 聚焦於「**不透明的 agent 間委託**」：呼叫方不需要知道被呼叫 Agent 的內部實作（模型、framework），只需要知道其 Agent Card 宣告的能力。

這與 MCP（Model Context Protocol）的定位不同：
- **MCP**：工具暴露（Agent → Tool）
- **A2A**：任務委託（Agent → Agent）

---

## 2. Shikigami 架構與 A2A 的對應分析

### 2.1 Shikigami 現有架構

```
使用者
  ↓
Scrum Master（主 session）← 主入口，Claude Code Plugin
  ├── Sprint Planning Skill → 派遣 PO/Architect/QA subagents
  ├── Sprint Execution Skill → 派遣 Story-Lifecycle subagents（worktree 隔離）
  └── Sprint Review Skill → 派遣 subagents
        │
        └── Subagent（Claude Agent tool）← 內部通訊，非標準化
```

**現有通訊模式**：Scrum Master 以 Claude Code 的 `Agent` tool 派遣 subagent，傳入 YAML 格式的輸入，接收 Markdown 格式的輸出。這是**緊耦合、非標準化**的通訊。

### 2.2 A2A 概念對應

| Shikigami 角色 | A2A 對應概念 | Agent Card 潛在能力宣告 |
|---------------|------------|----------------------|
| Scrum Master | A2A Orchestrator | `execute-sprint`, `plan-sprint`, `review-sprint` |
| PO Agent | A2A Executor（planning 類）| `backlog-triage`, `story-selection` |
| Architect Agent | A2A Executor（architecture 類）| `technical-evaluation`, `adr-creation` |
| QA Agent | A2A Executor（quality 類）| `ac-validation`, `test-planning` |
| Developer（Story-Lifecycle）| A2A Executor（implementation 類）| `implement-story`, `code-review` |

### 2.3 相容性評估

**相容程度：中（Medium）**

| 評估維度 | 現狀 | A2A 相容性 | 說明 |
|---------|------|-----------|------|
| 通訊格式 | YAML/Markdown 非結構化 | 低 | A2A 要求 JSON messages；需要 adapter |
| 任務邊界 | Sprint/Story 隱式邊界 | 中 | A2A Task 概念與 Story 可對應，但需顯式定義 |
| Agent 能力宣告 | 無標準化描述（嵌入 SKILL.md）| 低 | 需建立 Agent Card（JSON）for each role |
| Transport | Claude Code 內部 Agent tool | 低 | A2A 要求 HTTPS transport；重大架構改動 |
| Authentication | Claude Code OAuth（plugin 層）| 中 | A2A 的 OpenID Connect 可整合 |
| 狀態管理 | Sprint checkpoint（per-session files）| 高 | A2A 的 Task 狀態與 Shikigami checkpoint 相容 |
| 多框架整合 | 僅 Claude Code（+ OpenCode/Gemini 有限支援）| 低 | A2A 的核心價值（跨框架）需要 transport 層重構 |

**相容性評分**：

| 面向 | 分數（1-5）| 說明 |
|------|-----------|------|
| 概念層相容性 | 4/5 | Role→AgentCard，Story→Task 概念對應自然 |
| 技術層相容性 | 2/5 | Transport、格式均需重大改動 |
| 實作成本 | 1/5（成本高）| 需要建立 HTTP server + Agent Cards + adapter layer |
| 業務價值 | 3/5 | 多框架整合有真實需求，但用戶群目前有限 |

---

## 3. 整合建議

### 3.1 建議：**觀望**（Watch and Wait）

**理由**：

1. **當前用戶群不需要跨框架整合**：Shikigami 的主要用戶群使用 Claude Code 作為唯一框架，A2A 的核心價值（與 CrewAI/LangGraph 互操作）目前沒有需求
2. **技術層改動成本高**：需要引入 HTTP server 層、Agent Card JSON 格式、A2A Task 生命週期管理，這些都不在現有 Plugin 架構內
3. **A2A 生態仍在成熟**：雖有 50+ 夥伴，但企業生產採用案例仍在早期。等待 2026 Q3-Q4 看採用曲線
4. **先完成內部穩定性工作**：TCB Checkpoint（#404）、Crash Recovery（#405）、Session Watchdog（#408）等正在進行的工作優先級更高

### 3.2 觀望觸發點（自動升級為 Sprint 候選的條件）

以下任一條件達成時，重新評估並開啟 A2A 整合 Story：

| 觸發條件 | 動作 |
|---------|------|
| Shikigami 用戶中有 3+ 人提出跨框架整合需求（GitHub Issues）| 開啟 A2A Adapter Story（估計 L-size）|
| CrewAI/LangGraph 發布穩定的 A2A SDK（v1.0+）| 重新評估整合成本 |
| A2A 被 Anthropic Claude Code 官方支援 | 優先考慮整合 |
| Shikigami 完成 v1.0.0 外部發布里程碑 | 將 A2A 列入 M6 規劃 |

### 3.3 低成本前置工作（不需等待，可現在做）

若決定未來整合 A2A，以下工作可以低成本現在準備：

| 工作 | 成本 | 說明 |
|------|------|------|
| 為每個 Agent 角色撰寫 Agent Card draft（docs/）| S（1pt）| 只是 JSON 文件，無架構改動 |
| 在 plugin.json 新增 A2A 相容性宣告欄位 | S（0.5pt）| 未來 marketplace 發現性 |
| CLAUDE.md 新增 A2A 整合路線圖說明 | S（0.5pt）| 文件化意圖 |

---

## 4. 後續 Story 草稿（若觀望期後決定實作）

以下草稿供未來 PO 排程參考：

**Story A（觸發條件達成後第 1 Sprint）**：
> feat: A2A Agent Card 定義 — 為 8 個角色建立標準化能力宣告文件
> Size: S（1pt）| Type: RESEARCH/DESIGN

**Story B（Story A 完成後）**：
> feat: A2A Adapter Layer — SM 作為 A2A Orchestrator，支援外部 Agent 呼叫 Shikigami Roles
> Size: L（3pt）| Type: FEATURE | 需 ADR

**Story C（Story B 完成後）**：
> test: A2A 端對端整合測試 — Shikigami ↔ CrewAI/LangGraph 雙向呼叫驗證
> Size: M（2pt）| Type: INTEGRATION

---

## 5. 結論

| 問題 | 結論 |
|------|------|
| A2A 協議是否成熟？ | 是，有 50+ 企業夥伴，但企業生產案例仍早期 |
| Shikigami 架構是否相容 A2A？ | 概念層相容（中等），技術層需重大改動（低相容）|
| 現在是否應實作 A2A 整合？ | **否，建議觀望** |
| 何時重新評估？ | 用戶跨框架需求出現、A2A SDK 穩定、或 v1.0.0 發布後 |

---

*由 Sprint 139 #399 RESEARCH Story 產出*
