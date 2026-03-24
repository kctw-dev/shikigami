# Scrum Master & SRE Engineer Refinement 職責

<!-- 本檔案由 scrum-master/SKILL.md §11 拆出，主文件以指針引用 -->
<!-- US-203 角色 Refinement 職責定義 — Sprint 77 -->

## 11. Scrum Master & SRE Engineer Refinement 職責

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
