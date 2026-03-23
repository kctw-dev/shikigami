# Product Brief: Token 成本控制（Risk-based Model Routing）

**PB ID**: PB-2026-03-23-token-cost-routing
**狀態**: Draft
**建立日期**: 2026-03-23
**來源議題**: #342 AI Agent 設計研究報告 §4.1
**產品負責人**: PO Agent

---

## 1. 問題陳述

Shikigami 目前所有 agent（含 subagent）統一使用 `model: sonnet`，無論任務風險等級高低。這造成：

- **成本浪費**：低風險、高重複性任務（格式轉換、log 摘要、基本 CRUD 生成）消耗與高風險任務相同的 token 單價
- **資源錯配**：需要深度推理的關鍵決策（架構設計、安全審查、跨 Story 依賴分析）與簡單任務用同一模型，前者可能需要更強的能力
- **預算不可預測**：無法根據 Sprint 內容預估 token 成本，難以做容量規劃
- **缺乏成本意識**：agent 設計時沒有「這個任務值多少 token」的概念，導致濫用高價模型

OpenAI 等業界實踐指出：根據任務風險評分（complexity、stakes、reversibility）路由到不同等級 model，可在品質不下降的前提下顯著降低成本。

---

## 2. 目標使用者

**主要**：持續使用 Shikigami 跑多個 Sprint 的開發者（對 token 成本有感）
**次要**：企業內部部署 Shikigami 需要做 token budget 管控的 DevOps / Platform 團隊

使用場景：
- 長 Cruise 巡航多個 repo：大量低風險分析任務
- Sprint 內大量 Story 並行：混合高低風險任務
- 自動化測試執行：幾乎全部是低風險、高重複性任務

---

## 3. 商業假設 [UNCERTAIN]

- [UNCERTAIN] Shikigami 任務可按風險分成至少三級（高/中/低），且分類準確率可達 80% 以上
- [UNCERTAIN] 低風險任務佔所有 agent 呼叫的 40–60%，成功路由可降低整體成本 25–35%
- [UNCERTAIN] haiku 等級模型處理低風險任務的品質可接受（錯誤率不超過現有 sonnet 的 1.5 倍）
- [UNCERTAIN] 風險評分可以在不增加額外 LLM 呼叫的前提下由 meta-agent 或 hook 完成

---

## 4. 提案解決方向

### 核心概念
在 subagent 派發前，由 Scrum Master 或 dispatcher hook 對任務進行風險評分，根據分數路由到對應 model tier。

### 風險評分維度（草案）
- **Reversibility**：任務結果是否可輕易回滾（高 = haiku 候選）
- **Stakes**：錯誤是否影響 production 或 user-facing 功能（高 = opus 候選）
- **Complexity**：任務是否需要跨多個上下文的推理（高 = sonnet/opus）
- **Novelty**：任務是否有明確範本可循（低 = haiku 候選）

### 方向 A：靜態分類規則（Rule-based）
在 agent 定義中標記預設 model tier，PO/Architect 手動分類每類任務。簡單但靈活性低。

### 方向 B：動態評分（SM meta-prompt）
Scrum Master 在派發 subagent 前，執行輕量評分 prompt，輸出 tier 決策。成本較高但自適應。

### 方向 C：混合模式
高風險任務 hardcode 使用 sonnet/opus，低風險任務預設 haiku，中風險任務由 SM 動態判斷。

推薦方向：**方向 C**（靜態規則覆蓋確定性任務，動態評分處理模糊地帶，平衡成本與彈性）。

---

## 5. 成功指標

| 指標 | 基準線 | 目標 | 測量方式 |
|------|--------|------|----------|
| 每 Sprint 平均 token 成本 | 待建立基準 | 降低 25% | token 計費紀錄 |
| 低風險任務路由準確率 | N/A | ≥ 80% | QA 抽樣審查 |
| haiku 路由任務的品質可接受率 | N/A | ≥ 95% | Sprint Review 品質評分 |
| Story 完成率（與路由前比較） | 待建立基準 | 持平（±5%） | Sprint 統計 |

---

## 6. 排除範圍

- 不自行訓練或 fine-tune 風險分類模型
- 不修改 Claude API 呼叫介面（在 agent 定義層處理，非底層）
- 不處理 model 不可用時的 fallback 機制（此為基礎設施議題）
- 不跨 provider 路由（不涉及 GPT、Gemini 等非 Anthropic 模型的整合）

---

## 7. 依賴與風險

### 依賴
- CLAUDE.md 規範「所有 agent 統一使用 model: sonnet」需要正式修訂，允許例外
- 需要 token 計費觀測基準（quality-observer MCP 或外部 telemetry）
- Scrum Master agent 需要支援在派發前插入評分步驟（hook 或 prompt 修改）

### 風險
| 風險 | 可能性 | 影響 | 緩解策略 |
|------|--------|------|----------|
| haiku 模型在邊界任務上失敗，增加重試成本 | 中 | 高 | 設定自動升級機制：haiku 失敗 → 自動 retry with sonnet |
| 風險評分本身耗費額外 token，抵消節省效益 | 中 | 中 | 優先做靜態規則分類，只在模糊任務做動態評分 |
| 開發者不信任低端模型，手動 override 頻繁 | 低 | 低 | 提供 override 機制，同時記錄 override 原因供後續分析 |
| CLAUDE.md 「model: sonnet 統一」規範與此方向衝突 | 高 | 高 | 先與 Architect 對齊修訂規範，再實作路由邏輯 |
