# Routing History Schema

**Version**: 1.0
**Last Updated**: 2026-03-26
**Reference**: ADR-039 Model Routing History

## 概述

此文件定義 `routing-history.json` 的結構規格。routing-history 記錄每個 Story 在 Sprint Execution 中的模型路由決策，用於審計、統計分析和優化路由策略。

## JSON 結構

routing-history.json 是一個 JSON 物件，包含以下頂層欄位：

### 頂層欄位

| 欄位名 | 型別 | 必填 | 說明 |
|--------|------|------|------|
| `schema_version` | string | ✓ | Schema 版本號，採用 semver 格式（如 "1.0"） |
| `description` | string | ✓ | 文件描述，說明記錄範圍和目的 |
| `updated_at` | string (ISO 8601) | ✓ | 最後更新時間，格式：YYYY-MM-DDTHH:mm:ssZ |
| `coverage` | object | ✓ | 覆蓋範圍元數據，包含 `sprint_from`, `sprint_to`, `note` |
| `missing_periods` | array | ✗ | 缺漏期間記錄，列出無法取得路由決策的 Sprint 區間及原因 |
| `history` | array | ✓ | 路由決策歷史陣列，每個元素代表一筆路由記錄 |

### coverage 物件

| 欄位名 | 型別 | 必填 | 說明 |
|--------|------|------|------|
| `sprint_from` | integer | ✓ | 覆蓋起始 Sprint 號 |
| `sprint_to` | integer | ✓ | 覆蓋結束 Sprint 號（包含） |
| `note` | string | ✗ | 覆蓋說明備註 |

### missing_periods 陣列元素

| 欄位名 | 型別 | 必填 | 說明 |
|--------|------|------|------|
| `sprint_range` | string | ✓ | Sprint 範圍，格式："NNN-MMM"（如 "161-166"） |
| `reason` | string | ✓ | 缺漏原因 |
| `resolution` | string | ✗ | 修復方案說明 |
| `repaired_at` | string (YYYY-MM-DD) | ✗ | 修復日期 |
| `repaired_by` | string | ✗ | 修復來源（Story 編號或說明） |

### history 陣列元素

每筆路由決策記錄包含以下欄位：

| 欄位名 | 型別 | 必填 | 允許值 | 說明 |
|--------|------|------|--------|------|
| `sprint_number` | integer | ✓ | 正整數 | Sprint 編號 |
| `story_id` | string | ✓ | 數字 ID 或特殊值 | Story ID（如 "783"）或特殊值（如 "backfill-estimated"） |
| `risk_score` | integer | ✓ | 1-12 | 風險分數，評估範圍：1-12（低→中→高）。詳見 ADR-039 |
| `routing_tier` | integer | ✓ | 1, 2, 3 | 路由層級：1=haiku, 2=sonnet, 3=opus |
| `model` | string | ✓ | "haiku", "sonnet", "opus" | 分配的 AI 模型名稱 |
| `reason` | string | ✓ | 任意字串 | 路由決策理由，格式建議：`<STORY_TYPE>-<SIZE>-<CONDITION>`（如 "FEATURE-S-standard"） |

## 允許值詳解

### risk_score (1-12)

根據 ADR-039，風險分數定義如下：

- **1-3**：低風險，典型 haiku 候選（TEST、DOC、RESEARCH 類 S-size Story）
- **4-6**：中風險，典型 sonnet 候選（標準 FEATURE/INFRA Story）
- **7-9**：高風險，需考慮 sonnet/opus（複雜設計決策、跨系統影響）
- **10-12**：極高風險，建議 opus（架構變更、安全審計、複雜重構）

### routing_tier (1, 2, 3)

| Tier | Model | 適用情況 |
|------|-------|---------|
| 1 | haiku | 低複雜度、限制範圍、高時間效率要求 |
| 2 | sonnet | 標準 Story，平衡複雜度與成本 |
| 3 | opus | 高風險、複雜架構決策、自評審查 |

### reason 格式建議

reason 欄位建議遵循命名慣例，便於統計分析：

- `<STORY_TYPE>-<SIZE>-<CONDITION>`
- 其中 STORY_TYPE ∈ {FEATURE, INFRA, PROCESS, RESEARCH, TEST, DOC}
- SIZE ∈ {S, M, L}
- CONDITION ∈ {standard, no-code, haiku-expansion, ...}

特殊值（如回溯補充）：
- `backfill-estimated-from-missing-period` — 缺期回溯估計
- `backfill-from-sprint-NNN` — 從特定 Sprint 資料補回
- `backfill-from-sprint-NNN-TYPE` — 從特定 Sprint 的特定記錄類型補回

## 驗證規則

使用此 schema 時應遵循：

1. **完整性**：每筆 history 記錄必須包含所有必填欄位
2. **型別一致性**：欄位值必須符合指定型別
3. **值範圍**：risk_score ∈ [1, 12]，routing_tier ∈ [1, 2, 3]
4. **時間戳格式**：updated_at 必須為 ISO 8601 格式
5. **Sprint 編號邏輯**：sprint_from ≤ sprint_to，history 記錄的 sprint_number 應落在 coverage 範圍內（或在 missing_periods 中解釋）

## 示例

```json
{
  "sprint_number": 159,
  "story_id": "783",
  "risk_score": 6,
  "routing_tier": 2,
  "model": "sonnet",
  "reason": "INFRA-S-standard"
}
```

## 未來擴展

如需在 history 記錄中加入新欄位（如 execution_time, token_cost 等），應：

1. 在本文件中新增欄位定義
2. 更新 schema_version（如 1.0 → 1.1）
3. 更新 routing-history.json 的 $schema 參考

## 相關文件

- [ADR-039: Token Cost Model Routing](../adr/adr-039-token-cost-model-routing.md)
- [routing-history.json](./routing-history.json)
- [Story #885: routing-history.json 建立與歷史補回](https://github.com/kctw-dev/shikigami/issues/885)
