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
6. **[RETRO-AUTO-PROMOTE] retro-action 高優先級自動升格**（#739）：掃描帶有 `retro-action` + `priority: must` label 的 open Issues，自動加入 `sprint-candidate` label，並輸出 `[RETRO-AUTO-PROMOTE] #N → sprint-candidate`。此步驟在 Backlog 排序之前執行，確保高優先 retro-action 不被遺漏。

   ```bash
   # 自動升格邏輯（偽碼）
   RETRO_MUST=$(gh issue list -R ${OWNER_REPO} \
     --label "retro-action" --label "priority: must" \
     --state open --json number,title,labels \
     | jq -r '.[] | select(.labels | map(.name) | contains(["sprint-candidate"]) | not) | .number')
   for N in $RETRO_MUST; do
     gh issue edit $N -R ${OWNER_REPO} --add-label "sprint-candidate"
     echo "[RETRO-AUTO-PROMOTE] #${N} → sprint-candidate"
   done
   ```

   **NFR1（冪等性）**：僅升格尚未帶有 `sprint-candidate` label 的 Issues，避免重複操作。
   **NFR2（範圍限定）**：僅針對 `priority: must` 的 retro-action，不升格 should/could，避免過度自動化。

### 即時排序計算步驟

<!-- #564 RICE Score 補充 — Sprint 132 -->

1. 從 `gh issue list` 回傳的每個 Issue body，以正則表達式提取 RICE Score 數值（格式：`\*\*RICE Score\*\* \| \*\*(\d+(?:\.\d+)?)\*\*`）；提取失敗時以 RICE Score = 0 計算並記錄警告
2. 從 Issue labels 提取 MoSCoW tier：`priority: must` → tier 1、`priority: should` → tier 2、`priority: could` → tier 3；無 priority label 時以 tier 3 計算
3. 排序規則：先依 MoSCoW tier 升序（tier 1 最優先），同 tier 內依 RICE Score 降序
4. 從排序結果頂部選取符合 Sprint Goal、當前里程碑目標（ROADMAP.md）與 Sprint 容量的 Stories

> **RICE Score 評分標準**：`docs/km/rice-scoring-standard.md`（2026-03-24 建立）
> - 計算公式：`(Reach × Impact × Confidence) / Effort`
> - Reach：1-4（影響角色數），Impact：1-5（改善程度），Confidence：50%-100%，Effort = Story Points
> - Issue body 格式：`**RICE Score** | **N.N**`（po-prompt.md 正則提取使用此格式）
> - 無 RICE Score 的 Story 以 RICE = 0 計算（排在同 tier 最後），新開 sprint-candidate 時應補充

### Sprint 容量估算基準

#### 容量上限

- **Sprint 容量基準：5-8 pts**
- 上限為 8 pts，不得超載

#### 計算公式

1. 取最近 3 個 Sprint 的 velocity 平均值
2. 加減 1 pt 作為彈性區間
3. 上限不超過 8 pts，下限不低於 5 pts

#### 範例

| Sprint | Velocity |
|--------|----------|
| Sprint N-2 | 7 pts |
| Sprint N-1 | 7 pts |
| Sprint N | TBD |
| **平均** | **7 pts** |
| **建議容量** | **6-8 pts** |

#### 超載處理

若候選 Story 總點數超過上限：

1. 依 MoSCoW 優先級從 Could → Should 順序移除
2. 不得壓縮估點來「塞進」更多 Story

### 獨立性評估

逐一列出每個 Story 預計修改的主要檔案，判斷哪些 Story 修改不同檔案（可平行執行），哪些 Story 修改相同檔案（有衝突，需順序執行）。

### RICE Score 與路由 Tier 交叉審查（ADR-039 決策 2.6，#854，Sprint 166）

<!-- #854 retro: haiku 路由比例偏低 — ADR-039 Score 4-5 TEST/DOC 強制 haiku 規則 — Sprint 166 -->

PO 完成 Story 選取後，必須執行 haiku 比例交叉審查：

1. 對每個選入 Story，評估 Story Type（TEST / DOC / LOG / FEATURE / INFRA...）與風險分數
2. Score 4-5 且 Story Type ∈ {TEST, DOC, LOG} → 強制路由至 haiku（Tier 1），不可依賴 agent 主觀判斷
3. 計算 haiku 預估比例：`haiku_ratio = haiku_stories / total_stories`
4. 若 `haiku_ratio < 20%`，PO 必須逐一說明 Tier 2+ 選用理由，確認無可降級 Stories

**AC2 交叉審查輸出格式**（加入 Round 1 回傳表格）：

```markdown
| Story ID | 標題 | 估點 | AC 確認結果 | 獨立性評估 | Story Type | Risk Score | Routing Tier |
|----------|------|------|------------|-----------|-----------|-----------|-------------|
| US-#N    | ...  | S    | PASS       | 獨立      | TEST      | 5         | haiku（強制） |
| US-#M    | ...  | M    | PASS       | 獨立      | FEATURE   | 8         | sonnet       |
```

若 `haiku_ratio < 20%`：輸出 `[HAIKU-RATIO-WARN] haiku 比例 X% < 20%，請確認是否有可降級 Stories`

### Round 1 回傳格式

```markdown
| Story ID | 標題 | 估點 | AC 確認結果 | 獨立性評估 |
|----------|------|------|------------|-----------|
| US-#N    | ...  | M    | PASS / 待確認 | 獨立 / 與 US-#M 衝突（同修改 path/to/file） |
```

---

## Developer SKILL 類 Story AC 路徑明確性規則（#573，Sprint 134）

<!-- retro: Sprint Planning AC 指定明確檔案路徑 — Sprint 132 Problem 1 -->

PO 在 Sprint Planning 中為 **Developer SKILL 類 Story**（涉及 Developer subagent 行為修改的 Story）撰寫 AC 時，**必須**明確指定實際修改的檔案路徑，不得使用泛稱（如「Developer SKILL 文件」）。

**路徑選擇規則：**

| 修改意圖 | 應指定的路徑 |
|---------|------------|
| Developer subagent 執行行為修改（TDD 流程、Commit 規範、自審策略） | `skills/sprint-execution/developer-prompt.md` |
| Sprint Execution 整體流程修改（派遣邏輯、Hard Gate、平行分群） | `skills/sprint-execution/SKILL.md` |
| Story-Lifecycle 執行步驟修改（三問、Live Log、branch 策略） | `skills/sprint-execution/story-lifecycle-prompt.md` |
| 同時涉及以上多個檔案 | 在 AC 中逐一列出所有路徑 |

**Architect 技術評估配合規則：** 技術評估表格的「修改檔案」欄位必須填寫完整路徑（非泛稱），與 PO AC 路徑對應一致。

---

## AC 完整性 Gate（#563，Sprint 132）

<!-- retro: Story AC 完整性前置確認 — Sprint 131 Problem 1 -->

<HARD-RULE id="ac-completeness-gate">
**PO Round 1 輸出 AC 完整性硬性規則：每個 Story 至少包含 1 條 AC 草稿。**

| 情況 | 處置 |
|------|------|
| Story Issue body 包含至少 1 條明確 AC（非「AC 待補」或空白）| 允許進入 Sprint |
| Story Issue body AC 為空、或僅含「AC 待補」、或 AC 欄位不存在 | PO Round 1 輸出標記「**AC 缺失**」，不得進入 Sprint；PO 必須先補充 AC 後重新評估 |

**目的**：防止 PO Round 1 輸出空 AC，導致 QA 在 Round 3 全部打回 NEEDS_REVISION，增加多輪溝通摩擦（Sprint 131 Problem 1 歷史案例：#388/#386 PO Round 1 AC 全空，QA 打回 4/4 NEEDS_REVISION）。

**成功指標**：下個 Sprint（Sprint 133）PO Round 1 的 AC 通過率 >= 75%（4 Story 中最多 1 個需補充）。
</HARD-RULE>

---

## PO Round 2：Sprint 文件產出與最終確認

### 職責

<!-- #744 Sprint Planning 會議紀錄模板標準化 — Sprint 157 -->

1. 根據 Architect 與 QA 的回饋，最終確認 Sprint Backlog
2. 建立 `docs/sprints/sprint_N.md`（N 為遞增的 Sprint 編號）— **建立前必須執行並行衝突防護流程（見下方）**
3. 更新 `docs/PROJECT_BOARD.md`，反映新 Sprint 的 Stories 配置
4. 為所有選入的 Issues 執行 GitHub 操作：
   - 套用 `status: in-sprint` label（移除 `status: backlog`）
   - 移除 `sprint-candidate` label（retro #954）
   - 設定對應的 Sprint Milestone（`gh issue edit <number> --milestone "Sprint N" --add-label "status: in-sprint" --remove-label "status: backlog" --remove-label "sprint-candidate"`）
5. **產出 Sprint Planning 會議紀錄**，依照 `templates/sprint-planning-meeting.md` 格式（#744），寫入 `docs/meetings/$(date '+%Y-%m-%d')-sprint-{N}-planning.md`，必須包含：Sprint Goal、Velocity Baseline、Stories Selected、Risk Notes、Next Sprint Preview、決議事項
6. 回傳最終 Sprint Backlog 結構化摘要（Markdown 表格：Story ID / 標題 / 估點 / AC 確認結果）

**主 session 不直接讀取 PROJECT_BOARD.md，僅接收 subagent 回傳的摘要。**

---

### 並行衝突防護流程（建立 sprint_N.md 前必須執行）

多個 session 可能同時執行 Sprint Planning，導致重複編號衝突。PO Round 2 在建立 sprint_N.md 之前，**必須**依下列步驟取得安全的 Sprint 編號：

```
1. 執行 git pull（同步最新狀態，取得其他 session 已 commit 的 sprint 文件）
   失敗時：輸出 `[WARN] git pull 失敗，繼續使用本地狀態`，繼續後續流程（不阻塞）
1.5 執行 Sprint Planning Claim（US-312）：
   bash hooks/claim-issue.sh "sprint-${next_N}-planning"
   [CLAIM-OK]      → 繼續（已取得 planning 鎖）
   [CLAIM-BLOCKED] → 輸出 [WARN] 已有其他 session 正在 Planning，繼續執行（不阻塞）
   claim 失敗（git push 失敗）→ 輸出 [WARN]，繼續執行（保守策略）
2. 掃描 docs/sprints/ 取得所有 sprint_N.md 的最大編號 max_N
   指令：ls docs/sprints/sprint_*.md 2>/dev/null | grep -oP 'sprint_\K\d+' | sort -n | tail -1
   空目錄 fallback：若上述指令無輸出（目錄為空），則 `max_N=${max_N:-0}`（fallback 為 0，不報錯）
3. 計算下一個 Sprint 編號：next_N = max_N + 1
4. 檢查 docs/sprints/sprint_{next_N}.md 是否已存在：
   - 若不存在 → 使用此編號，繼續建立文件
   - 若已存在 → 自動遞增編號（next_N += 1），重複檢查直至找到未使用的編號，並輸出：
     [SPRINT-CONFLICT] sprint_{原編號}.md 已存在，自動遞增至 sprint_{next_N}.md
5. PO 分配 Story 時填 assignee（記錄於 sprint_N.md 各 Story 的負責人欄位）
6. 建立 docs/sprints/sprint_{next_N}.md
7. 立即執行 git add docs/sprints/sprint_{next_N}.md docs/PROJECT_BOARD.md && git commit
   （縮小競態窗口，讓後續 session 的 git pull 能看到此次建立的文件）
8. 執行 Sprint Planning Release（US-312）：
   bash hooks/release-issue.sh "sprint-${next_N}-planning"
   → [CLAIM-RELEASE] refs/claims/sprint-${next_N}-planning
   失敗不阻塞（|| true）
```

> **注意**：此防護流程僅在無衝突時增加一次 `git pull`，不影響正常流程效能。
> claim/release 完整機制定義見 `skills/sprint-execution/SKILL.md` §2.11。

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
- US-#N：標題被改寫（Round 1：「原始標題」→ Round 2：「改寫後標題」）
- US-#M：AC 被刪除（Round 1 有 3 條 AC，Round 2 僅有 2 條）
- US-#K：Story ID 不符（Round 2 出現 Round 1 未選取的 ID）

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
