# Shikigami on OpenCode — 安裝指南

**文件版本**：1.0（US-50 Phase 3b，Sprint 28）
**最後更新**：2026-03-03
**關聯 ADR**：[ADR-008 OpenCode 平台整合策略](./adr/ADR-008.md)

> 本指南適用於想在 **OpenCode** 平台上執行 Shikigami 的外部使用者。如果你使用的是 Claude Code，請參閱 [README.md](../../README.md) 中的快速開始章節。

---

## 目錄

1. [前置需求](#1-前置需求)
2. [目錄結構設定（Symlink 適配）](#2-目錄結構設定symlink-適配)
3. [Agent 設定檔說明](#3-agent-設定檔說明)
4. [首次 Sprint 快速上手](#4-首次-sprint-快速上手)
5. [模型選擇建議](#5-模型選擇建議)
6. [Troubleshooting](#6-troubleshooting)

---

## 1. 前置需求

在開始安裝前，請確認以下條件已滿足：

### 1.1 系統需求

| 需求 | 說明 |
|------|------|
| **OpenCode** | 已安裝 OpenCode CLI（建議 v1.0.190 以上）。參閱 [OpenCode 官方文件](https://opencode.ai/docs/) 完成安裝。 |
| **Git** | 已安裝 Git（v2.0 以上），且已完成基本 git 設定（`user.name`、`user.email`） |
| **gh CLI**（選用） | 如需使用 `issue-management` 等 GitHub 整合功能，需安裝並認證 [GitHub CLI](https://cli.github.com/) |

### 1.2 Shikigami 儲存庫

你需要先 clone Shikigami 儲存庫到本地端：

```bash
git clone https://github.com/KCTW/shikigami.git
cd shikigami
```

> **注意**：Shikigami 採用的是 symlink 適配策略（詳見 [ADR-008 決策一](#adr-008-決策一引用)）。Clone 後請務必確認 symlink 已正確還原（見第 2 節）。

### 1.3 Symlink 支援（Windows 使用者注意）

Windows 環境下，git 預設不追蹤 symlink。請在 clone 前執行：

```bash
git config core.symlinks true
```

---

## 2. 目錄結構設定（Symlink 適配）

### ADR-008 決策一引用

Shikigami 採用 **Symlink 適配策略**（ADR-008 決策一）作為唯一正式支援的目錄整合方式：

> `skills/` 目錄為唯一內容來源（Claude Code 主平台）。OpenCode 透過 `.opencode/skills -> ../skills` symlink 存取所有 21 個 SKILL.md，實現零複製的路徑適配，確保兩個平台共用同一份 SKILL.md，不存在內容漂移問題。

**完整目錄結構定義（ADR-008 決策一）**：

```
shikigami/
├── skills/                        ← 唯一來源（Claude Code 主平台）
│   ├── sprint-planning/SKILL.md
│   ├── sprint-execution/SKILL.md
│   └── ...（共 21 個技能）
├── .opencode/                     ← OpenCode 平台適配目錄
│   ├── skills -> ../skills        ← symlink（git 追蹤中）
│   └── agents/                   ← subagent 設定檔目錄
│       ├── developer.md
│       ├── architect.md
│       ├── qa-engineer.md
│       ├── product-owner.md
│       └── security-engineer.md
└── AGENTS.md                      ← OpenCode 框架入口
```

### 2.1 確認 Symlink 狀態

clone 後執行以下指令，確認 symlink 已正確建立：

```bash
ls -la .opencode/
```

預期輸出應包含：

```
skills -> ../skills
```

若 symlink 已正確存在（git 已追蹤此 symlink），代表設定完成，**無需手動建立**。

### 2.2 手動建立 Symlink（僅在 symlink 缺失時執行）

若 `ls -la .opencode/` 的輸出中沒有 `skills -> ../skills`，手動執行：

```bash
cd .opencode
ln -s ../skills skills
cd ..
```

驗證：

```bash
ls .opencode/skills/sprint-planning/SKILL.md
# 應輸出該檔案路徑，表示 symlink 正確解析
```

### 2.3 驗證 OpenCode 可發現 Skills

啟動 OpenCode 後，確認 Skills 可被發現：

```bash
opencode
```

在 OpenCode 互動介面中輸入：

```
> list skills
```

預期看到 Shikigami 的 21 個 Skills（sprint-planning、sprint-execution、sprint-review 等）。

---

## 3. Agent 設定檔說明

Shikigami 的五個核心角色已預先設定於 `.opencode/agents/` 目錄下，無需額外設定即可使用。

### 3.1 角色設定檔一覽

| 設定檔 | 角色 | 職責摘要 |
|--------|------|---------|
| `.opencode/agents/developer.md` | Developer | TDD 實作、衝突偵測、技術債管理 |
| `.opencode/agents/architect.md` | Architect | T-shirt 估點、ADR 決策管理、平行分群策略 |
| `.opencode/agents/product-owner.md` | Product Owner | Backlog 管理、Sprint 目標定義、Story 選取 |
| `.opencode/agents/qa-engineer.md` | QA Engineer | AC 驗證、Spec Compliance、Code Quality Review |
| `.opencode/agents/security-engineer.md` | Security Engineer | OWASP Top 10、弱點掃描、Secrets 稽核 |

> **Scrum Master**：Scrum Master 是主 session 編排者（非被派遣 subagent），由 `AGENTS.md` 框架入口直接承擔，無獨立 agent 設定檔。

### 3.2 設定檔格式說明

每個設定檔採用 YAML frontmatter + Markdown 格式（ADR-008 決策三規範）：

```yaml
---
name: developer
description: Senior full-stack developer implementing User Stories with TDD discipline
model: sonnet
---

# 角色 system prompt 正文...
```

### 3.3 Subagent 派遣方式

在 OpenCode 中，Scrum Master（主 session）透過 Task tool 按需派遣上述角色：

- Scrum Master 讀取 `.opencode/agents/<role>.md` 作為 subagent system prompt
- 以 Task tool 傳入任務描述
- 接收 subagent 回傳結果

> **已知待確認項**：Task tool 的具體參數欄位命名（`description`、`prompt` 等）需在實機環境中對照 OpenCode 官方文件確認（詳見 OPENCODE_POC.md Phase 3c）。

---

## 4. 首次 Sprint 快速上手

本節提供從初始化到完成一個完整 Sprint 的快速上手流程。

### 4.1 專案初始化

在 OpenCode 中開啟你的專案目錄，使用自然語言啟動 onboarding：

```
> Initialize Shikigami for my project
```

或直接觸發 onboarding Skill：

```
> Use onboarding skill
```

Scrum Master 會引導你建立專案的設定檔（`CLAUDE.md` 或等效的 project config）與文件目錄結構。

### 4.2 Sprint Planning

準備好需求後，啟動 Sprint Planning：

```
> Start Sprint Planning
```

或：

```
> Use sprint-planning skill
```

**流程說明**：

1. **PO Subagent** — 從 Backlog 選取 Stories，定義 Sprint 目標
2. **Architect Subagent** — 技術估算（S/M/L 估點）、平行分群建議
3. **QA Subagent** — AC 可測試性確認（靜態/動態判定）
4. **PO Subagent** — Sprint Backlog 最終確認，建立 Sprint 文件

預期產出：`docs/sprints/sprint_N.md`（Sprint 規劃文件）

### 4.3 Sprint Execution

開始實作 Story：

```
> Implement US-01
```

或：

```
> Use sprint-execution skill
```

**流程說明**：

1. **Developer Subagent** — 依 TDD 流程實作（Red → Green → Refactor）
2. **QA Subagent（Spec Compliance）** — 驗證 Acceptance Criteria 通過
3. **QA Subagent（Code Quality）** — 品質門禁審查

### 4.4 Sprint Review

Sprint 結束時進行回顧：

```
> Run Sprint Review
```

或：

```
> Use sprint-review skill
```

**流程說明**：

1. 驗收所有 Stories 的 DoD（Definition of Done）
2. 產出 Retrospective 記錄
3. 更新 Metrics（Velocity、完成率）
4. Action Items 轉為 GitHub Issues（需 gh CLI）

### 4.5 自然語言觸發（推薦方式）

你不需要精確匹配上面的指令。Scrum Master 會分析你的意圖，自動路由到對應的 Skill：

```
> 我想開始新的 Sprint
> 幫我實作登入功能
> 資料庫要用 PostgreSQL 還是 SQLite？
> 幫我看一下這段代碼有沒有安全問題
```

---

## 5. 模型選擇建議

OpenCode 是 model-agnostic 平台，支援多種 LLM。由於 Shikigami 的 SKILL.md prompt 工程針對 Claude 系列模型最佳化，建議優先選擇：

| 推薦程度 | 模型 | 說明 |
|---------|------|------|
| **強烈推薦** | Claude Sonnet / Claude Opus（Anthropic）| Shikigami 開發與驗證環境，prompt 相容性最佳 |
| **可用** | 其他高品質 LLM | 基本功能可用，但複雜的多角色 Scrum 流程可能需要調整 prompt |

在 OpenCode 設定中指定模型：

```bash
opencode --model anthropic/claude-sonnet-4-5
```

或在 OpenCode 設定檔中設定預設模型（參閱 [OpenCode 設定文件](https://opencode.ai/docs/)）。

---

## 6. Troubleshooting

### 問題 1：Skills 無法被 OpenCode 發現

**症狀**：輸入 `list skills` 後看不到 Shikigami 的 Skills，或 `sprint-planning` 等 Skill 不存在。

**根因**：`.opencode/skills` symlink 未正確建立或解析失敗。

**解決步驟**：

1. 確認 symlink 存在：

```bash
ls -la .opencode/
# 應看到 skills -> ../skills
```

2. 若 symlink 不存在，手動建立：

```bash
cd .opencode && ln -s ../skills skills && cd ..
```

3. 確認 symlink 解析正確：

```bash
ls .opencode/skills/sprint-planning/SKILL.md
# 應輸出檔案路徑
```

4. Windows 使用者：確認 git 設定支援 symlink：

```bash
git config core.symlinks true
git checkout .  # 重新還原 symlink
```

---

### 問題 2：Subagent 派遣失敗

**症狀**：Scrum Master 嘗試派遣 Developer / QA 等角色時失敗，或 Task tool 呼叫報錯。

**根因可能**：

- Task tool 參數格式與 OpenCode 版本不符
- `.opencode/agents/` 設定檔格式問題

**解決步驟**：

1. 確認 agent 設定檔存在：

```bash
ls .opencode/agents/
# 應看到 developer.md architect.md qa-engineer.md product-owner.md security-engineer.md
```

2. 確認設定檔格式正確（YAML frontmatter 完整）：

```bash
head -5 .opencode/agents/developer.md
# 應看到 ---\nname: developer\ndescription: ...\nmodel: sonnet\n---
```

3. 對照 [OpenCode Agents 文件](https://opencode.ai/docs/agents/) 確認 Task tool 參數格式是否有版本變更。

4. 若問題持續，可手動直接呼叫 Subagent（使用 `@mention`）：

```
> @developer implement US-01 with TDD
```

---

### 問題 3：SKILL.md 中出現不認識的 `claude -p` 語法

**症狀**：在 SKILL.md 中看到 `claude -p "/sprint-planning"` 等指令，在 OpenCode 中無法執行。

**說明**：這些是 **說明性殘留項**（R-4、R-5、R-6），標注了 Claude Code 的等效指令語法，不影響 OpenCode 的 SKILL.md 載入與執行。這是 ADR-008 決策二的雙平台標注機制，保留 Claude Code 用戶的使用說明。

**解決方式**：忽略這些說明性語法。在 OpenCode 中，直接透過自然語言或 Skill 名稱觸發，例如：

```
> Use sprint-planning skill
```

---

### 問題 4：`~/.claude/projects/` 路徑相關功能異常

**症狀**：Sprint Planning 的 token 慢想模式記錄步驟出現路徑錯誤或找不到檔案。

**說明**：`~/.claude/projects/` 是 Claude Code 特有的 session 資料路徑（殘留項 R-3），在 OpenCode 中不存在。SKILL.md 已內建降級機制，會填入「N/A」繼續執行，不影響主流程。

**解決方式**：此為已知的平台差異（Phase 1 識別），不影響核心 Sprint 流程，可安全忽略。

---

### 問題 5：Scrum Master 無法辨識意圖

**症狀**：輸入後 Scrum Master 沒有觸發對應 Skill，或回應不符預期。

**解決步驟**：

1. 確認 `AGENTS.md` 已被 OpenCode 載入（它是框架入口）：

```
> What is your role?
```

如果 OpenCode 正確載入了 `AGENTS.md`，它會描述 Scrum Master 的角色與能力。

2. 嘗試更明確的指令：

```
> Use sprint-planning skill to start a new Sprint
> Use sprint-execution skill to implement US-01
```

3. 若仍有問題，確認你的 OpenCode 版本支援 `AGENTS.md` 作為 session 入口（參閱 [OpenCode 文件](https://opencode.ai/docs/)）。

---

## 相關文件

| 文件 | 用途 |
|------|------|
| [AGENTS.md](../../AGENTS.md) | OpenCode 框架入口，角色定義與 Skill 載入說明 |
| [ADR-008](./adr/ADR-008.md) | OpenCode 平台整合架構決策記錄 |
| [OPENCODE_POC.md](./km/OPENCODE_POC.md) | OpenCode POC 可行性調查報告與各 Phase 完成記錄 |
| [README.md](../../README.md) | 完整功能說明、7 個角色、21 個 Skills |
| [OpenCode 官方 Skills 文件](https://opencode.ai/docs/skills/) | OpenCode Skills 規範參考 |
| [OpenCode 官方 Agents 文件](https://opencode.ai/docs/agents/) | OpenCode Agents 規範參考 |
