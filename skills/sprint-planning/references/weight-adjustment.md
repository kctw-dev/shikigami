# 角色權重調整檢查（US-22 / ADR-004）

**觸發時機**：健康檢查完成後、PO 第一輪開始前 *(慢想模式限定)*。

**執行步驟**：

1. 讀取 `docs/km/Retrospective_Log.md`
2. 少於 3 個 Sprint 記錄 → 輸出「歷史資料不足」→ 寫入 sprint_N.md → 結束
3. 提取最近 2 個已完成 Sprint 的 `### Problem` 區塊，比對 QA 關鍵字清單：

```yaml
qa_keywords: ["QA", "審查", "Review", "Code Quality", "Spec Compliance", "雙階段", "品質"]
```

**觸發後調整規則**：

| 條件 | 調整 |
|------|------|
| 連續 2 Sprint 有 QA 相關 Problem | QA Review 升為 Hard Gate（Must） |
| 連續 2 Sprint 無 QA 相關 Problem（升級中） | QA Review 恢復為 Should |
| 連續 2 Sprint 無任何 Problem | Bypass 門檻從 S 放寬至 M |

結果（無論調整與否）持久化至 `docs/sprints/sprint_N.md`「## 權重調整記錄」區塊。

關鍵字清單更新時機：Sprint Review Retrospective 環節，SQA 識別漏判 → 提議新關鍵字 → Architect 確認。
