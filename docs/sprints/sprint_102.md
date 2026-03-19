# Sprint 102

**Sprint Goal**：清除 Sprint 100 Retro 遺留測試技術債
**日期**：2026-03-19
**容量**：3 points
**狀態**：進行中

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INFRA：修復 test-sprint-planning-skill.sh | #308 | S | 1 | 待辦 |
| INFRA：US-275 邊界補齊 | #309 | S | 1 | 待辦 |
| RESEARCH：評估既有測試技術債清理 | #310 | S | 1 | 待辦 |

## Acceptance Criteria

### US-308 — INFRA #308：修復 test-sprint-planning-skill.sh

**AC-1：現有 FAIL 全部修復**
- 現有 10 FAIL 全部修復為 PASS

**AC-2：防漂移約束覆蓋**
- 修改後測試仍覆蓋 po-prompt.md 的防漂移約束

### US-309 — INFRA #309：US-275 邊界補齊

**AC-1：空目錄 fallback**
- sprint 目錄為空時 max_N fallback 為 0，不報錯

**AC-2：git pull 失敗容錯**
- git pull 失敗時輸出 [WARN] 並繼續（不阻塞）

### US-310 — RESEARCH #310：評估既有測試技術債清理

**AC-1：結構化評估報告**
- 產出結構化評估報告（含 FAIL 原因分類、建議處置）

**AC-2：測試涵蓋範圍**
- 報告涵蓋 test-us13 和 test-us37 兩個測試檔案

## 技術評估摘要

- **Architect 備注**：三者可完全平行（無檔案衝突）；#308 TDD 反向修復（改測試路徑指向 po-prompt.md）；#309 直接修改 po-prompt.md 兩處邊界；#310 RESEARCH 產出評估報告
- **方法論**：#308/#309 TDD，#310 RESEARCH
- **Refinement**：READY

## QA 驗收確認摘要

- **US-308**：PASS — 2 AC 全數可驗證（執行測試腳本驗證 PASS 數 + grep 防漂移關鍵字）
- **US-309**：PASS — 2 AC 全數可驗證（空目錄模擬 + git pull 失敗模擬）
- **US-310**：PASS — 2 AC 全數可驗證（檢查報告結構 + 檢查涵蓋範圍）
- **防漂移基準**：3 Stories, 3 pts

## 平行分群建議

| Phase | 分群 | Stories | 理由 |
|-------|------|---------|------|
| Phase 1 | Group A | #308 | 修復測試腳本，獨立作業 |
| Phase 1 | Group B | #309 | 修改 po-prompt.md 邊界，獨立作業 |
| Phase 1 | Group C | #310 | RESEARCH 評估，獨立作業 |
