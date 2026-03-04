# Project Board

**最後更新**：2026-05-11（Sprint 38 Planning 完成）
**當前 Sprint**：Sprint 38（進行中）

工件導覽：[ROADMAP](prd/ROADMAP.md) → [Backlog](prd/PRODUCT_BACKLOG.md) → [Sprint 38](sprints/sprint_38.md) → 本看板 | [Tutorial](tutorial/README.md)

---

## Sprint 38 — 進行中

**Sprint Goal**：解封 M4 GitHub Actions 整合主線（ADR-011 起草）、交付 Decision Knowledge Base 初版，並回應 Stakeholder 對 PO 審查積壓量可視化的需求。
**期間**：2026-05-11 ~ 2026-05-17

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-81：ADR-011 起草 — GitHub Actions 整合架構決策 | S | 1 | 完成 |
| US-11：Decision Knowledge Base — ADR 查詢與決策影響追蹤 | M | 2 | 完成 |
| US-82：PO 審查積壓量可視化 — backlog-management 新增待審 Issues 計數與老齡警示 | S | 1 | 完成 |

**目標 Velocity**：4 points（3 Stories）

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

## Sprint 35 — 完成

**Sprint Goal**：ADR-010 原子性實作交付 — Backlog Source of Truth 從 PRODUCT_BACKLOG.md 遷移至 GitHub Issues，完成三個 SKILL.md 改寫 + DEPRECATED 標頭 + Label 基礎設施
**結果**：Goal 達成（5/5 Stories PASS）。Velocity 8 points，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-04-20 ~ 2026-04-26

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-69：ADR-010 Label 基礎設施 — 建立所有 ADR-010 定義 labels 並更新 onboarding Pre-flight | S | 1 | 完成 |
| US-70：`backlog-intake` SKILL.md 重大改寫 — 移除 PRODUCT_BACKLOG.md 寫入，改為 Issue label + body template 兩層架構 | M | 2 | 完成 |
| US-71：`sprint-planning` SKILL.md 修改 — PO Story 選取來源改為 `gh issue list` + 即時 MoSCoW/RICE 排序計算 | M | 2 | 完成 |
| US-72：`backlog-management` SKILL.md 修改 — Grooming 流程改為操作 GitHub Issues，加入 Pre-flight 錯誤恢復掃描 | M | 2 | 完成 |
| US-73：PRODUCT_BACKLOG.md DEPRECATED 標頭加入 + ADR-009 格式契約決策域「Superseded by ADR-010」標注 | S | 1 | 完成 |

**目標 Velocity**：8 points（5 Stories）
**實際 Velocity**：8 points（5 Stories）

---

## Sprint 34 — 完成

**Sprint Goal**：Issue #46 自動化排程框架收尾結案 + Issue #49 CI 失敗根因修正
**結果**：Goal 達成（2/2 Stories PASS）。Velocity 2 points，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-04-13 ~ 2026-04-19

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-66：Issue #46 最終收尾 — 四條排程流程驗收條件逐項確認、缺口補齊，close Issue #46 | S | 1 | 完成 |
| US-68：Issue #49 框架端主動修正評估 — workflow check 失敗根因分析（根因已確認：Sprint 33 commit 順序問題，非框架 bug） | S | 1 | 完成 |

**目標 Velocity**：2 points（2 Stories）
**實際 Velocity**：2 points（2 Stories）

---

## Sprint 33 — 完成

**Sprint Goal**：以 Issue #46 第四條流程「需求入庫自動化」為核心交付，同步啟動 M5 外部使用者觸及的主動推廣行動與 Backlog 精化
**結果**：Goal 達成（3/3 Stories PASS）。Velocity 4 points，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-04-06 ~ 2026-04-12

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-63：Issue #46 子 Story #4 — 需求入庫自動化（PO Backlog Intake cron + shikigami:backlog-intake Skill） | M | 2 | 完成 |
| US-64：M5 條件 (a) 主動觸及強化 — 外部社群推廣文案製作（GitHub README badges + 技術文章草稿 + 主動 outreach 指引） | S | 1 | 完成 |
| US-65：US-T08（Intent Routing 測試）評估重開 — RICE 重新評分與 Sprint Planning 可行性確認 | S | 1 | 完成 |

**目標 Velocity**：4 points（3 Stories）
**實際 Velocity**：4 points（3 Stories）

---

## 短衝記錄

| 日期 | 標題 | Issue/Story | commit hash |
|------|------|-------------|-------------|
| 2026-04-27 | 改善 sprint-N-replied label 機制為單一可重用 sprint-replied label | #66 | 7ce9c12 |
| 2026-04-27 | US-14 Notification Templates — PR/Deploy/Review 事件通知模板 | #63 | be133a5 |

---

> 歷史 Sprint 記錄：[PROJECT_BOARD_ARCHIVE](km/archive/PROJECT_BOARD_ARCHIVE.md)（Sprint 1–32）
