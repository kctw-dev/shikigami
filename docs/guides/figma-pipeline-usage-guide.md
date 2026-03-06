# Figma 管線使用指南

**建立日期**：2026-03-06
**關聯 ADR**：ADR-015（Figma 整合取代 SSD 管線，Accepted）
**關聯 Story**：US-152（Sprint 56）
**版本**：v1.0

---

## 概覽

本指南為 Figma 整合 UIUX 管線的端對端使用手冊，適用於首次或日常使用 Figma 管線進行前端設計的開發者。閱讀本指南後，你將能夠：

1. 從前端 User Story 開始，填寫 SDD Figma 欄位
2. 依命名規則在 Figma 中建立設計稿（Page / Frame / Layer）
3. 選用 Component Library 中的元件並以 Instance 方式引用
4. 將 Design Token 綁定至 Figma Variables
5. 呼叫 MCP 工具讓 AI 生成帶 Auto Layout 的 Frame
6. 提交 Vision Critic 審查並處理退件

**架構總覽（雙層 MCP）**：

| 層次 | MCP Server | 用途 |
|------|-----------|------|
| 寫入層 | `claude-talk-to-figma-mcp`（WebSocket） | 建立 Frame、設定 Auto Layout、引用元件、套用 Variable |
| 讀取層 | 官方 Figma MCP Server（SSE） | 截圖讀取、設計脈絡讀取、Vision Critic 審查輸入 |

**前置條件**：本地 Figma 整合環境已依 `docs/guides/figma-desktop-verification-sop.md` 設定完成。

---

## 端對端工作流程（AC1）

以下為 Figma 管線的標準作業流程，每個前端 Story 均依此順序執行。

---

### 步驟一：前端 Story 接收與 SDD 模板填寫

**觸發時機**：接收到含前端介面的 User Story 後，開始設計前優先填寫 SDD。

**操作**：

1. 在 `docs/design/` 目錄下建立 SDD 檔案，命名格式：`sdd-US-{N}-{功能描述}.md`
2. 使用 `docs/templates/sdd-frontend-template.md` 作為模板
3. 填寫基本資訊（Story ID、Issue、Sprint）
4. **Figma 設計稿區段**（強制填寫欄位，ADR-015 Phase 1 起）：

| 欄位 | 說明 |
|------|------|
| **Figma Frame URL** | 設計完成後貼入 Figma 分享連結 |
| **Frame 名稱** | 依命名規則填寫：`{StoryID}-{功能描述}-{平台}` |
| **所在 Page** | 填寫 Sprint Page 名稱：`Sprint-{N}-{功能名}` |
| **最後更新日期** | 每次更新設計稿時同步更新 |

> **Phase 1 規則**：Figma Frame URL 欄位已填寫（非空）即滿足 Figma Gate 要求。Phase 2（Vision Critic 上線後）需通過自動審查。

---

### 步驟二：Figma 文件建立（Page / Frame / Layer 命名）

**觸發時機**：SDD 填寫完成後，開始在 Figma 中建立設計稿。

#### 2.1 確保環境就緒

依以下順序啟動工作環境（順序不可顛倒）：

```
1. 啟動 Figma Desktop App（確認已登入）
2. 在 Figma Desktop 開啟目標 Figma 文件
3. 終端機啟動 MCP Server：
   $ claude-talk-to-figma-mcp
   等待顯示 "Waiting for Figma Plugin connection..."
4. 在 Figma Desktop 執行 Talk to Figma Plugin
   填入 Server URL：ws://localhost:3000
   點擊 Connect，等待顯示 "Connected"
5. 啟動 Claude Code（確認 /mcp 可見 claude-talk-to-figma Server）
```

#### 2.2 建立或切換至 Sprint Page

在 Claude Code 中輸入：

```
請透過 claude-talk-to-figma MCP：
1. 使用 get_pages 查看目前 Page 清單
2. 若尚無此 Sprint 的 Page，使用 create_page 建立：
   名稱格式：Sprint-{N}-{功能名}（例：Sprint-57-UserProfile）
3. 使用 set_current_page 切換至目標 Sprint Page
```

**Page 命名規則**：

| 類型 | 命名格式 | 範例 |
|------|---------|------|
| 固定系統 Page | 底線開頭 | `_Component-Library`、`_Design-Tokens`、`_Archive` |
| Sprint Page | `Sprint-{N}-{功能名}` | `Sprint-57-UserProfile` |

#### 2.3 建立 User Story Frame

在 Claude Code 中輸入：

```
請透過 claude-talk-to-figma MCP，建立 Desktop Frame：
- create_frame：名稱 = US-{N}-{功能描述}-Desktop，寬度 1440px，高度 900px
- set_auto_layout：方向 VERTICAL，Gap 0，Padding 0
- 建立 Header（64px 高）、Main-Content（Hug 高度）子 Frame
- Header 設定 Horizontal Auto Layout，Gap 16px，左右 Padding 24px
- Main-Content 設定 Vertical Auto Layout，Gap 48px，上下 Padding 80px
```

**Frame 命名規則**（依 `figma-structure-guide.md`）：

| 類型 | 格式 | 範例 |
|------|------|------|
| Desktop Frame | `{StoryID}-{功能描述}-Desktop` | `US-157-User-Profile-Desktop` |
| Mobile Frame | `{StoryID}-{功能描述}-Mobile` | `US-157-User-Profile-Mobile` |
| PoC 測試 Frame | `POC-{StoryID}-{描述}-{平台}` | `POC-US-147-FrameGeneration-Desktop` |

#### 2.4 Layer 命名原則

| 類型 | 正確命名 | 禁止命名 |
|------|---------|---------|
| Frame | `US-157-User-Profile-Desktop` | `Frame 1`、`Frame` |
| Group | `Login-Form`、`Header`、`Card-List` | `Group`、`Group 1`、`Container` |
| 文字層 | `Page-Title`、`Input-Label`、`Error-Message` | `Text`、`Text 1`、`Label` |
| Component | `Button/Primary`、`Input/Default` | `button`、`Primary Button` |

---

### 步驟三：Component Library 元件選用

**觸發時機**：Frame 骨架建立後，開始填入 UI 元件。

#### 3.1 查看可用元件

在 Claude Code 中輸入：

```
請透過 claude-talk-to-figma MCP，使用 get_local_components 工具
列出目前 Figma 文件中所有 Component Library 中的元件。
```

目前 Component Library 包含以下基礎元件（Sprint 55 US-148 定義）：

| 元件名稱 | 位置 | 變體 |
|---------|------|------|
| `Button/Primary` | `_Component-Library > [Atoms]` | Primary、Secondary、Danger、Ghost |
| `Input/Default` | `_Component-Library > [Atoms]` | default、focus、error、disabled |
| `Card/Default` | `_Component-Library > [Molecules]` | Default、Elevated、Outlined |

#### 3.2 引用元件 Instance

在 Claude Code 中輸入：

```
請透過 claude-talk-to-figma MCP：
1. 使用 get_local_components 取得 Button/Primary 的 Component Key
2. 使用 create_component_instance 在目標 Frame 內建立 Button Instance
   （傳入 Component Key，而非重新建立形狀）
3. 若同一 Frame 有多個相同元件，使用 set_node_properties 為每個
   Instance 加入上下文後綴，例如：Button/Primary (Submit)
```

**重要原則**：引用 Component Instance 而非重新繪製形狀，確保設計一致性且可統一更新。

---

### 步驟四：Design Token 綁定（Figma Variables）

**觸發時機**：元件與 Frame 建立後，套用 Design Token 確保符合設計規範。

#### 4.1 確認 Variables 已存在

在 Claude Code 中輸入：

```
請透過 claude-talk-to-figma MCP，使用 get_variables 工具
確認以下 Design Token Variables 是否已存在，若不存在請建立：
- color/primary/500（#3b82f6）
- color/neutral/0（#ffffff）
- color/secondary/900（#0f172a）
- color/background/primary（#f8fafc）
```

#### 4.2 套用 Variable 至節點

在 Claude Code 中輸入：

```
請透過 claude-talk-to-figma MCP，使用 apply_variable_to_node 工具：
- 將 color/primary/500 套用至 [節點名稱] 的 fills 屬性
- 禁止使用 set_fill_color 直接設定 hex 值
```

**Variable 命名對照表**（Figma Variable 名稱 ↔ Design Token）：

| Figma Variable 名稱 | Token 路徑 | 色碼值 | 用途 |
|------------------|----------|-------|-----|
| `color/primary/500` | `color.primary.500` | `#3b82f6` | Button Primary 背景、Input focus 邊框 |
| `color/primary/600` | `color.primary.600` | `#2563eb` | Button Primary hover 背景 |
| `color/secondary/900` | `color.secondary.900` | `#0f172a` | 標題文字色 |
| `color/secondary/700` | `color.secondary.700` | `#334155` | 主要內文色 |
| `color/secondary/500` | `color.secondary.500` | `#64748b` | 次要文字色 |
| `color/neutral/0` | `color.neutral.0` | `#ffffff` | 卡片背景、按鈕文字色 |
| `color/neutral/100` | `color.neutral.100` | `#f3f4f6` | Input 背景、Button Secondary 背景 |
| `color/neutral/200` | `color.neutral.200` | `#e5e7eb` | 邊框預設色 |
| `color/neutral/400` | `color.neutral.400` | `#9ca3af` | Placeholder 文字色 |
| `color/danger/500` | `color.danger.500` | `#ef4444` | Button Danger 背景、Input error 邊框 |
| `color/background/primary` | `color.secondary.50` | `#f8fafc` | 頁面背景底色 |

**原則**：所有顏色屬性必須透過 `apply_variable_to_node` 綁定 Variable，禁止直接 hardcode hex 值。

---

### 步驟五：AI Frame 生成（MCP 工具呼叫）

**觸發時機**：需要 AI 根據 User Story 自動生成 Frame 骨架時。

#### 5.1 標準 Frame 生成提示範例

以下為讓 AI 生成完整 Frame 骨架的標準提示格式：

```
請透過 claude-talk-to-figma MCP，根據以下 User Story 生成 Figma Frame：

Story ID：US-{N}
功能描述：{功能的簡短說明}
目標平台：Desktop（1440px）

執行步驟：
1. 確認目前在 Sprint-{N}-{功能名} Page（若無則建立）
2. 確認 Figma Variables 已存在（color/primary/500、color/neutral/0 等）
3. create_frame：US-{N}-{功能描述}-Desktop，1440x900px
4. set_auto_layout：主 Frame VERTICAL，Gap 0，Padding 0
5. 建立 Header 子 Frame（64px，HORIZONTAL Auto Layout）
6. 在 Header 中 create_text：Page-Title，填入功能標題文字
7. 建立 Main-Content 子 Frame（VERTICAL Auto Layout，Gap 48px，Padding 80px）
8. 根據 User Story 功能目標，在 Main-Content 中建立對應 UI 區塊
9. 優先使用 get_local_components + create_component_instance 引用現有元件
10. 所有顏色屬性使用 apply_variable_to_node 綁定 Variable
```

#### 5.2 完整工具呼叫序列

| 步驟 | 工具 | 說明 |
|------|------|------|
| 1 | `get_document_info` | 確認文件資訊 |
| 2 | `get_pages` + `create_page` | 確認或建立 Sprint Page |
| 3 | `set_current_page` | 切換至目標 Page |
| 4 | `get_variables` + `set_variable` | 確認或建立 Design Token Variables |
| 5 | `create_frame` | 建立主 Frame |
| 6 | `set_auto_layout` | 設定 Vertical Auto Layout |
| 7 | `create_frame` + `set_auto_layout` | 建立 Header 子 Frame（Horizontal） |
| 8 | `create_text` | 在 Header 建立頁面標題 |
| 9 | `apply_variable_to_node` | 綁定 Header 背景色 Variable |
| 10 | `create_frame` + `set_auto_layout` | 建立 Main-Content 子 Frame（Vertical） |
| 11 | `get_local_components` | 取得 Component Key 清單 |
| 12 | `create_component_instance` | 引用 Button / Input / Card 元件 |
| 13 | `apply_variable_to_node` | 綁定所有節點顏色至 Variable |
| 14 | `export_node_as_image` | 讀取 Frame 截圖（Vision Critic 準備） |

---

### 步驟六：Vision Critic 審查（評分與退件處理）

**觸發時機**：Frame 設計完成後，提交 Vision Critic 審查。

#### 6.1 Phase 1（目前）— 截圖讀取驗證

**目前（ADR-015 Phase 1）**：Vision Critic PoC 規格已定義（見 `docs/design/vision-critic-poc-spec.md`），完整自動化審查在 Phase 2 上線。當前步驟：

1. 使用 MCP 讀取 Frame 截圖：

```
請透過 claude-talk-to-figma MCP，使用 export_node_as_image 工具
將 US-{N}-{功能描述}-Desktop Frame 匯出為 PNG 格式，
儲存至 docs/design/poc-screenshots/ 目錄。
```

2. 確認截圖可讀取且顯示正確的 Frame 結構（非空白）
3. 在 SDD 的 Figma Frame URL 欄位填入 Figma 分享連結

#### 6.2 Phase 2（Vision Critic 上線後）— 三維度評分

依 `docs/design/vision-critic-poc-spec.md` 定義的三維度評分模型：

| 維度 | 評分項目 | 閾值 |
|------|---------|------|
| 佈局一致性 | Auto Layout 結構、間距規則 | — |
| Design Token 符合度 | 顏色、字型、間距 Variable 綁定 | — |
| 元件規範符合度 | Button / Input / Card 規格匹配 | — |
| **綜合評分** | 三維度加權平均 | ≥80 PASS，60-79 CONDITIONAL，<60 FAIL |

**PASS（≥80 分）**：Story 可繼續進入實作階段。

**CONDITIONAL（60-79 分）**：與 Architect 確認後決定是否繼續；建議修正主要扣分項後重審。

**FAIL（<60 分）**：退件，依退件報告修正設計後重新提交 Vision Critic 審查。退件報告存放於 `docs/design/vision-critic-reviews/US-{N}-review-{date}.md`。

**退件處理流程**：

```
1. 讀取退件報告（docs/design/vision-critic-reviews/）
2. 確認失敗維度與具體扣分項目
3. 依修正建議使用 MCP 工具修正 Figma Frame
4. 重新觸發 Vision Critic 審查
```

---

## 快速參考卡（AC2）

### A. 常用 MCP 工具與用途對照

#### claude-talk-to-figma-mcp（寫入層）

| 工具名稱 | 類別 | 典型用途 | 常用參數 |
|---------|------|---------|---------|
| `create_frame` | 寫入 | 建立 Frame | `name`, `width`, `height`, `x`, `y` |
| `set_auto_layout` | 寫入 | 設定 Auto Layout | `layoutMode`, `itemSpacing`, `paddingTop/Bottom/Left/Right` |
| `create_component_instance` | 寫入 | 引用 Component Instance | `componentKey`（非 node ID） |
| `apply_variable_to_node` | 寫入 | 綁定 Design Token Variable | `nodeId`, `property`, `variableName` |
| `create_text` | 寫入 | 建立文字層 | `name`, `content`, `fontSize`, `fontWeight` |
| `set_text_content` | 寫入 | 修改文字內容 | `nodeId`, `content` |
| `set_fill_color` | 寫入 | 設定填充色（臨時用，最終須改 Variable） | `nodeId`, `r`, `g`, `b` |
| `set_corner_radius` | 寫入 | 設定圓角 | `nodeId`, `radius` |
| `set_stroke_color` | 寫入 | 設定邊框色 | `nodeId`, `r`, `g`, `b`, `strokeWeight` |
| `set_font_name` | 寫入 | 設定字型 | `nodeId`, `fontFamily` |
| `set_font_size` | 寫入 | 設定字級 | `nodeId`, `fontSize` |
| `set_font_weight` | 寫入 | 設定字重 | `nodeId`, `fontWeight` |
| `create_page` | 寫入 | 建立新 Page | `name` |
| `set_current_page` | 導覽 | 切換至指定 Page | `pageId` 或 `pageName` |
| `insert_child` | 結構 | 將子節點插入父節點 | `parentId`, `childId`, `index` |
| `move_node` | 寫入 | 移動節點位置 | `nodeId`, `x`, `y` |
| `resize_node` | 寫入 | 調整節點尺寸 | `nodeId`, `width`, `height` |
| `delete_node` | 寫入 | 刪除節點 | `nodeId` |
| `create_component_from_node` | 寫入 | 將 Frame 轉為 Component | `nodeId` |
| `set_variable` | 寫入 | 建立或修改 Variable | `name`, `value`, `type` |
| `get_document_info` | 讀取 | 取得文件資訊 | — |
| `get_pages` | 讀取 | 列出所有 Page | — |
| `get_node_info` | 讀取 | 讀取節點詳細屬性 | `nodeId` |
| `get_local_components` | 讀取 | 列出本地 Component | — |
| `get_variables` | 讀取 | 讀取 Variables 清單 | — |
| `export_node_as_image` | 讀取 | 匯出節點截圖 | `nodeId`, `format`, `scale` |

#### 官方 Figma MCP Server（讀取層）

| 工具名稱 | 用途 |
|---------|------|
| `get_screenshot` | 取得 Frame / 節點截圖（Vision Critic 使用） |
| `get_design_context` | 取得設計脈絡（元件樹、樣式資訊） |

---

### B. Figma 命名規則速查

| 物件類型 | 命名格式 | 正確範例 | 禁止範例 |
|---------|---------|---------|---------|
| Sprint Page | `Sprint-{N}-{功能名}` | `Sprint-57-UserProfile` | `Sprint57`、`sprint_57` |
| Desktop Frame | `{StoryID}-{功能描述}-Desktop` | `US-157-User-Profile-Desktop` | `Frame 1`、`US157-Profile` |
| Mobile Frame | `{StoryID}-{功能描述}-Mobile` | `US-157-User-Profile-Mobile` | `Mobile Frame` |
| PoC Frame | `POC-{StoryID}-{描述}-{平台}` | `POC-US-147-FrameGen-Desktop` | `PoC Frame` |
| Group | `{語意描述}`（Kebab-case） | `Login-Form`、`Header`、`Card-List` | `Group`、`Group 1`、`Container` |
| 文字層 | `{語意用途}` | `Page-Title`、`Input-Label` | `Text`、`Text 1` |
| Component（Master） | `{類型}/{變體}` | `Button/Primary`、`Input/Default` | `button`、`Primary Button` |
| Component Instance（多個同類） | `{Master名稱} ({上下文})` | `Button/Primary (Submit)` | `Button copy 1` |
| 歸檔 Frame | `{原名} [ARCHIVED-{YYYY-MM-DD}]` | `US-103-Flow [ARCHIVED-2026-03-15]` | 直接刪除 |

**命名錯誤案例快速修正**：

| 錯誤命名 | 正確命名 |
|---------|---------|
| `Frame 1` | `US-157-User-Profile-Desktop` |
| `Rectangle 3` | `Hero-Background` |
| `Group 2` | `Login-Form` |
| `Spring 55` | `Sprint-55-FigmaIntegration` |
| `US146-Overview` | `US-146-Overview-Desktop` |

---

### C. Design Token 變數名稱速查

**顏色 Variables（Figma Variable 名稱 ↔ 色碼值）**：

| 色彩群組 | Figma Variable 名稱 | 色碼值 | 典型用途 |
|---------|------------------|-------|---------|
| Primary | `color/primary/50` | `#eff6ff` | Ghost Button hover 背景 |
| Primary | `color/primary/100` | `#dbeafe` | 選取 / 高亮狀態 |
| Primary | `color/primary/500` | `#3b82f6` | 主要 CTA 按鈕背景 |
| Primary | `color/primary/600` | `#2563eb` | CTA hover 狀態 |
| Primary | `color/primary/700` | `#1d4ed8` | CTA active 按壓狀態 |
| Secondary | `color/secondary/50` | `#f8fafc` | 頁面背景底色 |
| Secondary | `color/secondary/500` | `#64748b` | 次要文字色 |
| Secondary | `color/secondary/700` | `#334155` | 主要內文色 |
| Secondary | `color/secondary/900` | `#0f172a` | 標題主色 |
| Danger | `color/danger/50` | `#fef2f2` | 錯誤訊息背景 |
| Danger | `color/danger/500` | `#ef4444` | 破壞性操作 CTA |
| Danger | `color/danger/700` | `#b91c1c` | 錯誤狀態文字色 |
| Neutral | `color/neutral/0` | `#ffffff` | 卡片 / 模態底色 |
| Neutral | `color/neutral/100` | `#f3f4f6` | 輸入框背景 |
| Neutral | `color/neutral/200` | `#e5e7eb` | 邊框預設色 |
| Neutral | `color/neutral/400` | `#9ca3af` | Placeholder 文字色 |
| Neutral | `color/neutral/800` | `#1f2937` | 深灰主要標題 |

**間距 Token（Figma Auto Layout 設定參考）**：

| Token 名稱 | 像素值 | Tailwind Class | 典型使用場景 |
|-----------|-------|---------------|------------|
| `spacing/xs` | 4 px | `p-1` | Icon 與文字微間距 |
| `spacing/sm` | 8 px | `p-2` | 表單內部元素、按鈕 Gap |
| `spacing/md` | 16 px | `p-4` | 行動版 Padding 標準 |
| `spacing/lg` | 24 px | `p-6` | 卡片 Padding、行動版區塊 Gap |
| `spacing/xl` | 32 px | `p-8` | 桌面版 Section Padding |
| `spacing/2xl` | 48 px | `p-12` | 桌面版頁面區塊 Gap |
| `spacing/3xl` | 64 px | `p-16` | Header 高度、英雄區塊 |
| `spacing/4xl` | 80 px | — | 桌面版 Main Content 上下 Padding |

**圓角 Token**：

| Token 名稱 | 值 | 用途 |
|-----------|---|------|
| `borderRadius.base` | 4px | 輸入框 |
| `borderRadius.md` | 6px | 按鈕、Badge |
| `borderRadius.lg` | 8px | 卡片 |
| `borderRadius.xl` | 12px | 大卡片 |
| `borderRadius.full` | 9999px | Pill Button、Avatar |

**Auto Layout 設定速查（常用場景）**：

| 場景 | 方向 | Gap | Padding |
|------|------|-----|---------|
| 桌面頁面最外層 Frame | VERTICAL | 0 | 0 |
| Header 內部 | HORIZONTAL | 16 px | 0 上下 / 24 左右 |
| 桌面 Main Content | VERTICAL | 48 px | 80 px 上下 / 0 左右 |
| 行動 Main Content | VERTICAL | 24 px | 16 px 四邊 |
| Button 內部 | HORIZONTAL | 8 px | 12 px 上下 / 24 px 左右 |
| Input 輸入框 | HORIZONTAL | 8 px | 12 px 上下 / 16 px 左右 |
| Card 內部 | VERTICAL | 16 px | 24 px 四邊 |

---

## 相關文件索引（AC3）

以下為 Figma 管線相關所有規格文件的導覽索引，按功能分類整理。

### Sprint 55 交付物（基礎規格）

| 文件 | Story | 內容說明 |
|------|-------|---------|
| [`docs/guides/figma-mcp-setup.md`](figma-mcp-setup.md) | US-145 | Figma MCP Server 選型與安裝指南（雙層架構決策、安裝步驟、驗證指令） |
| [`docs/design/figma-structure-guide.md`](../design/figma-structure-guide.md) | US-146 | Figma 文件結構指南（Page 架構、Frame / Layer / Component 命名規則） |
| [`docs/design/component-library-spec.md`](../design/component-library-spec.md) | US-148 | Component Library 規格文件（Button / Input / Card 完整 Auto Layout 與 Variable 設定） |
| [`docs/design/poc-frame-generation-guide.md`](../design/poc-frame-generation-guide.md) | US-147 | AI 生成 Frame PoC 執行計畫（完整 MCP 工具呼叫序列、截圖讀取步驟） |

### Sprint 56 交付物（操作文件）

| 文件 | Story | 內容說明 |
|------|-------|---------|
| [`docs/guides/figma-desktop-verification-sop.md`](figma-desktop-verification-sop.md) | US-150 | Figma Desktop 本地驗證環境 SOP（逐步安裝指引、Sprint 55 動態 AC 驗證清單、常見問題排除） |
| [`docs/design/vision-critic-poc-spec.md`](../design/vision-critic-poc-spec.md) | US-151 | Vision Critic PoC 規格（三維度評分模型、MCP 工具呼叫序列、退件報告格式） |
| [`docs/guides/figma-pipeline-usage-guide.md`](figma-pipeline-usage-guide.md) | US-152 | 本文件（Figma 管線端對端使用指南） |

### 設計規格與模板

| 文件 | 內容說明 |
|------|---------|
| [`docs/design/design-tokens.json`](../design/design-tokens.json) | Design Token 規格（顏色、字型、間距、圓角、陰影的完整值定義） |
| [`docs/templates/sdd-frontend-template.md`](../templates/sdd-frontend-template.md) | SDD 前端模板（含 Figma 設計稿欄位、元件庫白名單、Figma Gate 規則） |

### ADR 決策文件

| 文件 | 說明 |
|------|------|
| `docs/adr/ADR-015-figma-integration.md` | UIUX 管線架構轉型決策（Figma 整合取代 SSD 管線，含 Phase 1 / Phase 2 路線圖） |
| `docs/adr/ADR-014-uiux-agent.md` | UIUX Agent 架構基礎決策（Phase 1 防呆設計、Design Token 強制使用） |

---

## 已知限制與 Fallback 策略（AC4）

以下整合各規格文件中記載的限制事項，並提供對應的替代方案。

---

### 限制一：必須有 Figma Desktop App 開啟

**來源**：`figma-mcp-setup.md` §5 限制一

**說明**：所有寫入操作（建立 Frame、設定 Auto Layout、引用元件、套用 Variable）都需要 Figma Desktop App 在前台或背景執行，且 Talk to Figma Plugin 已連接。這排除了以下場景：

- 純雲端 CI 環境（GitHub Actions、GitLab CI 等）
- 無頭（headless）伺服器環境
- Figma Desktop 關閉時的自動化觸發

**Fallback 策略**：

1. **本地工作站模式**：所有 Figma 寫入操作設計為在開發者本地環境觸發，由 AI 輔助完成，非全自動化管線。
2. **截圖備存**：每個設計稿完成後，使用 `export_node_as_image` 將截圖儲存至 `docs/design/poc-screenshots/`，作為非同步審查的輸入材料。
3. **官方 MCP Server 唯讀模式**：若僅需讀取設計脈絡或截圖（無寫入需求），可在 Figma Desktop 開啟後使用官方 Figma MCP Server 的唯讀工具，無需 Plugin 連接。

---

### 限制二：Variables REST API 需要 Enterprise 帳號

**來源**：`figma-mcp-setup.md` §5 限制二

**說明**：若要透過 Figma REST API 讀寫 Variables，需要 Enterprise 方案（$35/月 Dev seat）。

**Fallback 策略**：

使用 Plugin API 路徑（即透過 `claude-talk-to-figma-mcp` 的 `set_variable`/`get_variables` 工具），不受方案層級限制。Professional 方案（$15/月）即可操作 Variables。

```
所有 Variable 操作使用 claude-talk-to-figma-mcp 工具：
- 建立 Variable：set_variable（非 REST API）
- 讀取 Variables：get_variables（非 REST API）
- 套用 Variable：apply_variable_to_node（非 REST API）
```

---

### 限制三：社群工具維護穩定性風險

**來源**：`figma-mcp-setup.md` §5 限制三

**說明**：`claude-talk-to-figma-mcp` 為社群維護（非 Figma 官方），當 Figma Plugin API 重大更新時，存在適配延遲風險（可能數天至數週的工具失效期）。

**Fallback 策略**：

1. **版本鎖定**：在 `package.json` 中鎖定版本（`"claude-talk-to-figma-mcp": "^0.9.0"`），避免自動升級至可能不穩定的新版本。
2. **升級評估流程**：新版本發布後，先在非生產 Figma 文件中測試所有常用工具（`create_frame`、`set_auto_layout`、`create_component_instance`、`apply_variable_to_node`），確認行為正常後再升級。
3. **官方 MCP 讀取備援**：若寫入工具失效，可暫時改用人工在 Figma 操作設計，使用官方 MCP Server 讀取截圖。
4. **降版回退**：若升級後工具不穩定，立即回退至上一鎖定版本：`npm install -g claude-talk-to-figma-mcp@0.9.2`。

---

### 限制四：Personal Access Token 90 天到期

**來源**：`figma-mcp-setup.md` §5 限制四

**說明**：Figma PAT 自 2025 年更新後強制最長 90 天有效期。到期後，官方 Figma MCP Server 的讀取操作（包含 Vision Critic 截圖讀取路徑）會出現 401 認證錯誤。

**Fallback 策略**：

1. **60 天提前提醒**：在日曆設定 Token 建立後第 60 天的提醒，確保有足夠時間在到期前更新。
2. **Token 更新 SOP**：
   - 前往 Figma Settings > Security > Personal access tokens
   - 撤銷舊 Token，生成新 Token（含 `file_content:read` Scope）
   - 更新 `.env.local` 中的 `FIGMA_ACCESS_TOKEN` 值
   - 重啟 Claude Code 或重新載入 MCP 設定
3. **Token 安全存放**：Token 存放於 `.env.local`（已加入 `.gitignore`），禁止硬編碼於任何代碼檔案或文件。

---

### 限制五：WebSocket Server 單一連接限制

**來源**：`figma-mcp-setup.md` §5 限制五

**說明**：`claude-talk-to-figma-mcp` 的 WebSocket Server 每次只能與一個 Figma Plugin 實例建立連接。

**Fallback 策略**：

若需同時操作多個 Figma 文件：

```bash
# 啟動第二個 Server 實例（使用不同 port）
claude-talk-to-figma-mcp --port 3055
```

在第二個 Figma 文件的 Plugin UI 中填入 `ws://localhost:3055` 連接。每個 Figma 文件對應一個 port 的獨立 Server 實例。

---

### 限制六：Figma Desktop App 為 macOS / Windows 限定

**來源**：`figma-desktop-verification-sop.md` 前置條件

**說明**：Figma Desktop App 不支援 Linux。所有需要 Plugin API 寫入能力的操作均需在 macOS 或 Windows 環境下執行。

**Fallback 策略**：

1. **Linux 開發者**：在配備 macOS 或 Windows 的機器上完成 Figma 設計操作，再透過 Figma 網頁版確認視覺結果。
2. **遠端桌面**：若必須在 Linux 環境下工作，可透過遠端桌面（RDP / VNC）連接至 macOS 或 Windows 機器執行 Figma Desktop。
3. **官方 REST API 唯讀**：Linux 環境可使用 Figma REST API 讀取現有設計稿（不含寫入），搭配官方 MCP Server 進行讀取審查。

---

## 附錄：環境啟動標準順序

每次開始工作前，依以下順序啟動（順序不可顛倒）：

```
1. 啟動 Figma Desktop App（確認已登入）
2. 在 Figma Desktop 開啟目標 Figma 文件
3. 終端機啟動 MCP Server：
   $ claude-talk-to-figma-mcp
   等待：WebSocket server running on ws://localhost:3000
4. 在 Figma Desktop 執行 Talk to Figma Plugin
   填入 Server URL：ws://localhost:3000
   點擊 Connect
5. 終端機確認顯示：Figma Plugin connected
6. 啟動 Claude Code，執行 /mcp 確認兩個 MCP Server 均已連接
   - claude-talk-to-figma（87 個工具）
   - figma-official（讀取工具）
```

---

## 版本記錄

| 版本 | 日期 | 變更說明 |
|------|------|---------|
| v1.0 | 2026-03-06 | 初始建立（US-152，Sprint 56） |
