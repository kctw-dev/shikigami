# Shikigami 改進 Issues
**來源：** AI Agent 設計研究報告（2026-03-23）
**共 8 個 Issue｜優先級：🔴 高 ×2　🟡 中 ×3　🟢 低 ×3**

---

## Issue #1 🔴 [feat] 加入 Structured Trace Log，解決 Observability 問題

**Labels:** `enhancement` `observability` `priority:high`

### 背景

多 agent 系統的 observability 是 2026 年業界公認最大未解痛點。由於 agent 行為是非確定性的，相同輸入可能產生不同執行路徑，傳統日誌無法追蹤，導致 bug 難以重現。

### 問題描述

Shikigami 目前缺乏每個 agent action 的結構化執行記錄，當多角色並行執行時，若發生錯誤或意外行為，難以從日誌中還原整個決策鏈。

### 建議做法

為每個 agent action 記錄以下欄位：

```json
{
  "timestamp": "ISO8601",
  "agent_role": "Developer | QA | Architect | ...",
  "action_type": "tool_call | message | decision",
  "input_summary": "...",
  "output_summary": "...",
  "tool_used": "...",
  "duration_ms": 1234,
  "session_id": "...",
  "parent_task_id": "..."
}
```

### 驗收條件

- [ ] 所有 8 個角色的 action 均有結構化 trace 輸出
- [ ] Trace log 支援依 session_id 過濾，可重建單次 sprint 的完整執行路徑
- [ ] 在 high 自治模式下，trace log 自動儲存至外部（檔案或 DB）

### 參考資料

- [12 Failure Patterns of Agentic AI Systems - Concentrix](https://www.concentrix.com/insights/blog/12-failure-patterns-of-agentic-ai-systems/)
- [Multi-Agent System Reliability - Maxim AI](https://www.getmaxim.ai/articles/multi-agent-system-reliability-failure-patterns-root-causes-and-production-validation-strategies/)

---

## Issue #2 🔴 [security] Security 角色加入 Prompt Injection 防禦檢查

**Labels:** `security` `guardrails` `priority:high`

### 背景

業界研究（2026）明確指出：model-level guardrail（system prompt 層級）無法防禦 prompt injection，必須在 infrastructure 層面加入輸入清洗機制。目前 63% 的組織無法有效控制自己的 AI，部分原因正是只依賴 model-level 防禦。

### 問題描述

Shikigami 的 Security 角色目前負責 Code Security Review，但外部輸入（用戶需求文件、User Story、外部 API 回應）在進入 Architect / Developer pipeline 前，沒有經過 prompt injection 掃描。惡意構造的需求文件可能夾帶指令，劫持 agent 行為。

### 建議做法

在以下兩個進入點前加入 Security 角色的 prompt injection 防禦 gate：

1. **需求文件輸入** → PO 收到原始需求後、Architect 開始設計前
2. **外部工具回應** → 任何 external API call 的回應進入 agent context 前

防禦檢查清單：
- 是否包含角色覆寫指令（`ignore previous instructions`）
- 是否嘗試提升權限（`you are now admin`）
- 是否包含隱藏指令（white text、base64 encoded content）

### 驗收條件

- [ ] PO 角色在處理外部需求前觸發 Security 的 injection scan
- [ ] scan 結果為 HIGH RISK 時，流程暫停並通知 Stakeholder 角色
- [ ] 防禦規則可在 SECURITY_RULES.md 中配置，不寫死在 prompt

### 參考資料

- [AI Agent Guardrails: Production Guide 2026](https://authoritypartners.com/insights/ai-agent-guardrails-production-guide-for-2026/)
- [AI Agent Data Governance 2026 - Kiteworks](https://www.kiteworks.com/cybersecurity-risk-management/ai-agent-data-governance-why-organization-cant-stop-their-own-ai/)

---

## Issue #3 🟡 [feat] Developer 角色導入 TDAD Dependency Map，精準執行 TDD

**Labels:** `enhancement` `tdd` `developer-role` `priority:medium`

### 背景

2026 年 3 月，arxiv 發表 TDAD（Test-Driven Agentic Development）論文，發現一個關鍵洞察：**讓 agent 知道「哪些測試要驗」比告訴它「怎麼做 TDD」更有效**。單純的 TDD prompting 反而增加 9.94% 的 regression，但加入 source↔test 依賴圖後顯著改善。

### 問題描述

Shikigami Developer 目前執行 Red→Green→Refactor 時，每次變更後可能觸發全量測試，既耗時也不精準。若能在修改前先建立影響範圍分析，可大幅提升 TDD 循環效率。

### 建議做法

在 Developer subagent 的 TDD 執行流程中加入「Pre-TDD Dependency Analysis」步驟：

```
[Developer TDD Flow]
1. 接收任務（修改 file_A.py）
2. 🆕 建立 dependency map：掃描哪些 test_*.py 直接或間接 import file_A
3. Red phase：只執行受影響的測試，確認 fail
4. Green phase：實作最小修改讓測試通過
5. Refactor phase：重構，再次執行受影響測試確認
6. 輸出 summary（包含哪些測試被執行、是否全部通過）
```

### 驗收條件

- [ ] Developer 在每次 code change 前輸出受影響測試清單
- [ ] 全量測試只在 Refactor 完成後的最終 QA Gate 才觸發
- [ ] Dependency map 支援 Python、TypeScript（最少兩種語言）

### 參考資料

- [TDAD: Test-Driven Agentic Development - arxiv](https://arxiv.org/html/2603.17973v1)
- [Red/green TDD - Simon Willison](https://simonwillison.net/guides/agentic-engineering-patterns/red-green-tdd/)

---

## Issue #4 🟡 [feat] Scrum Master 加入平行任務衝突預測，優化序列化策略

**Labels:** `enhancement` `parallel-dispatch` `scrum-master-role` `priority:medium`

### 背景

平行 agent 執行的黃金法則：**只在 agent 接觸不同檔案時才能真正平行**（Google ADK、Claude Code 文件均強調此點）。目前業界最常見的 multi-agent 失敗原因之一，就是多個 agent 同時修改同一個檔案，導致 race condition 或 merge conflict。

### 問題描述

Shikigami 已有同檔案衝突偵測與自動序列化，但衝突偵測發生在「執行時」，造成不必要的等待。若能在 Scrum Master 派遣任務時「預測衝突」，可以更主動地優化任務分組。

### 建議做法

在 Scrum Master 的 Parallel Dispatch 前加入靜態衝突分析：

```
[Parallel Dispatch Flow]
1. 接收 Sprint Backlog（N 個任務）
2. 🆕 衝突預測：為每個任務分析預計修改的檔案集合
3. 🆕 任務分組：
   - Group A（可平行）：檔案集合互不重疊的任務
   - Group B（需序列）：共享檔案的任務
4. 先派遣 Group A 平行執行
5. Group A 完成後，序列執行 Group B
6. 輸出 dispatch plan，讓 Stakeholder 可視
```

### 驗收條件

- [ ] Scrum Master 在派遣前輸出任務分組計劃（平行 vs. 序列）
- [ ] 預測準確率追蹤（預計衝突 vs. 實際衝突），作為品質指標
- [ ] 當 Group B 因 Group A 的變更而改變衝突狀態時，動態重新評估

### 參考資料

- [Parallel agents - Google ADK](https://google.github.io/adk-docs/agents/workflow-agents/parallel-agents/)
- [Claude Code Sub-Agents Parallel vs Sequential](https://claudefa.st/blog/guide/agents/sub-agent-best-practices)
- [Self-Manager Parallel Agent Loop - arxiv](https://arxiv.org/pdf/2601.17879)

---

## Issue #5 🟡 [chore] 評估 Shikigami 角色定義對齊 Agent Skills 開放標準

**Labels:** `compatibility` `open-standard` `chore` `priority:medium`

### 背景

Anthropic 於 2025 年 12 月將 Agent Skills 發佈為開放標準（agentskills.io），截至 2026 年 3 月已有 16+ 主要 AI 工具採用（包含 Canva、Notion、Figma、Atlassian 的官方 skill）。標準的核心結構是帶有 YAML frontmatter 的 SKILL.md 檔案，支援三層資訊階層（metadata → 核心指令 → 動態載入的補充資源）。

### 問題描述

Shikigami 的 8 個角色定義目前是框架內部格式，未對齊 Agent Skills 開放標準。若未來有跨平台移植或社群貢獻的需求，標準化格式可大幅降低遷移成本。

### 建議做法

1. 閱讀 [agentskills.io](https://agentskills.io) 開放標準規格
2. 評估 Shikigami 現有角色定義（PO、Architect、Developer、QA、Security、SRE、UI/UX、Stakeholder）與標準的差距
3. 提出遷移計劃：哪些部分可直接對齊，哪些需要框架特化擴充

### 驗收條件

- [ ] 完成現有格式 vs. Agent Skills 標準的 Gap Analysis 文件
- [ ] 至少一個角色（建議選 Developer）作為 PoC，遷移至標準格式並驗證功能不受影響
- [ ] 若遷移有技術限制，記錄原因並提出備選方案

### 參考資料

- [Equipping Agents with Agent Skills - Anthropic](https://claude.com/blog/equipping-agents-for-the-real-world-with-agent-skills)
- [Anthropic Launches Skills Open Standard - AI Business](https://aibusiness.com/foundation-models/anthropic-launches-skills-open-standard-claude)
- [Agent Skills Guide 2026 - Serenities AI](https://serenitiesai.com/articles/agent-skills-guide-2026)

---

## Issue #6 🟢 [feat] QA 角色加入 FREE-MAD「有明確反證才改變立場」機制

**Labels:** `enhancement` `qa-role` `check-and-balance` `priority:low`

### 背景

FREE-MAD（Consensus-Free Multi-Agent Debate）研究（2026）發現：在 multi-agent debate 中，agent 常因「多數意見壓力」而撤回原本正確的異議，造成群體盲思。解法是引入「只在有明確反證時才改變立場」的強制約束，讓 challenger 角色更有韌性。

### 問題描述

Shikigami QA 角色在 challenge Architect 決策時，若 Architect 給出解釋，QA 可能傾向接受而撤回挑戰——即使 Architect 的解釋不夠有力。這削弱了制衡機制的實際效果。

### 建議做法

在 QA 角色的 challenge 規則中加入以下約束：

```
QA Challenge Protocol:
1. 提出挑戰時，記錄挑戰的核心依據（test case / spec reference）
2. 收到 Architect 回應後，評估回應是否提供了「新的技術證據」
3. 判斷標準：
   - ✅ 可接受並撤回挑戰：回應包含 QA 未考慮到的新測試數據 / spec 條文
   - ❌ 不可接受（維持挑戰）：回應只是重新解釋相同觀點，或訴諸權威
4. 若維持挑戰，觸發 Stakeholder 的仲裁流程
```

### 驗收條件

- [ ] QA 角色在撤回挑戰前必須輸出「撤回原因說明」（含引用 Architect 的哪段論點）
- [ ] QA 維持挑戰超過 2 輪時，自動升級至 Stakeholder 仲裁
- [ ] 新增 QA challenge 的回合數統計到 sprint report

### 參考資料

- [FREE-MAD: Consensus-Free Multi-Agent Debate](https://arxiv.org/pdf/2509.11035)
- [Multi-Agent Debate Strategies - Emergent Mind](https://www.emergentmind.com/topics/multi-agent-debate-mad-strategies)

---

## Issue #7 🟢 [feat] High 自治模式加入 Kill Switch 緊急停止機制

**Labels:** `enhancement` `governance` `safety` `priority:low`

### 背景

業界 2026 年治理研究顯示，僅有 40% 的組織具備有效的 AI Kill Switch 能力，但這被視為 AI Governance 的核心基礎設施。隨著 Shikigami 在 high 自治模式下可以執行更長時間、更複雜的任務，緊急停止能力的重要性相應提升。

### 問題描述

目前 Shikigami 在 high 自治模式下，若發現 agent 產生預期外行為（如 Security 角色標記高風險、或 Stakeholder 認為方向偏離），缺乏一鍵暫停所有正在執行的 subagent 的機制。

### 建議做法

實作 `SHIKIGAMI_EMERGENCY_STOP` 訊號機制：

```
Kill Switch 觸發條件（任一即可）：
- Security 角色輸出 CRITICAL 風險評級
- Stakeholder 在任何時間點發出停止指令
- 超過設定的最大執行時間（configurable，預設 30 分鐘）

Kill Switch 行為：
1. 廣播停止訊號給所有 active subagent
2. subagent 在當前原子操作完成後停止（不強制中斷，避免檔案損毀）
3. 儲存當前所有 agent 的狀態快照
4. 輸出 Emergency Stop Report（說明已完成哪些任務、哪些被中斷）
```

### 驗收條件

- [ ] Kill Switch 在 30 秒內完成所有 subagent 的安全停止
- [ ] 停止後生成 Emergency Stop Report，包含每個 subagent 的最後狀態
- [ ] 支援從 Kill Switch 狀態恢復執行（斷點續跑）

### 參考資料

- [AI Agent Data Governance 2026 - Kiteworks](https://www.kiteworks.com/cybersecurity-risk-management/ai-agent-data-governance-why-organizations-cant-stop-their-own-ai/)
- [7 Agentic AI Trends to Watch in 2026](https://machinelearningmastery.com/7-agentic-ai-trends-to-watch-in-2026/)

---

## Issue #8 🟢 [research] 評估 A2A 協議相容性，規劃跨框架 Agent 協作路線

**Labels:** `research` `compatibility` `a2a` `priority:low`

### 背景

Google 主導的 A2A（Agent-to-Agent）協議已於 2025 年 6 月捐給 Linux Foundation，截至 2026 年 3 月有 50+ 技術夥伴採用（Atlassian、Box、Salesforce、SAP、ServiceNow 等）。A2A 的核心價值是讓不同框架開發的 agent 可以互相通訊，作為 MCP（工具層）的配套協議（agent 間通訊層）。

### 問題描述

Shikigami 的 8 個角色目前是緊密耦合在單一框架內，若未來需要：
- 與外部 CrewAI / LangGraph agent 協作
- 被其他 orchestrator 調用為 subagent
- 在多機器分散式環境中跨框架部署

缺乏標準化的 agent 通訊協議會成為瓶頸。

### 建議做法

1. 研究 A2A 協議規格（[A2A Protocol Spec](https://google.github.io/A2A/)）
2. 評估 Shikigami 角色哪些可以作為 A2A-compatible agent 暴露
3. 評估 Scrum Master orchestrator 是否可以透過 A2A 調用外部 agent
4. 產出一份 A2A 相容性評估報告，包含：
   - 技術可行性分析
   - 需要修改的 interface 清單
   - 潛在的安全考量（agent 身份驗證）

### 驗收條件

- [ ] 完成 A2A 相容性評估報告
- [ ] 識別出 Shikigami 最適合作為 A2A agent 暴露的 2-3 個角色
- [ ] 若決定實作，提出 Phase 1 PoC 的範圍定義

### 參考資料

- [MCP vs A2A: Protocols for Multi-Agent Collaboration 2026](https://onereach.ai/blog/guide-choosing-mcp-vs-a2a-protocols/)
- [Developer's Guide to AI Agent Protocols - Google](https://developers.googleblog.com/developers-guide-to-ai-agent-protocols/)
- [A2A Protocol Explained - Codilime](https://codilime.com/blog/a2a-protocol-explained/)

---

## 摘要一覽

| Issue | 標題 | 優先級 | 標籤 |
|-------|------|--------|------|
| #1 | 加入 Structured Trace Log | 🔴 高 | observability |
| #2 | Security 角色加入 Prompt Injection 防禦 | 🔴 高 | security |
| #3 | Developer 導入 TDAD Dependency Map | 🟡 中 | tdd |
| #4 | Scrum Master 加入平行任務衝突預測 | 🟡 中 | parallel-dispatch |
| #5 | 評估對齊 Agent Skills 開放標準 | 🟡 中 | compatibility |
| #6 | QA 加入 FREE-MAD 挑戰韌性機制 | 🟢 低 | check-and-balance |
| #7 | High 自治模式加入 Kill Switch | 🟢 低 | governance |
| #8 | 評估 A2A 協議相容性 | 🟢 低 | research |

*產出來源：[AI Agent 設計研究報告 2026-03-23](./ai-agent-design-research-2026-03-23.md)*
