# SBE 範例：Sprint Planning 排程模式 HARD-GATE

**模組**：sprint-lifecycle
**業務規則來源**：`skills/sprint-planning/SKILL.md §3.1`
**版本**：v1.0
**日期**：2026-03-12
**狀態**：Active

---

## 業務規則摘要

排程模式（`SHIKIGAMI_SCHEDULED=true`）下，Sprint Planning 只允許選入 S-size（1pt）Stories。選入 M 或 L size Stories 時，流程**必須中止**並輸出告警。

---

## Scenarios

### Scenario 1：排程模式選入非 S-size Story 觸發 HARD-GATE

```gherkin
Scenario: 排程模式下選入非S-size Story時Sprint Planning中止

  Given 環境變數 SHIKIGAMI_SCHEDULED 設為 "true"
    And PO subagent 已從 Backlog 篩選出候選 Stories
    And 候選 Stories 中包含至少一個 M-size Story（US-#NX）

  When  PO subagent 嘗試將 M-size Story（US-#NX）選入 Sprint Backlog

  Then  Sprint Planning 流程中止，不繼續後續步驟
    And 輸出告警訊息的第一行包含 "[SCHEDULED-MODE-GATE]"
    And 告警訊息列出所有違規的 Story ID 及其 T-shirt Size
    And 告警訊息包含「建議改為手動執行 Sprint Planning」的提示
```

---

### Scenario 2：排程模式選入非 S-size Story（L-size）同樣觸發 HARD-GATE

```gherkin
Scenario: 排程模式下L-size Story同樣觸發HARD-GATE

  Given 環境變數 SHIKIGAMI_SCHEDULED 設為 "true"
    And PO subagent 已從 Backlog 篩選出候選 Stories
    And 候選 Stories 中包含 L-size Story（US-YYY）

  When  PO subagent 嘗試將 L-size Story（US-YYY）選入 Sprint Backlog

  Then  Sprint Planning 流程中止
    And 輸出告警訊息包含 "[SCHEDULED-MODE-GATE]"
    And 告警訊息列出 US-YYY 及其 Size "L"
```

---

### Scenario 3：排程模式下所有 Story 均為 S-size 時正常執行

```gherkin
Scenario: 排程模式下所有候選Story均為S-size時正常執行

  Given 環境變數 SHIKIGAMI_SCHEDULED 設為 "true"
    And PO subagent 已從 Backlog 篩選出候選 Stories
    And 所有候選 Stories 的 T-shirt size 均為 S（1pt）

  When  PO subagent 執行 Sprint Backlog 選取流程

  Then  Sprint Planning 繼續執行，不觸發 HARD-GATE
    And 所有 S-size Stories 正常進入 Sprint Backlog
    And 不輸出任何包含 "[SCHEDULED-MODE-GATE]" 的告警
```

---

### Scenario 4：手動模式下 M-size Story 不受排程限制

```gherkin
Scenario: 手動模式下M-size Story可正常選入Sprint Backlog

  Given 環境變數 SHIKIGAMI_SCHEDULED 未設定
    And PO subagent 已從 Backlog 篩選出候選 Stories
    And 候選 Stories 包含 M-size Story（US-ZZZ）

  When  PO subagent 執行 Sprint Backlog 選取流程

  Then  M-size Story（US-ZZZ）正常進入 Sprint Backlog
    And Sprint Planning 繼續執行
    And 不觸發排程模式 HARD-GATE
```

---

### Scenario 5：排程模式下混合 S 與 M-size 候選，M-size 被阻擋

```gherkin
Scenario: 排程模式下混合S和M-size候選時只有M-size被阻擋

  Given 環境變數 SHIKIGAMI_SCHEDULED 設為 "true"
    And PO subagent 已從 Backlog 篩選出候選 Stories
    And 候選 Stories 包含 S-size Story（US-AAA）
    And 候選 Stories 包含 M-size Story（US-BBB）

  When  PO subagent 嘗試執行 Sprint Backlog 選取

  Then  Sprint Planning 流程中止
    And 告警訊息列出 US-BBB 為違規 Story（Size: M）
    And 告警訊息不包含 US-AAA（S-size Story 不是阻擋原因）
```

---

## 來源業務規則引用

### HARD-GATE 原文（`skills/sprint-planning/SKILL.md §3.1`）

> 排程模式下，M/L Stories 不得選入 Sprint Backlog，僅 S size Stories 可納入。

### 告警訊息格式（`skills/sprint-planning/SKILL.md §3.1`）

```
[SCHEDULED-MODE-GATE] 排程模式下僅允許 S size Stories。
偵測到非 S size Story：
- <Story ID>：<標題>（Size: <M 或 L>）

Sprint Planning 已中止。請改為手動執行 Sprint Planning 以選入 M/L size Stories。
```

---

## 衍生測試案例

依照 `docs/definition/sbe-examples/SBE_TO_TEST_RULES.md` 的轉換規則，本文件的 Scenarios 衍生以下測試類型：

| Scenario | 測試類型 | 主要斷言 |
|----------|---------|---------|
| Scenario 1 | Branch Check | 輸出含 `[SCHEDULED-MODE-GATE]`，流程中止 |
| Scenario 2 | Branch Check | L-size 同樣觸發 GATE |
| Scenario 3 | Branch Check | 無 GATE 觸發，流程正常繼續 |
| Scenario 4 | Branch Check | 手動模式不受排程限制 |
| Scenario 5 | Branch Check | 混合情況下只有 M-size 被列入告警 |
