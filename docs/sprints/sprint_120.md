# Sprint 120 — PO 巡邏行為修正 + CI 基礎設施修復

**Sprint Goal**：修正 PO patrol 交付物識別缺陷 + Stakeholder 回覆處置表 + Sprint 不等 stakeholder 流程改善 + CI workflow 修復 + code-review checklist 強化
**期間**：2026-03-23 ~ 2026-03-30
**Velocity 目標**：10 pts（Sprint 119: 10 pts）

## Sprint Backlog

| # | Story | Size | Points | MoSCoW | 狀態 |
|---|-------|------|--------|--------|------|
| #381 | retro: 修復 new-issue-intake CI workflow — claude-code-action 持續 failure | S | 2 | Must | 待開始 |
| #412 | [Cruise Feedback] PO 巡邏未正確解讀 Issue 交付物，誤將「規劃」類 Issue 標為 awaiting-reply | M | 3 | Must | 待開始 |
| #422 | [Cruise Feedback] 新增 Stakeholder 回覆處置表 — 明確指示應立即觸發執行 | S | 2 | Must | 待開始 |
| #415 | [Cruise Feedback] Sprint 不應等待 stakeholder — 人機協作流程改善 | S | 2 | Should | 待開始 |
| #421 | retro: code-review checklist 加入 PR title / Issue title 語義一致性檢查 | S | 1 | Should | 完成 |

## 技術決策

- #381 調查 claude-code-action CI failure 根因，修復 new-issue-intake workflow
- #412 修改 PO patrol 分流邏輯，加入交付物類型識別（實作類/規劃類/調查類）
- #422 新增 Stakeholder 回覆處置表（明確指示/確認/提問/拒絕），在 Issue 處置決策表之前執行
- #415 新增 shoot_skip_merge、sprint.completion_criteria: pr_submitted、self_review 步驟
- #421 code-review checklist 加入 PR title / Issue title 語義一致性檢查規則

## 獨立性評估

| Story | 修改檔案 | 獨立性 |
|-------|---------|--------|
| #381 | `.github/workflows/new-issue-intake.yml` | 獨立 |
| #412 | PO patrol 相關 skill/prompt | 與 #422 衝突（同修改 PO patrol 邏輯）|
| #422 | PO patrol 相關 skill/prompt | 與 #412 衝突 |
| #415 | `skills/shoot/SKILL.md`, `skills/sprint-execution/SKILL.md` | 獨立 |
| #421 | code-review 相關 prompt | 獨立 |

## 平行分群

### Phase 1（可平行執行）
| Story | 標題 | Size | 說明 |
|-------|------|------|------|
| #381 | CI workflow 修復 | S | 獨立修改 CI workflow |
| #415 | Sprint 不等 stakeholder | S | 獨立修改 shoot/sprint-execution |
| #421 | code-review checklist | S | 獨立修改 code-review prompt |

### Phase 2（需序列執行）
| Story | 標題 | Size | 衝突原因 |
|-------|------|------|---------|
| #412 | PO patrol 交付物識別 | M | 先執行，建立交付物識別基礎 |
| #422 | Stakeholder 回覆處置表 | S | 後執行，依賴 #412 的交付物識別 |
