# Sprint 157

- **Sprint Goal**: 強化 Sprint 流程品質與觀測能力 — 補充 Sprint Review 測試覆蓋、建立 ADR 索引自動維護、整合 SRE 記憶體趨勢偵測、Sprint Planning 會議紀錄模板標準化、ADR-039 Model Routing Dashboard、Sprint Review 指標收集平行化
- **期間**: 2026-03-25 ~ 2026-03-31
- **容量**: 7 pts

## Stories

| # | Story | Issue | Points | Status | Assignee |
|---|-------|-------|--------|--------|----------|
| 1 | feat: Sprint Review 邊界案例測試自動化（test-sprint-review-boundary.sh） | #732 | 1 | DONE(#761) | Developer |
| 2 | feat: ADR 目錄索引自動維護（docs/adr/README.md 自動更新） | #742 | 1 | DONE(#762) | Developer |
| 3 | feat: Sprint Planning 會議紀錄模板標準化（templates/sprint-planning-meeting.md） | #744 | 1 | TODO | Developer |
| 4 | feat: Sprint Review 指標收集平行化（Analytics + SPACE + Quality Observer 同步執行） | #709 | 3 | TODO | Developer |
| 5 | feat: ADR-039 Model Routing 準確率追蹤 Dashboard | #711 | 1 | TODO | Developer |

**Total: 7 pts**

## 技術評估（Architect）

| Story | T-shirt | ADR 需求 | API 契約 | Related SDDs | Story Type | 說明 |
|-------|---------|---------|---------|-------------|------------|------|
| #732 | S | 無需 ADR | 不適用 | — | FEATURE+INFRA | 新建 `tests/test-sprint-review-boundary.sh`（純本地 shell 測試）+ 整合 `.github/workflows/` CI；SRE 工作量極小（workflow append），不拆分 |
| #742 | S | 無需 ADR | 不適用 | — | FEATURE | 新建 `scripts/update-adr-index.sh` + `docs/adr/README.md`；`story-lifecycle-prompt.md` 新增觸發語句 |
| #744 | S | 無需 ADR | 不適用 | — | FEATURE | 新建 `templates/sprint-planning-meeting.md`；修改 `skills/sprint-planning/references/commit-and-trigger.md` + `po-prompt.md` |
| #709 | M | 無需 ADR | 不適用 | — | FEATURE | 重構 `skills/sprint-review/SKILL.md` 指標收集段落（Task tool 並行調度）；SHIKIGAMI_MAX_PARALLEL=2 OOM 防護已在 AC5/NFR3 明確 |
| #711 | S | 無需 ADR | 不適用 | — | FEATURE | 新建 `scripts/routing-stats.sh` + `docs/km/model-routing-dashboard.md`；AC4 需修改 `skills/sprint-review/SKILL.md`（依賴 #709 先行）|

## Refinement 結果

- **#732, #742, #744, #711**：Refinement 豁免（S-size）
- **#709**（M-size）：READY — Q1 無前置依賴，Q2 #711 依賴本 Story，Q3 無跨 Type 拆分需求，Q4 Contract Owner（Architect）已確認，Q5 單 Sprint 可完成

## QA 驗收確認

| Story | AC 完整性 | Path Verification | SDD 引用 | 結論 |
|-------|----------|-------------------|---------|------|
| #732 | PASS | N/A | 跳過（Related SDDs=—）| APPROVED |
| #742 | PASS | PASS（docs/adr/ 存在）| 跳過（Related SDDs=—）| APPROVED |
| #744 | PASS | PASS（commit-and-trigger.md, po-prompt.md 存在）| 跳過（Related SDDs=—）| APPROVED |
| #709 | PASS | PASS（skills/sprint-review/SKILL.md 存在）| 跳過（Related SDDs=—）| APPROVED |
| #711 | PASS | PASS（docs/sprints/ 存在）| 跳過（Related SDDs=—）| APPROVED |

## 執行順序（Parallel Grouping）

> SHIKIGAMI_MAX_PARALLEL 未設定，預設視為 2（CLAUDE.md §12）。

**Batch 1（同時執行，最多 2）**：
- #732（1pt, S）— `tests/test-sprint-review-boundary.sh` + CI workflow
- #742（1pt, S）— `scripts/update-adr-index.sh` + `docs/adr/README.md`

**Batch 2（Batch 1 完成後，最多 2）**：
- #744（1pt, S）— `templates/sprint-planning-meeting.md` + sprint-planning refs

**Phase 2 — 序列執行（sprint-review/SKILL.md 衝突）**：
- #709（3pt, M）— 先執行，重構 `skills/sprint-review/SKILL.md`
- #711（1pt, S）— #709 完成後執行，AC4 同修改 `skills/sprint-review/SKILL.md`

**檔案衝突分析**：

| 衝突檔案 | 涉及 Story | 建議執行順序 | 矩陣依據 |
|---------|-----------|------------|---------|
| `skills/sprint-review/SKILL.md` | #709, #711 | #709 → #711 | parallel-safety-matrix.md §1：相同 skill 子目錄 = NO |

## Schema Contracts（ADR-036 Schema 先行）

本 Sprint 所有 Story 為腳本/文件/SKILL 流程類，不涉及 Agent-to-Agent 資料交換或 HTTP REST API，無需產出 Schema Contract。
