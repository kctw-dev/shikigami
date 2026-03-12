---
name: schedule
description: "Use when setting up automated scheduled execution of a skill via cron. Handles pre-flight checks, script generation, crontab registration, post-deploy verification, and rollback."
requiredTools:
  - Read
  - Glob
  - Grep
  - Bash
---

# Schedule Skill — 自動排程設定

**關聯 ADR**：ADR-005（Accepted）
**關聯 Story**：US-35（Issue #46）

## 1. 概述

一行指令完成排程設定。`/schedule <skill> --interval <duration>` 自動執行三階段流程：Pre-flight 環境檢測 → 腳本生成 + crontab 寫入 → Post-deploy 驗證（失敗時自動回滾），讓 Shikigami Skill 以 cron 方式持續自動執行，無需人工介入。

---

## 2. 觸發語法

```
/schedule <skill-name> --interval <duration>
/schedule <skill-name> --interval <duration> --sequential-group <group-name>
/schedule <skill-name> --remove
/schedule <skill-name> --dry-run
```

### 參數說明

| 參數 | 必填 | 預設 | 說明 |
|------|------|------|------|
| `<skill-name>` | 是 | — | 要排程的 Skill 名稱（如 `sprint-execution`） |
| `--interval` | 否 | `5m` | 執行間隔。僅接受 `1m` / `5m` / `15m` / `1h`，不接受 cron 表達式 |
| `--sequential-group` | 否 | — | 將此 Skill 綁定至指定群組，同群組內的 Skill 序列執行，不平行觸發 |
| `--remove` | 否 | — | 從 crontab 移除對應排程 entry |
| `--dry-run` | 否 | — | 只執行 Pre-flight 檢測，不部署任何檔案 |

### interval 格式對照表

| 人類可讀格式 | cron 表達式 |
|-------------|------------|
| `1m` | `* * * * *` |
| `5m` | `*/5 * * * *` |
| `15m` | `*/15 * * * *` |
| `1h` | `0 * * * *` |

**不接受**：`10m`、`30m`、`2h`、`*/5 * * * *`（原始 cron 格式）、空字串、大寫 `M`。

---

## 3. 執行流程（三階段）

```
使用者執行 /schedule <skill> --interval <duration>
  |
  v
[階段 1] Pre-flight 環境檢測
  |-- 任一檢查失敗 --> 阻擋，不生成任何檔案，輸出錯誤說明
  +-- 全部通過
        |
        v
[階段 2] 生成 + 部署
  ├── 建立 crontab 快照（原子性回滾基礎）
  ├── 從 SKILL.md frontmatter 讀取 requiredTools
  ├── 生成腳本 scripts/<skill-name>_cron.sh
  ├── chmod +x
  ├── mkdir -p logs/
  └── 冪等寫入 crontab
        |
        v
[階段 3] Post-deploy 驗證
  |-- 任一驗證失敗 --> 自動回滾（先還原 crontab，再刪除腳本）
  +-- 全部通過
        |
        v
輸出成功訊息：腳本路徑 + crontab 預覽行
```

---

## 4. Pre-flight 檢測項目（AC2）

在生成任何檔案之前，依序驗證以下所有環境條件：

| # | 檢查項目 | 驗證方式 | 失敗處理 |
|---|----------|----------|----------|
| 0 | skill name 字元白名單 | 正則 `^[a-z0-9][a-z0-9-]{0,63}$` 驗證 skill name | 阻擋，輸出 `[FAIL] skill name 不合法` 錯誤訊息，不生成任何檔案 |
| 0.5 | group name 字元白名單（有 `--sequential-group` 時） | 正則 `^[a-z0-9][a-z0-9-]{0,63}$` 驗證 group-name | 阻擋，輸出 `[FAIL] group name 不合法` 錯誤訊息，不生成任何檔案 |
| 1 | claude CLI 存在 | `which claude` | 阻擋，提示安裝 |
| 2 | flock 可用性 | `which flock` | macOS 提示 `brew install util-linux`；若不存在則阻擋 |
| 3 | OAuth 認證有效 | `unset ANTHROPIC_API_KEY && claude auth status` | 阻擋，提示 `claude auth login` |
| 4 | 專案目錄可寫 | `test -w $PROJECT_DIR` | 阻擋，提示確認目錄權限 |
| 5 | 目標 Skill 已註冊 | 檢查 `skills/<skill-name>/SKILL.md` 存在 | 阻擋，列出可用 Skill 清單 |
| 6 | 無重複排程 | `crontab -l \| grep <skill-name>_cron.sh` | 警告並阻擋，提示先執行 `--remove` |
| 7 | group 衝突偵測（有 `--sequential-group` 時） | 檢查 crontab 中是否已有同 group 的排程正在執行（lock file 存在且被持有） | 阻擋，輸出 `[FAIL] group 衝突：同群組 <group-name> 已有 Skill 排程中`，建議先 `--remove` 衝突 Skill |

**group 衝突偵測規則（US-36 AC3）**：嘗試以 `flock -n` 取得 group lock（`/tmp/shikigami-group-<hash>-<group>.lock`），若被佔用則輸出 `[FAIL]` 並 return 1。僅在指定 `--sequential-group` 時執行（檢查 7）。

**skill name / group name 白名單驗證**（Retro #53, US-36 Issue #50）：skill name 與 group name 使用相同正則 `^[a-z0-9][a-z0-9-]{0,63}$`。允許小寫英文、數字、連字號；首字元不可為連字號；最長 64 字元。非法輸入時 Pre-flight 立即阻擋，不生成任何檔案。group name 在 `--sequential-group` 指定時驗證（檢查 0.5）。

**認證驗證規則（ADR-005 決策域四）**：先 `unset ANTHROPIC_API_KEY` 強制 OAuth 路徑，再依序檢查 `which claude` 與 `claude auth status`，任一失敗則阻擋。

**--dry-run 只執行 Pre-flight 檢測**，所有 Pre-flight 通過後輸出「Pre-flight 通過，dry-run 模式不部署任何檔案」，不執行後續部署步驟。

---

## 5. 腳本生成模板（AC3）

腳本自動生成至 `scripts/<skill-name>_cron.sh`，由 `templates/schedule_cron.sh.tmpl` 填入以下佔位符：

| 佔位符 | 說明 |
|--------|------|
| `{{SKILL_NAME}}` | Skill 名稱（如 `sprint-execution`） |
| `{{INTERVAL}}` | 人類可讀 interval（如 `5m`） |
| `{{CRON_EXPR}}` | cron 表達式（如 `*/5 * * * *`） |
| `{{PROJECT_DIR}}` | 專案根目錄絕對路徑 |
| `{{PROJECT_HASH}}` | 專案目錄路徑 MD5 前 8 碼 |
| `{{TIMESTAMP}}` | 生成時間戳（ISO 8601） |
| `{{ALLOWED_TOOLS}}` | 從 SKILL.md frontmatter `requiredTools` 讀取 |
| `{{REQUIRED_TOOLS_HASH}}` | `requiredTools` 清單 MD5，供版本追蹤用 |

### allowedTools 白名單（ADR-005 決策域三）

從目標 Skill 的 `SKILL.md` frontmatter 使用 awk 解析 `requiredTools` YAML 清單，組裝為 `--allowedTools` 參數。

**預設白名單**（Skill 無 `requiredTools` 聲明時使用）：

```
Read Glob Grep Edit Write Bash
```

MCP 工具（如 `mcp__github__*`）不納入預設白名單，必須在 Skill 的 SKILL.md 中明確聲明。

### 排程 PR 建立規範（US-54 AC3）

排程腳本執行完成後，若有需要建立 PR（例如 sprint-execution 產生變更），**必須**在 PR 建立指令中附加 `--label "scheduled"` label，以便 Scrum Master 在互動 Session 啟動時能夠偵測並提醒審核。

**規則**：
- 所有由排程腳本（`*_cron.sh`）觸發的 PR 建立操作，必須帶有 `--label "scheduled"`
- `scheduled` label 為固定必填，不得省略
- label 不存在時先建立：`gh label create "scheduled" --color "#0075ca" --description "排程自動執行產生的 PR"`

**設計理由**：`scheduled` label 是 Scrum Master §5.3 排程 PR 偵測的依據。若排程 PR 缺少此 label，偵測機制將無法找到待審 PR，破壞 Issue #46 的完整性。

### 鎖檔案命名（ADR-005 決策域二）

鎖檔案路徑格式（含 project-hash，防止多專案撞名）：

```
/tmp/shikigami-schedule-<project-hash>-<skill-name>.lock
```

`<project-hash>` 為專案目錄路徑 MD5 前 8 碼。

**設計理由**：同一台機器上的不同 Shikigami 專案排程相同 Skill 時，因 project-hash 不同而使用不同鎖，互不干涉（ADR-005 Stakeholder Review 修訂一）。

---

## 5.5 序列鎖（Sequential Group Lock）使用說明

### 問題背景

Planning 與 Execution 兩個 Skill 若同時觸發，會造成共享檔案（如 `sprint_N.md`）的讀寫衝突與競態條件。序列鎖機制透過 group 綁定，確保同群組內的 Skill 不會平行執行。

### 觸發語法

```bash
# 將 sprint-planning 綁定至 sprint-cycle 群組
/schedule sprint-planning --interval 1h --sequential-group sprint-cycle

# 將 sprint-execution 綁定至同一群組
/schedule sprint-execution --interval 1h --sequential-group sprint-cycle
```

### Group 綁定方式

使用 `--sequential-group <group-name>` 將 Skill 加入指定群組。同一群組名稱的所有 Skill 共享一把群組鎖（group lock），任一時刻只有一個 Skill 能持有此鎖並執行。

**group-name 命名規範**：與 skill-name 相同的白名單規則——小寫英文、數字、連字號，不可以連字號開頭，最長 64 字元。

### 鎖行為描述

| 情境 | 行為 |
|------|------|
| 群組無任何 Skill 執行中 | 取得 group lock，繼續執行 |
| 同群組另一 Skill 正在執行（group lock 被佔用） | 立即退出（SKIPPED），不等待 |
| 無 `--sequential-group` 參數 | 只使用 skill-level lock，行為與 Sprint 18 完全一致 |

### 鎖檔案命名（ADR-005 決策域二）

```
/tmp/shikigami-group-<project-hash>-<group-name>.lock
```

Group lock 在 skill-level lock 之前取得，確保群組層級的互斥先於 Skill 層級的互斥：

```
1. 嘗試取得 group lock（/tmp/shikigami-group-<hash>-<group>.lock）
   └── 失敗 → SKIPPED（log group lock 被佔用），exit 0
2. 嘗試取得 skill lock（/tmp/shikigami-schedule-<hash>-<skill>.lock）
   └── 失敗 → SKIPPED（log skill lock 被佔用），exit 0
3. 執行 Skill
```

### 使用範例

```bash
# 設定 Planning + Execution 序列排程（同屬 sprint-cycle 群組）
claude -p "/schedule sprint-planning --interval 1h --sequential-group sprint-cycle"
claude -p "/schedule sprint-execution --interval 1h --sequential-group sprint-cycle"

# 兩者不會平行執行：sprint-planning 執行中時，sprint-execution 觸發後會 SKIPPED
```

---

## 5.7 排程衝刺 worktree 隔離執行

**關聯 Story**：US-57（Issue #46 子 Story #2）

排程觸發 `sprint-execution` 時，必須在獨立 worktree 中執行，確保不與互動 Session 的工作樹衝突。

### 步驟 (a)：worktree 建立規則

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

### 步驟 (b)：commit + push 至 scheduled branch

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

### 步驟 (c)：worktree 清除

worktree 執行完成後（無論成功或失敗）必須清除。使用 `trap cleanup_worktree EXIT` 確保 `git worktree remove --force` 在任何退出路徑均執行。

### 衝突防護規則

| 規則 | 說明 |
|------|------|
| (a) 靜默模式 | 排程觸發時跳過 §5.3 互動式 PR 偵測提醒，僅寫入 `logs/<skill>_cron.log`；互動 Session 另有 §5.3 機制負責提醒 |
| (b) timestamp 防重複 | worktree 路徑含 timestamp（格式 `YYYYMMDD-HHMMSS`）確保每次觸發建立不同路徑，不重複建立 |
| (c) 失敗處理 | worktree 建立失敗時 exit 1 並寫入 log 錯誤記錄，不保留殘留 worktree |

**失敗處理**：`git worktree add` 失敗時 log 錯誤、`git worktree remove --force` 清除殘留、exit 1。

---

## 5.8 程式碼入庫 QA 自動化

**關聯 Story**：US-60（Issue #46 子 Story #3）

排程衝刺執行完成、`scheduled/*` 分支 push 後，自動進行程式碼入庫品質驗證並建立 PR，確保排程產出的變更在進入主分支前通過 QA 閘門。

### 偵測條件

排程腳本在執行 §5.7 步驟 (b) push 完成後，偵測以下條件以啟動 QA 自動化流程：

| 偵測項目 | 判定方式 |
|----------|----------|
| 分支命名符合 `scheduled/*` 規則 | `git branch --show-current \| grep -q '^scheduled/'` |
| 分支已 push 至 remote | `git ls-remote --heads origin "$BRANCH_NAME"` 確認遠端分支存在 |
| 無對應 open PR | `gh pr list --head "$BRANCH_NAME" --state open --json number \| jq 'length == 0'` |

三項條件全部滿足時，進入 PR 建立流程；任一不符則 log 說明並跳過。

### PR 建立流程

偵測條件通過後，依序執行以下步驟：

**步驟 1：Quality Gate 前置檢查**

在建立 PR 前先執行 quality-gate 檢查項目（見下方「Quality Gate 檢查項目」）。任一項失敗則記錄錯誤至 log，**不建立 PR**，等待人工介入。

**步驟 2：建立 PR**

使用 `gh pr create --title "[SCHEDULED] ${SKILL_NAME} — <timestamp>" --label "scheduled" --base main`，body 須包含：Skill 名稱、Interval、Sprint 編號、Story ID、分支名、執行時間、Quality Gate 結果、變更摘要。

**步驟 3：PR 建立後通知**

PR URL 與 Quality Gate 結果寫入 `${LOG_FILE}`。

### Quality Gate 檢查項目

排程 PR 建立前必須通過以下三條 quality-gate 規則：

| # | 規則 | 驗證方式 | 失敗處理 |
|---|------|----------|----------|
| (a) | **CI 驗證通過** — bash syntax check + 現有測試 | 對 worktree 內所有新增/修改的 `.sh` 檔案執行 `bash -n <file>`；若專案有測試腳本則執行 `bash tests/run_tests.sh` 或同等指令 | 記錄失敗檔案清單至 log，不建立 PR，等待人工修復 |
| (b) | **PR body 包含 Story ID 與 Sprint 編號標注** — 確保可追溯性 | 驗證 PR body 中含有 `Story ID` 欄位（非空）與 `Sprint` 欄位（非空），格式如 `US-NN` 與 `Sprint NN` | 若環境變數 `STORY_ID` 或 `SPRINT_NUMBER` 未設定則以 `UNKNOWN` 填入並在 log 中警告 |
| (c) | **Merge 前確認無衝突（non-conflicting）** — 確保分支可乾淨合併至主分支 | 執行 `git merge-tree $(git merge-base HEAD origin/main) HEAD origin/main` 並檢查是否有衝突標記（`<<<<<<`） | 記錄衝突檔案清單至 log，不建立 PR，通知人工解衝突後重跑 |

**實作要點**：(a) 用 `find -name "*.sh" -newer .git -print0` 找新增/修改的 sh 檔並逐一 `bash -n` 驗證；(b) 檢查 `STORY_ID` / `SPRINT_NUMBER` 環境變數，空值以 `UNKNOWN` 填入並警告；(c) 用 `git merge-tree` 檢查衝突標記（`<<<<<<`）。任一失敗 return 1，不建立 PR。

---

## 6. 冪等 crontab 寫入（AC4）

移除含同名腳本的既有 entry 後重新寫入，確保多次執行不產生重複。

**規則**：skill-name 連字號轉底線作為 `SCRIPT_TOKEN`，先 `grep -v` 移除舊 entry，再 append 新 entry（含 `# shikigami-schedule:` 註解行），pipe 至 `crontab -`。

---

## 7. Post-deploy 驗證與自動回滾（AC5）

部署完成後依序驗證（ADR-005 決策域五）：

| # | 驗證項目 | 驗證方式 | 失敗處理 |
|---|----------|----------|----------|
| a | crontab 項目已寫入 | `crontab -l \| grep <script_token>_cron.sh` | 自動回滾 |
| b | 腳本存在且可執行 | `test -x scripts/<skill>_cron.sh` | 自動回滾 |
| c | flock 配置正確 | `grep -n "flock" scripts/<skill>_cron.sh` | 自動回滾 |
| d | 腳本語法正確 | `bash -n scripts/<skill>_cron.sh` | 自動回滾 |

**回滾順序（原子性）**：先還原 crontab 快照，再刪除生成的腳本。先還原 crontab 是為了防止在回滾窗口期觸發損毀腳本。

**回滾實作要點**：部署前 `mktemp` 建立 crontab 快照（chmod 600），`trap rollback ERR` 確保失敗時自動觸發。回滾函數先 `crontab "$CRONTAB_BACKUP"` 還原，再 `rm -f` 刪除腳本。回滾後系統狀態：crontab 無新 entry、腳本已刪除。

---

## 8. `--remove` 移除排程（AC6）

```bash
claude -p "/schedule sprint-execution --remove"
```

**流程**：

1. 從 crontab 移除含 `<skill_token>_cron.sh` 的 entry
2. 保留腳本和 log 目錄（避免誤刪歷史紀錄）
3. 確認 crontab 已移除後輸出確認訊息

**冪等行為**：若目標排程不存在，輸出警告訊息但正常退出（exit 0）：

```
[WARN] 排程 'sprint-execution' 不存在，無需移除
```

---

## 9. `--dry-run` 只檢測（AC7）

```bash
claude -p "/schedule sprint-execution --dry-run"
```

**執行內容**：只執行 Pre-flight 檢測（第 4 節全部 7 項），不部署任何檔案、不生成腳本、不修改 crontab。

**輸出範例**：

```
── QA Pre-flight ──────────────────────
  [PASS] skill name 字元白名單通過
  [PASS] claude CLI 可用
  [PASS] flock 可用
  [PASS] OAuth 認證有效（非無效 API key）
  [PASS] 專案目錄存在且可寫
  [PASS] /sprint-execution skill 已註冊
  [PASS] 無衝突的排程已存在

Pre-flight 全部通過。dry-run 模式，不部署任何檔案。
```

---

## 10. Log 機制（AC8）

每次排程腳本執行均記錄至專案內 `logs/` 目錄：

**log 路徑**：`logs/schedule-<skill-name>.log`

例如：`logs/schedule-sprint-execution.log`

### Log 格式

每行由時間戳 + 狀態組成：

| 狀態 | 觸發時機 | 格式範例 |
|------|----------|----------|
| `START` | 取得 flock 鎖，開始執行 | `[2026-03-02 09:00:00] START — skill=sprint-execution interval=5m group=sprint-cycle` |
| `START`（無 group） | 取得 flock 鎖，開始執行（無 group 設定） | `[2026-03-02 09:00:00] START — skill=sprint-execution interval=5m group=none` |
| `SKIPPED` | flock 被前一執行個體佔用（non-blocking 立即返回） | `[2026-03-02 09:05:00] SKIPPED — previous run still active (lock: /tmp/shikigami-schedule-abc12345-sprint-execution.lock)` |
| `END` | 執行完成 | `[2026-03-02 09:03:42] END (exit: 0)` |

**group 欄位說明（US-36 AC4）**：

- 每次 `START` 記錄均包含 `group=<group-name>` 欄位
- 無 `--sequential-group` 設定時記錄 `group=none`
- SKIPPED 和 END 不需要額外的 group 欄位（已在對應 START 記錄中呈現）

**查看 log**：`tail -f logs/schedule-<skill-name>.log`；過濾失敗：`grep "exit: [^0]" logs/schedule-*.log`

---

## 11. 成功輸出範例（AC1、AC9）

```
── QA Pre-flight ──────────────────────
  [PASS] skill name 字元白名單通過
  [PASS] claude CLI 可用
  [PASS] flock 可用
  [PASS] OAuth 認證有效（非無效 API key）
  [PASS] 專案目錄存在且可寫
  [PASS] /sprint-execution skill 已註冊
  [PASS] 無衝突的排程已存在

── 部署 ───────────────────────────────
  ✓ 腳本已生成：scripts/sprint_execution_cron.sh
  ✓ 執行權限已設定（chmod +x）
  ✓ Log 目錄已確認：logs/
  ✓ Crontab 已寫入

── QA Post-deploy ─────────────────────
  [PASS] crontab 項目已寫入（crontab -l 確認）
  [PASS] 腳本存在且可執行（test -x）
  [PASS] flock 配置正確（grep flock 確認）
  [PASS] 腳本語法正確（bash -n）

✓ 排程啟用完成 — sprint-execution 每 5 分鐘執行

── 摘要 ───────────────────────────────
  腳本路徑：scripts/sprint_execution_cron.sh
  Crontab 項目：*/5 * * * * /home/user/proj/scripts/sprint_execution_cron.sh
  Log 路徑：logs/schedule-sprint-execution.log
```

---

## 12. ADR-005 技術決策摘要

| 決策域 | 決策 | 核心理由 |
|--------|------|----------|
| 排程工具 | cron | 跨平台（Linux/macOS）、零依賴、MVP 足夠 |
| 互斥鎖 | flock（含 project-hash） | 進程死亡時 OS 自動釋放，不殘留孤兒鎖；project-hash 防多專案撞名 |
| allowedTools | SKILL.md frontmatter `requiredTools` | 版本控制原子性，防止聲明與實作漂移 |
| API Key 注入 | OAuth（`~/.claude/`），明確 `unset ANTHROPIC_API_KEY` | 安全性優先，API Key 不出現在腳本明文 |
| Post-deploy 回滾 | 原子性回滾（先還原 crontab，再刪除腳本） | 防止靜默失敗，回滾順序有安全含義 |

---

## 13. 維運注意事項

### OAuth Token 過期

Token 過期時排程失敗（log 出現認證錯誤），執行 `claude auth login` 重新認證。

### Skill 演進後更新排程

`requiredTools` 變更後需 `--remove` 再重新 `/schedule`，腳本內含 `requiredTools-hash` 可比對版本。

### Lock File 管理

Lock file 存放於 `/tmp/`，重開機後自動清除。

---

## 14. 與其他 Skill 的關係

| 情境 | 說明 |
|------|------|
| 排程執行 sprint-execution | `/schedule sprint-execution --interval 5m` |
| 排程執行 backlog-management | `/schedule backlog-management --interval 1h` |
| 移除排程 | `/schedule sprint-execution --remove` |
| 只檢測環境 | `/schedule sprint-execution --dry-run` |

---

## 15. 使用範例

本節提供完整的 `/schedule` 指令使用範例，說明前提條件與預期結果，協助使用者快速設定自動化排程。

---

### 範例 (a)：README 統計自動更新排程

`/schedule readme-update --interval 1h` — 每小時自動更新 README 徽章統計並 commit。

**前提條件**：OAuth 認證有效、目標 Skill 已存在、flock 可用、專案目錄可寫（同 §4 Pre-flight 檢測項目）。

移除排程：`/schedule readme-update --remove`

---

### 範例 (b)：Daily Standup 自動排程

`/schedule daily-standup --interval 1h` — 每小時觸發 standup report 生成。

**注意**：`/schedule` 不接受原始 cron 表達式（如 `0 9 * * 1-5`）。若需精確時間觸發，選擇 `--interval 1h` 並在 Skill 內部加入時間條件判斷（如 `[ $(date +%H) -eq 9 ] || exit 0`）。

**序列執行**（避免與 sprint-execution 共享檔案衝突）：兩者均綁定 `--sequential-group sprint-cycle`。

---

### 範例 (c)：Issue 管理自動化排程（issue-management）

`/schedule issue-management --interval 1h` — 每小時掃描 GitHub Issues 執行入庫、分類、回覆。移除：`/schedule issue-management --remove`。

**注意**：依賴 gh CLI OAuth 與 claude CLI OAuth 兩者認證，需定期確認。新 Issue 入庫已由 GitHub Action（`new-issue-intake.yml`）即時處理，排程用於批次補齊。
