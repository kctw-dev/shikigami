# Kotodama（言霊）— 系統架構設計

## 1. 系統總覽

AI 產品經理系統。AI 扮演產品經理，面對客戶理解需求，驅動 Shikigami 工程團隊執行。每個產品部署一套獨立實例，各自接自己的資料源。

### 關鍵架構決策

| 決策 | 選擇 | 理由 |
|------|------|------|
| 部署模型 | 單一實例 per 產品 | 簡單可靠，用 template 一鍵部署，各實例完全獨立 |
| 訊息匯流排 | NATS JetStream | 輕量低延遲，subject-based routing |
| AI 引擎 | LLM + Tool-use 架構 | PM 角色需要結構化推理與外部知識查詢 |
| 對話狀態 | 顯式狀態機 + 持久化 | 需求釐清有明確階段，可追蹤可恢復 |
| 管道適配 | Adapter Pattern + 統一訊息格式 | 新管道只加 adapter 不動核心 |

## 2. 系統架構圖

```
                                 ┌─────────────────────────────────┐
                                 │         Channel Layer           │
                                 │  LINE / Slack / Telegram /      │
                                 │  Web Chat / Email Adapters      │
                                 └────────────┬────────────────────┘
                                              │
                              ┌───────────────▼────────────────────┐
                              │   Unified Message Bus (NATS JS)    │
                              │   inbound / outbound               │
                              └───────────────┬────────────────────┘
                                              │
                    ┌─────────────────────────┼─────────────────────────┐
                    ▼                         ▼                         ▼
           ┌────────────────┐     ┌───────────────────┐     ┌──────────────────┐
           │ Conversation   │     │  AI Product       │     │  Escalation      │
           │ Manager        │     │  Manager Core     │     │  Manager         │
           │ - Session mgmt │     │  - State Machine  │     │  - Rule Engine   │
           │                │     │  - LLM Orchestrate│     │  - Notification  │
           └────────────────┘     └───────────────────┘     └──────────────────┘
                                              │
           ┌──────────────────────────────────┼──────────────────────────────┐
           ▼                    ▼              ▼              ▼              ▼
    ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌───────────┐
    │ Knowledge    │ │ Requirement  │ │ Sprint       │ │ Audit     │
    │ Query Svc    │ │ Manager Svc  │ │ Bridge Svc   │ │ Logger    │
    └──────────────┘ └──────────────┘ └──────────────┘ └───────────┘
                                              │
           ┌──────────────────────────────────▼──────────────────────────────┐
           │                  Data Access Layer (DAL)                        │
           │  PostgreSQL / Redis / MinIO / pgvector                         │
           └────────────────────────────────────────────────────────────────┘
```

## 3. 安全模型

### Application Layer
- JWT claim 解析，Channel identity mapping
- Request context binding（不可變）

### Data Access Layer
- Audit logging
- 查詢權限控制

### Database Layer
- 每個實例獨立的 PostgreSQL database
- 實例間物理隔離，無需跨實例防護

### AI 知識查詢權限矩陣

PM 只能查該查的——禁止的工具根本不存在於 LLM 的 tool schema，LLM 無法呼叫不存在的 tool。

| Tool | 允許 | 說明 |
|------|------|------|
| query_feature_list | ✓ | 產品功能清單 |
| query_spec_docs | ✓ | 規格文件 |
| query_backlog | ✓ | 需求 Backlog |
| query_sprint_status | ✓ | Sprint 狀態 |
| query_changelog | ✓ | 變更紀錄 |
| query_bug_list | ✓ | Bug 清單 |
| query_api_capabilities | ✓ | API 能力描述 |
| query_conversation_history | ✓ | 對話歷史 |
| query_decision_log | ✓ | 決策紀錄 |
| access_source_code | ✗ | Tool 不註冊到 LLM schema |
| access_prod_data | ✗ | Tool 不註冊到 LLM schema |
| access_credentials | ✗ | Tool 不註冊到 LLM schema |

## 4. 對話狀態機

```
IDLE → EXPLORING → CLARIFYING → DRAFTING → REVIEWING → CONFIRMED → SCHEDULED → IN_PROGRESS → DELIVERED
                        ↑            │
                        └── 客戶要求修改 ──┘

任何狀態均可觸發 → ESCALATED
```

### 多人共享對話衝突處理
1. 收集窗口：30 秒，收集同時段輸入
2. 衝突偵測：AI 分析是否矛盾，明確指出矛盾點
3. 角色權重：老闆方向 > PM 功能 > 工程師技術，但不自動裁決
4. 決策紀錄：誰提出、誰決定、最終結論

## 5. 升級機制

### 觸發條件
**超出職權：** 報價/費用、合約條款、不確定的技術承諾、核心架構變更
**對話卡住：** 同一需求 >3 輪未收斂、客戶情緒負面、工程交付阻塞 >2 天

### 人類介入模式
- **Takeover：** 人類完全接管對話
- **Assist：** 人類提供指示，AI 繼續執行
- **Override：** 人類修正 AI 草稿

## 6. 多管道統一訊息架構

### UnifiedMessage 格式
- message_id, channel_type, direction
- sender (platform_user_id, role)
- content (type, text, rich_blocks, attachments)
- conversation_id, thread_id
- metadata (sentiment, intent, language)

### 管道適配器介面
- normalize(rawEvent) → UnifiedMessage
- render(UnifiedMessage) → ChannelPayload
- capabilities() → ChannelCapabilities
- verifySignature(request) → Boolean

### 輸出降級策略
各管道根據 capabilities 自動降級呈現。

## 7. 工程銜接 — Shikigami 整合

Sprint Bridge Service：
- UserStory CONFIRMED → 轉換為 Shikigami Issue
- 雙向同步：Sprint 狀態 ↔ 平台進度
- 映射：Product ↔ Repo, Story ↔ Issue, Sprint ↔ Sprint

## 8. 部署模型

每個產品部署一套獨立的 Kotodama 實例：

- **部署方式**：Helm chart / Docker Compose template 一鍵部署
- **資料隔離**：每套實例有自己的 PostgreSQL database、Redis、MinIO
- **獨立性**：實例間無共享狀態，故障不互相影響
- **擴展方式**：新產品 = 部署新實例

## 9. 技術棧

| 層級 | 技術 | 理由 |
|------|------|------|
| 語言 | TypeScript (Node.js) | 非同步 IO、管道 SDK 支援完善 |
| API 框架 | Fastify | 高性能、schema validation 內建 |
| 訊息匯流排 | NATS JetStream | 輕量、at-least-once、subject routing |
| 主資料庫 | PostgreSQL 16+ | JSONB、成熟穩定 |
| 快取 | Redis (Valkey) | Session、cache、去重 |
| 物件儲存 | MinIO / S3 | 附件、文件 |
| LLM | Claude API | Tool-use 強、長 context |
| 向量搜尋 | pgvector | 單一實例規模足夠 |
| 容器編排 | K3s | 輕量夠用 |
| 監控 | OpenTelemetry + Grafana | 分散式追蹤統一 |

## 10. ADR 摘要

| ADR | 決策 |
|-----|------|
| ADR-001 | 單一實例 per 產品而非多租戶共享平台 |
| ADR-002 | NATS JetStream 而非 Kafka |
| ADR-003 | Tool schema 排除而非 prompt 約束 |
| ADR-004 | 顯式狀態機而非純 LLM 自由流 |
| ADR-005 | 收集窗口而非即時逐條回應 |
| ADR-006 | 規則引擎而非純 LLM 判斷升級 |
| ADR-007 | 輸出降級而非最小公分母 |
| ADR-008 | pgvector 而非獨立向量 DB |
