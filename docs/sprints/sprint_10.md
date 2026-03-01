# Sprint 10

> 週期：2026-03-01 ~ 2026-03-08
> 狀態：進行中
> 專案等級：low（完全自治）

---

## Sprint Goal

**「填入 Token 真實數據並細化至分環節記錄，引入 Retrospective 驅動的角色權重自動調整，讓框架的成本可觀測性與自我演進能力同步提升」**

Retro #18（Token 真實數據）與 US-23 合併執行，從 Sprint 10 起在 Metrics_Log.md Token 表格填入真實記錄，並進一步細化為分環節（Planning、Execution、Review）粒度，讓成本數據具備可追蹤性。Retro #19（領域專家審查機制設計）採方案 B 調查先行，產出決策記錄文件，不預設採納結論。US-22 引入 Retrospective 驅動的角色權重自動調整，ADR-004 已 Accepted 解鎖 Hard Gate。

對應 ROADMAP：M5「穩定化」。

---

## Sprint Backlog

| Story | 任務 | 負責 | 狀態 | QA Review |
|---|---|---|---|---|
| Retro #19：領域專家審查機制設計 [BYPASS] | 調查文件撰寫 + 決策結論記錄 | PO + Architect | 完成 | Bypass（S size Retro Action Item） |
| US-23：Token 成本分環節記錄 | Metrics_Log.md 分環節表格 + sprint-planning 整合 + 示範資料 | Developer + Architect | 完成 | Spec: PASS / Code: PASS |
| US-22：Retrospective 驅動角色權重自動調整 | sprint-planning SKILL.md 權重調整步驟 + 關鍵字清單 + 持久化機制 | Developer | 待開始 | — |

---

## 工作容量

- Retro #19：< 0.1 Sprint（S，調查報告撰寫 + 決策記錄，無實作）
- US-23：~0.4 Sprint（M，分環節表格設計 + sprint-planning 整合 + 示範資料）
- US-22：~0.6 Sprint（L，權重調整邏輯 + 關鍵字清單 + 持久化 + AC 覆蓋廣）
- 合計：~1.1 Sprint（6 points，略超容量但 Retro #19 極輕量）

**Points 換算**（T-shirt Sizing）：Retro #19 = 1pt（S）、US-23 = 2pt（M）、US-22 = 3pt（L）= 合計 **6 points**

> **容量決策說明**：歷史 Velocity 為 5→4→6→8→7→6→5，中位數 6pt。US-22 Hard Gate 已由 ADR-004 解鎖，Retro #19 為極輕量調查任務，風險可控。

---

## 執行順序

```
Retro #19 ──────────────────────────────────> 待開始（最優先：S size，快速完成，產出決策文件關閉 Issue #19）

US-23 ──────────────────────────────────────> 待開始（Retro #19 完成後開始，Retro #18 合併執行範圍）

US-22 ──────────────────────────────────────> 待開始（US-23 完成後開始，依賴 ADR-004 關鍵字清單；ADR-004 已 Accepted）
```

- Retro #19 最優先：S size 快速完成，關閉 Issue #19
- US-23 次之：填入 Token 真實數據，實現分環節記錄，Retro #18 合併於此執行
- US-22 最後：Hard Gate 已解鎖（ADR-004 Accepted），但實作複雜度最高，排在 US-23 之後

---

## 風險

| 風險 | 可能性 | 影響 | 應對 |
|---|---|---|---|
| US-23 分環節 token 數據在 Claude Code 環境中仍無法自動取得 | 高 | 中 | AC4 降級機制已定義（字串統一為「Token 資料不可用，需手動補充」），分環節欄位填 N/A |
| US-22 關鍵字比對在 sprint-planning SKILL.md 整合後觸發 ADR-003 | 低 | 高 | Architect 確認 ADR-004 已建立且 Accepted，US-22 修改受 ADR-003 Checklist 管轄但不阻塞 |
| Retro #19 調查結論「採納」後在本 Sprint 產生新的 M Story | 低 | 中 | 本 Sprint 調查先行不預設採納；若採納，後續 Story 排入 Sprint 11 |
| US-22 AC2 關鍵字清單觸發條件在目前 Retrospective_Log.md 中已滿足，導致 Sprint Planning 立即升級 | 確定 | 低 | 預期行為；US-22 執行時應在實作層面正確處理，並在 AC3 輸出中說明 |

---

## Story 詳情

### Retro #19：領域專家審查機制設計

**背景與動機**

Sprint 9 Retrospective 中使用者指出框架缺乏在特定階段引入外部領域專家（Domain Expert）的機制，可能導致專業知識不足的盲區。本 Action Item 採方案 B（調查先行）：先調查問題規模與解決方案可行性，再決定是否進入下一步實作。

**Acceptance Criteria（Sprint Planning 精化版）**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 文件建立與路徑 | 新建 `docs/decisions/retro-19-domain-expert-review.md`；文件包含四個必要欄位：問題陳述、調查結果、決策結論、後續行動 |
| AC2 | [靜態] | 調查內容完整性 | 「調查結果」欄位需至少覆蓋：(a) 使用案例識別（哪些 Sprint 階段最可能需要領域專家）；(b) 現有框架的限制說明；(c) 至少兩個可行方案概述 |
| AC3 | [靜態] | 決策結論明確 | 「決策結論」欄位需明確說明：採納或不採納；若採納，「後續行動」欄位需描述後續 Story 的規模（M）與需要建立新 ADR 的說明 |
| AC4 | [動態] | Issue 關閉 | GitHub Issue #19 在 Sprint 10 Review 時關閉 |

**MoSCoW**：Must（Retro Action Item）
**GitHub Issue**：#19
**Size**：S / **Points**：1

---

### US-23：Token 成本分環節記錄

**背景與動機**

US-19 在 Sprint 9 建立了 Token 記錄機制，但 Sprint 9 Review 時 Token 表格仍為空（Retro #18 Action Item）。本 Story 雙重目標：(1) 從 Sprint 10 起填入真實數據；(2) 細化記錄粒度至分環節（Planning、Execution、Review），讓成本結構可觀測，為後續優化決策提供依據。

**Acceptance Criteria（Sprint Planning 精化版）**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 分環節表格格式 | 在 `docs/km/Metrics_Log.md` 現有 Token 成本記錄表格之後，新建獨立 H2 區塊「## Token 成本分環節記錄」。表格欄位：Sprint 編號、Planning token、Execution token、Review token、合計 token、各環節佔比。「各環節佔比」計算基準：本環節 token ÷ 三環節 token 總和（Planning + Execution + Review）。不修改現有 Token 成本記錄表格 |
| AC2 | [靜態] | sprint-planning 整合 | `skills/sprint-planning/SKILL.md` 新增指引：Sprint Planning 結束時，記錄本次 Planning 環節的 token 消耗至分環節表格對應列（Planning token 欄）；不修改現有 Token 成本摘要指引的任何內容 |
| AC3 | [靜態] | 示範資料 | 分環節表格含至少一列示範資料；數值採 K 格式（如 `12K`）；各環節佔比三列加總等於 100% |
| AC4 | [動態] | 降級處理 | 當 token 數據不可得時（無法讀取 Claude Code API 計數器），分環節表格各 token 欄填「N/A」，佔比欄填「N/A」；在 sprint-planning SKILL.md 對應位置輸出精確字串「Token 資料不可用，需手動補充」 |
| AC5 | [動態] | ADR-003 Checklist | 本 Story 修改 `skills/sprint-planning/SKILL.md`，需在 Sprint 執行前確認 ADR-003 Framework Document Change Audit Checklist 通過 |

**RICE 評分**

| 維度 | 分數 |
|------|------|
| Reach | 8 |
| Impact | 3 |
| Confidence | 70% |
| Effort | 0.5 人週 |
| **RICE Score** | **33.6** |

**MoSCoW**：Must
**Size**：M / **Points**：2
**對應 Retro Action**：#18（合併執行）

---

### US-22：Retrospective 驅動角色權重自動調整

**背景與動機**

框架目前以固定深度執行各角色審查，無法根據歷史 Retrospective 趨勢自動調整介入強度。ADR-004 已確立關鍵字清單比對機制（Accepted），Hard Gate 解鎖。本 Story 實作「Sprint Planning 自動讀取 Retro 趨勢 → 調整角色權重 → 持久化調整記錄」的完整閉環，讓框架具備從歷史問題中學習的自我演進能力。

**Acceptance Criteria（Sprint Planning 精化版）**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 觸發時機與插入位置 | `skills/sprint-planning/SKILL.md` 在「健康檢查」步驟之後、「PO 第一輪」步驟之前，新增「## 角色權重調整檢查」步驟 |
| AC2 | [動態] | 權重調整規則（引用 ADR-004） | 依 ADR-004 關鍵字清單比對機制執行：QA 領域關鍵字清單 `["QA", "審查", "Review", "Code Quality", "Spec Compliance", "雙階段", "品質"]`；連續定義：最近 2 個已完成 Sprint（Sprint N-1 和 Sprint N）的 Retrospective Problem 區塊各含至少一個清單關鍵字；重置條件：任一 Sprint Problem 區塊不含任何清單關鍵字則計數歸零。觸發條件滿足時，QA Review 從 Should 升為 Hard Gate（Must，不可跳過）；連續 2 Sprint 無任何 Problem → Bypass 門檻從 S 放寬至 M |
| AC3 | [動態] | 調整透明化與持久化 | Sprint Planning 輸出「本次調整項目」清單，說明調整依據（引用具體 Retro Sprint 編號與匹配的關鍵字）；調整結果持久化至 `docs/sprints/sprint_N.md`「## 權重調整記錄」區塊；若未發生調整，輸出「歷史趨勢穩定，無需調整」並同樣寫入「## 權重調整記錄」區塊 |
| AC4 | [靜態] | 資料不足降級 | Retrospective_Log.md 少於 3 個 Sprint 記錄時，略過調整步驟，輸出「歷史資料不足 3 個 Sprint，跳過權重調整」；此訊息同樣寫入 `sprint_N.md`「## 權重調整記錄」區塊 |

**RICE 評分**

| 維度 | 分數 |
|------|------|
| Reach | 8 |
| Impact | 3 |
| Confidence | 55% |
| Effort | 2.0 人週 |
| **RICE Score** | **6.6** |

**MoSCoW**：Could
**Size**：L / **Points**：3
**對應 Issue**：#12（建議 4）
**依賴**：ADR-004（Accepted）、US-09（Retrospective Analytics，已完成）

---

## 驗收標準（Sprint 結束時勾選）

### Retro #19：領域專家審查機制設計

- [ ] `docs/decisions/retro-19-domain-expert-review.md` 已建立，含四個必要欄位（AC1 通過）
- [ ] 調查結果覆蓋使用案例、現有框架限制、至少兩個可行方案（AC2 通過）
- [ ] 決策結論明確（採納或不採納），若採納則後續行動描述完整（AC3 通過）
- [ ] GitHub Issue #19 在 Sprint 10 Review 時關閉（AC4 通過）

### US-23：Token 成本分環節記錄

- [ ] Metrics_Log.md 現有 Token 表格後新建 H2「Token 成本分環節記錄」，含六欄位 + 佔比計算基準（AC1 通過）
- [ ] sprint-planning SKILL.md 新增 Planning token 記錄指引，未修改現有 Token 成本摘要指引（AC2 通過）
- [ ] 分環節表格含示範資料（K 格式，佔比三欄加總 100%）（AC3 通過）
- [ ] 降級字串統一為「Token 資料不可用，需手動補充」；分環節表格欄位填 N/A（AC4 通過）
- [ ] ADR-003 Checklist 通過確認（AC5 通過）

### US-22：Retrospective 驅動角色權重自動調整

- [ ] sprint-planning SKILL.md 在健康檢查後、PO 第一輪前新增「角色權重調整檢查」步驟（AC1 通過）
- [ ] 步驟內容正確引用 ADR-004 關鍵字清單與連續定義，觸發邏輯完整（AC2 通過）
- [ ] 調整結果持久化至 sprint_N.md「## 權重調整記錄」區塊（AC3 通過）
- [ ] 資料不足時輸出正確降級訊息並寫入 sprint_N.md（AC4 通過）

## 權重調整記錄

> 本區塊於 Sprint Planning 執行「角色權重調整檢查」時填入（US-22 實作後生效）。

（待 US-22 實作後由 sprint-planning 自動填入）
