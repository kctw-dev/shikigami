# Shikigami on Gemini CLI — 安裝指南

**文件版本**：1.0
**最後更新**：2026-03-03

> 本指南適用於想在 **Gemini CLI** 平台上執行 Shikigami 的使用者。如果你使用的是 Claude Code，請參閱 [README.md](../README.md) 中的快速開始章節。如果你使用的是 OpenCode，請參閱 [INSTALL_OPENCODE.md](./INSTALL_OPENCODE.md)。

---

## 目錄

1. [前置需求](#1-前置需求)
2. [安裝方式](#2-安裝方式)
3. [目錄結構說明](#3-目錄結構說明)
4. [首次 Sprint 快速上手](#4-首次-sprint-快速上手)
5. [模型選擇建議](#5-模型選擇建議)
6. [Troubleshooting](#6-troubleshooting)

---

## 1. 前置需求

在開始安裝前，請確認以下條件已滿足：

### 1.1 系統需求

| 需求 | 說明 |
|------|------|
| **Gemini CLI** | 已安裝 Gemini CLI。快速安裝：`npm install -g @anthropic-ai/gemini-cli` 或參閱 [Gemini CLI 官方文件](https://geminicli.com/docs/) |
| **Git** | 已安裝 Git（v2.0 以上），且已完成基本 git 設定（`user.name`、`user.email`） |
| **gh CLI**（選用） | 如需使用 `issue-management` 等 GitHub 整合功能，需安裝並認證 [GitHub CLI](https://cli.github.com/) |

---

## 2. 安裝方式

Shikigami 以 Gemini CLI Extension 形式安裝，一行指令即可完成：

```bash
gemini extensions install https://github.com/KCTW/shikigami
```

### 2.1 驗證安裝

安裝完成後，確認 extension 已載入：

```bash
gemini extensions list
```

預期輸出應包含 `shikigami`。

### 2.2 驗證 Skills 載入

啟動 Gemini CLI 後，確認 Skills 可被發現。在互動介面中輸入：

```
> list skills
```

預期看到 Shikigami 的 22 個 Skills（sprint-planning、sprint-execution、sprint-review 等）。

### 2.3 驗證 Commands 可用

確認自定義 commands 可用：

```
/shikigami:sprint
```

若顯示 Sprint Planning 流程啟動，代表 commands 已正確載入。

---

## 3. 目錄結構說明

Shikigami 安裝為 Gemini CLI extension 後，以下結構自動生效：

```
shikigami/                     ← Extension 根目錄
├── gemini-extension.json      ← Extension manifest（入口）
├── GEMINI.md                  ← Framework context file（每 session 自動注入）
├── skills/                    ← 22 個 Skills（Gemini CLI 原生自動發現）
│   ├── scrum-master/SKILL.md
│   ├── sprint-planning/SKILL.md
│   ├── sprint-execution/SKILL.md
│   └── ...
├── .gemini/
│   └── commands/shikigami/    ← 4 個自定義 commands（TOML 格式）
│       ├── sprint.toml        → /shikigami:sprint
│       ├── standup.toml       → /shikigami:standup
│       ├── review.toml        → /shikigami:review
│       └── dispel.toml        → /shikigami:dispel
├── agents/                    ← 7 個角色 system prompt
└── templates/                 ← 專案初始化範本
    └── GEMINI.md.template     ← 使用者專案配置範本
```

### 3.1 架構優勢

與 OpenCode 整合不同，Gemini CLI 整合**不需要 symlink**：

- Gemini CLI 的 extension 架構原生支援 `skills/*/SKILL.md` 格式
- Skills 自動發現，無需手動配置
- `GEMINI.md` 透過 `gemini-extension.json` 的 `contextFileName` 欄位自動注入每個 session
- 這是 Shikigami 三個支援平台中適配最簡單的

---

## 4. 首次 Sprint 快速上手

本節提供從初始化到完成一個完整 Sprint 的快速上手流程。

### 4.1 專案初始化

在 Gemini CLI 中開啟你的專案目錄，使用自然語言啟動 onboarding：

```
> Initialize Shikigami for my project
```

或直接觸發 onboarding Skill：

```
> Use onboarding skill
```

Scrum Master 會引導你建立專案的 `GEMINI.md` 與文件目錄結構。

### 4.2 Sprint Planning

準備好需求後，啟動 Sprint Planning：

```
> Start Sprint Planning
```

或使用 command：

```
/shikigami:sprint
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

或使用 Skill：

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

或使用 command：

```
/shikigami:review
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

Gemini CLI 預設使用 Gemini 系列模型。Shikigami 的 SKILL.md prompt 工程主要針對 Claude 系列模型最佳化，但也相容其他高品質 LLM。

| 推薦程度 | 模型 | 說明 |
|---------|------|------|
| **強烈推薦** | Gemini 2.5 Pro / Gemini 2.5 Flash | Gemini CLI 預設模型，與 extension 架構整合最佳 |
| **可用** | 其他 Gemini CLI 支援的模型 | 基本功能可用，但複雜的多角色 Scrum 流程可能需要較強的模型 |

在 Gemini CLI 設定中指定模型：

```bash
gemini --model gemini-2.5-pro
```

或在 Gemini CLI 設定檔中設定預設模型（參閱 [Gemini CLI 設定文件](https://geminicli.com/docs/reference/configuration/)）。

---

## 6. Troubleshooting

### 問題 1：Skills 無法被 Gemini CLI 發現

**症狀**：Shikigami Skills 未出現在 skill 清單中。

**根因**：Extension 未正確安裝或載入。

**解決步驟**：

1. 確認 extension 已安裝：

```bash
gemini extensions list
# 應看到 shikigami
```

2. 若未列出，重新安裝：

```bash
gemini extensions install https://github.com/KCTW/shikigami
```

3. 確認 `gemini-extension.json` 存在於 extension 目錄中。

---

### 問題 2：Commands 不可用

**症狀**：輸入 `/shikigami:sprint` 等 command 無反應或報錯。

**根因**：TOML command 檔案未被 Gemini CLI 發現。

**解決步驟**：

1. 在 Gemini CLI 中執行 `/commands reload` 重新載入 commands。

2. 確認 command 檔案存在：

```bash
ls .gemini/commands/shikigami/
# 應看到 sprint.toml standup.toml review.toml dispel.toml
```

---

### 問題 3：GEMINI.md 未自動注入

**症狀**：啟動 session 後 Scrum Master 行為未載入，輸入指令後無 Shikigami 調度反應。

**根因**：`contextFileName` 配置未生效。

**解決步驟**：

1. 確認 `gemini-extension.json` 包含 `contextFileName` 欄位：

```bash
cat gemini-extension.json | grep contextFileName
# 應看到 "contextFileName": "GEMINI.md"
```

2. 確認 `GEMINI.md` 存在於 extension 根目錄。

3. 在 Gemini CLI 中使用 `/memory show` 檢查已載入的 context 文件。

---

### 問題 4：Subagent 派遣失敗

**症狀**：Scrum Master 嘗試派遣 Developer / QA 等角色時失敗。

**根因**：Gemini CLI 的 sub-agent API 與 Shikigami 預期格式可能存在差異。

**解決步驟**：

1. 確認 `agents/` 目錄下的角色 system prompt 檔案存在：

```bash
ls agents/
# 應看到 developer.md architect.md qa-engineer.md product-owner.md security-engineer.md sre-engineer.md stakeholder.md
```

2. 嘗試更明確的指令觸發：

```
> Use sprint-execution skill to implement US-01
```

3. 若問題持續，可使用自然語言直接描述任務，Scrum Master 會嘗試在主 session 內處理。

---

### 問題 5：SKILL.md 中出現不認識的 `claude -p` 語法

**症狀**：在 SKILL.md 中看到 `claude -p "/sprint-planning"` 等指令，在 Gemini CLI 中無法執行。

**說明**：這些是**說明性殘留項**，標注了 Claude Code 的等效指令語法，不影響 Gemini CLI 的 SKILL.md 載入與執行。Shikigami 的 Skills 設計為平台無關，這些語法僅為文件說明用途。

**解決方式**：忽略這些說明性語法。在 Gemini CLI 中，直接透過自然語言或 Skill 名稱觸發。

---

### 問題 6：`~/.claude/projects/` 路徑相關功能異常

**症狀**：Sprint Planning 的 token 慢想模式記錄步驟出現路徑錯誤。

**說明**：`~/.claude/projects/` 是 Claude Code 特有的 session 資料路徑，在 Gemini CLI 中不存在。SKILL.md 已內建降級機制，會填入「N/A」繼續執行，不影響主流程。

**解決方式**：此為已知的平台差異，不影響核心 Sprint 流程，可安全忽略。

---

## 相關文件

| 文件 | 用途 |
|------|------|
| [gemini-extension.json](../gemini-extension.json) | Gemini CLI Extension manifest |
| [GEMINI.md](../GEMINI.md) | Framework context file，每 session 自動注入 |
| [README.md](../README.md) | 完整功能說明、7 個角色、22 個 Skills |
| [INSTALL_OPENCODE.md](./INSTALL_OPENCODE.md) | OpenCode 平台安裝指南 |
| [Gemini CLI Extensions 文件](https://geminicli.com/docs/extensions/) | Gemini CLI Extension 官方文件 |
| [Gemini CLI Custom Commands 文件](https://geminicli.com/docs/cli/custom-commands/) | Gemini CLI 自定義 commands 官方文件 |
