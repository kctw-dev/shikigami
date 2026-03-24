# §5.7 排程衝刺 worktree 隔離執行

**關聯 Story**：US-57（Issue #46 子 Story #2）

排程觸發 `sprint-execution` 時，必須在獨立 worktree 中執行，確保不與互動 Session 的工作樹衝突。

## 步驟 (a)：worktree 建立規則

排程腳本偵測到 `SHIKIGAMI_SCHEDULED=1` 環境變數且 Skill 為 `sprint-execution` 時，在執行前建立獨立 worktree：

**路徑格式**：

```
.claude/worktrees/scheduled-<skill>-<YYYYMMDD-HHMMSS>
```

**範例**：

```
.claude/worktrees/scheduled-sprint-execution-20260303-090000
```

使用 `git worktree add <path> HEAD` 建立。timestamp 格式 `YYYYMMDD-HHMMSS` 確保每次觸發路徑唯一。

## 步驟 (b)：commit + push 至 scheduled branch

執行完成後，在 worktree 內 commit 所有變更並 push 至排程分支：

**分支命名格式**：

```
scheduled/<skill>/<date>
```

**範例**：

```
scheduled/sprint-execution/20260303
```

在 worktree 內 `git checkout -b` 建立分支、`git add -A`、commit（訊息格式 `[SCHEDULED] ${SKILL_NAME} — <timestamp>`）、push。push 完成後依 §5「排程 PR 建立規範」建立帶有 `--label "scheduled"` 的 PR。

## 步驟 (c)：worktree 清除

worktree 執行完成後（無論成功或失敗）必須清除。使用 `trap cleanup_worktree EXIT` 確保 `git worktree remove --force` 在任何退出路徑均執行。

## 衝突防護規則

| 規則 | 說明 |
|------|------|
| (a) 靜默模式 | 排程觸發時跳過 §5.3 互動式 PR 偵測提醒，僅寫入 `logs/<skill>_cron.log`；互動 Session 另有 §5.3 機制負責提醒 |
| (b) timestamp 防重複 | worktree 路徑含 timestamp（格式 `YYYYMMDD-HHMMSS`）確保每次觸發建立不同路徑，不重複建立 |
| (c) 失敗處理 | worktree 建立失敗時 exit 1 並寫入 log 錯誤記錄，不保留殘留 worktree |

**失敗處理**：`git worktree add` 失敗時 log 錯誤、`git worktree remove --force` 清除殘留、exit 1。
