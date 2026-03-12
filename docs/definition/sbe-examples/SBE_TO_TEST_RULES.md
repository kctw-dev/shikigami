# SBE → 測試案例轉換規則

**版本**：v1.0
**日期**：2026-03-12
**狀態**：Active
**關聯 Story**：US-226
**依賴文件**：`docs/definition/sbe-examples/SBE_FORMAT.md`

---

## 1. 概述

本文件定義如何將 SBE 範例（`*.sbe.md`）系統性地轉換為可執行的測試案例。轉換遵循**單一來源原則**：SBE 是業務規則的 ground truth，測試案例是 SBE 的衍生物，不允許測試案例與 SBE 描述存在語意分歧。

**轉換方向**：

```
SBE 範例（*.sbe.md）
    └─ 轉換規則（本文件）
         └─ 測試案例（靜態驗證 / 自動化測試 / 行為驗證腳本）
```

---

## 2. 測試案例類型對照

SBE Scenario 依照驗證性質對應不同的測試案例類型：

| SBE Scenario 特徵 | 對應測試案例類型 | 驗證方式 | 適用範例 |
|------------------|---------------|---------|---------|
| `Given` 含文件路徑存在性、目錄結構 | **靜態驗證（Static Check）** | `glob` / `ls` / 路徑存在性確認 | AC 引用具體 `.md` 路徑 |
| `When` 是 Agent 執行某流程，`Then` 是輸出內容 | **行為驗證（Behavior Check）** | 讀取 Agent 輸出，比對關鍵字或結構 | Sprint Planning HARD-GATE 觸發 |
| `When` 是環境變數設定，`Then` 是流程分支 | **條件分支驗證（Branch Check）** | 模擬環境變數，驗證流程是否走向正確分支 | 排程模式 vs 手動模式 |
| `Given` 包含資料狀態，`Then` 是資料變更 | **狀態轉換驗證（State Check）** | 驗證執行前後資料狀態的差異 | GitHub label 更新、文件內容變更 |

---

## 3. 轉換規則

### 規則 T1：Scenario 一對一映射為測試案例

每個 `Scenario:` 區塊對應唯一一個測試案例，名稱從 Scenario 標題衍生：

```
# SBE
Scenario: 排程模式下選入非S-size Story時Sprint Planning中止

# 衍生測試案例名稱
test_case: scheduled_mode_non_s_story_triggers_gate
```

**命名規則**：
- 取 Scenario 標題的語意摘要，轉為 `snake_case`
- 前綴加測試類型（`static_`、`behavior_`、`branch_`、`state_`）

### 規則 T2：Given 轉換為測試前置條件（Precondition）

`Given` 和 `And`（Given 下）的每一行映射為測試前置設定步驟：

| SBE Given | 測試前置動作 |
|-----------|-----------|
| 環境變數 X 設為 Y | `os.environ['X'] = 'Y'` 或 mock 環境 |
| 文件 `/path/to/file.md` 存在 | `assert os.path.exists('/path/to/file.md')` |
| GitHub Issue #N 具有 label L | `gh issue view N --json labels` 驗證 label 存在 |
| Sprint 記錄數量 >= 3 | 讀取 `Retrospective_Log.md`，計算 Sprint 記錄數 |

### 規則 T3：When 轉換為測試執行步驟（Action）

`When` 描述測試動作的觸發：

| SBE When | 測試動作 |
|---------|---------|
| PO subagent 嘗試將 Story 選入 Sprint Backlog | 呼叫/模擬 Sprint Planning 選取流程 |
| Agent 執行 `/sprint-planning` | 觸發 Sprint Planning Skill，收集輸出 |
| 環境變數已設定，流程繼續 | 在已設定前置條件後，執行目標流程 |

### 規則 T4：Then 轉換為斷言（Assertion）

每個 `Then` 和 `And`（Then 下）的陳述映射為一條獨立斷言：

| SBE Then | 測試斷言 |
|---------|---------|
| 輸出告警訊息包含 "[SCHEDULED-MODE-GATE]" | `assert "[SCHEDULED-MODE-GATE]" in output` |
| Sprint Planning 流程中止 | `assert process.returncode != 0` 或 `assert "中止" in output` |
| 文件 `X.md` 存在 | `assert os.path.exists('X.md')` |
| 文件包含 Given/When/Then 結構 | `assert "Given" in content and "When" in content and "Then" in content` |
| Story 正常進入 Sprint Backlog | 讀取 `sprint_N.md`，確認 Story ID 在 Sprint Backlog 清單中 |

### 規則 T5：靜態驗證測試（Static Check）的特殊處理

當 AC 類型為 `[靜態]` 時，SBE Scenario 衍生為**靜態驗證清單**，而非可執行腳本：

```markdown
# 靜態驗證清單（衍生自 SBE Scenario）
Scenario: SBE標準格式定義文件存在

驗證步驟：
- [ ] 執行 `glob docs/definition/sbe-examples/SBE_FORMAT.md`
- [ ] 確認文件包含 "Given" 關鍵字
- [ ] 確認文件包含 "When" 關鍵字
- [ ] 確認文件包含 "Then" 關鍵字
- [ ] 確認文件包含至少一個完整的 Scenario 範例
```

---

## 4. 轉換流程

### Step 1：識別 SBE 文件

掃描 `docs/definition/sbe-examples/**/*.sbe.md`，列出所有待轉換的 SBE 文件。

### Step 2：分析 Scenario 類型

對每個 Scenario，依照 §2 的對照表判斷測試案例類型（靜態 / 行為 / 條件分支 / 狀態轉換）。

### Step 3：套用轉換規則 T1–T5

依照 §3 的規則，將 Given/When/Then 逐條映射為前置條件、執行步驟、斷言。

### Step 4：產出測試案例文件

每個 `.sbe.md` 文件對應產出一個測試案例清單或可執行測試腳本。靜態驗證輸出 Markdown 清單，行為驗證輸出 Bash/Python 測試腳本骨架。

### Step 5：與 SBE 來源保持同步

測試案例文件須在 header 中標注 SBE 來源：

```markdown
<!-- Source: docs/definition/sbe-examples/sprint-lifecycle/sprint_planning_scheduled_mode.sbe.md -->
<!-- Generated: 2026-03-12 -->
<!-- DO NOT EDIT DIRECTLY — update the SBE source file instead -->
```

---

## 5. 衝突處理

當 SBE 描述與現有測試案例不一致時：

| 衝突類型 | 處置規則 |
|---------|---------|
| SBE 更新，測試案例未同步 | 以 SBE 為準，強制更新測試案例 |
| 測試案例發現新的邊界條件 | 將邊界條件回寫到 SBE 新增 Scenario，再衍生測試案例 |
| 測試案例比 SBE 更嚴格 | 檢查是否需要在 SBE 中補充對應的規則；若業務規則確實有此要求，補充至 SBE |

**核心原則**：測試案例可以比 SBE 更細緻（技術細節），但不能與 SBE 語意相矛盾。

---

## 6. 範例：完整轉換示範

### 輸入（SBE Scenario）

```gherkin
Scenario: 排程模式下選入非S-size Story時Sprint Planning中止

  Given 環境變數 SHIKIGAMI_SCHEDULED 設為 "true"
    And PO subagent 已從 Backlog 篩選出候選 Stories

  When  PO subagent 嘗試將 M-size Story（US-XXX）選入 Sprint Backlog

  Then  Sprint Planning 流程中止
    And 輸出告警訊息包含 "[SCHEDULED-MODE-GATE]"
    And 告警訊息列出違規的 Story ID 及其 Size
    And 告警訊息建議改為手動執行 Sprint Planning
```

### 輸出（靜態驗證清單）

```markdown
<!-- Source: docs/definition/sbe-examples/sprint-lifecycle/sprint_planning_scheduled_mode.sbe.md -->

## branch_scheduled_mode_non_s_story_triggers_gate

**類型**：條件分支驗證（Branch Check）

### 前置條件
- [ ] 環境變數 `SHIKIGAMI_SCHEDULED` 已設為 `"true"`

### 執行步驟
- [ ] 模擬 PO subagent 嘗試選入 M-size Story

### 斷言
- [ ] Sprint Planning 流程中止（輸出包含「中止」或非零返回碼）
- [ ] 輸出包含 `"[SCHEDULED-MODE-GATE]"`
- [ ] 輸出包含違規 Story ID（如 `US-XXX`）及其 Size（`M`）
- [ ] 輸出包含「手動執行」或「manual」建議文字
```

---

## 7. 與 Sprint Planning 流程的銜接

Sprint Planning 中的 QA subagent 執行「路徑驗證規則（AC 路徑存在性檢查）」時，等同執行**靜態驗證測試**。QA 可直接引用對應的 SBE Scenario 作為驗證依據，格式一致，無需重複定義。

詳見 `skills/sprint-planning/SKILL.md §6 Step 3（QA 路徑驗證規則）`。

---

## 參考文件

- `docs/definition/sbe-examples/SBE_FORMAT.md`：SBE 標準格式定義
- `docs/definition/sbe-examples/sprint-lifecycle/`：Sprint 生命週期模組 SBE 範例
- `skills/sprint-planning/SKILL.md §3.1`：排程模式 HARD-GATE 業務規則
- `skills/qa-engineer/SKILL.md`：QA 驗收標準確認流程
