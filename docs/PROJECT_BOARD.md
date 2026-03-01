# Project Board

**最後更新**：2026-03-08
**當前 Sprint**：Sprint 5（進行中）

工件導覽：[ROADMAP](prd/ROADMAP.md) → [Backlog](prd/PRODUCT_BACKLOG.md) → [Sprint 5](sprints/sprint_5.md) → 本看板

---

## Sprint 5 — 進行中

**Sprint Goal**：完成 v0.3.0 Tech Debt Registry，並同步建立 ADR-002 解鎖測試框架擴展路徑
**週期**：2026-03-08 ~ 2026-03-15

| Story | Size | Points | 狀態 | 備注 |
|-------|------|--------|------|------|
| ADR-002：測試框架技術選型 | S | 1 | 完成 | 純 Bash + 共享函式庫 |
| US-10：Tech Debt Registry | M | 2 | 進行中 | 與 ADR-002 並行 |
| US-T01：Skill 完整性驗證 | S | 1 | 待開始 | Hard Gate：等待 ADR-002 |
| US-FIX-01：修復審計發現 | M | 2 | 完成 | 5 commits, 13 項修復 |

**計畫 Velocity**：6 points（4 Stories）

---

## Sprint 4 — 完成

**Sprint Goal**：啟動 v0.3.0 知識沉澱，以 US-08 Sprint Metrics 完成 v0.2.0 收尾，並建立 Retrospective Analytics 的第一層能力
**結果**：Goal 達成（3/3 Stories PASS）。Velocity 4 points，完成率 100%。
**Stakeholder 驗收**：接受

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-08：Sprint Metrics（Velocity 追蹤與趨勢分析） | S | 1 | 完成 |
| US-09：Retrospective Analytics（問題趨勢分析） | M | 2 | 完成 |
| US-T06：Command 路由驗證 | S | 1 | 完成 |

**實際 Velocity**：4 points（3 Stories）

---

## Sprint 3 — 完成

**Sprint Goal**：完成 v0.2.0 自我感知，並修復跨兩個 Sprint 的行為性缺陷
**結果**：Goal 達成（4/4 Stories PASS）。Velocity 5 points，完成率 100%。
**Stakeholder 驗收**：接受，v0.2.0 Release 批准

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| Story 1（Retro #3）：Sprint Review 自動觸發重修 | S | 1 | 完成 |
| US-06：Onboarding（專案初始化） | M | 2 | 完成 |
| Story 3（Retro #2）：Health Check 自動掛鉤 | S | 1 | 完成 |
| US-T04：版號一致性驗證 | S | 1 | 完成 |

**實際 Velocity**：5 points（4 Stories）

---

## Sprint 2 — 完成

**Sprint Goal**：讓框架能感知自己的狀態

| Story | Size | 狀態 |
|-------|------|------|
| US-07：Health Check Skill | M | 完成 |
| US-S01：Standup 遠端差距感知 | S | 完成 |
| Retro #2：不阻塞原則強化 | S | 完成 |
| Retro #3：Plan Mode 互斥說明 | S | 完成 |

---

## 歷史交付

### Sprint 1（v0.1.0 核心框架）
- [x] Story 5：專案等級自治策略
- [x] Story 1：Issue Lifecycle Management
- [x] ADR-001：Backlog Bridge 編排模式
- [x] Story 2：Backlog Bridge 完整版
- [x] Story 3：Issue Comment 強化
- [x] Story 4：Issue Triage 強化 + triage-prompt.md
