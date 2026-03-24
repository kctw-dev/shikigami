# Vision Critic — Figma MCP 截圖整合方式

> 參照自 `skills/vision-critic/SKILL.md` §4

---

## §4 Figma MCP 截圖整合方式（ADR-015 決策對齊）

### 4.1 決策摘要

ADR-015（2026-03-06 Accepted）：**AI 直接透過 Figma MCP 審查 Figma Frame**。Vision Critic 的截圖來源從 Playwright 渲染前端代碼改為 Figma MCP 直接擷取設計稿截圖，審查基準從「截圖 vs SSD 骨架」改為「截圖 + Design System 規範」。

**MVP 截圖路徑（ADR-015 選定）**：Figma MCP `export_node_as_image`（主要路徑）；官方 Figma MCP Server `get_screenshot`（備援路徑）。

### 4.2 環境需求

**前置條件**：

| 需求項目 | 說明 |
|---------|------|
| Figma Desktop App | 已開啟，目標設計文件已載入 |
| claude-talk-to-figma Plugin | 已安裝並連接（顯示 Connected） |
| claude-talk-to-figma CLI Server | 已啟動（ws://localhost:3000） |
| Claude Code MCP | 已連接 claude-talk-to-figma Server |

### 4.3 截圖取得流程

- **主要路徑**：使用 `export_node_as_image`（claude-talk-to-figma），參數 format=PNG、scale=2。取得 base64 PNG 後以 `<figma_screenshot>` XML 標記包裹。
- **備援路徑**：主要路徑失敗時（WebSocket 斷線），改用官方 Figma MCP 的 `get_screenshot` 工具。

#### 截圖規格要求

| 規格項目 | 值 | 說明 |
|---------|---|------|
| 格式 | PNG | 無損壓縮，確保色彩精確度 |
| 縮放比例 | 2x（200%） | 確保 Design Token 色彩值可精確讀取 |
| 最小解析度 | 960 × 600 px | 低於此解析度可能影響細節識別 |
| 最大解析度 | 2880 × 1800 px | 超出此值對審查精確度無顯著提升，且增加 token 消耗 |

### 4.4 MCP 工具呼叫序列

完整的 MCP 工具呼叫序列定義於 `docs/design/vision-critic-poc-spec.md` §AC3，以下為摘要：

| 步驟 | 工具 | Server | 用途 | 輸入維度 |
|------|------|--------|------|---------|
| Step 1 | `export_node_as_image` | claude-talk-to-figma | 截圖取得 | 維度一、維度三 |
| Step 1（備援） | `get_screenshot` | 官方 Figma MCP | 截圖取得（備援） | 維度一、維度三 |
| Step 2 | `get_nodes_info` | claude-talk-to-figma | 節點結構批次讀取 | 維度一、維度三 |
| Step 3a | `get_variables` | claude-talk-to-figma | Variable 清單取得 | 維度二 |
| Step 3b | `get_node_info`（多次） | claude-talk-to-figma | 各節點 Variable 綁定確認 | 維度二 |
| Step 4 | `get_local_components` | claude-talk-to-figma | 元件引用狀態確認 | 維度三 |
| Step 5 | 無（Agent 內部計算） | — | 評分計算與報告生成 | 全維度 |
