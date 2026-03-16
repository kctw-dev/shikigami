# Product Brief：互動式審查模式（Interactive Review Mode）

---

## 基本資訊

| 欄位 | 內容 |
|------|------|
| Brief ID | PB-2026-03-15-interactive-review-mode |
| 功能名稱 | 互動式審查模式（Interactive Review Mode） |
| 作者 | PO |
| 建立日期 | 2026-03-15 |
| 狀態 | **草稿** |
| 觸發來源 | Issue #271 — gstack vs Shikigami 競品分析（第 5 章，中價值項目） |
| 關聯 Skill | quality-gate、sprint-execution |

---

## Discovery Phase — Step 1：背景分析

### 核心發現（來自 Issue #271）

Issue #271 競品分析指出，gstack 的 `/plan-eng-review` 採用「逐一問問題帶 A/B/C 選項」的互動模式，對每個重要決策點提問並等待使用者選擇，而非一次輸出長篇報告。

相比之下，Shikigami 的 quality-gate 當前行為是：QA Agent 執行完整審查後，產出一份審查報告（PASS/FAIL + 問題清單），使用者只能接受全部結果或退回重做，沒有中間互動點。

Issue #271 建議可借鑑此模式，用於 quality-gate 的 CRITICAL issue 處理：當 QA Agent 發現 CRITICAL 問題時，不是直接 FAIL 並終止，而是向使用者提出 A/B/C 選項（如「修復後繼續 / 降級為 Important / 標記為已知問題並繼續」），讓使用者主動決策。

### 現有流程缺口

查閱 `skills/quality-gate/SKILL.md` 確認，當前 CRITICAL 缺陷處理為硬規則：

> 存在任何 Critical 缺陷 → 門禁 FAIL，必須修復後重新審查

這是一個 HARD-GATE，不存在使用者介入或決策點。在某些場景（如技術債管理、已知問題文件化、緊急發布場景），這個設計會造成流程中斷而無法繼續，或迫使使用者繞過 QA 機制。

---

## Discovery Phase — Step 2：假設外顯化（三問機制）

### 候選需求：互動式 CRITICAL 問題決策點

**問題 1：這個需求解決了什麼問題？**

當 quality-gate 發現 CRITICAL 問題時，使用者有時需要做出超越「修復或停止」的複雜決策（例如：接受已知風險並文件化、暫緩修復但加入技術債追蹤、調整問題嚴重度分類）。目前 HARD-GATE 設計不允許這類決策存在，使用者只能繞過整個 QA 機制（損失品質保護），或被迫中斷工作流程。

**問題 2：我們假設哪些事情是真的？**

| # | 假設 | 標籤 |
|---|------|------|
| A1 | 使用者確實遇到需要「接受已知 CRITICAL 風險並繼續」的場景，而非每次都是直接修復 | [UNCERTAIN] |
| A2 | 在 quality-gate 流程中加入互動決策點，不會降低整體品質水準（因為使用者主動選擇並文件化，比靜默繞過更安全） | [UNCERTAIN] |
| A3 | A/B/C 選項模式（取自 gstack `/plan-eng-review`）比自由輸入回覆對 Agent 的執行分支更清晰可控 | 假設成立（有界選項比自由輸入更易處理） |
| A4 | 互動式決策點只應出現在 CRITICAL 問題，而非 Important 或 Suggestion 級別問題 | 假設成立（Important/Suggestion 已有處理規則） |
| A5 | 引入互動決策點後，使用者不會因選項疲勞（option fatigue）而習慣性選擇「跳過」，反而降低品質 | [UNCERTAIN] |
| A6 | 使用者有能力在被問到 A/B/C 時，做出有意義的技術判斷，而不是隨機選擇 | [UNCERTAIN] |

**問題 3：如果假設是錯的，會怎樣？**

- A1 為假：若使用者遇到 CRITICAL 問題都是直接修復，互動點只會增加摩擦，降低 quality-gate 的執行流暢度。
- A2 為假：若互動決策點實際上成為「跳過 CRITICAL 的合法路徑」，品質水準將下降，違反 quality-gate 的核心設計意圖。
- A5 為假（選項疲勞）：使用者習慣性選擇「繼續」，等同於 HARD-GATE 失效，品質保護形同虛設。
- A6 為假：若使用者缺乏足夠技術上下文，互動問答只會延誤流程，不創造真實價值。

---

## 1. 問題陳述（Problem Statement）

Shikigami 的 quality-gate 對 CRITICAL 問題採用無例外的 HARD-GATE 設計：發現 CRITICAL 即終止，必須修復後重啟。這在大多數情況下是正確的。但現實中存在合理的例外場景：技術債明確接受並文件化、已知問題的緊急修補路徑、外部依賴問題的降級處理等。

當使用者面對這些例外場景時，當前設計只提供兩個選擇：(1) 修復問題（有時不在當下的工作範圍內）或 (2) 不走 quality-gate（完全失去品質保護）。沒有「有意識地接受風險並繼續，同時留下決策記錄」的路徑。

gstack 的互動式審查模式指出了一個改善方向：在關鍵決策點提供結構化選項，讓使用者的決策行為被明確記錄，而非被迫繞過機制。

---

## 2. 目標使用者（Target Users）

**主要使用者：使用 Shikigami quality-gate 的工程師**

- 在緊急修補場景中，需要在「完美修復」與「有意識接受風險」之間做出知情決策的使用者
- 在技術債管理場景中，需要明確記錄「已知問題，計劃在下一 Sprint 修復」的使用者

**排除**：
- 尋求完全繞過品質保護機制的使用者（本功能不是後門，決策必須被記錄）
- 不需要人工介入決策的自動化 CI/CD 環境（互動模式本質上需要人在場）

---

## 3. 商業假設（Business Assumptions）

| # | 假設 | 標籤 | 驗證方式 |
|---|------|------|---------|
| A1 | 使用者在實際使用中遇到「需要接受已知 CRITICAL 風險並繼續」的場景 | [UNCERTAIN] | GitHub Issues 中搜尋 quality-gate FAIL 相關討論；或直接向活躍使用者調查 |
| A2 | 加入互動決策點後品質水準不降低（記錄 > 繞過） | [UNCERTAIN] | 設計必要的決策記錄機制（強制寫入 decision log），讓「接受風險」的選擇有可查記錄 |
| A5 | 使用者不會因選項疲勞習慣性略過 | [UNCERTAIN] | 嚴格限制互動點出現條件（僅 CRITICAL，且不允許連續多次選擇「繼續」） |

---

## 4. 提案解決方向（Proposed Direction）

### 核心設計原則

互動式決策點的設計必須滿足：
1. **決策必須被記錄**：任何非「修復」的選擇都必須強制寫入決策記錄
2. **選項有限且明確**：A/B/C 三選項，不允許自由輸入
3. **不降低品質基線**：接受風險路徑必須附帶後續行動承諾（如建立 Issue、標記技術債）

### 4.1 CRITICAL 問題互動決策點設計

當 quality-gate 發現 CRITICAL 問題時，在 FAIL 之前插入一個互動點：

```
[CRITICAL] 發現 1 個關鍵缺陷：
  - [Critical] handler.js L45: 輸入未驗證，存在注入漏洞（XSS）

請選擇處置方式：
  A. 修復後重新審查（推薦）
  B. 降級為 Important，本次繼續（需提供降級理由，強制記錄）
  C. 接受風險並繼續（需在 GitHub 建立 Security Issue，強制記錄）

請輸入 A、B 或 C：
```

### 4.2 決策記錄機制

選擇 B 或 C 時，強制執行：
- 將決策記錄寫入 `docs/km/quality-gate-decisions.md`（新建文件）
- 記錄內容：日期、問題描述、選擇的選項、理由、後續行動（Issue 編號或計劃）
- 若選擇 C 且未提供 GitHub Issue 編號，拒絕繼續

### 4.3 防濫用機制

- 同一個 Story/PR 連續選擇 B 或 C 超過 2 次，強制升級至人工 Architect 審查
- Security 類 CRITICAL 問題不允許選擇 B（只能 A 或 C，且 C 必須建立 Issue）

---

## 5. 成功指標（Success Metrics）

| 指標 | 基線 | 目標 | 量測方式 |
|------|------|------|---------|
| quality-gate CRITICAL 問題的處置選項覆蓋率 | 1 種（修復或停止） | 3 種有記錄的合法路徑 | 設計確認 |
| 互動決策記錄完整率 | 0%（無記錄機制） | 100%（每次 B/C 選擇均有記錄） | 查閱 quality-gate-decisions.md |
| 使用者使用互動點後的主觀滿意度 | 未量測 | >= 4/5 | 功能使用後問卷，N >= 3 |
| 引入後 CRITICAL 問題的實際修復率不降低 | 未量測（假設接近 100%） | >= 80% 仍選擇 A（修復） | 統計 decisions.md 的選項分布 |

---

## 6. 排除範圍（Out of Scope）

- **Important / Suggestion 級別問題的互動選項**：這兩個級別已有明確處理規則，不加入互動點
- **自動化 CI/CD 環境中的互動模式**：互動點假設人在場，CI/CD 環境不適用
- **回溯已有的決策記錄**：不處理引入功能前的歷史決策
- **改變 HARD-GATE 的核心語意**：security-review 升級路徑不受影響

---

## 7. 依賴與風險（Dependencies & Risks）

### 依賴

| 依賴項目 | 類型 | 說明 |
|---------|------|------|
| `skills/quality-gate/SKILL.md` | 修改目標 | 需在 CRITICAL 問題處理流程中插入互動決策點 |
| `skills/shoot/SKILL.md` | 修改目標 | shoot 流程中的 quality-gate 也需同步更新 |
| `docs/km/quality-gate-decisions.md` | 新建文件 | 決策記錄存放位置，需設計文件格式 |

### 風險

| 風險 | 可能性 | 影響 | 緩解措施 |
|------|-------|------|---------|
| 互動決策點成為「繞過 CRITICAL 的合法後門」（A2 不成立） | 高 | 高 | **核心設計風險**：防濫用機制（連續 2 次強制升級）是關鍵緩解措施，必須納入 Gate 2 設計審查 |
| 使用者選項疲勞，習慣性選擇「繼續」（A5 不成立） | 中 | 高 | 嚴格限制觸發條件，統計 A/B/C 分布，若 C 選擇率 > 20% 則觸發設計回顧 |
| 使用者實際上不遇到此場景（A1 不成立） | 中 | 中 | 若需求佐證不足，此 Brief 優先級應下降；可先設計但不立即排入 Sprint |
| shoot 與 quality-gate 兩個 Skill 的同步維護成本 | 低 | 中 | 設計時以 quality-gate SKILL 為 SSOT，shoot SKILL 引用而非複製 |

### 核心風險警示

**本 Brief 最大風險是「降低品質保護」**。互動決策點的設計若不審慎，可能讓 HARD-GATE 名存實亡。Gate 2 審查必須由 QA Engineer 主導，確認防濫用機制足夠嚴格。

---

### Architect 技術可行性評估

**評估日期**：2026-03-15
**判斷**：可行

#### 技術可行性分析

1. **實作路徑清晰，不引入新技術依賴**
   本 Brief 的核心變更是在 `quality-gate/SKILL.md` 的判定規則中插入條件分支，屬於純 Skill 行為定義修改，不需要新 MCP 整合、不依賴外部工具、不改變現有架構邊界。從技術實作難度看，這是三個 Brief 中最低的。

2. **shoot/SKILL.md 同步問題是架構合規重點**
   目前 `shoot/SKILL.md` 的 QA Post-check（§8）明確說明「與 sprint-execution story-lifecycle 的 §5-§6 審查標準一致」，而 quality-gate 的 CRITICAL 判定邏輯亦存在於 shoot 流程中（`quality-gate` §7 的判定規則）。若互動決策點只更新 quality-gate/SKILL.md 而未同步更新 shoot/SKILL.md，將違反 Single Source of Truth 原則。此問題在 Brief 中已識別，但**需要在實作前確認 SSOT 架構**：是在 quality-gate Skill 定義決策邏輯後由 shoot 引用，還是兩者各自定義。Architect 建議以 quality-gate 為 SSOT，shoot 以引用方式呼叫，不複製邏輯。

3. **決策記錄機制（4.2）的持久化設計需謹慎**
   `docs/km/quality-gate-decisions.md` 作為決策記錄的存放位置，屬於新建文件路徑。需確認：(a) 此文件是否應納入 version control（建議是）；(b) 選項 C 要求「提供 GitHub Issue 編號」的驗證機制如何在 Agent context 中執行（需要 gh CLI 可用）；(c) 若多個 CRITICAL 問題同時出現，每個問題各自觸發一次互動決策，還是批次處理？

4. **防濫用機制（4.3）的「連續 2 次」計數邏輯需明確定義**
   「同一個 Story/PR 連續選擇 B 或 C 超過 2 次，強制升級 Architect 審查」——此計數的 Scope 定義（是同一個 quality-gate 執行、同一個 Story、還是同一個 branch）需在設計時明確，否則 Agent 無法正確執行此規則。

#### 提案方向技術評語（第 4 區段）

- **4.1 CRITICAL 問題互動決策點設計**：A/B/C 三選項設計在技術上可行，Agent 可執行明確的分支邏輯。選項 C 強制要求 GitHub Issue 編號的設計，依賴 gh CLI 可用性，需設計 gh CLI 不可用時的降級行為（否則在無 gh CLI 環境中選項 C 永遠無法完成）。

- **4.2 決策記錄機制**：文件路徑和格式設計合理。但建議在 Skill 定義中明確「決策記錄寫入失敗時的行為」（是阻擋繼續還是 WARN 後繼續），避免 Agent 行為不一致。

- **4.3 防濫用機制**：「Security 類 CRITICAL 不允許選擇 B」的設計需定義何謂「Security 類」——建議對應到 `security-review/SKILL.md` 的問題分類，確保定義一致而非各 Skill 各自解讀。

#### 是否需要 ADR

**不需要獨立 ADR**，但實作時需在 `quality-gate/SKILL.md` 的變更說明中清楚記錄「HARD-GATE 語意調整原則」——保持 HARD-GATE 名稱不變，但在 HARD-GATE 觸發前插入決策點，此設計決策需以 inline comment 或 Skill 的版本說明形式記錄，供未來維護者理解設計意圖。

#### 補充技術風險

| 風險 | 可能性 | 影響 | Architect 評語 |
|------|-------|------|---------------|
| shoot/quality-gate 邏輯不同步導致行為不一致（語意常數重複定義） | 中 | 高 | **Layer Compliance 違規風險**：判定規則是語意常數，若分散在兩個 Skill 各自定義，違反 Single Source of Truth 原則，Architect 審查 Gate 將攔截此違規 |
| 「連續 2 次」計數 Scope 未定義，Agent 無法正確執行防濫用規則 | 中 | 中 | Gate 2 必須輸出計數規則的精確定義，可寫成測試案例（Given/When/Then）確認無歧義 |
| 選項 C 的 gh CLI 依賴在無 gh 環境中造成永久阻塞 | 低 | 中 | 需設計降級路徑：gh CLI 不可用時，允許以「手動建立 Issue 後輸入 Issue 編號」替代 |

---

## Gate Checklist

### Gate 1：問題理解（PO 確認）

- [x] 問題陳述基於 Issue #271 競品分析，現有缺口有依據（quality-gate HARD-GATE 設計）
- [x] 目標使用者已識別
- [x] 所有 [UNCERTAIN] 假設已列出
- [ ] 使用者遇到 CRITICAL 場景的佐證收集（驗證 A1）

### Gate 2：範圍收斂（PO + QA + Architect 確認）

- [ ] 防濫用機制設計通過 QA Engineer 審查（核心設計風險緩解）
- [ ] 決策記錄格式設計完成
- [ ] shoot 與 quality-gate 同步設計確認
- [ ] Out of Scope 已與 Stakeholder 對齊
- [x] **Architect 技術可行性評估完成**：判定「可行」，已識別 SSOT 架構設計、防濫用計數 Scope 定義、選項 C gh CLI 降級三項需在設計時釐清的技術點，無需獨立 ADR

### Gate 3：Ready for Sprint（PO + QA 確認）

- [ ] User Story 已撰寫
- [ ] AC 已定義，每條 AC 可測試（特別是「防濫用機制」的 AC）
- [ ] RICE Score 已計算
- [ ] Size 估算已與 Developer/Architect 確認
