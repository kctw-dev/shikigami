---
type: sprint-planning
sprint: 180
date: "2026-04-09"
start_time: "2026-04-09T11:00+08:00"
end_time: "2026-04-09T11:08+08:00"
participants:
  - role: PO
    rounds: [1, 2]
  - role: Architect
  - role: QA
---

# Sprint 180 Planning 會議紀錄

## Sprint Goal

> 將 ADR-045 short-lived subagent 從 PoC 模擬升級為 sprint-execution task-list-init 步驟的真實整合，同步補完 Sprint 179 Retro Action Items 的可觀測性與文件缺口

## Velocity Baseline

| Sprint | Velocity |
|--------|----------|
| Sprint 177 | 6 pts |
| Sprint 178 | 6 pts |
| Sprint 179 | 6 pts |
| **平均** | **6 pts** |
| **建議容量** | **5-7 pts** |
| **本 Sprint 選取** | **6 pts** |

## Stories Selected

| Story | Issue | Points | AC 確認 | 說明 |
|-------|-------|--------|---------|------|
| retro: sprint-execution 整合 short-lived subagent — ADR-045 落地第一步 | #983 | 3 | PASS（Sprint 180 修訂版 AC） | M-L Story，ADR-045 落地第一步，sonnet 路由（Score 9, FEAT） |
| retro: backlog 水位趨勢腳本整合至自動化報告 | #982 | 1 | PASS | S Story，Sprint 179 Retro action，haiku 路由（Score 5, FEAT） |
| retro: 建立 hooks 架構說明文件 — hook-runner.sh 使用時機指南 | #984 | 1 | PASS | S Story，Sprint 179 Retro action，haiku 路由（Score 4, DOC） |
| retro: TDD 外部工具模擬最佳實踐指南 — fake binary vs PATH 清空陷阱 | #953 | 1 | PASS | S Story，Sprint 176 Retro action A，haiku 路由（Score 4, DOC） |

**總計**：4 Stories / 6 pts

## 修訂版 AC 確認（#983）

Sprint 180 Planning 期間由 PO/Architect/QA 共同敲定 #983 的修訂版 AC，已同步寫入 GitHub Issue body：

- **AC-1**：選定 `task-list-init` 作為第一個整合步驟（與 PoC 直接延續，最小步距）
- **AC-2**：新增 `rule-ratio-measure.sh` 規則佔比測量腳本（零依賴，token 估算用字元數）
- **AC-3**：軟性觀察指標作為 trending 數據記錄，非 DoD blocker
- **AC-4**：新建 `skills/sprint-execution/references/step-subagent-contract.md` 契約文件

## Risk Notes

- **#983 M-L Story 佔 50% 容量**：單一 Story 3 pts，若 task-list-init 整合遇阻礙影響大 → 緩解：Scope Buffer 允許規則佔比量測腳本降級 v0（手動跑），自動化整合排 Sprint 181
- **#983 coordinator-only 檔案獨占**：修改 `skills/sprint-execution/SKILL.md`、`scripts/state-machine/*`，與其他 Story 平行會衝突 → 緩解：排入 Wave 1 獨占執行
- **#983 軟性指標無 PASS/FAIL**：AC-3 僅作為觀察記錄 → 緩解：AC-1/AC-2/AC-4 為可立即驗證的交付物，DoD 以這三項為準
- **#982 / #984 / #953 皆為文件與腳本級異動**：風險極低，haiku 路由充分

## 平行分群

> **SHIKIGAMI_MAX_PARALLEL=2**

- **Wave 1（獨占）**：#983 (sonnet) — coordinator-only 檔案獨占
- **Wave 2（2 worktrees 平行）**：#982 (haiku) + #984 (haiku)
- **Wave 3**：#953 (haiku)

## 決議事項

1. Sprint 180 選入 4 Stories / 6 pts，與 Round 1 清單完全一致（防漂移約束通過）
2. #983 路由至 sonnet（Score 9, FEAT），其餘 3 Stories 路由至 haiku
3. #983 採用 Sprint 180 修訂版 AC（task-list-init 範圍、rule-ratio 測量、軟性指標、契約文件）
4. 平行分群：3 Waves，Wave 1 #983 獨占避免 coordinator-only 檔案衝突
5. Sprint Goal 聚焦 ADR-045 落地第一步，同步清理 Sprint 179 Retro 遺留行動項目
