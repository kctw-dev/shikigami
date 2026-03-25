---
name: architect
description: "Use when technical estimation, story sizing, ADR requirement assessment, or parallel dispatch grouping decisions are needed during Sprint Planning or Execution"
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

### 觸發條件摘要

**需要新建 ADR**（滿足任一）：引入新技術選型、架構模式變更、系統邊界重定義、安全策略決策、流程強制化決策、角色權重調整機制。

**判斷觸發詞：** 「架構」、「選型」、「介面契約」、「協作模式」、「強制執行」、「Hard Gate 新增」。

**需要修改現有 ADR**：擴充既有決策範圍、修正決策細節、新增觸發條件。

**不需要 ADR**：純知識文件擴充、實作既有 ADR 的決策、Bug 修復、UI/UX 格式調整。

**新建 ADR 前**：需執行 claim（`bash hooks/claim-issue.sh "adr-NNN"`），完成後 release。

> 詳細判斷框架、決策矩陣、ADR 建立前置步驟、觸發清單格式，請參照：`skills/architect/references/adr-requirements.md`

---

## §3 平行分群策略

### 目的

平行分群（Phase Grouping）決定哪些 Story 可以同時由不同 Story-Lifecycle subagent 並行執行，哪些 Story 必須序列執行，以防止同檔案競態條件（Race Condition）。

### Story 依賴關係判斷

#### 步驟 1：建立修改檔案清單

Architect 在 Sprint Planning 時，根據每個 Story 的 AC 描述，列出各 Story 預計修改的檔案路徑：

```
US-#N → 預計修改：
  - skills/sprint-execution/SKILL.md
  - docs/sprints/sprint_N.md（固定：每個 Story 都會更新）

US-#M → 預計修改：
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
| US-#N    | ...  | S       | 修改獨立檔案，無衝突 |

### Phase 2（需序列執行，US-#N 完成後）
| Story ID | 標題 | T-shirt | 衝突原因 |
|----------|------|---------|---------|
| US-#M    | ...  | M       | AC3 依賴 US-#N 的 SKILL.md 狀態 |

### 執行順序
US-#N → US-#M（嚴格序列，不可平行）
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

Sprint Planning Round 2 時自動執行，評估是否建議採用 BDD / DDD 方法論（Advisory，不阻塞流程）。

**BDD 觸發**（符合任一）：`[動態]` AC 含多執行路徑（B1）、使用者可觀察行為變更（B2）、狀態轉換邏輯（B3，需調用 `/diagram`）、AC 通過標準 > 80 字且含條件邏輯（B4）。

**DDD 觸發**（符合任一）：引入新核心領域概念（D1）、跨模組共享業務邏輯（D2）、複雜業務規則 3+ 條件（D3）、程式碼涉及 3+ Entity 互動（D4）。

BDD 觸發後由 **QA Round 3** 接手確認，需補充 Given-When-Then 行為範例。DDD 觸發後 Developer 在 TDD Red 前先建領域模型文件，Architect 調用 `/diagram` 更新 SDD-000。

---

## §6 對抗辯論（Adversarial Debate）

**觸發條件**：§2 判斷「需要新建 ADR」時自動觸發；修改現有 ADR 或不需要 ADR 的情境不觸發。

評估 ADR 時，Architect 模擬「樂觀進取者」（擴展性、開發速度）與「嚴謹質疑者」（複雜度、維護負擔）兩個對立觀點辯論，輸出深度依 `project_level` 控制（low：僅結論；medium：摘要；high：完整論點）。

> 完整辯論流程、輸出格式請參照：`skills/architect/references/adversarial-debate.md`

---

## §7 API 契約產出（US-195）

<!-- US-195 API 契約 Hard Gate — Sprint 74 -->

**觸發條件**：Story 新增或修改 API 端點（REST/GraphQL/WebSocket）、涉及前後端資料交換、跨 Client/Server 邊界傳輸結構化資料。

**不涉及 API 的 Story**：評估表格「API 契約」欄填「不適用」，Hard Gate 自動跳過。

技術評估表格必須包含 API 契約欄位（有 / 無 / 不適用），「無」時 Hard Gate 阻擋開發。

> 契約標準模板（Endpoint、Request Schema、Response Schema 等）、評估表格格式，請參照：`skills/architect/references/api-contract.md`

---

## §8 跨領域依賴分析 Checklist（Refinement Chair 用）

<!-- US-202 Refinement 機制 — Sprint 76 -->

當 Architect 擔任 Refinement Chair 時（見 sprint-planning/SKILL.md §9），必須對每個 M/L Story 執行五項分析：前置依賴（8.1）、下游影響（8.2）、跨 Type 拆分（8.3）、Contract Owner 確認（8.4）、單 Sprint 完成性（8.5）。各項均需明確回答，不可省略。

> 完整 Checklist 判斷條件與處置規則，請參照：`skills/architect/references/dependency-analysis.md`

---

## §9 Refinement 職責（Refinement Chair）

<!-- US-203 角色 Refinement 職責定義 — Sprint 77 -->

Architect 在 Refinement 中擔任 **Refinement Chair**，負責主持每個 M/L size Story 的結構化分析（詳細機制見 [sprint-planning/SKILL.md §9](../sprint-planning/SKILL.md)）。

職責包含：主持 Q1–Q5 分析、依賴識別、Story Type 判定、拆分建議、Contract Owner 確認、完成性評估。

輸出格式：Story Type 確認 + 依賴分析結果表（Q1–Q5）+ **READY / NOT_READY** 結論。詳細格式見 sprint-planning/SKILL.md §9.5。

| 面向 | Refinement Chair（Sprint Planning 前） | Architect subagent（Sprint Planning Round 2） |
|------|---------------------------------------|----------------------------------------------|
| 時機 | Sprint Planning **之前** | Sprint Planning **進行中** |
| 焦點 | 依賴識別、風險評估、拆分判斷 | 技術可行性評估、ADR 需求判斷、平行分群建議 |
| 輸出 | READY / NOT_READY 報告 | 技術評估表格、平行分群建議、API 契約 |

---

## §10 SDD 審查：領域模型與封裝設計

<!-- Issue #256 — Architect SDD 審查補領域模型與封裝設計 -->

**觸發條件**：Story 涉及業務邏輯實作（非 doc-only/純 UI/純配置）、同一業務概念出現在 2+ 個模組、或有狀態轉換邏輯。

**SDD 審查必查項（DM 維度）**：
- [ ] DM-1 業務邏輯封裝在 Service 層（Router 只做 I/O 調度）
- [ ] DM-2 同一業務規則單一實作來源（不重複）
- [ ] DM-3 狀態轉換有統一對照表/狀態機
- [ ] DM-4 共享資源有 Gateway Service 作為唯一寫入入口

DM-1/DM-2/DM-3 FAIL 判定：Router 含業務判斷 > 5 行、相同規則在 2+ 處各自實作、狀態轉換散落各 handler。DM-4 FAIL：2+ 模組直接寫入同一 DB collection 無 Gateway。

觸發 DM-1/2/3/4 時，SDD 需補「模組設計」章節（責任劃分、業務邏輯 SSOT、狀態轉換對照）。各 SDD 只放循序圖/流程圖，領域模型與類別圖統一引用 [`docs/sdd/SDD-000-architecture.md`](../../docs/sdd/SDD-000-architecture.md)。

審查輸出格式：架構符合性、ADR 觸發、Layer Compliance（共用常數/import 方向/SSOT）、DM-1/2/3/4、全局架構文件一致性 各項 `[PASS/FAIL]`。

<HARD-GATE>
**領域模型審查 Hard Gate**：DM-1、DM-2、DM-3、DM-4 任一 FAIL 時，Architect 審查整體判定為 FAIL。Story 不得進入開發，須先修正 SDD 的模組設計。
</HARD-GATE>

---

## §11 全局架構文件與圖表產出

維護 `docs/sdd/SDD-000-architecture.md` 作為所有 SDD 的 Single Source of Truth（含系統領域模型、類別圖、元件圖）。各 SDD 只存放循序圖/流程圖/狀態機圖（B3 觸發），全局圖統一在 SDD-000 維護。

**`/diagram` 調用觸發**：D1（新領域概念）→ 更新領域模型；D2（跨模組）→ 更新領域模型 + 元件圖；D4/DM-1/2/3（Entity 互動或 Service 結構）→ 更新類別圖；DM-4 → 更新類別圖 + Gateway 對照表；新增外部依賴 → 更新元件圖；B3/D3 → 更新對應 SDD 內部圖（非全局）。

**SDD 編號規則**：格式 `SDD-{NNN}-{名稱}.md`，SDD-000 固定為全局架構文件，SDD-001+ 依序遞增。建立時先掃描最大編號 +1，驗證不重複，跳號不回填，平行 Sprint 時由 Architect 在 Planning 預分配編號。

**一致性檢查**：各 SDD 引用的 Entity/Service 是否存在於 SDD-000；術語是否與 SDD-000 §1.3 統一語言表一致。不一致則 FAIL，要求先更新全局架構文件。

<HARD-GATE>
**全局架構文件 Hard Gate**：

1. `docs/sdd/SDD-000-architecture.md` 不存在時，唯一允許的工作是**建立此文件**。其他 Sprint Planning 與 Shoot 均不得啟動。
2. **工作內容必須能在 SDD 體系中定位**（全局概念 → SDD-000；功能細節 → SDD-001+；最小定位標準：概念名稱存在於某份 SDD 即 PASS）。找不到 → FAIL。
3. **豁免條件**：doc-only 變更、bug fix/重構（不引入新 Entity/Service/系統邊界）、Hotfix（24 小時內補齊）。
4. **責任方**：Architect subagent 在步驟 3 審查時執行此檢查。
</HARD-GATE>

---

## 參照文件

- **ADR-003**：`docs/adr/ADR-003.md`（Framework Document Change 流程）
- **ADR-004**：`docs/adr/ADR-004.md`（角色權重調整機制）
- **ADR-007**：`docs/adr/ADR-007-story-lifecycle-subagent.md`（Story-Lifecycle Subagent 封裝，含 L-size 分批策略）
- **sprint-planning/SKILL.md**：`skills/sprint-planning/SKILL.md`（Sprint Planning 完整流程，含 Subagent 派遣順序）
- **ADR-012**：`docs/adr/ADR-012-max-account-rotation.md`（§環境管理考量，啟發 §4 原則）
- **sprint-execution/SKILL.md**：`skills/sprint-execution/SKILL.md`（Sprint Execution 流程，含 DESIGN_ISSUE 升級處置）
