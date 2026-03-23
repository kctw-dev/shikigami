# Runner 環境必裝套件清單

**用途**：Self-hosted GitHub Actions runner VM 啟動時必須預裝的工具清單。
**根因**：Issue #433 — Runner 缺 unzip 導致 claude-code-action 無法執行。
**關聯腳本**：`scripts/runner-setup.sh`

---

## 必裝工具清單

### 基礎工具

| 工具 | 用途 | 安裝方式 |
|------|------|---------|
| `unzip` | 解壓縮 ZIP 檔（claude-code-action 安裝必須） | `apt-get install unzip` |
| `zip` | 打包 ZIP 檔 | `apt-get install zip` |
| `curl` | HTTP 請求 / 下載工具 | `apt-get install curl` |
| `wget` | 備援下載工具 | `apt-get install wget` |
| `jq` | JSON 資料處理 / CI 腳本常用 | `apt-get install jq` |

### 版本控制

| 工具 | 用途 | 安裝方式 |
|------|------|---------|
| `git` | 版本控制 / checkout | `apt-get install git` |

### GitHub 操作

| 工具 | 用途 | 安裝方式 |
|------|------|---------|
| `gh` | GitHub CLI — Issues / PR 操作 | 官方 apt repo（見下方） |

---

## 安裝方式

### 一鍵初始化（推薦）

```bash
bash scripts/runner-setup.sh
```

腳本為冪等設計，重複執行無副作用。

### 手動安裝（單步驟參考）

```bash
# 更新套件索引
sudo apt-get update -qq

# 安裝基礎工具（含關鍵的 unzip）
sudo apt-get install -y unzip zip curl wget jq git

# 安裝 GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt-get update -qq
sudo apt-get install -y gh
```

---

## MIG Startup Script 整合

若使用 Google Cloud MIG（Managed Instance Group），將以下內容加入 VM startup script：

```bash
#!/usr/bin/env bash
# MIG startup script — runner 環境初始化

# 確保工具已安裝
bash /path/to/shikigami/scripts/runner-setup.sh
```

或直接內嵌以下最小化版本：

```bash
#!/usr/bin/env bash
set -euo pipefail

apt-get update -qq
apt-get install -y unzip zip curl wget jq git

# GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
apt-get update -qq
apt-get install -y gh
```

---

## 驗證清單

新 VM 啟動後，執行以下指令確認環境就緒：

```bash
# 應全部有輸出，無 command not found
command -v unzip && unzip --version | head -1
command -v curl && curl --version | head -1
command -v wget && wget --version | head -1
command -v jq && jq --version
command -v git && git --version
command -v gh && gh --version | head -1
```

或使用完整驗證：

```bash
bash scripts/runner-setup.sh --dry-run
```

---

## 歷史紀錄

| 日期 | 事件 | Issue |
|------|------|-------|
| 2026-03-23 | 建立 checklist（Sprint 121 #436） | #436 |
| 2026-03-23 | 根因：缺 unzip 導致 CI 失敗 | #433 |
