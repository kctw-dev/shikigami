# Step Subagent 契約文件（ADR-045 §3 落地）

<!-- Story #983 AC-4 — Sprint 180 -->

## 概述

本文件定義 Sprint Execution 中 short-lived step subagent 的 Prompt 模板規範、結果 JSON 契約、以及擴充指引。

ADR-045 方向修正（Sprint 179 #977）確立了以下核心觀點：
- 規則衰減是**注意力問題**（不是記憶力問題）
- Short-lived subagent 的核心優勢：每次啟動時規則完整在 context window 頂部，不受注意力衰減影響
- State machine 降級為 **progress tracker**（不是複雜狀態機）

---

## 1. Prompt 模板規範（4 區塊結構）

每個 step subagent 的 prompt 必須包含以下四個區塊，且**必須依序出現**：

### 區塊一：`## 規則片段`

**位置**：Prompt 第一個主要區塊（context window 頂部）
**目的**：確保規則在注意力最強的位置，避免長文後段注意力衰減導致規則被忽略
**規則佔比要求**：使用 `rule-ratio-measure.sh` 量測，規則區塊 token 數 >= 建議門檻值

不同 step 有不同門檻要求，詳見 [`scripts/state-machine/THRESHOLD_GUIDE.md`](../../state-machine/THRESHOLD_GUIDE.md)（Story #996 AC-4）：
- **delivery-completion-check**：>= 30%
- **task-list-init**：>= 20%
- **其他通用 step**：>= 10%

```markdown
## 規則片段

你是 Sprint Execution 的 {step_name} 步驟 subagent。你的唯一任務是 {task_description}。

### 必須遵守的規則
1. {rule_1}
2. {rule_2}
...

### 禁止事項
- {prohibition_1}
- {prohibition_2}
```

### 區塊二：`## 輸入契約`

**目的**：明確定義 subagent 接收的所有輸入來源

```markdown
## 輸入契約

- Sprint 編號：{sprint_number}
- {input_resource_1}：{path_or_description}
- {input_resource_2}：{path_or_description}
```

### 區塊三：`## 輸出契約`

**目的**：明確定義 subagent 必須產出的所有 artifacts

```markdown
## 輸出契約

必須產出：
- {artifact_1}（{description}）
- {result_json_file}（步驟結果 JSON，遵循 ADR-045 §3 格式）
```

### 區塊四：`## 成功/失敗判定`

**目的**：定義明確的完成標準，subagent 必須能自主判斷成功/失敗

```markdown
## 成功/失敗判定

成功條件：
- {success_condition_1}
- {success_condition_2}

失敗條件：
- {failure_condition_1}

遇到失敗時：寫入失敗 JSON 並結束，不嘗試自行修復。
```

---

## 2. 結果 JSON 契約（ADR-045 §3）

Step subagent 完成後必須產出結果 JSON 檔案，格式如下：

```json
{
  "step_name": "task-list-init",
  "status": "completed | failed | dispatch_ready",
  "output_artifacts": [
    "/path/to/artifact1",
    "/path/to/artifact2"
  ],
  "duration_ms": 1234,
  "error": null
}
```

### 欄位說明

| 欄位 | 類型 | 必要 | 說明 |
|------|------|------|------|
| `step_name` | string | 是 | 步驟名稱（與 prompt 一致） |
| `status` | string | 是 | `completed`（成功）/ `failed`（失敗）/ `dispatch_ready`（dispatch 模式準備完成） |
| `output_artifacts` | array | 是 | 產出的所有 artifact 檔案路徑清單（成功時非空） |
| `duration_ms` | integer | 是 | 執行耗時（毫秒） |
| `error` | string\|null | 是 | 失敗原因（成功時為 `null`） |

### 失敗結果範例

```json
{
  "step_name": "task-list-init",
  "status": "failed",
  "output_artifacts": [],
  "duration_ms": 500,
  "error": "Sprint Planning 結果檔案不存在：docs/sprints/sprint-180/planning.md"
}
```

---

## 3. 規則佔比量測（AC-2）

使用 `scripts/state-machine/rule-ratio-measure.sh` 量測 prompt 的規則佔比：

```bash
bash scripts/state-machine/rule-ratio-measure.sh <prompt_file>
```

輸出格式：

```json
{
  "rule_tokens": 45,
  "total_tokens": 120,
  "ratio": 0.3750,
  "passed": true
}
```

Token 估算規則（零依賴，純 bash）：
- 英文 ASCII 可見字元：字元數 / 4
- 中文 CJK 字元：字元數 / 1.5

**門檻**：`ratio >= 0.10`（10%）→ `passed: true`

---

## 4. 目前實作的 Step Subagent

### task-list-init

| 項目 | 內容 |
|------|------|
| 步驟名稱 | `task-list-init` |
| 對應 SKILL.md | §3 執行流程 — Task List 初始化節點 |
| Prompt 模板 | 由 `step-subagent-poc.sh generate-prompt task-list-init <sprint>` 生成 |
| 輸出 artifact | `docs/sprints/sprint-{N}/task-list.md` |
| 規則佔比 | 實測 44.78%（Sprint 180 prompt）|

### delivery-completion-check

<!-- ADR-045 Phase 2 落地 — Story #988 Sprint 181 -->

| 項目 | 內容 |
|------|------|
| 步驟名稱 | `delivery-completion-check` |
| ADR-045 Phase | Phase 2（L2 獨立驗證層） |
| 對應 SKILL.md | §3 POST-EXECUTION 驗證流程 — L1 inline bash 通過後的 L2 驗證節點 |
| Prompt 模板檔 | `skills/sprint-execution/steps/delivery-completion-check.md` |
| 生成指令 | `step-subagent-poc.sh generate-prompt delivery-completion-check <sprint> [story_id] [branch]` |
| 派遣指令 | `step-subagent-poc.sh dispatch delivery-completion-check <sprint> <story_id> <branch> <claimed_pr_url>` |
| Model | haiku（固定，model-route step=delivery-completion-check tier=haiku reason=short-task-high-ratio）|
| 輸出 artifact | 無（唯讀驗證，不產出檔案） |
| 結果 JSON 路徑 | `docs/cruise-logs/delivery-checks-<date>.jsonl`（append-only per-date） |
| 規則佔比 | 實測 44.07%（Sprint 181 prompt，>= 30% AC-2 要求） |
| 三態輸出 | `completed` / `failed` (NO_PR_FOUND) / `escalate` (PR_MISMATCH_SUSPECTED_FABRICATION) |
| 禁止工具 | git push, gh pr create, gh pr merge, git commit, 任何檔案修改 |
| 允許工具 | gh pr list, gh pr view, git log, cat, 讀取 state machine |
| 前置條件 | L1 [POST-EXEC-PR-PASS] 已輸出；若 L1 BLOCKED 則跳過 L2 |

**Phase 2 落地決策摘要**（Sprint 181）：
- L1（#989）已交付 main session inline bash 驗證（PR #991 merged）
- L2（#988）新增獨立 step subagent，進一步防止 PR 偽造（#953 歷史案例）
- 雙軌驗證：L1 快速 bash 過濾 + L2 短任務 haiku subagent 深度確認
- Progress tracker 使用 per-date JSONL 檔案（`delivery-checks-<date>.jsonl`），避免 git conflict（多機器場景）

---

## 5. 擴充指引

### 5.1 新增步驟 subagent

1. 在 `step-subagent-poc.sh` 中新增 `generate_prompt_<step_name>()` 函數
2. 在 `step-subagent-poc.sh` 中新增 `simulate_<step_name>()` 函數
3. 在 `step-subagent-poc.sh` 中新增 `dispatch_<step_name>()` 函數
4. 更新 `generate_prompt()`、`simulate()`、`dispatch()` 的 case 分支
5. 使用 `rule-ratio-measure.sh` 驗證新 prompt 的規則佔比 >= 10%
6. 在 SKILL.md §3 對應節點加入「Step Subagent 派遣」說明

### 5.2 Prompt 品質檢查清單

- [ ] 規則區塊是 prompt 第一個主要區塊
- [ ] 規則說明具體可執行（非模糊描述）
- [ ] 禁止事項明確列出
- [ ] 輸入契約列出所有檔案路徑
- [ ] 輸出契約包含結果 JSON 路徑
- [ ] 成功/失敗條件可自主判斷
- [ ] `rule-ratio-measure.sh` 量測 passed=true

### 5.3 Progress Tracker 整合

Step subagent 完成後，主 session 透過 `state-machine.sh` 更新進度：

```bash
# 標記步驟完成
bash scripts/state-machine/state-machine.sh complete <step_name>

# 查詢整體進度
bash scripts/state-machine/state-machine.sh status
```

State machine 在 ADR-045 定位為 **progress tracker**，不做複雜的狀態轉換決策。

---

## 參考

- ADR-045：Short-lived Subagent 方向修正（`docs/adr/ADR-045-state-machine-short-lived-subagent.md`）
- PoC 腳本：`scripts/state-machine/step-subagent-poc.sh`
- 規則量測：`scripts/state-machine/rule-ratio-measure.sh`
- Sprint Execution SOP：`skills/sprint-execution/SKILL.md`
- Step Subagent 派遣 SOP：`skills/sprint-execution/references/execution-flow-details.md`
