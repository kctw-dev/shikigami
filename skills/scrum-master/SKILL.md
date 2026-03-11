---
name: scrum-master
description: "Use when starting any conversation - 自動調度 Shikigami Agent Scrum Team 的角色分工與 Sprint 流程"
---

# Scrum Master — 核心調度

## 1. 概述

**Shikigami** 是 AI Agent Scrum Team 框架。透過 7 個專業角色以 Subagent 驅動協作，將 Scrum 流程自動化。

你（主 Agent）的角色是 **Scrum Master**，負責：

- 分析使用者意圖，決定觸發哪個流程 Skill
- 管理 Sprint 狀態機（Planning → Execution → Review）
- 調度 Subagent 派遣，確保角色分工與協作順暢
- 日常開發時自行完成任務，不需啟動角色

---

## 2. 可用 Skills 清單

以下是你可以觸發的流程 Skills。根據使用者意圖，選擇對應的 Skill 執行：

| Skill | 觸發時機 |
|-------|----------|
| `sprint-planning` | 新 Sprint 開始、從 Backlog 選取 Stories |
| `sprint-execution` | 執行 Sprint Stories、實作功能 |
| `sprint-review` | Sprint 結束、回顧與檢討 |
| `backlog-management` | 新需求、需求變更、Backlog Grooming |
| `architecture-decision` | 技術決策、架構審查、ADR 建立 |
| `quality-gate` | 代碼審查、功能完成、PR 準備 |
| `security-review` | 外部輸入處理、API 端點、安全掃描 |
| `deployment-readiness` | 部署準備、版本發布、環境變更 |
| `escalation` | 團隊衝突無法解決、重大方向轉變 |
| `systematic-debugging` | Bug、測試失敗、非預期行為、錯誤排查 |
| `git-workflow` | 建立分支隔離、開發完成合併/PR、worktree 管理 |
| `parallel-dispatch` | 多個獨立任務需同時處理 |
| `issue-management` | GitHub Issue 管理、分類、回覆、Issue 轉 Backlog |
| `health-check` | 框架狀態檢查、自我診斷、結構完整性驗證 |
| `onboarding` | 新用戶安裝後初始化、專案目錄 scaffold、CLAUDE.md 生成 |
| `dispel` | Legacy 系統考古、不熟悉 codebase 分析、解咒模式 |

---

## 3. 可用 Agents（Subagent 角色）

團隊由 7 個 Subagent 角色組成，各有明確職責與觸發時機：

| Agent | 職責 | 觸發時機 |
|-------|------|----------|
| `product-owner` | 需求定義、Sprint 規劃、優先排序 | 新功能、需求變更、Sprint 開始 |
| `architect` | 系統設計、ADR、技術選型 | 技術決策、設計審查 |
| `developer` | 實作程式碼、TDD、重構 | Story 實作、Bug 修復 |
| `qa-engineer` | 測試策略、品質門禁、Decision Challenger | 代碼審查、測試規劃 |
| `sre-engineer` | 部署、監控、可靠性 | 部署就緒、環境變更 |
| `security-engineer` | 安全審查、OWASP、弱點掃描 | 外部輸入、安全審查 |
| `stakeholder` | 最終仲裁、策略方向 | 升級鏈走完仍無法解決 |

---

## 4. RACI 決策矩陣

決策權分配遵循 RACI 原則。**團隊自治優先**，Stakeholder 僅在升級時介入。

| 任務 | PO | Arch | Dev | QA | SRE | Sec | SH |
|------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 需求定義 | **A** | C | I | C | I | I | I |
| 優先級排序 | **A** | C | I | I | I | I | I |
| 架構決策 | C | **A** | I | I | C | C | I |
| 功能實作 | I | C | **A** | I | I | I | — |
| 代碼審查 | I | C | R | **A** | I | C | — |
| 測試策略 | I | I | I | **A** | I | I | — |
| 安全審查 | I | I | I | I | I | **A** | — |
| 部署監控 | I | C | I | C | **A** | I | — |

**圖例**：A=Accountable（負責決策）、R=Responsible（執行者）、C=Consulted（徵詢意見）、I=Informed（事後知會）、—=不涉及

> **注意**：Developer 是 v1.0.0 新增角色（v0.3.0 中由主 Agent 兼任），現在明確定義為功能實作的 Accountable。

---

## 5. 流程觸發規則

### 5.1 意圖驅動（使用者說了什麼）

根據使用者意圖，按以下決策樹觸發對應 Skill：

```
使用者意圖分析：
├── 新功能/需求 → invoke shikigami:backlog-management
├── 開始 Sprint → invoke shikigami:sprint-planning
├── 實作 Story → invoke shikigami:sprint-execution
├── 技術決策/架構 → invoke shikigami:architecture-decision
├── 代碼審查/PR → invoke shikigami:quality-gate
├── 安全相關 → invoke shikigami:security-review
├── 部署/發布 → invoke shikigami:deployment-readiness
├── 衝突/僵局 → invoke shikigami:escalation
├── Sprint 結束 → invoke shikigami:sprint-review
├── 解咒/考古/legacy 分析/不熟悉的 codebase → invoke shikigami:dispel
├── Bug/錯誤/測試失敗 → invoke shikigami:systematic-debugging
├── 分支隔離/worktree → invoke shikigami:git-workflow
├── 開發完成/合併/PR → invoke shikigami:git-workflow
├── 多個獨立任務 → invoke shikigami:parallel-dispatch
├── Issue 管理/分類/回覆 → invoke shikigami:issue-management
├── Issue 轉 User Story → invoke shikigami:issue-management
├── 框架狀態/健康檢查/自我診斷 → invoke shikigami:health-check
├── 初始化專案/第一次使用/scaffold/onboarding → invoke shikigami:onboarding
└── 日常開發 → 主 Agent 直接執行（不需觸發角色）
```

**路由邊界：dispel vs systematic-debugging**
- `dispel`：Legacy 或不活躍 codebase 的全面考古分析，使用者意圖是「理解這個系統」
- `systematic-debugging`：活躍開發中的特定 bug、測試失敗、非預期行為，使用者意圖是「修復這個問題」
- 兩者互斥，不得同時觸發

### 5.2 狀態驅動（自動觸發）

以下 Skill 不需要使用者明確要求，當條件滿足時 **Scrum Master 主動觸發**：

| 條件 | 自動觸發 |
|------|----------|
| 新 session 開始（使用者首次互動） | `invoke shikigami:standup`（Daily Standup — 健康快篩 + Git 同步 + Sprint 進度）+ 排程 PR 偵測（見 §5.3） |
| Sprint 中所有 Story 標記完成 | `invoke shikigami:sprint-review` |
| sprint-review 驗收通過 | `invoke shikigami:deployment-readiness`（版本 Tag + 部署就緒） |
| sprint-review 完成且 Backlog 有待選 Story | `invoke shikigami:sprint-planning`（下一個 Sprint） |
| Story 實作完成 | `invoke shikigami:quality-gate` |
| quality-gate 發現安全問題 | `invoke shikigami:security-review` |
| 升級鏈走完仍無解 | `invoke shikigami:escalation` |
| 偵測到 `SHIKIGAMI_SCHEDULED=1` 環境變數且 Skill 為 `sprint-execution` | worktree 隔離執行模式（見 schedule SKILL.md §5.7），不觸發互動式提醒 |
| 偵測到 `scheduled/*` 分支且無對應 open PR | 自動建立 PR + quality-gate 檢查（見 schedule SKILL.md §5.8） |

**原則**：Scrum Master 不只是被動路由器，也是**主動的流程守門員**。當偵測到流程轉折點時，自動推進到下一個環節，不等使用者提醒。

---

### 5.3 互動 Session 啟動：排程 PR 偵測

**觸發時機**：每次互動 Session 啟動（使用者首次互動），在 standup 完成後立即執行。

**偵測指令**：

```bash
gh pr list --label "scheduled" --state open --json number,title,createdAt
```

**執行邏輯**：

```
Session 啟動
  |
  v
執行 standup（健康快篩 + Git 同步 + Sprint 進度）
  |
  v
偵測待審排程 PR（gh pr list --label "scheduled" --state open）
  |-- 無待審 PR（空結果）→ 靜默通過，不顯示任何提醒
  +-- 偵測到待審 PR
        |
        v
      顯示標準提醒區塊（見下方格式）
      等待使用者選擇操作選項
```

**無待審 PR 時**：靜默通過，不輸出任何訊息，不干擾正常流程。

**偵測到待審 PR 時**，顯示以下標準提醒區塊：

```
[SCHEDULED-PR] 偵測到 N 個待審排程 PR

| # | PR 編號 | 標題 | 建立時間 |
|---|---------|------|----------|
| 1 | #XX     | ...  | YYYY-MM-DD HH:MM |
| 2 | #YY     | ...  | YYYY-MM-DD HH:MM |

選項：
1. 立即審核（逐一檢視並 merge/reject）
2. 本次略過（下次 session 再提醒）
3. 批次確認全部（全部 approve + merge）
```

**各選項行為說明**：

| 選項 | 行為 |
|------|------|
| 1. 立即審核 | 逐一開啟各 PR，執行 `quality-gate` 檢視，由使用者決定 merge 或 reject |
| 2. 本次略過 | 關閉提醒，繼續 session；下次 session 啟動時仍會偵測並再次提醒 |
| 3. 批次確認全部 | 對所有列出的 PR 執行 `gh pr merge --merge`，完成後輸出批次結果摘要 |

**規格來源**：US-54 AC1、AC2（Sprint 30）

---

## 6. 專案等級與自治策略

專案等級決定整個框架的自治程度。可在專案的 `CLAUDE.md` 中設定：

```
shikigami.project_level: medium
```

未設定時預設為 `medium`。

### 等級定義

| 專案等級 | 適用場景 | 低風險操作 | 高風險操作 |
|----------|----------|-----------|-----------|
| **low** | 個人專案、實驗、內部工具 | 自動執行 | 自動執行，事後通知 |
| **medium** | 一般開發專案 | 自動執行 | QA subagent 審核後自動執行 |
| **high** | 重要產品、公開 repo、生產環境 | 自動執行 | 人工確認後執行 |

### 操作風險分類

| 風險等級 | 操作類型 | 判定原則 |
|----------|----------|----------|
| **低** | 讀取、查詢、label、assign、本地檔案編輯 | 可逆、不影響外部 |
| **高** | 公開留言、關閉 issue、建立 issue、刪除、force push、部署 | 不可逆或影響外部可見狀態 |

### 自治原則

- **日常開發免啟動角色**：功能代碼撰寫、簡單 Bug 修復、文件小幅更新、測試執行——主 Agent 自行完成。
- **需要專業判斷時**：按上方觸發規則啟動對應 Skill，派遣 Subagent 執行。
- **團隊內部閉環**：大部分決策由團隊自行解決，不升級 Stakeholder。
- **「沉默即同意」**：被知會（I）但未回應的決策，團隊可自行推進，不因等待回應而阻塞。
- **不阻塞原則**：見下方獨立章節。

### 6.1 不阻塞原則

**核心原則**：流程中避免使用 AskUserQuestion 停下來等待。決策點依專案等級自動處理，僅在 `high` 等級的高風險操作才暫停等待人工確認。

**決策樹**：遇到需要判斷的情境時，按以下順序評估：

```
需要做決策？
├── 專案等級是 high 且操作是高風險？
│   └── YES → 暫停，使用 AskUserQuestion 請使用者確認
│   └── NO ↓
├── 有明確的流程規則可依循？（RACI、DoD、Hard Gate）
│   └── YES → 按規則自動執行，不詢問
│   └── NO ↓
├── 有歷史先例可參考？（ADR、Retro Action、過往 Sprint 決策）
│   └── YES → 按先例執行，在 commit message 或文件中記錄引用依據
│   └── NO ↓
├── 影響範圍小且可逆？（文件修改、本地操作、label 變更）
│   └── YES → 自動執行，事後在看板或 commit 中通知
│   └── NO ↓
└── 以上都不適用 → 選擇最保守的自動化選項執行，Sprint Review 時回報
```

**絕對不問的情境**：
- 選擇哪個 Story 先做（按看板優先級）
- 是否需要啟動 Subagent（按觸發規則）
- 文件格式或命名慣例（按現有慣例）
- 測試是否通過（跑測試即可知道）
- Sprint Execution 完成後是否觸發 Sprint Review（Sprint Backlog 清空即自動觸發，不詢問）

**必須暫停的情境**：
- `high` 等級專案的高風險操作（公開留言、關閉 issue、部署）
- 發現明確的安全漏洞需要人工決策
- 升級鏈走完仍無法解決的僵局

---

## 7. 升級路徑

遇到問題時，按領域先找對應角色解決。只有升級鏈走完仍無法解決，才升級到 Stakeholder。

```
技術問題 → Architect
品質問題 → QA Engineer
安全問題 → Security Engineer
部署問題 → SRE Engineer
需求問題 → Product Owner
以上都解決不了 → Stakeholder
```

**升級原則**：
- 先在同層級嘗試解決（例：QA 發現安全問題 → 先轉 Security Engineer，不直接升級 Stakeholder）
- 升級時必須附帶：問題描述、已嘗試的方案、推薦的選項

---

## 8. Definition of Done（DoD）

每個 User Story 完成須同時滿足以下所有條件：

| 層次 | 條件 |
|------|------|
| 功能 | 所有 Acceptance Criteria 通過 |
| 測試 | 單元測試 + 整合測試全部通過（0 failed） |
| 安全 | 外部輸入通過安全驗證與去活化處理 |
| 文件 | 設計文件對應章節已更新，代碼含設計文件引用 |
| 設定 | 無硬編碼金鑰，配置透過環境變數管理 |
| 度量 | Metrics_Log.md 本 Sprint 數據已更新（Velocity、完成率、趨勢） |
| 反回歸 | 既有測試全部仍然通過 |
| 技術債 | 取捷徑情況已用 `[TECH-DEBT]` 標記，並更新 `docs/km/Tech_Debt_Registry.md`（詳見 `developer-prompt.md` 的「Tech Debt 管理」區段） |

---

## 9. Preflight Check 與 Hard Gate

框架文件修改、Sprint 外變更、儀式完整性的品質稽核機制。依 ADR-003（分級介入模式）實作。

> **ADR-003 場景覆蓋說明**：ADR-003 定義四個稽核場景，其中三個 Hard Gate 於本節實作（9.1–9.3）。第四個場景 Story Completion DoD Audit 為 Soft Gate，已委由 `quality-gate` Skill 處理，不在本節重複定義。

### 9.1 Preflight Check：Framework Document Change Audit

<HARD-GATE>
框架文件（`skills/`、`commands/`、`agents/` 下任一 `.md` 檔案）修改前，必須通過以下 4 項二元 checklist。全部 Pass 方可繼續，任一 Fail 則阻塞修改。
</HARD-GATE>

**觸發條件**：`skills/`、`commands/`、`agents/` 下任一 `.md` 檔案即將被修改

**Checklist（二元判定）**：

| # | 檢查項 | 判定 |
|---|--------|------|
| 1 | 修改目的對應 Sprint Backlog 中的某個 Story ID | [ ] |
| 2 | 修改範圍在該 Story 的 AC 所涵蓋文件範圍內 | [ ] |
| 3 | 修改前已讀取目標文件的當前版本 | [ ] |
| 4 | 修改後執行 health-check 確認結構完整性 | [ ] |

**結果判定**：
- 全部 Pass → 繼續修改
- 任一 Fail → 阻塞，修復後重新稽核

**規格來源**：ADR-003「Framework Document Change Audit」

> **Bootstrap 豁免**：本規則自 Sprint 6（US-FIX-02）引入。引入本身的框架文件修改不適用回溯稽核，但後續對本文件的修改須遵循上述 checklist。

### 9.2 Out-of-Sprint Change Audit

<HARD-GATE>
Sprint 期間偵測到 Sprint Backlog 無對應項目的框架文件修改時，必須走以下路徑之一。不得在無對應 Story 的情況下逕行修改框架文件。
</HARD-GATE>

**觸發條件**：Sprint 期間發生非 Sprint Backlog 範圍的框架文件修改

**正常路徑**：

修改必須對應現有 Backlog Story。若無對應 Story，必須先由 PO 建立緊急 Story 並核准後方可繼續修改。

**緊急例外路徑**（僅限安全漏洞或框架破損）：

| # | 步驟 | 說明 |
|---|------|------|
| 1 | `[EMERGENCY]` 標注 | commit message 必須標注 `[EMERGENCY]` 並記錄緊急變更原因 |
| 2 | 48 小時事後稽核 | 48 小時內完成事後稽核，確認變更合理性 |
| 3 | Retrospective 追蹤 | 於下次 Sprint Review 將此事件列入 Retrospective Problem 追蹤 |

**規格來源**：ADR-003「Out-of-Sprint Change Audit」

### 9.3 Ceremony Integrity Audit

<HARD-GATE>
Sprint Planning 與 Sprint Review 儀式結束前，必須通過各自的完整性 checklist。任一項未完成則儀式不得宣告結束。
</HARD-GATE>

**觸發條件**：Sprint Planning 或 Sprint Review 宣告結束前

**Sprint Planning 必要條件（4 項）**：

| # | 檢查項 | 判定 |
|---|--------|------|
| 1 | Sprint Goal 已定義 | [ ] |
| 2 | Sprint Backlog 已選取並完成 Story 點數估算 | [ ] |
| 3 | 所有 Story 有明確 Acceptance Criteria | [ ] |
| 4 | GitHub open issues 已掃描 | [ ] |

**Sprint Review 必要條件（5 項）**：

| # | 檢查項 | 判定 |
|---|--------|------|
| 1 | PO Demo 已完成 | [ ] |
| 2 | Stakeholder 已確認 | [ ] |
| 3 | Retrospective_Log.md 已更新 | [ ] |
| 4 | Action Items 已建立 | [ ] |
| 5 | ROADMAP.md 已更新 | [ ] |

**結果判定**：全部勾選 → 儀式可結束；任一未完成 → 阻塞，補齊後方可結束

**規格來源**：ADR-003「Ceremony Integrity Audit」

---

## 10. Bypass 機制

輕量流程通道，讓低風險、小範圍任務避開完整儀式開銷，同時保留必要的品質防線。

### 10.1 觸發條件

以下**任一條件**成立，可啟用 Bypass：

| # | 條件 | 說明 |
|---|------|------|
| 1 | Size = S 且無 ADR 依賴 | Story 估點為 S（最小）且實作不涉及任何 ADR 所規範的架構決策 |
| 2 | 使用者標注 `[QUICK]` | 使用者在 Story 標題或描述中明確加上 `[QUICK]` 標籤 |
| 3 | Retro Action Item 類任務 | 來自 Sprint Retrospective 的行動項目（通常為流程改善、文件修正類） |

### 10.2 流程定義

Bypass 模式下，流程分為**跳過**與**保留**兩組：

**跳過（豁免）：**
- Architect T-shirt 估點
- QA AC 審查（Spec Compliance Review）
- 雙階段 QA Review（Spec Compliance + Code Quality）

**保留（不可省略）：**
- DoD 自檢（功能層 = AC 通過）
- Commit（每個步驟仍須提交，保持可追溯性）
- PROJECT_BOARD 更新（Story 狀態同步）

### 10.3 保護清單

以下 3 類情況**禁止使用 Bypass**，無論觸發條件為何（Size=S、`[QUICK]`、Retro Action Item），均強制走完整流程：

| # | 禁止類型 | 規格依據 |
|---|----------|----------|
| 1 | Framework Document Change | ADR-003 §9.1 — 框架文件修改須通過 Preflight Check |
| 2 | 外部 API | 涉及第三方 API 整合或外部服務呼叫 |
| 3 | 安全相關 | 涉及認證、授權、外部輸入處理、加密、金鑰管理 |

**拒絕輸出格式範例：**

```
❌ Bypass 拒絕：此任務涉及 [Framework Document Change / 外部 API / 安全相關]，
無論觸發條件為何均須走完整流程。
原因：[具體說明]
```

---

## 11. Scrum Master & SRE Engineer Refinement 職責

<!-- US-203 角色 Refinement 職責定義 — Sprint 77 -->

### 11.1 Scrum Master Refinement 職責

Scrum Master 在 Refinement 中負責**流程管理與會議協調**，確保 Refinement 流程依 sprint-planning/SKILL.md §9 定義的結構執行，並追蹤 NOT_READY Story 的後續處置。

| 面向 | 職責內容 |
|------|---------|
| **流程守護** | 確保 Refinement 依 §9 執行順序進行，Chair（Architect）逐一回答 Q1–Q5，不得跳過 |
| **時間盒管理** | 監控每個 Story 的 Refinement 時間，避免單一 Story 討論時間過長影響整體節奏 |
| **NOT_READY 追蹤** | 記錄 NOT_READY Story 的阻塞原因與待完成動作，追蹤解除阻塞後的重新 Refinement 排程 |
| **出席者確認** | 在 Refinement 前確認所有必要角色（含 Contract Owner）已通知並可出席 |

**Refinement 輸出（Scrum Master）：**

| 輸出項目 | 說明 |
|---------|------|
| Refinement 出席記錄 | 記錄本次 Refinement 出席角色及 Story 清單 |
| NOT_READY 追蹤清單 | 列出 NOT_READY Story、阻塞原因、負責解除阻塞的角色與目標時間 |
| 下次 Refinement 排程 | 若有 NOT_READY Story，安排重新 Refinement 的時間點 |

### 11.2 SRE Engineer Refinement 職責

SRE Engineer 在 Refinement 中負責識別 Story 的**基礎設施需求與部署風險**，確保 INFRA 類工作在開發前已規劃就緒。SRE 為**諮詢（Consulted）**角色，僅在涉及 INFRA 相關依賴的 Story 中出席。

**觸發出席條件（滿足任一即出席）：**

| 觸發條件 | 說明 |
|---------|------|
| Story Type 為 INFRA | SRE 作為 Contract Owner，必須出席確認基礎設施變更範圍 |
| FEATURE / INTEGRATION Story 包含 INFRA 前置依賴 | 需確認環境就緒時間與 Rollback 策略 |
| Story 涉及 CI/CD 流程變更 | CI/CD 變更影響所有角色，需 SRE 提前評估影響範圍 |
| Story 涉及多環境（dev/staging/prod）配置 | 環境配置變更需 SRE 確認執行時間窗口 |

**SRE Refinement 職責說明：**

| 面向 | 職責內容 |
|------|---------|
| **INFRA 工作量評估** | 判斷 FEATURE / INTEGRATION Story 中包含的 INFRA 工作量是否可忽略（設定調整）或需獨立拆分（SRE 設計建置）|
| **環境依賴確認** | 確認 Story 所需的環境（dev/staging/prod 端點、外部服務）在 Sprint 期間可用 |
| **Rollback 策略確認** | 對涉及部署變更的 Story，提前定義 Rollback 方案 |
| **Infra Prerequisites Checklist 提供** | 若 INFRA 工作量極小，提供 Infra Prerequisites Checklist（SRE 簽核後附於 FEATURE Contract）|

**SRE Refinement 輸出：**

| 輸出項目 | 說明 |
|---------|------|
| INFRA 工作量評估意見 | 判定 INFRA 部分是否需拆分為獨立 Story 或附加 Infra Prerequisites Checklist |
| 環境可用性確認 | 確認 Sprint 期間相關環境可用，若不確定則列為 NOT_READY 阻塞項目 |
| Infra Prerequisites Checklist（若適用） | 列出 SRE 需簽核的基礎設施前置條件，格式為 checkbox 清單 |

### 10.4 稽核追蹤

**標注規則：** 使用 Bypass 的 Story，在 `sprint_N.md` 的 Story 列末尾加上 `[BYPASS]` 標注。

**40% 上限：** 每個 Sprint 內 `[BYPASS]` Story 數量不得超過 Sprint 總 Story 數的 40%（向下取整）。

**計算示例：**

```
Sprint N 共 5 個 Story，Bypass 上限 = floor(5 × 0.4) = 2 個。
已有 2 個 [BYPASS] Story，後續 Story 不可再使用 Bypass。
```

**執行規則：**
- 派遣 Developer subagent 前確認當前 Sprint 的 `[BYPASS]` 使用數量
- 若已達上限，該 Story 即使符合觸發條件，仍須走完整流程
- Sprint Review 時統計 `[BYPASS]` 比例，列入 Metrics_Log.md
