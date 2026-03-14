# SDD-001 前端模板（Frontend Story SDD Template）

**版本**：1.1.0
**最後更新**：2026-03-06
**適用範圍**：所有帶有前端 UI 元件的 User Story

---

## 概覽

本模板定義前端 Story 的標準軟體設計文件（SDD）結構，確保每個前端 Story 在實作前具備完整的設計規格，並在完成前通過必要的驗證關卡。

---

## 一、Story 基本資訊

| 欄位 | 說明 |
|------|------|
| Story ID | 例：US-XXX |
| Issue # | GitHub Issue 編號 |
| Sprint | 所屬 Sprint |
| Owner | 負責開發者 |
| Size / Points | S/M/L / 點數 |

---

## 二、UI 元件規格

### 2.1 元件清單

列出本 Story 涉及的所有 UI 元件，必須使用元件庫白名單內的元件：

| 元件名稱 | 用途 | 來源（元件庫） |
|----------|------|--------------|
| Button | 主要操作觸發 | @shadcn/ui |
| Input | 文字輸入 | @shadcn/ui |

### 2.2 元件狀態定義

說明每個元件的互動狀態（default / hover / active / disabled / error）。

---

## 三、Design Token 使用規範

### 3.1 Token 來源

所有樣式數值必須引用 `design-tokens.json` 中的具名 Token，禁止使用硬編碼（hardcode）數值。

**Token 檔案路徑**：`design-tokens.json`（專案根目錄）

### 3.2 Design Token 路徑驗證規則

#### 3.2.1 正規表示式驗證規則

以下正規表示式用於 PR 審查與 linting 工具，偵測潛在的硬編碼違規：

**顏色硬編碼偵測（應使用 Token 替代）**

```regex
# Hex 顏色碼
/#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})\b/

# RGB/RGBA 函式
/\brgba?\(\s*\d+\s*,\s*\d+\s*,\s*\d+/

# HSL/HSLA 函式
/\bhsla?\(\s*\d+/

# CSS 具名顏色（常見違規）
/\b(red|blue|green|white|black|gray|grey|yellow|orange|purple|pink)\b(?!\s*[:{])/
```

**間距 / 尺寸硬編碼偵測**

```regex
# px 固定值（0px 除外，允許用於邊框重置）
/(?<!^0)\b\d+px\b/

# rem 固定值（非 Token 引用）
/\b\d+(\.\d+)?rem\b/

# 百分比（若為固定排版值，應改用 Token）
/\b(100|[1-9]\d?)%\b(?!\s*[,)])/
```

**字型大小硬編碼偵測**

```regex
# 直接指定字型大小
/font-size\s*:\s*\d+(\.\d+)?(px|rem|em|pt)\b/

# Tailwind 任意值（應使用 Token 轉換後的 class）
/\[([\d.]+)(px|rem|em)\]/
```

#### 3.2.2 ESLint / Stylelint 規則設定

**Stylelint（CSS/SCSS）**

```json
{
  "rules": {
    "color-no-invalid-hex": true,
    "color-named": "never",
    "declaration-property-value-disallowed-list": {
      "color": ["/^#/", "/^rgb/", "/^hsl/"],
      "background-color": ["/^#/", "/^rgb/", "/^hsl/"],
      "border-color": ["/^#/", "/^rgb/", "/^hsl/"]
    },
    "declaration-property-unit-disallowed-list": {
      "font-size": ["px", "pt"],
      "margin": ["px"],
      "padding": ["px"]
    }
  }
}
```

**ESLint（JavaScript/TypeScript — inline style 偵測）**

```json
{
  "rules": {
    "no-restricted-syntax": [
      "error",
      {
        "selector": "Property[key.name='color'][value.type='Literal']",
        "message": "禁止硬編碼顏色值，請使用 design-tokens.json 中的 Token。"
      },
      {
        "selector": "Property[key.name='backgroundColor'][value.type='Literal']",
        "message": "禁止硬編碼背景顏色值，請使用 design-tokens.json 中的 Token。"
      },
      {
        "selector": "Property[key.name='fontSize'][value.type='Literal'][value.value=/px$/]",
        "message": "禁止硬編碼 fontSize（px），請使用 Token 對應的 Tailwind class。"
      }
    ]
  }
}
```

### 3.3 違規範例與正確範例對照

#### 3.3.1 顏色 Token

| 類型 | 違規範例（禁止） | 正確範例（應使用） | Token 對應 |
|------|----------------|------------------|------------|
| CSS 類別 | `color: #1A73E8;` | `color: var(--color-primary-600);` | `design-tokens.json > color.primary.600` |
| CSS 類別 | `background: rgb(26, 115, 232);` | `background: var(--color-primary-600);` | `design-tokens.json > color.primary.600` |
| CSS 類別 | `border-color: red;` | `border-color: var(--color-error-500);` | `design-tokens.json > color.error.500` |
| Tailwind class | `class="text-[#1A73E8]"` | `class="text-primary-600"` | Token 轉換後的 Tailwind config |
| Tailwind class | `class="bg-blue-500"` | `class="bg-primary-600"` | 使用語義化 Token class |
| Inline style (JS) | `style={{ color: '#1A73E8' }}` | `style={{ color: 'var(--color-primary-600)' }}` | CSS 變數引用 |

**說明**：
- 違規：直接使用 HEX、RGB、HSL 或 CSS 具名顏色
- 正確：使用 CSS 變數（`var(--token-name)`）或 Token 對應的 Tailwind utility class

#### 3.3.2 間距（Spacing）Token

| 類型 | 違規範例（禁止） | 正確範例（應使用） | Token 對應 |
|------|----------------|------------------|------------|
| CSS 類別 | `margin: 16px;` | `margin: var(--spacing-4);` | `design-tokens.json > spacing.4` |
| CSS 類別 | `padding: 8px 16px;` | `padding: var(--spacing-2) var(--spacing-4);` | spacing tokens |
| CSS 類別 | `gap: 24px;` | `gap: var(--spacing-6);` | `design-tokens.json > spacing.6` |
| Tailwind class | `class="m-[16px]"` | `class="m-4"` | Tailwind spacing scale（Token 對齊） |
| Tailwind class | `class="p-[8px]"` | `class="p-2"` | Tailwind spacing scale（Token 對齊） |

**說明**：
- 違規：任意 px 固定值、任意值語法（`[Npx]`）
- 正確：使用 Token 對應的 CSS 變數或 Tailwind scale class

#### 3.3.3 圓角（Border Radius）Token

| 類型 | 違規範例（禁止） | 正確範例（應使用） | Token 對應 |
|------|----------------|------------------|------------|
| CSS 類別 | `border-radius: 8px;` | `border-radius: var(--radius-md);` | `design-tokens.json > radius.md` |
| CSS 類別 | `border-radius: 50%;` | `border-radius: var(--radius-full);` | `design-tokens.json > radius.full` |
| Tailwind class | `class="rounded-[8px]"` | `class="rounded-md"` | Token 對應的 Tailwind class |

#### 3.3.4 字型（Typography）Token

| 類型 | 違規範例（禁止） | 正確範例（應使用） | Token 對應 |
|------|----------------|------------------|------------|
| CSS 類別 | `font-size: 14px;` | `font-size: var(--font-size-sm);` | `design-tokens.json > fontSize.sm` |
| CSS 類別 | `font-size: 1.5rem;` | `font-size: var(--font-size-2xl);` | `design-tokens.json > fontSize.2xl` |
| CSS 類別 | `font-weight: 700;` | `font-weight: var(--font-weight-bold);` | `design-tokens.json > fontWeight.bold` |
| Tailwind class | `class="text-[14px]"` | `class="text-sm"` | Tailwind typography（Token 對齊） |

#### 3.3.5 陰影（Shadow）Token

| 類型 | 違規範例（禁止） | 正確範例（應使用） | Token 對應 |
|------|----------------|------------------|------------|
| CSS 類別 | `box-shadow: 0 2px 4px rgba(0,0,0,0.1);` | `box-shadow: var(--shadow-sm);` | `design-tokens.json > shadow.sm` |
| Tailwind class | `class="shadow-[0_2px_4px_rgba(0,0,0,0.1)]"` | `class="shadow-sm"` | Token 對應的 Tailwind class |

---

## 四、UIUX Agent 管線規格

### 4.1 管線觸發條件

本 Story 屬於前端 Story（包含 UI 元件），必須通過 UIUX Agent 三層管線驗證。

觸發條件：Story 標籤包含 `frontend`，且包含至少 1 個 UI 元件。

### 4.2 管線輸入規格

| 管線層 | 輸入 | 輸出 |
|--------|------|------|
| UX Agent（shikigami:uiux-designer） | User Story 文字 | 骨架文件 JSON |
| UI Agent（shikigami:uiux-designer） | 骨架文件 JSON + design-tokens.json | 前端代碼 |
| Vision Critic（shikigami:vision-critic） | 截圖 + 骨架文件 JSON | 視覺評分（0~100）|

---

## 五、Done Definition（完成定義）

本 Story 標記為「完成」前，必須逐項確認以下清單：

### 5.1 功能完整性

- [ ] 所有 Acceptance Criteria 已通過
- [ ] 元件行為符合設計規格（互動狀態完整）
- [ ] 響應式布局已驗證（若適用）

### 5.2 Design Token 合規性

- [ ] 所有顏色值引用 Token（無 HEX / RGB / 具名顏色硬編碼）
- [ ] 所有間距值引用 Token（無任意 px 固定值）
- [ ] 所有圓角值引用 Token
- [ ] 所有字型大小引用 Token
- [ ] Stylelint / ESLint 規則檢查通過（無 Token 違規告警）

### 5.3 UIUX Agent 管線通過（必要關卡）

- [ ] UX Agent（shikigami:uiux-designer）骨架文件 Schema 合規（JSON Schema 驗證通過）
- [ ] UI Agent（shikigami:uiux-designer）Design Token 注入驗證通過（無 hardcode 數值殘留）
- [ ] Vision Critic（shikigami:vision-critic）視覺評分 PASS（評分 ≥ 通過閾值）

### 5.4 代碼品質

- [ ] 測試覆蓋率達標（doc-only Story 免）
- [ ] PR 審查通過（至少 1 位 Reviewer 核准）
- [ ] 無硬編碼 Token 值（Design Token 路徑驗證通過）
- [ ] 既有測試全數通過

### 5.5 文件同步

- [ ] 元件使用說明已更新（若引入新元件）
- [ ] SDD 文件與實作一致

---

## 六、PR 審查清單（Reviewer 用）

審查前端 PR 時，必須確認：

- [ ] 無硬編碼顏色（HEX / RGB / 具名顏色）
- [ ] 無任意間距值（`px` 固定值 / Tailwind 任意值語法 `[Npx]`）
- [ ] 無任意字型大小（直接 `px`/`rem` 值）
- [ ] 所有 Token 引用路徑正確（對應 design-tokens.json 中存在的 key）
- [ ] UIUX 管線三層驗證結果已附於 PR 描述

---

## 七、參考文件

- [design-tokens.json](../../design-tokens.json) — Design Token 標準定義（專案根目錄）
- [ADR-014](../adrs/ADR-014-uiux-agent-architecture.md) — UIUX Agent 架構決策
- [SDD-002-UIUX-E2E.md](SDD-002-UIUX-E2E.md) — UIUX 管線端對端整合測試設計
- [docs/design/design-tokens-versioning.md](../design/design-tokens-versioning.md) — Design Token 版本控制策略

---

*本模板由 Sprint 52（US-104）建立，Sprint 54（US-120、US-135）補充 UIUX 管線 Done Definition 與 Design Token 路徑驗證規則。*
