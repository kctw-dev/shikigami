---
name: schedule
description: "Use when scheduling a skill for automated periodic execution via cron — setup, verification, and rollback of crontab entries"
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

**驗證規則**：group 衝突偵測用 `flock -n` 取得 group lock，失敗則 `[FAIL]` return 1（僅檢查 7）。白名單正則 `^[a-z0-9][a-z0-9-]{0,63}$`（Retro #53）。認證先 `unset ANTHROPIC_API_KEY` 再 `claude auth status`（ADR-005 決策域四）。`--dry-run` 只執行 Pre-flight，通過後不部署。

---

## 5. 腳本生成模板（AC3）

> 詳細佔位符、allowedTools 白名單、PR 建立規範、鎖檔案命名：[references/script-template.md](references/script-template.md)

腳本自動生成至 `scripts/<skill-name>_cron.sh`，由 `templates/schedule_cron.sh.tmpl` 填入佔位符（`{{SKILL_NAME}}`、`{{INTERVAL}}`、`{{CRON_EXPR}}`、`{{PROJECT_DIR}}`、`{{PROJECT_HASH}}`、`{{TIMESTAMP}}`、`{{ALLOWED_TOOLS}}`、`{{REQUIRED_TOOLS_HASH}}`）。排程 PR 必須帶 `--label "scheduled"`；鎖路徑格式 `/tmp/shikigami-schedule-<project-hash>-<skill-name>.lock`。

## 5.5 序列鎖（Sequential Group Lock）

> 完整說明：[references/sequential-lock.md](references/sequential-lock.md)

`--sequential-group <group-name>` 綁定群組後，同群組 Skill 共享一把 group lock，任一時刻只有一個 Skill 執行。Group lock 先於 skill lock 取得；若被佔用則立即 SKIPPED（exit 0），不等待。鎖路徑：`/tmp/shikigami-group-<project-hash>-<group-name>.lock`。

## 5.7 排程衝刺 worktree 隔離執行

> 完整說明：[references/worktree-isolation.md](references/worktree-isolation.md)

排程觸發 `sprint-execution` 時（`SHIKIGAMI_SCHEDULED=1`），在 `.claude/worktrees/scheduled-<skill>-<YYYYMMDD-HHMMSS>` 建立獨立 worktree，執行完畢後 commit + push 至 `scheduled/<skill>/<date>` 分支建立 PR，最後 `trap cleanup_worktree EXIT` 確保清除 worktree。

## 5.8 程式碼入庫 QA 自動化

> 完整說明：[references/qa-automation.md](references/qa-automation.md)

`scheduled/*` 分支 push 後自動偵測三項條件（分支命名合規、已 push、無 open PR），全通過後執行 Quality Gate（CI syntax check、PR body Story ID/Sprint 標注、無 merge 衝突），Gate 通過才建立帶 `--label "scheduled"` 的 PR。

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

**回滾順序（原子性）**：先還原 crontab 快照，再刪除生成的腳本。`trap rollback ERR` 確保失敗時自動觸發。

---

## 8. `--remove` 移除排程（AC6）

```bash
claude -p "/schedule sprint-execution --remove"
```

移除 crontab 中含 `<skill_token>_cron.sh` 的 entry，保留腳本和 log 目錄。**冪等**：排程不存在時輸出 `[WARN]` 並 exit 0。

---

## 9. `--dry-run` 只檢測（AC7）

只執行 Pre-flight 檢測（§4 全部 7 項），不部署任何檔案、不生成腳本、不修改 crontab。

---

## 10. Log 機制（AC8）

**log 路徑**：`logs/schedule-<skill-name>.log`

| 狀態 | 格式範例 |
|------|----------|
| `START` | `[2026-03-02 09:00:00] START — skill=sprint-execution interval=5m group=sprint-cycle` |
| `SKIPPED` | `[2026-03-02 09:05:00] SKIPPED — previous run still active (lock: /tmp/...)` |
| `END` | `[2026-03-02 09:03:42] END (exit: 0)` |

無 `--sequential-group` 時記錄 `group=none`。查看：`tail -f logs/schedule-<skill>.log`。

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

- **OAuth Token 過期**：執行 `claude auth login` 重新認證。
- **Skill 演進後更新排程**：`requiredTools` 變更後 `--remove` 再重新 `/schedule`，腳本內含 `requiredTools-hash` 供比對。
- **Lock File 管理**：存放於 `/tmp/`，重開機後自動清除。

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

> 完整範例：[references/usage-examples.md](references/usage-examples.md)

- `(a)` `/schedule readme-update --interval 1h` — 每小時更新 README 徽章
- `(b)` `/schedule daily-standup --interval 1h` — 每小時觸發 standup；精確時間在 Skill 內判斷
- `(c)` `/schedule issue-management --interval 1h` — 每小時批次處理 GitHub Issues
