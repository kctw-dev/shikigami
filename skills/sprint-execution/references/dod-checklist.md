# DoD 自檢 + Checkpoint 檢查項（§6）

## 6. DoD 自檢

每個 Story 完成前，Developer 必須逐項檢查 Definition of Done。DoD 條件定義請參照 `skills/scrum-master/SKILL.md` §8，以下為執行時 checkbox 格式：

| 層次 | 自檢 |
|------|------|
| 功能：所有 Acceptance Criteria 通過 | [ ] |
| 測試：單元測試 + 整合測試全部通過（0 failed） | [ ] |
| 安全：外部輸入通過安全驗證與去活化處理 | [ ] |
| 文件：設計文件對應章節已更新，代碼含設計文件引用 | [ ] |
| 設定：無硬編碼金鑰，配置透過環境變數管理 | [ ] |
| 度量：Metrics_Log.md 本 Sprint 數據已更新 | [ ] |
| 反回歸：既有測試全部仍然通過 | [ ] |
| 技術債：取捷徑情況已用 `[TECH-DEBT]` 標記並更新 Tech_Debt_Registry.md | [ ] |

## 6.1 執行流程 Checkpoint 檢查項

<!-- US-229 Checkpoint 強制重讀步驟 — Sprint 83 -->

每個 Story-Lifecycle subagent 回傳 PASS 後，主 session 必須完成以下 Checkpoint 相關檢查：

- [ ] **每個 Story-Lifecycle subagent 回傳後，Checkpoint 重讀步驟已執行**：已依 §3.1 三個子動作，重讀 `skills/sprint-execution/SKILL.md` §3 流程定義、比對下一步驟一致性，並輸出 Checkpoint 標記。
- [ ] **Checkpoint 結果已記錄（PASS 或 FAIL + 處置）**：已輸出 `[CHECKPOINT-PASS]` 或 `[CHECKPOINT-FAIL]` 標記（格式見 §3.1.2）；若為 FAIL，已依 §3.1.1 執行對應失敗處置方案並記錄處置結果。
