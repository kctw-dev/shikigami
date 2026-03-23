# Product Brief：GAD 接入 Delivery Phase（雙 Team 視覺對比）

**狀態**：草稿
**來源**：#362 P0 GAD 研究報告 §六
**日期**：2026-03-23

---

## 1. 問題陳述

前端 Story 的 QA Gate 目前只有「tests GREEN」，缺乏視覺對比驗證。Agent 實作的 UI 可能通過測試但與 Figma 設計不一致。需要雙 Team 交替審查機制：Agent A 實作 → Agent B 截圖對比 Figma → 批判 → 修正。

## 2. 目標使用者

前端開發 Story 的 Developer + QA — 視覺品質提升

## 3. 商業假設

- [UNCERTAIN] 假設：Agent 截圖對比 Figma 的準確度足夠（Vision Critic 已有基礎 ≥80 分）— 驗證方法：對照人工 review 結果
- [UNCERTAIN] 假設：browser automation（agent-browser）可靠取得截圖 — 驗證方法：技術 PoC

## 4. 提案解決方向

```
Test Contract GREEN
    +
Agent A 實作 → Agent B 截圖對比 Figma + Contract Spec → 批判報告 → Agent A 修正
    ↓
QA Veto Gate：tests GREEN + visual diff PASS
```

## 5. 成功指標

前端 Story 視覺一致性 ≥ 90%（Vision Critic 分數）

## 6. 排除範圍

僅適用前端 Story（有 Figma Prototype 的），後端/Infra Story 不適用

## 7. 依賴與風險

- 依賴 talk-to-figma-mcp（已有 ADR-016）
- 依賴 agent-browser 截圖能力
- 依賴 Vision Critic（已有 skills/vision-critic/SKILL.md）
