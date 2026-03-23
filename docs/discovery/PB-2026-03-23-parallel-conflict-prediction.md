# Product Brief: Parallel Conflict Prediction — 平行任務衝突預測

**Issue 來源：** #342 研究報告 Issue #4
**優先級：** 中
**日期：** 2026-03-23
**PB 狀態：** Draft

---

## 1. 問題陳述

Shikigami 的 Scrum Master 角色目前在派遣 Sprint 任務時，雖已具備同檔案衝突偵測與自動序列化機制，但衝突偵測發生在「執行時」——即 subagent 實際修改檔案時才發現衝突。這導致已啟動的 subagent 被強制等待，造成 GPU/token 資源浪費，並延長 Sprint 執行時間。

業界（Google ADK、Claude Code 文件）明確指出：平行 agent 執行的黃金法則是「只在 agent 接觸不同檔案時才能真正平行」。事後偵測是次優策略，事前預測才能最大化並行效率。

---

## 2. 目標使用者

**主要使用者：** 使用 Shikigami 執行大型 Sprint（含 5 個以上並行任務）的開發者或 AI 團隊 Operator
- 期望最大化 subagent 並行效率，縮短 Sprint 完成時間
- 希望事前知道任務排程計劃，而非事後被動等待

**次要使用者：** Stakeholder 角色
- 需要在 Sprint 開始前審視任務分組計劃，確認排程符合優先級預期
- 需要可視的 dispatch plan 作為 Sprint 執行的透明記錄

---

## 3. 商業假設

**假設外顯化（三問）：**

1. **我們假設靜態檔案分析能在 Sprint 啟動前預測大多數衝突** — Scrum Master 可以在派遣前透過 User Story 的描述或歷史變更記錄，判斷各任務可能修改哪些檔案。[UNCERTAIN] 若任務描述粒度過粗（例如「重構整個 src/ 目錄」），靜態分析無法產生有效預測，衝突預測準確率可能不足 50%。需在 PoC 階段以真實 Sprint 資料驗證準確率基準。

2. **我們假設事前分組能顯著減少執行時等待** — 對 5 個以上任務的 Sprint，事前分組可將平行效率提升 20% 以上（相較於現有執行時序列化策略）。[UNCERTAIN] 若多數 Sprint 的任務天然互不重疊，事前分析只會增加啟動延遲而不帶來效益。

3. **我們假設 Stakeholder 對可視的 dispatch plan 有明確需求** — 使用者希望在 Sprint 開始前能看到任務分組計劃，並認為這提升了對 AI 團隊行為的掌握感。[UNCERTAIN] 若使用者習慣全權交給 AI 自主排程，dispatch plan 的可視化可能是過度工程。

---

## 4. 提案解決方向

在 Scrum Master 的 Parallel Dispatch 流程前加入靜態衝突分析：

```
[升級後的 Parallel Dispatch Flow]
1. 接收 Sprint Backlog（N 個任務）
2. [新增] 衝突預測：為每個任務推斷預計修改的檔案集合
   - 基於 User Story 描述中的模組/檔案關鍵字
   - 參考歷史 trace log 中同類任務的實際修改記錄
3. [新增] 任務分組：
   - Group A（可平行）：檔案集合互不重疊的任務組合
   - Group B（需序列）：共享檔案或不確定範圍的任務
4. 輸出 dispatch plan（標示平行 vs. 序列分組）供 Stakeholder 確認
5. 先派遣 Group A 平行執行
6. Group A 完成後，依 Group A 的實際變更動態重新評估 Group B 的衝突狀態
7. 序列或最終平行執行 Group B
```

追蹤指標：記錄「預測衝突 vs. 實際衝突」比率，作為持續改進依據。

---

## 5. 成功指標

- **預測準確率：** 衝突預測的精確率（Precision）> 75%（預測有衝突者實際確實有衝突），確保不過度序列化
- **召回率（Recall）：** 實際衝突被預測到的比率 > 80%，確保不漏掉真正的衝突
- **效率提升：** 在含 5 個以上任務的 Sprint 中，平行執行效率（並行任務數 / 總任務數）提升 > 15%
- **Dispatch Plan 輸出率：** 每個 Sprint 100% 產出可視化的任務分組計劃
- **動態重評估觸發：** Group B 因 Group A 變更而改變衝突狀態時，動態重評估覆蓋率 100%

---

## 6. 排除範圍

- **不含語意層衝突分析：** 本 PB 僅處理檔案層級的衝突預測，不分析兩個任務在邏輯上是否矛盾（語意衝突屬 Architect 審查範疇）
- **不含跨 Sprint 衝突管理：** 預測範圍限於單一 Sprint 內的任務分組，跨 Sprint 依賴圖為後續需求
- **不含即時重調度 UI：** dispatch plan 以靜態文件輸出，不建立拖拉式排程介面
- **不含資源競爭管理：** 本 PB 僅關注檔案衝突，不處理 API rate limit 或 token budget 競爭

---

## 7. 依賴與風險

**依賴：**
- Issue #1（Structured Trace Log）：歷史 trace log 是衝突預測的重要輸入，若 trace log 尚未實作，預測只能依賴 User Story 文字，準確率偏低
- Scrum Master 角色定義需更新，加入 Pre-dispatch Analysis 步驟
- Stakeholder 角色需更新，增加審視 dispatch plan 的互動點

**技術風險：**
- **預測準確率不足風險：** 若 User Story 描述抽象，靜態分析無法識別具體修改檔案，預測退化為隨機猜測。[UNCERTAIN] 需在導入後追蹤準確率，若持續低於 60% 則需重新評估策略
- **過度序列化風險：** 保守的衝突預測傾向於將任務放入 Group B，反而讓並行效率低於現有機制

**商業風險：**
- Sprint 啟動前的分析步驟增加 latency，若 Sprint 任務數少（< 3 個），此開銷得不償失，需設定最小任務數閾值才啟動預測
