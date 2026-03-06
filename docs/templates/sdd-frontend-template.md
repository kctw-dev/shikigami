# Software Design Document — 前端功能模板

> 適用範圍：所有含前端介面的 User Story。本模板由 ADR-014 Phase 1 定義，強制用於所有前端 SDD。
> 引用規格：`docs/design/design-tokens.json`（v1.0.0）

---

## 基本資訊

| 欄位 | 內容 |
|------|------|
| Story ID | <!-- 例：US-103 --> |
| Issue # | <!-- 例：#104 --> |
| Sprint | <!-- 例：Sprint 52 --> |
| Author | <!-- 角色名稱，例：Developer Subagent --> |
| 建立日期 | <!-- 例：2026-03-06 --> |
| 最後更新 | <!-- 例：2026-03-06 --> |

---

## 功能概述

<!-- 以 1-3 句說明本功能的使用者情境與業務目標 -->

---

## 資訊架構骨架

<!-- 描述頁面版面區塊、元件層級與互動說明（純語意，無樣式） -->

### 版面區塊

| 區塊名稱 | 說明 | 元件層級 |
|---------|------|---------|
| <!-- 例：Header --> | <!-- 例：頁面頂部導覽列 --> | <!-- 例：L1 — 頁面頂層 --> |

### 互動說明

<!-- 列出主要互動流程（如：點擊、輸入、狀態切換） -->

---

## Frontend Constraints

> 本區段為強制填寫欄位，所有前端 Story 必須完整填寫。Developer Subagent 實作時須嚴格遵循以下約束。

### 元件庫白名單

| 元件庫 / 框架 | 用途 | 允許狀態 |
|-------------|------|---------|
| **Tailwind CSS** | 所有樣式類別（spacing、typography、color） | 允許 |
| **Shadcn UI** | UI 元件（Button、Input、Card、Dialog、Table 等） | 允許 |
| 自訂 CSS（.css / .scss / CSS-in-JS） | — | **禁止** |
| 其他 UI 元件庫（MUI、Ant Design、Chakra 等） | — | **禁止，需 ADR 核准** |

**強制規則**：前端實作僅使用 Tailwind CSS utility classes 與 Shadcn UI 元件，禁止撰寫自訂 CSS。

### Design Tokens 引用路徑

**規格檔案**：`docs/design/design-tokens.json`（版本 1.0.0）

| Token 群組 | 引用方式 | 說明 |
|-----------|---------|------|
| `color.*` | 引用 token key（例：`color.primary.500`） | 所有顏色禁止 hardcode 色碼（#hex / rgb()） |
| `typography.fontSize.*` | 引用 Tailwind class（例：`text-base`） | 字級使用 Tailwind 對應 class |
| `typography.fontFamily.*` | 引用 Tailwind class（例：`font-sans`） | 字型族群使用 Tailwind class |
| `borderRadius.*` | 引用 Tailwind class（例：`rounded-md`） | 圓角禁止自訂數值 |
| `spacing.*` | 引用 Tailwind class（例：`p-4`、`m-6`） | 所有 margin/padding 使用 Tailwind spacing |
| `shadow.*` | 引用 Tailwind class（例：`shadow-md`） | 陰影禁止自訂 box-shadow 數值 |

**強制規則**：所有顏色、圓角、間距值須引用 `docs/design/design-tokens.json` 中的具名 token，禁止 hardcode 數值。

### Human-in-the-loop 觸發條件

以下情境觸發時，前端操作須在 AC 中明確加入「人工確認」步驟，不得全自動執行：

| 觸發條件 | 說明 | 處理方式 |
|---------|------|---------|
| **破壞性資料操作** | 刪除、清空、批次覆寫使用者資料 | 顯示確認對話框，明確說明影響範圍 |
| **付款與金融操作** | 扣款、訂閱升降級、退款 | 顯示金額確認畫面，需使用者明確按下「確認」 |
| **服務重啟與系統操作** | 重啟服務、清除快取、刷新憑證 | 顯示警告提示，需管理員權限確認 |
| **外部系統寫入** | 發送 Email、Webhook、API 呼叫（寫入性） | 預覽發送內容，提供「取消」按鈕 |
| **不可逆操作** | 任何無法 Undo 的操作 | 顯示明確的不可逆警告，倒數計時或二次確認 |

**強制規則**：上述觸發條件的相關 AC 須包含「使用者確認後才執行」的驗收標準，Story Lifecycle 自動在 Done Definition 加入 HITL 檢核點。

---

## 技術設計

### 元件結構

<!-- 描述主要元件樹（可使用縮排列表） -->

```
頁面根元件
├── 區塊 A
│   ├── 子元件 1
│   └── 子元件 2
└── 區塊 B
    └── 子元件 3
```

### 狀態管理

<!-- 描述頁面狀態（Loading / Empty / Error / Success）與狀態轉換邏輯 -->

| 狀態 | 觸發條件 | UI 表現 |
|------|---------|--------|
| Loading | 資料請求中 | 顯示 Skeleton 或 Spinner |
| Empty | 無資料 | 顯示 Empty State 插圖 + CTA |
| Error | 請求失敗 | 顯示錯誤訊息 + 重試按鈕 |
| Success | 資料載入完成 | 顯示正常介面 |

### API 串接

<!-- 列出本功能相關的 API 端點 -->

| 端點 | 方法 | 說明 |
|------|------|------|
| `/api/...` | GET/POST | <!-- 說明 --> |

---

## 驗收標準對照

> 以下 AC 條目對應 sprint_*.md 的 Acceptance Criteria 表格，實作前請確認兩處一致。

| AC # | 類型 | 條件 | 通過標準 |
|------|------|------|---------|
| AC1 | <!-- 靜態/動態 --> | <!-- 條件描述 --> | <!-- 通過標準 --> |

**自動注入的前端合規 AC（由 issue-management 自動加入，不可刪除）**：

| AC # | 條件 | 通過標準 |
|------|------|---------|
| FE-AC1 | 元件庫符合性 | 前端實作僅使用 Tailwind CSS 或 Shadcn UI 元件，禁止自訂 CSS |
| FE-AC2 | Design Tokens 符合性 | 所有顏色、圓角、間距值引用 `docs/design/design-tokens.json` 中的具名 token，禁止 hardcode 數值 |

---

## 風險與依賴

| 風險 / 依賴 | 說明 | 緩解措施 |
|-----------|------|---------|
| <!-- 例：Shadcn UI 版本相容性 --> | <!-- 說明 --> | <!-- 緩解措施 --> |

---

## 參考

- ADR-014：UIUX Agent 架構決策（Phase 1 防呆設計基礎）
- `docs/design/design-tokens.json`：Design Tokens 規格定義
- [Tailwind CSS 文件](https://tailwindcss.com/docs)
- [Shadcn UI 元件庫](https://ui.shadcn.com/)
