# Sprint 155

- **Sprint Goal**: 強化框架自動化工具鏈 — 新增 worktree 清理與容量計算腳本、強化 Claim/Release 容錯與 Story-Lifecycle 結果暫存、校準容量估算方法論、補強 ADR 衝突預偵測
- **期間**: 2026-03-25 ~ 2026-03-31
- **容量**: 6 pts

## Stories

| # | Story | Issue | Points | Status | Assignee |
|---|-------|-------|--------|--------|----------|
| 1 | feat: Story-Lifecycle subagent 結果暫存強化（CACHE-RECOVERY 防失敗） | #737 | 1 | TODO | Developer |
| 2 | feat: git worktree 自動清理腳本（Sprint 完成後防 OOM） | #735 | 1 | TODO | Developer |
| 3 | feat: Sprint 容量自動計算腳本（基於 3-Sprint Velocity 平均） | #734 | 1 | TODO | Developer |
| 4 | retro: Sprint 153 容量估算校準 — 識別隱性工作 | #719 | 1 | TODO | Developer |
| 5 | retro: Sprint Planning 新增 ADR 編號衝突預偵測機制 | #730 | 1 | TODO | Developer |
| 6 | feat: Claim/Release 機制降級容錯強化（git remote 失敗處理） | #733 | 1 | TODO | Developer |

**Total: 6 pts**

## 技術評估（Architect）

| Story | T-shirt | ADR 需求 | API 契約 | Related SDDs | 說明 |
|-------|---------|---------|---------|-------------|------|
| #737 | S | 無需 ADR | 不適用 | — | story-lifecycle-prompt.md + subagent-results/ 目錄寫入 |
| #735 | S | 無需 ADR | 不適用 | — | 新建 scripts/cleanup-worktrees.sh |
| #734 | S | 無需 ADR | 不適用 | — | 新建 scripts/calculate-sprint-capacity.sh，讀取 metrics-log |
| #719 | S | 無需 ADR | 不適用 | — | RESEARCH type：分析 cruise logs 識別隱性工作 |
| #730 | S | 無需 ADR | 不適用 | — | 修改 architect-prompt.md + 新建測試腳本 |
| #733 | S | 無需 ADR | 不適用 | — | 修改 hooks/claim-issue.sh + hooks/release-issue.sh |

**ADR Hard Gate**: 全部通過（無技術選型 Story）

## 執行順序（Parallel Grouping）

> SHIKIGAMI_MAX_PARALLEL 未設定，預設視為 2（CLAUDE.md §12）。

**Batch 1（同時執行）**：
- #737（1pt, S）— story-lifecycle-prompt.md 暫存強化
- #735（1pt, S）— scripts/cleanup-worktrees.sh 新建

**Batch 2（Batch 1 完成後執行）**：
- #734（1pt, S）— scripts/calculate-sprint-capacity.sh 新建
- #730（1pt, S）— architect-prompt.md ADR 衝突預偵測

**Batch 3（Batch 2 完成後執行）**：
- #719（1pt, S）— RESEARCH：cruise logs 分析
- #733（1pt, S）— hooks/claim-issue.sh + release-issue.sh 容錯

## QA 驗收確認

全部 6 個 Story AC 完整性確認 PASS，隱性需求已覆蓋。DoR/DoD 檢查通過。

## Model Routing（ADR-039）

| Story | Tier | Score | Model |
|-------|------|-------|-------|
| #737 | 2 | 7 | sonnet |
| #735 | 2 | 7 | sonnet |
| #734 | 2 | 7 | sonnet |
| #719 | 1 | 5 | haiku（RESEARCH 唯讀分析） |
| #730 | 2 | 7 | sonnet |
| #733 | 2 | 8 | sonnet |
