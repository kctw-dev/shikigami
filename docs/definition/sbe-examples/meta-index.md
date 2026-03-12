# SBE 範例庫 Meta-Index

**版本**：v1.0
**日期**：2026-03-12
**狀態**：Active
**關聯 Story**：US-227
**關聯 ADR**：ADR-017（Context Hub Knowledge Ingestion）

---

## 用途

此 Meta-Index 是 Agent 載入 SBE 知識的**第一層入口**，提供最精簡的模組索引（模組名 + 一句話摘要），讓 Agent 在極小的 context 佔用下快速定位目標模組，再按需深入載入。

---

## 格式定義

每個模組條目的格式如下：

```
| 模組名稱 | 一句話摘要（說明該模組涵蓋的業務規則範疇） | 模組 Index 路徑 |
```

**填寫原則**：
- **模組名稱**：對應 `sbe-examples/` 下的子目錄名稱，使用 kebab-case
- **一句話摘要**：精確描述模組涵蓋的業務規則範疇，不超過 30 字
- **模組 Index 路徑**：指向該模組的 `index.md`，供 Agent 取得範例清單

---

## 模組索引

| 模組名稱 | 業務規則範疇（一句話） | 模組 Index 路徑 |
|---------|-------------------|----------------|
| `sprint-lifecycle` | Sprint Planning、Execution、Review、Retro 全生命週期的 Agent 行為規則與 GATE 條件 | `sprint-lifecycle/index.md` |

---

## Agent 載入流程

Agent 在查詢 SBE 知識時，依照以下三層漸進載入策略執行。此策略設計目標是：**最小化每層 context 佔用，最大化知識查詢精準度**。

### 三層漸進載入

```
Layer 1：Meta-Index（本文件）
    │
    │ context 佔用：極小（僅模組名 + 一句話摘要）
    │ 決策：根據模組摘要，判斷哪個模組與當前任務相關
    │
    ▼
Layer 2：模組 Index（<module>/index.md）
    │
    │ context 佔用：中等（範例清單 + 簡要描述）
    │ 決策：根據範例描述，定位具體的 .sbe.md 文件
    │
    ▼
Layer 3：具體 SBE 範例（<module>/<name>.sbe.md）
    │
    │ context 佔用：完整（Given/When/Then 業務規則詳述）
    │ 決策：讀取完整範例，作為執行的 ground truth
    ▼
Agent 依照 SBE 範例定義的行為規則執行
```

### 決策邏輯（分層細則）

#### Layer 1 → Layer 2 的決策規則

Agent 讀取 Meta-Index 後，根據任務上下文判斷相關模組：

| 任務類型 | 目標模組 |
|---------|---------|
| Sprint Planning 相關（Story 選取、Refinement、GATE 判斷） | `sprint-lifecycle` |
| Sprint Execution 相關（Story 實作、TDD 流程、checkpoint） | `sprint-lifecycle` |
| Sprint Review / Retro 相關（成果整理、指標量測） | `sprint-lifecycle` |

**若任務不在任何已索引模組的範疇內**：直接向 Architect 確認，不猜測。

#### Layer 2 → Layer 3 的決策規則

Agent 讀取模組 Index 後，根據範例描述欄位匹配當前業務情境：

- **精確匹配**：業務情境與某個範例描述高度一致 → 直接載入該 `.sbe.md`
- **部分匹配**：業務情境跨越多個範例 → 載入所有相關 `.sbe.md`（不超過 3 個）
- **無匹配**：模組 Index 中無對應範例 → 依現有 SKILL.md 定義執行，並標記 `[SBE-GAP]` 供後續補充

#### 強制從 Layer 1 開始的情境

以下情境 Agent **必須**從 Layer 1（本文件）開始，不得跳過：

1. 開始新的 Sprint 生命週期任務前
2. 遭遇 GATE 條件判斷時（如排程模式 HARD-GATE、Refinement 前置門禁）
3. 業務規則存在多個 Scenario 分支時（需確認 ground truth 再執行）

### 漸進載入範例

**情境**：Agent 執行排程模式下的 Sprint Planning，需判斷是否觸發 HARD-GATE。

```
Step 1: 讀取 meta-index.md
  → 找到 sprint-lifecycle 模組：「Sprint Planning、Execution、Review、Retro 全生命週期...」
  → 判斷：與 Sprint Planning HARD-GATE 相關 → 前往 Layer 2

Step 2: 讀取 sprint-lifecycle/index.md
  → 找到條目：sprint_planning_scheduled_mode — 「排程模式 HARD-GATE：非 S-size Story 的阻擋條件」
  → 判斷：精確匹配 → 前往 Layer 3

Step 3: 讀取 sprint-lifecycle/sprint_planning_scheduled_mode.sbe.md
  → 載入完整 Scenarios（Given/When/Then）
  → Agent 依照 Scenario 1-5 的規則執行排程模式判斷
```

---

## 維護規範

### 新增模組時

1. 在 `sbe-examples/` 下建立新子目錄：`<module-name>/`
2. 在子目錄內建立 `index.md`（參考 `sprint-lifecycle/index.md` 格式）
3. 在本 Meta-Index 的「模組索引」表格新增一行
4. 更新版本號與日期

### 格式不變原則

Meta-Index 的表格格式為固定規範：**不得新增額外欄位**。若需要更豐富的模組說明，在模組的 `index.md` 中擴充，而非在 Meta-Index 中增加欄位。此原則確保 Meta-Index 永遠保持極小的 context 佔用。

---

## 參考文件

- `docs/definition/sbe-examples/SBE_FORMAT.md`：SBE 格式定義（Given/When/Then 標準格式）
- `docs/definition/sbe-examples/SBE_TO_TEST_RULES.md`：SBE → 測試案例轉換規則
- `docs/adr/ADR-017-context-hub-knowledge-ingestion.md`：Knowledge Ingestion 知識載入策略（兩層索引為漸進載入機制的設計依據）
