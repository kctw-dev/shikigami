# Schema Contract 目錄

**建立日期**：2026-03-24
**決策依據**：ADR-036（Schema-first API Contract 統一定義）
**觸發 Story**：#406 feat: Schema 先行 — API Contract 統一定義

---

## 目的

此目錄存放 Shikigami GAD（Group Agent Development）工作流程中各 Sprint 的 API Contract 定義檔案，作為多 Agent Group 並行開發的介面協定基礎。

---

## 格式規範

### 使用格式（依 ADR-036 決策）

| 場景 | 格式 |
|------|------|
| Agent function calling contract | JSON Schema（Draft 2020-12，`.json`）|
| Agent-to-Agent 資料交換 | JSON Schema（`.json`）|
| HTTP REST API 文件 | OpenAPI 3.0（`.yaml`）|
| 不確定場景 | JSON Schema（預設）|

---

## 命名規範（kebab-case）

```
docs/schema/
├── README.md                          # 本文件
├── sprint-<N>/                        # 每個 Sprint 的 schema 工作目錄
│   ├── <story-id>-<description>.json  # JSON Schema Contract（draft 狀態）
│   └── <story-id>-<description>.yaml  # OpenAPI Contract（若為 HTTP 場景）
└── locked/                            # 已鎖定（不可修改）的 Contract
    └── <story-id>-<description>.json
```

**命名規則**：
- 目錄與檔名均使用 **kebab-case**（全小寫，單字以連字號分隔）
- 檔名前綴為 Story ID（如 `406-gad-agent-contract.json`）
- JSON Schema 副檔名：`.json`
- OpenAPI 副檔名：`.yaml`

**範例**：
- `docs/schema/sprint-136/406-gad-agent-contract.json`
- `docs/schema/locked/406-gad-agent-contract.json`（鎖定後移至此）

---

## Contract 生命週期狀態

| 狀態 | 說明 | 修改權限 | 存放位置 |
|------|------|---------|---------|
| `draft` | 起草中，隨 Story 開發演進 | 任何 Agent 可修改 | `sprint-<N>/` |
| `review` | Sprint Planning / Architect 審查中 | 僅 Architect 可修改 | `sprint-<N>/` |
| `locked` | 凍結，各組以此為實作依據 | 禁止修改，需新建版本 | `locked/` |

---

## 鎖定流程（Sprint Planning 中）

1. Architect 完成技術評估後，將本 Sprint 使用的 Contract 狀態設為 `locked`
2. 將 Contract 檔案從 `sprint-<N>/` 複製至 `locked/`
3. 在 `sprint_N.md` 的「Schema Contracts」區塊記錄 locked schema 路徑

---

## Sprint_N.md 記錄格式

在每個 Sprint 文件中，新增以下區塊：

```markdown
## Schema Contracts（#406 Schema 先行）

| Contract | 路徑 | 狀態 | 使用 Story |
|---------|------|------|-----------|
| GAD Agent Contract | docs/schema/locked/N-description.json | locked | #N |
```

---

## 範例檔案

| 範例 | 路徑 | 說明 |
|------|------|------|
| GAD Agent Contract 範例 | [`examples/gad-agent-contract.example.json`](examples/gad-agent-contract.example.json) | Claude tool use JSON Schema Draft 2020-12 格式的完整範例，包含 name / description / input_schema 欄位定義，附兩個真實 Agent contract 案例（sprint_planning_trigger / issue_triage） |

> **使用方式**：複製此範例，依實際 Agent tool 需求修改 `name`、`description`、`input_schema.properties`，存至 `sprint-<N>/` 目錄，命名規則見上方「命名規範」。

---

## 參考

- ADR-036：`docs/adr/ADR-036-schema-first-api-contract.md`
- JSON Schema 規格：https://json-schema.org/draft/2020-12
- OpenAPI 3.0 規格：https://spec.openapis.org/oas/v3.0.3
