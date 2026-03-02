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
/schedule <skill-name> --remove
/schedule <skill-name> --dry-run
```

### 參數說明

| 參數 | 必填 | 預設 | 說明 |
|------|------|------|------|
| `<skill-name>` | 是 | — | 要排程的 Skill 名稱（如 `sprint-execution`） |
| `--interval` | 否 | `5m` | 執行間隔。僅接受 `1m` / `5m` / `15m` / `1h`，不接受 cron 表達式 |
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
| 1 | claude CLI 存在 | `which claude` | 阻擋，提示安裝 |
| 2 | flock 可用性 | `which flock` | macOS 提示 `brew install util-linux`；若不存在則阻擋 |
| 3 | OAuth 認證有效 | `unset ANTHROPIC_API_KEY && claude auth status` | 阻擋，提示 `claude auth login` |
| 4 | 專案目錄可寫 | `test -w $PROJECT_DIR` | 阻擋，提示確認目錄權限 |
| 5 | 目標 Skill 已註冊 | 檢查 `skills/<skill-name>/SKILL.md` 存在 | 阻擋，列出可用 Skill 清單 |
| 6 | 無重複排程 | `crontab -l \| grep <skill-name>_cron.sh` | 警告並阻擋，提示先執行 `--remove` |

**認證驗證實作（ADR-005 決策域四）**：

```bash
preflight_check_auth() {
  unset ANTHROPIC_API_KEY  # 強制 OAuth 路徑
  if ! which claude >/dev/null 2>&1; then
    echo "[FAIL] claude CLI 不可用"
    return 1
  fi
  if ! claude auth status >/dev/null 2>&1; then
    echo "[FAIL] claude OAuth 認證無效或已過期"
    echo "[INFO] 請執行：claude auth login"
    return 1
  fi
  echo "[PASS] OAuth 認證有效"
}
```

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

從目標 Skill 的 `SKILL.md` frontmatter 解析 `requiredTools` 清單，組裝為 `--allowedTools` 參數：

```bash
parse_required_tools() {
  local skill_md="$1"
  awk '
    /^---/ { fm_count++; next }
    fm_count == 1 && /^requiredTools:/ { in_list=1; next }
    fm_count == 1 && in_list && /^  - / { gsub(/^  - /, ""); print; next }
    fm_count == 1 && in_list && !/^  - / { in_list=0 }
    fm_count == 2 { exit }
  ' "$skill_md"
}
```

**預設白名單**（Skill 無 `requiredTools` 聲明時使用）：

```
Read Glob Grep Edit Write Bash
```

MCP 工具（如 `mcp__github__*`）不納入預設白名單，必須在 Skill 的 SKILL.md 中明確聲明。

### 鎖檔案命名（ADR-005 決策域二）

鎖檔案路徑格式（含 project-hash，防止多專案撞名）：

```
/tmp/shikigami-schedule-<project-hash>-<skill-name>.lock
```

其中 `<project-hash>` 為專案目錄路徑 MD5 前 8 碼：

```bash
PROJECT_HASH=$(echo "$PROJECT_DIR" | md5sum | cut -c1-8)
LOCK_FILE="/tmp/shikigami-schedule-${PROJECT_HASH}-${SKILL_NAME}.lock"
```

**設計理由**：同一台機器上的不同 Shikigami 專案排程相同 Skill 時，因 project-hash 不同而使用不同鎖，互不干涉（ADR-005 Stakeholder Review 修訂一）。

---

## 6. 冪等 crontab 寫入（AC4）

移除含同名腳本的既有 entry 後重新寫入，確保多次執行不產生重複：

```bash
# 生成腳本路徑（skill-name 中的連字號轉底線）
SCRIPT_TOKEN=$(echo "$SKILL_NAME" | tr '-' '_')
CRON_ENTRY="$CRON_EXPR $PROJECT_DIR/scripts/${SCRIPT_TOKEN}_cron.sh"

# 冪等寫入
(crontab -l 2>/dev/null | grep -v "${SCRIPT_TOKEN}_cron.sh"; echo "# shikigami-schedule: ${SKILL_NAME}"; echo "$CRON_ENTRY") | crontab -
```

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

```bash
CRONTAB_BACKUP=$(mktemp /tmp/shikigami-crontab-backup-XXXXXX.bak)
chmod 600 "$CRONTAB_BACKUP"
SCRIPT_GENERATED=false

rollback() {
  echo "[ERROR] 部署驗證失敗，開始回滾..."
  # Step 1：還原 crontab（優先）
  if [[ -f "$CRONTAB_BACKUP" ]]; then
    crontab "$CRONTAB_BACKUP" && echo "[INFO] crontab 已還原"
  fi
  # Step 2：刪除生成的腳本
  if [[ "$SCRIPT_GENERATED" == "true" ]] && [[ -f "$SCRIPT_PATH" ]]; then
    rm -f "$SCRIPT_PATH" && echo "[INFO] 腳本已刪除：${SCRIPT_PATH}"
  fi
}

# 建立快照
crontab -l 2>/dev/null > "$CRONTAB_BACKUP" || true
trap rollback ERR
```

**回滾後系統狀態**：crontab 無新 entry、腳本已刪除。

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

**執行內容**：只執行 Pre-flight 檢測（第 4 節全部 6 項），不部署任何檔案、不生成腳本、不修改 crontab。

**輸出範例**：

```
── QA Pre-flight ──────────────────────
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
| `START` | 取得 flock 鎖，開始執行 | `[2026-03-02 09:00:00] START — skill=sprint-execution interval=5m` |
| `SKIPPED` | flock 被前一執行個體佔用（non-blocking 立即返回） | `[2026-03-02 09:05:00] SKIPPED — previous run still active (lock: /tmp/shikigami-schedule-abc12345-sprint-execution.lock)` |
| `END` | 執行完成 | `[2026-03-02 09:03:42] END (exit: 0)` |

**查看 log**：

```bash
# 查看最新 log
tail -f logs/schedule-sprint-execution.log

# 查看所有 Skill 的 log
ls logs/schedule-*.log

# 過濾失敗執行
grep "exit: [^0]" logs/schedule-sprint-execution.log
```

---

## 11. 成功輸出範例（AC1、AC9）

```
── QA Pre-flight ──────────────────────
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

OAuth token 有效期限到期後排程執行會失敗（log 中出現認證錯誤）。處理方式：

```bash
claude auth login  # 重新認證
```

### Skill 演進後更新排程

若 Skill 的 `requiredTools` 有新增，需重新執行 schedule 讓腳本更新 `--allowedTools`：

```bash
# 先移除舊排程
claude -p "/schedule sprint-execution --remove"
# 重新建立（使用新的 requiredTools）
claude -p "/schedule sprint-execution --interval 5m"
```

生成的腳本含 `requiredTools-hash` 版本標記，可用於比對 Skill 是否已演進：

```bash
# 查看當前排程腳本的 requiredTools-hash
grep "requiredTools-hash" scripts/sprint_execution_cron.sh
```

### Lock File 管理

Lock file 存放於 `/tmp/`，重開機後自動清除。若需手動查看：

```bash
ls /tmp/shikigami-schedule-*.lock
```

---

## 14. 與其他 Skill 的關係

| 情境 | 說明 |
|------|------|
| 排程執行 sprint-execution | `/schedule sprint-execution --interval 5m` |
| 排程執行 backlog-management | `/schedule backlog-management --interval 1h` |
| 移除排程 | `/schedule sprint-execution --remove` |
| 只檢測環境 | `/schedule sprint-execution --dry-run` |
