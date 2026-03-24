# PO 確認關卡（§4 詳細規範）

Discovery Phase 定義 3 個 PO 確認關卡，任何一個關卡未通過，流程不得繼續推進。

<HARD-GATE>
未經 PO 確認的 Product Brief 不得轉化為 Backlog Item。
</HARD-GATE>

## Gate 1：Product Brief 草稿審查

| 屬性 | 說明 |
|------|------|
| **觸發時機** | Step 3 Product Brief 草稿完成後 |
| **把關者** | PO |
| **通過條件** | (1) 問題陳述清晰、無解決方案污染；(2) 所有不確定假設已用 `[UNCERTAIN]` 標籤外顯化；(3) 7 個區段均已填寫 |
| **未通過後果** | 退回 Step 2 重新執行假設外顯化，或退回 Step 3 補充缺失區段 |

## Gate 2：技術可行性確認

| 屬性 | 說明 |
|------|------|
| **觸發時機** | Step 4 Architect 技術評估完成後 |
| **把關者** | Architect（確認無技術阻礙）|
| **通過條件** | Architect 確認：(1) 技術方向可行；(2) 無當前無法克服的技術阻礙；(3) ADR 需求已識別並標注 |
| **未通過後果** | Product Brief 進入「技術阻礙」狀態，暫停推進，待技術問題解決（可能需要先執行 `/architecture-decision`） |

## Gate 3：PO 最終簽核

| 屬性 | 說明 |
|------|------|
| **觸發時機** | Step 5 PO 最終審查 |
| **把關者** | PO（最終決策者）|
| **通過條件** | PO 明確選擇以下三種決議之一 |
| **決議選項** | **批准**：進入 Step 6；**退回**：指定修改點，退回對應步驟；**擱置**：記錄擱置原因，存檔 |
| **未通過後果** | 退回指定步驟修改（退回），或存入擱置清單（擱置），均不得進入 Step 6 |

## Hard Gates 彙整

| Gate | 觸發時機 | 把關者 | 未通過後果 |
|------|----------|--------|------------|
| **Gate 1**：Product Brief 草稿審查 | Step 3 完成後 | PO | 退回 Step 2 或 Step 3 |
| **Gate 2**：技術可行性確認 | Step 4 完成後 | Architect | Product Brief 暫停，待技術問題解決 |
| **Gate 3**：PO 最終簽核 | Step 5 | PO | 退回修改 or 擱置，均不進 Step 6 |

**強制規則**：任何 Product Brief 未通過 Gate 3 PO 最終簽核，不得執行 Step 6 轉化為 Backlog。此為不可繞過的 Hard Gate。
