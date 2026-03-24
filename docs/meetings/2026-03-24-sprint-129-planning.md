# Sprint 129 Planning

- **日期**：2026-03-24
- **Sprint**：129
- **參與角色**：PO, Architect, QA, Developer

## Sprint Goal

落地 Sprint 128 Retro 四項行動改善（Issue 追蹤紀律、OOM 防護、重複派遣防護、Task name 格式），修復 CI OAuth token 失效並建立長期自動同步機制，同步完成 worktree 殘留清理功能。

## Backlog 選入（7 Stories, 7 pts）

| Story ID | 標題 | Type | Size | Priority |
|----------|------|------|------|----------|
| #534 | retro: Retro-Action Issue 追蹤紀律 | PROCESS | S(1) | must |
| #536 | retro: 平行 subagent OOM 防護 | PROCESS | S(1) | must |
| #537 | retro: 重複派遣防護 Gate | PROCESS | S(1) | must |
| #538 | retro: Task name 改用 repo/sprint-N 格式 | PROCESS | S(1) | must |
| #500 | feat: Worktree 自動清理 | FEATURE | S(1) | should |
| #524 | [SRE] CI failure: OAuth token 過期 | INFRA | S(1) | must |
| #539 | feat: GCE watchdog 自動同步 OAuth token | FEATURE | S(1) | must |

## Capacity

- Total: 7 pts (7S)
- Sprint 128 Velocity: 8 pts (100%)
- Baseline: 5-8 pts

## Execution Plan

### Phase 1a（可平行 — worktree）
- #534, #500

### Phase 1b（序列 — 同改 sprint-execution/SKILL.md）
- #536 -> #537 -> #538

### Phase 2（序列 — 人工部署）
- #524 -> #539

## Planning Rounds

### Round 1
- PO 初版 Backlog 選入 7 Stories
- Architect 提出平行分群建議與衝突分析
- QA 審查 #538 和 #524 的 AC，標記 NEEDS_REVISION

### Round 2
- PO 根據 QA 回饋修正 #538 和 #524 的 AC（已更新至 GitHub Issue）
- Story 清單不變（7 Stories, 7 pts），防漂移確認通過
- Architect 修正後的分群方案採用

## Risks

- #524 AC1/AC2 需人工執行，不作為 Sprint Done 阻塞條件
- Phase 1b 三個 Story 都改 sprint-execution/SKILL.md，必須序列避免衝突

## 決議

- Sprint 129 Planning 完成，進入 Execution
