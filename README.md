# 式神 Shikigami — AI Agent Scrum Team 框架

![Version](https://img.shields.io/badge/version-v0.69.3-blue?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)
![Sprints](https://img.shields.io/badge/sprints-94%2B-orange?style=flat-square)
![Skills](https://img.shields.io/badge/skills-25-purple?style=flat-square)

**為你的 AI 開發工具注入 8 個專業角色，涵蓋 Discovery → Definition → Delivery 全產品生命週期。**

```
/plugin marketplace add KCTW/shikigami
/plugin install shikigami
```

> 安裝後對 Claude 說：`幫我初始化 Shikigami` — Scrum Master 會接手引導。

---

## Quick Start

### 前置條件

- 已安裝 [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- 已完成 Claude Code 帳號認證（可正常對話）

### 安裝（Claude Code）

在 Claude Code 互動介面中輸入：

```
/plugin marketplace add KCTW/shikigami
/plugin install shikigami
```

安裝後重啟 Claude Code，在你的專案目錄說：

```
幫我初始化 Shikigami
```

Scrum Master 會建立 `CLAUDE.md` 與 `docs/` 目錄結構，完成後即可開始。

### 其他平台

| 平台 | 安裝指令 | 安裝指南 |
|------|----------|----------|
| **OpenCode** | symlink 適配策略 | [docs/INSTALL_OPENCODE.md](docs/INSTALL_OPENCODE.md) |
| **Gemini CLI** | `gemini extensions install https://github.com/KCTW/shikigami` | [docs/INSTALL_GEMINI.md](docs/INSTALL_GEMINI.md) |
| **Cursor** | `bash scripts/install-cursor.sh` | [docs/INSTALL_CURSOR.md](docs/INSTALL_CURSOR.md) |

---

## 這能解決什麼問題？

你一個人開發，需求靠腦補、寫完的代碼沒人 review，架構決策靠直覺，安全問題等上線才發現。

Shikigami 注入 8 個角色，覆蓋產品從**探索到上線**的完整流程：

- **Discovery**：PO 驅動產品探索，Product Brief 標準化格式 + 假設外顯化 + PO 確認關卡
- **Definition**：Backlog 管理、Sprint Planning、架構決策（ADR）
- **Delivery**：TDD 開發、QA 雙階段審查、Security 掃描、SRE 部署
- **Design**：UI/UX Designer 透過 Figma MCP 執行設計，Vision Critic 自審視覺品質

角色之間**互相制衡**，不是 8 個獨立助手。**不需要記指令**，用自然語言說你要做什麼，Scrum Master 自動調度。

---

## 使用情境

### 情境 1：我有一個模糊的想法，想確認該不該做

```
我想加一個使用者登入功能，但不確定要用哪種方式
```

Shikigami 觸發 Discovery Phase：PO 產出 Product Brief（問題陳述 + 商業假設 + 驗證方法），Architect 評估技術可行性，PO 簽核後自動轉為 Backlog Issues。從探索到可執行 Story，全程結構化。

### 情境 2：我想讓 AI 執行代碼審查，而不只是給建議

```
開始 Sprint / 實作 Story A
```

Developer subagent 依照 TDD 流程實作（Red → Green → Refactor），完成後 QA subagent 自動執行雙階段審查（Spec Compliance + Code Quality）。任何不符合 AC 的代碼都會在合併前被攔截。

<details>
<summary>更多使用情境範例（Sprint 開發循環、Issue 管理、架構決策）</summary>

### Sprint 開發循環

```
開始 Sprint

Scrum Master → 觸發 sprint-planning
PO：從 Backlog 選取 Stories
Architect：技術估算
QA：AC 可測試性確認
PO：Sprint 文件已建立 → docs/sprints/sprint_N.md

實作 Story A

Developer subagent：
  Red — 寫失敗測試
  Green — 最小實作通過
  Refactor — 重構優化
  commit: "test: 新增功能測試"
  commit: "feat: 實作核心邏輯"

QA subagent（Spec Review）：所有 AC 通過
QA subagent（Code Quality）：品質門禁通過
```

### Issue 管理

```
幫我分類一下 GitHub Issues

PO subagent：
  gh issue list --search "no:label" → 找到 5 個未分類 issues
  分類結果：
    #12 登入失敗      | bug             | 已要求補充重現步驟
    #13 希望支援匯出  | feature-request | —
    #14 怎麼安裝？    | question        | 已引導至 README
  Labels 已自動套用
```

### 架構決策

```
資料庫要用 PostgreSQL 還是 SQLite？

Architect subagent：
  建立 ADR-002
  選項 A：PostgreSQL — 擴展性強，維運成本高
  選項 B：SQLite — 零配置，單檔案，不適合高併發
  建議：採用 SQLite（MVP 階段，KISS 原則）

QA subagent（Decision Challenger）：
  為 PostgreSQL 辯護：未來遷移成本可能很高
  結論：同意 SQLite，但建議抽象 DB 層以降低遷移風險

Architect：ADR-002 狀態 → Accepted
```

</details>

---

## 功能概覽

### 8 個角色

| 角色 | 職責 |
|---|---|
| **Product Owner** | 需求定義、優先級決策、Backlog 管理 |
| **Architect** | 架構決策、SDD 撰寫、技術選型 |
| **Developer** | 功能實作、TDD 開發、Bug 修復 |
| **QA Engineer** | 代碼審查、測試策略、品質把關 |
| **Security Engineer** | 安全掃描、漏洞評估、OWASP 檢查 |
| **SRE Engineer** | 部署檢查、監控配置、環境管理 |
| **UI/UX Designer** | 設計系統維護、Figma 原型製作、視覺品質審查 |
| **Stakeholder** | 最終仲裁、打破僵局 |

**重點：它們互相制衡，不是 8 個獨立助手。**

<details>
<summary>完整 25 個 Skills 列表</summary>

**Discovery（產品探索）**

| Skill | 說明 |
|---|---|
| **discovery-phase** | Product Discovery 獨立入口、Product Brief 標準化格式、假設外顯化、PO 確認關卡 |

**Definition（需求定義與 Sprint 管理）**

| Skill | 說明 |
|---|---|
| **scrum-master** | 自動調度 Agent Scrum Team 的角色分工與 Sprint 流程 |
| **sprint-planning** | 啟動新 Sprint、從 Backlog 選取 Stories、規劃 Sprint 目標 |
| **backlog-management** | Backlog 梳理、需求變更管理 |
| **escalation** | 團隊衝突無法解決、重大產品轉向、升級鏈啟動 |

**Delivery（開發與交付）**

| Skill | 說明 |
|---|---|
| **sprint-execution** | 執行 Sprint Stories、功能實作、處理 Sprint Backlog |
| **sprint-review** | Sprint 結束時進行回顧與驗收、評估 Sprint 成果 |
| **architecture-decision** | 技術決策、架構審查、技術選型、ADR 撰寫 |
| **quality-gate** | 代碼審查、功能驗收、PR 檢查、品質指標檢測 |
| **security-review** | 外部輸入處理、API 安全、配置安全、漏洞評估 |
| **deployment-readiness** | 部署準備、版本發布、環境配置、生產就緒檢查 |
| **systematic-debugging** | Bug 排查、測試失敗分析、系統化除錯流程 |
| **dispel** | Legacy 系統考古、不熟悉 codebase 分析、解咒模式 |
| **architect** | Architect 角色知識框架、架構評估決策指引 |
| **qa-engineer** | QA 角色知識框架、審查策略與 Story-Lifecycle 整合指引 |

**Design（設計）**

| Skill | 說明 |
|---|---|
| **uiux-designer** | UI/UX Designer 角色定義、Design Foundation 流程、Figma MCP 整合 |
| **vision-critic** | UI 截圖多維度視覺一致性評分，產出 PASS/FAIL 報告與可執行修正建議 |

**工具整合**

| Skill | 說明 |
|---|---|
| **git-workflow** | 分支隔離、Worktree 管理、開發完成後的合併/PR 流程 |
| **parallel-dispatch** | 多個獨立任務的平行 Subagent 派遣，含同檔案衝突偵測與自動序列化 |
| **issue-management** | GitHub Issue 管理、自動分類、回覆、Issue 轉 Backlog |
| **health-check** | 框架自我診斷、結構完整性檢查、逾期 Action Items 偵測 |
| **onboarding** | 新專案初始化、目錄結構建立、CLAUDE.md 生成引導 |
| **schedule** | Sprint 自動排程執行、cron 腳本生成、序列排程保護 |
| **shoot** | 短衝模式、單 Story 快速執行、不起 Sprint 的輕量交付 |
| **diagram** | 架構圖自動化生成（drawio-mcp-server stdio 整合、雙格式輸出、多雲圖標集） |

</details>

---

## 進階設定

### 專案配置（CLAUDE.md）

安裝 plugin 後，將 `templates/CLAUDE.md.template` 複製到你的專案根目錄：

```bash
cp templates/CLAUDE.md.template ./CLAUDE.md
```

根據你的專案調整：專案名稱與技術棧、開發紅線、文件目錄結構、快速啟動指令。

### 專案等級（自治策略）

在 `CLAUDE.md` 中設定 AI 團隊的自治程度：

```
shikigami.project_level: medium
```

| 等級 | 適用場景 | 行為 |
|------|----------|------|
| **low** | 個人專案、實驗 | 完全自治，所有操作自動執行 |
| **medium**（預設） | 一般開發專案 | 低風險自動，高風險由 QA 審核後自動執行 |
| **high** | 重要產品、公開 repo | 低風險自動，高風險需人工確認 |

---

## 文件導覽

| 文件 | 用途 |
|------|------|
| [入門教學](docs/tutorial/GETTING_STARTED.md) | 從安裝到第一個 Sprint 的完整端對端步驟指引 |
| [Troubleshooting 指南](docs/tutorial/TROUBLESHOOTING.md) | 6 個常見失敗情境排查指南 |
| [版本歷程](docs/CHANGELOG.md) | 完整版本演進與 Sprint 紀錄 |
| [OpenCode 安裝](docs/INSTALL_OPENCODE.md) | OpenCode 平台詳細安裝步驟 |
| [Gemini CLI 安裝](docs/INSTALL_GEMINI.md) | Gemini CLI 平台詳細安裝步驟 |
| [Cursor 安裝](docs/INSTALL_CURSOR.md) | Cursor 平台詳細安裝步驟 |

---

## 授權

MIT
