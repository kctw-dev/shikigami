# Product Brief：演示模式（Live Log Streaming）實作

---

## 基本資訊

| 欄位 | 內容 |
|------|------|
| Brief ID | PB-2026-03-15-demo-mode-live-log-streaming |
| 功能名稱 | 演示模式（Live Log Streaming）實作 |
| 作者 | PO |
| 建立日期 | 2026-03-15 |
| 狀態 | **Gate 3 通過 — 批准** |
| 關聯里程碑 | M5 |
| 關聯 Spike | US-268（Issue #255，Sprint 96） |
| 關聯 Memory | project_demo_mode_idea.md |

---

## 1. 問題陳述（Problem Statement）

Shikigami 框架的 Sprint Execution 流程對新使用者而言是黑箱：Agent 在後台執行多個步驟，使用者只能在流程結束後看到結果，無法即時追蹤目前執行到哪個步驟、哪個 Agent 正在工作、或是否有中間異常。這個問題在演示場景（Demo）下尤其明顯——展示給利害關係人看時，等待一個靜止的介面對觀看者沒有說服力，也無法傳達 AI 團隊並行作業的效果。

Sprint 96 Spike（US-268）已評估了多個方案，並推薦以 Live Log Streaming（`tail -f` 模式）作為演示模式的實作路徑，判斷為技術可行且成本最低。但 Spike 產出目前仍停留在技術評估階段，尚未轉化為框架功能。

---

## 2. 目標使用者（Target Users）

**主要使用者**：Shikigami 框架使用者（展示場景）
- 在技術評估會議、客戶展示、新成員 Onboarding 等場合，需要即時展現 AI 團隊工作過程的開發者或技術主管。

**次要使用者**：框架日常使用者
- 在 Sprint 執行過程中，需要監控 Agent 工作進度、即時發現異常的使用者。

**排除**：對 Shikigami 框架完全不熟悉、無技術背景的受眾（演示模式預期受眾仍需具備基本 CLI 操作能力）。

---

## 3. 商業假設（Business Assumptions）

| # | 假設 | 標籤 | 驗證方式 |
|---|------|------|---------|
| A1 | Live Log Streaming（`tail -f`）雙視窗操作門檻在目標使用者（具備 CLI 能力的開發者）的可接受範圍內，不需要額外的 UI 封裝 | [UNCERTAIN] | 小規模使用者訪談（3-5 人），或在下一次 Stakeholder 演示中直接驗證 |
| A2 | 開啟 Live Log Streaming 模式後，因日誌輸出增加導致的 Token 用量增加在可接受範圍內（不超過正常流程的 20%） | [UNCERTAIN] | 在測試 Sprint 中量測：有/無 streaming 模式的 token count 對比 |
| A3 | Sprint Execution 的日誌輸出格式對演示受眾具有足夠的可讀性，不需要額外的格式化處理 | [UNCERTAIN] | 以 Sprint 96 Spike 的日誌格式樣本，進行小規模使用者測試 |
| A4 | 修改 `story-lifecycle-prompt.md` 與 `sprint-execution/SKILL.md` 兩個檔案足以實作 Live Log Streaming 模式，不需要其他 Agent 或 Skill 的配合修改 | 假設成立（Spike 結論） | 實作過程中確認 |
| A5 | Live Log Streaming 模式可以作為可選的 flag 或設定開關，不影響未開啟此模式的日常流程行為 | 假設成立 | 設計確認 |
| A6 | 演示模式功能的存在，對新使用者的 Onboarding 體驗有正向影響（更容易理解框架行為） | [UNCERTAIN] | 在新使用者 Onboarding 過程中觀察並收集反饋 |

---

## 4. 提案解決方向（Proposed Direction）

基於 Sprint 96 Spike（US-268）推薦方案，採用 Live Log Streaming 路徑：

1. **日誌寫入機制設計**：在 `sprint-execution/SKILL.md` 中定義 Agent 步驟執行時的日誌輸出規範（步驟名稱、執行 Agent、時間戳、狀態）。

2. **`story-lifecycle-prompt.md` 修改**：在各關鍵執行節點加入結構化日誌輸出指令，使 Agent 在執行過程中產生可追蹤的步驟記錄。

3. **Streaming 啟動方式**：定義演示模式的啟動指令（`tail -f` 搭配日誌檔案路徑），在使用者文件中說明雙視窗操作方式。

4. **日誌格式規範**：設計對演示受眾友善的日誌格式，兼顧可讀性與資訊密度。

---

## 5. 成功指標（Success Metrics）

| 指標 | 基線 | 目標 | 量測方式 |
|------|------|------|---------|
| 演示場景使用者滿意度 | 未量測（無演示模式） | >= 4/5（使用者評分） | 演示後問卷，N >= 3 |
| Token 用量增幅 | N/A | < 20%（相較無 streaming 模式） | 測試 Sprint 對比量測 |
| 雙視窗操作成功率（首次使用） | N/A | >= 80%（無需額外說明即可操作） | 觀察 3-5 名首次使用者 |
| 日誌格式可讀性評分 | N/A | >= 4/5（演示受眾評分） | 小規模使用者測試 |
| SKILL.md 修改後既有 Sprint 執行行為不受影響 | Sprint 執行通過率 100% | 維持 100% | 回歸測試 |

---

## 6. 排除範圍（Out of Scope）

- **Web UI 即時監控介面**：超出當前技術棧（CLI-first），不在本 Brief 考慮。
- **日誌持久化與搜索**：本功能聚焦即時串流展示，日誌歸檔與搜索能力為獨立功能。
- **非 Sprint Execution 流程的日誌串流**：初期聚焦 sprint-execution，不延伸至 sprint-planning、retrospective 等其他 Skill。
- **多 Agent 平行執行的視覺化呈現**：日誌為文字串流，不包含拓撲圖或甘特圖等視覺化元件。
- **自動化演示腳本**：不包含固定情境的預錄或模擬演示功能。

---

## 7. 依賴與風險（Dependencies & Risks）

### 依賴

| 依賴項目 | 類型 | 說明 |
|---------|------|------|
| Sprint 96 Spike US-268 產出 | 前置技術評估 | Spike 已完成，推薦路徑已確立 |
| `story-lifecycle-prompt.md` 當前版本 | 修改基礎 | 需確認是否與候選需求 2（ADR-020 落地）存在修改衝突 |
| `sprint-execution/SKILL.md` 當前版本 | 修改基礎 | 同上，需與 ADR-020 落地工作協調修改時序 |

### 風險

| 風險 | 可能性 | 影響 | 緩解措施 |
|------|-------|------|---------|
| 雙視窗操作門檻過高，目標使用者接受度低（A1 不成立） | 中 | 高（功能有效性存疑） | Gate 2 前進行小規模使用者訪談；若門檻過高，探討單視窗方案 |
| Token 成本增幅超過 20%（A2 不成立） | 低 | 中（日常使用成本上升） | Spike 階段量測；若超標，壓縮日誌輸出欄位 |
| 日誌格式可讀性不足（A3 不成立） | 中 | 中（演示效果打折） | Gate 2 前以 Spike 日誌樣本進行格式評估，必要時重新設計格式 |
| 與 ADR-020 落地工作的 SKILL.md 修改產生衝突 | 中 | 低（需 merge 協調） | 排定修改時序：ADR-020 先落地，演示模式後疊加 |

### Architect 技術可行性評估（Discovery Step 4）

| 欄位 | 內容 |
|------|------|
| 評估日期 | 2026-03-15 |
| 評估結論 | **可行** |
| 需要 ADR | 否 |

**技術方向評估**：

Live Log Streaming（`tail -f` 模式）是成熟的 Unix 技術模式，零基礎設施依賴，完全符合框架的 CLI-first 技術棧。實作範圍明確：修改 `story-lifecycle-prompt.md` 與 `sprint-execution/SKILL.md` 兩個檔案，加入結構化日誌輸出指令。A4 假設（兩個檔案足夠）在技術上合理——日誌寫入行為由 SKILL.md 規範，Agent 依指令輸出，不需要其他 Agent 配合修改。

**技術評估細項**：

1. **日誌寫入機制**：Agent 在執行步驟時，以 shell 指令（`echo` 或 `tee -a`）將結構化記錄寫入日誌檔案。技術上簡單可靠，唯一需設計的是日誌檔案路徑的命名規範（建議 `docs/sprints/sprint-{N}/execution.log`）。
2. **可選 flag 設計**：A5 假設（可選開關不影響日常流程）在技術上可行——在 SKILL.md 中以條件判斷（`if [flag]`）控制是否輸出日誌，未開啟時無副作用。
3. **Token 成本**：日誌寫入使用 shell 指令（非 Agent 回應），`tail -f` 在獨立終端執行，不消耗主 session 的 context window。A2 假設的 token 增幅主要來自 Agent 執行 `echo` 指令的 tool call overhead，預估遠低於 20%。
4. **與 ADR-020 落地的衝突**：`story-lifecycle-prompt.md` 同時被 Brief 2 修改。技術上兩者修改的區段不同（ADR-020 修改 `related_sdds` 處理邏輯，演示模式新增日誌輸出步驟），merge 衝突風險低。建議排序：ADR-020 先落地，演示模式後疊加。

**技術阻礙**：無重大技術阻礙。

**技術風險補充**：

| 風險 | 可能性 | 影響 | 說明 |
|------|-------|------|------|
| 日誌格式設計不佳導致可讀性差 | 中 | 中 | 非技術阻礙，屬 UX 設計問題，可透過迭代改進 |
| 跨平台路徑差異（Windows/WSL） | 低 | 低 | 框架已在 WSL 環境運作，`tail -f` 在所有支援平台可用 |

---

## Gate Checklist

### Gate 1：問題理解（PO 確認）

- [ ] 問題陳述已獲 Stakeholder 確認，演示場景痛點有佐證（project_demo_mode_idea.md memory）
- [ ] 目標使用者已識別，演示場景使用案例清晰
- [ ] 所有 [UNCERTAIN] 假設已列出
- [ ] Spike US-268 產出已納入參考

### Gate 2：範圍收斂（PO + Architect 確認）

- [ ] 雙視窗操作門檻使用者訪談完成（驗證 A1）
- [ ] Token 成本增幅初步估算（驗證 A2）
- [ ] 日誌格式草稿設計並通過可讀性評估（驗證 A3）
- [ ] 與 ADR-020 落地工作的修改時序已協調
- [ ] Out of Scope 已與 Stakeholder 對齊

### Gate 3：Ready for Sprint（PO + QA 確認）

- [ ] User Story 已撰寫（至少覆蓋：啟動 streaming、日誌格式、關閉 streaming）
- [ ] AC 已定義，每條 AC 可測試
- [ ] 回歸測試範圍已定義（確保既有 sprint-execution 行為不受影響）
- [ ] RICE Score 已計算
- [ ] S-size 估算已與 Developer 確認

---

## Gate 3：PO 最終決議

| 欄位 | 內容 |
|------|------|
| 決議日期 | 2026-03-15 |
| 決議 | **批准（Approve）** |
| 決議者 | PO |

**決議理由**：

1. Architect 評估結論為「可行」，無重大技術阻礙，是四個 Brief 中唯一無附帶條件的。
2. Spike US-268 已完成技術驗證，推薦路徑明確，實作範圍收斂（兩個檔案修改）。
3. 完全符合 M5「好上手、人機協作」方向——演示模式直接提升框架的可展示性與新使用者 Onboarding 體驗。
4. 技術棧簡潔（`tail -f`），零基礎設施依賴，風險可控。
5. 與其他 Brief 無硬依賴，可獨立排入最近的 Sprint。

**後續行動**：

- 進入 Step 6：轉化為 Backlog User Stories
- 建議排入下一可用 Sprint（優先級最高）
- Story 範圍：啟動 streaming、日誌格式規範、關閉 streaming、回歸測試
- 與 ADR-020 落地工作協調 `story-lifecycle-prompt.md` 修改時序（ADR-020 先，演示模式後疊加）
