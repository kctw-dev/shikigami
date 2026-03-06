# Figma 文件結構指南

**建立日期**：2026-03-06
**關聯 ADR**：ADR-015（Figma 整合取代 SSD 管線，Accepted）
**關聯 Story**：US-146（Sprint 55）
**關聯指南**：[Figma MCP Server 選型與本地設定指南](../guides/figma-mcp-setup.md)
**版本**：v1.0

---

## 概述

本指南定義 Shikigami 專案的 Figma 文件結構標準，包含 Page 架構、Layer 命名規則與 Frame 模板規格。所有 AI 生成的 Figma 內容與人工設計工作均須遵循此結構，確保：

- **可導覽性**：人工設計師能快速定位任何 Sprint 的設計稿
- **AI 可操作性**：AI Agent 能以一致的命名規則建立與引用節點
- **跨 Story 一致性**：不同 User Story 生成的 Frame 遵循相同的結構慣例
- **審查可追溯性**：Vision Critic 能對應 Frame 命名找到對應 User Story

---

## AC1：Page 架構定義

### 1.1 標準 Page 清單

每個 Shikigami Figma 文件應包含以下固定 Page，按順序排列：

| 順序 | Page 名稱 | 用途 | 內容說明 |
|------|-----------|------|----------|
| 1 | `_Component-Library` | 元件庫（主要來源） | 所有可重用的 Figma Component，AI 生成 Frame 時引用此處的元件 Instance |
| 2 | `_Design-Tokens` | Design Token 可視化 | Figma Variables 的視覺化呈現，對應 `docs/design/design-tokens.json` 的 token 結構 |
| 3 | `_Archive` | 歷史稿件歸檔 | 已廢棄或過期的 Frame 移入此頁，不刪除但不影響作業中的 Page |
| 4+ | `Sprint-{N}-{功能名}` | 各 Sprint 設計稿 | 每個 Sprint 一個 Page，含該 Sprint 所有 User Story 的 Frame |

**命名規則說明**：
- 固定 Page 名稱以底線 `_` 開頭，確保排序時置於 Sprint Page 之前
- Sprint Page 不加底線前綴，按 Sprint 編號自然排序

### 1.2 固定 Page 詳細規格

#### `_Component-Library` Page

- **用途**：存放所有已定義的 Figma Component（Master Component）
- **結構**：按元件類型以 Section 分組（見下方元件分類）
- **Section 命名**：`[元件類型]` 例如 `[Atoms]`、`[Molecules]`、`[Organisms]`
- **AI 操作原則**：AI 建立新 Frame 時優先引用此 Page 的元件，而非重新定義原始形狀
- **更新原則**：新元件在此 Page 建立 Master Component，所有其他 Page 的使用均為 Instance

元件分類結構：

```
_Component-Library
├── [Atoms]        — 原子元件：Button、Input、Label、Icon、Badge、Divider 等
├── [Molecules]    — 分子元件：FormField、SearchBar、Card、ListItem 等
├── [Organisms]    — 組織元件：Header、Sidebar、DataTable、Modal 等
└── [Templates]    — 版面模板：PageLayout、FormLayout 等
```

#### `_Design-Tokens` Page

- **用途**：以視覺方式呈現 Figma Variables，讓設計師能直覺理解 Token 值
- **結構**：按 Token 類別以 Frame 分組，各 Frame 命名為 `Tokens/{類別}` 例如 `Tokens/Colors`
- **Token 類別**：

| Frame 名稱 | 對應 Token 類別 | 說明 |
|-----------|----------------|------|
| `Tokens/Colors` | `color.*` | 品牌色、語意色（success、warning、error、info）、中性色（gray scale） |
| `Tokens/Typography` | `typography.*` | 字型、字級（font-size）、行高（line-height）、字重（font-weight） |
| `Tokens/Spacing` | `spacing.*` | 間距系統（xs、sm、md、lg、xl） |
| `Tokens/Border-Radius` | `border-radius.*` | 圓角規格（sm、md、lg、full） |
| `Tokens/Shadow` | `shadow.*` | 陰影規格（sm、md、lg） |

- **對應關係**：此 Page 的 Variables 與 `docs/design/design-tokens.json` 保持同步（Figma Variables 為主要來源，`design-tokens.json` 為導出快照）

#### `_Archive` Page

- **用途**：保存歷史版本或已廢棄的設計稿，保留審查軌跡
- **操作**：將廢棄 Frame 移入此 Page 前，在 Frame 名稱後附加 `[ARCHIVED-{YYYY-MM-DD}]`，例如 `US-103-Design-Tokens-Flow [ARCHIVED-2026-03-15]`
- **不得**：直接刪除任何含有 User Story ID 的 Frame，歸檔優先於刪除

### 1.3 Sprint Page 規格

**命名格式**：`Sprint-{N}-{功能名}`

| 元素 | 說明 | 範例 |
|------|------|------|
| `Sprint-` | 固定前綴 | — |
| `{N}` | Sprint 編號，兩位數補零（01、02、...、55、56） | `55` |
| `-` | 分隔符 | — |
| `{功能名}` | 該 Sprint 核心功能的簡短中英文描述，使用 PascalCase 或 Kebab-case | `FigmaIntegration` 或 `Figma-Integration` |

**範例**：
- `Sprint-55-FigmaIntegration`
- `Sprint-56-ComponentLibrary`
- `Sprint-57-VisionCritic`

**Sprint Page 內部結構**：
- 每個 Sprint Page 內，Frame 按 User Story ID 排列（US-145 Frame 在左，US-146 Frame 在右，以此類推）
- Sprint Page 頂部保留一個 `[Sprint-{N}-Overview]` 說明區域（使用 FigJam Sticky 或 Text Frame），記錄 Sprint Goal 與 Frame 索引

---

## AC2：Layer 命名規則定義

### 2.1 命名總原則

**語意化優先**：Layer 名稱應表達其語意用途，而非描述視覺外觀。

| 錯誤（外觀描述） | 正確（語意描述） |
|-----------------|-----------------|
| `Rectangle 1` | `Card-Background` |
| `Group 2` | `Navigation-Links` |
| `Blue Button` | `Primary-Action-Button` |
| `Frame 4` | `US-146-Page-Architecture-Overview` |

**大小寫規則**：
- Frame 名稱：`{StoryID}-{功能描述}`，使用 Kebab-case（連字號）
- Group 名稱：`{語意描述}`，使用 Kebab-case
- Component 名稱（Master）：`{類型}/{變體}`，使用斜線分隔類型與變體
- Component Instance 名稱：保留 Master 名稱，加上上下文後綴 `({上下文})`

### 2.2 Frame 命名規則

**格式**：`{StoryID}-{功能描述}`

| 元素 | 說明 | 範例 |
|------|------|------|
| `{StoryID}` | User Story ID，格式為 `US-{N}` | `US-146` |
| `-` | 分隔符 | — |
| `{功能描述}` | 簡短描述此 Frame 的功能目標，使用 Kebab-case | `Figma-Structure-Overview`、`Page-Architecture-Desktop` |

**多視窗 Frame（同一 Story 有多個尺寸或狀態）**：
- 在後面附加 `-{平台}` 或 `-{狀態}`

| 後綴類型 | 格式 | 範例 |
|---------|------|------|
| 平台區分 | `-Desktop` / `-Mobile` / `-Tablet` | `US-146-Page-Architecture-Desktop` |
| 狀態區分 | `-Default` / `-Loading` / `-Error` / `-Empty` | `US-146-Form-Input-Error` |
| 流程步驟 | `-Step-{N}` | `US-146-Onboarding-Step-1` |

**PoC / 測試用 Frame**：
- 前綴加 `POC-` 或 `TEST-`，後接說明
- 例如：`POC-US-147-AutoLayout-Verification`、`TEST-US-145-MCP-Connection`
- 驗證完成後應移至 `_Archive` Page

### 2.3 Group 命名規則

**格式**：`{語意區塊名}`（使用 Kebab-case）

Group 命名應反映其包含的 UI 區塊語意，常見慣例：

| Group 語意 | 命名範例 |
|-----------|----------|
| 頁面區域 | `Header`、`Sidebar`、`Footer`、`Main-Content` |
| 表單群組 | `Login-Form`、`Search-Bar`、`Filter-Panel` |
| 導航項目 | `Primary-Navigation`、`Breadcrumb` |
| 內容清單 | `Card-List`、`Table-Row-Group` |
| 互動狀態層 | `Hover-Overlay`、`Loading-Skeleton` |
| 標注層 | `Annotations`（設計稿標注用，非實際 UI） |

**禁止命名**：
- `Group`、`Group 1`、`Group 2`（Figma 預設名稱，未加語意）
- `Frame`、`Frame 1`（同上）
- `Container`（過於泛化）

### 2.4 元件命名規則（Master Component）

**格式**：`{類型}/{變體}`（使用斜線 `/` 分層）

斜線命名在 Figma 中會被解析為元件分層，對應 Component Set 的組織方式：

```
Button/Primary          ← Button 類型，Primary 變體
Button/Secondary
Button/Ghost
Button/Destructive

Input/Default
Input/Focused
Input/Error
Input/Disabled

Card/Default
Card/Elevated
Card/Outlined
```

**多維度變體**（適用於有 Size / State / Theme 等多個屬性的元件）：

```
Button/Primary/Large
Button/Primary/Medium
Button/Primary/Small
Button/Secondary/Large
```

**Figma Component Set 建議**：對於有多個變體的元件，優先使用 Figma Component Set（將所有變體組合為一個 Component Set 節點），並透過 Variant Property 控制變體切換，而非建立多個獨立 Master Component。

### 2.5 元件實例命名規則（Component Instance）

**預設行為**：Instance 建立後，Figma 會保留 Master Component 名稱（如 `Button/Primary`）。

**加上下文後綴**（當同一 Frame 中有多個相同元件 Instance 時）：
- 格式：`{Master名稱} ({上下文})`
- 例如：`Button/Primary (Submit)`、`Button/Primary (Cancel)`、`Button/Ghost (Skip)`

**命名時機**：
- 如果 Frame 中只有一個該類型的 Instance，可保留 Master 名稱不加後綴
- 如果 Frame 中有兩個以上相同類型的 Instance，必須加上下文後綴以區分

### 2.6 文字層命名規則

**格式**：反映文字的語意用途，而非文字內容本身

| 語意用途 | 命名範例 |
|---------|----------|
| 頁面標題 | `Page-Title`、`Hero-Heading` |
| 段落說明 | `Section-Description`、`Body-Text` |
| 標籤 | `Input-Label`、`Form-Field-Label` |
| 錯誤訊息 | `Error-Message`、`Validation-Text` |
| 按鈕文字 | `CTA-Text`（僅在文字層獨立存在時，通常文字層位於 Button Component 內部） |
| 佔位符 | `Placeholder-Text` |

**禁止命名**：
- `Text`、`Text 1`、`Label`（過於泛化）
- 直接用文字內容命名（如 `請輸入電子郵件`）

---

## AC3：Frame 模板規格定義

### 3.1 標準 Frame 尺寸

| 平台 | 寬度 | 高度 | 用途說明 |
|------|------|------|----------|
| **Desktop** | 1440 px | 依內容決定（最小 900 px） | 桌面版頁面設計 |
| **Mobile** | 375 px | 依內容決定（最小 812 px） | 行動版頁面設計（iPhone 14 Pro 基準） |
| **Tablet** | 768 px | 依內容決定（最小 1024 px） | 平板版設計（iPad 基準） |
| **Component** | 依元件決定 | 依元件決定 | Component Library 中的元件 Frame |
| **Token-Swatch** | 240 px | 依 Token 數量決定 | `_Design-Tokens` Page 的 Token 色票展示 |

**高度說明**：
- 頁面 Frame 的高度不固定，隨內容量決定
- 使用 Auto Layout 的 Frame 高度通常設定為 `Hug` 模式（由子元素撐高）
- 固定頁面區塊（如 Header）高度設定為數值（不使用 Hug）

### 3.2 Desktop Frame 模板規格

**適用範圍**：Sprint Page 中所有 Desktop 平台的頁面 Frame

```
Frame 名稱：{US-XXX}-{功能描述}-Desktop
寬度：1440 px
高度：Hug（由 Auto Layout 決定）
背景色：--color-background-primary（對應 Figma Variable）

Auto Layout 設定：
  方向：Vertical（垂直，由上至下排列頁面區塊）
  Alignment：Left
  Gap（子元素間距）：0 px（頁面區塊緊密相連，各區塊內部自行設定間距）
  Padding：0 px（頁面最外層 Frame 無 Padding，各區塊自行設定）
  Overflow：Scroll（允許內容超出 Frame 高度可滾動）

子層結構（建議順序）：
  1. Header（高度固定：64 px）
  2. Main-Content（高度：Hug，Auto Layout Vertical，Padding：80 px 上下、0 px 左右）
  3. Footer（高度固定：依設計決定）

內容區塊（Main-Content）Auto Layout：
  方向：Vertical
  Gap：48 px（區塊間距）
  Padding：80 px 上下 / 0 px 左右（水平邊距由容器 max-width 決定）
  Max Width：1200 px（內容最大寬度，水平居中）
```

### 3.3 Mobile Frame 模板規格

**適用範圍**：Sprint Page 中所有 Mobile 平台的頁面 Frame

```
Frame 名稱：{US-XXX}-{功能描述}-Mobile
寬度：375 px
高度：Hug（由 Auto Layout 決定）
背景色：--color-background-primary（對應 Figma Variable）

Auto Layout 設定：
  方向：Vertical
  Alignment：Left
  Gap：0 px（頁面區塊緊密相連）
  Padding：0 px
  Overflow：Scroll

子層結構（建議順序）：
  1. Mobile-Header（高度固定：56 px）
  2. Main-Content（高度：Hug，Auto Layout Vertical）
  3. Bottom-Navigation（高度固定：60 px，含 safe area）

內容區塊（Main-Content）Auto Layout：
  方向：Vertical
  Gap：24 px
  Padding：16 px 上下 / 16 px 左右（行動版水平 Padding）
```

### 3.4 元件 Frame 模板規格（Component Library 用）

**適用範圍**：`_Component-Library` Page 中的 Master Component Frame

```
Component Frame Auto Layout 設定（以 Button 為例）：

Button/Primary（基本規格）：
  方向：Horizontal
  Alignment：Center（水平垂直居中）
  Gap：8 px（Icon 與文字之間的間距，若有 Icon）
  Padding：12 px 上下 / 24 px 左右
  高度：40 px（Medium 尺寸預設）
  圓角：--border-radius-md（對應 Figma Variable）
  背景色：--color-brand-primary（對應 Figma Variable）
  文字色：--color-text-on-primary（對應 Figma Variable）

Button 尺寸變體：
  Large：高度 48 px，Padding 14 px 上下 / 28 px 左右
  Medium：高度 40 px，Padding 12 px 上下 / 24 px 左右（預設）
  Small：高度 32 px，Padding 8 px 上下 / 16 px 左右

Input/Default（基本規格）：
  方向：Horizontal
  Alignment：Left（文字左對齊）
  Gap：8 px（前綴 Icon 與文字之間）
  Padding：12 px 上下 / 16 px 左右
  高度：40 px
  圓角：--border-radius-sm
  邊框：1 px Solid --color-border-default
  背景色：--color-background-primary

Card/Default（基本規格）：
  方向：Vertical
  Alignment：Left
  Gap：16 px（Card 內部元素間距）
  Padding：24 px（四邊均等）
  圓角：--border-radius-md
  背景色：--color-background-surface
  陰影：--shadow-sm（對應 Figma Variable）
```

### 3.5 間距系統（Spacing Scale）

以下間距值對應 `design-tokens.json` 中的 `spacing.*` Token，在 Figma Auto Layout 的 Gap 與 Padding 設定中使用：

| Token 名稱 | 值 | 使用場景 |
|-----------|-----|----------|
| `spacing.xs` | 4 px | 細密間距（Icon 與文字、Badge 內部） |
| `spacing.sm` | 8 px | 小間距（表單欄位內部元素） |
| `spacing.md` | 16 px | 標準間距（卡片內容、行動版 Padding） |
| `spacing.lg` | 24 px | 中等間距（行動版區塊間距、元件 Gap） |
| `spacing.xl` | 32 px | 大間距（桌面版 Section 上下 Padding） |
| `spacing.2xl` | 48 px | 超大間距（桌面版頁面區塊間距） |
| `spacing.3xl` | 64 px | 最大間距（英雄區塊 Padding） |
| `spacing.4xl` | 80 px | 桌面版 Main Content 上下 Padding |

**使用原則**：
- Gap 與 Padding 的值必須使用此 Spacing Scale 中的值，不得使用任意數值
- 若需要特殊間距，先確認是否有對應 Token；若無，提出新增 Token 的需求，不直接使用自訂數值

### 3.6 Auto Layout 設定速查表

| 設定場景 | 方向 | Gap | Padding | Alignment |
|---------|------|-----|---------|-----------|
| 桌面頁面最外層 Frame | Vertical | 0 | 0 | Left |
| 行動頁面最外層 Frame | Vertical | 0 | 0 | Left |
| 桌面 Main Content 區塊 | Vertical | 48 px (2xl) | 80 px 上下, 0 左右 | Left |
| 行動 Main Content 區塊 | Vertical | 24 px (lg) | 16 px (md) 四邊 | Left |
| Header 內部 | Horizontal | 16 px (md) | 0 上下, 24 px 左右 | Space-Between |
| 按鈕（Primary / Secondary） | Horizontal | 8 px (sm) | 12 px 上下, 24 px 左右 | Center |
| 輸入欄位 | Horizontal | 8 px (sm) | 12 px 上下, 16 px 左右 | Left |
| Card 內部 | Vertical | 16 px (md) | 24 px (lg) 四邊 | Left |
| Form 表單 | Vertical | 16 px (md) | 0 | Left |
| 清單（List） | Vertical | 8 px (sm) | 0 | Left |
| 水平按鈕組（Button Group） | Horizontal | 8 px (sm) | 0 | Center |

---

## 附錄 A：AI 操作 Figma 的命名遵循原則

當 AI Agent 透過 `claude-talk-to-figma-mcp` 建立 Figma 節點時，必須遵循以下原則：

1. **Frame 命名**：呼叫 `create_frame` 時，`name` 參數必須符合 `{StoryID}-{功能描述}-{平台}` 格式
2. **Group 命名**：呼叫 `group_nodes` 時，`name` 參數必須符合語意化命名規則（不得使用預設 `Group` 名稱）
3. **Page 選擇**：呼叫 `set_current_page` 時，優先切換到對應 Sprint Page（如 `Sprint-55-FigmaIntegration`），不在 `_Component-Library` 或 `_Design-Tokens` Page 建立 User Story Frame
4. **元件引用**：呼叫 `create_component_instance` 前，先呼叫 `get_local_components` 確認元件存在，引用現有元件而非重新建立形狀
5. **Variable 套用**：顏色、間距等屬性套用時優先使用 `apply_variable_to_node` 並指定對應 Token 名稱，而非直接設定 hex 值

---

## 附錄 B：常見命名錯誤與修正

| 錯誤命名 | 問題說明 | 正確命名 |
|---------|---------|---------|
| `Frame 1` | Figma 預設名稱，無語意 | `US-146-Page-Overview-Desktop` |
| `Rectangle 3` | 形狀描述，無語意 | `Hero-Background` |
| `Group 2` | 無語意群組名 | `Login-Form` |
| `button` | 小寫，不符合命名規則 | `Button/Primary` |
| `Primary Button` | 空格，應使用 Kebab-case 或斜線分層 | `Button/Primary` |
| `Spring 55` | 拼寫錯誤 | `Sprint-55-FigmaIntegration` |
| `sprint_55_figma` | 下底線，不符合慣例 | `Sprint-55-FigmaIntegration` |
| `US146-Overview` | 缺少 Story ID 格式中的連字號 | `US-146-Overview-Desktop` |

---

## 附錄 C：快速參考卡

### 新建 Sprint Page 時

```
1. 呼叫 create_page，名稱：Sprint-{N}-{功能名}
2. 頁面頂部建立 Text Frame：[Sprint-{N}-Overview]，記錄 Sprint Goal
3. 依 Story 排列 Frame（US-XXX 在左側，Story ID 遞增向右）
```

### 新建 User Story Frame 時

```
1. 確認當前 Page 為對應 Sprint Page
2. create_frame：名稱 = US-{N}-{功能描述}-Desktop（或 Mobile）
3. set_auto_layout：方向 Vertical、Gap 0、Padding 0
4. 在 Frame 內建立 Header、Main-Content、Footer 子 Frame
5. 各子 Frame 設定對應 Auto Layout（見 3.6 速查表）
6. 優先引用 _Component-Library 中的元件 Instance
```

### 新建元件至 Component Library 時

```
1. 切換到 _Component-Library Page
2. 在對應 Section（[Atoms] / [Molecules] / [Organisms]）中建立 Frame
3. 設定 Auto Layout（見 3.4 元件 Frame 模板規格）
4. 套用 Figma Variables 至顏色、間距屬性
5. create_component_from_node 將 Frame 轉為 Master Component
6. 命名：{類型}/{變體}（如 Button/Primary）
```

---

## 版本記錄

| 版本 | 日期 | 變更說明 |
|------|------|---------|
| v1.0 | 2026-03-06 | 初始建立（US-146，Sprint 55） |
