# Trace Log 完整性指標規範

**版本**：1.0.0
**建立日期**：2026-03-24
**相關 ADR**：ADR-033（Structured Trace Log 架構）
**相關 Issue**：#483、#392、#473

---

## 1. 概述

本文件定義 Shikigami Trace Log 的品質度量基線，包含：

- 必要欄位定義（依據 ADR-033）
- 完整性指標計算方式
- 健康門檻
- parentSpanId 參照完整性規則

---

## 2. 必要欄位定義（ADR-033 Schema）

依據 ADR-033 決策 2，每筆 trace span 必須包含以下 **8 個必要欄位**：

| 欄位 | 類型 | 說明 |
|------|------|------|
| `traceId` | string | 一次完整執行鏈的唯一識別碼 |
| `spanId` | string | 本 span 的唯一識別碼 |
| `parentSpanId` | string \| null | 父 span 的 spanId；根 span 為 null |
| `agentRole` | string | 執行動作的 Agent 角色 |
| `action` | string | 執行的動作名稱 |
| `timestamp` | string | ISO 8601 帶時區，精確到秒 |
| `status` | string | `"started"` \| `"completed"` \| `"failed"` |
| `sessionId` | string | Claude session 識別碼 |

---

## 3. 完整性指標

### 3.1 必要欄位覆蓋率（Primary Metric）

**定義**：

```
必要欄位覆蓋率 = 包含全部 8 個必要欄位的 span 數 / 總 span 數 × 100%
```

**計算方式**：
- 逐行讀取 JSONL 檔案
- 每行必須為合法 JSON 物件
- 檢查是否包含全部 8 個必要欄位（欄位值允許 null，但欄位鍵必須存在）
- 統計完整 span 數與總 span 數

**健康門檻**：

| 等級 | 覆蓋率 | 說明 |
|------|--------|------|
| HEALTHY | ≥ 100% | 全部 span 包含必要欄位 |
| WARNING | 80% ~ 99% | 部分 span 缺少欄位，需調查原因 |
| CRITICAL | < 80% | 嚴重欄位缺失，Trace 可用性不足 |

### 3.2 JSON 格式合法性

每行必須為合法 JSON 物件（`{...}`）。非法 JSON 行視為無效 span，計入總 span 數但不計入完整 span 數。

### 3.3 parentSpanId 參照完整性

**定義**：

```
parentSpanId 參照完整性率 =
  parentSpanId 指向有效 spanId 的 span 數（排除 null）/
  parentSpanId 非 null 的 span 數 × 100%
```

**規則**：
- `parentSpanId = null`：合法，代表根 span（root span）
- `parentSpanId = "<spanId>"`：必須指向同一 session 檔案或同一 traceId 的已知 spanId
- 孤立 parentSpanId（跨 session 引用）：視為 WARNING，非 ERROR（多機器場景允許）

---

## 4. 檔案命名格式

per-session 檔案命名規則（依據 ADR-033 決策 4）：

```
docs/trace-logs/{YYYY-MM-DD}-{session-id}.jsonl
```

範例：
```
docs/trace-logs/2026-03-24-session-abc123.jsonl
docs/trace-logs/2026-03-24-session-xyz456.jsonl
```

**格式驗證正規表達式**：
```
^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-zA-Z0-9_-]+\.jsonl$
```

---

## 5. status 欄位合法值

`status` 欄位僅允許以下三個值：

- `"started"` — span 開始執行
- `"completed"` — span 執行完成
- `"failed"` — span 執行失敗

---

## 6. timestamp 欄位格式

`timestamp` 欄位必須符合 ISO 8601 帶時區格式，精確到秒：

```
YYYY-MM-DDTHH:MM:SS+HH:MM
YYYY-MM-DDTHH:MM:SSZ
```

範例：`2026-03-24T10:00:00+0800`、`2026-03-24T02:00:00Z`

---

## 7. 與自動化驗證腳本的對應

本規範的指標均由 `scripts/validate-trace-log.sh` 實作自動化驗證：

| 規範章節 | 腳本驗證項 |
|----------|-----------|
| 3.1 必要欄位覆蓋率 | AC2：驗證必要欄位存在 |
| 3.2 JSON 格式合法性 | AC1：JSONL 格式驗證 |
| 3.3 parentSpanId 參照完整性 | AC3：parentSpanId 參照完整性檢查 |
| 4 檔案命名格式 | AC4：per-session 命名格式驗證 |

---

## 8. quality-observer MCP 整合

trace 查詢透過 `shikigami-quality-observer` MCP Server 提供：

| Tool | 功能 |
|------|------|
| `get_trace_recent` | 查詢最近 N 條 trace span |
| `get_trace_by_session` | 按 session ID 篩選 trace span |
| `get_trace_summary` | 取得 human-readable trace 摘要（完整性、分佈統計）|

---

## 9. 參照

- [ADR-033 Structured Trace Log 架構](../adr/ADR-033-structured-trace-log.md)
- [ADR-028 Multi-Sprint Observability](../adr/ADR-028-multi-sprint-observability.md)
- `scripts/validate-trace-log.sh`
- `mcp-servers/quality-observer/index.js`
