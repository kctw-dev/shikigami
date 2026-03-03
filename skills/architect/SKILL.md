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

## 參照文件

- **ADR-003**：`docs/adr/ADR-003.md`（Framework Document Change 流程）
- **ADR-004**：`docs/adr/ADR-004.md`（角色權重調整機制）
- **ADR-007**：`docs/adr/ADR-007-story-lifecycle-subagent.md`（Story-Lifecycle Subagent 封裝，含 L-size 分批策略）
- **sprint-planning/SKILL.md**：`skills/sprint-planning/SKILL.md`（Sprint Planning 完整流程，含 Subagent 派遣順序）
- **sprint-execution/SKILL.md**：`skills/sprint-execution/SKILL.md`（Sprint Execution 流程，含 DESIGN_ISSUE 升級處置）
