# ADR-017：Context Hub 整合架構決策 — Knowledge Ingestion 機制

**狀態**：Accepted
**日期**：2026-03-11
**決策者**：Architect
**關聯 Issue**：#216（Knowledge Ingestion — Context Hub 整合，API 文件強制內化）
**關聯 ADR**：ADR-006（Prompt Injection Protection）、ADR-007（Story Lifecycle Subagent）、ADR-015（Figma MCP Integration）
**關聯 Sprint**：Sprint 80（平行撰寫）

---

## 背景

Shikigami 框架的 Sprint 執行流程中，Story-Lifecycle subagent（ADR-007）在實作涉及外部 API 整合的 Story 時，僅憑 AC 中提供的 API 文件 URL 進行開發。Agent 並不會主動抓取並內化這些 URL 指向的文件內容，而是依賴自身訓練資料中的 API 知識進行推測。

此行為導致以下已觀察到的問題：

1. **端點幻覺**：Agent 生成不存在的 API endpoint（如 `/v2/users/bulk` 在該 API 中不存在）
2. **參數幻覺**：Agent 使用錯誤的請求參數名稱或型別（如將 `page_size` 寫為 `limit`）
3. **回應格式幻覺**：Agent 假設 API 回應結構與實際不符（如假設分頁使用 `next_cursor` 但實際使用 `offset`）

這些幻覺在 Spec Compliance self-review 階段難以被發現，因為 self-review 同樣缺乏 ground truth 作為對照。

Sprint 80 完成的 US-214（不確定性前置檢查）建立了第一道防線：Agent 在開發前必須列舉假設並標記 `[UNCERTAIN]` 項目。但此機制僅解決「意識到不確定」的情境，無法解決「Agent 自信但錯誤」的情境——即 Agent 不知道自己不知道的問題。

Issue #216 提出整合 [andrewyng/context-hub](https://github.com/andrewyng/context-hub)（`chub` CLI 工具），將 API 文件強制爬取並結構化為本地知識庫，讓 Agent 查詢 ground truth 而非依賴推測。此 Issue 被 ADR-017 Hard Gate 阻塞，本 ADR 即為該 Hard Gate 的決策文件。

### Anti-Hallucination 雙軌策略

本 ADR 的 Knowledge Ingestion 機制與 US-214 的不確定性前置檢查構成互補的雙軌策略：

| 軌道 | 機制 | 解決的問題 | 狀態 |
|------|------|-----------|------|
| 軌道 1：意識層 | US-214 不確定性三問檢查 | Agent 知道自己不確定 → 強制驗證後才能繼續 | Sprint 80 完成 |
| 軌道 2：知識層 | #216 Knowledge Ingestion | Agent 不知道自己不知道 → 提供 ground truth 消除推測空間 | 本 ADR 決策 |

兩軌合併後的預期效果：Agent 在開發前先查閱內化的知識庫（軌道 2），再透過三問檢查確認剩餘不確定項目（軌道 1），形成「先查後問」的閉環。

---

## 決策驅動力

1. **API 幻覺的業務影響**：幻覺導致的錯誤代碼進入 commit 後，修復成本遠高於預防成本。目前依賴 QA self-review 攔截，但 self-review 同樣缺乏 ground truth，攔截率不可靠。

2. **MCP 已是業界標準**：Claude Code、Gemini CLI、Cursor 等主流 AI CLI 平台均已支援 MCP。Shikigami 自身也在 ADR-015 採用 Figma MCP 整合。MCP 不再是「特定平台限定」的機制，而是跨平台通用的工具整合標準。

3. **框架安裝簡潔性**：Shikigami 是供其他專案使用的框架，每增加一個外部依賴都增加使用者的安裝門檻與維護負擔。但 MCP server 的安裝模式（`.mcp.json` 宣告式設定 + `npx` 自動安裝）已大幅降低此門檻。

4. **ADR-006 安全延伸**：外部 API 文件的內容屬於不信任的外部資料來源（使用者指定的 URL 可能指向惡意內容）。任何知識內化機制必須繼承 ADR-006 的 Prompt Injection 防護原則。

5. **知識時效性**：API 文件會隨版本更新而變化。知識庫必須有明確的刷新機制，避免過時知識比沒有知識更危險。

6. **Token 成本控制**：內化的知識庫會佔用 context window。知識庫的體積與查詢方式直接影響每次 Sprint 執行的 token 成本。

---

## 選項分析

### 選項 A：Context Hub as MCP Server Integration

將 `chub`（andrewyng/context-hub）安裝為 MCP server，Agent 透過 MCP tool call 查詢知識庫。

#### 架構示意

```
Claude Code / Gemini CLI / Cursor（MCP 已是業界標準）
    │
    │ MCP tool call（search_docs, get_endpoint, ...）
    ▼
chub MCP Server（本機 stdio 或 remote HTTP+SSE）
    │
    ├── 爬取 API docs URL → 結構化索引
    ├── 向量化搜尋 / 關鍵字搜尋
    └── 回傳結構化 API 知識片段
```

#### .mcp.json 設定示意

```json
{
  "mcpServers": {
    "context-hub": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "context-hub-mcp-server", "--config", ".chub/config.yml"]
    }
  }
}
```

#### 優缺點

| 面向 | 評估 | 說明 |
|------|------|------|
| Claude Code 原生整合 | 優 | MCP tool 自動出現在 Agent 工具列表中，無需額外提示工程 |
| 查詢精準度 | 優 | chub 提供語意搜尋能力，Agent 可按需查詢特定 endpoint |
| Token 效率 | 優 | 按需查詢，僅載入相關知識片段，不預載全量知識 |
| 跨平台相容性 | 優 | MCP 已是業界標準：Claude Code、Gemini CLI、Cursor 均支援；與 ADR-015 Figma MCP 整合一致 |
| 安裝複雜度 | 中 | `.mcp.json` 宣告式設定 + `npx` 自動安裝，使用者已有 MCP 設定經驗（ADR-015 Figma） |
| 外部依賴 | 中 | 依賴 andrewyng/context-hub npm package；但 MCP server 模式降低了直接依賴耦合 |
| MCP server 生命週期管理 | 中 | stdio 模式隨用隨啟，無常駐服務；CI 環境需 fallback 機制（見選項 C） |
| ADR-006 Injection 防護 | 需延伸 | MCP tool 回傳的知識片段為不信任外部資料，需套用 XML 隔離標記 |

#### 風險

- **context-hub MCP server 成熟度**：context-hub 的 MCP server 模式仍在發展中，需確認其 MCP tool schema 穩定性。緩解：鎖定版本 + 定期升級驗證。
- **CI 環境 MCP 不可用**：CI pipeline 通常不啟動 MCP server。緩解：CI 環境 fallback 至選項 C（WebFetch native）或跳過知識爬取。

---

### 選項 B：Context Hub as CLI Tool + Onboarding Skill Extension

將 `chub` 安裝為獨立 CLI 工具，在 Onboarding 與 Sprint 執行流程中透過 Bash 工具呼叫。知識庫以結構化 Markdown 形式存入 `docs/km/api-knowledge/`。

#### 架構示意

```
Onboarding 流程（§2.X Knowledge Ingestion 階段）
    │
    │ Bash: chub crawl <api-docs-url> --output docs/km/api-knowledge/
    ▼
docs/km/api-knowledge/
    ├── stripe-api/
    │   ├── _index.md          # 端點清單與概覽
    │   ├── payments.md        # /v1/payments 端點詳細文件
    │   └── customers.md       # /v1/customers 端點詳細文件
    └── github-api/
        ├── _index.md
        └── ...

Sprint Execution（story-lifecycle-prompt.md）
    │
    │ Read: docs/km/api-knowledge/{api}/_index.md
    │ Read: docs/km/api-knowledge/{api}/{endpoint}.md
    ▼
Agent 使用 ground truth 開發，非推測
```

#### 優缺點

| 面向 | 評估 | 說明 |
|------|------|------|
| 跨平台相容性 | 優 | Bash + Read 工具所有平台皆支援；知識庫為純 Markdown，任何 Agent 均可讀取 |
| 與 Onboarding 整合 | 優 | 自然延伸 Onboarding §2 流程，新增「Knowledge Ingestion」階段 |
| 知識可審查性 | 優 | 知識庫為 Markdown 文件，commit 至 repo，人工可審查、版控可追蹤 |
| 安裝複雜度 | 中 | 需安裝 chub CLI（`npm install -g context-hub`）；比選項 A 簡單但仍為外部依賴 |
| 知識刷新 | 劣 | 需重新執行 `chub crawl` 或 Onboarding Knowledge Ingestion 階段；無自動刷新 |
| chub 搜尋能力未利用 | 劣 | 僅使用 chub 的爬取 + 結構化輸出功能，未使用其語意搜尋；Agent 以 Read 工具直接讀取 Markdown |
| 外部依賴 | 中 | 依賴 context-hub npm package，但僅作為 CLI 工具，不作為常駐服務 |
| Token 成本 | 中 | 知識庫預載為 Markdown，Agent 讀取相關文件時佔用 context；但可控（僅讀取相關端點文件） |

#### 風險

- **chub CLI 安裝門檻**：每個使用 Shikigami 的專案都需要安裝 context-hub，增加了框架的安裝步驟數量。
- **chub 版本相容性**：context-hub 為活躍開發的專案，CLI 介面可能發生破壞性變更，影響 Onboarding 流程穩定性。

---

### 選項 C：Native Knowledge Base（No External Tool）

不引入任何外部工具，利用 Agent 自身已有的工具（WebFetch、Read、Write、Bash）實現知識內化。Agent 在 Sprint 開始時抓取 API 文件，自行轉換為結構化 Markdown 摘要，存入 `docs/km/api-knowledge/`。

#### 架構示意

```
Sprint Execution 開始（story-lifecycle-prompt.md §開始前準備）
    │
    │ 步驟 7.5（三問檢查後、TDD/doc-only 前）
    │
    │ 若 AC 引用 API docs URL：
    │   WebFetch: <api-docs-url>
    │   Agent 自行解析 HTML/JSON → 結構化摘要
    │   Write: docs/km/api-knowledge/{api}/{endpoint}.md
    ▼
docs/km/api-knowledge/
    ├── stripe-api/
    │   ├── _index.md          # Agent 生成的端點清單
    │   ├── payments.md        # Agent 提取的端點摘要
    │   └── _metadata.md       # 爬取時間、來源 URL、Agent 信心度
    └── ...

後續開發步驟
    │
    │ Read: docs/km/api-knowledge/{api}/{endpoint}.md
    ▼
Agent 使用自己提取的 ground truth 開發
```

#### 優缺點

| 面向 | 評估 | 說明 |
|------|------|------|
| 零外部依賴 | 優 | 不需安裝任何額外工具；Shikigami 框架本身即完整 |
| 跨平台相容性 | 優 | WebFetch / Read / Write 為所有平台的基本工具；完全平台中立 |
| 安裝簡潔性 | 優 | 使用者安裝 Shikigami 即可，無額外步驟 |
| 框架自主性 | 優 | 不依賴外部工具的維護週期與相容性；框架維護者完全掌控知識內化邏輯 |
| 知識可審查性 | 優 | 知識庫為 Markdown，commit 至 repo，人工可審查 |
| 與 US-214 整合 | 優 | 知識內化步驟自然嵌入三問檢查流程，形成「爬取 → 三問 → 開發」閉環 |
| 爬取品質 | 中 | Agent 使用 WebFetch 抓取原始 HTML/JSON 後自行解析；品質依賴 Agent 的解析能力而非專用爬蟲 |
| 複雜文件處理 | 劣 | SPA 渲染的 API 文件（如 Swagger UI）可能無法被 WebFetch 正確抓取；需 fallback 機制 |
| Token 成本（爬取階段） | 劣 | Agent 抓取原始 HTML 後需在 context 中解析，大型 API 文件的原始 HTML 可能佔用大量 token |
| 實作工作量 | 中 | 需在 story-lifecycle-prompt.md 中定義完整的知識內化流程與結構化摘要格式規範 |

#### 風險

- **爬取品質不穩定**：不同 API 文件的格式差異大（OpenAPI spec、Markdown、HTML、Swagger UI），Agent 的解析品質可能不一致。可透過定義標準化摘要模板緩解。
- **大型 API 文件的 token 爆炸**：某些 API 文件（如 AWS SDK 完整文件）體積巨大，單次 WebFetch 可能超出 context 限制。需定義「僅爬取 AC 相關端點」的範圍限定規則。

---

## 差異分析表格

| 評估維度 | 選項 A：MCP Server | 選項 B：CLI + Onboarding | 選項 C：Native（無外部工具） |
|---------|-------------------|------------------------|--------------------------|
| **跨平台相容性** | 高（MCP 已是業界標準，主流平台均支援） | 高（所有平台） | 高（所有平台） |
| **安裝複雜度** | 中（.mcp.json + npx 自動安裝） | 中（chub CLI） | 無（零額外安裝） |
| **知識刷新機制** | 即時（每次 tool call 可重新搜尋） | 手動（重新執行 Onboarding / chub crawl） | 自動（每個 Story 開始時按需爬取） |
| **Token 成本影響** | 低（按需查詢，僅載入片段） | 中（預載 Markdown 文件） | 中-高（爬取階段 HTML 解析佔 token） |
| **US-214 整合深度** | 高（MCP tool call 嵌入三問檢查流程，Agent 直接查詢驗證） | 中（Onboarding 預載，三問檢查引用知識庫） | 高（知識爬取嵌入三問檢查流程，形成閉環） |
| **ADR-006 Injection 風險** | 中（MCP server 回傳需套用 XML 隔離標記，與 ADR-015 Figma 同等處理） | 中（chub 輸出 + 外部 URL 內容） | 中（WebFetch 內容，單一注入面） |
| **框架維護負擔** | 中（.mcp.json 版本鎖定，與 ADR-015 Figma MCP 同等維護模式） | 中（chub CLI 版本追蹤） | 低（僅維護 prompt 規範與摘要模板） |
| **知識品質** | 高（chub 專用爬蟲 + 結構化索引） | 高（chub 專用爬蟲） | 中（依賴 Agent 解析能力） |
| **離線可用性** | 部分（本地知識庫可離線查詢） | 完整（Markdown 文件離線可讀） | 完整（知識庫一旦建立，離線可讀） |

---

## 決策

**採用選項 A（Context Hub as MCP Server Integration），選項 C 為 CI 環境 fallback。**

### 決策理由

#### 1. MCP 已是業界標準，與框架現有決策一致

MCP 是 Claude Code、Gemini CLI、Cursor 等主流 AI CLI 平台均支援的工具整合標準。Shikigami 自身已在 ADR-015 採用 Figma MCP 整合——拒絕在 Knowledge Ingestion 中使用 MCP 會造成框架內部的決策矛盾：同一個框架不應一邊擁抱 MCP（設計領域），一邊排斥 MCP（知識領域）。

選項 A 的 `.mcp.json` 宣告式設定與 `npx` 自動安裝模式，使用者已在 ADR-015 Figma 整合中有過設定經驗，學習曲線為零。

#### 2. 根除「幻覺洗白」風險（回應 QA Decision Challenger）

QA Decision Challenger 指出選項 C 的核心矛盾：**用會幻覺的 Agent 去建立防止幻覺的知識庫**。Agent 透過 WebFetch 抓取 HTML 後自行解析，解析過程本身可能引入新的幻覺（誤讀參數型別、漏掉必要參數），這些錯誤被寫入知識庫後反而獲得「已驗證」假象。

選項 A 使用 context-hub 的**專用爬蟲**進行 HTML 解析與結構化索引，解析過程為程式化的 DOM 遍歷，**不經過 LLM 推理**，從根本上消除幻覺洗白風險。同一 URL 爬取結果具有確定性（deterministic），Agent 僅負責查詢，不負責解析。

#### 3. Token 效率最優

選項 A 的按需查詢模式是三個選項中 Token 效率最高的：

- Agent 透過 MCP tool call 查詢特定端點，僅載入相關知識片段
- 不需要將大型 HTML 載入 context 進行解析（選項 C 的劣勢）
- 不需要預載整份 Markdown 知識庫（選項 B 的劣勢）

#### 4. 與 US-214 不確定性檢查的深度整合

MCP tool call 可直接嵌入 story-lifecycle-prompt.md 的三問檢查流程：

```
步驟 7：不確定性三問檢查（US-214）
  │
  │ 三問 (2) 輸出：[UNCERTAIN] Stripe API /v1/payments 的請求參數
  │                → 驗證方式：查詢 Context Hub MCP
  ▼
步驟 7.5：Knowledge Ingestion（本 ADR）
  │
  │ MCP tool call: context_hub.get_endpoint("stripe", "/v1/payments")
  │ → 回傳結構化端點資訊（專用爬蟲解析，非 LLM 推測）
  ▼
步驟 7：回到三問，確認 [UNCERTAIN] 項目已驗證（ground truth 來自專用爬蟲）
  │
  ▼
步驟 8：進入 TDD/doc-only 路徑（所有 [UNCERTAIN] 已驗證）
```

Agent 查詢 MCP 取得的知識是專用爬蟲的確定性輸出，而非 Agent 自己解析的結果。三問檢查 → MCP 查詢 → 確認驗證，整個閉環中 Agent 不需要擔當知識建立者的角色。

#### 5. 知識刷新為即時而非延遲

選項 A 每次 tool call 可指定是否重新搜尋源文件，知識永遠是最新的。選項 B 需重新執行 `chub crawl`，選項 C 依賴 7 天過期機制。對於 API 文件頻繁更新的場景，選項 A 的即時刷新是顯著優勢。

### 排除方案說明

- **選項 B（CLI + Onboarding）**：可行但定位尷尬——使用 chub 的爬取能力但不使用其 MCP 查詢能力，浪費了工具最有價值的部分。若已決定引入 chub，直接走 MCP 整合更合理
- **選項 C（Native Knowledge Base）**：存在「幻覺洗白」系統性風險（QA Decision Challenger 已指出），且 Token 成本在爬取大型 HTML 時不可控。**降級為 CI 環境 fallback**——CI pipeline 不啟動 MCP server 時，fallback 至 WebFetch native 模式

### CI 環境 Fallback 策略（選項 A + C 雙軌）

| 環境 | 策略 | 說明 |
|------|------|------|
| 開發環境（本機） | 選項 A：MCP Server | 正常啟動 context-hub MCP server，Agent 透過 MCP tool call 查詢 |
| CI 環境（`CI=true`） | 選項 C fallback | 跳過 MCP，讀取已存在的知識庫；若知識庫不存在，輸出 `[KNOWLEDGE-INGESTION-SKIPPED: CI_ENV]` |
| MCP server 啟動失敗 | 選項 C fallback | 降級至 WebFetch native 模式，輸出 `[MCP-FALLBACK]` 告警 |

---

## 結果

### 預期效果

1. **API 幻覺顯著降低**：Agent 在開發前透過 MCP 查詢 ground truth，端點名稱、參數、回應格式均來自專用爬蟲解析，非 LLM 推測
2. **根除幻覺洗白風險**：知識建立由專用爬蟲（程式化 DOM 解析）負責，非 LLM Agent。Agent 僅負責查詢，不負責解析，切斷「用幻覺建防幻覺知識庫」的矛盾
3. **三問檢查有效性提升**：`[UNCERTAIN]` 項目有明確的驗證路徑（MCP tool call 查詢），回傳結果具有確定性
4. **與 ADR-015 一致的 MCP 整合模式**：使用者已有 Figma MCP 設定經驗，Knowledge Ingestion MCP 的設定模式完全一致，學習曲線為零

### 可量測指標

| 指標 | 基線（ADR-017 前） | 目標 | 量測方式 |
|------|-------------------|------|---------|
| API 相關 Story 的 Spec Compliance FAIL 率 | 待量測 | 降低 50%+ | Metrics_Log.md |
| `[ASSUMPTION-VIOLATION]` 標記出現率 | 待量測 | 降低 | story-lifecycle 輸出摘要統計 |
| 知識庫命中率 | N/A | 追蹤 | 開發時引用 `docs/km/api-knowledge/` 文件的比例 |

---

## 影響

### 對 story-lifecycle-prompt.md 的影響

story-lifecycle-prompt.md 的「開始前準備」區段需新增「知識查詢」步驟（步驟 7.5），位於 US-214 三問檢查（步驟 7）之後、TDD/doc-only 路徑判斷（步驟 8）之前：

```
步驟 7：不確定性三問檢查（US-214，已實作）
步驟 7.5：Knowledge Ingestion via MCP（本 ADR，新增）
步驟 8：TDD/doc-only 路徑判斷（現有）
```

步驟 7.5 的觸發條件：三問檢查 (2) 中存在 API 相關的 `[UNCERTAIN]` 項目，或 AC 中包含 API docs URL。

### 對 MCP 設定的影響

消費端專案的 `.mcp.json` 需新增 context-hub MCP server 設定：

```json
{
  "mcpServers": {
    "context-hub": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "context-hub-mcp-server", "--config", ".chub/config.yml"]
    }
  }
}
```

此設定模式與 ADR-015 Figma MCP 完全一致，使用者已有設定經驗。

### 對 Onboarding Skill 的影響

Onboarding 流程（skills/onboarding/SKILL.md）需新增「MCP 設定驗證」步驟，確認 `.mcp.json` 中 context-hub MCP server 已配置（與 Figma MCP 驗證同模式）。知識查詢本身發生在 Sprint 執行層面（每個 Story 按需查詢），而非專案初始化層面。

### 對 ADR-006 的影響（Injection 防護延伸）

MCP server 回傳的知識片段屬於不信任外部資料（來源為使用者指定的 API docs URL）。story-lifecycle-prompt.md 的 Knowledge Ingestion 步驟必須繼承 ADR-006 的防護原則：

| 資料來源 | 注入風險 | 緩解策略 |
|---------|---------|---------|
| MCP tool call 回傳的 API 知識片段 | 原始 API 文件可能包含惡意 LLM 指令 | MCP 回傳內容以 `<api_knowledge>` XML 隔離標記包裹（與 ADR-006 `<ci_output>` 同模式），Agent 僅從標記內提取結構化 API 資訊 |
| Fallback 模式（選項 C）的 WebFetch 內容 | 外部 URL 包含注入內容 | Agent 僅提取結構化 API 資訊至預定義模板欄位，不直接搬運原始 HTML |

**ADR-006 §影響延伸宣告**：所有 Context Hub MCP 回傳內容與 WebFetch fallback 取得的外部內容均視為不信任資料，必須以 XML 隔離標記包裹後方可供 Agent 使用。

### 對 Sprint 執行節奏的影響

| 場景 | 現狀 | 採用選項 A 後 |
|------|------|-------------|
| AC 引用 1 個 API docs URL | Agent 憑推測開發 | Agent 透過 MCP tool call 查詢，即時取得結構化知識（增加數秒） |
| 相同 API 的第二個 Story | Agent 憑推測開發 | MCP server 有本地快取，查詢更快（接近零增加） |
| AC 未引用任何 API URL | 無影響 | 步驟 7.5 不觸發，零影響 |
| 大型 API 文件（>50 端點） | N/A | Agent 僅查詢 AC 相關端點，MCP server 按需回傳片段 |

### 對 SBE 知識庫載入策略的影響（兩層索引機制）

**關聯 Story**：US-227

本 ADR 確立的 Token 效率原則（按需載入、最小化 context 佔用）同樣適用於 SBE 業務規則知識庫的載入策略。`docs/definition/sbe-examples/` 目錄採用**兩層索引機制**實現 SBE 知識的漸進載入：

```
Layer 1：docs/definition/sbe-examples/meta-index.md
    │
    │ context 佔用：極小（模組名 + 一句話摘要）
    │ 作用：Agent 掃描所有模組，定位相關模組
    ▼
Layer 2：docs/definition/sbe-examples/<module>/index.md
    │
    │ context 佔用：中等（範例清單 + 簡要描述）
    │ 作用：Agent 在模組內定位具體 SBE 範例
    ▼
Layer 3：docs/definition/sbe-examples/<module>/<name>.sbe.md
    │
    │ context 佔用：完整（Given/When/Then 業務規則全文）
    │ 作用：Agent 依照 SBE 範例執行，作為 ground truth
    ▼
Agent 執行
```

此三層漸進載入策略與本 ADR 的 MCP 按需查詢原則（Token 效率最優）精神一致：不預載全量知識，而是依任務需要按需取用。兩者共同構成 Shikigami 框架的知識載入策略基礎。

**載入策略對比**：

| 知識類型 | 載入機制 | 精準控制手段 |
|---------|---------|------------|
| 外部 API 知識 | Context Hub MCP tool call | 僅查詢 AC 引用的端點 |
| SBE 業務規則知識 | 兩層索引漸進載入 | meta-index → 模組 index → 具體範例 |

---

## 實作路線圖

### Phase 1：MCP Server 設定與 Onboarding 整合（P1，與 #216 實作同步）

#### 1.1 `.mcp.json` 設定模板

消費端專案需在 `.mcp.json` 中新增 context-hub MCP server：

```json
{
  "mcpServers": {
    "context-hub": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "context-hub-mcp-server", "--config", ".chub/config.yml"]
    }
  }
}
```

#### 1.2 Onboarding 整合

Onboarding Skill（`skills/onboarding/SKILL.md`）新增 MCP 設定驗證步驟，確認 context-hub MCP server 已配置。驗證模式與 ADR-015 Figma MCP 一致。

### Phase 2：story-lifecycle-prompt.md 流程整合（P1）

在 story-lifecycle-prompt.md 的「開始前準備」區段新增步驟 7.5：

**觸發條件**：
- 步驟 7 三問檢查 (2) 中存在 API 相關的 `[UNCERTAIN]` 項目
- **或** AC 中包含 API 文件 URL（`http*://` 指向 API docs 的連結）

**執行邏輯**：
1. **環境檢查**：
   - 若偵測到 `CI=true` 環境變數 → fallback 至選項 C（讀取已存在知識庫或跳過），輸出 `[KNOWLEDGE-INGESTION-SKIPPED: CI_ENV]`
   - 若 MCP server 不可用（tool call 失敗）→ fallback 至選項 C（WebFetch native），輸出 `[MCP-FALLBACK]` 告警
2. **MCP 查詢**：透過 context-hub MCP tool call 查詢 AC 引用的 API 端點
3. **回傳內容隔離**：MCP 回傳的知識片段以 `<api_knowledge>` XML 標記包裹（ADR-006 防護延伸）
4. 更新三問檢查 (2) 中相關 `[UNCERTAIN]` 項目的驗證狀態

**範圍限定規則**：
- 僅查詢 AC 直接引用的端點，不查詢 API 全量
- 單次查詢上限：5 個端點（超過時 Agent 選取最相關的 5 個）

**Fallback 模式（選項 C）執行邏輯**：
當 MCP 不可用時，降級至 WebFetch native 模式：
1. 執行 WebFetch 爬取 API docs URL
2. **單一端點 HTML 體積上限**：100KB。超過時優先嘗試 OpenAPI JSON spec URL
3. Agent 自行解析並建立結構化摘要至 `docs/km/api-knowledge/`
4. **知識品質自檢**：Agent 完成摘要後比對結構化元素數量，不足 50% 時降級信心度為 `LOW`，標記 `[KNOWLEDGE-QUALITY-LOW]`
5. WebFetch 失敗時：標記 `[KNOWLEDGE-GAP]`，繼續執行

### Phase 3：知識庫快取與生命週期管理（P2）

1. **MCP server 本地快取**：context-hub MCP server 自行管理知識庫快取，框架不需要額外的過期機制（MCP server 每次查詢可選擇是否重新搜尋源文件）
2. **Fallback 模式知識庫（docs/km/api-knowledge/）**：僅在 fallback 模式下產生，過期判斷以 `git log -1 --format=%ct` 為準（7 天過期），不依賴 Agent 自判
3. **體積監控（僅 fallback 知識庫）**：
   - **軟性警告**（500KB）：Sprint Review 時檢查
   - **硬性上限**（2MB）：CI pipeline 檢查
4. **Production 排除**：`docs/km/api-knowledge/` 加入 `.dockerignore`

### Phase 4：進階整合（P2）

1. **OpenAPI Spec 優先**：若 API 提供 OpenAPI/Swagger JSON spec URL，MCP server 優先索引 JSON spec（結構化程度最高）
2. **手動知識注入**：使用者可手動建立 `docs/km/api-knowledge/{api-name}/{endpoint}.md`，Agent 在 fallback 模式下視為已驗證知識
3. **Annotation 機制**：Agent 發現文件缺口時透過 MCP tool call 標記（`chub annotate`），下次 session 自動呈現

---

## 演進路徑

本 ADR 選擇選項 A（MCP Server）為主要方案，選項 C 為 fallback。

**Fallback 品質監控**：若 `[MCP-FALLBACK]` 頻繁觸發（連續 3 Sprint），應調查 MCP server 可用性問題並修復，而非長期依賴 fallback 模式。

**Fallback 模式品質監控**：
- `[KNOWLEDGE-QUALITY-LOW]` 標記連續出現 3 Sprint → 調查 WebFetch 解析品質，考慮強制要求 MCP 環境
- 每 3 Sprint 人工抽查 fallback 知識庫文件與原始 API 文件的一致性

---

## 審查記錄

### QA Decision Challenger（2026-03-11）

**挑戰標的**：選項 C（Native Knowledge Base）的核心前提——Agent 自行 WebFetch + 解析的品質足夠作為 ground truth。

**核心論點**：用同一個會產生幻覺的 Agent 去建立防止幻覺的知識庫，存在「幻覺洗白」風險——Agent 解析錯誤寫入知識庫後被後續步驟視為 ground truth，使原本可被三問檢查攔截的問題被錯誤認定為已解決。

**結論**：建議重新考慮（選項 C 不宜作為主方案）。

**Architect 回應**：
1. 接受「幻覺洗白」為選項 C 的系統性風險，此風險無法僅靠品質自檢完全消除
2. **決策修正**：將選項 A（MCP Server）升級為主方案——MCP 使用 context-hub 專用爬蟲進行程式化 DOM 解析（非 LLM 推理），從根本上消除幻覺洗白風險
3. 選項 C 降級為 CI 環境 fallback，僅在 MCP 不可用時啟用，並保留品質自檢機制（`[KNOWLEDGE-QUALITY-LOW]` 標記）作為 fallback 模式的安全網
4. MCP 已是業界標準（Claude Code、Gemini CLI、Cursor 均支援），且 Shikigami ADR-015 已採用 Figma MCP——採用選項 A 與框架現有決策完全一致

### SRE Review（2026-03-11）

**結論**：PASS with conditions（2 個必要條件，均已在最終決策中滿足）。

**條件 1**：CI 環境 MCP server 不可用時的明確處理機制。
**Architect 回應**：已在 Phase 2 執行邏輯步驟 1 中加入環境檢查——CI 環境（`CI=true`）自動 fallback 至選項 C，輸出 `[KNOWLEDGE-INGESTION-SKIPPED: CI_ENV]`；MCP server 啟動失敗時 fallback 至 WebFetch native，輸出 `[MCP-FALLBACK]`。兩種 fallback 路徑均有明確告警，無靜默降級。

**條件 2**：fallback 模式知識庫的過期判斷改為不依賴 Agent 自判的強制機制。
**Architect 回應**：已將過期判斷改為 git-based 機制（`git log -1 --format=%ct`），不依賴 `_metadata.md` 中 Agent 自行記錄的時間戳。此條件僅影響 fallback 模式產生的 `docs/km/api-knowledge/` 知識庫；MCP 主路徑無本地知識庫，每次查詢即時取得最新資料。

**額外採納的建議**：
- 單一端點 HTML 體積上限 100KB（R4 緩解，僅 fallback 模式適用）
- 知識庫體積雙軌機制（500KB 軟性 + 2MB 硬性 CI 檢查）（R5 緩解，僅 fallback 模式適用）
- Production artifact 排除（R6 緩解）
- 並行執行衝突：知識庫文件以各端點獨立文件為主，`_index.md` 採 append-only 格式（R3 緩解，僅 fallback 模式適用）

---

## 參考

- GitHub Issue #216：Knowledge Ingestion — Context Hub 整合，API 文件強制內化
- GitHub Issue #215：US-214 不確定性前置檢查（Sprint 80 完成）
- ADR-006：Issue 內容提示注入防護（§Prompt Injection Isolation Rule）
- ADR-007：Story 生命週期 Subagent 封裝（§AC2 介面契約、§AC3 審查獨立性）
- ADR-013：shikigami:diagram MCP 整合架構決策（§4.4 Supply Chain 安全）
- ADR-015：Figma 整合架構決策（MCP 整合模式先例，`.mcp.json` 宣告式設定）
- [andrewyng/context-hub](https://github.com/andrewyng/context-hub)：Context Hub CLI 工具
- OWASP Top 10 for LLM Applications — LLM01: Prompt Injection（外部內容注入風險）
- `docs/definition/sbe-examples/meta-index.md`：SBE 範例庫 Meta-Index（兩層索引機制 Layer 1）
- `docs/definition/sbe-examples/sprint-lifecycle/index.md`：Sprint Lifecycle 模組 SBE Index（兩層索引機制 Layer 2）
