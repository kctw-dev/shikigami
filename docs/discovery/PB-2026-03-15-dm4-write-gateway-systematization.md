# Product Brief：DM-4 寫入入口審查機制系統化

---

## 基本資訊

| 欄位 | 內容 |
|------|------|
| Brief ID | PB-2026-03-15-dm4-write-gateway-systematization |
| 功能名稱 | DM-4 寫入入口審查機制系統化 |
| 作者 | PO |
| 建立日期 | 2026-03-15 |
| 狀態 | **Gate 3 擱置（Shelve）** |
| 關聯里程碑 | M5 |
| 關聯 SDD | SDD-000-architecture.md §2.3 DM-4 |
| 關聯 Commit | 0da8626（DM-4 Gateway 對照表落地） |
| 潛在關聯 ADR | ADR-022（待評估是否需要） |

---

## 1. 問題陳述（Problem Statement）

SDD-000 §2.3 定義了 DM-4 Gateway 寫入入口審查機制，並在 commit 0da8626 中完成了類別圖層面的 Gateway 對照表落地。但 DM-4 目前僅存在於 SDD 的架構描述層，尚未轉化為可執行的 Agent 行為約束：

1. **缺乏流程層約束**：沒有任何 SKILL.md 強制要求 Agent 在執行寫入操作前通過 DM-4 Gateway 審查。Agent 可以在不經過 Gateway 的情況下直接執行寫入，DM-4 的設計意圖無從落地。

2. **缺乏架構決策記錄**：DM-4 機制的設計理由、邊界條件、例外情況尚未形成 ADR，未來的 Skill 修改者無從得知 Gateway 的設計邊界，容易在不知情的情況下繞過或破壞審查機制。

3. **與 ADR-020 的落地缺口**：ADR-020 要求 Spec Compliance Review 驗證實作是否符合 SDD 定義的架構約束，DM-4 Gateway 是 SDD-000 中明確定義的架構約束。在 DM-4 系統化完成前，Spec Reviewer 無法有效驗證寫入操作是否合規。

現況是 DM-4 的架構意圖存在於 SDD，但對 Agent 行為無約束力。

---

## 2. 目標使用者（Target Users）

**直接受影響的 Agent 角色**：
- Developer Agent：執行寫入操作前，需通過 DM-4 Gateway 審查流程。
- Spec Reviewer Agent：Spec Compliance Review 中需驗證寫入操作是否通過 DM-4 Gateway。
- Architect Agent：需在 Sprint Planning 時為涉及寫入操作的 Story 標注 DM-4 相關的 SDD 約束。

**框架維護者（長期受益）**：
- 需要理解 DM-4 設計理由以進行 Skill 修改的 Architect 或 Developer。
- ADR-022（若建立）提供設計決策的可追溯性。

**間接受益方**：
- 所有使用 Shikigami 框架的開發團隊，因寫入操作更安全、更一致而減少資料不一致風險。

---

## 3. 商業假設（Business Assumptions）

| # | 假設 | 標籤 | 驗證方式 |
|---|------|------|---------|
| A1 | DM-4 Gateway 系統化需要建立獨立的 ADR-022，不能僅靠 SDD-000 §2.3 作為設計依據（理由：ADR 是流程決策的記錄，SDD 是架構設計的描述，兩者角色不同） | [UNCERTAIN] | 與 Architect 討論：SDD §2.3 的現有描述是否足夠指導 Skill 修改者，或是否需要 ADR 補充決策理由與邊界條件 |
| A2 | DM-4 系統化的工作規模為 M-size（需修改 2-4 個 SKILL.md + 可能建立 ADR-022），可在單一 Sprint 內完成 | [UNCERTAIN] | 盤點需修改的 SKILL.md 清單，估算每個修改的工作量 |
| A3 | DM-4 系統化依賴 ADR-020 落地（候選需求 2）先完成：因為 Spec Reviewer 需要能夠執行 SDD 一致性驗證，才能有效驗證 DM-4 Gateway 合規性 | [UNCERTAIN] | 分析 DM-4 系統化的驗收條件，確認是否有 AC 需要 ADR-020 落地作為前置條件 |
| A4 | SDD-000 §2.3 的 DM-4 Gateway 對照表（commit 0da8626）描述的邊界條件已足夠清晰，不需要補充設計才能開始 Skill 修改 | [UNCERTAIN] | 審查 SDD-000 §2.3 現有內容，評估是否有歧義或缺口 |
| A5 | 現有框架中所有涉及寫入操作的 Agent 行為已在 SDD-000 §2.3 Gateway 對照表中被識別，不存在遺漏的寫入場景 | [UNCERTAIN] | 以 Spec Reviewer 視角盤點所有 Skill 中的寫入操作，對照 Gateway 對照表，確認覆蓋完整性 |

---

## 4. 提案解決方向（Proposed Direction）

DM-4 機制從架構描述層落地至流程執行層，分兩個工作流：

**工作流 A：ADR-022 建立（若評估需要）**
- 記錄 DM-4 Gateway 的設計理由、適用範圍、邊界條件、例外情況。
- 定義 Gateway 審查的觸發條件（哪類寫入操作需要通過 Gateway）。
- 建立 DM-4 違規的處理規則（FAIL 時的後續流程）。

**工作流 B：SKILL.md 行為約束落地**
- `developer-prompt.md`：在執行寫入操作前，新增 DM-4 Gateway 審查步驟，包含對照 SDD-000 §2.3 Gateway 對照表的自我檢查指令。
- `spec-reviewer-prompt.md`：Spec Compliance Review 新增「DM-4 Gateway 合規驗證」項目（與 ADR-020 SDD 一致性驗證協調，避免重複）。
- 其他受影響 SKILL.md（待盤點後確認）。

**工作流順序**：若假設 A3 成立，需先完成 ADR-020 落地，再執行 DM-4 Skill 修改。若假設 A3 不成立（DM-4 可獨立落地），則可與 ADR-020 並行。

---

## 5. 成功指標（Success Metrics）

| 指標 | 基線 | 目標 | 量測方式 |
|------|------|------|---------|
| DM-4 Gateway 約束在 SKILL.md 層覆蓋率 | 0%（目前僅存在於 SDD） | 100%（所有涉及寫入的 Skill 均有 Gateway 審查步驟） | 逐一審查 Skill |
| Spec Compliance Review DM-4 驗證執行率 | 0% | 100%（涉及寫入操作的 Story 均執行） | Sprint Review 統計 |
| 繞過 Gateway 的寫入操作發現率 | 未量測 | 建立基線（首個 Sprint 後統計） | Spec Compliance Review 記錄 |
| ADR-022 建立（若需要） | 不存在 | Accepted 狀態 | ADR 文件存在且通過 Architecture Review |

---

## 6. 排除範圍（Out of Scope）

- **DM-4 Gateway 的自動化實作**（如 MCP Server 寫入攔截）：本 Brief 聚焦 Skill 層的流程約束，不涉及技術基礎設施的自動化強制。
- **SDD-000 §2.3 以外的寫入場景識別**：若盤點發現 Gateway 對照表有缺口，補充 Gateway 對照表為 SDD 維護工作，獨立處理。
- **DM-4 的讀取操作審查**：DM-4 定義為寫入入口審查，讀取操作不在審查範圍。
- **ADR-020 落地工作**：ADR-020 的六個 SKILL.md 修改由候選需求 2 獨立處理，本 Brief 僅處理 DM-4 額外需要的修改，不重複。

---

## 7. 依賴與風險（Dependencies & Risks）

### 依賴

| 依賴項目 | 類型 | 說明 |
|---------|------|------|
| SDD-000 §2.3 DM-4 Gateway 對照表 | 前置技術基礎 | 已落地（commit 0da8626），需審查品質是否足夠 |
| ADR-020 落地（候選需求 2） | 潛在前置依賴 | 假設 A3 待確認，若有依賴則需排在候選需求 2 之後 |
| ADR-022 評估 | 前置決策 | 需先決定是否建立 ADR-022，才能確認工作範圍 |

### 風險

| 風險 | 可能性 | 影響 | 緩解措施 |
|------|-------|------|---------|
| SDD-000 §2.3 描述不足，DM-4 邊界條件模糊（A4 不成立） | 中 | 高（Skill 修改缺乏清晰依據，容易產生歧義） | Gate 2 前審查 SDD-000 §2.3，不足時先補強描述（可能觸發 ADR-022 需求） |
| Gateway 對照表覆蓋不完整（A5 不成立） | 中 | 中（部分寫入場景無 Gateway 約束） | Gate 2 前完成寫入場景盤點，對照 Gateway 對照表確認覆蓋完整性 |
| 工作規模評估過小（A2 不成立），單 Sprint 無法完成 | 中 | 中（Sprint 規劃不準確） | Gate 2 前完成詳細工作量估算；若超出 M-size，拆分為兩個 Sprint |
| ADR-020 落地工作延誤，阻塞 DM-4 系統化（若 A3 成立） | 低 | 中（DM-4 工作被迫等待） | Gate 2 確認依賴關係；若有依賴，與 ADR-020 排入同一 Sprint |
| `spec-reviewer-prompt.md` 同時被 ADR-020 和 DM-4 修改，產生衝突 | 中 | 低（需 merge 協調） | 統一在一個 PR 中處理 `spec-reviewer-prompt.md` 的所有修改 |

### Architect 技術可行性評估（Discovery Step 4）

| 欄位 | 內容 |
|------|------|
| 評估日期 | 2026-03-15 |
| 評估結論 | **有條件可行** |
| 需要 ADR | **建議建立 ADR-022** |

**技術方向評估**：

DM-4 Gateway 機制從 SDD 架構描述層落地至 SKILL.md 流程約束層，技術上屬於 SKILL.md 文本修改，與 Brief 2（ADR-020 落地）同質。但 DM-4 系統化涉及一個根本問題：**SDD-000 §2.3 Gateway 對照表目前為空模板**。

**SDD-000 §2.3 現況審查**：

Gateway 對照表的所有列均為範例佔位符（`*例：credits_balance*`、`*例：order.status*`），無任何本專案的實際共享資源定義。變更紀錄顯示 2026-03-15 commit 0da8626 「新增 Gateway 標記、§2.3 共享資源寫入入口對照表」，但對照實際內容，該 commit 建立的是**表格結構**（schema），而非填入具體的 Gateway 映射資料。

**結論**：A4 假設（SDD-000 §2.3 描述足夠清晰可直接開始 Skill 修改）**不成立**。Agent 被要求「對照 SDD-000 §2.3 Gateway 對照表」時，對照的是空表。

**ADR-022 必要性評估（A1 假設）**：

**建議建立 ADR-022**。理由：
1. **SDD vs ADR 角色區分**：SDD-000 §2.3 定義了 Gateway 的資料結構（哪些共享資源有哪個 Gateway），但不定義流程決策（Agent 何時觸發審查、FAIL 時如何處理、例外情況的豁免條件）。後者屬 ADR 範疇。
2. **可追溯性需求**：未來 Skill 修改者需要理解「為何要有 Gateway 審查」的決策理由與邊界條件，ADR 是標準載體。
3. **與 ADR-020 的對稱性**：ADR-020 定義了 SDD → AC 追溯鏈的流程決策，DM-4 Gateway 審查是同層級的流程決策，應有對等的決策記錄。

**技術阻礙**：

1. **SDD-000 §2.3 為空模板**：DM-4 落地的前提是 Gateway 對照表有實質內容。需先為本專案識別並填入共享資源與 Gateway 映射（即使是 Shikigami 框架自身的共享資源，如 `PROJECT_BOARD.md`、`Metrics_Log.md` 的寫入入口）。
2. **受影響 SKILL.md 範圍待確認**：Brief 提及 `developer-prompt.md` 與 `spec-reviewer-prompt.md`，但 Grep 結果顯示 DM-4/Gateway 審查目前僅出現在 `skills/architect/SKILL.md` 與 `skills/shoot/SKILL.md`（Architect 審查 Gate 的 Layer Compliance 檢查）。Developer 和 Spec Reviewer 的 prompt 中尚無 DM-4 相關內容，A2 假設（M-size 工作量）需在盤點後重新評估。
3. **與 ADR-020 的依賴關係**：A3 假設（依賴 ADR-020 先完成）在技術上**部分成立**。DM-4 的 Spec Reviewer 驗證步驟依賴 ADR-020 已落地的 SDD 一致性驗證框架（`spec-reviewer-prompt.md` §6），DM-4 在該框架上疊加而非獨立實作。但 Developer 的 Gateway 自我檢查步驟可獨立於 ADR-020。建議排序：ADR-020 先落地，DM-4 後疊加。

**技術風險補充**：

| 風險 | 可能性 | 影響 | 說明 |
|------|-------|------|------|
| Gateway 對照表為空，落地後 Agent 審查行為無標的 | 高 | 高 | 與 Brief 2 的 SDD-000 空模板問題同源 |
| 寫入場景盤點遺漏（A5 不成立） | 中 | 中 | 框架寫入操作分散於多個 Skill，需系統性盤點 |
| ADR-022 範圍膨脹 | 低 | 中 | 嚴格限制 ADR-022 為決策記錄，不含實作細節 |

---

## Gate Checklist

### Gate 1：問題理解（PO 確認）

- [ ] 問題陳述已獲 Stakeholder 確認，不包含解決方案
- [ ] DM-4 的架構設計意圖已理解（參照 SDD-000 §2.3）
- [ ] 所有 [UNCERTAIN] 假設已列出
- [ ] 與候選需求 2（ADR-020 落地）的關係已初步釐清

### Gate 2：範圍收斂（PO + Architect 確認）

- [ ] ADR-022 必要性評估完成（驗證 A1）
- [ ] 受影響 SKILL.md 清單盤點完成，工作量估算完成（驗證 A2）
- [ ] 與 ADR-020 落地的依賴關係確認（驗證 A3）
- [ ] SDD-000 §2.3 品質審查完成（驗證 A4）
- [ ] 寫入場景完整性盤點完成（驗證 A5）
- [ ] 若需 ADR-022，ADR-022 草稿已完成

### Gate 3：Ready for Sprint（PO + QA 確認）

- [ ] User Story 已撰寫（覆蓋：Gateway 審查步驟、Spec Compliance DM-4 驗證、ADR-022 若需要）
- [ ] AC 已定義，每條 AC 可測試
- [ ] AC 已引用 SDD-000 §2.3 Gateway 對照表
- [ ] RICE Score 已計算
- [ ] 與候選需求 2 的 Sprint 排入時序已確認

---

## Gate 3：PO 最終決議

| 欄位 | 內容 |
|------|------|
| 決議日期 | 2026-03-15 |
| 決議 | **擱置（Shelve）** |
| 決議者 | PO |

**決議理由**：

1. **雙重前置依賴未解除**：本 Brief 依賴 PB-2（ADR-020 落地）先完成，而 PB-2 本身因 SDD-000 空模板問題被退回。依賴鏈中有兩個未解決的阻礙。
2. **SDD-000 ss2.3 Gateway 對照表為空模板**：Architect 確認 A4 假設不成立。Agent 被要求「對照 SDD-000 ss2.3 Gateway 對照表」時，對照的是空表。此問題與 PB-2 的 SDD-000 空模板問題同源。
3. **ADR-022 尚需評估**：Architect 建議建立 ADR-022，但 ADR-022 的範圍與內容尚未定義，增加了不確定性。
4. **與 PB-2 的 spec-reviewer-prompt.md 修改交叉**：兩個 Brief 都需要修改同一檔案，PB-2 未完成前排入 PB-4 會造成 merge 衝突風險。

**擱置條件（重新啟動觸發器）**：

當以下條件**全部滿足**時，本 Brief 可重新啟動 Discovery 流程：
1. PB-2（ADR-020 落地）完成 Gate 3 審查並獲批准
2. SDD-000 至少 ss2.3 章節補充至有實質內容（非空模板）
3. ADR-022 評估完成（建立或決定不需要）

**備註**：擱置不代表否定 Brief 的商業價值。DM-4 寫入入口審查機制對框架安全性有正面意義，但目前前置條件不成熟，強行推進等同在沙地上蓋房子。
