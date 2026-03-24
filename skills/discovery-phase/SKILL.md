---
name: discovery-phase
description: "Use when starting product discovery, exploring new requirements, or validating business assumptions before Sprint Planning"
---

# Discovery Phase — Phase 0 產品探索

## 1. 概述

Discovery Phase 是五階段流水線的 **Phase 0**，獨立於 backlog-management 之外運作。

```
Phase 0 Discovery → Phase 1 Definition → Phase 2 Delivery → Phase 3 Testing & Quality → Phase 4 SRE
```

**觸發時機**：
- 里程碑啟動時（新里程碑開始前）
- Sprint 中段出現重大需求不確定性時
- `feature-request` Issue 達回饋閾值時（由 `/issue-management §10.2` 偵測）

兩種觸發入口（Milestone 觸發 vs Issue 觸發）流程步驟相同，差異在 Step 1 背景分析起點與候選需求範圍。詳見 [`references/trigger-modes.md`](references/trigger-modes.md)

**目標**：在進入 Sprint Planning 之前，確保每個候選需求的商業假設已外顯化、技術可行性已初步評估，並經 PO 正式簽核為可執行的 Product Brief。

---

## 2. 執行流程

Discovery Phase 包含 6 個步驟，必須依序執行：

```
/discovery-phase（獨立觸發）
  ├─ Step 1：背景分析（PO 分析願景文件）
  ├─ Step 2：假設外顯化（三問機制，每個候選需求）
  ├─ Step 3：Product Brief 草稿（PO 產出標準化格式）
  ├─ Step 4：技術可行性評估（Architect 輸入）
  ├─ Step 5：PO 確認關卡（PO 簽核 Product Brief）
  └─ Step 6：轉化為 Backlog（開 GitHub Issues，移交 /backlog-management §3 Grooming）
```

### Step 1：背景分析（PO subagent）

- [ ] 讀取願景文件（PRD、ROADMAP.md），理解里程碑目標與產品方向
- [ ] 盤點現有功能缺口與技術債
- [ ] 識別候選需求清單（Candidate Requirements List）

### Step 2：假設外顯化（PO subagent）

針對每個候選需求執行三問機制：(1) 這個需求解決了什麼問題？(2) 我們假設哪些事情是真的？(3) 如果假設是錯的，會怎樣？

每個假設使用 `[UNCERTAIN] 假設：[描述] — 驗證方法：[方法]` 格式外顯化。

- [ ] 對每個候選需求完成三問分析並記錄 `[UNCERTAIN]` 假設

### Step 3：Product Brief 草稿（PO subagent）

- [ ] 使用 `docs/templates/product-brief-template.md` 為每個候選需求產出 Product Brief 草稿（7 個必填區段，詳見 §3）
- [ ] 所有 `[UNCERTAIN]` 假設必須出現在「商業假設」區段，狀態設為「草稿」
- [ ] 輸出存放於 `docs/discovery/PB-{YYYY-MM-DD}-{feature-slug}.md`

> Gate 1 觸發（見 §4）：草稿完成後進入 PO 草稿審查

### Step 4：技術可行性評估（Architect subagent）

- [ ] 讀取 Product Brief 草稿，評估技術可行性，識別需要 ADR 的 Story
- [ ] 在 Brief 的「依賴與風險」區段補充技術風險描述

> Gate 2 觸發（見 §4）：技術評估完成後進入確認

### Step 5：PO 確認關卡（PO subagent）

- [ ] 對每個 Product Brief 執行最終審查（Gate 3），選擇：**批准**（進 Step 6）/ **退回**（退回指定步驟）/ **擱置**（存檔備查）
- [ ] 更新 Product Brief 狀態

### Step 6：轉化為 Backlog（PO subagent）

僅針對狀態為「PO 已簽核」的 Product Brief：

- [ ] 開 GitHub Issue，套用原始 labels，Issue body 引用 Product Brief 路徑
- [ ] 標注需要 ADR 的 Issue
- [ ] 移交至 `/backlog-management §3 Grooming`

---

## Discovery Item Checklist（每個候選需求必做）

- [ ] Step 2：三問假設外顯化
- [ ] Step 3：PB 草稿（docs/discovery/PB-*.md）
- [ ] Gate 1：PO 草稿審查
- [ ] Step 4：Architect 技術可行性
- [ ] Gate 2：技術確認
- [ ] Step 5：PO 簽核
- [ ] Step 6：轉 Backlog（開 Issue）

---

## 3. Product Brief 格式

Product Brief 是 Discovery Phase 的核心產出物，使用 `docs/templates/product-brief-template.md` 模板建立。必填 7 個區段：問題陳述、目標使用者、商業假設（`[UNCERTAIN]` 格式）、提案解決方向、成功指標、排除範圍、依賴與風險。

> 詳細格式規範與假設外顯化格式，見 [`references/product-brief-template.md`](references/product-brief-template.md)

---

## 4. PO 確認關卡（Hard Gate）

<HARD-GATE>
未經 PO 確認的 Product Brief 不得轉化為 Backlog Item。
</HARD-GATE>

Discovery Phase 定義 3 個 PO 確認關卡（Gate 1 草稿審查、Gate 2 技術可行性確認、Gate 3 PO 最終簽核），任何一個關卡未通過，流程不得繼續推進。

> 各 Gate 詳細通過條件與未通過後果，見 [`references/po-confirmation-gates.md`](references/po-confirmation-gates.md)

---

## 5. 與其他 Skill 的關係

| Skill | 關係說明 |
|-------|----------|
| `/backlog-management` | Step 6 產出的 GitHub Issues 移交至 `/backlog-management §3 Grooming` 進行 RICE 評分與 Sprint 排程 |
| `/sprint-planning` | 經 Grooming 的 Backlog → Sprint Planning 選取。Discovery Phase 不直接觸發 Sprint Planning |
| `/architecture-decision` | Step 4 識別的「需要 ADR」項目，需先完成 `/architecture-decision` 流程（ADR 狀態 = Accepted）才能進 Sprint |

---

## 6. Hard Gates 彙整

Gate 1（草稿審查）→ Gate 2（技術確認）→ Gate 3（PO 最終簽核）三關必須依序通過。任何 Product Brief 未通過 Gate 3，不得執行 Step 6 轉化為 Backlog。

> 詳細規則見 [`references/po-confirmation-gates.md`](references/po-confirmation-gates.md)

---

## 7. Subagent 派遣順序

```
1. PO        → Step 1 背景分析（願景文件、功能缺口盤點）
2. PO        → Step 2 假設外顯化（三問機制，每個候選需求）
3. PO        → Step 3 Product Brief 草稿（7 區段標準格式）
               ↓ [Gate 1: PO 草稿審查]
4. Architect → Step 4 技術可行性評估（識別 ADR 需求、技術風險）
               ↓ [Gate 2: Architect 技術確認]
5. PO        → Step 5 最終簽核（批准 / 退回 / 擱置）
               ↓ [Gate 3: PO 最終簽核]
6. PO        → Step 6 轉化為 Backlog（開 GitHub Issues，移交 Grooming）
```
