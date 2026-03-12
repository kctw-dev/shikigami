# ADR-019：MCP 三層架構 — 知識庫 / 流程管理 / 品質觀察 MCP Server

**狀態**：Draft
**日期**：2026-03-12
**決策者**：待定（PO + Architect）
**關聯 Issue**：#231（US-243 MCP 三層架構評估 Spike）
**關聯 ADR**：ADR-006（Prompt Injection 防護）、ADR-012（多環境認證架構）、ADR-013（diagram MCP 整合）、ADR-018（Discovery Phase 架構）
**關聯 Sprint**：Sprint 88（US-243 RESEARCH Spike）

---

## 背景

### 問題陳述

Shikigami 框架目前以 Claude Code Plugin 架構運作（23 個 Skills、8 個 Agent 角色）。所有 Agent 對知識資產（`docs/km/`）、流程狀態（`docs/sprints/`、`PROJECT_BOARD.md`）的存取均透過**全文文件載入**模式——Agent 直接讀取完整 Markdown 文件，從中提取所需資訊。

此模式隨框架規模增長暴露出三個結構性問題：

1. **Token 效率低落**：Agent 需載入 Metrics_Log.md（88 Sprint 累積，數千行）才能取得單一 Sprint 的 Velocity 數據。大量無關歷史 context 佔用 context window，增加 token 成本並稀釋相關資訊的權重。

2. **結構化查詢能力缺失**：Quality Observer 診斷報告需要整合 Metrics_Log、Retrospective_Log、Calibration_Log 等多個文件，目前依賴 Agent 跨文件推斷，數據整合準確率不穩定。

3. **平行執行狀態衝突風險**：Sprint 88 採用平行執行模式（US-240 至 US-243 同步進行）。多個 subagent 同時讀取 PROJECT_BOARD.md 時，缺乏共享狀態層導致狀態不一致的風險。

### 觸發本 ADR 的契機

Sprint 88 US-243 RESEARCH Spike 產出了 MCP 三層架構評估報告（`docs/research/mcp-three-layer-architecture.md`）與品質觀察 MCP Server 的 POC 實作（`mcp-servers/quality-observer/`）。本 ADR 為 Spike 的決策記錄，待 PO + Architect 確認後從 Draft 升級為 Accepted / Rejected。

### 現有 MCP 整合基礎

框架已有 ADR-013（diagram MCP 整合）確立了 stdio transport 作為本框架 MCP 整合的標準選擇，以及 `.mcp.json` 的宣告式設定模式。ADR-019 繼承此基礎決策，不重新評估 transport 選擇。

---

## 決策問題

是否應在 Shikigami 框架的現有 plugin 架構之上，引入 MCP 三層架構（知識庫 / 流程管理 / 品質觀察 MCP Server）作為補強層？若引入，應採用何種實作優先序與整合策略？

---

## 三層架構概覽

```
Shikigami Agent（Claude Code）
    │
    ├── Plugin 架構（現有，維持不變）
    │       ├── Skills（23 個 SKILL.md）
    │       ├── Agents（8 個角色）
    │       └── Hooks / Commands
    │
    └── MCP 架構（新增補強層）
            ├── 知識庫 MCP Server → docs/km/ 結構化查詢
            ├── 流程管理 MCP Server → docs/sprints/, PROJECT_BOARD.md 狀態查詢
            └── 品質觀察 MCP Server → 品質指標聚合查詢（POC 已實作）
```

各層職責定義見 `docs/research/mcp-three-layer-architecture.md` §3。

---

## 選項分析

### 選項 A：採用 MCP 三層架構（漸進式補強）

#### 架構描述

在現有 plugin 架構之上，以**補強模式（Augmentation）**引入三個 MCP Server。現有 Skill 不受破壞性修改，MCP tools 作為高效數據存取介面逐步替代部分全文載入場景。

採用漸進式導入序列：

1. **Phase 1**：品質觀察 MCP Server（POC 已驗證，最獨立）
2. **Phase 2**：流程管理 MCP Server（解決平行執行狀態衝突）
3. **Phase 3**：知識庫 MCP Server（最高複雜度，待 Phase 1/2 驗證後實作）

#### .mcp.json 擴充

```json
{
  "mcpServers": {
    "drawio": { ... },
    "shikigami-quality-observer": {
      "type": "stdio",
      "command": "node",
      "args": ["mcp-servers/quality-observer/index.js"],
      "env": { "SHIKIGAMI_ROOT": "${workspaceFolder}" }
    }
  }
}
```

#### 優劣分析

| 面向 | 評估 | 說明 |
|------|------|------|
| Token 效率提升 | 優 | 精確查詢替代全文載入，估計減少 40-60% token 用量（知識查詢場景） |
| 數據一致性 | 優 | 結構化 tool 強制數據格式，減少 Agent 解析 Markdown 的誤差 |
| 平行執行安全性 | 優（Phase 2 後） | 流程管理 MCP Server 作為共享狀態層，防止平行 subagent 狀態衝突 |
| 可測試性 | 優 | MCP tool 介面明確，可獨立 unit test |
| 演進性 | 優 | 底層文件格式可重構而不影響 Skill |
| 初始建置成本 | 劣 | 三個 MCP Server 各需 M-L 工程工作量 |
| 維護負擔 | 劣 | 文件格式變更需同步更新 MCP Server |
| 框架複雜度 | 劣 | 新增 mcp-servers/ 目錄，安裝步驟增加 |
| YAGNI 符合度 | 中 | POC 驗證降低風險；漸進式導入控制 over-engineering |

---

### 選項 B：維持現有 plugin-only 架構

#### 架構描述

不引入 MCP 三層架構，維持現有「全文文件載入」模式。若需改善效率，透過以下措施在 plugin 層面優化：

1. 文件分割（將 Metrics_Log.md 按年度歸檔）
2. 在 Skill 中明確指定只讀取最近 N 個 Sprint 的數據
3. 透過 Skill 約束縮小 context 範圍

#### 優劣分析

| 面向 | 評估 | 說明 |
|------|------|------|
| 維護成本低 | 優 | 無新增基礎設施，現有開發者熟悉度高 |
| 框架複雜度不增加 | 優 | 安裝步驟不變，使用者學習曲線最低 |
| 向後相容 | 優 | 所有現有 Skill 行為完全不變 |
| YAGNI 符合度 | 優（短期） | 避免「尚未確定有必要」的技術導入 |
| Token 效率 | 劣 | 問題持續存在且隨 Sprint 數量增加而惡化 |
| 結構化查詢能力 | 劣 | 無法解決 Quality Observer 多文件整合問題 |
| 平行執行狀態安全 | 劣 | 缺乏共享狀態層，衝突風險隨平行度增加 |
| 技術債累積 | 劣 | 文件規模增長後效率問題將成為必須解決的技術債 |

---

### 選項 C：輕量化 Plugin 封裝（折中方案）

#### 架構描述

不使用 MCP 協議，而是將常用查詢邏輯封裝為 Skill 內的共享 helper 函數或 Skill template。例如在 sprint-execution/SKILL.md 中定義「Metrics 查詢步驟」，強制 Agent 只讀取相關段落而非全文。

#### 優劣分析

| 面向 | 評估 | 說明 |
|------|------|------|
| 無新增依賴 | 優 | 維持純 Markdown Skill 架構 |
| 實作成本低 | 優 | 只需修改 SKILL.md，無 Node.js 開發 |
| 標準化程度低 | 劣 | 依賴 Agent 遵循 Skill 指令，無強制介面約束 |
| 跨 Skill 共享難 | 劣 | Skill 間無法共享查詢邏輯，重複定義風險高 |
| 可測試性 | 劣 | 無法獨立測試查詢邏輯，只能在 Sprint 執行中驗證 |

---

## 評估矩陣

| 評估維度 | 選項 A（MCP 三層架構） | 選項 B（plugin-only） | 選項 C（輕量化 Plugin 封裝） |
|---------|--------------------|---------------------|--------------------------|
| Token 效率 | 高 | 低（持續惡化） | 中 |
| 實作成本 | 高（M-L per server） | 無 | 低 |
| 維護負擔 | 中（需同步文件格式） | 低 | 低 |
| 平行執行安全 | 高（Phase 2 後） | 低 | 低 |
| 可測試性 | 高（MCP tool 可 unit test） | 低 | 低 |
| 框架複雜度 | 高（新增 mcp-servers/） | 無增加 | 低 |
| YAGNI 符合度 | 中（POC 驗證降低風險） | 高 | 高 |
| 長期技術債風險 | 低（前置解決） | 高 | 中 |
| ADR-013 一致性 | 高（stdio 模式繼承） | N/A | N/A |

---

## 約束條件

| 約束 | 來源 | 說明 |
|------|------|------|
| ADR-006 Injection 防護 | ADR-006 | MCP tool 輸出為不信任外部資料，須以 `<mcp_tool_output>` XML 標記包裹 |
| ADR-012 零硬編碼 Secrets | ADR-012 | SHIKIGAMI_ROOT 以環境變數注入，不 hardcode 於 .mcp.json |
| ADR-013 stdio transport | ADR-013 | 繼承 stdio local 部署形態與 transport 選擇 |
| CI 行為一致 | ADR-013 §3 | MCP Server 在 CI 環境的策略需明確定義（跳過或 mock） |
| 寫入操作安全 | 框架設計原則 | 寫入型 tool（status update）需要確認步驟，防止 Agent 誤呼叫 |

---

## 開放問題

| # | 問題 | 優先級 | 狀態 |
|---|------|--------|------|
| OQ-1 | Metrics_Log.md 格式在歷史 Sprint 有差異（Sprint 27-31 備註格式不同），MCP Server 解析準確率需 POC 實際驗證 | 高 | Open |
| OQ-2 | 寫入型 MCP tool 是否需要人工確認步驟？若是，確認機制如何在 stdio transport 中實作？ | 高 | Open |
| OQ-3 | MCP Server 在 CI 環境的行為策略——是否與 ADR-013 CI 跳過原則對齊，或需要 stub？ | 中 | Open |
| OQ-4 | 三個 MCP Server 是否應獨立 npm package 或合併為 monorepo 結構？ | 中 | Open — POC 驗證後決定 |
| OQ-5 | ADR-012 多 GCE 環境的 MCP Server 安裝步驟是否需要統一 setup script？ | 低 | Open |

---

## 實作影響預估（若選擇選項 A）

| 文件 / 目錄 | 變更類型 | 說明 |
|------------|---------|------|
| `mcp-servers/quality-observer/` | **新建（POC 已完成）** | 品質觀察 MCP Server POC |
| `mcp-servers/process-management/` | **新建（Phase 2）** | 流程管理 MCP Server |
| `mcp-servers/knowledge-base/` | **新建（Phase 3）** | 知識庫 MCP Server |
| `.mcp.json` | **修改** | 新增三個 MCP Server 設定 |
| `skills/sprint-review/SKILL.md` | **修改（可選）** | 更新 Metrics 查詢步驟，指向 MCP tool |
| `skills/quality-gate/SKILL.md` | **修改（可選）** | 更新品質指標查詢步驟 |
| `docs/adr/adr-019-*.md` | **本文件** | 架構決策記錄 |

---

## 決策

**狀態**：Draft — 待 PO + Architect 確認

**草稿傾向**：選項 A（漸進式 MCP 三層架構），以 Phase 1（品質觀察 MCP Server）作為起點，依 POC 驗證結果決定 Phase 2/3 的實作時機。

**理由**：
1. Token 效率問題隨 Sprint 數量持續惡化，選項 B 為迴避而非解決
2. ADR-013 已確立 stdio MCP 整合為框架技術方向，選項 A 在同一路徑上延伸，技術一致性高
3. 品質觀察 MCP Server POC 已驗證基本技術可行性（US-243 Sprint 88）
4. 漸進式 Phase 導入控制 over-engineering 風險，符合框架一貫的 YAGNI 原則執行方式

**等待決策的條件**：
- OQ-1（Metrics 解析準確率）的 POC 實際驗證結果
- PO 對維護負擔增加的可接受性評估
- Architect 對寫入操作安全策略（OQ-2）的設計建議

---

## 參考

- `docs/research/mcp-three-layer-architecture.md`：MCP 三層架構完整評估報告（US-243 Spike 產出）
- `mcp-servers/quality-observer/`：品質觀察 MCP Server POC 實作（US-243 Spike 產出）
- ADR-013：shikigami:diagram MCP 整合架構決策（stdio transport 決策來源）
- ADR-006：Prompt Injection 防護（安全約束繼承來源）
- ADR-012：Claude Max 多開發環境認證架構（Secrets 管理規範）
- `docs/km/Quality_Observer.md`：Quality Observer 角色定義
- GitHub Issue #231：US-243 MCP 三層架構評估 Spike
