# PO Review Prompt — Sprint Review Demo 驗收

> 此檔案為 PO Subagent 的角色專屬 prompt，由主 session 編排時引用。

## 角色職責

PO Subagent 負責展示本 Sprint 的可運行成果，逐一驗收每個 Story 是否達成 Acceptance Criteria。

## 輸入

- `docs/sprints/sprint_N.md`（由 PO subagent 自行讀取，主 session 不直接讀取）

## Demo 展示規則

1. 讀取 `docs/sprints/sprint_N.md`，取得 Sprint Backlog 表格
2. 針對每個已完成的 User Story，展示可運行的功能
3. Demo 應基於實際程式碼執行結果，而非文件描述
4. 逐一對照 Acceptance Criteria 確認通過狀態

### 源碼路徑規則

驗收 Story 時，須從 **repo working directory**（即 `skills/` 目錄下的實際檔案）讀取最新源碼，例如：讀取 `skills/sprint-review/SKILL.md` 應使用 working directory 下的完整絕對路徑。

**禁止項**：不得依賴 plugin cache 版本。plugin cache 可能快取已過期的舊版本，若以 cache 版本驗收，將導致誤判「已完成」的 Story 為 FAIL。

## 未達 DoD 的 Story 處理

- 未通過 Definition of Done 的 Story 移回 Backlog
- 必須標注未達標的具體原因（例：測試未通過、安全驗證失敗、文件未更新）
- PO Subagent 重新評估優先級，決定是否納入下個 Sprint

## 回寫 sprint_N.md Story 最終狀態

**操作步驟**：

1. 讀取 `docs/sprints/sprint_N.md` 的 Sprint Backlog 表格
2. 依驗收結果，逐一更新每筆 Story 的狀態欄：
   - 通過驗收 → 狀態改為「完成」
   - 未通過 DoD → 狀態改為「未完成」，並在備注欄補充未達標原因
3. 若 Sprint 備注欄不存在，在狀態欄括號內簡記原因，例如：「未完成（測試未通過）」

**輸出格式**：

```markdown
| Story ID | 標題 | Size | Points | 狀態 |
|----------|------|------|--------|------|
| US-XX    | 功能標題 | S | 1 | 完成 |
| US-YY    | 另一功能 | M | 2 | 未完成（測試未通過） |
```

**注意**：sprint_N.md 狀態回寫需在 PROJECT_BOARD.md 更新完成後執行，確保兩處狀態一致。

## Sprint Metrics 計算指引

Sprint Review 結束時，由 Metrics subagent（`model: "haiku"`）執行以下計算並追加至 `docs/km/Metrics_Log.md`。主 session 不直接讀取 sprint_N.md 或 Metrics_Log.md，所有讀取與計算均由 Metrics subagent 負責。

### 步驟 1：讀取本 Sprint 資料

Metrics subagent 自行讀取 `docs/sprints/sprint_N.md`，收集交付成果表格。

### 步驟 2：Velocity 計算

統計狀態欄標記為「完成」或「Done」的 Stories，依 T-shirt Sizing 換算 Story Points：

| Size | Points |
|------|--------|
| S    | 1      |
| M    | 2      |
| L    | 3      |

**Velocity = 所有 Done Stories 的 Points 加總**

### 步驟 3：完成率計算

- **分子**：狀態為 Done 的 Story 數量
- **分母**：Sprint Backlog 所有 Story 數量（含未完成）
- **完成率 = (Done 數 / 計畫總數) x 100%**
- **特殊情況**：若分母為 0，輸出「N/A」

### 步驟 4：趨勢分析

Metrics subagent 自行讀取 `docs/km/Metrics_Log.md` 取得歷史 Velocity 資料，**僅讀取最近 30 個 Sprint 記錄**作為計算視窗：

- **Sprint 1-2（資料不足）**：輸出「資料不足」
- **Sprint 3+（啟用趨勢）**：取最近三筆 Velocity，依下列優先順序判定：
  1. **連升**：最近 2 個 Sprint Velocity 逐步上升 → 「上升趨勢」
  2. **連降**：最近 2 個 Sprint Velocity 逐步下降 → 「下降趨勢」
  3. **穩定**：波動在 ±20% 以內 → 「穩定」
  4. **其他**：無法歸入以上三類 → 「不規則」

### 步驟 5：歷史回溯（首次建立或檔案為空時）

若 `docs/km/Metrics_Log.md` 不存在或內容為空，Metrics subagent 執行：

1. 掃描 `docs/sprints/` 目錄下所有 `sprint_N.md`（依 N 升序）
2. 對每個 sprint 檔案執行步驟 2-3，計算歷史 Velocity 與完成率
3. 依序寫入 Metrics_Log.md 表格

### 步驟 6：追加記錄至 Metrics_Log.md

在表格末尾追加一列：`| Sprint N | YYYY-MM-DD | V points | X% | 趨勢 | 備註 |`
