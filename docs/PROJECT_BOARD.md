# Project Board

**最後更新**：2026-03-02（Sprint 22 Planning Round 2 — US-33、US-37、US-38、US-39 選入 Sprint 22）
**當前 Sprint**：Sprint 22（進行中）

工件導覽：[ROADMAP](prd/ROADMAP.md) → [Backlog](prd/PRODUCT_BACKLOG.md) → [Sprint 22](sprints/sprint_22.md) → 本看板 | [Tutorial](tutorial/README.md)

---

## Sprint 22 — 進行中

**Sprint Goal**：強化框架安全性與排程智能化
**期間**：2026-03-16 ~ 2026-03-22

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-33（Issue #33）：Onboarding 缺少 BACKLOG_DONE.md 模板 | S | 1 | 待辦 |
| US-37（Issue #55）：防範 Issue 提示注入攻擊 | S | 1 | 待辦 |
| US-38（Issue #51）：排程模式下 Velocity 自動調小 — 僅選 S size Stories | S | 1 | 待辦 |
| US-39（Issue #45）：Sprint Execution context overflow — Story 生命週期封裝為 subagent | L | 3 | 待辦 |

**Sprint 容量**：6 Points（4 Stories）

---

## Sprint 21 — 完成

**Sprint Goal**：清零 Sprint 20 Retro Action Item（#58）+ parallel-dispatch 衝突偵測（US-32）+ Onboarding Labels 補完（US-34）
**結果**：Goal 達成（3/3 Stories PASS）。Velocity 4 points，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-03-09 ~ 2026-03-15

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| Retro #58（Issue #58）：L-size Story QA checklist 強化 — SKILL.md 新增大型 Story 審查增強項 | S | 1 | 完成 |
| US-32（Issue #40）：parallel-dispatch 應內建同檔案衝突偵測與自動序列化 | M | 2 | 完成 |
| US-34（Issue #32）：Onboarding 應預建常用 GitHub Labels | S | 1 | 完成 |

**實際 Velocity**：4 points（3 Stories）

---

## Sprint 20 — 完成

**Sprint Goal**：清零 Sprint 19 Retro Action Items（#56、#57），交付 /shoot 短衝模式（US-31）
**結果**：Goal 達成（3/3 Stories PASS）。Velocity 5 points，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-03-02 ~ 2026-03-08

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| Retro #56（Issue #56）：修復 test-schedule.sh assert_contains SIGPIPE 非確定性失敗 | S | 1 | 完成 |
| Retro #57（Issue #57）：Developer subagent 狀態更新衝突防護 | S | 1 | 完成 |
| US-31（Issue #47）：/shoot 短衝模式 | L | 3 | 完成 |

**實際 Velocity**：5 points（3 Stories）

---

## Sprint 19 — 完成

**Sprint Goal**：Schedule Skill 品質鞏固 — 修補安全缺陷，實現序列排程保護，補完 PO 跨輪次一致性機制
**結果**：Goal 達成（4/4 Stories PASS）。Velocity 5 points，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-03-02 ~ 2026-03-08

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| Retro #53（Issue #53）：schedule skill — skill name 字元白名單驗證 | S | 1 | 完成 |
| Retro #54（Issue #54）：schedule skill — 模板品質強化（set -euo pipefail + 備份安全） | S | 1 | 完成 |
| US-30（Issue #48）：PO subagent 多輪派遣時 Story 內容偏離修正機制 | S | 1 | 完成 |
| US-36（Issue #50）：Planning + Execution 序列排程 — 避免平行衝突 | M | 2 | 完成 |

**實際 Velocity**：5 points（4 Stories）

---

## Sprint 18 — 完成

**Sprint Goal**：建立 Schedule Skill — 實現 Sprint 自動排程執行能力
**結果**：Goal 達成（1/1 Stories PASS）。Velocity 3 points，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-03-02 ~ 2026-03-08

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-35（Issue #46）：Sprint 排程執行 + 權限 bypass 機制（shikigami:schedule） | L | 3 | 完成 |

**實際 Velocity**：3 points（1 Story）

---

## Sprint 17 — 完成

**Sprint Goal**：檔案瘦身優先 — 建立 PROJECT_BOARD 與 Retrospective_Log 歷史歸檔機制（US-29），清零 Sprint 16 Retro Action Items（Retro #41 Token 記錄指引 cache tokens 修正、Retro #42 OpenCode POC 佔位候選入 Backlog），確保效能可觀測性與知識管理基礎就緒。
**結果**：Goal 達成（3/3 Stories PASS）。Velocity 4 points，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-03-02 ~ 2026-03-08

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| Retro #41：Token 記錄指引更新 — 三個 SKILL.md 納入 cache tokens 加總計算 | S | 1 | 完成 |
| Retro #42：OpenCode POC 可行性調查佔位入 Backlog | S | 1 | 完成 |
| US-29（Issue #44）：PROJECT_BOARD.md 與 Retrospective_Log.md 歷史歸檔機制 | M | 2 | 完成 |

**實際 Velocity**：4 points（3 Stories）

---

> 歷史 Sprint 記錄：[PROJECT_BOARD_ARCHIVE](km/archive/PROJECT_BOARD_ARCHIVE.md)（Sprint 1–16）
