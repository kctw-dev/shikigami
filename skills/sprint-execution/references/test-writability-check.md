# 測試可寫性檢查（TDD Red 階段前置，US-240）

<!-- SSOT：story-lifecycle-prompt.md §3 Red 測試可寫性檢查已移至此處（Sprint 127 #485 模組化拆分） -->
<!-- US-240 TDD 測試可寫性檢查 — Sprint 88 -->

在撰寫第一個失敗測試前，必須先對每個 AC 執行「測試可寫性檢查」，確認 AC 具備足夠的資訊可寫出有意義的斷言（assertion）。

> **角色上下文**：測試可寫性檢查涉及 AC 品質判斷，若觸發 ESCALATE: REQUIREMENT_AMBIGUITY 需向 PO/Architect 提供結構化問題。進入此檢查前，應已透過 §3 Hard Gate 載入 `developer-prompt.md`；若升級路徑需引用 PO 或 Architect 視角，使用 Read 工具讀取 `agents/product-owner.md` 與 `agents/architect.md` 以理解其決策框架。

## 判斷條件（滿足任一即判定為「無法寫測試」）

| 條件編號 | 判斷條件 | 說明與範例 |
|---------|---------|-----------|
| TC-W1 | **AC 描述模糊無法寫 assertion** | AC 描述使用「適當」、「正確」、「合理」等主觀詞語，無法轉化為可驗證的斷言。例：「系統應適當處理錯誤」無法確定預期值 |
| TC-W2 | **AC 缺少輸入/輸出定義** | AC 未定義輸入資料格式、邊界值、或預期的輸出值/狀態碼/回應結構。例：「API 應回傳使用者資料」未說明回傳欄位 |
| TC-W3 | **AC 涉及未定義的外部依賴** | AC 描述依賴尚未定義的外部系統行為、API 契約、或第三方服務規格，無法建立 mock 或 stub。例：「依 {外部服務} 的規格處理」但規格文件不存在 |
| TC-W4 | **AC 之間存在邏輯矛盾** | 同一 Story 的多個 AC 之間存在相互排斥的行為描述，無法同時滿足。例：AC1 要求「操作不可逆」、AC3 要求「可撤銷最近操作」 |
| TC-W5 | **AC 的完成標準無法量測** | AC 描述的驗收標準為主觀或定性判斷，無法轉化為可重複執行的自動化測試。例：「頁面應呈現良好的用戶體驗」 |

## 執行流程

```
對每個 AC 執行測試可寫性評估：
  |
  v
逐條掃描 AC，判斷是否觸發以上任一條件（TC-W1 ~ TC-W5）
  |
  |-- 所有 AC 均通過（無任何條件觸發）
  |     → 測試可寫性檢查：PASS
  |     → 繼續執行 Red 階段步驟 1（撰寫失敗測試）
  |
  +-- 任一 AC 觸發上述條件
        → 測試可寫性檢查：FAIL
        → 輸出結構化問題清單（格式見下方）
        → 回傳 ESCALATE: REQUIREMENT_AMBIGUITY
        → 禁止繼續進入 Red 階段（Hard Gate）
```

## ESCALATE: REQUIREMENT_AMBIGUITY 結構化問題清單格式

```
測試可寫性檢查失敗 — {story_id}

觸發條件：{TC-W1 ~ TC-W5，列出所有觸發的條件編號}

問題清單：
- [問題 1] AC{編號}：{觸發條件} — {具體說明，指出 AC 原文中模糊/缺少的部分}
  建議補充：{具體建議 PO 或 Architect 補充的資訊}
- [問題 2] AC{編號}：{觸發條件} — {具體說明}
  建議補充：{具體建議}
（依問題數量依序列出）

影響範圍：
- 受影響 AC：{列出所有無法寫測試的 AC 編號}
- 可繼續執行 AC：{列出所有可正常寫測試的 AC 編號，若無則填「無」}

建議行動：請 PO / Architect 釐清上述問題後重新派遣 Story-Lifecycle subagent。
```

<HARD-GATE>
**測試可寫性 Hard Gate**：任一 AC 觸發 TC-W1 ~ TC-W5，禁止進入 Red 階段撰寫測試，必須回傳 ESCALATE: REQUIREMENT_AMBIGUITY。此 Gate 不受 bypass=true 豁免。
</HARD-GATE>
