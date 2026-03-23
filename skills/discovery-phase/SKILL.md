---
name: discovery-phase
description: "Use when starting product discovery, exploring new requirements, or validating business assumptions before Sprint Planning"
---

# Discovery Phase — Phase 0 產品探索

## 1. 概述

Discovery Phase 是五階段流水線的 **Phase 0**，獨立於 backlog-management 之外運作。

**五階段流水線脈絡**：

```
Phase 0 Discovery → Phase 1 Definition → Phase 2 Delivery → Phase 3 Testing & Quality → Phase 4 SRE
```

**觸發時機**：
- 里程碑啟動時（新里程碑開始前）
- Sprint 中段出現重大需求不確定性時（mid-Sprint significant requirement uncertainty）
- `feature-request` Issue 達回饋閾值時（Issue 觸發，見下方說明）

### Issue 觸發 vs Milestone 觸發

Discovery Phase 支援兩種觸發入口，流程步驟相同，但背景分析的起點與範圍不同：

| 屬性 | Milestone 觸發 | Issue 觸發 |
|------|--------------|-----------|
| **觸發來源** | 里程碑啟動（新里程碑）或 Sprint 中段重大不確定性 | `feature-request` Issue 達閾值（≥3 thumbs-up 或 ≥5 comments），由 `/issue-management §10.2` 偵測並建議 |
| **Step 1 背景分析起點** | 願景文件（PRD、ROADMAP.md）+ 功能缺口盤點 | 觸發 Issue 本身（Issue body、留言、reactions）+ 相關功能現況 |
| **候選需求範圍** | 里程碑全範圍，可能包含多個候選需求 | 聚焦於觸發 Issue 所描述的單一需求（可擴展至相關 Issues） |
| **Product Brief 數量** | 一個里程碑通常產出多個 Product Brief | 通常聚焦產出 1 個 Product Brief（對應觸發 Issue） |
| **Issue 處理** | Step 6 新開 GitHub Issues | Step 6 引用原觸發 Issue，不重複開新 Issue |

**Issue 觸發的 Step 1 補充說明**：

當由 `/issue-management §10.2` 建議啟動時，Step 1 背景分析應額外執行：

```bash
# 讀取觸發 Issue 的完整內容與留言
gh issue view <trigger-issue-number> --comments --json \
  number,title,body,comments,reactionGroups,labels

# 查找相關 feature-request Issues（相似主題）
gh issue list --label "feature-request" --state open \
  --json number,title,reactionGroups,comments --limit 100
```

- [ ] 讀取觸發 Issue 的完整 body、所有留言與 reactions，作為候選需求的需求基礎
- [ ] 盤點是否有重複主題的其他 `feature-request` Issues，可一併納入同一 Discovery 探索範圍
- [ ] 識別候選需求清單（通常以觸發 Issue 為核心，可擴展至相關 Issues）

**目標**：在進入 Sprint Planning 之前，透過結構化的探索流程，確保每個候選需求的商業假設已外顯化、技術可行性已初步評估，並經 PO 正式簽核為可執行的 Product Brief。

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

### Step 1：背景分析

**執行角色**：PO subagent

- [ ] 讀取願景文件（PRD、產品文件、ROADMAP.md），理解里程碑目標與產品方向
- [ ] 盤點現有功能缺口與技術債，比對目前產品狀態與里程碑目標之間的差距
- [ ] 識別候選需求清單（Candidate Requirements List）
- [ ] 輸出：候選需求清單（可為結構化列表或暫存文件）

### Step 2：假設外顯化（三問機制）

**執行角色**：PO subagent

針對每個候選需求，執行三問機制，將隱性假設外顯化：

1. **這個需求解決了什麼問題？** — 釐清問題陳述，避免解決方案優先
2. **我們假設哪些事情是真的？** — 識別商業假設、使用者假設、技術假設
3. **如果假設是錯的，會怎樣？** — 評估假設失效的影響，決定驗證優先序

每個假設使用 `[UNCERTAIN]` 標籤格式外顯化：

```
[UNCERTAIN] 假設：[描述] — 驗證方法：[方法]
```

- [ ] 對每個候選需求完成三問分析
- [ ] 識別所有 `[UNCERTAIN]` 假設並記錄驗證方法
- [ ] 輸出：帶有 `[UNCERTAIN]` 標籤的假設清單

### Step 3：Product Brief 草稿

**執行角色**：PO subagent

- [ ] 使用 `docs/templates/product-brief-template.md` 為每個候選需求產出 Product Brief 草稿
- [ ] 確保所有 7 個必填區段均已填寫（詳見 §3）
- [ ] 所有 `[UNCERTAIN]` 假設必須出現在「商業假設」區段
- [ ] 狀態設為「草稿」
- [ ] 輸出：Product Brief 草稿（存放於 `docs/discovery/` 目錄，命名格式：`PB-{YYYY-MM-DD}-{feature-slug}.md`）

> **PO 確認關卡 Gate 1 觸發**（見 §4）：草稿完成後，進入 Gate 1 審查

### Step 4：技術可行性評估

**執行角色**：Architect subagent

- [ ] 讀取各 Product Brief 草稿，從技術角度評估可行性
- [ ] 識別需要 ADR 的 Story（標注「需要 ADR」）
- [ ] 標記技術風險與依賴項目
- [ ] 若有技術阻礙，在 Product Brief 的「依賴與風險」區段補充技術風險描述
- [ ] 輸出：Product Brief 草稿更新（技術可行性欄位）

> **PO 確認關卡 Gate 2 觸發**（見 §4）：技術評估完成後，進入 Gate 2 確認

### Step 5：PO 確認關卡

**執行角色**：PO subagent（最終決策者）

- [ ] PO 對每個 Product Brief 執行最終審查（Gate 3，見 §4）
- [ ] 對每個 Brief 選擇以下三種決議之一：
  - **批准（Approve）**：Product Brief 通過，可進入 Step 6 轉化為 Backlog
  - **退回（Return）**：需要修改，退回 Step 2 或 Step 3 重新執行
  - **擱置（Shelve）**：暫不推進，記錄原因，存檔備查
- [ ] 將 Product Brief 狀態更新為「PO 已簽核」、「退回修改」或「已擱置」

### Step 6：轉化為 Backlog

**執行角色**：PO subagent

僅針對狀態為「PO 已簽核」的 Product Brief 執行：

- [ ] 為每個已簽核的 Brief 開 GitHub Issue，套用原始 Issue labels（`feature-request` / `bug` / `question`）
- [ ] Issue body 中引用對應的 Product Brief 路徑
- [ ] 標注需要 ADR 的 Issue（由 Step 4 Architect 識別）
- [ ] 移交至 `/backlog-management §3 Grooming`，進行 RICE 評分與優先級排序
- [ ] 輸出：GitHub Issues（含 Product Brief 引用）

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

Product Brief 是 Discovery Phase 的核心產出物，使用 `docs/templates/product-brief-template.md` 模板建立。

### 7 個必填區段

| # | 區段名稱 | 說明 |
|---|----------|------|
| 1 | **問題陳述（Problem Statement）** | 清晰描述我們要解決的問題，不含解決方案 |
| 2 | **目標使用者（Target Users）** | 誰會受益？使用者的痛點是什麼？ |
| 3 | **商業假設（Business Assumptions）** | 所有 `[UNCERTAIN]` 假設，含驗證方法 |
| 4 | **提案解決方向（Proposed Direction）** | 方向性描述，不需是完整設計，允許多個選項 |
| 5 | **成功指標（Success Metrics）** | 如何判斷這個需求成功？可量化的指標 |
| 6 | **排除範圍（Out of Scope）** | 明確不做的事情，防止範圍擴張 |
| 7 | **依賴與風險（Dependencies & Risks）** | 技術依賴、外部依賴、已知風險（含 Architect 評估結果） |

### 假設外顯化格式（第 3 區段）

商業假設區段中，所有不確定的假設必須使用以下格式：

```markdown
- [UNCERTAIN] 假設：使用者願意為此功能付費 — 驗證方法：用戶訪談 + A/B 測試付費轉換率
- [UNCERTAIN] 假設：技術方案 X 能在現有架構下整合 — 驗證方法：Architect 概念驗證（PoC）
```

已驗證的假設（有資料佐證）則直接陳述，不加 `[UNCERTAIN]` 標籤。

---

## 4. PO 確認關卡（Hard Gate）

Discovery Phase 定義 3 個 PO 確認關卡，任何一個關卡未通過，流程不得繼續推進。

<HARD-GATE>
未經 PO 確認的 Product Brief 不得轉化為 Backlog Item。
</HARD-GATE>

### Gate 1：Product Brief 草稿審查

| 屬性 | 說明 |
|------|------|
| **觸發時機** | Step 3 Product Brief 草稿完成後 |
| **把關者** | PO |
| **通過條件** | (1) 問題陳述清晰、無解決方案污染；(2) 所有不確定假設已用 `[UNCERTAIN]` 標籤外顯化；(3) 7 個區段均已填寫 |
| **未通過後果** | 退回 Step 2 重新執行假設外顯化，或退回 Step 3 補充缺失區段 |

### Gate 2：技術可行性確認

| 屬性 | 說明 |
|------|------|
| **觸發時機** | Step 4 Architect 技術評估完成後 |
| **把關者** | Architect（確認無技術阻礙）|
| **通過條件** | Architect 確認：(1) 技術方向可行；(2) 無當前無法克服的技術阻礙；(3) ADR 需求已識別並標注 |
| **未通過後果** | Product Brief 進入「技術阻礙」狀態，暫停推進，待技術問題解決（可能需要先執行 `/architecture-decision`） |

### Gate 3：PO 最終簽核

| 屬性 | 說明 |
|------|------|
| **觸發時機** | Step 5 PO 最終審查 |
| **把關者** | PO（最終決策者）|
| **通過條件** | PO 明確選擇以下三種決議之一 |
| **決議選項** | **批准**：進入 Step 6；**退回**：指定修改點，退回對應步驟；**擱置**：記錄擱置原因，存檔 |
| **未通過後果** | 退回指定步驟修改（退回），或存入擱置清單（擱置），均不得進入 Step 6 |

---

## 5. 與其他 Skill 的關係

| Skill | 關係說明 |
|-------|----------|
| `/backlog-management` | Discovery Phase 的輸出物（GitHub Issues）移交至 `/backlog-management §3 Grooming`，進行 RICE 評分與 Sprint 排程 |
| `/sprint-planning` | 經 Grooming 的 Backlog → Sprint Planning 選取。Discovery Phase 不直接觸發 Sprint Planning |
| `/architecture-decision` | Step 4 Architect 識別的「需要 ADR」項目，需在進入 Sprint 前完成 `/architecture-decision` 流程（ADR 狀態 = Accepted） |

### 流程銜接示意

```
/discovery-phase
  └─ Step 6 產出 GitHub Issues
       └─ /backlog-management §3 Grooming（RICE 評分、優先級排序）
            └─ /sprint-planning（Sprint 週期選取）
```

若 Step 4 識別到需要 ADR 的需求：

```
/discovery-phase Step 4（識別 ADR 需求）
  └─ /architecture-decision（ADR 產出 + Accepted）
       └─ /sprint-planning（Story 解鎖，可進 Sprint）
```

---

## 6. Hard Gates 彙整

| Gate | 觸發時機 | 把關者 | 未通過後果 |
|------|----------|--------|------------|
| **Gate 1**：Product Brief 草稿審查 | Step 3 完成後 | PO | 退回 Step 2 或 Step 3 |
| **Gate 2**：技術可行性確認 | Step 4 完成後 | Architect | Product Brief 暫停，待技術問題解決 |
| **Gate 3**：PO 最終簽核 | Step 5 | PO | 退回修改 or 擱置，均不進 Step 6 |

**強制規則**：任何 Product Brief 未通過 Gate 3 PO 最終簽核，不得執行 Step 6 轉化為 Backlog。此為不可繞過的 Hard Gate。

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

**派遣說明**：

1. **PO（Steps 1–3）**：從願景文件出發，發掘候選需求，外顯化假設，產出 Product Brief 草稿。
2. **Architect（Step 4）**：接收 PO 產出的 Product Brief 草稿，評估技術可行性，識別 ADR 需求，更新 Brief 的「依賴與風險」區段。
3. **PO（Steps 5–6）**：執行最終簽核決策，對批准的 Brief 開 GitHub Issues，移交 Grooming 流程。
