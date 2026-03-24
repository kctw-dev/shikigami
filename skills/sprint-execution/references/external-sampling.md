# §AC3 外部抽樣審查觸發邏輯（ADR-007 Phase 2）

<!-- SSOT：story-lifecycle-prompt.md §AC3 已移至此處（Sprint 127 #485 模組化拆分） -->
<!-- ADR-007 Phase 2 實作 — Sprint 24 / US-41 -->
<!-- 來源：docs/adr/ADR-007-story-lifecycle-subagent.md §AC3 -->

本 subagent 回傳 PASS 後，主 session 依以下規則判斷是否觸發外部抽樣審查（External Sampling Review）。**判斷與派遣行為由主 session 執行**；本節定義判斷規則，供主 session 參照。

## 基礎抽樣率

**基礎抽樣率：30%（取上整）**

計算方式：當前 Sprint Story 總數 × 30%，結果取上整（ceiling）。

範例：
- 4 Story Sprint → 4 × 0.30 = 1.2 → 取上整 = **2 個 Story** 接受外部抽樣
- 5 Story Sprint → 5 × 0.30 = 1.5 → 取上整 = **2 個 Story** 接受外部抽樣
- 3 Story Sprint → 3 × 0.30 = 0.9 → 取上整 = **1 個 Story** 接受外部抽樣

**基礎抽樣 Story 選取優先順序：**
1. 優先選取 Size 最大的 Story（M 優先於 S）
2. 次優先選取本 Sprint 中修改檔案數量最多的 Story（依回傳的修改檔案清單計算）
3. 隨機保底：若所有 Story 規模和修改量相近，隨機選取達到 30% 門檻

## 觸發條件評估（TC-1 ~ TC-4）

以下觸發條件依序評估（TC-1 → TC-2 → TC-3 → TC-4），**任一條件觸發即執行全量外部審查（抽樣率提升至 100%）**，不繼續評估後續條件。

---

### TC-1：L-size Story 全量觸發

**判斷規則：**
- 條件：本 Sprint 的 Story 中存在 Size = L 的 Story
- 觸發：是 → 本 Sprint **所有 Story** 均接受外部抽樣審查（100% 全量）
- 說明：L-size Story 涉及範圍廣、AC 數多，自審遺漏風險高，強制全量確保品質

**評估時機：** Sprint 執行開始前或每個 Story 處理時，檢查 Sprint Backlog 中是否含 L-size Story。

---

### TC-2：安全相關 AC 全量觸發

**判斷規則：**
- 條件：當前 Story 的 AC 中含有安全相關驗收條件
- 安全相關 AC 識別標準（滿足任一即判定）：
  - AC 類型標記為 `[動態]` 且涉及外部輸入處理
  - AC 描述涉及認證（authentication）/ 授權（authorization）
  - AC 描述涉及加密、金鑰、secrets 管理
  - AC 描述涉及 API 端點新增或修改
- 觸發：是 → 本 Sprint **所有 Story** 均接受外部抽樣審查（100% 全量）
- 說明：安全問題一旦遺漏，修復成本高且可能產生合規風險

**評估時機：** 每個 Story 的 AC 清單讀取後立即評估。

---

### TC-3：前次 Sprint Review 自審品質問題全量觸發

**判斷規則：**
- 條件：前次 Sprint Review 或 Retrospective 中記錄了「自審遺漏缺陷」問題（即外部審查或 Stakeholder 發現了 Story-Lifecycle self-review 未偵測到的問題）
- 觸發：是 → 本 Sprint **所有 Story** 均接受外部抽樣審查（100% 全量）
- 持續時間：全量觸發持續至**連續 2 個 Sprint 無自審品質問題**為止，之後恢復基礎 30% 抽樣率
- 計數規則：
  - 若當次 Sprint 在全量觸發下無 DISPUTE 事件 → 清潔計數 +1
  - 若當次 Sprint 出現 DISPUTE 事件 → 清潔計數重置為 0
  - 清潔計數達到 2 → 下一 Sprint 恢復基礎抽樣率

**觸發來源識別：** 從 `docs/km/Retrospective_Log.md` 中查找前次 Sprint 的「自審品質問題」記錄項目。

**評估時機：** Sprint 執行開始時，讀取 Retrospective_Log.md 確認前次 Sprint 問題記錄。

---

### TC-4：連續 2 次 self-review FAIL 強制觸發

**判斷規則：**
- 條件：Story-Lifecycle subagent 在同一 Story 的任一審查階段（Spec Compliance 或 Code Quality）連續自審 FAIL 達 **2 次**
- 觸發：是 → 該 Story **強制接受外部抽樣審查**（不等 Story 最終回傳 PASS）
- 說明：連續 self-review FAIL 表示自審機制可能存在盲點，需外部獨立視角介入
- 注意：TC-4 僅影響當前 Story，不自動升級為全 Sprint 全量（但可與其他 TC 疊加）

**評估時機：** Story-Lifecycle subagent 回傳結果時，主 session 檢查回傳摘要中的審查失敗次數記錄。

---

## 觸發條件優先順序總結

```
評估順序：TC-1 → TC-2 → TC-3 → TC-4

TC-1 觸發（L-size Story 存在）
  → 本 Sprint 全量 100%，跳過後續評估

TC-2 觸發（安全相關 AC）
  → 本 Sprint 全量 100%，跳過後續評估

TC-3 觸發（前次 Sprint 自審品質問題）
  → 本 Sprint 全量 100%，跳過後續評估

TC-4 觸發（當前 Story 連續 2 次 self-review FAIL）
  → 當前 Story 強制外部抽樣

以上條件均未觸發
  → 基礎 30% 抽樣率（依優先順序選取 Story）
```
