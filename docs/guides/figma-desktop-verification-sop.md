# Figma Desktop 本地驗證環境 SOP

**建立日期**：2026-03-06
**關聯 Story**：US-150（Sprint 56）
**關聯 ADR**：ADR-015（Figma 整合取代 SSD 管線，Accepted）
**版本**：v1.0

---

## 概覽

本 SOP 文件提供 Figma Desktop 本地驗證環境的完整建立流程，適用於首次設定 Figma 整合環境的開發者。完成本 SOP 後，你將能夠：

1. 在 Figma Desktop App 中安裝並執行 claude-talk-to-figma-mcp Plugin
2. 透過 WebSocket 建立 Claude Code ↔ Figma Desktop 的雙向通道
3. 設定官方 Figma MCP Server 進行唯讀操作
4. 驗證 Sprint 55 所有動態 AC（US-145 / US-148 / US-147）

**架構說明（雙層 MCP）**：

| 層次 | MCP Server | 用途 |
|------|-----------|------|
| 寫入層 | `claude-talk-to-figma-mcp`（WebSocket） | 建立 Frame、設定 Auto Layout、引用元件、套用 Variable |
| 讀取層 | 官方 Figma MCP Server（SSE） | 截圖讀取、設計脈絡讀取、Vision Critic 審查 |

---

## 前置條件清單

在開始任何安裝步驟前，確認以下條件全部達成：

- [ ] **作業系統**：macOS 或 Windows（Linux 不支援 Figma Desktop App）
- [ ] **Figma 帳號**：Professional 方案以上，且具備 Dev seat（$15/月）
- [ ] **Node.js**：v18 或以上（執行 `node --version` 確認）
- [ ] **npm**：v9 或以上（執行 `npm --version` 確認）
- [ ] **Claude Code**：已安裝（執行 `/version` 確認）
- [ ] **網路**：可連接至 `api.figma.com`（或公司代理已設定）

---

## Part 1：Figma Desktop App 安裝與帳號設定

### Step 1-1：下載並安裝 Figma Desktop App

1. 前往 [https://www.figma.com/downloads/](https://www.figma.com/downloads/)
2. 選擇對應平台：
   - macOS：下載 `.dmg` 檔，拖拉至 Applications 資料夾
   - Windows：下載 `.exe` 安裝程式，執行後依指示完成安裝
3. 啟動 Figma Desktop App
4. 以你的 Figma 帳號登入（確認帳號方案為 Professional 或以上）

**驗證**：Figma Desktop 主畫面出現，可見 "Recent files" 或 "Drafts"。

### Step 1-2：取得 Figma Personal Access Token（PAT）

PAT 用於官方 Figma MCP Server 與 Figma REST API 的認證。

1. 點擊 Figma Desktop 右上角頭像圖示
2. 選擇 **Settings**
3. 切換至 **Security** 分頁
4. 在 **Personal access tokens** 區塊點擊 **Generate new token**
5. 填入 Token 名稱（建議：`shikigami-mcp-local`）
6. 設定到期日（建議：90 天，目前最長限制）
7. 必要 Scope 選擇：`file_content:read`
8. 點擊 **Generate token**，立即複製 Token 值（頁面關閉後無法再次查看）

**Token 安全存放（必要步驟）**：

在專案根目錄建立 `.env.local` 檔案（若不存在），加入以下內容：

```bash
# Figma Personal Access Token（90 天效期，勿提交至 Git）
FIGMA_ACCESS_TOKEN=figd_xxxxxxxxxxxxxxxx

# Figma 文件 ID（從 URL 提取：figma.com/file/{FILE_KEY}/...）
FIGMA_FILE_KEY=xxxxxxxxxxxxxxxx
```

確認 `.env.local` 已在 `.gitignore` 中（禁止將 Token 硬編碼於任何代碼檔案）。

**Token 到期提醒**：在日曆設定 60 天後的提醒，確保在到期前更新 Token。

### Step 1-3：確認帳號方案與 Dev Seat

1. 前往 [https://www.figma.com/settings](https://www.figma.com/settings)
2. 確認方案顯示為 **Professional** 或以上
3. 確認已配置 **Dev seat**（若方案正確但無 Dev seat，Plugin API 的寫入能力會受限）

---

## Part 2：claude-talk-to-figma-mcp Plugin 安裝與 WebSocket 連接

### Step 2-1：安裝 npm 套件

在終端機執行以下指令安裝 `claude-talk-to-figma-mcp`：

```bash
# 全域安裝（推薦）
npm install -g claude-talk-to-figma-mcp

# 驗證安裝成功
claude-talk-to-figma-mcp --version
```

預期輸出：`0.9.2` 或以上版本號。

若系統出現權限錯誤（npm EACCES），以下擇一解決：

```bash
# 方案 A：使用 sudo（不推薦）
sudo npm install -g claude-talk-to-figma-mcp

# 方案 B：修改 npm 全域路徑（推薦）
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
# 在 ~/.bashrc 或 ~/.zshrc 新增以下行後重啟終端機
export PATH=~/.npm-global/bin:$PATH
# 再次安裝
npm install -g claude-talk-to-figma-mcp
```

### Step 2-2：在 Figma Desktop 安裝 Plugin

`claude-talk-to-figma-mcp` 的寫入能力透過 Figma Plugin 橋接，需要在 Figma Desktop 中安裝對應的 Plugin。

**方式 A：從 Figma 社群搜尋安裝（推薦）**

1. 在 Figma Desktop 頂部搜尋列輸入 "Talk to Figma" 或前往 [Figma Community](https://www.figma.com/community)
2. 搜尋 "claude-talk-to-figma" 或 "Talk to Figma MCP"
3. 找到對應 Plugin 後點擊 **Install**

**方式 B：從開發模式安裝（備選）**

若社群找不到對應 Plugin：

1. 開啟 Figma Desktop，開啟任意文件
2. 前往 **Main Menu > Plugins > Development > New Plugin**
3. 選擇 **Link existing plugin**（若你有 Plugin ID）
   或選擇 **Create new plugin** 並依照套件 README 中的 Plugin 建立指引操作

### Step 2-3：啟動 MCP Server（WebSocket 模式）

在終端機中啟動 WebSocket Server：

```bash
# 啟動（預設 port 3000）
claude-talk-to-figma-mcp

# 若 port 3000 已被佔用，指定其他 port
claude-talk-to-figma-mcp --port 3055
```

Server 啟動後，終端機應顯示：

```
WebSocket server running on ws://localhost:3000
Waiting for Figma Plugin connection...
```

**保持此終端機視窗開啟**，整個工作期間 Server 必須持續運行。

### Step 2-4：在 Figma Desktop 執行 Plugin 並連接

1. 在 Figma Desktop 中開啟你的目標 Figma 文件（或建立新文件）
2. 前往 **Main Menu > Plugins > [你安裝的 Talk to Figma Plugin]** 並執行
3. Plugin UI 面板開啟後，在 Server URL 輸入框填入：`ws://localhost:3000`（或步驟 2-3 指定的 port）
4. 點擊 **Connect**

**連接成功標準**：

- Plugin UI 面板顯示 **"Connected"** 狀態（通常為綠色）
- 終端機 MCP Server 輸出：`Figma Plugin connected`

若 Plugin UI 顯示連接失敗，參見本文件末尾「Part 5：常見問題排除」。

---

## Part 3：官方 Figma MCP Server 設定（API Token 配置）

官方 Figma MCP Server 提供唯讀操作能力，透過 Figma Desktop App 的本地 SSE 端點運作。

### Step 3-1：確認官方 MCP Server 已啟動

1. 確認 Figma Desktop App 已開啟並登入
2. 官方 Figma MCP Server 在 Figma Desktop 啟動後自動監聽本地端點：`http://127.0.0.1:3845/sse`

**驗證官方 Server 是否運行**：

在瀏覽器或終端機中訪問此端點：

```bash
curl http://127.0.0.1:3845/sse
```

若 Figma Desktop 正常運行，應會收到 SSE 串流回應（持續輸出數據）。若連接被拒（Connection refused），表示 Figma Desktop 未開啟或未正常啟動 MCP Server。

### Step 3-2：在 Claude Code 設定 MCP Server 連接

開啟 Claude Code 的 MCP 設定檔（路徑：`~/.claude/settings.json`）。若檔案已有其他 MCP 設定，在 `mcpServers` 物件中新增以下兩筆：

```json
{
  "mcpServers": {
    "claude-talk-to-figma": {
      "command": "claude-talk-to-figma-mcp",
      "args": [],
      "env": {}
    },
    "figma-official": {
      "url": "http://127.0.0.1:3845/sse"
    }
  }
}
```

**說明**：

| 設定項目 | 說明 |
|---------|------|
| `claude-talk-to-figma` | 寫入層 MCP，透過 stdio 啟動 WebSocket Bridge |
| `figma-official` | 讀取層 MCP，連接 Figma Desktop 本地 SSE 端點 |

若官方 MCP Server 需要 API Token（某些版本可能需要），在 `figma-official` 設定中加入：

```json
"figma-official": {
  "url": "http://127.0.0.1:3845/sse",
  "env": {
    "FIGMA_ACCESS_TOKEN": "${FIGMA_ACCESS_TOKEN}"
  }
}
```

（`${FIGMA_ACCESS_TOKEN}` 會自動從系統環境變數或 `.env.local` 讀取。）

### Step 3-3：重新載入 Claude Code MCP 連接

設定完成後，在 Claude Code 中執行：

```
/mcp
```

確認輸出中同時出現以下兩個 MCP Server：

- `claude-talk-to-figma`（工具清單應包含 `create_frame`、`set_auto_layout` 等 87 個工具）
- `figma-official`（工具清單應包含 `get_screenshot`、`get_design_context` 等讀取工具）

---

## Part 4：MCP 連線驗證步驟

以下三個驗證指令依序執行，確認整體管線可運作。每個指令均需在 Claude Code 中輸入。

### 驗證指令一：create_frame — 建立測試 Frame

**目的**：驗證寫入層（claude-talk-to-figma）連接正常。

在 Claude Code 中輸入以下提示：

```
請透過 claude-talk-to-figma MCP，在目前開啟的 Figma 文件中建立一個
名為 "SOP-Verification-Test" 的 Frame，寬度 400px、高度 300px，
位置設定在 (0, 0)。
```

**預期結果**：
- Claude Code 呼叫 `create_frame` 工具，回傳成功訊息
- Figma Canvas 中出現名為 `SOP-Verification-Test` 的 Frame
- Frame 尺寸為 400x300px（可在 Figma 右側屬性面板確認）

**清除測試 Frame**（驗證通過後執行）：

```
請刪除剛才建立的 SOP-Verification-Test Frame。
```

### 驗證指令二：get_variables — 讀取 Variable 清單

**目的**：驗證 Variable 讀取能力，為後續 Design Token 綁定做準備。

在 Claude Code 中輸入：

```
請透過 claude-talk-to-figma MCP，使用 get_variables 工具
讀取目前 Figma 文件中所有已定義的 Variables，並列出結果。
若文件尚無 Variables，回報「目前無 Variables」即可。
```

**預期結果**：
- Claude Code 呼叫 `get_variables` 工具
- 回傳 Variables 清單（或「目前無 Variables」的確認訊息）
- 無錯誤發生（若報錯，參見 Part 5 故障排除）

### 驗證指令三：export_node_as_image — 匯出截圖

**目的**：驗證截圖讀取能力，確認視覺驗證（Vision Critic）路徑可用。

此驗證需先有一個可匯出的 Frame（使用驗證指令一建立的 Frame，或文件中任意現有 Frame）。

在 Claude Code 中輸入：

```
請透過 claude-talk-to-figma MCP，執行以下步驟：
1. 使用 get_document_info 取得目前文件的基本資訊
2. 使用 get_pages 列出所有 Page 及其 node ID
3. 在目前頁面中找到任意一個 Frame（使用 get_node_info 或文件結構）
4. 使用 export_node_as_image 工具將該 Frame 匯出為 PNG 格式
5. 回報匯出結果（是否成功、節點 ID、輸出格式）
```

**預期結果**：
- `export_node_as_image` 呼叫成功
- 回傳 base64 編碼的圖片數據或圖片 URL
- 無錯誤訊息

---

## Part 5：Sprint 55 動態 AC 驗證清單

Sprint 55 包含三個含動態 AC 的 Story（US-145、US-148、US-147），以下提供逐一對應的驗證步驟與預期結果。

> **說明**：動態 AC 需要 Figma Desktop App 開啟且 MCP 連接正常（已完成 Part 1-4）才能執行。

---

### US-145：Figma MCP Server 選型與本地設定驗證

**AC1 驗證：MCP 連接成功**

| 驗證項目 | 驗證方式 | 預期結果 |
|---------|---------|---------|
| npm 套件安裝 | 執行 `claude-talk-to-figma-mcp --version` | 輸出版本號（0.9.2 或以上） |
| Plugin 連接 | Figma Desktop 中 Plugin UI 顯示狀態 | 顯示 "Connected"（綠色） |
| CLI Server 連接 | 觀察 MCP Server 終端機輸出 | 顯示 "Figma Plugin connected" |
| Claude Code MCP | 在 Claude Code 執行 `/mcp` | 輸出中含 `claude-talk-to-figma` Server |
| 工具清單 | `/mcp` 輸出的工具列表 | 包含 `create_frame`、`set_auto_layout`、`create_component_instance` |

**AC1 執行清單**：

- [ ] `npm install -g claude-talk-to-figma-mcp` 執行成功，無錯誤
- [ ] 終端機 MCP Server 顯示 "WebSocket server running on ws://localhost:3000"
- [ ] Figma Desktop App 已開啟，Plugin 已執行並顯示 Connected
- [ ] CLI Server 顯示 "Figma Plugin connected"
- [ ] Claude Code `/mcp` 輸出可見 `claude-talk-to-figma` Server 及工具清單

**AC2 驗證：寫入工具可用性測試**

在 Claude Code 中輸入：

```
請透過 claude-talk-to-figma MCP，在目前開啟的 Figma 文件中建立一個
名為 "US-145-Test" 的 Frame，尺寸為 1440x900px，位置在 (0, 0)。
```

**成功標準**：Frame 出現於 Figma Canvas，名稱為 `US-145-Test`，尺寸 1440x900px。

**AC2 執行清單**：

- [ ] 透過 Claude Code 呼叫 `create_frame` 工具成功（無報錯）
- [ ] Frame 出現於 Figma Canvas（目視確認）
- [ ] Frame 的名稱與尺寸與呼叫參數一致

測試完成後清除測試 Frame：

```
請刪除剛才建立的 US-145-Test Frame。
```

---

### US-148：Component Library 元件建立驗證

**AC1 驗證：三個元件已建立**

在 Claude Code 中輸入：

```
請透過 claude-talk-to-figma MCP，使用 get_local_components 工具
列出目前 Figma 文件中所有的本地 Component（Figma Master Component）。
```

**AC1 成功標準**：回傳清單中包含以下三個 Component（或在 `_Component-Library` Page 目視確認）：

| Component 名稱 | 所在 Page | 預期存在 |
|--------------|---------|---------|
| `Button/Primary` | `_Component-Library` 或 `Component Library` | 是 |
| `Input/Default` | `_Component-Library` 或 `Component Library` | 是 |
| `Card/Default` | `_Component-Library` 或 `Component Library` | 是 |

**AC1 執行清單**：

- [ ] `get_local_components` 呼叫成功
- [ ] 回傳清單包含 `Button/Primary`
- [ ] 回傳清單包含 `Input/Default`
- [ ] 回傳清單包含 `Card/Default`
- [ ] 三個元件均位於 Component Library Page（非其他 Page）

**AC2 驗證：Auto Layout 與 Variable 綁定**

在 Claude Code 中輸入（以 Button 為例）：

```
請透過 claude-talk-to-figma MCP，執行以下驗證：
1. 使用 get_local_components 找到 Button/Primary 的 node ID
2. 使用 get_node_info 讀取該 Component 的完整屬性
3. 確認是否有 Auto Layout 設定（layoutMode 為 HORIZONTAL）
4. 確認是否有 Figma Variable 綁定（fills 屬性是否包含 Variable 引用）
```

**AC2 成功標準**：

- Button：`layoutMode = HORIZONTAL`，背景色綁定 `color/primary/500`
- Input：`layoutMode = VERTICAL`，邊框色綁定 `color/neutral/200`
- Card：`layoutMode = VERTICAL`，背景色綁定 `color/neutral/0`

**AC2 執行清單**：

- [ ] Button 的 `layoutMode` 為 HORIZONTAL（gap 8px，padding 16/8px）
- [ ] Button 背景色已綁定 Variable `color/primary/500`
- [ ] Input 外框的 `layoutMode` 為 VERTICAL（gap 6px）
- [ ] Input 邊框色已綁定 Variable `color/neutral/200`
- [ ] Card 的 `layoutMode` 為 VERTICAL（gap 16px，padding 24px 全向）
- [ ] Card 背景色已綁定 Variable `color/neutral/0`

**AC3 驗證：AI 可引用元件 Instance**

在 Claude Code 中輸入：

```
請透過 claude-talk-to-figma MCP，進行元件引用驗證：

步驟 1：使用 get_local_components 列出所有本地元件，
        記錄 Button/Primary、Input/Default、Card/Default 三個元件的 Component Key。

步驟 2：確認或建立 Sprint-55-Component-PoC Page，切換至該 Page。

步驟 3：使用 create_frame 建立驗證 Frame：
        名稱 US-148-AC3-Verification，尺寸 1440x900px。

步驟 4：分別使用 create_component_instance 引用三個元件的 Component Key，
        將 Instance 放置於 US-148-AC3-Verification Frame 中。

步驟 5：使用 export_node_as_image 匯出 US-148-AC3-Verification Frame 截圖，
        確認三個元件 Instance 可見。
```

**AC3 執行清單**：

- [ ] `get_local_components` 回傳清單包含三個 Component
- [ ] `create_component_instance` 呼叫 Button Component Key 成功
- [ ] `create_component_instance` 呼叫 Input Component Key 成功
- [ ] `create_component_instance` 呼叫 Card Component Key 成功
- [ ] US-148-AC3-Verification Frame 中三個 Instance 可在 Figma Canvas 目視確認

---

### US-147：AI Frame 生成 PoC 驗證

**AC2 驗證：Frame 存在於指定 Page**

在 Claude Code 中輸入：

```
請透過 claude-talk-to-figma MCP，使用 get_pages 列出所有 Page，
確認是否存在名為 "Sprint-55-FigmaIntegration" 的 Page，
並確認該 Page 中是否有名為 "POC-US-147-FrameGeneration-Desktop" 的 Frame。
```

**成功標準**：

- `Sprint-55-FigmaIntegration` Page 存在
- `POC-US-147-FrameGeneration-Desktop` Frame 存在於該 Page，尺寸 1440x900px

**AC3 驗證：Auto Layout 已設定**

在 Claude Code 中輸入：

```
請透過 claude-talk-to-figma MCP，讀取 POC-US-147-FrameGeneration-Desktop Frame 及其子節點的屬性，
確認以下 Auto Layout 設定：
- 主 Frame：layoutMode = VERTICAL
- Header 子 Frame：layoutMode = HORIZONTAL，itemSpacing = 16
- Main-Content 子 Frame：layoutMode = VERTICAL，itemSpacing = 48
```

**AC3 執行清單**：

- [ ] 主 Frame `POC-US-147-FrameGeneration-Desktop` 設定 `layoutMode = VERTICAL`
- [ ] `Main-Content` 子 Frame 設定 `layoutMode = VERTICAL`，`itemSpacing = 48`
- [ ] `Header` 子 Frame 設定 `layoutMode = HORIZONTAL`，`itemSpacing = 16`

**AC4 驗證：Figma Variable 綁定**

在 Claude Code 中輸入：

```
請透過 claude-talk-to-figma MCP，使用 get_variables 確認文件中
"color/primary/500" 和 "color/background/primary" Variables 是否存在，
並使用 get_node_info 讀取 Header 或 Screenshot-Placeholder 節點，
確認 fills 屬性是否包含 Variable 綁定（而非直接 hex 值）。
```

**AC4 執行清單**：

- [ ] `color/primary/500` Variable 存在於文件
- [ ] `color/background/primary` Variable 存在於文件
- [ ] `Header` 或 `Screenshot-Placeholder` 節點的 fills 屬性顯示 Variable 名稱

**AC5 驗證：截圖可讀取**

在 Claude Code 中輸入：

```
請透過 claude-talk-to-figma MCP，使用 export_node_as_image 工具
匯出 POC-US-147-FrameGeneration-Desktop Frame 為 PNG 格式，
確認能成功取得截圖數據。
```

**AC5 執行清單**：

- [ ] `export_node_as_image` 工具呼叫成功
- [ ] 截圖數據（base64 或 URL）已取得
- [ ] `docs/design/poc-screenshots/POC-US-147-FrameGeneration.png` 檔案已儲存

---

## Part 6：常見問題排除

### 故障情境 A：WebSocket 連接失敗

**症狀**：Plugin UI 顯示連接失敗、"Connection refused" 或超時，且終端機 Server 未顯示 "Figma Plugin connected"。

**排查步驟**：

**步驟 1：確認 MCP Server 是否在執行**

```bash
# 確認 port 3000 是否有行程在監聽
# macOS / Linux
lsof -i :3000
# Windows
netstat -ano | findstr :3000
```

若無輸出，表示 Server 未啟動。重新執行：

```bash
claude-talk-to-figma-mcp
```

**步驟 2：確認 Plugin 使用的 URL 正確**

Plugin UI 中的 Server URL 必須完全匹配（含協議前綴）：

- 正確：`ws://localhost:3000`（預設）
- 錯誤：`localhost:3000`（缺少 ws:// 前綴）
- 錯誤：`http://localhost:3000`（協議錯誤）

若使用自訂 port（如 3055），URL 應為 `ws://localhost:3055`。

**步驟 3：確認防火牆未封鎖本地 WebSocket**

某些企業環境的安全策略會封鎖 localhost WebSocket 連接。嘗試關閉防火牆或白名單 port 3000。

**步驟 4：重啟 Plugin 與 Server**

1. 在 Figma Desktop 中關閉 Plugin（點擊 Plugin UI 右上角 X）
2. 按 `Ctrl+C`（或 `Cmd+C`）停止 MCP Server
3. 重新啟動 MCP Server：`claude-talk-to-figma-mcp`
4. 重新在 Figma Desktop 執行 Plugin，重新連接

**步驟 5：更換 Port**

若 port 3000 持續衝突：

```bash
# 使用 port 3055
claude-talk-to-figma-mcp --port 3055
```

Plugin UI 中 Server URL 改為 `ws://localhost:3055`。

---

### 故障情境 B：Figma API Token 無效

**症狀**：Claude Code 呼叫官方 Figma MCP Server 工具時，收到 `401 Unauthorized` 或 `Invalid token` 錯誤；或 `curl http://127.0.0.1:3845/sse` 回傳認證錯誤。

**排查步驟**：

**步驟 1：確認 Token 值正確**

```bash
# 確認環境變數已設定
echo $FIGMA_ACCESS_TOKEN
```

若輸出為空，表示環境變數未載入。確認 `.env.local` 檔案存在且內容正確：

```bash
cat .env.local
# 應看到 FIGMA_ACCESS_TOKEN=figd_xxxxxxxxxxxxxxxx
```

手動匯出環境變數：

```bash
export FIGMA_ACCESS_TOKEN=figd_xxxxxxxxxxxxxxxx
```

**步驟 2：確認 Token 未過期**

Token 效期最長 90 天。前往 Figma Settings > Security > Personal access tokens，確認 Token 狀態。若已過期，重新生成並更新 `.env.local`。

**步驟 3：確認 Token Scope 正確**

Token 必須包含 `file_content:read` Scope。若 Token 為舊版（無 Scope 設定），需重新生成包含必要 Scope 的 Token。

**步驟 4：直接測試 Token 有效性**

```bash
# 使用 REST API 直接測試 Token
curl -H "X-Figma-Token: $FIGMA_ACCESS_TOKEN" \
  https://api.figma.com/v1/me
```

正常回應應顯示你的 Figma 帳號資訊（JSON 格式）。若回傳 `{"status": 403, ...}` 或 `{"err": "..."}` 表示 Token 無效。

**步驟 5：重新生成 Token**

1. 前往 Figma Settings > Security > Personal access tokens
2. 撤銷舊 Token（點擊 Revoke）
3. 生成新 Token（含 `file_content:read` Scope）
4. 更新 `.env.local` 中的 `FIGMA_ACCESS_TOKEN` 值

---

### 故障情境 C：Plugin 未載入或無法找到

**症狀**：Figma Desktop Main Menu > Plugins 中找不到已安裝的 Talk to Figma Plugin；或 Plugin 執行後立即崩潰。

**排查步驟**：

**步驟 1：確認 Plugin 安裝狀態**

1. 開啟 Figma Desktop，前往 **Main Menu > Plugins > Manage plugins**
2. 搜尋 "Talk to Figma" 或 "claude-talk-to-figma"
3. 若 Plugin 出現但未安裝，點擊 **Install**
4. 若 Plugin 完全找不到，重新在 Figma Community 搜尋

**步驟 2：確認是否在 Figma 文件中（非首頁）**

Plugin 只能在已開啟的 Figma 文件中執行，無法在 Figma 首頁執行。

1. 從 Figma 首頁開啟任意文件（或建立新文件）
2. 在文件中前往 **Main Menu > Plugins > [Talk to Figma Plugin]**

**步驟 3：確認 Figma Desktop App 版本**

舊版 Figma Desktop 可能與 Plugin 版本不相容。更新 Figma Desktop 至最新版：

- macOS：Figma Desktop > Figma Menu > Check for updates
- Windows：透過 Windows 設定或 Figma 官網下載最新版

**步驟 4：重新安裝 Plugin**

1. 在 **Manage plugins** 中卸載現有的 Talk to Figma Plugin
2. 重新從 Figma Community 搜尋並安裝
3. 重新啟動 Figma Desktop（完全關閉後重開）

**步驟 5：使用開發模式安裝（備選）**

若社群版 Plugin 持續有問題，改用 Development 模式從 npm 套件的 Plugin 源碼安裝：

```bash
# 找到 npm 全域安裝路徑中 Plugin 相關文件
npm root -g
# 通常在 /usr/local/lib/node_modules/claude-talk-to-figma-mcp/plugin/ 或類似路徑
```

在 Figma Desktop 中透過 **Main Menu > Plugins > Development > New Plugin > Import plugin from manifest** 載入 `manifest.json`。

---

## 附錄 A：環境啟動標準順序

每次開始工作前，依以下順序啟動環境（順序不可顛倒）：

```
1. 啟動 Figma Desktop App（確認已登入）
2. 在 Figma Desktop 開啟目標 Figma 文件
3. 終端機啟動 MCP Server：
   $ claude-talk-to-figma-mcp
   等待顯示 "Waiting for Figma Plugin connection..."
4. 在 Figma Desktop 執行 Talk to Figma Plugin
   填入 Server URL：ws://localhost:3000
   點擊 Connect，等待顯示 "Connected"
5. 終端機確認顯示 "Figma Plugin connected"
6. 啟動 Claude Code（或在已開啟的 Claude Code 中執行 /mcp 確認連接）
```

---

## 附錄 B：工具速查表

### claude-talk-to-figma-mcp 常用工具

| 工具名稱 | 類別 | 常用場景 |
|---------|------|---------|
| `create_frame` | 寫入 | 建立新 Frame（指定名稱、尺寸、位置） |
| `set_auto_layout` | 寫入 | 設定 Frame 的 Auto Layout（方向、間距、Padding） |
| `create_component_instance` | 寫入 | 引用 Component Library 元件，建立 Instance |
| `apply_variable_to_node` | 寫入 | 將 Design Token Variable 套用至節點屬性 |
| `create_text` | 寫入 | 建立文字層 |
| `set_fill_color` | 寫入 | 設定節點背景填充色 |
| `get_document_info` | 讀取 | 取得文件基本資訊（名稱、ID） |
| `get_pages` | 讀取 | 列出所有 Page |
| `get_node_info` | 讀取 | 讀取節點詳細屬性 |
| `get_local_components` | 讀取 | 列出本地 Component Library |
| `get_variables` | 讀取 | 讀取文件 Variables 清單 |
| `export_node_as_image` | 讀取 | 匯出節點截圖（PNG / JPEG / SVG） |
| `set_current_page` | 導覽 | 切換至指定 Page |
| `insert_child` | 結構 | 將子節點插入父節點 |

### 官方 Figma MCP Server 工具（部分）

| 工具名稱 | 用途 |
|---------|------|
| `get_screenshot` | 取得 Frame / 節點截圖 |
| `get_design_context` | 取得設計脈絡（元件樹、樣式資訊） |

---

## 附錄 C：版本鎖定建議

為確保環境穩定性，在 `package.json` 中鎖定套件版本：

```json
{
  "devDependencies": {
    "claude-talk-to-figma-mcp": "^0.9.0"
  }
}
```

版本升級流程：

1. 新版本發布後，先在非生產 Figma 文件中測試
2. 確認所有 MCP 工具行為正常後，更新版本鎖定
3. 在 Sprint Retro 記錄版本變更

---

## 參考文件

- [ADR-015：UIUX 管線架構轉型 — Figma 整合](../adr/ADR-015-figma-integration.md)
- [Figma MCP Server 選型與本地設定指南](figma-mcp-setup.md)（US-145，Sprint 55）
- [Figma 文件結構指南](../design/figma-structure-guide.md)（US-146，Sprint 55）
- [Component Library 規格文件](../design/component-library-spec.md)（US-148，Sprint 55）
- [AI 生成 Frame PoC 執行計畫](../design/poc-frame-generation-guide.md)（US-147，Sprint 55）
- [claude-talk-to-figma-mcp npm 套件](https://www.npmjs.com/package/claude-talk-to-figma-mcp)
- [Figma Plugin API 官方文件](https://www.figma.com/plugin-docs/)
- [Figma MCP Server 官方開發者文件](https://developers.figma.com/docs/figma-mcp-server/)
- [Figma 個人 Access Token 管理](https://help.figma.com/hc/en-us/articles/8085703771159-Manage-personal-access-tokens)

---

## 版本記錄

| 版本 | 日期 | 變更說明 |
|------|------|---------|
| v1.0 | 2026-03-06 | 初始建立（US-150，Sprint 56） |
