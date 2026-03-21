# Sprint 110

**Sprint Goal**：統一框架共用檔案的跨機器安全模式 — 所有 append-only log 改為 per-session + 結算
**日期**：2026-03-21
**容量**：5 points
**狀態**：進行中

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INFRA：框架共用檔案跨機器 conflict 修復 | #322 | L | 5 | 完成 |

## Acceptance Criteria

### #322 — 框架共用檔案跨機器 conflict 修復（L, 5pt）

> **Type**：INFRA
> **修改範圍**：6 個 append-only log 的寫入 Skill + 新增 6 個 settle 腳本 + PROJECT_BOARD.md / sprint_N.md push retry 機制 + 相關測試
> **Architect 備注**：沿用 #319 出勤紀錄 per-session + 結算模式，不需 ADR（既有模式擴展）

**AC-1：Shoot_Log.md 改為 per-session + 結算**
- shoot Skill 寫入改為 per-session 檔案（`docs/km/shoot-log/YYYY-MM-DD-session-<SESSION_ID>.md`）
- 新增 `hooks/shoot-log-settle.sh` 結算腳本
- 結算後產出 `docs/km/shoot-log/YYYY-MM-DD.summary.md`

**AC-2：sprint.live.log 改為 per-session + 結算**
- sprint-execution Skill 寫入改為 per-session 檔案（`docs/sprints/live-log/YYYY-MM-DD-session-<SESSION_ID>.log`）
- 新增 `hooks/live-log-settle.sh` 結算腳本
- 結算後產出 `docs/sprints/live-log/YYYY-MM-DD.summary.log`

**AC-3：Metrics_Log.md 改為 per-session + 結算**
- sprint-review Skill 寫入改為 per-session 檔案
- 新增 `hooks/metrics-settle.sh` 結算腳本

**AC-4：Retrospective_Log.md 改為 per-session + 結算**
- sprint-review Skill 寫入改為 per-session 檔案
- 新增 `hooks/retro-settle.sh` 結算腳本

**AC-5：quality-gate-decisions.md 改為 per-session + 結算**
- quality-gate Skill 寫入改為 per-session 檔案
- 新增 `hooks/quality-gate-settle.sh` 結算腳本

**AC-6：Tech_Debt_Registry.md 改為 per-session + 結算**
- story-lifecycle 寫入改為 per-session 檔案
- 新增 `hooks/tech-debt-settle.sh` 結算腳本

**AC-7：PROJECT_BOARD.md 加入 push retry 機制**
- 更新共用檔案時加入 `git pull --rebase` + retry 機制
- 最多重試 3 次，失敗時輸出明確錯誤訊息

**AC-8：sprint_N.md 同上**
- 同 AC-7，sprint_N.md 更新時加入 push retry 機制

**AC-9：所有修改的 Skill 文件更新指引**
- shoot / sprint-execution / sprint-review / quality-gate / story-lifecycle 的 SKILL.md 或 prompt 更新寫入路徑指引

**AC-10：測試覆蓋**
- 新增測試腳本驗證 per-session 寫入與結算正確性
- 測試 push retry 機制

## 技術評估摘要

### Architect 備注

- **沿用 #319 per-session + 結算模式** — 與出勤紀錄（attendance）和探索紀錄（exploration）同架構
- **不需 ADR** — 既有模式擴展，非新架構決策
- **優先序**：(1) Shoot_Log + sprint.live.log（最常觸發）→ (2) PROJECT_BOARD + sprint_N（push retry）→ (3) 其餘 log
- **push retry 機制**：`git pull --rebase` + 最多 3 次重試

### QA 備注

- **所有 AC 可驗證**
- AC1-AC6：檔案結構型 + 腳本存在型（沿用 #319 先例可對照）
- AC7-AC8：機制存在型（push retry 腳本/流程文件落地）
- AC9：文件修改型（diff 可驗）
- AC10：測試執行型（test script PASS）
- **DoR**：PASS
- **防漂移基準**：1 Story, 5 pts
