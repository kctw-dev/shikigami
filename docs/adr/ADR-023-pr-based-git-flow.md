# ADR-023：PR-based Git Flow — 從直推 main 遷移至 Pull Request 審查流程

**狀態**：Accepted
**日期**：2026-03-20
**決策者**：Architect（技術選型）+ QA Decision Challenger
**關聯 ADR**：ADR-007（Story Lifecycle Subagent）、ADR-021（pr-review-toolkit 整合）、ADR-022（檔案級鎖定）
**關聯 Issue**：#315（PR-based Git Flow）、#313（Sprint Checkpoint）、#312（Claim 機制）
**觸發來源**：Stakeholder 要求 — 所有 Skill 實作成果應經 PR 審查後才合併至 main，建立 code review 閘門

---

## 背景

### 問題陳述

目前 Shikigami 框架中，shoot（§7 步驟 6）與 sprint-execution（§3 Story-Lifecycle subagent 內部）的 git flow 均為**直接 commit + push 到 main**：

```
實作完成 → git commit → git push origin main
```

這意味著：

1. **無 PR 審查閘門**：所有變更直接進入 main，即使內部有 Spec Compliance / Code Quality / pr-review-toolkit 審查，審查結果不產生 GitHub 上的可追溯記錄
2. **無法利用 GitHub PR 機制**：GitHub 原生的 code review、conversation、change request、approval 等功能完全閒置
3. **多 Session 合併衝突風險**：#312 claim 機制解決了 Story 級互斥，#322 解決了檔案級鎖定，但直推 main 仍可能在 push 時遇到 non-fast-forward reject
4. **審查歷史不可追溯**：pr-review-toolkit 的審查結果只存在於 subagent context 中，session 結束即消失

### 現行 Git Flow

| 流程 | 現行行為 | 問題 |
|------|---------|------|
| shoot §7 步驟 6 | `git commit -m "shoot: <標題>"` → `git push` | 直推 main，無 PR |
| sprint-execution §3 Story-Lifecycle | subagent 內部 commit → 主 session push | 直推 main，無 PR |
| Sprint Planning 狀態文件 | 直接寫入 main | 頻繁小更新，走 PR 過重 |
| Sprint Checkpoint（§2.12） | 寫入 `sprint-checkpoint.json` → commit → push main | 禁止直推後機制中斷 |

---

## 決策問題

是否將 Shikigami 的 git flow 從「直推 main」遷移至「feature branch → PR → code review → merge」，並解決以下六個子問題：

1. 核心 PR 流程設計
2. main branch 保護機制
3. Sprint 狀態文件的 Git Flow
4. Checkpoint Resume 適配
5. Code Review Loop 設計
6. parallel-dispatch 適配

---

## 考慮的選項

### 決策 1：核心 PR 流程

**選定方案：feature branch → PR → review loop → merge**

```
[實作完成]
  → git checkout -b <branch-name>
  → git commit
  → git push -u origin <branch-name>
  → gh pr create --title "<標題>" --body "<審查摘要>"
  → code review loop（pr-review-toolkit agents）
  → LGTM → gh pr merge --squash --delete-branch
  → 回到 main
```

**Branch 命名規則**：

| 場景 | 命名格式 | 範例 |
|------|---------|------|
| Sprint Story | `sprint-<N>/<story-id>` | `sprint-102/US-315` |
| Shoot 任務（有 Issue） | `shoot/<issue-number>` | `shoot/320` |
| Shoot 任務（無 Issue） | `shoot/<短描述>` | `shoot/fix-css-layout` |
| 狀態文件自動 PR | `sprint-<N>/status-update` | `sprint-102/status-update` |

**Merge 策略**：squash merge，保持 main 歷史線性。刪除合併後的 feature branch。

### 決策 2：main branch 保護

**選定方案：PreToolUse hook 攔截直推 main**

在 `hooks/hooks.json` 的 `PreToolUse` 新增攔截規則，偵測 Bash 工具中包含直推 main 的指令：

攔截 pattern：
- `git push origin main`
- `git push origin HEAD:main`
- `git push` （當目前在 main branch 上）

**輸出**：`[MAIN-PROTECT] 禁止直推 main。請建立 feature branch 並透過 PR 合併。`

**豁免清單**（由 hook 腳本檢查）：

| 豁免情境 | 判定條件 | 理由 |
|----------|---------|------|
| 狀態文件直推 | 變更檔案僅限 `docs/sprints/**` 或 `docs/PROJECT_BOARD.md` | 決策 3：狀態文件豁免，允許直推 main |
| Claim/Release ref push | `git push origin refs/claims/` | #312 機制使用 refs，非 main branch |
| git tag push | `git push origin --tags` 或 `git push origin v*` | 版本標籤不走 PR |

### 決策 3：Sprint 狀態文件的 Git Flow

**選定方案：選項 B — 狀態文件豁免，允許直推 main**

涉及檔案：
- `docs/PROJECT_BOARD.md`
- `docs/sprints/sprint_*.md`
- `docs/sprints/Metrics_Log.md`
- `docs/sprints/Retrospective_Log.md`
- `docs/sprints/sprint.live.log`
- `docs/sprints/subagent-results/*.md`
- `docs/sprints/sprint-checkpoint.json`

**理由**：

| 考量 | 分析 |
|------|------|
| 更新頻率 | 每個 Story 完成都會更新，一個 Sprint 可能更新 5-10 次 |
| 內容性質 | 狀態記錄、進度追蹤，非程式碼或框架行為定義 |
| 審查價值 | 低 — 狀態文件內容由流程自動產生，審查不增加品質 |
| 速度影響 | 走 PR 每次增加 branch + PR + merge 開銷，嚴重拖慢 Sprint 節奏 |

**Hook 豁免判定**：commit 只包含 `docs/sprints/**` 或 `docs/PROJECT_BOARD.md` 路徑時，允許直推。

被排除的選項：
- **選項 A（全部走 PR）**：狀態文件每個 Story 完成都更新，走 PR 過重，拖慢 Sprint 節奏
- **選項 C（走 PR 但自動 merge）**：增加 branch + PR 建立開銷，自動 merge 又沒有實質審查，成本高但收益為零

### 決策 4：Checkpoint Resume 適配

**選定方案：維持現行 JSON 檔案機制，歸入狀態文件豁免**

`docs/sprints/sprint-checkpoint.json` 已被決策 3 歸入狀態文件豁免清單，可直推 main。

**理由**：

| 選項 | 評估 |
|------|------|
| (a) git refs（commit message 存 JSON） | 複雜度高，JSON 在 commit message 中不易讀寫，refs 命名空間已被 claim 使用 |
| (b) 固定 branch `checkpoint/sprint-N` | 需額外管理 branch 生命週期，增加複雜度 |
| (c) GitHub Issue comment | 依賴 `gh` API，離線環境不可用 |
| (d) PR description/comment | checkpoint 寫入頻率高，每次建 PR 不合理 |
| **(e) 現行 JSON 檔案** | **已有可運行實作（§2.12），直推豁免解決保護衝突，零遷移成本** |

Checkpoint 機制（§2.12）的現行設計已符合 PR-based flow 需求，只需確保其被歸入狀態文件豁免即可。

### 決策 5：Code Review Loop 設計

**選定方案：pr-review-toolkit 三 agent + LGTM 標準 + loop 上限**

PR 建立後執行 code review loop：

```
[PR 建立]
  → 派遣 pr-review-toolkit 三 agent 審查 PR diff
     ├─ code-reviewer
     ├─ silent-failure-hunter
     └─ comment-analyzer
  → 彙整審查結果
  → 判定 LGTM
     |-- 無 CRITICAL / HIGH → [LGTM] → merge PR
     +-- 有 CRITICAL / HIGH → 修復 → commit → push → 重新審查
           |-- 第 N 輪仍有 CRITICAL/HIGH（N = loop 上限）
           |     → 升級 Architect → 人工介入
           +-- 修復通過 → [LGTM] → merge PR
```

**LGTM 標準**：

| 嚴重度 | 是否阻塞 merge |
|--------|--------------|
| CRITICAL | 阻塞 — 必須修復 |
| HIGH | 阻塞 — 必須修復 |
| MEDIUM | 不阻塞 — 記錄為 tech debt |
| LOW / Info | 不阻塞 — 可選修復 |

**Loop 上限**：**3 輪**。第 3 輪仍存在 CRITICAL/HIGH 時，升級至 Architect 進行人工決策（與 shoot §8.6 和 sprint-execution §4.3 Circuit Breaker 一致）。

**降級策略（pr-review-toolkit 未安裝）**：

- 回退至內部 QA subagent 審查（現行 shoot §8.5 / sprint-execution §5 外部獨立審查機制）
- 輸出 `[PR-REVIEW-DEGRADED] pr-review-toolkit 未安裝，使用內部 QA 審查`
- 內部 QA 審查 PASS 即視為 LGTM

**審查結果記錄**：審查摘要以 `gh pr comment` 寫入 PR conversation，建立可追溯的審查歷史。

### 決策 6：parallel-dispatch 適配

**選定方案：每個 subagent 各自開 branch，主 session 負責 merge 協調**

```
主 session（Sprint Execution §3）
  ├─ Subagent A（Story #301）→ branch: sprint-102/US-301
  ├─ Subagent B（Story #302）→ branch: sprint-102/US-302
  └─ Subagent C（Story #303）→ branch: sprint-102/US-303
  |
  v
各 subagent 獨立完成後：
  → push branch → gh pr create → 回傳 PR URL
  |
  v
主 session 收到 PR URL：
  → 依序執行 code review loop（決策 5）
  → LGTM → merge
  → merge conflict → 主 session 解決（rebase feature branch onto main）
```

**規則**：

| 項目 | 規則 |
|------|------|
| Branch 建立者 | 各 subagent 自行建立 |
| PR 建立者 | 各 subagent 自行建立（含 PR body 摘要） |
| Code review 執行者 | 主 session（統一品質閘門） |
| Merge 執行者 | 主 session（避免並行 merge 衝突） |
| Merge conflict 解決者 | 主 session（rebase onto latest main） |

**與 ADR-022 檔案級鎖定的關係**：ADR-022 的檔案鎖在 PR flow 下仍有價值 — 在 subagent 開始實作前先鎖定預計修改的檔案，避免多個 PR 修改同一檔案造成 merge conflict。

---

## 決策

**採用 PR-based Git Flow**，具體決策摘要：

| 決策項 | 結論 |
|--------|------|
| 核心流程 | feature branch → PR → review loop → squash merge |
| Branch 命名 | `sprint-<N>/<story-id>` / `shoot/<issue-or-desc>` |
| main 保護 | PreToolUse hook 攔截直推，豁免清單控制例外 |
| 狀態文件 | **豁免**（選項 B），允許直推 main |
| Checkpoint | **維持現行 JSON 檔案**，歸入狀態文件豁免 |
| Code Review | pr-review-toolkit 三 agent，LGTM = 無 CRITICAL/HIGH，3 輪上限 |
| parallel-dispatch | 各 subagent 開 branch + PR，主 session 負責 review + merge |

---

## 實作影響

### 需修改的檔案

| 檔案 | 修改內容 |
|------|---------|
| `hooks/hooks.json` | PreToolUse 新增 main branch 保護 hook |
| `hooks/protect-main.sh` | 新增：main 直推攔截腳本（含豁免判定） |
| `skills/shoot/SKILL.md` §7 步驟 6 | `git commit + push` 改為 `branch + commit + push + PR + review + merge` |
| `skills/shoot/SKILL.md` §8.6 | pr-review-toolkit 審查改為在 PR 上執行，結果寫入 PR comment |
| `skills/sprint-execution/SKILL.md` §3 | Story-Lifecycle subagent 改為建立 branch + PR，主 session 負責 review + merge |
| `skills/sprint-execution/SKILL.md` §2.12 | Checkpoint 標注為狀態文件豁免，維持直推 |
| `agents/developer.md` | 新增 branch 操作指引（建立、push、PR 建立） |
| `skills/sprint-execution/story-lifecycle-prompt.md` | subagent 輸出新增 PR URL 回傳 |

### Hook 變更（hooks.json）

新增 PreToolUse hook entry：

```json
{
  "matcher": "Bash",
  "hooks": [
    {
      "type": "command",
      "command": "bash '${CLAUDE_PLUGIN_ROOT}/hooks/main-protect.sh'"
    }
  ]
}
```

`main-protect.sh` 邏輯：

```bash
# 從 $CLAUDE_TOOL_INPUT 解析 git push 指令
# 判斷是否為直推 main 的操作
# 檢查豁免條件：
#   1. commit message 含 [checkpoint]
#   2. push 目標為 refs/claims/
#   3. push 目標為 tag
#   4. 變更檔案僅限 docs/sprints/** 或 docs/PROJECT_BOARD.md
# 非豁免 → 輸出 [MAIN-PROTECT] 警告
```

### shoot §7 步驟 6 流程變更

現行：
```
[步驟 6] git commit（以 shoot: 前綴）+ git push
```

變更為：
```
[步驟 6] Branch + PR 流程
  6.1 git checkout -b shoot/<issue-or-desc>
  6.2 git commit -m "shoot: <任務標題>"
  6.3 git push -u origin shoot/<issue-or-desc>
  6.4 gh pr create --title "shoot: <任務標題>" --body "<審查摘要>"
  6.5 Code Review Loop（決策 5）
  6.6 gh pr merge --squash --delete-branch
  6.7 git checkout main && git pull
```

### sprint-execution §3 流程變更

Story-Lifecycle subagent 新增職責：
```
[subagent 內部]
  1. git checkout -b sprint-<N>/<story-id>（從最新 main）
  2. TDD 開發（現行流程不變）
  3. 審查閉環（現行流程不變）
  4. git commit + git push -u origin sprint-<N>/<story-id>
  5. gh pr create --title "feat: <story-id> <標題>" --body "<AC + 審查摘要>"
  6. 回傳 PR URL 至主 session

[主 session]
  7. 接收 PR URL
  8. Code Review Loop（決策 5）
  9. gh pr merge --squash --delete-branch
  10. 更新 PROJECT_BOARD + checkpoint（直推 main，豁免）
```

---

## 後果

### 正面

- **審查歷史可追溯**：所有 code review 結果記錄在 GitHub PR conversation 中，永久保存
- **GitHub 原生協作**：可利用 PR 的 review request、approval、change request 等機制
- **main 穩定性提升**：所有程式碼變更必須通過 review 才進入 main
- **多 Session 衝突前置偵測**：PR merge 時的 conflict check 比直推更早暴露問題
- **與業界 Git Flow 一致**：降低外部貢獻者學習成本

### 負面

- **Sprint 速度下降**：每個 Story 增加 branch + PR + review + merge 開銷（估計每個 Story +2-3 分鐘）
- **流程複雜度增加**：subagent 需要理解 branch 操作，主 session 需要協調 merge
- **離線環境受限**：`gh pr create` / `gh pr merge` 需要 GitHub API 存取

### 風險緩解

| 風險 | 緩解措施 |
|------|---------|
| Sprint 速度顯著下降 | 狀態文件豁免（決策 3）減少 PR 數量；squash merge 保持歷史簡潔 |
| subagent 不熟悉 branch 操作 | story-lifecycle-prompt.md 提供明確指令模板 |
| gh CLI 不可用 | 降級策略：回退直推 main + 內部審查（輸出 `[PR-FLOW-DEGRADED]`） |
| parallel subagent merge conflict | 主 session 統一 merge 順序 + ADR-022 檔案鎖前置偵測 |
| review loop 無限循環 | 3 輪上限 + Architect 升級（與 Circuit Breaker 一致） |
| Checkpoint 寫入被阻塞 | 歸入狀態文件豁免，維持直推（決策 4） |

### 降級行為總表

| 條件 | 降級行為 | 輸出標記 |
|------|---------|---------|
| `gh` CLI 不可用 | 回退直推 main + 內部審查 | `[PR-FLOW-DEGRADED]` |
| pr-review-toolkit 未安裝 | 內部 QA subagent 審查 | `[PR-REVIEW-DEGRADED]` |
| PR merge conflict | 主 session rebase 解決 | `[PR-MERGE-CONFLICT]` |
| Review loop 超過 3 輪 | 升級 Architect | `[PR-REVIEW-ESCALATE]` |
