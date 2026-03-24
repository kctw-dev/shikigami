# 前端 Story 設計資訊 Pre-check（US-244）

<!-- US-244 前端 Story 設計資訊 Gate — Sprint 88 -->

Sprint Execution 取出 Story 後、派遣 Story-Lifecycle subagent 前，對識別為**前端 Story**的 FEATURE type Story 執行「設計資訊 Pre-check」，確保開發前已具備充分的視覺設計規格，避免開發與設計脫節。

## 前端 Story 識別標準

滿足以下任一條件即識別為前端 Story：

| 識別條件 | 說明 |
|---------|------|
| AC 描述含 UI 元件相關詞語 | 如「頁面」、「元件」、「視覺」、「版面」、「畫面」、「介面」、「按鈕」、「表單」、「對話框」等 |
| AC 描述含前端技術詞語 | 如「React」、「Vue」、「CSS」、「樣式」、「RWD」、「前端」、「瀏覽器」等 |
| Story 標題含前端意圖 | 標題描述明確涉及「UI 實作」、「前端修改」、「頁面設計」等 |

> **注意**：`story_type=DESIGN` 的 Story 不適用本 Pre-check（DESIGN type 走 §4.5 專屬路徑）。本 Pre-check 僅適用於 **FEATURE type 但涉及前端修改**的 Story。

## 設計資訊 Pre-check 流程

```
取出 Story（story_type=FEATURE）
  |
  v
前端 Story 識別（滿足任一識別條件）
  |
  |-- 非前端 Story → [FE-PRECHECK-SKIP] 略過，繼續派遣 subagent
  |
  +-- 識別為前端 Story
        |
        v
      掃描 Sprint 文件與 AC，確認是否存在以下任一設計資訊：
        - Design Spec（設計規格文件連結或附件）
        - Figma Prototype / Frame 連結
        - Design Token 參照（`docs/design/design-tokens.json`）
        - 依賴的已凍結 DESIGN Story Contract
        |
        |-- 設計資訊完整（至少一項存在）
        |     → [FE-PRECHECK-PASS] 設計資訊確認完整，繼續派遣 subagent
        |
        +-- 設計資訊缺失（以上均不存在）
              → 輸出 [FE-PRECHECK-WARN]（告警，不阻塞）
              → 標記 Story 為「需要 UIUX Designer 介入」
              → 繼續派遣 subagent（Developer 可先用 Mock Design 開發，
                但交付前須補充 UIUX/QA 視覺一致性審查）
```

## Pre-check 輸出格式

```
[FE-PRECHECK-PASS] {story_id} — 前端 Story 設計資訊確認完整（{設計資訊項目名稱}）

[FE-PRECHECK-WARN] {story_id} — 前端 Story 缺少設計資訊（未找到 Design Spec / Figma Prototype / Design Token）
  建議：在開發前請 UIUX Designer 提供設計規格；Developer 可以 Mock Design 先行開發，
  但 Story-Lifecycle subagent 交付時須執行 UIUX/QA 視覺一致性審查（見 story-lifecycle-prompt.md §4.7）

[FE-PRECHECK-SKIP] {story_id} — 非前端 Story，跳過設計資訊 Pre-check
```

## 降級策略

- Sprint 文件解析失敗或 AC 讀取錯誤 → `[FE-PRECHECK-SKIP]` 靜默略過，不阻塞
- 設計資訊缺失不觸發 Hard Gate，僅輸出告警（`[FE-PRECHECK-WARN]`）
- 所有情況均不阻塞 Sprint 執行
