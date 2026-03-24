# Vision Critic — 評分框架

> 參照自 `skills/vision-critic/SKILL.md` §5–§6

---

## §5 視覺比對規則（ADR-015 + ADR-014 OQ-3 決策對齊）

Vision Critic Agent 對 Figma Frame 執行**三維度視覺比對**，每個維度輸出 0–100 分，加權合算為總分。

**評分基準**：對照 `docs/design/component-library-spec.md`（元件規格）與 `docs/design/design-tokens.json`（13 個 Figma Variables）。審查對象從前端代碼截圖升級為 Figma Frame 截圖 + 節點結構資料 + Variable 綁定狀態（ADR-015 架構簡化效益）。

---

### 5.1 統一評分矩陣

三個維度共用相同的 0–100 分量表結構。以下為統一評分矩陣與各維度的差異判定標準：

| 分數範圍 | 維度一：佈局一致性（35%） | 維度二：Design Token 符合度（40%） | 維度三：元件規範符合度（25%） |
|---------|----------------------|-------------------------------|--------------------------|
| 90–100 | Auto Layout 完整設定；間距完全對應 Spacing Scale；對齊符合規格 | 所有顏色屬性已綁定 Variable；字型符合 Typography Token；間距已綁定或使用 Scale 值 | 所有 UI 元件為 Component Instance；尺寸、圓角、Auto Layout 完全符合規格 |
| 70–89 | Auto Layout 已設定；間距偏差 ≤ 4px；1–2 個子 Frame 對齊偏差 | 主要互動元件已綁定 Variable；1–2 個次要節點 hardcode 但色碼值偏差 ≤ 5% | 主要元件使用 Instance；1 個次要元件屬性偏差（如圓角差 ≤ 2px） |
| 50–69 | Auto Layout 已設定但間距偏差 5–16px；3+ 子元素對齊不一致 | 綁定不完整；3+ 節點 hardcode；字型大小偏差 ≤ 2px | 部分元件用 Instance，部分自繪 Frame；尺寸偏差 ≤ 8px |
| 0–49 | 主 Frame 未設定 Auto Layout（**Hard Gate HG-3**）；或偏差 > 16px | 無任何 Variable 綁定（**Hard Gate HG-1**）；或色碼偏差 > 10% | 主要元件未使用 Instance（**Hard Gate HG-2**）；或尺寸偏差 > 8px |

### 5.2 維度一：佈局一致性（權重 35%）

**評估目標**：Figma Frame 的 Auto Layout 結構是否符合設計規格，間距是否遵循 Spacing Scale，對齊方式是否正確。

**資料來源**：截圖視覺 + `get_node_info` / `get_nodes_info` 結構資料（`layoutMode`、`itemSpacing`、`padding*` 屬性）。

**具體稽核項目**：

| 稽核項目 | 通過標準 |
|---------|---------|
| 主 Frame Auto Layout 方向 | Desktop 主 Frame = VERTICAL |
| Header 子 Frame | HORIZONTAL，itemSpacing = 16px，paddingLeft/Right = 24px |
| Main-Content 子 Frame | VERTICAL，itemSpacing = 48px，paddingTop/Bottom = 80px |
| 元件 Auto Layout | Button = HORIZONTAL/CENTER/gap 8px；Card = VERTICAL/MIN/gap 16px/padding 24px |
| 間距值合規性 | 所有 itemSpacing 和 padding 值均在 Spacing Scale 允許值清單內 |

**Spacing Scale 允許值清單**（來自 `design-tokens.json`）：`0, 1, 2, 4, 8, 12, 16, 24, 32, 40, 48, 64, 80, 96`（px）

### 5.3 維度二：Design Token 符合度（權重 40%）

**評估目標**：Figma 節點的顏色、字型、間距屬性是否透過 Figma Variable 綁定（非 hardcode）。權重最高，直接影響設計系統一致性與可維護性。

**資料來源**：`get_variables`（Variable 清單）+ `get_node_info`（`boundVariables` 屬性確認）。

**Variable 綁定驗證**：使用 `get_node_info` 讀取節點 `boundVariables` 屬性，確認 `boundVariables.fills[0].id` 對應 Variable ID 而非空物件。

**13 個 Figma Variables 驗證清單**（來自 `design-tokens.json`）：

| Figma Variable 名稱 | 色碼值 | 關聯元件 |
|-------------------|-------|---------|
| `color/primary/500` | `#3b82f6` | Button Primary 背景色、Input focus 邊框色 |
| `color/primary/600` | `#2563eb` | Button Primary hover 背景色 |
| `color/primary/50` | `#eff6ff` | Button Ghost hover 背景色 |
| `color/secondary/700` | `#334155` | Button Secondary 文字色 |
| `color/secondary/900` | `#0f172a` | Card 標題文字色 |
| `color/secondary/500` | `#64748b` | Card 內文文字色 |
| `color/danger/500` | `#ef4444` | Button Danger 背景色、Input error 邊框色 |
| `color/danger/700` | `#b91c1c` | Button Danger hover 背景色 |
| `color/danger/50` | `#fef2f2` | Input error 背景色 |
| `color/neutral/0` | `#ffffff` | Card 背景色、Button 文字色 |
| `color/neutral/100` | `#f3f4f6` | Input 背景色、Button Secondary 背景色 |
| `color/neutral/200` | `#e5e7eb` | Input 邊框色、Card Outlined 邊框色 |
| `color/neutral/400` | `#9ca3af` | Placeholder 文字色 |

### 5.4 維度三：元件規範符合度（權重 25%）

**評估目標**：UI 元件是否引用 Component Library 中的 Component Instance，屬性是否符合 `docs/design/component-library-spec.md` 定義的規格。

**資料來源**：截圖視覺 + `get_local_components`（元件清單）+ `get_node_info`（節點類型與屬性）。

**元件規格稽核摘要**（完整規格見 `component-library-spec.md`）：

| 元件 | 高度 | 圓角 | Padding | Auto Layout | 元件類型 |
|------|------|------|---------|-------------|---------|
| Button | 40px (±2px) | 6px | H:16px V:8px | HORIZONTAL/CENTER/gap 8px | COMPONENT 或 INSTANCE |
| Input | 40px (±2px) | 4px | H:12px V:8px | HORIZONTAL | COMPONENT 或 INSTANCE |
| Card | ≥200px | 8px | 全向 24px | VERTICAL/gap 16px | COMPONENT 或 INSTANCE |

---

## §6 通過/不通過閾值（ADR-014 OQ-3 + ADR-015 架構對齊）

### 6.1 總分計算

```
總分 = (佈局一致性分 × 0.35) + (Design Token 符合度分 × 0.40) + (元件規範符合度分 × 0.25)
```

**加權設計理由**（ADR-014 OQ-3 決策，依 ADR-015 調整維度名稱）：

- **Design Token 符合度（40%）**：影響設計系統一致性與可維護性，為最高權重；Figma Variable 綁定是 ADR-015 管線的核心品質指標
- **佈局一致性（35%）**：決定 Auto Layout 結構品質，確保跨 Frame 排版規則的一致性
- **元件規範符合度（25%）**：確保 Component Instance 正確使用，維持 Component Library 的重用效益

### 6.2 PASS/FAIL 判定矩陣

| 總分範圍 | 判定結果 | 後續行動 |
|---------|---------|---------|
| ≥ 80 | **PASS** | 設計稿通過審查，可進入代碼生成或交付階段 |
| 60–79 | **CONDITIONAL PASS** | 附改善建議清單，可選擇性修正後重提；不強制退件 |
| < 60 | **FAIL** | 發出結構化退件報告，要求修正並重試（最多 3 次） |

### 6.3 Hard Gate 必要條件

以下任一條件觸發，**無論總分多高均強制判 FAIL**：

| # | Hard Gate 條件 | 說明 |
|---|--------------|------|
| HG-1 | Variable 綁定完全缺失 | 目標 Frame 中無任何節點綁定 Figma Variable（所有色彩均為 hardcode hex 值） |
| HG-2 | 必要元件缺失 | Frame 規格要求使用的 Component Instance（如 Button、Card）不存在，使用原始 Frame 代替 |
| HG-3 | Auto Layout 未設定 | 主 Frame 或主要子 Frame 未設定 Auto Layout（`layoutMode = NONE`），使用絕對定位代替 |

**Hard Gate 邏輯說明**：Figma Variable 綁定完全缺失與元件非 Instance 使用屬結構性品質問題，不允許用其他維度分數「平均掉」。Hard Gate 在審查報告中以獨立欄位 `hardGateViolations` 標記，與維度分數邏輯分離。

### 6.4 重試迴圈終止條件

| 條件 | 說明 |
|------|------|
| PASS（總分 ≥ 80，無 Hard Gate 違規） | 審查通過，退出迴圈，進入代碼生成或交付階段 |
| CONDITIONAL PASS（60–79，無 Hard Gate 違規） | 退出迴圈，附改善建議 |
| 達到最大重試次數（預設 3 次） | 強制退出迴圈，升級為人工審查 |
| AI 連續輸出相同錯誤 | 判定退件報告無效，升級為人工審查 |
