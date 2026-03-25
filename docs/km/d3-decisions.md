# D3 Debate Protocol — 決策記錄

D3（Design Disagreement Debate）是 Sprint Planning 中 Architect 與 QA 意見分歧時的結構化辯論機制。
本文件記錄所有 D3 辯論的過程與最終決策，作為架構決策的歷史參考。

## 格式說明

每筆記錄包含以下欄位：

| 欄位 | 說明 |
|------|------|
| **Date** | 辯論日期（YYYY-MM-DD） |
| **Sprint** | Sprint 編號 |
| **Story** | Story 編號與標題 |
| **Advocate Position** | Round 1：Architect 提出的技術方案立場 |
| **Challenge** | Round 2：QA 提出的挑戰與疑慮 |
| **Rebuttal** | Round 3：Architect 考量成本後的回應（Cost-aware rebuttal） |
| **Judge Rationale** | SM 裁決理由 |
| **Final Decision** | 最終決策結果 |

## 決策記錄

| Date | Sprint | Story | Advocate Position | Challenge | Rebuttal | Judge Rationale | Final Decision |
|------|--------|-------|-------------------|-----------|----------|-----------------|----------------|
| *(範例 Example)* | Sprint N | #000 Story Title | Architect 建議採用方案 A，理由：效能較佳、符合現有架構 | QA 質疑：方案 A 測試覆蓋難度高，邊界條件複雜，建議改用方案 B | Architect 回應：考量實作成本，同意部分採用方案 B 的測試策略，維持核心架構不變 | SM 裁決：Architect 的 Cost-aware 回應已充分考量 QA 疑慮，方案 A 為最終決定 | 採用方案 A，並採納 QA 建議的測試策略 |

---

> 說明：本文件由 Sprint Planning 流程自動寫入，手動修改需經 SM 確認。
> 觸發條件：Architect 與 QA 對同一 Story 的技術方案產生分歧時觸發 D3 流程。
