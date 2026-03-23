# Sprint 119 — 品質防線鞏固

**Sprint Goal**：ADR-032 + CRITICAL 互動確認 + Review 分層 + Discovery Checklist + Worktree 驗證
**期間**：2026-03-23 ~ 2026-03-30
**Velocity 目標**：10 pts（Sprint 118: 10 pts）

## Sprint Backlog

| # | Story | Size | Points | MoSCoW | 狀態 |
|---|-------|------|--------|--------|------|
| #391 | adr: ADR-032 交付路徑分層（/commit vs /shoot vs /sprint-execution） | M | 3 | Must | 完成 |
| #387 | feat: CRITICAL issue 互動式確認（AskUserQuestion pattern） | S | 2 | Must | 完成 |
| #390 | feat: Discovery Phase Per-Item Checklist — 防止後續 item 跳步 | S | 2 | Must | 完成 |
| #384 | feat: Review 建議清單分層（MUST FIX vs SUGGESTION） | S | 2 | Should | 完成 |
| #382 | retro: 驗證 worktree 隔離機制在實際 Sprint 執行中生效 | S | 1 | Must | 完成 |

## 技術決策

- #391 撰寫 ADR-032，記錄三條交付路徑的判斷規則
- #387 修改 quality-gate SKILL.md，加入 project_level 分層 + AskUserQuestion pattern
- #390 修改 Discovery SKILL.md，加入 per-item checklist 強制驗核
- #384 修改 code-review-prompt，明確 MUST FIX / SUGGESTION 分層輸出
- #382 新增 tests/test-worktree-isolation.sh 驗證 AC-1~4

## Sprint 119 Review 結果

**驗收日期**：2026-03-23
**Velocity**：10 pts（目標 10，達成率 100%）
**完成率**：100%（完成 5 / 計畫 5）
**Sprint Goal 達成**：是

### AC 驗收摘要

| Story | PR | AC | 結果 |
|-------|----|----|------|
| #391 ADR-032 交付路徑分層 | #414 | ADR-032 文件建立，三條路徑判斷規則明確 | PASS |
| #387 CRITICAL 互動確認 | #416 | quality-gate project_level 分層，medium/high 使用 AskUserQuestion | PASS |
| #390 Discovery Per-Item Checklist | #418 | Discovery SKILL.md 加入 per-item checklist，防跳步 | PASS |
| #384 Review 建議清單分層 | #419 | code-review 輸出 MUST FIX / SUGGESTION 分層 | PASS |
| #382 worktree 隔離驗證 | #417 | test-worktree-isolation.sh 建立，AC-1~4 驗證腳本完成 | PASS |

### Issue 狀態回寫

- #391：已 close + done label（PR #414 merged）
- #387：已 close + done label（PR #416 merged）
- #390：已 close + done label（PR #418 merged）
- #384：已 close + done label（PR #419 merged）
- #382：已 close + done label（PR #417 merged）
