# Sprint 161

**Sprint Goal**：強化框架安全性與可觀測性基礎 — Prompt Injection Defense、Review Suggestions 追蹤台帳、Scrum Master 狀態圖、版本 bump ROADMAP 同步強制驗證、Shell Test 最佳實踐統一

- **開始日期**：2026-03-25
- **容量**：7 pts

## Sprint Backlog

| # | Story | Issue | Points | Status | Assignee |
|---|-------|-------|--------|--------|----------|
| 1 | feat: Prompt Injection Defense — Security Gate 外部輸入掃描（pipeline 前置防護） | #776 | 3 | DONE (#812) | Developer |
| 2 | feat: Review Suggestions 追蹤 — 非阻塞建議跨 Sprint 模式識別台帳 | #799 | 1 | DONE (#813) | Developer |
| 3 | docs: Scrum Master 狀態圖 — Sprint 生命週期路由可視化（Mermaid stateDiagram） | #796 | 1 | TODO | Developer |
| 4 | retro: 版本 bump checklist — ROADMAP.md 版號同步強制驗證 | #810 | 1 | TODO | Developer |
| 5 | retro: shell test 腳本最佳實踐 — 禁用 set -e + 統一 counter 模式 | #811 | 1 | TODO | Developer |

**Total: 7 pts**

## 技術評估（Architect）

| Story | T-shirt | ADR 需求 | API 契約 | Related SDDs | Story Type | Refinement | 說明 |
|-------|---------|---------|---------|-------------|------------|-----------|------|
| #776 | M | 無需新 ADR（延伸 ADR-006 Accepted） | 不適用 | — | SECURITY | READY | 新建 `scripts/injection-scan.sh`、`docs/security/INJECTION_RULES.md`、`tests/test-injection-scan.sh`；修改 `skills/sprint-execution/SKILL.md` §3 pre-flight 注入掃描 |
| #799 | S | 無需 ADR | 不適用 | — | FEATURE | READY | 新建 `docs/km/review-suggestions.md`、`scripts/review-suggestion-audit.sh`；修改 `skills/sprint-execution/story-lifecycle-prompt.md` SUGGESTION 記錄步驟；新建 `tests/test-review-suggestions.sh` |
| #796 | S | 無需 ADR | 不適用 | SDD-000 §sprint lifecycle | FEATURE | READY（見注意事項）| AC1 path 說明：`docs/sdd/scrum-master-state-graph.md` 已存在，Developer 應更新現有檔案而非新建 `docs/sdd/scrum-state-graph.md`（避免重複）；修改 `agents/scrum-master.md` 或 `skills/scrum-master/SKILL.md` 引用 SDD |
| #810 | S | 無需 ADR | 不適用 | — | INFRA | READY | 修改 `scripts/validate-version.sh` 增加 ROADMAP 版號一致性檢查；修改 `docs/prd/ROADMAP.md` 版號欄位；驗證 Sprint Review §1.5 硬性檢查通過 |
| #811 | S | 無需 ADR | 不適用 | — | FEATURE | READY | 修改 `skills/qa-engineer/SKILL.md` 增加 shell test 最佳實踐段落；新建 `templates/test-template.sh`；修改 `tests/*.sh` 統一使用 `$((VAR+1))` 模式（掃描並修正所有 `((VAR++))` 殘留）|

**平行分群**：所有 5 個 Stories 修改不同主要檔案，可完全平行執行。
- Group A（並行）：#776, #799, #796, #810, #811

**ADR 預偵測**：[ADR-NEXT] ADR-044 可用。本 Sprint 無需新建 ADR。

## Refinement 結果

- **#776**（M-size，SECURITY）：READY — ADR-006 已 Accepted，無前置依賴；injection-scan.sh + sprint-execution SKILL.md 前置檢查獨立實作；Contract Owner（Security Engineer / Architect）確認；3pt 估點合理
- **#799**（S-size，FEATURE）：READY — 無前置依賴；SUGGESTION 記錄為 optional 不阻塞主流程；1pt 可完成
- **#796**（S-size，FEATURE）：READY（Developer 需注意 `scrum-master-state-graph.md` 已存在，優先更新現有文件）；無前置依賴；1pt 可完成
- **#810**（S-size，INFRA）：READY — validate-version.sh 已存在，增量修改；1pt 可完成
- **#811**（S-size，FEATURE）：READY — tests/*.sh 掃描修正為主要工作量，估點 1pt 合理（修正數量有限）

## QA 驗收確認

| Story | AC 完整性 | Path Verification | SDD 引用 | 隱性需求 | 結論 |
|-------|----------|-------------------|---------|---------|------|
| #776 | PASS（AC1-4 可測試）| N/A（新建檔案）| 跳過（Related SDDs=—）| [Major] AC2 中 BLOCK 結果 halt dispatch 需定義 exit code 與 log format（AC4 已含測試涵蓋）| APPROVED |
| #799 | PASS（AC1-4 可測試）| PASS（story-lifecycle-prompt.md 存在）| 跳過（Related SDDs=—）| [Minor] AC2 SUGGESTION 記錄步驟需確保 append-only（不覆蓋既有內容）| APPROVED |
| #796 | PASS（AC1-3 可測試，需補 SDD 一致性 AC）| FAIL→NOTE（AC1 指向 docs/sdd/scrum-state-graph.md，實際應更新 docs/sdd/scrum-master-state-graph.md）| SDD-000 §sprint lifecycle 引用：AC 中缺少 SDD 一致性條件 → Developer 需確認 SDD 符合性 | [Minor] Mermaid 格式需為 agent 可消費（非圖片）| APPROVED（Developer 執行時更新現有 SDD 並確認符合 SDD-000 §sprint lifecycle routing） |
| #810 | PASS（AC1-3 可測試）| PASS（scripts/validate-version.sh 存在）| 跳過（Related SDDs=—）| [Minor] AC2 驗證失敗時的 exit code 需定義（非 0 = 錯誤）| APPROVED |
| #811 | PASS（AC1-3 可測試）| PASS（skills/qa-engineer/SKILL.md, templates/ 存在）| 跳過（Related SDDs=—）| [Minor] AC3 掃描範圍需明確（所有 tests/*.sh 或指定子集）| APPROVED |

## 非功能性需求補充（retro-action Stories）

- **#810**：NFR1: validate-version.sh 執行時間 < 3 秒；NFR2: 驗證失敗時輸出具體的版號不一致說明
- **#811**：NFR1: test-template.sh 為 agent 可消費的示範檔案，含中文說明；NFR2: 修改後既有測試結果不受影響

## Sprint 161 Notes

- #796 Developer 注意：`docs/sdd/scrum-master-state-graph.md` 已存在，評估是否更新現有文件取代建立新文件 `docs/sdd/scrum-state-graph.md`
- #776 為 Sprint 中最大 Story（3pts，M-size），建議最先執行以留充足時間
- 所有 5 個 Stories 可完全平行執行（無檔案衝突）
