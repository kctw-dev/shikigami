# Scrum Master 調度狀態圖

**文件類型**：SDD（輔助）
**最後更新**：2026-03-23
**維護者**：Scrum Master
**規格來源**：Issue #401、PB-2026-03-23-scrum-master-state-graph
**相關文件**：`skills/scrum-master/SKILL.md`

---

## 1. 說明

本文件以 Mermaid `stateDiagram-v2` 描述 Scrum Master 的完整調度狀態機，涵蓋：

- 標準 Sprint lifecycle：Planning → Execution → Review → Retrospective
- Exception path：Story blocked、Subagent crash、PO 介入、Escalation
- 關鍵轉換節點的決策樹說明

> **受眾**：Architect agent、Developer agent、Power User debug
> **原則**：本文件是行為文件化（documentation），不改變 SM 的實際調度行為

---

## 2. 完整 Sprint Lifecycle 狀態圖

```mermaid
stateDiagram-v2
    [*] --> Idle : 系統初始化

    Idle --> SessionStart : 使用者首次互動
    SessionStart --> Standup : 執行 /standup
    Standup --> PRDetection : standup 完成
    PRDetection --> Idle : 無待審 PR（靜默通過）
    PRDetection --> AwaitingPRAction : 偵測到待審排程 PR
    AwaitingPRAction --> Idle : 使用者選擇略過 / PR 處理完成

    Idle --> BacklogManagement : 使用者提出新需求
    BacklogManagement --> Idle : Backlog 更新完成

    Idle --> SprintPlanning : 開始新 Sprint / 使用者觸發
    BacklogManagement --> SprintPlanning : Backlog 有待選 Story

    state SprintPlanning {
        [*] --> CeremonyIntegrityCheck
        CeremonyIntegrityCheck --> GoalDefinition : 全部 Pass
        CeremonyIntegrityCheck --> [*] : 任一 Fail（阻塞，補齊後重審）
        GoalDefinition --> BacklogSelection
        BacklogSelection --> StoryEstimation
        StoryEstimation --> ACReview
        ACReview --> IssuesScan
        IssuesScan --> [*] : Planning 完成
    }

    SprintPlanning --> SprintExecution : Planning 儀式通過（4 項 checklist OK）

    state SprintExecution {
        [*] --> StorySelection : 選取最高優先級 Story
        StorySelection --> PreflightCheck : 判斷是否為框架文件修改
        PreflightCheck --> BypassEval : 非框架文件修改
        PreflightCheck --> FullProcess : 框架文件修改（強制完整流程）
        BypassEval --> BypassMode : Size=S 且無 ADR 依賴 / [QUICK] / Retro Action
        BypassEval --> FullProcess : 不符合 Bypass 條件
        BypassMode --> SubagentDispatch
        FullProcess --> SubagentDispatch
        SubagentDispatch --> StoryInProgress : Subagent 啟動
        StoryInProgress --> QualityGate : Story 實作完成
        QualityGate --> SecurityReview : QA 發現安全問題
        SecurityReview --> QualityGate : 安全問題解決
        QualityGate --> StoryDone : QA 通過
        StoryDone --> StorySelection : Sprint Backlog 仍有 Story
        StoryDone --> [*] : Sprint Backlog 全部完成
    }

    SprintExecution --> SystematicDebugging_PreReview : Sprint Review 前 HARD-GATE
    SystematicDebugging_PreReview --> SprintReview : 系統健康確認通過

    state SprintReview {
        [*] --> ReviewCeremonyCheck
        ReviewCeremonyCheck --> PODemo : 全部 Pass
        ReviewCeremonyCheck --> [*] : 任一 Fail（阻塞，補齊後重審）
        PODemo --> StakeholderConfirm
        StakeholderConfirm --> RetrospectiveLog
        RetrospectiveLog --> ActionItems
        ActionItems --> RoadmapUpdate
        RoadmapUpdate --> [*] : Review 完成
    }

    SprintReview --> DeploymentReadiness : Review 驗收通過
    DeploymentReadiness --> SystematicDebugging_PostDeploy : 部署完成（post-deploy health check）
    SystematicDebugging_PostDeploy --> Idle : 健康檢查通過

    SprintReview --> SprintPlanning : Review 完成且 Backlog 有待選 Story
    DeploymentReadiness --> Idle : 無新 Sprint 待開始
```

---

## 3. Exception Path 狀態圖

```mermaid
stateDiagram-v2
    state ExceptionHandling {
        [*] --> StoryBlocked
        [*] --> SubagentCrash
        [*] --> POIntervention
        [*] --> EscalationTriggered
    }

    StoryBlocked --> BlockedAnalysis : SM 偵測到 Story 無法繼續
    BlockedAnalysis --> WaitForUnblock : 阻塞原因記錄，等待解除
    BlockedAnalysis --> SelectNextStory : 有其他可執行 Story
    SelectNextStory --> SprintExecution_Running : 執行下一個 Story
    WaitForUnblock --> SprintExecution_Running : 阻塞解除
    WaitForUnblock --> POIntervention : 阻塞無法自行解除

    SubagentCrash --> CrashDetection : SM 偵測到 Subagent 無回應
    CrashDetection --> RetryDispatch : 可重試（第一次 crash）
    CrashDetection --> EscalationTriggered : 重試失敗或無法重試
    RetryDispatch --> SprintExecution_Running : 重試成功

    POIntervention --> RequirementsReview : PO 介入澄清需求
    RequirementsReview --> StoryRevised : 需求更新
    RequirementsReview --> StoryCancelled : Story 取消
    StoryRevised --> SprintExecution_Running : 重新執行
    StoryCancelled --> BacklogUpdate : 更新 Backlog

    EscalationTriggered --> DomainOwnerConsult : 先找領域負責角色
    DomainOwnerConsult --> Resolved : 領域角色解決
    DomainOwnerConsult --> StakeholderEscalation : 無法解決
    StakeholderEscalation --> Resolved : Stakeholder 仲裁
    Resolved --> SprintExecution_Running : 繼續執行
```

---

## 4. 意圖路由狀態圖

```mermaid
stateDiagram-v2
    [*] --> IntentAnalysis : 使用者訊息輸入

    IntentAnalysis --> BacklogManagement : 新需求 / 需求變更 / Grooming
    IntentAnalysis --> SprintPlanning : 開始 Sprint
    IntentAnalysis --> SprintExecution : 實作 Story
    IntentAnalysis --> ArchitectureDecision : 技術決策 / 架構
    IntentAnalysis --> QualityGate : 代碼審查 / PR 準備
    IntentAnalysis --> SecurityReview : 安全相關
    IntentAnalysis --> DeploymentReadiness : 部署 / 發布
    IntentAnalysis --> Escalation : 衝突 / 僵局
    IntentAnalysis --> SprintReview : Sprint 結束
    IntentAnalysis --> SystematicDebugging : Bug / 錯誤 / 測試失敗
    IntentAnalysis --> GitWorkflow : 分支隔離 / worktree / 合併 / PR
    IntentAnalysis --> ParallelDispatch : 多個獨立任務
    IntentAnalysis --> IssueManagement : Issue 管理 / 分類 / 回覆
    IntentAnalysis --> HealthCheck : 框架狀態 / 健康檢查
    IntentAnalysis --> Onboarding : 初始化 / 第一次使用
    IntentAnalysis --> Dispel : Legacy 考古 / 不熟悉 codebase
    IntentAnalysis --> DirectExecution : 日常開發（主 Agent 直接執行）

    note right of DirectExecution
        不觸發任何 Skill
        主 Agent 自行完成
    end note

    note right of Dispel
        互斥規則：
        Dispel = 理解系統（legacy）
        SystematicDebugging = 修復問題（活躍開發）
        不得同時觸發
    end note
```

---

## 5. 自動觸發狀態圖

```mermaid
stateDiagram-v2
    state AutoTriggerConditions {
        [*] --> CheckSprintStatus

        CheckSprintStatus --> AllStoriesDone : Sprint Backlog 全部完成
        AllStoriesDone --> SprintReview_Auto : 自動觸發 sprint-review

        CheckSprintStatus --> ReviewPassed : sprint-review 驗收通過
        ReviewPassed --> DeploymentReadiness_Auto : 自動觸發 deployment-readiness

        CheckSprintStatus --> ReviewDoneBacklogReady : Review 完成且 Backlog 有待選 Story
        ReviewDoneBacklogReady --> SprintPlanning_Auto : 自動觸發 sprint-planning

        CheckSprintStatus --> StoryImplemented : Story 實作完成
        StoryImplemented --> QualityGate_Auto : 自動觸發 quality-gate

        CheckSprintStatus --> QAFoundSecurity : quality-gate 發現安全問題
        QAFoundSecurity --> SecurityReview_Auto : 自動觸發 security-review

        CheckSprintStatus --> EscalationChainExhausted : 升級鏈走完仍無解
        EscalationChainExhausted --> Escalation_Auto : 自動觸發 escalation

        CheckSprintStatus --> CIFail : CI 狀態回傳 FAIL
        CIFail --> SystematicDebugging_CI : 自動觸發 systematic-debugging（建議）

        CheckSprintStatus --> BugFixDone : Bug 修復完成
        BugFixDone --> SystematicDebugging_BugVerify : 自動觸發 systematic-debugging（建議）
    }
```

---

## 6. project_level 行為矩陣

```mermaid
stateDiagram-v2
    state "project_level 決策" as PLDecision {
        [*] --> CheckLevel

        CheckLevel --> LowLevel : project_level = low
        CheckLevel --> MediumLevel : project_level = medium
        CheckLevel --> HighLevel : project_level = high

        LowLevel --> AutoExecute_All : 所有操作自動執行（含高風險）
        AutoExecute_All --> NotifyAfter : 事後通知

        MediumLevel --> CheckRisk : 評估操作風險
        CheckRisk --> AutoExecute_Low : 低風險操作
        CheckRisk --> QAReview_Auto : 高風險操作
        QAReview_Auto --> AutoExecute_High : QA subagent 審核後自動執行

        HighLevel --> CheckRisk_High : 評估操作風險
        CheckRisk_High --> AutoExecute_LowH : 低風險操作（自動執行）
        CheckRisk_High --> WaitHumanConfirm : 高風險操作（暫停等待人工確認）
        WaitHumanConfirm --> ExecuteAfterConfirm : 使用者確認後執行
    }

    note right of LowLevel
        低風險：Sprint Planning 完成後自動 Execution
        自動 Sprint Review、自動派工等
        project_level=low 禁止停下來問使用者
    end note
```

---

## 7. 關鍵轉換節點決策樹

### 7.1 Story 執行前：Bypass vs. 完整流程決策

```
Story 準備執行
├── 是框架文件修改（skills/、commands/、agents/ 下 .md）？
│   ├── YES → 強制完整流程（Bypass 禁止）
│   │         執行 Preflight Check（4 項 checklist）
│   │         全 Pass → 繼續 | 任一 Fail → 阻塞
│   └── NO ↓
├── 涉及外部 API 整合？
│   ├── YES → 強制完整流程（Bypass 禁止）
│   └── NO ↓
├── 涉及安全相關（認證 / 授權 / 加密 / 金鑰）？
│   ├── YES → 強制完整流程（Bypass 禁止）
│   └── NO ↓
├── Size = S 且無 ADR 依賴？
│   ├── YES → 可用 Bypass
│   └── NO ↓
├── 標注 [QUICK]？
│   ├── YES → 可用 Bypass
│   └── NO ↓
├── 來自 Retro Action Item？
│   ├── YES → 可用 Bypass
│   └── NO → 完整流程
│
└── [Bypass 可用時] Sprint 內 Bypass 使用數量 < 40% 上限？
    ├── YES → 套用 Bypass 模式（跳過：Architect 估點、QA AC 審查、雙階段 QA Review）
    └── NO → 已達上限，強制完整流程
```

### 7.2 Story Blocked 決策樹

```
偵測到 Story 阻塞
├── 阻塞原因是技術問題？
│   └── YES → 先找 Architect 協助解決
├── 阻塞原因是品質問題？
│   └── YES → 先找 QA Engineer
├── 阻塞原因是安全問題？
│   └── YES → 先找 Security Engineer
├── 阻塞原因是需求不明確？
│   └── YES → 找 Product Owner 澄清（PO 介入路徑）
├── 阻塞原因是部署 / 環境問題？
│   └── YES → 找 SRE Engineer
│
├── 有其他可執行 Story？
│   └── YES → 選取下一個 Story，繼續 Sprint Execution
│
├── 領域角色協助後仍無解？
│   └── YES → invoke shikigami:escalation
│
└── 升級鏈走完仍無解 → Stakeholder 最終仲裁
```

### 7.3 Subagent Crash Recovery 決策樹

```
Subagent 無回應 / 異常終止
├── 是第一次 crash？
│   ├── YES → 記錄 crash 原因，重新派遣（RetryDispatch）
│   └── NO ↓
├── 重試後再次 crash？
│   ├── Story 可拆分為更小任務？
│   │   └── YES → 拆分後重試
│   └── NO → 觸發 Escalation 路徑
│
└── 使用 SHIKIGAMI_SCHEDULED=1 環境下的 crash？
    └── 進入 worktree 隔離模式，建立 scheduled/* 分支
        等待下次互動 Session 自動偵測並建立 PR
```

### 7.4 Sprint Review 前 HARD-GATE 決策樹

```
Sprint Execution 完成，準備進入 Sprint Review
├── 強制執行 systematic-debugging（HARD-GATE）
│
├── systematic-debugging 結果：PASS？
│   ├── YES → 繼續進入 Sprint Review
│   └── NO → 停止進入 Review
│         系統健康問題需先修復
│         修復完成後重新執行 systematic-debugging
│
└── 進入 Sprint Review 儀式 Integrity Check（5 項 checklist）
    ├── 全部通過 → 儀式正常結束
    └── 任一未完成 → 阻塞，補齊後方可結束
```

---

## 8. 狀態定義索引

| 狀態 | 說明 | 觸發 Skill |
|------|------|-----------|
| `Idle` | 待機，等待使用者輸入或條件觸發 | — |
| `SessionStart` | Session 啟動序列開始 | `/standup` |
| `Standup` | 健康快篩 + Git 同步 + Sprint 進度 | `/standup` |
| `PRDetection` | 偵測待審排程 PR | — |
| `SprintPlanning` | Sprint 規劃儀式 | `sprint-planning` |
| `SprintExecution` | Story 執行中 | `sprint-execution` |
| `QualityGate` | 代碼審查與品質門禁 | `quality-gate` |
| `SecurityReview` | 安全性審查 | `security-review` |
| `SprintReview` | Sprint 回顧儀式 | `sprint-review` |
| `DeploymentReadiness` | 部署就緒檢查 | `deployment-readiness` |
| `SystematicDebugging_PreReview` | Review 前 HARD-GATE 健康檢查 | `systematic-debugging` |
| `SystematicDebugging_PostDeploy` | 部署後健康檢查 | `systematic-debugging` |
| `BacklogManagement` | Backlog 管理與 Grooming | `backlog-management` |
| `ArchitectureDecision` | 架構決策與 ADR | `architecture-decision` |
| `Escalation` | 升級鏈仲裁 | `escalation` |
| `GitWorkflow` | 分支 / worktree / PR 管理 | `git-workflow` |
| `ParallelDispatch` | 多任務並行調度 | `parallel-dispatch` |
| `IssueManagement` | GitHub Issue 管理 | `issue-management` |
| `HealthCheck` | 框架健康診斷 | `health-check` |
| `Onboarding` | 新用戶初始化 | `onboarding` |
| `Dispel` | Legacy codebase 考古 | `dispel` |
| `StoryBlocked` | Story 阻塞異常處理 | — |
| `SubagentCrash` | Subagent 異常恢復 | — |
| `POIntervention` | PO 介入需求澄清 | — |

---

## 9. 維護規範

1. **同步更新觸發條件**：每當 `skills/scrum-master/SKILL.md` 的 §5 或 §6 有變更，本文件必須同步更新
2. **新 Skill 接入**：新增 Skill 時，在第 4 節「意圖路由狀態圖」與第 8 節「狀態定義索引」中補充對應條目
3. **新 Exception Path**：發現新的異常情境時，在第 3 節補充對應 exception path
4. **DoD 條件**：SM Skill 變更的 DoD 必須包含「本文件已同步更新」
