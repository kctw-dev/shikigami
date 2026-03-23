# Product Brief：Review 建議清單（非二元 gate）

**狀態**：草稿
**來源**：#362 P0 GAD 研究報告 §六
**日期**：2026-03-23

---

## 1. 問題陳述

Shikigami 的 Veto Gate 是二元判定（PASS/FAIL）。FAIL 時產出問題清單要求修復，但 Developer 沒有「部分接受」的選項。實務上有些建議是改善性而非阻塞性，強制全部修復降低效率。

## 2. 目標使用者

Developer subagent — 保留決策權，提升修復效率

## 3. 商業假設

- [UNCERTAIN] 假設：分離建議與阻塞可減少修復循環次數 — 驗證方法：統計 FAIL 後的平均修復輪數（前後對比）
- [UNCERTAIN] 假設：Developer 有能力正確判斷哪些建議可跳過 — 驗證方法：跳過的建議在後續 Sprint Review 是否被 DISPUTE

## 4. 提案解決方向

Review 產出分兩層：
- **MUST FIX**（阻塞）：不修不過 gate
- **SUGGESTION**（建議）：Developer 自行決定，記錄決策理由

## 5. 成功指標

修復循環次數下降 20%+

## 6. 排除範圍

不改變 Hard Gate 機制本身，只分層 review 產出

## 7. 依賴與風險

依賴 pr-review-toolkit 嚴重度分級（已有 CRITICAL/HIGH/MEDIUM/LOW）
