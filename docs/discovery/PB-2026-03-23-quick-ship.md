# Product Brief：快速交付 Skill（/shoot 進化版）

**狀態**：草稿
**來源**：#271 gstack vs Shikigami 競品分析 §5.3
**日期**：2026-03-23

---

## 1. 問題陳述

Shikigami 的交付流程分散在 git-workflow + sprint-execution + quality-gate + deployment-readiness 多個 skill。gstack 的 `/ship` 一鍵串完 test → review → version → changelog → commit → push → PR，體驗更流暢。

## 2. 目標使用者

需要快速交付單一改動的開發者（已有 /shoot，但 /shoot 的 QA gate 較重）

## 3. 商業假設

- [UNCERTAIN] 假設：存在一類改動適合「比 /shoot 更輕但比直接 commit 更安全」的交付路徑 — 驗證方法：統計 /shoot 中 QA gate 通過率 100% 的比例
- [UNCERTAIN] 假設：減少 QA gate 不會降低品質 — 驗證方法：追蹤快速交付的 DISPUTE 率

## 4. 提案解決方向

分層交付：
- `/commit`（最輕）：lint + format → commit → push（無 QA gate）
- `/shoot`（現有）：完整 QA gate → PR → merge
- `/sprint-execution`（最重）：Sprint 儀式 + 完整審查

## 5. 成功指標

交付效率提升（小改動的 cycle time 下降）

## 6. 排除範圍

不降低 /shoot 的品質標準。新增一個更輕的路徑，不替代。

## 7. 依賴與風險

- 需要明確定義「哪些改動適合 /commit」的判斷標準
- 風險：開發者可能濫用輕量路徑跳過品質關卡
