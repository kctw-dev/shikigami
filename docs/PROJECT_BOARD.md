# Project Board

**最後更新**：2026-04-27（Sprint 36 Review 完成）
**當前 Sprint**：Sprint 36（完成）

工件導覽：[ROADMAP](prd/ROADMAP.md) → [Backlog](prd/PRODUCT_BACKLOG.md) → [Sprint 36](sprints/sprint_36.md) → 本看板 | [Tutorial](tutorial/README.md)

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

## Sprint 32 — 完成

**Sprint Goal**：完成 Issue #46 自動化排程框架的程式碼入庫 QA 閉環（子 Story #3），同步推進 M5 條件 (a) 外部使用者觸及強化與 Issue #35 Token Baseline 精確化，使排程 Sprint 週期具備端對端自動化能力
**結果**：Goal 達成（3/3 Stories PASS）。Velocity 4 points，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-03-30 ~ 2026-04-05

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-60：Issue #46 子 Story #3 — 排程衝刺程式碼入庫 QA 自動化（schedule SKILL.md + scrum-master/sprint-review SKILL.md） | M | 2 | 完成 |
| US-61：M5 條件 (a) 外部使用者觸及強化 — Onboarding 低摩擦路徑最佳化（README + tutorial + M5 追蹤更新） | S | 1 | 完成 |
| US-62：Issue #35 — Token 追蹤 Baseline Snapshot 機制（Metrics_Log.md + sprint-planning/execution SKILL.md） | S | 1 | 完成 |

**目標 Velocity**：4 points（3 Stories）
**實際 Velocity**：4 points（3 Stories）

---

> 歷史 Sprint 記錄：[PROJECT_BOARD_ARCHIVE](km/archive/PROJECT_BOARD_ARCHIVE.md)（Sprint 1–31）
