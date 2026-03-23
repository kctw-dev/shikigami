# Product Brief: D3 Framework（Debate-Deliberate-Decide）

**PB ID**: PB-2026-03-23-d3-debate-framework
**狀態**: Draft
**建立日期**: 2026-03-23
**來源議題**: #342 AI Agent 設計研究報告 §2.2（EACL 2026 D3 論文）
**相關議題**: #397 FREE-MAD（互補，不重複）
**產品負責人**: PO Agent

---

## 1. 問題陳述

Shikigami 目前 QA 與 Architect 之間的技術辯論缺乏結構化流程。現況問題：

- **辯論角色不明確**：QA 提出問題後，Architect 回應，但沒有明確的「advocate」、「judge」角色分工，容易變成各說各話
- **缺乏成本感知**：辯論雙方不考慮提案的實施成本，高成本方案可能因論述強勢而通過
- **決策依據不透明**：最終決策是「Scrum Master 拍板」但拍板理由沒有結構化紀錄
- **覆盤困難**：事後無法追溯「為什麼選了方案 A 而非方案 B」，同樣問題下次再辯

FREE-MAD（#397）處理的是「Multi-Agent Decision 的投票與共識機制」，本 PB 聚焦在「辯論流程本身的結構化」，兩者互補：D3 規範辯論格式，FREE-MAD 規範最終決策收斂。

---

## 2. 目標使用者

**主要**：Architect agent 與 QA agent（辯論主體）
**次要**：Scrum Master agent（裁判 / judge 角色）、PO（觀察辯論品質）

使用場景：
- Sprint Planning 時的技術方案選擇（例：用哪個 DB、用哪種 API 設計）
- Sprint Review 時的 defect root cause 辯論
- Architecture Decision Record（ADR）形成前的正式辯論
- 高風險 Story 實作前的 risk assessment

---

## 3. 商業假設 [UNCERTAIN]

- [UNCERTAIN] 結構化辯論流程可提升技術決策品質，減少因論述不充分導致的返工（降低 20% 以上）
- [UNCERTAIN] advocate / judge / jury 角色分離可減少「強勢 agent 壟斷決策」的情況
- [UNCERTAIN] 成本感知對抗（每個論點附上 effort 評估）可讓決策更均衡，避免過度工程
- [UNCERTAIN] D3 辯論紀錄可自動轉換為 ADR 草稿，降低 ADR 撰寫的摩擦

---

## 4. 提案解決方向

### 核心概念
引入三階段辯論流程：Debate（各方提出論點）→ Deliberate（成本感知交叉質詢）→ Decide（judge 基於明確標準裁決）。

### 角色定義（草案）
- **Advocate**：提出並捍衛特定方案（由 Architect 或 Developer 擔任）
- **Challenger**：質疑提案、提出反例（由 QA 或另一位 Architect 擔任）
- **Judge**：制定辯論規則、評估論點品質、最終裁決（由 Scrum Master 擔任）
- **Jury**（選用）：多個 agent 以投票方式輔助 judge（與 FREE-MAD #397 整合）

### 辯論格式（草案）
```
## Debate Round
- [Advocate] 方案描述 + 理由 + 估算成本（S/M/L）
- [Challenger] 反駁點 + 替代方案
- [Advocate] 回應 + 成本比較

## Deliberate
- [Judge] 整理雙方分歧點
- [All] 對分歧點逐一補充證據

## Decide
- [Judge] 裁決依據（明確標準）
- [All] 決策紀錄 → ADR 草稿
```

### 方向 A：新增 D3 Skill
建立 `skills/d3-debate/SKILL.md`，定義完整辯論流程，供 SM 在需要時啟動。

### 方向 B：擴充現有 Sprint Planning Skill
在 Sprint Planning 的技術評估環節嵌入 D3 mini-format（輕量版，3 輪以內）。

推薦方向：**方向 A**（獨立 Skill 更易測試、更易在不同時機啟動），方向 B 可作為整合點。

---

## 5. 成功指標

| 指標 | 基準線 | 目標 | 測量方式 |
|------|--------|------|----------|
| 技術決策有明確書面依據的比率 | 待建立基準 | 80% 以上 | Sprint Review ADR 統計 |
| 因技術決策不充分導致的返工 Story 數 | 待建立基準 | 降低 20% | Sprint 統計 |
| D3 辯論平均耗時（token） | N/A | < 3000 tokens / 場 | token 計費紀錄 |
| 開發者對技術決策透明度的滿意度 | 待建立基準 | NPS +15 | Sprint Retro 問卷 |

---

## 6. 排除範圍

- 不處理非技術性決策（業務需求優先級由 MoSCoW / RICE 處理，不走 D3）
- 不替代 FREE-MAD（#397）的投票機制；D3 聚焦辯論過程，FREE-MAD 聚焦決策收斂
- 不強制所有 Story 都走 D3（只在高風險或有分歧時啟動）
- 不實作即時辯論 UI（文字格式即可，不做可視化辯論介面）

---

## 7. 依賴與風險

### 依賴
- 需要釐清與 FREE-MAD（#397）的整合介面，避免流程重疊
- Scrum Master agent 需要支援「judge」模式（需要角色切換能力）
- ADR 模板需要支援「D3 辯論摘要」區段（可能需要更新 `docs/adr/` 模板）

### 風險
| 風險 | 可能性 | 影響 | 緩解策略 |
|------|--------|------|----------|
| D3 辯論耗費過多 token，拖慢 Sprint | 中 | 高 | 設定辯論輪數上限（max 3 rounds），逾時 judge 強制裁決 |
| Agent 在 advocate 角色中「表演性辯論」而非真實推理 | 中 | 中 | 要求每個論點附上可驗證的依據（file path、測試結果） |
| D3 與 FREE-MAD 流程重疊，產生混淆 | 中 | 中 | 在 D3 Skill 文件明確標注與 FREE-MAD 的分工邊界 |
