# Analytics Prompt — Retrospective Analytics 趨勢分析

> 此檔案為 Analytics Subagent 的角色專屬 prompt，由主 session 編排時引用。

## 角色職責

Analytics Subagent 負責分析歷史 Retrospective 資料，產出趨勢報告，供 Retrospective 參考。

## 輸入

- `docs/km/Retrospective_Log.md`（由 Analytics subagent 自行讀取，主 session 不直接讀取）

## 前置檢查

- 若 `docs/km/Retrospective_Log.md` **不存在**：輸出「尚無 Retrospective 記錄」，正常結束 Analytics。
- 若檔案存在但只有 **1 個 Sprint 記錄**：頻率統計區塊輸出「資料不足（需至少 2 個 Sprint）」；Action Items 關閉速度與待關閉 Items 區塊正常計算輸出。

## 報告格式（四區塊，缺一不可）

```
## Retrospective Analytics 報告（Sprint N 前）

### ① Good 趨勢

### ② Problem 趨勢

### ③ Action Items 關閉速度

### ④ 待關閉 Items
```

## ① Good 趨勢 — 分析規則

1. 讀取所有 Sprint 的 `### Good` 區塊，以**語義主題**歸類（關鍵字相近即同一主題）。
2. 出現 **2 次以上**的主題，輸出：主題關鍵字、出現次數、最近出現 Sprint。
3. 無重複主題時，輸出「無重複 Good 趨勢」。

## ② Problem 趨勢 — 分析規則

1. 讀取所有 Sprint 的 `### Problem` 區塊，以**語義主題**歸類。
2. 出現 **2 次以上**的主題，輸出：主題關鍵字、出現次數、首次與最近出現 Sprint、若未解決加註「跨 N 個 Sprint 未解決」。
3. **連續出現**判斷：
   - 連續情境（最新 Sprint 仍出現且無中斷）→ 醒目標注 `> ⚠️ **重複問題（連續 N 個 Sprint）**`
   - 間斷情境 → 說明是否已解決，不觸發警示
4. 無重複主題時，輸出「無重複 Problem 趨勢」。

## ③ Action Items 關閉速度 — 分析規則

1. 收集所有 Sprint 的 Action Item，對 Closed Item 計算**關閉速度** = 關閉 Sprint - 建立 Sprint。
2. 輸出：平均（四捨五入至一位小數）、最快、最慢關閉速度。無 Closed Item 時輸出「尚無已關閉 Action Item」。
3. 對 **Open** Item 計算逾期 Sprint 數並標注。

## ④ 待關閉 Items — 分析規則

1. 列出所有 Open Action Item：Item 內容、Owner、建立 Sprint、逾期 Sprint 數。
2. 無 Open Item 時，輸出「目前無待關閉 Action Items」。

## SPACE 五維度量測

**執行時機**：步驟 2（Good/Problem/Action 收集）完成後，步驟 3（Action Item 建立 Issue）之前執行。

**誰量測**：Sprint Review 主持者（主 session）負責統計 P、C、E 數值，並邀請 PO/Stakeholder 在 Sprint Review 結束前評分 S 維度；A 維度直接引用本 Sprint 的完成率。

**資料來源**：

| 維度 | 資料來源 |
|------|---------|
| S（Satisfaction） | PO 或 Stakeholder 在 Sprint Review Demo 結束後現場評分（口頭確認後記錄） |
| P（Performance） | 從本 Sprint 的不確定性三問記錄、外部抽樣審查記錄中統計幻覺攔截次數與漏網次數 |
| A（Activity） | 引用 `docs/km/Metrics_Log.md` 主表格本 Sprint 的「完成率」欄位，不重複計算 |
| C（Communication） | 從本 Sprint 的 Retro 記錄與 QA 互審記錄中統計跨 Agent 交叉確認發現的問題數 |
| E（Efficiency） | 從本 Sprint 的 Checkpoint 記錄統計 `[CHECKPOINT-FAIL]` 數量（斷鏈次數）加上使用者手動介入修正的次數 |

**執行步驟**：

1. 主 session 從本 Sprint 對話記錄、Checkpoint 記錄、Retro 記錄中統計 P、C、E 的原始數值。
2. 邀請 PO/Stakeholder 口頭確認 S（滿意度 1-5）。
3. 將 A 欄位標注為引用本 Sprint 完成率（格式：「= 完成率 X%」）。
4. 填入 `docs/km/Metrics_Log.md` 的 `## SPACE 五維度指標` 表格。

## Quality Observer 診斷報告

**執行時機**：步驟 2.5（SPACE 五維度量測）完成後、步驟 3（Action Item 建立 Issue）之前執行。

**目的**：基於本 Sprint 的 SPACE 數據，從系統性行為模式角度產出品質診斷，補充 Good/Problem/Action 收集所未能涵蓋的跨 Sprint 模式識別。

**與 SPACE 量測的關係**：Quality Observer 消費步驟 2.5 填入的 SPACE 數值（P、C、E 維度），轉化為三維度行為模式診斷（幻覺頻率、斷鏈模式、角色協作效率）。SPACE 記錄表是數據來源，Quality Observer 診斷報告是模式詮釋層。

**執行步驟**：

1. 讀取本 Sprint 的 SPACE 數據（P、C、E 欄位）及前三個 Sprint 的歷史 SPACE 數據（用於趨勢計算）。
2. 依 `docs/km/Quality_Observer.md` 的診斷報告格式，逐一填入三維度觀察數值與模式識別描述。
3. 判定各維度警示狀態，給出綜合診斷結論（健康 / 輕度警示 / 嚴重警示）。
4. 輸出完整診斷報告（格式見 `docs/km/Quality_Observer.md`「診斷報告格式」區塊）。

**診斷報告的後續使用**：
- **健康**：記錄至本 Sprint Retrospective_Log.md 附錄，無需額外行動。
- **輕度警示**：將改善建議列為 Retrospective Action Item 候選，由主 session 決定是否納入步驟 3 建立 GitHub Issue。
- **嚴重警示**：須立即將改善建議提交為 Retrospective Action Item，並標注優先級為高；若涉及結構性斷鏈或連續性幻覺，需升級至 Architect/PO 決策。

**注意事項**：
- Quality Observer 診斷報告聚焦於**行為模式**，不記錄個別 bug 或具體缺陷內容（那是 QA 的職責）
- 若本 Sprint 為系統首次使用 Quality Observer（尚無歷史 SPACE 數據），前三 Sprint 平均欄位填「資料不足」
- 診斷報告不阻塞步驟 3 的執行；即使無警示，也應完成報告輸出
