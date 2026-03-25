# Sprint 165

**Sprint Goal**：建立核心腳本測試防護網 — 為 bump-version、init-project、validate 系列與 Watchdog 補齊自動化測試，確保紅線邏輯有測試護航

- **開始日期**：2026-03-26
- **容量**：5 pts（基準 velocity 7 pts，本 Sprint 選入 5 pts — 全為 S size 測試腳本，數量充足）

## Sprint Backlog

| # | Story | Issue | Points | Status | Assignee |
|---|-------|-------|--------|--------|----------|
| 1 | test: bump-version.sh 自動化測試 — 版號同步 5 檔驗證 | #839 | 1 | DONE (#850) | Developer |
| 2 | test: init-project.sh 自動化測試 — Onboarding 腳本初始化驗證 | #845 | 1 | DONE (de31215) | Developer |
| 3 | test: 驗證腳本測試覆蓋率提升 — validate-agents/skills/json 補測試 | #838 | 1 | DONE (#851) | Developer |
| 4 | test: calculate-sprint-capacity.sh 自動化測試 — 容量計算驗證（AC 更新：取代舊 test-sprint-capacity.sh） | #844 | 1 | DONE (03b4970) | Developer |
| 5 | test: Watchdog 腳本測試覆蓋 — check/monitor/restart 三合一驗證 | #847 | 1 | DONE (#852) | Developer |

**Total: 5 pts**

## PO Round 1：Backlog 排序與 Story 選取

### Velocity 計算
| Sprint | Velocity |
|--------|----------|
| Sprint 162 | 6 pts |
| Sprint 163 | 7 pts |
| Sprint 164 | 4 pts |
| **平均** | **6 pts** |
| **建議容量** | **4-7 pts（上限 7 pts）** |

> 腳本輸出：`[CAPACITY] avg_velocity=6pts, recommended_capacity=6pts (±20% range: 4-7pts)`

### RETRO-AUTO-PROMOTE 掃描結果
`[BACKLOG-OK]` 無 `retro-action` + `priority: must` 未升格 Issues。

### 即時排序（MoSCoW Tier + RICE Score）
| Issue | MoSCoW Tier | RICE Score | Size | Points | 選入決策 |
|-------|------------|-----------|------|--------|---------|
| #839 | should (tier 2) | — | S | 1 | 選入（紅線保護：版號同步） |
| #845 | should (tier 2) | — | S | 1 | 選入（Onboarding 品質） |
| #838 | should (tier 2) | — | S | 1 | 選入（驗證腳本覆蓋） |
| #844 | should (tier 2) | — | S | 1 | 選入（AC 更新後 READY） |
| #847 | should (tier 2) | — | S | 1 | 選入（Watchdog 覆蓋） |

### 非功能屬性審查
| Issue | NFR 欄位 | 狀態 |
|-------|---------|------|
| #839 | NFR1: 測試不依賴網路（mock 5 檔） | 通過 |
| #845 | NFR1: 測試使用臨時目錄隔離 | 通過 |
| #838 | NFR1: 測試使用 fixture 檔案 | 通過 |
| #844 | NFR1: 取代舊 test-sprint-capacity.sh | 通過 |
| #847 | NFR1: 測試不啟動實際 watchdog 進程 | 通過 |

### 獨立性評估
| Issue | 預計修改檔案 | 獨立性 |
|-------|------------|--------|
| #839 | tests/test-bump-version.sh | 獨立 |
| #845 | tests/test-init-project.sh | 獨立 |
| #838 | tests/test-validate-agents.sh, tests/test-validate-skills.sh, tests/test-validate-json.sh | 獨立 |
| #844 | tests/test-calculate-sprint-capacity.sh（刪除 tests/test-sprint-capacity.sh） | 獨立 |
| #847 | tests/test-watchdog.sh | 獨立 |

## 技術評估（Architect）

> 容量基線：`[CAPACITY] avg_velocity=6pts, recommended_capacity=6pts (±20% range: 4-7pts)`
> ADR 衝突偵測：無新 ADR 需求

| Story | T-shirt | ADR 需求 | Story Type | Refinement | 路由 Tier | 說明 |
|-------|---------|---------|------------|-----------|----------|------|
| #839 | S | 無 | TEST | READY | haiku | bump-version.sh 5 檔版號同步測試 |
| #845 | S | 無 | TEST | READY | haiku | init-project.sh 初始化流程測試 |
| #838 | S | 無 | TEST | READY | haiku | validate-agents/skills/json 補測試 |
| #844 | S | 無 | TEST | READY | haiku | calculate-sprint-capacity.sh 測試（取代舊測試） |
| #847 | S | 無 | TEST | READY | haiku | watchdog check/monitor/restart 三合一測試 |

**Hard Gate 檢查**：全部通過，無 ADR 需求。

### 平行分群
| Group | Stories | 說明 |
|-------|---------|------|
| Batch 1（可並行） | #839, #845 | 修改不同測試檔案，無衝突 |
| Batch 2（可並行） | #838, #844 | 修改不同測試檔案，無衝突 |
| Batch 3 | #847 | 獨立 |

> MAX_PARALLEL=2，3 batch 循序執行。

### Token Cost Routing
全部 haiku tier（風險評分 5-6），純測試腳本，無框架行為變更風險。

## QA 驗收確認

| Story | AC 驗收結果 | DoR 狀態 |
|-------|------------|---------|
| #839 | PASS — AC 可自動化測試 | READY |
| #845 | PASS — AC 可自動化測試 | READY |
| #838 | PASS — AC 可自動化測試 | READY |
| #844 | PASS — AC 更新後可自動化測試（取代舊 test-sprint-capacity.sh） | READY |
| #847 | PASS — AC 可自動化測試 | READY |

**D3 協定**：Architect 與 QA 無分歧，D3 不觸發。

## PO 決策紀錄

1. **#844 AC 調整**：採用 QA 建議，AC1 改為取代既有 test-sprint-capacity.sh，新建 test-calculate-sprint-capacity.sh，合併覆蓋 + 擴充邊界場景。已在 GitHub Issue #844 留言記錄。

## Retrospective

**Review 完成時間**：2026-03-26

### Sprint Metrics
- **Velocity**：5 pts
- **Completion Rate**：100%（5/5 Stories DONE）
- **Sprint Goal**：達成 — 核心腳本測試防護網建立完成

### 測試覆蓋成果
| Story | Issue | 測試結果 |
|-------|-------|---------|
| bump-version.sh 測試 | #839 | 18 PASS |
| init-project.sh 測試 | #845 | 16 PASS |
| validate-agents/skills/json 補測試 | #838 | 81 PASS（24+23+34） |
| calculate-sprint-capacity.sh 測試 | #844 | 14 PASS |
| Watchdog 三合一測試 | #847 | 5 PASS |
| **合計** | | **134 PASS** |

### Demo 結果
PASS — 全部 5 個 Story 測試腳本存在且執行通過。

### QA 邊界測試
PASS — 本地執行確認所有測試腳本 0 FAIL。

### Stakeholder 確認
PASS — 本 Sprint 全為測試腳本，無使用者面功能變更，商業風險低。

### CRITICAL Quality Gate 覆寫
無。

### Sprint 外完成項目
無（Shoot_Log 本 Sprint 期間無新條目）。

### Retro Actions
- 無系統性問題，本 Sprint 順利交付。

### Issue 回寫
- 已 close：#839、#845、#838、#844、#847
- 已移除 `status: in-sprint` label
