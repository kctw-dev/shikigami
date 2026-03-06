# AI 生成 Frame PoC 執行計畫

**建立日期**：2026-03-06
**關聯 ADR**：ADR-015（Figma 整合取代 SSD 管線，Accepted）
**關聯 Story**：US-147（Sprint 55）
**依賴文件**：
- `docs/guides/figma-mcp-setup.md`（MCP Server 選型與安裝指南）
- `docs/design/figma-structure-guide.md`（Page 架構與命名規則）
- `docs/design/component-library-spec.md`（元件規格）
- `docs/adr/ADR-015-figma-integration.md`（架構決策背景）
**版本**：v1.0

---

## 概覽

本文件定義 US-147 PoC（Proof of Concept）的完整執行計畫，目標是透過 Claude Code 呼叫 Figma MCP（`claude-talk-to-figma-mcp`），以真實 User Story 為輸入，生成帶 Auto Layout 與 Figma Variable 綁定的 Figma Frame，並讀取截圖，驗證 ADR-015 Phase 1 技術路徑可落地。

**重要說明**：本文件的 AC1-AC5 均為動態 AC，需要 Figma Desktop App + `claude-talk-to-figma-mcp` 連接才能執行。CLI 環境（GitHub Actions 等）無法直接生成 Figma Frame。本文件提供完整操作指引，動態驗證由使用者在本地環境依步驟執行。

---

## 1. PoC 輸入選擇（AC1）

### 1.1 選擇理由

選擇 **US-147 自身**（AI 生成 Frame PoC — 透過 Figma MCP 生成帶 Auto Layout 的 Frame）作為 PoC 輸入 User Story。

理由如下：

| 理由 | 說明 |
|------|------|
| **自反性驗證** | 用 US-147 自身描述生成其 UI 框架，可驗證 AI 是否能從結構化文字（User Story + AC）推斷出合理的 UI 骨架 |
| **文件已備** | US-147 的完整 AC、Done Definition、相關技術背景（ADR-015）均已就緒，AI 讀取的上下文完整 |
| **功能性明確** | US-147 描述的是「PoC 執行結果確認」功能，對應的 UI 元素可預期（Frame 列表、狀態指示、截圖預覽） |
| **備選方案** | 若 US-147 自反性太強不易推斷 UI，備選為 US-145（Figma MCP Server 選型與本地設定驗證），其 UI 對應「設定引導頁面」場景更直覺 |

### 1.2 US-147 User Story 摘要（PoC 輸入）

```
Story：AI 生成 Frame PoC — 透過 Figma MCP 生成帶 Auto Layout 的 Frame

As a Developer validating the ADR-015 Phase 1 end-to-end technical path,
I want to use Claude Code + Figma MCP to generate a Frame based on a real
User Story input (with Auto Layout and at least one Figma Variable binding),
so that the feasibility of AI-driven Figma design generation is confirmed
and documented as a reproducible PoC.

核心 AC：
- AC1：以真實 User Story 為輸入，生成對應 Frame
- AC2：Frame 存在於指定 Sprint Page，命名符合規則
- AC3：Auto Layout 已設定（方向 + 間距）
- AC4：至少一個元素綁定 Figma Variable
- AC5：截圖可讀取，存放 docs/design/poc-screenshots/
```

### 1.3 推斷的 UI 骨架

基於 US-147 的功能目標（「確認 PoC 可行性」），AI 應生成以下 UI 結構：

```
Page：Sprint-55-FigmaIntegration
Frame：POC-US-147-FrameGeneration-Desktop（1440px）

Frame 結構：
├── Header（64px 高，Horizontal Auto Layout）
│   ├── Page-Title（文字：「US-147 PoC — AI Frame 生成驗證」）
│   └── Status-Badge（Badge 元素，顯示 PoC 狀態）
├── Main-Content（Vertical Auto Layout，Gap 48px，Padding 80px）
│   ├── Story-Input-Section（顯示輸入的 User Story 摘要）
│   │   ├── Section-Title（文字：「輸入：User Story」）
│   │   └── Story-Card（Card Component Instance）
│   ├── Frame-Generation-Section（顯示生成的 Frame 資訊）
│   │   ├── Section-Title（文字：「生成結果」）
│   │   └── Result-Card（Card Component Instance）
│   └── Screenshot-Section（截圖預覽區）
│       ├── Section-Title（文字：「截圖驗證」）
│       └── Screenshot-Placeholder（Rectangle，綁定 Figma Variable）
└── Footer（簡單頁腳，顯示 PoC 日期與 ADR-015 連結）
```

---

## 2. 完整 MCP 工具呼叫序列（Step by Step）

本節定義 AI Agent 執行 PoC 時的完整工具呼叫序列。每步驟均標注：使用的工具名稱、參數說明、執行前提與預期結果。

### 前置條件確認

在開始執行任何 MCP 工具前，確認以下環境已就緒：

```
環境清單：
1. Figma Desktop App 已開啟並登入（Professional 或以上帳號）
2. claude-talk-to-figma-mcp CLI Server 已在終端機啟動：
   $ claude-talk-to-figma-mcp
   （預設監聽 ws://localhost:3000）
3. Figma Desktop 中已執行 Talk to Figma Plugin 並連接（顯示 Connected）
4. Claude Code MCP 已連接：/mcp 指令可見 claude-talk-to-figma 工具

驗證指令：
$ /mcp
（確認輸出中含 claude-talk-to-figma Server 及其工具清單）
```

---

### Step 1：讀取文件資訊

**工具**：`get_document_info`

**目的**：確認目前開啟的 Figma 文件資訊，取得文件 ID 與 Page 列表。

**MCP 呼叫指令（Claude Code 輸入）**：
```
請透過 claude-talk-to-figma MCP 使用 get_document_info 工具，
讀取目前開啟的 Figma 文件的基本資訊（名稱、文件 ID、現有 Page 列表）。
```

**預期輸出**：
```json
{
  "name": "Shikigami Design System",
  "id": "...",
  "pages": [
    { "id": "...", "name": "_Component-Library" },
    { "id": "...", "name": "_Design-Tokens" },
    ...
  ]
}
```

---

### Step 2：確認或建立 Sprint Page

**工具**：`get_pages` + `create_page`（按需）+ `set_current_page`

**目的**：確認 `Sprint-55-FigmaIntegration` Page 是否存在。若不存在則建立；若存在則直接切換。

**MCP 呼叫指令**：
```
請透過 claude-talk-to-figma MCP：

步驟 2a：使用 get_pages 工具取得所有 Page 清單。

步驟 2b：確認是否存在名為 "Sprint-55-FigmaIntegration" 的 Page。
  - 若不存在，使用 create_page 工具建立：name = "Sprint-55-FigmaIntegration"
  - 若已存在，跳過建立步驟

步驟 2c：使用 set_current_page 工具切換至 "Sprint-55-FigmaIntegration" Page。
```

**命名規則依據**：
- Sprint Page 命名格式：`Sprint-{N}-{功能名}`（見 `figma-structure-guide.md` §1.3）
- Sprint 55 功能名：`FigmaIntegration`

**預期結果**：目前頁面切換為 `Sprint-55-FigmaIntegration`。

---

### Step 3：確認 Figma Variables 已存在

**工具**：`get_variables` + `set_variable`（按需）

**目的**：確認 `color/primary/500` 等 Design Token Variables 是否已存在。若不存在則建立 AC4 所需的最低要求 Variable。

**MCP 呼叫指令**：
```
請透過 claude-talk-to-figma MCP 使用 get_variables 工具，
讀取文件目前已有的 Variables 清單。

若不存在名為 "color/primary/500" 的 Variable，
使用 set_variable 工具建立以下最低要求 Variables：
- 名稱：color/primary/500，值：#3b82f6，類型：COLOR
- 名稱：color/neutral/0，值：#ffffff，類型：COLOR
- 名稱：color/background/primary，值：#f8fafc，類型：COLOR
- 名稱：color/secondary/900，值：#0f172a，類型：COLOR
- 名稱：color/secondary/500，值：#64748b，類型：COLOR
```

**Token 對照**（參考 `docs/design/design-tokens.json`）：

| Variable 名稱 | 色碼 | 用途 |
|-------------|------|------|
| `color/primary/500` | `#3b82f6` | 主要強調色（Header、Badge） |
| `color/neutral/0` | `#ffffff` | 純白背景 |
| `color/background/primary` | `#f8fafc` | 頁面背景色 |
| `color/secondary/900` | `#0f172a` | 主要文字色 |
| `color/secondary/500` | `#64748b` | 次要文字色 |

**預期結果**：上述 Variables 均存在於 Figma 文件中。

---

### Step 4：建立主要 PoC Frame（AC2 + AC3）

**工具**：`create_frame` + `set_auto_layout`

**目的**：建立符合命名規則的主 Frame，並設定 Vertical Auto Layout。

**MCP 呼叫指令**：
```
請透過 claude-talk-to-figma MCP，建立 PoC 主 Frame：

步驟 4a：使用 create_frame 建立 Frame：
  - name：POC-US-147-FrameGeneration-Desktop
  - width：1440
  - height：900
  - x：0
  - y：0

步驟 4b：使用 set_auto_layout 設定 Frame 的 Auto Layout：
  - 方向（layoutMode）：VERTICAL
  - 主軸對齊（primaryAxisAlignItems）：MIN
  - 交叉軸對齊（counterAxisAlignItems）：STRETCH
  - 子元素間距（itemSpacing）：0
  - Padding 全向：0
```

**命名規則依據**：
- PoC Frame 命名格式：`POC-{StoryID}-{功能描述}-{平台}`（見 `figma-structure-guide.md` §2.2）
- 功能描述：`FrameGeneration`
- 平台：`Desktop`

**預期結果**：
- Figma Canvas 中出現名為 `POC-US-147-FrameGeneration-Desktop` 的 Frame
- Frame 尺寸為 1440 x 900 px
- Frame 已設定 Vertical Auto Layout

---

### Step 5：建立 Header 子 Frame（AC3）

**工具**：`create_frame` + `set_auto_layout` + `insert_child`

**目的**：在主 Frame 內建立 Header 區塊，設定 Horizontal Auto Layout。

**MCP 呼叫指令**：
```
請透過 claude-talk-to-figma MCP：

步驟 5a：使用 create_frame 建立 Header Frame：
  - name：Header
  - width：1440
  - height：64

步驟 5b：使用 set_auto_layout 設定 Header Auto Layout：
  - layoutMode：HORIZONTAL
  - primaryAxisAlignItems：SPACE_BETWEEN
  - counterAxisAlignItems：CENTER
  - paddingTop：0，paddingBottom：0
  - paddingLeft：24，paddingRight：24
  - itemSpacing：16

步驟 5c：使用 insert_child 將 Header Frame 插入至主 Frame
  （POC-US-147-FrameGeneration-Desktop）的第一個子元素位置
```

**Auto Layout 規格依據**：Header 內部為 Horizontal，Padding 左右 24px（見 `figma-structure-guide.md` §3.6 速查表）。

**預期結果**：主 Frame 內出現名為 `Header` 的子 Frame，高度 64px，Horizontal Auto Layout。

---

### Step 6：在 Header 建立標題文字

**工具**：`create_text` + `set_text_content`

**目的**：在 Header 中建立頁面標題文字層。

**MCP 呼叫指令**：
```
請透過 claude-talk-to-figma MCP：

步驟 6a：使用 create_text 工具在 Header Frame 內建立文字層：
  - name：Page-Title
  - content："US-147 PoC — AI Frame 生成驗證"
  - fontSize：20
  - fontWeight：600

步驟 6b：使用 set_font_name 設定字型：
  - fontFamily："Inter"（或本機可用的 Sans-serif 字型）
```

**命名規則依據**：文字層命名 `Page-Title`（見 `figma-structure-guide.md` §2.6）。

**預期結果**：Header 內出現名為 `Page-Title` 的文字層，顯示 PoC 標題。

---

### Step 7：建立 Main-Content 子 Frame（AC3 強化）

**工具**：`create_frame` + `set_auto_layout` + `insert_child`

**目的**：建立主要內容區塊，設定 Vertical Auto Layout 並指定適當間距。

**MCP 呼叫指令**：
```
請透過 claude-talk-to-figma MCP：

步驟 7a：使用 create_frame 建立 Main-Content Frame：
  - name：Main-Content
  - width：1440
  - height：836（900 - 64 的剩餘高度）

步驟 7b：使用 set_auto_layout 設定 Main-Content Auto Layout：
  - layoutMode：VERTICAL
  - primaryAxisAlignItems：MIN
  - counterAxisAlignItems：CENTER
  - itemSpacing：48
  - paddingTop：80
  - paddingBottom：80
  - paddingLeft：0
  - paddingRight：0

步驟 7c：使用 insert_child 將 Main-Content Frame 插入至主 Frame 的第二個子元素位置
```

**Auto Layout 規格依據**：桌面 Main Content，Gap 48px（2xl），Padding 上下 80px（4xl）（見 `figma-structure-guide.md` §3.2 與 §3.6）。

**預期結果**：主 Frame 包含 Header + Main-Content 兩個子 Frame，Main-Content 已設定 Vertical Auto Layout，Gap 48px。

---

### Step 8：建立 Story-Input Section

**工具**：`create_frame` + `create_text` + `insert_child`

**目的**：在 Main-Content 中建立「輸入 User Story」展示區塊。

**MCP 呼叫指令**：
```
請透過 claude-talk-to-figma MCP：

步驟 8a：使用 create_frame 建立 Story-Input-Section Frame：
  - name：Story-Input-Section
  - width：1200
  - height：200
  設定 Auto Layout：
  - layoutMode：VERTICAL
  - itemSpacing：16
  - paddingTop：0，paddingBottom：0，paddingLeft：0，paddingRight：0

步驟 8b：在 Story-Input-Section 內建立 Section-Title 文字層：
  - name：Section-Title
  - content："輸入：User Story"
  - fontSize：16，fontWeight：600

步驟 8c：在 Story-Input-Section 內建立 Story-Description 文字層：
  - name：Story-Description
  - content："US-147：AI 生成 Frame PoC — 以 Claude Code + Figma MCP 生成帶 Auto Layout 的 Frame，驗證 ADR-015 Phase 1 技術路徑可落地。"
  - fontSize：14，fontWeight：400

步驟 8d：使用 insert_child 將 Story-Input-Section 插入至 Main-Content Frame
```

**預期結果**：Main-Content 中出現 Story-Input-Section，包含標題與 US-147 描述文字。

---

### Step 9：建立 Screenshot-Placeholder（AC4 — Figma Variable 綁定）

**工具**：`create_rectangle`（或 `create_frame`）+ `apply_variable_to_node`

**目的**：建立截圖預覽佔位矩形，並將其背景色綁定 Figma Variable（AC4 核心驗證）。

**MCP 呼叫指令**：
```
請透過 claude-talk-to-figma MCP：

步驟 9a：使用 create_rectangle 建立截圖佔位矩形：
  - name：Screenshot-Placeholder
  - width：1200
  - height：300
  （若 create_rectangle 不可用，使用 create_frame 替代）

步驟 9b：使用 set_fill_color 設定初始顏色（暫定）：
  - 顏色：#e2e8f0（淺藍灰色，作為佔位色）

步驟 9c：[AC4 關鍵步驟] 使用 apply_variable_to_node 將 Figma Variable 綁定至節點：
  - 節點：Screenshot-Placeholder（使用上一步取得的 node ID）
  - 屬性：fills（填充色）
  - Variable：color/background/primary（對應 Design Token）

步驟 9d：使用 insert_child 將 Screenshot-Placeholder 插入至 Main-Content Frame
```

**AC4 通過標準**：`apply_variable_to_node` 呼叫成功，`Screenshot-Placeholder` 矩形的 fills 屬性已綁定 Figma Variable `color/background/primary`，在 Figma 中選取此節點可見 Variable 綁定顯示。

**預期結果**：Main-Content 中出現 Screenshot-Placeholder 矩形，背景色已綁定 Variable（非直接 hex 值）。

---

### Step 10：套用 Variable 至 Header 背景色（AC4 強化）

**工具**：`apply_variable_to_node`

**目的**：將 Header Frame 的背景色也綁定 Figma Variable，強化 AC4 的覆蓋範圍。

**MCP 呼叫指令**：
```
請透過 claude-talk-to-figma MCP：

步驟 10a：使用 get_node_info 取得 Header Frame 的 node ID

步驟 10b：使用 set_fill_color 設定 Header 初始背景色：
  - 顏色：#3b82f6（Primary 品牌色）

步驟 10c：使用 apply_variable_to_node 將 Variable 綁定至 Header：
  - 節點：Header Frame（使用步驟 10a 取得的 node ID）
  - 屬性：fills
  - Variable：color/primary/500
```

**預期結果**：Header 背景色已綁定 `color/primary/500` Variable（藍色主題色），在 Figma 中選取 Header 可見 Variable 綁定。

---

### Step 11：讀取 Frame 截圖（AC5）

**工具**：`export_node_as_image`

**目的**：透過 MCP 讀取主 Frame 的截圖，存放至 `docs/design/poc-screenshots/`。

**MCP 呼叫指令**：
```
請透過 claude-talk-to-figma MCP：

步驟 11a：使用 get_node_info 確認主 Frame（POC-US-147-FrameGeneration-Desktop）的 node ID

步驟 11b：使用 export_node_as_image 工具匯出截圖：
  - node ID：[主 Frame 的 node ID]
  - format：PNG
  - scale：1（或 2 for 2x 高解析度）

步驟 11c：將返回的截圖數據（base64 或檔案路徑）儲存至：
  docs/design/poc-screenshots/POC-US-147-FrameGeneration.png
```

**備選方案（若 export_node_as_image 輸出為 base64）**：

若 `export_node_as_image` 工具回傳 base64 字串，使用以下 Claude Code 操作儲存：
```
# 在 Claude Code 中執行
import base64
data = "<base64 string from MCP>"
with open("docs/design/poc-screenshots/POC-US-147-FrameGeneration.png", "wb") as f:
    f.write(base64.b64decode(data))
```

**備選方案（若 MCP 截圖失敗，改用 Figma REST API）**：

```bash
# 使用 Figma REST API 匯出截圖（需要 PAT）
curl -H "X-Figma-Token: $FIGMA_ACCESS_TOKEN" \
  "https://api.figma.com/v1/images/$FIGMA_FILE_KEY?ids={NODE_ID}&format=png&scale=1" \
  -o /tmp/figma_image_url.json

# 取出 URL 後下載
# curl -o docs/design/poc-screenshots/POC-US-147-FrameGeneration.png "{image_url}"
```

**預期結果**：
- `docs/design/poc-screenshots/POC-US-147-FrameGeneration.png` 存在
- 截圖可讀取（非空檔案，可在瀏覽器或圖片工具中開啟）
- 截圖顯示 Frame 結構（Header + Main-Content，含標題文字）

---

## 3. Auto Layout 設定摘要（AC3）

本 PoC 涉及的所有 Auto Layout 設定彙整：

| 節點名稱 | 方向 | Gap（itemSpacing） | Padding | 對齊 |
|---------|------|-------------------|---------|------|
| `POC-US-147-FrameGeneration-Desktop`（主 Frame） | VERTICAL | 0 | 0 全向 | MIN/STRETCH |
| `Header` | HORIZONTAL | 16 | 0 上下 / 24 左右 | SPACE_BETWEEN / CENTER |
| `Main-Content` | VERTICAL | 48 | 80 上下 / 0 左右 | MIN / CENTER |
| `Story-Input-Section` | VERTICAL | 16 | 0 全向 | MIN / STRETCH |

**AC3 通過標準**：主 Frame 的 Auto Layout 已設定（`layoutMode = VERTICAL`，`itemSpacing = 0`），且 Main-Content 子 Frame 設定（`layoutMode = VERTICAL`，`itemSpacing = 48`）。在 Figma 中選取這些 Frame 時，右側屬性面板應顯示 Auto Layout 設定。

---

## 4. Variable 綁定步驟摘要（AC4）

| 節點 | 屬性 | Variable 名稱 | 色碼值 |
|------|------|-------------|-------|
| `Screenshot-Placeholder` | fills（背景色） | `color/background/primary` | `#f8fafc` |
| `Header` | fills（背景色） | `color/primary/500` | `#3b82f6` |

**最低要求（AC4）**：至少完成上述其中一個 Variable 綁定，即判定 AC4 通過。

**AC4 通過標準**：使用 `apply_variable_to_node` 工具呼叫成功，在 Figma 中選取對應節點時，fills 屬性顯示 Variable 名稱（如 `color/primary/500`），而非直接顯示 hex 色碼。

---

## 5. 截圖讀取步驟摘要（AC5）

| 步驟 | 工具 | 說明 |
|------|------|------|
| 取得 node ID | `get_node_info` | 讀取主 Frame 的 node ID |
| 匯出截圖 | `export_node_as_image` | format=PNG，scale=1 |
| 儲存檔案 | 寫入磁碟 | 目標路徑：`docs/design/poc-screenshots/POC-US-147-FrameGeneration.png` |

**備選路徑**（`export_node_as_image` 失敗時）：
1. 使用官方 Figma MCP Server 的 `get_screenshot` 工具（需 Figma Desktop MCP 連接）
2. 使用 Figma REST API `/v1/images/{file_key}?ids={node_id}` 取得圖片 URL，再下載

---

## 6. 預期結果描述

成功完成本 PoC 後，預期呈現以下結果：

### 6.1 Figma 文件狀態

```
Figma 文件
├── _Component-Library（已存在）
├── _Design-Tokens（已存在）
└── Sprint-55-FigmaIntegration（PoC 建立）
    └── POC-US-147-FrameGeneration-Desktop（1440 x 900 px）
        ├── Header（64px，Horizontal Auto Layout，背景色綁定 color/primary/500）
        │   └── Page-Title（文字：「US-147 PoC — AI Frame 生成驗證」）
        └── Main-Content（Vertical Auto Layout，Gap 48px，Padding 80px）
            ├── Story-Input-Section（Vertical Auto Layout，Gap 16px）
            │   ├── Section-Title（文字：「輸入：User Story」）
            │   └── Story-Description（US-147 描述文字）
            └── Screenshot-Placeholder（背景色綁定 color/background/primary）
```

### 6.2 Variables 狀態

Figma 文件的 Variables 面板中，以下 Variables 存在：
- `color/primary/500` = `#3b82f6`
- `color/neutral/0` = `#ffffff`
- `color/background/primary` = `#f8fafc`
- `color/secondary/900` = `#0f172a`
- `color/secondary/500` = `#64748b`

### 6.3 截圖輸出

- 檔案：`docs/design/poc-screenshots/POC-US-147-FrameGeneration.png`
- 格式：PNG，1440 x 900 px（或等比例縮放）
- 內容：可讀取的 Frame 截圖，顯示 Header（藍色背景）+ Main-Content（灰白背景）的 UI 骨架

### 6.4 AC 驗證結果

| AC | 判定 | 驗證依據 |
|----|------|---------|
| AC1 | PASS | 以 US-147 User Story 為輸入，已生成對應 Frame |
| AC2 | PASS | Frame 名稱 `POC-US-147-FrameGeneration-Desktop` 符合命名規則；位於 `Sprint-55-FigmaIntegration` Page |
| AC3 | PASS | 主 Frame 設定 Vertical Auto Layout；Main-Content 設定 Gap 48px |
| AC4 | PASS | `Screenshot-Placeholder` fills 綁定 `color/background/primary` Variable |
| AC5 | PASS | `docs/design/poc-screenshots/POC-US-147-FrameGeneration.png` 已存在且可讀取 |

---

## 7. 故障排除

### 問題一：`apply_variable_to_node` 呼叫失敗

**可能原因**：Variable 名稱不存在，或 Variable ID 格式錯誤。

**解決方式**：
1. 先用 `get_variables` 確認 Variable 名稱完全一致
2. `apply_variable_to_node` 可能需要傳入 Variable ID（UUID）而非名稱，先用 `get_variables` 取得 ID 後重試

### 問題二：`export_node_as_image` 回傳空值或錯誤

**可能原因**：節點 ID 錯誤，或 Frame 內容為空。

**解決方式**：
1. 用 `get_node_info` 確認 node ID 正確
2. 確認 Frame 非空（至少有一個子節點）
3. 改用官方 Figma MCP Server 的 `get_screenshot` 工具

### 問題三：`set_auto_layout` 執行後 Frame 佈局異常

**可能原因**：Auto Layout 屬性衝突（如既有固定寬度與 STRETCH 對齊衝突）。

**解決方式**：
1. 先用 `get_node_info` 讀取 Frame 目前的完整屬性
2. 確認子節點設定後重新呼叫 `set_auto_layout`
3. 若問題持續，拆解步驟：先建立 Frame，再加入子節點，最後設定 Auto Layout

### 問題四：WebSocket 連接斷開

**可能原因**：Figma Plugin 逾時或 CLI Server 重啟。

**解決方式**：
1. 在 Figma Desktop 中重新執行 Talk to Figma Plugin
2. 重新連接至 `ws://localhost:3000`
3. 確認 CLI Server 仍在執行（或重新啟動）

---

## 8. 完整執行清單（AC 對應）

### AC1 驗證清單（PoC 輸入為真實 User Story）

- [ ] 已選定 US-147 作為 PoC 輸入（或備選 US-145）
- [ ] AI 已讀取 US-147 的 User Story 摘要與 AC 清單
- [ ] 根據 US-147 功能目標推斷出合理的 UI 骨架結構

### AC2 驗證清單（Frame 存在於指定 Page）

- [ ] `Sprint-55-FigmaIntegration` Page 已存在（或已透過 `create_page` 建立）
- [ ] Frame 名稱為 `POC-US-147-FrameGeneration-Desktop`，符合命名規則（`POC-{StoryID}-{功能描述}-{平台}`）
- [ ] 在 Figma 中切換至 `Sprint-55-FigmaIntegration` Page 可見該 Frame

### AC3 驗證清單（Auto Layout 已設定）

- [ ] 主 Frame `POC-US-147-FrameGeneration-Desktop` 設定 `layoutMode = VERTICAL`
- [ ] `Main-Content` 子 Frame 設定 `layoutMode = VERTICAL`，`itemSpacing = 48`
- [ ] `Header` 子 Frame 設定 `layoutMode = HORIZONTAL`，`itemSpacing = 16`
- [ ] 在 Figma 中選取上述 Frame，右側屬性面板顯示 Auto Layout 設定

### AC4 驗證清單（Figma Variable 綁定）

- [ ] `color/primary/500` Variable 已在文件 Variables 中存在
- [ ] `color/background/primary` Variable 已在文件 Variables 中存在
- [ ] `apply_variable_to_node` 已呼叫，成功回傳（無錯誤）
- [ ] 在 Figma 中選取 `Screenshot-Placeholder` 或 `Header`，fills 屬性顯示 Variable 名稱

### AC5 驗證清單（截圖可讀取）

- [ ] `export_node_as_image` 工具呼叫成功
- [ ] 截圖數據（base64 或 URL）已取得
- [ ] `docs/design/poc-screenshots/POC-US-147-FrameGeneration.png` 檔案已儲存
- [ ] 開啟檔案，截圖顯示 Frame 結構（非空白、非錯誤圖片）

---

## 9. 動態 AC 執行環境說明

**本文件所有 MCP 操作步驟均需在以下環境中執行：**

```
必要環境：
1. Figma Desktop App（macOS 或 Windows）已開啟並登入
2. Figma 文件已開啟（需有 Sprint-55 Page 的寫入權限）
3. claude-talk-to-figma-mcp CLI Server 已在背景執行（ws://localhost:3000）
4. Figma Desktop 中 Talk to Figma Plugin 已連接至 CLI Server
5. Claude Code MCP 設定包含 claude-talk-to-figma Server

詳細安裝步驟請參閱：docs/guides/figma-mcp-setup.md
```

**CI 環境不適用**：AC1-AC5 均為動態 AC，需要 Figma Desktop App 執行環境，純雲端 CI（GitHub Actions 等）無法執行。所有動態驗證均需開發者在本地工作站手動觸發，依本文件步驟序列逐步執行。

---

## 10. 參考文件

- [ADR-015：UIUX 管線架構轉型 — Figma 整合](../adr/ADR-015-figma-integration.md)
- [Figma MCP Server 選型與本地設定指南](../guides/figma-mcp-setup.md)
- [Figma 文件結構指南](figma-structure-guide.md)（Page 架構與命名規則）
- [Component Library 規格文件](component-library-spec.md)（元件規格與 Variable 綁定）
- [Design Tokens](design-tokens.json)（Token 名稱與色碼對照）
- [claude-talk-to-figma-mcp npm 套件](https://www.npmjs.com/package/claude-talk-to-figma-mcp)
- [Figma Plugin API — Auto Layout](https://www.figma.com/plugin-docs/api/properties/nodes-autolayout/)
- [Figma Plugin API — Variables](https://www.figma.com/plugin-docs/api/figma-variables/)

---

## 版本記錄

| 版本 | 日期 | 變更說明 |
|------|------|---------|
| v1.0 | 2026-03-06 | 初始建立（US-147，Sprint 55） |
