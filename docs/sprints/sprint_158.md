# Sprint 158

**Sprint Goal**：強化框架自動化維運能力 — 新增 SRE patrol 記憶體趨勢洩漏告警機制，並為 cruise log 歸檔建立每日定時觸發流程

- **開始日期**：2026-03-25
- **容量**：4 pts

## Sprint Backlog

| # | Story | Issue | Points | Status | Assignee |
|---|-------|-------|--------|--------|----------|
| 1 | feat: SRE patrol 記憶體使用趨勢偵測（漸進式洩漏告警） | #743 | 2 | TODO | Developer |
| 2 | feat: cruise logs 歸檔每日自動觸發（定時 cron 整合） | #738 | 2 | TODO | Developer |

**Total: 4 pts**

## 技術評估（Architect）

| Story | T-shirt | ADR 需求 | API 契約 | Schema Contract | Related SDDs | Story Type | Refinement | 說明 |
|-------|---------|---------|---------|----------------|-------------|------------|-----------|------|
| #743 | M | 無需 ADR | 不適用 | 豁免 | — | FEATURE | READY | 新建 `scripts/memory-trend-check.sh` + `tests/test-memory-trend.sh`；修改 SRE patrol 執行路徑（`skills/cruise/references/sre-inspection.md`）新增記憶體記錄 |
| #738 | M | 無需 ADR | 不適用 | 豁免 | — | INFRA | READY | 修改 `scripts/cruise_cron.sh` AC1 歸檔邏輯；修改 `.claude/shikigami.local.md` AC2；新建 `tests/test-cruise-archive-trigger.sh` |

## Refinement 結果

- **#743**（M-size，FEATURE）：READY — Q1 無前置依賴，Q2 無下游 Story 依賴，Q3 無跨 Type 拆分需求，Q4 Contract Owner（Architect）已確認，Q5 單 Sprint 可完成（2pts）
- **#738**（M-size，INFRA）：READY — Q1 無前置依賴（cruise_cron.sh 已存在），Q2 無下游依賴，Q3 不需拆分（SRE 工作量明確），Q4 Contract Owner（SRE）已確認，Q5 單 Sprint 可完成（2pts）

## QA 驗收確認

| Story | AC 完整性 | Path Verification | SDD 引用 | 隱性需求 | 結論 |
|-------|----------|-------------------|---------|---------|------|
| #743 | PASS | N/A（新建檔案）| 跳過（Related SDDs=—）| [Minor] AC5 建議補充：歷史記錄 < 3 條時不觸發告警（reliability）| APPROVED |
| #738 | PASS | PASS（cruise_cron.sh, shikigami.local.md 存在）| 跳過（Related SDDs=—）| 無 | APPROVED |

## 方法論適用性評估

| Story | BDD | DDD | 說明 |
|-------|-----|-----|------|
| #743 | 建議（B1 — AC2 含條件觸發路徑，建議補充 Given-When-Then 行為範例）| 不適用 | 連續 3 次下降 > 10% 觸發條件適合 BDD |
| #738 | 不適用 | 不適用 | AC 為靜態設定項，無複雜行為路徑 |

## 執行順序（Parallel Grouping）

> SHIKIGAMI_MAX_PARALLEL 未設定，預設視為 2（CLAUDE.md §12）。

**Phase 1（可平行執行，Batch 1 最多 2）**：
- #743（2pt, M）— `scripts/memory-trend-check.sh` + `skills/cruise/references/sre-inspection.md`
- #738（2pt, M）— `scripts/cruise_cron.sh` + `.claude/shikigami.local.md`

Phase 2：無（無檔案衝突）

**檔案衝突分析**：

| 衝突檔案 | 涉及 Story | 建議執行順序 | 矩陣依據 |
|---------|-----------|------------|---------|
| 無衝突 | — | 可平行 | parallel-safety-matrix.md §1：修改不同目錄 = YES |

## Schema Contracts（ADR-036 Schema 先行）

本 Sprint 所有 Story 為腳本/設定/巡檢流程類，不涉及 Agent-to-Agent 資料交換或 HTTP REST API，無需產出 Schema Contract。

## model-route 記錄

- model-route #743 tier=2 score=7 model=sonnet reason=FEATURE-M-standard
- model-route #738 tier=2 score=7 model=sonnet reason=INFRA-M-standard
