---
type: sprint-planning
sprint: 160
date: 2026-03-25
participants: [PO, Architect, QA]
velocity_baseline: 6pts
recommended_capacity: 7pts
sprint_goal: 強化框架品質防禦與開發者體驗
---

# Sprint 160 Planning — 2026-03-25

## Sprint Goal

強化框架品質防禦與開發者體驗 — 建立 QA 立場韌性機制、專案快速範本、Session Watchdog 心跳監控、Quality Observer MCP Phase 2 端點強化、Context Engineering JIT 載入策略、Quick Ship Pipeline 與 Schema-First 強制驗證工具

## Velocity Baseline

| Sprint | Velocity |
|--------|---------|
| Sprint 157 | 7 pts |
| Sprint 158 | 4 pts（小 Sprint）|
| Sprint 159 | 6 pts |
| **平均** | **6 pts** |
| **建議容量** | **6 pts（±20%: 4-7 pts）** |
| **本 Sprint 選取** | **7 pts**（在 ±20% 範圍內）|

## Stories Selected

| Story ID | 標題 | 估點 | AC 確認結果 | 獨立性評估 |
|----------|------|------|------------|-----------|
| US-#795 | feat: QA FREE-MAD 挑戰韌性 — 制衡立場不受多數壓力撤回機制 | 1 | APPROVED | 獨立（agents/qa-engineer.md）|
| US-#797 | feat: 專案範本 — init-project.sh 快速配置 Skills/Hooks/Script 標準化 | 1 | APPROVED | 獨立（templates/project-template/ + scripts/init-project.sh）|
| US-#793 | feat: Context Engineering JIT Skill 載入策略（減少 context 壓力）| 1 | APPROVED | 獨立（skills/sprint-execution/SKILL.md）|
| US-#802 | feat: Schema-First 強制工具 — API Contract 前置驗證腳本（ADR-036 落地）| 1 | APPROVED | 獨立（scripts/validate-schema-contracts.sh）|
| US-#798 | feat: Quick Ship Pipeline — 統一 lint/test/bump/commit/PR 單一指令交付 | 1 | APPROVED | 獨立（scripts/quick-ship.sh）|
| US-#794 | feat: Quality Observer MCP Phase 2 — metrics 端點強化（coverage/debt/health）| 1 | APPROVED | 獨立（mcp-servers/quality-observer/index.js）|
| US-#772 | feat: Session Watchdog — 存活監控心跳機制（無聲 hang 偵測）| 1 | APPROVED | 獨立（scripts/watchdog-check.sh）|

**Total: 7 pts**

## Risk Notes

- #793 修改 `skills/sprint-execution/SKILL.md` JIT loading 策略，需確認不破壞既有 SKILL injection 路徑（NFR1 已定義）
- #772 heartbeat 寫入格式需在 AC2 WATCHDOG-ALERT 輸出時對齊 cruise log 標準格式
- #798 quick-ship.sh pipeline 步驟失敗 exit code 規範需在 AC1 實作時明確定義

## Next Sprint Preview

留待下 Sprint 評估的 Backlog 項目（按 RICE 排序）：
- #776 Prompt Injection Defense（M size, 2pts, should）— 安全防護，本 Sprint 超載故留置
- #790 retro: worktree 自動清理整合驗證（S size, 1pt, could）— 持續關注 Sprint 161
- #800 TDAD Story 依賴圖（S size, 1pt, could）
- #799 Review Suggestions 追蹤台帳（S size, 1pt, could）

## 決議事項

1. Sprint 160 容量訂為 7 pts（+1 on baseline，在 ±20% 允許範圍 4-7 pts 內）
2. #776（M size，Prompt Injection Defense）因超載退回 Backlog，Sprint 161 評估
3. #790 retro-action 維持 priority: could，不強制升格（非 must）
4. 執行順序：Phase 1（#795, #797）→ Phase 2（#793, #802）→ Phase 3（#798, #794）→ Phase 4（#772）
5. 所有 7 Stories 均通過 Architect 技術評估與 QA 驗收，READY 進入 Execution

## Sprint Planning 完成時間

2026-03-25T20:31+08:00
