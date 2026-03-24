## §1.16 Smoke Test 要求：涉及外部資源的 Story

<!-- US-253 Smoke Test 要求 — Sprint 93 -->

TDD 確保程式邏輯正確，但 Mock 導致與真實世界脫節。涉及外部資源的 Story 必須在 TDD 之外要求至少 1 個 smoke test，以真實資料驗證外部系統互動的假設。

> **背景（US-253）**：RSS 新聞 Story 的測試全部 Mock 掉 rss-parser，永遠不會發現 Google News RSS 預設回傳跨年舊文章。TDD 驗證了「程式邏輯正確」，但沒驗證「與外部系統互動的假設是否正確」。

### 外部資源 Story 識別標準（AC1）

滿足以下任一條件即識別為「涉及外部資源的 Story」：

| 識別條件 | 範例 |
|---------|------|
| Story 涉及外部 API 呼叫 | 呼叫第三方 REST API、GraphQL 端點、外部服務 SDK |
| Story 涉及 RSS / Atom Feed 解析 | Google News RSS、任何 RSS/Atom 訂閱源 |
| Story 涉及爬蟲或 Web Scraping | 抓取外部網頁內容 |
| Story 涉及第三方資料庫或 Webhook | 接收外部系統推送資料 |
| Story 涉及雲端服務 API | AWS S3、Google Cloud Storage、SendGrid 等 |
| Story 涉及外部認證服務 | OAuth 2.0、OpenID Connect、SAML 等 |

### 何時需要 Smoke Test（觸發條件）（AC4）

**強制觸發（以下任一條件滿足即必須有 smoke test）：**

1. Story 識別為「涉及外部資源」（依上方識別標準）
2. Story 的 Mock 策略假設了外部系統的特定行為（如 API 回應格式、資料新鮮度）
3. Story 涉及外部系統版本升級或 API 變更

**強制豁免（以下情況可豁免 smoke test）：**

1. 外部服務在開發環境無法存取（需說明替代驗證方式）
2. 外部 API 需付費且 Story 明確無法取得測試憑證（需在 AC 中標注）
3. Story 已有完整的 Contract Test 覆蓋（Consumer-Driven Contract Testing）

**豁免須在 AC 中明確標注**：`[SMOKE-EXEMPT] 原因：{說明}`

### Smoke Test 內容要求（AC2）

涉及外部資源的 Story 必須包含至少 1 個 smoke test，符合以下條件：

| 要求項目 | 說明 | 判定標準 |
|---------|------|---------|
| **真實資料驗證** | Smoke test 使用真實外部資料，不使用 Mock/Stub | 測試代碼中不應有 Mock 外部呼叫的部分 |
| **假設驗證** | 明確驗證 TDD mock 中的假設（如回應格式、資料結構） | 測試斷言覆蓋 mock 假設的核心欄位 |
| **異常偵測** | 能夠偵測外部系統行為與預期不符的情況 | 有意義的斷言，非僅確認「呼叫不報錯」 |
| **可重複執行** | Smoke test 應標注為選擇性執行（`[SMOKE]` 或獨立目錄） | 不影響一般 TDD 測試套件的 CI 執行 |

**Smoke test 文件位置建議**：
- 放置於 `tests/smoke/` 目錄，或
- 測試函式名稱含 `smoke_` 前綴

### Code Review 檢查點（CQ-SMOKE）（AC3）

QA 在 Code Review（外部抽樣審查）時，對「涉及外部資源」的 Story 執行以下額外檢查：

| 檢查項目 | 判定標準 | FAIL 條件 |
|---------|---------|----------|
| **CQ-SMOKE-1 外部資源識別** | Story 涉及外部資源（依識別標準判定） | N/A（識別步驟） |
| **CQ-SMOKE-2 Smoke test 存在** | 交付物中含至少 1 個 smoke test，或有 `[SMOKE-EXEMPT]` 標注 | 無 smoke test 且無豁免標注 → FAIL |
| **CQ-SMOKE-3 Smoke test 使用真實資料** | Smoke test 代碼不 mock 外部呼叫 | Smoke test 仍使用 Mock → FAIL |
| **CQ-SMOKE-4 假設覆蓋** | Smoke test 的斷言覆蓋主要 mock 假設（格式、結構、時效性等） | 斷言空洞（僅確認不報錯） → FAIL |

**CQ-SMOKE FAIL 嚴重度**：

| 情況 | 嚴重度 |
|------|-------|
| Story 涉及外部資源但無 smoke test 且無豁免標注 | Major |
| Smoke test 存在但仍使用 Mock | Important |
| Smoke test 斷言空洞 | Important |

**FAIL 判定**：CQ-SMOKE-2 FAIL（無 smoke test 且無豁免）→ Code Quality Review 整體 FAIL。
