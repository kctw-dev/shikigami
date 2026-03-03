---
name: sprint-planning
description: "Use when starting a new sprint, selecting stories from backlog, or beginning sprint planning ceremony"
---

# Sprint Planning — Sprint 週期起點

## 1. 概述

Sprint Planning 是每個 Sprint 週期的起點儀式。主要由 **Product Owner (PO)** 主持，**Architect** 與 **QA Engineer** 共同參與，確保選入 Sprint 的 Stories 在需求、技術可行性、驗收標準三方面皆已就緒。

**目標**：從 Product Backlog 頂部選取符合 Sprint Goal 的 Stories，經技術評估與驗收確認後，正式納入 Sprint Backlog。

---

## 1.1 快思/慢想模式

Sprint Planning 支援兩種執行模式：

### 快思模式（預設）

- **觸發方式**：直接執行 Sprint Planning（無需任何額外參數）
- **跳過項目**：完整健康檢查、Token 消耗測量、角色權重調整檢查
- **執行流程**：PO 選 Stories → Architect 技術評估 → QA 驗收標準確認 → 建立 Sprint 文件

### 慢想模式

- **觸發方式**：使用者傳入 `--deep` 參數或說「完整檢查」
- **執行流程**：健康檢查 → 角色權重調整 → PO 選 Stories → Architect 技術評估 → QA 驗收標準確認 → 建立 Sprint 文件 → Token 消耗記錄

---

## 2. 流程 Checklist

> **模式選擇**：預設為**快思模式**，跳過前 3 項（健康檢查、權重調整、Token 記錄），直接從 PO 選 Stories 開始。使用者傳入 `--deep` 或說「完整檢查」時切換至**慢想模式**，執行完整流程。

以下步驟必須逐項建立 task 完成，不可跳過：

- [ ] **執行框架健康檢查**（invoke shikigami:health-check）— 完整 4 項檢查（必要文件 + 孤兒 Story + ADR 一致性 + Retro 逾期）。CRITICAL 標注警告但不阻塞 Planning 流程 *(慢想模式限定)*
- [ ] **角色權重調整檢查**（US-22 / ADR-004）— 讀取 `docs/km/Retrospective_Log.md`，依關鍵字比對演算法判斷是否觸發調整；結果寫入 `docs/sprints/sprint_N.md`「## 權重調整記錄」區塊（詳見 §7） *(慢想模式限定)*
- [ ] **PO subagent** 掃描 GitHub open issues（`gh issue list --state open`），對未分類 issues 執行 Triage（invoke shikigami:issue-management Triage），將 bug/feature-request 透過 Backlog Bridge 納入 Backlog
- [ ] **PO subagent** 自行讀取 `docs/prd/PRODUCT_BACKLOG.md`、`docs/PROJECT_BOARD.md` 與 `docs/prd/ROADMAP.md`，從 Backlog 頂部（依優先級排序）選取符合 Sprint Goal 與 ROADMAP 里程碑的 Stories，並回傳結構化摘要（Markdown 表格：Story ID / 標題 / 估點 / AC 確認結果）。**主 session 不讀取上述三個檔案，僅接收 subagent 回傳的摘要表格。**
- [ ] **檢查選入的 Story 是否標注「需要 ADR」** — 若標注需要 ADR，則該 ADR 必須已建立且狀態為 Accepted，方可進入 Sprint
- [ ] **Architect subagent** 評估每個 Story 的技術工時（T-shirt size: S / M / L）
- [ ] **QA subagent** 確認每個 Story 的驗收標準（Acceptance Criteria）可被測試
- [ ] 上個 Sprint 的 **Retro Action Items** 自動列入 Backlog（若有未完成項目）
- [ ] **PO subagent** 建立 `docs/sprints/sprint_N.md`（N 為遞增的 Sprint 編號）
- [ ] 更新 `docs/PROJECT_BOARD.md`，反映新 Sprint 的 Stories 配置
- [ ] **記錄本次 Planning 環節 Token 消耗至 `docs/km/Metrics_Log.md` Token 成本分環節記錄表格**（對應 Planning token 欄） *(慢想模式限定)*：
  - **主要方法（優先）**：讀取 `~/.claude/projects/` 目錄下當前 session 的 JSONL 檔案，提取所有 `message.usage` 欄位中的 `input_tokens`、`cache_read_input_tokens`、`cache_creation_input_tokens` 與 `output_tokens`，依下列公式加總後填入 Metrics_Log.md 對應欄位：
    - **有效 input tokens = input_tokens + cache_read_input_tokens + cache_creation_input_tokens**
    - **output tokens = output_tokens**
  - **次選（降級方法）**：若 JSONL 檔案不存在、路徑不可存取、或 `message.usage` 欄位解析失敗，則各 token 欄填「N/A」，佔比欄填「N/A」，並輸出精確字串「Token 資料不可用，需手動補充」。
- [ ] **完成 `docs/PROJECT_BOARD.md` 或 `docs/sprints/sprint_N.md` 修改後，立即執行 git commit + git push**（僅限 Sprint 狀態文件，格式與範圍見 §5 Commit + Push 規範）

---

## 3. Hard Gate

<HARD-GATE>
沒有 ADR 的技術選型 Story 不能進 Sprint。
</HARD-GATE>

**說明**：任何涉及技術選型的 Story（例如選擇框架、資料庫、第三方服務等），必須先透過 `architecture-decision` Skill 完成 ADR（Architecture Decision Record）並獲得 Accepted 狀態。未通過此門禁的 Story 將被退回 Backlog，待 ADR 完成後方可在下次 Sprint Planning 重新選入。

---

## 3.1 排程模式（Scheduled Mode）

排程模式是指 Sprint Planning 由 cron 自動觸發（而非 Scrum Master 手動執行）的執行情境。排程執行缺乏人工介入，因此須限制選入較小的 Stories，以確保自動化執行在安全的 context 與時間邊界內完成。

### 偵測機制（AC4）

排程模式透過環境變數 `SHIKIGAMI_SCHEDULED` 偵測：

| 環境變數 | 值 | 意義 |
|----------|----|------|
| `SHIKIGAMI_SCHEDULED` | `true` | 排程模式（cron 觸發） |
| `SHIKIGAMI_SCHEDULED` | 未設定或其他值 | 手動模式（非排程模式） |

**設定方式**：由 `schedule` Skill 生成的 cron 腳本（`scripts/<skill>_cron.sh`）在執行 `claude -p "/sprint-planning"` 前自動注入 `SHIKIGAMI_SCHEDULED=true`，Sprint Planning 在執行期間讀取此環境變數以判斷當前模式。

偵測邏輯（虛擬碼）：

```bash
if [[ "${SHIKIGAMI_SCHEDULED:-}" == "true" ]]; then
  # 排程模式：啟用 S-size 篩選 HARD-GATE
  SCHEDULED_MODE=true
else
  # 手動模式：不啟用 S-size 篩選，保持原有行為
  SCHEDULED_MODE=false
fi
```

### S-size 篩選 HARD-GATE（AC1、AC2）

<HARD-GATE>
排程模式下，M/L Stories 不得選入 Sprint Backlog，僅 S size Stories 可納入。
</HARD-GATE>

**適用條件**：`SHIKIGAMI_SCHEDULED=true` 環境變數已設定。

**規則說明**：

- 排程執行環境無人工監督，M/L size Stories 可能因 context 超限或執行時間過長導致失敗
- S size Stories 估點為 1，執行風險可控，適合全自動化流程
- PO subagent 在排程模式下選取 Stories 時，必須先過濾非 S size Stories

**違規處理**：若 PO subagent 在排程模式下選入 M 或 L size Stories，Sprint Planning **必須中止**，並輸出以下告警：

```
[SCHEDULED-MODE-GATE] 排程模式下僅允許 S size Stories。
偵測到非 S size Story：
- <Story ID>：<標題>（Size: <M 或 L>）

Sprint Planning 已中止。請改為手動執行 Sprint Planning 以選入 M/L size Stories。
```

### 非排程模式不受影響（AC3）

非排程模式（手動 Sprint Planning，`SHIKIGAMI_SCHEDULED` 未設定或非 `true`）的 Story 選取邏輯**不受影響**：

- M/L Stories 仍可依原有流程（§6 Subagent 派遣順序）選入 Sprint Backlog
- §2 流程 Checklist 所有步驟保持不變
- §3 ADR Hard Gate 保持不變
- 快思/慢想模式（§1.1）保持不變

手動執行範例：

```bash
# 手動 Sprint Planning（非排程模式），M/L Stories 不受限
claude -p "/sprint-planning"

# 手動 + 完整檢查（慢想模式），M/L Stories 不受限
claude -p "/sprint-planning --deep"
```

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
0.   健康檢查       → invoke shikigami:health-check（完整 4 項）【慢想模式限定】
0.5. 角色權重調整   → 讀取 Retrospective_Log.md，執行關鍵字比對，輸出調整結果至 sprint_N.md（詳見 §7）【慢想模式限定】
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

   ### 防漂移約束（Drift Protection）

   **比對規則**：PO Round 2 回傳的 Story 清單，其 Story ID 與標題欄位必須與 Round 1 回傳的結構化摘要完全一致。任何欄位不符均視為偏離，不得靜默接受。

   **偏離判定規則**：下列任一情形即為偏離：

   | # | 偏離類型 | 判定條件 |
   |---|----------|----------|
   | 1 | Story ID 不符 | Round 2 清單中出現 Round 1 未選取的 Story ID，或缺少 Round 1 已選取的 Story ID |
   | 2 | 標題被改寫 | Round 2 回傳的 Story 標題與 Round 1 回傳的標題不完全相同（任何文字變動均算） |
   | 3 | AC 被新增/刪除 | Round 2 回傳的 Story AC 條目數量或內容與 Round 1 不同（新增或刪除任一 AC） |

   > **備註**：若 Round 1 回傳空表格（0 個 Story），Round 2 亦須回傳空表格；Round 2 新增任何 Story 均視為偏離類型 1，觸發 DRIFT-ALERT。

   **告警處理路徑**：

   - 偵測到偏離時，QA 告警並要求 PO 重新派遣，不靜默接受
   - QA 須列出所有偏離項目，明確指出每一個偏離的 Story ID 及偏離類型
   - PO 重新派遣後，QA 重新執行比對，直至完全一致方可繼續後續流程

   **告警格式範例**：

   ```
   [DRIFT-ALERT] PO Round 2 輸出偏離 Round 1，要求 PO 重新派遣。

   偏離項目：
   - US-XX：標題被改寫（Round 1：「原始標題」→ Round 2：「改寫後標題」）
   - US-YY：AC 被刪除（Round 1 有 3 條 AC，Round 2 僅有 2 條）
   - US-ZZ：Story ID 不符（Round 2 出現 Round 1 未選取的 ID）

   請 PO 重新派遣，確保 Round 2 Story 清單與 Round 1 完全一致後再繼續。
   ```

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
