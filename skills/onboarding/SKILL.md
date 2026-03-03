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

依序執行以下 5 個階段，每個階段完成後繼續下一個，不中途暫停詢問（AC4 CLAUDE.md 生成為框架設定豁免例外，見第 2.4 節）。

### 2.1 前置檢查：環境驗證（Pre-flight）

**目的**：確認執行環境就緒，包含範本來源與 ADR-010 定義的 GitHub labels 存在性。若任一項不符合則提前中止並給出明確錯誤。

#### 2.1.1 templates/ 目錄驗證

執行步驟：
1. 讀取框架根目錄，確認 `templates/` 目錄存在
2. 確認以下 4 個範本文件皆存在：
   - `templates/PRODUCT_BACKLOG.md`
   - `templates/ROADMAP.md`
   - `templates/PROJECT_BOARD.md`
   - `templates/BACKLOG_DONE.md`

**判定規則**：
- `templates/` 不存在 → **立即中止**，輸出錯誤：
  ```
  [錯誤] templates/ 目錄不存在。
  Onboarding 需要此目錄作為初始文件來源。
  請確認 Shikigami 框架安裝完整，或從官方 repository 補回 templates/。
  ```
- 個別範本文件缺失 → **立即中止**，逐一列出缺失的文件：
  ```
  [錯誤] 以下範本文件缺失，無法繼續：
  - templates/PRODUCT_BACKLOG.md  ← 缺失
  請確認 Shikigami 框架安裝完整。
  ```
- 全部存在 → 繼續執行

#### 2.1.2 ADR-010 GitHub Labels 驗證（Pre-flight）

**目的**：確認 ADR-010 定義的 Backlog Issue 核心 labels 已建立於 GitHub repo。這些 labels 是 Backlog 管理流程的基礎設施，若缺失則後續 Sprint Planning 與 backlog-intake 流程將無法正常運作。

執行步驟：
```bash
gh label list --json name --limit 100
```

驗證以下三個 **Backlog Issue 核心 labels** 是否存在（最低要求）：

| Label | 語意 |
|-------|------|
| `type: backlog-item` | 識別為結構化 Story，區別於原始 Issue |
| `status: backlog` | 尚未排入 Sprint 的待選 Story |
| `status: in-sprint` | 已選入當前 Sprint |

**完整 ADR-010 label 清單**（14 個，應全部存在）：

| 類別 | Labels |
|------|--------|
| 原始 Issue labels | `feature-request`、`bug`、`question`、`triaged`、`backlog-linked` |
| Backlog Issue labels | `type: backlog-item`、`status: backlog`、`status: in-sprint` |
| 優先級 labels | `priority: must`、`priority: should`、`priority: could` |
| Size labels | `size: S`、`size: M`、`size: L` |

**判定規則**：
- 三個核心 labels（`type: backlog-item`、`status: backlog`、`status: in-sprint`）任一缺失 → **發出警告**，輸出修復指令後繼續（不中止，Onboarding 本身仍可執行）：
  ```
  [警告] 以下 ADR-010 核心 labels 尚未建立：
  - type: backlog-item  ← 缺失
  這些 labels 是 Backlog 管理流程的必要基礎設施。
  請執行以下指令建立缺失的 labels：
    gh label create "type: backlog-item" --color "0052cc" --description "識別為結構化 Story，區別於原始 Issue" --force
    gh label create "status: backlog" --color "1d76db" --description "尚未排入 Sprint 的待選 Story" --force
    gh label create "status: in-sprint" --color "0e8a16" --description "已選入當前 Sprint" --force
  或執行 US-69 的 Label 初始化腳本（建立全部 14 個 ADR-010 labels）：
    # 參見 docs/adr/ADR-010.md §實作路線圖 步驟 1
  ```
- 全部存在 → 輸出：`[Pass] ADR-010 labels 驗證通過（14/14）`，繼續執行

### 2.2 建立文件目錄結構

**目的**：確保 Shikigami 所需的 4 個核心目錄存在。

依序處理以下目錄：

| 目錄 | 用途 |
|------|------|
| `docs/prd/` | 產品需求文件（Backlog、Roadmap） |
| `docs/adr/` | 架構決策紀錄 |
| `docs/sprints/` | Sprint 紀錄文件 |
| `docs/km/` | 知識管理（Retrospective Log） |

對每個目錄：
- 不存在 → 建立目錄，輸出：`[建立] docs/xxx/`
- 已存在 → 跳過，輸出：`[略過] docs/xxx/ 已存在`

### 2.3 複製初始文件

**目的**：將 4 個核心範本複製至 `docs/prd/`，作為專案文件起點。

依序處理：

| 來源 | 目的地 |
|------|--------|
| `templates/PRODUCT_BACKLOG.md` | `docs/prd/PRODUCT_BACKLOG.md` |
| `templates/ROADMAP.md` | `docs/prd/ROADMAP.md` |
| `templates/PROJECT_BOARD.md` | `docs/PROJECT_BOARD.md` |
| `templates/BACKLOG_DONE.md` | `docs/prd/BACKLOG_DONE.md` |

對每個文件：
- 目的地不存在 → 複製，輸出：`[複製] templates/XXX.md → docs/.../XXX.md`
- 目的地已存在 → **不覆蓋**，輸出警告：
  ```
  [警告] docs/.../XXX.md 已存在，跳過複製。
          如需重置，請手動刪除後重新執行。
  ```

### 2.4 生成 CLAUDE.md

**目的**：建立框架啟動設定文件，定義專案資訊與自治等級。

**豁免不阻塞原則（框架根設定）**：`CLAUDE.md` 是框架的核心配置文件，決定整個 Scrum Team 的自治行為（包括 `shikigami.project_level`）。**任何專案等級皆需人工確認**，不可自動生成後跳過確認步驟。這是對不阻塞原則的明確豁免。

執行邏輯：

```
CLAUDE.md 是否存在？
├── 存在 → 輸出「[略過] CLAUDE.md 已存在，跳過生成」，繼續下一步
└── 不存在 → 進入問答流程（使用 AskUserQuestion）
```

問答流程（3 個問題，依序詢問）：

**問題 1 — 專案名稱**：
```
你的專案名稱是什麼？
（將填入 CLAUDE.md 的「專案資訊 → 專案名稱」欄位）
```

**問題 2 — 技術棧**：
```
你的技術棧是什麼？
（例如：FastAPI + PostgreSQL + pytest、Next.js + Prisma、純文件專案）
（將填入 CLAUDE.md 的「專案資訊 → 技術棧」欄位）
```

**問題 3 — 專案等級**：
```
你的專案等級是什麼？這決定 Shikigami 的自治程度：

  low    — 個人專案、實驗、內部工具
             高風險操作自動執行，事後通知

  medium — 一般開發專案（預設）
             高風險操作由 QA subagent 審核後自動執行

  high   — 重要產品、公開 repo、生產環境
             高風險操作必須人工確認

請輸入 low / medium / high：
```

收到 3 個回答後，依據 `templates/CLAUDE.md.template`，填入對應欄位生成 `CLAUDE.md`：
- 專案名稱 → `專案資訊 → 專案名稱`
- 技術棧 → `專案資訊 → 技術棧`
- 專案等級 → 在文件末尾新增：`shikigami.project_level: [使用者答案]`

輸出：`[生成] CLAUDE.md（請確認內容後再繼續）`

### 2.5 輸出下一步清單

所有步驟完成後，輸出 Product Discovery 引導清單：

```
## Onboarding 完成

以下是你的下一步：

1. **確認 CLAUDE.md**
   確認專案名稱、技術棧、專案等級設定正確。
   如需調整，直接編輯 CLAUDE.md。

2. **執行 /standup**
   確認框架狀態健康，開始每日工作節奏。

3. **Sprint Planning**
   執行 `/sprint` 開始第一個 Sprint，從 Product Backlog 選取 Stories。
```

---

## 3. 冪等性報告

執行完成後（無論是首次或重複執行），輸出統計摘要：

```
## Onboarding 執行摘要

跳過 {X} 目錄、{Y} 檔案（共 {Z} 項）

詳細：
- 目錄已存在跳過：{X} 個
- 文件已存在跳過：{Y} 個
- 新建目錄：{A} 個
- 新建文件：{B} 個
```

若為全新安裝（所有項目皆為新建），X=0、Y=0、Z=0。

---

## 4. 執行方式

此 Skill 由 Scrum Master（主 Agent）直接執行，不需要派遣 Subagent。

執行時使用的工具：
- **Read / Glob**：前置檢查，確認 templates/ 存在
- **Bash（mkdir）**：建立不存在的目錄
- **Bash（cp）**：複製範本文件至目的地
- **Write**：生成 CLAUDE.md
- **AskUserQuestion**：僅用於第 2.4 節 CLAUDE.md 的 3 個問題（豁免不阻塞原則）

**流程中不得多餘詢問**：除 CLAUDE.md 的 3 個問題外，所有步驟自動執行，不停下來確認。

---

## 5. 與其他 Skill 的關係

| 情境 | 建議觸發 |
|------|----------|
| Onboarding 完成後，確認框架健康 | `shikigami:health-check` |
| 目錄與文件就緒後，開始第一個 Sprint | `shikigami:sprint-planning` |
| 需要建立第一個 ADR | `shikigami:architecture-decision` |
| Backlog 有需求待討論 | `shikigami:backlog-management` |
