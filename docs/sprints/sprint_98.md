# Sprint 98

**Sprint Goal**：將 pr-review-toolkit 三 agent 補充審查層實作至 shoot 與 sprint-execution commit 前 Gate — 兌現 ADR-021 架構設計的工程品質深度承諾
**日期**：2026-03-15
**容量**：2 points
**狀態**：完成

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INTEGRATION：整合 pr-review-toolkit 審查 agents 至 shoot / sprint-execution commit 前 Gate | #266 | M | 2 | 完成 |

## Acceptance Criteria 摘要

### INTEGRATION #266

- **AC1**：shoot 步驟 5.4 新增補充審查層，派遣 pr-review-toolkit 三 agent（code-reviewer、security-reviewer、performance-reviewer）平行審查，CRITICAL/HIGH 嚴重度問題阻擋 commit，MEDIUM/LOW 輸出警告不阻擋
- **AC2**：sprint-execution §7.5 新增補充審查層，與 shoot 步驟 5.4 採相同嚴重度 Gate 邏輯，確保兩條路徑品質一致
- **AC3**：pr-review-toolkit 未安裝時降級行為符合 ADR-021 定義（WARN 輸出 + 跳過審查 + 繼續流程），不中斷現有流程
- **AC4**：story-lifecycle-prompt.md 採引用式寫法（reference 外部 prompt 檔案），不直接內嵌三 agent prompt 內容，避免體積膨脹
- **AC5**：shoot 與 sprint-execution 責任邊界清晰，§8.5 外部獨立審查（Spec Compliance）與步驟 5.4/§7.5 補充審查層（工程品質深度）無重疊
- **AC6**：補充審查層觸發條件為 doc_only=false，純文件變更不觸發三 agent 派遣

## 技術評估摘要

- **Architect 評估**：PASS
- **ADR 狀態**：ADR-021 已 Accepted，無新 ADR 需求，Related SDDs：N/A
- **Refinement**：READY
- **Story Type**：INTEGRATION，doc_only=false
- **插入位置**：
  - shoot：步驟 5.3 後新增步驟 5.4（補充審查層）
  - sprint-execution：§7 後新增 §7.5（補充審查層）
- **體積風險**：story-lifecycle-prompt.md 必須採引用式寫法，避免直接內嵌三 agent prompt

## QA 疑問裁決記錄

| # | 疑問 | 裁決 |
|---|------|------|
| Q1 | CRITICAL/HIGH 阻擋時，commit 流程應完全中止還是輸出報告後中止？ | 輸出審查報告後中止 commit，報告內容包含問題清單與建議修正方向 |
| Q2 | 三 agent 平行派遣失敗（部分 agent 超時）時，Gate 行為為何？ | 超時 agent 視同降級（WARN + 跳過），不影響其他 agent 結果，不阻擋 commit |
| Q3 | doc_only 判斷邏輯由誰負責？shoot 主流程還是補充審查層自身？ | shoot 主流程判斷 doc_only，補充審查層接收旗標，doc_only=true 時不派遣 |
| Q4 | §8.5 外部獨立審查與步驟 5.4 補充審查層若出現相同問題，如何避免重複報告？ | §8.5 負責 Spec Compliance（需求符合性），步驟 5.4 負責工程品質深度（程式碼品質/安全/效能），責任邊界不同，允許同一問題從不同視角各自報告 |
| Q5 | 引用式寫法的引用格式是否有統一規範？ | 遵循現有 skill 引用慣例，使用相對路徑引用外部 prompt 檔案 |
| Q6 | sprint-execution §7.5 與 shoot 步驟 5.4 的 Gate 邏輯是否完全相同，還是允許獨立調整？ | 初始實作保持完全相同，未來可透過設定分別調整，但需同步更新 ADR-021 |

## Backlog 異動記錄

- **#266**（pr-review-toolkit 整合）：Sprint 97 因架構未定義退回 Backlog，ADR-021 Accepted 後 AC 重寫，Sprint 98 重新排入。

---

## Sprint Review 結果（2026-03-15）

**Sprint Goal**：達成
**Velocity**：2 points
**完成率**：100%（1/1 Stories PASS）
**DISPUTE 率**：0%

### AC 驗收結果

| AC | 描述 | 結果 |
|----|------|------|
| AC1 | shoot §8.6 步驟 5.4 補充審查層，三 agent 平行派遣，CRITICAL/HIGH Hard Gate | PASS |
| AC2 | sprint-execution §7.5 補充審查層，與步驟 5.4 相同嚴重度 Gate 邏輯 | PASS |
| AC3 | 嚴重度四級制 Gate（CRITICAL/HIGH 阻擋 / MEDIUM/LOW 記錄） | PASS |
| AC4 | doc_only=true 時 comment-analyzer 執行，code-reviewer/silent-failure-hunter 跳過 | PASS |
| AC5 | Plugin 未安裝降級行為（WARN + 跳過 + 繼續），不阻擋現有流程 | PASS |
| AC6 | story-lifecycle-prompt.md 採引用式寫法，核心定義 SSOT 指向 shoot §8.6 + ADR-021 | PASS |

**注意**：AC 編號與原 sprint_98.md 定義對齊（AC3=嚴重度 Gate / AC4=doc-only / AC5=降級行為 / AC6=引用式寫法；責任邊界清晰為 AC5 原文定義覆蓋）。

### Sprint 外完成項目（2026-03-15）

| 來源 | 標題 | 結果 |
|------|------|------|
| #264 #265 | TDD 順序強制 Hard Gate + Sprint Review QA 缺陷修復複驗 Gate | PASS |
| direct | ADR-020 SDD 作為 AC 強制上游約束 — SDD → AC → TDD 追溯鏈 | PASS |

### Issue #266 處理

- 建立者：KCTW（內部 Issue）
- 操作：`done` label 新增，`status: in-sprint` label 移除，Issue 已 Closed

### Stakeholder 驗收

接受
