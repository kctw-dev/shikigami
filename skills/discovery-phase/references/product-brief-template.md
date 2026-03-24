# Product Brief 格式（§3 詳細規範）

Product Brief 是 Discovery Phase 的核心產出物，使用 `docs/templates/product-brief-template.md` 模板建立。

## 7 個必填區段

| # | 區段名稱 | 說明 |
|---|----------|------|
| 1 | **問題陳述（Problem Statement）** | 清晰描述我們要解決的問題，不含解決方案 |
| 2 | **目標使用者（Target Users）** | 誰會受益？使用者的痛點是什麼？ |
| 3 | **商業假設（Business Assumptions）** | 所有 `[UNCERTAIN]` 假設，含驗證方法 |
| 4 | **提案解決方向（Proposed Direction）** | 方向性描述，不需是完整設計，允許多個選項 |
| 5 | **成功指標（Success Metrics）** | 如何判斷這個需求成功？可量化的指標 |
| 6 | **排除範圍（Out of Scope）** | 明確不做的事情，防止範圍擴張 |
| 7 | **依賴與風險（Dependencies & Risks）** | 技術依賴、外部依賴、已知風險（含 Architect 評估結果） |

## 假設外顯化格式（第 3 區段）

商業假設區段中，所有不確定的假設必須使用以下格式：

```markdown
- [UNCERTAIN] 假設：使用者願意為此功能付費 — 驗證方法：用戶訪談 + A/B 測試付費轉換率
- [UNCERTAIN] 假設：技術方案 X 能在現有架構下整合 — 驗證方法：Architect 概念驗證（PoC）
```

已驗證的假設（有資料佐證）則直接陳述，不加 `[UNCERTAIN]` 標籤。

## 存放規範

- 目錄：`docs/discovery/`
- 命名格式：`PB-{YYYY-MM-DD}-{feature-slug}.md`
- 狀態流轉：草稿 → PO 已簽核 / 退回修改 / 已擱置
