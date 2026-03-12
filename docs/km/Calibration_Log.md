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
