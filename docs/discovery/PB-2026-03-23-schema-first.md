# Product Brief: Schema 先行（API Contract 統一定義）

**PB ID**: PB-2026-03-23-schema-first
**狀態**: Draft
**建立日期**: 2026-03-23
**來源議題**: #362 GAD 研究報告 §二 核心設計原則
**產品負責人**: PO Agent

---

## 1. 問題陳述

在使用 Shikigami 的 GAD（Group Autonomous Development）場景中，多組 agent 並行開發時缺乏統一的介面契約：

- **介面對接靠猜測**：前端 agent 實作 API 呼叫時，只能猜測後端的回應格式，或依賴自然語言描述，容易產生不一致
- **整合測試發現晚**：前後端各自開發完成後才在整合階段發現欄位名稱錯誤、型別不符等問題，返工成本高
- **DB Schema 與 API 脫鉤**：DB agent 設計的資料模型與 API 暴露的欄位往往需要額外對映，且沒有自動驗證
- **版本管理缺失**：API 變更時沒有 Schema 版本紀錄，難以追蹤「這次變更影響哪些組的哪些實作」
- **文件即代碼缺失**：沒有 machine-readable 的 API 契約，無法自動生成 client stub 或 mock server

GAD 研究報告（#362）明確指出：Schema-first 是多組並行開發的基礎，在開發前先定義並共享 Schema 可大幅降低整合成本。

---

## 2. 目標使用者

**主要**：使用 Shikigami 執行 GAD 的開發者（多個 agent 組並行工作的場景）
**次要**：Solo 開發者（單一 agent 組），Schema 文件也有助於單人開發的思路清晰度

使用場景：
- Sprint Planning 時，Architect agent 定義 API Schema，前後端 agent 組各自依 Schema 實作
- DB agent 設計資料模型後，自動從 Schema 生成 TypeScript 型別或 Python Pydantic model
- QA agent 使用 Schema 生成 API mock server，在後端完成前讓前端能獨立測試

---

## 3. 商業假設 [UNCERTAIN]

- [UNCERTAIN] 在 GAD 場景中，整合問題佔所有 defect 的 30–50%，Schema 先行可降低此比例 60% 以上
- [UNCERTAIN] Architect agent 可在 Sprint Planning 階段以 30 分鐘以內完成初版 OpenAPI Schema 草稿
- [UNCERTAIN] 各組 agent 願意且能夠遵守「Schema 是 source of truth，不可自行修改」的規範
- [UNCERTAIN] JSON Schema / OpenAPI 格式的 agent 可讀性足夠好，agent 可直接解析並生成符合規範的代碼

---

## 4. 提案解決方向

### 核心概念
在 Sprint Planning 結束、各組開始實作前，新增「Schema 定義」階段：由 Architect agent 主導產出 OpenAPI spec 或 JSON Schema，各組以此為契約並行開發。

### Schema 生命週期
1. **Define**：Architect agent 在 `docs/schema/` 目錄建立 `[feature-name].openapi.yaml`
2. **Review**：QA agent 審查 Schema 的完整性（必要欄位、錯誤碼、認證方式）
3. **Lock**：PO 確認 Schema 進入 locked 狀態，各組可開始實作
4. **Evolve**：Schema 變更必須走 Change Request 流程，影響組需要被通知

### 方向 A：OpenAPI First
以 OpenAPI 3.0 作為統一格式，自動生成：TypeScript types（openapi-typescript）、Python models（datamodel-code-generator）、mock server（prism）。

### 方向 B：JSON Schema First（輕量版）
用 JSON Schema 描述資料模型（不含 HTTP 語意），適合不一定有 REST API 的場景（如 event-driven）。

### 方向 C：Contract Testing（Consumer-Driven）
各組定義自己的 consumer contract，Pact 等工具驗證 provider 符合所有 consumer 的期望。比 Schema-first 更靈活但更複雜。

推薦方向：**方向 A**（OpenAPI First，標準化程度最高，工具生態最成熟），方向 B 作為補充（非 REST 場景）。

---

## 5. 成功指標

| 指標 | 基準線 | 目標 | 測量方式 |
|------|--------|------|----------|
| 整合階段發現的介面不一致問題數 / Sprint | 待建立基準 | 降低 60% | Sprint Review 統計 |
| Schema 定義完成時間（Planning 到 locked） | N/A | < 2 小時 | Sprint Planning 紀錄 |
| 從 Schema 自動生成的 client code 採用率 | N/A | ≥ 80% | 代碼審查統計 |
| 因介面問題導致的返工 Story 數 | 待建立基準 | 降低 50% | Sprint 統計 |

---

## 6. 排除範圍

- 不處理 gRPC / GraphQL 等非 REST 協議（本 PB 聚焦 REST API）
- 不實作 Schema registry 服務（檔案系統 + git 版本控制即可）
- 不處理 DB migration 自動化（Schema 定義到 DB migration 的轉換是獨立議題）
- 不涉及 runtime API validation（只處理開發前的契約定義，不是 runtime middleware）

---

## 7. 依賴與風險

### 依賴
- Sprint Planning Skill 需要新增「Schema 定義」階段（Scrum Master Skill 修改）
- Architect agent 需要有 OpenAPI Schema 生成能力（現有能力評估需確認）
- `docs/schema/` 目錄結構與命名規範需要定義
- 各 agent 組需要知道「在哪裡找 Schema，Schema locked 後才能開始實作」

### 風險
| 風險 | 可能性 | 影響 | 緩解策略 |
|------|--------|------|----------|
| Architect agent 產出的 Schema 品質不足，需要多輪修改 | 中 | 高 | Schema Review 由 QA + Developer 雙重審查，設定 review checklist |
| Schema 頻繁變更，各組跟不上更新 | 中 | 高 | Schema change request 流程必須通知所有相關組，並提供 migration guide |
| 開發者覺得 Schema 定義是額外負擔，不願配合 | 低 | 中 | 展示 Schema-to-code 自動生成的節省效益，降低配合成本 |
| Non-GAD（Solo）場景強制 Schema 造成過度工程 | 低 | 低 | Schema 定義為 GAD 場景的 opt-in，Solo 場景不強制 |
