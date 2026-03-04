# Project Board

**最後更新**：2026-03-04（Sprint 44 Planning 完成）
**當前 Sprint**：Sprint 44（進行中）

工件導覽：[ROADMAP](prd/ROADMAP.md) → [Backlog](prd/PRODUCT_BACKLOG.md) → [Sprint 44](sprints/sprint_44.md) → 本看板 | [Tutorial](tutorial/README.md)

---

## Sprint 44 — 進行中

**Sprint Goal**：建立 API Key Rotation 架構基礎 — 起草 ADR-012，確認 ToS 合規性與 Key pool 設計方案，為 Sprint 45 US-A 實作提供可信的架構前提。
**期間**：2026-03-04 ~ 2026-03-10

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-92：ADR-012 起草 — Claude API Key Rotation 認證輪流架構決策 | S | 1 | 待開始 |

**目標 Velocity**：1 point（1 Story）

---

## Sprint 43 — 完成

**Sprint Goal**：為 Backlog 下一個發展方向奠定決策基礎：精化 #69（開發不中斷）為可執行 Story，並執行 M5 外部觸及效果最終診斷，確認對外最後一哩是否有可改善空白。
**結果**：Goal 達成（2/2 Stories PASS）。Velocity 3 points，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-03-04 ~ 2026-03-10

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-90：Issue #69 精化 — 「開發不中斷 營運不中斷」可行性分析與 Story 拆解 | S | 1 | 完成 |
| US-91：M5 條件 (a) 觸及診斷 — Outreach Log 審查 + 安裝阻力掃描 | M | 2 | 完成 |

**目標 Velocity**：3 points（2 Stories）
**實際 Velocity**：3 points（2 Stories）

---

## Sprint 42 — 完成

**Sprint Goal**：完善 Onboarding 自動化鏈路（GitHub Action 串接）並強化 Sprint 執行品質（Done 定義 checkbox 強化），同時在本 Sprint Review 中首次驗證 US-86 一致性審查機制的完整覆蓋率。
**結果**：Goal 達成（2/2 Stories PASS）。Velocity 3 points，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-03-04 ~ 2026-03-10

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-88：Onboarding 自動串接 GitHub Action — runner 偵測 + backlog-intake 驗證 | M | 2 | 完成 |
| US-89：story-lifecycle-prompt.md Done 定義 checkbox 自動勾選提醒強化 | S | 1 | 完成 |

**目標 Velocity**：3 points（2 Stories）
**實際 Velocity**：3 points（2 Stories）

---

## Sprint 41 — 完成

**Sprint Goal**：M4 收尾與文件一致性強化 — 更新 ROADMAP M4 完成狀態、TD-002 技術債結案、建立交付物文案一致性審查機制回應 Sprint 38-40 連續 Retro Problem。
**結果**：Goal 達成（4/4 Stories PASS）。Velocity 5 points，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-03-04 ~ 2026-03-10

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-84：M4 里程碑正式收尾 — ROADMAP US-14 完成標注 + M4 結案評估 | S | 1 | 完成 |
| US-85：TD-002 技術債結案 + Schema 文案修正 | S | 1 | 完成 |
| US-86：交付物文案一致性審查機制 — 回應 Sprint 38-40 連續 Retro Problem | M | 2 | 完成 |
| US-87：GitHub Action 自動觸發 backlog-intake — Issue labeled 事件驅動入庫 | S | 1 | 完成 |

**目標 Velocity**：5 points（4 Stories）
**實際 Velocity**：5 points（4 Stories）

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

## 短衝記錄

| 日期 | 標題 | Issue/Story | commit hash |
|------|------|-------------|-------------|
| 2026-04-27 | 改善 sprint-N-replied label 機制為單一可重用 sprint-replied label | #66 | 7ce9c12 |
| 2026-04-27 | US-14 Notification Templates — PR/Deploy/Review 事件通知模板 | #63 | be133a5 |

---

> 歷史 Sprint 記錄：[PROJECT_BOARD_ARCHIVE](km/archive/PROJECT_BOARD_ARCHIVE.md)（Sprint 1–38）
