# Systematic Debugging — 四階段流程詳解

## Phase 1: 根因調查

```
1. 仔細閱讀錯誤訊息（不跳過 stack trace）
   |
   v
2. 穩定重現問題（記錄精確步驟）
   |
   v
3. 檢查近期變更（git diff, recent commits）
   |
   v
4. 多元件系統：在每個元件邊界加診斷 log
   |
   v
5. 追蹤資料流：從壞值往回追到源頭
```

**Phase 1 詳解**：

1. **閱讀錯誤訊息**：完整閱讀 error message 與 stack trace，不可僅看第一行就跳過。Stack trace 中的每一層呼叫都是線索。
2. **穩定重現**：找到可 100% 重現問題的精確步驟。無法穩定重現的 bug 不可直接進入修復階段。
3. **檢查近期變更**：使用 `git diff`、`git log` 檢查近期的 commit，確認問題是否由最近的變更引入。
4. **元件邊界診斷**：在微服務或多模組架構中，於每個元件的輸入/輸出點加入診斷 log，縮小問題範圍。
5. **資料流追蹤**：從觀察到的錯誤值（壞值）往回追溯，找到資料最初被汙染或錯誤產生的源頭。

6. **根因分類**：完成上述調查後，依據語意分析將根因歸入以下 4 類，並決定對應路由。

### 根因分類表

| 根因分類 | 判定依據（語意分析） | 路由目標角色 | 建議處置動作 |
|----------|----------------------|--------------|--------------|
| 實作問題（程式碼 Bug） | 錯誤源於程式碼實作缺陷，非規格定義問題 | Developer | 修復程式碼，補充對應測試 |
| 規格問題（SDD/API 契約定義錯誤） | 介面定義、函式簽名或參數型別描述與實作不符 | Architect | 修正 SDD/API 契約，通知相關實作方 |
| 業務規則問題（AC/Product Brief 描述不符） | 測試斷言對應 AC 描述，非程式碼本身缺陷 | PO | 釐清 AC 意圖，必要時修訂驗收條件 |
| API 問題（外部 API 行為與文件不符） | 回應 schema 或 HTTP status 與 API 文件定義不一致 | Knowledge Ingestion 更新 | 觸發 Knowledge Ingestion 更新 API 文件；若 Knowledge Ingestion 不可用，標記 [KNOWLEDGE-GAP] 並繼續 Developer 修復路徑 |

### 根因判定規則（BDD 行為範例格式）

| # | Given（錯誤情境） | Then（根因分類） |
|---|-------------------|------------------|
| R1 | 測試錯誤類型為 runtime error（TypeError / ImportError / SyntaxError），且錯誤不涉及介面定義或 API 文件 | 分類為「實作問題」→ 路由至 Developer |
| R2 | 測試錯誤涉及介面不符（函式簽名錯誤、參數型別不符、模組介面定義異常） | 分類為「規格問題」→ 路由至 Architect |
| R3 | 測試錯誤類型為 assertion failure，且失敗斷言可對應 AC 或 Product Brief 的業務描述 | 分類為「業務規則問題」→ 路由至 PO |
| R4 | 測試錯誤涉及外部 API 回應 schema 不符或 HTTP status 異常（非程式碼邏輯問題） | 分類為「API 問題」→ 路由至 Knowledge Ingestion 更新 |

> **語意分析注意事項**：判定依據為語意理解，非關鍵字 pattern matching。同一錯誤訊息可能同時符合多條規則，此時優先採用最具體的規則（R4 > R3 > R2 > R1）。

### API 問題的 Graceful Degradation

```
API 問題分類確認
      |
      v
嘗試觸發 Knowledge Ingestion 更新
      |
      +-- Knowledge Ingestion 可用 ──→ 更新 API 文件，重新驗證
      |
      +-- Knowledge Ingestion 不可用 ──→ 標記 [KNOWLEDGE-GAP]
                                              |
                                              v
                                         繼續 Developer 修復路徑
                                         （暫時 workaround，待 KI 恢復後補正）
```

**[KNOWLEDGE-GAP] 標記格式**：

```
[KNOWLEDGE-GAP]
分類：API 問題
說明：Knowledge Ingestion 不可用，無法驗證 API 文件與實際行為一致性。
暫時路由：Developer 修復路徑（workaround）
待辦：Knowledge Ingestion 恢復後，重新觸發 API 文件更新。
```

### 追溯報告輸出格式

Phase 1 流程結尾（完成根因分類後），必須輸出以下結構化追溯報告：

```
[ROOT-CAUSE-TRACE]
根因分類：<實作問題 | 規格問題 | 業務規則問題 | API 問題>
判定依據：<語意分析說明，引用具體錯誤訊息或 stack trace 片段>
路由目標角色：<Developer | Architect | PO | Knowledge Ingestion>
建議處置動作：<具體建議，一到三條>
```

**輸出範例**：

```
[ROOT-CAUSE-TRACE]
根因分類：業務規則問題
判定依據：測試斷言 `assert result.status == "approved"` 失敗，對應 AC3「訂單金額 > 1000 時自動核准」，
          實際回傳 status="pending"，推測為 AC 定義的金額門檻與實作不一致。
路由目標角色：PO
建議處置動作：
  1. 釐清 AC3 金額門檻的精確定義（含或不含邊界值）
  2. 確認「自動核准」的業務邏輯是否有其他前置條件
  3. PO 確認後更新 AC，Developer 依新 AC 修正實作
```

---

## Phase 2: 模式分析

1. **找到可運作的類似代碼**：在 codebase 中搜尋功能相似但正常運作的代碼片段。
2. **比較差異**：將問題代碼與正常代碼逐項比對，列出所有差異。
3. **理解依賴關係**：釐清問題代碼所依賴的模組、服務、設定，確認是否有依賴層的異常。

---

## Phase 3: 假設與驗證

```
形成假設 → 最小變更測試 → 驗證結果
    ^                         |
    |     未通過：新假設       |
    +-------------------------+
    |     通過：進入 Phase 4   |
    +-------------------------→ Phase 4
```

1. **形成單一假設**：明確陳述「我認為 X 是根因，因為 Y」，假設必須具備可證偽性。
2. **最小變更測試**：一次只改一個變數，執行測試驗證假設。
3. **判定結果**：
   - 驗證通過 → 進入 Phase 4
   - 驗證未通過 → 回到步驟 1，形成新假設

---

## Phase 4: 實作修復

1. **先寫失敗測試（TDD）**：撰寫一個能重現 bug 的測試案例，確認測試在修復前為失敗狀態。
2. **實作單一修復**：只修根因，不做額外的「順手改進」。修復範圍必須與根因調查結果一致。
3. **驗證通過 + 無回歸**：確認失敗測試轉為通過，且既有測試套件全部通過、無新增回歸。
