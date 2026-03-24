# §4.5 / §4.6 / §4.7 DESIGN 路徑與視覺審查

<!-- SSOT：story-lifecycle-prompt.md §4.5 §4.6 §4.7 已移至此處（Sprint 127 #485 模組化拆分） -->

---

## §4.5 DESIGN Type 執行路徑（story_type=DESIGN 時）

<!-- US-207：框架整合更新 — Sprint 78, ADR-016 -->

當 `story_type=DESIGN` 時，本 subagent 切換至 DESIGN 專屬路徑，派遣 UI/UX Designer 角色執行。DESIGN type Story 不進入一般 TDD 循環或 doc-only 路徑，而是遵循以下獨立流程：

### 執行流程

<!-- US-209：Figma MCP Health Check pre-flight 步驟 — Sprint 79, ADR-016 OQ-4 -->

```
story_type=DESIGN 偵測
  |
  v
【Health Check pre-flight】Figma MCP 環境健康檢查（§4.5 pre-flight）
  |-- 依賴 1 FAIL（Figma Desktop App 未啟動）
  |     → 執行恢復步驟（見 skills/uiux-designer/SKILL.md §13 依賴 1）
  |     → 修復後重新確認；若無法修復 → ESCALATE: DEPENDENCY_MISSING
  |-- 依賴 2 FAIL（Plugin 未連接）
  |     → 執行恢復步驟（見 skills/uiux-designer/SKILL.md §13 依賴 2）
  |     → 修復後重新確認；若無法修復 → ESCALATE: DEPENDENCY_MISSING
  |-- 依賴 3 FAIL（CLI Server 未啟動）
  |     → 執行恢復步驟（見 skills/uiux-designer/SKILL.md §13 依賴 3）
  |     → 修復後重新確認；若無法修復 → ESCALATE: DEPENDENCY_MISSING
  |-- 依賴 4 FAIL（MCP 未連接）
  |     → 執行恢復步驟（見 skills/uiux-designer/SKILL.md §13 依賴 4）
  |     → 修復後重新確認；若無法修復 → ESCALATE: DEPENDENCY_MISSING
  +-- 4 項依賴全 PASS（READY）
        |
        v
確認 Design Foundation 就緒
  |-- Design System 不存在 → ESCALATE: DEPENDENCY_MISSING
  +-- 就緒
        |
        v
透過 KCTW/talk-to-figma-mcp 製作 Figma Prototype
  |
  v
Vision Critic 自審（/vision-critic --frame-id <node_id>）
  |-- FAIL（總分 < 80）→ 修復後重試（最多 3 次）
  |-- 連續 3 次 FAIL → ESCALATE: DESIGN_ISSUE
  +-- PASS（≥80 分）
        |
        v
QA Contract Testability Review
  |-- FAIL → 修復後重試（最多 3 次）
  +-- PASS
        |
        v
Prototype 凍結為 Contract → 跳至 §8 DoD 自檢
```

### 豁免項目

| 步驟 | 行為 |
|------|------|
| TDD 循環（§3） | 豁免（無可執行測試） |
| Spec Compliance self-review（§5） | 替換為 Vision Critic 自審 |
| Code Quality self-review（§6） | 不適用（無程式碼） |
| Runtime Verification（§6.5） | 不適用 |
| Security self-review（§7） | 不適用 |

### Review 責任

| 審查對象 | 審查者 | 說明 |
|---------|--------|------|
| Design System / Tokens | Architect | 技術可行性（Design Foundation 階段完成） |
| Component Library | Architect | 元件粒度、框架匹配 |
| Figma Prototype | Vision Critic | Designer 自審工具（非 QA） |
| Contract 可測試性 | QA | Contract Testability Review（Contract 凍結條件） |

詳細流程定義請參閱 [`skills/uiux-designer/SKILL.md`](../uiux-designer/SKILL.md)。

---

## §4.6 DESIGN Blocker 檢查（非 DESIGN Story 的前置檢查）

<!-- US-210：DESIGN Story Sprint 內排序規則 — Sprint 79, ADR-016 OQ-2 -->

**觸發條件**：`story_type` **不為** `DESIGN` 時，在進入一般執行路徑前，執行此檢查。`story_type=DESIGN` 時跳過（DESIGN Story 本身不需檢查自己是否被 blocker）。

### 目的

確保依賴 DESIGN Contract 的 FEATURE Story（或其他 Story）不在 Contract 凍結前開始開發，防止因規格未定導致的返工浪費。

### 檢查流程

```
讀取 sprint_file，取得當前 Story 的 AC 與依賴資訊
  |
  v
掃描依賴 DESIGN Contract 的標記：
  判斷條件（滿足任一即視為依賴 DESIGN Contract）：
  - AC 描述含「依 Figma Prototype」
  - AC 描述含「依 {Story ID} Contract」（Story ID 為 DESIGN type）
  - sprint_file 中當前 Story 的「依賴」欄位列出 DESIGN type Story
  |
  |-- 未偵測到 DESIGN 依賴標記
  |     → DESIGN blocker 檢查：CLEAR（通過）
  |     → 繼續執行一般路徑（doc_only 判斷 → TDD 循環 → ...）
  |
  +-- 偵測到 DESIGN 依賴標記
        |
        v
      讀取 sprint_file，確認依賴的 DESIGN Story 狀態
        |
        |-- DESIGN Story 狀態為「完成」且 Contract 凍結記錄存在
        |     → DESIGN blocker 檢查：CLEAR（通過）
        |     → 繼續執行一般路徑
        |
        +-- DESIGN Story 狀態為「待辦」、「進行中」、「FAIL」或「不存在」
              → 輸出告警：
                [DESIGN-BLOCKER] {current_story_id} 依賴 {design_story_id} 的 Figma Prototype Contract，
                但 Contract 尚未凍結（{design_story_id} 狀態：{status}）。
                依 SKILL.md §4.6 排序規則，本 Story 不得在 Contract 凍結前開始開發。
              → 回傳 ESCALATE: DEPENDENCY_MISSING
```

### 檢查結論輸出

```
DESIGN Blocker 檢查 — {story_id}

依賴掃描結果：
- DESIGN 依賴偵測：{偵測到 / 未偵測到}
- 依賴的 DESIGN Story：{story_id 或 N/A}
- DESIGN Contract 狀態：{已凍結 / 未凍結 / N/A}

整體結論：CLEAR（可繼續執行）/ BLOCKED（ESCALATE: DEPENDENCY_MISSING）
```

### 備注

- 本檢查為**防呆機制**：正常情況下主 session 的排序邏輯（`SKILL.md §4.6`）應確保 DESIGN Story 先於依賴其 Contract 的 FEATURE Story 執行。本檢查作為第二道防線，處理排序邏輯未能覆蓋的邊界情況（如主 session 錯誤排序、手動觸發等）。
- **[MOCK-CONTRACT] 豁免**：若 FEATURE Story 備注欄含有 `[MOCK-CONTRACT]` 標記（主 session 明確決定以模擬資料降級執行），跳過本檢查，輸出告警提示後繼續執行。

---

## §4.7 前端 FEATURE Story 視覺一致性審查（US-244 AC3）

<!-- US-244 前端 Story 交付視覺一致性審查 — Sprint 88 -->

<HARD-GATE>
**UIUX/QA 角色載入 Hard Gate**：進入視覺一致性審查前，必須使用 Read 工具讀取 `agents/uiux-designer.md`（UIUX 視覺一致性審查視角）與 `agents/qa-engineer.md`（QA 視覺回歸確認視角），載入兩個角色的完整決策權與方法論。此 Gate 不受 bypass=true 豁免。
</HARD-GATE>

**觸發條件**：`story_type=FEATURE` 且 Story 被識別為前端 Story（涉及 UI 元件、頁面、視覺設計的修改）時，在雙階段自審（Spec Compliance + Code Quality）通過後、DoD 自檢前，執行 UIUX/QA 視覺一致性審查。

> **注意**：`story_type=DESIGN` 的 Story 走 §4.5 專屬路徑（Vision Critic 自審 + QA Contract Testability Review），不適用本節。本節僅適用於 **FEATURE type 的前端修改 Story**。

### 前端 Story 識別（§4.7 內部判斷）

進入此步驟時，重新確認 Story 是否為前端 Story（與 `SKILL.md §2.10` 識別標準一致）：

- AC 描述含 UI 元件相關詞語（頁面、元件、視覺、版面、畫面、介面等）
- AC 描述含前端技術詞語（React、Vue、CSS、樣式、RWD 等）
- 故事標題或 AC 明確描述「前端修改」、「UI 實作」等

**若不符合前端 Story 識別標準** → `[VCR-SKIP]` 跳過視覺一致性審查，直接進入 DoD 自檢

### 審查流程

```
前端 Story 識別：符合 → 執行視覺一致性審查
  |
  v
Step 1：設計規格確認
  - 確認是否有參照設計規格（Figma Prototype 連結 / Design Spec / Design Token）
  - 若有 → 依規格進行視覺對比；若無 → 以 Design Token 為基準驗證
  |
  v
Step 2：UIUX 視覺一致性審查（Developer 自審，代 UIUX 角色視角）
  審查項目：
  - [ ] VCR-1：元件樣式符合 Design Token（顏色、字體、間距）
  - [ ] VCR-2：版面結構符合設計規格（或現有 Design System 慣例）
  - [ ] VCR-3：互動行為與 AC 描述一致（hover、focus、disabled 等狀態）
  - [ ] VCR-4：響應式設計（RWD）邊界條件已處理（若 Story 涉及 RWD）
  |
  v
Step 3：QA 視覺回歸確認（Developer 自審，代 QA 角色視角）
  審查項目：
  - [ ] VCR-5：修改後的 UI 與既有頁面視覺風格一致，無明顯衝突
  - [ ] VCR-6：新增 UI 元件不破壞既有版面（無意外 overflow、遮蔽等問題）
  |
  v
整體結論
  |-- 所有 VCR-1 ~ VCR-6 通過（或 N/A）→ [VCR-PASS] 視覺一致性審查通過
  +-- 任一項目 FAIL → [VCR-FAIL] 修復後重新審查（最多 3 次）
        第 3 次仍 FAIL → 回傳 ESCALATE: DESIGN_ISSUE（建議 UIUX Designer 介入）
```

### 審查清單格式

```
UIUX/QA 視覺一致性審查 — {story_id}

Story 類型：前端 FEATURE Story
設計規格參照：{Figma Prototype URL / Design Token 路徑 / N/A}

UIUX 視覺一致性審查：
- [ ] VCR-1：元件樣式符合 Design Token → {PASS/FAIL/N/A + 說明}
- [ ] VCR-2：版面結構符合設計規格 → {PASS/FAIL/N/A + 說明}
- [ ] VCR-3：互動行為與 AC 描述一致 → {PASS/FAIL/N/A + 說明}
- [ ] VCR-4：響應式設計邊界條件 → {PASS/FAIL/N/A + 說明}

QA 視覺回歸確認：
- [ ] VCR-5：視覺風格一致性 → {PASS/FAIL/N/A + 說明}
- [ ] VCR-6：版面完整性（無破壞既有版面）→ {PASS/FAIL/N/A + 說明}

整體結論：[VCR-PASS] / [VCR-FAIL]
```

### 降級策略

- 若無 Design Token（`docs/design/design-tokens.json` 不存在） → VCR-1 改為「與現有 UI 元件樣式一致」替代驗證
- 若 Story 僅修改邏輯（AC 確認無 UI 渲染變更） → `[VCR-SKIP]` 跳過
- 所有降級情境均輸出對應標記，不阻塞但記錄至 DoD 自檢
