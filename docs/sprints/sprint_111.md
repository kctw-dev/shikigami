# Sprint 111

**Sprint Goal**：落地 Cruise Mode Phase 1 — PO 巡邏 + SRE 巡檢自動巡航
**日期**：2026-03-21
**容量**：5 points
**狀態**：進行中

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| FEATURE：Cruise Mode Phase 1 — PO 巡邏 + SRE 巡檢自動巡航 | #321 | L | 5 | 進行中 |

## Acceptance Criteria

### #321 — Cruise Mode Phase 1（L, 5pt）

> **Type**：FEATURE
> **修改範圍**：新增 cruise Skill（SKILL.md + command）、cruise log 目錄、flag file 機制、protect-main.sh 更新、相關測試
> **Architect 備注**：需 ADR-026（Session 內 loop + flag file stop + PO/SRE 平行派遣）

**AC-1：PO 巡邏**
- 掃描 open issues（`gh issue list`）
- 留言追蹤（逾期、無回應 Issue 標記）
- 交付追蹤（in-sprint Story 進度確認）
- 巡邏結果寫入 cruise log

**AC-2：SRE 巡檢**
- CI/CD 狀態檢查（`gh run list`）
- Runner 健康檢查
- Warnings 掃描
- 發現問題時建 Issue（不修）
- 巡檢結果寫入 cruise log

**AC-4：介面**
- `/cruise` — 啟動巡航（預設間隔）
- `/cruise 10m` — 指定間隔啟動
- `/cruise stop` — 停止巡航
- 實作方式：Session 內 loop（sleep + flag file）
- stop：刪除 flag file + SessionEnd hook 清理

**AC-5：跨機器安全**
- per-session cruise log（`docs/cruise-logs/YYYY-MM-DD-session-<SESSION_ID>.md`）
- Issue 重複防護（`gh issue list --search` 檢查已存在 Issue）
- protect-main.sh 加入 `^docs/cruise-logs/` 白名單

**AC-6：測試**
- 新增測試腳本驗證 cruise 機制
- flag file 建立/刪除驗證
- cruise log 寫入驗證

## 技術評估摘要

### Architect 備注

- **ADR-026**：Session 內 loop + flag file stop（Sprint 內第一步完成）
- **PO + SRE 平行派遣**：兩個巡邏角色同時執行
- **per-session cruise log**：`docs/cruise-logs/` 目錄
- **Issue 重複防護**：`gh issue list --search` 避免重複建 Issue
- **不需 CronCreate**：Session 內 loop 即可

### QA 備注

- **所有 AC 可驗證**
- AC-1：行為型（cruise log 輸出可驗 PO 巡邏行為）
- AC-2：行為型（cruise log + Issue 建立可驗 SRE 巡檢行為）
- AC-4：介面型（CLI 操作可驗 /cruise、/cruise 10m、/cruise stop）
- AC-5：結構型（檔案結構 + gh issue list --search 機制可驗）
- AC-6：測試執行型（test script PASS）
- **DoR**：PASS
- **防漂移基準**：1 Story, 5 pts
