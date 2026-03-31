# 外部獨立審查結果處理（CONFIRM / DISPUTE）+ Circuit Breaker

<!-- ADR-007 Phase 2 實作 — Sprint 24 / US-41 AC3 -->
<!-- 來源：docs/adr/ADR-007-story-lifecycle-subagent.md §AC3 DISPUTE 處理 -->

主 session 接收外部獨立審查 subagent 回傳結果後，依以下兩個路徑處理。

---

## 4.1 CONFIRM 路徑

外部抽樣審查 subagent 回傳 **CONFIRM**（即確認 Story-Lifecycle subagent 自審結論正確）時，執行以下步驟：

1. **記錄審查結果**：在 Sprint 執行記錄中記錄「{Story ID} 外部審查：CONFIRM」
2. **主 session merge PR**：執行 `gh pr merge <PR_URL>`（#960 修正：CONFIRM 後才 merge）
3. **更新品質指標**：Sprint Review 結束時，將「外部審查執行率」與「DISPUTE 率」更新至 `docs/km/Metrics_Log.md`
4. **繼續下一個 Story**：標記當前 Story 為完成，取出 Sprint Backlog 中下一個待辦 Story 繼續執行

---

## 4.2 DISPUTE 路徑

外部抽樣審查 subagent 回傳 **DISPUTE**（即發現自審結論有誤，存在自審未偵測到的缺陷）時，執行以下步驟：

1. **記錄 DISPUTE 事件**：在 Sprint 執行記錄中記錄「{Story ID} 外部審查：DISPUTE」，標記為 Retrospective Problem
2. **PR 保持未合併**：PR 不 merge（#960 修正：審查通過前不 merge）
3. **傳入缺陷清單**：將外部審查 subagent 回傳的**具體缺陷清單**傳入 Story-Lifecycle subagent，要求修復（缺陷清單須完整，不得省略）
4. **執行修復**：Story-Lifecycle subagent 接收缺陷清單後，push 修復 commit 至 PR branch，修復完成後回傳 PASS 摘要。**subagent 不得執行 `gh pr merge`**（#960：merge 權限僅限主 session 在 CONFIRM 後行使）
5. **強制第二輪外部審查**：修復完成後，強制對該 PR 執行第二輪外部獨立審查（無條件觸發）
6. **第二輪結果處理**：
   - 第二輪 CONFIRM → 主 session 執行 `gh pr merge` → 記錄結果，繼續下一 Story
   - 第二輪 DISPUTE → 暫停 Sprint 執行，升級至 Architect 評估（多次 DISPUTE 視為系統性設計問題）

---

## 4.3 Circuit Breaker 機制（自動降級規則）

<!-- ADR-007 Phase 2 實作 — Sprint 24 / US-41 AC4 -->
<!-- 來源：docs/adr/ADR-007-story-lifecycle-subagent.md §AC3 機制回退 -->

**定義**：當外部抽樣審查的 DISPUTE 率持續偏高，表示 Story-Lifecycle self-review 品質已出現系統性退化，需要框架自動觸發架構重評估。

### 觸發條件

- **閾值**：連續 **3 個 Sprint** 的 DISPUTE 率均超過 **20%**
- **DISPUTE 率計算方式**：當次 Sprint 外部抽樣中 DISPUTE 數 / 外部抽樣執行數
  - 範例：Sprint 中抽樣 3 個 Story，2 個回傳 DISPUTE → DISPUTE 率 = 67%（超過 20%）
  - 範例：Sprint 中抽樣 5 個 Story，1 個回傳 DISPUTE → DISPUTE 率 = 20%（不超過，恰好在閾值）
  - 超過：DISPUTE 率 > 20%（嚴格大於，非大於等於）

### 觸發後動作

當連續 3 個 Sprint DISPUTE 率均 > 20% 時，框架自動執行：

1. 在 Sprint Review / Retrospective 文件中記錄「Circuit Breaker 已觸發」事件
2. 通知 Architect：自審品質持續退化，需在**下一個 Sprint Planning 前**評估是否：
   - 回退至部分封裝模式（ADR-007 選項 C）
   - 引入其他補償機制（如回退至部分封裝模式、增加 Architect 審查層等）
3. 在 Architect 完成評估並做出決策前，維持全量外部審查（基礎率已為 100%，#958 修正）

### 重置條件

Circuit Breaker 計數採用**滾動 3 Sprint 窗口**，重置規則如下：

| 情境 | 計數行為 |
|------|---------|
| 當次 Sprint DISPUTE 率 > 20% | 計數 +1（或維持計數） |
| 當次 Sprint DISPUTE 率 ≤ 20% | 滑動窗口更新；若最近 3 Sprint 中有任一 Sprint DISPUTE 率 ≤ 20%，則不觸發 Circuit Breaker |
| Architect 完成架構重評估並實施改善措施 | 計數**手動重置為 0**，記錄重置事件於 Retrospective_Log.md |

重置記錄格式：`[Circuit Breaker 重置] Sprint N — Architect 重評估完成，實施 {改善措施}，計數重置為 0`

### 品質指標記錄位置

每個 Sprint Review 結束時，將以下指標更新至 `docs/km/Metrics_Log.md`：

| 指標 | 說明 | 用途 |
|------|------|------|
| 自審通過率 | Story-Lifecycle self-review PASS 數 / 總 Story 數 | 監控 subagent 自審效能 |
| 外部審查執行率 | 實際外部審查 Story 數 / 總 PASS Story 數 | 驗證 100% 全量審查是否落實（#958 修正） |
| DISPUTE 率 | 外部抽樣中 DISPUTE 數 / 外部抽樣執行數 | Circuit Breaker 計數依據 |
