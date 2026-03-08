# 設計師協作指南

**對象**：使用 Figma 的人類設計師
**目的**：說明你在這個 AI 開發團隊中的角色、如何交付設計稿、以及設計稿交付後會發生什麼事

---

## 你的角色

你是設計的決策者。AI 團隊負責把你的設計稿變成程式碼，但**長什麼樣子由你決定**。

```
你（設計師）          AI 團隊
─────────           ─────────
在 Figma 畫設計    → AI 讀取你的 Figma 設計
定義顏色、間距      → AI 轉成程式碼
審查 AI 產出結果    → AI 修正到你滿意
```

你不需要寫任何程式碼、HTML、CSS。**Figma 就是你唯一的工具。**

---

## 快速開始（三步驟）

### 第一步：在 Figma 畫設計

在團隊的 Figma 文件中，找到對應的 Sprint Page（頁面），建立你的 Frame（畫框）。

### 第二步：把 Figma 連結貼到 Issue

到 GitHub Issue（工作單）裡，貼上你的 Figma Frame 連結，或直接告訴 PO（產品負責人）「設計稿好了」。

### 第三步：等待 AI 產出 & 審查

AI 團隊會讀取你的設計稿、產出程式碼、截圖比對。如果結果不對，AI 會自動修正。你可以在最後審查截圖是否符合你的設計意圖。

---

## Figma 文件結構

團隊的 Figma 文件有固定的 Page（頁面）結構，請遵循：

| Page 名稱 | 用途 | 你會用到嗎？ |
|-----------|------|-------------|
| `_Component-Library` | 元件庫（按鈕、輸入框、卡片等） | 會 — 建立或修改共用元件 |
| `_Design-Tokens` | 顏色、間距、字型的視覺展示 | 會 — 查看或修改設計規格 |
| `_Archive` | 廢棄設計稿的存放處 | 偶爾 — 歸檔舊設計 |
| `Sprint-{N}-{功能名}` | 每個開發週期的設計稿 | **最常用** — 你的設計稿放這裡 |

### Sprint Page 命名範例

```
Sprint-55-FigmaIntegration
Sprint-56-UserDashboard
Sprint-57-LoginRedesign
```

---

## 命名規則

**為什麼要命名規則？** 因為 AI 會讀取你的 Figma 圖層名稱來理解設計結構。好的命名 = AI 產出更準確的程式碼。

### Frame（畫框）命名

格式：`{Story編號}-{功能描述}-{平台}`

| 範例 | 說明 |
|------|------|
| `US-146-Login-Page-Desktop` | 桌面版登入頁 |
| `US-146-Login-Page-Mobile` | 手機版登入頁 |
| `US-147-Dashboard-Default` | 儀表板預設狀態 |
| `US-147-Dashboard-Loading` | 儀表板載入中狀態 |

### 圖層命名

用**語意**（這是什麼）命名，不要用外觀（它長什麼樣）命名。

| 不好的命名 | 好的命名 | 原因 |
|-----------|---------|------|
| `Rectangle 1` | `Card-Background` | AI 不知道 Rectangle 1 是什麼 |
| `Group 2` | `Navigation-Links` | 要表達這個群組的用途 |
| `Blue Button` | `Button/Primary` | 顏色可能會改，語意不變 |
| `Frame 4` | `Login-Form` | 每個 Frame 都要有意義的名字 |

### 元件命名

使用 `/`（斜線）來分類元件：

```
Button/Primary        ← 主要按鈕
Button/Secondary      ← 次要按鈕
Button/Danger         ← 危險操作按鈕
Input/Default         ← 輸入框預設狀態
Input/Error           ← 輸入框錯誤狀態
Card/Default          ← 卡片預設樣式
Card/Outlined         ← 卡片外框樣式
```

---

## Design Token（設計代幣）

Design Token 是**顏色、間距、字型等設計決策的集中管理方式**。

### 什麼是 Design Token？

簡單說：不要在 Figma 裡隨意輸入顏色碼（如 `#3b82f6`），而是使用預先定義好的 **Figma Variable（變數）**。

這樣做的好處：
- 你改一個 Variable，所有用到它的元件自動更新
- AI 產出的程式碼會引用同一套顏色，不會出現色差

### 目前可用的 Token

#### 顏色

| 名稱 | 色碼 | 用途 |
|------|------|------|
| `color/primary/500` | `#3b82f6` 🔵 | 主要按鈕、重點連結 |
| `color/primary/600` | `#2563eb` 🔵 | 按鈕滑鼠懸停（hover）狀態 |
| `color/secondary/700` | `#334155` | 主要內文文字 |
| `color/secondary/900` | `#0f172a` | 標題文字 |
| `color/danger/500` | `#ef4444` 🔴 | 刪除按鈕、錯誤提示 |
| `color/neutral/0` | `#ffffff` ⬜ | 卡片背景、按鈕文字 |
| `color/neutral/100` | `#f3f4f6` | 輸入框背景 |
| `color/neutral/200` | `#e5e7eb` | 邊框預設色 |
| `color/neutral/400` | `#9ca3af` | 佔位文字（placeholder） |

#### 間距

| 名稱 | 值 | 用途 |
|------|-----|------|
| `spacing/xs` | 4px | 極小間距（圖示與文字之間） |
| `spacing/sm` | 8px | 小間距（表單內部元素） |
| `spacing/md` | 16px | 標準間距（卡片內容） |
| `spacing/lg` | 24px | 中等間距（區塊之間） |
| `spacing/xl` | 32px | 大間距（頁面段落之間） |
| `spacing/2xl` | 48px | 超大間距（桌面版主要區塊） |

#### 圓角

| 名稱 | 值 | 用途 |
|------|-----|------|
| `borderRadius/sm` | 2px | 極小圓角（標籤） |
| `borderRadius/base` | 4px | 預設圓角（輸入框） |
| `borderRadius/md` | 6px | 按鈕圓角 |
| `borderRadius/lg` | 8px | 卡片圓角 |
| `borderRadius/full` | 9999px | 全圓（圓形頭像、藥丸按鈕） |

#### 字型

| 名稱 | 值 | 用途 |
|------|-----|------|
| 主要字型 | Inter + Noto Sans TC | 介面文字（英文 + 繁體中文） |
| 程式碼字型 | JetBrains Mono | 程式碼區塊 |
| 字級 xs | 12px | 標籤、徽章 |
| 字級 sm | 14px | 次要文字、表格 |
| 字級 base | 16px | 主要內文 |
| 字級 lg | 18px | 小標題 |
| 字級 2xl | 24px | 區段標題 |
| 字級 3xl | 30px | 頁面主標題 |

### 如何在 Figma 使用 Token？

1. 選取你的元件（例如一個按鈕）
2. 在右側面板的「填色」或「邊框」欄位，點擊色彩值
3. 選擇 **Variable**（變數）模式
4. 從清單中選取對應的 Token（例如 `color/primary/500`）

**重要**：不要直接輸入色碼。如果你需要一個清單中沒有的顏色，請提出新增 Token 的需求，而不是直接用自訂色碼。

---

## 現有元件庫

`_Component-Library` Page 中已有以下基礎元件，設計時請優先使用：

### Button（按鈕）

| 變體 | 用途 | 背景色 |
|------|------|--------|
| Primary | 主要行動按鈕（如「送出」「確認」） | 🔵 藍色 |
| Secondary | 次要按鈕（如「取消」「返回」） | 淺灰色 |
| Danger | 危險操作（如「刪除」） | 🔴 紅色 |
| Ghost | 低調操作（如「略過」） | 透明 |

尺寸：`sm`（32px 高）、`md`（40px 高，預設）、`lg`（48px 高）

### Input（輸入框）

| 狀態 | 說明 |
|------|------|
| Default | 預設狀態 |
| Focus | 使用者正在輸入（邊框變藍） |
| Error | 輸入有誤（邊框變紅） |
| Disabled | 不可輸入 |

### Card（卡片）

| 變體 | 說明 |
|------|------|
| Default | 帶陰影的標準卡片 |
| Elevated | 更明顯的陰影（懸浮感） |
| Outlined | 無陰影，有邊框 |

### 新增元件

如果你需要的元件不在庫中（例如 Modal 彈窗、Dropdown 下拉選單），請：

1. 在 `_Component-Library` Page 建立新元件
2. 使用 Token 設定顏色和間距（不要用自訂值）
3. 遵循命名規則（`元件類型/變體`，如 `Modal/Default`）
4. 通知團隊有新元件可用

---

## 標準畫框尺寸

| 平台 | 寬度 | 說明 |
|------|------|------|
| Desktop（桌面版） | 1440px | 標準桌面螢幕寬度 |
| Mobile（手機版） | 375px | iPhone 基準寬度 |
| Tablet（平板版） | 768px | iPad 基準寬度 |

高度不固定，隨內容量決定。建議使用 Auto Layout 的 **Hug**（自動撐高）模式。

---

## 設計稿交付流程

```
1. 你在 Figma 完成設計
   ↓
2. 貼連結到 GitHub Issue，或通知 PO
   ↓
3. PO 將設計稿對應到 User Story（使用者故事）
   ↓
4. Sprint Planning（衝刺規劃）時，團隊決定這個 Sprint 要做哪些
   ↓
5. AI 團隊自動執行：
   a. UX Agent  — 讀取你的 Figma，分析結構
   b. UI Agent  — 依照 Design Token 產出前端程式碼
   c. Vision Critic — 截圖比對，確認程式碼畫面跟你的設計一致
   ↓
6. 如果 Vision Critic 評分不及格，AI 自動修正再試
   ↓
7. 你可以審查最終截圖，確認是否符合設計意圖
```

---

## 你不需要做的事

- 寫 HTML / CSS / JavaScript
- 更新 `design-tokens.json` 檔案（AI 會從 Figma Variable 同步）
- 使用 GitHub（除了貼連結和看結果）
- 了解 Sprint、Scrum 等開發流程細節

---

## 你需要做的事

| 事項 | 頻率 |
|------|------|
| 在 Figma 畫設計稿 | 每當有新功能需求 |
| 遵循命名規則 | 每次建立 Frame 或元件 |
| 使用 Figma Variable（不要自訂色碼） | 設定顏色、間距時 |
| 建立新元件到 `_Component-Library` | 當需要新的共用元件 |
| 審查 AI 產出的截圖 | Sprint 結束時 |
| 提出新 Token 需求 | 當現有 Token 不夠用 |

---

## 常見問題

### Q：我可以用任何顏色嗎？

不行。請從 Design Token 清單中選用。如果需要新顏色，提出需求讓團隊新增 Token。這是為了確保整個產品的顏色一致。

### Q：我改了 Figma 的設計，AI 會自動更新嗎？

不會立刻更新。你改完後需要通知團隊，AI 會在下一個 Sprint 重新讀取你的設計並更新程式碼。

### Q：我可以在任何 Page 畫設計嗎？

請畫在對應的 Sprint Page（如 `Sprint-57-LoginRedesign`）。元件放在 `_Component-Library`，Token 展示放在 `_Design-Tokens`。不要在這些固定 Page 中畫一般設計稿。

### Q：我對 AI 產出的結果不滿意怎麼辦？

告訴 PO 哪裡不對。Vision Critic（視覺審查 AI）會根據你的回饋調整評分標準，下次產出會更接近你的設計。

### Q：舊的設計稿可以刪掉嗎？

不要直接刪除。請移到 `_Archive` Page，並在名稱後加上 `[ARCHIVED-日期]`，例如 `US-146-Login [ARCHIVED-2026-03-08]`。

### Q：我需要安裝什麼軟體？

只需要 **Figma Desktop App**。不需要安裝程式開發工具。

---

## 相關文件（給想深入了解的人）

| 文件 | 說明 |
|------|------|
| [Figma 文件結構指南](figma-structure-guide.md) | 完整的 Page 架構與 Layer 命名規則 |
| [元件庫規格](component-library-spec.md) | Button、Input、Card 的完整規格 |
| [Design Token 定義](design-tokens.json) | 所有 Token 的完整清單（JSON 格式） |
| [Token 版本控制策略](design-tokens-versioning.md) | Token 變更的版號管理規則 |
| [Figma 管線使用指南](../guides/figma-pipeline-usage-guide.md) | AI 管線的完整操作流程 |
