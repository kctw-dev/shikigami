# Sprint 9

> 週期：2026-03-01 ~ 2026-03-08
> 狀態：進行中
> 專案等級：low（完全自治）

---

## Sprint Goal

**「建立 Token 成本透明化機制，強化 Sprint 流程檔案即時持久化，並建立孤兒文件自動偵測能力，讓框架的運營成本與程式碼衛生可觀測」**

US-19 回應使用者明確要求：先有 token 用量數據，才能做有依據的優化決策。Retro #16 解決 Sprint 文件更新累積不 commit 導致 session 中斷遺失的風險。US-T09 完善程式碼品質工具鏈，新增孤兒文件自動偵測。

對應 ROADMAP：M5「穩定化」。

---

## Sprint Backlog

| Story | 任務 | 負責 | 狀態 | QA Review |
|---|---|---|---|---|
| US-19：Token 成本透明化 | Metrics_Log.md Token 表格 + sprint-review 整合 + 手動模板 | Developer + Architect | 待開始 | Spec: — / Code: — |
| Retro #16：Sprint 文件即時 commit + push | sprint-planning / execution / review 三個 SKILL.md commit 規範 | Developer | 完成 | Spec: PASS / Code: PASS |
| US-T09：孤兒文件清理規範 | 孤兒判斷規則 + validate-orphans.sh + CI 整合 | Developer | 待開始 | Spec: — / Code: — |

---

## 工作容量

- US-19：~0.4 Sprint（M，欄位設計 + SKILL.md 整合 + 手動模板 + 離群值邏輯）
- Retro #16：< 0.1 Sprint（S，三個 SKILL.md 各增一段 commit 指引）
- US-T09：~0.3 Sprint（M，政策定義 + Bash 腳本 + CI 整合）
- 合計：~0.8 Sprint（5 points）

**Points 換算**（T-shirt Sizing）：US-19 = 2pt（M）、Retro #16 = 1pt（S）、US-T09 = 2pt（M）= 合計 **5 points**

> **容量決策說明**：歷史 Velocity 為 5→4→6→8→7→6，5pt 處於中位偏低。US-19 為使用者最高優先項目，Sprint 保守聚焦於此核心需求。

---

## 執行順序

```
Retro #16 ─────────────────────────────────> 待開始（最優先：S size，快速完成，後續 Story commit 即遵循新規範）

US-19 ─────────────────────────────────────> 待開始（核心 Story，Retro #16 完成後開始，確保 commit 規範已就緒）

US-T09 ─────────────────────────────────────> 待開始（無強依賴，但建議 Retro #16 完成後開始）
```

- Retro #16 最優先：S size 快速完成，後續 Story 開發即遵循新 commit 規範
- US-19 為 Sprint 核心，建議在 Retro #16 完成後開始
- US-T09 與 US-19 無依賴，可在 US-19 之後或並行

---

## 風險

| 風險 | 可能性 | 影響 | 應對 |
|---|---|---|---|
| Claude Code 無法自動取得 token 用量 | 高 | 中 | AC4 手動降級模板已設計；AC2 含 fallback 輸出規範 |
| US-19 AC3 離群值在少量資料下不穩定 | 確定 | 低 | AC3 已加入「需至少 3 個 Sprint 記錄」前置條件，Sprint 9 Review 時不會觸發計算 |
| US-T09 validate-orphans.sh exit code 與 CI 衝突 | 低 | 高 | AC2 明確聲明 exit code = 0（warning 不阻塞 CI），與 US-T07 AC3 不衝突 |
| Retro #16 commit 指引措辭觸發 ADR-003 Hard Gate | 低 | 中 | Architect 已建議限定範圍為 Sprint 狀態文件，避免泛指 |

---

## Story 詳情

### US-19：Token 成本透明化

**背景與動機**

使用者明確要求：先掌握 token 用量變化數據，才能判斷流程成本是否合理。不應在沒有數據支撐的情況下隨意精簡流程。（Retro Action #17，已關閉）

**Acceptance Criteria（Sprint Planning 精化版）**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 記錄格式 | 在 `docs/km/Metrics_Log.md` 新增獨立的 Token 成本記錄表格（不修改現有 Velocity 表格）。欄位標頭完整包含：Sprint 編號、輸入 token、輸出 token、估算成本 (USD)、資料來源。「資料來源」允許值：`Claude Code API` / `手動記錄` / `不可用`。成本格式：USD 數值（小數 4 位，如 `$0.0012`）或 `N/A` |
| AC2 | [靜態+動態] | Sprint Review 整合 | `skills/sprint-review/SKILL.md` 第 6 節執行清單末尾新增「Token 成本摘要」子節，含：(a) 讀取 Token 表格的操作指引；(b) fallback 規範：當 Token 資料不可得時（Token 表格無本 Sprint 記錄列，或 token 計數器不可存取），輸出精確字串「Token 資料不可用，需手動補充」 |
| AC3 | [動態] | 成本對照 | 前置條件：Token 表格中本 Sprint 之前已有 3+ 列完整記錄；不滿足時輸出「Token 歷史資料不足（需至少 3 個 Sprint 記錄），跳過離群值分析」。滿足時：以 Sprint 整體為單位計算平均 token 消耗，某 Sprint 輸入或輸出 token 超過歷史平均值 2 倍標記為 `[OUTLIER]` |
| AC4 | [靜態] | 手動降級 | 在 `docs/km/Metrics_Log.md` 的 Token 表格下方提供手動記錄模板，格式為 Markdown 表格，含 AC1 定義的五個欄位，含至少一列示範資料 |

**設計決策**：Token 消耗以 Sprint 整體為記錄單位（非 Story 層級），與現有 Metrics_Log.md 的 Velocity 記錄粒度對齊。

**RICE**：11.2
**MoSCoW**：Should → **Must**（使用者明確要求最高優先）
**Size**：M / **Points**：2
**對應 Issue**：#12（建議 1）、Retro #17（已關閉）

---

### Retro #16：Sprint 文件即時 commit + push

**背景與動機**

Sprint 8 Planning 期間 Stakeholder 指出：Sprint 文件更新累積到最後才一次 commit，中間若 session 中斷會遺失變更。

**Acceptance Criteria（QA 提議 + PO 確認版）**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | sprint-planning commit 規範 | `skills/sprint-planning/SKILL.md` 在產出文件或執行檢查清單新增條文：完成 `docs/PROJECT_BOARD.md` 或 `docs/sprints/sprint_N.md` 修改後，立即執行 git commit + git push |
| AC2 | [靜態] | sprint-execution commit 規範 | `skills/sprint-execution/SKILL.md` 在「更新看板與同步 Sprint 文件」步驟中新增：每個 Story 完成後，更新 PROJECT_BOARD.md 和 sprint_N.md 狀態欄後，立即執行 git commit + git push |
| AC3 | [靜態] | sprint-review commit 規範 | `skills/sprint-review/SKILL.md` 第 6 節執行清單新增 checklist item：產出文件（PROJECT_BOARD.md、Retrospective_Log.md、Metrics_Log.md）完成最後修改後執行 git commit + git push |
| AC4 | [靜態] | 範圍排除聲明 | 三個 SKILL.md 任一處明確聲明 commit 規範僅適用於 Sprint 狀態文件（PROJECT_BOARD.md、sprint_N.md、Metrics_Log.md、Retrospective_Log.md），不適用於 Knowledge Management 文件 |

**MoSCoW**：Must（Retro Action Item）
**GitHub Issue**：#16
**Size**：S / **Points**：1

---

### US-T09：孤兒文件清理規範

**背景與動機**

隨著 Sprint 數量增加，`docs/` 目錄可能累積不再被引用的孤兒文件。需要定義判斷規則、自動偵測機制與處置流程。

**Acceptance Criteria（QA 重寫 + PO 確認版）**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 孤兒判斷規則 | 新建政策文件或在 `health-check/SKILL.md` 擴充：(a) 正向定義：`docs/` 下的 .md 文件未被任何其他 .md 文件以相對路徑引用且不在豁免清單中；(b) 豁免清單至少含 4 類（sprint_N.md、Metrics_Log.md、頂層文件、ADR 文件）；(c) 判定週期為每次 CI 執行 |
| AC2 | [靜態+動態] | Linter 孤兒標記 | 新建 `scripts/validate-orphans.sh`；`.github/workflows/validate.yml` 新增步驟；exit code 規則：無論是否偵測到孤兒，exit code 均為 0（warning 不影響 CI pass/fail，與 US-T07 AC3 不衝突）；輸出格式：`WARNING: <file_path>: 孤兒文件（無任何 .md 引用）` |
| AC3 | [靜態] | 孤兒處置規範 | 在規則文件中說明處置流程：(a) 開發者在 Retro 中列為 Problem；(b) PO 裁定：刪除/補充引用/加入豁免清單；(c) 裁定後執行並關閉對應 issue |

**RICE**：16.7
**MoSCoW**：Could
**Size**：M / **Points**：2（Architect 從 S 上調）

---

## 驗收標準

### US-19：Token 成本透明化

- [ ] Metrics_Log.md 新增獨立 Token 表格，含五欄位 + 允許值定義（AC1 通過）
- [ ] sprint-review SKILL.md 新增「Token 成本摘要」子節 + fallback 規範（AC2 通過）
- [ ] 離群值計算含「資料不足」前置條件（AC3 通過）
- [ ] 手動記錄模板含示範資料（AC4 通過）

### Retro #16：Sprint 文件即時 commit + push

- [ ] sprint-planning SKILL.md 新增 commit 規範（AC1 通過）
- [ ] sprint-execution SKILL.md 新增 commit 規範（AC2 通過）
- [ ] sprint-review SKILL.md 新增 commit 規範（AC3 通過）
- [ ] 範圍排除聲明存在（AC4 通過）
- [ ] GitHub Issue #16 關閉

### US-T09：孤兒文件清理規範

- [ ] 孤兒判斷規則定義完整（正向定義 + 豁免清單 + 判定週期）（AC1 通過）
- [ ] validate-orphans.sh 存在，CI 新增步驟，exit code = 0（AC2 通過）
- [ ] 孤兒處置規範含三種路徑（AC3 通過）
