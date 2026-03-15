# SDD-000 系統架構（Global Architecture）

> 本文件是系統的全局架構定義，所有功能 SDD（SDD-001+）引用本文件，不得在個別 SDD 中重複定義領域模型、類別結構或系統邊界。
>
> **地位**：系統憲法。任何開發工作的業務概念、Service、外部依賴必須先在本文件中定位，才能開工。

**最後更新**：2026-03-15
**維護者**：Architect

---

## 1. 系統領域模型

> 定義系統中所有核心 Entity 及其關聯。新增業務概念時（D1/D2 觸發），Architect 必須更新本段落並調用 `/diagram` 產出領域模型圖。

### 1.1 核心概念定義

| Entity | 說明 | 所屬 Bounded Context |
|--------|------|---------------------|
| Agent | 具有特定角色定義、決策權與方法論的 AI 執行單元；由 YAML frontmatter + Markdown body 定義，存放於 `agents/*.md`。框架共有 8 個角色：Architect、Developer、Product Owner、QA Engineer、Security Engineer、SRE Engineer、UI/UX Designer、Stakeholder | Agent |
| Skill | 可調用的標準作業程序（SOP），定義觸發條件、執行流程與輸出格式；存放於 `skills/*/SKILL.md`。框架共有 25 個 Skill，涵蓋從 Onboarding 到 Sprint Review 的完整交付週期 | Skill |
| Sprint | 固定週期的迭代開發單位，包含 Sprint Goal、Sprint Backlog（Story 清單）與容量（points）。記錄於 `docs/sprints/sprint_N.md`，狀態由 Scrum Master 管理 | Delivery |
| Story | 最小可交付工作單元（User Story），具有 story_id、story_type、size、AC 與狀態。分為 FEATURE / DESIGN / INFRA / SECURITY / INTEGRATION / RESEARCH 六種類型 | Delivery |
| Hook | 事件觸發的側效應機制，於特定 Claude Code 生命週期事件（SessionStart、PreToolUse）自動執行；由 `hooks/hooks.json` 配置，Shell script 實作。目前有 session-start（注入 Scrum Master skill 內容）與 quality-observer（品質觀測）兩個 Hook | Infrastructure |
| MCP Server | 基於 Model Context Protocol（MCP）的工具擴展服務，提供結構化工具呼叫能力；以 Node.js 實作，存放於 `mcp-servers/`。目前有 quality-observer MCP Server（品質指標查詢） | Infrastructure |
| ADR | 架構決策紀錄（Architecture Decision Record），記錄重要技術決策的背景、選項、決策結果與後果；存放於 `docs/adr/` | Governance |
| SDD | 系統設計文件（System Design Document），定義系統架構、元件邊界、領域模型；SDD-000 為全局架構，SDD-001+ 為功能 SDD；存放於 `docs/sdd/` | Governance |

### 1.2 概念間關係

| 來源 Entity | 關係 | 目標 Entity | 說明 |
|------------|------|------------|------|
| Sprint | 包含（1:N） | Story | 一個 Sprint 包含多個 Story，Sprint 容量以 points 總計控制 |
| Agent | 執行（N:M） | Skill | Agent 可調用多個 Skill；Skill 可被多個 Agent 觸發（如 sprint-execution 由 Scrum Master 主導） |
| Story | 觸發（1:1） | Story-Lifecycle Subagent | Sprint Execution 中，每個 Story 派遣一個全新的 Story-Lifecycle subagent 在獨立 context 中閉環執行 |
| Hook | 注入（1:N） | Agent Session | SessionStart Hook 在每個 session 啟動時將 Scrum Master skill 內容注入 Agent context |
| MCP Server | 提供工具給（1:N） | Agent | Agent 透過 MCP protocol 呼叫 MCP Server 暴露的工具，取得結構化資料（如品質指標） |
| Story | 依賴（N:M） | ADR / SDD | Story 實作前需確認相關 ADR 與 SDD 已定義；SDD 作為 AC 強制上游約束（ADR-020） |
| Skill | 參照（N:M） | Agent | Skill 定義中指定執行角色（如 sprint-execution 指定由 Developer、QA、Architect 等協作） |

### 1.3 統一語言（Ubiquitous Language）

| 術語 | 定義 | 注意事項 |
|------|------|---------|
| Story-Lifecycle Subagent | Sprint Execution 中為單一 Story 派遣的全新 subagent，整個生命週期（Dev + Review + 修復循環）在 subagent 內部閉環，主 session 僅收摘要。不可與一般 Agent 混用 | 區別：一般 Agent = 角色定義；Story-Lifecycle Subagent = 執行實例 |
| doc-only | Story 的一種屬性標記，表示所有 AC 均為靜態文件填充，目標檔案路徑均在 `docs/` 下。doc-only Story 豁免 TDD，但雙階段 Review 維持必要 | 不可用於 skills/、agents/、commands/ 路徑的修改 |
| Gateway | 共享資源的唯一寫入入口 Service/Module。當 2 個以上 Module 需要寫入同一共享資源時，必須指定 Gateway，其他 Module 禁止直接寫入。由 DM-4 審查機制強制執行 | 定義於本文件 §2.3 Gateway 對照表 |
| Hard Gate | 流程中不可跨越的強制關卡，違反時必須 FAIL 並拒絕繼續執行。以 `<HARD-GATE>` 標記。區別於 Soft Gate（可確認後繼續） | 典型案例：雙階段 Review、TDD 強制、DESIGN blocker |
| Provider | Story-Lifecycle subagent 的執行平台（`claude` 或 `gemini`）。由環境變數 `SHIKIGAMI_MODEL_PROVIDER` 與 `SHIKIGAMI_ROLE_PROVIDER_MAP` 控制，預設自動偵測宿主平台 | 不影響 Agent 角色行為，僅影響執行引擎 |
| RICE | 優先級排序框架（Reach × Impact × Confidence ÷ Effort），用於 Product Backlog 優先級決策。由 PO 在 Discovery / Backlog Grooming 時計算 | 排序必須基於商業價值，非技術偏好 |
| Sprint Velocity | Sprint 實際完成的 story points 總計，用於預測下一 Sprint 容量。記錄於 `docs/km/Metrics_Log.md` | AI 團隊無工作量限制，velocity 用於流程健康指標而非限制容量 |
| Bounded Context | 領域概念的明確邊界，邊界內術語定義一致、邊界外需翻譯。框架主要 Bounded Context：Agent（角色行為）、Skill（作業程序）、Delivery（交付週期）、Infrastructure（執行環境）、Governance（決策治理） | 跨 Bounded Context 的概念交互須透過明確接口 |

### 1.4 領域模型圖

> *待 Architect 調用 /diagram 產出後，在此嵌入或引用圖檔路徑*

```
（待 Architect 產出）
```

---

## 2. 類別圖

> 定義 Service 層、Router 層的結構與依賴方向，並標示共享資源的唯一寫入入口（Gateway）。DM-1/DM-2/DM-3/DM-4 審查觸發或 D4 觸發時，Architect 必須更新本段落。

### 2.1 分層結構

| 層級 | 責任 | 命名慣例 |
|------|------|---------|
| Plugin Layer（插件層） | 框架入口、manifest 宣告、marketplace 發布資訊；決定 Skill/Agent 清單與 Hook 配置 | `.claude-plugin/plugin.json`、`.claude-plugin/marketplace.json` |
| Agent Layer（角色層） | 具有特定決策權與方法論的 AI 角色定義；每個 Agent 知道自己的職責邊界與跨角色協作規則 | `agents/*.md`（YAML frontmatter + Markdown body） |
| Skill Layer（技能層） | 標準作業程序（SOP）定義；Agent 調用 Skill 執行具體任務，Skill 包含觸發條件、流程步驟與 Hard Gate | `skills/*/SKILL.md`（及 `*-prompt.md` 角色特定 prompt） |
| Infrastructure Layer（基礎設施層） | 執行環境整合：Hook 機制（事件觸發）、MCP Server（工具擴展）、驗證腳本（一致性保障）、測試腳本（品質驗證） | `hooks/`、`mcp-servers/`、`scripts/`、`tests/` |

### 2.2 Service 清單

| Service 名稱 | 職責 | 依賴的 Repository | Gateway 標記 |
|-------------|------|------------------|-------------|
| Scrum Master（scrum-master Skill） | 框架總控制器；Session 初始化、Sprint 生命週期協調、升級鏈管理、Bypass 保護清單維護 | `skills/scrum-master/SKILL.md`、`docs/PROJECT_BOARD.md` | PROJECT_BOARD 狀態協調的唯一入口 |
| Sprint Execution（sprint-execution Skill） | Story 取出、Story-Lifecycle Subagent 派遣、雙階段 Review 協調、看板更新、抽樣審查決策 | `docs/PROJECT_BOARD.md`、`docs/sprints/sprint_N.md` | Sprint Backlog 狀態的唯一寫入入口（平行執行時由主 session 批次更新） |
| Sprint Planning（sprint-planning Skill） | Sprint Backlog 確認、Refinement 執行、Story Size 估點、doc-only 判定、平行分群建議 | `docs/sprints/sprint_N.md`、`docs/PROJECT_BOARD.md` | — |
| Sprint Review（sprint-review Skill） | Sprint 驗收、SPACE 指標計算、Retrospective 記錄、Metrics_Log 更新、版本 bump 觸發 | `docs/km/Metrics_Log.md`、`docs/km/Retrospective_Log.md` | Sprint 級別狀態欄位的唯一寫入入口 |
| Architecture Decision（architecture-decision Skill） | ADR 流程主持、技術選型決策、多角色 challenge 協調、ADR 歸檔 | `docs/adr/ADR-*.md` | ADR 文件的唯一寫入入口 |
| Quality Observer（MCP Server） | 品質指標結構化查詢；透過 MCP protocol 暴露 get_metrics、get_sprint_health 等工具 | `docs/km/Metrics_Log.md` | — （唯讀查詢，不寫入） |
| Session Start Hook | Session 初始化側效應；於 SessionStart 事件將 scrum-master SKILL.md 完整內容注入 Agent context | `skills/scrum-master/SKILL.md` | — |
| Pre-Commit Hook | git commit 前版號一致性驗證；於 PreToolUse（Bash+git commit）事件觸發 validate-version.sh | `scripts/validate-version.sh` | — |

> **Gateway 標記**：當某 Service 是特定共享資源的唯一寫入入口時，在此欄標注。其他 Service 必須透過該 Gateway 操作，不得直接寫入。標記「—」表示該 Service 非任何共享資源的 Gateway。

### 2.3 共享資源寫入入口（Gateway 對照表）

> 定義哪些共享資源有唯一寫入入口約束。新增共享資源或 DM-4 審查觸發時，Architect 必須更新本表。

| 共享資源 | Gateway Service | 允許的操作方法 | 禁止直接操作 |
|---------|----------------|--------------|-------------|
| `docs/PROJECT_BOARD.md`（Story 狀態欄） | Sprint Execution（主 session） | Story 狀態欄位更新（待辦→進行中→已完成） | 禁止平行 Story-Lifecycle subagent 直接寫入；Sprint 級別欄位僅限 sprint-review 修改 |
| `docs/PROJECT_BOARD.md`（Sprint 級別欄） | Sprint Review Skill | Sprint 完成標記、Stakeholder 驗收欄位、Sprint 級別結果欄位 | 禁止 Developer / Sprint Execution 修改 Sprint 級別欄位 |
| `docs/sprints/sprint_N.md`（Story 狀態欄） | Sprint Execution（主 session） | Sprint Backlog 表格中 Story 列的「狀態」欄 | 禁止平行 subagent 直接寫入；Sprint 級別欄位僅限 sprint-review 修改 |
| `docs/km/Metrics_Log.md` | Sprint Review Skill | Sprint 指標更新（SPACE 維度、velocity、DISPUTE 率等） | 禁止 Sprint Execution / Developer 直接修改 Metrics 數值 |
| `docs/km/Retrospective_Log.md` | Sprint Review Skill | Sprint Retrospective 記錄、Action Item 追蹤 | 禁止 Sprint Execution / Developer 直接修改 Retrospective 記錄 |
| `.claude-plugin/plugin.json`（version 欄位） | Version Bump 流程（chore: bump commit） | 版號遞增（patch / minor / major） | 禁止在 Feature/Fix commit 中直接修改 version 欄位；需同時更新 marketplace.json、gemini-extension.json、CLAUDE.md、README.md badge |

> **判斷標準**：當 2 個以上 Service/Module 需要寫入同一資料資源（DB collection、欄位、狀態）時，必須定義 Gateway Service。

### 2.4 類別圖

> *待 Architect 調用 /diagram 產出後，在此嵌入 Mermaid classDiagram。類別圖必須標示 Gateway Service 與依賴方向。*

```
（待 Architect 產出 — 需使用 Mermaid classDiagram，標示依賴方向與 Gateway 註解）
```

---

## 3. 元件圖

> 定義前端、後端、資料庫、外部服務的系統邊界。新增外部依賴或系統邊界變更時，Architect 必須更新本段落。

### 3.1 系統邊界

| 元件 | 類型 | 託管模式 | 說明 |
|------|------|---------|------|
| Claude Code Host | 外部服務 | 受管服務（Anthropic） | 宿主平台；提供 Agent tool、LLM 推理能力、Session 生命週期管理。Shikigami 插件在此 Runtime 中執行 |
| Shikigami Plugin | 內部 | 自建 | Claude Code Plugin 格式（`.claude-plugin/plugin.json`）；定義 Agent、Skill、Hook、MCP Server 清單，作為框架入口 |
| MCP Server（quality-observer） | 內部 | 自建（Node.js） | 透過 Model Context Protocol STDIO transport 提供品質指標查詢工具；由 `mcp-servers/quality-observer/` 實作，以 `node index.js` 啟動 |
| File System（專案目錄） | 內部 | 本地 / Git 倉庫 | 所有框架定義文件、Sprint 記錄、ADR、SDD、看板的實際儲存媒介；透過 Read/Edit/Bash tool 存取；以 Git 管理版本 |
| Gemini CLI | 外部服務 | 受管服務（Google） | 可選的替代宿主平台；支援雙軌派遣機制（`SHIKIGAMI_MODEL_PROVIDER=gemini`），Shikigami 框架支援在 Gemini CLI 上執行（`gemini-extension.json`） |
| GitHub（Issues / Actions） | 外部服務 | 受管服務（GitHub） | Issue 追蹤（User Story 來源）、CI/CD 工作流程；透過 `gh` CLI 存取，Sprint Execution 快掃 CI 狀態 |

> **元件類型**：內部 / 外部服務
> **託管模式**：自建（Self-hosted）/ 受管服務（Managed Service）— 影響維運責任與 SLA 邊界

### 3.2 元件間通訊

| 來源 | 目標 | 協定 | 說明 |
|------|------|------|------|
| Claude Code Host | Shikigami Plugin | Plugin Manifest / Hook JSON | Host 讀取 `.claude-plugin/plugin.json` 載入框架定義；Hook 配置觸發 Shell script 執行 |
| Agent（主 session） | Story-Lifecycle Subagent | Agent tool（claude provider）或 Bash（gemini provider） | Sprint Execution 派遣 subagent 執行 Story；以 story-lifecycle-prompt.md 為 prompt；結果寫入暫存文件後回傳 |
| Agent | MCP Server | MCP Protocol（STDIO transport） | Agent 透過 MCP tool calling 呼叫 quality-observer 查詢品質指標 |
| Hook（SessionStart） | Agent Context | JSON output（additional_context 欄位） | session-start Hook 讀取 scrum-master SKILL.md，序列化為 JSON 注入 Agent 初始 context |
| Agent | File System | Read / Edit / Bash tool | 讀寫 docs/、agents/、skills/ 等目錄；git commit 透過 Bash tool 執行 |
| Agent | GitHub | Bash（gh CLI） | 讀取 Issue body、列出 CI workflow 執行結果、發布 Issue comment |

### 3.3 元件圖

> *待 Architect 調用 /diagram 產出後，在此嵌入或引用圖檔路徑*

```
（待 Architect 產出）
```

### 3.4 部署邊界

Shikigami 框架為 Claude Code Plugin，無獨立部署拓撲。執行環境為使用者本地工作站（Claude Code / Gemini CLI）加上 Anthropic / Google 雲端 LLM 推理服務。MCP Server 以本地 Node.js 程序形式啟動（STDIO transport），無需獨立部署。

### 3.5 可觀測性端點

| 元件 | 監控類型 | 端點 / 查詢方式 | 說明 |
|------|---------|----------------|------|
| Sprint 指標 | Metrics | `docs/km/Metrics_Log.md` | SPACE 維度指標、velocity、DISPUTE 率；由 Sprint Review 每 Sprint 更新 |
| 品質指標 | MCP 工具 | `mcp-servers/quality-observer` — `get_metrics` / `get_sprint_health` tool | 結構化查詢 Metrics_Log，供 Agent 在 session 中即時查詢品質狀態 |
| 版號一致性 | 驗證腳本 | `bash scripts/validate-version.sh` | 每次 git commit 前由 PreToolUse Hook 自動觸發；確認 plugin.json / marketplace.json / CLAUDE.md 版號一致 |

---

## 4. 變更紀錄

| 日期 | 變更內容 | 觸發條件代碼 | 變更段落 | 關聯 Story/Issue |
|------|---------|-------------|---------|-----------------|
| 2026-03-14 | 初始建立 | Onboarding | 全文 | — |
| 2026-03-15 | §2 新增 Gateway 標記、§2.3 共享資源寫入入口對照表 | DM-4 | §2 類別圖 | #268 |
| 2026-03-15 | §1.1 填入 8 個核心 Entity（Agent、Skill、Sprint、Story、Hook、MCP Server、ADR、SDD）；§1.2 定義 Entity 間關聯；§1.3 填入 8 個統一語言術語（含 Story-Lifecycle Subagent、doc-only、Gateway、Hard Gate、Provider、RICE、Sprint Velocity、Bounded Context）；§2.1 以 Shikigami 實際分層（Plugin / Agent / Skill / Infrastructure）取代通用範例；§2.2 填入 8 個核心 Service/Module（含 Gateway 標記）；§2.3 填入 6 個共享資源 Gateway 對照條目；§3.1 定義 6 個系統邊界元件；§3.2 定義元件間通訊協定；§3.4–3.5 以框架實際可觀測性端點取代佔位符。觸發原因：SDD-000 空模板狀態阻塞 PB-2（ADR-020 SDD→AC 追溯鏈落地）與 PB-4（DM-4 審查機制 Gateway 對照表）兩條產品線 | D1（新領域概念） | §1 領域模型、§2 類別圖、§3 元件圖 | #270 |

> **觸發條件代碼**：限定以下值 — `D1`（新領域概念）、`D2`（跨模組共享）、`D3`（複雜業務規則，圖表放各 SDD）、`D4`（3+ Entity 互動）、`B3`（狀態轉換，圖表放各 SDD）、`DM-1`（業務邏輯封裝）、`DM-2`（Single Source of Truth）、`DM-3`（狀態轉換統一）、`DM-4`（共享寫入入口）、`Onboarding`（初始建立）、`外部依賴變更`
