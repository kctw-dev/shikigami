# Component Library 規格文件 — Button / Input / Card

**建立日期**：2026-03-06
**關聯 ADR**：ADR-015（Figma 整合取代 SSD 管線，Accepted）
**關聯 Story**：US-148（Sprint 55）
**依賴文件**：
- `docs/guides/figma-mcp-setup.md`（MCP Server 選型與安裝指南）
- `docs/design/design-tokens.json`（Design Tokens 色彩與間距規格）
- `docs/design/figma-structure-guide.md`（US-146 Layer 命名規則，建立後參照）
**版本**：v1.0

---

## 概覽

本文件定義 Shikigami 設計系統 Component Library 的三個基礎元件規格：**Button**、**Input**、**Card**。

每個元件的規格包含：
1. 元件屬性（尺寸、狀態、變體）
2. Auto Layout 設定
3. Figma Variable 綁定（對應 design-tokens.json）
4. MCP 操作步驟（使用 claude-talk-to-figma-mcp 工具依序執行）

**重要說明**：AC1、AC2、AC3 均為動態 AC，需要在 Figma Desktop App 開啟且 claude-talk-to-figma-mcp Plugin 已連接的環境中執行。本文件提供完整操作指引，動態驗證由使用者在本地環境完成。

---

## Layer 命名規則（US-146 前置規範）

> 注意：US-146（`docs/design/figma-structure-guide.md`）為本 Story 的並行 Story，若尚未建立，以下命名規則為臨時定義，US-146 完成後以 figma-structure-guide.md 為準。

| 物件類型 | 命名格式 | 範例 |
|---------|---------|------|
| Component（主元件） | `{ComponentName}/{Variant}` | `Button/Primary`、`Button/Secondary` |
| Component Set（元件集合） | `{ComponentName}` | `Button`、`Input`、`Card` |
| Component Property | `{property-name}` | `variant`、`size`、`state` |
| Auto Layout Frame（元件內部） | `{semantic-role}` | `icon-left`、`label`、`container` |
| Variable 名稱 | `color/{group}/{shade}` | `color/primary/500`、`color/neutral/0` |

**Component Library Page**：所有三個元件均建立於 Figma 文件的 **"Component Library"** Page（若 Page 不存在，先透過 `create_page` 工具建立）。

---

## 1. Button 元件

### 1.1 元件屬性

| 屬性 | 類型 | 值 |
|-----|------|---|
| **名稱** | — | `Button` |
| **Layer 路徑** | — | Component Library Page / Button |
| **變體（variant）** | Component Property | `Primary`、`Secondary`、`Danger`、`Ghost` |
| **尺寸（size）** | Component Property | `sm`、`md`（預設）、`lg` |
| **狀態（state）** | Component Property | `default`、`hover`、`active`、`disabled` |

**各尺寸規格**：

| 尺寸 | 最小寬度 | 高度 | Padding（水平） | Padding（垂直） | 字型大小 |
|------|---------|------|----------------|----------------|---------|
| `sm` | 80px | 32px | 12px | 6px | 14px（`typography.fontSize.sm`） |
| `md` | 120px | 40px | 16px | 8px | 16px（`typography.fontSize.base`） |
| `lg` | 160px | 48px | 24px | 12px | 18px（`typography.fontSize.lg`） |

**各變體顏色規格**：

| 變體 | 背景色 Token | 文字色 Token | 邊框色 Token | Hover 背景 Token |
|-----|------------|------------|------------|----------------|
| `Primary` | `color/primary/500` | `color/neutral/0` | 無 | `color/primary/600` |
| `Secondary` | `color/neutral/100` | `color/secondary/700` | `color/neutral/200` | `color/neutral/200` |
| `Danger` | `color/danger/500` | `color/neutral/0` | 無 | `color/danger/700` |
| `Ghost` | 透明 | `color/primary/500` | 無 | `color/primary/50` |

### 1.2 Auto Layout 設定

| 設定項目 | 值 | 說明 |
|---------|---|------|
| **方向（layoutMode）** | HORIZONTAL | 水平排列（icon + label） |
| **主軸對齊（primaryAxisAlignItems）** | CENTER | 水平置中 |
| **交叉軸對齊（counterAxisAlignItems）** | CENTER | 垂直置中 |
| **間距（itemSpacing）** | 8px（`spacing.2`） | icon 與 label 之間的間距 |
| **Padding 上下（paddingTop / paddingBottom）** | 依尺寸（見 1.1） | — |
| **Padding 左右（paddingLeft / paddingRight）** | 依尺寸（見 1.1） | — |
| **最小寬度（minWidth）** | 依尺寸（見 1.1） | 確保按鈕不過窄 |
| **圓角（cornerRadius）** | 6px（`borderRadius.md`） | 按鈕邊角 |

### 1.3 Figma Variable 綁定

每個 Button 變體的以下屬性須綁定 Figma Variable（使用 `apply_variable_to_node` 工具）：

| 屬性 | Variable 路徑 | 對應 Token |
|-----|-------------|----------|
| 背景填色（Primary 變體） | `color/primary/500` | `color.primary.500` = `#3b82f6` |
| 文字顏色（Primary 變體） | `color/neutral/0` | `color.neutral.0` = `#ffffff` |
| 背景填色（Secondary 變體） | `color/neutral/100` | `color.neutral.100` = `#f3f4f6` |
| 文字顏色（Secondary 變體） | `color/secondary/700` | `color.secondary.700` = `#334155` |
| 邊框顏色（Secondary 變體） | `color/neutral/200` | `color.neutral.200` = `#e5e7eb` |
| 背景填色（Danger 變體） | `color/danger/500` | `color.danger.500` = `#ef4444` |
| 文字顏色（Ghost 變體） | `color/primary/500` | `color.primary.500` = `#3b82f6` |

**AC2 最低要求**：Button 元件至少一個顏色屬性（建議 Primary 變體背景色）已綁定 Figma Variable `color/primary/500`。

### 1.4 MCP 操作步驟（AC1 + AC2 + AC3）

#### 步驟 0：確保環境就緒

```
確認環境：
1. Figma Desktop App 已開啟並登入
2. claude-talk-to-figma-mcp Plugin 已連接（Plugin UI 顯示 Connected）
3. claude-talk-to-figma-mcp CLI Server 已啟動
4. Claude Code MCP 連接正常（/mcp 指令可見 claude-talk-to-figma 工具）
```

#### 步驟 1：切換至 Component Library Page

使用 `set_current_page` 工具切換至 Component Library Page（若 Page 不存在，先使用 `create_page` 建立）：

```
請透過 claude-talk-to-figma MCP：
1. 先使用 get_pages 工具查看目前文件有哪些 Page
2. 若沒有 "Component Library" Page，使用 create_page 工具建立，命名為 "Component Library"
3. 使用 set_current_page 工具切換至 "Component Library" Page
```

#### 步驟 2：確認或建立 Figma Variables

先確認 Variables 是否已存在，再建立元件：

```
請透過 claude-talk-to-figma MCP 使用 get_variables 工具，
確認是否已有名為 "color/primary/500" 的 Variable。

若不存在，使用 set_variable 工具建立以下 Variables：
- 名稱：color/primary/500，值：#3b82f6，類型：COLOR
- 名稱：color/neutral/0，值：#ffffff，類型：COLOR
- 名稱：color/neutral/100，值：#f3f4f6，類型：COLOR
- 名稱：color/secondary/700，值：#334155，類型：COLOR
- 名稱：color/neutral/200，值：#e5e7eb，類型：COLOR
- 名稱：color/danger/500，值：#ef4444，類型：COLOR
```

#### 步驟 3：建立 Button Primary 元件（md 尺寸）

```
請透過 claude-talk-to-figma MCP，建立 Button/Primary 元件：

1. 使用 create_frame 建立 Frame：
   - 名稱：Button/Primary
   - 寬度：120px，高度：40px
   - 位置：(0, 0)

2. 使用 set_auto_layout 設定 Auto Layout：
   - 方向：HORIZONTAL
   - primaryAxisAlignItems：CENTER
   - counterAxisAlignItems：CENTER
   - itemSpacing：8
   - paddingTop：8，paddingBottom：8
   - paddingLeft：16，paddingRight：16

3. 在 Frame 內使用 create_text 建立文字層：
   - 內容："Button"
   - fontSize：16
   - fontWeight：600

4. 使用 set_fill_color 設定 Frame 背景色為 #3b82f6（暫定，後續綁定 Variable）

5. 使用 set_corner_radius 設定圓角：6px

6. 使用 apply_variable_to_node 將 color/primary/500 Variable 綁定至 Frame 的 fills 屬性

7. 使用 create_component_from_node 將此 Frame 轉換為 Figma Component
   （或使用 set_node_properties 設定節點類型為 COMPONENT）
```

**驗證**：Component Library Page 中出現名為 `Button/Primary` 的 Figma Component，背景色已綁定 Variable。

---

## 2. Input 元件

### 2.1 元件屬性

| 屬性 | 類型 | 值 |
|-----|------|---|
| **名稱** | — | `Input` |
| **Layer 路徑** | — | Component Library Page / Input |
| **狀態（state）** | Component Property | `default`、`focus`、`error`、`disabled` |
| **有無 Label** | Component Property | `with-label`、`no-label` |

**規格**：

| 項目 | 值 | Token |
|-----|---|-------|
| 寬度 | 320px（預設彈性寬度） | — |
| 高度（Input 框） | 40px | — |
| 邊框寬度 | 1px | — |
| 圓角 | 4px | `borderRadius.base` |
| 字型大小 | 16px | `typography.fontSize.base` |
| Placeholder 文字色 | `#9ca3af` | `color.neutral.400` |
| 內文字色 | `#0f172a` | `color.secondary.900` |

**各狀態顏色規格**：

| 狀態 | 背景色 Token | 邊框色 Token | 說明 |
|-----|------------|------------|------|
| `default` | `color/neutral/100` | `color/neutral/200` | 預設輸入框 |
| `focus` | `color/neutral/0` | `color/primary/500` | 聚焦時邊框變藍 |
| `error` | `color/danger/50` | `color/danger/500` | 錯誤狀態 |
| `disabled` | `color/neutral/100` | `color/neutral/200` | 停用狀態，opacity 0.5 |

### 2.2 Auto Layout 設定

| 設定項目 | 值 | 說明 |
|---------|---|------|
| **方向（layoutMode）** | VERTICAL | 垂直排列（label + input frame） |
| **主軸對齊（primaryAxisAlignItems）** | MIN | 頂部對齊 |
| **交叉軸對齊（counterAxisAlignItems）** | STRETCH | 寬度延伸填滿 |
| **間距（itemSpacing）** | 6px（`spacing.1.5`，近似 `spacing.2`） | Label 與輸入框的間距 |
| **Input 框內部 Padding 左右** | 12px（`spacing.3`） | — |
| **Input 框內部 Padding 上下** | 8px（`spacing.2`） | — |

**內部結構**（Auto Layout 子層）：
```
Input（VERTICAL Auto Layout）
├── label-text（Label 文字層）
└── input-box（輸入框 Frame，HORIZONTAL Auto Layout）
    ├── placeholder-text（Placeholder 文字層）
    └── [icon-right]（選用，右側圖示）
```

### 2.3 Figma Variable 綁定

| 屬性 | Variable 路徑 | 對應 Token |
|-----|-------------|----------|
| 輸入框背景色（default 狀態） | `color/neutral/100` | `color.neutral.100` = `#f3f4f6` |
| 邊框顏色（default 狀態） | `color/neutral/200` | `color.neutral.200` = `#e5e7eb` |
| 邊框顏色（focus 狀態） | `color/primary/500` | `color.primary.500` = `#3b82f6` |
| 邊框顏色（error 狀態） | `color/danger/500` | `color.danger.500` = `#ef4444` |
| Placeholder 文字色 | `color/neutral/400` | `color.neutral.400` = `#9ca3af` |

**AC2 最低要求**：Input 元件至少一個顏色屬性（建議 default 狀態邊框色）已綁定 Figma Variable `color/neutral/200`。

### 2.4 MCP 操作步驟（AC1 + AC2）

```
請透過 claude-talk-to-figma MCP，在 Component Library Page 建立 Input/Default 元件：

1. 使用 create_frame 建立外框：
   - 名稱：Input/Default
   - 寬度：320px，高度：64px（含 Label：20px + gap 6px + 框 40px）
   - 位置：(200, 0)（與 Button 水平錯開）

2. 使用 set_auto_layout 設定 Auto Layout：
   - 方向：VERTICAL
   - itemSpacing：6
   - paddingTop：0，paddingBottom：0，paddingLeft：0，paddingRight：0

3. 在外框內建立 label-text 文字層：
   - 內容："Label"
   - fontSize：14，fontWeight：500
   - 文字色：#334155

4. 在外框內建立 input-box Frame：
   - 高度：40px
   - 設定 Auto Layout：HORIZONTAL，paddingLeft/Right：12，paddingTop/Bottom：8
   - 背景色：#f3f4f6（暫定，後綁 Variable）
   - 邊框：1px solid #e5e7eb
   - 圓角：4px

5. 在 input-box 內建立 placeholder-text 文字層：
   - 內容："請輸入..."
   - fontSize：16
   - 文字色：#9ca3af

6. 使用 apply_variable_to_node 將以下 Variable 綁定至對應節點：
   - input-box 背景色 → color/neutral/100
   - input-box 邊框色 → color/neutral/200

7. 使用 create_component_from_node 將 Input/Default Frame 轉換為 Figma Component
```

**驗證**：Component Library Page 中出現名為 `Input/Default` 的 Figma Component，邊框色已綁定 Variable。

---

## 3. Card 元件

### 3.1 元件屬性

| 屬性 | 類型 | 值 |
|-----|------|---|
| **名稱** | — | `Card` |
| **Layer 路徑** | — | Component Library Page / Card |
| **變體（variant）** | Component Property | `Default`、`Elevated`、`Outlined` |
| **有無 Header Image** | Component Property | `with-image`、`no-image` |

**規格**：

| 項目 | 值 | Token |
|-----|---|-------|
| 寬度 | 320px（預設，彈性） | — |
| 最小高度 | 200px | — |
| 圓角 | 8px | `borderRadius.lg` |
| 內距（Padding） | 24px | `spacing.6` |
| 背景色（Default） | `#ffffff` | `color.neutral.0` |
| 背景色（帶底色） | `#f1f5f9` | `color.secondary.100` |
| 邊框色（Outlined） | `#e5e7eb` | `color.neutral.200` |

**各變體規格**：

| 變體 | 背景色 Token | 邊框 | 陰影 |
|-----|------------|------|------|
| `Default` | `color/neutral/0` | 無 | `shadow/base`（0 1px 3px rgba(0,0,0,0.1)） |
| `Elevated` | `color/neutral/0` | 無 | `shadow/md`（0 4px 6px rgba(0,0,0,0.1)） |
| `Outlined` | `color/neutral/0` | 1px solid `color/neutral/200` | 無 |

### 3.2 Auto Layout 設定

| 設定項目 | 值 | 說明 |
|---------|---|------|
| **方向（layoutMode）** | VERTICAL | 垂直排列（header + content + footer） |
| **主軸對齊（primaryAxisAlignItems）** | MIN | 頂部對齊 |
| **交叉軸對齊（counterAxisAlignItems）** | STRETCH | 寬度填滿 |
| **間距（itemSpacing）** | 16px（`spacing.4`） | 卡片內部元素間距 |
| **Padding 全向** | 24px（`spacing.6`） | 卡片內距 |
| **最小高度** | 200px | — |

**內部結構**（Auto Layout 子層）：
```
Card（VERTICAL Auto Layout）
├── card-header（HORIZONTAL Auto Layout）
│   ├── card-title（文字層，主標題）
│   └── card-badge（選用，徽章）
├── card-content（文字層，內文描述）
└── card-footer（HORIZONTAL Auto Layout，選用）
    └── action-button（Button/Primary Instance）
```

### 3.3 Figma Variable 綁定

| 屬性 | Variable 路徑 | 對應 Token |
|-----|-------------|----------|
| 卡片背景色（所有變體） | `color/neutral/0` | `color.neutral.0` = `#ffffff` |
| 邊框顏色（Outlined 變體） | `color/neutral/200` | `color.neutral.200` = `#e5e7eb` |
| 標題文字色 | `color/secondary/900` | `color.secondary.900` = `#0f172a` |
| 內文文字色 | `color/secondary/500` | `color.secondary.500` = `#64748b` |

**AC2 最低要求**：Card 元件至少一個顏色屬性（建議背景色）已綁定 Figma Variable `color/neutral/0`。

### 3.4 MCP 操作步驟（AC1 + AC2）

```
請透過 claude-talk-to-figma MCP，在 Component Library Page 建立 Card/Default 元件：

1. 使用 create_frame 建立 Card Frame：
   - 名稱：Card/Default
   - 寬度：320px，高度：200px
   - 位置：(600, 0)（與 Button、Input 水平錯開）

2. 使用 set_auto_layout 設定 Auto Layout：
   - 方向：VERTICAL
   - primaryAxisAlignItems：MIN
   - counterAxisAlignItems：STRETCH
   - itemSpacing：16
   - paddingTop：24，paddingBottom：24
   - paddingLeft：24，paddingRight：24

3. 使用 set_fill_color 設定背景色（暫定 #ffffff，後綁 Variable）

4. 使用 set_corner_radius 設定圓角：8px

5. 在 Frame 內建立 card-header Frame：
   - 使用 create_frame，設定 HORIZONTAL Auto Layout
   - 建立 card-title 文字層：內容 "Card Title"，fontSize：18，fontWeight：600，色 #0f172a

6. 建立 card-content 文字層：
   - 內容："Card description text goes here."
   - fontSize：14，色 #64748b

7. 使用 apply_variable_to_node 將以下 Variable 綁定至對應節點：
   - Card Frame 背景色 → color/neutral/0
   - card-title 文字色 → color/secondary/900
   - card-content 文字色 → color/secondary/500

8. 使用 create_component_from_node 將 Card/Default Frame 轉換為 Figma Component
```

**驗證**：Component Library Page 中出現名為 `Card/Default` 的 Figma Component，背景色已綁定 Variable。

---

## 4. AC3 驗證：AI 透過 MCP 引用元件 Instance

AC3 要求 Claude Code 能透過 Figma MCP 以 Component Instance 方式引用三個元件。以下為完整操作步驟：

### 4.1 前置條件

- AC1 已完成：Button、Input、Card 三個 Figma Component 存在於 Component Library Page
- Figma Component 的 Node ID 已知（可透過 `get_local_components` 工具取得）

### 4.2 建立測試驗證 Frame

```
請透過 claude-talk-to-figma MCP，進行 AC3 元件引用驗證：

步驟 1：讀取 Component Library
使用 get_local_components 工具，列出所有本地元件，
確認 Button/Primary、Input/Default、Card/Default 三個 Component 存在，
並記錄各自的 Component Key（component key，非 node id）。

步驟 2：切換至 Sprint Page
使用 get_pages 確認或建立 Sprint-55-Component-PoC Page，
使用 set_current_page 切換至該 Page。

步驟 3：建立 PoC 驗證 Frame
使用 create_frame 建立：
- 名稱：US-148-AC3-Verification
- 寬度：1440px，高度：900px
- 位置：(0, 0)
設定 Auto Layout：HORIZONTAL，itemSpacing：48，padding：48。

步驟 4：建立 Button Instance
使用 create_component_instance 工具：
- 傳入 Button/Primary 的 component key
- 在 US-148-AC3-Verification Frame 內建立 Instance

步驟 5：建立 Input Instance
使用 create_component_instance 工具：
- 傳入 Input/Default 的 component key
- 在 US-148-AC3-Verification Frame 內建立 Instance

步驟 6：建立 Card Instance
使用 create_component_instance 工具：
- 傳入 Card/Default 的 component key
- 在 US-148-AC3-Verification Frame 內建立 Instance

步驟 7：讀取截圖確認
使用 export_node_as_image 工具，將 US-148-AC3-Verification Frame 匯出為 PNG，
確認截圖中三個元件 Instance 均可見。
```

### 4.3 AC3 通過標準

以下三項均滿足時，AC3 判定為通過：

- [ ] `get_local_components` 回傳清單包含 Button、Input、Card 三個 Component
- [ ] `create_component_instance` 分別對三個元件成功呼叫，無報錯
- [ ] US-148-AC3-Verification Frame 中，三個 Component Instance 在 Figma Canvas 中可目視確認

---

## 5. 完整驗證清單

### AC1 驗證清單：三個元件建立

- [ ] Figma Component Library Page 已存在
- [ ] `Button/Primary` Component 已建立，命名符合規則
- [ ] `Input/Default` Component 已建立，命名符合規則
- [ ] `Card/Default` Component 已建立，命名符合規則
- [ ] 三個元件均位於 Component Library Page（非其他 Page）

### AC2 驗證清單：Auto Layout 與 Variable 綁定

**Button**：
- [ ] Button 已設定 Auto Layout（HORIZONTAL，gap 8px，padding 16px 水平 / 8px 垂直）
- [ ] Button 背景色已綁定 Variable `color/primary/500`（`#3b82f6`）

**Input**：
- [ ] Input 外框已設定 Auto Layout（VERTICAL，gap 6px）
- [ ] Input 輸入框內部已設定 Auto Layout（HORIZONTAL，padding 12px 水平 / 8px 垂直）
- [ ] Input 邊框色已綁定 Variable `color/neutral/200`（`#e5e7eb`）

**Card**：
- [ ] Card 已設定 Auto Layout（VERTICAL，gap 16px，padding 24px 全向）
- [ ] Card 背景色已綁定 Variable `color/neutral/0`（`#ffffff`）

### AC3 驗證清單：AI 可引用元件

- [ ] `get_local_components` 可列出三個 Component
- [ ] `create_component_instance` 呼叫 Button Component Key 成功，Instance 出現在 Frame
- [ ] `create_component_instance` 呼叫 Input Component Key 成功，Instance 出現在 Frame
- [ ] `create_component_instance` 呼叫 Card Component Key 成功，Instance 出現在 Frame
- [ ] 三個 Instance 在 Figma Canvas 可目視確認

---

## 6. 動態 AC 執行環境說明

**本文件所有 MCP 操作步驟均需在以下環境中執行：**

```
必要環境：
1. Figma Desktop App（macOS 或 Windows）已開啟並登入
2. Figma 文件已開啟（需有 Component Library Page 的寫入權限）
3. claude-talk-to-figma-mcp CLI Server 已在背景執行（預設 ws://localhost:3000）
4. Figma Desktop 中 Talk to Figma Plugin 已連接至 CLI Server
5. Claude Code MCP 設定包含 claude-talk-to-figma Server

詳細安裝步驟請參閱：docs/guides/figma-mcp-setup.md
```

**CI 環境不適用**：Figma Plugin API 需要 Figma Desktop App 執行環境，純雲端 CI（GitHub Actions 等）無法執行 AC1、AC2、AC3 動態驗證。所有動態驗證均需開發者在本地工作站手動觸發。

---

## 7. Design Token 對照表

以下為本文件使用的 Figma Variable 名稱與 design-tokens.json 值的完整對照：

| Figma Variable 名稱 | Token 路徑 | 色碼值 | 用途 |
|------------------|----------|-------|-----|
| `color/primary/500` | `color.primary.500` | `#3b82f6` | Button Primary 背景色、Input focus 邊框色 |
| `color/primary/600` | `color.primary.600` | `#2563eb` | Button Primary hover 背景色 |
| `color/primary/50` | `color.primary.50` | `#eff6ff` | Button Ghost hover 背景色 |
| `color/secondary/700` | `color.secondary.700` | `#334155` | Button Secondary 文字色 |
| `color/secondary/900` | `color.secondary.900` | `#0f172a` | Card 標題文字色 |
| `color/secondary/500` | `color.secondary.500` | `#64748b` | Card 內文文字色 |
| `color/danger/500` | `color.danger.500` | `#ef4444` | Button Danger 背景色、Input error 邊框色 |
| `color/danger/700` | `color.danger.700` | `#b91c1c` | Button Danger hover 背景色 |
| `color/danger/50` | `color.danger.50` | `#fef2f2` | Input error 背景色 |
| `color/neutral/0` | `color.neutral.0` | `#ffffff` | Card 背景色、Button 文字色 |
| `color/neutral/100` | `color.neutral.100` | `#f3f4f6` | Input 背景色、Button Secondary 背景色 |
| `color/neutral/200` | `color.neutral.200` | `#e5e7eb` | Input 邊框色、Card Outlined 邊框色 |
| `color/neutral/400` | `color.neutral.400` | `#9ca3af` | Placeholder 文字色 |

---

## 8. 參考資料

- [ADR-015：UIUX 管線架構轉型 — Figma 整合](../adr/ADR-015-figma-integration.md)
- [docs/guides/figma-mcp-setup.md](../guides/figma-mcp-setup.md)（MCP Server 安裝指南）
- [docs/design/design-tokens.json](design-tokens.json)（Design Tokens 規格）
- [claude-talk-to-figma-mcp npm 套件](https://www.npmjs.com/package/claude-talk-to-figma-mcp)
- [Figma Plugin API — Components](https://www.figma.com/plugin-docs/api/ComponentNode/)
- [Figma Plugin API — Variables](https://www.figma.com/plugin-docs/api/figma-variables/)
- [Figma Plugin API — Auto Layout](https://www.figma.com/plugin-docs/api/properties/nodes-autolayout/)
