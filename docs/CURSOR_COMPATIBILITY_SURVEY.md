# Shikigami × Cursor 平台相容性調查報告

**文件版本**：1.0（US-191，Sprint 72）
**調查日期**：2026-03-10
**調查方法**：靜態分析（Cursor 官方文件 + Shikigami 架構分析）
**結論摘要**：Cursor 平台**部分支援** Shikigami 工作流，核心 Skills 可透過 `.cursor/rules/` 適配，但 Subagent dispatch 及 SessionStart hook 需手動替代。

---

## 1. Cursor 平台架構概述

Cursor 是一個 AI-native 代碼編輯器，基於 VS Code 構建，提供以下 AI 功能機制：

| 機制 | 描述 | 檔案路徑 |
|------|------|----------|
| **Project Rules（.cursorrules）** | 全局 AI 指令規則，舊版格式 | `.cursorrules`（根目錄） |
| **Project Rules（新版）** | 作用域規則，支援 `alwaysApply` / `autoAttach` / `agentRequested` | `.cursor/rules/*.mdc` |
| **User Rules** | 個人全局規則 | Cursor 設定介面 |
| **Agent Mode** | AI 自主執行多步驟任務（含工具呼叫）| Cursor Chat |
| **Context @mentions** | 指定 codebase / files / docs 作為 AI 上下文 | Chat 輸入 |
| **MCP（Model Context Protocol）** | 連接外部工具、讀取資源 | `~/.cursor/mcp.json` |

---

## 2. Shikigami 元件相容性對照表

### 2.1 核心機制分析

| Shikigami 元件 | 功能說明 | Cursor 等效機制 | 相容性 | 說明 |
|---------------|---------|----------------|--------|------|
| `skills/*/SKILL.md` | AI 行為規範文件 | `.cursor/rules/*.mdc` | **高度相容** | SKILL.md 內容可直接轉為 Cursor Rule，觸發條件透過 `alwaysApply` 或 `agentRequested` 控制 |
| `hooks/session-start` | Session 啟動時注入 Scrum Master | 無直接等效 | **不支援** | Cursor 無 SessionStart Hook 機制；需以 `alwaysApply: true` 的 Cursor Rule 替代 |
| `hooks/hooks.json` | Hook 設定與 matcher 規則 | 無等效 | **不支援** | Cursor 無 Hook 系統；無法移植 |
| Subagent dispatch（Agent tool）| 派遣獨立 subagent 執行子任務 | 無原生等效 | **部分支援** | Cursor Agent Mode 支援多步驟執行，但無法真正派遣獨立 context 隔離的 subagent；需降級為單 session 循序執行 |
| `commands/*.md` | Slash Commands（`/sprint`, `/review` 等）| 無原生等效 | **不支援** | Cursor 無 Slash Command 插件機制；需以 `agentRequested` Rule 替代 |
| `agents/*.md` | Subagent 角色設定檔 | `.cursor/rules/*.mdc`（全局 Rules）| **部分支援** | 角色 prompt 可轉為 Rule，但無法真正隔離 context |
| `CLAUDE.md` 專案配置 | 專案等級與開發紅線設定 | `.cursorrules` 或 `.cursor/rules/` | **高度相容** | 可直接遷移至 Cursor Rules 格式 |
| `gemini-extension.json` | Gemini CLI extension 設定 | 無等效 | **不適用** | Cursor 不使用 Gemini CLI extension 系統 |

### 2.2 技術深度分析

#### SKILL.md 相容性（高度相容）

Cursor 的 `.cursor/rules/*.mdc` 格式與 SKILL.md 高度相容：

```
SKILL.md（Shikigami）         → .cursor/rules/<skill>.mdc（Cursor）
---                            ---
name: sprint-execution          description: "sprint-execution..."
description: "..."         →   alwaysApply: false
---                            ---
# Skill 正文                   # Skill 正文（內容直接沿用）
```

25 個 Skills 中，估計 **22/25（88%）** 可直接轉換：
- 純 Markdown 指令類 Skills（sprint-planning、backlog-management 等）→ 完全可轉
- 使用 Subagent dispatch 的 Skills（sprint-execution、parallel-dispatch）→ 需降級
- Hook 相依類（scrum-master 的 SessionStart 機制）→ 需 workaround

#### Subagent Dispatch 相容性（部分支援）

**Claude Code 架構**：
```
主 session（Scrum Master）
  └── Task tool → Developer subagent（獨立 context）
  └── Task tool → QA subagent（獨立 context）
```

**Cursor 架構限制**：
- Cursor Agent Mode 無法原生派遣具備獨立 context 隔離的 subagent
- 所有 AI 互動在同一 Cursor Chat session 中進行
- 無等效的 Task tool

**降級策略**：以循序執行替代平行派遣
```
Cursor Agent Mode（單 session）
  Step 1: [acting as Developer] 執行 TDD...
  Step 2: [acting as QA] 審查 AC...
  Step 3: [acting as Scrum Master] 更新狀態...
```

此降級方案維持工作流的**邏輯完整性**，但失去 context 隔離帶來的**prompt contamination 防護**。

#### SessionStart Hook（不支援）

| 特性 | Claude Code | Cursor |
|------|-------------|--------|
| Session 啟動觸發 | `hooks.json` → `session-start` 腳本 | 無 |
| Scrum Master 自動注入 | 自動（Hook 執行） | 需手動設定 `alwaysApply: true` Rule |
| 注入時機 | 精確（Session 啟動） | 每次 AI 請求（略有差異） |

**Workaround**：建立 `.cursor/rules/shikigami-always.mdc`，設定 `alwaysApply: true`，並包含 Scrum Master 角色定義。效果等同但觸發頻率不同。

---

## 3. Subagent Dispatch 技術結論

**結論：部分支援（Partially Supported）**

| 評估維度 | 結論 | 說明 |
|---------|------|------|
| 邏輯流程 | 支援 | Cursor Agent Mode 可執行多步驟工作流 |
| Context 隔離 | 不支援 | 無法創建真正隔離的 subagent context |
| 角色切換 | 部分支援 | 透過 Rule 注入實現邏輯角色切換，但共用 context |
| 平行執行 | 不支援 | Cursor 無平行 Agent 機制 |
| 自動派遣 | 部分支援 | 需 Agent Mode 主動執行，無 Hook 自動觸發 |

**實際影響**：
- Sprint Execution 的 TDD 流程、QA 審查等**邏輯步驟可完整執行**
- 但 `parallel-dispatch` Skill（平行 subagent）在 Cursor 中**無法實作**，需改為循序執行
- Context overflow 防護較弱（所有 Steps 共用同一 session）

---

## 4. Skills 相容性矩陣

| Skill | Claude Code | Cursor | 降級方式 |
|-------|------------|--------|---------|
| scrum-master | 完整 | 可用 | alwaysApply Rule，失去 SessionStart 精確觸發 |
| sprint-planning | 完整 | 可用 | Rule + Agent Mode |
| sprint-execution | 完整 | 部分可用 | 循序執行替代 Subagent dispatch |
| sprint-review | 完整 | 可用 | Rule + Agent Mode |
| backlog-management | 完整 | 可用 | Rule + Agent Mode |
| architecture-decision | 完整 | 可用 | Rule + Agent Mode |
| quality-gate | 完整 | 可用 | Rule + Agent Mode |
| security-review | 完整 | 可用 | Rule + Agent Mode |
| deployment-readiness | 完整 | 可用 | Rule + Agent Mode |
| systematic-debugging | 完整 | 可用 | Rule + Agent Mode |
| dispel | 完整 | 可用 | Rule + Agent Mode |
| git-workflow | 完整 | 可用 | Rule + Agent Mode（含 Terminal 工具） |
| parallel-dispatch | 完整 | **不可用** | 無 Cursor 等效機制，需改為循序執行 |
| issue-management | 完整 | 可用 | Rule + Agent Mode + Terminal（gh CLI） |
| health-check | 完整 | 可用 | Rule + Agent Mode |
| onboarding | 完整 | 可用 | Rule + Agent Mode |
| schedule | 完整 | 部分可用 | cron 腳本生成可用，自動觸發需外部 cron |
| shoot | 完整 | 可用 | Rule + Agent Mode |
| escalation | 完整 | 可用 | Rule + Agent Mode |
| architect | 完整 | 可用 | Rule 作為知識框架 |
| qa-engineer | 完整 | 可用 | Rule 作為知識框架 |
| diagram | 完整 | 部分可用 | MCP 整合需個別設定 |
| ux-agent | 完整 | 可用 | Rule + Agent Mode |
| ui-agent | 完整 | 可用 | Rule + Agent Mode |
| vision-critic | 完整 | 可用 | Rule + Agent Mode + 截圖上傳 |

**統計**：25 Skills 中，22 完整/可用（88%），2 部分可用（8%），1 不可用（4%）

---

## 5. 風險評估

| 風險 | 等級 | 說明 | 緩解方式 |
|------|------|------|---------|
| Context overflow | 中 | 無 subagent context 隔離，長 Sprint 可能 overflow | 每個 Story 開新 Cursor Chat |
| Prompt contamination | 中 | 多角色共用 session，前一角色 context 影響後續 | 每個 Story 開新 Chat，明確角色切換指示 |
| parallel-dispatch 失效 | 低 | 無平行執行能力，循序替代 | 降級為循序執行，不影響最終結果 |
| Hook 時機不精確 | 低 | alwaysApply Rule 每次請求都觸發，而非 Session 啟動 | 可接受，功能等效 |
| 版本相容性 | 低 | Cursor 更新可能改變 Rules 格式 | 追蹤 Cursor 更新日誌 |

---

## 6. 結論與建議

### 總體評估

Cursor 是 Shikigami **「可用但非原生最佳化」** 的平台。透過 `.cursor/rules/` 適配，88% 的 Skills 可在 Cursor 中正常觸發並執行，但以下限制需使用者知悉：

1. **無 SessionStart Hook**：Scrum Master 不自動注入，需依賴 alwaysApply Rule
2. **無真正 Subagent dispatch**：工作流以 Agent Mode 循序執行，失去 context 隔離
3. **parallel-dispatch Skill 無法使用**：Cursor 無平行 Agent 機制

### 建議

- **推薦用戶**：已有 Cursor 訂閱、偏好 VS Code UI、不需要嚴格 context 隔離的開發者
- **不推薦場景**：需要嚴格 prompt contamination 防護的大型 Sprint（建議使用 Claude Code）
- **最佳實踐**：每個 Story 開一個新的 Cursor Chat，最小化 context contamination

---

## 7. 相關文件

| 文件 | 用途 |
|------|------|
| [INSTALL_CURSOR.md](./INSTALL_CURSOR.md) | Cursor 平台安裝與設定指南 |
| [ADR-008](./adr/ADR-008.md) | OpenCode 平台整合參考（類似決策） |
| [INSTALL_OPENCODE.md](./INSTALL_OPENCODE.md) | OpenCode 安裝指南（策略參考） |
| [Cursor Rules 官方文件](https://docs.cursor.com/context/rules) | Cursor Rules 格式規範 |
