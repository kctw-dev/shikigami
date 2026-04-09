# Sprint 181

**Sprint Goal：以外部機械性驗證取代 agent 自我回報 — 雙層 PR 存在性防護（主 session inline + 獨立 step subagent）封堵 #953 類 process violation，自動化 prompt 規則佔比監控**

**開始日期**：2026-04-09
**結束日期**：2026-04-16
**容量**：6 pts
**Velocity 基準**：avg 6 pts（Sprint 178=6, Sprint 179=6, Sprint 180=6）

---

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 | 負責 | Routing Tier |
|-------|-------|------|--------|------|------|-------------|
| post-execution PR 強制驗證（L1 主 session inline） | #989 | S-M | 2 | TODO | — | sonnet（Score 6, PROCESS） |
| ADR-045 Phase 2 — delivery-completion-check step subagent（L2 獨立 agent） | #988 | M-L | 3 | TODO | — | sonnet（Score 9, PROCESS+ARCH） |
| rule-ratio-measure.sh 整合到 dispatch 流程（preflight hook） | #990 | S | 1 | TODO | — | haiku（Score 5, PROCESS+TEST） |

**總計**：3 Stories / 6 pts

---

## 驗收標準摘要

### #989 post-execution PR 強制驗證（L1 主 session inline）

**背景**：Sprint 180 #953 process violation — haiku subagent 直推 main，自圓其說「純文件不需 PR」。現有 SKILL.md §3 line 418-425 已有「PR 存在性驗證」描述，但為流程圖語意，主 session 不會真正執行。

**AC-1：SKILL.md 加入 [MANDATORY] 驗證區塊**
- 修改 `skills/sprint-execution/SKILL.md` §3 line 418-425 區塊
- 從「流程圖語意」升級為主 session 必須執行的 bash 指令
- 加入 `[MANDATORY]` 標記，納入 §5 Hard Gates
- 指令模板：
  ```bash
  STORY_ID="${story_id}"
  BRANCH="${branch_name:-$(echo "${story_id}" | sed 's/^#//' | xargs -I{} echo "story-{}")}"
  PR_JSON=$(gh pr list --head "${BRANCH}" --state open --json number,state,baseRefName,url,headRefOid 2>/dev/null || echo "[]")
  PR_COUNT=$(echo "${PR_JSON}" | jq 'length')
  ```

**AC-2：明確升級動作矩陣（取代「升級路徑」軟性描述）**
- `PR_COUNT == 0` → 輸出 `[POST-EXEC-PR-MISSING]` + 拒絕接受 STATUS=PASS + 標記 Story=BLOCKED + 主 session 直接暫停 Sprint Execution（不自動補派、不自動建 PR、不自動 merge）
- `PR_COUNT >= 1 且 baseRefName != "main"` → 輸出 `[POST-EXEC-PR-WRONG-BASE]` + 拒絕 PASS + BLOCKED
- `PR_COUNT >= 1 且 state != "OPEN"` → 輸出 `[POST-EXEC-PR-NOT-OPEN]` + 拒絕 PASS
- `PR_COUNT == 1 且 state == "OPEN" 且 baseRefName == "main"` → PASS

**AC-3：測試規範（明確檔案 + 斷言）**
- 新建 `tests/test-post-execution-pr-verify.sh`
- 必含 3 個測試：
  - TC1：mock gh 回傳空陣列 → 斷言 exit code != 0
  - TC2：mock gh 回傳 baseRefName="feature/xxx" → 斷言 exit code != 0
  - TC3：mock gh 回傳 baseRefName="main" state="OPEN" → 斷言 exit code == 0
- 用 TMPBIN + fake binary 模擬 gh（參考 Sprint 180 #953 建立的指南）

**AC-4：邊界情況規則**
- 多 PR 匹配（PR_COUNT > 1）：取 base=main + state=OPEN 的第一個，若全部不符視為 PR_MISSING
- Story ID 搜尋：不用 `--search`（容易誤匹配），固定用 `--head <branch>`

---

### #988 ADR-045 Phase 2 — delivery-completion-check step subagent（L2 獨立 agent）

**背景**：Sprint 180 #953 haiku subagent 直推 main，自報 STATUS=PASS 時沒人能獨立驗證。Sprint 181 #989 建立 L1 主 session inline 驗證層。本 Story（#988）建立 L2 獨立 step subagent 驗證層。

**AC-1：明確的插入點時機**
- 插入於 SKILL.md §3 line 418 區塊
- 順序：`haiku subagent 回傳 STATUS=PASS → #989 L1 inline bash 驗證（先跑） → 通過後 → #988 L2 step subagent 派遣 → 通過後 → 標記 Story DONE`
- 若 L1 已 BLOCKED，不派遣 L2（節省資源 + 避免雙重升級）

**AC-2：Step subagent prompt template 結構**
- 新建 `skills/sprint-execution/steps/delivery-completion-check.md`
- 遵循 step-subagent-contract.md §1 四區塊結構：
  - `## 規則片段`：明確列出 5 條禁令（不可 git push / gh pr create / gh pr merge / 不可代建 PR / 不可接受「doc-only 無需 PR」自圓其說）
  - `## 輸入契約`：Story ID、branch name、claimed PR_URL
  - `## 輸出契約`：result JSON 檔案路徑
  - `## 成功/失敗判定`：明確的三態（completed / failed / escalate）
- 規則佔比必須 >= 30%（用 rule-ratio-measure.sh 驗證，本 story 自舉測試）

**AC-3：硬性 Read-only 約束**
- step subagent prompt 必須明確包含 Read-only 禁令清單
- 禁止執行：`git push`、`gh pr create`、`gh pr merge`、`git commit`、任何檔案修改工具
- 僅允許：`gh pr list`、`git log`、`cat`、讀取 state machine 狀態

**AC-4：Step subagent 流程架構**
- 擴充 `scripts/state-machine/step-subagent-poc.sh` 新增：
  - `generate_prompt_delivery_completion_check <sprint> <story_id> <branch>`
  - `dispatch_delivery_completion_check <story_id>`
- Progress tracker 改用 `docs/cruise-logs/delivery-checks-<date>.jsonl` append-only 格式（不改動 state-machine.sh schema）
- 結果 JSON 遵循 ADR-045 §3：`{ step_name, status, output_artifacts, duration_ms, error }`
- `status` 新增 `escalate` 語意：當偵測 PR claim 與實查不一致（疑似偽造）

**AC-5：Model Routing**
- step subagent 固定使用 haiku（短任務 + 固定 prompt + 高規則佔比）
- 派遣時記錄 `model-route step=delivery-completion-check tier=haiku reason=short-task-high-ratio`

**AC-6：測試規範**
- 新建 `tests/test-delivery-completion-check.sh`
- TC1：正常 Story（PR 存在、base=main）→ 斷言 status=completed
- TC2：#953 情境重放（直推 main 無 PR）→ 斷言 status=failed, error="NO_PR_FOUND"
- TC3：偽造情境（claimed_pr_url 與實查不符）→ 斷言 status=escalate, error="PR_MISMATCH_SUSPECTED_FABRICATION"

**AC-7：step-subagent-contract.md 更新**
- 在 §4「目前實作的 Step Subagents」新增 `delivery-completion-check` 條目
- 記錄 Phase 2 落地決策

---

### #990 rule-ratio-measure.sh 整合到 dispatch 流程（preflight hook）

**背景**：Sprint 180 #983 建立了 `scripts/state-machine/rule-ratio-measure.sh`，可機械化量測 prompt 中規則片段的 token 佔比。但這個工具只是存在，沒有自動整合到派遣流程。#953 事件的 prompt 規則佔比可能嚴重不足，但沒人量測過。

**AC-1：Preflight Hook 插入點**
- 修改 `skills/sprint-execution/SKILL.md` §3 line 398「派遣 Story-Lifecycle subagent」節點之前
- 加入 preflight bash 區塊（[MANDATORY]）
- 量測對象：dispatch 時實際送給 subagent 的 full prompt（主 session 組裝後的完整文字，不是 SKILL.md body）

**AC-2：三段式硬性門檻（取代「考慮阻斷」軟性字樣）**
- `ratio >= 0.10` → PASS，繼續派遣
- `0.05 <= ratio < 0.10` → WARN，記錄告警，繼續派遣
- `ratio < 0.05` → BLOCK，直接拒絕派遣（exit 非零），要求人工檢查 prompt

**AC-3：Fail-safe 約束**
- 若 `rule-ratio-measure.sh` 不存在或執行失敗 → BLOCK（fail-safe，不得 silent skip）
- 理由：工具失效時不能假設 prompt 品質 OK

**AC-4：記錄 Schema（明確 JSONL）**
- 每次派遣記錄到 `docs/cruise-logs/dispatch-rule-ratio-<date>.jsonl`
- Schema：
  ```json
  {
    "timestamp": "ISO-8601",
    "story_id": "#N",
    "prompt_size_chars": N,
    "rule_tokens": N,
    "total_tokens": N,
    "ratio": 0.xx,
    "threshold": "PASS|WARN|BLOCK",
    "action": "continue|block"
  }
  ```

**AC-5：ADR-045 補寫三段式門檻章節**
- 在 ADR-045 新增「§ Rule Ratio 門檻定義」子章節
- 記錄三段式門檻（0.10 / 0.05）的選定理由
- 非條件式（移除原 AC-3「若目前文件未包含」的軟性字樣）

**AC-6：整合測試（含 fixtures）**
- 新建 `tests/fixtures/low-ratio-prompt.txt`（規則佔比 < 0.05）
- 新建 `tests/fixtures/warn-ratio-prompt.txt`（規則佔比 0.06）
- 擴充 `tests/test-rule-ratio-measure.sh`（或新建 `tests/test-dispatch-preflight.sh`）
- TC1：low-ratio fixture → 斷言 exit code != 0（BLOCK）
- TC2：warn-ratio fixture → 斷言 exit code == 0 但 stderr 含 WARN
- TC3：正常 story-lifecycle-prompt.md → 斷言 exit code == 0 且 ratio >= 0.10

---

## 技術評估摘要

| Story | T-shirt | ADR | Schema Contract | Related SDDs | 平行分群 |
|-------|---------|-----|----------------|-------------|---------|
| #989 | S-M | 不需新 ADR（直接強化現有 SKILL.md） | 無 | SKILL.md §3/§5 | Wave 1（獨占） |
| #988 | M-L | ADR-045 Phase 2（延續） | delivery-completion-check 結果 JSON 契約 | ADR-045, step-subagent-contract.md | Wave 2（獨占） |
| #990 | S | ADR-045 補節（Rule Ratio 門檻） | dispatch-rule-ratio JSONL schema | ADR-045 | Wave 2 或 Wave 3 |

### Wave 規劃說明

- **Wave 1（獨占）**：#989 — 修改 `skills/sprint-execution/SKILL.md` §3/§5（coordinator-only 檔案），需獨占避免衝突。
- **Wave 2（獨占）**：#988 — 同樣修改 SKILL.md §3 line 418 區塊，與 #989 順序執行（L1 先、L2 後），避免 coordinator-only 衝突。#990 若範圍不重疊可於 Wave 2 平行，否則排 Wave 3。
- **Wave 3**：#990 — SKILL.md §3 line 398 修改，若 Wave 2 已釋出可接續進行。

## 平行分群

> **SHIKIGAMI_MAX_PARALLEL=2**

**Wave 1（獨占）**：#989 (sonnet)
**Wave 2（獨占）**：#988 (sonnet)
**Wave 3**：#990 (haiku)

> 注意：#989 和 #988 均修改 SKILL.md §3，為避免 merge conflict，嚴格序列執行（Wave 1 → Wave 2）。

## Risk Notes

- **#953 事件驅動**：Sprint 180 haiku subagent 直推 main（commit 4de02fb），自圓其說「純文件 Story 無需 PR 流程」，觸發 PROCESS-VIOLATION。本 Sprint 3 個 Story 均直接針對此事件的系統性防護。
- **雙層防禦策略（L1 + L2 互補）**：
  - #989（L1 inline）：主 session 快速止血，不派 subagent，直接 bash 驗證
  - #988（L2 subagent）：獨立 short-lived Claude 實例，context 完全隔離，無自圓其說空間
  - 兩層互補：L1 通過才派 L2，L1 若 BLOCKED 則 L2 不派（資源保護）
- **#990 preflight fail-safe 原則**：`rule-ratio-measure.sh` 若工具失效 → BLOCK 而非 skip，工具失效不等於 prompt 品質 OK
- **SKILL.md 獨占衝突風險**：#989、#988、#990 均涉及 SKILL.md §3，三個 Story 嚴格排序執行，禁止平行 worktree 同時修改
- **AC 硬化確認**：所有 3 個 issue 的 AC 已由 QA 審查完成，移除所有軟性字樣（「考慮」、「建議」等），確立明確閾值與測試檔案名稱

---

## Sprint Review 結果

（待 Sprint 結束後填入）
