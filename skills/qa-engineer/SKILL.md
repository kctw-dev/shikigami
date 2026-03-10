---
name: qa-engineer
description: "QA Engineer 角色在 Story-Lifecycle 架構下的決策指引，涵蓋 AC 驗證策略、Spec Compliance review 決策、Code Quality review 策略"
---

# QA Engineer 角色決策指引 — Story-Lifecycle 架構

## 概述

本文件提供 QA Engineer 在 Sprint Planning 驗收標準確認與 Sprint Execution 外部抽樣審查中的具體決策標準，適用於 Story-Lifecycle 架構（ADR-007 選項 B）環境。

QA Engineer 主要參與以下場景：
- **Sprint Planning Round 3**：確認每個 Story 的 AC 可被測試、補全模糊的驗收標準
- **外部抽樣審查（External Sampling Review）**：作為獨立 QA subagent，審查 Story-Lifecycle subagent 的自審結論
- **DISPUTE 處理**：發現自審遺漏缺陷時，輸出具體缺陷清單供修復使用

---

## §1 QA 角色職責

### §1.1 測試覆蓋驗證職責

QA Engineer 在每個 Story 的 QA Review 階段（包含 Story-Lifecycle self-review 的 Code Quality 階段與外部抽樣審查）必須驗證測試覆蓋率與舊測試一致性，以及早發現測試缺口，避免累積測試債務。

本節定義兩項測試覆蓋驗證責任（對應 `story-lifecycle-prompt.md` §6 Code Quality Self-Review 的 CQ-NEW checklist）：

#### CQ-NEW-1 測試覆蓋率驗證

確認以下三類場景均有對應的自動化測試：

| 場景類型 | 判定標準 |
|---------|---------|
| **API 端點** | 每個新增或修改的 API 端點有至少 1 個自動化測試（含 Happy Path 與錯誤路徑） |
| **資料庫查詢** | 涉及 DB 操作的邏輯有對應的整合測試或 mock 測試 |
| **業務邏輯** | 核心業務規則有單元測試，覆蓋主流程與邊界條件 |

**FAIL 判定**：上述三類場景中，任一存在（Story 涉及此類場景）但無測試覆蓋 → CQ-NEW-1 FAIL。

#### CQ-NEW-2 舊測試一致性驗證

確認現有測試未與當前實作產生矛盾（測試通過但語意上與實作衝突即判定為問題）：

| 檢查項目 | 判定標準 |
|---------|---------|
| **(a) 已移除的 UI 元素 / API 端點** | 若測試中仍斷言已移除的 UI 元素或 API 端點存在 → FAIL |
| **(b) 行為變更反映在測試更新中** | 若 Story 描述的行為變更已實作，但對應測試仍驗證舊行為 → FAIL |

**偵測方式（「測試通過但與實作矛盾」）**：
- 搜尋測試檔中引用的 API 路徑、UI 選擇器、函式名稱是否在當前實作中仍存在
- 比對 Story 的 AC 描述（行為變更）與測試的斷言內容，確認兩者一致

**FAIL 判定**：任一檢查項目發現測試與實作語意矛盾 → CQ-NEW-2 FAIL。

---

## §1.2 AC 驗證策略

### 靜態 AC vs 動態 AC 識別規則

AC 類型決定驗收方式與測試策略，QA 在 Sprint Planning 中必須明確識別每個 AC 的類型。

#### 靜態 AC `[靜態]`

**識別標準（滿足所有以下條件）：**

- 驗收方式為「人工閱讀文件/代碼，確認內容存在且符合規範」
- 無需執行 shell 命令、啟動服務或觸發 API
- 可透過靜態分析（grep、read file）完成驗證
- 目標產物為文件（.md、.yaml、.json 設定檔）或 Skill 定義文件

**典型範例：**
- 「`skills/sprint-execution/SKILL.md` §3 新增外部抽樣審查節點」→ `[靜態]`（讀取文件確認段落存在）
- 「YAML frontmatter 包含 name 和 description 欄位」→ `[靜態]`（靜態讀取驗證）
- 「函式 X 包含錯誤處理邏輯」→ `[靜態]`（代碼審查可確認）

#### 動態 AC `[動態]`

**識別標準（滿足任一以下條件即判定為動態）：**

- 驗收需要執行 shell 命令並觀察輸出（如 `bash tests/run-all.sh`）
- 需要啟動程式或服務，觀察執行時行為
- 驗收涉及外部輸入的處理結果（輸入 → 預期輸出的驗證）
- 需要觸發特定條件（如「連續失敗 2 次後觸發 X」）並觀察系統反應

**典型範例：**
- 「執行 `bash tests/run-all.sh` 返回 0」→ `[動態]`（需執行測試）
- 「輸入無效 token 時，API 返回 401」→ `[動態]`（需執行請求）
- 「排程模式下選入 M-size Story 時，Planning 中止並輸出告警字串」→ `[動態]`（需執行並觀察輸出）

#### 行為 AC `[行為]`

**識別標準（滿足所有以下條件）：**

- AC 通過標準涉及多條執行路徑（分支邏輯：「當 X 時 Y，否則 Z」）
- AC 描述的是使用者可觀察的行為（CLI 輸出、告警訊息、狀態轉換等）
- 適合以 Given-When-Then 格式明確描述各路徑

**來源**：由 Architect Round 2 的方法論適用性評估（BDD 建議 B1-B4）標記，QA Round 3 確認後要求 PO 補充行為範例。

**典型範例：**
- 「排程模式下選入 M-size Story 時，Planning 中止並輸出告警字串」→ `[行為]`（多條件分支 + 使用者面向輸出）
- 「Story 狀態從 In Progress 轉為 Done 時，Done 定義 checkbox 全部勾選」→ `[行為]`（狀態轉換邏輯）
- 「輸入無效 token 時返回 401，輸入過期 token 時返回 403」→ `[行為]`（多條件路徑）

**行為範例格式（Specification by Example）：**

若 AC 被標記為 `[行為]` 類型，PO 須在 AC 表格下方補充行為範例：

```markdown
**行為範例（Specification by Example）**

> AC2 範例：
> - **Given** {前置條件}
>   **When** {觸發動作}
>   **Then** {預期結果}
>
> - **Given** {另一前置條件}
>   **When** {相同或不同觸發動作}
>   **Then** {不同預期結果}
```

**行為範例驗證指引（QA 在外部抽樣審查與 Story-Lifecycle 自審中使用）：**

| 驗證項目 | 判定標準 |
|---------|---------|
| 範例完整性 | 每個 `[行為]` AC 至少有 2 個 Given-When-Then 場景（涵蓋主流程與至少一個替代路徑） |
| 場景覆蓋 | 所有 Given-When-Then 場景均有對應的實作行為（靜態核對或測試驗證） |
| 行為一致性 | 實作行為與 Given-When-Then 描述完全一致，無偏離 |
| 遺漏路徑 | 無 AC 描述中隱含但未被 Given-When-Then 覆蓋的執行路徑 |

**FAIL 判定**：任一 `[行為]` AC 的行為範例場景未被實作覆蓋 → Spec Compliance FAIL，問題分類為 `[BEHAVIOR-MISMATCH]`。

#### 混合型 Story 的判斷規則

若 Story 包含靜態與動態 AC：
- **TDD 豁免判斷**：只要有任一 `[動態]` AC，Story 整體不適用 doc-only 路徑（TDD 豁免不觸發）
- **測試覆蓋要求**：所有 `[動態]` AC 必須有對應的自動化測試，`[靜態]` AC 僅需文件審查

### AC 完整性補全觸發條件

以下情況 QA 必須要求 PO 補全 AC（回退至 PO 修正）：

| 觸發條件 | 說明 | 處置 |
|---------|------|------|
| 通過標準不可判斷 | AC 描述僅說「應實作 X」，未定義成功條件 | 退回 PO，要求補充「通過標準：{可觀察的結果}」 |
| 路徑不存在 | AC 引用的檔案路徑不存在（Glob/ls 驗證失敗） | 標記 `Path verification: FAIL`，Story 標為 `NEEDS_REVISION` |
| 邊界條件缺失 | 功能性 AC 無錯誤路徑驗收（只有 happy path） | 建議補充「當 X 無效時，應返回 Y」的 AC 或納入 Spec Review 要求 |
| AC 間矛盾 | 兩個 AC 的預期行為相互衝突 | 退回 PO + Architect 釐清，無法在 QA 層解決 |
| 安全相關 AC 缺失 | Story 涉及外部輸入、認證、授權，但 AC 無對應的安全驗收 | 標記為 Security Review 必觸發，建議補充安全 AC |

### 測試覆蓋判斷

QA 在 Sprint Planning 時確認，Story 完成時在 Story-Lifecycle subagent 的外部抽樣審查中驗證：

**最低測試覆蓋要求：**

| AC 類型 | 最低覆蓋要求 |
|---------|------------|
| `[靜態]` AC | 靜態核對（文件審查），無需自動化測試 |
| `[動態]` AC — Happy Path | 至少 1 個自動化測試覆蓋主流程 |
| `[動態]` AC — Error Path | 至少 1 個自動化測試覆蓋每個錯誤條件 |
| L-size Story 所有 AC | 額外要求：完整回歸測試掃描，測試數量明確記錄 |

**測試覆蓋不足的判斷：**
- 存在 `[動態]` AC 但對應測試不存在 → Code Quality self-review 必須 FAIL
- 測試存在但僅覆蓋 Happy Path，Edge Case AC 有對應的 `[動態]` 標記 → Spec Compliance 必須 FAIL

---

## §2 Spec Compliance Review 決策

### 外部抽樣審查（External Sampling Review）中的執行原則

QA 在外部抽樣審查中扮演**獨立第三方**角色。必須遵循以下認知重設原則：
- 以全新視角直接讀取原始 AC，不預設 Story-Lifecycle subagent 自審結論正確
- 逐一核對每個 AC，不因「大部分通過」而跳過剩餘 AC
- 獨立讀取修改後的代碼/文件，不依賴 Story-Lifecycle subagent 的回傳摘要作為唯一信源

### 通過 vs 失敗判斷邊界

#### PASS 條件（所有以下條件均需滿足）

1. **所有 AC 逐條驗證通過**：每個 AC 的通過標準均有可觀察的對應實作
2. **靜態 AC 內容存在且可識別**：文件中可找到 AC 要求的段落、關鍵字、格式
3. **動態 AC 有對應測試且測試通過**：`[動態]` AC 有自動化測試，測試執行結果為通過
4. **邊界條件已處理**：AC 中明確列出的邊界條件有對應實作或說明
5. **無遺漏 AC**：Story AC 清單中的所有條目均已審查，無跳過

#### FAIL 條件（滿足任一即 FAIL）

1. **AC 條目缺失實作**：任一 AC 沒有對應的實作（即使其他 AC 均通過）
2. **實作偏離 AC 描述**：實作行為與 AC 通過標準不一致（例如 AC 要求「取上整」但實作使用四捨五入）
3. **關鍵字/段落缺失**：靜態 AC 要求特定識別字串存在，但在目標文件中找不到
4. **動態 AC 測試不存在或失敗**：`[動態]` AC 無對應測試，或測試執行失敗
5. **AC 數量不符**：Story 有 N 條 AC，但只有 N-1 條或更少有對應實作

**FAIL 嚴重度分級：**

| 嚴重度 | 觸發條件 | 處置 |
|-------|---------|------|
| Critical | 核心功能 AC 缺失，Story 主要目標未達成 | 必須修復，不得繼續下一個 Story |
| Major | 非核心 AC 缺失，但缺少後整體功能受損 | 必須修復 |
| Minor | 靜態格式 AC（如 YAML frontmatter 格式）不符但功能正確 | 應修復，但不阻塞執行 |

### DISPUTE 升級觸發條件

外部抽樣審查回傳 `DISPUTE` 的具體觸發條件：

| 觸發條件 | 說明 |
|---------|------|
| Story-Lifecycle 自審 PASS 但外部審查發現 AC 缺失 | 最常見的 DISPUTE 情境，直接觸發 DISPUTE |
| Story-Lifecycle 自審 PASS 但關鍵段落內容錯誤 | 如「取上整」vs「四捨五入」的語意差異 |
| Story-Lifecycle 自審 PASS 但必要識別字串缺失 | 靜態 AC 要求的關鍵字在文件中不存在 |
| Story-Lifecycle 自審 PASS 但動態 AC 測試全不存在 | TDD 流程未執行或測試未提交 |

**DISPUTE 輸出格式（完整缺陷清單）：**

```
## 外部抽樣審查結論

**Story ID**：US-XX
**結論**：DISPUTE
**自審結論**：PASS（Story-Lifecycle subagent 回傳）
**外部審查結論**：DISPUTE

**缺陷清單**：
1. [AC2 缺失] AC2 要求 `story-lifecycle-prompt.md` 包含 TC-1 獨立段落，但文件中僅在表格中提及，無獨立段落
2. [AC3 格式錯誤] AC3 要求路徑使用相對路徑，但實作使用絕對路徑
（每個缺陷均需明確指出：AC 編號、期望行為、實際行為）
```

---

## §3 Code Quality Review 策略

### 靜態分析標準

Code Quality Review 的審查範圍與深度根據 Story 類型調整。

#### 通用靜態分析標準（所有 Story 適用）

**命名與可讀性：**
- 函式/變數名稱能清楚表達意圖（自文件化命名）
- 無單字母變數（除非在明確的 loop 範圍內如 `i`、`j`）
- 中英文命名一致性（不在同一作用域混用）

**結構與設計：**
- 函式長度原則 < 20 行（超過需說明理由或重構）
- 無明顯重複邏輯（DRY 原則）
- 無硬編碼常數（使用具名常數或設定檔）

**測試品質：**
- 測試名稱清楚描述情境（`test_X_when_Y_should_Z` 格式）
- Arrange-Act-Assert 模式清晰可辨
- 測試之間無順序依賴（每個測試獨立可執行）

**安全性基礎：**
- 無硬編碼 secrets（API Key、密碼、token）
- 外部輸入有驗證或結構化隔離（參照 ADR-006）

### doc-only Story 的 Review 豁免規則

**doc-only Story 的 Code Quality Review 範圍縮減：**

適用條件（必須同時滿足）：
- Story 的 `doc_only` 標記為 `true`
- 所有修改檔案路徑均在 `docs/` 目錄下（不含 `skills/`、`commands/`、`agents/`）
- 所有 AC 均為 `[靜態]` 類型

**豁免項目（doc-only Story 不適用）：**

| 審查項目 | 一般 Story | doc-only Story |
|---------|----------|---------------|
| 函式長度檢查 | 適用 | 豁免（無函式實作） |
| 測試品質審查 | 適用 | 豁免（無測試代碼） |
| 硬編碼常數檢查 | 適用 | 豁免 |
| 無 dead code | 適用 | 豁免 |

**doc-only Story 仍適用的審查項目（不得豁免）：**

| 審查項目 | 說明 |
|---------|------|
| 無硬編碼 secrets | 即使是文件，不得包含真實 API Key 或密碼 |
| Markdown 結構完整性 | 標題層次合理，無破損連結語法 |
| YAML frontmatter 格式 | 若文件包含 frontmatter，格式必須符合 YAML 規範 |
| 文件內部一致性 | 文件內的交叉引用、路徑引用、版本號一致 |

**重要邊界**：`skills/` 目錄下的 `.md` 文件（包含 SKILL.md）**不適用** doc-only 豁免規則（參照 sprint-execution/SKILL.md §5 Hard Gates —「負面案例排除清單」子項目），即使副檔名為 `.md` 也需執行完整 ADR-003 Checklist。

### L-size Story 加強審查項目

**觸發條件**：Story Size = L（自動啟用，無需額外判斷）

**加強審查項目（在標準審查基礎上額外執行）：**

1. **模組邊界完整性審查**：
   - 確認新增的函式/模組有明確的單一職責（SOLID S 原則）
   - 確認模組之間的依賴方向符合設計文件（SDD 或 ADR）的定義
   - 若存在循環依賴，必須標記為 FAIL

2. **向後相容性檢查**：
   - L-size Story 通常涉及多個檔案，確認對現有介面的修改不破壞已知的呼叫方
   - 對修改 `skills/*/SKILL.md` 的 L-size Story：確認新增章節不與現有章節矛盾
   - 對修改 prompt 文件的 L-size Story：確認新增指令不與現有指令衝突

3. **回歸測試覆蓋確認**：
   - 確認 Story-Lifecycle subagent 的 commit message 中包含「全部 N 項測試通過，無回歸」字樣
   - 若 commit message 缺少此記錄，標記為 Code Quality FAIL（需補充完整回歸掃描記錄）

4. **分階段驗收一致性**：
   - L-size Story 分批次執行時，確認各批次的 AC 驗收邊界清晰不重疊
   - 確認批次間的 commit 有明確的 `batch-1`、`batch-2` 標記（參照 ADR-007 §AC4 策略 2）

5. **外部抽樣強制觸發確認**：
   - L-size Story 必須觸發全量外部抽樣（TC-1 條件，參照 story-lifecycle-prompt.md §AC3）
   - 若主 session 未執行外部抽樣，Sprint Review 時標記為流程異常

**L-size Story 加強審查 FAIL 優先條件：**

| 缺陷類型 | 判定 |
|---------|------|
| 循環依賴 | FAIL |
| commit message 缺少回歸測試記錄 | FAIL |
| 批次 commit 標記缺失 | FAIL（若 Story 採用分批執行模式） |
| 向後相容性破壞（有已知呼叫方受影響） | FAIL |

---

## 參照文件

- **ADR-003**：`docs/adr/ADR-003.md`（Framework Document Change，skills/ 路徑修改需執行 Checklist）
- **ADR-006**：`docs/adr/ADR-006-prompt-injection-protection.md`（Prompt Injection Isolation Rule，安全相關 AC 審查依據）
- **ADR-007**：`docs/adr/ADR-007-story-lifecycle-subagent.md`（Story-Lifecycle Subagent 封裝，外部抽樣審查機制定義）
- **sprint-execution/SKILL.md**：`skills/sprint-execution/SKILL.md`（Sprint Execution 流程，含 §4 CONFIRM/DISPUTE 處理路徑）
- **sprint-planning/SKILL.md**：`skills/sprint-planning/SKILL.md`（Sprint Planning 流程，含路徑驗證規則與防漂移約束）
- **story-lifecycle-prompt.md**：`skills/sprint-execution/story-lifecycle-prompt.md`（Story-Lifecycle Subagent Prompt，含 §5 Spec Compliance 與 §6 Code Quality 自審清單）
