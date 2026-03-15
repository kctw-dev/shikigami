# Product Brief：MCP Phase 2 — 品質觀察 MCP Server 正式交付

---

## 基本資訊

| 欄位 | 內容 |
|------|------|
| Brief ID | PB-2026-03-15-mcp-phase2-quality-observer |
| 功能名稱 | MCP Phase 2 — 品質觀察 MCP Server 正式交付 |
| 作者 | PO |
| 建立日期 | 2026-03-15 |
| 狀態 | **Gate 3 退回 — 返回 Step 2** |
| 關聯里程碑 | M5 |
| 關聯 ADR | ADR-019（MCP 三層架構） |
| 關聯 Sprint | Sprint 88（US-243 POC），待排入下一可用 Sprint |

---

## 1. 問題陳述（Problem Statement）

Shikigami 框架中，Quality Observer 角色需要彙整 Metrics_Log、Retrospective_Log、Calibration_Log 等多個分散文件才能得出品質診斷結論。現行做法是 Agent 以全文載入方式讀取這些文件，再透過推斷進行跨文件整合。此模式存在兩個核心問題：

1. **數據整合準確率不穩定**：Agent 跨文件推斷沒有結構化介面保障，相同查詢在不同 context 條件下可能產生不一致的解讀。
2. **Token 效率低落**：Quality Observer 每次診斷需載入完整歷史日誌，隨 Sprint 數量增加，無關歷史 context 佔用比例持續上升，稀釋有效資訊的權重。

Sprint 88 已完成品質觀察 MCP Server 的 POC 實作（`mcp-servers/quality-observer/`），驗證了技術可行性。但 POC 尚未正式整合進框架的日常使用流程，品質診斷場景仍依賴舊有全文載入模式。

---

## 2. 目標使用者（Target Users）

**主要使用者**：Quality Observer Agent
- 在 Sprint Retrospective、Sprint Review、臨時品質診斷等情境中，需要查詢結構化品質指標的 AI Agent。

**次要使用者**：Scrum Master Agent、PO Agent
- 需要引用品質數據作為 Sprint 規劃或優先級決策依據的其他 Agent。

**框架使用者（間接受益）**：所有使用 Shikigami 框架的開發團隊
- 品質診斷準確率提升，間接改善 Sprint 決策品質。

---

## 3. 商業假設（Business Assumptions）

| # | 假設 | 標籤 | 驗證方式 |
|---|------|------|---------|
| A1 | POC 已實作的工具覆蓋 Quality Observer 日常診斷所需的主要查詢場景 | [UNCERTAIN] | 盤點 POC tool 清單 vs Quality Observer 典型查詢模式，Gap 分析 |
| A2 | Phase 1（流程管理 MCP Server）尚未交付，`.mcp.json` 目前只有 `drawio` 一個 MCP Server 設定，Phase 2 可獨立整合不需等待 Phase 1 | [UNCERTAIN] | 確認 `.mcp.json` 現況，評估 Phase 1/2 是否有 namespace 或 tool ID 衝突 |
| A3 | Metrics_Log.md 歷史格式差異（Sprint 27-31 備註格式不同）不影響 Phase 2 的核心品質指標查詢 | [UNCERTAIN] | 以 Sprint 88 POC 的解析邏輯對歷史資料進行完整回歸測試 |
| A4 | ADR-019 C1（Fallback 機制）、C2（狀態持久化）、C3（零外部依賴）三個附帶條件在 POC 中已被滿足或可在正式化過程中補全 | 確認中 | 審查 `mcp-servers/quality-observer/` 實作細節 |
| A5 | `.mcp.json` 整合後，CI 環境的 MCP Server 跳過行為符合 ADR-013 已定義的跳過原則，不需額外適配 | 假設成立 | CI pipeline 驗證 |
| A6 | 品質觀察 MCP Server 正式交付後，Quality Observer 的診斷準確率可量化改善 | [UNCERTAIN] | 定義診斷準確率基線（對照組：全文載入模式），交付後對比 |

---

## 4. 提案解決方向（Proposed Direction）

ADR-019 Phase 2 路徑：將 `mcp-servers/quality-observer/` POC 正式化，完成以下工作：

1. **POC 工具覆蓋範圍審查**：盤點現有 tools，比對 Quality Observer 典型查詢需求，補齊缺口。
2. **`.mcp.json` 整合**：新增 `shikigami-quality-observer` server 設定，符合 ADR-019 §選項 A 範本格式。
3. **相關 Skill 更新**：更新 `skills/sprint-review/SKILL.md`、`skills/quality-gate/SKILL.md` 等受影響的 Skill，指向 MCP tool 介面而非全文載入指令。
4. **驗收測試補全**：為每個 MCP tool 補全 unit test，確保 Fallback 場景（MCP 不可達時）行為正確。
5. **Phase 1/2 並存驗證**：即便 Phase 1 尚未交付，確認兩個 Phase 的 `.mcp.json` 設定能共存。

---

## 5. 成功指標（Success Metrics）

| 指標 | 基線 | 目標 | 量測方式 |
|------|------|------|---------|
| Quality Observer 診斷一致性 | 同查詢在不同 context 下結果差異率（待建基線） | 差異率 < 5% | A/B 對照：MCP 查詢 vs 全文載入查詢，相同 Sprint 資料 |
| 診斷場景 token 用量 | 全文載入時的 token count（待量測） | 減少 >= 30% | Sprint Review 過程 token count 對比 |
| MCP tool 測試覆蓋率 | 0%（POC 無測試） | >= 80% | unit test 覆蓋報告 |
| `.mcp.json` 整合後 CI 通過率 | 100%（現況） | 維持 100% | CI pipeline |

---

## 6. 排除範圍（Out of Scope）

- **Phase 1（流程管理 MCP Server）實作**：Phase 1 為獨立交付單元（另見 ADR-019），本 Brief 不包含。
- **Phase 3（知識庫 MCP Server）**：待 Phase 1/2 完成後評估。
- **寫入型 MCP tools**：本 Phase 僅聚焦唯讀品質指標查詢，不實作狀態寫入 tools。
- **多 GCE 環境統一 setup script**：ADR-019 OQ-5 已明確延後至 Phase 3。
- **歷史資料格式修正**：Metrics_Log.md 歷史格式差異問題由 Phase 3（知識庫 MCP Server）處理。

---

## 7. 依賴與風險（Dependencies & Risks）

### 依賴

| 依賴項目 | 類型 | 說明 |
|---------|------|------|
| `mcp-servers/quality-observer/` POC | 前置技術基礎 | 需先審查 POC 品質，決定是擴展 POC 或重寫 |
| ADR-019 附帶條件 C1/C2/C3 | 技術約束 | 正式化實作必須滿足，不可忽略 |
| ADR-013 CI 跳過原則 | 技術約束 | `.mcp.json` 整合後 CI 行為需驗證 |
| Phase 1 MCP Server（弱依賴） | 並行風險 | Phase 1/2 若同期進行，`.mcp.json` 需協調合併 |

### 風險

| 風險 | 可能性 | 影響 | 緩解措施 |
|------|-------|------|---------|
| POC 工具覆蓋不足，需大幅補齊 | 中 | 高（交付規模膨脹） | Gate 1 前完成 Gap 分析，釐清補齊成本 |
| Phase 1/2 `.mcp.json` 整合衝突 | 低 | 中（需協調 merge） | Phase 2 先以獨立 PR 整合，Phase 1 跟進合併時處理衝突 |
| 歷史格式差異影響解析準確率 | 中 | 中（舊資料診斷不準） | 限縮初期查詢範圍至 Sprint 32 以後（格式穩定後）；舊資料標記為 legacy |
| Quality Observer 診斷準確率改善無法量化 | 中 | 低（無法驗收 A6 假設） | 交付前先建立全文載入模式的基線測量 |

### Architect 技術可行性評估（Discovery Step 4）

| 欄位 | 內容 |
|------|------|
| 評估日期 | 2026-03-15 |
| 評估結論 | **有條件可行** |
| 需要 ADR | 否（ADR-019 已涵蓋） |

**技術方向評估**：

POC 已驗證 MCP Server 的 stdio transport 與 Node.js 實作路徑可行。`.mcp.json` 現況僅有 `talk-to-figma` 一個 MCP Server，Phase 2 新增 `shikigami-quality-observer` 不存在 namespace 或 tool ID 衝突風險，A2 假設可初步判定成立。

**技術阻礙與缺口**：

1. **POC 工具覆蓋嚴重不足**：POC 僅實作 4 個 tools（`get_velocity_trend`、`get_metrics_by_sprint`、`get_health_status`、`get_quality_observer_definition`），全部聚焦 Metrics_Log 與 Quality_Observer 定義。`RETROSPECTIVE_LOG_PATH` 已宣告但未使用——Retrospective_Log 與 Calibration_Log 的結構化查詢完全缺失。Quality Observer 日常診斷的「幻覺頻率」「斷鏈模式」「角色協作效率」三維度，目前僅有定義文件的全文回傳（`get_quality_observer_definition`），無結構化查詢能力。A1 假設高度可能不成立，需大幅補齊工具。
2. **ADR-019 附帶條件未滿足**：C1（Fallback 機制）——POC 中無任何 Fallback 邏輯，MCP 不可達時會直接拋錯。C2（狀態持久化）——POC 為純讀取模式，不涉及狀態持久化，此條件在 Phase 2（唯讀）不適用。C3（零外部依賴）——僅依賴 `@modelcontextprotocol/sdk`，符合要求。
3. **測試覆蓋為零**：`mcp-servers/quality-observer/` 目錄下無任何測試檔案，從 0% 到 80% 的差距需要可觀的測試開發工作量。
4. **歷史格式差異**：`parseMetricsLog()` 的解析邏輯依賴固定表格格式，Sprint 27-31 的備註格式差異未處理，需驗證回歸。

**技術風險補充**：

| 風險 | 可能性 | 影響 | 說明 |
|------|-------|------|------|
| POC 需大幅擴展而非小幅修補，交付規模遠超預期 | 高 | 高 | 4 個 tools 需擴展至預估 8-12 個，含 Retrospective/Calibration 查詢 |
| Fallback 機制設計增加複雜度 | 中 | 中 | 需為每個 tool 定義降級行為（回退到全文載入），增加測試面 |
| MCP SDK 版本鎖定風險 | 低 | 低 | `^1.0.0` 語意版本，需確認 Claude Code runtime 內建的 SDK 版本相容性 |

---

## Gate Checklist

### Gate 1：問題理解（PO 確認）

- [ ] 問題陳述已獲 Stakeholder 確認，不包含解決方案
- [ ] 目標使用者已識別，痛點有佐證來源（ADR-019、Sprint 88 報告）
- [ ] 所有 [UNCERTAIN] 假設已列出
- [ ] 商業價值說明清晰（品質診斷準確率、token 效率）

### Gate 2：範圍收斂（PO + Architect 確認）

- [ ] POC 工具覆蓋 Gap 分析完成（驗證 A1）
- [ ] `.mcp.json` Phase 1/2 並存可行性確認（驗證 A2）
- [ ] 歷史格式差異風險評估完成（驗證 A3）
- [ ] Out of Scope 已與 Stakeholder 對齊
- [ ] 排序理由記錄（相對 Phase 1 的優先級）

### Gate 3：Ready for Sprint（PO + QA 確認）

- [ ] User Story 已撰寫（符合 As-a / I-want / So-that 格式）
- [ ] AC 已定義，每條 AC 可測試
- [ ] AC 已引用 ADR-019 附帶條件（C1/C2/C3）
- [ ] RICE Score 已計算
- [ ] 依賴項目已與相關 Sprint 協調

---

## Gate 3：PO 最終決議

| 欄位 | 內容 |
|------|------|
| 決議日期 | 2026-03-15 |
| 決議 | **退回（Return）— 返回 Step 2 重新收斂範圍** |
| 決議者 | PO |

**決議理由**：

1. Architect 評估 POC 工具覆蓋嚴重不足：現有 4 個 tools 需擴展至 8-12 個，Retrospective_Log 與 Calibration_Log 的結構化查詢完全缺失。A1 假設高度可能不成立，交付規模存在膨脹風險。
2. ADR-019 附帶條件 C1（Fallback 機制）未滿足，POC 中無任何 Fallback 邏輯。正式化需為每個 tool 設計降級行為，增加大量測試面。
3. 測試覆蓋從 0% 到 80% 的跨度過大，結合工具數量可能翻倍，整體工作量難以在單一 Sprint 預估。
4. Brief 目前無法回答「正式化需要做多少工作」這個基本問題，範圍未收斂。

**退回修改要求**：

1. **完成 POC Gap 分析**：盤點 Quality Observer 典型查詢模式，對照現有 4 個 tools，產出明確的缺口清單與補齊工作量估算。
2. **定義 MVP 工具清單**：從 Gap 分析中選出 Phase 2 正式交付的最小工具集（而非一次補齊所有缺口），降低交付規模。
3. **Fallback 設計草案**：針對 MVP 工具清單，設計 Fallback 行為（回退到全文載入）的統一模式，而非逐 tool 個別設計。
4. 完成上述修改後，重新提交 Gate 2 審查。
