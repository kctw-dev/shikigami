# ADR-011：GitHub Actions 整合架構決策

**狀態**：Proposed
**日期**：2026-05-11
**決策者**：Architect
**關聯 Issue**：#46（feat: 自動化排程框架）、#76（ADR-011 起草）
**關聯 Story**：US-81（ADR-011 起草 — Sprint 38）
**關聯里程碑**：M4 外部整合

---

## 背景

Issue #46（feat: 自動化排程框架）原始設計定義了四條自動化流程：

1. **衝刺自動化排程**（Sprint Execution cron）
2. **需求入庫自動化**（PO Backlog Intake cron）
3. **Sprint Planning 自動化**
4. **程式碼入庫 QA 自動化**

其中，流程 4「程式碼入庫 QA 自動化」明確要求與 GitHub Actions CI/CD 管線整合，以在每次 Pull Request 或 Push 事件觸發時，自動執行框架層級的 QA 驗證。

ROADMAP M4「外部整合」里程碑的核心目標是讓 Shikigami 框架從「指引框架」進化為「執行框架」，其中 US-12（GitHub Actions 整合 — CI/CD 狀態感知）為 M4 的主要交付項目之一。

目前框架已具備以下基礎：

- `US-T07`（Sprint 7）：CI Pipeline — GitHub Actions 自動化驗證（基礎 workflow 已建立）
- `ADR-005`（Sprint 18）：Schedule Skill 技術決策（排程框架與 GitHub Actions 的互動模式）
- `ADR-006`（Sprint 22）：Prompt Injection Protection（外部事件觸發時的安全防護）
- `ADR-010`（Sprint 34 外）：Backlog Source of Truth 遷移至 GitHub Issues（ADR-010 定義了 GitHub Issues 與 Sprint 管理的整合模式）

然而，Shikigami 框架目前缺乏一份正式的架構決策文件，定義：

1. GitHub Actions 整合的**觸發模式**（push-based vs. pull-based vs. webhook）
2. Shikigami Skills 如何**讀取和回應** CI/CD 狀態（成功/失敗/進行中）
3. **安全模型**：GitHub Actions 執行環境中的認證策略（GITHUB_TOKEN vs. PAT vs. App）
4. **觸發邊界**：哪些 Shikigami 流程應由 GitHub Actions 自動觸發，哪些維持手動/排程觸發

本 ADR 評估三個備選整合方案，為 US-12 的實作提供架構依據。

---

## 決策問題

Shikigami 框架應以何種架構模式與 GitHub Actions CI/CD 管線整合，以支援 CI/CD 狀態感知、自動化 QA 觸發，並與現有 ADR-005（排程框架）、ADR-006（Injection 防護）及 ADR-010（GitHub Issues Backlog）形成一致的整合體系？

---

## 約束條件

| 約束 | 說明 |
|------|------|
| ADR-006 Injection 防護 | 任何外部事件（PR body、commit message、Issue 內容）進入 Shikigami Skills 時，必須維持 ADR-006 的 XML 隔離標記要求 |
| ADR-005 排程框架相容性 | GitHub Actions 整合不得破壞現有 `shikigami:schedule` cron 排程的執行模型 |
| ADR-010 GitHub Issues 整合 | CI/CD 狀態更新應能回寫至對應的 GitHub Issues（Story 狀態追蹤） |
| GITHUB_TOKEN 最小權限原則 | GitHub Actions workflow 採用最小必要權限，避免過度授權 |
| 零硬編碼 Secrets | 所有認證資訊必須透過 GitHub Secrets 或 GITHUB_TOKEN 環境變數注入，不得硬編碼於 workflow YAML |
| YAGNI 原則 | 不實作超出 US-12 MVP 需求的整合複雜度（DORA Metrics 等進階功能留待 US-13） |
| Skills 工具鏈相容性 | 整合方案必須與現有 Claude Code + gh CLI 工具鏈相容 |

---

## 選項分析

### Option A：Push-Based 事件觸發（Webhook via GitHub Actions） — 推薦方案

**概念**：以 GitHub Actions workflow 作為主要觸發器，監聽 `push`、`pull_request`、`workflow_run` 等事件，在 CI/CD 管線完成後自動執行 Shikigami QA Skills，並透過 `gh issue comment` 將結果回寫至對應 GitHub Issue。

#### 架構設計

```
GitHub Event（push / PR / workflow_run）
    │
    │ GitHub Actions Trigger
    ▼
.github/workflows/shikigami-ci.yml
    │
    ├── 執行現有 CI/CD 步驟（lint / test / build）
    │
    └── CI 完成後：呼叫 Shikigami QA Skill
         │
         ├── 讀取 CI 結果（GITHUB_TOKEN + gh run view）
         ├── ADR-006 XML 隔離處理外部輸入
         ├── 更新對應 GitHub Issue 狀態（gh issue comment）
         └── 觸發 sprint-review 狀態同步（可選）
```

#### 認證策略

```yaml
# workflow 中使用 GITHUB_TOKEN（自動注入，無需手動設定）
env:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

GITHUB_TOKEN 提供足夠的權限執行：
- `gh run view`（讀取 workflow 執行狀態）
- `gh issue comment`（回寫狀態至 Issue）
- `gh pr review`（PR 審查意見）

#### 優點

- 與 GitHub 原生事件體系深度整合，無需額外 webhook 基礎設施
- GITHUB_TOKEN 自動注入，認證配置最簡
- 事件觸發延遲低（push 後即觸發，無輪詢延遲）
- 與 ADR-010（GitHub Issues Backlog）天然整合：CI 結果直接回寫至 Issue
- 與現有 `US-T07`（Sprint 7）建立的 CI workflow 結構相容，改動最小
- 可透過 `workflow_run` 事件串聯多個 workflow，實現流程編排

#### 缺點

- GitHub Actions 的執行環境需要安裝 Claude Code（或等效 AI 執行器），增加 workflow 設置複雜度
- 若 CI 執行時間長，Shikigami QA Skill 的回應延遲依賴 CI 完成時間
- `workflow_run` 事件的觸發條件較複雜，需要謹慎設計避免循環觸發
- GITHUB_TOKEN 在 fork PR 情境下的權限受限（無法回寫至原 repo Issues）

#### 遷移成本

- 新增 `.github/workflows/shikigami-ci.yml`（或更新現有 CI workflow）
- 更新 `skills/sprint-execution/SKILL.md`：新增 CI 狀態感知步驟
- 建立 CI 狀態格式規範（供 ADR-006 隔離處理）

---

### Option B：Pull-Based 輪詢模式（排程查詢 CI 狀態）

**概念**：不依賴 GitHub Actions 事件觸發，改由 Shikigami 排程框架（ADR-005 `shikigami:schedule`）定期輪詢 `gh run list` 查詢最新 CI 狀態，並在偵測到狀態變化時觸發對應 Skill 流程。

#### 架構設計

```
shikigami:schedule（cron 排程）
    │
    │ 定期執行（如每 15 分鐘）
    ▼
gh run list --workflow=ci.yml --limit 5
    │
    ├── 與上次記錄的狀態比對（docs/km/ci_status_cache.md）
    │
    ├── 若有狀態變化：觸發 Shikigami QA Skill
    │    ├── 解析 CI 結果（ADR-006 XML 隔離）
    │    └── 更新 GitHub Issue 狀態
    │
    └── 若無變化：無操作（輪詢結束）
```

#### 優點

- 完全複用 ADR-005 排程框架，無需理解 GitHub Actions workflow 觸發機制
- 執行環境與現有排程 cron 完全相同，依賴最小
- 對 fork PR 的權限限制無影響（輪詢方式不依賴 workflow_run 事件）

#### 缺點

- 輪詢延遲：CI 完成後最多需等待一個輪詢週期（如 15 分鐘）才能感知
- 需要引入狀態快取（`ci_status_cache.md` 或等效機制），增加額外維護負擔
- 無法精確感知 CI 事件的觸發來源（哪個 PR / push / commit 觸發了哪次 CI）
- 在 CI 執行頻繁的專案中，輪詢結果可能混淆多次 CI 執行的狀態
- 與 Issue #46 的「程式碼入庫 QA 自動化」設計意圖不完全吻合（Issue #46 預期事件驅動而非輪詢）
- 空輪詢（無 CI 執行時）造成資源浪費

#### 遷移成本

- 更新 `shikigami:schedule` cron 配置（新增 CI 輪詢任務）
- 建立 CI 狀態快取機制（新增文件或格式）
- 更新 `skills/sprint-execution/SKILL.md`：新增 CI 狀態輪詢步驟

---

### Option C：Hybrid 模式（Actions 觸發 + Schedule 降級保護）

**概念**：以 Option A（Push-Based 事件觸發）為主要整合路徑，同時保留 Option B（Pull-Based 輪詢）作為降級保護機制。當 GitHub Actions workflow 未能正常觸發 Shikigami QA 時（如網路問題、Actions 配額耗盡），排程輪詢自動補漏。

#### 架構設計

```
主路徑：GitHub Actions Event（Option A）
    │
    ├── 正常觸發 → 執行 Shikigami QA Skill → 回寫 Issue
    │
    └── 觸發失敗 / 超時：標記 CI_PENDING 狀態

降級路徑：shikigami:schedule 輪詢（Option B）
    │
    ├── 偵測到 CI_PENDING 狀態 → 補執行 Shikigami QA
    └── 正常情況：跳過（主路徑已處理）
```

#### 優點

- 結合兩種方式的優點：事件驅動的即時性 + 輪詢的可靠性
- 對 GitHub Actions 故障有容錯能力

#### 缺點

- 架構複雜度最高：需要同時維護兩條觸發路徑
- 需要引入「CI_PENDING 狀態」的定義與追蹤機制，增加額外狀態管理負擔
- 違反 YAGNI 原則：MVP 階段不需要為極低概率的 Actions 故障建立降級機制
- 兩條路徑的競態條件（race condition）：若 Actions 延遲且 Schedule 先執行，可能導致重複回寫
- 遷移成本為 Option A + Option B 的總和，無法在 S-size Story（US-12）內完成

#### 遷移成本

- Option A 與 Option B 的遷移成本總和，外加競態條件保護機制

---

## 評估矩陣

| 評估維度 | Option A（推薦） | Option B | Option C |
|---------|----------------|----------|----------|
| 符合 Issue #46 事件驅動設計意圖 | 完全符合 | 部分符合（輪詢非事件驅動） | 完全符合 |
| 與 ADR-005 排程框架相容性 | 高（並行，不衝突） | 高（完全複用） | 中（需協調兩路徑） |
| 與 ADR-010 GitHub Issues 整合 | 高（直接回寫） | 中（延遲回寫） | 高（主路徑直接回寫） |
| 認證複雜度 | 低（GITHUB_TOKEN 自動注入） | 低（沿用 ADR-005 認證） | 中（兩種認證模式並存） |
| CI 狀態感知延遲 | 低（事件驅動，秒級） | 高（輪詢間隔，分鐘級） | 低（主路徑事件驅動） |
| YAGNI 符合度 | 是 | 是 | 否（MVP 不需降級機制） |
| 系統複雜度 | 低 | 低 | 高 |
| 遷移成本 | 低（新增 workflow + 更新 SKILL.md） | 中（新增快取機制 + 更新 SKILL.md） | 高（A + B + 競態保護） |
| 長期可維護性 | 高 | 中（快取機制維護負擔） | 低（雙路徑協調成本高） |
| ADR-006 Injection 防護相容性 | 完全相容（XML 隔離外部輸入） | 完全相容 | 完全相容 |

---

## 決策

**（Proposed）本 ADR 當前狀態為起草中（Proposed），尚待 Architect 正式裁決。**

**初步建議：採用 Option A（Push-Based 事件觸發）。**

初步建議理由：

### 1. 符合 Issue #46 原始設計意圖

Issue #46「程式碼入庫 QA 自動化」流程明確預設事件驅動模式（push / PR 事件觸發自動 QA），而非輪詢模式。Option A 與設計意圖一致。

### 2. GITHUB_TOKEN 認證最簡

Option A 使用 GitHub Actions 自動注入的 GITHUB_TOKEN，無需手動配置 PAT 或 GitHub App，符合最小配置原則。GITHUB_TOKEN 的權限範圍（Issues read/write、PRs read）完全覆蓋 Shikigami QA Skill 的操作需求。

### 3. 與現有基礎設施最相容

`US-T07`（Sprint 7）已建立基礎 CI workflow（`.github/workflows/`），Option A 在此基礎上延伸，改動最小。Option B 需要引入全新的狀態快取機制，Option C 的遷移成本超出 S-size Story 的範疇。

### 4. 長期架構清晰度

Option A 建立了清晰的「GitHub 事件 → GitHub Actions → Shikigami Skill → GitHub Issues 回寫」單向流程，與 ADR-010 定義的 GitHub Issues Backlog 體系形成一致的生態。

---

## 影響與風險

### 對現有架構的影響

| 元件 | 影響 | 說明 |
|------|------|------|
| `.github/workflows/` | 新增 / 更新 | 新增 `shikigami-ci.yml` 或更新現有 workflow，加入 Shikigami QA 觸發步驟 |
| `skills/sprint-execution/SKILL.md` | 輕度修改 | 新增 CI 狀態感知步驟，定義 CI 失敗時的 Sprint 執行行為 |
| `skills/sprint-review/SKILL.md` | 輕度修改 | 新增 CI 狀態確認步驟（Story Done 前確認 CI 綠燈） |
| ADR-006 Injection 防護 | 繼承 | CI 結果（commit message、PR body）進入 Skill 時，套用 XML 隔離標記 |
| ADR-005 排程框架 | 不受影響 | Option A 與排程框架並行運作，不衝突 |

### 風險評估

| 風險 | 可能性 | 影響 | 緩解策略 |
|------|--------|------|---------|
| Fork PR 情境 GITHUB_TOKEN 權限不足 | 中 | 低 | 明確記錄 Fork PR 限制，在 SKILL.md 中說明降級行為（跳過 Issue 回寫，僅記錄日誌） |
| workflow_run 事件循環觸發 | 低 | 高 | 在 workflow YAML 中明確設定觸發條件白名單，避免 Shikigami QA workflow 觸發自身 |
| Claude Code 在 Actions 環境不可用 | 低 | 高 | 需確認 GitHub Actions runner 環境下 Claude Code / gh CLI 的可用性（US-12 實作前 spike） |
| ADR-006 外部輸入注入（CI 結果含惡意內容） | 低 | 中 | ADR-006 XML 隔離機制已覆蓋此風險，CI 結果作為「不信任輸入」處理 |

---

## 開放問題（待 US-12 實作階段解決）

本 ADR 起草階段識別以下開放問題，留待 US-12 實作前正式解決：

| # | 問題 | 優先級 |
|---|------|--------|
| OQ-1 | GitHub Actions runner 環境下 Claude Code 的安裝與認證方式（是否支援 `ANTHROPIC_API_KEY` secret 注入？） | 高 |
| OQ-2 | Shikigami QA Skill 在 CI 環境下的執行模式（完整 Skill 執行 vs. 輕量化 CI-specific 子集） | 高 |
| OQ-3 | CI 狀態回寫至 GitHub Issues 的格式規範（comment 格式、標籤更新範圍） | 中 |
| OQ-4 | 多 PR 並行情境下的 CI 狀態追蹤（同時有多個 PR 在 CI 中，如何關聯至正確 Issue） | 中 |

---

## 參考

- GitHub Issue #46：feat: 自動化排程框架（「程式碼入庫 QA 自動化」流程原始設計）
- GitHub Issue #76：ADR-011 起草任務（本 ADR 起源）
- ROADMAP M4「外部整合」里程碑：US-12（GitHub Actions 整合）、US-13（DORA Metrics）、US-14（Notification Templates）
- ADR-005：Schedule Skill 技術決策（排程框架，與本 ADR 並行運作）
- ADR-006：Prompt Injection Protection（外部輸入安全防護，本 ADR 繼承此約束）
- ADR-010：Backlog Source of Truth — GitHub Issues 優先策略（CI 狀態回寫目標）
- `US-T07`（Sprint 7）：CI Pipeline — GitHub Actions 自動化驗證（現有 CI 基礎設施）
- `skills/sprint-execution/SKILL.md`：主要受影響 Skill（CI 狀態感知）
- `skills/sprint-review/SKILL.md`：次要受影響 Skill（Done 前 CI 確認）
