# SDD-000 系統架構（Global Architecture）

> 本文件是系統的全局架構定義，所有功能 SDD（SDD-001+）引用本文件，不得在個別 SDD 中重複定義領域模型、類別結構或系統邊界。
>
> **地位**：系統憲法。任何開發工作的業務概念、Service、外部依賴必須先在本文件中定位，才能開工。

**最後更新**：{日期}
**維護者**：Architect

---

## 1. 系統領域模型

> 定義系統中所有核心 Entity 及其關聯。新增業務概念時（D1/D2 觸發），Architect 必須更新本段落並調用 `/diagram` 產出領域模型圖。

### 1.1 核心概念定義

| Entity | 說明 | 所屬 Bounded Context |
|--------|------|---------------------|
| <!-- 例：User --> | <!-- 系統使用者 --> | <!-- Identity --> |

### 1.2 概念間關係

| 來源 Entity | 關係 | 目標 Entity | 說明 |
|------------|------|------------|------|
| <!-- 例：User --> | <!-- 擁有 --> | <!-- Order --> | <!-- 一個 User 可有多筆 Order --> |

### 1.3 統一語言（Ubiquitous Language）

| 術語 | 定義 | 注意事項 |
|------|------|---------|
| <!-- 例：Credit --> | <!-- 系統內部貨幣單位 --> | <!-- 不可與「金額」混用 --> |

### 1.4 領域模型圖

<!-- Architect 調用 /diagram 產出後，在此嵌入或引用圖檔路徑 -->

```
（待 Architect 產出）
```

---

## 2. 類別圖

> 定義 Service 層、Router 層的結構與依賴方向。DM-1/DM-2 審查觸發或 D4 觸發時，Architect 必須更新本段落。

### 2.1 分層結構

| 層級 | 責任 | 命名慣例 |
|------|------|---------|
| Router / Controller | I/O 調度、參數驗證、回應格式化 | `routes/*.py` 或 `controllers/*.ts` |
| Service | 業務邏輯、狀態轉換、規則判斷 | `services/*.py` 或 `services/*.ts` |
| Repository / DAO | 資料存取、查詢封裝 | `repositories/*.py` 或 `repos/*.ts` |

### 2.2 Service 清單

| Service 名稱 | 職責 | 依賴的 Repository |
|-------------|------|------------------|
| <!-- 例：PaymentService --> | <!-- 交易狀態轉換、金流處理 --> | <!-- OrderRepository, CreditRepository --> |

### 2.3 類別圖

<!-- Architect 調用 /diagram 產出後，在此嵌入或引用圖檔路徑 -->

```
（待 Architect 產出）
```

---

## 3. 元件圖

> 定義前端、後端、資料庫、外部服務的系統邊界。新增外部依賴或系統邊界變更時，Architect 必須更新本段落。

### 3.1 系統邊界

| 元件 | 類型 | 說明 |
|------|------|------|
| <!-- 例：Frontend --> | <!-- 內部 --> | <!-- Next.js SPA --> |
| <!-- 例：Backend API --> | <!-- 內部 --> | <!-- FastAPI --> |
| <!-- 例：Firestore --> | <!-- 外部服務 --> | <!-- GCP NoSQL DB --> |

### 3.2 元件間通訊

| 來源 | 目標 | 協定 | 說明 |
|------|------|------|------|
| <!-- 例：Frontend --> | <!-- Backend API --> | <!-- REST / HTTPS --> | <!-- Bearer Token 認證 --> |

### 3.3 元件圖

<!-- Architect 調用 /diagram 產出後，在此嵌入或引用圖檔路徑 -->

```
（待 Architect 產出）
```

---

## 4. 變更紀錄

| 日期 | 變更內容 | 觸發條件 | 關聯 Story/Issue |
|------|---------|---------|-----------------|
| {日期} | 初始建立 | Onboarding | — |
