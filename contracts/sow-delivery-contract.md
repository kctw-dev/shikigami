---
title: SOW 交付合約
created: 2026-03-12
last_updated: 2026-03-12
applicable_roles:
  - architect
  - qa-engineer
  - developer
---

# SOW 交付合約

本合約定義 Statement of Work（SOW）文件的交付標準。所有 `applicable_roles` 列出的角色在建立或審查 SOW 文件時，必須依本合約執行驗收。

---

## 適用情境

- 新 Story 需要 SOW 作為設計依據時
- Sprint Planning 中 SOW 文件審查時
- Sprint Review 中 SOW 交付物驗收時

---

## 檢查清單

### 必要結構

- [ ] SOW 文件含有明確的標題與版本號
- [ ] SOW 文件含有目標描述（Objective）區段，說明交付目的與商業價值
- [ ] SOW 文件含有範疇定義（Scope）區段，明確列出 In-Scope 與 Out-of-Scope 項目
- [ ] SOW 文件含有交付物清單（Deliverables）區段
- [ ] SOW 文件含有驗收標準（Acceptance Criteria）區段

### 架構文件要求

- [ ] **SOW 必須包含架構圖**（系統架構圖、資料流圖或元件關係圖，至少一種）
- [ ] 架構圖需標注主要元件與元件間的介面邊界
- [ ] 架構圖需與 SOW 文件中的技術描述一致

### 時程與資源

- [ ] SOW 含有時程規劃（Sprint 編號或預估完成日期）
- [ ] SOW 含有負責角色（Owner）與參與角色（Stakeholders）定義

### 品質與審查

- [ ] SOW 經過 Architect 技術審查確認可行性
- [ ] SOW 經過 QA Engineer 確認 AC 具備可測試性
- [ ] SOW 中的術語與 `docs/prd/PRODUCT_BACKLOG.md` 保持一致

---

## 違規處置

若 SOW 文件未通過本合約任一強制項（標注 **SOW 必須包含...** 的條目），QA Engineer 應：

1. 拒絕驗收，回傳 FAIL 結論
2. 列出具體未達標項目
3. 要求 Architect 修訂後重新提交審查
