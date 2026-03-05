# GCE 認證設定指引 — 多開發環境 OAuth 認證與使用紀律規範

**版本**：v1.0.0
**建立日期**：2026-03-05
**關聯 ADR**：[ADR-012](adr/ADR-012-max-account-rotation.md)（Claude Max 多開發環境認證架構決策）
**關聯 Story**：US-A（Issue #87，Sprint 45）

---

## 概覽

本指引說明如何在多台 GCE（Google Compute Engine）開發機上設定 Claude Max 認證，以及 GitHub Actions CI/CD 環境的 API Key 設定方式。本指引依循 ADR-012 選項 B 決策：**每台 GCE 擁有獨立的 Max 訂閱帳號，各自平行工作，CI/CD 使用獨立 API Key**。

> **重要**：本指引不包含帳號輪換邏輯。ADR-012 明確決定不在同一台機器上切換帳號（選項 B 採用多機器各自獨立訂閱）。

---

## 1. GCE 認證設定流程（AC2）

### 1.1 前置條件

- 每台 GCE 開發機已安裝 Claude Code CLI
- 每台 GCE 對應一個獨立的 Anthropic Max 訂閱帳號
- 各帳號使用不同的 email 地址註冊，各自獨立管理

### 1.2 GCE 首次認證步驟

在每台 GCE 開發機上，依以下步驟完成獨立帳號的 OAuth 認證：

#### 步驟 1：啟動 OAuth 認證流程

```bash
claude auth login
```

執行後，Claude Code 會輸出一組授權 URL，例如：

```
Please visit the following URL to authenticate:
https://claude.ai/login?code=...
```

#### 步驟 2：在瀏覽器完成登入

1. 複製上述 URL，在本機瀏覽器（或透過 SSH 埠轉發）開啟
2. 使用該台 GCE 對應的 Anthropic 帳號 email 登入
3. 授權 Claude Code 存取權限
4. 瀏覽器會顯示授權成功訊息

#### 步驟 3：確認認證狀態

```bash
claude auth status
```

預期輸出範例：

```
Logged in as: your-account@example.com
Plan: Max 20x
```

確認帳號 email 符合該台 GCE 應使用的帳號。

### 1.3 各 GCE 認證獨立性說明

| GCE 機器 | 使用帳號 | 認證方式 | 額度來源 |
|---------|---------|---------|---------|
| GCE-A | 帳號 A（email-a@example.com） | OAuth（Max 訂閱） | 帳號 A 的 5 小時窗口 |
| GCE-B | 帳號 B（email-b@example.com） | OAuth（Max 訂閱） | 帳號 B 的 5 小時窗口 |
| GitHub Actions | API Key | `ANTHROPIC_API_KEY` | Commercial Terms 計費 |

**各 GCE 的認證狀態完全獨立，無需共享或同步。**

---

## 2. GitHub Secrets 設定驗證指引（AC3）

GitHub Actions CI/CD 環境**不使用** Max 訂閱 OAuth 認證。OAuth 認證需要互動式瀏覽器登入，不適用於 CI/CD 的非互動式環境。CI/CD 使用獨立的 API Key 認證（Commercial Terms）。

### 2.1 設定 GitHub Repository Secret

1. 前往 GitHub Repository 頁面
2. 點選 **Settings** → **Secrets and variables** → **Actions**
3. 點選 **New repository secret**
4. 填入以下資訊：
   - **Name**：`ANTHROPIC_API_KEY`
   - **Secret**：填入 Claude API Key（格式：`sk-ant-api03-...`）
5. 點選 **Add secret** 儲存

### 2.2 Workflow YAML 注入方式

在 GitHub Actions workflow 檔案（`.github/workflows/shikigami-*.yml`）中，以下列方式注入 API Key：

```yaml
jobs:
  shikigami-skill:
    runs-on: ubuntu-latest
    env:
      ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
    steps:
      - name: Run Shikigami skill
        run: |
          # Claude Code 會自動使用 ANTHROPIC_API_KEY 環境變數
          claude --skip-permissions ...
```

### 2.3 Secrets 設定驗證步驟

設定完成後，透過以下方式驗證：

1. **觸發一次 CI workflow**：手動觸發或推送一個測試 commit
2. **查看 workflow 執行日誌**：確認 `ANTHROPIC_API_KEY` 已正確注入（日誌中不會顯示明文金鑰）
3. **確認無認證錯誤**：若出現 `AuthenticationError` 或 `Invalid API key`，重新確認 Secret 設定

| 驗證項目 | 通過標準 |
|---------|---------|
| Secret 名稱 | 精確為 `ANTHROPIC_API_KEY`（大小寫敏感） |
| Workflow 注入語法 | `${{ secrets.ANTHROPIC_API_KEY }}`（勿使用 `$ANTHROPIC_API_KEY`） |
| CI 執行結果 | Claude Code 可正常呼叫 API，無認證錯誤 |

---

## 3. 使用紀律規範（AC4）

依 ADR-012 決策，為降低 ToS 合規殘餘風險，所有使用多 GCE 環境的開發者須遵守以下紀律：

### 3.1 平行獨立開發原則

- **多台 GCE 可同時運行**，各自處理不同的開發任務（不同分支、不同功能）
- **工作分配主要基於開發需求**，而非額度狀態——額度狀態為次要考量
- 不同 GCE 之間的工作**不存在協調機制**；各機器獨立決策

### 3.2 不進行帳號輪換

- **嚴禁**在同一台 GCE 上執行以下任何操作以切換帳號：
  - `claude auth logout` 後以另一帳號 `claude auth login`
  - 修改 `CLAUDE_CONFIG_DIR` 環境變數指向不同帳號的設定目錄
  - 任何形式的帳號切換腳本
- **原因**：同機器帳號切換的行為模式符合 AUP「circumvent product guardrails」的特徵，風險等級顯著高於多機器多訂閱模式

### 3.3 配額耗盡即停原則

- 當某台 GCE 的帳號額度耗盡時，**該機器停止 Claude Code 工作**，等待窗口重置
- 不因額度耗盡而在同機器切換帳號
- 若需繼續工作，**移動到另一台有可用額度的 GCE 機器**
- 不啟用 Extra Usage（避免不可預測的費用）

### 3.4 獨立帳號管理

- 各帳號使用**不同的 email 地址**註冊
- 各帳號**各自付款**，不共享付款方式
- 帳號數量控制在 **2-3 個**，避免管理負擔過重

### 3.5 使用紀律速查卡

| 動作 | 允許 | 備注 |
|------|------|------|
| 多台 GCE 同時使用不同帳號工作 | 是 | ADR-012 選項 B 核心架構 |
| 在 GCE-A 額度耗盡後移至 GCE-B 繼續工作 | 是 | 正常的多機器使用模式 |
| 在同一 GCE 上切換不同帳號 | **否** | 嚴格禁止 |
| 使用腳本自動在額度耗盡時切換帳號 | **否** | 明確規避行為 |
| CI/CD 使用 Max OAuth 認證 | **否** | 非互動環境不適用；使用 API Key |
| 啟用 Extra Usage 應急 | 謹慎 | 費用不可預測，非推薦做法 |

---

## 4. 認證資訊安全規範（AC5）

### 4.1 零硬編碼原則

**認證資訊（OAuth Token、API Key）不得出現於版本控制追蹤的任何檔案中**，包括但不限於：

- 程式碼檔案（`.js`、`.ts`、`.py`、`.sh` 等）
- 設定檔案（`.env`、`.yaml`、`.json`、`.toml` 等）
- 文件檔案（`.md`、`.txt` 等）
- Git 歷史紀錄中的任何 commit

### 4.2 允許的認證資訊存放位置

| 認證資訊 | 允許存放位置 | 禁止存放位置 |
|---------|------------|------------|
| Max OAuth Token | `~/.claude/` 目錄（由 Claude Code 自動管理，git 不追蹤） | 任何 git 追蹤的檔案 |
| `ANTHROPIC_API_KEY` | GitHub Repository Secrets / 系統環境變數 | `.env` 文件（若已納入 git）、程式碼中 |
| Anthropic 帳號密碼 | 密碼管理器 | 任何檔案 |

### 4.3 `.gitignore` 防護

確認專案 `.gitignore` 包含以下條目，防止認證資訊意外進入版本控制：

```gitignore
# 認證與機密資訊
.env
.env.local
.env.*.local
*.key
*.pem
secrets/
.claude/settings.local.json
```

### 4.4 意外提交的處置程序

若認證資訊意外出現在 git commit 中，**立即執行以下步驟**：

1. **撤銷受影響的 API Key**：前往 Anthropic Console → API Keys → 刪除已洩露的金鑰
2. **生成新的 API Key**：立即建立替換金鑰
3. **更新 GitHub Secrets**：以新金鑰更新 `ANTHROPIC_API_KEY`
4. **清理 git 歷史**（選擇性）：使用 `git filter-branch` 或 `BFG Repo-Cleaner` 移除歷史記錄中的金鑰
5. **通知相關人員**：若為團隊環境，通知所有可能受影響的協作者

> **注意**：ADR-012 第 395-396 行明確規範：「零硬編碼 Secrets：API Key 只能透過環境變數或 GitHub Secrets 注入；ADR-006 Injection 防護：認證資訊不進入 LLM prompt」

---

## 5. 參考資料

- [ADR-012：Claude Max 多開發環境認證架構決策](adr/ADR-012-max-account-rotation.md)
- [ADR-011：GitHub Actions 整合架構決策](adr/ADR-011-github-actions-integration.md)
- [ADR-006：Prompt Injection 防護](adr/ADR-006-prompt-injection-protection.md)
- [Anthropic Consumer Terms of Service](https://www.anthropic.com/legal/consumer-terms)
- [Claude Code 與 Max 計劃](https://support.claude.com/en/articles/11145838-using-claude-code-with-your-pro-or-max-plan)
