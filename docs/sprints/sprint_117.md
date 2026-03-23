# Sprint 117 — 框架執行可靠性強化 + CI Token 自動化 + Cruise 智慧巡邏

**Sprint Goal**：強化框架執行可靠性（Hook 攔截擴充）、補齊 CI token 自動更新、提升 Cruise 智慧巡邏能力（閒置排入 + 進度追蹤）

**期間**：2026-03-23 ~ 2026-03-30
**Velocity 目標**：10 pts（Sprint 116: 10 pts）

## Sprint Backlog

| # | Story | Size | Points | MoSCoW | 狀態 |
|---|-------|------|--------|--------|------|
| #368-子1 | Hook 攔截擴充（Sprint Execution 關鍵動作攔截點） | M | 3 | Must | 完成 |
| #330 | feat: Claude OAuth Token Watchdog — 自動 refresh + 更新 GitHub Secret | M | 3 | Must | 完成 |
| #331-子2 | cruise: 閒置排入機制（idle 偵測 + 主動觸發 Sprint Planning） | S | 2 | Should | 完成 |
| #331-子3 | cruise: 背景 agent 進度追蹤（subagent 產出物偵測） | S | 2 | Should | 完成 |

## 技術決策（Architect）

- #330 需要 ADR-030（OAuth token 生命週期管理策略）
- 平行策略：Track A（#368-子1 Hook）/ Track B（#330 ADR+Watchdog）/ Track C（#331-子2+子3 Cruise）
- #331 兩個子 Story 同屬 cruise/SKILL.md，建議同一 subagent 實作避免 merge conflict
- #331-子3 需要 claim 鎖保護（多 session 競態）

## Sprint 117 Review 結果

**Review 日期**：2026-03-23
**版本**：v0.80.0
**Sprint Goal 達成**：是

| # | Story | PR | 驗收 | 備注 |
|---|-------|----|------|------|
| #368-子1 | Hook 攔截擴充（BRANCH-GATE + PUSH-MAIN-GATE） | #371 | PASS | hooks.json 新增 2 個 prompt hook，覆蓋 git checkout -b / git push origin main 攔截 |
| #330 | Claude OAuth Token Watchdog — SessionStart 過期偵測+告警 | #372 | PASS | oauth-token-watchdog.sh 落地、ADR-030 決策記錄、SessionStart 靜默掛載 |
| #331-子2+子3 | cruise 閒置偵測 + 背景 agent 進度追蹤 | #373 | PASS | Step 6 閒置偵測（low/medium/high matrix）+ git log 進度偵測 + subagent 產出物偵測 |

## Sprint 117 統計

- Velocity：10 pts（目標 10，達成率 100%）
- 完成率：100%（3/3 Stories PASS）
- Sprint 外 Shoots（本 session）：#333, #335

## 未選入

| # | 標題 | 原因 |
|---|------|------|
| #368-方向2 | 責任下放 | Story-Lifecycle subagent 前置條件未滿足 |
| #368-方向3 | 流程拆解 | 中期架構工作，需獨立 Sprint |
| #331-子1 | Architect 定期巡檢 | RICE 最低，需新 agent 行為設計 |
| #342 | 研究報告 | 已完成，建議 close |
| #271 | 競品分析 | 已完成，後續 action 另開 Issue |
