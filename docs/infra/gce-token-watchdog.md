# GCE Token Watchdog 部署指引

**版本**：v1.0
**建立日期**：2026-03-24
**相關 Issue**：#539
**相關 SOP**：[docs/km/sop-claude-oauth-token-refresh.md](../km/sop-claude-oauth-token-refresh.md)

---

## 概述

`scripts/refresh-claude-token.sh` 是在 agent-team GCE 機器上執行的 watchdog 腳本，負責定期將本機最新的 Claude OAuth token 同步至 GitHub Secret，避免 CI workflow 因 token 過期而中斷。

**架構說明：**

```
GCE agent-team 機器
  └── Claude CLI (自動 refresh token)
       └── ~/.claude/.credentials.json  (最新 token)
            └── cron job (每 4 小時)
                 └── refresh-claude-token.sh
                      └── gh secret set
                           └── GitHub Secret: CLAUDE_CODE_OAUTH_TOKEN
                                └── GitHub Actions CI workflows
```

---

## 前置條件

在 GCE 機器上執行以下確認：

```bash
# 1. 確認 Claude CLI 已登入
claude --version
ls ~/.claude/.credentials.json || ls ~/.claude/credentials.json

# 2. 確認 gh CLI 已安裝並認證
gh --version
gh auth status

# 3. 確認 gh CLI 有目標 repo 的 Secret 寫入權限
gh secret list -R kctw-dev/shikigami
```

---

## 部署步驟

### 步驟 1：複製腳本至 GCE 機器

在本機執行（或直接在 GCE 上 clone repo）：

```bash
# 方法 A：從 repo 取得腳本
git clone https://github.com/kctw-dev/shikigami.git
cp shikigami/scripts/refresh-claude-token.sh ~/scripts/
chmod +x ~/scripts/refresh-claude-token.sh

# 方法 B：直接下載
mkdir -p ~/scripts
curl -o ~/scripts/refresh-claude-token.sh \
  https://raw.githubusercontent.com/kctw-dev/shikigami/main/scripts/refresh-claude-token.sh
chmod +x ~/scripts/refresh-claude-token.sh
```

### 步驟 2：測試腳本

首次手動執行，確認流程無誤：

```bash
bash ~/scripts/refresh-claude-token.sh
```

預期輸出範例：

```
[WATCHDOG 2026-03-24T10:00:00] INFO: 啟動 Claude OAuth token watchdog
[WATCHDOG 2026-03-24T10:00:00] INFO: 目標 repo: kctw-dev/shikigami / secret: CLAUDE_CODE_OAUTH_TOKEN
[WATCHDOG 2026-03-24T10:00:00] INFO: 使用 credentials 檔案: /home/kevin/.claude/.credentials.json
[WATCHDOG 2026-03-24T10:00:00] INFO: token 驗證通過（長度: 512）
[WATCHDOG 2026-03-24T10:00:00] INFO: 正在同步 token 至 GitHub Secret...
[WATCHDOG 2026-03-24T10:00:00] INFO: token 同步成功
[WATCHDOG 2026-03-24T10:00:00] INFO: 完成
```

若出現錯誤，參考下方「故障排除」章節。

### 步驟 3：設定 crontab

```bash
# 編輯 crontab
crontab -e
```

加入以下設定（每 4 小時執行一次，並記錄 log）：

```cron
# Claude OAuth token watchdog — 每 4 小時同步至 GitHub Secret
0 */4 * * * /home/kevin/scripts/refresh-claude-token.sh >> /home/kevin/logs/token-watchdog.log 2>&1
```

建立 log 目錄：

```bash
mkdir -p ~/logs
```

確認 crontab 已設定：

```bash
crontab -l
```

### 步驟 4：驗證 CI workflow 恢復

腳本首次成功執行後，觸發一次 New Issue Intake workflow 確認 token 有效：

```bash
# 列出最近 workflow 執行結果
gh run list --repo kctw-dev/shikigami --limit 5

# 或手動觸發（若有 workflow_dispatch）
gh workflow run --repo kctw-dev/shikigami new-issue-intake.yml
```

---

## 環境變數（選用）

腳本支援以下環境變數覆寫預設值：

| 變數 | 預設值 | 說明 |
|------|--------|------|
| `CLAUDE_CREDENTIALS_FILE` | 自動偵測 | 強制指定 credentials 路徑 |
| `GITHUB_REPO` | `kctw-dev/shikigami` | 目標 GitHub repo |
| `GITHUB_SECRET_NAME` | `CLAUDE_CODE_OAUTH_TOKEN` | Secret 名稱 |
| `MIN_TOKEN_LENGTH` | `20` | token 最短長度（安全閾值） |

範例（測試用途）：

```bash
GITHUB_REPO="my-org/my-repo" bash ~/scripts/refresh-claude-token.sh
```

---

## 故障排除

### 錯誤：找不到 credentials 檔案

```
ERROR: 找不到 Claude credentials 檔案
```

解法：
1. 確認 Claude CLI 已登入：`claude login`
2. 確認 credentials 檔案存在：`ls -la ~/.claude/`
3. 若路徑不同，設定環境變數：`CLAUDE_CREDENTIALS_FILE=/path/to/credentials.json bash ~/scripts/refresh-claude-token.sh`

### 錯誤：無法取得有效 token

```
ERROR: 無法從 ... 取得有效 token（值為空或 null）
```

解法：
1. 檢查 credentials 檔案格式：`cat ~/.claude/.credentials.json | jq .`
2. 確認 token 欄位名稱是否符合腳本預期（`claudeAiOauth.accessToken` 等）
3. 重新登入 Claude CLI：`claude login`

### 錯誤：gh CLI 未認證

```
ERROR: gh CLI 未認證，請先執行 'gh auth login'
```

解法：`gh auth login --web` 或使用 PAT：`gh auth login --with-token < token.txt`

### 錯誤：gh secret set 失敗

解法：
1. 確認 gh CLI 帳號有 repo 的 `secrets` 寫入權限
2. 確認 repo 名稱正確：`gh repo view kctw-dev/shikigami`

---

## 維護

- **腳本來源**：`scripts/refresh-claude-token.sh`（git 版控）
- **更新腳本**：在 GCE 機器上 `git pull`，再重新複製腳本
- **查看 log**：`tail -f ~/logs/token-watchdog.log`
- **手動觸發**：`bash ~/scripts/refresh-claude-token.sh`

---

## 更新紀錄

| 日期 | 版本 | 說明 |
|------|------|------|
| 2026-03-24 | v1.0 | 初版建立（對應 Issue #539） |
