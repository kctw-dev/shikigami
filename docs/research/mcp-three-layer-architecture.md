# MCP 三層架構評估報告

**文件類型**：RESEARCH Spike Report（US-243）
**日期**：2026-03-12
**Sprint**：Sprint 88
**狀態**：完成

---

## 1. 摘要

本報告評估在 Shikigami AI Agent Scrum Team 框架中引入 MCP（Model Context Protocol）三層架構的可行性與整合方式。評估範疇涵蓋三個 MCP Server：知識庫 MCP Server、流程管理 MCP Server、品質觀察 MCP Server。

**評估結論**：MCP 三層架構可作為現有 plugin 架構的**補強層**，而非替代層。建議採用漸進式導入策略，以「品質觀察 MCP Server」作為 MVP（最低風險、最高獨立性），視驗證結果再決定其他兩個 Server 的優先序。

---

## 2. 背景與動機

### 2.1 現有架構概覽

Shikigami 框架目前以 Claude Code Plugin 架構運作，核心組件：

| 組件 | 說明 | 數量 |
|------|------|------|
| Skills | Slash command 觸發的流程定義（SKILL.md） | 23 個 |
| Agents | 專業角色（Developer, QA, Architect, PO, SM 等） | 8 個 |
| Commands | 工具調用指令 | N/A |
| Hooks | 生命週期鉤子 | N/A |

知識資產存儲在 `docs/km/` 目錄，以 Markdown 格式管理：Metrics_Log.md、Retrospective_Log.md、Calibration_Log.md、Decision_Journal.md、Shoot_Log.md、Quality_Observer.md 等。

### 2.2 現有架構的限制

| 限制 | 影響 |
|------|------|
| 知識資產存取依賴全文載入 | Agent 無法針對性查詢特定 Sprint 或特定指標的數據，token 效率低 |
| 流程狀態散佈於多個文件 | PROJECT_BOARD.md、sprint_N.md 缺乏統一查詢介面，狀態不一致風險高 |
| 品質指標無結構化查詢能力 | Quality Observer 診斷需手動整合 Metrics_Log、Retrospective_Log 等多個來源 |
| Skill 間資料共享靠文件讀取 | 缺乏跨 Skill 的即時狀態共享機制 |

### 2.3 MCP 帶來的能力

MCP（Model Context Protocol）為 Anthropic 定義的標準化工具協議，允許 LLM 透過結構化工具（tools）與資源（resources）存取外部系統，而非完全依賴 prompt 注入原始文件內容。

---

## 3. 三個 MCP Server 的工具清單與資源定義

### 3.1 知識庫 MCP Server（Knowledge Base MCP Server）

**職責**：管理 `docs/km/` 下的知識資產，提供結構化查詢介面，取代全文載入模式。

**目標文件**：Metrics_Log.md、Retrospective_Log.md、Calibration_Log.md、Decision_Journal.md、Shoot_Log.md、Knowledge_Staleness_Detection.md

#### Tools（工具清單）

| Tool 名稱 | 描述 | 輸入參數 | 輸出格式 |
|-----------|------|---------|---------|
| `get_metrics_by_sprint` | 取得指定 Sprint 的 SPACE 五維度指標 | `sprint_number: int` | JSON: {velocity, completion_rate, trend, notes} |
| `get_metrics_range` | 取得 Sprint 區間的指標趨勢 | `from_sprint: int, to_sprint: int` | JSON: [{sprint, metrics}] |
| `get_retrospective` | 取得指定 Sprint 的 Retro 記錄 | `sprint_number: int` | JSON: {good, problems, actions} |
| `list_open_action_items` | 列出所有未關閉的 Retro Action Items | — | JSON: [{sprint, action, status}] |
| `get_calibration_log` | 取得 Calibration 記錄 | `sprint_number?: int` | JSON: [{date, role, calibration_note}] |
| `get_decision_journal` | 取得 Decision Journal 記錄 | `sprint_number?: int, keyword?: string` | JSON: [{date, decision, rationale}] |
| `query_shoot_log` | 查詢 Shoot Log 記錄 | `sprint_number?: int, status?: 'PASS'\|'FAIL'` | JSON: [{sprint, story_id, status}] |
| `check_knowledge_staleness` | 檢查知識文件的新鮮度 | `document: string` | JSON: {document, last_updated, staleness_level} |
| `append_retrospective` | 新增 Retro 記錄條目 | `sprint_number: int, type: 'good'\|'problem'\|'action', content: string` | JSON: {success: bool} |
| `update_metrics` | 更新 Metrics Log | `sprint_number: int, metrics: MetricsObject` | JSON: {success: bool} |

#### Resources（資源定義）

| Resource URI | 類型 | 描述 |
|-------------|------|------|
| `km://metrics/sprint/{n}` | text/json | Sprint N 的完整指標 |
| `km://retrospective/sprint/{n}` | text/markdown | Sprint N 的 Retro 記錄 |
| `km://calibration/latest` | text/json | 最新的 Calibration 記錄 |
| `km://decision-journal` | text/markdown | 完整 Decision Journal |
| `km://shoot-log/recent` | text/json | 最近 5 個 Sprint 的 Shoot Log |
| `km://action-items/open` | text/json | 所有開放的 Action Items |

---

### 3.2 流程管理 MCP Server（Process Management MCP Server）

**職責**：管理 Sprint 生命週期狀態，提供 PROJECT_BOARD 與 sprint_N.md 的結構化查詢與更新介面。

**目標文件**：PROJECT_BOARD.md、docs/sprints/sprint_N.md

#### Tools（工具清單）

| Tool 名稱 | 描述 | 輸入參數 | 輸出格式 |
|-----------|------|---------|---------|
| `get_current_sprint` | 取得當前 Sprint 狀態 | — | JSON: {sprint_number, status, stories[]} |
| `get_story_status` | 取得特定 Story 的狀態 | `story_id: string` | JSON: {story_id, status, sprint, size} |
| `list_stories_by_status` | 列出指定狀態的 Story | `status: 'TODO'\|'IN_PROGRESS'\|'DONE'\|'BLOCKED'` | JSON: [{story_id, title, size, sprint}] |
| `update_story_status` | 更新 Story 狀態 | `story_id: string, new_status: string, note?: string` | JSON: {success: bool, previous_status: string} |
| `get_sprint_backlog` | 取得 Sprint Backlog | `sprint_number: int` | JSON: {sprint, stories[], capacity, velocity_plan} |
| `get_project_board` | 取得 PROJECT_BOARD 全覽 | — | JSON: {current_sprint, all_stories_summary} |
| `get_sprint_capacity` | 取得 Sprint 容量狀態 | `sprint_number?: int` | JSON: {total_points, used_points, remaining_points} |
| `list_blocked_stories` | 列出所有 BLOCKED Story | — | JSON: [{story_id, title, blocked_reason}] |
| `get_story_ac` | 取得 Story 的 Acceptance Criteria | `story_id: string` | JSON: {story_id, acs: [{ac_id, description, target_file}]} |
| `record_sprint_event` | 記錄 Sprint 事件 | `sprint_number: int, event_type: string, description: string` | JSON: {success: bool} |

#### Resources（資源定義）

| Resource URI | 類型 | 描述 |
|-------------|------|------|
| `process://sprint/current` | text/json | 當前 Sprint 狀態 |
| `process://sprint/{n}/backlog` | text/json | Sprint N 的完整 Backlog |
| `process://story/{id}` | text/json | 特定 Story 的完整資訊 |
| `process://board/overview` | text/json | PROJECT_BOARD 全覽 |
| `process://board/blocked` | text/json | 所有 BLOCKED 項目 |

---

### 3.3 品質觀察 MCP Server（Quality Observer MCP Server）

**職責**：提供品質指標的結構化查詢，整合 SPACE 五維度數據、DISPUTE 率、自審通過率、Code Quality 趨勢等，供 Quality Observer 角色使用。

**目標文件**：docs/km/Metrics_Log.md、docs/km/Quality_Observer.md、docs/km/Retrospective_Log.md

#### Tools（工具清單）

| Tool 名稱 | 描述 | 輸入參數 | 輸出格式 |
|-----------|------|---------|---------|
| `get_quality_summary` | 取得指定 Sprint 的品質摘要 | `sprint_number: int` | JSON: {hallucination_rate, chain_break_rate, collaboration_efficiency} |
| `get_dispute_rate` | 取得 DISPUTE 率趨勢 | `from_sprint: int, to_sprint: int` | JSON: [{sprint, dispute_rate}] |
| `get_self_review_pass_rate` | 取得自審通過率趨勢 | `from_sprint: int, to_sprint: int` | JSON: [{sprint, pass_rate}] |
| `get_velocity_trend` | 取得 Velocity 趨勢分析 | `last_n_sprints: int` | JSON: {trend, data: [{sprint, velocity}], analysis} |
| `get_hallucination_metrics` | 取得幻覺頻率指標 | `sprint_number?: int` | JSON: {intercepted, escaped, trend} |
| `get_chain_break_metrics` | 取得斷鏈模式指標 | `sprint_number?: int` | JSON: {breaks, manual_interventions, hotspots[]} |
| `get_collaboration_metrics` | 取得角色協作效率指標 | `sprint_number?: int` | JSON: {cross_review_issues, collaboration_score} |
| `get_health_status` | 取得系統健康狀態評估 | — | JSON: {overall: 'healthy'\|'warning'\|'critical', dimensions: {}} |
| `generate_quality_report` | 生成品質診斷報告摘要 | `sprint_number: int` | JSON: {summary, findings[], recommendations[]} |
| `get_space_dimensions` | 取得 SPACE 五維度數據 | `sprint_number: int` | JSON: {satisfaction, performance, activity, communication, efficiency} |

#### Resources（資源定義）

| Resource URI | 類型 | 描述 |
|-------------|------|------|
| `quality://health/current` | text/json | 當前系統健康狀態 |
| `quality://metrics/sprint/{n}` | text/json | Sprint N 的品質指標 |
| `quality://trend/velocity` | text/json | Velocity 趨勢（近 10 Sprint） |
| `quality://trend/dispute-rate` | text/json | DISPUTE 率趨勢 |
| `quality://report/sprint/{n}` | text/markdown | Sprint N 的品質診斷報告 |
| `quality://observer/definition` | text/markdown | Quality Observer 角色定義 |

---

## 4. 與現有 Plugin 架構的整合方式分析

### 4.1 整合模式比較

| 整合模式 | 說明 | 適用性 |
|---------|------|-------|
| **補強模式（Augmentation）** | MCP Server 作為工具層，現有 Skill 透過 MCP 工具存取結構化數據，替代部分全文載入 | 推薦。最低侵入性，現有 Skill 行為不變，僅增加數據存取效率 |
| **替代模式（Replacement）** | MCP Server 完全取代 Skill 對文件的直接讀取 | 不推薦。破壞現有 Skill 自主性，遷移風險高 |
| **並行模式（Parallel）** | MCP Server 與現有文件讀取並存，Skill 自由選擇 | 可作為過渡方案，但長期會造成雙重維護負擔 |

### 4.2 整合點分析

#### Skills 與 MCP Server 的互動模式

```
現有 Claude Code Agent
    │
    ├── Skill（SKILL.md 定義的流程）
    │       │
    │       ├── 直接讀取 docs/km/*.md（現有模式）
    │       │
    │       └── 透過 MCP Tool 查詢（新模式）
    │               │
    │               ├── Knowledge Base MCP Server → docs/km/
    │               ├── Process Management MCP Server → docs/sprints/, PROJECT_BOARD.md
    │               └── Quality Observer MCP Server → 品質指標聚合
    │
    └── .mcp.json（MCP Server 設定）
```

#### 受影響的 Skills

| Skill | 現有行為 | MCP 整合後 |
|-------|---------|-----------|
| `sprint-review/SKILL.md` | 讀取 Metrics_Log.md 全文 | 改用 `get_metrics_by_sprint` tool |
| `sprint-execution/SKILL.md` | 讀取 PROJECT_BOARD.md 確認 Story 狀態 | 改用 `get_story_status`、`update_story_status` |
| `quality-gate/SKILL.md` | 手動整合多個品質文件 | 改用 `get_quality_summary`、`get_health_status` |
| `scrum-master/SKILL.md` | 讀取 sprint_N.md 計算容量 | 改用 `get_sprint_capacity` |
| `shoot/SKILL.md` | 讀取/寫入 Shoot_Log.md | 改用 `query_shoot_log`、append 工具 |

### 4.3 .mcp.json 設定方案

現有框架已有 `.mcp.json`（ADR-013 決策，drawio-mcp-server 整合）。三個新 MCP Server 可擴充至同一設定：

```json
{
  "mcpServers": {
    "drawio": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "drawio-mcp-server@1.8.0", "--editor"]
    },
    "shikigami-knowledge-base": {
      "type": "stdio",
      "command": "node",
      "args": ["mcp-servers/knowledge-base/index.js"],
      "env": {
        "SHIKIGAMI_ROOT": "${workspaceFolder}"
      }
    },
    "shikigami-process-management": {
      "type": "stdio",
      "command": "node",
      "args": ["mcp-servers/process-management/index.js"],
      "env": {
        "SHIKIGAMI_ROOT": "${workspaceFolder}"
      }
    },
    "shikigami-quality-observer": {
      "type": "stdio",
      "command": "node",
      "args": ["mcp-servers/quality-observer/index.js"],
      "env": {
        "SHIKIGAMI_ROOT": "${workspaceFolder}"
      }
    }
  }
}
```

### 4.4 安全考量（繼承 ADR-006 + ADR-013）

| 考量 | 策略 |
|------|------|
| MCP tool 輸出信任級別 | 繼承 ADR-006 規則：tool 輸出以 `<mcp_tool_output>` XML 標記包裹 |
| 寫入操作安全 | 寫入 tool（update_story_status、append_retrospective）需要確認步驟 |
| Secrets 管理 | 繼承 ADR-012 零硬編碼原則；SHIKIGAMI_ROOT 以環境變數注入 |
| 供應鏈安全 | 自建 MCP Server（非第三方 npm），最高信任；版本控制於同一 repo |

---

## 5. 利弊分析

### 5.1 優點

| 優點 | 說明 | 量化影響（估計） |
|------|------|----------------|
| **Token 效率提升** | 精確查詢取代全文載入，減少無關 context | 估計減少 40-60% token 用量（知識查詢場景） |
| **數據一致性** | 結構化 tool 定義強制數據格式，避免 Agent 解析 Markdown 的誤差 | 減少狀態腦補幻覺（SPACE P 維度改善） |
| **跨 Skill 共享狀態** | MCP Server 作為共享狀態層，多個 Skill 可即時讀取同一來源 | 避免平行執行時的狀態衝突 |
| **可測試性** | MCP tool 介面明確，可獨立測試，不依賴 Claude 推理 | 提升自動化驗證覆蓋率 |
| **演進性** | 底層實作（文件格式、存儲位置）可在不改動 Skill 的情況下重構 | 降低未來架構演進成本 |

### 5.2 缺點

| 缺點 | 說明 | 緩解策略 |
|------|------|---------|
| **初始建置成本** | 3 個 MCP Server 的 Node.js 實作需要工程工作量（各 M-L size） | 分期導入；先 POC 驗證，再全面實作 |
| **維護負擔增加** | 每個 MCP Server 需與對應文件格式保持同步 | 文件格式變更時同步更新 MCP Server |
| **學習曲線** | Agent 需學習使用 MCP tools 而非直接讀取文件 | 在 Skill 說明中加入工具使用範例 |
| **過度設計風險** | 對頻率低的查詢場景，MCP 帶來的收益不抵成本 | 優先實作高頻查詢場景（品質指標、Sprint 狀態） |
| **本地開發依賴** | MCP Server 需在本機常駐，與 ADR-012 多 GCE 環境整合需規劃 | 統一 setup script，與 drawio-mcp-server 安裝並列 |

### 5.3 優先導入建議

| 優先序 | MCP Server | 理由 |
|--------|-----------|------|
| 1（MVP） | **品質觀察 MCP Server** | 最獨立；不影響現有 Skill 寫入流程；Quality Observer 角色為 US-228 新增，無歷史負擔；POC 風險最低 |
| 2 | **流程管理 MCP Server** | 衝突管理（平行執行鎖定）是 Sprint 88 的背景問題，MCP 化可直接解決；但寫入操作需謹慎設計 |
| 3 | **知識庫 MCP Server** | 查詢場景清晰；但 Metrics_Log 格式多樣，解析複雜度高；建議待前兩個 Server 驗證後實作 |

---

## 6. 不確定性與開放問題

| # | 問題 | 優先級 | 狀態 |
|---|------|--------|------|
| OQ-1 | MCP Server 讀取 Markdown 文件的解析準確率是否足夠高？Metrics_Log 格式在歷史 Sprint 有差異 | 高 | Open — 需 POC 驗證 |
| OQ-2 | 寫入型 MCP tool（update_story_status）是否需要人工確認步驟？若 Agent 誤呼叫可能造成狀態污染 | 高 | Open — 建議 ADR-019 定義寫入安全策略 |
| OQ-3 | MCP Server 在 CI 環境的行為策略（與 ADR-013 CI 跳過原則對齊）？ | 中 | Open |
| OQ-4 | 三個 MCP Server 是否應獨立部署，或合併為單一 server 的多個 namespace？ | 中 | Open — POC 階段先獨立，視複雜度決定是否合併 |

---

## 7. 結論

MCP 三層架構為 Shikigami 框架提供了一個**補強現有 Plugin 架構**的可行路徑。核心價值在於將現有的「全文文件讀取模式」升級為「結構化工具查詢模式」，在不破壞現有 Skill 架構的前提下提升 token 效率、數據一致性與跨 Skill 狀態共享能力。

建議採用漸進式導入策略：
1. 以「品質觀察 MCP Server」POC 驗證技術可行性與整合模式
2. 根據 POC 結果決定後續兩個 Server 的實作優先序
3. 完整決策記錄於 ADR-019

---

## 參考

- ADR-013：shikigami:diagram MCP 整合架構決策（MCP 整合模式參考）
- ADR-006：Prompt Injection 防護（安全考量繼承來源）
- ADR-012：Claude Max 多開發環境認證架構（Secrets 管理規範）
- `docs/km/Quality_Observer.md`：Quality Observer 角色定義（品質觀察 MCP Server 需求來源）
- `docs/km/Metrics_Log.md`：SPACE 五維度指標格式（Knowledge Base MCP Server 解析目標）
- [MCP Specification](https://spec.modelcontextprotocol.io/)：MCP 協議規格
- US-228（Sprint 84）：Quality Observer 角色建立
- US-243（Sprint 88）：本 Spike 報告起源
