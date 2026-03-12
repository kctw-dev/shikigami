# Knowledge Staleness Detection — 知識老化偵測機制

<!-- US-221 知識老化偵測 — Sprint 84 -->

## 1. 概述

知識老化偵測（Knowledge Staleness Detection）是 Shikigami 框架的知識管理子系統，負責監控已內化的外部知識（API 文件、SDK Changelog、技術規格等）是否仍符合當前開發需求。

本機制搭配 Knowledge Ingestion（US-216, ADR-017）與 Context Hub 使用，確保 AI Agent 基於最新知識做出技術決策。

---

## 2. 已內化知識清單（Ingested Knowledge Inventory）

此清單記錄所有已透過 Knowledge Ingestion 流程內化至框架的外部知識條目。

### 欄位說明

| 欄位 | 說明 |
|------|------|
| `id` | 條目唯一識別碼（格式：`KI-NNN`） |
| `name` | 知識條目名稱（簡述） |
| `source_url` | 原始文件 URL 或來源位置 |
| `ingested_at` | 首次內化時間戳（ISO 8601 格式：`YYYY-MM-DD`） |
| `last_verified_at` | 最後驗證時間戳（重新爬取比對後更新） |
| `version` | 當前已內化版本號（若原始文件有版本號） |
| `priority` | 重要性等級（`HIGH` / `MEDIUM` / `LOW`） |
| `category` | 知識類別（`API_DOC` / `SDK` / `CHANGELOG` / `SPEC` / `OTHER`） |
| `staleness_status` | 新鮮度狀態（`FRESH` / `STALE` / `EXPIRED`，由 health-check 自動計算） |
| `notes` | 備注（如特殊來源限制、訂閱方式等） |

### 清單（初始狀態）

> 本清單由 Knowledge Ingestion 流程維護。每次內化新知識或重新驗證現有知識後，更新對應條目。

| id | name | source_url | ingested_at | last_verified_at | version | priority | category | staleness_status | notes |
|----|------|-----------|-------------|-----------------|---------|----------|----------|-----------------|-------|
| — | （目前無已內化知識條目） | — | — | — | — | — | — | — | — |

---

## 3. 三層偵測機制

### 架構概覽

```
┌──────────────────────────────────────────────────────────┐
│               知識老化偵測三層機制                         │
│                                                          │
│  Layer 1：定時檢查（Scheduled Check）                     │
│  ├─ 觸發條件：每 N 天定期執行                             │
│  └─ 責任者：health-check SKILL §2 檢查 6                  │
│                                                          │
│  Layer 2：事件觸發（Event-Driven Check）                  │
│  ├─ 觸發條件：Sprint 開始時自動執行                        │
│  └─ 責任者：sprint-execution SKILL §2.8                   │
│                                                          │
│  Layer 3：外部 Changelog 訂閱（Changelog Subscription）   │
│  ├─ 觸發條件：已訂閱的外部服務發布新版本                   │
│  └─ 責任者：手動訂閱 + Context Hub 整合                   │
└──────────────────────────────────────────────────────────┘
```

---

### 3.1 Layer 1：定時檢查

**目的**：定期重新爬取已內化的 API 文件，比對版本差異，維持知識清單的新鮮度狀態。

**觸發條件：**

| 條件 | 說明 |
|------|------|
| health-check 執行時 | 每次執行 `/health-check` 時自動觸發第 6 項新鮮度檢查 |
| Sprint Planning 前 | Sprint Planning 開始前建議手動執行 health-check，確保知識狀態 |

**新鮮度閾值：**

| 距上次驗證天數 | 狀態 | 判定規則 |
|-------------|------|---------|
| ≤ 30 天 | `FRESH` | 正常，無需動作 |
| 31–90 天 | `STALE` | 需在近期 Sprint 排程更新 |
| > 90 天 | `EXPIRED` | 立即觸發重新爬取 |

**執行步驟：**

1. 讀取本文件 §2 已內化知識清單
2. 對每個條目計算距今天數（今日日期 − `last_verified_at`）
3. 依閾值更新 `staleness_status` 欄位
4. 輸出 health-check 第 6 項報告（格式見 `skills/health-check/SKILL.md` §2 檢查 6）

**降級策略：**

- 本文件不存在 → WARN（不阻塞 health-check，輸出「知識老化偵測文件不存在」告警）
- 清單為空（無條目）→ PASS（無需驗證）

---

### 3.2 Layer 2：事件觸發

**目的**：在每個 Sprint 開始時，自動重新驗證關鍵（`priority = HIGH`）API 文件版本，確保新 Sprint 的開發決策基於最新知識。

**觸發條件：**

| 事件 | 觸發位置 |
|------|---------|
| Sprint Execution 啟動 | `skills/sprint-execution/SKILL.md` §2.8 |

**驗證邏輯：**

```
篩選 priority = HIGH 的條目
  |
  +-- FRESH (≤30d)  → [KS-PASS] 繼續執行
  +-- STALE (31-90d) → [KS-WARN] 告警，不阻塞
  +-- EXPIRED (>90d) → [KS-FAIL] 要求確認
```

**降級策略：**

- 本文件不存在 → `[KS-SKIP]` 靜默略過，不阻塞 Sprint 執行
- 讀取失敗（格式錯誤、權限問題）→ `[KS-SKIP]` 靜默略過
- 無 HIGH 優先條目 → `[KS-SKIP]` 靜默略過

---

### 3.3 Layer 3：外部 Changelog 訂閱

**目的**：主動追蹤已依賴的外部服務 changelog，在外部服務發布新版本時，即時識別潛在的知識老化風險。

**觸發條件：**

| 條件 | 說明 |
|------|------|
| 外部服務發布新版本 | 訂閱的 changelog 推送通知（RSS、GitHub Release、郵件列表等） |
| Knowledge Ingestion 執行時 | 內化新知識時同步建立訂閱登記 |

**訂閱登記表：**

> 記錄已建立 changelog 訂閱的外部服務。

| 服務名稱 | Changelog URL | 訂閱方式 | 最後收到通知 | 關聯知識條目 |
|---------|--------------|---------|------------|------------|
| （目前無已訂閱服務） | — | — | — | — |

**處理流程：**

```
收到外部 changelog 通知
  |
  v
識別受影響的已內化知識條目（對照關聯知識條目欄）
  |-- 無關聯條目 → 記錄通知，無需動作
  +-- 有關聯條目
        |
        v
評估變更影響程度
  |-- BREAKING CHANGE → 立即排程本 Sprint 內更新（開新 Story）
  |-- MINOR UPDATE    → 加入下次 Sprint Planning 評估
  +-- PATCH / BUG FIX → 更新 last_verified_at，staleness_status 維持 FRESH
        |
        v
更新 §2 已內化知識清單對應條目
（version、last_verified_at、staleness_status）
```

**降級策略：**

- 無法建立自動訂閱 → 手動登記至訂閱表，每個 Sprint Planning 時人工查閱 changelog
- 外部服務無 changelog 機制 → 依賴 Layer 1 定時檢查發現差異

---

## 4. 知識更新流程

當偵測到 STALE 或 EXPIRED 知識條目時，依以下流程更新：

```
偵測到 STALE / EXPIRED 條目
  |
  v
重新爬取原始文件（source_url）
  |-- 爬取失敗（URL 失效、需登入等）→ 標記為 [UNREACHABLE]，升級至人工處理
  +-- 爬取成功
        |
        v
與現有內化版本進行 diff 比對
  |-- 無差異 → 更新 last_verified_at，staleness_status 改為 FRESH
  |-- 有差異（MINOR）→ 更新內化內容，記錄變更摘要，更新 version 與時間戳
  +-- 有差異（BREAKING CHANGE）
        |
        v
  建立 Knowledge Update Story（加入 Product Backlog）
  標記：[KS-UPDATE] {知識條目名稱} — BREAKING CHANGE 需重新內化
        |
        v
  更新 §2 清單（staleness_status → STALE，notes 記錄 BREAKING CHANGE）
  等待 Story 完成後再將 staleness_status 更新為 FRESH
```

---

## 5. 與其他機制的整合

| 機制 | 整合方式 |
|------|---------|
| Knowledge Ingestion（US-216, ADR-017） | 每次新知識內化後，在 §2 清單新增條目；ADR-017 定義爬取與儲存規範 |
| Context Hub | 已內化知識儲存於 Context Hub；偵測到 EXPIRED 時通知 Context Hub 失效對應知識區塊 |
| health-check SKILL | 執行 §2 的新鮮度計算，輸出第 6 項診斷報告 |
| sprint-execution SKILL | Sprint 開始時自動執行 Layer 2 事件觸發驗證（§2.8） |
| Product Backlog | BREAKING CHANGE 觸發新增 [KS-UPDATE] Story 至 Backlog |

---

## 6. 維護規範

### 6.1 清單更新責任

| 動作 | 執行者 | 更新欄位 |
|------|--------|---------|
| 內化新知識 | Developer（Knowledge Ingestion 流程） | 新增完整條目 |
| 重新驗證（無差異） | Developer / health-check 自動 | `last_verified_at`、`staleness_status` |
| 版本更新 | Developer | `version`、`last_verified_at`、`staleness_status`、`notes` |
| 訂閱新 changelog | Developer | §3.3 訂閱登記表新增列 |

### 6.2 staleness_status 計算規則

`staleness_status` 欄位由 health-check 動態計算，**不應手動填寫**。手動填入的值在下次 health-check 執行時會被覆蓋。唯一例外：`[UNREACHABLE]` 標記由人工設定，health-check 遇到此標記時輸出 WARN 而非嘗試計算天數。

### 6.3 文件版本記錄

本文件每次有重大更新時，在本節記錄變更摘要：

| 日期 | 版本 | 變更說明 |
|------|------|---------|
| 2026-03-12 | v1.0 | 初始建立（US-221，Sprint 84）— 定義三層偵測機制、已內化知識清單格式、降級策略 |
