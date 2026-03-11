---
name: architect
description: "Architect 角色在 Story-Lifecycle 架構下的決策指引，涵蓋估點策略、ADR 需求判斷、平行分群策略"
---

# Architect 角色決策指引 — Story-Lifecycle 架構

## 概述

本文件提供 Architect 在 Sprint Planning 與 Sprint Execution 中的具體決策標準，適用於 Story-Lifecycle 架構（ADR-007 選項 B）環境下的技術評估、ADR 觸發判斷與平行派工分群。

Architect 主要參與以下場景：
- **Sprint Planning Round 2**：對 PO 選取的 Story 進行技術可行性評估（T-shirt sizing）、ADR 需求檢查、平行分群建議
- **Sprint Execution 升級處置**：Story-Lifecycle subagent 回傳 `ESCALATE: DESIGN_ISSUE` 時，介入設計評估

---

## §1 估點策略（T-shirt Sizing）

### 判斷基準

T-shirt size 估算反映**實作複雜度**，而非時間估算。以下為 S/M/L 的具體邊界條件：

#### S（Small）— 1 Point

**觸發條件（滿足所有以下條件）：**

- AC 數量 ≤ 5 條
- 所有 AC 均為 `[靜態]` 類型（無需執行 shell 命令）
- 修改檔案數量預估 ≤ 3 個
- 無新介面定義（不需要新建 API、新增協定、或定義新 Schema）
- 無跨模組依賴變更（不影響其他 Story 或 Skill 的執行路徑）

**典型範例（來自本專案歷史）：**
- 純文件更新（docs/ 下的 markdown 文件）
- 單一 SKILL.md 修改（新增章節或補充說明）
- 小型規則擴充（如新增關鍵字清單條目）

#### M（Medium）— 2 Points

**觸發條件（滿足以下任一條件即升為 M）：**

- AC 數量 6–8 條，或 AC 數量 ≤ 5 但含至少一個 `[動態]` AC
- 修改檔案數量預估 4–6 個
- 涉及跨 Skill 的協作修改（例如同時修改 sprint-execution/SKILL.md 與 story-lifecycle-prompt.md）
- 新建單一 Skill 文件（新建 SKILL.md 但無新介面定義）
- 需要新增 bash 腳本、測試腳本或設定檔

**典型範例：**
- 修改 Sprint Execution 流程（如新增外部抽樣審查步驟）
- 新建單一角色的 SKILL.md（知識文件，無執行邏輯）
- 小型功能實作（涉及 src/ 目錄但邏輯單純）

#### L（Large）— 3 Points

**觸發條件（滿足以下任一條件即升為 L）：**

- AC 數量 > 8 條
- 修改檔案數量預估 > 6 個
- 涉及新架構決策實作（ADR 定義的架構變更正式落地）
- 需要同時修改多個 Skill 的核心流程（Sprint Planning + Sprint Execution + 相關 prompt）
- 涉及新建可執行腳本（cron、部署、測試腳本）且邏輯複雜
- 預計需要 ADR-007 §AC4 策略 2（L-size 強制預分批）

**觸發 L-size 特殊流程：**
- 強制預分批執行（ADR-007 §AC4 策略 2）
- Sprint Execution 前 Architect 必須確認設計方向
- 分至少 2 個驗收批次執行

**典型範例：**
- ADR-007 Phase 2 外部抽樣審查機制實作（US-41）
- Sprint Planning / Sprint Execution SKILL.md 大規模重構
- 新建包含執行邏輯的完整 Skill（含 prompt + SKILL.md + 測試）

### 邊界情況判斷規則

| 情境 | 判斷建議 |
|------|---------|
| S 與 M 邊界模糊（AC 數量恰好 5 條但含 [動態] AC） | 升為 M（[動態] AC 表示需執行測試，實際工時高於靜態文件修改） |
| M 與 L 邊界模糊（修改 6 個檔案但邏輯簡單） | 維持 M（以邏輯複雜度為主要判斷，非純粹檔案數量） |
| doc-only Story（所有 AC 均為 [靜態] 且路徑在 docs/） | 預設 S，除非 AC 數量 > 5 則考慮 M |
| 跨 Sprint 依賴導致範圍不確定 | 先保守估為 M，待依賴 Story 完成後重新確認 |

---

## §2 ADR 需求判斷

### 判斷框架

ADR（Architecture Decision Record）的目的是記錄**有架構影響的技術決策**，使未來的 Architect 能理解決策背景、選項與取捨。以下標準判斷何時需要 ADR。

#### 需要新建 ADR 的條件

**滿足任一以下條件即需要新建 ADR：**

1. **引入新技術選型**：引入目前專案未使用的框架、資料庫、第三方服務或工具（觸發 Hard Gate：無 ADR 的技術選型 Story 不得進入 Sprint）

2. **架構模式變更**：改變 Agent 之間的協作模式（例如從主 session 執行 Review 改為 subagent 自審，如 ADR-007）

3. **系統邊界重定義**：改變 Skill 之間的介面契約（輸入/輸出 Schema 改變）、新增或移除 Skill 之間的依賴關係

4. **安全策略決策**：定義新的安全邊界或 Prompt Injection 防護機制（如 ADR-006）

5. **流程強制化決策**：將原本「建議執行」的步驟升格為 Hard Gate（如 ADR-003 Framework Document Change 流程）

6. **角色權重調整機制**：新增基於指標的自動調整規則（如 ADR-004 Role Weight Adjustment）

**判斷觸發詞：** 若 Story 描述中出現「架構」、「選型」、「介面契約」、「協作模式」、「強制執行」、「Hard Gate 新增」等詞，應評估是否需要新建 ADR。

#### 需要修改現有 ADR 的條件

**滿足以下條件時修改現有 ADR（而非新建）：**

1. **擴充現有決策範圍**：在既有 ADR 定義的架構框架內新增子機制（例如 ADR-007 Phase 2 外部抽樣審查機制是 ADR-007 §AC3 的實作，屬於既有決策範圍的延伸，不需新 ADR）

2. **修正決策細節**：原 ADR 的判斷條件需要微調，但核心決策方向不變

3. **新增觸發條件**：在既有機制中新增觸發條件（如在 ADR-004 的關鍵字清單中新增關鍵字）

**修改 ADR 時必須遵循 ADR-003 Checklist**（Framework Document Change 流程）。

#### 不需要 ADR 的條件

**滿足以下任一條件即不需要 ADR：**

1. **純知識文件擴充**：新建或修改 SKILL.md 作為角色指引文件，無架構決策變更（如本 Story US-42）

2. **實作既有 ADR 的決策**：Story 的工作內容已在現有 Accepted ADR 的範圍內定義（如 US-41 實作 ADR-007 §AC3，無需新 ADR）

3. **Bug 修復或細節補充**：修正現有實作的錯誤，不改變設計方向

4. **UI/UX 或輸出格式調整**：調整 Markdown 格式、輸出樣式，不影響系統行為

**判斷觸發詞：** 若 Story 描述為「實作 ADR-XXX」、「補充說明」、「修正文件」、「新增知識文件」，通常不需要新 ADR。

### ADR 觸發清單（Sprint Planning 輸出項目）

Architect 在 Sprint Planning Round 2 必須輸出 ADR 觸發清單：

| Story | ADR 編號 | 說明 |
|-------|----------|------|
| US-XX | 新建 ADR-YYY | {觸發原因} |
| US-XX | 修改 ADR-YYY | {修改原因} |
| US-XX | 無需 ADR | {依據條件} |

---

## §3 平行分群策略

### 目的

平行分群（Phase Grouping）決定哪些 Story 可以同時由不同 Story-Lifecycle subagent 並行執行，哪些 Story 必須序列執行，以防止同檔案競態條件（Race Condition）。

### Story 依賴關係判斷

#### 步驟 1：建立修改檔案清單

Architect 在 Sprint Planning 時，根據每個 Story 的 AC 描述，列出各 Story 預計修改的檔案路徑：

```
US-XX → 預計修改：
  - skills/sprint-execution/SKILL.md
  - docs/sprints/sprint_N.md（固定：每個 Story 都會更新）

US-YY → 預計修改：
  - skills/sprint-execution/story-lifecycle-prompt.md
  - docs/sprints/sprint_N.md（固定）
```

> **注意**：`docs/sprints/sprint_N.md` 與 `docs/PROJECT_BOARD.md` 為所有 Story 共享文件，但更新時僅修改對應 Story 的狀態欄，衝突風險由 `read-then-compare` 機制管理，不需因此強制序列化。

#### 步驟 2：識別共享核心邏輯檔案

以下類型的檔案若被多個 Story 修改，**必須序列執行**：

| 檔案類型 | 說明 |
|---------|------|
| `skills/*/SKILL.md` | Skill 核心邏輯文件，多個 Story 同時修改會導致 merge conflict |
| `skills/*/story-lifecycle-prompt.md` | Subagent prompt 文件，結構性內容修改不可並行 |
| `docs/adr/ADR-XXX.md` | ADR 文件，若兩個 Story 都需修改同一 ADR |
| `src/**/*.{js,ts,py,sh}` | 核心執行程式碼，並行修改極高 merge conflict 風險 |

#### 步驟 3：分群決策規則

**Phase 1（可平行執行）：**
- 所有修改檔案均互不重疊
- PO 獨立性評估欄位為「獨立」
- 特殊情況：即使同時修改 `docs/sprints/sprint_N.md`，若各 Story 僅更新自己的狀態欄，可視為獨立（由 read-then-compare 機制保護）

**Phase 2（需序列執行）：**
- 任一核心邏輯檔案被多個 Story 修改
- Story A 的輸出是 Story B 的輸入（邏輯依賴）
- Story B 的 AC 需引用 Story A 完成後的文件狀態（如 US-42 AC3 依賴 US-41 完成的 SKILL.md）

**序列執行順序規則：**
1. 依賴關係明確時：前置 Story 先執行（如 US-41 → US-42）
2. 依賴關係不明確時：Size 大的先執行（L → M → S），確保核心架構先到位
3. 同 Size 時：AC 數量多的先執行

### 同檔案競態偵測條件

**必須觸發序列化的競態條件（滿足任一即強制序列化）：**

1. **直接路徑衝突**：兩個 Story 的 AC 中出現相同的目標檔案路徑（完全一致的路徑字串）

2. **邏輯內容依賴**：Story B 的 AC 描述「在 Story A 交付的文件中新增...」，即使路徑相同也代表有序列依賴

3. **修改範圍重疊**：兩個 Story 都需修改同一 SKILL.md 的相同章節（例如都要修改 §3 執行流程）

4. **ADR 實作依賴**：Story B 需要引用 Story A 尚未完成的 ADR 決策或機制

**競態偵測輸出格式（Sprint Planning 正式輸出）：**

```markdown
### 檔案衝突分析

| 衝突檔案 | 涉及 Story | 衝突類型 | 建議執行順序 |
|---------|-----------|---------|------------|
| skills/sprint-execution/SKILL.md | US-41, US-42 | AC3 引用依賴 | US-41 → US-42 |
```

### 平行分群建議輸出格式

Sprint Planning 中 Architect 的正式輸出（供主 session 調度使用）：

```markdown
## 平行分群建議

### Phase 1（可平行執行）
| Story ID | 標題 | T-shirt | 說明 |
|----------|------|---------|------|
| US-XX    | ...  | S       | 修改獨立檔案，無衝突 |

### Phase 2（需序列執行，US-XX 完成後）
| Story ID | 標題 | T-shirt | 衝突原因 |
|----------|------|---------|---------|
| US-YY    | ...  | M       | AC3 依賴 US-XX 的 SKILL.md 狀態 |

### 執行順序
US-XX → US-YY（嚴格序列，不可平行）
```

---

## §4 環境管理成本評估原則

### 觸發條件

當架構方案涉及以下情境時，Architect 必須同步評估環境管理成本：

- 多台機器 / 多環境部署（如多 GCE 平行開發）
- 新增獨立的執行環境（如 CI/CD runner、staging 環境）
- 工作流程需要開發者在多個環境之間移動

### 評估要求

Architect 在方案評估階段，除功能性與 ToS 合規性外，必須同時評估以下三類環境管理成本：

| 成本類型 | 評估問題 |
|---------|---------|
| 設置成本 | 新環境從零到可用需要多少步驟？是否可自動化？ |
| 維護成本 | 多環境的工具版本同步、磁碟清理、安全更新如何管理？ |
| 同步成本 | 開發者在環境之間移動時，需要手動同步哪些資產？ |

### 判斷框架

| 條件 | 決策 |
|------|------|
| 環境管理成本 ≤ 方案本身收益 | 採用多環境方案，但 ADR 中需記錄環境管理策略 |
| 環境管理成本 > 方案本身收益 | 降級為單機方案，或要求 IaC / 環境自動化作為前置條件 |
| 環境管理成本無法評估 | 先以單環境 MVP 驗證，再決定是否擴展至多環境 |

### 判斷啟發（輔助「成本 vs 收益」的估算）

| 情境 | 成本判定 | 建議 |
|------|---------|------|
| 新環境設置步驟 > 10 步且無法腳本化 | 高設置成本 | 要求 IaC 或自動化腳本作為前置條件 |
| 環境維護需每兩週以上人工介入一次 | 高維護成本 | 降級為單機方案或要求 IaC |
| 環境重建耗時 > 30 分鐘 | 高同步成本 | 要求快速重建機制（snapshot / image / dotfiles） |
| 設置步驟 ≤ 5 步且可腳本化 | 低設置成本 | 多環境方案可行 |

---

## §5 方法論適用性評估（Methodology Fitness Check）

### 目的

Sprint Planning Architect Round 2 時，Architect 對每個 Story 自動執行方法論適用性評估，判斷是否建議採用 BDD（行為驅動開發）或 DDD（領域驅動設計）方法論。評估結果為**建議性質（Advisory）**，不阻塞 Sprint 流程。

### BDD 適用性觸發條件

Architect 檢查 Story 是否符合以下任一條件，若符合則建議採用 BDD 方法論：

| # | 觸發條件 | 說明 | 建議動作 |
|---|---------|------|---------|
| B1 | Story 含 `[動態]` AC 且有多條執行路徑 | AC 通過標準描述「當 X 時 Y，否則 Z」的分支邏輯 | 建議將該 AC 改為 `[行為]` 類型，以 Given-When-Then 明確描述各路徑 |
| B2 | Story 涉及使用者可觀察的行為變更 | 新增或修改 CLI 輸出、告警訊息、錯誤處理等使用者面向行為 | 建議補充行為範例（Specification by Example） |
| B3 | Story 涉及狀態轉換邏輯 | 狀態機、label 流轉、Story 生命週期等有 N 個狀態的轉換 | 建議用 Given-When-Then 逐一描述每個轉換路徑 |
| B4 | AC 通過標準超過 80 字且含條件邏輯 | 複雜的通過標準用散文寫容易漏判 | 建議拆為多個 Given-When-Then 場景 |

**不觸發 BDD 建議**：doc-only 且所有 AC 為 `[靜態]` 的 Story、簡單存在性檢查、格式修改。

### DDD 適用性觸發條件

| # | 觸發條件 | 說明 | 建議動作 |
|---|---------|------|---------|
| D1 | Story 引入新的核心領域概念 | 新增 Entity、Value Object、Aggregate 等業務物件 | 建議先建立領域模型文件（`docs/sdd/domain-model-*.md`） |
| D2 | Story 跨越多個模組且共享業務邏輯 | 多個 Skill/模組需要理解同一業務規則 | 建議定義 Bounded Context 邊界與統一語言（Ubiquitous Language） |
| D3 | Story 涉及複雜業務規則 | 包含 3 個以上互相影響的業務條件判斷 | 建議建立領域規則文件，用表格或決策樹記錄規則 |
| D4 | Story 修改的程式碼涉及 3+ 個 Entity 的互動 | 多物件交互容易產生隱含耦合 | 建議繪製領域互動圖或建立 SDD |

**不觸發 DDD 建議**：純 UI 修改、配置變更、doc-only Story、單一模組內部重構。

### 評估輸出格式

Architect Round 2 回傳新增以下區塊：

```markdown
## 方法論適用性評估

| Story ID | BDD 建議 | DDD 建議 | 說明 |
|----------|---------|---------|------|
| US-XX | 建議（B1, B2） | 不適用 | AC2 含多執行路徑 + CLI 輸出變更，建議補充行為範例 |
| US-YY | 不適用 | 不適用 | doc-only，所有 AC 為 [靜態] |
| US-ZZ | 不適用 | 建議（D1） | 引入新的 Domain Entity，建議先建領域模型 |
```

### 當 BDD 被建議時的後續流程

1. Architect 輸出建議後，**QA Round 3** 接手確認
2. QA 評估被標記的 AC 是否確實需要行為範例
3. 若 QA 同意：要求 PO 在 AC 表格下方補充「行為範例」區塊
4. 行為範例格式：

```markdown
**行為範例（Specification by Example）**

> AC2 範例：
> - **Given** 排程模式 `SHIKIGAMI_SCHEDULED=true`
>   **When** PO 選入 M-size Story
>   **Then** 輸出 `[SCHEDULED-MODE-GATE]` 告警並中止 Planning
>
> - **Given** 手動模式（非排程）
>   **When** PO 選入 M-size Story
>   **Then** 正常選入，無告警
```

5. Story-Lifecycle subagent 在 Spec Compliance Self-Review 時，逐一驗證每個行為範例場景

### 當 DDD 被建議時的後續流程

1. Architect 輸出建議後，標記為 Sprint 實作前置條件
2. Developer 在 TDD Red 階段前，先建立或更新領域模型文件（`docs/sdd/` 下）
3. 領域模型不需要完整的 DDD 戰術模式，只需：
   - 核心概念定義（Entity / Value Object 列表）
   - 概念間關係（簡單表格或文字描述）
   - 統一語言詞彙表（術語 → 定義，避免同一概念多種稱呼）

---

## §6 對抗辯論（Adversarial Debate）

### 目的

評估 ADR（架構決策紀錄）時，Architect 應主動模擬兩個對立觀點進行辯論，以產出更穩健的技術決策。

### 兩個觀點

| 觀點 | 角色 | 聚焦面向 |
|------|------|---------|
| 樂觀進取者 | 主張採用提案方案 | 擴展性、開發速度、創新潛力 |
| 嚴謹質疑者 | 挑戰提案方案 | 複雜度、維護負擔、失敗模式 |

### 輸出深度（依 project_level 控制）

| project_level | 輸出方式 |
|---------------|---------|
| **low** | 內部完成辯論，僅輸出最終結論 |
| **medium** | 輸出辯論摘要與建議（預設） |
| **high** | 完整呈現雙方論點，由使用者決策 |

### 觸發條件

當 §2 判斷「需要新建 ADR」時自動觸發。修改現有 ADR 或不需要 ADR 的情境不觸發。

### 輸出格式（medium 模式範例）

```markdown
### 對抗辯論摘要

**提案**：[方案描述]

| 面向 | 樂觀進取者 | 嚴謹質疑者 |
|------|-----------|-----------|
| 擴展性 | [論點] | [反論] |
| 維護成本 | [論點] | [反論] |
| 失敗風險 | [論點] | [反論] |

**結論**：[Architect 綜合判斷與建議]
```

---

## §7 API 契約產出（US-195）

<!-- US-195 API 契約 Hard Gate — Sprint 74 -->

### 觸發條件

Architect 在技術評估階段，**若 Story 涉及以下任一情境，必須產出 API 契約**：

- Story 新增或修改 API 端點（REST / GraphQL / WebSocket）
- Story 涉及前端與後端之間的資料交換（request / response schema 變更）
- Story 跨越 Client / Server 邊界且傳輸結構化資料

**不涉及 API 的 Story**（純前端 UI、純後端業務邏輯、doc-only、工具腳本等）：在 Architect 技術評估表格的「API 契約」欄位填入「不適用」，並於 Sprint Planning 輸出中明確標注，Story-Lifecycle subagent 將跳過 API 契約 Hard Gate，不觸發阻擋。

### API 契約標準模板

Architect 產出的 API 契約必須使用以下 Markdown 表格格式：

```markdown
### API 契約：{端點路徑}

| 欄位 | 內容 |
|------|------|
| Endpoint | `{HTTP_METHOD} /api/v1/{path}` |
| Method | `GET` / `POST` / `PUT` / `PATCH` / `DELETE` |
| Auth | Bearer Token / API Key / 無 |
| Content-Type | `application/json` |

**Request Schema**

| 欄位名稱 | 型別 | 必填 | 說明 |
|---------|------|------|------|
| `{field_name}` | `string` / `number` / `boolean` / `object` / `array` | 是/否 | {欄位說明} |

**Response Schema（成功 2xx）**

| 欄位名稱 | 型別 | 說明 |
|---------|------|------|
| `{field_name}` | `string` / `number` / `boolean` / `object` / `array` | {欄位說明} |

**錯誤回應**

| HTTP 狀態碼 | 錯誤代碼 | 說明 |
|------------|---------|------|
| `400` | `INVALID_REQUEST` | {說明} |
| `401` | `UNAUTHORIZED` | {說明} |
| `404` | `NOT_FOUND` | {說明} |
| `500` | `INTERNAL_ERROR` | {說明} |
```

> **最小必要欄位**：Endpoint、Method、Request Schema、Response Schema 為必填欄位。Auth、Content-Type、錯誤回應表格為建議填寫，若確無需求可省略。

### Architect 技術評估表格輸出格式

Sprint Planning Architect Round 2 輸出的技術評估結果，必須包含「API 契約」欄位：

| Story | T-shirt | ADR 需求 | API 契約 | 說明 |
|-------|---------|---------|---------|------|
| US-XX | M | 無需 ADR | **有**（見下方契約定義） | {說明} |
| US-YY | S | 無需 ADR | **無**（需補充，阻擋開發） | {說明} |
| US-ZZ | S | 無需 ADR | **不適用** | doc-only，無 API 互動 |

**欄位說明：**

| 值 | 意義 |
|----|------|
| 有 | Architect 已產出 API 契約，Developer 可直接進入開發 |
| 無 | Story 涉及 API 但 Architect 尚未產出契約，Story-Lifecycle Hard Gate 將阻擋開發 |
| 不適用 | Story 不涉及 API 互動，Hard Gate 自動跳過 |

---

## §8 跨領域依賴分析 Checklist（Refinement Chair 用）

<!-- US-202 Refinement 機制 — Sprint 76 -->

當 Architect 擔任 Refinement Chair 時（見 sprint-planning/SKILL.md §9），必須使用本 Checklist 對每個 M/L Story 進行跨領域依賴分析。以下各項均需明確回答，不可省略。

### 8.1 前置依賴分析

**問題**：這個 Story 開始前需要什麼前置條件？

| 判斷條件 | 處置 |
|---------|------|
| Story AC 描述中含「依賴 US-XXX 完成」、「需要 XXX 先就緒」等字眼 | 確認前置 Story 是否在同 Sprint 可完成，若不可則標記 NOT_READY |
| Story 需要外部系統可用性（第三方 API、SaaS 服務） | 確認外部系統狀態，若不確定則在 Sprint 前發出確認請求 |
| Story 需要 ADR 已通過才能實作 | 確認對應 ADR 狀態為 Accepted，否則退回 Backlog |
| Story 無前置依賴 | 記錄「無前置依賴」，繼續下一項 |

### 8.2 下游影響分析

**問題**：是否有其他 Story 依賴本 Story 的輸出？

| 判斷條件 | 處置 |
|---------|------|
| 本 Sprint 中有其他 Story 的 AC 引用本 Story 的輸出（API、Schema、文件） | 確認本 Story 在排程上優先，Contract Owner 須出席 Refinement；輸出界面需在 Refinement 中定義清楚 |
| 下一個 Sprint 的規劃 Story 依賴本 Story | 記錄跨 Sprint 依賴，確保本 Story 完成時交付物完整，降低下 Sprint 返工風險 |
| 無下游依賴 | 記錄「無下游依賴」，繼續下一項 |

### 8.3 跨 Story Type 拆分分析

**問題**：本 Story 是否跨越多個 Story Type 需要拆分？

| 判斷條件 | 處置 |
|---------|------|
| Story 同時包含 FEATURE + INFRA 工作，且 INFRA 工作量不可忽略（需要 SRE 獨立設計、建置） | 拆分為獨立 INFRA Story（Contract Owner：SRE）和 FEATURE Story；INFRA Story 成為 FEATURE Story 的前置依賴 |
| Story 同時包含 FEATURE + INFRA 工作，但 INFRA 工作量極小（設定調整、參數修改） | 保持為單一 FEATURE Story，在 Contract 中附加 Infra Prerequisites Checklist，由 SRE 簽核 |
| Story 同時包含 FEATURE + SECURITY 工作（如新功能 + 安全審查） | 由 Security Engineer 作為 SECURITY 審查 Co-Owner；若安全工作量大則拆分 SECURITY Story |
| Story 同時包含 INTEGRATION + INFRA（如 API 串接 + 環境設定） | 優先執行 INFRA Story，確保環境就緒後再執行 INTEGRATION Story |
| Story 僅屬於單一 Type | 依 §8.2 分類規則確認 Type，記錄「無跨 Type 拆分需求」，繼續下一項 |

### 8.4 Contract Owner 確認

**問題**：Contract Owner 是否已確認？是否能在本 Sprint 參與？

| 判斷條件 | 處置 |
|---------|------|
| 依 sprint-planning/SKILL.md §8.3 對照表，Contract Owner 角色明確且可在本 Sprint 參與 | 記錄 Contract Owner 確認狀態，繼續 |
| Contract Owner 為 Architect（FEATURE / INTEGRATION），但本 Story 的技術界面尚未釐清 | 在 Refinement 中釐清技術界面定義，完成 API 契約草稿後方可標記 READY |
| Contract Owner 為外部角色（SRE / Security Engineer / UI/UX Designer），無法在本 Sprint 參與 | 標記 NOT_READY，記錄阻塞原因：Contract Owner 無法參與 |
| Story Type 為 RESEARCH，無 Contract Owner | 確認 Spike Report 輸出格式已定義，記錄「RESEARCH 類型，無 Contract Owner」 |

### 8.5 單 Sprint 完成性評估

**問題**：本 Story 能在一個 Sprint 內完成嗎？

| 判斷條件 | 處置 |
|---------|------|
| L size Story 且 AC > 8 條，Sprint 容量可能不足 | 強制執行 ADR-007 §AC4 策略 2（L-size 預分批），或考慮拆分為 2 個 M Story |
| M size Story 且同 Sprint 有多個 M/L Story 競用 Architect 資源 | 評估 Sprint 容量，若超載則延後至下一 Sprint |
| Story 依賴的外部工作（SRE 確認、安全審查）需要超過一個 Sprint 的等待時間 | 標記 NOT_READY，等待外部工作完成後重新 Refinement |
| Story 在估點與 Sprint 容量範圍內可完成 | 記錄「可在單 Sprint 完成」，繼續 |

---

## 參照文件

- **ADR-003**：`docs/adr/ADR-003.md`（Framework Document Change 流程）
- **ADR-004**：`docs/adr/ADR-004.md`（角色權重調整機制）
- **ADR-007**：`docs/adr/ADR-007-story-lifecycle-subagent.md`（Story-Lifecycle Subagent 封裝，含 L-size 分批策略）
- **sprint-planning/SKILL.md**：`skills/sprint-planning/SKILL.md`（Sprint Planning 完整流程，含 Subagent 派遣順序）
- **ADR-012**：`docs/adr/ADR-012-max-account-rotation.md`（§環境管理考量，啟發 §4 原則）
- **sprint-execution/SKILL.md**：`skills/sprint-execution/SKILL.md`（Sprint Execution 流程，含 DESIGN_ISSUE 升級處置）
