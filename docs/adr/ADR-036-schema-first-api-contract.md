# ADR-036：Schema-first API Contract 統一定義架構決策

**日期**：2026-03-24
**狀態**：Accepted
**相關 Issue**：#601（ADR RESEARCH）、#406（feat: Schema 先行 — API Contract 統一定義）
**提案者**：Architect Agent（Sprint 136 ADR RESEARCH）
**關聯 ADR**：ADR-007（Story-Lifecycle Subagent）、ADR-016（DESIGN/FEATURE Sprint 排序）

---

## 背景

### 問題陳述

Shikigami 的 GAD（Group Agent Development）工作流程目前缺乏統一的 API Contract 定義階段。當多個 Agent Group 並行開發時，介面協定往往在實作過程中才被隱性協商，導致：

1. **介面不一致**：Agent Group A 和 B 對同一介面的假設不同，整合階段出現大量衝突
2. **無法驗證**：Sprint Planning 的 AC 無法針對介面合約進行自動化驗證
3. **鎖定時機不明**：不清楚何時介面應被「凍結（locked）」，何時允許修改
4. **格式選擇缺失**：OpenAPI 3.0 vs JSON Schema 各有優缺點，未有明確選型依據

### 決策需求

選定 Schema-first API Contract 的：
- 描述格式（Schema 語言）
- 目錄結構與命名規範
- locked 狀態機制定義
- Sprint Planning 流程整合點

---

## 選項比較

### Option A：OpenAPI 3.0（YAML/JSON）

**描述**：使用業界標準 OpenAPI 3.0 規格定義 HTTP API Contract，包含 path、method、request/response schema、status codes。

**優點**：
- 業界廣泛採用，工具鏈成熟（Swagger UI、Redoc、openapi-generator）
- 支援完整 HTTP 語意（路徑、方法、狀態碼、headers）
- 可直接生成 client/server stub
- 與 Postman、Insomnia 等測試工具原生整合

**缺點**：
- 對純 Agent-to-Agent（非 HTTP）介面語意過重
- YAML 結構較複雜，非 HTTP 場景（如 function calling schema）需額外適配
- 學習曲線較高，非 HTTP 背景的 Agent role 上手成本較高

**適用場景**：GAD 中涉及 HTTP REST API 的 Agent 協作介面。

---

### Option B：JSON Schema（Draft 2020-12）

**描述**：使用 JSON Schema 定義資料結構合約，不假設傳輸層協定，適用任意資料交換場景。

**優點**：
- 輕量且與傳輸層無關（HTTP、Agent function call、WebSocket 均適用）
- Claude function calling / tool use 原生使用 JSON Schema，語意高度一致
- 結構簡單，易於 Agent 自動生成與解析
- 驗證工具普及（ajv、jsonschema-python 等）

**缺點**：
- 不涵蓋 HTTP 語意（無路徑、方法、狀態碼定義）
- 若需完整 REST API 文件，需搭配其他工具

**適用場景**：Agent function calling schema、Agent-to-Agent 資料交換合約、非 HTTP 場景。

---

### Option C：混合策略（JSON Schema 為主，OpenAPI 為輔）

**描述**：以 JSON Schema 作為 Shikigami 內部 Agent Contract 的主要格式，僅在明確需要 HTTP API 文件時採用 OpenAPI 3.0（OpenAPI 的 `components/schemas` 本身即為 JSON Schema 超集）。

**優點**：
- 覆蓋 Shikigami 最主要的使用場景（Agent tool calling）
- HTTP API 場景可直接升級至 OpenAPI，無需重寫 schema
- 漸進式採用，降低初期複雜度
- 與 Claude API 工具呼叫格式天然對齊

**缺點**：
- 維護兩種格式需要規範文件說明切換時機
- 混合策略若缺乏明確規範，可能造成格式選擇混亂

---

## 決策

**採用 Option C：混合策略（JSON Schema 為主，OpenAPI 為輔）**

### 理由

1. **Shikigami 主要使用場景**是 Agent-to-Agent function calling contract（JSON Schema），而非 HTTP REST API documentation（OpenAPI）
2. **ADR-037 JIT Retrieval** 採用 JSON Schema 定義 tool schema，與本決策保持一致
3. **漸進式採用**：絕大多數 GAD 場景只需 JSON Schema，HTTP API 文件需求出現時再引入 OpenAPI，避免過度設計
4. **Claude tool use 原生格式**：JSON Schema 是 Claude function calling 的原生 schema 語言，Agent 理解成本最低

### 採用規則

| 場景 | 格式 |
|------|------|
| Agent function calling contract | JSON Schema（Draft 2020-12）|
| Agent-to-Agent 資料交換 | JSON Schema |
| HTTP REST API 文件 | OpenAPI 3.0（YAML） |
| 不確定場景 | JSON Schema（預設） |

---

## 目錄結構與命名規範

```
docs/schema/
├── README.md                          # 命名規範與格式說明
├── <sprint-N>/                        # 每個 Sprint 的 schema 快照
│   ├── <story-id>-<description>.json  # JSON Schema Contract
│   └── <story-id>-<description>.yaml  # OpenAPI Contract（若為 HTTP）
└── locked/                            # 已鎖定（不可修改）的 contract
    └── <story-id>-<description>.json
```

**命名規則**：
- 檔名使用 kebab-case
- 前綴為 Story ID（如 `406-schema-first-gad.json`）
- JSON Schema 副檔名 `.json`，OpenAPI 副檔名 `.yaml`

---

## locked 狀態機制

Schema Contract 有三個生命週期狀態：

| 狀態 | 說明 | 修改權限 |
|------|------|---------|
| `draft` | 起草中，隨 Story 開發演進 | 任何 Agent 可修改 |
| `review` | Sprint Planning / Architect 審查中 | 僅 Architect 可修改 |
| `locked` | 凍結，各組以此為實作依據 | 禁止修改，需新建版本 |

**鎖定時機**：Sprint Planning 完成 Architect 技術評估後，Architect 將本 Sprint 使用的 Contract 狀態設為 `locked`，並移至 `docs/schema/locked/` 目錄。

**記錄方式**：在 `sprint_N.md` 中新增「Schema Contracts」區塊，列出本 Sprint 所有 locked schema 路徑。

---

## 影響分析

### 需要更新的文件

| 文件 | 更新內容 |
|------|---------|
| `skills/sprint-planning/references/architect-prompt.md` | 新增 Schema Definition 階段指引（#406 實作） |
| `docs/schema/README.md` | 建立命名規範與格式說明（#406 實作） |

### 對現有流程的影響

- Sprint Planning Architect 評估新增「Schema Contract 輸出」步驟
- Story-Lifecycle subagent 的 API 契約欄位現在有明確的格式選擇依據
- RESEARCH / DESIGN type Story 不需要產出 Schema Contract（豁免）

### 不影響的部分

- 現有 ADR、SDD、Sprint 文件格式不變
- Agent 角色定義、Hook 機制不變
- 無 breaking change（純新增，無刪除）

---

## 參考

- [JSON Schema 官方規格](https://json-schema.org/draft/2020-12)
- [OpenAPI 3.0 規格](https://spec.openapis.org/oas/v3.0.3)
- ADR-016：DESIGN/FEATURE Sprint 排序規則
- ADR-037：Context Engineering JIT Retrieval（JSON Schema 使用案例）
- Issue #406：feat: Schema 先行 — API Contract 統一定義
- Issue #601：RESEARCH: ADR-036 — Schema-first API Contract 統一定義架構決策
