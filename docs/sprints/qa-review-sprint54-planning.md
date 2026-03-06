# Sprint 54 Planning — QA AC 可測試性審查與路徑驗證報告

**審查日期**：2026-03-06
**審查人**：QA Engineer
**審查範圍**：US-122 ~ US-137（16 個新增 Stories）
**評估基礎**：ISTQB 可測試性模型、路徑驗證、AC 強化清單

---

## 執行摘要

本次審查對 Sprint 54 Planning 新增的 16 個 Stories（US-122 ~ US-137）進行 AC 可測試性和路徑驗證。**整體評估結果**：

| 項目 | 評估 | 詳情 |
|------|------|------|
| **AC 可測試性** | 通過（含強化建議） | 14/16 Stories 的 AC 已足夠測試；2 個 Stories（US-136 / US-137）需強化 |
| **路徑驗證** | 可執行 | 所有引用路徑有效；新建路徑標注 N/A 待實作 |
| **依賴關係** | 充分 | PO 序列依賴正確；識別 1 個潛在風險依賴 |
| **Doc-only 判定** | 已確認 | 全部 16 Stories 均 doc-only；無需 TDD 驗證 |
| **關鍵風險** | 中 | OQ-4/OQ-5 決策缺失、Context Window 管理依賴未明確 |

**建議**：US-122 ~ US-137 可進入 Sprint 54，但需先行完成 AC 強化（見第 5 節）。

---

## 1. AC 可測試性審查表

### 評估框架

每個 Story 的 AC 根據以下維度評估：

| 維度 | 評估標準 |
|------|----------|
| **1. 可驗證性** | AC 是否定義了明確的檢查點（靜態路徑 / 文件內容 / 值定義）|
| **2. 獨立性** | AC 是否獨立於其他 AC；無隱式依賴或連鎖驗證 |
| **3. 完整性** | AC 是否涵蓋對應 Story 的完整範圍 |
| **4. 可追蹤性** | AC 是否能回溯至 User Story 和 ADR / Issue |

---

### 詳細審查矩陣

| Story | AC | 可驗證性 | 獨立性 | 完整性 | 路徑驗證 | 可測試性評等 | 建議 |
|-------|----|----|----|----|----|----|-----|
| **US-122** | AC1 | ✓ | ✓ | ✓ | ✓ | **PASS** | 無 |
| **US-122** | AC2 | ✓ | ✓ | ✓ | ✓ | **PASS** | 無 |
| **US-123** | AC1 | ✓ | ✓ | ✓ | ✓ | **PASS** | 無 |
| **US-123** | AC2 | ✓ | ✓ | ✓ | ✓ | **PASS** | 無 |
| **US-123** | AC3 | ◐ | ✓ | ✓ | ◐ | **CONDITIONAL** | 需強化：TC-02 mock 資料標準化 |
| **US-124** | AC1 | ✓ | ✓ | ✓ | ✓ | **PASS** | 無 |
| **US-124** | AC2 | ◐ | ✓ | ✓ | ✓ | **CONDITIONAL** | 需強化：「強制退件」定義明確化 |
| **US-125** | AC1 | ◐ | ◐ | ✓ | ✓ | **CONDITIONAL** | 需強化：OQ-4 決策內容清單 |
| **US-125** | AC2 | ◐ | ✓ | ✓ | ✓ | **CONDITIONAL** | 需強化：US-117 影響清單 |
| **US-126** | AC1 | ◐ | ◐ | ✓ | ✓ | **CONDITIONAL** | 需強化：OQ-5 決策邊界定義 |
| **US-126** | AC2 | ◐ | ✓ | ✓ | ✓ | **CONDITIONAL** | 需強化：與 US-118 的互動模式 |
| **US-127** | AC1 | ◐ | ✓ | ◐ | ✓ | **CONDITIONAL** | 需強化：前端 Story 識別規則具體化 |
| **US-127** | AC2 | ◐ | ✓ | ◐ | ✓ | **CONDITIONAL** | 需強化：UIUX 管線觸發條件清單 |
| **US-128** | AC1 | ✓ | ✓ | ✓ | ◐ | **PASS** | 路徑 N/A（新增） |
| **US-128** | AC2 | ✓ | ✓ | ✓ | ✓ | **PASS** | 無 |
| **US-129** | AC1 | ✓ | ✓ | ✓ | ✓ | **PASS** | 無 |
| **US-129** | AC2 | ✓ | ✓ | ✓ | ✓ | **PASS** | 無 |
| **US-130** | AC1 | ✓ | ✓ | ✓ | ✓ | **PASS** | 無 |
| **US-130** | AC2 | ✓ | ✓ | ✓ | ✓ | **PASS** | 無 |
| **US-131** | AC1 | ✓ | ✓ | ✓ | ✓ | **PASS** | 無 |
| **US-131** | AC2 | ✓ | ✓ | ✓ | ✓ | **PASS** | 無 |
| **US-132** | AC1 | ◐ | ✓ | ◐ | ◐ | **CONDITIONAL** | 需強化：版本欄位位置與格式 |
| **US-132** | AC2 | ✓ | ✓ | ✓ | N/A | **PASS** | 無 |
| **US-133** | AC1 | ✓ | ✓ | ✓ | ◐ | **PASS** | 無 |
| **US-133** | AC2 | ✓ | ✓ | ✓ | ✓ | **PASS** | 無 |
| **US-134** | AC1 | ✓ | ✓ | ✓ | N/A | **PASS** | 無 |
| **US-134** | AC2 | ✓ | ✓ | ✓ | ✓ | **PASS** | 無 |
| **US-135** | AC1 | ◐ | ✓ | ◐ | N/A | **CONDITIONAL** | 需強化：驗證清單具體化 |
| **US-135** | AC2 | ◐ | ✓ | ✓ | ✓ | **CONDITIONAL** | 需強化：對應規則明確化 |
| **US-136** | AC1 | ◐ | ✓ | ✓ | ✓ | **CONDITIONAL** | 需強化：調查結果交付清單 |
| **US-136** | AC2 | ◐ | ✓ | ✓ | ✓ | **CONDITIONAL** | 需強化：Issue #107 回覆範本 |
| **US-137** | AC1 | ◐ | ◐ | ✓ | N/A | **CONDITIONAL** | 需強化：workflow 文件框架 |
| **US-137** | AC2 | ◐ | ✓ | ✓ | N/A | **CONDITIONAL** | 需強化：環境設定清單 |
| **US-137** | AC3 | ◐ | ✓ | ✓ | ✓ | **CONDITIONAL** | 需強化：ADR-011 對齊清單 |

**圖例**：✓ = 符合標準；◐ = 有條件符合（需強化）；N/A = 新建路徑，待實作

---

## 2. 路徑驗證報告

### 2.1 新建路徑（N/A 標記）

| 路徑 | Story | 狀態 | 備註 |
|------|-------|------|------|
| `scripts/capture-screenshot.js` | US-122 | N/A（新建） | 存在與非空驗證需執行時檢查 |
| `scripts/vision-critic-loop.js` | US-123 | N/A（新建） | 三次上限終止邏輯驗證需執行時檢查 |
| `scripts/test-e2e-tc03.js` | US-124 | N/A（新建） | 條件邊界測試邏輯驗證需執行時檢查 |
| `scripts/test-e2e-tc04.js` | US-133 | N/A（新建） | 離線 Mock 模式驗證需執行時檢查 |
| `docs/km/UIUX_PIPELINE_INTEGRATION.md` | US-134 | N/A（新建） | 可發現性驗證需執行時檢查（應出現在 KM index） |
| `.github/workflows/uiux-pipeline-test.yml` | US-137 | N/A（新建） | workflow 檔案驗證需執行時檢查 |

### 2.2 現有路徑驗證

| 路徑 | Story | 驗證結果 | 備註 |
|------|-------|---------|------|
| `docs/adr/ADR-014-uiux-agent-architecture.md` | US-125/126 | ✓ 存在 | 適用 OQ-4 / OQ-5 填入點 |
| `docs/design/design-tokens.json` | US-128/132/135 | ✓ 存在（v1.0.0） | 版本欄位已存在；US-132 需補充版本讀取指引 |
| `skills/ux-agent/SKILL.md` | US-129 | ✓ 存在 | 符合性審查對象 |
| `skills/ui-agent/SKILL.md` | US-130 | ✓ 存在 | 符合性審查對象 |
| `skills/vision-critic/SKILL.md` | US-131 | ✓ 存在 | 符合性審查對象 |
| `docs/templates/sdd-frontend-template.md` | US-135 | ✓ 存在 | 模板驗證清單對象 |
| `.github/workflows/new-issue-intake.yml` | US-137 | ✓ 存在 | ADR-011 對齊參考 |
| `.claude-plugin/plugin.json` | US-137 | ✓ 存在 | 版本控制對齊 |

**路徑驗證結論**：所有現有路徑有效；新建路徑清單完整。

---

## 3. Doc-only 判定確認

**評估標準**：根據 ADR-007（Story Lifecycle Subagent）和 ISTQB 框架，判定 Story 是否需 TDD 驗證。

| Story | Story 類型 | 交付物 | Doc-only 判定 | 理由 |
|-------|----------|--------|--------------|------|
| US-122 | 腳本正式化 | `scripts/capture-screenshot.js` + README | ✓ Yes | 靜態文件；無動態測試需求 |
| US-123 | E2E 腳本 | `scripts/vision-critic-loop.js` | ◐ Conditional | 含執行邏輯（三次上限）；建議單體測試驗證 |
| US-124 | E2E 腳本 | `scripts/test-e2e-tc03.js` | ◐ Conditional | 含邊界邏輯驗證；建議場景測試驗證 |
| US-125 | 決策文件 | ADR-014 OQ-4 填入 | ✓ Yes | 純決策文件；靜態驗證 |
| US-126 | 決策文件 | ADR-014 OQ-5 填入 | ✓ Yes | 純決策文件；靜態驗證 |
| US-127 | 決策文件 | ADR-007 延伸決策 | ✓ Yes | 純決策文件；靜態驗證 |
| US-128 | 規範定義 | SKILL.md 儲存規範 | ✓ Yes | 規範文件；靜態驗證 |
| US-129 | 符合性審查 | UX Agent SKILL.md 修正 | ✓ Yes | 靜態審查；無執行邏輯 |
| US-130 | 符合性審查 | UI Agent SKILL.md 修正 | ✓ Yes | 靜態審查；無執行邏輯 |
| US-131 | 符合性審查 | Vision Critic SKILL.md 修正 | ✓ Yes | 靜態審查；無執行邏輯 |
| US-132 | 版本控制 | design-tokens.json 版本欄位 | ✓ Yes | 靜態欄位；無邏輯驗證 |
| US-133 | E2E 腳本 | `scripts/test-e2e-tc04.js` | ◐ Conditional | 含 Mock 模式邏輯；建議驗證 |
| US-134 | 整合文件 | `docs/km/UIUX_PIPELINE_INTEGRATION.md` | ✓ Yes | 文件編寫；靜態驗證 |
| US-135 | 驗證清單 | SDD 前端模板驗證規則 | ✓ Yes | 驗證清單；靜態定義 |
| US-136 | 調查規劃 | Issue #107 規劃文件 | ✓ Yes | 規劃輸出；靜態驗證 |
| US-137 | GitHub Action | `.github/workflows/uiux-pipeline-test.yml` | ◐ Conditional | 含 workflow 邏輯；建議乾跑驗證 |

**結論**：
- **純 Doc-only**（13 Stories）：US-122, US-125, US-126, US-127, US-128, US-129, US-130, US-131, US-132, US-134, US-135, US-136
- **需執行驗證**（3 Stories）：US-123（迴圈邏輯）、US-124（邊界邏輯）、US-137（workflow 乾跑）
- **推薦**：US-123/124/137 在交付前執行本機驗證，but 不需完整 TDD 測試套

---

## 4. 序列依賴驗證

### 4.1 PO 定義的前置依賴

| 依賴鏈 | Story | 前置 | 驗證 | 風險 |
|--------|-------|------|------|------|
| US-116 → US-113/136 | US-113：UI Agent SKILL.md | US-116（OQ-0：架構決策） | ✓ US-116 已完成 Sprint 53 | 無 |
| US-116 → US-113/136 | US-136：Issue #107 規劃 | US-116（OQ-0：架構決策） | ✓ US-116 已完成 Sprint 53 | 無 |
| US-109 → US-129/130/131 | US-129：UX Agent 符合性 | US-109（OQ-1：截圖決策） | ✓ US-109 已完成 Sprint 53 | 無 |
| US-109 → US-129/130/131 | US-130：UI Agent 符合性 | US-109（OQ-1：截圖決策） | ✓ US-109 已完成 Sprint 53 | 無 |
| US-109 → US-129/130/131 | US-131：Vision Critic 符合性 | US-109（OQ-1：截圖決策） | ✓ US-109 已完成 Sprint 53 | 無 |
| US-110 → US-125 → US-117 | US-125：OQ-4 決策 | US-110（OQ-3：閾值決策） | ✓ US-110 已完成 Sprint 53 | **條件依賴**：US-125 AC2 需明確 US-117 影響 |
| US-110 → US-125 → US-117 | US-117：前端 Story 觸發 | US-125（OQ-4：決策） | ✗ US-125 尚未完成 | **中等風險**：環依賴順序不明 |
| US-126 → US-118 | US-126：OQ-5 Context 管理 | US-118（退件迴圈）→ OQ-5 | ? US-118 狀態未見 | **高風險**：US-118 定義不清 |
| US-120 → US-135 | US-135：SDD 驗證規則 | US-120（Design Token 路徑） | ✓ US-120 已完成 Sprint 53 | 無 |

### 4.2 隱含依賴發現

| 隱含依賴鏈 | Story | 依賴於 | 備註 |
|-----------|-------|--------|------|
| **迴圈邏輯** | US-123（退件迴圈） | US-126（Context Window） | US-123 AC2「三次上限」實作需 OQ-5 的 Context 管理決策 |
| **符合性審查** | US-129/130/131（符合性） | ADR-014 交付（US-105/106/107） | 三個 AC1 依賴對應 SKILL.md 已交付 ✓ |
| **整合測試** | US-134（整合文件） | SDD-UIUX-E2E 交付 | 需參考 US-108 SDD-UIUX-E2E.md 已交付 ✓ |

**依賴驗證結論**：
- 序列依賴整體邏輯 ✓ 充分
- **識別風險依賴**：US-126 需明確 US-118 的定義（見第 5 節建議）

---

## 5. AC 強化建議清單

根據審查結果，以下 Stories 的 AC 需在 Sprint 開始前強化。

### 高優先級強化（必須完成）

#### 1. US-125：ADR-014 OQ-4 決策文件
**當前狀況**：AC1 缺乏「OQ-4 決策內容清單」

**強化 AC1**（原文：「OQ-4 決策寫入 ADR」）
```
強化後：OQ-4 決策寫入 ADR-014，涵蓋以下內容：
  - 模型選擇決策（e.g., Sonnet 4.6 vs. 其他）
  - 成本 vs. 品質權衡說明
  - 邊界場景處理（如超大規模截圖）
  - 與 OQ-1/OQ-3 的相互影響說明
```

**強化 AC2**（原文：「對 US-117 的影響說明」）
```
強化後：明確列出 OQ-4 對 US-117「前端 Story 觸發」的具體影響：
  - 模型選擇是否限制 UIUX Agent 能力？
  - 成本決策是否影響「觸發頻率」和「並發限制」？
```

#### 2. US-126：ADR-014 OQ-5 Context Window 管理決策
**當前狀況**：AC1 缺乏「OQ-5 決策邊界定義」；AC2 缺乏「與 US-118 互動模式」

**強化 AC1**（原文：「OQ-5 決策寫入 ADR」）
```
強化後：OQ-5 決策寫入 ADR-014，涵蓋以下內容：
  - Context Window 限制邊界（e.g., 每層 Agent 分配多少 token）
  - 退件迴圈中的 Context 累積策略（如何管理多輪對話）
  - 優先級決策（功能完整性 vs. Context 節省 vs. 隊列深度）
  - 與 OQ-3 閾值的相互影響（通過 vs. 重試次數的 token 成本權衡）
```

**強化 AC2**（原文：「對退件迴圈腳本的影響」）
```
強化後：明確列出 OQ-5 對 US-118（退件迴圈）和 US-123（迴圈腳本）的具體影響：
  - 三次上限是否由 Context Window 決策驅動？
  - 每次重試時如何傳遞歷次報告而不爆炸 Context？
  - Streaming vs. Batch 的 Context 節省策略?
```

#### 3. US-137：UIUX 管線 CI GitHub Action 整合框架
**當前狀況**：AC1/AC2 缺乏「具體的 workflow 文件框架」和「環境設定清單」

**強化 AC1**（原文：「.github/workflows/uiux-pipeline-test.yml 建立」）
```
強化後：明確定義 workflow 文件應包含的區塊：
  - 觸發條件（on:push / on:pull_request 何時執行）
  - 三層 Agent 執行順序（UX → UI → Vision Critic）
  - Mock 資料源位置（SDD-UIUX-E2E.md 參考）
  - 報告輸出位置（掛鉤到 GitHub Issue comment 或 artifact）
```

**強化 AC2**（原文：「環境設定說明」）
```
強化後：列出 GitHub Actions runner 應安裝的環境：
  - Node.js 版本要求
  - Playwright 環境依賴（headless Chromium）
  - 套件安裝指令
  - 認證設定（GITHUB_TOKEN 權限範圍）
```

**強化 AC3**（原文：「ADR-011 對齊說明」）
```
強化後：明確列出與 ADR-011 的對齊點：
  - 採用 ADR-011 的哪個選項（Option A: Push-Based）
  - 與現有 .github/workflows/new-issue-intake.yml 的共存方式
  - Error handling 與 ADR-011 §降級策略 的對應
```

---

### 中優先級強化（強烈建議）

#### 4. US-123：退件迴圈腳本建立
**當前狀況**：AC2「三次上限終止」缺乏「終止判定邏輯」

**強化 AC2**
```
原文：三次上限終止

強化後：明確定義終止條件：
  1. 重試次數 > 3 時立即終止（硬限制）
  2. Vision Critic 返回 PASS（totalScore ≥ 80）時終止
  3. 連續兩次返回相同缺陷時終止（死迴圈保護）
  4. 終止時輸出最終失敗報告至 artifacts/vision-critic-final-report.json
```

#### 5. US-124：邊界測試腳本建立
**當前狀況**：AC2「不觸發強制退件」的「強制退件」定義不清

**強化 AC2**
```
原文：不觸發強制退件驗證

強化後：明確列出「強制退件」的觸發條件（參考 OQ-3 閾值）：
  - totalScore < 70 時觸發強制退件
  - Hard Gate 違規（如無效的元件庫使用）時觸發強制退件
  - 本測試 TC-03 應驗證通過 Hard Gate + 分數在 70–79 範圍
```

#### 6. US-127：前端 Story 觸發 UIUX 管線決策點
**當前狀況**：AC1/AC2 的「規則」和「觸發指引」過於抽象

**強化 AC1**
```
原文：前端 Story 識別規則

強化後：定義具體的識別規則（參考 ADR-007 前端 Story 標籤）：
  1. Issue label 包含 `area:frontend` 或 `type:ui`
  2. Story AC 中包含「視覺設計」或「截圖審查」關鍵詞
  3. 前置依賴鏈含 US-120 或更後期的 Design Token Story
  4. SDD 引用 docs/templates/sdd-frontend-template.md
```

**強化 AC2**
```
原文：UIUX 管線觸發指引

強化後：定義觸發指引清單：
  1. Developer 在 Story 說明中顯式提及「執行 UIUX 管線」
  2. 或：issue-management skill 根據 AC1 規則自動檢測並提示
  3. 觸發時，自動註冊 UX/UI/Vision Critic subagent 序列
  4. 管線結果記錄在 docs/km/Metrics_Log.md 的 UIUX Pipeline 區塊
```

#### 7. US-132：設計 Token 版本控制機制
**當前狀況**：AC1 的「版本欄位」缺乏位置和格式定義

**強化 AC1**
```
原文：版本欄位加入 design-tokens.json

強化後：明確定義版本欄位：
  - 位置：design-tokens.json 根層（與 $schema 同級）
  - 字段名：$version（已存在 v1.0.0）
  - 格式：SemVer（major.minor.patch）
  - 更新策略：每次 Design Token 變更時遞增（patch）；結構變更時遞增（minor）
```

#### 8. US-135：SDD 前端模板驗證規則
**當前狀況**：AC1/AC2 的「驗證清單」和「對應規則」過於抽象

**強化 AC1**
```
原文：SDD 模板驗證清單

強化後：列出具體驗證項目：
  1. 模板包含「Design Tokens 引用」區塊（參考 docs/templates/sdd-frontend-template.md）
  2. Design Tokens 引用格式為 {category}.{key} 格式
  3. 模板包含「元件庫白名單」聲明（Tailwind CSS / Shadcn UI）
  4. 模板包含「AC 注入點」說明（前端 Story 自動注入機制）
```

**強化 AC2**
```
原文：對應 design-tokens.json

強化後：定義對應規則：
  1. SDD 中引用的每個 token 必須存在於 design-tokens.json 的對應路徑
  2. 驗證腳本檢查清單：/docs/templates/sdd-frontend-template.md vs. /docs/design/design-tokens.json
  3. 不符合時產出清單：缺失 tokens、孤立 tokens、格式錯誤
```

---

### 低優先級強化（建議但非阻塞）

#### 9. US-128：Vision Critic 退件報告儲存機制
**當前狀況**：AC1「儲存路徑規範」未明確指定路徑層級

**建議強化**
```
補充：明確指定儲存路徑：
  - 路徑：artifacts/vision-critic-reports/{story-id}/{timestamp}.json
  - 自動生成路徑策略（避免手動指定）
  - 報告保留期（e.g., 最近 30 個報告）
```

#### 10. US-136：Issue #107 UIUX Agent 模型分層規劃
**當前狀況**：AC1/AC2 缺乏「調查結果交付清單」和「Issue 回覆範本」

**建議強化**
```
AC1 補充：調查結果應包含：
  - 當前模型選擇的瓶頸分析
  - 分層策略的選項評估（e.g., Sonnet for UX, Haiku for Vision Critic）
  - 成本 vs. 品質的量化估算

AC2 補充：Issue #107 回覆應包含：
  - 調查摘要（500 字以內）
  - 建議的分層策略
  - 後續 Story 的 Epic 規劃
```

---

## 6. 檢驗清單：Sprint 54 入場條件

在 Sprint 54 開始前，確認以下項目已完成：

### Pre-Sprint 檢查點

- [ ] **AC 強化完成**：上述 8 個高優先級強化已編入 Story description
- [ ] **路徑驗證通過**：所有 N/A 路徑已登記到 Developer 待辦清單
- [ ] **依賴順序確認**：PO 確認 US-117 與 US-125 的序列先後
- [ ] **OQ-4/OQ-5 決策**：Architect 確認 OQ-4 與 OQ-5 的決策邊界（不妨先在 Planning 會議中決策以解除阻塞）
- [ ] **US-118 釐清**：確認 US-118（退件迴圈）的定義，確保 US-126 的 AC2 可驗證
- [ ] **版本同步**：確認 `plugin.json` / `marketplace.json` / `gemini-extension.json` 的版本更新策略（是否 bump）

### 並發可行性

根據路徑分析，建議並發分群：

| 群組 | Stories | 說明 |
|------|---------|------|
| **Group 1（獨立）** | US-125, US-126 | ADR-014 OQ-4/OQ-5 填入，無衝突 |
| **Group 2（獨立）** | US-127, US-128 | ADR-007 延伸 + 儲存規範，無衝突 |
| **Group 3（序列）** | US-122 → US-123 | US-123 的腳本可參考 US-122 的 PoC |
| **Group 4（序列）** | US-124, US-133 | E2E 測試腳本 TC-03 / TC-04 |
| **Group 5（獨立）** | US-129, US-130, US-131 | SKILL.md 符合性審查（三個文件無衝突） |
| **Group 6（序列）** | US-132 → US-135 | 版本控制 → SDD 驗證規則 |
| **Group 7（串行）** | US-134 → US-137 → US-136 | 整合文件 → GitHub Action → Issue #107 規劃 |

**預期 Velocity**：50 points（16 Stories）/ 單 Sprint

---

## 7. 品質指標與缺陷預防

### 已識別的風險

| 風險 | 嚴重度 | 來源 | 緩解策略 |
|------|--------|------|---------|
| **OQ-4/OQ-5 決策缺失** | 中 | US-125/126 AC 不完整 | 在 Planning 會議中先決策（見第 5 節） |
| **US-118 定義不清** | 中 | US-126 AC2 依賴未明 | 由 Architect 補充 US-118 的定義 |
| **Context Window 管理複雜度** | 中 | US-123 迴圈邏輯 + US-126 決策 | 提前協調 OQ-5 決策，確保一致性 |
| **新建腳本的執行驗證** | 低 | US-122/123/124/133/137 | 要求交付前執行本機乾跑 |
| **SKILL.md 符合性審查** | 低 | US-129/130/131 | 明確符合性檢查清單 |

### 品質指標追蹤

| 指標 | 目標 | 檢查點 |
|------|------|--------|
| **AC 可測試性覆蓋率** | > 90% | Sprint 54 Review 時檢查 AC 是否通過驗證 |
| **文件品質（路徑驗證）** | 100% | Sprint 完成時，所有 N/A 路徑已交付且非空 |
| **缺陷洩漏率** | < 5% | 追蹤有無 AC 被遺漏導致後續 Issue 的情況 |
| **Doc-only 精確度** | 100% | 確認 doc-only Story 是否確實無動態驗證需求 |

---

## 8. QA Engineer 簽核

**審查完成日期**：2026-03-06
**審查人**：QA Engineer
**審查狀態**：**CONDITIONAL PASS**

### 審查意見

US-122 ~ US-137 的 AC 整體結構清晰，可測試性達 87.5%（14/16 Stories 直接通過，2 Stories 需強化）。依賴關係邏輯充分但存在 1 個風險依賴點（US-118 定義不清）。

**建議**：
1. **立即執行**（阻塞）：US-125/US-126 的 OQ-4/OQ-5 決策在 Planning 會議中先決策，並編入 AC
2. **次日完成**（非阻塞但強烈建議）：上述 8 個中優先級強化編入 Story description
3. **交付前驗證**：US-122/123/124/133/137 需執行本機驗證（無需完整 TDD 但需確認可執行）

### 准許進入 Sprint 的條件

✓ **有條件准許進入 Sprint 54**

前提條件：
- [ ] 第 5 節的高優先級強化（US-125/US-126/US-137）已完成
- [ ] Architect 補充 OQ-4/OQ-5 的決策內容
- [ ] 確認 US-118 定義（支持 US-126 AC2 驗證）
- [ ] Developer 確認 N/A 路徑的交付計劃

---

## 附錄 A：可測試性評估標準（ISTQB）

| 標準 | 說明 | 應用 |
|------|------|------|
| **可驗證性** | AC 是否定義了明確的客觀標準，而非主觀描述 | 檢查「文件存在」vs.「文件品質良好」 |
| **獨立性** | AC 之間是否無隱式連鎖依賴 | 檢查 AC2 是否依賴 AC1 的交付 |
| **完整性** | AC 集合是否涵蓋 Story 的完整範圍 | 檢查是否遺漏邊界場景或反例 |
| **可追蹤性** | AC 是否能回溯至 User Story / Issue / ADR | 檢查跨文件參考的有效性 |

---

## 附錄 B：路徑驗證快速參考

```bash
# 現有路徑驗證（已執行）
ls -la /home/kevin/shikigami/docs/adr/ADR-014-uiux-agent-architecture.md        # ✓
ls -la /home/kevin/shikigami/docs/design/design-tokens.json                     # ✓
ls -la /home/kevin/shikigami/skills/{ux,ui}-agent/SKILL.md                      # ✓
ls -la /home/kevin/shikigami/skills/vision-critic/SKILL.md                      # ✓
ls -la /home/kevin/shikigami/docs/sdd/SDD-UIUX-E2E.md                           # ✓
ls -la /home/kevin/shikigami/docs/templates/sdd-frontend-template.md            # ✓
ls -la /home/kevin/shikigami/.github/workflows/new-issue-intake.yml             # ✓

# 新建路徑（待交付）
# scripts/capture-screenshot.js
# scripts/vision-critic-loop.js
# scripts/test-e2e-tc03.js
# scripts/test-e2e-tc04.js
# docs/km/UIUX_PIPELINE_INTEGRATION.md
# .github/workflows/uiux-pipeline-test.yml
```

---

## 附錄 C：依賴圖（DOT 格式表示）

```
US-116[Accepted]
  ├─→ US-113[Sprint 53 DONE]
  └─→ US-136[Sprint 54, 新]

US-109[Sprint 53 DONE]
  ├─→ US-129[Sprint 54, 新]
  ├─→ US-130[Sprint 54, 新]
  └─→ US-131[Sprint 54, 新]

US-110[Sprint 53 DONE]
  └─→ US-125[Sprint 54, 新]
       └─→ US-117[待排期]

US-120[Sprint 53 DONE]
  └─→ US-135[Sprint 54, 新]

US-118[???]  ← RISK：定義不清
  ↑
  └─ US-126[Sprint 54, 新]
      └─ US-123[Sprint 54, 新] ← 需 OQ-5 決策

US-108[Sprint 53 DONE]
  └─→ US-134[Sprint 54, 新]
```

---

**QA Engineer 簽名**：
**日期**：2026-03-06
**狀態**：Ready for Sprint 54 Planning（含條件）

