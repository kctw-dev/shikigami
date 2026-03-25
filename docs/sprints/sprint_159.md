# Sprint 159

**Sprint Goal**：強化框架可靠性與品質治理基礎 — 建立 Kill Switch 安全停止機制、DM-4 Write Gateway 系統化保護、quality-gate 決策記錄台帳、Playwright MCP 穩定性驗證 Spike、ADR 索引自動維護與互動式 QA 決策點前置設計

- **開始日期**：2026-03-25
- **容量**：6 pts

## Sprint Backlog

| # | Story | Issue | Points | Status | Assignee |
|---|-------|-------|--------|--------|----------|
| 1 | feat: Kill Switch — 優雅緊急停止機制（Story 邊界安全中止自動執行） | #783 | 1 | TODO | Developer |
| 2 | feat: DM-4 Write Gateway 系統化 — 平行 subagent 共用文件寫入保護 | #775 | 1 | TODO | Developer |
| 3 | feat: quality-gate 決策記錄機制 — CRITICAL 發現處置台帳 + 防濫用稽核腳本 | #779 | 1 | TODO | Developer |
| 4 | spike: Playwright MCP subagent 穩定性驗證（Browser Automation 前置 Spike） | #774 | 1 | TODO | Developer |
| 5 | feat: ADR 目錄索引自動維護 v2 — docs/adr/README.md 可搜尋索引（architecture-decision 整合） | #778 | 1 | TODO | Developer |
| 6 | feat: quality-gate CRITICAL 互動決策點 — 結構化風險接受 / 拒絕 / 延後機制 | #773 | 1 | TODO | Developer |

**Total: 6 pts**

## 技術評估（Architect）

| Story | T-shirt | ADR 需求 | API 契約 | Schema Contract | Related SDDs | Story Type | Refinement | 說明 |
|-------|---------|---------|---------|----------------|-------------|------------|-----------|------|
| #783 | S | 無需 ADR | 不適用 | 豁免 | — | INFRA | READY | 新建 `scripts/kill-switch.sh`；修改 `skills/sprint-execution/SKILL.md` dispatch 前置 kill-switch 檢查；修改 cruise main loop sentinel 偵測 |
| #775 | S | 無需 ADR | 不適用 | 豁免 | — | INFRA | READY | 修改 `skills/sprint-execution/SKILL.md` coordinator-only 清單（PROJECT_BOARD.md、sprint_N.md、checkpoint.json）；修改 `skills/sprint-execution/story-lifecycle-prompt.md` HARD-GATE；新建 `tests/test-dm4-write-gateway.sh` |
| #779 | S | 無需 ADR | 不適用 | 豁免 | — | FEATURE | READY | 新建 `docs/km/quality-gate-decisions.md`；修改 `skills/sprint-review/SKILL.md` CRITICAL override 記錄步驟；新建 `scripts/quality-gate-audit.sh` + `tests/test-quality-gate-audit.sh` |
| #774 | S | 無需 ADR | 不適用 | 豁免 | — | RESEARCH | READY | 產出 `docs/discovery/spike-playwright-mcp-2026.md` 報告；GO/NO-GO 決策；無生產代碼；不影響 main branch |
| #778 | S | 無需 ADR | 不適用 | 豁免 | — | FEATURE | READY | 新建 `scripts/update-adr-index.sh`；新建/更新 `docs/adr/README.md`；修改 `skills/architecture-decision/SKILL.md` 後置自動更新步驟 |
| #773 | S | 無需 ADR | 不適用 | 豁免 | — | FEATURE | READY | 修改 `skills/sprint-execution/story-lifecycle-prompt.md` CRITICAL QA detection；`docs/km/quality-gate-decisions.md` 由 #779 先行建立；新建 `tests/test-interactive-review.sh` |

## Refinement 結果

- **#783**（S-size，INFRA）：READY — Q1 無前置依賴，Q2 無下游 Story 依賴，Q3 範圍明確（kill-switch sentinel + dispatch 前置檢查），Q4 Contract Owner（Architect）已確認，Q5 單 Sprint 可完成（1pt）
- **#775**（S-size，INFRA）：READY — Q1 無前置依賴（story-lifecycle-prompt.md 已存在），Q2 #773/#779 受益但不被阻擋，Q3 不需拆分，Q4 Contract Owner（Architect）已確認，Q5 單 Sprint 可完成（1pt）
- **#779**（S-size，FEATURE）：READY — Q1 無前置依賴，Q2 #773 依賴此 Story 先行建立 quality-gate-decisions.md，Q3 不需拆分，Q4 Contract Owner（Architect）已確認，Q5 單 Sprint 可完成（1pt）
- **#774**（S-size，RESEARCH）：READY — Q1 無前置依賴，Q2 Browser Automation Skill 為下游但不在本 Sprint，Q3 交付物明確（Spike 報告），Q4 Contract Owner（Architect）已確認，Q5 單 Sprint 可完成（1pt）
- **#778**（S-size，FEATURE）：READY — Q1 無前置依賴（docs/adr/ 已存在），Q2 無下游，Q3 不需拆分，Q4 Contract Owner（Architect）已確認，Q5 單 Sprint 可完成（1pt）
- **#773**（S-size，FEATURE）：READY — Q1 依賴 #779 先行（quality-gate-decisions.md），Q2 無下游，Q3 不需拆分，Q4 Contract Owner（Architect）已確認，Q5 單 Sprint 可完成（1pt）

## QA 驗收確認

| Story | AC 完整性 | Path Verification | SDD 引用 | 隱性需求 | 結論 |
|-------|----------|-------------------|---------|---------|------|
| #783 | PASS | PASS（skills/sprint-execution/SKILL.md 存在）| 跳過（Related SDDs=—）| [Minor] AC2 需明確：kill-switch 檢查在 Story dispatch 迴圈開頭執行 | APPROVED |
| #775 | PASS | PASS（story-lifecycle-prompt.md 存在）| 跳過（Related SDDs=—）| [Minor] AC1 需在 SKILL.md 步驟中列出 coordinator-only 檔案完整清單 | APPROVED |
| #779 | PASS | PASS（skills/sprint-review/SKILL.md 存在）| 跳過（Related SDDs=—）| [Minor] AC1 需說明 CRITICAL override 的偵測條件（PR merged despite CRITICAL finding）| APPROVED |
| #774 | PASS | N/A（新建檔案）| 跳過（Related SDDs=—）| 無 — Spike 範疇定義清晰 | APPROVED |
| #778 | PASS | PASS（docs/adr/ 目錄存在）| 跳過（Related SDDs=—）| [Minor] AC3 需釐清 ADR status 欄位從 frontmatter 或 body 正則提取 | APPROVED |
| #773 | PASS | PASS（story-lifecycle-prompt.md 存在）| 跳過（Related SDDs=—）| [Note] 依賴 #779 先行，執行排序需在 sprint-execution 派遣前確認 #779 完成 | APPROVED（依賴 #779）|

## 方法論適用性評估

| Story | BDD | DDD | 說明 |
|-------|-----|-----|------|
| #783 | 建議（B1 — AC2 含條件觸發路徑：sentinel 存在 → 停止派遣，適合 Given-When-Then）| 不適用 | Kill switch sentinel 偵測邏輯 |
| #775 | 不適用 | 不適用 | Prompt enforcement + validation，無複雜行為路徑 |
| #779 | 不適用 | 不適用 | 記錄機制，AC 為靜態結構 |
| #774 | 不適用 | 不適用 | RESEARCH type，非功能實作 |
| #778 | 不適用 | 不適用 | Script + doc 產出，無行為路徑 |
| #773 | 建議（B2 — AC1 含三路決策點 A/B/C，適合 Given CRITICAL finding / When user selects A/B/C / Then record）| 不適用 | 互動決策點觸發邏輯 |

## 執行順序（Parallel Grouping）

> SHIKIGAMI_MAX_PARALLEL 未設定，預設視為 2（CLAUDE.md §12）。

**Phase 1（可平行執行，Batch 1 最多 2）**：
- #783（1pt, S）— `scripts/kill-switch.sh` + `skills/sprint-execution/SKILL.md`
- #774（1pt, S）— `docs/discovery/spike-playwright-mcp-2026.md`（RESEARCH，無代碼衝突）

**Phase 2（Batch 2）**：
- #775（1pt, S）— `skills/sprint-execution/SKILL.md` + `story-lifecycle-prompt.md`（Phase 1 #783 修改 SKILL.md 後執行，避免衝突）
- #778（1pt, S）— `scripts/update-adr-index.sh` + `docs/adr/README.md`（獨立模組）

**Phase 3（Batch 3）**：
- #779（1pt, S）— `docs/km/quality-gate-decisions.md` + `skills/sprint-review/SKILL.md`
- #773（1pt, S）— `story-lifecycle-prompt.md` + `tests/test-interactive-review.sh`（依賴 #779 先行建立 quality-gate-decisions.md）

> #773 必須在 #779 完成後才能派遣（共用 docs/km/quality-gate-decisions.md 前置條件）。

**檔案衝突分析**：

| 衝突檔案 | 涉及 Story | 建議執行順序 | 矩陣依據 |
|---------|-----------|------------|---------|
| `skills/sprint-execution/SKILL.md` | #783 (Phase 1), #775 (Phase 2) | Phase 1 完成後才執行 Phase 2 | 同檔案修改必須序列化 |
| `docs/km/quality-gate-decisions.md` | #779 (建立), #773 (依賴) | #779 必須在 #773 之前完成 | 前置條件依賴 |
| `story-lifecycle-prompt.md` | #775 (Phase 2), #773 (Phase 3) | Phase 2 完成後才執行 Phase 3 | 同檔案修改序列化 |

## Schema Contracts（ADR-036 Schema 先行）

本 Sprint 所有 Story 為腳本/設定/文件/Skill prompt 類，不涉及 Agent-to-Agent 資料交換或 HTTP REST API，無需產出 Schema Contract。

## model-route 記錄

- model-route #783 tier=2 score=6 model=sonnet reason=INFRA-S-standard
- model-route #775 tier=2 score=6 model=sonnet reason=INFRA-S-standard
- model-route #779 tier=2 score=6 model=sonnet reason=FEATURE-S-standard
- model-route #774 tier=1 score=5 model=haiku reason=RESEARCH-S-no-code
- model-route #778 tier=2 score=6 model=sonnet reason=FEATURE-S-standard
- model-route #773 tier=2 score=6 model=sonnet reason=FEATURE-S-standard
