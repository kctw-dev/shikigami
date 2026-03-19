# Sprint 104

**Sprint Goal**：Sprint Git Flow 改為 PR-based — 禁止直推 main，引入 code review 環節提升程式碼品質
**日期**：2026-03-19
**容量**：3 points
**狀態**：進行中

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| FEATURE：Sprint Git Flow 改為 PR-based — 禁止直推 main | #315 | L | 3 | 完成 |

## Acceptance Criteria

### #315 — FEATURE：Sprint Git Flow 改為 PR-based — 禁止直推 main

> **前置條件**：實作前需完成 ADR-023（PR-based Git Flow 技術選型），ADR 狀態需為 Accepted。

**AC-1：ADR 技術選型決議（ADR-023）**
- 產出 ADR-023 文件，決定 PR-based Git Flow 的技術選型
- 決策項目：hook 攔截機制、Sprint 狀態文件豁免策略、code review loop 上限、降級策略
- ADR 狀態為 Accepted

**AC-2：PreToolUse Hook 禁止直推 main**
- hooks.json 新增 PreToolUse matcher，攔截 `git push origin main` / `git push -u origin main` 等直推 main 指令
- 攔截時輸出明確錯誤訊息，引導使用者建立 feature branch
- 允許 `git push origin main` 的例外情況：merge commit 後的 push（由 PR merge flow 觸發）

**AC-3：sprint-execution SKILL.md PR Flow 改造**
- §3 步驟 7（git commit + push）改為：push feature branch → 建立 PR → code review loop → LGTM → merge
- code review 使用 pr-review-toolkit agents（code-reviewer / silent-failure-hunter / comment-analyzer）
- code review loop 上限：最多 3 輪，超過則升級通知

**AC-4：shoot SKILL.md PR Flow 改造**
- 步驟 6 同 AC-3 邏輯
- shoot 模式的 PR title 格式：`shoot: <描述>`

**AC-5：sprint-planning / sprint-review 狀態文件 Git Flow 決策落地**
- 依 ADR-023 決策結果實作（豁免直推 or 也走 PR）
- 若豁免：hook 中設定白名單路徑（docs/sprints/、docs/PROJECT_BOARD.md）
- 若走 PR：相關 Skill 同步改造

**AC-6：checkpoint 機制適配 branch**
- checkpoint 資料新增 branch name 欄位
- resume 時先 checkout 對應 branch 再繼續
- 其他 session 可從 branch 讀取 checkpoint

## 技術評估摘要

### Architect 備注

- **#315**：**需 ADR-023**（PR-based Git Flow 技術選型）。這是 git workflow 架構變更，涉及多個 Skill 的 commit/push 流程改造，影響範圍廣。
- **關鍵決策點**：
  1. Hook 攔截機制：PreToolUse hook 攔截 `git push` 到 main 的模式匹配規則
  2. Sprint 狀態文件豁免策略：PROJECT_BOARD.md / sprint_N.md 是否也走 PR（建議豁免，理由：這些是流程管理文件，非程式碼，且 Planning/Review 流程需要即時更新）
  3. Code review loop 上限：3 輪上限防止無限循環
  4. 降級策略：PR 建立失敗時降級為直推 + WARN
- **影響範圍**：
  - `skills/sprint-execution/SKILL.md` — §3 步驟 7 PR flow
  - `skills/sprint-execution/story-lifecycle-prompt.md` — §8.05 git commit 後的 push 流程
  - `skills/shoot/SKILL.md` — 步驟 6 PR flow
  - `hooks/hooks.json` — 新增 PreToolUse 攔截規則
  - `skills/sprint-planning/po-prompt.md` — Sprint 文件 git push（依 ADR 決策）
  - `skills/sprint-review/SKILL.md` — Review 文件 git push（依 ADR 決策）
  - checkpoint JSON 結構
- **技術可行性**：高 — PreToolUse hook 已有版號檢查先例（hooks.json），`gh pr create` / `gh pr merge` CLI 成熟穩定
- **方法論**：ADR-first + TDD
- **ADR 檢查**：需 ADR-023（新增）
- **Refinement**：READY（ADR 為 Sprint 內第一步）

### 平行分群建議

| Phase | 分群 | Stories / AC | 理由 |
|-------|------|-------------|------|
| Phase 1 | Group A | #315 AC-1（ADR-023） | ADR 撰寫，必須先完成 |
| Phase 2 | Group B | #315 AC-2（Hook）+ AC-3（sprint-execution）+ AC-4（shoot） | 依賴 ADR-023 Accepted，三者可平行 |
| Phase 2 | Group C | #315 AC-5（狀態文件）+ AC-6（checkpoint） | 依賴 ADR-023 決策結果 |

**注意**：AC-2 的 hook 攔截規則需先完成，AC-3/AC-4 的 PR flow 改造才能在正確的防護下開發測試。建議 Phase 2 內 AC-2 略微優先。

## QA 驗收確認摘要

- **#315**：PASS — 6 AC 全數可驗證
  - AC-1：ADR-023 檔案存在且狀態為 Accepted，決策項目完整
  - AC-2：在 main branch 執行 `git push origin main`，驗證 hook 攔截並輸出錯誤訊息；驗證 feature branch push 不被攔截
  - AC-3：模擬 sprint-execution Story 完成流程，驗證 PR 建立 / code review loop / merge 行為
  - AC-4：模擬 shoot 流程，驗證 PR 建立（title 格式正確）/ code review / merge
  - AC-5：依 ADR 決策驗證（豁免：直推不被攔截；走 PR：PR 流程正常）
  - AC-6：驗證 checkpoint JSON 含 branch name；模擬 resume 時 checkout 到正確 branch
- **防漂移基準**：1 Story, 3 pts
