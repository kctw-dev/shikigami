# Security Engineer Refinement 職責

<!-- US-203 角色 Refinement 職責定義 — Sprint 77 -->

Security Engineer 在 Refinement 中負責提前識別 Story 的安全風險，確保安全需求在開發啟動前已明確定義於 AC 中。Security Engineer 在 Refinement 中為**諮詢（Consulted）**角色，不主持、不輸出正式報告，但需提供具體安全風險評估意見。

## 觸發條件

Security Engineer **須出席 Refinement** 的情況（滿足任一條件）：

| 觸發條件 | 說明 |
|---------|------|
| Story Type 為 SECURITY | SECURITY Story 必須由 Security Engineer 作為 Contract Owner 確認修復方案方向 |
| Story 的 AC 含 `[安全]` 標記 | AC 已明確標注安全需求，需 Security Engineer 確認驗收標準可行性 |
| Story 涉及外部輸入、認證、授權或加密 | 即使 Story Type 非 SECURITY，涉及安全面向需 Security Engineer 提前評估 |
| FEATURE / INTEGRATION Story 引入新 API 端點 | 新 API 端點具備攻擊面，需提前識別輸入驗證與認證需求 |

**不觸發出席**：doc-only Story（僅修改 docs/ 文件）、純 RESEARCH 探索性 Story 且無程式碼交付物。

## 職責說明

| 面向 | 職責內容 |
|------|---------|
| **威脅識別** | 針對 Story 草稿，識別潛在安全威脅向量（OWASP Top 10 類別），列出受影響範圍 |
| **安全 AC 建議** | 若 Story 缺少對應安全驗收條件，建議補充至 AC 清單（如輸入驗證、認證流程、加密要求）|
| **Contract Owner 確認（SECURITY Story）** | 作為 SECURITY Type 的 Contract Owner，確認修復方案方向，提供安全審查策略初稿 |
| **Security Review 觸發預判** | 判斷 Story 完成後是否需觸發 Security Review Skill，並在 Refinement 報告中預先記錄 |

## Refinement 輸出

| 輸出項目 | 說明 |
|---------|------|
| 安全風險評估摘要 | 列出識別的威脅向量（OWASP 分類）、受影響範圍與嚴重度（Critical / High / Medium / Low）|
| 安全 AC 補充建議（若有） | 建議補充的安全驗收條件，由 PO 決定是否納入 Story AC 清單 |
| Security Review 觸發預判 | 明確說明 Story 完成後是否預期觸發 Security Review（是/否/條件觸發）|
