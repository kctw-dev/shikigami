# Vision Critic PoC 規格 — Figma Frame 截圖審查

**建立日期**：2026-03-06
**關聯 ADR**：ADR-014 OQ-3（Vision Critic 通過閾值，三維加權評分 ≥80 PASS）、ADR-015（Figma 整合，Accepted）
**關聯 Story**：US-151（Sprint 56）
**前置依賴**：
- `docs/guides/figma-mcp-setup.md`（MCP Server 選型，雙層架構決策）
- `docs/design/component-library-spec.md`（Button/Input/Card 元件規格）
- `docs/design/poc-frame-generation-guide.md`（Frame 生成 11 步驟序列）
- `docs/design/figma-structure-guide.md`（Page 架構與命名規則）
- `docs/design/design-tokens.json`（13 個 Figma Variables）
**版本**：v1.0

---

## 概覽

本文件定義 Vision Critic PoC（Proof of Concept）的完整審查規格，涵蓋：角色定義、截圖取得流程、三維度評分模型、MCP 工具呼叫序列、退件報告格式。

Vision Critic 是 ADR-014 三層 Agent 管線的第三層（最終守門人）。在 Figma 整合架構（ADR-015）下，其審查對象從「前端代碼截圖」轉型為「Figma Frame 截圖 + 節點結構 + Variable 綁定狀態」，利用 Figma MCP 的原生讀取能力直接獲取設計稿的結構性資料，使審查精確度大幅提升。

---

## AC1：Vision Critic 角色定義與截圖取得流程

### 1.1 Vision Critic 角色定義

**角色**：Vision Critic 是 UIUX 管線的獨立視覺審查 Agent，負責在 AI 生成 Figma Frame 後執行品質守門。

**輸入**：
1. Figma Frame 截圖（PNG，透過 MCP 取得）
2. Figma 節點結構資料（JSON，透過 MCP 讀取）
3. Figma Variable 綁定狀態（JSON，透過 MCP 驗證）
4. 設計規格參照：`docs/design/component-library-spec.md` + `docs/design/design-tokens.json`

**輸出**：
- 三維度評分報告（JSON 格式，含各維度分數與總分）
- 通過判定：PASS / CONDITIONAL PASS / FAIL
- 退件報告（FAIL 或 CONDITIONAL 時，含失敗維度、扣分項、修正建議、對應 MCP 操作）

**與前一版本的差異（Figma 整合後）**：

| 面向 | ADR-014 原始設計（前端截圖） | Figma 整合版（本規格） |
|------|--------------------------|---------------------|
| 截圖來源 | Playwright 自動截圖（渲染 HTML） | Figma MCP `export_node_as_image` 或官方 `get_screenshot` |
| 結構驗證 | 視覺推斷（從像素判斷層級） | `get_node_info` / `get_nodes_info` 直接讀取節點屬性 |
| Token 驗證 | 色碼值比對（可能有渲染偏差） | `get_variables` + `get_node_info` 直接確認 Variable 綁定 |
| 元件符合度 | 截圖比對（需 Reference Image） | `get_local_components` + 節點類型確認 |

**ADR-006 Prompt Injection 防護**：所有透過 MCP 工具取得的外部資料（截圖 base64、節點 JSON、Variable 清單）進入 Vision Critic Agent prompt 時，須以 XML 隔離標記包裹：

```xml
<figma_screenshot>
  [base64 PNG 字串]
</figma_screenshot>

<figma_node_structure>
  [節點 JSON 資料]
</figma_node_structure>

<figma_variable_bindings>
  [Variable 綁定 JSON]
</figma_variable_bindings>

<design_spec_reference>
  [component-library-spec.md 摘要 + design-tokens.json 相關條目]
</design_spec_reference>
```

### 1.2 截圖取得流程

Vision Critic 的截圖取得採用**雙路徑備援設計**，主要路徑使用 `claude-talk-to-figma-mcp` 的 `export_node_as_image` 工具；官方 Figma MCP 的 `get_screenshot` 作為備援。

#### 主要路徑：`export_node_as_image`（claude-talk-to-figma-mcp）

```
前置條件：
1. Figma Desktop App 已開啟，目標文件已載入
2. claude-talk-to-figma-mcp Plugin 已連接（顯示 Connected）
3. claude-talk-to-figma-mcp CLI Server 已啟動（ws://localhost:3000）
4. Claude Code MCP 已連接 claude-talk-to-figma Server

截圖取得步驟：
Step A：使用 get_node_info 取得目標 Frame 的 node ID
Step B：使用 export_node_as_image 匯出截圖
         - node ID：[目標 Frame 的 node ID]
         - format：PNG
         - scale：2（2x 高解析度，確保細節可辨識）
Step C：取得 base64 PNG 字串，傳入 Vision Critic Agent prompt（XML 隔離）
```

#### 備援路徑：`get_screenshot`（官方 Figma MCP Server）

當主要路徑失敗時（WebSocket 斷線、Plugin 未連接），使用官方 MCP：

```
前置條件：
1. Figma Desktop App 已開啟（官方 MCP Server 自動啟動於 http://127.0.0.1:3845/sse）
2. Claude Code MCP 設定已包含 figma-official Server

截圖取得步驟：
Step A：確認 http://127.0.0.1:3845/sse 可存取（Figma Desktop 運行中）
Step B：使用官方 Figma MCP 的 get_screenshot 工具
         - 傳入目標 Frame 的 node ID 或 URL
Step C：取得截圖資料，以相同 XML 隔離標記包裹後傳入 Agent
```

#### 截圖規格要求

| 規格項目 | 值 | 說明 |
|---------|---|------|
| 格式 | PNG | 無損壓縮，確保色彩精確度 |
| 縮放比例 | 2x（200%） | 確保 Design Token 色彩值可精確讀取 |
| 最小解析度 | 960 × 600 px（Desktop 1440px 的 2/3x 下限） | 低於此解析度可能影響細節識別 |
| 最大解析度 | 2880 × 1800 px | 超出此值對審查精確度無顯著提升，且增加 token 消耗 |

---

### 1.3 三維度評分模型定義

Vision Critic 對 Figma Frame 進行三個維度的評估，各維度輸出 0–100 分，加權合算為總分。

#### 三維度總覽

| 維度 | 評估對象 | 資料來源 | 權重 |
|------|---------|---------|------|
| **維度一：佈局一致性** | Auto Layout 結構、間距規則、對齊方式 | 截圖視覺 + `get_node_info` 結構資料 | 35% |
| **維度二：Design Token 符合度** | 顏色、字型、間距 Variable 綁定狀態 | `get_variables` + `get_node_info` 屬性 | 40% |
| **維度三：元件規範符合度** | Button/Input/Card 規格匹配、元件 Instance 使用 | 截圖視覺 + `get_local_components` | 25% |

**總分計算公式**：

```
總分 = (佈局一致性分 × 0.35) + (Design Token 符合度分 × 0.40) + (元件規範符合度分 × 0.25)
```

#### 通過閾值定義（ADR-014 OQ-3 決策）

| 總分範圍 | 判定結果 | 後續行動 |
|---------|---------|---------|
| ≥ 80 | **PASS** | 設計稿通過審查，可進入後端串接或交付階段 |
| 60–79 | **CONDITIONAL PASS** | 附改善建議，可選擇性修正後重提；不強制退件 |
| < 60 | **FAIL** | 發出結構化退件報告，要求修正並重試（最多 3 次） |

#### Hard Gate 強制條件（優先於分數判定）

以下任一條件觸發，無論總分多高均強制判 **FAIL**：

1. **Variable 綁定完全缺失**：目標 Frame 中無任何節點綁定 Figma Variable（所有色彩均為 hardcode hex 值）
2. **必要元件缺失**：Frame 規格要求使用的 Component Instance（如 Button、Card）不存在，使用原始 Frame 代替
3. **Auto Layout 未設定**：主 Frame 或主要子 Frame 未設定 Auto Layout（`layoutMode = NONE`），使用絕對定位代替

---

## AC2：三維度評分模型——具體權重分配

### 2.1 維度一：佈局一致性（權重 35%）

**評估目標**：Figma Frame 的 Auto Layout 結構是否符合設計規格，間距是否遵循 Spacing Scale，對齊方式是否正確。

**評分標準**：

| 分數範圍 | 評估說明 | 對應條件 |
|---------|---------|---------|
| 90–100 | 完全符合佈局規格 | 所有 Frame 已設定 Auto Layout；間距值完全對應 Spacing Scale（`figma-structure-guide.md` §3.5）；主軸對齊與交叉軸對齊符合元件規格 |
| 70–89 | 輕微佈局偏差 | Auto Layout 已設定；間距偏差 ≤ 4px（1 個 Tailwind 基礎單位，對應 `spacing.1`）；1–2 個子 Frame 對齊方式偏差但不影響視覺層級 |
| 50–69 | 中度佈局問題 | Auto Layout 已設定但間距偏差 5–16px；3 個以上子元素對齊不一致；間距值未使用 Spacing Scale（直接 hardcode） |
| 0–49 | 嚴重佈局問題 | 主 Frame 或主要子 Frame 未設定 Auto Layout（觸發 Hard Gate）；或間距值偏差 > 16px，整體視覺節奏嚴重混亂 |

**具體稽核項目**：

| 稽核項目 | 通過標準 | MCP 驗證工具 |
|---------|---------|------------|
| 主 Frame Auto Layout 方向 | 符合 Frame 模板規格（Desktop 主 Frame = VERTICAL） | `get_node_info` → `layoutMode` |
| Header 子 Frame | HORIZONTAL Auto Layout，itemSpacing = 16px，paddingLeft/Right = 24px | `get_node_info` → `layoutMode`、`itemSpacing`、`padding*` |
| Main-Content 子 Frame | VERTICAL Auto Layout，itemSpacing = 48px，paddingTop/Bottom = 80px | `get_node_info` → `layoutMode`、`itemSpacing`、`padding*` |
| 元件 Auto Layout | Button = HORIZONTAL/CENTER/gap 8px；Card = VERTICAL/MIN/gap 16px/padding 24px | `get_node_info` → 各元件節點屬性 |
| 間距值合規性 | 所有 itemSpacing 和 padding 值均在 Spacing Scale 允許值清單內 | 截圖視覺比對 + `get_node_info` |

**Spacing Scale 允許值清單**（來自 `design-tokens.json`）：

```
0px, 1px, 2px, 4px, 8px, 12px, 16px, 24px, 32px, 40px, 48px, 64px, 80px, 96px
```

---

### 2.2 維度二：Design Token 符合度（權重 40%）

**評估目標**：Figma 節點的顏色、字型、間距屬性是否透過 Figma Variable 綁定，而非直接 hardcode 數值。本維度權重最高（40%），因其直接影響設計系統的一致性與可維護性。

**評分標準**：

| 分數範圍 | 評估說明 | 對應條件 |
|---------|---------|---------|
| 90–100 | Variable 綁定完整 | 所有顏色屬性已綁定 Figma Variable；字型大小與字重符合 Typography Token；間距屬性已綁定或使用 Spacing Scale 值 |
| 70–89 | 大部分符合 | 主要互動元件（Button 背景色、Input 邊框色）已綁定 Variable；1–2 個次要節點使用 hardcode 但色碼值與 Token 定義一致（偏差 ≤ 5%） |
| 50–69 | 部分符合 | 主要元件有 Variable 綁定但不完整；3 個以上節點使用 hardcode 值；字型大小偏差 ≤ 2px |
| 0–49 | 嚴重不符 | 無任何 Variable 綁定（觸發 Hard Gate）；或大量顏色 hardcode 且色碼值與 Token 定義偏差 > 10% |

**13 個 Figma Variables 驗證清單**（來自 `design-tokens.json` + `component-library-spec.md`）：

| Figma Variable 名稱 | Token 路徑 | 色碼值 | 關聯元件 |
|-------------------|----------|-------|---------|
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

**Variable 綁定驗證方法**：

使用 `get_node_info` 讀取節點的 `boundVariables` 屬性。若節點有 Variable 綁定，`boundVariables.fills[0].id` 應對應 Variable ID，而非空值。

```json
// Variable 已綁定的節點屬性示例（通過）
{
  "boundVariables": {
    "fills": [{ "type": "VARIABLE_ALIAS", "id": "VariableID:color/primary/500" }]
  }
}

// 未綁定 Variable 的節點（hardcode，需扣分）
{
  "fills": [{ "type": "SOLID", "color": { "r": 0.231, "g": 0.510, "b": 0.965 } }],
  "boundVariables": {}
}
```

---

### 2.3 維度三：元件規範符合度（權重 25%）

**評估目標**：Frame 中使用的 UI 元件是否引用 Component Library 中的 Component Instance，元件屬性是否符合 `component-library-spec.md` 定義的規格（尺寸、圓角、Auto Layout 結構）。

**評分標準**：

| 分數範圍 | 評估說明 | 對應條件 |
|---------|---------|---------|
| 90–100 | 完全符合元件規範 | 所有 UI 元件均為 Component Instance（非自繪 Frame）；元件尺寸、圓角、Auto Layout 完全符合規格；Instance 命名符合 `figma-structure-guide.md` §2.5 規則 |
| 70–89 | 大部分符合 | 主要元件（Button、Card）使用 Component Instance；1 個次要元件屬性偏差（如圓角差 ≤ 2px）；無自繪重複元件 |
| 50–69 | 部分符合 | 部分元件使用 Instance，部分使用自繪 Frame；元件尺寸偏差 ≤ 8px（Button 高度允許 32–48px 範圍內） |
| 0–49 | 嚴重不符 | 主要元件（Button、Input、Card）未使用 Component Instance（觸發 Hard Gate）；或元件尺寸嚴重偏差（> 8px），視覺無法辨識對應元件類型 |

**具體稽核項目（對應 `component-library-spec.md`）**：

**Button 規格稽核**：

| 稽核項目 | 通過標準（md 尺寸） |
|---------|-----------------|
| 高度 | 40px（允許偏差 ±2px） |
| Padding 水平 | 16px（對應 `spacing.4`） |
| Padding 垂直 | 8px（對應 `spacing.2`） |
| 圓角 | 6px（對應 `borderRadius.md`） |
| 字型大小 | 16px（對應 `typography.fontSize.base`） |
| 字重 | 600（對應 `typography.fontWeight.semibold`） |
| 元件類型 | COMPONENT 或 INSTANCE（非普通 FRAME） |

**Input 規格稽核**：

| 稽核項目 | 通過標準 |
|---------|---------|
| 輸入框高度 | 40px（允許偏差 ±2px） |
| 圓角 | 4px（對應 `borderRadius.base`） |
| 字型大小 | 16px |
| Auto Layout（輸入框） | HORIZONTAL，paddingLeft/Right = 12px，paddingTop/Bottom = 8px |
| 元件類型 | COMPONENT 或 INSTANCE |

**Card 規格稽核**：

| 稽核項目 | 通過標準 |
|---------|---------|
| 圓角 | 8px（對應 `borderRadius.lg`） |
| Padding 全向 | 24px（對應 `spacing.6`） |
| Auto Layout 方向 | VERTICAL |
| itemSpacing | 16px（對應 `spacing.4`） |
| 最小高度 | 200px |
| 元件類型 | COMPONENT 或 INSTANCE |

---

### 2.4 權重總和驗證

| 維度 | 權重 |
|------|------|
| 維度一：佈局一致性 | 35% |
| 維度二：Design Token 符合度 | 40% |
| 維度三：元件規範符合度 | 25% |
| **合計** | **100%** |

---

## AC3：MCP 工具呼叫序列

Vision Critic 執行審查的完整 MCP 工具呼叫序列，每步驟標注使用的工具名稱、參數、預期輸出與用途。

### 前置條件確認

```
審查前環境確認：
1. Figma Desktop App 已開啟，目標設計文件已載入
2. claude-talk-to-figma-mcp Plugin 已連接（顯示 Connected）
3. 目標 Frame 已存在於指定 Sprint Page（由 AI Frame 生成工作流完成後）
4. Claude Code MCP 已連接 claude-talk-to-figma Server
```

---

### Step 1：截圖取得

**工具**：`export_node_as_image`（claude-talk-to-figma-mcp）

**用途**：取得 Figma Frame 的高解析度截圖，作為視覺審查的輸入。

**參數**：
```json
{
  "nodeId": "[目標 Frame 的 node ID]",
  "format": "PNG",
  "scale": 2
}
```

**預期輸出**：base64 編碼的 PNG 截圖字串。

**備援工具**：若 `export_node_as_image` 失敗，使用官方 Figma MCP Server 的 `get_screenshot` 工具，傳入相同 node ID。

**輸出用途**：傳入 Vision Critic Agent 的截圖輸入，以 `<figma_screenshot>` XML 標記包裹，供「維度一：佈局一致性」與「維度三：元件規範符合度」的視覺評估。

---

### Step 2：節點結構讀取

**工具**：`get_nodes_info`（claude-talk-to-figma-mcp）

**用途**：批次讀取目標 Frame 及其主要子節點的完整屬性，包含 Auto Layout 設定、尺寸、圓角等結構性資料。

**參數**：
```json
{
  "nodeIds": [
    "[主 Frame node ID]",
    "[Header 子 Frame node ID]",
    "[Main-Content 子 Frame node ID]",
    "[Button Instance node ID（若存在）]",
    "[Input Instance node ID（若存在）]",
    "[Card Instance node ID（若存在）]"
  ]
}
```

**預期輸出**：
```json
{
  "nodes": {
    "[node ID]": {
      "name": "US-XXX-Feature-Desktop",
      "type": "FRAME",
      "layoutMode": "VERTICAL",
      "primaryAxisAlignItems": "MIN",
      "counterAxisAlignItems": "STRETCH",
      "itemSpacing": 0,
      "paddingTop": 0,
      "paddingBottom": 0,
      "paddingLeft": 0,
      "paddingRight": 0,
      "width": 1440,
      "height": 900,
      "cornerRadius": 0,
      "boundVariables": {},
      "children": [...]
    }
  }
}
```

**輸出用途**：提供「維度一：佈局一致性」的結構性資料，驗證 Auto Layout 方向、itemSpacing、Padding 值；提供「維度三：元件規範符合度」的元件屬性（圓角、尺寸）驗證。以 `<figma_node_structure>` XML 標記包裹。

---

### Step 3：Variable 綁定驗證

**工具**：`get_variables`（claude-talk-to-figma-mcp）+ `get_node_info` 確認綁定

**用途**：
1. 讀取文件已定義的所有 Figma Variables，確認 13 個 Design Token Variables 均已建立
2. 對目標節點的 `boundVariables` 屬性進行逐一確認，驗證 Variable 綁定狀態

**Step 3a：取得 Variable 清單**

工具：`get_variables`
```json
{}
```

預期輸出：
```json
{
  "variables": [
    {
      "id": "VariableID:color/primary/500",
      "name": "color/primary/500",
      "resolvedType": "COLOR",
      "valuesByMode": { "default": { "r": 0.231, "g": 0.510, "b": 0.965, "a": 1.0 } }
    },
    ...
  ]
}
```

**Step 3b：確認各節點的 Variable 綁定**

對每個關鍵節點呼叫 `get_node_info`，讀取 `boundVariables` 屬性：

工具：`get_node_info`
```json
{
  "nodeId": "[關鍵節點 node ID（如 Button Frame、Input-Box Frame）]"
}
```

**驗證矩陣**（需逐一確認）：

| 節點 | 期望綁定的 Variable | 對應屬性 |
|------|------------------|---------|
| Button/Primary Frame | `color/primary/500` | `fills` |
| Input-Box（default 狀態） | `color/neutral/200` | `strokes`（邊框色） |
| Card Frame | `color/neutral/0` | `fills` |
| Page 背景或 Main-Content | `color/secondary/50`（`#f8fafc`）或 `color/neutral/50` | `fills` |

**輸出用途**：提供「維度二：Design Token 符合度」的精確量化資料，以 `<figma_variable_bindings>` XML 標記包裹。

---

### Step 4：元件引用狀態確認

**工具**：`get_local_components`（claude-talk-to-figma-mcp）

**用途**：確認 Component Library 中的元件是否存在，並驗證目標 Frame 中的子節點類型是 INSTANCE 而非自繪 FRAME。

**參數**：
```json
{}
```

**預期輸出**：
```json
{
  "components": [
    { "id": "...", "name": "Button/Primary", "key": "..." },
    { "id": "...", "name": "Input/Default", "key": "..." },
    { "id": "...", "name": "Card/Default", "key": "..." }
  ]
}
```

**驗證邏輯**：

從 Step 2 的節點結構中，檢查各 UI 元件節點的 `type` 屬性：
- `type = "INSTANCE"` → 正確使用 Component Instance（加分）
- `type = "FRAME"` 且名稱為 `Button/Primary` → 可能是重建而非引用（扣分）
- 在 `get_local_components` 輸出中找不到對應元件 → Component Library 缺失（扣分）

**輸出用途**：提供「維度三：元件規範符合度」的元件類型驗證資料。

---

### Step 5：評分計算與輸出

**工具**：無（Vision Critic Agent 內部計算）

**用途**：彙整 Step 1–4 的資料，計算三維度分數，輸出最終評分報告。

**評分計算流程**：

```
1. 彙整輸入：
   - 截圖（視覺評估）
   - 節點結構 JSON（Auto Layout、尺寸屬性）
   - Variable 綁定 JSON（13 個 Token 的綁定狀態）
   - 元件引用狀態（INSTANCE vs FRAME）

2. 執行 Hard Gate 檢查：
   - 若無任何 Variable 綁定 → 強制 FAIL，跳過分數計算
   - 若主要元件非 INSTANCE → 強制 FAIL，跳過分數計算
   - 若主 Frame layoutMode = NONE → 強制 FAIL，跳過分數計算

3. 計算三維度分數（0–100）：
   - D1（佈局一致性）：對照 Spacing Scale + Auto Layout 屬性
   - D2（Design Token 符合度）：Variable 綁定數量 / 應綁定總數 × 100 後調整
   - D3（元件規範符合度）：截圖視覺評估 + 節點屬性驗證

4. 計算加權總分：
   totalScore = (D1 × 0.35) + (D2 × 0.40) + (D3 × 0.25)

5. 判定通過等級：
   - totalScore ≥ 80 → PASS
   - 60 ≤ totalScore < 80 → CONDITIONAL PASS
   - totalScore < 60 → FAIL
```

**評分報告 JSON Schema**：

```json
{
  "reviewId": "VCR-{StoryID}-{timestamp}",
  "targetFrame": "{Frame 名稱}",
  "targetNodeId": "{Frame node ID}",
  "reviewedAt": "2026-03-06T00:00:00Z",
  "scores": {
    "layoutConsistency": {
      "score": 0,
      "weight": 0.35,
      "weightedScore": 0,
      "findings": []
    },
    "designTokenCompliance": {
      "score": 0,
      "weight": 0.40,
      "weightedScore": 0,
      "findings": []
    },
    "componentSpecCompliance": {
      "score": 0,
      "weight": 0.25,
      "weightedScore": 0,
      "findings": []
    }
  },
  "totalScore": 0,
  "verdict": "PASS | CONDITIONAL_PASS | FAIL",
  "hardGateViolations": [],
  "recommendations": []
}
```

---

### MCP 工具呼叫序列彙整

| 步驟 | 工具 | Server | 用途 | 輸入維度 |
|------|------|--------|------|---------|
| Step 1 | `export_node_as_image` | claude-talk-to-figma | 截圖取得 | D1、D3 |
| Step 1（備援） | `get_screenshot` | 官方 Figma MCP | 截圖取得（備援） | D1、D3 |
| Step 2 | `get_nodes_info` | claude-talk-to-figma | 節點結構批次讀取 | D1、D3 |
| Step 3a | `get_variables` | claude-talk-to-figma | Variable 清單取得 | D2 |
| Step 3b | `get_node_info`（多次） | claude-talk-to-figma | 各節點 Variable 綁定確認 | D2 |
| Step 4 | `get_local_components` | claude-talk-to-figma | 元件引用狀態確認 | D3 |
| Step 5 | 無（Agent 內部計算） | — | 評分計算與報告生成 | 全維度 |

---

## AC4：退件報告格式定義

當 Vision Critic 判定 **FAIL** 或 **CONDITIONAL PASS** 時，輸出退件報告（Visual Review Report，VRR）。

### 4.1 退件報告輸出格式（JSON）

```json
{
  "reviewId": "VCR-US-151-20260306T120000Z",
  "targetFrame": "US-151-VisionCritic-Desktop",
  "targetNodeId": "node-id-here",
  "reviewedAt": "2026-03-06T12:00:00Z",
  "verdict": "FAIL",
  "totalScore": 54,
  "scores": {
    "layoutConsistency": {
      "score": 72,
      "weight": 0.35,
      "weightedScore": 25.2,
      "findings": [
        {
          "severity": "WARNING",
          "dimension": "layoutConsistency",
          "description": "Main-Content itemSpacing 為 40px，不在 Spacing Scale 允許值清單（期望 48px）",
          "affectedNode": "Main-Content",
          "affectedNodeId": "node-id-main-content",
          "deductionReason": "間距值 hardcode，未使用 spacing.12（48px）Token"
        }
      ]
    },
    "designTokenCompliance": {
      "score": 35,
      "weight": 0.40,
      "weightedScore": 14.0,
      "findings": [
        {
          "severity": "ERROR",
          "dimension": "designTokenCompliance",
          "description": "Button/Primary Frame 背景色為 hardcode #3b82f6，未綁定 Variable color/primary/500",
          "affectedNode": "Button/Primary",
          "affectedNodeId": "node-id-button",
          "deductionReason": "boundVariables.fills 為空，應綁定 color/primary/500",
          "expectedVariable": "color/primary/500",
          "actualValue": "#3b82f6（hardcode）",
          "mcpFix": "apply_variable_to_node",
          "mcpFixParams": {
            "nodeId": "node-id-button",
            "property": "fills",
            "variableName": "color/primary/500"
          }
        },
        {
          "severity": "ERROR",
          "dimension": "designTokenCompliance",
          "description": "Card Frame 背景色未綁定 Variable color/neutral/0",
          "affectedNode": "Card/Default",
          "affectedNodeId": "node-id-card",
          "deductionReason": "boundVariables.fills 為空",
          "expectedVariable": "color/neutral/0",
          "actualValue": "#ffffff（hardcode）",
          "mcpFix": "apply_variable_to_node",
          "mcpFixParams": {
            "nodeId": "node-id-card",
            "property": "fills",
            "variableName": "color/neutral/0"
          }
        }
      ]
    },
    "componentSpecCompliance": {
      "score": 85,
      "weight": 0.25,
      "weightedScore": 21.25,
      "findings": [
        {
          "severity": "INFO",
          "dimension": "componentSpecCompliance",
          "description": "Button/Primary 圓角為 4px，規格要求 6px（borderRadius.md）",
          "affectedNode": "Button/Primary",
          "affectedNodeId": "node-id-button",
          "deductionReason": "圓角值偏差 2px，在可接受範圍但建議修正",
          "expectedValue": "6px",
          "actualValue": "4px",
          "mcpFix": "set_corner_radius",
          "mcpFixParams": {
            "nodeId": "node-id-button",
            "cornerRadius": 6
          }
        }
      ]
    }
  },
  "hardGateViolations": [],
  "recommendations": [
    {
      "priority": "HIGH",
      "dimension": "designTokenCompliance",
      "action": "為 Button/Primary 和 Card/Default 的 fills 屬性套用 Figma Variable 綁定",
      "details": "使用 apply_variable_to_node 工具，分別綁定 color/primary/500 和 color/neutral/0",
      "mcpOperationSequence": [
        {
          "step": 1,
          "tool": "apply_variable_to_node",
          "params": {
            "nodeId": "[Button/Primary node ID]",
            "property": "fills",
            "variableName": "color/primary/500"
          }
        },
        {
          "step": 2,
          "tool": "apply_variable_to_node",
          "params": {
            "nodeId": "[Card/Default node ID]",
            "property": "fills",
            "variableName": "color/neutral/0"
          }
        }
      ]
    },
    {
      "priority": "MEDIUM",
      "dimension": "layoutConsistency",
      "action": "將 Main-Content itemSpacing 從 40px 調整為 48px（spacing.12）",
      "details": "40px 不在 Spacing Scale 允許值清單，最近的合規值為 48px（spacing.12）",
      "mcpOperationSequence": [
        {
          "step": 1,
          "tool": "set_auto_layout",
          "params": {
            "nodeId": "[Main-Content node ID]",
            "itemSpacing": 48
          }
        }
      ]
    },
    {
      "priority": "LOW",
      "dimension": "componentSpecCompliance",
      "action": "將 Button/Primary 圓角從 4px 調整為 6px（borderRadius.md）",
      "details": "目前偏差在 INFO 級別（≤ 2px），建議修正以完全符合規格",
      "mcpOperationSequence": [
        {
          "step": 1,
          "tool": "set_corner_radius",
          "params": {
            "nodeId": "[Button/Primary node ID]",
            "cornerRadius": 6
          }
        }
      ]
    }
  ]
}
```

### 4.2 退件報告欄位定義

| 欄位 | 類型 | 說明 |
|------|------|------|
| `reviewId` | string | 唯一審查 ID，格式 `VCR-{StoryID}-{timestamp}` |
| `targetFrame` | string | 被審查的 Frame 名稱 |
| `targetNodeId` | string | 被審查的 Frame node ID |
| `reviewedAt` | string（ISO 8601） | 審查時間 |
| `verdict` | enum | `PASS`、`CONDITIONAL_PASS`、`FAIL` |
| `totalScore` | number（0–100） | 加權總分 |
| `scores.{dimension}.score` | number（0–100） | 各維度原始分 |
| `scores.{dimension}.weight` | number（0.0–1.0） | 各維度權重 |
| `scores.{dimension}.weightedScore` | number | 各維度加權分（score × weight） |
| `scores.{dimension}.findings` | array | 該維度的具體問題清單 |
| `findings[].severity` | enum | `ERROR`（嚴重，直接扣分）、`WARNING`（警告，部分扣分）、`INFO`（資訊，輕微扣分） |
| `findings[].description` | string | 問題描述（中文） |
| `findings[].affectedNode` | string | 問題所在節點名稱 |
| `findings[].affectedNodeId` | string | 問題所在節點 ID |
| `findings[].deductionReason` | string | 扣分原因說明 |
| `findings[].mcpFix` | string | 推薦的修正 MCP 工具名稱 |
| `findings[].mcpFixParams` | object | 修正 MCP 工具的參數 |
| `hardGateViolations` | array | 強制 FAIL 的 Hard Gate 違規清單（空陣列代表無違規） |
| `recommendations` | array | 排序後的修正建議清單（HIGH/MEDIUM/LOW 優先級） |
| `recommendations[].mcpOperationSequence` | array | 修正所需的 MCP 工具呼叫序列（含 step 編號） |

### 4.3 Hard Gate 退件報告格式

當觸發 Hard Gate 時，`hardGateViolations` 陣列包含違規條目，且 `verdict` 強制為 `FAIL`（不論分數高低）：

```json
{
  "verdict": "FAIL",
  "totalScore": 82,
  "hardGateViolations": [
    {
      "gateId": "HG-001",
      "description": "目標 Frame 中無任何節點綁定 Figma Variable",
      "failReason": "所有顏色屬性均為 hardcode hex 值，未使用任何 Design Token Variable 綁定",
      "requiredAction": "至少為主要元件的一個顏色屬性套用 Variable 綁定（建議 Button 背景色綁定 color/primary/500）",
      "mcpFix": "apply_variable_to_node",
      "mcpFixExample": {
        "nodeId": "[Button Frame node ID]",
        "property": "fills",
        "variableName": "color/primary/500"
      }
    }
  ]
}
```

### 4.4 CONDITIONAL PASS 報告格式

CONDITIONAL PASS（60–79 分）的退件報告使用相同格式，但 `verdict` 為 `CONDITIONAL_PASS`，且 `recommendations` 標記為選擇性修正：

```json
{
  "verdict": "CONDITIONAL_PASS",
  "totalScore": 74,
  "conditionalNotes": "本次審查評分介於 60–79 分（CONDITIONAL PASS 區間）。以下改善建議為選擇性項目，不強制執行；若需提升至 PASS（≥80 分），建議優先處理 HIGH 優先級的修正項目。",
  "recommendations": [
    {
      "priority": "HIGH",
      "isRequired": false,
      "action": "..."
    }
  ]
}
```

---

## 參考文件

- [ADR-014：UIUX Agent 架構決策](../adr/ADR-014-uiux-agent-architecture.md)（OQ-3 Vision Critic 通過閾值）
- [ADR-015：UIUX 管線架構轉型 — Figma 整合](../adr/ADR-015-figma-integration.md)
- [Figma MCP Server 選型與本地設定指南](../guides/figma-mcp-setup.md)
- [Component Library 規格文件](component-library-spec.md)（Button/Input/Card 元件規格）
- [AI 生成 Frame PoC 執行計畫](poc-frame-generation-guide.md)（11 步驟 Frame 生成序列）
- [Figma 文件結構指南](figma-structure-guide.md)（Page 架構與命名規則）
- [Design Tokens](design-tokens.json)（13 個 Figma Variable 定義）
- [ADR-006：Issue 內容提示注入防護](../adr/ADR-006-prompt-injection.md)（XML 隔離標記規則）
- [Figma Plugin API — Variables](https://www.figma.com/plugin-docs/api/figma-variables/)
- [Figma Plugin API — Node Types](https://www.figma.com/plugin-docs/api/node-types/)

---

## 版本記錄

| 版本 | 日期 | 變更說明 |
|------|------|---------|
| v1.0 | 2026-03-06 | 初始建立（US-151，Sprint 56） |
