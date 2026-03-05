# CI/CD Workflow 拆分指引

**版本**：v1.0.0
**建立日期**：2026-03-05（Sprint 45，US-93）
**ADR 參考**：ADR-011（GitHub Actions 整合架構）
**關聯 Issue**：#88

---

## 概述

本指引說明如何依任務類型拆分 CI/CD workflow，解決「self-hosted runner OOM（記憶體不足）」問題，同時保留「Stakeholder 留言 → 本機 bash 觸發」的事件驅動能力。

### 問題背景

連續多個 Sprint 出現 CI 測試失敗的根本原因：compute-heavy 任務（測試、建置）與 event-driven 任務（通知觸發）共用同一條 self-hosted runner，導致 self-hosted runner 因記憶體不足而失敗。

### 解決方案

將 CI/CD workflow 依資源需求拆分為兩種類型，各自使用最適合的 runner：

- **Compute-heavy 任務** → GitHub-hosted runner（彈性資源，按需分配）
- **Event-driven 任務** → self-hosted runner（本機環境存取，低資源消耗）

---

## GitHub-hosted vs self-hosted 適用場景對照表

| 評估維度 | GitHub-hosted Runner | Self-hosted Runner |
|---------|---------------------|-------------------|
| **適用任務** | 測試（unit / integration）、建置、lint、靜態分析 | 通知觸發、本機 bash 腳本執行、需存取本機環境的操作 |
| **資源需求** | Compute-heavy（CPU / Memory 需求高） | Event-driven（資源消耗低） |
| **執行環境** | GitHub 雲端環境（每次全新虛擬機） | 本機 / GCE 開發環境（持久化環境） |
| **本機環境存取** | 不可（沙箱隔離） | 可（直接存取本機檔案系統、服務） |
| **OOM 風險** | 低（GitHub 提供充足資源） | 高（若執行 compute-heavy 任務） |
| **成本** | 按使用量計費（公開 repo 免費） | 依自建環境成本 |
| **維護負擔** | 低（GitHub 托管，自動更新） | 高（需自行維護 runner 環境） |
| **並行能力** | 高（GitHub 自動管理並行度） | 依本機資源上限 |
| **適用事件** | `push`、`pull_request`、`workflow_run` | `issue_comment`、`workflow_dispatch` |

---

## 決策樹

```
新增 CI/CD workflow 任務時，依下列問題逐步判斷：

問題 1：此任務是否需要存取本機環境（本機檔案、本機服務、本機 claude CLI）？
  |
  +-- 是 ──→ 使用 self-hosted runner
  |           [範例：issue_comment 觸發通知、本機 bash 腳本執行]
  |
  +-- 否 ──→ 問題 2

問題 2：此任務是否有高 CPU / Memory 需求（測試套件、建置、依賴安裝）？
  |
  +-- 是 ──→ 使用 GitHub-hosted runner
  |           [範例：npm test、npm build、pip install + pytest]
  |
  +-- 否 ──→ 問題 3

問題 3：此任務的觸發事件是否為 issue_comment 或 workflow_dispatch？
  |
  +-- 是 ──→ 使用 self-hosted runner（事件驅動，低資源）
  |
  +-- 否 ──→ 使用 GitHub-hosted runner（預設選擇，資源充足）
```

### 決策摘要

| 情境 | 建議 Runner | 理由 |
|------|------------|------|
| 執行單元測試、整合測試 | GitHub-hosted | 避免 self-hosted OOM |
| npm / pip 依賴安裝 | GitHub-hosted | 安裝過程 I/O 密集，consume 大量資源 |
| Stakeholder 留言觸發通知 | Self-hosted | 需本機 bash / claude CLI 存取 |
| 本機 bash 腳本執行 | Self-hosted | 需存取本機環境 |
| 靜態分析（lint、type check） | GitHub-hosted | 計算密集，適合雲端環境 |
| Issue 狀態回寫（gh CLI） | GitHub-hosted 或 Self-hosted | 視是否需本機環境而定 |

---

## Workflow 模板

本目錄提供以下模板：

### `notify-comment.yml`

**用途**：issue_comment 事件觸發 + self-hosted runner
**適用場景**：Stakeholder 於 GitHub Issue 留言 → 觸發本機 bash 腳本

**使用方式**：

1. 複製 `notify-comment.yml` 至消費端專案 `.github/workflows/`
2. 替換 3 個 Placeholder：
   - `<<PLACEHOLDER_RUNNER_LABEL>>`：self-hosted runner label（例如：`[self-hosted, linux, x64]`）
   - `<<PLACEHOLDER_BASH_SCRIPT>>`：bash 腳本路徑（例如：`./scripts/notify.sh`）
   - `<<PLACEHOLDER_TOKEN_SCOPE>>`：所需 token scope（例如：`issues: write`）
3. 確認 bash 腳本具備執行權限（`chmod +x`）
4. 確認 self-hosted runner 已在 GitHub repo 完成註冊

**使用後效果**：複製並替換 3 個 Placeholder 後，無需修改其餘 workflow 結構即可觸發 issue_comment 事件並執行本機 bash。

---

## 安全規範（ADR-011 合規）

### 零硬編碼 Secrets

所有 token 與認證資訊必須透過 GitHub Secrets 或自動注入的 `GITHUB_TOKEN` 傳遞：

```yaml
# 正確做法
env:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

# 錯誤做法（禁止）
env:
  GITHUB_TOKEN: ghp_xxxxxxxxxxxx  # 硬編碼禁止
```

### 最小權限原則

workflow `permissions` 欄位僅授予所需最小 scope：

```yaml
# 僅需回寫 issue comment 的情況
permissions:
  issues: write

# 僅需讀取的情況
permissions:
  issues: read
  pull-requests: read
```

### Bot 留言過濾（防循環觸發）

`issue_comment` 觸發的 workflow 必須加入 Bot 過濾條件，避免 workflow 自身回寫 comment 後再次觸發：

```yaml
if: ${{ github.event.comment.user.type != 'Bot' }}
```

### ADR-006 Injection 防護

外部輸入（Issue comment 內容、PR body）進入 Shikigami Skills 前，必須套用 ADR-006 XML 隔離標記處理。

---

## 與 ADR-011 對齊說明

本指引完全遵循 ADR-011 決策（Option A：Push-Based 事件觸發）：

- issue_comment 事件 → GitHub Actions 原生事件體系
- GITHUB_TOKEN 自動注入 → 認證配置最簡，符合最小配置原則
- self-hosted runner 僅用於事件驅動任務 → 不用於 compute-heavy 任務，避免 OOM

CI/CD 拆分策略是 ADR-011 架構的延伸實踐，將「compute-heavy vs. event-driven」的資源需求差異映射至 runner 選型。
