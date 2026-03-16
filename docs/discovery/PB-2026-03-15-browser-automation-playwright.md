# Product Brief：Browser Automation 能力引入（Playwright MCP 整合）

---

## 基本資訊

| 欄位 | 內容 |
|------|------|
| Brief ID | PB-2026-03-15-browser-automation-playwright |
| 功能名稱 | Browser Automation 能力引入（Playwright MCP 整合） |
| 作者 | PO |
| 建立日期 | 2026-03-15 |
| 狀態 | **草稿** |
| 觸發來源 | Issue #271 — gstack vs Shikigami 競品分析（第 5 章，高價值項目） |
| 關聯角色 | QA Engineer、UX Designer、SRE Engineer |

---

## Discovery Phase — Step 1：背景分析

### 核心發現（來自 Issue #271）

Issue #271 競品分析發現，gstack 透過持久化 Chromium daemon 賦予其框架中的角色「看得到畫面」的能力——可以直接開啟瀏覽器、截圖、填表、點擊，讓 QA、UX、SRE 角色能夠對 Web 應用執行視覺驗證與 E2E 測試。

Shikigami 目前的三個角色存在此能力缺口：

| 角色 | 缺口描述 |
|------|---------|
| QA Engineer | 只能做靜態程式碼審查，無法執行 E2E 測試或視覺回歸測試 |
| UX Designer | 只能產出 Figma Prototype，無法在真實瀏覽器中驗證 Contract 實作結果 |
| SRE Engineer | 只能分析日誌與 metrics，無法模擬使用者路徑進行可用性監控 |

### 現有工具狀態

Playwright MCP 已出現於 Claude Code 的 available deferred tools 清單中（`mcp__plugin_playwright_playwright__browser_*` 系列），這意味著 Shikigami 框架在 Claude Code 環境中已可間接存取 Playwright 能力，但目前沒有任何 Agent 定義或 Skill 說明如何使用此工具。

---

## Discovery Phase — Step 2：假設外顯化（三問機制）

### 候選需求：Browser Automation 能力引入

**問題 1：這個需求解決了什麼問題？**

QA、UX、SRE 三個 Agent 角色在涉及 Web UI 的場景中，只能依賴靜態分析或間接驗證，無法對實際執行的瀏覽器行為進行驗證。具體痛點：
- QA 的 E2E 測試（測試金字塔 10%）目前無執行路徑
- UX 的 Contract Testability Review 無法在真實環境驗證 Prototype 實作符合度
- SRE 的 Synthetic Monitoring（使用者路徑模擬）無執行工具

**問題 2：我們假設哪些事情是真的？**

| # | 假設 | 標籤 |
|---|------|------|
| A1 | Shikigami 的主要使用者確實在使用框架開發 Web 應用，因此 browser automation 能力對他們有實際用途 | [UNCERTAIN] |
| A2 | Claude Code 環境中的 Playwright MCP 工具足夠穩定，可在 Agent 指令中被可靠調用，不需要額外的 daemon 管理 | [UNCERTAIN] |
| A3 | 為 Agent 定義中新增 browser automation 能力後，Agent 能夠正確判斷何時使用 Playwright 工具，不會產生不必要的瀏覽器操作 | [UNCERTAIN] |
| A4 | Playwright MCP 的工具介面（截圖、點擊、填表等）對 Agent 而言是足夠的，無需 gstack 的持久化 daemon 架構 | [UNCERTAIN] |
| A5 | 引入 browser automation 能力後，不會因 MCP tool call 的 context 消耗而顯著影響執行效率 | [UNCERTAIN] |
| A6 | 三個角色（QA/UX/SRE）的 browser 使用情境足夠不同，需要各自定義使用規範，而非共用單一 skill | [UNCERTAIN] |

**問題 3：如果假設是錯的，會怎樣？**

- A1 為假：若使用者主要開發 CLI 或 API 服務，browser automation 能力對 Shikigami 核心用戶無價值，投入效益低。
- A2 為假：若 Playwright MCP 在 Agent 環境中不穩定（連線中斷、截圖失敗），會降低 QA/UX/SRE Agent 的可靠性。
- A3 為假：Agent 可能在不適當時機啟動瀏覽器，造成不必要的環境副作用或 context 浪費。
- A4 為假：若需要 daemon 才能可靠運作（如 gstack 方案），則需要另行設計 MCP Server 或 hook 機制。
- A5 為假：大量截圖或互動式操作可能消耗過多 context，造成 session 不穩定。
- A6 為假：若三個角色的使用情境高度相似，可共用一個 browser skill，減少維護成本。

---

## 1. 問題陳述（Problem Statement）

Shikigami 框架的 QA Engineer、UX Designer、SRE Engineer 三個 Agent 角色在涉及 Web UI 驗證的場景中存在能力盲點：它們只能執行靜態分析，無法與真實執行的瀏覽器互動。這導致以下具體缺口：

1. **QA E2E 測試無執行路徑**：quality-gate 技能定義測試金字塔含 10% E2E 測試，但目前沒有工具讓 QA Agent 實際執行端對端測試。
2. **UX Contract 驗證只停留在 Prototype 層**：UX Designer 的 Figma Prototype Contract 凍結後，無法在真實瀏覽器中驗證前端實作是否符合 Contract。
3. **SRE 缺少 Synthetic Monitoring 能力**：SRE 無法模擬使用者路徑進行主動可用性探測。

競品 gstack 透過持久化 Chromium daemon 解決了同樣問題。Shikigami 環境中已存在 Playwright MCP（available deferred tools），但無任何 Agent 或 Skill 定義其使用方式。

---

## 2. 目標使用者（Target Users）

**主要使用者：使用 Shikigami 框架開發 Web 應用的工程師與設計師**

- 需要讓 QA Agent 執行真實瀏覽器 E2E 測試的使用者
- 需要讓 UX Agent 在真實環境驗證設計 Contract 實作的使用者
- 需要讓 SRE Agent 進行 Synthetic Monitoring 的使用者

**排除**：
- 不開發 Web 前端的純 API/CLI 服務開發者（對此功能無需求）
- 需要 Web 應用 URL 可訪問（localhost 或 staging 環境）的場景才適用

---

## 3. 商業假設（Business Assumptions）

| # | 假設 | 標籤 | 驗證方式 |
|---|------|------|---------|
| A1 | Shikigami 的主要使用者中，有足夠比例在開發 Web 應用，browser automation 有實際需求 | [UNCERTAIN] | 使用者調查或 GitHub Issue 反應；若 issue 討論中有「如何做 E2E 測試」的問題，可作為需求佐證 |
| A2 | Playwright MCP 在 Claude Code Agent 環境中可被可靠調用，工具調用失敗率可接受 | [UNCERTAIN] | 技術 Spike 驗證：在 Claude Code 環境中執行基礎 Playwright 操作（截圖、導航），觀察穩定性 |
| A3 | Agent 能夠在適當時機正確使用 Playwright 工具，不會產生不必要的瀏覽器操作 | [UNCERTAIN] | 設計明確的觸發條件定義，在 Agent role 定義中限定使用情境 |
| A4 | Playwright MCP 的無 daemon 架構足夠，不需要 gstack 式的持久化 daemon | [UNCERTAIN] | 技術 Spike：對比有無 daemon 在多步驟操作下的穩定性差異 |
| A5 | Browser automation 使用情境在三個角色中足夠不同，值得各自定義規範 | [UNCERTAIN] | 初步設計三角色的 browser 使用場景矩陣，評估重疊度 |

---

## 4. 提案解決方向（Proposed Direction）

基於 Issue #271 的分析結果與 Playwright MCP 已存在的現況，建議分三個維度設計：

### 4.1 Agent 角色定義擴充

在三個 Agent 定義文件中新增 browser automation 使用規範：

- **QA Engineer**（`agents/qa-engineer.md`）：新增 E2E 測試執行章節，定義何時使用 Playwright MCP、使用哪些工具（navigate、snapshot、click、fill_form）、測試結果如何回報
- **UX Designer**（`agents/uiux-designer.md`）：新增 Contract 實作驗證章節，定義 Prototype Contract 凍結後的瀏覽器實作驗證流程
- **SRE Engineer**（`agents/sre-engineer.md`）：新增 Synthetic Monitoring 章節，定義使用者路徑模擬的觸發時機與執行規範

### 4.2 Browser Automation Skill（新 Skill）

建立 `skills/browser-automation/SKILL.md`，定義：
- 可用工具清單與各工具的適用情境
- 三個角色的標準使用情境矩陣
- 截圖命名規範與存放路徑
- 錯誤處理（MCP 不可用時的降級行為）

### 4.3 Quality Gate 擴充

在 `skills/quality-gate/SKILL.md` 的 E2E 測試區段，補充 Playwright MCP 作為執行工具的說明。

---

## 5. 成功指標（Success Metrics）

| 指標 | 基線 | 目標 | 量測方式 |
|------|------|------|---------|
| QA Agent 能成功執行 E2E 測試（Playwright 截圖並回報結果） | 0%（無工具） | 基礎場景成功率 >= 90% | 在測試專案中執行 E2E Story，觀察 QA Agent 截圖與結果回報 |
| UX Agent 能在瀏覽器中驗證 Contract 實作 | 無此流程 | 流程定義完整，可執行 | 設計驗收場景並執行一次完整流程 |
| SRE Agent 能執行 Synthetic Monitoring 路徑 | 無此能力 | 流程定義完整，可執行 | 設計驗收場景並執行一次完整流程 |
| Playwright MCP 調用成功率 | 未知 | >= 95% | Spike 量測 |
| Agent 定義中無歧義的 browser 使用觸發條件 | 0（未定義） | 三角色各有明確觸發條件 | QA Review 確認無歧義 |

---

## 6. 排除範圍（Out of Scope）

- **持久化 Playwright daemon 架構**：不採用 gstack 的 daemon 模式，使用 Playwright MCP 現有介面
- **視覺回歸測試自動化（截圖比對）**：初期不建立基線截圖比對機制，只做行為驗證
- **跨瀏覽器測試矩陣**：初期只支援 Playwright 預設瀏覽器（Chromium），不設計多瀏覽器測試規範
- **CI/CD 整合**：不在本 Brief 範圍內設計 Playwright 在 CI 環境的執行方案
- **非 Claude Code 平台（OpenCode / Gemini CLI / Cursor）的 Playwright MCP 支援**：初期只保障 Claude Code 環境，其他平台可用性標記為「未知」

---

## 7. 依賴與風險（Dependencies & Risks）

### 依賴

| 依賴項目 | 類型 | 說明 |
|---------|------|------|
| Playwright MCP（`mcp__plugin_playwright_playwright__*`） | 技術前提 | 已在 Claude Code available deferred tools 中，但需要技術 Spike 確認在 Agent subagent 環境中的可靠性 |
| QA Agent、UX Agent、SRE Agent 現有定義 | 修改基礎 | 需在現有角色定義上擴充，不應破壞現有行為 |
| quality-gate Skill | 擴充目標 | E2E 測試區段需補充工具定義 |

### 風險

| 風險 | 可能性 | 影響 | 緩解措施 |
|------|-------|------|---------|
| Playwright MCP 在 subagent 環境中不穩定（A2 不成立） | 高 | 高 | **此為阻塞性風險**：必須先執行技術 Spike 驗證可用性，Spike 結論決定是否繼續推進本 Brief |
| Shikigami 主要使用者不開發 Web 應用（A1 不成立） | 中 | 高 | 先透過社群反應（GitHub Issue / PR 討論）收集使用者場景佐證再決定優先級 |
| Agent 在不適當時機觸發 browser 操作（A3 不成立） | 中 | 中 | 在 Agent 定義中嚴格限定觸發條件，設計明確的 Guard Clause |
| Playwright MCP 工具介面在 Agent context 中消耗過多 token（A5 不成立） | 中 | 中 | Spike 中量測截圖等操作的 context 消耗，決定是否需要限制工具使用頻率 |

### 阻塞項

**本 Brief 推進前，必須完成技術 Spike：驗證 Playwright MCP 在 Claude Code subagent 環境中的基礎可用性。**

若 Spike 結論為「不可用」或「不穩定」，本 Brief 需重新評估替代方案（如採用 gstack 的 daemon 架構作為 MCP Server）。

---

### Architect 技術可行性評估

**評估日期**：2026-03-15
**判斷**：有條件可行（需 Spike）

#### 技術可行性分析

1. **Playwright MCP 整合路徑已存在，但可靠性待驗證**
   Playwright MCP 工具已出現在 available deferred tools 清單中，表示基礎整合路徑成立。然而 Shikigami 以 Markdown 定義 Agent 行為，無法在框架層直接控制 MCP tool 的生命週期。若 MCP server 需要 `browser_install` 初始化，而 subagent 環境每次調度都是冷啟動，多步驟操作的狀態連續性（如跨多次 tool call 維持同一個 browser session）是主要技術不確定點。

2. **Skill 架構模式適當，新建 browser-automation Skill 方向正確**
   現有架構中，quality-gate、shoot 等跨角色共用能力均以獨立 Skill 形式定義，browser-automation Skill 符合此架構模式。三個角色（QA/UX/SRE）共用同一個 browser-automation Skill 作為能力底層，各自在 Agent 定義中定義使用情境，符合 Single Responsibility 原則，不引入架構異味。

3. **UX Designer 的整合路徑存在特殊複雜度**
   UX Designer 目前透過 `talk-to-figma-mcp` 操作 Figma，其 Contract 驗證流程設計在 Prototype 凍結後由 QA 執行。若 UX Agent 自身也要使用 Playwright 驗證實作符合度，需釐清職責邊界：是 UX 主動驗證，還是透過 QA 的 Playwright 能力代為驗證。兩者在 Agent 定義上的設計差異需在 Gate 2 明確。

4. **Context 消耗問題比預期嚴重**
   截圖操作（`browser_take_screenshot`）回傳的是 base64 圖片資料，在 Claude context 中佔用大量 token。SRE 的 Synthetic Monitoring 場景若涉及多步驟使用者路徑模擬（如登入→操作→驗證結果），可能在單次 subagent session 中消耗數萬 token。需在 Spike 中量測並設計使用頻率上限。

#### 提案方向技術評語（第 4 區段）

- **4.1 Agent 角色定義擴充**：方向正確。但需注意 UX Designer 的現有流程中，Contract 驗證是 QA 的職責（`QA Contract Testability Review`），若改為 UX 自行使用 Playwright 驗證，可能與現有流程的職責邊界衝突。建議先確認職責分配，再決定是在 UX Agent 還是 QA Agent 定義中增加驗證章節。

- **4.2 Browser Automation Skill（新 Skill）**：架構上應建立，作為三角色能力的 Single Source of Truth。Skill 中需特別定義**降級行為**（MCP 不可用時的 fallback），以及**工具調用前置條件**（必須有可訪問的 URL）。

- **4.3 Quality Gate 擴充**：E2E 測試區段補充 Playwright MCP 為執行工具，方向合理。需同步更新 shoot/SKILL.md 中的 CQ-SMOKE 條件觸發清單（涉及外部資源），確保 Playwright 操作被正確歸類為 CQ-SMOKE 場景。

#### 是否需要 ADR

**需要 ADR**。引入 Playwright MCP 作為 Agent 能力層的瀏覽器自動化工具，涉及：
- 是否採用 daemon 架構 vs 無狀態 MCP tool call 架構的決策
- 三角色共用 Skill vs 各自定義能力的架構選擇
- Context 消耗上限與降級策略

建議在 Spike 結論確認後，立即觸發 ADR。

#### 補充技術風險

| 風險 | 可能性 | 影響 | Architect 評語 |
|------|-------|------|---------------|
| MCP browser session 跨 tool call 狀態不連續（每次 tool call 開新 session） | 中 | 高 | 若確認，多步驟 E2E 測試場景將無法實現，Spike 中必須驗證此點 |
| UX 與 QA 職責邊界不清，導致 Contract 驗證流程重複定義 | 中 | 中 | Gate 2 必須輸出角色職責矩陣，明確誰在何時執行 Playwright 驗證 |
| browser-automation Skill 與 quality-gate Skill 的 E2E 測試描述出現語意重複定義 | 低 | 中 | 設計時以 browser-automation Skill 為 SSOT，quality-gate 引用而非複製 |

---

## Gate Checklist

### Gate 1：問題理解（PO 確認）

- [x] 問題陳述基於 Issue #271 競品分析，三角色缺口有依據
- [x] 目標使用者已識別
- [x] 所有 [UNCERTAIN] 假設已列出
- [ ] 使用者場景佐證收集（驗證 A1）

### Gate 2：範圍收斂（PO + Architect 確認）

- [ ] 技術 Spike 完成：Playwright MCP 在 subagent 環境中基礎可用性確認（驗證 A2、A4、A5）
- [ ] 三角色 browser 使用場景矩陣設計完成（驗證 A3、A6）
- [ ] Out of Scope 已與 Stakeholder 對齊
- [x] **Architect 技術可行性評估完成**：判定「有條件可行（需 Spike）」，已識別 MCP session 連續性、UX 職責邊界、context 消耗三項技術風險，ADR 需求已標注

### Gate 3：Ready for Sprint（PO + QA 確認）

- [ ] User Story 已撰寫（至少覆蓋：QA E2E 執行、UX Contract 驗證、SRE Synthetic Monitoring）
- [ ] AC 已定義，每條 AC 可測試
- [ ] RICE Score 已計算
- [ ] Size 估算已與 Developer/Architect 確認
