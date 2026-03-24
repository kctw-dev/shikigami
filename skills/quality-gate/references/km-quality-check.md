# KM 文件品質檢查（第三方 API enum 來源驗證）

> 參見主文件：`skills/quality-gate/SKILL.md §8.1`

<!-- US-274 KM 第三方 API 文件驗證機制 — Sprint 100, #276 -->

**適用範圍**：`docs/km/` 目錄下含第三方 API 資訊的文件。

**觸發條件（以下任一出現在審查對象中即觸發）**：API、SDK、endpoint、webhook、OAuth、第三方。

**純內部模組文件、ADR、Retrospective Log 等非第三方 API 類文件不觸發此項。**

## KM 品質檢查清單

| 項目 | 檢查內容 | 等級 |
|------|----------|------|
| KM-API-1：Enum 來源標注 | KM 文件中的 API enum 值是否附有官方文件 URL、版本號或實測日期 | Important（WARN） |
| KM-API-2：Enum 完整性宣告 | enum 列舉是否標注「完整列舉」或「部分列舉（截至 YYYY-MM-DD）」 | Important（WARN） |

## 判定規則

- 違反 KM-API-1 或 KM-API-2 → 門禁輸出 `[KM-WARN]`，等級為 **Important**
- `[KM-WARN]` 不觸發 CRITICAL 互動決策點（不阻擋合併），但必須記錄於審查報告
- 同一文件連續違反超過 3 項 → 升級為 **Critical**，進入 §7.1 CRITICAL 互動決策點

## 輸出格式

```
[KM-WARN] {檔案路徑}: enum "{參數名}" 缺少來源標注
[KM-WARN] {檔案路徑}: enum "{參數名}" 缺少完整性宣告（需標注「完整列舉」或「部分列舉，截至 YYYY-MM-DD」）
```
