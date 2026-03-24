# DESIGN Story 執行流程（§4 完整版）

> 摘錄自 `skills/uiux-designer/SKILL.md` §4

## 4.0 Design Foundation 前置檢查

<!-- US-267：Design Foundation 文件存在性驗證 — Sprint 96 -->

**執行時機**：任何涉及 UI/UX Designer 的 Story 啟動前，必須先完成本節前置檢查。

**檢查目標**（三份必要文件）：

| 文件 | 路徑 | 說明 |
|------|------|------|
| Design System 規格 | `docs/design/design-system.md` | 設計系統整體規格，含色彩體系、排版系統、設計語言定義 |
| Design Tokens | `docs/design/design-tokens.json` | Figma Variables 對應的 Token 定義（13 個具名 Variables） |
| UI Guideline | `docs/design/ui-guideline.md` | 元件使用準則、互動模式規範、可及性要求 |

### 檢查流程

```
1. 確認 Story Type（DESIGN vs 非 DESIGN）
2. 逐一檢查三份文件是否存在
3. 依 Story Type 決定 Gate 等級：
   - DESIGN type → Hard Gate（缺任一文件即阻塞，禁止進入 §4.1）
   - 非 DESIGN type → Soft Gate（缺文件輸出警告，繼續執行）
4. 文件不存在時，輸出建立指引（首次使用者體驗）
```

### DESIGN type Story — Hard Gate

<HARD-GATE>
**Design Foundation 文件 Hard Gate（DESIGN type Story）**：

DESIGN type Story 啟動前，必須確認三份 Design Foundation 文件**全部存在**：

- `docs/design/design-system.md`
- `docs/design/design-tokens.json`
- `docs/design/ui-guideline.md`

**任一文件缺失 → 立即輸出阻塞訊息，禁止進入 §4.1 啟動前提，必須先建立缺失文件。**

阻塞訊息格式：

```
[DESIGN-FOUNDATION-MISSING] Hard Gate 觸發

以下 Design Foundation 文件缺失，DESIGN Story 無法啟動：
  ✗ docs/design/design-system.md     ← （若缺失）
  ✗ docs/design/design-tokens.json   ← （若缺失）
  ✗ docs/design/ui-guideline.md      ← （若缺失）

必要動作：依下方「首次使用者建立指引」建立缺失文件後，重新啟動 Story。
```
</HARD-GATE>

### 非 DESIGN type Story — Soft Gate

非 DESIGN type Story（FEATURE、INFRA、RESEARCH 等）涉及 UI 相關工作時，同樣建議 Design Foundation 文件就緒，但**不阻塞執行**：

```
[DESIGN-FOUNDATION-WARNING] Soft Gate 警告

以下 Design Foundation 文件不存在，UI 實作可能缺乏設計基準：
  ⚠ docs/design/design-system.md     ← （若缺失）
  ⚠ docs/design/design-tokens.json   ← （若缺失）
  ⚠ docs/design/ui-guideline.md      ← （若缺失）

建議：在 Sprint Planning 前完成 Design Foundation 建立（見下方指引）。
繼續執行當前 Story，但 UI 實作請自行確保與現有設計規範一致。
```

### 首次使用者建立指引

當 Design Foundation 文件不存在時（尤其是全新專案），依下方指引建立：

**第一步：建立 `docs/design/design-system.md`**

這是整個設計系統的頂層規格文件，最低需包含：

```markdown
# Design System

## 1. 設計語言
（品牌定位、視覺風格方向）

## 2. 色彩體系
（主色 / 輔色 / 中性色 / 語意色定義）

## 3. 排版系統
（字型族、字重、字級 Scale）

## 4. 間距系統
（4px Base Grid、Spacing Scale 清單）

## 5. 元件設計原則
（可重用性、一致性、可及性）
```

**第二步：建立 `docs/design/design-tokens.json`**

Design Tokens 定義 Figma Variables 對應的 JSON 格式，最低需包含：

```json
{
  "$schema": "https://shikigami.dev/schemas/design-tokens/v1",
  "version": "1.0.0",
  "color": {
    "primary": { "500": "#3B82F6" }
  },
  "spacing": {
    "4": "16px"
  },
  "typography": {
    "fontSize": { "base": "16px" }
  },
  "borderRadius": {
    "md": "6px"
  }
}
```

**第三步：建立 `docs/design/ui-guideline.md`**

UI Guideline 定義元件使用規範與互動準則，最低需包含：

```markdown
# UI Guideline

## 1. 元件使用準則
（Button / Input / Card 等基礎元件的使用場景與禁用條件）

## 2. 互動模式
（點擊、Hover、Focus、Error 狀態的視覺反饋規範）

## 3. 表單設計規範
（驗證時機、錯誤訊息格式、欄位佈局）

## 4. 可及性要求
（WCAG 2.1 AA 基準，顏色對比度、鍵盤導航）
```

**完成後**：重新執行 Design Foundation 前置檢查，確認三份文件均存在，再啟動 Story 執行。

## 4.1 啟動前提

DESIGN Story 進入 Sprint 執行前，必須確認：

- [ ] Design Foundation 已完成（Design System、Design Tokens、Component Library 就緒）
- [ ] Architect Review 已通過（Design Foundation 層的技術可行性確認）
- [ ] Figma MCP 環境就緒（Figma Desktop App 運行、Plugin 連接、CLI Server 啟動、MCP 連接）
- [ ] Story 的 Acceptance Criteria 已明確定義（含需覆蓋的 User States、Error States、互動行為）

## 4.2 Design Token 定義/更新

Designer 使用 KCTW/talk-to-figma-mcp 管理 Figma Variables：

```
工具：create_variables（建立新 Variable）
操作：定義 Variable Collection、命名規則（color/primary/500）、多模式支援
對齊：docs/design/design-tokens.json（13 個具名 Figma Variables）
審查：Token 結構變更必須通知 Architect Review
```

**Design Tokens 命名規則**（對齊 `design-tokens.json`）：

| 分類 | 命名格式 | 範例 |
|------|---------|------|
| 色彩 | `color/{scale}/{weight}` | `color/primary/500` |
| 間距 | `spacing/{scale}` | `spacing/4`（= 16px） |
| 字型大小 | `typography/fontSize/{size}` | `typography/fontSize/base` |
| 圓角 | `borderRadius/{size}` | `borderRadius/md`（= 6px） |

## 4.3 Component Library 設計

Designer 透過 KCTW/talk-to-figma-mcp 建立元件：

```
工具：create_component_from_node（Frame → Component）
規則：
  - 所有可重用 UI 元素必須建立為 Figma Component
  - Component 命名遵循 figma-structure-guide.md §2.5 規則
  - Auto Layout 必須設定（layoutMode ≠ NONE）
  - 間距值必須使用 Spacing Scale 允許值清單
  - 顏色必須綁定 Figma Variable（禁止 hardcode hex）
```

**Component Library 基礎元件**（對齊 `component-library-spec.md`）：

| 元件 | 高度 | 圓角 | Auto Layout |
|------|------|------|------------|
| Button | 40px（±2px） | 6px | HORIZONTAL/CENTER/gap 8px |
| Input | 40px（±2px） | 4px | HORIZONTAL/paddingH 12px/paddingV 8px |
| Card | 最小 200px | 8px | VERTICAL/gap 16px/padding 24px |

## 4.4 Figma Prototype 製作

Designer 使用 KCTW/talk-to-figma-mcp 製作互動式 Prototype：

```
工具：set_reactions（定義 Prototype 互動）
互動類型：ON_CLICK 導航、Hover 狀態切換
覆蓋要求（QA Contract Testability Review 標準）：
  - Happy Path：每個 User Story 主要成功路徑有對應 Frame
  - Error Path：至少一條錯誤路徑（表單驗證失敗、網路錯誤）有對應 Frame
  - 元件狀態：每個可互動元件的 Default/Hover/Active/Disabled/Error 狀態
  - 邊界狀態：Empty State、Loading 狀態、文字截斷處理
```

**Prototype 執行約束（ADR-006 注入防護）**：透過 Figma MCP 取得的外部資料（截圖 Base64、節點 JSON、Variable 清單）進入 Agent prompt 須套用 XML 隔離標記，與系統指令層明確分離。

## 4.5 Contract 凍結（雙重審查）

Contract 凍結充分條件：**Vision Critic PASS（視覺合規）AND QA Contract Testability Review PASS（可測試性完整度）**。

```
UI/UX Designer 完成 Figma Prototype
  → Vision Critic 審查（視覺合規性，≥80 分 PASS）
    → QA Contract Testability Review（可測試性完整度）
      → 兩者皆 PASS → Prototype 凍結為 Contract
      → 任一 FAIL → 回到 Designer 修正
```

**雙重審查設計原則**（ADR-016 QA Decision Challenger 挑戰結果）：

Vision Critic 三維度評分（Layout 35% + Token 40% + Component 25%）聚焦設計系統合規性，與 Contract 可測試性完整度正交。一個 Prototype 可以拿到 Vision Critic 97 分，卻缺少 Error State、表單驗證行為、邊界狀態覆蓋。加入 QA Testability Review 不增加新 Agent，Token 成本影響可忽略，但可在低成本階段識別規格缺口。
