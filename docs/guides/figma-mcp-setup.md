# Figma MCP Server 選型與本地設定指南

**建立日期**：2026-03-06
**關聯 ADR**：ADR-015（Figma 整合取代 SSD 管線，Accepted）
**關聯 Story**：US-145（Sprint 55）
**版本**：v1.0

---

## 1. 選型決策

### 1.1 候選方案比較

基於 ADR-015 OQ-1 及 OQ-2 調查結論，共評估以下四個 MCP Server 方案：

| 方案 | npm 套件 | 最新版本 | 寫入能力 | 架構模式 | 維護活躍度 |
|------|---------|---------|---------|---------|-----------|
| **官方 Figma MCP Server** | （由 Figma Desktop 內建） | N/A | 唯讀（`generate_figma_design` 例外，為截圖轉換，非 AI 繪製） | Desktop 本地 SSE | Figma 官方 |
| **Figma-Context-MCP / Framelink** | `figma-developer-mcp` | 0.6.6（2026-03-04） | 唯讀（`get_figma_data`, `download_figma_images`） | REST API | 活躍（2 天前更新） |
| **claude-talk-to-figma-mcp** | `claude-talk-to-figma-mcp` | 0.9.2（2026-02-28） | 完整寫入（Plugin API） | WebSocket + Figma Plugin | 活躍（6 天前更新） |
| **cursor-talk-to-figma-mcp** | `cursor-talk-to-figma-mcp` | 0.3.4（2025-10-28） | 完整寫入（Plugin API） | WebSocket + Figma Plugin | 較不活躍（4 個月前更新） |

### 1.2 決策結論

**推薦方案：雙層架構**

| 用途 | 選用方案 | 理由 |
|------|---------|------|
| **設計寫入（建立 Frame、Auto Layout、Component Instance）** | `claude-talk-to-figma-mcp` v0.9.2 | 最新版本（2026-02-28），針對 Claude Desktop 優化，支援完整 Plugin API 寫入工具集，含 `create_frame`、`set_auto_layout`、`create_component_instance`、`apply_variable_to_node` 等 |
| **設計讀取（Vision Critic 審查、Component 讀取）** | 官方 Figma MCP Server | Figma 官方支援，13 個讀取工具，`get_screenshot`、`get_design_context` 已足夠審查用途 |

**不選 cursor-talk-to-figma-mcp**：該套件最後更新為 2025-10-28，維護活躍度低於 claude 版本。

**不選 figma-developer-mcp（Framelink）**：僅有兩個讀取工具（`get_figma_data`、`download_figma_images`），不支援寫入操作，不符合本管線核心需求。

**寫入路徑確認（OQ-1/OQ-2 結論）**：
- Figma REST API 不支援設計節點寫入，所有寫入操作必須透過 Plugin API
- Plugin API 只能在 Figma Desktop App 中執行 Plugin 才能運作
- `claude-talk-to-figma-mcp` 透過 WebSocket 橋接 Claude Code 與 Figma Desktop Plugin

---

## 2. 前置條件

在開始安裝前，確認以下環境條件均已滿足：

- [ ] Figma Desktop App 已安裝（macOS 或 Windows）
- [ ] 已有 Figma 帳號（至少 Professional 方案 + Dev seat，費用 $15/月）
- [ ] Node.js 18+ 已安裝（`node --version` 應顯示 v18 以上）
- [ ] Claude Code 已安裝（v1.x 以上）
- [ ] Figma Personal Access Token（PAT）已建立，有效期 90 天内
  - 建立路徑：Figma 右上角頭像 > Settings > Security > Personal access tokens
  - 必要 Scope：`file_content:read`

---

## 3. 安裝步驟

### 步驟一：安裝 claude-talk-to-figma-mcp npm 套件

```bash
# 全域安裝（推薦）
npm install -g claude-talk-to-figma-mcp

# 驗證安裝
claude-talk-to-figma-mcp --version
```

或使用 npx 直接執行（無需安裝）：

```bash
npx claude-talk-to-figma-mcp
```

### 步驟二：在 Figma Desktop 安裝 Plugin

`claude-talk-to-figma-mcp` 運作需要 Figma Plugin 作為 WebSocket 橋接端。

1. 開啟 Figma Desktop App
2. 前往 **Main Menu > Plugins > Development > New Plugin**
3. 選擇 **Link existing plugin**（如果已有 Plugin ID）或建立新 Plugin
4. Plugin 建立後，在 Canvas 中透過 **Plugins > Development > [Plugin Name]** 執行

替代方案：直接從 Figma Plugin 市場安裝（如果套件作者已發布）：
- 搜尋 "Talk to Figma" 或 "claude-talk-to-figma"

### 步驟三：啟動 MCP Server（WebSocket 模式）

在終端機中啟動 Server：

```bash
# 啟動 WebSocket Server（預設 port 3000）
claude-talk-to-figma-mcp

# 或指定 port
claude-talk-to-figma-mcp --port 3055
```

Server 啟動後應顯示類似：
```
WebSocket server running on ws://localhost:3000
Waiting for Figma Plugin connection...
```

### 步驟四：在 Figma Desktop 執行 Plugin 建立連接

1. 開啟 Figma Desktop，開啟任一文件
2. 執行已安裝的 Talk to Figma Plugin
3. Plugin UI 中輸入 Server URL：`ws://localhost:3000`（或指定的 port）
4. 點擊 Connect
5. 終端機中應顯示：`Figma Plugin connected`

### 步驟五：設定 Claude Code MCP 連接

在 Claude Code 的 MCP 設定中新增 Server：

```json
{
  "mcpServers": {
    "claude-talk-to-figma": {
      "command": "claude-talk-to-figma-mcp",
      "args": [],
      "env": {}
    }
  }
}
```

設定檔位置（macOS）：`~/.claude/settings.json`（或 Claude Code 的 MCP 設定介面）

設定完成後，重新啟動 Claude Code 或執行 `/mcp` 指令重新載入。

### 步驟六：設定官方 Figma MCP Server（讀取用）

官方 MCP Server 透過 Figma Desktop 的本地 Server 運作：

1. 開啟 Figma Desktop App（確認已登入）
2. 官方 MCP Server 端點：`http://127.0.0.1:3845/sse`（Figma Desktop 啟動後自動監聽）

在 Claude Code 設定中新增：

```json
{
  "mcpServers": {
    "figma-official": {
      "url": "http://127.0.0.1:3845/sse"
    }
  }
}
```

---

## 4. 驗證指令

### 4.1 列出可用工具

在 Claude Code 中執行：

```
/mcp
```

確認以下 MCP Server 和工具已出現：

**claude-talk-to-figma（寫入 Server）應包含的核心工具**：

| 工具名稱 | 類別 | 說明 |
|---------|------|------|
| `create_frame` | 寫入 | 建立新 Frame，指定位置、尺寸、名稱 |
| `set_auto_layout` | 寫入 | 設定 Frame 或元件的 Auto Layout（方向、間距、Padding） |
| `create_component_instance` | 寫入 | 引用 Component Library 中的元件，建立 Instance |
| `apply_variable_to_node` | 寫入 | 將 Figma Variable 套用到節點屬性（顏色、間距等） |
| `create_text` | 寫入 | 在指定節點中建立文字層 |
| `set_text_content` | 寫入 | 修改文字層的內容 |
| `set_fill_color` | 寫入 | 設定節點的填充顏色 |
| `set_node_properties` | 寫入 | 設定節點的各種屬性 |
| `move_node` | 寫入 | 移動節點到指定位置 |
| `resize_node` | 寫入 | 調整節點尺寸 |
| `delete_node` | 寫入 | 刪除節點 |
| `get_document_info` | 讀取 | 讀取文件基本資訊 |
| `get_node_info` | 讀取 | 讀取指定節點的詳細屬性 |
| `get_local_components` | 讀取 | 列出文件中的本地元件 |
| `export_node_as_image` | 讀取 | 匯出節點為圖片（PNG/JPEG/SVG） |
| `get_variables` | 讀取 | 讀取文件中的 Variables |
| `set_variable` | 寫入 | 建立或修改 Variable |

完整工具清單（從 v0.9.2 套件提取，共 87 個工具）：

```
apply_image_transform, apply_variable_to_node, boolean_operation,
clone_node, convert_to_frame, create_component_from_node,
create_component_instance, create_component_set, create_connector,
create_ellipse, create_frame, create_page, create_polygon,
create_rectangle, create_section, create_shape_with_text, create_star,
create_sticky, create_text, delete_node, delete_page,
export_node_as_image, flatten_node, get_annotation, get_document_info,
get_figjam_elements, get_grid, get_guide, get_image_from_node,
get_local_components, get_node_info, get_nodes_info, get_pages,
get_remote_components, get_selection, get_styled_text_segments,
get_styles, get_svg, get_variables, group_nodes, insert_child,
move_node, rename_node, rename_page, reorder_node, replace_image_fill,
resize_node, rotate_node, scan_text_nodes, set_annotation,
set_auto_layout, set_corner_radius, set_current_page,
set_effect_style_id, set_effects, set_fill_color, set_font_name,
set_font_size, set_font_weight, set_gradient, set_grid, set_guide,
set_image, set_image_fill, set_image_filters, set_instance_variant,
set_letter_spacing, set_line_height, set_multiple_text_contents,
set_node_properties, set_paragraph_spacing, set_selection_colors,
set_sticky_text, set_stroke_color, set_svg, set_text_align,
set_text_case, set_text_content, set_text_decoration,
set_text_style_id, set_variable, switch_variable_mode, ungroup_nodes
```

### 4.2 AC1 驗證：確認連接成功（需手動執行）

連接成功的判定標準（三步驟均需完成）：

1. **Plugin 載入**：Figma Desktop 中 Talk to Figma Plugin 顯示 "Connected" 狀態
2. **CLI 啟動**：`claude-talk-to-figma-mcp` 終端機顯示 Plugin 已連接
3. **Claude Code 連接**：`/mcp` 指令輸出中可見 `claude-talk-to-figma` Server 及其工具清單

### 4.3 AC2 驗證：寫入工具可用性測試（需手動執行）

在 Claude Code 中呼叫 `create_frame` 工具：

```
請透過 claude-talk-to-figma MCP，在目前開啟的 Figma 文件中建立一個
名為 "US-145-Test" 的 Frame，尺寸為 1440x900px，位置在 (0, 0)。
```

**成功標準**：Frame 出現於 Figma Canvas，名稱為 `US-145-Test`，尺寸為 1440x900px。

測試完成後可刪除此測試 Frame：

```
請刪除剛才建立的 US-145-Test Frame。
```

---

## 5. 已知限制

### 限制一：必須有 Figma Desktop App 開啟

所有寫入操作（建立 Frame、設定 Auto Layout、引用元件）都需要 Figma Desktop App 在背景執行且 Plugin 已連接。這排除了以下場景：

- 純雲端 CI 環境（GitHub Actions 等）
- 無頭（headless）伺服器環境
- Figma Desktop 未開啟時

**因應策略**：AI Agent 工作流設計為 AI 輔助本地開發環境，不作為 CI/CD 自動化管線的一部分。寫入操作由開發者在本地工作站觸發。

### 限制二：Variables REST API 需要 Enterprise 帳號

若要透過 Figma REST API 讀寫 Variables，需要 Enterprise 方案（$35/月 Dev seat）。

**因應策略（OQ-2 結論）**：使用 Plugin API 路徑（即透過 `claude-talk-to-figma-mcp` 的 `set_variable`/`get_variables` 工具），不受方案層級限制。Professional 方案即可操作 Variables。

### 限制三：社群工具維護穩定性風險

`claude-talk-to-figma-mcp` 為社群維護（非 Figma 官方），Figma API 重大更新時存在適配延遲風險。

**因應策略**：在 `package.json` 中鎖定版本（`^0.9.0`），建立版本升級評估流程。新版本發布後，先在非生產 Figma 文件中測試，確認工具行為正常後再升級。

### 限制四：Personal Access Token 90 天到期

Figma PAT 自 2025 年更新後強制最長 90 天有效期，到期後 REST API 呼叫（Vision Critic 讀取截圖路徑）會失敗。

**因應策略**：在日曆中設定 60 天提醒更新 Token，更新後同步至本地環境變數設定。Token 存放於 `.env.local`（已加入 `.gitignore`），禁止硬編碼於任何代碼檔案。

### 限制五：WebSocket Server 為單一連接

`claude-talk-to-figma-mcp` 的 WebSocket Server 每次只能與一個 Figma Plugin 實例建立連接。同時操作多個 Figma 文件需要啟動多個 Server 實例（不同 port）。

---

## 6. 動態 AC 驗證說明（AC1/AC2）

**AC1 和 AC2 屬於動態 AC，需要實際的 Figma Desktop App 執行環境。**

本指南提供完整的安裝與驗證步驟，但動態驗證的最終確認需在有 Figma Desktop App 的本地環境中手動完成。以下是開發者執行驗證的清單：

**AC1 驗證清單（MCP 連接成功）**：
- [ ] `npm install -g claude-talk-to-figma-mcp` 執行成功，無錯誤
- [ ] Figma Desktop App 已開啟，Plugin 已執行並顯示 Connected
- [ ] `claude-talk-to-figma-mcp` 終端機顯示 "Figma Plugin connected"
- [ ] Claude Code `/mcp` 指令輸出中可見 `claude-talk-to-figma` Server
- [ ] Server 工具清單包含 `create_frame`、`set_auto_layout`、`create_component_instance`

**AC2 驗證清單（寫入工具可用）**：
- [ ] 透過 Claude Code 呼叫 `create_frame` 工具
- [ ] Frame 出現於 Figma Canvas（可在 Figma 中目視確認）
- [ ] Frame 的名稱、尺寸與呼叫參數一致

---

## 7. 快速參考卡

### 環境啟動順序

```
1. 開啟 Figma Desktop App
2. 開啟目標 Figma 文件
3. 執行 Talk to Figma Plugin（連接至 ws://localhost:3000）
4. 終端機啟動 MCP Server：claude-talk-to-figma-mcp
5. 開啟 Claude Code（確認 MCP 已連接）
```

### 常用工具速查

| 任務 | 工具 | 範例呼叫 |
|------|------|---------|
| 建立 Frame | `create_frame` | 建立名為 US-XXX 的 1440px Frame |
| 設定 Auto Layout | `set_auto_layout` | 設定水平方向、gap 16px |
| 引用元件 | `create_component_instance` | 引用 Button 元件建立 Instance |
| 套用 Variable | `apply_variable_to_node` | 將 brand-primary 套用至背景色 |
| 截圖讀取 | `export_node_as_image` | 匯出 Frame 為 PNG |
| 讀取文件 | `get_document_info` | 取得文件基本資訊 |

### 環境變數設定（.env.local）

```bash
# Figma Personal Access Token（90 天效期，勿提交至 Git）
FIGMA_ACCESS_TOKEN=figd_xxxxxxxxxxxxxxxx

# Figma 文件 ID（從 URL 提取：figma.com/file/{FILE_KEY}/...）
FIGMA_FILE_KEY=xxxxxxxxxxxxxxxx
```

---

## 8. 參考資料

- [ADR-015：UIUX 管線架構轉型 — Figma 整合](../adr/ADR-015-figma-integration.md)
- [ADR-015 OQ-1：Figma MCP Server 能力邊界調查](../adr/ADR-015-figma-integration.md#oq-1figma-mcp-server-能力邊界)
- [ADR-015 OQ-2：Figma REST API 限制調查](../adr/ADR-015-figma-integration.md#oq-2figma-rest-api-限制)
- [claude-talk-to-figma-mcp npm 套件](https://www.npmjs.com/package/claude-talk-to-figma-mcp)
- [Figma Plugin API 官方文件](https://www.figma.com/plugin-docs/)
- [Figma MCP Server 官方開發者文件](https://developers.figma.com/docs/figma-mcp-server/)
- [Figma 個人 Access Token 管理](https://help.figma.com/hc/en-us/articles/8085703771159-Manage-personal-access-tokens)
