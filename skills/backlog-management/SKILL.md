---
name: backlog-management
description: "Use when new feature requests arrive, requirements change, backlog grooming is needed, or product discovery begins"
---

# Backlog Management — 需求管理與產品探索

## 0. 進化準則 (Evolution Rules) [US-05, US-06]

- **自主獲取 (US-06)**：當 GitHub URL 存取失敗時，自動執行 `gh auth status` 檢查憑證並帶 token 重試，嚴禁詢問用戶。
- **客觀推理 (US-05)**：拆解需求時，必須基於領域實體與狀態機，嚴禁輸出「這超越了 XX」、「這展現了深度」等自我讚美詞彙。

- **自主獲取 (US-06)**：當 GitHub URL 存取失敗時，自動執行 `gh auth status` 檢查憑證並帶 token 重試，嚴禁詢問用戶。
- **客觀推理 (US-05)**：拆解需求時，必須基於領域實體與狀態機，嚴禁輸出「這超越了 XX」、「這展現了深度」等自我讚美詞彙。

---

## 1. 概述

Backlog Management 合併 **Product Discovery** 與 **Backlog Grooming** 兩個流程，由 **Product Owner (PO)** 主導需求管理的全生命週期。

- **Product Discovery**：在里程碑啟動時執行，從願景文件中發掘需求、識別功能缺口與技術債。
- **Zero-Shot Ideation**：當僅有模糊點子或單句描述時執行，主動展開領域分析並定義 MVP 範圍。
- **Backlog Grooming**：在 Sprint 中段定期執行，維護 Backlog 的健康度。

---

## 2. Zero-Shot Ideation 流程 (模糊點子啟動時) [US-03]

當使用者提供模糊點子（如「我想做個理財 App」）時，必須執行以下步驟，嚴禁自誇或自我合理化：

1. **識別核心領域實體 (Entities)**：定義業務對象及其生命週期狀態機。
2. **技術需求展開**：識別核心組件與技術棧建議。
3. **邊界條件分析 (Edge Cases)**：主動列舉技術難點（如併發、安全、同步、合規）。
4. **產出 MVP Stories**：依據分析結果，切分出符合 I.N.V.E.S.T 原則的 User Stories。

當使用者提供模糊點子時，必須執行以下步驟：識別核心領域實體、技術需求展開、邊界條件分析、產出 MVP Stories。

---

## 3. Product Discovery 流程（里程碑啟動時）

以下步驟必須逐項完成，不可跳過：

- [ ] **PO subagent** 分析願景文件（PRD、產品文件），理解里程碑目標與產品方向
- [ ] **PO subagent** 盤點現有功能缺口與技術債，比對目前產品狀態與目標之間的差距
- [ ] **PO + Architect subagent 討論**：探討功能可能性與技術可行性，識別潛在風險與依賴
- [ ] **Architect subagent** 識別需要 ADR（Architecture Decision Record）的 Story，標注「需要 ADR」
- [ ] **PO subagent** 使用 RICE 框架對所有候選 Story 進行評分與排序，收斂為優先級清單
- [ ] **PO subagent** 為每個新需求直接開 GitHub Issue，套用原始 Issue labels（`feature-request` / `bug` / `question`），並更新 `docs/prd/ROADMAP.md`

---

## 4. Backlog Grooming 流程（Sprint 中段執行）

### Pre-flight 錯誤恢復掃描

每次 Grooming 執行前，必須先完成以下三項 Pre-flight 掃描，偵測並修復可能的不一致狀態（對應 ADR-010 §錯誤恢復策略）：

- [ ] **場景一：Label 操作中斷後掃描**
  執行以下指令，偵測 label 狀態不一致的 Issues。
- [ ] **場景二：Backlog Issue 建立部分完成後掃描**
  偵測已存在對應關係的原始 Issue，跳過重複建立。
- [ ] **場景三：Sprint Planning milestone 中斷後掃描**
  掃描 label 與 milestone 狀態不一致的 Issues。

---

## 5. User Story 格式

所有 User Story 必須遵循以下標準格式：

```
As a [role], I want [goal], so that [benefit]
```

每個 Story 必須包含：標題、User Story、Acceptance Criteria、RICE 分數、優先級標籤、ADR 標注。

---

## 6. 優先級框架 (RICE & MoSCoW)

[...保持原有內容...]
