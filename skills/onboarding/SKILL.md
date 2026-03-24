---
name: onboarding
description: "Use when a new user installs Shikigami and needs to scaffold the project document structure for the first time"
---

# Onboarding — 專案初始化

## 1. 概述

Onboarding 是 Shikigami 的一次性安裝引導流程。新使用者安裝框架後，此 Skill 自動建立文件目錄結構、複製初始範本、生成 `CLAUDE.md`，並引導至 Product Discovery，讓使用者在 5 分鐘內就緒，可以啟動第一個 Sprint。

**觸發方式**：使用者表達「初始化專案」、「第一次使用」、「安裝設定」、「scaffold」、「onboarding」、「剛安裝好」等語意時，由 Scrum Master 路由至此 Skill。

**冪等保證**：所有步驟對已存在的目錄與文件均跳過，不覆寫、不錯誤。重複執行安全。

---

## 2. 執行流程

> 完整執行步驟（5 個階段、前置檢查、GitHub Action 串接）：[`references/execution-steps.md`](references/execution-steps.md)

依序執行以下 5 個階段，每個階段完成後繼續下一個，不中途暫停詢問（§2.4 CLAUDE.md 生成為框架設定豁免例外）。

**快速摘要**：

| 階段 | 內容 |
|------|------|
| **2.1 前置檢查** | templates/ 目錄驗證、context-hub MCP 設定、ADR-010 labels 驗證 |
| **2.2 建立目錄** | docs/prd/、docs/adr/、docs/sprints/、docs/km/、docs/sdd/ |
| **2.3 複製文件** | PRODUCT_BACKLOG、ROADMAP、PROJECT_BOARD、SDD-000（含日期替換） |
| **2.4 生成配置** | CLAUDE.md / GEMINI.md，3 個問題（豁免不阻塞原則，需人工確認） |
| **2.5 下一步清單** | 輸出 Onboarding 完成清單（含 GitHub Action 串接狀態） |
| **2.6 GitHub Action** | Runner 偵測、OAuth 驗證、workflow 存在性確認（僅偵測，不自動安裝） |

### 2.1 前置檢查（摘要）

- `templates/` 不存在 → **立即中止**
- 必要範本缺失（非 SDD-000 升級豁免情況）→ **立即中止**
- context-hub MCP 未配置 → **警告後繼續**
- ADR-010 核心 labels 缺失 → **警告後繼續**（輸出修復指令）

### 2.4 生成配置文件（HARD-GATE）

<HARD-GATE>
{CONFIG_FILE}（CLAUDE.md 或 GEMINI.md）是框架核心配置文件，任何專案等級皆需人工確認，不可自動生成後跳過確認步驟。3 個問題必須依序詢問：專案名稱、技術棧、專案等級（low/medium/high）。
</HARD-GATE>

### 2.5 + 2.6 完成清單與 GitHub Action

> 完整清單格式與冪等性報告：[`references/completion-checklist.md`](references/completion-checklist.md)

所有步驟完成後輸出 completion-checklist.md 定義的完成清單，填入 §2.6 偵測結果的 `{GITHUB_ACTION_STATUS}`。

---

## 3. 執行方式

此 Skill 由 Scrum Master（主 Agent）直接執行，不需要派遣 Subagent。

執行時使用的工具：
- **Read / Glob**：前置檢查，確認 templates/ 存在
- **Bash（mkdir）**：建立不存在的目錄
- **Bash（cp）**：複製範本文件至目的地
- **Write**：生成 CLAUDE.md
- **AskUserQuestion**：僅用於第 2.4 節 CLAUDE.md 的 3 個問題（豁免不阻塞原則）

**流程中不得多餘詢問**：除 CLAUDE.md 的 3 個問題外，所有步驟自動執行，不停下來確認。

---

## 4. 與其他 Skill 的關係

| 情境 | 建議觸發 |
|------|----------|
| Onboarding 完成後，確認框架健康 | `shikigami:health-check` |
| 目錄與文件就緒後，開始第一個 Sprint | `shikigami:sprint-planning` |
| 需要建立第一個 ADR | `shikigami:architecture-decision` |
| Backlog 有需求待討論 | `shikigami:backlog-management` |
