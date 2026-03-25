# Onboarding 執行流程（詳細步驟）

<!-- 本檔案由 onboarding/SKILL.md §2 拆出，主文件以指針引用 -->

## 2. 執行流程

依序執行以下 5 個階段，每個階段完成後繼續下一個，不中途暫停詢問（AC4 CLAUDE.md 生成為框架設定豁免例外，見第 2.4 節）。

### 2.1 前置檢查：環境驗證（Pre-flight）

**目的**：確認執行環境就緒，包含範本來源與 ADR-010 定義的 GitHub labels 存在性。若任一項不符合則提前中止並給出明確錯誤。

#### 2.1.1 templates/ 目錄驗證

執行步驟：
1. 讀取框架根目錄，確認 `templates/` 目錄存在
2. 確認以下範本文件皆存在：
   - `templates/PRODUCT_BACKLOG.md`
   - `templates/ROADMAP.md`
   - `templates/PROJECT_BOARD.md`
   - `templates/BACKLOG_DONE.md`（選用，ADR-010 後 Backlog 由 GitHub Issues 管理，此為歷史文物）
   - `templates/SDD-000-architecture.md`

**判定規則**：
- `templates/` 不存在 → **立即中止**，輸出錯誤：
  ```
  [錯誤] templates/ 目錄不存在。
  Onboarding 需要此目錄作為初始文件來源。
  請確認 Shikigami 框架安裝完整，或從官方 repository 補回 templates/。
  ```
- 個別**必要**範本文件缺失（`PRODUCT_BACKLOG.md`、`ROADMAP.md`、`PROJECT_BOARD.md`、`SDD-000-architecture.md`）→ 依以下規則處理：
  - `templates/SDD-000-architecture.md` 缺失但 `docs/sdd/SDD-000-architecture.md` **已存在** → **警告後繼續**（舊版升級豁免）：
    ```
    [警告] templates/SDD-000-architecture.md 不存在，但 docs/sdd/SDD-000-architecture.md 已存在。
    跳過範本檢查，使用既有的全局架構文件。
    注意：若既有文件缺少「觸發條件代碼」或「變更段落」欄位，建議手動對照最新範本補充。
    ```
  - 其他必要範本缺失 → **立即中止**，逐一列出缺失的文件：
    ```
    [錯誤] 以下範本文件缺失，無法繼續：
    - templates/PRODUCT_BACKLOG.md  ← 缺失
    請確認 Shikigami 框架安裝完整。
    ```
- `templates/BACKLOG_DONE.md` 缺失 → **警告後繼續**（選用文件，ADR-010 後 Backlog 由 GitHub Issues 管理）：
  ```
  [警告] templates/BACKLOG_DONE.md 不存在，跳過複製（選用文件）。
  ```
- 全部存在 → 繼續執行

#### 2.1.2 Context Hub MCP 設定驗證（Pre-flight）

<!-- US-216 Knowledge Ingestion via MCP — Sprint 81, ADR-017 -->

**目的**：確認 `.mcp.json` 中已配置 context-hub MCP server，讓 Story-Lifecycle subagent 在執行涉及外部 API 的 Story 時能透過 MCP 查詢 ground truth。驗證模式與 ADR-015 Figma MCP 驗證一致。

執行步驟：
1. 使用 Glob 工具確認 `.mcp.json` 是否存在於專案根目錄
2. 若存在，讀取 `.mcp.json`，確認 `mcpServers` 中包含 `context-hub` server 配置

**判定規則**：

```
.mcp.json 不存在：
  → [警告] .mcp.json 不存在，context-hub MCP server 尚未配置。
    若專案涉及外部 API 整合（INTEGRATION 類型 Story），建議在 .mcp.json 中新增以下配置：
    {
      "mcpServers": {
        "context-hub": {
          "type": "stdio",
          "command": "npx",
          "args": ["-y", "context-hub-mcp-server", "--config", ".chub/config.yml"]
        }
      }
    }
    缺少此配置時，Knowledge Ingestion（ADR-017）將自動 fallback 至 WebFetch native 模式。
    → 繼續執行（不阻塞 Onboarding）

.mcp.json 存在但無 context-hub server：
  → [警告] .mcp.json 已存在，但未找到 context-hub server 配置。
    建議在 mcpServers 物件中新增 context-hub 設定（見上方範本）。
    → 繼續執行（不阻塞 Onboarding）

.mcp.json 存在且包含 context-hub server 配置：
  → [Pass] context-hub MCP server 設定已就緒
  → 繼續執行
```

#### 2.1.3 ADR-010 GitHub Labels 驗證（Pre-flight）

**目的**：確認 ADR-010 定義的 Backlog Issue 核心 labels 已建立於 GitHub repo。這些 labels 是 Backlog 管理流程的基礎設施，若缺失則後續 Sprint Planning 與 Issue 自動入庫流程將無法正常運作。

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
| `docs/sdd/` | 系統設計文件（SDD） |

對每個目錄：
- 不存在 → 建立目錄，輸出：`[建立] docs/xxx/`
- 已存在 → 跳過，輸出：`[略過] docs/xxx/ 已存在`

### 2.3 複製初始文件

**目的**：將核心範本複製至對應目錄，作為專案文件起點。

依序處理：

| 來源 | 目的地 | 備註 |
|------|--------|------|
| `templates/PRODUCT_BACKLOG.md` | `docs/prd/PRODUCT_BACKLOG.md` | 選用，ADR-010 後 Backlog 由 GitHub Issues 管理 |
| `templates/ROADMAP.md` | `docs/prd/ROADMAP.md` | |
| `templates/PROJECT_BOARD.md` | `docs/PROJECT_BOARD.md` | |
| `templates/BACKLOG_DONE.md` | `docs/prd/BACKLOG_DONE.md` | 選用，ADR-010 後 Backlog 由 GitHub Issues 管理，此為歷史文物 |
| `templates/SDD-000-architecture.md` | `docs/sdd/SDD-000-architecture.md` | **必要**，全局架構文件（領域模型、類別圖、元件圖） |

對每個文件：
- 目的地不存在 → 複製，輸出：`[複製] templates/XXX.md → docs/.../XXX.md`
  - **SDD-000 特殊處理**：複製完成後，執行以下替換與驗證步驟：
    1. 使用 Bash 執行 `date +%Y-%m-%d` 取得系統日期
    2. 使用 Edit 工具將文件中所有 `{日期}` 佔位符替換為實際日期（如 `2026-03-14`）
    3. **驗證**：使用 Grep 確認文件中不存在 `{日期}` 字串；若仍存在，輸出 `[警告] SDD-000 的 {日期} 佔位符替換失敗，請手動填入日期`，並在 Onboarding 執行摘要中標記為需手動確認項目
- 目的地已存在 → **不覆蓋**，輸出警告：
  ```
  [警告] docs/.../XXX.md 已存在，跳過複製。
          如需重置，請手動刪除後重新執行。
  ```

### 2.4 生成專案配置文件（CLAUDE.md / GEMINI.md）

**目的**：建立框架啟動設定文件，定義專案資訊與自治等級。

**平台偵測**：依據執行環境自動判斷應生成哪個配置文件：

```
平台偵測：
├── gemini-extension.json 在 plugin 根目錄存在 → Gemini CLI 環境
│   └── 配置文件名 = GEMINI.md，範本 = templates/GEMINI.md.template
├── .opencode/ 在 plugin 根目錄存在 → OpenCode 環境
│   └── 配置文件名 = CLAUDE.md，範本 = templates/CLAUDE.md.template
└── 預設 → Claude Code 環境
    └── 配置文件名 = CLAUDE.md，範本 = templates/CLAUDE.md.template
```

> 以下流程中，`{CONFIG_FILE}` 代表偵測結果的配置文件名（`CLAUDE.md` 或 `GEMINI.md`），`{TEMPLATE}` 代表對應範本。

**豁免不阻塞原則（框架根設定）**：`{CONFIG_FILE}` 是框架的核心配置文件，決定整個 Scrum Team 的自治行為（包括 `shikigami.project_level`）。**任何專案等級皆需人工確認**，不可自動生成後跳過確認步驟。這是對不阻塞原則的明確豁免。

執行邏輯：

```
{CONFIG_FILE} 是否存在？
├── 存在 → 輸出「[略過] {CONFIG_FILE} 已存在，跳過生成」，繼續下一步
└── 不存在 → 進入問答流程（使用 AskUserQuestion）
```

問答流程（3 個問題，依序詢問）：

**問題 1 — 專案名稱**：
```
你的專案名稱是什麼？
（將填入 {CONFIG_FILE} 的「專案資訊 → 專案名稱」欄位）
```

**問題 2 — 技術棧**：
```
你的技術棧是什麼？
（例如：FastAPI + PostgreSQL + pytest、Next.js + Prisma、純文件專案）
（將填入 {CONFIG_FILE} 的「專案資訊 → 技術棧」欄位）
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

收到 3 個回答後，依據 `{TEMPLATE}`，填入對應欄位生成 `{CONFIG_FILE}`：
- 專案名稱 → `專案資訊 → 專案名稱`
- 技術棧 → `專案資訊 → 技術棧`
- 專案等級 → 在文件末尾新增：`shikigami.project_level: [使用者答案]`

輸出：`[生成] {CONFIG_FILE}（請確認內容後再繼續）`

### 2.5 輸出下一步清單

> 完整清單格式與 GitHub Action 狀態填入規則：[`references/completion-checklist.md`](references/completion-checklist.md)

所有步驟完成後，依據 §2.6 執行結果填入 `{GITHUB_ACTION_STATUS}`，輸出 completion-checklist.md 定義的完成清單。

### 2.6 GitHub Action 串接（Runner 就緒確認）

> **注意**：`new-issue-intake.yml` workflow 已於 Sprint 142 移除（OAuth 401 持續失敗，功能由 Cruise PO 巡邏取代）。此節改為只確認 self-hosted runner 基礎設施就緒狀態，不再驗證特定 workflow 檔案。

**目的**：確認 GitHub Actions self-hosted runner 已就緒，讓後續 Sprint Execution CI 管線可正常使用。

**安全邊界**：此階段僅執行「偵測與驗證」，不自動安裝 runner 或儲存認證憑證。所有安裝步驟均輸出為手動指引，由使用者決定是否執行。

#### 2.6.1 冪等性檢查

執行前先判斷是否已就緒，避免重複操作：

**條件**：runner 已存在 **且** OAuth 已認證

```
若以上條件同時成立 → 輸出：
  [略過] GitHub Action 串接已就緒
  - Self-hosted runner：已連線
  - OAuth 認證（claude auth status）：已認證
並跳至 §2.5 下一步清單，填入「GitHub Actions runner 已就緒（self-hosted runner 已連線）」
```

若任一條件不成立，繼續執行 §2.6.2 ~ §2.6.3 各步驟。

#### 2.6.2 Runner 偵測

**目的**：確認 GitHub repo 已有 self-hosted runner 連線（Sprint Execution CI 管線需要 self-hosted runner 執行）。

執行指令：

```bash
gh api repos/{owner}/{repo}/actions/runners
```

> `{owner}` 與 `{repo}` 從當前 git remote 自動解析（`git remote get-url origin`）。

**判定規則**：

```
API 回傳結果中 total_count > 0 且至少一個 runner.status = "online"？
├── 是 → 輸出：[Pass] Self-hosted runner 已就緒（{runner_name}，{runner_status}）
└── 否 → 輸出警告與手動指引：

  [警告] 未偵測到 online 狀態的 self-hosted runner。
  Sprint Execution CI 管線需要 self-hosted runner 才能在本機執行 Claude Code。

  手動安裝步驟：
  1. 前往 GitHub repo 的 Settings → Actions → Runners → New self-hosted runner
  2. 選擇對應平台（Linux / macOS / Windows）
  3. 依據頁面指引下載並執行 runner 安裝腳本
  4. 完成後重新執行 Onboarding 以驗證連線狀態

  注意：runner 安裝需要 root / sudo 權限，請在適當環境執行。
```

#### 2.6.3 OAuth 驗證狀態確認

**目的**：確認 Claude Code 已完成 OAuth 認證，CI 管線的 claude CLI 呼叫才能正常執行。

執行指令：

```bash
claude auth status
```

**判定規則**：

```
輸出包含認證成功標示（如 "Logged in" 或 "authenticated"）？
├── 是 → 輸出：[Pass] Claude OAuth 認證已就緒
└── 否 → 輸出警告與手動指引：

  [警告] Claude OAuth 未認證。
  CI 管線在 runner 上執行時需要有效的 OAuth 認證。

  手動認證步驟：
  1. 在 runner 主機上執行：claude auth
  2. 依據提示完成 OAuth 流程（瀏覽器授權）
  3. 完成後執行 claude auth status 確認認證狀態
  4. 重新執行 Onboarding 以驗證

  安全提醒：憑證由 Claude Code 安全儲存，不儲存於任何明文文件或環境變數。
```

#### 2.6.4 串接狀態摘要

依據 §2.6.2 ~ §2.6.3 的各項結果，決定 §2.5 的 `{GITHUB_ACTION_STATUS}` 填入值：

```
全部 Pass → 填入：GitHub Actions runner 已就緒（self-hosted runner 已連線）
任一 Warning → 填入：GitHub Actions runner 待設定（見 §2.6 手動指引）
```
