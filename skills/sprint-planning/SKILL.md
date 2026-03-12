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

## 模型選用建議

> **Sprint Planning subagent 模型分配：**
>
> | Subagent | 模型 | 理由 |
> |----------|------|------|
> | PO Round 1 | `sonnet` | Backlog 分析與 Story 選取任務，Sonnet 已足夠且更穩定，可避免 Opus 超時導致 Planning 流程中斷 |
> | Architect | `opus` | 技術可行性評估與 ADR 檢查需要高層次策略推理 |
> | QA | `opus` | 驗收標準確認與 AC 驗證策略需要深度分析 |
> | PO Round 2 | `opus` | Sprint 文件產出與最終確認需要完整推理能力 |
>
> 派遣 subagent 時依上表指定 `model`，無需使用者手動切換。
> 主 session 模型不受影響，使用者無需執行 `/model` 切換。

---

## 2. 流程 Checklist

> **模式選擇**：預設為**快思模式**，跳過前 3 項（健康檢查、權重調整、Token 記錄），直接從 PO 選 Stories 開始。使用者傳入 `--deep` 或說「完整檢查」時切換至**慢想模式**，執行完整流程。

以下步驟必須逐項建立 task 完成，不可跳過：

- [ ] **執行框架健康檢查**（<!-- Claude Code -->invoke shikigami:health-check<!-- OpenCode -->使用 health-check skill<!-- /OpenCode -->）— 完整 4 項檢查（必要文件 + 孤兒 Story + ADR 一致性 + Retro 逾期）。CRITICAL 標注警告但不阻塞 Planning 流程 *(慢想模式限定)*
- [ ] **角色權重調整檢查**（US-22 / ADR-004）— 讀取 `docs/km/Retrospective_Log.md`，依關鍵字比對演算法判斷是否觸發調整；結果寫入 `docs/sprints/sprint_N.md`「## 權重調整記錄」區塊（詳見 §7） *(慢想模式限定)*
- [ ] **PO subagent** 掃描 GitHub open issues（`gh issue list --state open`），對未分類 issues 執行 Triage（<!-- Claude Code -->invoke shikigami:issue-management Triage<!-- OpenCode -->使用 issue-management skill 並傳入 Triage 任務<!-- /OpenCode -->），將 bug/feature-request 透過 Backlog Bridge 納入 Backlog
- [ ] **PO subagent** 執行 `gh issue list --label "type: backlog-item" --label "status: backlog" --state open --json number,title,body,labels --limit 200` 取得 Backlog Issues，並自行讀取 `docs/PROJECT_BOARD.md` 與 `docs/prd/ROADMAP.md`，根據即時排序（MoSCoW tier 優先，同 tier 內 RICE Score 降序）從排序頂部選取符合 Sprint Goal 與 ROADMAP 里程碑的 Stories，並回傳結構化摘要（Markdown 表格：Story ID / 標題 / 估點 / AC 確認結果）。**主 session 不讀取上述文件，僅接收 subagent 回傳的摘要表格。**
- [ ] **檢查選入的 Story 是否標注「需要 ADR」** — 若標注需要 ADR，則該 ADR 必須已建立且狀態為 Accepted，方可進入 Sprint
- [ ] **Architect subagent** 評估每個 Story 的技術工時（T-shirt size: S / M / L）
- [ ] **QA subagent** 確認每個 Story 的驗收標準（Acceptance Criteria）可被測試
- [ ] 上個 Sprint 的 **Retro Action Items** 自動列入 Backlog（若有未完成項目）
- [ ] **PO subagent** 建立 `docs/sprints/sprint_N.md`（N 為遞增的 Sprint 編號）
- [ ] 更新 `docs/PROJECT_BOARD.md`，反映新 Sprint 的 Stories 配置
- [ ] **記錄本次 Planning 環節 Token 消耗至 `docs/km/Metrics_Log.md` Token 成本分環節記錄表格**（對應 Planning token 欄） *(慢想模式限定)*：參照 `skills/sprint-execution/SKILL.md` §步驟詳解 步驟 7「記錄本次 Execution 環節 Token 消耗」的 Token 計算公式與降級方法執行，填入 Planning token 欄。<!-- OpenCode -->OpenCode session 資料路徑待 Phase 2 實機調查確認；暫時填「N/A」並輸出「Token 資料不可用，需手動補充」<!-- /OpenCode -->
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

**設定方式**：由 `schedule` Skill 生成的 cron 腳本（`scripts/<skill>_cron.sh`）在執行 <!-- Claude Code -->`claude -p "/sprint-planning"`<!-- OpenCode -->`opencode sprint-planning`（OpenCode 平台等效指令，待實機確認）<!-- /OpenCode --> 前自動注入 `SHIKIGAMI_SCHEDULED=true`，Sprint Planning 在執行期間讀取此環境變數以判斷當前模式。

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

<!-- Claude Code -->
```bash
# 手動 Sprint Planning（非排程模式），M/L Stories 不受限
claude -p "/sprint-planning"

# 手動 + 完整檢查（慢想模式），M/L Stories 不受限
claude -p "/sprint-planning --deep"
```
<!-- OpenCode -->
```bash
# 手動 Sprint Planning（非排程模式），M/L Stories 不受限
# OpenCode 等效指令待實機確認；預期為直接在 OpenCode 中呼叫 sprint-planning skill
opencode sprint-planning

# 手動 + 完整檢查（慢想模式），M/L Stories 不受限
opencode sprint-planning --deep
```
<!-- /OpenCode -->

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

| 文件 / 操作 | 說明 |
|------------|------|
| `docs/sprints/sprint_N.md` | 新建。包含 Sprint Goal、選入的 Stories 清單、T-shirt size 估算、驗收標準摘要 |
| `docs/PROJECT_BOARD.md` | 更新。反映新 Sprint 的 Stories 配置，將選入的 Stories 移至「Sprint Backlog」欄位 |
| GitHub Issues labels/milestone | 為選入的 Issues 套用 `status: in-sprint` label（移除 `status: backlog`）並設定對應的 Sprint Milestone（`gh issue edit <number> --milestone "Sprint N" --add-label "status: in-sprint" --remove-label "status: backlog"`） |

### Commit + Push 規範

完成上述任一 Sprint 狀態文件修改後，**立即執行**：

```bash
git add docs/PROJECT_BOARD.md docs/sprints/sprint_N.md
git commit -m "docs: Sprint N Planning — 更新看板與 Sprint 文件"
git push
```

> **範圍限制**：僅適用於 Sprint 狀態文件（`PROJECT_BOARD.md`、`sprint_N.md`、`Metrics_Log.md`、`Retrospective_Log.md`）；其他 KM 文件（ADR、SDD、PRODUCT_BACKLOG.md、ROADMAP.md 等）不適用，避免觸發 ADR-003 Out-of-Sprint Hard Gate。

---

## 6. Subagent 派遣順序

Sprint Planning 的 Subagent 調度遵循以下固定順序：

```
0.   健康檢查       → <!-- Claude Code -->invoke shikigami:health-check<!-- OpenCode -->使用 health-check skill<!-- /OpenCode -->（完整 4 項）【慢想模式限定】
0.5. 角色權重調整   → 讀取 Retrospective_Log.md，執行關鍵字比對，輸出調整結果至 sprint_N.md（詳見 §7）【慢想模式限定】
1.   PO             → 分析 Backlog、選取 Stories、定義 Sprint Goal        【model: "sonnet"】
2.   Architect      → 技術評估、ADR 檢查、方法論適用性評估                   【model: "opus"】
3.   QA             → 驗收標準確認                                         【model: "opus"】
4.   PO             → 產出 Sprint 文件                                     【model: "opus"】
```

**派遣說明**：

0.5. **角色權重調整檢查**：健康檢查完成後立即執行。讀取 `docs/km/Retrospective_Log.md`，統計已完成 Sprint 記錄數量。若少於 3 個則輸出「歷史資料不足 3 個 Sprint，跳過權重調整」；否則對 QA 領域執行關鍵字清單比對，判斷是否觸發升級或放寬。結果（無論調整與否）均持久化至 `docs/sprints/sprint_N.md`「## 權重調整記錄」區塊。完整規則詳見 §7。
0.9. **Issue 快掃**：委派 `/issue-management`（§11 Backlog Bridge 批次模式）執行 Issue 掃描與 comment 回覆（新 Issue 入庫、未處理 comment 回覆、Triage 分類）。降級指引：gh 指令失敗時靜默略過，不阻塞 Planning 流程。

1. **PO（第一輪）**：由 PO subagent 執行以下步驟選取 Stories，**主 session 不直接讀取這些資源**：

   **資料來源（PO subagent 讀取）**：
   - `gh issue list --label "type: backlog-item" --label "status: backlog" --state open --json number,title,body,labels --limit 200`（Backlog Issues）
   - `docs/PROJECT_BOARD.md`（專案進度與看板狀態）
   - `docs/prd/ROADMAP.md`（當前里程碑目標）

   **即時排序計算步驟（PO subagent 執行）**：
   1. 從 `gh issue list` 回傳的每個 Issue body，以正則表達式提取 RICE Score 數值（格式：`\*\*RICE Score\*\* \| \*\*(\d+(?:\.\d+)?)\*\*`）；提取失敗時以 RICE Score = 0 計算並記錄警告
   2. 從 Issue labels 提取 MoSCoW tier：`priority: must` → tier 1、`priority: should` → tier 2、`priority: could` → tier 3；無 priority label 時以 tier 3 計算
   3. 排序規則：先依 MoSCoW tier 升序（tier 1 最優先），同 tier 內依 RICE Score 降序
   4. 從排序結果頂部選取符合 Sprint Goal、當前里程碑目標（ROADMAP.md）與 Sprint 容量的 Stories

   PO subagent 回傳格式（Markdown 表格）：

   ```markdown
   | Story ID | 標題 | 估點 | AC 確認結果 | 獨立性評估 |
   |----------|------|------|------------|-----------|
   | US-XX    | ...  | M    | PASS / 待確認 | 獨立 / 與 US-YY 衝突（同修改 path/to/file） |
   ```

   此階段 PO 需明確定義本次 Sprint 要達成的目標，並評估各 Story 間的檔案修改獨立性：逐一列出每個 Story 預計修改的主要檔案，判斷哪些 Story 修改不同檔案（可平行執行），哪些 Story 修改相同檔案（有衝突，需順序執行）。「獨立性評估」欄位填入「獨立」或「與 US-XX 衝突（同修改 path/to/file）」，供 Architect 後續規劃平行派工分群使用。
2. **Architect**：對 PO 選取的每個 Story 進行技術可行性評估，給出 T-shirt size 估算（S/M/L），並檢查需要 ADR 的 Story 是否已有對應的 Accepted ADR。若涉及 API 互動的 Story，Architect 必須產出 API 契約（參閱 [Architect 角色決策指引 §7](../architect/SKILL.md)）。若發現 Hard Gate 問題，該 Story 退回 Backlog。詳細決策標準（估點策略、ADR 需求判斷、平行分群策略、API 契約產出）請參閱 [Architect 角色決策指引](../architect/SKILL.md)。

   **技術評估輸出表格**（正式輸出項目）：Architect 必須輸出包含「API 契約」欄位的技術評估結果：

   ```markdown
   ## 技術評估結果

   | Story | T-shirt | ADR 需求 | API 契約 | 說明 |
   |-------|---------|---------|---------|------|
   | US-XX | M | 無需 ADR | **有**（見下方契約定義） | {說明} |
   | US-YY | S | 無需 ADR | **無**（需補充，阻擋開發） | {說明} |
   | US-ZZ | S | 無需 ADR | **不適用** | doc-only，無 API 互動 |
   ```

   **API 契約欄位說明**：

   | 值 | 意義 |
   |----|------|
   | 有 | Architect 已產出 API 契約，Developer 可直接進入開發 |
   | 無 | Story 涉及 API 但 Architect 尚未產出契約，Story-Lifecycle Hard Gate 將阻擋開發 |
   | 不適用 | Story 不涉及 API 互動，Hard Gate 自動跳過 |

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

   **方法論適用性評估**（正式輸出項目）：Architect 須對每個 Story 自動執行方法論適用性評估（BDD/DDD），結果為建議性質，不阻塞流程。詳細觸發條件請參閱 [Architect 角色決策指引 §5](../architect/SKILL.md)。

   輸出格式：

   ```markdown
   ## 方法論適用性評估

   | Story ID | BDD 建議 | DDD 建議 | 說明 |
   |----------|---------|---------|------|
   | US-XX | 建議（B1, B2） | 不適用 | AC2 含多執行路徑 + CLI 輸出變更，建議補充行為範例 |
   | US-YY | 不適用 | 不適用 | doc-only，所有 AC 為 [靜態] |
   | US-ZZ | 不適用 | 建議（D1） | 引入新的 Domain Entity，建議先建領域模型 |
   ```

3. **QA**：逐一確認剩餘 Stories 的 Acceptance Criteria 是否明確且可被自動化測試驗證。若驗收標準模糊，退回 PO 補充後重新評估。詳細決策標準（AC 驗證策略、Spec Compliance review 決策、Code Quality review 策略）請參閱 [QA Engineer 角色決策指引](../qa-engineer/SKILL.md)。

   **路徑驗證規則（AC 路徑存在性檢查）**：
   - 若 Story 的 AC 中包含具體檔案路徑（例如 `docs/xxx.md`、`skills/xxx/SKILL.md`），QA **須執行 Glob 或 ls 確認路徑存在**，並在回報中標注：
     - `Path verification: PASS` — 路徑存在
     - `Path verification: FAIL` — 路徑不存在
     - `Path verification: N/A` — AC 未引用任何具體路徑
   - 若結果為 `FAIL`：QA 標記該 Story 為 `NEEDS_REVISION`，Story 退回 PO 修正路徑後重新提交。
   - 若 AC 不引用任何路徑：填 `N/A`，不需執行 Glob/ls。
4. **PO（第二輪）**：根據 Architect 與 QA 的回饋，最終確認 Sprint Backlog，建立 `docs/sprints/sprint_N.md`，並由 PO subagent 更新 `docs/PROJECT_BOARD.md`。PO subagent 同時為所有選入的 Issues 執行以下 GitHub 操作：套用 `status: in-sprint` label（移除 `status: backlog`）並設定對應的 Sprint Milestone。PO subagent 回傳最終 Sprint Backlog 結構化摘要（Markdown 表格：Story ID / 標題 / 估點 / AC 確認結果），**主 session 不直接讀取 PROJECT_BOARD.md，僅接收 subagent 回傳的摘要**。

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

---

## 8. Story Type 分類系統

<!-- US-201 Story Type 分類系統定義 — Sprint 76 -->

每個 Story 必須標注一個 Story Type，以決定適用的 Contract Owner、TDD 策略與 Review 規則。Type 由 PO 在 Backlog 建立 Story 時指定，Architect 在技術評估時確認。

### 8.1 Story Type 定義表（AC1）

| Type | 定義描述 | 典型範例 | Contract Owner |
|------|---------|---------|---------------|
| **FEATURE** | 新功能或現有功能增強，交付使用者可感知的業務價值 | 新增 Sprint Planning 快思模式、實作 CI Soft Gate、新增 API 端點 | **Architect** |
| **DESIGN** | UI/UX 設計相關，含視覺稿、互動設計、設計系統維護 | 設計登入頁面 Wireframe、更新 Design Token、建立元件規格書 | **UI/UX Designer** |
| **INFRA** | 基礎設施、部署、環境設定與維運相關 | 設定 CI/CD Pipeline、配置 Kubernetes Namespace、調整 Terraform 模組 | **SRE** |
| **SECURITY** | 安全掃描、權限控制、漏洞修復、合規性確認 | 修復 OWASP 注入漏洞、實作 JWT 刷新機制、執行 Dependency Audit | **Security Engineer** |
| **INTEGRATION** | 跨系統整合，含 API 串接、訊息佇列、第三方服務對接 | 整合 GitHub Webhook、串接 Slack 通知 API、實作 OAuth2 Provider 對接 | **Architect** |
| **RESEARCH** | 探索性調查、POC（概念驗證）、技術選型評估 | 評估 Vector DB 選型、POC Gemini CLI 整合可行性、調查 WebSocket 替代方案 | **N/A（需 Spike Report）** |

> **Contract Owner 說明**：Contract Owner 負責在 Story 進入 Sprint 前確認 API 契約（若適用）。FEATURE 與 INTEGRATION 共享 Architect 作為 Contract Owner，但職責不重疊——FEATURE 著重功能介面定義，INTEGRATION 著重跨系統協議定義。RESEARCH 無 Contract Owner，完成後須產出 Spike Report，內容包含調查結論與建議後續行動。

### 8.2 分類判斷決策表（AC2）

依以下規則順序判斷 Story Type，**以第一個符合的規則為準**：

| 優先順序 | 判斷條件 | 判定 Type |
|---------|---------|----------|
| 1 | Story 包含安全關鍵字（漏洞、CVE、權限、認證、加密、OWASP、掃描）或 AC 含 `[安全]` 標記 | **SECURITY** |
| 2 | Story 主要目的是調查、評估、POC，且無明確交付物（非文件類 deliverable）| **RESEARCH** |
| 3 | Story 修改的是 `infrastructure/`、`deployment/`、`.github/workflows/`、`scripts/` 目錄，或涉及環境設定、CI/CD 設定 | **INFRA** |
| 4 | Story 修改的是 `design/`、`assets/`、UI 元件目錄，或主要輸出為視覺設計稿 | **DESIGN** |
| 5 | Story 涉及對外部系統（第三方 API、訊息佇列、外部服務）的整合，且包含 API 契約定義 | **INTEGRATION** |
| 6 | 其他情況（新功能、增強現有功能、文件化已決策的功能） | **FEATURE** |

**邊界情況範例（至少 2 個）：**

| 邊界案例 | 判定理由 |
|---------|---------|
| **「新增 GitHub Webhook 端點」** — 此 Story 新增了一個接收 GitHub Webhook 的 API 端點，既像 FEATURE（新功能），又像 INTEGRATION（跨系統整合）。 | 判定為 **INTEGRATION**。規則 5 先於規則 6，且此 Story 的核心價值在於跨系統協議的建立，而非純粹的使用者功能交付。Contract Owner 為 Architect（需產出 Webhook 契約文件）。 |
| **「修復 JWT 過期 Bug 並補強 Token 刷新邏輯」** — 此 Story 修復了 Bug（像 FEATURE），但涉及認證機制修改（像 SECURITY）。 | 判定為 **SECURITY**。規則 1 最高優先，「認證」符合 SECURITY 關鍵字，且修改認證邏輯的風險等級需要 Security Engineer 確認。 |
| **「評估採用 Playwright 進行 E2E 測試的可行性」** — 此 Story 可能產出一份技術評估文件（像 FEATURE 的 doc-only），但目的是探索性調查。 | 判定為 **RESEARCH**。規則 2 適用，主要目的是調查與評估，輸出為 Spike Report 而非可交付的功能。無 Contract Owner，完成條件為產出 Spike Report。 |

### 8.3 Contract Owner 對照表（AC4）

每種 Type 對應唯一的 Contract Owner，無歧義重疊：

| Type | Contract Owner | Contract 職責 | 無 Contract Owner 的情況 |
|------|---------------|--------------|------------------------|
| FEATURE | Architect | 功能介面定義、模組邊界確認 | doc-only FEATURE 不涉及 API，Contract 欄填「不適用」 |
| DESIGN | UI/UX Designer | 設計規格確認、互動邏輯定義 | — |
| INFRA | SRE | 基礎設施變更確認、部署規格定義 | — |
| SECURITY | Security Engineer | 安全審查確認、漏洞修復驗收 | — |
| INTEGRATION | Architect | 跨系統 API 契約定義、協議確認 | — |
| RESEARCH | N/A | 無 Contract（產出 Spike Report） | RESEARCH 恆為 N/A |

> **衝突排除說明**：FEATURE 與 INTEGRATION 雖共享 Architect 作為 Contract Owner，但在同一 Sprint 中不會對同一介面同時產生 FEATURE 和 INTEGRATION Story，因此不存在 Contract 衝突。若罕見情況下出現同一介面的 FEATURE + INTEGRATION 並行，由 Architect 統一協調，以 INTEGRATION Contract 為主文件，FEATURE Contract 作為補充。

---

## 9. Refinement 機制

<!-- US-202 Refinement 機制 — Sprint 76 -->

Refinement 是 M/L size Story 在正式進入 Sprint 前的結構化分析流程，目的是在開發啟動前識別跨領域依賴、風險與拆分需求，減少 Sprint 中的意外阻塞。

### 9.1 Refinement Chair 角色（AC1）

**Chair**：由 **Architect** 擔任 Refinement Chair。

**職責範圍（與 §6 Architect subagent 的職責區分）：**

| 面向 | Refinement Chair（§9，Sprint Planning 前） | Architect subagent（§6，Sprint Planning Round 2） |
|------|------------------------------------------|--------------------------------------------------|
| 時機 | Sprint Planning **之前**，Story 準備進入 Sprint 時 | Sprint Planning **進行中**，PO Round 1 完成後 |
| 焦點 | 依賴識別、風險評估、Story 可拆分性判斷 | 技術可行性評估、ADR 需求判斷、平行分群建議 |
| 輸入 | Story 草稿（未正式進 Sprint Backlog） | PO Round 1 已選取的 Story 清單 |
| 輸出 | READY / NOT_READY 結論（§9.5） | 技術評估表格、ADR 觸發清單、平行分群建議 |
| 參與者 | Architect + 依 Story Type 決定的相關角色 | 主 session（接收回傳摘要） |

Refinement Chair 不替代 Architect subagent 的 Sprint Planning 評估職責；Refinement 是 Sprint Planning 的**前置門禁**，兩者互補。

### 9.2 Refinement 觸發條件（AC2）

#### 觸發規則

| Story Size | Refinement 要求 | 說明 |
|-----------|----------------|------|
| **M（2 Points）** | **必須**經過 Refinement | M size Story 具有一定複雜度，需提前識別依賴與風險 |
| **L（3 Points）** | **必須**經過 Refinement | L size Story 複雜度高，Refinement 為強制前置條件 |
| **S（1 Point）** | **免除** Refinement（預設） | S size Story 複雜度低，Architect 在 Sprint Planning Round 2 評估已足夠 |

#### S size 豁免例外

以下情況 S size Story **仍須**執行 Refinement，不得豁免：

| 豁免例外條件 | 說明 |
|------------|------|
| S size Story 跨越 3 個以上 Story Type 的邊界 | 例如同時涉及 FEATURE + INFRA + SECURITY，依賴關係複雜度不低於 M |
| S size Story 是另一個 M/L Story 的前置依賴（unblocking dependency） | 若 S size Story 未完成將阻塞 M/L Story，需在 Refinement 中確認介面契約 |
| S size Story 包含跨系統外部依賴（第三方 API、外部服務） | 外部依賴的可用性需在 Sprint 前確認，不應在 Sprint 中途發現阻塞 |

#### 免除 Refinement 的確認

S size Story 免除 Refinement 時，Architect 在 Sprint Planning Round 2 技術評估表格中標注「Refinement: 豁免（S-size）」，無需額外文件。

### 9.3 Refinement 在 Sprint Planning 中的位置（AC4）

Refinement 插入在 **§6 PO Round 1 之前**、Backlog 整理之後：

```
Sprint Planning 完整執行順序：

0.   健康檢查           【慢想模式限定】
0.5. 角色權重調整        【慢想模式限定】
0.9. Issue 快掃

[Refinement 區間] — 僅適用於 M/L size Story
R1.  Architect 擔任 Chair，執行 Refinement
R2.  產出 Refinement 報告（READY / NOT_READY）
R3.  NOT_READY Story 退回 Backlog，不進入 Sprint Planning

1.   PO Round 1        — 從已 READY 的 Story 中選取
2.   Architect Round 2 — 技術評估（§6 職責）
3.   QA               — 驗收標準確認
4.   PO Round 2       — 產出 Sprint 文件
```

**與 §2 Checklist 的銜接**：

- Refinement 發生在 §2 Checklist 的「PO subagent 選 Stories」步驟**之前**。
- PO Round 1（§2 第 4 個 Checklist 項目）選取的 Story 清單，已排除 NOT_READY Story。
- §2 Checklist 既有步驟不變，Refinement 為附加的前置步驟，不替換任何現有步驟。

**與 §6 派遣順序的銜接**：

- §6 所定義的 Subagent 派遣順序（步驟 0 → 4）保持不變。
- Refinement（R1–R3）發生在步驟 1（PO Round 1）之前，不影響 §6 內部順序。

### 9.4 Refinement 依賴分析 Checklist

Architect 在擔任 Refinement Chair 時，必須對每個 M/L Story 逐一回答以下問題。詳細跨領域依賴分析方法請參閱 [Architect 角色決策指引 §8](../architect/SKILL.md)。

| # | 問題 | 判斷條件 | 處置 |
|---|------|---------|------|
| Q1 | 這個 Story 開始前需要什麼前置條件？ | 是否有其他 Story 或外部工作必須先完成？ | 若有：記錄前置依賴，確認是否在同 Sprint 可達成；若不可達成，標記 NOT_READY |
| Q2 | 是否有其他 Story 依賴本 Story 的輸出？ | 本 Story 的產出物（API、文件、Schema）是否是其他 Story 的輸入？ | 若有：確認本 Story 優先排程；Contract Owner 必須出席 Refinement |
| Q3 | 本 Story 是否跨越多個 Story Type 需要拆分？ | 是否同時包含 INFRA + FEATURE、SECURITY + INTEGRATION 等跨 Type 組合？ | 若是：依 §8.2 規則判斷主 Type，評估是否拆成多個單一 Type Story |
| Q4 | Contract Owner 是否已確認？是否出席？ | 依 §8.3 對照表，Contract Owner 角色是否已知且可在本 Sprint 參與？ | 若缺席或未確定：標記 NOT_READY，等待 Contract Owner 確認後重新 Refinement |
| Q5 | 本 Story 能在一個 Sprint 內完成嗎？ | 依 §1 估點策略，M/L size 是否在 Sprint 容量內？ | 若不能：建議拆分為多個 S/M Story，分批進入不同 Sprint |

### 9.5 Refinement 輸出格式（AC5）

每個 M/L Story 完成 Refinement 後，Architect 必須輸出以下結構化報告：

```markdown
## Refinement 報告：{Story ID} — {Story 標題}

### Story Type 確認
- **Story Type**：{FEATURE / DESIGN / INFRA / SECURITY / INTEGRATION / RESEARCH}
- **判定依據**：{依 §8.2 決策表說明判定理由}
- **Contract Owner**：{角色名稱 / N/A}

### 依賴分析結果
| 問題 | 結論 | 備註 |
|------|------|------|
| Q1 前置條件 | {有/無} | {若有：列出具體前置 Story ID 或外部依賴} |
| Q2 下游依賴 | {有/無} | {若有：列出依賴本 Story 的 Story ID} |
| Q3 跨 Type 拆分 | {需要/不需要} | {若需要：建議拆分方案} |
| Q4 Contract Owner 出席 | {已確認/未確認} | {確認狀態說明} |
| Q5 單 Sprint 可完成 | {是/否} | {若否：建議拆分方式} |

### 跨領域依賴處置
{若有跨領域依賴（FEATURE + INFRA、FEATURE + SECURITY 等），說明處置方案：
- 拆分方案：{拆成哪些 Story}
- 或 Infra Prerequisites Checklist：{若 Infra 工作量極小，列出 SRE 簽核的清單項目}}

### 結論
**{READY / NOT_READY}**

{READY 時}：Story 通過 Refinement，可進入 Sprint Planning PO Round 1 選取。
{NOT_READY 時}：阻塞原因：{具體說明}。需完成以下動作後重新 Refinement：
- [ ] {待完成動作 1}
- [ ] {待完成動作 2}
```

**READY 條件**：Q1–Q5 全部無阻塞項目，或阻塞項目已有明確解決方案且可在本 Sprint 完成。

**NOT_READY 條件**：任一以下情況：
- 前置依賴無法在本 Sprint 解決
- Contract Owner 未確認且無法在 Sprint 期間參與
- Story 無法在一個 Sprint 內完成且尚未拆分

### 9.6 排程模式與 Refinement 的互動（AC6）

排程模式（§3.1）與 Refinement 機制有以下明確互動規則：

| 執行模式 | Refinement 行為 |
|---------|----------------|
| **排程模式**（`SHIKIGAMI_SCHEDULED=true`） | **完全跳過 Refinement**。排程模式僅允許 S-size Story，S-size 預設豁免 Refinement，因此排程模式下不會有任何 Story 需要 Refinement。 |
| **手動模式**（非排程） | 依 §9.2 觸發條件執行 Refinement，M/L size 必須，S size 預設豁免（豁免例外見 §9.2）。 |

**理由**：排程模式的 S-size HARD-GATE（§3.1）確保選入 Sprint 的 Story 全為 S-size，S-size 預設豁免 Refinement，因此兩個機制在邏輯上完全相容——排程模式下不會有任何觸發 Refinement 的 Story 進入選取流程。

**跨 Type 依賴的特殊處置（來自 Issue #199）**：

當 FEATURE Story 包含 INFRA 前置需求時，Refinement 依以下規則處置：

| 情況 | 處置方式 |
|------|---------|
| SRE 工作量不可忽略（需要獨立設計、建置或審查） | 拆分為獨立 INFRA Story，Contract Owner 由 SRE 擔任 |
| SRE 工作量極小（設定調整、參數修改等） | 在 FEATURE Contract 中附加 Infra Prerequisites Checklist，由 SRE 簽核後合併在 FEATURE Story 中執行 |

---

## 10. Type-specific DoR 與 DoD

<!-- US-204 Story Template 更新 — Sprint 76 -->

本節定義每種 Story Type 的 Definition of Ready（DoR）與 Definition of Done（DoD），在 Sprint Planning 與 Sprint Execution 時作為額外門禁條件使用。

### 10.1 Type-specific DoR（Definition of Ready）（AC3）

以下表格定義每種 Type 進入 Sprint 前必須滿足的 Ready 條件（每種至少 3 項）：

| Type | DoR 條件 | 說明 |
|------|---------|------|
| **FEATURE** | AC 以可測試格式撰寫（Given-When-Then 或等效格式） | 每條 AC 必須明確描述輸入、操作與預期結果 |
| **FEATURE** | API 契約已由 Architect 確認（涉及 API 時）| Contract Owner 已產出 API 契約（狀態 Reviewed 或 Accepted），或確認「不適用」 |
| **FEATURE** | 無未解決的前置依賴 | 依 §9.4 Q1 確認，所有前置 Story 已完成或可在本 Sprint 完成 |
| **FEATURE** | 技術評估已完成（Architect Round 2） | T-shirt size 已確認，ADR 需求已評估 |
| **DESIGN** | 設計稿或 Wireframe 已有初稿 | 不需最終版，但需有足夠細節供開發參考 |
| **DESIGN** | UI/UX Designer 已確認設計規格 | Contract Owner（UI/UX Designer）已簽核設計方向 |
| **DESIGN** | 相關設計系統（Design Token、元件規格）已確認 | 若修改既有元件，需確認與現有 Design System 的相容性 |
| **INFRA** | SRE 已確認基礎設施變更範圍 | Contract Owner（SRE）已理解並確認變更影響 |
| **INFRA** | 相關環境配置已識別（dev/staging/prod） | 需明確哪些環境受影響，並確認變更時間窗口 |
| **INFRA** | Rollback 策略已定義 | 若部署失敗，已有明確回滾方案 |
| **SECURITY** | 安全威脅已識別（Threat Model 或 AC 中明確） | 至少描述潛在威脅向量與受影響範圍 |
| **SECURITY** | Security Engineer 已確認修復方案方向 | Contract Owner（Security Engineer）已審查修復策略 |
| **SECURITY** | 相關 CVE/漏洞 ID 或 OWASP 類別已標注 | 修復對象有明確參考依據（如 CVE-XXXX-XXXXX 或 OWASP A01） |
| **INTEGRATION** | 外部系統 API 文件已可存取 | 第三方 API 規格或 Webhook 文件已確認可讀取 |
| **INTEGRATION** | 跨系統 API 契約已由 Architect 定義 | Contract Owner（Architect）已產出跨系統協議文件（狀態 Reviewed 或 Accepted） |
| **INTEGRATION** | 外部系統可用性已確認（dev/staging 端點） | 整合測試所需的端點可存取，或已有 Mock/Stub 替代方案 |
| **RESEARCH** | 調查範圍與問題陳述已明確 | Spike Report 的預期問題清單已定義 |
| **RESEARCH** | 時間盒（Time-box）已設定 | 調查有明確截止時間，避免無限期探索 |
| **RESEARCH** | 預期輸出格式已定義（Spike Report 結構） | 至少定義：調查結論、建議後續行動、技術風險評估 |

### 10.2 Type-specific DoD（Definition of Done）（AC4）

以下表格定義每種 Type 的完成條件，以 `sprint-execution/SKILL.md` §6 DoD 自檢對照表為基礎，差異項以 **[Type-specific]** 標記：

#### 通用 DoD 基準（來自 sprint-execution/SKILL.md §6）

所有 Type 均須通過以下通用 DoD 條件：

| 層次 | 條件 | 自檢 |
|------|------|------|
| 功能 | 所有 Acceptance Criteria 通過 | [ ] |
| 測試 | 單元測試 + 整合測試全部通過（0 failed） | [ ] |
| 安全 | 外部輸入通過安全驗證與去活化處理（或 N/A） | [ ] |
| 文件 | 設計文件對應章節已更新，代碼含設計文件引用 | [ ] |
| 設定 | 無硬編碼金鑰，配置透過環境變數管理 | [ ] |
| 度量 | Metrics_Log.md 本 Sprint 數據已更新 | [ ] |
| 反回歸 | 既有測試全部仍然通過 | [ ] |
| 技術債 | 取捷徑情況已用 `[TECH-DEBT]` 標記並更新 Tech_Debt_Registry.md（或 N/A） | [ ] |

#### Type-specific DoD 附加條件

| Type | 附加 DoD 條件 | 標記 |
|------|-------------|------|
| **FEATURE** | API 契約變更已同步更新至 Sprint Planning 技術評估表格（涉及 API 時）| [Type-specific] |
| **FEATURE** | SA 圖表（docs/sa/）已更新（涉及 API/Entity/業務流程變更時） | [Type-specific] |
| **DESIGN** | 最終設計稿或規格書已提交至指定設計資源路徑 | [Type-specific] |
| **DESIGN** | UI/UX Designer（Contract Owner）已執行最終驗收 | [Type-specific] |
| **DESIGN** | 測試：單元測試 + 整合測試（**豁免**，doc_only=true 時無程式碼交付物） | [Type-specific] |
| **INFRA** | Rollback 已在 staging 環境驗證（或記錄豁免理由） | [Type-specific] |
| **INFRA** | SRE（Contract Owner）已執行基礎設施變更驗收 | [Type-specific] |
| **INFRA** | 所有受影響環境（dev/staging/prod）的配置變更已同步 | [Type-specific] |
| **SECURITY** | 安全修復已通過對應的安全掃描工具驗證（或記錄手動驗證步驟） | [Type-specific] |
| **SECURITY** | Security Engineer（Contract Owner）已執行安全審查驗收 | [Type-specific] |
| **SECURITY** | OWASP 對照項目已在 AC 中標記為解決（適用時） | [Type-specific] |
| **INTEGRATION** | 跨系統整合已在 staging 環境端到端驗證 | [Type-specific] |
| **INTEGRATION** | API 契約（Architect 定義）已完整實作，無偏差 | [Type-specific] |
| **INTEGRATION** | 外部系統異常（超時、錯誤碼）的處理邏輯已測試 | [Type-specific] |
| **RESEARCH** | Spike Report 已產出，含調查結論、建議後續行動、技術風險評估 | [Type-specific] |
| **RESEARCH** | 測試：單元測試 + 整合測試（**豁免**，RESEARCH 無程式碼交付物） | [Type-specific] |
| **RESEARCH** | Spike Report 已由 PO/Architect 閱覽並確認納入後續 Backlog 規劃 | [Type-specific] |

> **doc_only 豁免說明**：DESIGN 與 RESEARCH type 因無程式碼交付物，「測試：單元測試 + 整合測試」項目自動豁免（標記 N/A）。其他通用 DoD 項目仍須遵守。

---

## 11. Product Owner（PO）Refinement 職責

<!-- US-203 角色 Refinement 職責定義 — Sprint 77 -->

PO 在 Refinement 中負責提供需求側的完整輸入，確保 Architect（Refinement Chair）能在充分資訊下完成依賴分析與 READY/NOT_READY 判定。

### 職責說明

| 面向 | 職責內容 |
|------|---------|
| **Story 草稿準備** | 在 Refinement 前確保 Story 草稿包含完整的 AC 列表、User Story 描述與初步 MoSCoW 優先級 |
| **驗收標準說明** | 向 Architect 說明每個 AC 的業務背景，協助判斷 Story Type 與依賴關係 |
| **範圍澄清** | 回應 Architect 在 Q1–Q5 分析過程中提出的範圍澄清問題 |
| **拆分決策配合** | 配合 Architect 的拆分建議，更新 Story 範圍與 AC 清單 |
| **NOT_READY 處置** | 接受 NOT_READY 結論，完成阻塞項目後重新提交 Refinement |

### Refinement 輸出

PO 在 Refinement 完成後需確認或更新以下項目：

| 輸出項目 | 說明 |
|---------|------|
| 更新後的 Story 草稿 | 反映 Refinement 中達成的範圍共識，AC 清單已更新 |
| 拆分 Story（若適用） | 若 Architect 建議拆分，PO 建立對應的新 Story，納入下次排序 |
| READY 確認 | READY 結論後，PO 確認 Story 可進入 Sprint Planning PO Round 1 |

---

## 12. SBE 範例體系（Specification by Example）

<!-- US-226 SBE 範例體系 — Sprint 84 -->

Sprint Planning 流程中的業務規則（Hard Gate、Refinement 觸發條件、排程模式限制等）均以 **SBE 範例**作為 ground truth 表達，並衍生為對應的測試案例。

### 12.1 SBE 使用時機

| 時機 | 說明 | 負責角色 |
|------|------|---------|
| **新增 Hard Gate 或業務規則** | 在 `docs/definition/sbe-examples/sprint-lifecycle/` 建立對應的 `.sbe.md` 文件，以 Given/When/Then 格式明確化規則的前置條件、觸發事件與預期結果 | Architect |
| **QA 驗收標準確認（§6 Step 3）** | QA subagent 執行路徑驗證與 AC 驗收時，可直接引用對應的 SBE Scenario 作為驗證依據，避免重複定義驗收邏輯 | QA |
| **修改既有流程規則** | 更新流程規則時，必須同步更新對應的 SBE 文件（SBE 為 ground truth，下游文件從 SBE 衍生） | 修改者 |
| **Discovery Phase 需求探索** | Product Brief 中的業務假設與驗證方法，可以 SBE 格式預先表達，作為後續 Story AC 的雛形 | PO + Architect |

### 12.2 Sprint Planning 相關 SBE 文件

| SBE 文件 | 對應業務規則 |
|---------|-----------|
| `docs/definition/sbe-examples/sprint-lifecycle/sprint_planning_scheduled_mode.sbe.md` | §3.1 排程模式 HARD-GATE（S-size 限制） |
| `docs/definition/sbe-examples/sprint-lifecycle/sprint_planning_refinement_gate.sbe.md` | §9.2 Refinement 觸發條件與豁免規則 |

### 12.3 SBE 格式標準

SBE 文件格式定義、欄位說明、轉換規則詳見：

- `docs/definition/sbe-examples/SBE_FORMAT.md`：Given/When/Then 標準格式
- `docs/definition/sbe-examples/SBE_TO_TEST_RULES.md`：SBE → 測試案例轉換規則
