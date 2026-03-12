---
title: Calibration Log — 代理人校準記錄
created: 2026-03-12
last_updated: 2026-03-12
maintainer: Developer（每次 Sprint Retrospective 步驟 5 校準儀式後手動更新）
---

# Calibration Log

本文件記錄每個 Sprint Retrospective 中「代理人校準儀式」（步驟 5）的執行結果，包含 Agent 歸納的 Stakeholder 核心價值觀、Stakeholder 修正意見與漂移判定結論。

**校準儀式流程**：詳見 `skills/sprint-review/SKILL.md` §3 步驟 5

**漂移判定標準**：
- Stakeholder 修正任一項價值觀描述 → **偵測到漂移**（差異點須寫入 `docs/km/Decision_Journal.md`）
- 三項均確認無修正 → **無漂移**

---

## 記錄模板

```markdown
### Sprint N 校準記錄

**日期**：YYYY-MM-DD

**Agent 歸納的價值觀**：
1. [價值觀一]
2. [價值觀二]
3. [價值觀三]

**Stakeholder 修正**：
- [修正說明，若無修正填寫「無」]

**漂移判定**：偵測到漂移 / 無漂移
```

---

<!-- 校準記錄從此行以下依 Sprint 編號升序追加 -->

### Sprint 91 校準記錄

**日期**：2026-03-12

**Agent 歸納的價值觀**：
1. Context 紀律 — 少即是多，移除 agent 已知的冗餘內容，每一行 SKILL.md 都必須有存在價值
2. 文件即代碼，品質門禁不可繞過 — .md 是給 agent 消費的，50 個 HARD-GATE 在瘦身中零損失
3. 漸進式演進，同概念工作打包 — 先瘦身再拆分的序列依賴設計，避免在冗餘基礎上建構新結構

**本 Sprint 最重要決策**：US-246（瘦身）嚴格先於 US-245（拆分）序列執行，確保角色 prompt 從已精簡的 SKILL.md 中提取，避免二次清理

**Stakeholder 修正**：待確認

**漂移判定**：待確認

---

### Sprint 90 校準記錄

**日期**：2026-03-12

**Agent 歸納的價值觀**：
1. 實戰驅動框架演進 — 框架功能來源於真實專案實戰經驗，不做假設性需求
2. 文件即代碼，.md 是給 agent 消費的 — 所有 SKILL.md、模板、流程定義以 agent 可消費格式撰寫
3. 同概念工作應打包，AI 團隊沒有工作量限制 — 相關概念 Story 合併同一 Sprint 交付

**本 Sprint 最重要決策**：將 Systematic Debugging 在 Sprint Review 前定義為 HARD-GATE（強制觸發），依據 CloneAI Sprint 73-74 實戰觀察

**Stakeholder 修正**：無

**漂移判定**：無漂移

---

### Sprint 89 校準記錄

**日期**：2026-03-12

**Agent 歸納的價值觀**：
1. 品質先於速度 — 流程不可跳步，品質門禁不可繞過
2. 文件即代碼 — 文件品質等同程式品質，.md 是給 agent 消費的
3. 漸進式架構演進 — 不過度設計，Phase 分步交付，每步可驗證

**本 Sprint 最重要決策**：Sprint 89 僅排 #238 單一 Story（2pt），#189 因 Refinement 未通過（範圍過大、需拆分、外部依賴未驗證）而不排入

**Stakeholder 修正**：價值觀無修正。但補充認知修正：AI 團隊沒有工作量議題，只有資源衝突或限制。同一概念的工作應打包一起做，不該以 Velocity 數字為由拆散。#189 未排入的正當理由是 Refinement 未通過，非「容量不足」。

**漂移判定**：無漂移（三項價值觀確認），認知修正已記錄至 Memory

---

### Sprint 88 校準記錄

**日期**：2026-03-12

**Agent 歸納的價值觀**：
1. 品質先於速度 — 寧可一個 Sprint 少做一個 Story，也不跳過 QA 雙階段審查或外部抽樣
2. 文件即代碼 — .md 是給 agent 消費的，文件品質等同程式品質，SPEC 與 POC 必須交叉驗證
3. 漸進式架構演進 — 先 Definition 再 Delivery，不因框架仍在 doc-only 階段而急於寫程式碼

**本 Sprint 最重要決策**：MCP 三層架構選擇漸進式策略（ADR-019 Option A），以 Quality Observer POC 驗證可行性後再擴展，而非一次全面導入

**Stakeholder 修正**：無

**漂移判定**：無漂移

---

### Sprint 87 校準記錄

**日期**：2026-03-12

**Agent 歸納的價值觀**：
1. 品質先於速度 — 寧可一個 Sprint 少做一個 Story，也不跳過 QA 雙階段審查或外部抽樣
2. 文件即代碼 — .md 是給 agent 消費的，文件品質等同程式品質，SPEC 與 POC 必須交叉驗證
3. 漸進式架構演進 — 先 Definition 再 Delivery，不因框架仍在 doc-only 階段而急於寫程式碼

**本 Sprint 最重要決策**：Solo Mode 設計為 SPEC + POC 雙檔案架構，確保角色封裝規則有具體 QA 場景驗證

**Stakeholder 修正**：無

**漂移判定**：無漂移
