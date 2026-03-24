# Sprint 129

## Sprint Goal
落地 Sprint 128 Retro 四項行動改善（Issue 追蹤紀律、OOM 防護、重複派遣防護、Task name 格式），修復 CI OAuth token 失效並建立長期自動同步機制，同步完成 worktree 殘留清理功能。

## Sprint Backlog

| Story ID | 標題 | Type | Size | Priority | Assignee | Phase |
|----------|------|------|------|----------|----------|-------|
| #534 | retro: Retro-Action Issue 追蹤紀律 | PROCESS | S(1) | must | Developer | Phase 1a |
| #500 | feat: Worktree 自動清理 — 殘留 worktree 偵測與回收機制 | FEATURE | S(1) | should | Developer | Phase 1a |
| #536 | retro: 平行 subagent OOM 防護（SHIKIGAMI_MAX_PARALLEL 上限規則） | PROCESS | S(1) | must | Developer | Phase 1b-1 |
| #537 | retro: 重複派遣防護 Gate（worktree 唯一性檢查） | PROCESS | S(1) | must | Developer | Phase 1b-2 |
| #538 | retro: Task name 改用 repo/sprint-N 格式取代 SESSION_ID | PROCESS | S(1) | must | Developer | Phase 1b-3 |
| #524 | [SRE] CI failure: OAuth token 過期 | INFRA | S(1) | must | Developer | Phase 2-1 |
| #539 | feat: GCE watchdog 自動同步 OAuth token | FEATURE | S(1) | must | Developer | Phase 2-2 |

## Capacity
- Total: 7 pts (7S)
- Sprint 128 Velocity: 8 pts (100%)
- Baseline: 5-8 pts

## Execution Plan

### Phase 1a（可平行 — worktree）
- #534 Retro-Action Issue 追蹤紀律
- #500 Worktree 自動清理

### Phase 1b（序列 — 同改 sprint-execution/SKILL.md）
1. #536 平行 subagent OOM 防護
2. #537 重複派遣防護 Gate
3. #538 Task name 格式改用 repo/sprint-N

### Phase 2（序列 — 人工部署）
1. #524 OAuth token 更新（需人工執行 AC1/AC2）
2. #539 GCE watchdog 自動同步（依賴 #524 完成）

## Risks
- #524 AC1/AC2 需人工執行（GCE/Anthropic Console），不作為 Sprint Done 阻塞條件
- Phase 1b 三個 Story 都改 sprint-execution/SKILL.md，必須序列避免衝突

## Sprint Duration
2026-03-24 ~ 2026-03-31
