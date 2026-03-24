---
name: sprint-execution
description: "Use when executing sprint stories, implementing features, or working through sprint backlog items"
---

# Sprint Execution — Subagent 驅動開發

## 1. 概述

Sprint 執行的核心 Skill。從 Sprint Backlog 逐個取出 Story，透過 **Subagent 驅動開發模式** 完成實作與審查。

每個 Story 派遣一個全新的 Developer subagent 進行 TDD 開發，完成後經過**雙階段審查**（Spec Compliance + Code Quality）確保品質，最終更新 PROJECT_BOARD 並進入下一個 Story。

---

## 2. 核心原則

**Story-Lifecycle Subagent 封裝 = context 隔離 + 自審閉環 + 高品質迭代**（ADR-007 選項 B）

- **隔離性**：每個 Story 派遣一個全新的 Story-Lifecycle subagent，整個生命週期（Dev + Review + 修復循環）在 subagent 內部閉環，主 session 僅收摘要，避免 context overflow
- **TDD 強制**：所有功能實作必須先寫測試再寫代碼（subagent 內部執行）
- **三階段自審**：Spec Compliance → Code Quality → Security（條件觸發），由 Story-Lifecycle subagent 自審，補償機制見 ADR-007 §AC3
- **小步快跑**：每個小步驟一個 commit，保持可追溯性

---

## 2.1 Provider 路由（多模型派遣）

<!-- US-177 CLI Adapter 簡化 — Sprint 67 -->
<!-- US-180 Developer Provider 路由 Fallback 自動化 — Sprint 69 -->
<!-- US-181 Provider 路由預設值宿主平台偵測 — Sprint 70 -->

Sprint 執行支援**雙軌派遣機制**：由環境變數 `SHIKIGAMI_MODEL_PROVIDER` 和 `SHIKIGAMI_ROLE_PROVIDER_MAP` 控制路由。解析順序：`SHIKIGAMI_ROLE_PROVIDER_MAP[role]` → `SHIKIGAMI_MODEL_PROVIDER` → 宿主平台自動偵測 → `claude`（ultimate fallback）。Gemini CLI 失敗時自動 fallback 至 Claude Agent tool，輸出 `[FALLBACK]` 告警。

> 詳見 `references/provider-routing.md`

---

## 2.2 平行執行安全防護（共用文件保護）

<!-- US-188 平行 subagent 禁止直接修改共用文件 — Sprint 72 -->
<!-- US-255 SHIKIGAMI_MAX_PARALLEL 平行數量上限控制 — Sprint 93 -->
<!-- #537 Worktree 唯一性檢查（重複派遣防護 Gate） — Sprint 129 -->

<HARD-GATE>
**平行 Story-Lifecycle subagent 禁止直接修改 `docs/PROJECT_BOARD.md` 和 `docs/sprints/sprint_N.md`**（競態條件防護）。所有平行 subagent 完成後，主 session 統一批次更新。`SHIKIGAMI_MAX_PARALLEL` 環境變數控制最大平行數量（**預設值 2**，未設定時視為 2，OOM 防護，#536）。派遣前必須：(1) 執行 **Worktree 唯一性檢查**：以 `git worktree list --porcelain` 確認同 Story ID 的 worktree 不存在，若已存在則輸出 `[DISPATCH-SKIP]` 跳過（#537）；(2) 計算現存 worktree 數量，超限時輸出 `[OOM-WARN]` 並等待釋放（#536）。Git Worktree 隔離（`isolation: "worktree"`）消除大部分並發衝突。
</HARD-GATE>

> 詳見 `references/parallel-safety.md`

---

## 2.8 Sprint 開始時 API 文件版本驗證（US-221）

<!-- US-221 知識老化偵測 — Sprint 84 -->

Sprint Execution 第一個 Story 取出之前，自動驗證已內化的關鍵 API 文件版本新鮮度（知識老化偵測「事件觸發」層）。HIGH 優先條目 FRESH（≤30 天）→ `[KS-PASS]`；STALE（31–90 天）→ `[KS-WARN]` 不阻塞；EXPIRED（>90 天）→ `[KS-FAIL]` 要求確認。檔案不存在則 `[KS-SKIP]` 靜默略過。

> 詳見 `references/knowledge-staleness.md`

---

## 2.9 合約載入（US-204）

<!-- US-204 統一合約位置 — Sprint 82 -->

Sprint Execution 開始前，依 Story AC 載入相關共用交付合約：

| 情境 | 須載入的合約 |
|------|------------|
| Story AC 涉及 SOW 文件建立或審查 | `contracts/sow-delivery-contract.md` |
| Story AC 涉及 Metrics、Points、Velocity 等數值修改 | `contracts/numerical-consistency-contract.md` |
| 不確定適用哪份合約 | 先讀取 `contracts/README.md` 查閱合約清單 |

合約載入為 Story 實作前的必要步驟（取出 AC 後、開始 TDD 前執行）。若合約與 AC 有衝突，以 AC 為準。

---

## 2.10 前端 Story 設計資訊 Pre-check（US-244）

<!-- US-244 前端 Story 設計資訊 Gate — Sprint 88 -->

取出 FEATURE type Story 後，若識別為前端 Story（AC 含 UI 元件詞語、前端技術詞語、或標題含前端意圖），執行設計資訊 Pre-check：確認 Design Spec / Figma Prototype / Design Token / 凍結 DESIGN Contract 至少一項存在。缺失時輸出 `[FE-PRECHECK-WARN]`（不阻塞），標記「需 UIUX 介入」。

> 詳見 `references/frontend-precheck.md`

---

## 2.11 多 Session 並行協調 — Claim/Release 機制（US-312）

<!-- US-312 多 Session 並行開發 Issue/Story 級別協調機制 — Sprint 101 -->

三層協調防止多 session 重複領取 Story：本地 `flock` + 遠端 `git push refs/claims/<id>` + GitHub Issue assignee/label 展示層。`[CLAIM-OK]` → 繼續；`[CLAIM-BLOCKED]` → 跳至下一 Story；SessionEnd hook 自動 release。

> 詳見 `references/claim-release.md`

---

## 2.12 Sprint 進度 Checkpoint（US-313）

<!-- US-313 Sprint 進度 Checkpoint 機制 — Sprint 102 -->

每個 Story 完成後，主 session 自動寫入 `docs/sprints/sprint-checkpoint.json`（狀態文件豁免，允許直推 main，ADR-023 決策 4）。寫入失敗靜默略過（`[CHECKPOINT-WRITE-WARN]`），不阻塞主流程。

> 詳見 `references/checkpoint.md`

---

## 2.13 Sprint Task List — compact 後進度恢復（#469 / #538）

<HARD-GATE>
**Task List 強制建立（#538 AC7）**：Sprint Execution 啟動時，必須為每個 in-sprint Story 建立對應 Task（格式：`{repo}/sprint-{N}-execution`）。若 TaskList 中缺失本 Sprint 的 Task，必須立即補建再繼續。任何跳過 Task 建立的行為均屬流程違規。hook 腳本 `hooks/task-gate.sh` 可協助驗證（Sprint Execution 啟動時自動呼叫）。
</HARD-GATE>

<!-- 以下為 §2.13 正文，接原標題 -->

<!-- #469 Cruise/Sprint 執行時建立 Task List — 防止 compact 後跳步 -->
<!-- #538 Task 命名改為 repo/sprint-N-phase 格式，取代 SESSION_ID 後綴 -->

Sprint Execution 啟動時建立 Task List，以 `{repo}/sprint-{N}-{phase}` 格式命名，記錄三個主要 phase。compact 後查詢 TaskList，以 `{repo}/sprint-{N}-` 為前綴匹配，恢復進度跳過已完成 phase，防止跳步。

**Task 命名格式（#538 AC2）**：`{repo}/sprint-{N}-{phase}`

其中 `{repo}` = 從 `git remote get-url origin` 解析的 `owner/repo`（如 `kctw-dev/shikigami`），`{N}` = Sprint 編號（從 sprint_N.md 讀取），`{phase}` = `planning` | `execution` | `review`。

**命名範例**：
- `kctw-dev/shikigami/sprint-129-planning`
- `kctw-dev/shikigami/sprint-129-execution`
- `kctw-dev/shikigami/sprint-129-review`

> 詳見 `references/checkpoint.md`

---

## 3. 執行流程

```
Task List 初始化（§2.13，#469 AC1/AC3，#538 AC2）
  # Sprint 啟動時建立 Task List，記錄三個主要 phase
  # 從 git remote 解析 OWNER_REPO（如 kctw-dev/shikigami）
  OWNER_REPO=$(git remote get-url origin | sed -E 's#^(https?://[^/]+/|git@[^:]+:)##; s#\.git$##')
  # 從 sprint_N.md 讀取 SPRINT_NUM
  SPRINT_NUM=<N>  # 從 sprint file 路徑解析

  # 清理舊 Sprint 殘留 Task（#538 AC5）
  # 若 TaskList 中存在前一 Sprint 的 Task（status 非 completed），標記為 completed
  OLD_SPRINT_TASKS=$(TaskList | filter subject starts_with "${OWNER_REPO}/sprint-" AND subject NOT contains "/sprint-${SPRINT_NUM}-" AND status != "completed")
  for OLD_TASK in OLD_SPRINT_TASKS:
    TaskUpdate id=OLD_TASK.id status="completed"

  TaskCreate tasks：
    - "${OWNER_REPO}/sprint-${SPRINT_NUM}-planning"   status=pending
    - "${OWNER_REPO}/sprint-${SPRINT_NUM}-execution"  status=pending
    - "${OWNER_REPO}/sprint-${SPRINT_NUM}-review"     status=pending
  # compact 後恢復進度（#538 AC4）：以 "{repo}/sprint-{N}-" 為前綴查詢 TaskList，從第一個非 completed 的 task 繼續
  |
  v
# ── Task List 狀態更新：sprint-execution 開始（#469 AC2）──
TaskUpdate id="${OWNER_REPO}/sprint-${SPRINT_NUM}-execution" status=in-progress
  |
  v
Sprint Checkpoint 偵測（AC-2 斷點續跑，§2.12）
  |-- docs/sprints/sprint-checkpoint.json 不存在
  |     → [CHECKPOINT-NEW] 正常開始（無先前 checkpoint）
  |-- 存在且所有 Story status = "completed"
  |     → [CHECKPOINT-DONE] 所有 Story 已完成，觸發 sprint-review
  +-- 存在且有未完成 Story（status = "in-progress" 或 "pending"）
        → [CHECKPOINT-RESUME] 偵測到未完成 checkpoint，從斷點繼續
        → 跳過所有 status = "completed" 的 Story（已完成，不重做）
  |
  v
Issue 快掃（gh issue list --state open --limit 10）
  |-- gh 失敗 --> 靜默略過，繼續下一步（不阻塞）
  +-- 成功 --> 篩出需回覆的 issue → PO 草稿 → QA 審核 → 發布
  |
  v
CI 狀態快掃（gh run list --limit 3 --json name,status,conclusion,url）
  |-- gh 失敗 / UNKNOWN --> 靜默略過，繼續下一步（不阻塞）
  |-- CI PASS --> 繼續執行
  +-- CI FAIL --> 輸出 [CI-SOFT-GATE]（含 workflow 名稱與 run URL），要求確認是否繼續
        |-- 使用者確認繼續 --> 繼續 Story 開發
        |-- 同一 workflow 連續 3 次 FAIL --> 升級為 Hard Gate，阻塞 Story 開發
        +-- 使用者拒絕繼續 --> 中止本次 Sprint 執行，等待 CI 修復
  |
  v
API 文件版本驗證（§2.8，知識老化偵測事件觸發層）
  |-- [KS-SKIP] 檔案不存在或讀取失敗 --> 靜默略過，繼續執行（不阻塞）
  |-- [KS-PASS] 所有 HIGH 條目均 FRESH --> 繼續執行
  |-- [KS-WARN] 有 STALE 條目 --> 輸出告警，繼續執行（不阻塞）
  +-- [KS-FAIL] 有 EXPIRED 條目 --> 要求確認是否繼續
  |
  v
Sprint Backlog 中取出 Story
  |
  v
前端 Story 設計資訊 Pre-check（§2.10，story_type=FEATURE 時）
  |-- [FE-PRECHECK-SKIP] 非前端 Story --> 繼續執行
  |-- [FE-PRECHECK-PASS] 設計資訊完整 --> 繼續執行
  +-- [FE-PRECHECK-WARN] 設計資訊缺失 --> 輸出告警，標記「需 UIUX 介入」，繼續執行
  |
  v
Worktree 唯一性檢查（§2.2，重複派遣防護，#537）
  git worktree list --porcelain | grep -E "branch refs/heads/sprint-[0-9]+/${story_id}-"
  |-- 找到對應 worktree → [DISPATCH-SKIP] 跳過此 Story，取出下一個 Story 繼續
  |-- git worktree 指令失敗 → 靜默忽略，繼續執行（不阻塞）
  +-- 未找到 → 繼續 OOM 上限檢查與 Claim 流程
  |
  v
Claim Story（§2.11，多 Session 並行協調）
  bash hooks/claim-issue.sh <story_id>
  |-- [CLAIM-OK]      --> 繼續執行（已取得 story 鎖）
  |-- [CLAIM-BLOCKED] --> 輸出告警，跳至下一個 Story（本 Story 由他人執行）
  +-- git push 失敗   --> 輸出 [WARN]，繼續執行（保守策略：不阻塞）
  |
  v
  ┌─────────────────────────────────────────────────────────────┐
  │  派遣 Story-Lifecycle subagent（story-lifecycle-prompt.md）  │
  │                                                             │
  │  Agent tool 派遣參數：                                       │
  │    subagent_type: "general-purpose"                         │
  │    model: "sonnet"                                          │
  │    isolation: "worktree"  ← 新增（#379）                    │
  │                                                             │
  │  subagent 內部閉環：                                         │
  │  ├─ 讀取 sprint_N.md（AC + 需求）                           │
  │  ├─ git checkout -b sprint-<N>/<story-id>（ADR-023，AC-3）  │
  │  ├─ TDD 開發（Red → Green → Refactor）                      │
  │  ├─ Spec Compliance self-review                             │
  │  │    |-- FAIL --> 修復循環（最多 3 次，內部閉環）            │
  │  │    +-- PASS                                              │
  │  ├─ Code Quality self-review                                │
  │  │    |-- FAIL --> 修復循環（最多 3 次，內部閉環）            │
  │  │    +-- PASS                                              │
  │  ├─ Security self-review（條件觸發）                         │
  │  │    |-- FAIL / ESCALATE --> 升級主 session                │
  │  │    +-- PASS / SKIP                                       │
  │  ├─ git commit + git push -u origin sprint-<N>/<story-id>  │
  │  ├─ gh pr create                                           │
  │  │    |-- gh 不可用 → [PR-FLOW-DEGRADED] 降級直推            │
  │  ├─ Code Review Loop（ADR-023 決策 5，pr-review-toolkit）   │
  │  │    |-- LGTM（無 CRITICAL/HIGH）→ gh pr merge --squash    │
  │  │    +-- CRITICAL/HIGH → 修復循環（最多 3 輪）              │
  │  │          |-- 3 輪後仍 CRITICAL/HIGH → [PR-REVIEW-ESCALATE]│
  │  │          +-- 通過 → gh pr merge --squash --delete-branch  │
  │  └─ 回傳：PASS/FAIL/ESCALATE + MERGED_COMMIT               │
  └─────────────────────────────────────────────────────────────┘
  |
  v
接收 Story-Lifecycle subagent 回傳
  |-- context 中無回傳結果（context compaction 導致丟失）
  |     → [CACHE-RECOVERY] 掃描 docs/sprints/subagent-results/{story_id}.md
  |           |-- 檔案存在 → 讀取暫存結果，繼續處置（輸出 [CACHE-RECOVERY-OK]）
  |           +-- 檔案不存在 → 輸出 [CACHE-RECOVERY-FAIL]，視同 ESCALATE: CONTEXT_OVERFLOW
  |-- ESCALATE --> 依升級類型處置（見 references/execution-flow-details.md 升級表）
  |-- FAIL     --> 記錄失敗原因，更新看板，繼續下一 Story
  +-- PASS（含 MERGED_COMMIT）
        |
        v
  ┌─────────────────────────────────────────────────────────────┐
  │  Checkpoint: 重讀流程定義（US-229）                          │
  │  (a) 重讀 §3 完整流程步驟定義                               │
  │  (b) 比對下一步驟是否符合流程定義                            │
  │  (c) 記錄 [CHECKPOINT-PASS] 或 [CHECKPOINT-FAIL]           │
  │  詳見 references/execution-flow-details.md §3.1            │
  └─────────────────────────────────────────────────────────────┘
        |
        v
  ┌─────────────────────────────────────────────────────────────┐
  │  外部抽樣審查決策（ADR-007 §AC3 Phase 2）                    │
  │  TC-1：L-size → 100%全量；TC-2：安全相關→100%；             │
  │  TC-3：前次品質問題→100%；TC-4：連續2次FAIL→100%；          │
  │  其他：30% 基礎抽樣率（取上整）                              │
  └─────────────────────────────────────────────────────────────┘
        |
        +-- 不觸發抽樣 → 更新 PROJECT_BOARD（Story 狀態 → 完成）
        |
        +-- 觸發外部抽樣 → 派遣獨立 QA subagent【model: "sonnet"】
                |-- CONFIRM → 記錄結果，更新 PROJECT_BOARD
                +-- DISPUTE → 執行 DISPUTE 處理流程（見 references/external-review-dispute.md §4.2）
  |
  v（不觸發抽樣 / CONFIRM 完成後匯合）
  ┌─────────────────────────────────────────────────────────────┐
  │  Story Completion Checklist（#368 方向3，每個 Story 完成後） │
  │  1. [ ] git checkout main && git pull                       │
  │  2. [ ] 更新 PROJECT_BOARD.md + sprint_N.md 狀態           │
  │         sprint_N.md：每個完成 Story 行尾加 DONE(#PR) 標記  │
  │         git commit + push（豁免直推 main，ADR-023 決策 3）  │
  │  3. [ ] 寫入 sprint-checkpoint.json（§2.12，豁免直推 main）  │
  │  4. [ ] release claim：bash hooks/release-issue.sh <id>    │
  │  5. [ ] 檢查 Sprint Backlog 是否清空                        │
  │         |-- 有剩餘 Story → 取出下一個 Story 繼續            │
  │         +-- 全部完成 → 立即 invoke shikigami:sprint-review  │
  │  ※ 步驟 1-4 任一失敗不阻塞，輸出 WARN 後繼續步驟 5          │
  └─────────────────────────────────────────────────────────────┘
```

> 完整步驟詳解（CI 快掃判定、派遣參數、PR 合併流程、Push Retry、升級類型處置表、Subagent 結果暫存）：`references/execution-flow-details.md`

---

## 4. 外部抽樣審查結果處理（CONFIRM / DISPUTE）

CONFIRM → 記錄抽樣結果，更新品質指標，繼續下一 Story。
DISPUTE → 回退 Story、傳入缺陷清單至 Story-Lifecycle subagent 修復、強制第二輪外部抽樣；第二輪 DISPUTE → 升級至 Architect。Circuit Breaker：連續 3 Sprint DISPUTE 率 > 20% → 通知 Architect + 下 Sprint 全量抽樣。

> 詳見 `references/external-review-dispute.md`

---

## 4.5 DESIGN Type Story 執行路徑（ADR-016）

DESIGN type Story 派遣 UI/UX Designer subagent（非 Developer），走 Vision Critic 自審 + QA Contract Testability Review，輸出 Figma Prototype Contract。TDD 豁免。

> 詳見 `references/design-sprint-rules.md`

---

## 4.6 DESIGN ↔ FEATURE Sprint 內排序規則（ADR-016 OQ-2）

DESIGN Story 優先執行，依賴其 Contract 的 FEATURE Story 須等 Contract 凍結後執行。無依賴的 FEATURE Story 可平行。DESIGN blocker 未解除時依賴 FEATURE Story 禁止進入開發（HARD-GATE）。FAIL 預設方案 A（回流 Backlog）。

> 詳見 `references/design-sprint-rules.md`

---

## 4.7 Delivery Phase 雙 Team 視覺對比 Gate（#385 / ADR-034）

<!-- #385 GAD Delivery Phase 視覺對比 Gate — Sprint 133 -->
<!-- 依賴：ADR-034 browser-automation tool selection（Accepted，PR#560） -->

**適用條件**：Story 為 frontend FEATURE（AC 含有 Figma Prototype URL），Story-Lifecycle subagent 完成 Code Review 通過後、執行 `gh pr merge` 之前觸發。

**跳過條件（AC5）**：後端 / Infra / DESIGN / RESEARCH Story 自動跳過（判斷：AC 或 issue body 中無 Figma Prototype URL）。跳過時輸出 `[VISUAL-GATE-SKIP] 非前端 Story，跳過視覺對比 Gate`。

### 執行流程

```
[VISUAL-GATE-START] story={id} 時間={timestamp}

1. 取得 Figma Prototype URL（從 issue body 或 DESIGN Contract）
   |-- 找不到 URL → [VISUAL-GATE-SKIP] 跳過
   |-- 找到 URL → 繼續

2. Agent B（Vision Critic）執行雙 Team 視覺對比：
   a. 截圖 Agent 實作結果（agent-browser screenshot）
   b. 截圖 Figma Prototype（Figma Export / talk-to-figma）
   c. 呼叫 skills/vision-critic/SKILL.md 執行分數評估

3. 產出結構化差異報告（AC3）：
   - 截圖路徑：/tmp/visual-gate/{story-id}-impl.png + {story-id}-figma.png
   - Vision Critic 分數：{0-100}
   - 差異項目清單：{具體差異描述}
   - 判定：PASS（分數 ≥ 80）/ FAIL（分數 < 80）

4. 判定結果（AC4）：
   |-- PASS（Vision Critic ≥ 80） → [VISUAL-GATE-PASS] 繼續 gh pr merge
   +-- FAIL（Vision Critic < 80） → [VISUAL-GATE-FAIL] 阻擋 merge
         - 輸出具體差異描述（NFR1 要求：包含足夠資訊讓 Developer 定位問題）
         - 差異報告含截圖對比路徑 + 量化分數（NFR2）
         - 通知 Developer 修復後重新觸發
```

**降級（agent-browser 或 talk-to-figma 不可用）**：輸出 `[VISUAL-GATE-DEGRADED] 視覺對比工具不可用，降級為人工確認`，不阻擋 merge，但在 PR description 標記「需人工視覺確認」。

---

## 5. Hard Gates

<HARD-GATE>
每個 Story 必須通過雙階段審查（Spec Compliance + Code Quality）才能標記為完成。
不得跳過任何一個審查階段。

> 歷史案例：Sprint 7 因跳過此步驟列為 Retro Problem（Issue #14），導致品質門禁失效。
</HARD-GATE>

> **Bypass 豁免：** 標記為 `[BYPASS]` 的 Story 豁免雙階段審查。豁免條件與 `skills/scrum-master/SKILL.md` §10.3 Bypass 保護清單對齊——涉及 Framework Document Change、外部 API、安全相關的 Story 不得適用豁免。

<HARD-GATE>
所有功能實作必須遵循 TDD：先寫失敗測試 → 最小實作讓測試通過 → 重構。
例外：標注為 [SPIKE] 的探索性任務可豁免，但進入正式開發時必須補測試。
</HARD-GATE>

Story Type 對 TDD 豁免與 Review 策略的影響（FEATURE 必須 TDD；DESIGN 豁免；INFRA 條件性；SECURITY 強制；INTEGRATION 必須；RESEARCH 豁免）。doc-only Story 優先判定 TDD 豁免，但雙階段 Review 維持必要。

> 詳見 `references/hard-gates-tdd.md`

---

## 6. DoD 自檢

每個 Story 完成前，Developer 必須逐項檢查 Definition of Done。DoD 條件定義請參照 `skills/scrum-master/SKILL.md` §8，以下為執行時 checkbox 格式：

| 層次 | 自檢 |
|------|------|
| 功能：所有 Acceptance Criteria 通過 | [ ] |
| 測試：單元測試 + 整合測試全部通過（0 failed） | [ ] |
| 安全：外部輸入通過安全驗證與去活化處理 | [ ] |
| 文件：設計文件對應章節已更新，代碼含設計文件引用 | [ ] |
| 設定：無硬編碼金鑰，配置透過環境變數管理 | [ ] |
| 度量：Metrics_Log.md 本 Sprint 數據已更新 | [ ] |
| 反回歸：既有測試全部仍然通過 | [ ] |
| 技術債：取捷徑情況已用 `[TECH-DEBT]` 標記並更新 Tech_Debt_Registry.md | [ ] |

### 6.1 執行流程 Checkpoint 檢查項

<!-- US-229 Checkpoint 強制重讀步驟 — Sprint 83 -->

每個 Story-Lifecycle subagent 回傳 PASS 後，主 session 必須完成以下 Checkpoint 相關檢查：

- [ ] **每個 Story-Lifecycle subagent 回傳後，Checkpoint 重讀步驟已執行**：已依 §3.1 三個子動作，重讀 `skills/sprint-execution/SKILL.md` §3 流程定義、比對下一步驟一致性，並輸出 Checkpoint 標記。
- [ ] **Checkpoint 結果已記錄（PASS 或 FAIL + 處置）**：已輸出 `[CHECKPOINT-PASS]` 或 `[CHECKPOINT-FAIL]` 標記（格式見 §3.1.2）；若為 FAIL，已依 §3.1.1 執行對應失敗處置方案並記錄處置結果。

---

## 7. Systematic Debugging 觸發指引（CI FAIL / Deploy 後 / Bug 修復後）

<!-- US-247 Sprint 90 — Deploy 後與 Bug 修復後 systematic debugging 觸發指引 -->
<!-- v0.64.1 patch — 新增 CI FAIL 觸發點 -->

Sprint Execution 流程中，以下時機建議觸發 systematic debugging，確認系統健康並防止回歸。

以下時機均為**建議，非強制**，觸發方式統一為 `invoke shikigami:systematic-debugging`（附上觸發目的與相關資訊）。

| 時機 | 觸發條件 | 目的 | 可省略條件 |
|------|---------|------|-----------|
| **7.0 CI FAIL** | §3 CI 快掃或 §8.2 CI Gate 回傳 FAIL | 根因排查（環境、依賴、隱性回歸） | CI 失敗原因明確（lint/型別錯誤等） |
| **7.1 Deploy 後** | `deployment-readiness` 完成、部署至生產環境後 | Post-deploy health check | 緊急修復可延後至 Sprint Review 前（Sprint Review 前為 HARD-GATE） |
| **7.2 Bug 修復後** | Bug 修復通過 Review 後、下一 Story 前 | 回歸確認 | Bug 範圍小且有明確測試覆蓋 |

---

## 8. 審查失敗處理

當任一審查階段不通過時：

1. Reviewer 產出具體問題清單（含嚴重度分級）
2. 同一個 Developer subagent 接收問題清單進行修復
3. 修復完成後，重新執行該審查階段
4. 同一審查階段連續失敗 3 次，升級至 Architect 評估是否有設計問題

---

### L-size Story 審查增強

**觸發條件**：Story Size = L（3 points）時自動啟用增強審查，以下 checklist 項目為額外必要通過條件。

- [ ] **Architect 設計審查**：L-size Story 實作開始前，Architect 必須確認設計方向（介面定義、模組邊界、資料流），避免大型 Story 因設計問題在後期返工。Developer subagent 需在 prompt 中包含 Architect 確認的設計摘要，方可開始 TDD 循環。
- [ ] **分階段驗收**：將 Story 的 Acceptance Criteria 分為至少 2 個驗收批次（例如：核心路徑為第一批，邊界條件與錯誤處理為第二批），每批 AC 通過 Spec Compliance Review 後，再繼續下一批實作。若任一批次不通過，僅需針對該批次修復，不影響已通過批次。
- [ ] **額外回歸測試掃描**：L-size Story 完成後，除執行新增測試外，必須執行既有測試套件的完整掃描，確認無回歸失敗。掃描結果須明確記錄於 Story 完成 commit message（格式：`全部 N 項測試通過，無回歸`）。

---

## 8.1 安全審查觸發條件

主 session 層級觸發入口：Story-Lifecycle subagent 回傳 `ESCALATE: SECURITY_CRITICAL` 時，暫停 Sprint 執行，觸發 `security-review` Skill。完整觸發條件清單定義於 `skills/sprint-execution/story-lifecycle-prompt.md` §7 Security Self-Review。

---

## 9. 與其他 Skill 的關係

| 情境 | 觸發 |
|------|------|
| 發現需求不清 | 暫停，升級至 PO 釐清 → 回到 sprint-execution |
| 發現需要架構決策 | 暫停，觸發 `architecture-decision` → ADR 定案後回到 sprint-execution |
| 所有 Story 完成 | 觸發 `sprint-review` 進行驗收與回顧 |
| 發現安全問題 | 觸發 `security-review` 進行深度安全審查 |

### 9.1 角色決策指引

Sprint Execution 中各角色的具體決策標準請參閱以下文件：

- **Architect 決策指引**（估點策略、ADR 需求判斷、平行分群策略）：[`skills/architect/SKILL.md`](../architect/SKILL.md)
- **QA Engineer 決策指引**（AC 驗證策略、Spec Compliance review 決策、Code Quality review 策略）：[`skills/qa-engineer/SKILL.md`](../qa-engineer/SKILL.md)

---

<!-- ADR-007 Phase 2 外部抽樣審查機制已於 Sprint 24 US-41 完成實作並通過 QA 驗收，詳見 `docs/adr/ADR-007-story-lifecycle-subagent.md`。 -->

---

## 9.2 Sprint Live Log（演示模式 — US-269）

<!-- US-269 演示模式 Live Log Streaming — Sprint 99 -->

Sprint Execution 支援 Live Log Streaming，讓使用者在另一個 terminal 即時觀看 Story-Lifecycle subagent 工作進度。每個 session 寫入獨立 `.log` 檔案（`logs/live/YYYY-MM-DD-session-<SESSION_ID>.log`）。日誌寫入為可選機制，失敗時靜默忽略，不影響主流程。

> 詳見 `references/live-log.md`

---

## 10. Developer Refinement 職責

<!-- US-203 角色 Refinement 職責定義 — Sprint 77 -->

Developer 在 Refinement 中負責提供技術實作面的輸入，協助 Architect（Refinement Chair）識別實作風險與依賴，確保 Story 進入 Sprint 後不因技術細節阻塞開發。Developer 在 Refinement 中為**諮詢（Consulted）**角色，不主持、不輸出正式報告。

### 職責說明

| 面向 | 職責內容 |
|------|---------|
| **技術可行性回應** | 針對 Architect 在 Q1–Q5 分析中提出的技術問題，提供實作可行性評估 |
| **實作風險識別** | 指出已知的技術限制、潛在邊界條件或可能的實作陷阱 |
| **Story 可拆分性判斷** | 從實作角度建議 Story 是否可合理拆分，或提出拆分邊界建議 |
| **測試覆蓋初評** | 初步評估 AC 中的 `[動態]` 項目是否具備可測試的技術條件 |

### Refinement 輸出

Developer 不產出正式文件，於 Refinement 中提供：技術可行性評估意見（FEASIBLE / CONCERN / BLOCKED）與實作風險備注（由 Architect 記錄於 Refinement 報告）。
