# Sprint 83

**Sprint Goal**：強化 Sprint 流程可靠性 — 建立 Checkpoint 強制重讀機制防止流程跳步，並導入 SPACE 五維度指標量化代理人行為品質。

**期間**：2026-03-12 ~ 2026-03-19
**狀態**：進行中
**ADR 依賴**：無

---

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 | 備註 |
|-------|-------|------|--------|------|------|
| US-229：Checkpoint 強制重讀步驟 — subagent 返回後強制重讀流程定義，防止流程跳步 | #229 | M | 2 | 待開始 | FEATURE |
| US-225：SPACE 五維度指標 — 以 SPACE 框架量化代理人行為品質 | #225 | M | 2 | 待開始 | FEATURE |

**Sprint 容量**：4 points

---

## Story 定義

### US-229：Checkpoint 強制重讀步驟（M, 2pt, FEATURE）

**Issue**：#229
**主要修改**：`skills/sprint-execution/SKILL.md`

#### Acceptance Criteria

**AC1**：[靜態] `skills/sprint-execution/SKILL.md` 的流程圖（§3）在「接收 Story-Lifecycle subagent 回傳」步驟後、外部抽樣審查決策前，新增 **Checkpoint 重讀步驟**節點。
- 驗證條件：流程圖中存在明確的 `Checkpoint: 重讀流程定義` 節點，且位於「接收 Story-Lifecycle subagent 回傳 → PASS」之後、「外部抽樣審查決策」之前。
- 目標檔案：`skills/sprint-execution/SKILL.md`

**AC2**：[靜態] Checkpoint 步驟定義包含以下三個子動作，且各子動作有明確描述：
- (a) 重讀當前 Sprint 執行流程步驟清單（指定重讀 `skills/sprint-execution/SKILL.md` §3 流程步驟定義）
- (b) 比對下一步驟是否符合流程定義（驗證即將執行的步驟與流程圖定義一致，未發生跳躍或遺漏）
- (c) 記錄 Checkpoint 通過/未通過狀態（輸出 `[CHECKPOINT-PASS]` 或 `[CHECKPOINT-FAIL]` 標記）
- 驗證條件：`skills/sprint-execution/SKILL.md` 中存在 Checkpoint 步驟區塊，且包含上述 (a)(b)(c) 三個子動作的文字描述。
- 目標檔案：`skills/sprint-execution/SKILL.md`

**AC3**：[靜態] Checkpoint 失敗處理流程定義完整，包含以下內容：
- 偵測到流程跳躍時的處置方案（回退至正確步驟並記錄跳躍事件）
- 偵測到流程遺漏時的處置方案（補執行遺漏步驟並記錄遺漏事件）
- 失敗後是否繼續執行的決策邏輯（例如：失敗時暫停並等待人工確認，或自動修正後繼續）
- 驗證條件：`skills/sprint-execution/SKILL.md` 中存在 `[CHECKPOINT-FAIL]` 情境的處理流程描述，且涵蓋跳躍與遺漏兩種失敗類型。
- 目標檔案：`skills/sprint-execution/SKILL.md`

**AC4**：[靜態] Checkpoint 記錄格式定義，包含以下標記與結構：
- 定義 `[CHECKPOINT-PASS]` 標記格式（含 Sprint 編號、Story 編號、當前步驟、下一步驟）
- 定義 `[CHECKPOINT-FAIL]` 標記格式（含 Sprint 編號、Story 編號、預期步驟、實際步驟、失敗類型：跳躍/遺漏）
- 標記可供 SPACE E（Efficiency）維度消費（`[CHECKPOINT-FAIL]` 計入斷鏈次數）
- 驗證條件：`skills/sprint-execution/SKILL.md` 中存在 Checkpoint 記錄格式定義區塊，且包含 `[CHECKPOINT-PASS]` 和 `[CHECKPOINT-FAIL]` 兩種標記的欄位說明。
- 目標檔案：`skills/sprint-execution/SKILL.md`

**AC5**：[靜態] 執行檢查清單（§7 或對應的檢查清單區塊）新增 Checkpoint 相關檢查項：
- 至少包含：「每個 Story-Lifecycle subagent 回傳後，Checkpoint 重讀步驟已執行」
- 至少包含：「Checkpoint 結果已記錄（PASS 或 FAIL + 處置）」
- 驗證條件：`skills/sprint-execution/SKILL.md` 的檢查清單區塊中存在上述兩項 Checkpoint 相關的 checklist item。
- 目標檔案：`skills/sprint-execution/SKILL.md`

#### Done 定義

- [x] 所有 AC（AC1-AC5）驗證通過
- [x] `skills/sprint-execution/SKILL.md` 已更新並通過靜態驗證

---

### US-225：SPACE 五維度指標（M, 2pt, FEATURE）

**Issue**：#225
**主要修改**：`docs/km/Metrics_Log.md` + `skills/sprint-review/SKILL.md`

#### Acceptance Criteria

**AC1**：[靜態] `docs/km/Metrics_Log.md` 新增 `## SPACE 五維度指標` 獨立 H2 區塊，包含表格欄位定義。
- 表格欄位：Sprint 編號 / 日期 / S / P / A / C / E / 備註
- 驗證條件：`docs/km/Metrics_Log.md` 中存在 `## SPACE 五維度指標` H2 標題，其下方有 Markdown 表格，且表頭包含上述 8 個欄位。
- 目標檔案：`docs/km/Metrics_Log.md`

**AC2**：[靜態] 每個維度的量測公式定義完整，且位於 SPACE 區塊內（表格之前或之後的說明段落）。
- S（Satisfaction）= 1-5 滿意度量表，衡量 Sprint 產出品質符合期待程度
- P（Performance）= 幻覺攔截次數 / 漏網次數，衡量系統攔截 agent 腦補的能力
- A（Activity）= 完成率，引用現有 Metrics_Log.md 已記錄的完成率欄位（不重複定義）
- C（Communication）= 互審發現問題數，衡量 agent 交叉確認抓到的潛在問題數量
- E（Efficiency）= 斷鏈次數 / 人工介入次數，衡量流程中需要人類介入修正的頻率
- 驗證條件：`docs/km/Metrics_Log.md` SPACE 區塊中存在上述 S/P/A/C/E 五個維度各自的量測公式文字描述，且 A 維度明確標註引用現有欄位。
- 目標檔案：`docs/km/Metrics_Log.md`

**AC3**：[靜態] `skills/sprint-review/SKILL.md` Retrospective 流程新增 SPACE 量測步驟，插入位置在「步驟 2 Good/Problem/Action 收集」之後。
- 新步驟明確標示為 SPACE 五維度量測
- 新步驟與前後步驟的編號連貫（不破壞現有步驟編號邏輯）
- 驗證條件：`skills/sprint-review/SKILL.md` 中 Retrospective 流程區塊存在 SPACE 量測步驟，且位於 Good/Problem/Action 收集步驟之後、原流程後續步驟之前。
- 目標檔案：`skills/sprint-review/SKILL.md`

**AC4**：[靜態] SPACE 量測步驟包含完整的執行指引，涵蓋以下三個面向：
- 誰量測：明確指定由哪個角色（例如 Sprint Review 主持者 / PO）負責填寫各維度數值
- 資料來源：每個維度的數值從何處取得（例如 S 由 Stakeholder 評分、P 從 Retro 記錄統計、E 從 Checkpoint 記錄統計）
- 記錄時機：明確指定在 Sprint Review/Retro 的哪個階段執行量測與記錄
- 驗證條件：`skills/sprint-review/SKILL.md` 的 SPACE 量測步驟中存在「誰量測」「資料來源」「記錄時機」三個面向的文字描述。
- 目標檔案：`skills/sprint-review/SKILL.md`

**AC5**：[靜態] `docs/km/Metrics_Log.md` SPACE 表格包含至少一筆範例記錄（空白 Sprint 示範列）。
- 範例列使用佔位符（例如 Sprint N / YYYY-MM-DD / - / - / - / - / - / -）表示尚無實際數據
- 範例列格式與表頭欄位對齊
- 驗證條件：`docs/km/Metrics_Log.md` SPACE 表格中存在至少一筆資料列（非表頭），使用佔位符或示範值填寫。
- 目標檔案：`docs/km/Metrics_Log.md`

#### Done 定義

- 所有 AC（AC1-AC5）驗證通過
- `docs/km/Metrics_Log.md` 及 `skills/sprint-review/SKILL.md` 已更新並通過靜態驗證

---

## 平行分群建議

### Phase 1（平行，無檔案衝突）
| Story | Size | 說明 |
|-------|------|------|
| US-229 | M | 修改 skills/sprint-execution/SKILL.md |
| US-225 | M | 修改 docs/km/Metrics_Log.md + skills/sprint-review/SKILL.md |

US-229 與 US-225 修改的檔案完全不同，可由兩個 subagent 完全平行執行。

---

## Architect 評估結果

- T-shirt size：兩個 Story 均為 M（各 2pt）
- ADR 需求：無
- API 契約：不適用（doc-only 排除但無 API 互動）
- 平行分群：Phase 1 平行（US-229 + US-225），無 Phase 2
- 方法論：BDD 不適用、DDD 不適用

---

## 權重調整記錄

快思模式，跳過權重調整
