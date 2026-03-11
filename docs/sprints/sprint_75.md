# Sprint 75

**Sprint Goal**：強化交付品質閉環 — CI/CD 通知不遺漏 + E2E 結果納入流程判定 + Issue 回覆如實反映驗證狀態
**期間**：2026-03-11 ~ 2026-03-18
**ADR 依賴**：無

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-200：Issue 回覆溝通策略改善 — 分階段通知避免誤認已交付 | #197 | S | 1 | 完成 |
| US-198：CI/CD 失敗通知強化 — 多節點 CI 檢查與升級策略 | #195 | M | 2 | 完成 |
| US-199：E2E 測試與 CI/CD 管線整合 — deployment-readiness E2E Gate 升級 | #196 | M | 2 | 待開發 |

**總計**：5 points（2M + 1S）

**權重調整記錄**：歷史趨勢穩定（Sprint 72-74 完成率均 100%），無需調整。

**Architect 平行分群建議**：
- 全序列執行：US-200 (S) → US-198 (M) → US-199 (M)
- 原因：三者共用 sprint-review/SKILL.md，需序列避免衝突

**Architect 方法論適用性評估摘要**：
- US-198（CI/CD 通知強化）：建議 BDD（B1, B3），CI 狀態三值語意多執行路徑
- US-199（E2E 管線整合）：建議 BDD（B1, B2），E2E 結果對版本 Tag 影響決策
- US-200（Issue 回覆改善）：不適用，措辭模板修改

---

## 各 Story 詳情

### US-200：Issue 回覆溝通策略改善 — 分階段通知避免誤認已交付

**Issue**：#197
**MoSCoW**：Must
**Size**：S（1pt）
**doc-only**：YES

**User Story**：As a 外部 Issue 提交者，I want Issue 回覆明確區分「內部審查完成」vs「端對端驗證完成」，so that 我不會在功能尚未完整驗證時誤以為已修復。

**Acceptance Criteria**：

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | §2.6 外部 Issue 回覆改為階段 1 通知 | `skills/sprint-review/SKILL.md` §2.6 外部 Issue 留言改為：「Sprint N Review 驗收通過（PASS）。程式碼已完成內部審查，待部署驗證後正式交付。」 |
| AC2 | 新增階段 2 回覆流程 | `skills/sprint-review/SKILL.md` §2.6 新增階段 2：部署驗證通過後對外部 Issue 留言：「已通過端對端驗證，功能已正式交付。請測試確認後關閉此 Issue。」 |
| AC3 | §7 Checklist 同步更新 | `skills/sprint-review/SKILL.md` §7 外部 Issue PASS checkbox 拆為兩階段：(a) 階段 1 留言已發送；(b) 階段 2 留言已發送 |

**Done 定義**：
- [x] AC1-AC3 全部通過
- [x] QA Review PASS

---

### US-198：CI/CD 失敗通知強化 — 多節點 CI 檢查與升級策略

**Issue**：#195
**MoSCoW**：Must
**Size**：M（2pt）
**doc-only**：YES

**User Story**：As a Developer，I want CI/CD 失敗能在多個流程節點被感知（standup、Sprint Review、Story 開發前），so that 我不會因為只在 Sprint 開始時檢查一次而遺漏 CI 失敗。

**Acceptance Criteria**：

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | standup 新增 CI 狀態掃描 | `shikigami:standup` skill（區塊一或區塊二）新增 CI 狀態掃描，執行 `gh run list --limit 3`，CI FAIL 時輸出 `[CI-ALERT]` 含 workflow 名稱與 run URL |
| AC2 | Sprint Review 一致性審查新增 CI 確認 | `skills/sprint-review/SKILL.md` §1.5 審查 Checklist 新增「CI 最新 run 狀態為 PASS」項目 |
| AC3 | Story 開發前 CI 檢查升級為 Soft Gate | `skills/sprint-execution/SKILL.md` §3 步驟 1 CI FAIL 時改為 Soft Gate：輸出 `[CI-SOFT-GATE]` 並要求確認是否繼續 |
| AC4 | CI 連續 FAIL 升級閾值 | `skills/sprint-execution/SKILL.md` 新增：同一 workflow 連續 3 次 FAIL 升級為 Hard Gate，阻塞 Story 開發 |

**Done 定義**：
- [x] AC1-AC4 全部通過
- [x] QA Review PASS

---

### US-199：E2E 測試與 CI/CD 管線整合 — deployment-readiness E2E Gate 升級

**Issue**：#196
**MoSCoW**：Must
**Size**：M（2pt）
**doc-only**：YES

**User Story**：As a Developer，I want E2E 測試結果納入交付流程判定，so that 版本發布前有端對端驗證保障，不會在未經 E2E 驗證的情況下發布版本。

**Acceptance Criteria**：

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | L3 E2E 從「可選」升級為 Soft Gate | `skills/deployment-readiness/SKILL.md` §5.2 標題改為「L3 E2E 端對端驗證步驟（Soft Gate）」；E2E 失敗輸出 `[E2E-SOFT-GATE]`，需 PO 確認後方可繼續 |
| AC2 | Sprint Review 新增 E2E 驗證結果確認 | `skills/sprint-review/SKILL.md` §7 Checklist 新增「E2E 驗證結果已確認」項目 |
| AC3 | E2E 驗證結果判斷表更新 | `skills/deployment-readiness/SKILL.md` §5.2「測試失敗」行更新：輸出 `[E2E-SOFT-GATE]`，記錄失敗原因，需 PO 確認 |

**Done 定義**：
- [ ] AC1-AC3 全部通過
- [ ] QA Review PASS
