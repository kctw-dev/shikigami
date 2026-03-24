---
sprint: 142
start_date: 2026-03-25
end_date: 2026-03-31
status: active
velocity_baseline: 4.0
capacity: 5
version_target: v0.95.1
---

# Sprint 142

## Sprint Goal

修復 New Issue Intake CI 持續失敗根因，並完成 Backlog 健康補充，確保後續 Sprint 容量充足。

## Sprint Backlog

| Story | Issue | Type | Size | Points | 狀態 | Assignee | 獨立性 |
|-------|-------|------|------|--------|------|----------|--------|
| retro: 調查並修正 New Issue Intake CI workflow 連續失敗 | #650 | BUG/INFRA | M | 2 | DONE(#652) | Developer | Group A（獨立）|
| retro: Backlog 補充 — 掃描 open Issues 提升可執行 Story 存量 | #651 | RETRO | M | 3 | DONE(#659) | PO | Group A（獨立）|

**Sprint 容量**：5 pts（Sprint 139=5, 140=5, 141=2, avg≈4, 建議 5pts）

**平行分群**：Group A — #650 與 #651 完全獨立，可平行執行

## Architect 技術評估摘要

- #650: CI workflow 修正，根因為 ANTHROPIC_API_KEY secret 為空。需 Admin 設定 secret（外部依賴）。建議加入 workflow_dispatch 觸發器。
- #651: Backlog 管理操作，不涉及架構變更。PRODUCT_BACKLOG.md 已 deprecated (ADR-010)，source of truth 為 GitHub Issues。

## QA 驗收備註

- #650: AC2 已拆分 agent 可交付 vs Admin 人工操作。AC3 依賴 Admin 完成 secret 設定。
- #651: AC2 已修正為 GitHub Issues 操作（不寫入 deprecated 檔案）。
