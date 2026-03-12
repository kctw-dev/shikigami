# Decision Knowledge Base Index

**建立日期**：2026-05-11
**最後更新**：2026-03-12（ADR-019 Accepted — MCP 三層架構）
**維護者**：Developer（手動維護，每次新增或更新 ADR 時同步更新本文件）
**ADR 目錄**：`docs/adr/`

---

## 使用說明

### ADR 查詢介面

本索引提供三種篩選方式，協助快速定位架構決策記錄：

#### 依關鍵字篩選

搜尋 ADR 標題或下方「決策影響追蹤」區段中的關鍵字。常用關鍵字範例：

| 關鍵字 | 相關 ADR |
|--------|---------|
| Backlog | ADR-001、ADR-009、ADR-010 |
| 測試 / 驗證腳本 | ADR-002 |
| SQA / 稽核 / Hard Gate | ADR-003 |
| Retrospective / 關鍵字比對 | ADR-004 |
| 排程 / cron / flock | ADR-005 |
| 注入防護 / Prompt Injection | ADR-006 |
| Subagent / Context overflow | ADR-007 |
| OpenCode / 平台整合 | ADR-008 |
| backlog-intake / 需求入庫 | ADR-009 |
| GitHub Issues / Source of Truth | ADR-010 |
| GitHub Actions / CI/CD / 整合 | ADR-011 |
| UI/UX Designer / 設計角色 / Design Foundation | ADR-016 |
| Figma / Prototype / Contract / Vision Critic | ADR-014、ADR-015、ADR-016 |
| Design Tokens / Design System / Component Library | ADR-014、ADR-016 |
| Knowledge Ingestion / API 幻覺 / Anti-Hallucination | ADR-017 |
| WebFetch / api-knowledge / ground truth | ADR-017 |
| Context Hub / chub / MCP Knowledge Ingestion | ADR-017 |
| MCP / 三層架構 / 狀態機 / 流程管理 / 品質觀察 / 知識庫 | ADR-019 |
| context compaction / 流程斷裂 / 外部狀態 | ADR-019 |
| Decision Journal / 衝突決策 / 價值觀取捨 | DJ-001 |
| 平行執行 / 共用文件保護 / Subagent 協調 | DJ-001 |

#### 依狀態篩選

| 狀態 | ADR 列表 |
|------|---------|
| **Accepted**（正式採用） | ADR-001、ADR-002、ADR-003、ADR-004、ADR-005、ADR-006、ADR-007、ADR-008、ADR-009、ADR-010、ADR-016、ADR-017、ADR-019 |
| **Proposed**（起草中，待審查） | ADR-011 |
| **Deprecated**（已棄用） | — |

#### 依日期篩選

| 日期 | ADR |
|------|-----|
| 2026-02-28 | ADR-001 |
| 2026-03-01 | ADR-002、ADR-003、ADR-004 |
| 2026-03-02 | ADR-005、ADR-006、ADR-007 |
| 2026-03-03 | ADR-008、ADR-009、ADR-010 |
| 2026-05-11 | ADR-011 |
| 2026-03-11 | ADR-016、ADR-017 |
| 2026-03-12 | ADR-019 |

---

## ADR 彙整表

| ADR | 標題 | 狀態 | 日期 | 關聯 Story / Issue |
|-----|------|------|------|-------------------|
| [ADR-001](../adr/ADR-001.md) | Backlog Bridge 跨 Skill 編排模式 | Accepted | 2026-02-28 | Backlog Bridge 功能（issue-management Skill） |
| [ADR-002](../adr/ADR-002.md) | 測試框架技術選型 | Accepted | 2026-03-01 | US-T01 ~ US-T09（框架結構驗證測試系列） |
| [ADR-003](../adr/ADR-003.md) | SQA 稽核閘門介入模式 | Accepted | 2026-03-01 | US-22（Retrospective 驅動角色權重自動調整） |
| [ADR-004](../adr/ADR-004.md) | Retrospective Problem 主題比對機制 | Accepted | 2026-03-01 | US-22（Retrospective 驅動角色權重自動調整） |
| [ADR-005](../adr/ADR-005-schedule-skill-technical-decisions.md) | Schedule Skill 技術決策（cron / flock / allowedTools / OAuth / rollback） | Accepted | 2026-03-02 | Issue #46、US-36（跨 Skill 序列鎖） |
| [ADR-006](../adr/ADR-006-prompt-injection-protection.md) | Issue 內容提示注入防護 | Accepted | 2026-03-02 | Issue #55、US-37 |
| [ADR-007](../adr/ADR-007-story-lifecycle-subagent.md) | Story 生命週期 Subagent 封裝 | Accepted | 2026-03-02 | Issue #45、US-39（Sprint 22） |
| [ADR-008](../adr/ADR-008.md) | OpenCode 平台整合策略（Symlink 適配） | Accepted | 2026-03-03 | Issue #3、US-46（Sprint 26）、US-47（Sprint 27） |
| [ADR-009](../adr/ADR-009.md) | Backlog Intake 自動化技術決策 | Accepted | 2026-03-03 | Issue #46、US-63（Sprint 33） |
| [ADR-010](../adr/ADR-010.md) | Backlog Source of Truth — GitHub Issues 優先策略 | Accepted | 2026-03-03 | Issue #46、US-69 ~ US-73（Sprint 35） |
| [ADR-011](../adr/ADR-011-github-actions-integration.md) | GitHub Actions 整合架構決策 | Proposed | 2026-05-11 | Issue #46、Issue #76、US-81（Sprint 38） |
| [ADR-016](../adr/ADR-016-uiux-designer-role.md) | UI/UX Designer 角色定義與 Design Foundation 流程 | Accepted | 2026-03-11 | Issue #207 |
| [ADR-017](../adr/ADR-017-context-hub-knowledge-ingestion.md) | Context Hub 整合架構決策 — Knowledge Ingestion 機制 | Accepted | 2026-03-11 | Issue #216 |
| [ADR-019](../adr/ADR-019-mcp-three-layer-architecture.md) | MCP 三層架構 — 知識庫 / 流程管理 / 品質觀察 MCP Server | Accepted | 2026-03-12 | Issue #231（US-243） |

---

## 決策影響追蹤

本區段列出每個 Accepted ADR 影響的 Skills 與文件路徑。
**維護說明**：本區段為靜態手動維護，每次 ADR 狀態變更為 Accepted、或受影響文件有異動時，手動更新對應條目。

---

### ADR-001：Backlog Bridge 跨 Skill 編排模式

**核心決策**：`issue-management` 以委派模式呼叫 `backlog-management`，RICE 評分邏輯集中於 backlog-management。

| 影響類型 | 路徑 | 說明 |
|---------|------|------|
| Skills | `skills/issue-management/SKILL.md` | Backlog Bridge 子流程的步驟 4：invoke backlog-management |
| Skills | `skills/backlog-management/SKILL.md` | RICE 評分邏輯的唯一擁有者 |

---

### ADR-002：測試框架技術選型

**核心決策**：採用純 Bash 腳本 + 共享函式庫（`scripts/lib/validate-helpers.sh`）。

| 影響類型 | 路徑 | 說明 |
|---------|------|------|
| 腳本 | `scripts/lib/validate-helpers.sh` | 共享輔助函式庫 |
| 腳本 | `scripts/validate-commands.sh` | Command 路由驗證（US-T06） |
| 腳本 | `scripts/validate-version.sh` | 版號一致性驗證（US-T04） |
| 腳本 | `scripts/validate-skills.sh` | Skill 完整性驗證（US-T01） |
| 腳本 | `scripts/validate-agents.sh` | Agent 完整性驗證（US-T02） |

---

### ADR-003：SQA 稽核閘門介入模式

**核心決策**：分級介入 — Framework Document Change 與 Ceremony Integrity 採 Hard Gate；Story Completion DoD Audit 採 Soft Gate。

| 影響類型 | 路徑 | 說明 |
|---------|------|------|
| Skills | `skills/sqa-audit/SKILL.md` | SQA 稽核閘門的實作主體 |
| Skills | `skills/quality-gate/SKILL.md` | Hard Gate 機制定義 |
| Skills | `skills/scrum-master/SKILL.md` | §6.1「不阻塞原則」與此 ADR 的相容性 |
| Skills | `skills/sprint-planning/SKILL.md` | Ceremony Integrity Hard Gate：Sprint Planning 必要條件 |
| Skills | `skills/sprint-review/SKILL.md` | Ceremony Integrity Hard Gate：Sprint Review 必要條件 |

---

### ADR-004：Retrospective Problem 主題比對機制

**核心決策**：關鍵字清單比對（多關鍵字、可演進），確保決策確定性優先。

| 影響類型 | 路徑 | 說明 |
|---------|------|------|
| Skills | `skills/sprint-planning/SKILL.md` | §3 Role Weight Check：關鍵字清單定義與比對演算法 |
| 文件 | `docs/km/Retrospective_Log.md` | 關鍵字比對的資料來源 |

---

### ADR-005：Schedule Skill 技術決策

**核心決策**：cron 排程、flock 互斥鎖、SKILL.md frontmatter `requiredTools`、OAuth 認證（unset ANTHROPIC_API_KEY）、原子性回滾。

| 影響類型 | 路徑 | 說明 |
|---------|------|------|
| Skills | `skills/schedule/SKILL.md` | 核心受影響 Skill，排程部署全流程定義 |
| Skills | `skills/*/SKILL.md`（所有計劃排程的 Skill） | frontmatter 需新增 `requiredTools` 欄位 |
| 腳本 | `scripts/shikigami-schedule-*.sh`（生成腳本） | 排程腳本的生成格式與 Pre-flight 邏輯 |

---

### ADR-006：Issue 內容提示注入防護

**核心決策**：XML 資料隔離標記 + 角色限制宣告（Prompt Injection Isolation Rule）。

| 影響類型 | 路徑 | 說明 |
|---------|------|------|
| Skills | `skills/sprint-execution/SKILL.md` | §3 Issue 快掃：PO subagent prompt 建構步驟須套用 Isolation Rule |
| Skills | `skills/backlog-intake/SKILL.md` | 繼承 ADR-006 完整兩條規則（ADR-009 §決策域三定義） |

---

### ADR-007：Story 生命週期 Subagent 封裝

**核心決策**：完整 Story-Lifecycle Subagent（選項 B），主 session 僅接收摘要；審查獨立性補償機制（30% 抽樣審查）。

| 影響類型 | 路徑 | 說明 |
|---------|------|------|
| Skills | `skills/sprint-execution/SKILL.md` | §3 執行流程：改為派遣 Story-Lifecycle subagent |
| 文件 | `skills/sprint-execution/story-lifecycle-prompt.md` | Story-Lifecycle subagent 的 prompt 定義（Developer + self-review） |
| 文件 | `docs/km/Metrics_Log.md` | 自審通過率、外部抽樣執行率、DISPUTE 率追蹤 |

---

### ADR-008：OpenCode 平台整合策略

**核心決策**：Symlink 適配（`.opencode/skills -> ../skills`）、雙平台標注、subagent 設定檔存放於 `.opencode/agents/`。

| 影響類型 | 路徑 | 說明 |
|---------|------|------|
| 目錄結構 | `.opencode/skills` | symlink 指向 `skills/`，零重複維護 |
| 目錄結構 | `.opencode/agents/` | OpenCode subagent 設定檔目錄 |
| 文件 | `AGENTS.md` | OpenCode 框架入口（對應 CLAUDE.md） |
| 文件 | `docs/km/OPENCODE_POC.md` | Phase 1/2 調查與驗證記錄 |
| Skills | `skills/*/SKILL.md` | R-1 至 R-7 殘留項加入雙平台標注 |

---

### ADR-009：Backlog Intake 自動化技術決策

**核心決策**：GitHub Issues 為輸入來源（`backlog-intake` label 過濾）、繼承 ADR-006 Injection 防護、OAuth 認證（繼承 ADR-005）、`backlog-intake-done` label 冪等性保護。
**注意**：格式契約決策域已由 ADR-010 取代（Superseded）。

| 影響類型 | 路徑 | 說明 |
|---------|------|------|
| Skills | `skills/backlog-intake/SKILL.md` | 核心受影響 Skill（輸入來源、冪等性、Injection 防護） |
| Skills | `skills/schedule/SKILL.md` | §使用範例：`/schedule backlog-intake` 的 cron 範例 |

---

### ADR-010：Backlog Source of Truth — GitHub Issues 優先策略

**核心決策**：GitHub Issues 為唯一 Backlog source of truth；PRODUCT_BACKLOG.md 降級為唯讀快照；兩層 label 體系；Sprint Planning 改用 `gh issue list`。

| 影響類型 | 路徑 | 說明 |
|---------|------|------|
| Skills | `skills/backlog-intake/SKILL.md` | 輸出目標從寫入 .md 改為為 Issue 套用 label + 填補 Story template |
| Skills | `skills/sprint-planning/SKILL.md` | PO Story 選取來源改為 `gh issue list`；加入即時排序計算邏輯 |
| Skills | `skills/backlog-management/SKILL.md` | Grooming 流程改為操作 GitHub Issues；加入 Pre-flight 錯誤恢復掃描 |
| 文件 | `docs/prd/PRODUCT_BACKLOG.md` | 降級為唯讀歷史快照，加入 DEPRECATED 標頭 |
| ADR | `docs/adr/ADR-009.md` | 格式契約決策域標注「Superseded by ADR-010」 |

---

### ADR-016：UI/UX Designer 角色定義與 Design Foundation 流程

**核心決策**：新增第 8 角色 UI/UX Designer（合併 UX + UI）；Design Foundation 為 Pre-Sprint 三方協作（PO + Architect + Designer）；Prototype 凍結為 Contract 需 Vision Critic PASS + QA Contract Testability Review 雙重審查。

| 影響類型 | 路徑 | 說明 |
|---------|------|------|
| Agent | `agents/uiux-designer.md`（待建立） | UI/UX Designer Agent 定義 |
| Skills | `skills/uiux-designer/SKILL.md`（待建立） | UI/UX Designer Skill 定義（Design Foundation + DESIGN Story 執行） |
| Skills | `skills/sprint-execution/SKILL.md` | §5 DESIGN type 執行路徑：派遣 Designer subagent |
| Skills | `skills/sprint-execution/story-lifecycle-prompt.md` | DESIGN type 執行分支 |
| Skills | `skills/sprint-planning/SKILL.md` | §8.3 Contract Owner 指向實際 Agent；§9 Design Foundation 觸發 |
| Skills | `skills/scrum-master/SKILL.md` | 角色清單從 7 → 8 個 |
| Skills | `skills/vision-critic/SKILL.md` | 定位為 Designer self-review 工具 |
| ADR | ADR-014、ADR-015 | 補充/擴展：角色正式定義 |

---

### ADR-017：Context Hub 整合架構決策 — Knowledge Ingestion 機制

**核心決策**：採用選項 A（Context Hub as MCP Server Integration），Agent 透過 MCP tool call 查詢 context-hub 專用爬蟲解析的結構化 API 知識（確定性輸出，非 LLM 推測）。選項 C（WebFetch Native）為 CI 環境 fallback。

| 影響類型 | 路徑 | 說明 |
|---------|------|------|
| Skills | `skills/sprint-execution/story-lifecycle-prompt.md` | 新增步驟 7.5：Knowledge Ingestion via MCP（三問檢查後、TDD 前） |
| MCP 設定 | `.mcp.json`（消費端專案） | 新增 context-hub MCP server 設定（與 ADR-015 Figma MCP 同模式） |
| 目錄結構 | `docs/km/api-knowledge/` | fallback 模式知識庫目錄（僅 MCP 不可用時產生） |
| ADR | ADR-006 | Injection 防護延伸至 MCP server 回傳內容（`<api_knowledge>` XML 隔離標記） |
| ADR | ADR-015 | 與 Figma MCP 整合模式對齊，共用 `.mcp.json` 宣告式設定 |

---

### ADR-019：MCP 三層架構 — 知識庫 / 流程管理 / 品質觀察 MCP Server

**核心決策**：採用選項 A（漸進式 MCP 三層架構），在現有 plugin 架構之上以補強模式引入三個 MCP Server。Phase 順序：Phase 1 流程管理 → Phase 2 品質觀察 → Phase 3 知識庫。審查附帶條件：fallback 機制（C1）、狀態持久化到檔案（C2）、零外部依賴（C3）。

| 影響類型 | 路徑 | 說明 |
|---------|------|------|
| 目錄結構 | `mcp-servers/quality-observer/` | 品質觀察 MCP Server POC（已完成） |
| 目錄結構 | `mcp-servers/process-management/`（Phase 1 新建） | 流程管理 MCP Server（狀態機） |
| 目錄結構 | `mcp-servers/knowledge-base/`（Phase 3 新建） | 知識庫 MCP Server |
| MCP 設定 | `.mcp.json` | 新增三個 MCP Server 設定（漸進式） |
| Skills | `skills/sprint-review/SKILL.md`（可選） | Metrics 查詢步驟指向 MCP tool |
| Skills | `skills/sprint-execution/SKILL.md`（可選） | 流程狀態查詢指向 MCP tool |
| ADR | ADR-006 | MCP tool 輸出須以 `<mcp_tool_output>` XML 標記包裹（Injection 防護） |
| ADR | ADR-013 | 繼承 stdio transport 與 `.mcp.json` 宣告式設定 |

---

## Decision Journal 索引

本區段索引 `docs/km/Decision_Journal.md` 中的衝突決策記錄（DJ 系列）。
DJ 記錄聚焦於**非架構性的價值觀取捨**與**執行層面的衝突決策**，與 ADR 的架構決策互補。

**完整記錄**：[Decision_Journal.md](./Decision_Journal.md)

| DJ 編號 | 日期 | 情境摘要 | 關聯 ADR/Issue |
|---------|------|---------|---------------|
| [DJ-001](./Decision_Journal.md#dj-001) | 2026-03-12 | 平行執行 vs. 循序執行：US-218 與 US-219 共用索引文件的衝突處理策略 | US-218、US-219、Sprint 82 |

---

## 維護指引

新增 ADR 時，請依序執行：

1. 在 ADR 彙整表新增一行（含標題、狀態、日期、關聯 Story/Issue）
2. 在決策影響追蹤區段新增對應條目（至少一筆影響路徑記錄）
3. 更新「依關鍵字篩選」與「依狀態篩選」表格
4. 記錄本次更新日期於本文件頂部「最後更新」欄位

新增 DJ 時，請依序執行：

1. 在 `Decision_Journal.md` 新增 `### DJ-NNN` 區塊（含五個必要欄位）
2. 在本文件「Decision Journal 索引」表格新增一行
3. 在「依關鍵字篩選」表格新增對應關鍵字映射
4. 記錄本次更新日期於本文件頂部「最後更新」欄位
