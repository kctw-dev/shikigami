# Sprint 118 — Sprint Execution 流程重構（責任下放 + 流程拆解 + Epic 防護）

**Sprint Goal**：解決 Sprint Execution 漏步驟的根因 — Code Review 責任下放至 subagent、Story Completion Checklist 拆解、Sprint Review epic 防護

**期間**：2026-03-23 ~ 2026-03-30
**Velocity 目標**：10 pts（Sprint 117: 10 pts）

## Sprint Backlog

| # | Story | Size | Points | MoSCoW | 狀態 |
|---|-------|------|--------|--------|------|
| #368-子2 | 責任下放：Code Review Loop 移至 Story-Lifecycle subagent | M | 3 | Must | 完成 |
| #368-子3 | 流程拆解：Story Completion Checklist（5 步明確清單） | M | 3 | Must | 完成 |
| #376 | fix: Sprint Review 不應自動 close epic Issue | S | 2 | Must | 完成 |
| #374 | feat: Cruise 進度偵測 fallback 視窗可配置化 | S | 1 | Should | 完成 |
| #375 | feat: OAuth Token Watchdog 過期通知閾值可配置化 | S | 1 | Should | 完成 |

## 技術決策

- #368-子2+子3 同時修改 Sprint Execution SKILL.md，建議同一 subagent 打包實作
- #376 修改 Sprint Review SKILL.md 或 po-review-prompt.md
- #374 和 #375 為獨立配置修改，可平行

## Stakeholder 要求

使用者明確要求 #368 方向2+3 和 #376 必須選入本 Sprint。

## Sprint 外快速交付（Shoots）

| Issue | 描述 | PR |
|-------|------|-----|
| #379 | feat: Sprint Execution 平行 subagent 使用 git worktree 隔離 | #380 |

## Sprint 118 Review 結果

**驗收日期**：2026-03-23
**Velocity**：10 pts（目標 10，達成率 100%）
**完成率**：100%（完成 5 / 計畫 5）
**Sprint Goal 達成**：是

### AC 驗收摘要

| Story | PR | AC | 結果 |
|-------|----|----|------|
| #368-子2+子3 | #377 | Code Review Loop 責任下放 + 5 步 Checklist | PASS |
| #376 | #378 | Epic Issue 防護（title 含 epic: → 不 close） | PASS |
| #374 | #378 | Cruise fallback 視窗可配置化（shikigami.local.md） | PASS |
| #375 | #378 | OAuth warn_threshold_hours 可配置化 | PASS |

### Issue 狀態回寫（§2.6）

- #376/#374/#375：外部 Issue — 加 done label，移除 in-sprint，階段 1 留言（保持 Open）
- #368：Epic 防護生效 — 加 done label，移除 in-sprint，留言記錄（不 close）
