# §6.5 Runtime Verification（執行期驗證）

<!-- SSOT：story-lifecycle-prompt.md §6.5 已移至此處（Sprint 127 #485 模組化拆分） -->
<!-- US-184 新增 — Sprint 72 -->

**觸發條件**：`doc_only=false` 時必須執行。`doc_only=true` 時標記為 N/A，跳過此步驟。

**目的**：確保 bug fix 和新功能真的有效，而不只是靜態代碼審查通過。

## 依 Story 類型選擇驗證方式

### Bug Fix Story

1. 重現原始問題的步驟（依照 Bug Report 或 AC 描述，在修復前的語境中確認原始症狀存在）
2. 確認修復後症狀消失（執行相同重現步驟，確認問題不再復現）
3. 若無法在本 subagent 環境中重現，需明確說明原因並提出替代驗證方式

### API 修改 Story

1. 使用 `curl` 或 `httpie` 實際打 API，確認回應結構與欄位正確
2. 驗證範例（curl）：
   ```bash
   curl -s -X {METHOD} {endpoint} \
     -H "Content-Type: application/json" \
     [-H "Authorization: Bearer {token}"] \
     [-d '{request_body}']
   ```
3. 確認回應狀態碼與 AC 定義一致
4. 確認回應 payload 欄位名稱與型別正確

### 前端修改 Story

1. 檢查渲染邏輯，確認 UI 元件的條件分支正確
2. 實際跑 dev server（如 `npm run dev` / `yarn dev`），確認頁面可正常載入
3. 在瀏覽器 / headless 環境確認修改後的畫面符合 AC 預期

### 其他 Story（無法歸類上述三類）

1. 設計並執行至少一個「端到端」驗證步驟
2. 說明驗證方式與預期結果

## 驗證清單格式

```
Runtime Verification — {story_id}

Story 類型：Bug Fix / API 修改 / 前端修改 / 其他 / N/A（doc_only）

驗證步驟執行結果：
- [ ] 驗證步驟 1：{描述} → 結果：{PASS/FAIL + 說明}
- [ ] 驗證步驟 2：{描述} → 結果：{PASS/FAIL + 說明}
（依實際執行步驟列出）

整體結論：PASS / FAIL / N/A
```

## 修復閉環規則

- 若 FAIL：在本 subagent 內部修復，重新執行驗證
- 同一驗證步驟連續失敗 **3 次** → 回傳 `ESCALATE: DESIGN_ISSUE`
