# Product Brief：CRITICAL Issue 互動式確認

**狀態**：草稿
**來源**：#271 gstack vs Shikigami 競品分析 §5.2
**日期**：2026-03-23

---

## 1. 問題陳述

quality-gate 發現 CRITICAL issue 時，目前自動進入修復循環。但有些 CRITICAL 判定可能是誤判，或需要使用者判斷是否真的要修。缺乏人的決策介入點。

## 2. 目標使用者

Developer + PO — 對 CRITICAL issue 保留人的決策權

## 3. 商業假設

- [UNCERTAIN] 假設：CRITICAL 誤判率 > 10% — 驗證方法：統計過去 Sprint 的 CRITICAL 判定 vs 實際需修復比率
- [UNCERTAIN] 假設：互動式確認不會拖慢 project_level=low 的自動化流程 — 驗證方法：僅在 medium/high 啟用，low 維持自動

## 4. 提案解決方向

project_level 控制：
- low：CRITICAL 自動修復（現有行為不變）
- medium/high：CRITICAL 用 AskUserQuestion 逐一確認

## 5. 成功指標

CRITICAL 修復的有效率提升（減少不必要的修復循環）

## 6. 排除範圍

不改變 MEDIUM/LOW 的處理方式

## 7. 依賴與風險

- 依賴 project_level 機制（已完成 #348）
- low 模式不受影響（紅線 #9）
