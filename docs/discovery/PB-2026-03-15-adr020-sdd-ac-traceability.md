# Product Brief：ADR-020 SDD → AC 追溯鏈 SKILL.md 完整落地

---

## 基本資訊

| 欄位 | 內容 |
|------|------|
| Brief ID | PB-2026-03-15-adr020-sdd-ac-traceability |
| 功能名稱 | ADR-020 SDD → AC 追溯鏈 SKILL.md 完整落地 |
| 作者 | PO |
| 建立日期 | 2026-03-15 |
| 狀態 | **Gate 3 退回 — 返回 Step 2** |
| 關聯里程碑 | M5 |
| 關聯 ADR | ADR-020（SDD 作為 AC 強制上游約束） |
| 關聯 SDD | SDD-000-architecture.md |

---

## 1. 問題陳述（Problem Statement）

ADR-020 已於 2026-03-15 正式 Accepted，決定將 SDD 從「可選參考文件」升級為「AC 的強制上游約束」，建立 SDD → AC → TDD 追溯鏈。但 ADR-020 的決策目前仍停留在文件層面，六個受影響的 SKILL.md 尚未完成對應修改：

- `skills/sprint-planning/architect-prompt.md`
- `skills/sprint-planning/qa-prompt.md`
- `skills/sprint-execution/story-lifecycle-prompt.md`
- `skills/sprint-execution/spec-reviewer-prompt.md`
- `skills/sprint-execution/developer-prompt.md`
- `skills/architecture-decision/SKILL.md`

在這些 SKILL.md 完成修改前，Agent 的實際行為不會發生變化——Architect 仍不會強制標注 `related_sdds`，Spec Reviewer 仍不會驗 SDD 一致性，SDD 對 AC 和 TDD 的約束力無從落地。ADR-020 的設計意圖與框架行為之間存在落差。

---

## 2. 目標使用者（Target Users）

**直接受影響的 Agent 角色**：
- Architect Agent：需在 Sprint Planning 時執行 SDD 覆蓋範圍檢查，`related_sdds` 從可選升級為條件必填。
- QA Agent：Sprint Planning 審查時新增「SDD 引用檢查」項目。
- Developer Agent：TDD Red 階段新增 SDD 約束參考步驟。
- Spec Reviewer Agent：Spec Compliance Review 新增 SDD 一致性驗證區塊。

**間接受益方**：
- PO：AC 品質提升，減少設計與驗收脫節造成的返工。
- Stakeholder：實作與架構設計的一致性可驗證，降低架構漂移風險。
- 所有使用 Shikigami 框架的開發團隊。

---

## 3. 商業假設（Business Assumptions）

| # | 假設 | 標籤 | 驗證方式 |
|---|------|------|---------|
| A1 | 六個 SKILL.md 的修改內容相互獨立，可分別實作不需等待其他 SKILL.md 完成 | [UNCERTAIN] | 分析六個 SKILL.md 的執行時序，確認是否有先後依賴（例如 story-lifecycle 引用 architect 修改結果） |
| A2 | SDD-000-architecture.md 的現有內容品質足以作為 AC 撰寫的強制依據，不需要先補強 SDD-000 才能落地 ADR-020 | [UNCERTAIN] | 審查 SDD-000 的章節覆蓋範圍，對照近期 Sprint 的 Story 類型，評估是否存在覆蓋空白 |
| A3 | Agent 在執行 Sprint Planning 時，能夠根據 SKILL.md 中的 `related_sdds` 條件必填規則，正確判斷一個 Story 是否「涉及 SDD 定義範圍內的模組/介面/資料結構」，而不需要額外的判斷範例或樣板 | [UNCERTAIN] | 以近期 Sprint 的 Story 作為測試案例，驗證 Architect Agent 的判斷準確率 |
| A4 | 部分 Sprint 已完成部分 SKILL.md 修改（背景說明中提及「部分短衝已完成修改」），剩餘範圍可在盤點後明確，不需要全部重來 | 假設成立 | 逐一審查六個 SKILL.md 現況，記錄已完成/未完成狀態 |
| A5 | SDD 一致性驗證新增為 Spec Compliance Review 步驟後，整體 Sprint 執行時間增加不超過可接受範圍 | [UNCERTAIN] | 在小樣本 Sprint 中量測新增驗證步驟的時間成本 |

---

## 4. 提案解決方向（Proposed Direction）

ADR-020 落地執行路徑：

1. **現況盤點**：逐一審查六個受影響 SKILL.md，明確記錄哪些已按 ADR-020 修改、哪些尚未修改，產出缺口清單。

2. **修改實作**（依盤點缺口）：
   - `architect-prompt.md`：新增「SDD 覆蓋範圍檢查」步驟，`related_sdds` 升級為條件必填，附判斷規則（參照 ADR-020 §`related_sdds` 升級規則表）。
   - `qa-prompt.md`：Sprint Readiness 清單新增「SDD 引用檢查」項目。
   - `story-lifecycle-prompt.md`：`related_sdds` 升級為條件必填，開始前準備新增 SDD 約束提取步驟。
   - `spec-reviewer-prompt.md`：新增「SDD 一致性驗證」審查區塊（介面簽名、模組邊界、資料結構、狀態轉換）。
   - `developer-prompt.md`：TDD Red 階段新增 SDD 約束參考指引。
   - `architecture-decision/SKILL.md`：ADR 觸發 SDD 更新時，新增「受影響 Story AC 校準」步驟。

3. **回歸驗證**：修改完成後，以近期一個 Sprint 的 Story 作為測試資料，驗證 Agent 行為符合 ADR-020 設計意圖。

---

## 5. 成功指標（Success Metrics）

| 指標 | 基線 | 目標 | 量測方式 |
|------|------|------|---------|
| SKILL.md ADR-020 落地率 | 待盤點後確認（預計 < 50%） | 100%（六個 SKILL.md 全部完成） | 逐一審查確認 |
| Architect Agent 正確判斷 `related_sdds` 必填率 | 未量測（目前為選填） | >= 90%（涉及 SDD 範圍的 Story） | 抽樣審查近 3 個 Sprint 的 Story |
| Spec Compliance Review SDD 一致性驗證覆蓋率 | 0%（未執行） | 100%（有 `related_sdds` 的 Story 均執行） | Sprint Review 統計 |
| 設計與實作不一致發現率 | 未量測 | 建立基線（首個 Sprint 後統計） | Spec Compliance Review 記錄 |

---

## 6. 排除範圍（Out of Scope）

- **SDD-000 內容補強**：若盤點發現 SDD-000 品質不足，補強 SDD-000 為獨立工作項目，不包含在本 Brief 範圍內。
- **新增 SDD 文件**（SDD-001 以外）：本 Brief 聚焦 SKILL.md 行為落地，不包含新 SDD 文件的產出。
- **自動化 SDD 一致性工具**：ADR-020 採用 Agent 執行 SDD 一致性驗證，不包含靜態分析工具的開發。
- **歷史 Story AC 補標 `related_sdds`**：僅針對新 Sprint 的 Story 執行，不回溯修改歷史 AC。
- **ADR-022（若需要）**：DM-4 寫入入口審查機制為獨立 Brief，不在此範圍。

---

## 7. 依賴與風險（Dependencies & Risks）

### 依賴

| 依賴項目 | 類型 | 說明 |
|---------|------|------|
| ADR-020 已 Accepted | 前置決策 | 已完成（2026-03-15） |
| SDD-000-architecture.md 存在且品質足夠 | 技術基礎 | 需盤點確認（假設 A2） |
| 六個 SKILL.md 現況盤點 | 前置工作 | 必須在 Sprint 規劃前完成，否則無法估計工作量 |
| 候選需求 4（DM-4 審查機制）| 潛在依賴 | DM-4 落地可能影響 `spec-reviewer-prompt.md` 的修改內容，需評估先後順序 |

### 風險

| 風險 | 可能性 | 影響 | 緩解措施 |
|------|-------|------|---------|
| SDD-000 品質不足導致 AC 校準無依據 | 中 | 高（SKILL.md 修改後 Agent 行為仍不正確） | Gate 2 前完成 SDD-000 品質審查，品質不足時先補強 SDD-000 |
| Agent 判斷 SDD 觸發條件不準確，誤判率高 | 中 | 中（流程效率下降，誤觸發/漏觸發） | 在 architect-prompt.md 中提供判斷樹或典型案例，降低模糊空間 |
| 六個 SKILL.md 存在執行時序依賴（假設 A1 不成立） | 低 | 中（需調整實作順序） | 盤點時同步分析執行時序，確認獨立性 |
| 與候選需求 4（DM-4）的 `spec-reviewer-prompt.md` 修改產生衝突 | 低 | 中（需 merge 衝突處理） | 協調兩個 Brief 的實作時序，先落地 ADR-020，再疊加 DM-4 修改 |

### Architect 技術可行性評估（Discovery Step 4）

| 欄位 | 內容 |
|------|------|
| 評估日期 | 2026-03-15 |
| 評估結論 | **有條件可行** |
| 需要 ADR | 否（ADR-020 已存在且已 Accepted） |

**技術方向評估**：

ADR-020 決策內容清晰，六個受影響 SKILL.md 清單明確，修改方向有具體規則定義（`related_sdds` 升級規則表、Spec Compliance Review 擴充格式）。技術上屬於 SKILL.md 文本修改，無基礎設施或工具鏈依賴。

**前置條件關鍵評估 — SDD-000 完整性**：

SDD-000-architecture.md 目前為**模板狀態**，所有具體內容均為範例佔位符（以斜體 `*例：...*` 標示）。具體問題：
- 1.1 核心概念定義：空（僅有範例行）
- 1.2 概念間關係：空
- 1.3 統一語言：空
- 2.1 分層結構：為通用範例，非本專案具體分層
- 2.2 Service 清單：空（僅有範例行）
- 2.3 共享資源寫入入口（Gateway 對照表）：空（僅有範例行，但已有 DM-4 審查觸發的變更紀錄）
- 3.x 元件圖全部為空

**結論**：A2 假設（SDD-000 品質足以作為 AC 強制依據）**目前不成立**。SDD-000 作為模板，無法為 Architect Agent 提供可回溯的架構約束。ADR-020 落地後，Agent 被要求「檢查 Story 是否涉及 SDD 定義範圍」，但 SDD-000 尚無實質定義範圍可供檢查——`related_sdds` 條件必填規則會因 SDD-000 降級規則（「SDD-000 不存在時全部可省略」的語意邊界：存在但為空模板是否等同「不存在」）而產生歧義。

**前置工作建議**：在 ADR-020 落地前，需先決定：(a) 是否先補充 SDD-000 至最低可用狀態，或 (b) 明確定義「SDD-000 為空模板時」的降級行為等同「不存在」。

**技術阻礙**：

1. **SDD-000 空模板問題**（如上所述）：直接影響落地後 Agent 行為的有效性。
2. **六個 SKILL.md 部分已修改**：根據 Grep 結果，`architect-prompt.md` 已有 SDD 覆蓋範圍檢查規則與 `related_sdds` 升級規則；`spec-reviewer-prompt.md` 已有完整的 SDD 一致性驗證區塊（§6）。已完成的修改需盤點確認，避免重複工作。A4 假設部分成立。
3. **SKILL.md 修改可獨立進行**：六個檔案的修改在技術上獨立（不涉及共享狀態或序列化依賴），A1 假設成立。但 `spec-reviewer-prompt.md` 與 Brief 4（DM-4）存在交叉修改風險。

**技術風險補充**：

| 風險 | 可能性 | 影響 | 說明 |
|------|-------|------|------|
| SDD-000 為空模板，落地後 Agent 行為等同空轉 | 高 | 高 | ADR-020 規則運作的前提是 SDD 有實質內容可回溯 |
| 已完成修改與未完成修改的品質不一致 | 中 | 低 | 需統一審查標準 |

---

## Gate Checklist

### Gate 1：問題理解（PO 確認）

- [ ] 問題陳述已獲 Stakeholder 確認，不包含解決方案
- [ ] 六個受影響 SKILL.md 清單已確認
- [ ] 所有 [UNCERTAIN] 假設已列出
- [ ] ADR-020 落地商業價值說明清晰（設計合約有效性、減少架構漂移）

### Gate 2：範圍收斂（PO + Architect 確認）

- [ ] 六個 SKILL.md 現況盤點完成（已完成/未完成狀態記錄）
- [ ] SDD-000 品質審查完成（驗證 A2）
- [ ] Agent 觸發條件判斷設計草稿完成（驗證 A3 可測試）
- [ ] 與候選需求 4 的依賴關係已釐清
- [ ] 工作量估算完成（基於盤點缺口）

### Gate 3：Ready for Sprint（PO + QA 確認）

- [ ] 每個 SKILL.md 修改內容已有對應 User Story
- [ ] AC 已定義，每條 AC 可測試
- [ ] AC 已引用 ADR-020 對應的決策規則
- [ ] RICE Score 已計算
- [ ] 六個 SKILL.md 的修改順序已排定（若有依賴）

---

## Gate 3：PO 最終決議

| 欄位 | 內容 |
|------|------|
| 決議日期 | 2026-03-15 |
| 決議 | **退回（Return）— 返回 Step 2 解決 SDD-000 前置條件** |
| 決議者 | PO |

**決議理由**：

1. Architect 評估的關鍵發現：SDD-000 目前為**空模板**，所有章節均為範例佔位符。A2 假設（SDD-000 品質足以作為 AC 強制依據）**不成立**。
2. ADR-020 落地後，Agent 被要求「檢查 Story 是否涉及 SDD 定義範圍」，但 SDD-000 無實質定義範圍可供檢查。SKILL.md 修改後 Agent 行為等同空轉——執行了檢查流程但無內容可檢查，這不是有效的落地。
3. 部分 SKILL.md 已完成修改（architect-prompt.md、spec-reviewer-prompt.md），Architect 確認 A1（獨立性）和 A4（部分成立）假設，實際工作量可能小於預期。但 SDD-000 空模板問題是根本阻礙。
4. 正面評價：六個 SKILL.md 修改方向清晰、可獨立執行，ADR-020 決策規則完整。問題不在 Brief 品質，而在前置條件。

**退回修改要求**：

1. **SDD-000 最低可用狀態決策**：在 Brief 中增加一個前置工作項——決定 SDD-000 的最低可用狀態定義。兩個選項：
   - (a) 先補充 SDD-000 的核心章節（至少 1.1 核心概念定義、2.1 分層結構）至可回溯狀態，作為本 Brief 的前置 Story。
   - (b) 明確定義「SDD-000 為空模板時的降級行為」：`related_sdds` 條件必填規則在 SDD-000 無實質內容時自動降級為「可省略」，待 SDD-000 補充後自動升級。
2. **六個 SKILL.md 現況盤點**：完成已完成/未完成狀態記錄，更新工作量估算。
3. 完成上述修改後，重新提交 Gate 2 審查。

**PO 傾向**：建議選項 (a)——先補充 SDD-000。理由是選項 (b) 在邏輯上等同承認 ADR-020 暫時無法落地，不如直接面對 SDD-000 補充工作，同時也為 PB-4（DM-4）解除共同阻礙。
