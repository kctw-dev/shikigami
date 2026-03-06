# Gemini CLI 能力邊界調查報告

**文件類型**：調查報告
**撰寫日期**：2026-03-06
**關聯 Story**：US-121（Issue #108）
**關聯 ADR**：ADR-014（UIUX Agent 架構決策）
**撰寫者**：Architect（Story Lifecycle Subagent）

---

## 1. 執行摘要

本報告針對 Gemini CLI 在 ADR-014 三層 UIUX Agent 管線（UX Agent / UI Agent / Vision Critic Agent）各任務中的能力邊界進行調查，並評估 Claude Code + Gemini CLI 混合協作場景的潛在價值。

**核心結論**：Gemini CLI 在三層管線的大多數任務中不具備足以取代 Claude Code 的優勢，但在兩個特定場景下有互補價值：（1）Figma MCP 設計稿直接轉碼、（2）超大型程式碼庫多模態上下文分析。考量整合成本與現有 ADR-014 架構決策，**建議暫不整合 Gemini CLI 至主要管線，改為標記為 Phase 4 候選技術，等待 Figma 整合場景確認後再評估。**

---

## 2. 調查背景

### 2.1 三層管線架構回顧（ADR-014）

ADR-014 定義了以下三層 UIUX Agent 管線：

```
User Story
    │
    ▼
UX Agent（資訊架構骨架）
    │ 輸出：語意化骨架文件 JSON（Skeleton Document）
    ▼
UI Agent（前端代碼生成）
    │ 約束：Tailwind CSS + Shadcn UI + Design Tokens
    │ 輸出：React 前端代碼
    ▼
Vision Critic Agent（視覺品質審查）
    │ 輸入：前端截圖 + Design Tokens
    ├─ PASS → 交付後端串接
    └─ FAIL → 結構化退件報告 → 回到 UI Agent
```

### 2.2 調查範疇

本報告針對以下三個 Acceptance Criteria 進行調查：

- **AC1**：Gemini CLI 在三層管線各任務（UX 分析、UI 代碼生成、視覺評分）的能力邊界
- **AC2**：Claude Code + Gemini CLI 最有價值的協作場景定義
- **AC3**：是否整合 Gemini CLI 的決策建議，附 RICE 評估

### 2.3 額外調查面向（Sprint 54 背景）

Sprint 54 期間團隊同步評估 Figma 整合（ADR-015 Proposed）。本報告額外涵蓋：
- Gemini 的多模態能力在 Figma 操作場景的潛在價值
- Gemini 3 Figma MCP 整合最新狀態
- Gemini vs Claude 在視覺審查任務上的差異

---

## 3. Gemini CLI 現狀調查（2026-03 基線）

### 3.1 核心模型能力（Gemini 3 Pro）

截至 2026-03，Gemini CLI 主要依託 Gemini 3 Pro 模型，關鍵能力如下：

| 能力面向 | 評估 | 說明 |
|---------|------|------|
| Context Window | 1M token | 與 Claude Sonnet 4.6 相當（均為 200K-1M 範圍） |
| 多模態輸入 | 支援 | 可接受圖片（截圖、UI 設計稿）、PDF、影片 |
| 圖片分析 | 強 | Gemini 3 被評為「multimodal 最強模型」，可分析 UI 截圖、識別設計問題 |
| 程式碼生成 | 良好 | 前端 UI 代碼生成評價尤佳（特別是視覺多樣性） |
| 自主性 | 中等 | 複雜任務執行時需要人工引導次數多於 Claude Code |
| Figma MCP 整合 | 原生支援 | Figma 官方提供 `figma-gemini-cli-extension`，官方 Figma MCP Server 原生支援 Gemini CLI |
| 工具集 | 內建 + MCP | Google Search、檔案操作、Shell 命令、Web Fetch，可透過 MCP 擴充 |

### 3.2 Figma 整合深度

Figma 官方 MCP Server（2026-02-25 正式推出）對 Gemini CLI 的支援值得特別關注：

| 整合面向 | 說明 |
|---------|------|
| 官方支援 | Figma MCP Server 原生支援 Gemini CLI（與 Claude Code、Codex 同等級） |
| 設計稿轉碼 | 透過 `@figma-gemini-cli-extension`，可直接從 Figma frame link 生成程式碼 |
| 元件庫對應 | 有 Code Connect 配置時，MCP Server 自動對應 Figma 元件至代碼庫元件，避免重複創建 |
| 設計變數提取 | 可存取 Figma 設計變數、元件層級、版面資料 |
| 準確率 | 業界測試報告約 80-90%（在既有設計系統下） |
| 認證方式 | 在 Gemini CLI 執行 `/mcp auth figma` 即完成認證 |

---

## 4. AC1：能力邊界分析——三層管線各任務

### 4.1 UX 分析任務（UX Agent 層）

**任務說明**：接收 User Story，產出語意化資訊架構骨架文件（Skeleton Document JSON）

| 評估面向 | Claude Code（現行）| Gemini CLI | 說明 |
|---------|-------------------|------------|------|
| 語意理解 | 優 | 良好 | Claude 在細粒度語意推理上表現更穩定 |
| 資訊架構思維 | 優 | 良好 | Claude 在遵循嚴格 JSON Schema 規格方面更可靠 |
| Schema 符合性 | 優 | 中等 | Gemini 在複雜 Schema 約束下有時產出不符格式 |
| 執行自主性 | 優 | 中等 | Gemini 複雜任務需要引導，Claude 全自主完成 |
| 超長 User Story 處理 | 優 | 優 | 兩者 1M context 均可處理超大型規格文件 |
| Figma 設計稿輸入 | 不支援* | 原生支援 | *Claude 可接受截圖但無 Figma MCP 語意層 |

**結論**：在純文字規格輸入場景，Claude Code 優於 Gemini CLI。若 Figma 整合落地（ADR-015），Gemini CLI 的 Figma MCP 原生整合能力將成為 UX 層的重要差異點。

### 4.2 UI 代碼生成任務（UI Agent 層）

**任務說明**：接收骨架文件 + Design Tokens，生成 Tailwind CSS + Shadcn UI 前端代碼

| 評估面向 | Claude Code（現行）| Gemini CLI | 說明 |
|---------|-------------------|------------|------|
| 前端代碼品質 | 優 | 良好 | Claude 錯誤更少、符合 Design Tokens 約束更穩定 |
| 視覺多樣性 | 中等 | 優 | Gemini 3 被評為「前端視覺多樣性更豐富」，擅長探索不同佈局風格 |
| Design Token 注入 | 優 | 中等 | Claude 在嚴格約束下 hardcode 風險低；Gemini 偶有繞過 Token 約束 |
| Tailwind 合規 | 優 | 良好 | 兩者均可生成 Tailwind，但 Claude 合規率更高 |
| 元件庫白名單 | 優 | 中等 | Claude 在白名單約束下更可靠 |
| Figma 設計稿轉碼 | 不支援* | 優 | *ADR-015 情境下 Gemini CLI + Figma MCP 可直接從設計稿生成代碼 |
| 執行成本 | ~$4.80/任務* | ~$7.06/任務* | *實測資料，Gemini 因重試次數多成本較高 |

**結論**：純代碼品質與約束合規性，Claude Code 優勢明顯。若 ADR-015 Figma 整合落地，Gemini CLI 的 Figma → Code 直接生成能力（80-90% 準確率）可大幅縮短 UX → UI 的手工轉換時間。

### 4.3 視覺評分任務（Vision Critic Agent 層）

**任務說明**：接收 UI 截圖 + Design Tokens 規格，輸出 PASS/FAIL 視覺審查報告

| 評估面向 | Claude Sonnet 4.6（現行）| Gemini 3 Pro | 說明 |
|---------|--------------------------|--------------|------|
| 截圖分析能力 | 優 | 優 | 兩者均原生支援圖片輸入，可識別 UI 佈局、顏色對比 |
| WCAG 對比度分析 | 優 | 良好 | Claude 在 WCAG 規格遵循上更精確 |
| Design Token 規格對照 | 優 | 中等 | Claude 在 JSON 規格對照分析上更可靠 |
| 視覺審美評估 | 良好 | 優 | Gemini 3 多模態能力更強，視覺感知可能更敏銳 |
| 結構化 JSON 輸出 | 優 | 中等 | Gemini 在複雜 Schema 下結構化輸出穩定性較低 |
| 退件報告格式化 | 優 | 中等 | ADR-014 OQ-3 定義的退件報告 JSON Schema 需要穩定格式化輸出 |
| 截圖直接輸入 | 支援（@screenshot）| 支援（@screenshot）| 均可接受截圖作為輸入 |

**結論**：視覺審查任務中，兩者均有多模態截圖分析能力。Claude 在規格對照與結構化輸出方面更穩定，符合 ADR-014 OQ-3 定義的量化評分機制需求。Gemini 3 的視覺感知可能更豐富，但在嚴格 JSON Schema 輸出場景可靠性較低。

---

## 5. AC2：最有價值的協作場景定義

基於能力邊界分析，識別以下三個潛在協作場景，並評估其價值。

### 場景一：Figma → Skeleton Document（Gemini CLI 主導）

**適用條件**：ADR-015 Figma 整合落地後

```
Figma 設計稿（設計師產出）
    │
    ▼ [Gemini CLI + Figma MCP]
    │  - 直接讀取 Figma frame 設計變數
    │  - 分析元件層級與佈局結構
    │  - 生成初版 Skeleton Document JSON
    ▼
Claude Code（UX Agent）
    │  - 驗證 Skeleton Document JSON Schema 合規性
    │  - 補充語意化互動說明（Figma 無法表達的動態邏輯）
    │  - 輸出最終骨架文件
    ▼
UI Agent（現行 Claude Code 管線繼續）
```

**價值評估**：高。Figma MCP 整合可將「設計稿 → 骨架文件」的手工翻譯步驟自動化，減少資訊遺失，提升骨架文件與設計意圖的一致性。

**前置條件**：ADR-015 Figma 整合決策通過。

### 場景二：UI 代碼生成多樣性探索（Gemini CLI 輔助）

**適用條件**：UI Agent 首次生成方案時，需要多個佈局風格備選

```
Skeleton Document + Design Tokens
    │
    ├─[Claude Code] → 嚴格 Token 合規版本（生產品質，主方案）
    │
    └─[Gemini CLI]  → 視覺多樣性探索版本（替代風格，供設計師選擇）
    │
    ▼
設計師選擇 → 交由 Claude Code 統一做 Token 合規精修 → Vision Critic 審查
```

**價值評估**：中低。在純 AI 自動化管線中，多樣性探索的人工介入不符合全自動化目標。僅在「設計師仍在迴圈中」的 Human-in-the-loop 場景有價值。

**前置條件**：需要設計師介入選擇，與全自動管線目標衝突。

### 場景三：Vision Critic 第二意見（Gemini CLI 並行審查）

**適用條件**：高風險 UI 功能需要雙重視覺審查

```
UI Agent 輸出截圖
    │
    ├─[Claude Sonnet 4.6] → 主要視覺審查（ADR-014 OQ-3 定義標準）
    │
    └─[Gemini 3 Pro]     → 補充視覺感知審查（異常偵測）
    │
    ▼
兩者均 PASS → 交付；任一 FAIL → 退件（保守策略）
```

**價值評估**：低。雙重審查增加 LLM 呼叫成本，且兩審查結果不一致時需要裁決邏輯，增加管線複雜度。ADR-014 的 Vision Critic 設計已足夠，不需要額外審查層。

---

## 6. AC3：決策建議

### 6.1 RICE 評估

#### 選項 A：整合 Gemini CLI 於 Figma → Skeleton Document 步驟（ADR-015 觸發）

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響所有有 Figma 設計稿的前端 Story |
| Impact | 3 | 消除設計稿手工翻譯，大幅提升骨架文件品質 |
| Confidence | 0.5 | 前置依賴 ADR-015 決策，高不確定性 |
| Effort | 3 | 需整合 Figma MCP + Gemini CLI + 現有管線，架構變更複雜 |
| **RICE Score** | **1.5** | R×I×C/E |

**適用情境**：ADR-015 Figma 整合決策通過後，可作為 Phase 4 Gemini CLI 引入的觸發條件。

#### 選項 B：整合 Gemini CLI 作為 Vision Critic 輔助審查

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 2 | 影響高風險 UI Story 的視覺審查 |
| Impact | 1 | 已有完整 Vision Critic，增量價值有限 |
| Confidence | 0.8 | 技術可行但業務價值不明確 |
| Effort | 2 | 需新增並行審查路徑 + 裁決邏輯 |
| **RICE Score** | **0.8** | R×I×C/E |

**結論**：RICE Score 過低，不建議採用。

#### 選項 C：暫不整合，標記為 Phase 4 候選技術

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 保留未來整合彈性 |
| Impact | 2 | 記錄調查結論，為 Phase 4 決策提供基礎 |
| Confidence | 1.0 | 調查結論確定，不整合風險為零 |
| Effort | 0.5 | 僅需記錄文件 |
| **RICE Score** | **12.0** | R×I×C/E |

### 6.2 決策建議

**建議採用選項 C：暫不整合 Gemini CLI，標記為 Phase 4 候選技術。**

**理由如下**：

#### 理由一：ADR-014 現行架構已足夠

ADR-014 Phase 1-3 的三層 Agent 管線以 Claude Code 為核心，設計完整且技術可行性已確認。引入 Gemini CLI 會增加架構複雜度，違反 YAGNI 原則。

#### 理由二：Gemini CLI 的核心優勢依賴 ADR-015 前置決策

Gemini CLI 最有差異化價值的場景（Figma MCP 整合）需要 ADR-015 Figma 整合決策先行。在 ADR-015 尚未確定前，整合 Gemini CLI 存在方向性風險。

#### 理由三：Claude Code 在管線核心任務全面領先

在 Schema 合規性、Design Token 約束遵循、結構化 JSON 輸出三個對三層管線最關鍵的評估面向，Claude Code 均優於 Gemini CLI。視覺審查任務（Vision Critic）使用 Claude Sonnet 4.6 的可靠性高於替換為 Gemini。

#### 理由四：執行成本更高

業界測試顯示 Gemini CLI 完成同等任務的成本（$7.06）高於 Claude Code（$4.80），且需要更多人工引導。與全自動 Agent 管線目標相悖。

#### 理由五：Gemini vs Claude 視覺審查差異不構成切換理由

雖然 Gemini 3 在視覺感知豐富性上有優勢，但 ADR-014 OQ-3 的三維度量化評分（色彩一致性 40% + 元件位置 35% + 間距合規性 25%）需要穩定的 JSON 結構化輸出，Claude Sonnet 4.6 在此場景的可靠性更符合需求。

---

## 7. Gemini vs Claude 視覺審查任務差異對照

為具體回應 Sprint 54 背景調查項目，以下提供兩者在視覺審查場景的詳細差異：

| 評估面向 | Claude Sonnet 4.6 | Gemini 3 Pro |
|---------|-------------------|--------------|
| 截圖輸入支援 | 原生支援（PNG/JPEG/WebP/GIF） | 原生支援（同上） |
| 視覺元素識別精度 | 高 | 高 |
| WCAG 無障礙規格遵循 | 優（可引用具體 SC 條款） | 良好（較少 SC 條款細粒度） |
| Design Token 規格對照 | 優（JSON Schema 對照分析穩定） | 中等（複雜 JSON 比對易出錯） |
| 結構化 JSON 輸出 | 優（Schema 合規率高） | 中等（偶有格式偏差） |
| 視覺審美豐富性 | 良好 | 優（Gemini 3 多模態為業界最強）|
| Figma 設計稿直接輸入 | 不支援（需截圖） | 支援（透過 Figma MCP 讀取語意層）|
| 退件報告 JSON 格式一致性 | 優 | 中等 |
| 成本效益 | 較高 | 較低（重試成本高） |

**結論**：Vision Critic 任務以 Claude Sonnet 4.6 為主力仍是正確決策。若未來 ADR-015 Figma 整合落地，可考慮以 Gemini CLI 讀取 Figma 設計語意層（而非截圖），作為 Vision Critic 的上游設計意圖輸入，但核心審查邏輯仍建議保留 Claude。

---

## 8. Figma 整合場景 Gemini CLI 潛在價值分析

考量 ADR-015 Proposed 的 Figma 整合評估需求，本節專項分析 Gemini CLI 在 Figma 操作場景的潛在價值。

### 8.1 Figma MCP 整合現狀

| 面向 | 說明 |
|------|------|
| 官方支援狀態 | Figma 官方 MCP Server（2026-02-25 發布）原生支援 Gemini CLI |
| 認證方式 | `/mcp auth figma`（一行命令） |
| 設計稿讀取 | 可透過 Figma frame link 提取設計變數、元件層級、Code Connect 配置 |
| 代碼生成準確率 | 約 80-90%（在既有設計系統下） |
| 元件庫對應 | Code Connect 配置存在時，自動對應 Figma 元件至代碼庫元件 |

### 8.2 Gemini CLI 在 Figma 場景的優勢

1. **語意層讀取**：透過 Figma MCP，Gemini CLI 可讀取 Figma 的設計語意（變數名稱、元件名稱、設計意圖），而非僅處理截圖像素。這比 Claude 目前的「截圖分析」更接近設計師的設計意圖。

2. **Design Token 對應**：Figma 設計變數（Design Variables）可直接對應至專案的 Design Tokens，避免人工翻譯。

3. **元件庫橋接**：Code Connect 配置讓 Figma 元件與 Shadcn UI 等代碼庫元件直接對應，消除 UI Agent 的元件白名單偵測負擔。

4. **官方生態整合**：Figma 官方維護 `figma-gemini-cli-extension`，整合深度優於可能的 Claude + Figma MCP 整合。

### 8.3 對 ADR-015 評估的建議

若 ADR-015 Figma 整合決策傾向「AI 直接操作 Figma」模式，建議在 ADR-015 的選項分析中加入「Gemini CLI + Figma MCP」作為候選方案之一，理由如下：

- Figma 官方原生支援 Gemini CLI，整合維護風險低
- 可利用 Gemini 3 強大的多模態能力直接解析 Figma 設計稿語意層
- 80-90% 的設計稿轉碼準確率（在既有設計系統下）具備實用價值

---

## 9. 總結與行動建議

### 9.1 決策建議

| 決策 | 說明 |
|------|------|
| **暫不整合 Gemini CLI** | 當前管線以 Claude Code 為核心，技術完備，引入 Gemini CLI 違反 YAGNI |
| **標記為 Phase 4 候選技術** | 在 ADR-015 Figma 整合決策後，重新評估 Gemini CLI 的整合價值 |
| **ADR-015 應包含 Gemini CLI 選項** | Figma MCP 原生支援讓 Gemini CLI 在 Figma 整合場景具備競爭優勢 |
| **Vision Critic 維持 Claude Sonnet 4.6** | JSON Schema 輸出穩定性與 WCAG 規格遵循是關鍵，Claude 優勢明顯 |

### 9.2 後續行動建議

| 行動 | 優先級 | 觸發條件 |
|------|--------|---------|
| ADR-015 Figma 整合評估納入 Gemini CLI + Figma MCP 選項 | 高 | ADR-015 啟動時 |
| Gemini CLI Figma MCP PoC 驗證（80-90% 準確率實測）| 中 | ADR-015 通過後 |
| 評估以 Gemini CLI 替換 UX Agent 的 Figma 輸入路徑 | 低 | Phase 4 |

### 9.3 DoD 自檢

- [x] AC1：Gemini CLI 在三層管線各任務的能力邊界已調查完成（§4）
- [x] AC2：Claude Code + Gemini CLI 協作場景已定義（§5，共三個場景，含價值評估）
- [x] AC3：是否整合的決策建議已產出，附 RICE 評估（§6）
- [x] Figma 整合場景潛在價值已分析（§8）
- [x] Gemini vs Claude 視覺審查差異對照已完成（§7）

---

## 參考資料

- [Gemini CLI GitHub Repository](https://github.com/google-gemini/gemini-cli)
- [Gemini 3 — Google DeepMind](https://deepmind.google/models/gemini/)
- [Figma MCP Server 官方指南](https://help.figma.com/hc/en-us/articles/32132100833559-Guide-to-the-Figma-MCP-server)
- [figma/figma-gemini-cli-extension](https://github.com/figma/figma-gemini-cli-extension)
- [Gemini CLI + Figma MCP Server 整合教學](https://medium.com/google-cloud/gemini-cli-figma-mcp-server-turn-design-into-code-in-minutes-88ba219615c6)
- [Claude Code vs Gemini CLI 比較（Shipyard, 2026-01）](https://shipyard.build/blog/claude-code-vs-gemini-cli/)
- [Figma Make with Claude 4.6 or Gemini 3（UX Planet, 2026-02）](https://uxplanet.org/figma-make-with-claude-4-6-or-gemini-3-70d3b380f14a)
- [Hybrid AI Workflows: Spawning Gemini from Claude Code](https://paddo.dev/blog/gemini-claude-code-hybrid-workflow/)
- ADR-014：UIUX Agent 架構決策（`docs/adr/ADR-014-uiux-agent-architecture.md`）
