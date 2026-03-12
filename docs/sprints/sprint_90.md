# Sprint 90

**日期**：2026-03-12
**狀態**：進行中
**Sprint Goal**：CI/CD 可觀測性 + QA 流程補強 — Deploy 通知模板建立 + Systematic Debugging 自動觸發時機定義

---

## Sprint Backlog

| Story ID | 標題 | Issue | Size | Points | 狀態 |
|----------|------|-------|------|--------|------|
| US-247 | Systematic Debugging 自動觸發時機 — Sprint Review/Deploy/Bug Fix 三觸發點定義 | #240 | S | 1 | 待開始 |
| US-246 | CI/CD Deploy 通知 Workflow 模板 — deploy-notify.yml + Deploy Board 初始化 | #239 | S | 1 | 待開始 |

**Sprint 容量**：2 points

---

## Story 詳細

### US-247：Systematic Debugging 自動觸發時機（#240）

**Story Type**：FEATURE（doc-only）
**來源**：CloneAI Sprint 73-74 實戰觀察 — systematic debugging 能發現 QA 找不到的運行時問題

**AC**：
- [靜態] AC1：`skills/sprint-review/SKILL.md` 新增 systematic debugging 觸發步驟（Sprint Review 前，mandatory），位於 §7 執行檢查清單
- [靜態] AC2：`skills/sprint-execution/SKILL.md` 定義 Deploy 後 + Bug 修復後的 systematic debugging 觸發指引
- [靜態] AC3：`skills/scrum-master/SKILL.md` 更新角色調度表，新增 systematic debugging 觸發場景

**doc-only**：true（TDD 豁免，但 Spec Compliance + Code Quality Review 不豁免；ADR-003 Preflight Check 必須通過）

---

### US-246：CI/CD Deploy 通知 Workflow 模板（#239）

**Story Type**：FEATURE（doc-only / template）
**來源**：CloneAI Sprint 73-74 實戰經驗 — deploy notification + status board 標準化

**AC**：
- [靜態] AC1：`docs/templates/deploy-notify.yml` 模板建立，包含 workflow_run 監聯、Issue 看板更新、concurrency group 串行化
- [靜態] AC2：`docs/templates/deploy-board-init.sh` 腳本模板建立，包含 6 格狀態看板 Issue 初始化（Staging/Production × Backend/Frontend/E2E）
- [靜態] AC3：`skills/deployment-readiness/SKILL.md` 新增 Deploy Board 參照指引

**doc-only**：true（TDD 豁免；AC3 涉及 skills/ 路徑，ADR-003 Preflight Check 必須通過）

---

## 技術評估（Architect）

| Story | T-shirt | ADR 需求 | API 契約 | 說明 |
|-------|---------|---------|---------|------|
| US-247 | S | 無需 ADR | 不適用 | doc-only，修改 3 個 skills/ SKILL.md |
| US-246 | S | 無需 ADR | 不適用 | 新建 2 個 docs/templates/ 模板 + 修改 1 個 SKILL.md |

## 平行分群建議

### Phase 1（可平行執行）

| Story ID | 標題 | T-shirt | 說明 |
|----------|------|---------|------|
| US-247 | Systematic Debugging 自動觸發 | S | 修改 skills/{sprint-review,sprint-execution,scrum-master}/SKILL.md |
| US-246 | Deploy 通知模板 | S | 新建 docs/templates/ + 修改 skills/deployment-readiness/SKILL.md |

**檔案衝突分析**：無衝突，兩 Story 修改完全不同的檔案。

---

## QA 驗收標準確認

| Story | AC 可測試性 | 路徑驗證 | doc-only | ADR-003 | 結論 |
|-------|-----------|---------|---------|---------|------|
| US-247 | 全部 PASS | 全部 PASS（既有檔案） | true | 必須（skills/ 修改） | 可啟動 |
| US-246 | 全部 PASS | 2 個 N/A（新建）+ 2 個 PASS | true | 必須（AC3 skills/ 修改） | 可啟動 |
