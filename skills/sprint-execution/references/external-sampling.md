# §AC3 外部獨立審查規則（ADR-007 Phase 2 → #958 修正）

<!-- SSOT：story-lifecycle-prompt.md §AC3 已移至此處（Sprint 127 #485 模組化拆分） -->
<!-- ADR-007 Phase 2 實作 — Sprint 24 / US-41 -->
<!-- 來源：docs/adr/ADR-007-story-lifecycle-subagent.md §AC3 -->
<!-- #958 修正：基礎抽樣率從 30% 提升至 100%（全量外部審查） -->

本 subagent 回傳 PASS 後，主 session **必須**對該 Story 派遣獨立 QA subagent 執行外部審查。**判斷與派遣行為由主 session 執行**；本節定義規則，供主 session 參照。

## 外部審查率

**外部審查率：100%（全量）**

所有 Story-Lifecycle subagent 回傳 PASS 的 Story，**必須**接受獨立 QA subagent 外部審查。不得跳過、不得降級、不受 bypass 豁免。

> **#958 修正理由**：原 30% 抽樣率導致 70% Story 僅靠 self-review（Reviewer = Developer）就 merge，seiryu-dev 多次遇到品質問題。Self-review 保留作為第一道過濾，但獨立外部審查是 merge 前的必要 Hard Gate。

## 觸發條件（TC-1 ~ TC-4）— 歷史參考

> 以下觸發條件為基礎審查率 30% 時期的升級規則。基礎率已提升至 100% 後，TC-1~TC-4 自動滿足，不再影響行為。保留供歷史追溯。

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
- 持續時間：全量觸發持續至**連續 2 個 Sprint 無自審品質問題**為止（已失效：基礎率已為 100%，此規則不再影響行為）
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
#958 修正後流程（簡化）：

Story-Lifecycle subagent 回傳 PASS
  → 100% 全量外部獨立審查（無例外）
  → CONFIRM / DISPUTE 處理（見 external-review-dispute.md）

（TC-1~TC-4 歷史參考，不再影響行為）
```
