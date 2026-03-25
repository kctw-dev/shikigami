# Sprint 156

- **Sprint Goal**: 強化框架自動化觀測與工具鏈品質 — 整合 retro-action 自動升格、PR 描述模板、SRE hooks 健康監控、Backlog 健康趨勢報告、cruise logs 搜尋工具，補強 Architect 衝突預防與 bash arithmetic 慣例
- **期間**: 2026-03-25 ~ 2026-03-31
- **容量**: 7 pts

## Stories

| # | Story | Issue | Points | Status | Assignee |
|---|-------|-------|--------|--------|----------|
| 1 | feat: retro-action 高優先級自動升格 sprint-candidate（Sprint Planning 整合） | #739 | 1 | DONE(#753) | Developer |
| 2 | feat: GitHub PR 描述模板標準化（story-lifecycle PR 品質一致） | #741 | 1 | DONE(#754) | Developer |
| 3 | feat: validate-hooks.sh 整合 cruise SRE patrol（持續健康監控） | #740 | 1 | DONE(#755) | Developer |
| 4 | feat: Backlog 健康趨勢報告腳本（backlog-health-report.sh） | #736 | 1 | DONE(#755) | Developer |
| 5 | feat: cruise logs 搜尋查詢腳本（跨 session 診斷） | #731 | 1 | DONE(#756) | Developer |
| 6 | retro: Architect 批次分組新增共同修改檔案衝突預防標注 | #752 | 1 | DONE(#756) | Developer |
| 7 | retro: Developer prompt 新增 bash arithmetic increment 慣例警示（set -e 相容） | #751 | 1 | DONE(#757) | Developer |

**Total: 7 pts**

## 技術評估（Architect）

| Story | T-shirt | ADR 需求 | API 契約 | Related SDDs | 說明 |
|-------|---------|---------|---------|-------------|------|
| #739 | S | 無需 ADR | 不適用 | — | 修改 po-prompt.md + sprint-planning SKILL.md，掃描 retro-action + priority:must labels |
| #741 | S | 無需 ADR | 不適用 | — | 新建 .github/pull_request_template.md + story-lifecycle-prompt.md 修改引用 |
| #740 | S | 無需 ADR | 不適用 | — | 修改 skills/cruise/references/sre-patrol.md，新增 validate-hooks.sh 執行步驟 |
| #736 | S | 無需 ADR | 不適用 | — | 新建 scripts/backlog-health-report.sh，整合至 cruise PO patrol |
| #731 | S | 無需 ADR | 不適用 | — | 新建 scripts/search-cruise-logs.sh，純 bash+jq，跨平台 |
| #752 | S | 無需 ADR | 不適用 | — | 修改 architect-prompt.md Parallel Grouping 段落補充「同檔案衝突預防」規則 |
| #751 | S | 無需 ADR | 不適用 | — | 修改 story-lifecycle-prompt.md NFR 章節 + Developer Story template |

**ADR Hard Gate**: 全部通過（無技術選型 Story）

## 執行順序（Parallel Grouping）

> SHIKIGAMI_MAX_PARALLEL 未設定，預設視為 2（CLAUDE.md §12）。

**Batch 1（同時執行）**：
- #739（1pt, S）— po-prompt.md 自動升格邏輯
- #741（1pt, S）— .github/pull_request_template.md 新建

**Batch 2（Batch 1 完成後執行）**：
- #740（1pt, S）— sre-patrol.md validate-hooks 整合
- #736（1pt, S）— scripts/backlog-health-report.sh 新建

**Batch 3（Batch 2 完成後執行）**：
- #731（1pt, S）— scripts/search-cruise-logs.sh 新建
- #752（1pt, S）— architect-prompt.md 衝突預防標注

**Batch 4（Batch 3 完成後執行）**：
- #751（1pt, S）— story-lifecycle-prompt.md bash arithmetic 警示

> 衝突預防注意：#741 與 #751 均涉及 story-lifecycle-prompt.md，已排入不同 Batch 避免衝突。

## QA 驗收確認

全部 7 個 Story AC 完整性確認 PASS，隱性需求已覆蓋（NFR 明確定義）。DoR/DoD 檢查通過。

## Model Routing（ADR-039）

| Story | Tier | Score | Model |
|-------|------|-------|-------|
| #739 | 2 | 6 | sonnet |
| #741 | 2 | 5 | sonnet |
| #740 | 2 | 5 | sonnet |
| #736 | 2 | 5 | sonnet |
| #731 | 2 | 5 | sonnet |
| #752 | 1 | 4 | haiku |
| #751 | 1 | 4 | haiku |
