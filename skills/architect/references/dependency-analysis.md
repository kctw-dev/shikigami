# 跨領域依賴分析 Checklist（Refinement Chair 用）

> 本文件由 `skills/architect/SKILL.md §8` 拆出。主文件保留觸發說明，詳細 Checklist 在此。

<!-- US-202 Refinement 機制 — Sprint 76 -->

當 Architect 擔任 Refinement Chair 時（見 sprint-planning/SKILL.md §9），必須使用本 Checklist 對每個 M/L Story 進行跨領域依賴分析。以下各項均需明確回答，不可省略。

## 8.1 前置依賴分析

**問題**：這個 Story 開始前需要什麼前置條件？

| 判斷條件 | 處置 |
|---------|------|
| Story AC 描述中含「依賴 US-#N 完成」、「需要 XXX 先就緒」等字眼 | 確認前置 Story 是否在同 Sprint 可完成，若不可則標記 NOT_READY |
| Story 需要外部系統可用性（第三方 API、SaaS 服務） | 確認外部系統狀態，若不確定則在 Sprint 前發出確認請求 |
| Story 需要 ADR 已通過才能實作 | 確認對應 ADR 狀態為 Accepted，否則退回 Backlog |
| Story 無前置依賴 | 記錄「無前置依賴」，繼續下一項 |

## 8.2 下游影響分析

**問題**：是否有其他 Story 依賴本 Story 的輸出？

| 判斷條件 | 處置 |
|---------|------|
| 本 Sprint 中有其他 Story 的 AC 引用本 Story 的輸出（API、Schema、文件） | 確認本 Story 在排程上優先，Contract Owner 須出席 Refinement；輸出界面需在 Refinement 中定義清楚 |
| 下一個 Sprint 的規劃 Story 依賴本 Story | 記錄跨 Sprint 依賴，確保本 Story 完成時交付物完整，降低下 Sprint 返工風險 |
| 無下游依賴 | 記錄「無下游依賴」，繼續下一項 |

## 8.3 跨 Story Type 拆分分析

**問題**：本 Story 是否跨越多個 Story Type 需要拆分？

| 判斷條件 | 處置 |
|---------|------|
| Story 同時包含 FEATURE + INFRA 工作，且 INFRA 工作量不可忽略（需要 SRE 獨立設計、建置） | 拆分為獨立 INFRA Story（Contract Owner：SRE）和 FEATURE Story；INFRA Story 成為 FEATURE Story 的前置依賴 |
| Story 同時包含 FEATURE + INFRA 工作，但 INFRA 工作量極小（設定調整、參數修改） | 保持為單一 FEATURE Story，在 Contract 中附加 Infra Prerequisites Checklist，由 SRE 簽核 |
| Story 同時包含 FEATURE + SECURITY 工作（如新功能 + 安全審查） | 由 Security Engineer 作為 SECURITY 審查 Co-Owner；若安全工作量大則拆分 SECURITY Story |
| Story 同時包含 INTEGRATION + INFRA（如 API 串接 + 環境設定） | 優先執行 INFRA Story，確保環境就緒後再執行 INTEGRATION Story |
| Story 僅屬於單一 Type | 依 §8.2 分類規則確認 Type，記錄「無跨 Type 拆分需求」，繼續下一項 |

## 8.4 Contract Owner 確認

**問題**：Contract Owner 是否已確認？是否能在本 Sprint 參與？

| 判斷條件 | 處置 |
|---------|------|
| 依 sprint-planning/SKILL.md §8.3 對照表，Contract Owner 角色明確且可在本 Sprint 參與 | 記錄 Contract Owner 確認狀態，繼續 |
| Contract Owner 為 Architect（FEATURE / INTEGRATION），但本 Story 的技術界面尚未釐清 | 在 Refinement 中釐清技術界面定義，完成 API 契約草稿後方可標記 READY |
| Contract Owner 為外部角色（SRE / Security Engineer / UI/UX Designer），無法在本 Sprint 參與 | 標記 NOT_READY，記錄阻塞原因：Contract Owner 無法參與 |
| Story Type 為 RESEARCH，無 Contract Owner | 確認 Spike Report 輸出格式已定義，記錄「RESEARCH 類型，無 Contract Owner」 |

## 8.5 單 Sprint 完成性評估

**問題**：本 Story 能在一個 Sprint 內完成嗎？

| 判斷條件 | 處置 |
|---------|------|
| L size Story 且 AC > 8 條，Sprint 容量可能不足 | 強制執行 ADR-007 §AC4 策略 2（L-size 預分批），或考慮拆分為 2 個 M Story |
| M size Story 且同 Sprint 有多個 M/L Story 競用 Architect 資源 | 評估 Sprint 容量，若超載則延後至下一 Sprint |
| Story 依賴的外部工作（SRE 確認、安全審查）需要超過一個 Sprint 的等待時間 | 標記 NOT_READY，等待外部工作完成後重新 Refinement |
| Story 在估點與 Sprint 容量範圍內可完成 | 記錄「可在單 Sprint 完成」，繼續 |
