# 元件設計準則（設計語言 / 色彩 / 排版 / 間距 / 元件原則）

> 摘錄自 `skills/uiux-designer/SKILL.md`（§4.0 首次使用者建立指引範例結構）

## 1. 設計語言

品牌定位、視覺風格方向，由 PO 在 Design Foundation 三方協作階段輸入，Designer 轉化為 Figma 規格。

## 2. 色彩體系

| 類型 | 說明 | Token 命名格式 |
|------|------|---------------|
| 主色 | 品牌主要識別色，用於 CTA、強調元素 | `color/primary/{weight}` |
| 輔色 | 次要識別色，用於輔助視覺層次 | `color/secondary/{weight}` |
| 中性色 | 文字、邊框、背景灰階 | `color/neutral/{weight}` |
| 語意色 | 系統狀態反饋（成功/警告/危險/資訊） | `color/success|warning|danger|info/{weight}` |

**禁用規則**：所有元件顏色屬性必須綁定 Figma Variable，禁止在元件中 hardcode hex 值。

## 3. 排版系統

| 屬性 | 規範 | Token 命名格式 |
|------|------|---------------|
| 字型族 | 由 Design System 定義主字型（`font-family`） | — |
| 字重 | Regular（400）/ Medium（500）/ Bold（700） | — |
| 字級 Scale | 基於 16px base，使用 Modular Scale | `typography/fontSize/{size}` |

## 4. 間距系統

**基礎規則**：4px Base Grid。所有間距值必須為 4 的倍數。

| Scale | 值 | Token |
|-------|-----|-------|
| 1 | 4px | `spacing/1` |
| 2 | 8px | `spacing/2` |
| 3 | 12px | `spacing/3` |
| 4 | 16px | `spacing/4` |
| 6 | 24px | `spacing/6` |
| 8 | 32px | `spacing/8` |
| 12 | 48px | `spacing/12` |

**Auto Layout 規則**：所有 Figma Frame 與 Component 必須設定 Auto Layout（`layoutMode ≠ NONE`），間距值必須使用 Spacing Scale 允許值。

## 5. 元件設計原則

### 5.1 可重用性

- 所有可重用 UI 元素必須建立為 Figma Component（非單純 Frame）
- Component 必須定義 Variants 覆蓋所有使用狀態（Default / Hover / Active / Disabled / Error）

### 5.2 一致性

- Component 命名遵循 figma-structure-guide.md §2.5 規則
- 同類型元件的高度、圓角、間距必須統一（參照 Component Library 基礎元件規格）

### 5.3 基礎元件規格

| 元件 | 高度 | 圓角 | Auto Layout |
|------|------|------|------------|
| Button | 40px（±2px） | 6px（`borderRadius/md`） | HORIZONTAL / CENTER / gap 8px |
| Input | 40px（±2px） | 4px（`borderRadius/sm`） | HORIZONTAL / paddingH 12px / paddingV 8px |
| Card | 最小 200px | 8px（`borderRadius/lg`） | VERTICAL / gap 16px / padding 24px |

### 5.4 可及性（基礎）

詳細可及性要求見 `skills/uiux-designer/references/accessibility.md`。

基礎要求：
- 顏色對比度：文字與背景對比度 ≥ 4.5:1（WCAG 2.1 AA）
- 互動元素：最小觸控目標 44×44px
- 狀態指示：不得僅靠顏色傳達狀態（須搭配圖示或文字）
