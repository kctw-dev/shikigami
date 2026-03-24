---
name: systematic-debugging
description: "Use when encountering bugs, test failures, or unexpected behavior — systematic root cause analysis and regression prevention"
---

# Systematic Debugging — 系統化除錯

## 1. 概述

遇到 bug、測試失敗、非預期行為時的標準除錯流程。由 **Developer subagent** 主導除錯，**QA subagent** 驗證修復。

核心原則：**禁止猜測性修復，必須有根因調查。**

---

## 2. 核心原則（Iron Law）

```
沒有根因調查，不得提出修復方案。
```

- **先觀察再假設，先假設再動手**：未充分蒐集證據前，不得跳入修復階段。
- **每次只改一個變數**：同時修改多處會使因果關係無法釐清。
- **用 git stash 保護現場**：動手前先保存當前工作狀態，確保可隨時還原。
- **禁止「猜測性修復」**：每一個修復動作都必須有證據支持，不得憑直覺嘗試。

---

## 3. 四階段流程

Phase 1: 根因調查 → Phase 2: 模式分析 → Phase 3: 假設與驗證 → Phase 4: 實作修復

詳細四階段流程（根因分類表、判定規則、追溯報告格式）見 `references/four-phase-flow.md`。

---

## 4. Hard Gates

<HARD-GATE>
未完成 Phase 1 根因調查，不得提出修復方案。
</HARD-GATE>

<HARD-GATE>
連續修復失敗 3 次，必須升級至 Architect 評估是否為架構問題。
不得嘗試第 4 次修復。
</HARD-GATE>

---

## 5. Red Flags

以下念頭出現時，代表你正在偏離系統化除錯流程。**立即停止，返回 Phase 1。**

| Red Flag 念頭 | 正確做法 |
|----------------|----------|
| 「快速修一下就好，之後再查」 | STOP — 返回 Phase 1，先完成根因調查 |
| 「試試改 X 看會不會好」 | STOP — 這是猜測性修復，必須先有假設與證據 |
| 「同時改多個地方，跑測試」 | STOP — 每次只改一個變數，否則無法釐清因果 |
| 「跳過測試，手動驗證」 | STOP — 必須有自動化測試證明修復有效 |
| 「大概是 X 的問題，先修那個」 | STOP — 「大概」不是證據，回到 Phase 1 蒐集證據 |
| 「我不完全理解，但這樣可能可以」 | STOP — 不理解根因就不該動手修復 |
| 「再試一次修復」（已失敗 2+ 次時） | STOP — 觸發 Hard Gate，升級至 Architect 評估 |

---

## 6. Subagent 派遣

```
1. Developer subagent → 執行 Phase 1-4 除錯流程
2. QA subagent       → 驗證修復（Spec Compliance + Code Quality）
3. 如為架構問題      → Architect subagent 評估
```

---

## 7. 與其他 Skill 的關係

| 情境 | 觸發 |
|------|------|
| 修復完成 | 走 `quality-gate` 驗證 |
| 發現架構問題 | 觸發 `architecture-decision` |
| 需要安全修復 | 觸發 `security-review` |
| Sprint 中的 Bug | 更新 PROJECT_BOARD，回到 `sprint-execution` |
