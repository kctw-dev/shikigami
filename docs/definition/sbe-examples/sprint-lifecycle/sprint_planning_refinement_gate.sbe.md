# SBE 範例：Sprint Planning Refinement 前置門禁

**模組**：sprint-lifecycle
**業務規則來源**：`skills/sprint-planning/SKILL.md §9.2`
**版本**：v1.0
**日期**：2026-03-12
**狀態**：Active

---

## 業務規則摘要

M/L size Story 在進入 Sprint Planning PO Round 1 之前，**必須**完成 Refinement（由 Architect 擔任 Chair）。S size Story 預設豁免，但有三種例外情況仍須執行 Refinement。

---

## Scenarios

### Scenario 1：M-size Story 未經 Refinement 不可進入 PO Round 1

```gherkin
Scenario: M-size Story未通過Refinement不得進入PO Round 1選取

  Given Sprint Planning 進行到 Refinement 區間
    And 候選 Stories 中包含 M-size Story（US-MMM）
    And US-MMM 尚未完成 Refinement（無 READY 結論）

  When  Architect 作為 Refinement Chair 執行依賴分析

  Then  US-MMM 被標記為 NOT_READY
    And NOT_READY 結論包含具體阻塞原因說明
    And US-MMM 不進入 PO Round 1 的候選清單
    And US-MMM 被退回 Backlog，等待阻塞解除後重新 Refinement
```

---

### Scenario 2：M-size Story 通過 Refinement 可進入 PO Round 1

```gherkin
Scenario: M-size Story通過Refinement標記READY後可進入PO Round 1

  Given Sprint Planning 進行到 Refinement 區間
    And 候選 Stories 中包含 M-size Story（US-NNN）
    And US-NNN 的 Q1–Q5 分析結果全部無阻塞項目

  When  Architect 完成 Refinement 依賴分析並輸出報告

  Then  US-NNN 被標記為 READY
    And Refinement 報告包含完整的 Q1–Q5 分析結果
    And US-NNN 進入 PO Round 1 的候選清單
```

---

### Scenario 3：S-size Story 預設豁免 Refinement

```gherkin
Scenario: S-size Story預設豁免Refinement直接進入PO Round 1

  Given Sprint Planning 進行到 Refinement 區間
    And 候選 Stories 包含 S-size Story（US-SSS）
    And US-SSS 不符合任何豁免例外條件（無跨 3 個以上 Type、無前置依賴、無外部系統依賴）

  When  Architect 執行 Refinement 區間判斷

  Then  US-SSS 自動通過，不執行完整 Refinement 流程
    And Architect 在技術評估表格標注 "Refinement: 豁免（S-size）"
    And US-SSS 直接進入 PO Round 1 的候選清單
```

---

### Scenario 4：S-size Story 跨 3 個以上 Story Type 時仍須 Refinement

```gherkin
Scenario: S-size Story跨越3個以上StoryType時不得豁免Refinement

  Given 候選 Stories 包含 S-size Story（US-SSS-COMPLEX）
    And US-SSS-COMPLEX 同時涉及 FEATURE、INFRA、SECURITY 三個 Story Type

  When  Architect 在 Refinement 區間評估 US-SSS-COMPLEX

  Then  US-SSS-COMPLEX 不適用豁免例外，必須執行完整 Refinement
    And Architect 對 US-SSS-COMPLEX 執行 Q1–Q5 依賴分析
    And 輸出正式 Refinement 報告（含 READY / NOT_READY 結論）
```

---

## 來源業務規則引用

### Refinement 觸發條件（`skills/sprint-planning/SKILL.md §9.2`）

| Story Size | Refinement 要求 |
|-----------|----------------|
| M（2 Points） | 必須經過 Refinement |
| L（3 Points） | 必須經過 Refinement |
| S（1 Point） | 免除 Refinement（預設） |

### S size 豁免例外（`skills/sprint-planning/SKILL.md §9.2`）

1. S size Story 跨越 3 個以上 Story Type 的邊界
2. S size Story 是另一個 M/L Story 的前置依賴
3. S size Story 包含跨系統外部依賴

---

## 衍生測試案例

| Scenario | 測試類型 | 主要斷言 |
|----------|---------|---------|
| Scenario 1 | Behavior Check | NOT_READY Story 不進入 PO Round 1 |
| Scenario 2 | Behavior Check | READY Story 可進入 PO Round 1，報告含 Q1–Q5 |
| Scenario 3 | Behavior Check | S-size 標注豁免，直接進入 PO Round 1 |
| Scenario 4 | Behavior Check | 跨 Type S-size 不得豁免，須完整 Refinement |
