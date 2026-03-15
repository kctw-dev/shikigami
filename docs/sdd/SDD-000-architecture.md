# SDD-000 系統架構（Global Architecture）

> 本文件是系統的全局架構定義，所有功能 SDD（SDD-001+）引用本文件，不得在個別 SDD 中重複定義領域模型、類別結構或系統邊界。
>
> **地位**：系統憲法。任何開發工作的業務概念、Service、外部依賴必須先在本文件中定位，才能開工。

**最後更新**：2026-03-14
**維護者**：Architect

---

## 1. 系統領域模型

> 定義系統中所有核心 Entity 及其關聯。新增業務概念時（D1/D2 觸發），Architect 必須更新本段落並調用 `/diagram` 產出領域模型圖。

### 1.1 核心概念定義

| Entity | 說明 | 所屬 Bounded Context |
|--------|------|---------------------|
| *例：User* | *系統使用者* | *Identity* |

### 1.2 概念間關係

| 來源 Entity | 關係 | 目標 Entity | 說明 |
|------------|------|------------|------|
| *例：User* | *擁有* | *Order* | *一個 User 可有多筆 Order* |

### 1.3 統一語言（Ubiquitous Language）

| 術語 | 定義 | 注意事項 |
|------|------|---------|
| *例：Credit* | *系統內部貨幣單位* | *不可與「金額」混用* |

### 1.4 領域模型圖

> *待 Architect 調用 /diagram 產出後，在此嵌入或引用圖檔路徑*

```
（待 Architect 產出）
```

---

## 2. 類別圖

> 定義 Service 層、Router 層的結構與依賴方向，並標示共享資源的唯一寫入入口（Gateway）。DM-1/DM-2/DM-3/DM-4 審查觸發或 D4 觸發時，Architect 必須更新本段落。

### 2.1 分層結構

| 層級 | 責任 | 命名慣例 |
|------|------|---------|
| Router / Controller | I/O 調度、參數驗證、回應格式化 | `routes/*.py` 或 `controllers/*.ts` |
| Service | 業務邏輯、狀態轉換、規則判斷 | `services/*.py` 或 `services/*.ts` |
| Repository / DAO | 資料存取、查詢封裝 | `repositories/*.py` 或 `repos/*.ts` |

### 2.2 Service 清單

| Service 名稱 | 職責 | 依賴的 Repository | Gateway 標記 |
|-------------|------|------------------|-------------|
| *例：CreditService* | *點數增減、交易記錄* | *CreditRepository* | *credits_balance 唯一寫入入口* |
| *例：MediaService* | *媒體處理、點數扣抵* | *MediaRepository* | *— （依賴 CreditService.deduct）* |

> **Gateway 標記**：當某 Service 是特定共享資源的唯一寫入入口時，在此欄標注。其他 Service 必須透過該 Gateway 操作，不得直接寫入。標記「—」表示該 Service 非任何共享資源的 Gateway。

### 2.3 共享資源寫入入口（Gateway 對照表）

> 定義哪些共享資源有唯一寫入入口約束。新增共享資源或 DM-4 審查觸發時，Architect 必須更新本表。

| 共享資源 | Gateway Service | 允許的操作方法 | 禁止直接操作 |
|---------|----------------|--------------|-------------|
| *例：credits_balance* | *CreditService* | *add(), deduct(), refund()* | *禁止其他 Service 直接 Increment/Decrement* |
| *例：order.status* | *OrderService* | *transition()* | *禁止其他 Service 直接修改 status 欄位* |

> **判斷標準**：當 2 個以上 Service/Module 需要寫入同一資料資源（DB collection、欄位、狀態）時，必須定義 Gateway Service。

### 2.4 類別圖

> *待 Architect 調用 /diagram 產出後，在此嵌入 Mermaid classDiagram。類別圖必須標示 Gateway Service 與依賴方向。*

```
（待 Architect 產出 — 需使用 Mermaid classDiagram，標示依賴方向與 Gateway 註解）
```

---

## 3. 元件圖

> 定義前端、後端、資料庫、外部服務的系統邊界。新增外部依賴或系統邊界變更時，Architect 必須更新本段落。

### 3.1 系統邊界

| 元件 | 類型 | 託管模式 | 說明 |
|------|------|---------|------|
| *例：Frontend* | *內部* | *自建* | *Next.js SPA* |
| *例：Backend API* | *內部* | *自建* | *FastAPI* |
| *例：Firestore* | *外部服務* | *受管服務* | *GCP NoSQL DB* |

> **元件類型**：內部 / 外部服務
> **託管模式**：自建（Self-hosted）/ 受管服務（Managed Service）— 影響維運責任與 SLA 邊界

### 3.2 元件間通訊

| 來源 | 目標 | 協定 | 說明 |
|------|------|------|------|
| *例：Frontend* | *Backend API* | *REST / HTTPS* | *Bearer Token 認證* |

### 3.3 元件圖

> *待 Architect 調用 /diagram 產出後，在此嵌入或引用圖檔路徑*

```
（待 Architect 產出）
```

### 3.4 部署邊界（選填）

> 描述系統的部署拓撲，包含 Region、Zone、VPC 等基礎設施維度。初期可留空，待部署架構明確後填寫。

| 元件 | 部署位置 | Region / Zone | VPC / 網路 | 說明 |
|------|---------|---------------|-----------|------|
| *例：Backend API* | *GCE* | *asia-east1-b* | *prod-vpc* | *主要服務實例* |

### 3.5 可觀測性端點（選填）

> 列出系統的監控、日誌、追蹤端點，供 SRE 與 oncall 參考。

| 元件 | 監控類型 | 端點 / Dashboard | 對應 SLO | 說明 |
|------|---------|-----------------|---------|------|
| *例：Backend API* | *Metrics* | *grafana.internal/d/api-latency* | *P99 < 200ms* | *API 延遲監控* |

---

## 4. 變更紀錄

| 日期 | 變更內容 | 觸發條件代碼 | 變更段落 | 關聯 Story/Issue |
|------|---------|-------------|---------|-----------------|
| 2026-03-14 | 初始建立 | Onboarding | 全文 | — |
| 2026-03-15 | §2 新增 Gateway 標記、§2.3 共享資源寫入入口對照表 | DM-4 | §2 類別圖 | #268 |

> **觸發條件代碼**：限定以下值 — `D1`（新領域概念）、`D2`（跨模組共享）、`D3`（複雜業務規則，圖表放各 SDD）、`D4`（3+ Entity 互動）、`B3`（狀態轉換，圖表放各 SDD）、`DM-1`（業務邏輯封裝）、`DM-2`（Single Source of Truth）、`DM-3`（狀態轉換統一）、`DM-4`（共享寫入入口）、`Onboarding`（初始建立）、`外部依賴變更`
