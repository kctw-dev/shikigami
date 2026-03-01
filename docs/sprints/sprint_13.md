# Sprint 13

> 週期：2026-03-01 ~ 2026-03-08
> 狀態：進行中
> 專案等級：low（完全自治）

---

## Sprint Goal

**「清零 Sprint 12 Retro 流程缺口，建立 Sprint Planning 平行派工正式規範，為 M5 外部發布排除最後的流程控制風險。」**

Retro #26 修正 PO Demo 應讀取 repo 源碼而非 plugin cache。Retro #27 限制 Developer Board 更新範圍，防止越權標記 Sprint 完成。Retro #25 PO Sprint Planning Story 選取納入平行派工可行性考量。Retro #24 Architect Sprint Planning 評估包含平行派工策略。

對應 ROADMAP：M5「穩定化」。

---

## Sprint Backlog

| Story | 任務 | 負責 | 狀態 | QA Review | 平行組 |
|---|---|---|---|---|---|
| Retro #26：PO Demo 應讀取 repo 源碼而非 plugin cache | `skills/sprint-review/SKILL.md` §2 Step 1 明確指定讀取 repo 源碼路徑，禁止依賴 plugin cache | Developer | 待開始 | 待審 | Phase 1（平行） |
| Retro #27：Developer Board 更新範圍限制 — 防止越權標記 Sprint 完成 | `skills/sprint-execution/SKILL.md` Step 8 限定 Developer 可更新欄位範圍 | Developer | 待開始 | 待審 | Phase 1（平行） |
| Retro #25：PO Sprint Planning Story 選取應納入平行派工可行性考量 | `skills/sprint-planning/SKILL.md` §6 Step 1 新增獨立性評估欄位 | Developer | 待開始 | 待審 | Phase 1（平行） |
| Retro #24：Architect Sprint Planning 評估應包含平行派工策略 | `skills/sprint-planning/SKILL.md` §6 Step 2 新增平行分群建議輸出項目 | Developer | 待開始 | 待審 | Phase 2（#25 後） |

---

## T-shirt Size / Points 摘要

| Story | Size | Points | 備註 |
|-------|------|--------|------|
| Retro #26：PO Demo 應讀取 repo 源碼而非 plugin cache | S | 1 | 單一 SKILL.md 段落新增禁止項 |
| Retro #27：Developer Board 更新範圍限制 | S | 1 | 單一 SKILL.md 步驟權限限定 |
| Retro #25：PO Sprint Planning Story 選取納入平行派工可行性 | S | 1 | 單一 SKILL.md 表格欄位新增 |
| Retro #24：Architect Sprint Planning 評估包含平行派工策略 | S | 1 | 單一 SKILL.md 輸出項目新增 |
| **合計** | — | **4** | 4 × S，與 Sprint 12 持平 |

---

## 工作容量

| 指標 | 數值 |
|------|------|
| 計畫 Stories | 4 |
| 計畫 Points | 4（4 × S） |
| 近 3 Sprint 平均 Velocity | 4.7pt（Sprint 10: 6、Sprint 11: 4、Sprint 12: 4） |
| 緩衝率 | 85%（保守合理，全部為純靜態文件修改，無動態量測風險） |

**容量決策說明**：4 個 S-size Story，Retro #26/#27/#25 可完全平行執行（不同目標檔案），Retro #24 需在 Retro #25 完成後執行（同修改 `skills/sprint-planning/SKILL.md`）。所有 Story 均為純靜態文件修改，無 SKIPPED 降級路徑需求。

---

## 執行順序（平行化分析）

```
Phase 1（三路平行派遣，無檔案衝突）：
  Subagent A — Retro #26（修改 skills/sprint-review/SKILL.md）
  Subagent B — Retro #27（修改 skills/sprint-execution/SKILL.md）
  Subagent C — Retro #25（修改 skills/sprint-planning/SKILL.md §6 Step 1）

Phase 2（Phase 1 全部完成後，順序執行）：
  Subagent D — Retro #24（修改 skills/sprint-planning/SKILL.md §6 Step 2）
```

**平行化理由（Architect 確認）**：
- Retro #26 修改 `skills/sprint-review/SKILL.md`
- Retro #27 修改 `skills/sprint-execution/SKILL.md`
- Retro #25 修改 `skills/sprint-planning/SKILL.md`（§6 Step 1）
- 以上三者目標檔案互異，無衝突，可完全平行執行
- Retro #24 修改 `skills/sprint-planning/SKILL.md`（§6 Step 2），與 Retro #25 同檔，須在 #25 完成後順序執行

---

## 精化後 Acceptance Criteria

### Retro #26：PO Demo 應讀取 repo 源碼而非 plugin cache

| # | AC | 類型 |
|---|-----|------|
| AC1 | `skills/sprint-review/SKILL.md` §2 Step 1 PO Demo 指令明確指定讀取 repo 源碼路徑（working directory），並包含「不得依賴 plugin cache 版本」的禁止項 | [靜態] |
| AC2 | 下次 Sprint Review PO Demo 正確讀取 repo 源碼，無誤判 | [動態] |

**修改檔案（限定範圍）**：`skills/sprint-review/SKILL.md`

---

### Retro #27：Developer Board 更新範圍限制 — 防止越權標記 Sprint 完成

| # | AC | 類型 |
|---|-----|------|
| AC1 | `skills/sprint-execution/SKILL.md` 步驟 8 明確限定 Developer 只能更新 Story 狀態行，不得觸碰 Sprint 級別欄位（Sprint 完成標記、Stakeholder 驗收等） | [靜態] |
| AC2 | `skills/sprint-execution/SKILL.md` 步驟 8 同時明確限定 Developer 在 `docs/sprints/sprint_N.md` 中可更新的欄位範圍（僅限 Sprint Backlog 中各 Story 的「狀態」欄），並標注 Sprint 級別欄位「禁止 Developer 修改」 | [靜態] |

**修改檔案（限定範圍）**：`skills/sprint-execution/SKILL.md`

---

### Retro #25：PO Sprint Planning Story 選取應納入平行派工可行性考量

| # | AC | 類型 |
|---|-----|------|
| AC1 | `skills/sprint-planning/SKILL.md` §6 Step 1 PO 第一輪回傳格式表格新增「獨立性評估」欄位 | [靜態] |
| AC2 | PO 第一輪描述段落包含「評估 Story 間的檔案修改獨立性」的具體指引 | [靜態] |

**修改檔案（限定範圍）**：`skills/sprint-planning/SKILL.md`

---

### Retro #24：Architect Sprint Planning 評估應包含平行派工策略

| # | AC | 類型 |
|---|-----|------|
| AC1 | `skills/sprint-planning/SKILL.md` §6 Step 2 Architect 區段新增「平行分群建議」作為正式輸出項目 | [靜態] |
| AC2 | 平行分群建議包含 Phase 分組與檔案衝突分析的輸出格式說明 | [靜態] |

**修改檔案（限定範圍）**：`skills/sprint-planning/SKILL.md`

---

## 權重調整記錄

**歷史趨勢穩定，無需調整。**

Sprint 11 Retro Problem 關鍵字：未觸發 QA 升級條件。Sprint 12 Retro Problem 關鍵字：未達連續 2 Sprint QA 關鍵字閾值。US-22 ADR-004 規則未觸發，維持現有角色權重。

---

## ADR 前提

| Story | ADR 需求 | 狀態 |
|-------|---------|------|
| Retro #26 | ADR-003 Checklist（修改 skills/ 下 .md） | Hard Gate PASS（Architect 確認） |
| Retro #27 | ADR-003 Checklist（修改 skills/ 下 .md） | Hard Gate PASS（Architect 確認） |
| Retro #25 | ADR-003 Checklist（修改 skills/ 下 .md） | Hard Gate PASS（Architect 確認） |
| Retro #24 | ADR-003 Checklist（修改 skills/ 下 .md） | Hard Gate PASS（Architect 確認） |

**ADR-003 適用說明**：全部 4 Stories 均修改 `skills/` 目錄下的 SKILL.md 檔案，ADR-003 Framework Document Change Audit Hard Gate 適用。Developer 執行時須通過 Checklist。

無需建立新 ADR。

---

## Issue #28 處理記錄

**Issue #28**（量測門檻設定應包含容忍帶）**已於本次 Sprint 13 Planning 落地解決。**

容忍帶規範（tolerance band）已作為 AC 撰寫慣例納入本 Sprint，並體現於 AC 的通過標準表述方式中，無需獨立 Story 執行。Issue #28 於 Sprint 13 Planning 完成後關閉。

---

## Token 記錄

| 環節 | Token | 備註 |
|------|-------|------|
| Planning | 待補 | Sprint 13 Planning 完成後從 JSONL 提取 |
| Execution | 待補 | Sprint 13 Execution 完成後填入 |
| Review | 待補 | Sprint 13 Review 完成後填入 |
