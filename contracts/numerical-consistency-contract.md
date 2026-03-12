---
title: 數值一致性合約
created: 2026-03-12
last_updated: 2026-03-12
applicable_roles:
  - developer
  - qa-engineer
  - scrum-master
---

# 數值一致性合約

本合約定義專案中數值資料修改的跨表同步驗證標準。所有 `applicable_roles` 列出的角色在修改任何數值資料時，必須依本合約執行同步驗證。

---

## 適用情境

- Developer 修改 Story Points、Velocity、完成率等數值時
- Sprint Review 中更新 Metrics_Log.md 數值時
- PROJECT_BOARD.md 與 sprint_N.md 的狀態數值同步時
- ROADMAP.md 里程碑進度數值更新時

---

## 數值類型定義

| 數值類型 | 典型位置 | 跨表同步目標 |
|---------|---------|------------|
| Story Points | sprint_N.md、PROJECT_BOARD.md | 兩文件 Points 欄必須一致 |
| Velocity | Metrics_Log.md、PROJECT_BOARD.md 統計區塊 | 同 Sprint 的 Velocity 數值必須一致 |
| 完成率 | Metrics_Log.md、sprint_N.md | 計算基數（分子/分母）必須一致 |
| 里程碑進度 | ROADMAP.md、PROJECT_BOARD.md | 已完成 Story 數量必須一致 |

---

## 檢查清單

### 修改前確認

- [ ] 識別本次修改影響的所有數值欄位
- [ ] 列出所有包含相同數值的文件清單（跨表清單）
- [ ] 確認修改原因合理，非誤操作

### 修改中同步

- [ ] **數值修改後須跨表同步驗證**：對每個受影響文件執行 read-then-compare，確認數值一致性
- [ ] 修改 sprint_N.md 的 Points 後，同步更新 PROJECT_BOARD.md 統計區塊
- [ ] 修改 Metrics_Log.md 的 Velocity 後，確認與 sprint_N.md 完成 Story 加總一致
- [ ] 修改 ROADMAP.md 里程碑進度後，確認 PROJECT_BOARD.md 對應 Story 狀態已更新

### 修改後驗證

- [ ] 逐一核對所有受影響文件的數值，確認與修改後目標值一致
- [ ] 若發現不一致，在提交 commit 前修正，不得帶著不一致狀態提交
- [ ] Commit message 中標注已執行跨表同步驗證（格式：`驗證跨表數值一致性：{影響文件清單}`）

### 特殊情境

- [ ] 若因歸檔操作（docs/km/archive/）導致數值移動，確認歸檔前後的數值總和不變
- [ ] 若數值計算基準變更（如 T-shirt Sizing 對照表調整），需在 Retrospective Log 記錄變更說明

---

## 違規偵測

QA Engineer 在 Sprint Review 中若發現跨表數值不一致，應：

1. 標記為 `[NUMERICAL-INCONSISTENCY]` 問題
2. 列出不一致的文件路徑與具體數值差異
3. 要求 Developer 在 Sprint Review 結束前修正並重新提交

---

## 免除情境

以下情境可豁免跨表同步要求，但需在 commit message 中說明豁免原因：

- 文件正在進行大規模重構，跨表同步將在重構完成後統一執行
- 測試環境的臨時數值，明確標注 `[TEST-ONLY]`
