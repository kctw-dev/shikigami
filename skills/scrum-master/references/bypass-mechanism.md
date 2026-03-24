# Bypass 機制

<!-- 本檔案由 scrum-master/SKILL.md §10 拆出，主文件以指針引用 -->

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
