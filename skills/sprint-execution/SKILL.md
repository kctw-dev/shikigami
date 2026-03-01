---
name: sprint-execution
description: "Use when executing sprint stories, implementing features, or working through sprint backlog items"
---

# Sprint Execution — Subagent 驅動開發

## 1. 概述

Sprint 執行的核心 Skill。從 Sprint Backlog 逐個取出 Story，透過 **Subagent 驅動開發模式** 完成實作與審查。

每個 Story 派遣一個全新的 Developer subagent 進行 TDD 開發，完成後經過**雙階段審查**（Spec Compliance + Code Quality）確保品質，最終更新 PROJECT_BOARD 並進入下一個 Story。

---

## 2. 核心原則

**Fresh subagent per story + 雙階段審查 = 高品質、快速迭代**

- **隔離性**：每個 Story 使用全新的 Developer subagent，避免上下文污染
- **TDD 強制**：所有功能實作必須先寫測試再寫代碼
- **雙階段審查**：Spec Compliance 確認做對了，Code Quality 確認做好了
- **小步快跑**：每個小步驟一個 commit，保持可追溯性

---

## 3. 執行流程

```
Issue 快掃（gh issue list --state open --limit 10）
  |-- gh 失敗 --> 靜默略過，繼續下一步（不阻塞）
  +-- 成功 --> 篩出需回覆的 issue → PO 草稿 → QA 審核 → 發布
  |
  v
Sprint Backlog 中取出 Story
  |
  v
派遣 Developer subagent（使用 developer-prompt.md）
  |
  v
Developer 實作 + TDD + 自我審查
  |
  v
派遣 QA subagent 做 Spec Compliance Review（使用 spec-reviewer-prompt.md）← 不可跳過（HARD-GATE）
  |-- 不通過 --> Developer 修復 --> 重新審查
  +-- 通過
        |
        v
派遣 QA subagent 做 Code Quality Review（使用 quality-reviewer-prompt.md）← 不可跳過（HARD-GATE）
  |-- 不通過 --> Developer 修復 --> 重新審查
  +-- 通過
        |
        v
如有安全相關 --> 派遣 Security subagent
  |
  v
更新 PROJECT_BOARD
  |
  v
Sprint Backlog 還有 Story？
  |-- YES --> 取出下一個 Story（回到頂端繼續）
  +-- NO（所有 Story 完成）--> 立即 invoke shikigami:sprint-review（不詢問使用者）
```

### 步驟詳解

1. **取出 Story**：從 `docs/PROJECT_BOARD.md` 的「待辦」欄取出優先級最高的 Story，移至「進行中」。
2. **派遣 Developer subagent**：使用 `developer-prompt.md` 作為 prompt，注入 Story 的 Acceptance Criteria、相關 ADR、設計文件。
3. **Developer 實作**：遵循 TDD（Red → Green → Refactor），每個小步驟一個 commit，完成後執行自我審查 checklist。
4. **Spec Compliance Review**：派遣 QA subagent 使用 `spec-reviewer-prompt.md`，獨立驗證實作是否符合所有 Acceptance Criteria。
5. **Code Quality Review**：派遣 QA subagent 使用 `quality-reviewer-prompt.md`，評估代碼品質、SOLID 原則、測試品質。
6. **安全審查（條件觸發）**：若 Story 涉及外部輸入、API 端點、配置變更，派遣 Security subagent 進行安全審查。
7. **更新看板與同步 Sprint 文件**：Story 移至「已完成」，更新 `docs/PROJECT_BOARD.md`。同時同步 `docs/sprints/sprint_N.md` 的 Sprint Backlog 狀態欄（N 從 PROJECT_BOARD.md 符合 `/^## Sprint (\d+)/` 的最近「進行中」標題提取）：開啟 `docs/sprints/sprint_N.md`，將對應 Story 列的「狀態」欄更新為與 PROJECT_BOARD.md 一致。接著檢查終止條件：Sprint Backlog 中仍有待辦 Story → 取出下一個 Story 繼續執行；Sprint Backlog 已清空（所有 Story 完成）→ **立即 invoke shikigami:sprint-review**，不詢問使用者、不跳回「下一個 Story」流程。

---

## 4. Hard Gates

<HARD-GATE>
每個 Story 必須通過雙階段審查（Spec Compliance + Code Quality）才能標記為完成。
不得跳過任何一個審查階段。

> 歷史案例：Sprint 7 因跳過此步驟列為 Retro Problem（Issue #14），導致品質門禁失效。
</HARD-GATE>

<HARD-GATE>
所有功能實作必須遵循 TDD：先寫失敗測試 → 最小實作讓測試通過 → 重構。
例外：標注為 [SPIKE] 的探索性任務可豁免，但進入正式開發時必須補測試。
</HARD-GATE>

---

## 5. DoD 自檢

每個 Story 完成前，Developer 必須逐項檢查 Definition of Done：

| 層次 | 條件 | 自檢 |
|------|------|------|
| 功能 | 所有 Acceptance Criteria 通過 | [ ] |
| 測試 | 單元測試 + 整合測試全部通過（0 failed） | [ ] |
| 安全 | 外部輸入通過安全驗證與去活化處理 | [ ] |
| 文件 | 設計文件對應章節已更新，代碼含設計文件引用 | [ ] |
| 設定 | 無硬編碼金鑰，配置透過環境變數管理 | [ ] |
| 度量 | Metrics_Log.md 本 Sprint 數據已更新（Velocity、完成率、趨勢） | [ ] |
| 反回歸 | 既有測試全部仍然通過 | [ ] |
| 技術債 | 取捷徑情況已用 `[TECH-DEBT]` 標記，並更新 `docs/km/Tech_Debt_Registry.md`（詳見 `developer-prompt.md` 的「Tech Debt 管理」區段） | [ ] |

---

## 6. 審查失敗處理

當任一審查階段不通過時：

1. Reviewer 產出具體問題清單（含嚴重度分級）
2. 同一個 Developer subagent 接收問題清單進行修復
3. 修復完成後，重新執行該審查階段
4. 同一審查階段連續失敗 3 次，升級至 Architect 評估是否有設計問題

---

## 7. 安全審查觸發條件

以下情況自動觸發 Security subagent：

- Story 涉及外部使用者輸入處理
- 新增或修改 API 端點
- 涉及認證 / 授權邏輯
- 涉及加密 / 金鑰管理
- 涉及配置變更或環境變數

---

## 8. 與其他 Skill 的關係

| 情境 | 觸發 |
|------|------|
| 發現需求不清 | 暫停，升級至 PO 釐清 → 回到 sprint-execution |
| 發現需要架構決策 | 暫停，觸發 `architecture-decision` → ADR 定案後回到 sprint-execution |
| 所有 Story 完成 | 觸發 `sprint-review` 進行驗收與回顧 |
| 發現安全問題 | 觸發 `security-review` 進行深度安全審查 |
