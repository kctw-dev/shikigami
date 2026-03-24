# SDD 變更連鎖校準（ADR-020）

當 ADR 觸發 SDD 更新時，Architect 必須執行以下連鎖校準。若專案尚無 SDD（`docs/sdd/SDD-000-architecture.md` 不存在），連鎖校準不適用。

1. **列出受影響 Story**：檢查 Sprint 文件（`docs/sprints/sprint_N.md`）中各 Story 的 `related_sdds` 欄位，識別引用了被修改 SDD 章節的 Story
2. **AC 重新校準**：與 PO 確認受影響 Story 的 AC 是否需要更新（SDD 約束變更可能使既有 AC 過時或不完整）
3. **記錄校準結果**：在 Sprint 文件中記錄哪些 Story AC 被校準、校準原因
4. **重新進入 TDD**：若受影響 Story 已開始實作，需從 TDD Red 階段重新開始（基於新 AC 重寫失敗測試）

**輸出格式**：

```
[SDD-CASCADE] ADR-XXX 觸發 SDD-YYY 更新
  受影響 Story：{story_id_list}
  校準結果：
    - {story_id}: AC 已更新 / AC 無需更新 / 待 PO 確認
  TDD 重置：
    - {story_id}: 從 Red 階段重新開始 / 尚未開始實作（不影響）
```

**失敗處理**：若無法確定受影響範圍（Sprint 文件缺失或 `related_sdds` 欄位不完整），輸出 `[SDD-CASCADE-INCOMPLETE]` 並 ESCALATE 至主 session。主 session 收到後：(a) 暫停所有尚未開始實作的當前 Sprint Story，已開始實作的 Story 暫不影響直到手動列舉完成；(b) 請 Architect 手動列出可能受影響的 Story；(c) 完成手動列舉後重新執行連鎖校準，若列舉結果包含已開始實作的 Story，依正常連鎖校準規則從 Red 階段重新開始
