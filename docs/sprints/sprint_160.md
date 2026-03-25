# Sprint 160

**Sprint Goal**：強化框架品質防禦與開發者體驗 — 建立 QA 立場韌性機制、專案快速範本、Session Watchdog 心跳監控、Quality Observer MCP Phase 2 端點強化、Context Engineering JIT 載入策略、Quick Ship Pipeline 與 Schema-First 強制驗證工具

- **開始日期**：2026-03-25
- **容量**：7 pts

## Sprint Backlog

| # | Story | Issue | Points | Status | Assignee |
|---|-------|-------|--------|--------|----------|
| 1 | feat: QA FREE-MAD 挑戰韌性 — 制衡立場不受多數壓力撤回機制 | #795 | 1 | TODO | Developer |
| 2 | feat: 專案範本 — init-project.sh 快速配置 Skills/Hooks/Script 標準化 | #797 | 1 | TODO | Developer |
| 3 | feat: Context Engineering JIT Skill 載入策略（減少 context 壓力） | #793 | 1 | TODO | Developer |
| 4 | feat: Schema-First 強制工具 — API Contract 前置驗證腳本（ADR-036 落地） | #802 | 1 | TODO | Developer |
| 5 | feat: Quick Ship Pipeline — 統一 lint/test/bump/commit/PR 單一指令交付 | #798 | 1 | TODO | Developer |
| 6 | feat: Quality Observer MCP Phase 2 — metrics 端點強化（coverage/debt/health） | #794 | 1 | TODO | Developer |
| 7 | feat: Session Watchdog — 存活監控心跳機制（無聲 hang 偵測） | #772 | 1 | TODO | Developer |

**Total: 7 pts**

## 技術評估（Architect）

| Story | T-shirt | ADR 需求 | API 契約 | Schema Contract | Related SDDs | Story Type | Refinement | 說明 |
|-------|---------|---------|---------|----------------|-------------|------------|-----------|------|
| #795 | S | 無需 ADR | 不適用 | 豁免 | — | FEATURE | READY | 修改 `agents/qa-engineer.md` resilience protocol；修改 Decision Challenger prompt；新建 `tests/test-qa-resilience.sh` |
| #797 | S | 無需 ADR | 不適用 | 豁免 | — | FEATURE | READY | 新建 `templates/project-template/` 目錄；新建 `scripts/init-project.sh`；新建 `tests/test-project-template.sh` |
| #793 | S | 無需 ADR | 不適用 | 豁免 | — | FEATURE | READY | 修改 `skills/sprint-execution/SKILL.md` JIT loading 文件；修改 session-start hook 載入順序；新建 `tests/test-jit-loading.sh` |
| #802 | S | 無需 ADR（ADR-036 已 Accepted）| 不適用 | 豁免 | — | INFRA | READY | 新建 `scripts/validate-schema-contracts.sh`；修改 `skills/sprint-planning/references/architect-prompt.md`；新建 `tests/test-schema-first.sh` |
| #798 | S | 無需 ADR | 不適用 | 豁免 | — | INFRA | READY | 新建 `scripts/quick-ship.sh`；新建 `tests/test-quick-ship.sh` |
| #794 | S | 無需 ADR | 不適用 | 豁免（MCP stdio transport，非 HTTP REST API）| — | FEATURE | READY | 修改 `mcp-servers/quality-observer/index.js`；修改 Sprint Review analytics；新建 `tests/test-mcp-quality-observer.sh` |
| #772 | S | 無需 ADR | 不適用 | 豁免 | — | FEATURE | READY | 新建 `scripts/watchdog-check.sh`；修改 cruise main loop heartbeat 寫入；新建 `tests/test-watchdog.sh`；`docs/sprints/watchdog/` 目錄已存在 |

## Refinement 結果

- **#795**（S-size，FEATURE）：READY — Q1 無前置依賴，Q2 無下游 Story 依賴，Q3 範圍明確（qa-engineer.md + test），Q4 Contract Owner（QA）已確認，Q5 單 Sprint 可完成（1pt）
- **#797**（S-size，FEATURE）：READY — Q1 無前置依賴，Q2 無下游，Q3 template + init-script 獨立，Q4 Contract Owner（Architect）已確認，Q5 單 Sprint 可完成（1pt）
- **#793**（S-size，FEATURE）：READY — Q1 無前置依賴，Q2 無下游（SKILL.md JIT 文件修改），Q3 不需拆分，Q4 已確認，Q5 可完成（1pt）
- **#802**（S-size，INFRA）：READY — Q1 ADR-036 已 Accepted，Q2 無下游，Q3 範圍明確（validate script），Q4 已確認，Q5 可完成（1pt）
- **#798**（S-size，INFRA）：READY — Q1 無前置依賴，Q2 無下游，Q3 single script，Q4 已確認，Q5 可完成（1pt）
- **#794**（S-size，FEATURE）：READY — Q1 quality-observer MCP server 已存在，Q2 無下游，Q3 不需拆分，Q4 已確認，Q5 可完成（1pt）
- **#772**（S-size，FEATURE）：READY — Q1 watchdog/ 目錄已存在，Q2 無下游，Q3 不需拆分，Q4 已確認，Q5 可完成（1pt）

## QA 驗收確認

| Story | AC 完整性 | Path Verification | SDD 引用 | 隱性需求 | 結論 |
|-------|----------|-------------------|---------|---------|------|
| #795 | PASS | PASS（agents/qa-engineer.md 存在）| 跳過（Related SDDs=—）| [Minor] resilience protocol 需說明 counter-evidence 定義邊界，避免主觀解釋 | APPROVED |
| #797 | PASS | PASS（templates/ 存在）| 跳過（Related SDDs=—）| [Minor] AC2 init-project.sh 需處理目標目錄不存在情況（idempotent，NFR1 已涵蓋）| APPROVED |
| #793 | PASS | PASS（skills/sprint-execution/SKILL.md 存在）| 跳過（Related SDDs=—）| [Minor] AC2 session-start hook 修改需確保不破壞既有 SKILL 注入路徑（NFR1 已涵蓋）| APPROVED |
| #802 | PASS | PASS（skills/sprint-planning/references/architect-prompt.md 存在）| 跳過（Related SDDs=—）| [Minor] AC1 warn-only 模式需明確輸出格式供 CI log 解析 | APPROVED |
| #798 | PASS | PASS（scripts/ 目錄存在）| 跳過（Related SDDs=—）| [Minor] AC1 需定義 quick-ship.sh 失敗時 exit code 規範 | APPROVED |
| #794 | PASS | PASS（mcp-servers/quality-observer/ 存在）| 跳過（Related SDDs=—）| [Minor] AC1 coverage 資料不存在時的降級 JSON 結構（AC4 graceful fallback 已涵蓋）| APPROVED |
| #772 | PASS | PASS（docs/sprints/watchdog/ 存在）| 跳過（Related SDDs=—）| [Minor] AC2 WATCHDOG-ALERT 輸出至 cruise log 的格式標準需明確 | APPROVED |

## 方法論適用性評估

| Story | BDD | DDD | 說明 |
|-------|-----|-----|------|
| #795 | 建議（B1 — AC2 含條件觸發：收到 majority 壓力且無 counter-evidence → 維持立場，適合 Given-When-Then）| 不適用 | QA resilience 決策路徑 |
| #797 | 不適用 | 不適用 | Script + template 產出，無複雜行為路徑 |
| #793 | 不適用 | 不適用 | Prompt 策略文件 + hook 排序，無行為路徑 |
| #802 | 不適用 | 不適用 | Validation script，AC 為靜態結構 |
| #798 | 建議（B2 — AC1 含 pipeline 分支：validate fail / test fail / bump skip → 各自 exit code，適合 Given-When-Then）| 不適用 | Quick ship pipeline 分支邏輯 |
| #794 | 不適用 | 不適用 | MCP endpoint 擴充，AC 為靜態結構 |
| #772 | 建議（B1 — AC2 含條件：heartbeat stale → WATCHDOG-ALERT；AC3 含狀態機 ALIVE/STALE/MISSING，適合 Given-When-Then）| 不適用 | Watchdog 狀態偵測邏輯 |

## 執行順序（Parallel Grouping）

> SHIKIGAMI_MAX_PARALLEL 未設定，預設視為 2（CLAUDE.md §12）。

**Phase 1（可平行執行，Batch 1 最多 2）**：
- #795（1pt, S）— `agents/qa-engineer.md`（獨立）
- #797（1pt, S）— `templates/project-template/` + `scripts/init-project.sh`（獨立）

**Phase 2（Batch 2）**：
- #793（1pt, S）— `skills/sprint-execution/SKILL.md` + `session-start hook`
- #802（1pt, S）— `scripts/validate-schema-contracts.sh` + `architect-prompt.md`（獨立模組）

**Phase 3（Batch 3）**：
- #798（1pt, S）— `scripts/quick-ship.sh`（獨立）
- #794（1pt, S）— `mcp-servers/quality-observer/index.js`（獨立）

**Phase 4（Batch 4）**：
- #772（1pt, S）— `scripts/watchdog-check.sh` + cruise loop heartbeat

**檔案衝突分析**：

| 衝突檔案 | 涉及 Story | 建議執行順序 | 矩陣依據 |
|---------|-----------|------------|---------|
| `skills/sprint-execution/SKILL.md` | #793 (Phase 2) 唯一使用 | 無衝突 | 單一 Story 修改 |
| 其他檔案均獨立 | — | — | 無衝突 |

## Schema Contracts（ADR-036 Schema 先行）

本 Sprint 所有 Story 為腳本/設定/文件/Skill prompt 類，不涉及 Agent-to-Agent 資料交換或 HTTP REST API，無需產出 Schema Contract。

## model-route 記錄

- model-route #795 tier=2 score=6 model=sonnet reason=FEATURE-S-standard
- model-route #797 tier=2 score=6 model=sonnet reason=FEATURE-S-standard
- model-route #793 tier=2 score=6 model=sonnet reason=FEATURE-S-standard
- model-route #802 tier=2 score=6 model=sonnet reason=INFRA-S-standard
- model-route #798 tier=2 score=6 model=sonnet reason=INFRA-S-standard
- model-route #794 tier=2 score=6 model=sonnet reason=FEATURE-S-standard
- model-route #772 tier=2 score=6 model=sonnet reason=FEATURE-S-standard
