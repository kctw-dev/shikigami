# SBE 標準格式定義（Specification by Example）

**版本**：v1.0
**日期**：2026-03-12
**狀態**：Active
**關聯 Story**：US-226
**關聯 ADR**：ADR-018（Discovery Phase 架構方案）

---

## 1. 什麼是 SBE

Specification by Example（SBE）是一種以具體範例表達業務規則的需求定義方式。在 Shikigami 框架中，SBE 範例是業務規則的 **ground truth**，同時扮演三個角色：

1. **Agent 執行的依據**：Agent 在執行 Sprint 流程時，依照 SBE 範例中定義的條件與預期行為執行。
2. **測試腳本的來源**：透過 SBE → 測試案例轉換規則（`SBE_TO_TEST_RULES.md`），直接衍生為可執行的測試案例。
3. **下游文件的衍生基礎**：流程圖、決策表、API 契約等文件均以 SBE 範例為源頭衍生，改源頭則下游自動更新。

**單一來源原則**：業務規則 → 衍生 SBE 範例 → 衍生測試案例 → 衍生流程圖。

---

## 2. 標準格式：Given / When / Then

每個 SBE 範例必須包含以下三個結構性區塊：

### 2.1 格式定義

```
Scenario: <場景名稱（一句話描述業務情境）>

  Given <前置狀態（系統或世界的初始條件）>
    And <額外前置狀態（選用，可疊加多個）>

  When  <觸發事件（Actor 的行動或外部事件）>
    And <額外觸發事件（選用）>

  Then  <預期結果（系統應產生的可觀察輸出）>
    And <額外預期結果（選用）>
```

### 2.2 欄位說明

| 關鍵字 | 語意 | 填寫原則 |
|--------|------|---------|
| `Scenario` | 場景名稱 | 一句話，聚焦業務情境，不描述技術細節 |
| `Given` | 前置狀態 | 描述執行前系統的已知狀態（如：資料庫內容、環境變數、先決條件） |
| `And`（Given 下） | 額外前置狀態 | 並聯多個前置條件，每條一行，保持原子性 |
| `When` | 觸發事件 | 描述 Actor 執行的單一動作，或系統接收的外部事件 |
| `And`（When 下） | 額外觸發事件 | 當觸發包含多個步驟時使用，但應盡量保持單一觸發 |
| `Then` | 預期結果 | 描述系統的可觀察輸出；必須可量化或可驗證，不得模糊 |
| `And`（Then 下） | 額外預期結果 | 並聯多個預期輸出，每條獨立可驗證 |

### 2.3 命名規範

- **Scenario 命名**：`<業務動作>_<關鍵條件>_<預期結果摘要>`，使用底線分隔，全小寫英文或中文均可
- **檔案命名**：`<模組名稱>_<業務規則主題>.sbe.md`（例如：`sprint_planning_scheduled_mode.sbe.md`）
- **目錄結構**：依模組建立子目錄，每個子目錄對應 Shikigami 框架的一個 Skill 或業務領域

---

## 3. 完整範例：Sprint Planning 排程模式 HARD-GATE

以下範例取自 `skills/sprint-planning/SKILL.md §3.1`，示範如何將框架業務規則表達為 SBE 格式。

---

### 範例一：排程模式下選入 M-size Story 觸發 HARD-GATE

```gherkin
Scenario: 排程模式下選入非S-size Story時Sprint Planning中止

  Given 環境變數 SHIKIGAMI_SCHEDULED 設為 "true"
    And PO subagent 已從 Backlog 篩選出候選 Stories

  When  PO subagent 嘗試將 M-size Story（US-#NX）選入 Sprint Backlog

  Then  Sprint Planning 流程中止
    And 輸出告警訊息包含 "[SCHEDULED-MODE-GATE]"
    And 告警訊息列出違規的 Story ID 及其 Size
    And 告警訊息建議改為手動執行 Sprint Planning
```

---

### 範例二：排程模式下僅有 S-size Story 時正常執行

```gherkin
Scenario: 排程模式下所有候選Story均為S-size時正常執行

  Given 環境變數 SHIKIGAMI_SCHEDULED 設為 "true"
    And PO subagent 已從 Backlog 篩選出候選 Stories
    And 所有候選 Stories 的 T-shirt size 均為 S（1pt）

  When  PO subagent 執行 Sprint Backlog 選取

  Then  Sprint Planning 繼續執行，不觸發 HARD-GATE
    And 所有 S-size Stories 正常進入 Sprint Backlog
```

---

### 範例三：手動模式下 M-size Story 不受排程限制

```gherkin
Scenario: 手動模式下M-size Story可正常選入Sprint Backlog

  Given 環境變數 SHIKIGAMI_SCHEDULED 未設定（或設為非 "true" 的值）
    And PO subagent 已從 Backlog 篩選出候選 Stories
    And 候選 Stories 包含 M-size Story（US-YYY）

  When  PO subagent 執行 Sprint Backlog 選取

  Then  M-size Story（US-YYY）正常進入 Sprint Backlog
    And Sprint Planning 繼續執行，不觸發排程模式 HARD-GATE
```

---

## 4. 格式規則（Rules）

### 4.1 必要規則

| # | 規則 | 說明 |
|---|------|------|
| R1 | 每個 Scenario 必須獨立可執行 | Given 應完整描述初始狀態，不依賴其他 Scenario 的側效果 |
| R2 | Then 必須可觀察且可驗證 | 不允許「系統正常運作」等模糊表述；必須指出具體輸出、狀態變更或回應內容 |
| R3 | 一個 Scenario 對應一個業務規則 | 避免在單一 Scenario 中混入多個不相關的業務規則 |
| R4 | 具體值優先於抽象描述 | 使用實際的值、ID、狀態（如 `"true"`、`"S"`、`"[SCHEDULED-MODE-GATE]"`）而非抽象描述 |
| R5 | 每個 SBE 文件必須標注來源業務規則 | 在文件開頭標注對應的 SKILL.md 章節或 ADR 條目 |

### 4.2 禁止事項

| 禁止行為 | 原因 |
|---------|------|
| `Then` 使用「可能」、「大概」、「應該」等不確定語氣 | 無法驗證，測試轉換時產生歧義 |
| `Given` 省略關鍵前置條件 | 導致 Scenario 在不同環境下結果不一致 |
| 在 `When` 中描述多個獨立的使用者動作 | 難以定位失敗原因；每個 When 應聚焦單一觸發 |
| 在 SBE 文件中嵌入技術實作細節 | SBE 描述業務行為，技術細節屬於測試腳本層 |

---

## 5. 目錄結構

```
docs/definition/sbe-examples/
├── SBE_FORMAT.md              <- 本文件（格式定義）
├── SBE_TO_TEST_RULES.md       <- SBE → 測試案例轉換規則
└── sprint-lifecycle/          <- Sprint 生命週期模組範例
    ├── sprint_planning_scheduled_mode.sbe.md
    └── sprint_planning_refinement_gate.sbe.md
```

---

## 6. 版本控制

SBE 文件隨業務規則同步演進：

- **新增業務規則**：在對應模組子目錄新增 `.sbe.md` 文件
- **修改業務規則**：同步更新對應的 SBE 文件，並更新版本號
- **廢棄業務規則**：移至 `archive/` 子目錄，保留歷史記錄

每次修改 SBE 文件時，需同步更新相關的測試案例（`SBE_TO_TEST_RULES.md` 定義的衍生路徑）。

---

## 參考文件

- `skills/sprint-planning/SKILL.md`：Sprint Planning 業務規則來源
- `skills/sprint-execution/SKILL.md`：Sprint Execution 業務規則來源
- `docs/definition/sbe-examples/SBE_TO_TEST_RULES.md`：SBE → 測試案例轉換規則
- `docs/adr/ADR-018-discovery-phase-architecture.md`：Discovery Phase 架構背景
