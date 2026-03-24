# Sprint 132

## Sprint Goal
鞏固 Sprint Planning 品質 + 強化 Developer TDD 精準執行，落地 Sprint 131 Retro Action Items，並完成 TDAD 依賴分析工具選型 ADR。

## Sprint Backlog

| Story ID | 標題 | Type | Size | Priority | Assignee | Phase |
|----------|------|------|------|----------|----------|-------|
| #563 | retro: Story AC 完整性前置確認 — PO Round 1 必須提供完整 AC | RETRO | S(1) | must | Developer | Batch 1 ✓ PR#568 |
| #567 | ADR RESEARCH: TDAD 依賴分析工具選型（Python AST vs TypeScript madge） | RESEARCH | S(1) | should | Developer | Batch 1 ✓ PR#569 |
| #564 | retro: Sprint Candidate RICE Score 補充 — 24 個待排 Story 缺乏優先級量化 | RETRO | M(2) | should | Developer | Batch 2 ✓ PR#570 |
| #394 | feat: TDAD Dependency Map — 精準 TDD 執行 | FEATURE | M(2) | should | Developer | Batch 2 ✓ PR#571 |

## Capacity
- Total: 6 pts (2M + 2S)
- Sprint 131 Velocity: 6 pts (100%)
- Sprint 130 Velocity: 5 pts (100%)
- Sprint 129 Velocity: 7 pts (100%)
- Baseline: 5-7 pts（3 Sprint 平均 6 pts ± 1）
- 連續 100%: 第 5 Sprint（127+128+129+130+131）

## Execution Plan

### Batch 1（可平行，SHIKIGAMI_MAX_PARALLEL=2）
- #563 retro: Story AC 完整性前置確認（S, 1pt）
  - 修改 `skills/sprint-planning/references/po-prompt.md`
  - PO Round 1 輸出規則加入 AC 完整性硬性 Gate（每個 Story 至少 1 條 AC 草稿）
  - 完成後 patch version bump
- #567 ADR RESEARCH: TDAD 依賴分析工具選型（S, 1pt）
  - 評估 Python（pydeps, ast-grep）vs TypeScript（madge, tsc-references）
  - 時間盒：1-2 天
  - 產出 `docs/adr/ADR-035-tdad-dependency-analysis.md`（Accepted 狀態）
  - 解除 #394 Hard Gate

### Batch 2（Batch 1 完成後，可平行）
- #564 retro: Sprint Candidate RICE Score 補充（M, 2pt）
  - 建立 `docs/km/rice-scoring-standard.md`（或整合至現有 SOP）
  - 為前 10 個高頻 sprint-candidate 補充 RICE Score
  - 更新 `skills/sprint-planning/references/po-prompt.md` 引用 RICE Score 排序
  - Note: 依賴 #563 完成確保 po-prompt.md 無並行寫入衝突
- #394 feat: TDAD Dependency Map（M, 2pt）（依賴 #567 ADR Accepted）
  - 修改 `skills/developer/SKILL.md`，插入 Pre-TDD Dependency Analysis 步驟
  - 支援 Python 與 TypeScript（依 ADR-035 決策）
  - 完成後 patch version bump
  - 通過 validate-version.sh + test-sprint-execution.sh

## Risks
- #394 依賴 #567 ADR 結論，若 ADR 時間盒超出，#394 需退出本 Sprint
- #563 與 #564 均修改 po-prompt.md，Batch 2 的 #564 必須在 Batch 1 的 #563 完成後執行（避免寫入衝突）
- Sprint 131 Retro Action Items（#563/#564）直接影響下 Sprint 品質，優先確保交付

## Sprint Review 結果

**Sprint Review 日期**：2026-03-24
**驗收結果**：4/4 PASS
**Velocity**：6 pts
**完成率**：100%
**連續 100%**：第 6 Sprint（127+128+129+130+131+132）

| Story | 驗收結果 | PR | 備注 |
|-------|---------|-----|------|
| #563 retro: Story AC 完整性前置確認 | PASS | #568 | AC Gate 硬性規則已插入 po-prompt.md |
| #567 ADR RESEARCH: TDAD 依賴分析工具選型 | PASS | #569 | ADR-035 Accepted，#394 Hard Gate 解除 |
| #564 retro: Sprint Candidate RICE Score 補充 | PASS | #570 | rice-scoring-standard.md 建立，前 10 個 RICE 補充完成 |
| #394 feat: TDAD Dependency Map — 精準 TDD 執行 | PASS | #571 | developer-prompt.md 已插入 Pre-TDD 步驟，v0.89.2 |
