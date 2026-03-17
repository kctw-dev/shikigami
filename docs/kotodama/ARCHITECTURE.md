# Kotodama -- 系統架構

AI 產品經理。面對客戶理解需求，驅動 Shikigami 工程團隊執行。每個產品一套獨立實例。

## 架構圖

```
  LINE / Slack (Webhook)
        │
        ▼
┌──────────────────────────────┐
│  Kotodama (單一 Node.js app) │
│                              │
│  Webhook Handler             │
│    → Channel Adapter         │
│    → Conversation State      │
│    → AI Core (Claude API)    │
│    → Escalation Check        │
│    → Reply                   │
│                              │
│  Tools:                      │
│    query_backlog              │
│    query_spec_docs            │
│    query_sprint_status        │
│    ...                        │
└──────────┬───────────────────┘
           │
     PostgreSQL
  (對話、需求、知識)
```

一個 process、一個 DB、一個 config。Docker Compose 部署。

## 安全模型 -- AI 知識權限矩陣

PM 只能查該查的。禁止的工具不註冊到 LLM tool schema，LLM 無法呼叫不存在的 tool。

| Tool | 允許 | 說明 |
|------|------|------|
| query_feature_list | Y | 產品功能清單 |
| query_spec_docs | Y | 規格文件 |
| query_backlog | Y | 需求 Backlog |
| query_sprint_status | Y | Sprint 狀態 |
| query_changelog | Y | 變更紀錄 |
| query_bug_list | Y | Bug 清單 |
| query_api_capabilities | Y | API 能力描述 |
| query_conversation_history | Y | 對話歷史 |
| query_decision_log | Y | 決策紀錄 |
| access_source_code | N | 不註冊 |
| access_prod_data | N | 不註冊 |
| access_credentials | N | 不註冊 |

## 對話狀態機

```
IDLE → EXPLORING → CLARIFYING → CONFIRMED → DELIVERED
              ↑         │
              └─ 修改 ──┘

任何狀態 → ESCALATED
```

五個狀態就夠。需求還沒確認前都在 EXPLORING/CLARIFYING 之間來回，確認了就 CONFIRMED，交付了就 DELIVERED。

## 升級機制

**觸發條件：**
- 超出職權：報價、合約、技術承諾、架構變更
- 對話卡住：同一需求 >3 輪未收斂、客戶情緒負面

**人類介入模式：**
- Takeover -- 人類接管對話
- Assist -- 人類給指示，AI 繼續執行
- Override -- 人類修正 AI 草稿

## Shikigami 整合

需求 CONFIRMED 後轉為 Shikigami Issue，雙向同步 Sprint 狀態。

## 技術棧

| 項目 | 選擇 | 理由 |
|------|------|------|
| 語言 | TypeScript (Node.js) | 非同步 IO、管道 SDK 支援完善 |
| 主資料庫 | PostgreSQL | JSONB、成熟穩定 |
| LLM | Claude API | Tool-use 強、長 context |
| 部署 | Docker Compose | 單一實例，簡單可靠 |
| 日誌 | 結構化 JSON log | 夠用，不需要 Grafana |

## 關鍵 ADR

| ADR | 決策 |
|-----|------|
| ADR-001 | 單一實例 per 產品，非多租戶共享 |
| ADR-003 | Tool schema 排除，非 prompt 約束（安全核心） |
| ADR-004 | 顯式狀態機，非純 LLM 自由流 |
