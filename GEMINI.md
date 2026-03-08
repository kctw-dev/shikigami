# Shikigami — AI Agent Scrum Team 框架

> 7 個 AI 隊友，各有專責並互相制衡 — 讓你的 AI 開發工具擁有一支紀律嚴明的工程團隊。

本檔案為 Gemini CLI extension 進入點，透過 `gemini-extension.json` 的 `contextFileName` 自動注入每個 session。詳細的角色行為與流程規則由各 `skills/*/SKILL.md` 按需載入。

---

## Skills 載入路徑

Gemini CLI 從 extension 的 `skills/` 目錄自動發現所有 SKILL.md，無需手動設定。

```
skills/
├── scrum-master/          # Scrum Master — 流程調度中樞
├── sprint-planning/       # Sprint Planning 儀式
├── sprint-execution/      # Sprint 執行（Story-Lifecycle subagent）
├── sprint-review/         # Sprint Review + Retrospective
├── backlog-management/    # Backlog 管理
├── escalation/            # 升級處理
├── architecture-decision/ # ADR 架構決策
├── quality-gate/          # 品質門禁
├── security-review/       # 安全審查
├── deployment-readiness/  # 部署就緒檢查
├── systematic-debugging/  # 系統化除錯
├── dispel/                # Legacy 考古（解咒模式）
├── git-workflow/          # Git 分支管理
├── parallel-dispatch/     # 平行派遣
├── issue-management/      # GitHub Issue 管理
├── health-check/          # 框架健康檢查
├── onboarding/            # 新專案初始化
├── architect/             # Architect 決策指引
├── qa-engineer/           # QA Engineer 決策指引
├── schedule/              # Cron 排程管理
├── shoot/                 # 短衝模式（跳過 Sprint 儀式）
└── diagram/               # Draw.io 架構圖
```

---

## 自訂指令

| 指令 | 說明 |
|------|------|
| `/shikigami:sprint` | 啟動 Sprint Planning |
| `/shikigami:standup` | 每日站會（健康檢查 + Git 同步 + 進度確認） |
| `/shikigami:review` | Sprint Review + Retrospective |
| `/shikigami:dispel` | Legacy 系統考古模式 |

---

## 7 個角色

| 角色 | 職責 |
|------|------|
| **Scrum Master** | 意圖偵測、流程調度、Sprint 狀態機管理 |
| **Product Owner** | 需求定義、優先級決策、Backlog 管理 |
| **Architect** | 架構決策、SDD 撰寫、技術選型 |
| **Developer** | 功能實作、TDD 開發、Bug 修復 |
| **QA Engineer** | 程式碼審查、測試策略、品質門禁 |
| **Security Engineer** | 安全掃描、弱點評估、OWASP 檢查 |
| **SRE Engineer** | 部署檢查、監控配置、環境管理 |

**核心原則：互相制衡。** 不是 7 個獨立助手，而是一支紀律嚴明的工程團隊。

完整的角色互動規則（RACI 矩陣、升級路徑、DoD、Hard Gate、Bypass 機制）定義在 `skills/scrum-master/SKILL.md`。

---

## 專案自主等級（Project Level）

在你的專案根目錄 `GEMINI.md` 設定：

```
shikigami.project_level: medium
```

| 等級 | 低風險操作 | 高風險操作 |
|------|-----------|-----------|
| **low** | 自動執行 | 自動執行，事後通知 |
| **medium**（預設） | 自動執行 | QA 審查後自動執行 |
| **high** | 自動執行 | 需人工確認 |

---

## Agent 行為增強

跨 Skill 的全域 agent 行為規則。

### 錯誤自癒

| Exit Code | 症狀 | 自動修復 |
|-----------|------|---------|
| 2 | heredoc / 引號未閉合 | 改用 `write_file` 或 Edit 工具重寫 |
| 127 | 工具缺失 | 主動檢查 `$PATH` 與環境變數，不向使用者求救 |

**資源降級**：GitHub API 失敗時自動 fallback 至 `gh` CLI。窮盡所有程式化修復路徑後才升級至使用者。

### 失敗根因分析（RCA）

任何執行失敗時，自動產出簡要 RCA：
- **失敗項目**：哪個指令或操作出錯
- **根因**：為何失敗（環境、語法、相依性等）
- **修復方式**：如何解決
- **預防規則**：避免再犯的模式

RCA 記錄寫入專案知識管理（`docs/km/`），作為持續學習素材。

---

## 文件索引

| 文件 | 用途 |
|------|------|
| [README.md](./README.md) | 完整功能說明、角色概覽、22 Skills |
| [Getting Started](docs/tutorial/GETTING_STARTED.md) | 從安裝到第一個 Sprint 的完整教學 |
| [Troubleshooting](docs/tutorial/TROUBLESHOOTING.md) | 6 個常見失敗場景的診斷與解法 |
| [Product Backlog](docs/prd/PRODUCT_BACKLOG.md) | RICE 評分排序的 Backlog |
| [Project Board](docs/PROJECT_BOARD.md) | Sprint 進度與工件導覽 |
| [Gemini CLI 安裝指南](docs/INSTALL_GEMINI.md) | Gemini CLI 平台安裝說明 |

---

## 快速開始

1. 安裝 extension：
   ```
   gemini extensions install https://github.com/KCTW/shikigami
   ```

2. 在你的專案目錄打開 Gemini CLI，用自然語言描述需求 — Scrum Master 自動調度：
   ```
   > 幫我的專案初始化 Shikigami
   > 開始 Sprint Planning
   > 實作 US-01
   > 執行 Sprint Review
   ```

3. 或直接使用自訂指令：
   ```
   /shikigami:sprint
   /shikigami:standup
   /shikigami:review
   /shikigami:dispel
   ```

---

## 相關連結

- [Shikigami Gemini CLI 安裝指南](docs/INSTALL_GEMINI.md)
- [Gemini CLI Extensions 文件](https://geminicli.com/docs/extensions/)
- [Gemini CLI Custom Commands](https://geminicli.com/docs/cli/custom-commands/)
