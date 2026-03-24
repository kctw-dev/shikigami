# Sprint 128

## Sprint Goal
修復 Cruise Mode 核心行為缺陷（project_level=low HARD-GATE + SRE main branch 盲區），完成 INFRA 測試框架首次交付，同步落地三項 retro 流程改善。

## Sprint Backlog

| Story ID | 標題 | Type | Size | Priority | Assignee | Phase |
|----------|------|------|------|----------|----------|-------|
| #517 | [Cruise] project_level=low 自動行為標為 HARD-GATE | BUG/FEAT | S(1) | must | Developer | Phase 2-1 |
| #519 | [SRE] SRE 巡檢補充 main branch CI 獨立檢查 | BUG | S(1) | must | Developer | Phase 1 |
| #491 | Architect Gate for M+ Refactor Story | PROCESS | S(1) | must | Developer | Phase 2-3 |
| #494 | INFRA 測試框架架構設計 | FEATURE | S(1) | should | Developer | Phase 1 |
| #495 | INFRA 回歸測試案例實作 | FEATURE | M(2) | should | Developer | Phase 3 |
| #513 | Task 工具追蹤 Sprint Stories 進度 | FEATURE | S(1) | should | Developer | Phase 2-2 |
| #492 | Sprint 容量估算修訂 | PROCESS | S(1) | should | Developer | Phase 2-4 |

## Capacity
- Total: 8 pts (6S + 1M)
- Sprint 127 Velocity: 7 pts (100%)
- Baseline: 5-8 pts

## Execution Plan

### Phase 1（可平行）
- #519 SRE main branch CI 獨立檢查
- #494 INFRA 測試框架架構設計

### Phase 2（序列執行）
1. #517 HARD-GATE
2. #513 Task 工具追蹤
3. #491 Architect Gate
4. #492 容量估算修訂

### Phase 3（依賴 Phase 1）
- #495 INFRA 回歸測試案例實作（依賴 #494）

## Risks
- #524 OAuth token 過期 — CI workflow 全面失效，需使用者手動更新 GitHub Secret
- #525 Runner offline — CI 容量降至 1 台

## Sprint Duration
2026-03-24 ~ 2026-03-31
