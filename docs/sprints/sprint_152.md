# Sprint 152

- **Sprint Goal**: 修復品質缺口並補充 Backlog 動能 — 修復 #704 Issue body 截斷、補充 sprint-candidate >= 8、完成 Doctor cruise 定期觸發整合
- **期間**: 2026-03-25 ~ 2026-03-31
- **容量**: 6 / 6 pts

## Stories

| # | Story | Points | Status | Assignee |
|---|-------|--------|--------|----------|
| 1 | #707 retro: 修復 #704 Issue body 截斷問題（AC/NFR 內容遺失） | 1 | DONE(closed) | — |
| 2 | #706 retro: Sprint 151 PO Backlog Discovery — 補充 sprint-candidate 至 >= 8 | 3 | TODO | — |
| 3 | #704 retro: /shikigami:doctor cruise 定期觸發整合（AC6 補完） | 2 | TODO | — |

## 執行順序

- #707 先行（修復 #704 body，使 AC 完整可驗收）
- #706 與 #707 可平行執行（Discovery 工作獨立）
- #704 依賴 #707 完成後再執行（需要完整 AC 作為開發依據）

## Architect 技術評估

| Story | T-shirt | ADR 需求 | API 契約 | Related SDDs | ADR-039 Risk |
|-------|---------|---------|---------|-------------|-------------|
| US-#707 | S | 無需 ADR | 不適用 | — | 4（haiku） |
| US-#706 | M | 無需 ADR | 不適用 | — | 6（haiku） |
| US-#704 | S | 無需 ADR | 不適用 | — | 6（haiku） |

## QA 驗收確認

| Story | AC 確認 | 路徑驗證 | SDD 引用 | 結果 |
|-------|--------|---------|---------|------|
| US-#707 | PASS | N/A | — | PASS |
| US-#706 | PASS | N/A | — | PASS |
| US-#704 | PASS（條件：#707 先完成修復 body） | PASS（startup-flow.md 存在） | — | PASS |

## Notes

- Sprint 151 velocity = 2 pts（backlog 耗盡），Sprint 150 = 4 pts，Sprint 149 = 4 pts → 平均 3.3 pts，建議容量 5-6 pts
- #703 已結案：被 #706 完全涵蓋（superseded）
- #707 → #704 依賴鏈：#707 修復 body 截斷後，#704 方有完整 AC 可執行
- #706（Discovery）執行完畢後 sprint-candidate 應恢復至 >= 8，解決連續耗盡問題
