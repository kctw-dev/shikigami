# 式神 Shikigami — AI Agent Scrum Team 框架

> 7 個 AI 隊友，各司其職，互相制衡 — 讓你的 AI 開發工具擁有一整組有紀律的工程團隊。

---

## 這是什麼？

你一個人開發，寫完的代碼沒人 review，架構決策靠直覺，安全問題等上線才發現。

Shikigami 是一個 **plugin 框架**，為你的 AI 開發工具注入 7 個專業角色（式神）。它們不只各自回答問題 — 而是組成一張**互相制衡的治理網**：QA 審你的代碼並挑戰架構決策，Security 審外部輸入，SRE 從維運角度評估部署可行性。**不需要記指令，用自然語言說你要做什麼**，Scrum Master 會自動調度對應角色。

這不是理論框架 — Shikigami 從第一天起就用自己開發自己：連續 29 個 Sprint 完成率 100%，交付 97 Stories，QA 雙階段審查攔截了每個 Sprint 的品質問題。

**當前版本：v0.13.0**（21 Skills / 7 Agents / 4 Commands）

---

## 快速開始

### 前置條件

在安裝 Shikigami 前，請確認以下條件已滿足：

1. **已安裝 Claude Code CLI** — 參閱 [Claude Code 官方文件](https://docs.anthropic.com/en/docs/claude-code) 完成安裝
2. **已完成 Claude Code 帳號認證** — 開啟 Claude Code 確認可正常對話（無 401 認證錯誤）
3. **網路連線正常** — 安裝過程需存取 Claude Code marketplace

### 安裝（Claude Code）

在 Claude Code 互動介面中執行以下指令：

```
# 1. 加入 marketplace（首次安裝）
/plugin marketplace add KCTW/shikigami

# 2. 安裝 plugin（二選一）
/plugin install shikigami          # 指令安裝
/plugin                            # 或開啟 UI → Discover → 選擇 shikigami
```

> **注意**：所有指令都在 Claude Code 互動介面中輸入（不是終端機 shell）。安裝後開新 session 即自動啟動。

### 第一步：初始化專案

安裝完成後，對 Claude 說：

```
> 幫我初始化 Shikigami
```

Scrum Master 會觸發 `onboarding`，引導你建立專案的 `CLAUDE.md` 與文件目錄結構。

---

## OpenCode 平台支援

Shikigami 支援在 **OpenCode** 平台上執行，讓非 Claude Code 訂閱者也能使用完整的 Shikigami 工作流。

OpenCode 採用 symlink 適配策略（[ADR-008 決策一](docs/adr/ADR-008.md)），使 `.opencode/skills/` 指向現有的 `skills/` 目錄，實現零複製的雙平台共用，無內容漂移風險。

**詳細安裝步驟請參閱：[docs/INSTALL_OPENCODE.md](docs/INSTALL_OPENCODE.md)**

安裝指南涵蓋：
- 前置需求（OpenCode 版本、git symlink 設定）
- 目錄結構設定（symlink 適配驗證）
- Agent 設定檔說明（5 個角色 `.opencode/agents/`）
- 首次 Sprint 快速上手（sprint-planning / sprint-execution / sprint-review）
- 模型選擇建議（推薦 Claude Sonnet / Claude Opus）
- Troubleshooting（5 個常見問題）

---

## Beta 使用者招募

> **[Beta 回饋收集 — 請在此留言分享你的使用經驗](https://github.com/KCTW/shikigami/issues/59)**

Shikigami 正在尋找第一批 Beta 使用者，歡迎試用並分享回饋，幫助我們驗證真實場景下的使用體驗。

**試用對象**：
- **Claude Code 使用者**：依照 [docs/tutorial/README.md](docs/tutorial/README.md) 完成安裝，走完一個 Sprint 週期
- **OpenCode 使用者**：依照 [docs/INSTALL_OPENCODE.md](docs/INSTALL_OPENCODE.md) 完成安裝（[OpenCode 安裝指南直連](docs/INSTALL_OPENCODE.md)），走完一個 Sprint 週期

完成安裝後留言即可。我們特別想了解：安裝是否順利、哪些步驟有卡關、Sprint 流程的實際感受。不需要長篇大論 — 一兩句話就很有幫助。

---

## 文件導覽

安裝完成後，以下文件幫助你快速上手：

| 文件 | 用途 |
|------|------|
| [入門教學](docs/tutorial/GETTING_STARTED.md) | 從安裝到第一個 Sprint 的完整端對端步驟指引，含指令範例與預期輸出摘要 |
| [Troubleshooting 指南](docs/tutorial/TROUBLESHOOTING.md) | 6 個常見失敗情境排查指南，含症狀描述、根因說明與解決步驟 |

---

## 怎麼用？

用自然語言說你要做什麼，Scrum Master 會自動調度。也可以用 Slash Commands 直接觸發流程：`/sprint`（Sprint 規劃）、`/standup`（每日站立會議）、`/review`（Sprint 回顧）、`/dispel`（Legacy 系統考古）。

以下是模擬互動範例：

### 從零開始一個功能

```
> 我想加一個自動回覆 issue 的功能

🔄 Scrum Master：偵測到「新功能需求」→ 觸發 backlog-management

📋 PO subagent：分析需求中...
   ✓ 需求理解：自動處理、回覆、管理 GitHub Issues
   ✓ 功能缺口：目前 0 個 Skill 涉及 GitHub Issue 管理
   ✓ 產出 4 個候選 User Stories（RICE 評分完成）

🏗️ Architect subagent：技術評估中...
   ✓ gh CLI 完整支援所有操作
   ✓ Story 2 需要 ADR（跨 Skill 編排決策）
   ✓ 建議 Skill 結構：SKILL.md + triage-prompt.md

📋 PO subagent：Backlog 已更新 → docs/prd/PRODUCT_BACKLOG.md
```

### Sprint 開發循環

```
> 開始 Sprint

🔄 Scrum Master：觸發 sprint-planning

📋 PO：從 Backlog 選取 3 個 Stories
🏗️ Architect：技術估算 — Story A(S), Story B(M), Story C(M)
🔍 QA：AC 可測試性確認 — 全部通過
📋 PO：Sprint 1 文件已建立 → docs/sprints/sprint_1.md

> 實作 Story A

🔄 Scrum Master：觸發 sprint-execution

👨‍💻 Developer subagent：
   🔴 Red — 寫失敗測試
   🟢 Green — 最小實作通過
   🔄 Refactor — 重構優化
   ✓ commit: "test: 新增功能測試"
   ✓ commit: "feat: 實作核心邏輯"

🔍 QA subagent（Spec Review）：✓ 所有 AC 通過
🔍 QA subagent（Code Quality）：✓ 品質門禁通過

🔄 Scrum Master（自動觸發）：所有 Story 完成 → 觸發 sprint-review
```

### Issue 管理

```
> 幫我分類一下 GitHub Issues

🔄 Scrum Master：觸發 issue-management → Triage 子流程

📋 PO subagent：
   ✓ gh issue list --search "no:label" → 找到 5 個未分類 issues
   ✓ 分類結果：
     | #12 登入失敗 | bug        | 已要求補充重現步驟 |
     | #13 希望支援匯出 | feature-request | —              |
     | #14 怎麼安裝？ | question   | 已引導至 README   |
   ✓ Labels 已自動套用

> 把 issue #13 轉成 Story

📋 PO subagent：
   ✓ 讀取 issue #13 內容
   ✓ 轉換為 User Story（待 RICE 評分）
   ✓ 寫入 PRODUCT_BACKLOG.md
   🔄 委派 backlog-management → PO 執行 RICE 評分
   ✓ issue #13 留言：「已轉入 Backlog」
   ✓ 套用 in-backlog label
```

### 架構決策

```
> 資料庫要用 PostgreSQL 還是 SQLite？

🔄 Scrum Master：觸發 architecture-decision

🏗️ Architect subagent：
   ✓ 建立 ADR-002
   ✓ 選項 A：PostgreSQL — 擴展性強，維運成本高
   ✓ 選項 B：SQLite — 零配置，單檔案，不適合高併發
   ✓ 建議：採用 SQLite（MVP 階段，KISS 原則）

🔍 QA subagent（Decision Challenger）：
   ⚔️ 為 PostgreSQL 辯護：未來遷移成本可能很高
   ✓ 結論：同意 SQLite，但建議抽象 DB 層以降低遷移風險

🏗️ Architect：ADR-002 狀態 → Accepted
```

> **提示**：你不需要精確匹配上面的用語。Scrum Master 會分析你的意圖，自動路由到對應流程。只要說出你想做什麼就好。

完整的開發流程是 **Discovery → Sprint Planning → Sprint Execution → Sprint Review** 四步循環，但你不必一次全用 — 隨時從任何一步開始，Scrum Master 會銜接上下文。

---

## 專案配置

安裝 plugin 後，將 `templates/CLAUDE.md.template` 複製到你的專案根目錄並重命名為 `CLAUDE.md`：

```bash
cp templates/CLAUDE.md.template ./CLAUDE.md
```

根據你的專案需求調整其中的：
- 專案名稱與技術棧
- 開發紅線
- 文件目錄結構
- 快速啟動指令

### 專案等級（自治策略）

在 `CLAUDE.md` 中設定專案等級，決定 AI 團隊的自治程度：

```
shikigami.project_level: medium
```

| 等級 | 適用場景 | 行為 |
|------|----------|------|
| **low** | 個人專案、實驗 | 完全自治，所有操作自動執行 |
| **medium**（預設） | 一般開發專案 | 低風險自動，高風險由 QA 審核後自動執行 |
| **high** | 重要產品、公開 repo | 低風險自動，高風險需人工確認 |

---

## 角色與能力

### 7 個角色

| 角色 | 職責 | 觸發時機 |
|---|---|---|
| **Product Owner** | 需求定義、優先級決策、Backlog 管理 | 需求討論、Sprint 規劃、功能排序 |
| **Architect** | 架構決策、SDD 撰寫、技術選型 | 技術選型、系統設計、效能瓶頸分析 |
| **Developer** | 功能實作、TDD 開發、Bug 修復 | Sprint 執行、代碼撰寫、技術實作 |
| **QA Engineer** | 代碼審查、測試策略、品質把關 | 功能完成、PR 審查、品質檢測 |
| **Security Engineer** | 安全掃描、漏洞評估、OWASP 檢查 | 外部輸入處理、API 端點、配置變更 |
| **SRE Engineer** | 部署檢查、監控配置、環境管理 | 部署準備、版本發布、環境變更 |
| **Stakeholder** | 最終仲裁、打破僵局 | 團隊升級鏈走完仍無法解決 |

**重點：它們會互相制衡。** 不是 7 個獨立助手，是一組有紀律的工程團隊。

### 21 個 Skills

**Scrum 流程**

| Skill | 說明 |
|---|---|
| **scrum-master** | 自動調度 Agent Scrum Team 的角色分工與 Sprint 流程 |
| **sprint-planning** | 啟動新 Sprint、從 Backlog 選取 Stories、規劃 Sprint 目標 |
| **sprint-execution** | 執行 Sprint Stories、功能實作、處理 Sprint Backlog |
| **sprint-review** | Sprint 結束時進行回顧與驗收、評估 Sprint 成果 |
| **backlog-management** | 新需求管理、需求變更、Backlog 梳理、產品探索 |
| **escalation** | 團隊衝突無法解決、重大產品轉向、升級鏈啟動 |

**工程實踐**

| Skill | 說明 |
|---|---|
| **architecture-decision** | 技術決策、架構審查、技術選型、ADR 撰寫 |
| **quality-gate** | 代碼審查、功能驗收、PR 檢查、品質指標檢測 |
| **security-review** | 外部輸入處理、API 安全、配置安全、漏洞評估 |
| **deployment-readiness** | 部署準備、版本發布、環境配置、生產就緒檢查 |
| **systematic-debugging** | Bug 排查、測試失敗分析、系統化除錯流程 |
| **dispel** | Legacy 系統考古、不熟悉 codebase 分析、解咒模式 |
| **architect** | Architect 角色知識框架、架構評估決策指引 |
| **qa-engineer** | QA 角色知識框架、審查策略與 Story-Lifecycle 整合指引 |

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

---

## 實戰驗證

Shikigami 用自己開發自己（dogfooding）。以下是完整的自治開發記錄。

### 版本歷程

| 版本 | 主題 | Sprint | 交付內容 |
|------|------|--------|----------|
| v0.1.0 | 核心框架 | Sprint 1 | 16 Skills + 7 Agents + 3 Commands + Issue Management |
| v0.2.0 | 自我感知 | Sprint 2–4 | Onboarding + Health Check + Sprint Metrics |
| v0.3.0 | 知識沉澱 | Sprint 4–6 | Retrospective Analytics + Tech Debt Registry + 5 驗證腳本 + Hard Gate 機制 |
| v0.3.x | 穩定化 | Sprint 7–15 | dispel 解咒模式 + CI Pipeline + 制衡案例 + Issue 回覆自動化 + Bypass 機制 + Token 成本透明化 + 孤兒文件偵測 + 零讀取架構 + 角色權重自動調整 + 使用者文件（Tutorial + Troubleshooting） |
| v0.5.x | 流程精煉 | Sprint 16–17 | 快思/慢想雙模式精簡化 + doc-only Story 執行保護 + 多平台可行性調查 + 歷史歸檔機制（PROJECT_BOARD + Retrospective_Log） |
| v0.7.x | 自動化擴展 | Sprint 18–20 | schedule Skill（Sprint 自動排程執行）+ ADR-005 + shoot 短衝模式 + /shoot Command + 序列排程保護 + PO drift 修正 |
| v0.9.x | 品質強化 | Sprint 21–24 | parallel-dispatch 同檔案衝突偵測 + Onboarding Labels + 提示注入防護（ADR-006）+ ADR-007 Story-Lifecycle Subagent + 外部抽樣審查機制 + Architect/QA 知識框架 Skill |
| v0.13.0 | 多平台支援 | Sprint 25–29 | M5 完成條件終審 + OpenCode 平台整合（ADR-008）+ symlink 適配策略 + 五角色 Agent 移植 + INSTALL_OPENCODE.md 安裝指南 + Issue #3 正式結案 + Beta 使用者招募 |

### 累積數據（截至 Sprint 29）

- 連續 29 個 Sprint 完成率 100%，Velocity 歷史：8→5→5→4→6→8→7→6→5→6→4→4→4→2→4→8→4→3→5→5→4→6→5→5→4→2→4→4→3
- 97 Stories 交付，8 個 ADR（架構決策紀錄）
- 8 個自動化驗證腳本 + GitHub Actions CI Pipeline

### 開發流程實證

| 流程 | 角色協作 |
|------|----------|
| **Product Discovery** | PO 分析需求 → Architect 評估可行性 → QA 確認驗收標準 |
| **Sprint Execution** | Developer 依 TDD 實作 → QA 雙階段審查（Spec Compliance + Code Quality） |
| **Architecture Decision** | Architect 提案 → QA 扮演 Decision Challenger 挑戰 → ADR 記錄決策 |
| **Sprint Review** | 自動觸發驗收 → Retrospective Analytics 展示趨勢 → Action Items 轉為 GitHub Issues |
| **Hard Gate** | 框架文件修改前 Preflight Check、儀式完整性稽核、Sprint 外變更偵測 |

### 產出文件

| 文件 | 說明 |
|------|------|
| `docs/adr/` | 架構決策紀錄（ADR-001 ~ ADR-008） |
| `docs/sprints/` | Sprint 規劃與執行紀錄（sprint_1 ~ sprint_29） |
| `docs/km/Retrospective_Log.md` | 每次犯的錯都記下來，不重複犯 |
| `docs/km/Metrics_Log.md` | Velocity 趨勢與完成率追蹤 |
| `docs/km/ROLE_BALANCE_CASES.md` | [真實制衡案例記錄](docs/km/ROLE_BALANCE_CASES.md) |
| `docs/prd/PRODUCT_BACKLOG.md` | RICE 評分排序的 Backlog |

---

## FAQ

### 式神跟 Plan Mode 會衝突嗎？

**會。** Plan Mode 是 Claude Code 內建的系統級功能，優先級高於任何 plugin。當 Plan Mode 啟動時，式神會被「封印」— Scrum Master 雖然已載入，但無法派遣 Subagent 執行寫入操作。

```
┌─────────────────────┐
│ Claude Code 系統層    │  ← Plan Mode 在這裡（優先級最高）
├─────────────────────┤
│ Plugin 層            │  ← Shikigami 在這裡
├─────────────────────┤
│ 執行層               │  ← 實際做事在這裡
└─────────────────────┘
```

**建議**：二選一。如果要用式神的 Scrum 流程，就不要進 Plan Mode — 直接說你想做什麼，讓 Scrum Master 調度。

### 怎麼確認式神有沒有啟動？

安裝後開新 Session，觀察以下特徵：
- 系統提示中出現 `shikigami:` 前綴的 Skills（如 `shikigami:scrum-master`）
- 說「你有 shikigami superpowers 嗎？」— 有載入的話 Claude 會知道
- 工作過程中會看到 Subagent 派遣（如 `shikigami:developer`、`shikigami:qa-engineer`）

### 式神工作時有什麼特徵？

| 特徵 | 說明 |
|------|------|
| Skill 調用 | 看到 `invoke shikigami:xxx` |
| Subagent 派遣 | 看到 `subagent_type: shikigami:developer` 等 |
| Scrum 流程語言 | Sprint Planning、TDD 循環、Quality Gate、DoD 自檢 |
| 結構化文件產出 | `docs/prd/`、`docs/adr/`、`docs/sprints/` |
| 角色制衡 | Developer 寫完 → QA 審、Architect 決策 → QA 挑戰 |

### 專案等級設成 low 會不會太危險？

`low` 等級適合**個人專案和實驗**。所有操作自動執行，不需人工確認。如果你的 repo 是公開的且有外部使用者，建議用 `medium`（QA 審核高風險操作）或 `high`（人工確認）。

### 可以只用部分功能嗎？

可以。式神不強制你走完整 Scrum 流程。你可以：
- 只用 `systematic-debugging` 做除錯
- 只用 `quality-gate` 做代碼審查
- 只用 `issue-management` 管理 GitHub Issues
- 日常開發時 Scrum Master 會自動判斷不需要啟動角色，直接幫你做

---

## 授權

MIT
