---
name: sprint-planning
description: "Use when starting a new sprint, selecting stories from backlog, or beginning sprint planning ceremony"
---

# Sprint Planning — Sprint 週期起點

## 1. 概述

Sprint Planning 是每個 Sprint 週期的起點儀式。主要由 **Product Owner (PO)** 主持，**Architect** 與 **QA Engineer** 共同參與，確保選入 Sprint 的 Stories 在需求、技術可行性、驗收標準三方面皆已就緒。

**目標**：從 Product Backlog 頂部選取符合 Sprint Goal 的 Stories，經技術評估與驗收確認後，正式納入 Sprint Backlog。

---

## 2. 流程 Checklist

以下步驟必須逐項建立 task 完成，不可跳過：

- [ ] **執行框架健康檢查**（invoke shikigami:health-check）— 完整 4 項檢查（必要文件 + 孤兒 Story + ADR 一致性 + Retro 逾期）。CRITICAL 標注警告但不阻塞 Planning 流程
- [ ] **角色權重調整檢查**（US-22 / ADR-004）— 讀取 `docs/km/Retrospective_Log.md`，依關鍵字比對演算法判斷是否觸發調整；結果寫入 `docs/sprints/sprint_N.md`「## 權重調整記錄」區塊（詳見 §7）
- [ ] **PO subagent** 掃描 GitHub open issues（`gh issue list --state open`），對未分類 issues 執行 Triage（invoke shikigami:issue-management Triage），將 bug/feature-request 透過 Backlog Bridge 納入 Backlog
- [ ] **PO subagent** 自行讀取 `docs/prd/PRODUCT_BACKLOG.md`、`docs/PROJECT_BOARD.md` 與 `docs/prd/ROADMAP.md`，從 Backlog 頂部（依優先級排序）選取符合 Sprint Goal 與 ROADMAP 里程碑的 Stories，並回傳結構化摘要（Markdown 表格：Story ID / 標題 / 估點 / AC 確認結果）。**主 session 不讀取上述三個檔案，僅接收 subagent 回傳的摘要表格。**
- [ ] **檢查選入的 Story 是否標注「需要 ADR」** — 若標注需要 ADR，則該 ADR 必須已建立且狀態為 Accepted，方可進入 Sprint
- [ ] **Architect subagent** 評估每個 Story 的技術工時（T-shirt size: S / M / L）
- [ ] **QA subagent** 確認每個 Story 的驗收標準（Acceptance Criteria）可被測試
- [ ] 上個 Sprint 的 **Retro Action Items** 自動列入 Backlog（若有未完成項目）
- [ ] **PO subagent** 建立 `docs/sprints/sprint_N.md`（N 為遞增的 Sprint 編號）
- [ ] 更新 `docs/PROJECT_BOARD.md`，反映新 Sprint 的 Stories 配置
- [ ] **記錄本次 Planning 環節 Token 消耗至 `docs/km/Metrics_Log.md` Token 成本分環節記錄表格**（對應 Planning token 欄）：
  - **主要方法（優先）**：讀取 `~/.claude/projects/` 目錄下當前 session 的 JSONL 檔案，提取所有 `message.usage` 欄位中的 `input_tokens` 與 `output_tokens`，加總後填入 Metrics_Log.md 對應欄位。
  - **次選（降級方法）**：若 JSONL 檔案不存在、路徑不可存取、或 `message.usage` 欄位解析失敗，則各 token 欄填「N/A」，佔比欄填「N/A」，並輸出精確字串「Token 資料不可用，需手動補充」。
- [ ] **完成 `docs/PROJECT_BOARD.md` 或 `docs/sprints/sprint_N.md` 修改後，立即執行 git commit + git push**（僅限 Sprint 狀態文件，格式與範圍見 §5 Commit + Push 規範）

---

## 3. Hard Gate

<HARD-GATE>
沒有 ADR 的技術選型 Story 不能進 Sprint。
</HARD-GATE>

**說明**：任何涉及技術選型的 Story（例如選擇框架、資料庫、第三方服務等），必須先透過 `architecture-decision` Skill 完成 ADR（Architecture Decision Record）並獲得 Accepted 狀態。未通過此門禁的 Story 將被退回 Backlog，待 ADR 完成後方可在下次 Sprint Planning 重新選入。

---

## 4. Sprint 週期

**週期長度：1 週**

選擇 1 週的理由：

- **小團隊**：AI Agent Scrum Team 成員精簡，1 週足以完成一個有意義的增量
- **MVP 階段**：產品尚在早期驗證階段，需要快速迭代
- **高頻反饋**：縮短反饋迴圈，每週皆有機會調整方向

---

## 5. 產出文件

Sprint Planning 完成後，必須產出或更新以下文件：

| 文件 | 說明 |
|------|------|
| `docs/sprints/sprint_N.md` | 新建。包含 Sprint Goal、選入的 Stories 清單、T-shirt size 估算、驗收標準摘要 |
| `docs/PROJECT_BOARD.md` | 更新。反映新 Sprint 的 Stories 配置，將選入的 Stories 移至「Sprint Backlog」欄位 |
| `docs/prd/PRODUCT_BACKLOG.md` | 更新。已選入的 Story 標記狀態為 `In Sprint` 或對應的狀態標記 |

### Commit + Push 規範

完成上述任一 Sprint 狀態文件修改後，**立即執行**：

```bash
git add docs/PROJECT_BOARD.md docs/sprints/sprint_N.md
git commit -m "docs: Sprint N Planning — 更新看板與 Sprint 文件"
git push
```

> **範圍限制**：此即時 commit + push 規範**僅適用於 Sprint 狀態文件**（`PROJECT_BOARD.md`、`docs/sprints/sprint_N.md`、`docs/km/Metrics_Log.md`、`docs/km/Retrospective_Log.md`）。`Metrics_Log.md` 與 `Retrospective_Log.md` 雖位於 `docs/km/` 路徑，但屬 Sprint 狀態文件，適用本規範。其他 Knowledge Management 文件（ADR、SDD、PRODUCT_BACKLOG.md、ROADMAP.md、ROLE_BALANCE_CASES.md、Tech_Debt_Registry.md 等）**不在此規範範圍內**，避免觸發 ADR-003 Out-of-Sprint Hard Gate。

---

## 6. Subagent 派遣順序

Sprint Planning 的 Subagent 調度遵循以下固定順序：

```
0.   健康檢查       → invoke shikigami:health-check（完整 4 項）
0.5. 角色權重調整   → 讀取 Retrospective_Log.md，執行關鍵字比對，輸出調整結果至 sprint_N.md（詳見 §7）
1.   PO             → 分析 Backlog、選取 Stories、定義 Sprint Goal
2.   Architect      → 技術評估、ADR 檢查
3.   QA             → 驗收標準確認
4.   PO             → 產出 Sprint 文件
```

**派遣說明**：

0.5. **角色權重調整檢查**：健康檢查完成後立即執行。讀取 `docs/km/Retrospective_Log.md`，統計已完成 Sprint 記錄數量。若少於 3 個則輸出「歷史資料不足 3 個 Sprint，跳過權重調整」；否則對 QA 領域執行關鍵字清單比對，判斷是否觸發升級或放寬。結果（無論調整與否）均持久化至 `docs/sprints/sprint_N.md`「## 權重調整記錄」區塊。完整規則詳見 §7。
1. **PO（第一輪）**：先掃描 GitHub open issues 進行 Triage（question/invalid 直接回覆 + close，bug/feature-request 走 Backlog Bridge 納入 Backlog）。然後由 PO subagent 自行讀取以下三個檔案，根據優先級、Sprint Goal 與當前里程碑初步選取 Stories，並回傳結構化摘要表格，**主 session 不直接讀取這些檔案**：
   - `docs/prd/PRODUCT_BACKLOG.md`（Backlog 狀態與優先級）
   - `docs/PROJECT_BOARD.md`（專案進度與看板狀態）
   - `docs/prd/ROADMAP.md`（當前里程碑目標）

   PO subagent 回傳格式（Markdown 表格）：

   ```markdown
   | Story ID | 標題 | 估點 | AC 確認結果 | 獨立性評估 |
   |----------|------|------|------------|-----------|
   | US-XX    | ...  | M    | PASS / 待確認 | 獨立 / 與 US-YY 衝突（同修改 path/to/file） |
   ```

   此階段 PO 需明確定義本次 Sprint 要達成的目標，並評估各 Story 間的檔案修改獨立性：逐一列出每個 Story 預計修改的主要檔案，判斷哪些 Story 修改不同檔案（可平行執行），哪些 Story 修改相同檔案（有衝突，需順序執行）。「獨立性評估」欄位填入「獨立」或「與 US-XX 衝突（同修改 path/to/file）」，供 Architect 後續規劃平行派工分群使用。
2. **Architect**：對 PO 選取的每個 Story 進行技術可行性評估，給出 T-shirt size 估算（S/M/L），並檢查需要 ADR 的 Story 是否已有對應的 Accepted ADR。若發現 Hard Gate 問題，該 Story 退回 Backlog。

   **平行分群建議**（正式輸出項目）：Architect 須根據 PO 回傳表格中的「獨立性評估」欄位，輸出平行派工分群建議，供主 session 後續調度使用。

   輸出格式：

   ```markdown
   ## 平行分群建議

   ### Phase 1（可平行執行）
   | Story ID | 標題 | T-shirt | 說明 |
   |----------|------|---------|------|
   | US-XX    | ...  | S       | 修改獨立檔案，無衝突 |

   ### Phase 2（需序列執行）
   | Story ID | 標題 | T-shirt | 衝突原因 |
   |----------|------|---------|---------|
   | US-YY    | ...  | M       | 與 US-ZZ 同修改 path/to/file，需等 US-ZZ 完成後執行 |

   ### 檔案衝突分析
   | 衝突檔案 | 涉及 Story | 建議執行順序 |
   |---------|-----------|------------|
   | path/to/file | US-YY, US-ZZ | US-ZZ → US-YY |
   ```

   **分群規則**：
   - **Phase 1（可平行）**：PO 獨立性評估為「獨立」的 Story，可同時派遣給不同 Developer subagent 執行
   - **Phase 2（需序列）**：PO 獨立性評估標注衝突的 Story，需依建議順序逐一執行，避免 merge conflict
   - 若所有 Story 皆獨立，Phase 2 區塊可省略，填「無」
3. **QA**：逐一確認剩餘 Stories 的 Acceptance Criteria 是否明確且可被自動化測試驗證。若驗收標準模糊，退回 PO 補充後重新評估。

   **路徑驗證規則（AC 路徑存在性檢查）**：
   - 若 Story 的 AC 中包含具體檔案路徑（例如 `docs/xxx.md`、`skills/xxx/SKILL.md`），QA **須執行 Glob 或 ls 確認路徑存在**，並在回報中標注：
     - `Path verification: PASS` — 路徑存在
     - `Path verification: FAIL` — 路徑不存在
     - `Path verification: N/A` — AC 未引用任何具體路徑
   - 若結果為 `FAIL`：QA 標記該 Story 為 `NEEDS_REVISION`，Story 退回 PO 修正路徑後重新提交。
   - 若 AC 不引用任何路徑：填 `N/A`，不需執行 Glob/ls。
4. **PO（第二輪）**：根據 Architect 與 QA 的回饋，最終確認 Sprint Backlog，建立 `docs/sprints/sprint_N.md`，並由 PO subagent 更新 `docs/PROJECT_BOARD.md` 與 `docs/prd/PRODUCT_BACKLOG.md`。PO subagent 回傳最終 Sprint Backlog 結構化摘要（Markdown 表格：Story ID / 標題 / 估點 / AC 確認結果），**主 session 不直接讀取 PRODUCT_BACKLOG.md 或 PROJECT_BOARD.md，僅接收 subagent 回傳的摘要**。

---

## 7. 角色權重調整檢查（US-22 / ADR-004）

### 觸發時機

Sprint Planning 開始時，「健康檢查」完成後、「PO 第一輪」開始前執行。

### 執行步驟

1. 讀取 `docs/km/Retrospective_Log.md`
2. 計算 Sprint 記錄數量：
   - 少於 3 個 Sprint 記錄 → 輸出「歷史資料不足 3 個 Sprint，跳過權重調整」→ 寫入 sprint_N.md「## 權重調整記錄」→ 結束
3. 對每個監控領域執行比對：

#### QA 領域

**關鍵字清單**（ADR-004）：

```yaml
qa_keywords: ["QA", "審查", "Review", "Code Quality", "Spec Compliance", "雙階段", "品質"]
```

**比對規則**：
- 提取最近 2 個已完成 Sprint 的 `### Problem` 區塊
- 對每個 Problem 條列，檢查是否包含清單中任一關鍵字（大小寫不敏感）
- 連續 2 Sprint 均至少有一條 Problem 包含關鍵字 → 觸發 QA 升級
- 任一 Sprint 的 Problem 區塊不含任何清單關鍵字 → 連續計數歸零

**觸發後調整**：

| 條件 | 調整 |
|------|------|
| 連續 2 Sprint 有 QA 相關 Problem | QA Review 從 Should 升為 Hard Gate（Must，不可 Bypass） |
| 連續 2 Sprint 無 QA 相關 Problem（升級中） | QA Review 恢復為 Should（降級，自動解除 Hard Gate） |
| 連續 2 Sprint 無任何 Problem（所有領域） | Bypass 門檻從 S 放寬至 M |

### 輸出格式

**有調整時**（持久化至 sprint_N.md「## 權重調整記錄」）：

```
## 權重調整記錄

- 觸發條件：Sprint N-1（[匹配的 Problem 文字]，關鍵字：[關鍵字]）與 Sprint N（[匹配的 Problem 文字]，關鍵字：[關鍵字]）連續出現 QA 相關 Problem
- 調整項目：QA Review 升為 Hard Gate（Must），Bypass 不適用 QA 相關審查
- 生效 Sprint：Sprint N+1
```

**無調整時**（持久化至 sprint_N.md「## 權重調整記錄」）：

```
## 權重調整記錄

歷史趨勢穩定，無需調整
```

**資料不足時**（持久化至 sprint_N.md「## 權重調整記錄」）：

```
## 權重調整記錄

歷史資料不足 3 個 Sprint，跳過權重調整
```

### 關鍵字清單更新機制

更新時機：Sprint Review 的 Retrospective 環節。
更新觸發：Retrospective 記錄的 Problem 未被現有關鍵字捕捉時。
更新流程：SQA 識別漏判 → 提議新關鍵字 → Architect 確認 → 更新本節清單。
