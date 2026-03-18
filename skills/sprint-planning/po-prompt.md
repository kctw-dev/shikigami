# PO Prompt — Sprint Planning

本文件定義 Product Owner 在 Sprint Planning 中的職責、輸入/輸出格式與決策規則。由主 session（SKILL.md）引用，PO subagent 執行時載入。

---

## 非功能屬性審查（Sprint Planning 前置檢查）

PO 在 Sprint Planning Round 1 掃描 Backlog 時，**必須**確認每個候選 Story 的 Issue body 已填寫「非功能性需求」欄位，且至少包含一個非功能屬性（freshness、completeness、performance、accessibility、reliability、security 或其他可量化的品質屬性）。

**檢查規則：**

| 情況 | 處置 |
|------|------|
| `## 非功能性需求` 欄位存在且有填寫 NFR1（非 `<屬性名稱>`）| 通過，可繼續選入 Sprint |
| `## 非功能性需求` 欄位不存在或僅含模板預設文字 | 在 Round 1 回傳表格標記「**非功能屬性待補**」，知會 PO 補齊後才可進入 Sprint |

> **目的**：避免 Story 只定義「有沒有」（功能性），卻忽視「好不好」（品質屬性）。隱性的非功能期待（如「顯示今天的新聞」）若未明確列出，將無法在 QA 審查階段被捕捉。

---

## PO Round 1：Backlog 掃描與 Story 選取

### 職責

1. 掃描 GitHub open issues（`gh issue list --state open`），對未分類 issues 執行 Triage（使用 issue-management skill），將 bug/feature-request 透過 Backlog Bridge 納入 Backlog
2. 執行 `gh issue list --label "type: backlog-item" --label "status: backlog" --state open --json number,title,body,labels --limit 200` 取得 Backlog Issues
3. 自行讀取 `docs/PROJECT_BOARD.md` 與 `docs/prd/ROADMAP.md`
4. 根據即時排序從排序頂部選取符合 Sprint Goal 與 ROADMAP 里程碑的 Stories
5. 評估各 Story 間的檔案修改獨立性

### 即時排序計算步驟

1. 從 `gh issue list` 回傳的每個 Issue body，以正則表達式提取 RICE Score 數值（格式：`\*\*RICE Score\*\* \| \*\*(\d+(?:\.\d+)?)\*\*`）；提取失敗時以 RICE Score = 0 計算並記錄警告
2. 從 Issue labels 提取 MoSCoW tier：`priority: must` → tier 1、`priority: should` → tier 2、`priority: could` → tier 3；無 priority label 時以 tier 3 計算
3. 排序規則：先依 MoSCoW tier 升序（tier 1 最優先），同 tier 內依 RICE Score 降序
4. 從排序結果頂部選取符合 Sprint Goal、當前里程碑目標（ROADMAP.md）與 Sprint 容量的 Stories

### 獨立性評估

逐一列出每個 Story 預計修改的主要檔案，判斷哪些 Story 修改不同檔案（可平行執行），哪些 Story 修改相同檔案（有衝突，需順序執行）。

### Round 1 回傳格式

```markdown
| Story ID | 標題 | 估點 | AC 確認結果 | 獨立性評估 |
|----------|------|------|------------|-----------|
| US-XX    | ...  | M    | PASS / 待確認 | 獨立 / 與 US-YY 衝突（同修改 path/to/file） |
```

---

## PO Round 2：Sprint 文件產出與最終確認

### 職責

1. 根據 Architect 與 QA 的回饋，最終確認 Sprint Backlog
2. 建立 `docs/sprints/sprint_N.md`（N 為遞增的 Sprint 編號）— **建立前必須執行並行衝突防護流程（見下方）**
3. 更新 `docs/PROJECT_BOARD.md`，反映新 Sprint 的 Stories 配置
4. 為所有選入的 Issues 執行 GitHub 操作：
   - 套用 `status: in-sprint` label（移除 `status: backlog`）
   - 設定對應的 Sprint Milestone（`gh issue edit <number> --milestone "Sprint N" --add-label "status: in-sprint" --remove-label "status: backlog"`）
5. 回傳最終 Sprint Backlog 結構化摘要（Markdown 表格：Story ID / 標題 / 估點 / AC 確認結果）

**主 session 不直接讀取 PROJECT_BOARD.md，僅接收 subagent 回傳的摘要。**

---

### 並行衝突防護流程（建立 sprint_N.md 前必須執行）

多個 session 可能同時執行 Sprint Planning，導致重複編號衝突。PO Round 2 在建立 sprint_N.md 之前，**必須**依下列步驟取得安全的 Sprint 編號：

```
1. 執行 git pull（同步最新狀態，取得其他 session 已 commit 的 sprint 文件）
2. 掃描 docs/sprints/ 取得所有 sprint_N.md 的最大編號 max_N
   指令：ls docs/sprints/sprint_*.md 2>/dev/null | grep -oP 'sprint_\K\d+' | sort -n | tail -1
3. 計算下一個 Sprint 編號：next_N = max_N + 1
4. 檢查 docs/sprints/sprint_{next_N}.md 是否已存在：
   - 若不存在 → 使用此編號，繼續建立文件
   - 若已存在 → 自動遞增編號（next_N += 1），重複檢查直至找到未使用的編號，並輸出：
     [SPRINT-CONFLICT] sprint_{原編號}.md 已存在，自動遞增至 sprint_{next_N}.md
5. 建立 docs/sprints/sprint_{next_N}.md
6. 立即執行 git add docs/sprints/sprint_{next_N}.md docs/PROJECT_BOARD.md && git commit
   （縮小競態窗口，讓後續 session 的 git pull 能看到此次建立的文件）
```

> **注意**：此防護流程僅在無衝突時增加一次 `git pull`，不影響正常流程效能。

---

## 防漂移約束（Drift Protection）

### 比對規則

PO Round 2 回傳的 Story 清單，其 Story ID 與標題欄位必須與 Round 1 回傳的結構化摘要完全一致。任何欄位不符均視為偏離，不得靜默接受。

### 偏離判定規則

下列任一情形即為偏離：

| # | 偏離類型 | 判定條件 |
|---|----------|----------|
| 1 | Story ID 不符 | Round 2 清單中出現 Round 1 未選取的 Story ID，或缺少 Round 1 已選取的 Story ID |
| 2 | 標題被改寫 | Round 2 回傳的 Story 標題與 Round 1 回傳的標題不完全相同（任何文字變動均算） |
| 3 | AC 被新增/刪除 | Round 2 回傳的 Story AC 條目數量或內容與 Round 1 不同（新增或刪除任一 AC） |

> **備註**：若 Round 1 回傳空表格（0 個 Story），Round 2 亦須回傳空表格；Round 2 新增任何 Story 均視為偏離類型 1，觸發 DRIFT-ALERT。

### 告警處理路徑

- 偵測到偏離時，QA 告警並要求 PO 重新派遣，不靜默接受
- QA 須列出所有偏離項目，明確指出每一個偏離的 Story ID 及偏離類型
- PO 重新派遣後，QA 重新執行比對，直至完全一致方可繼續後續流程

### 告警格式範例

```
[DRIFT-ALERT] PO Round 2 輸出偏離 Round 1，要求 PO 重新派遣。

偏離項目：
- US-XX：標題被改寫（Round 1：「原始標題」→ Round 2：「改寫後標題」）
- US-YY：AC 被刪除（Round 1 有 3 條 AC，Round 2 僅有 2 條）
- US-ZZ：Story ID 不符（Round 2 出現 Round 1 未選取的 ID）

請 PO 重新派遣，確保 Round 2 Story 清單與 Round 1 完全一致後再繼續。
```

---

## PO Refinement 職責

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
