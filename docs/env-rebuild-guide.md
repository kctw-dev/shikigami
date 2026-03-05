# 環境重建流程文件 — 新 GCE 從零到可開發

**版本**：v1.0.0
**建立日期**：2026-03-05
**關聯 ADR**：[ADR-012](adr/ADR-012-max-account-rotation.md)（Claude Max 多開發環境認證架構決策）
**關聯文件**：[環境可攜性策略](env-portability-strategy.md)（方向選定）
**關聯 Story**：US-95（Issue #90，Sprint 46）

---

## 概覽

本文件提供在全新 GCE（Google Compute Engine）開發機上，從零重建完整 Shikigami 開發環境的逐步流程。

**最低成功條件**：依本文件執行後，能成功：
1. Clone Shikigami repository
2. 執行 git hooks（Claude Code SessionStart hook）
3. 執行 `scripts/validate-version.sh` 取得 PASS

**前提假設**：
- GCE 執行 Ubuntu 22.04 LTS
- 開發者有 root / sudo 權限
- 已有要部署到此 GCE 的 Anthropic Max 訂閱帳號
- 已有 GitHub 帳號（用於 clone repo）

> **認證資訊安全說明**：本文件不包含任何 OAuth Token、API Key 的內容。認證流程需在機器上互動式完成，不得以任何方式硬編碼或記錄於檔案中。

---

## 快速參考

```
總預估時間：約 15-25 分鐘（不含安裝套件下載時間）

步驟摘要：
  Phase 1（自動）：執行 setup-dev-env.sh         ~5-10 分鐘
  Phase 2（手動）：設定 git config               ~2 分鐘
  Phase 3（互動）：gh auth login                 ~3 分鐘
  Phase 4（互動）：claude auth login             ~5 分鐘
  Phase 5（驗證）：validate-version.sh 取得 PASS ~1 分鐘
```

---

## Phase 1：執行環境設定腳本（自動化步驟）

### 1.1 取得安裝腳本

若此機器尚未有 Shikigami repository，先取得安裝腳本：

```bash
# 方式 A：直接 curl 下載腳本（適用於全新機器）
curl -fsSL https://raw.githubusercontent.com/KCTW/shikigami/main/scripts/setup-dev-env.sh \
  -o /tmp/setup-dev-env.sh
bash /tmp/setup-dev-env.sh

# 方式 B：若已 clone repository（適用於重新設定現有機器）
cd ~/shikigami
bash scripts/setup-dev-env.sh
```

> **注意**：若 repository 為 private，方式 A 需先設定 GitHub 認證（Phase 3）才能下載。
> 此時請先依 Phase 1.2 在機器上安裝基礎工具，再進行 Phase 3，最後執行 clone。

### 1.2 腳本執行（若選擇方式 A）

腳本會依序完成以下步驟（均支援冪等執行，已安裝者自動跳過）：

| 步驟 | 說明 | 預期結果 |
|------|------|---------|
| apt update | 更新套件索引 | 套件索引最新 |
| 安裝基礎工具 | git、curl、jq | 工具可用 |
| 安裝 Node.js 20+ | 透過 NodeSource | `node --version` 回傳 v20+ |
| 安裝 Claude Code CLI | npm global install | `claude --version` 可執行 |
| 安裝 GitHub CLI | gh 官方 apt repo | `gh --version` 可執行 |
| 提示 git config | 顯示設定指令 | 使用者知道需要設定 |
| Clone repository | `git clone` | `~/shikigami/` 目錄存在 |
| 確認 git hooks | 說明 plugin 機制 | hooks 機制已知 |
| 執行 validate-version.sh | 最低成功條件驗證 | 全部 PASS |
| 顯示後續步驟 | 認證設定提示 | 使用者知道下一步 |

**預期腳本輸出**（已有環境的範例，新機器會顯示 PASS 而非 SKIP）：

```
[PASS] apt 套件索引更新完成
[SKIP] git 已安裝（已存在，跳過）
[SKIP] Node.js 已安裝，滿足最低需求（v20+）（已存在，跳過）
[SKIP] Claude Code 已安裝（已存在，跳過）
[SKIP] GitHub CLI 已安裝（已存在，跳過）
[SKIP] git 全域設定已存在（已存在，跳過）
[SKIP] Repository 已存在（已存在，跳過）
[PASS] git hooks 設定確認完成
[PASS] validate-version.sh 執行通過（exit code 0）
[PASS] 後續步驟說明完成
```

**若有步驟顯示 [FAIL]**，請依錯誤訊息排查後重新執行（腳本為冪等設計）。

---

## Phase 2：設定 git 全域設定

若腳本步驟中顯示 git 全域設定尚未完整，執行以下命令：

```bash
git config --global user.name "你的名字"
git config --global user.email "你的 email"
git config --global core.autocrlf false
git config --global init.defaultBranch main
```

確認設定：

```bash
git config --global --list
```

預期輸出包含：

```
user.name=你的名字
user.email=你的 email
core.autocrlf=false
init.defaultbranch=main
```

---

## Phase 3：GitHub CLI 認證

GitHub CLI 認證用於：clone private repository、操作 GitHub Issues、確認 CI/CD 狀態。

```bash
gh auth login
```

互動式選擇：
1. **What account do you want to log into?** → `GitHub.com`
2. **What is your preferred protocol for Git operations?** → `HTTPS`
3. **Authenticate Git with your GitHub credentials?** → `Yes`
4. **How would you like to authenticate GitHub CLI?** → `Login with a web browser`
5. 複製 one-time code，在本機瀏覽器完成授權

確認認證狀態：

```bash
gh auth status
```

預期輸出：

```
github.com
  ✓ Logged in to github.com as [你的 GitHub 帳號]
  ✓ Git operations for github.com configured to use https protocol.
  ✓ Token: ghp_...
```

---

## Phase 4：Claude Code OAuth 認證（最重要步驟）

> **ADR-012 對齊**：此步驟實現 ADR-012 §認證管理機制 定義的「每台 GCE 獨立認證，使用各自的 Max 訂閱帳號」。

> **使用紀律提醒**：此 GCE 使用的帳號**不得**與其他 GCE 共用。不同 GCE 必須使用各自獨立的 Anthropic Max 訂閱帳號。

詳細步驟請參考：**[GCE 認證設定指引](gce-auth-guide.md)**

### 快速摘要

```bash
# 在此 GCE 上，使用對應的 Anthropic 帳號進行 OAuth 認證
claude auth login
```

互動式步驟：
1. 執行後，Claude Code 會輸出授權 URL
2. 在本機瀏覽器開啟此 URL
3. 使用**此 GCE 對應的 Anthropic 帳號** email 登入
4. 授權完成後，回到終端確認

確認認證狀態：

```bash
claude auth status
```

預期輸出：

```
Logged in as: this-gce-account@example.com
Plan: Max 20x
```

**確認 email 符合此 GCE 應使用的帳號。**

---

## Phase 5：最終驗證（最低成功條件）

完成以上所有 Phase 後，執行以下命令驗證環境：

### 5.1 validate-version.sh（AC3 最低成功條件）

```bash
cd ~/shikigami
bash scripts/validate-version.sh
```

**預期輸出（全部 PASS）**：

```
==============================
 validate-version.sh
 .claude-plugin/ 版號一致性驗證
==============================

--- AC1：plugin.json vs marketplace.json 版號一致性
[PASS] plugin.json 與 marketplace.json 版號一致 (0.29.0)

--- AC1b：gemini-extension.json vs plugin.json 版號一致性
[PASS] plugin.json 與 gemini-extension.json 版號一致 (0.29.0)

--- AC2：git tag vs plugin.json 版號一致性
[PASS] git tag 與 plugin.json 版號一致 (0.29.0)

==============================
 總結：版號驗證全部通過
==============================
```

### 5.2 工具版本確認

```bash
node --version     # 應回傳 v20.x.x 或更高
claude --version   # 應回傳 2.x.x (Claude Code)
gh --version       # 應回傳 gh version 2.x.x
jq --version       # 應回傳 jq-1.x
git --version      # 應回傳 git version 2.x.x
```

### 5.3 Claude Code Plugin 確認

```bash
cd ~/shikigami
claude --version
```

確認 Shikigami plugin 是否已啟用（可選，初次啟動 claude 時自動安裝）：

```bash
claude --print "列出已啟用的 plugin" 2>/dev/null || echo "（需互動式 claude 確認 plugin 狀態）"
```

---

## 驗收清單

依本文件完成後，逐項確認：

- [ ] Phase 1：`setup-dev-env.sh` 執行完成，無 [FAIL]
- [ ] Phase 2：`git config --global user.name` 與 `user.email` 已設定
- [ ] Phase 3：`gh auth status` 顯示已登入
- [ ] Phase 4：`claude auth status` 顯示此 GCE 專屬帳號已登入
- [ ] Phase 5：`scripts/validate-version.sh` 全部 PASS
- [ ] 安全確認：未將任何 OAuth Token 或 API Key 寫入任何版控追蹤的檔案

---

## 常見問題排查

### Q1：`claude auth login` 無法顯示 URL

**原因**：Claude Code 可能需要終端支援特定功能。

**解法**：
```bash
# 確認 Claude Code 版本
claude --version

# 若版本過舊，升級
sudo npm install -g @anthropic-ai/claude-code
```

### Q2：`validate-version.sh` 回報版號不一致

**原因**：三個版號檔案（`plugin.json`、`marketplace.json`、`gemini-extension.json`）之一未同步更新。

**解法**：
```bash
cd ~/shikigami
# 確認三個檔案的版號
jq -r '.version' .claude-plugin/plugin.json
jq -r '.plugins[0].version' .claude-plugin/marketplace.json
jq -r '.version' gemini-extension.json

# 若有不一致，確認是否 git pull 到最新版本
git pull --ff-only
```

> **教訓記錄**（Sprint 45 v0.28.1）：版號更新必須同步三個檔案，漏更新會觸發 CI Structural Validation 失敗。

### Q3：`gh auth login` 失敗

**原因**：網路問題或 GitHub.com 連線受限。

**解法**：
```bash
# 確認網路連線
curl -s https://github.com | grep -o "GitHub" | head -1

# 若為 SSH 問題，改用 HTTPS protocol
gh auth login --hostname github.com --git-protocol https --web
```

### Q4：`setup-dev-env.sh` 中 Node.js 安裝失敗

**原因**：NodeSource GPG 簽名驗證或網路問題。

**解法**：
```bash
# 手動安裝 Node.js 20（替代方式：nvm）
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20
nvm alias default 20
```

### Q5：新 GCE 上 `git clone` 權限不足（private repo）

**原因**：GitHub CLI 尚未認證，無法使用 HTTPS git credential。

**解法**：先完成 Phase 3（`gh auth login`），再重新執行腳本。

```bash
gh auth login
bash scripts/setup-dev-env.sh  # 重新執行（冪等，只會補完缺少的步驟）
```

---

## 安全注意事項

> 本節與 ADR-012 §認證管理機制 及 `docs/gce-auth-guide.md` §4 保持一致。

1. **OAuth Token 不得出現於版控檔案**：`claude auth login` 的認證資訊存於 `~/.claude/`，已由 `.gitignore` 排除
2. **此 GCE 的認證帳號不得與其他 GCE 共用**（ADR-012 使用紀律）
3. **不在此 GCE 上執行帳號切換**（ADR-012 §3.2 嚴格規範）
4. **API Key 僅透過環境變數注入**（GitHub Secrets for CI/CD）

詳細認證安全規範，請參閱 [GCE 認證設定指引](gce-auth-guide.md) §4。

---

## 參考資料

- [ADR-012：Claude Max 多開發環境認證架構決策](adr/ADR-012-max-account-rotation.md)
- [開發環境可攜性策略（方向選定）](env-portability-strategy.md)
- [GCE 認證設定指引](gce-auth-guide.md)
- 實作腳本：`scripts/setup-dev-env.sh`
- Claude Code 文件：[Using Claude Code with Max Plan](https://support.claude.com/en/articles/11145838-using-claude-code-with-your-pro-or-max-plan)
