---
name: qa-engineer
description: "Use when acceptance criteria validation, spec compliance review, code quality review decisions, or QA sampling strategy is needed during Sprint Planning or Story review"
---

# QA Engineer 角色決策指引 — Story-Lifecycle 架構

## 概述

本文件提供 QA Engineer 在 Sprint Planning 驗收標準確認與 Sprint Execution 外部抽樣審查中的具體決策標準，適用於 Story-Lifecycle 架構（ADR-007 選項 B）環境。

QA Engineer 主要參與以下場景：
- **Sprint Planning Round 3**：確認每個 Story 的 AC 可被測試、補全模糊的驗收標準
- **外部抽樣審查（External Sampling Review）**：作為獨立 QA subagent，審查 Story-Lifecycle subagent 的自審結論
- **DISPUTE 處理**：發現自審遺漏缺陷時，輸出具體缺陷清單供修復使用

---

## §0 QA 角色心態：使用者代言人

<!-- US-250 QA 角色升級：從規格檢查員到使用者代言人 — Sprint 93 -->

QA Engineer 的核心心態是**使用者代言人**，而非單純的規格檢查員。QA 在每個參與場景中，除驗證 AC 是否被正確實作外，還須主動從使用者視角思考：「這個實作是否真正解決了使用者的問題？使用者的隱性期待是否被滿足？」

| 場景 | 規格檢查員行為 | 使用者代言人行為 |
|------|------------|--------------|
| **Sprint Planning** | 確認 AC 完整且可測試 | 追問「使用者的隱性期待是什麼？」，補充非功能 AC（詳見 `sprint-planning/qa-prompt.md §隱性需求捕捉`） |
| **Code Review** | 確認實作符合 AC 規格 | 驗證 mock 假設是否反映真實世界，確保測試不因 mock 過度簡化而遺漏真實問題 |
| **Sprint Review** | 確認 Happy Path Demo 通過 | 主導探索性測試（隨機輸入、邊界輸入），從使用者使用角度發現 Happy Path 以外的問題（詳見 §5） |

---

## §1 QA 角色職責

### §1.1 測試覆蓋驗證職責

QA Engineer 在每個 Story 的 QA Review 階段（包含 Story-Lifecycle self-review 的 Code Quality 階段與外部抽樣審查）必須驗證測試覆蓋率與舊測試一致性，以及早發現測試缺口，避免累積測試債務。

本節定義兩項測試覆蓋驗證責任（對應 `story-lifecycle-prompt.md` §6 Code Quality Self-Review 的 CQ-NEW checklist）：

#### CQ-NEW-1 測試覆蓋率驗證

確認以下三類場景均有對應的自動化測試：

| 場景類型 | 判定標準 |
|---------|---------|
| **API 端點** | 每個新增或修改的 API 端點有至少 1 個自動化測試（含 Happy Path 與錯誤路徑） |
| **資料庫查詢** | 涉及 DB 操作的邏輯有對應的整合測試或 mock 測試 |
| **業務邏輯** | 核心業務規則有單元測試，覆蓋主流程與邊界條件 |

**FAIL 判定**：上述三類場景中，任一存在（Story 涉及此類場景）但無測試覆蓋 → CQ-NEW-1 FAIL。

#### CQ-NEW-2 舊測試一致性驗證

確認現有測試未與當前實作產生矛盾（測試通過但語意上與實作衝突即判定為問題）：

| 檢查項目 | 判定標準 |
|---------|---------|
| **(a) 已移除的 UI 元素 / API 端點** | 若測試中仍斷言已移除的 UI 元素或 API 端點存在 → FAIL |
| **(b) 行為變更反映在測試更新中** | 若 Story 描述的行為變更已實作，但對應測試仍驗證舊行為 → FAIL |

**偵測方式（「測試通過但與實作矛盾」）**：
- 搜尋測試檔中引用的 API 路徑、UI 選擇器、函式名稱是否在當前實作中仍存在
- 比對 Story 的 AC 描述（行為變更）與測試的斷言內容，確認兩者一致

**FAIL 判定**：任一檢查項目發現測試與實作語意矛盾 → CQ-NEW-2 FAIL。

---

## §1.15 非功能屬性審查清單（AC Review 時比對）

QA 在 Sprint Planning Round 3（AC 確認）與外部抽樣審查中，須檢查 Story 是否已定義非功能屬性，並於 Sprint Review 驗證實作是否符合所宣告的非功能標準。

### 非功能屬性審查觸發條件

以下任一情況均觸發非功能屬性審查：

1. Story Issue body 含 `## 非功能性需求` 欄位且有填寫 NFR 條目
2. Story 描述涉及資料擷取、外部 API 呼叫、使用者介面或效能敏感操作

### 非功能屬性檢查清單

QA 在 AC Review 時逐一比對：

| # | 屬性類型 | 審查項目 | 判定標準 |
|---|---------|---------|---------|
| N1 | **freshness（資料新鮮度）** | Story 涉及動態資料時，是否定義資料的時效性要求（如「過去 24 小時」） | 有定義且可量化 → PASS；未定義但功能明顯依賴新鮮資料 → 要求 PO 補充 |
| N2 | **completeness（完整性）** | 資料查詢或呈現類功能是否定義「不得遺漏」的覆蓋範圍要求 | 有定義涵蓋率或邊界條件 → PASS；無定義 → 建議補充 |
| N3 | **performance（效能）** | 使用者互動或 API 呼叫類功能是否定義回應時間或吞吐量指標 | 有具體可量化指標（如 P95 < 2s）→ PASS；僅描述「快速」等模糊詞 → 標記 AMBIGUOUS |
| N4 | **accessibility（無障礙）** | 前端 UI Story 是否定義無障礙合規標準（如 WCAG 2.1 AA）| 有標準引用 → PASS；前端 Story 未提及 → 提醒補充 |
| N5 | **reliability（可靠性）** | 涉及外部資源依賴的 Story 是否定義失敗降級或重試策略 | 有降級策略或可用率目標 → PASS；無定義 → 建議補充 |
| N6 | **security（安全性）** | 涉及外部輸入的 Story 是否定義輸入驗證或 XSS/Injection 防護要求 | 有對應安全 AC → PASS；缺失 → 標記 Security Review 必觸發 |

### 非功能屬性缺失的判定與處置

| 情況 | 嚴重度 | 處置 |
|------|-------|------|
| Story 明顯依賴非功能屬性（如新鮮資料、使用者輸入）但 `## 非功能性需求` 欄位為空或缺失 | Major | Sprint Planning Round 3 標記「**非功能屬性待補**」，退回 PO 補充後重新確認 |
| 非功能屬性已填寫但標準模糊（如「應有良好效能」） | Minor | 標記 AMBIGUOUS，要求 PO 補充可量化指標 |
| 非功能屬性已定義且可量化，實作與標準一致 | — | PASS，記錄於 Spec Compliance Review |
| 非功能屬性已定義但實作未達標（如效能測試超標）| Critical | Spec Compliance FAIL，問題分類 `[NFR-VIOLATION]` |

> **背景說明（US-251）**：本清單源自框架改進需求。原始問題案例：AC「新聞卡片顯示標題、連結、摘要」通過測試，但使用者期待「今天的新聞」（freshness 屬性），因未在 AC 中明確定義而被忽略。本清單確保此類隱性品質期待在 Sprint Planning 階段即被捕捉。

---

## §1.16 Smoke Test 要求：涉及外部資源的 Story

> 詳細規則：[`references/smoke-test.md`](references/smoke-test.md)

**觸發條件**：Story 涉及外部 API / RSS / Scraping / 雲端服務 / 外部認證時自動觸發。

**HARD-GATE**：CQ-SMOKE-2 FAIL（無 smoke test 且無 `[SMOKE-EXEMPT]` 標注）→ Code Quality Review 整體 FAIL。

---

## §1.17 Decision Table Testing（DTT）：多條件交叉邏輯分析

> 詳細規則：[`references/decision-table-testing.md`](references/decision-table-testing.md)

**觸發條件**：AC 包含 3 個以上獨立條件交叉影響結果時，Sprint Planning Round 3 自動觸發。

**輸出**：條件定義表、決策表、測試案例表、規則缺口疑問（阻塞項）。存在規則缺口 → AC 標記 AMBIGUOUS 退回 PO。

---

## §1.2 AC 驗證策略

> 詳細規則：[`references/ac-verification-strategy.md`](references/ac-verification-strategy.md)

AC 類型識別摘要：

| 類型 | 識別標準 | 測試要求 |
|------|---------|---------|
| `[靜態]` | 人工讀取文件/代碼即可驗證，無需執行命令 | 文件審查，無需自動化測試 |
| `[動態]` | 需執行 shell 命令或觸發 API 觀察輸出 | 至少 1 個自動化測試（Happy Path + Error Path） |
| `[行為]` | 多條件分支 + 使用者可觀察行為，適合 GWT 格式 | PO 補充 Given-When-Then 範例，實作須全覆蓋 |

**HARD-GATE**：`[動態]` AC 對應測試不存在 → Code Quality self-review 必須 FAIL。

---

## §2 Spec Compliance Review 決策

### 外部抽樣審查（External Sampling Review）中的執行原則

QA 在外部抽樣審查中扮演**獨立第三方**角色。必須遵循以下認知重設原則：
- 以全新視角直接讀取原始 AC，不預設 Story-Lifecycle subagent 自審結論正確
- 逐一核對每個 AC，不因「大部分通過」而跳過剩餘 AC
- 獨立讀取修改後的代碼/文件，不依賴 Story-Lifecycle subagent 的回傳摘要作為唯一信源

### 通過 vs 失敗判斷邊界

#### PASS 條件（所有以下條件均需滿足）

1. **所有 AC 逐條驗證通過**：每個 AC 的通過標準均有可觀察的對應實作
2. **靜態 AC 內容存在且可識別**：文件中可找到 AC 要求的段落、關鍵字、格式
3. **動態 AC 有對應測試且測試通過**：`[動態]` AC 有自動化測試，測試執行結果為通過
4. **邊界條件已處理**：AC 中明確列出的邊界條件有對應實作或說明
5. **無遺漏 AC**：Story AC 清單中的所有條目均已審查，無跳過

#### FAIL 條件（滿足任一即 FAIL）

1. **AC 條目缺失實作**：任一 AC 沒有對應的實作（即使其他 AC 均通過）
2. **實作偏離 AC 描述**：實作行為與 AC 通過標準不一致（例如 AC 要求「取上整」但實作使用四捨五入）
3. **關鍵字/段落缺失**：靜態 AC 要求特定識別字串存在，但在目標文件中找不到
4. **動態 AC 測試不存在或失敗**：`[動態]` AC 無對應測試，或測試執行失敗
5. **AC 數量不符**：Story 有 N 條 AC，但只有 N-1 條或更少有對應實作

**FAIL 嚴重度分級：**

| 嚴重度 | 觸發條件 | 處置 |
|-------|---------|------|
| Critical | 核心功能 AC 缺失，Story 主要目標未達成 | 必須修復，不得繼續下一個 Story |
| Major | 非核心 AC 缺失，但缺少後整體功能受損 | 必須修復 |
| Minor | 靜態格式 AC（如 YAML frontmatter 格式）不符但功能正確 | 應修復，但不阻塞執行 |

### DISPUTE 升級觸發條件

外部抽樣審查回傳 `DISPUTE` 的具體觸發條件：

| 觸發條件 | 說明 |
|---------|------|
| Story-Lifecycle 自審 PASS 但外部審查發現 AC 缺失 | 最常見的 DISPUTE 情境，直接觸發 DISPUTE |
| Story-Lifecycle 自審 PASS 但關鍵段落內容錯誤 | 如「取上整」vs「四捨五入」的語意差異 |
| Story-Lifecycle 自審 PASS 但必要識別字串缺失 | 靜態 AC 要求的關鍵字在文件中不存在 |
| Story-Lifecycle 自審 PASS 但動態 AC 測試全不存在 | TDD 流程未執行或測試未提交 |

**DISPUTE 輸出格式（完整缺陷清單）：**

```
## 外部抽樣審查結論

**Story ID**：US-#N
**結論**：DISPUTE
**自審結論**：PASS（Story-Lifecycle subagent 回傳）
**外部審查結論**：DISPUTE

**缺陷清單**：
1. [AC2 缺失] AC2 要求 `story-lifecycle-prompt.md` 包含 TC-1 獨立段落，但文件中僅在表格中提及，無獨立段落
2. [AC3 格式錯誤] AC3 要求路徑使用相對路徑，但實作使用絕對路徑
（每個缺陷均需明確指出：AC 編號、期望行為、實際行為）
```

---

## §3 Code Quality Review 策略

> 詳細規則：[`references/code-quality-review.md`](references/code-quality-review.md)

**包含以下子策略**（依序執行）：
- **通用靜態分析**：命名可讀性、函式長度 < 20 行、DRY、無 hardcoded secrets
- **CQ-MOCK**：Mock 假設真實性檢查（回應格式、資料範圍、錯誤情境覆蓋）— Story 含 mock 時自動觸發
- **CQ-DATA**：靜態資料覆蓋率驗證 — 資料集 > 100 條目時自動觸發
- **doc-only 豁免規則**：`skills/` 目錄 `.md` 不適用豁免
- **L-size 加強審查**：模組邊界、向後相容、回歸測試記錄、批次標記

**HARD-GATE**：CQ-DATA-2 FAIL（資料集實際條目數 < AC 目標）→ Story 禁止標記為完成。

---

## §4 QA Engineer Refinement 職責

<!-- US-203 角色 Refinement 職責定義 — Sprint 77 -->

QA Engineer 在 Refinement 中負責從測試與驗收標準的角度評估 Story 的就緒程度，確保 AC 在 Story 進入 Sprint 前已具備可測試條件。QA 在 Refinement 中為**諮詢（Consulted）**角色，輸出 AC 可測試性評估意見。

### 職責說明

| 面向 | 職責內容 |
|------|---------|
| **AC 可測試性預評** | 針對 Story 草稿中的每個 AC，評估是否具備明確可觀察的通過標準（避免進 Sprint 後發現 AC 無法驗收）|
| **測試策略初評** | 識別 AC 類型（`[靜態]` / `[動態]` / `[行為]`），判斷哪些 AC 需自動化測試覆蓋 |
| **安全相關 AC 識別** | 若 Story 涉及外部輸入、認證或授權，提醒 AC 中需補充對應的安全驗收條件 |
| **AC 完整性建議** | 指出遺漏的錯誤路徑 AC、邊界條件 AC，建議補充至 Story 草稿 |
| **DTT 預識別** | 若 Story 草稿 AC 含 3 個以上條件交叉，預警 Sprint Planning Round 3 將觸發 DTT 分析，提醒 PO 準備業務規則釐清 |

### Refinement 輸出

QA 在 Refinement 中輸出以下結構化意見（可以表格或條列形式提供給 Architect 記錄於 Refinement 報告備注中）：

| 輸出項目 | 說明 |
|---------|------|
| AC 可測試性評估表 | 逐條列出每個 AC 的可測試性判定：TESTABLE / AMBIGUOUS / UNTESTABLE，含具體說明 |
| 測試覆蓋初估 | 初步列出哪些 AC 需自動化測試（`[動態]`）、哪些僅需文件審查（`[靜態]`） |
| 補充 AC 建議（若有） | 列出建議補充的錯誤路徑或邊界條件 AC，供 PO 在 Refinement 後更新 Story 草稿 |
| DTT 規則缺口清單（若觸發） | 多條件交叉 AC 觸發 DTT 時，附上 §1.17 Part 4 規則缺口疑問，缺口項目狀態標記為 AMBIGUOUS |

**AC 可測試性判定標準：**

| 判定 | 條件 |
|------|------|
| TESTABLE | AC 通過標準具體且可觀察，QA 可在 Sprint 中明確驗證 |
| AMBIGUOUS | AC 描述模糊（如「應有良好效能」），需 PO 補充具體指標後方可進入 Sprint |
| UNTESTABLE | AC 依賴外部不可控因素，或通過標準在技術上無法驗證，需 PO + Architect 重新設計 |

**AMBIGUOUS / UNTESTABLE 處置**：QA 在 Refinement 中提出後，由 Architect 在 Refinement 報告 Q4（Contract Owner 確認）或 Q5（完成性評估）備注阻塞原因；PO 更新 AC 後重新進入 Refinement 評估。

---

## §5 Sprint Review 探索性測試職責

> 詳細規則：[`references/exploratory-testing.md`](references/exploratory-testing.md)

QA 在 Happy Path Demo 後主導邊界案例測試，依業務背景從以下類別選取 **至少 3 個**邊界案例：

| 類別 | 典型案例 |
|------|---------|
| CJK 字符邊界 | 生僻字、全半形混用、簡繁體混用 |
| 空值與缺失值 | `""`、`null`、僅含特殊字元 |
| 時間邊界 | 跨日/月/年、Unix Epoch、時區換算 |
| 長度與大小 | 超長字串、超大數值、空集合 |
| 安全邊界 | XSS、SQL 注入、路徑穿越（涉及外部輸入時必選） |

**HARD-GATE**：安全邊界 FAIL → 立即升級為 Security Issue，中止驗收。

---

## 參照文件

- **ADR-003**：`docs/adr/ADR-003.md`（Framework Document Change，skills/ 路徑修改需執行 Checklist）
- **ADR-006**：`docs/adr/ADR-006-prompt-injection-protection.md`（Prompt Injection Isolation Rule，安全相關 AC 審查依據）
- **ADR-007**：`docs/adr/ADR-007-story-lifecycle-subagent.md`（Story-Lifecycle Subagent 封裝，外部抽樣審查機制定義）
- **sprint-execution/SKILL.md**：`skills/sprint-execution/SKILL.md`（Sprint Execution 流程，含 §4 CONFIRM/DISPUTE 處理路徑）
- **sprint-planning/SKILL.md**：`skills/sprint-planning/SKILL.md`（Sprint Planning 流程，含路徑驗證規則與防漂移約束）
- **story-lifecycle-prompt.md**：`skills/sprint-execution/story-lifecycle-prompt.md`（Story-Lifecycle Subagent Prompt，含 §5 Spec Compliance 與 §6 Code Quality 自審清單）
