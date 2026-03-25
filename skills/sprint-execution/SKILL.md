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
<!-- #712 動態記憶體感知調整機制 — Sprint 153 -->
<!-- #722 parallel-safety 全自動化 — 消除人工決策 — Sprint 154 -->

<HARD-GATE>
**平行 Story-Lifecycle subagent 禁止直接修改 `docs/PROJECT_BOARD.md` 和 `docs/sprints/sprint_N.md`**（競態條件防護）。所有平行 subagent 完成後，主 session 統一批次更新。`SHIKIGAMI_MAX_PARALLEL` 環境變數控制最大平行數量（**預設值 2**，未設定時視為 2，OOM 防護，#536）。派遣前必須：(1) 執行 **Worktree 唯一性檢查**：以 `git worktree list --porcelain` 確認同 Story ID 的 worktree 不存在，若已存在則輸出 `[DISPATCH-SKIP]` 跳過（#537）；(2) **自動執行 memory-aware-dispatch.sh** 取得 FINAL_MAX，超限時輸出 `[OOM-WARN]` 並等待釋放（#536 / #712）。Git Worktree 隔離（`isolation: "worktree"`）消除大部分並發衝突。
</HARD-GATE>

### 自動記憶體感知派遣（#712 / #722）

派遣 subagent 前，**自動**執行 `scripts/memory-aware-dispatch.sh` 取得動態安全並行上限，無需人工決策：

```bash
# 自動派遣決策（無需人工介入）
source scripts/memory-aware-dispatch.sh
FINAL_MAX=$(get_dispatch_decision | jq -r '.final_max')
# FINAL_MAX = min(DYNAMIC_MAX, SHIKIGAMI_MAX_PARALLEL)
# DYNAMIC_MAX = floor(available_mb / 512)
# 若 FINAL_MAX < SHIKIGAMI_MAX_PARALLEL → 自動輸出 [OOM-WARN]，採用 FINAL_MAX
```

| 情境 | 自動行為 |
|------|---------|
| 記憶體充足（available_mb ≥ 512 × N） | 採用靜態上限 N，無警告 |
| 記憶體受限（available_mb < 512 × N） | 自動降級至 FINAL_MAX，輸出 `[OOM-WARN]` |
| 偵測失敗（/proc/meminfo 不可讀等） | 靜默降級至靜態值 2，無警告 |

> 詳見 `references/parallel-safety.md`、`docs/sdd/sdd-004-parallel-execution-auto.md`

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

<!-- #469 Cruise/Sprint 執行時建立 Task List — 防止 compact 後跳步 -->
<!-- #538 Task 命名改為 repo/sprint-N-phase 格式，取代 SESSION_ID 後綴 -->

Sprint Execution 啟動時建立 Task List，以 `{repo}/sprint-{N}-{phase}` 格式命名，記錄三個主要 phase。compact 後查詢 TaskList，以 `{repo}/sprint-{N}-` 為前綴匹配，恢復進度跳過已完成 phase，防止跳步。

> 詳見 `references/checkpoint.md`（含 Task 命名格式、舊 Sprint 殘留清理、compact 恢復流程）

---

## 2.14 Crash Recovery — Side Effect Idempotency Guard（#405 / ADR-041）

<!-- #405 Temporal-style Crash Recovery — Sprint 140 -->

Session crash 後重啟時，Sprint Execution 自動偵測未完成 checkpoint，並透過 Side Effect Log 防止不可逆操作被重複執行。**[RECOVERY-TRIGGER] 條件**：`sprint-checkpoint.json` 存在且有 `status=in-progress` 的 Story。

> 詳見 `references/crash-recovery.md`（Side Effect Guard 使用方式、Recovery 觸發腳本）

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
  +-- 成功 --> 篩出需回覆的 issue
              → **Security Gate 掃描（#393，ADR-006 Security Gate 擴充）**
                規則檔：[`docs/definition/SECURITY_RULES.md`](../../docs/definition/SECURITY_RULES.md)
                |-- HIGH_RISK  → [SECURITY-GATE-HIGH] 暫停，通知 Stakeholder，ESCALATE: SECURITY_CRITICAL
                |-- MEDIUM_RISK → [SECURITY-GATE-MEDIUM] 附 warning 繼續，寫入 trace log
                +-- PASS → 繼續
              → PO 草稿 → QA 審核 → 發布
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
Kill Switch 前置檢查（#783，AC2）
  # 每次 Story dispatch 開始前，檢查 kill-switch sentinel
  # Session ID 來源：$SESSION_ID 環境變數，或 .claude/shikigami.local.md session_id 欄位
  SENTINEL="/tmp/shikigami-kill-${SESSION_ID}.flag"
  if [[ -f "$SENTINEL" ]]; then
    echo "[KILL-SWITCH-ACTIVATED] Kill switch 已啟動，安全停止 Sprint 執行"
    echo "  Sentinel: $SENTINEL"
    echo "  在完成當前 Story 後停止（NFR1：不強制中止已派遣的 subagent）"
    echo "  Active worktrees（NFR2）："
    bash scripts/kill-switch.sh --list "$SESSION_ID" 2>/dev/null || git worktree list 2>/dev/null
    # 寫入 checkpoint 記錄 kill-switch 停止點
    # 然後清潔退出 Sprint Execution
    exit 0
  fi
  |
  v
Sprint Backlog 中取出 Story
  |
  v
Parallel Conflict Prediction 靜態衝突分析（#395，AC1）
  # 取出所有 pending Story 後，靜態比對檔案重疊，分為 Group A（可平行）和 Group B（序列）
  # 輸出 [CONFLICT-PREDICTION] dispatch plan：Group A（平行）| Group B（序列）
  # 詳細分組規則與重評估邏輯：references/conflict-prediction.md
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
派遣 Story-Lifecycle subagent（story-lifecycle-prompt.md）
  Agent tool / Gemini CLI 雙軌派遣
  model: "sonnet" | isolation: "worktree"（#379）
  subagent 內部閉環：TDD → Spec Compliance → Code Quality → Security → PR → merge
  回傳：PASS/FAIL/ESCALATE + MERGED_COMMIT
  （詳細派遣參數與雙軌路徑：references/execution-flow-details.md）
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
  Checkpoint 重讀流程定義（§3.1 / references/execution-flow-details.md）
  輸出 [CHECKPOINT-PASS] 或 [CHECKPOINT-FAIL]
        |
        v
  外部抽樣審查決策（ADR-007 §AC3 Phase 2）
  TC-1: L-size→100%全量；TC-2: 安全相關→100%；TC-3: 前次品質問題→100%；
  TC-4: 連續2次FAIL→100%；其他: 30% 基礎抽樣率（取上整）
  （詳見 references/external-sampling.md）
        |
        +-- 不觸發抽樣 → 更新 PROJECT_BOARD（Story 狀態 → 完成）
        |
        +-- 觸發外部抽樣 → 派遣獨立 QA subagent【model: "sonnet"】
                |-- CONFIRM → 記錄結果，更新 PROJECT_BOARD
                +-- DISPUTE → 執行 DISPUTE 處理流程（見 references/external-review-dispute.md §4.2）
  |
  v（不觸發抽樣 / CONFIRM 完成後匯合）
  Story Completion Checklist（#368 方向3，每個 Story 完成後）
  1. [ ] git checkout main && git pull
  2. [ ] 更新 PROJECT_BOARD.md + sprint_N.md 狀態（以 Issue ID 定位列，取代最後一欄值）；git commit + push（豁免直推 main，ADR-023 決策 3）
  3. [ ] 寫入 sprint-checkpoint.json（§2.12，豁免直推 main）
  4. [ ] release claim：bash hooks/release-issue.sh <id>
  5. [ ] 檢查 Sprint Backlog 是否清空
         |-- 有剩餘 Story → 取出下一個 Story 繼續
         +-- 全部完成 → 立即 invoke shikigami:sprint-review
  ※ 步驟 1-4 任一失敗不阻塞，輸出 WARN 後繼續步驟 5
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

**適用條件**：Story 為 frontend FEATURE（AC 含有 Figma Prototype URL），Code Review 通過後、`gh pr merge` 之前觸發。**跳過條件**：後端 / Infra / DESIGN / RESEARCH Story（AC 或 issue body 中無 Figma Prototype URL），輸出 `[VISUAL-GATE-SKIP]`。

> 詳見 `references/visual-gate.md`（執行流程、判定規則、降級機制）

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

> 詳見 `references/hard-gates-tdd.md`（L-size 審查增強、§8.1 安全審查觸發條件）

---

## 6. DoD 自檢

每個 Story 完成前，Developer 必須逐項檢查 Definition of Done。DoD 條件定義請參照 `skills/scrum-master/SKILL.md` §8。

> DoD checkbox 格式與 §6.1 Checkpoint 檢查項：`references/dod-checklist.md`

---

## 7. Systematic Debugging 觸發指引（CI FAIL / Deploy 後 / Bug 修復後）

以下時機均為**建議，非強制**，觸發方式統一為 `invoke shikigami:systematic-debugging`。

> 詳見 `references/systematic-debugging.md`（觸發時機表：CI FAIL / Deploy 後 / Bug 修復後）

---

## 8. 審查失敗處理

當任一審查階段不通過時：

1. Reviewer 產出具體問題清單（含嚴重度分級）
2. 同一個 Developer subagent 接收問題清單進行修復
3. 修復完成後，重新執行該審查階段
4. 同一審查階段連續失敗 3 次，升級至 Architect 評估是否有設計問題

> L-size Story 審查增強（觸發條件：Story Size = L）與 §8.1 安全審查觸發條件：`references/hard-gates-tdd.md`

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

> 詳見 `references/developer-refinement.md`（職責說明表、Refinement 輸出定義）
