# Systematic Debugging 觸發指引（§7 / CI FAIL / Deploy 後 / Bug 修復後）

<!-- US-247 Sprint 90 — Deploy 後與 Bug 修復後 systematic debugging 觸發指引 -->
<!-- v0.64.1 patch — 新增 CI FAIL 觸發點 -->

Sprint Execution 流程中，以下時機建議觸發 systematic debugging，確認系統健康並防止回歸。

以下時機均為**建議，非強制**，觸發方式統一為 `invoke shikigami:systematic-debugging`（附上觸發目的與相關資訊）。

| 時機 | 觸發條件 | 目的 | 可省略條件 |
|------|---------|------|-----------|
| **7.0 CI FAIL** | §3 CI 快掃或 §8.2 CI Gate 回傳 FAIL | 根因排查（環境、依賴、隱性回歸） | CI 失敗原因明確（lint/型別錯誤等） |
| **7.1 Deploy 後** | `deployment-readiness` 完成、部署至生產環境後 | Post-deploy health check | 緊急修復可延後至 Sprint Review 前（Sprint Review 前為 HARD-GATE） |
| **7.2 Bug 修復後** | Bug 修復通過 Review 後、下一 Story 前 | 回歸確認 | Bug 範圍小且有明確測試覆蓋 |
