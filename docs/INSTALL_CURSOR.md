# Shikigami on Cursor — 安裝指南

**文件版本**：1.0（US-191，Sprint 72）
**最後更新**：2026-03-10
**關聯調查報告**：[CURSOR_COMPATIBILITY_SURVEY.md](./CURSOR_COMPATIBILITY_SURVEY.md)

> 本指南適用於想在 **Cursor** 平台上執行 Shikigami 的使用者。
> 如果你使用的是 Claude Code，請參閱 [README.md](../README.md) 中的快速開始章節。
> 如果你使用的是 OpenCode，請參閱 [INSTALL_OPENCODE.md](./INSTALL_OPENCODE.md)。
> 如果你使用的是 Gemini CLI，請參閱 [INSTALL_GEMINI.md](./INSTALL_GEMINI.md)。

---

## 重要說明：平台限制

Cursor **部分支援** Shikigami 工作流（88% Skills 可用）。使用前請了解以下限制：

| 限制 | 說明 | 影響 |
|------|------|------|
| 無 SessionStart Hook | Scrum Master 不自動注入，需 alwaysApply Rule 替代 | 低，功能等效 |
| 無獨立 Subagent context | 所有角色在同一 Chat session 執行 | 中，建議每個 Story 開新 Chat |
| parallel-dispatch 不可用 | 無平行 Agent 機制，改為循序執行 | 低，結果等效 |

如需完整的 Subagent context 隔離，建議使用 Claude Code 平台。

---

## 目錄

1. [前置需求](#1-前置需求)
2. [安裝方式](#2-安裝方式)
3. [Cursor Rules 設定](#3-cursor-rules-設定)
4. [首次 Sprint 快速上手](#4-首次-sprint-快速上手)
5. [模型選擇建議](#5-模型選擇建議)
6. [Troubleshooting](#6-troubleshooting)

---

## 1. 前置需求

在開始安裝前，請確認以下條件已滿足：

### 1.1 系統需求

| 需求 | 說明 |
|------|------|
| **Cursor** | 已安裝 Cursor 編輯器（建議最新版）。下載：[cursor.com](https://cursor.com) |
| **Git** | 已安裝 Git（v2.0 以上），且已完成基本 git 設定（`user.name`、`user.email`） |
| **gh CLI**（選用） | 如需使用 `issue-management` 等 GitHub 整合功能，需安裝並認證 [GitHub CLI](https://cli.github.com/) |
| **AI 訂閱** | Cursor Pro 訂閱（建議），或 API key（Claude / GPT-4 等） |

### 1.2 Shikigami 儲存庫

你需要先 clone Shikigami 儲存庫到本地端：

```bash
git clone https://github.com/KCTW/shikigami.git
cd shikigami
```

---

## 2. 安裝方式

Shikigami 在 Cursor 中透過 **`.cursor/rules/`** 目錄適配，採用 symlink 策略（與 OpenCode 類似）。

### 2.1 建立目錄結構

在 Shikigami 專案根目錄執行：

```bash
# 建立 Cursor 適配目錄
mkdir -p .cursor/rules

# 建立 skills symlink（使 Cursor Rules 可引用 Skill 內容）
ln -s ../skills .cursor/skills
```

### 2.2 安裝 Scrum Master 常駐 Rule

建立 Scrum Master 常駐規則（替代 Claude Code 的 SessionStart Hook）：

```bash
cat > .cursor/rules/shikigami-scrum-master.mdc << 'EOF'
---
description: "Shikigami Scrum Master — 自動調度 AI Agent Scrum Team"
alwaysApply: true
---

EOF
# 將 SKILL.md 內容附加
cat skills/scrum-master/SKILL.md >> .cursor/rules/shikigami-scrum-master.mdc
```

> **說明**：`alwaysApply: true` 使 Scrum Master 規則在每次 AI 請求時自動包含，替代 Claude Code 的 `SessionStart` Hook 自動注入機制。

### 2.3 安裝所有 Skills

執行自動化安裝腳本，將所有 Skills 轉換為 Cursor Rules：

```bash
# 使用提供的安裝腳本
bash scripts/install-cursor.sh
```

若腳本不存在，手動建立 Rules（對每個需要的 Skill 執行）：

```bash
# 範例：安裝 sprint-planning Skill
cat > .cursor/rules/shikigami-sprint-planning.mdc << 'EOF'
---
description: "Shikigami sprint-planning — 啟動新 Sprint、從 Backlog 選取 Stories、規劃 Sprint 目標"
alwaysApply: false
---

EOF
cat skills/sprint-planning/SKILL.md >> .cursor/rules/shikigami-sprint-planning.mdc
```

對以下核心 Skills 重複上述步驟：`sprint-execution`、`sprint-review`、`backlog-management`、`architecture-decision`、`quality-gate`、`security-review`。

### 2.4 驗證安裝

確認 Rules 已建立：

```bash
ls .cursor/rules/
# 應看到 shikigami-scrum-master.mdc 等檔案
```

在 Cursor 中開啟專案，並在 Chat 中輸入：

```
你有 shikigami superpowers 嗎？
```

若 Cursor 正確回應 Scrum Master 角色介紹，代表安裝成功。

---

## 3. Cursor Rules 設定

### 3.1 目錄結構說明

安裝完成後的目錄結構：

```
shikigami/
├── skills/                          ← 唯一來源（所有平台共用）
│   ├── scrum-master/SKILL.md
│   ├── sprint-planning/SKILL.md
│   └── ...（共 25 個技能）
├── .cursor/                         ← Cursor 平台適配目錄
│   ├── skills -> ../skills          ← symlink（可選）
│   └── rules/                       ← Cursor Rules 目錄
│       ├── shikigami-scrum-master.mdc    ← alwaysApply: true
│       ├── shikigami-sprint-planning.mdc
│       ├── shikigami-sprint-execution.mdc
│       └── ...（核心 Skills）
└── README.md
```

### 3.2 Rule 格式說明

每個 `.mdc` 檔案使用以下格式：

```markdown
---
description: "<Skill 名稱> — <功能簡述>"
alwaysApply: false    # scrum-master 設為 true，其餘設為 false
---

# （SKILL.md 內容直接貼入）
```

### 3.3 觸發方式

在 Cursor Chat 中，透過以下方式觸發 Skills：

| 方式 | 範例 |
|------|------|
| **自然語言（推薦）** | `我想開始新的 Sprint` |
| **明確指令** | `Use sprint-planning skill` |
| **@mentions** | `@shikigami-sprint-planning 開始規劃` |
| **Agent Mode** | 切換至 Agent Mode 後自然語言操作 |

> **重要**：複雜的多角色工作流（Sprint Execution 等）建議使用 **Cursor Agent Mode**，讓 AI 自主執行多步驟任務。

### 3.4 Cursor Agent Mode 使用建議

Shikigami 的 Sprint Execution 涉及多角色協作，在 Cursor 中建議：

1. 開啟 Cursor Chat → 切換至 **Agent** 模式
2. 輸入任務描述
3. 讓 Cursor Agent 自主執行（含 Terminal 工具、檔案讀寫等）

```
> [Agent Mode] 請依照 sprint-execution skill 執行 US-01 的開發，
  包含 TDD 紅燈→綠燈→重構，以及 QA spec compliance 和 code quality 審查。
```

**最佳實踐**：每個 Story 開一個新的 Cursor Chat，避免不同 Story 的 context 相互干擾。

---

## 4. 首次 Sprint 快速上手

以下 5 步驟帶你從安裝完成到第一次 Sprint 執行，目標在 **30 分鐘內完成**。

### 步驟 1 — 確認安裝（2 分鐘）

在 Cursor Chat 中輸入：

```
你有 shikigami superpowers 嗎？
```

預期看到 Scrum Master 角色介紹與可用 Skills 清單。

### 步驟 2 — 初始化你的專案（5 分鐘）

切換至 **Agent Mode**，在你的**專案目錄**中執行：

```
> 幫我初始化 Shikigami
```

或：

```
> Use onboarding skill to initialize my project
```

Scrum Master 會引導你建立 `CLAUDE.md`（或 `.cursorrules`）與 `docs/` 目錄結構。

### 步驟 3 — 建立 Backlog（5 分鐘）

```
> 我想加一個功能：[描述你的功能需求]
```

Scrum Master 會觸發 `backlog-management`，PO subagent 分析需求並寫入 Backlog。

### 步驟 4 — Sprint Planning（10 分鐘）

```
> 開始 Sprint Planning
```

或：

```
> Use sprint-planning skill
```

**預期流程**：
1. PO（角色切換）從 Backlog 選取 Stories，定義 Sprint 目標
2. Architect（角色切換）技術估算（S/M/L 估點）
3. QA（角色切換）AC 可測試性確認
4. 產出：`docs/sprints/sprint_N.md`

### 步驟 5 — 執行第一個 Story（10 分鐘）

```
> 實作 US-01
```

或：

```
> Use sprint-execution skill to implement US-01
```

**預期流程**（Cursor Agent Mode 中執行）：
1. Developer 角色：TDD Red → Green → Refactor
2. QA 角色：Spec Compliance 審查
3. QA 角色：Code Quality 審查
4. commit，Story 標記完成

---

## 5. 模型選擇建議

Cursor 支援多種 AI 模型。由於 Shikigami 的 SKILL.md prompt 工程針對 Claude 系列模型最佳化：

| 推薦程度 | 模型 | 說明 |
|---------|------|------|
| **強烈推薦** | Claude Sonnet 4.5 / Claude Opus 4 | Shikigami 開發與驗證環境，prompt 相容性最佳 |
| **可用** | GPT-4o / GPT-4 Turbo | 基本功能可用，複雜多角色流程可能需要調整 prompt |
| **不推薦** | GPT-3.5 Turbo / 小型模型 | 複雜 Scrum 流程可能無法完整執行 |

在 Cursor 設定中選擇模型：**Cursor 設定 → Models → 選擇 claude-sonnet-4-5 或 claude-opus-4**

---

## 6. Troubleshooting

### 問題 1：Cursor 沒有顯示 Scrum Master 角色

**症狀**：輸入問候語後，Cursor 沒有描述 Scrum Master 或 Shikigami 框架。

**根因**：`.cursor/rules/shikigami-scrum-master.mdc` 未建立或格式錯誤。

**解決步驟**：

1. 確認 Rule 檔案存在：
```bash
ls .cursor/rules/
# 應看到 shikigami-scrum-master.mdc
```

2. 確認 YAML frontmatter 格式正確：
```bash
head -5 .cursor/rules/shikigami-scrum-master.mdc
# 應看到 ---\ndescription: ...\nalwaysApply: true\n---
```

3. 確認 Cursor 已載入 Rules（在 Cursor 中重新開啟專案）。

4. 確認 `alwaysApply: true` 已設定（注意大小寫）。

---

### 問題 2：Sprint Execution 無法完整執行多步驟流程

**症狀**：要求執行 Sprint，Cursor 只執行部分步驟就停下，或無法自主完成 TDD 流程。

**根因**：未使用 Agent Mode，或 Agent Mode 因安全設定中斷。

**解決步驟**：

1. 確認已切換至 **Agent Mode**（Chat 左下角的模式切換）。
2. 在 Cursor 設定中確認 Agent 有 Terminal 工具存取權限。
3. 若仍有問題，分步驟執行：

```
> [acting as Developer] 為 US-01 寫失敗測試
> [acting as Developer] 實作最小代碼使測試通過
> [acting as QA] 審查 US-01 的 AC 是否全部通過
```

---

### 問題 3：`parallel-dispatch` Skill 無法使用

**症狀**：要求平行執行多個 Stories 時，Cursor 只能循序執行。

**說明**：這是 **已知限制**。Cursor 無原生平行 Agent 機制，`parallel-dispatch` Skill 在 Cursor 中不可用。

**解決方式**：改為循序執行每個 Story。若需要真正的平行 Subagent dispatch，請使用 Claude Code 平台。

---

### 問題 4：symlink 在 Windows 上失效

**症狀**：`.cursor/skills` symlink 無法解析，Skills 找不到。

**根因**：Windows 下 git 預設不支援 symlink。

**解決步驟**：

1. 啟用 Windows symlink 支援：
```bash
git config core.symlinks true
git checkout .
```

2. 若仍有問題，改為手動複製（不使用 symlink）：
```bash
cp -r skills .cursor/skills
```

> **注意**：複製方式會造成內容重複，Skills 更新時需手動同步。

---

### 問題 5：AI 回應不符合 Shikigami 框架

**症狀**：AI 沒有按照 SKILL.md 流程執行，或回應與框架不一致。

**解決步驟**：

1. 確認使用的模型足夠強大（推薦 Claude Sonnet 4.5 以上）。
2. 明確指定要使用的 Skill：
```
> 請閱讀並遵循 shikigami-sprint-execution Skill 的流程執行 US-01
```

3. 若 Rule 內容過長導致載入問題，可嘗試精簡 Rule：僅保留核心流程步驟。

---

## 相關文件

| 文件 | 用途 |
|------|------|
| [CURSOR_COMPATIBILITY_SURVEY.md](./CURSOR_COMPATIBILITY_SURVEY.md) | 詳細相容性分析報告 |
| [README.md](../README.md) | 完整功能說明、7 個角色、25 個 Skills |
| [INSTALL_OPENCODE.md](./INSTALL_OPENCODE.md) | OpenCode 安裝指南 |
| [INSTALL_GEMINI.md](./INSTALL_GEMINI.md) | Gemini CLI 安裝指南 |
| [Cursor Rules 官方文件](https://docs.cursor.com/context/rules) | Cursor Rules 格式規範 |
| [Cursor Agent Mode 文件](https://docs.cursor.com/chat/agent) | Cursor Agent Mode 使用說明 |
