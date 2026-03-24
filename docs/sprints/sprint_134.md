# Sprint 134

## Sprint Goal
落地 Sprint 133 Retro Action Items（並行 worktree 穩定性 + Sprint Planning AC 品質 + git tag 自動化）+ 啟動安全框架升級（Prompt Injection Defense Gate + Parallel Conflict Prediction），為多組並行作業奠定可觀測性基礎。

## Sprint Backlog

| Story ID | 標題 | Type | Size | Priority | Assignee | Phase | 狀態 |
|----------|------|------|------|----------|----------|-------|------|
| #573 | retro: Sprint Planning AC 指定明確檔案路徑 | RETRO | S(1) | should | Developer | Batch 1 | DONE(#592) |
| #581 | retro: Sprint 133 — 並行 worktree 版本衝突預防機制 | RETRO | S(1) | should | Developer | Batch 1 | DONE(#593) |
| #574 | retro: Sprint Review 後補打 git tag | RETRO | S(1) | should | Developer | Batch 2 | DONE(#594) |
| #393 | feat: Prompt Injection Defense — Security Gate 擴充 | FEATURE | M(2) | should | Developer | Batch 2 | DONE(#595) |
| #395 | feat: Parallel Conflict Prediction — 平行任務衝突預測 | FEATURE | M(2) | should | Developer | Batch 3 | DONE(#596) |

## Capacity
- Total: 7 pts (3S + 2M)
- Sprint 133 Velocity: 6 pts (100%)
- Sprint 132 Velocity: 6 pts (100%)
- Sprint 131 Velocity: 6 pts (100%)
- Baseline: 6-7 pts（3 Sprint 平均 6 pts ± 1）
- 連續 100%: 第 7 Sprint（127+128+129+130+131+132+133）

## Execution Plan

### Batch 1（可平行，SHIKIGAMI_MAX_PARALLEL=2）
- #573 retro: Sprint Planning AC 指定明確檔案路徑（S, 1pt）
  - 修改檔案：`skills/sprint-planning/references/po-prompt.md`
- #581 retro: 並行 worktree 版本衝突預防機制（S, 1pt）
  - 修改檔案：`skills/sprint-execution/story-lifecycle-prompt.md`

### Batch 2（可平行，SHIKIGAMI_MAX_PARALLEL=2）
- #574 retro: Sprint Review 後補打 git tag（S, 1pt）
  - 修改檔案：`skills/sprint-review/SKILL.md`
- #393 feat: Prompt Injection Defense — Security Gate 擴充（M, 2pt）
  - 修改檔案：`docs/adr/ADR-006-prompt-injection-protection.md`（擴充章節）、新建 `docs/definition/SECURITY_RULES.md`、新建 `tests/test-security-gate.sh`、修改 Security agent flow

### Batch 3（序列）
- #395 feat: Parallel Conflict Prediction — 平行任務衝突預測（M, 2pt）
  - 修改檔案：`skills/sprint-execution/SKILL.md`（dispatch flow）、相關 SDD 文件

## Architect 技術評估

| Story | T-shirt | ADR 需求 | API 契約 | Related SDDs | 說明 |
|-------|---------|---------|---------|-------------|------|
| #573 | S | 無需 ADR | 不適用 | — | doc-only 行為修正，改 po-prompt.md |
| #581 | S | 無需 ADR | 不適用 | — | 修改 story-lifecycle-prompt.md，加 rebase 步驟 |
| #574 | S | 無需 ADR | 不適用 | — | 修改 sprint-review/SKILL.md，加 git tag 步驟 |
| #393 | M | ADR-006 擴充（已 Accepted，補充 Security Gate 章節）| 不適用 | ADR-006 | 新增 Security Gate 呼叫 + SECURITY_RULES.md + tests |
| #395 | M | ADR-033 依賴（已 Accepted），無需新 ADR | 不適用 | ADR-033 | dispatch flow 加靜態衝突分析，輸出 dispatch plan |

## QA 驗收確認

| Story | AC 確認結果 | 測試策略 |
|-------|------------|---------|
| #573 | PASS — AC1/AC2 可測 | 下一 Sprint Planning 驗證 Developer Story AC 格式 |
| #581 | PASS — AC1 可測（文件更新），AC2 觀察性（下 Sprint）| review story-lifecycle-prompt.md diff |
| #574 | PASS — AC1/AC2 可自動驗證 | `validate-version.sh` + `git tag -l` 腳本驗證 |
| #393 | PASS — AC1-5 全部明確且可測 | `tests/test-security-gate.sh` 自動測試 |
| #395 | PASS — AC1-5 明確，AC2 dispatch plan 可 review | sprint execution live-log 查驗 |

## 平行分群建議

> **上限控制**：SHIKIGAMI_MAX_PARALLEL=2，Batch 1/2 各 2 個 Story，Batch 3 序列

| 批次 | Stories | 模式 | 衝突分析 |
|------|---------|------|---------|
| Batch 1 | #573 \| #581 | 平行 | 無衝突（不同目錄）|
| Batch 2 | #574 \| #393 | 平行 | 無衝突（不同目錄）|
| Batch 3 | #395 | 序列 | 修改 sprint-execution/SKILL.md，Batch 2 完成後再開始 |
