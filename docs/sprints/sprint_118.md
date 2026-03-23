# Sprint 118 — Sprint Execution 流程重構（責任下放 + 流程拆解 + Epic 防護）

**Sprint Goal**：解決 Sprint Execution 漏步驟的根因 — Code Review 責任下放至 subagent、Story Completion Checklist 拆解、Sprint Review epic 防護

**期間**：2026-03-23 ~ 2026-03-30
**Velocity 目標**：10 pts（Sprint 117: 10 pts）

## Sprint Backlog

| # | Story | Size | Points | MoSCoW | 狀態 |
|---|-------|------|--------|--------|------|
| #368-子2 | 責任下放：Code Review Loop 移至 Story-Lifecycle subagent | M | 3 | Must | 待開始 |
| #368-子3 | 流程拆解：Story Completion Checklist（5 步明確清單） | M | 3 | Must | 待開始 |
| #376 | fix: Sprint Review 不應自動 close epic Issue | S | 2 | Must | 待開始 |
| #374 | feat: Cruise 進度偵測 fallback 視窗可配置化 | S | 1 | Should | 待開始 |
| #375 | feat: OAuth Token Watchdog 過期通知閾值可配置化 | S | 1 | Should | 待開始 |

## 技術決策

- #368-子2+子3 同時修改 Sprint Execution SKILL.md，建議同一 subagent 打包實作
- #376 修改 Sprint Review SKILL.md 或 po-review-prompt.md
- #374 和 #375 為獨立配置修改，可平行

## Stakeholder 要求

使用者明確要求 #368 方向2+3 和 #376 必須選入本 Sprint。
