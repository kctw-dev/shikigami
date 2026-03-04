# Project Board

**最後更新**：2026-03-04（Sprint 41 US-86 完成 — 交付物文案一致性審查機制）
**當前 Sprint**：Sprint 41（進行中）

工件導覽：[ROADMAP](prd/ROADMAP.md) → [Backlog](prd/PRODUCT_BACKLOG.md) → [Sprint 41](sprints/sprint_41.md) → 本看板 | [Tutorial](tutorial/README.md)

---

## Sprint 41 — 進行中

**Sprint Goal**：M4 收尾與文件一致性強化 — 更新 ROADMAP M4 完成狀態、TD-002 技術債結案、建立交付物文案一致性審查機制回應 Sprint 38-40 連續 Retro Problem。
**期間**：2026-03-04 ~ 2026-03-10

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-84：M4 里程碑正式收尾 — ROADMAP US-14 完成標注 + M4 結案評估 | S | 1 | 完成 |
| US-85：TD-002 技術債結案 + Schema 文案修正 | S | 1 | 進行中 |
| US-86：交付物文案一致性審查機制 — 回應 Sprint 38-40 連續 Retro Problem | M | 2 | 完成 |
| US-87：GitHub Action 自動觸發 backlog-intake — Issue labeled 事件驅動入庫 | S | 1 | 完成 |

**目標 Velocity**：5 points（4 Stories）

---

## Sprint 40 — 完成

**Sprint Goal**：完成 M4 度量層 — US-13 DORA Metrics 交付，並清償 TD-002 技術債，讓工程效能可量化、PO subagent 輸出結構可驗證。
**結果**：Goal 達成（2/2 Stories PASS）。Velocity 5 points，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-05-25 ~ 2026-05-31

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-13：DORA Metrics — 部署頻率、變更前置時間、MTTR、變更失敗率追蹤 | L | 3 | 完成 |
| TD-002：PO subagent 輸出格式 JSON Schema 正式驗證 | M | 2 | 完成 |

**目標 Velocity**：5 points（2 Stories）
**實際 Velocity**：5 points（2 Stories）

---

## Sprint 39 — 完成

**Sprint Goal**：正式裁決 ADR-011（Proposed → Accepted），交付 M4 GitHub Actions 整合首個可執行 Story（US-12 CI/CD 狀態感知），讓外部工具鏈與 Shikigami Sprint 週期正式整合。
**結果**：Goal 達成（2/2 Stories PASS）。Velocity 3 points，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-05-18 ~ 2026-05-24

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-83：ADR-011 正式裁決 — GitHub Actions 整合架構決策 Proposed → Accepted | S | 1 | 完成 |
| US-12：GitHub Actions 整合 — CI/CD 狀態感知與 Sprint Health Check 整合 | M | 2 | 完成 |

**目標 Velocity**：3 points（2 Stories）
**實際 Velocity**：3 points（2 Stories）

---

## Sprint 38 — 完成

**Sprint Goal**：解封 M4 GitHub Actions 整合主線（ADR-011 起草）、交付 Decision Knowledge Base 初版，並回應 Stakeholder 對 PO 審查積壓量可視化的需求。
**結果**：Goal 達成（3/3 Stories PASS）。Velocity 4 points，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-05-11 ~ 2026-05-17

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-81：ADR-011 起草 — GitHub Actions 整合架構決策 | S | 1 | 完成 |
| US-11：Decision Knowledge Base — ADR 查詢與決策影響追蹤 | M | 2 | 完成 |
| US-82：PO 審查積壓量可視化 — backlog-management 新增待審 Issues 計數與老齡警示 | S | 1 | 完成 |

**目標 Velocity**：4 points（3 Stories）
**實際 Velocity**：4 points（3 Stories）

---

## Sprint 37 — 完成

**Sprint Goal**：完成 backlog-intake 單層 Issue 架構改造（#73/#72 合併交付）與 shoot US-XX ADR-010 適配，讓 Backlog 管理全工具鏈達到單層一致性與 PO 審查閉環。
**結果**：Goal 達成（3/3 Stories PASS）。Velocity 4 points，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-05-04 ~ 2026-05-10

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-77：單層 Issue 架構改造 — backlog-intake / backlog-management 棄用兩層 Issue，改為 blockquote 保留原始內容 | M | 2 | 完成 |
| US-78：shoot skill US-XX 模式需適配 ADR-010 — 從 GitHub Issues 查詢 Story | S | 1 | 完成 |
| US-80：backlog-intake PO Review Gate — AI 自動入庫後新增 PO 審查階段與 label 語意修正 | S | 1 | 完成 |

**目標 Velocity**：4 points（3 Stories）
**實際 Velocity**：4 points（3 Stories）

---

## Sprint 36 — 完成

**Sprint Goal**：完成 ADR-010 生命週期閉環 — 補全 sprint-review Issue 狀態回寫、初始化 GitHub Issues Backlog，讓 Backlog Source of Truth 遷移進入「全流程可用」狀態
**結果**：Goal 達成（3/3 Stories PASS）。Velocity 4 points，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-04-27 ~ 2026-05-03

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-74：ADR-010 後置 — sprint-review SKILL.md Story 完成後 Issue 狀態回寫對齊 | S | 1 | 完成 |
| US-75：ADR-010 Backlog 初始化 — 將現有候選 Stories 建立為 GitHub Issues | M | 2 | 完成 |
| US-76：Tech Debt Grooming Sprint 36 — TD-002 評估 + ADR-010 遷移後新技術債掃描 | S | 1 | 完成 |

**目標 Velocity**：4 points（3 Stories）
**實際 Velocity**：4 points（3 Stories）

---

## 短衝記錄

| 日期 | 標題 | Issue/Story | commit hash |
|------|------|-------------|-------------|
| 2026-04-27 | 改善 sprint-N-replied label 機制為單一可重用 sprint-replied label | #66 | 7ce9c12 |
| 2026-04-27 | US-14 Notification Templates — PR/Deploy/Review 事件通知模板 | #63 | be133a5 |

---

> 歷史 Sprint 記錄：[PROJECT_BOARD_ARCHIVE](km/archive/PROJECT_BOARD_ARCHIVE.md)（Sprint 1–35）
