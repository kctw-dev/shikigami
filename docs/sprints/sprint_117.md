# Sprint 117 — 框架執行可靠性強化 + CI Token 自動化 + Cruise 智慧巡邏

**Sprint Goal**：強化框架執行可靠性（Hook 攔截擴充）、補齊 CI token 自動更新、提升 Cruise 智慧巡邏能力（閒置排入 + 進度追蹤）

**期間**：2026-03-23 ~ 2026-03-30
**Velocity 目標**：10 pts（Sprint 116: 10 pts）

## Sprint Backlog

| # | Story | Size | Points | MoSCoW | 狀態 |
|---|-------|------|--------|--------|------|
| #368-子1 | Hook 攔截擴充（Sprint Execution 關鍵動作攔截點） | M | 3 | Must | 待開始 |
| #330 | feat: Claude OAuth Token Watchdog — 自動 refresh + 更新 GitHub Secret | M | 3 | Must | 待開始 |
| #331-子2 | cruise: 閒置排入機制（idle 偵測 + 主動觸發 Sprint Planning） | S | 2 | Should | 待開始 |
| #331-子3 | cruise: 背景 agent 進度追蹤（subagent 產出物偵測） | S | 2 | Should | 待開始 |

## 技術決策（Architect）

- #330 需要 ADR-030（OAuth token 生命週期管理策略）
- 平行策略：Track A（#368-子1 Hook）/ Track B（#330 ADR+Watchdog）/ Track C（#331-子2+子3 Cruise）
- #331 兩個子 Story 同屬 cruise/SKILL.md，建議同一 subagent 實作避免 merge conflict
- #331-子3 需要 claim 鎖保護（多 session 競態）

## 未選入

| # | 標題 | 原因 |
|---|------|------|
| #368-方向2 | 責任下放 | Story-Lifecycle subagent 前置條件未滿足 |
| #368-方向3 | 流程拆解 | 中期架構工作，需獨立 Sprint |
| #331-子1 | Architect 定期巡檢 | RICE 最低，需新 agent 行為設計 |
| #342 | 研究報告 | 已完成，建議 close |
| #271 | 競品分析 | 已完成，後續 action 另開 Issue |
