# Sprint 97

**Sprint Goal**：定義 pr-review-toolkit 外部 Plugin 整合架構 — 為 #266 實作掃清前置依賴
**日期**：2026-03-15
**容量**：1 point
**狀態**：進行中

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| RESEARCH：ADR — pr-review-toolkit 外部 Plugin 整合架構定義 | #267 | S | 1 | 進行中 |

## Acceptance Criteria 摘要

### RESEARCH #267

- **AC1**：ADR 定義 pr-review-toolkit 整合模式（派遣方式、輸入輸出格式、嚴重度分級）
- **AC2**：ADR 定義未安裝時降級行為（靜默跳過 vs 警告 vs 阻擋）及安裝提醒機制
- **AC3**：ADR 定義與現有 shoot §8.5 外部獨立審查的責任邊界
- **AC4**：ADR 產出 Spike Report，含結論與建議後續行動（供 #266 AC 重寫依據）

## 技術評估摘要

- #267：S/1pt，RESEARCH type。產出 ADR 文件（docs/adr/）+ Spike Report，無程式碼變更。前置依賴：無。後置影響：#266 AC 需依 ADR 結論重新改寫。

## Backlog 異動記錄

- **#266**（pr-review-toolkit 整合）：Planning Round 2 由 Architect 和 QA 判定 NOT_READY，退回 Backlog。
  - 原因：外部 plugin 整合架構、降級行為、安裝提醒在框架內均未定義。
  - 決議：ADR #267 Accepted 後，#266 AC 重寫再排入下一 Sprint。

## Refinement 記錄

- #267：S-size 豁免，無需 Refinement
