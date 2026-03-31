# Delivery Phase 雙 Team 視覺對比 Gate（§4.7 / #385 / ADR-034）

<!-- #385 GAD Delivery Phase 視覺對比 Gate — Sprint 133 -->
<!-- 依賴：ADR-034 browser-automation tool selection（Accepted，PR#560） -->

**適用條件**：Story 為 frontend FEATURE（AC 含有 Figma Prototype URL），Story-Lifecycle subagent 完成 Code Review 通過後、建立 PR 之前觸發（#960 修正：subagent 不再 merge，Visual Gate 在 PR 建立前執行）。

**跳過條件（AC5）**：後端 / Infra / DESIGN / RESEARCH Story 自動跳過（判斷：AC 或 issue body 中無 Figma Prototype URL）。跳過時輸出 `[VISUAL-GATE-SKIP] 非前端 Story，跳過視覺對比 Gate`。

## 執行流程

```
[VISUAL-GATE-START] story={id} 時間={timestamp}

1. 取得 Figma Prototype URL（從 issue body 或 DESIGN Contract）
   |-- 找不到 URL → [VISUAL-GATE-SKIP] 跳過
   |-- 找到 URL → 繼續

2. Agent B（Vision Critic）執行雙 Team 視覺對比：
   a. 截圖 Agent 實作結果（agent-browser screenshot）
   b. 截圖 Figma Prototype（Figma Export / talk-to-figma）
   c. 呼叫 skills/vision-critic/SKILL.md 執行分數評估

3. 產出結構化差異報告（AC3）：
   - 截圖路徑：/tmp/visual-gate/{story-id}-impl.png + {story-id}-figma.png
   - Vision Critic 分數：{0-100}
   - 差異項目清單：{具體差異描述}
   - 判定：PASS（分數 ≥ 80）/ FAIL（分數 < 80）

4. 判定結果（AC4）：
   |-- PASS（Vision Critic ≥ 80） → [VISUAL-GATE-PASS] 繼續建立 PR
   +-- FAIL（Vision Critic < 80） → [VISUAL-GATE-FAIL] 阻擋 PR 建立
         - 輸出具體差異描述（NFR1 要求：包含足夠資訊讓 Developer 定位問題）
         - 差異報告含截圖對比路徑 + 量化分數（NFR2）
         - 通知 Developer 修復後重新觸發
```

**降級（agent-browser 或 talk-to-figma 不可用）**：輸出 `[VISUAL-GATE-DEGRADED] 視覺對比工具不可用，降級為人工確認`，不阻擋 merge，但在 PR description 標記「需人工視覺確認」。
