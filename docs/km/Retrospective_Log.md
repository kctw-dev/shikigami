# Retrospective Log

> 歷史 Retro 記錄：[RETRO_ARCHIVE](archive/RETRO_ARCHIVE.md)（Sprint 1–13）

---

## Sprint 16 — 2026-03-02

**參與角色**：PO、Architect、Developer、QA、Stakeholder、SRE

### Good

1. 連續 16 個 Sprint 完成率 100%（6/6 Stories, 8/8 Points, Velocity 8pt），為歷史最高產出 Sprint 之一
2. QA Hard Gate（Must）全面執行，6 個 Story 共 12 次審查（6 Spec + 6 Quality）全 PASS，Sprint 14 觸發的 QA 升級機制運作正常
3. Sprint 15 Retro Action Items 全部清零（#37 ToC 補充 + #38 Token JSONL 調查），平均關閉速度維持 1 個 Sprint
4. Phase 1 平行派遣（Retro #37 + US-17）零衝突成功，Phase 2 序列執行（4 個 ADR-003 觸發 Story）亦全部順利
5. 快思/慢想雙模式（US-28）成功導入 sprint-planning SKILL.md 與 standup command，為日常迭代效率提升奠定結構基礎

### Problem

1. Token 記錄 cache tokens 處理不明確：JSONL 中 `input_tokens` 僅 292，但 `cache_read_input_tokens` 達 25M，現有三個 SKILL.md 的 token 提取指引僅提及 `input_tokens` + `output_tokens`，導致 Execution token 記錄數值失真
2. Sprint 16 Velocity 8pt 大幅超過近 3 Sprint 平均 3.3pt（242%），雖全部完成但需觀察是否為一次性高產出而非可持續節奏

### Action Items

| # | Action | Owner | 驗收方式 | Issue | 狀態 |
|---|--------|-------|----------|-------|------|
| 1 | Token 記錄指引更新：三個 SKILL.md 的 token 提取指引需納入 cache_read_input_tokens + cache_creation_input_tokens 加總計算 | Architect | 三個 SKILL.md 的主要方法描述明確包含 cache tokens 加總規則 | #41 | Open |
| 2 | Sprint 17 Planning 依 US-17 結論評估 OpenCode POC 優先排入 Backlog | PO | Sprint 17 Planning 時 PO 確認是否排入，並記錄決策理由 | #42 | Open |

---

## Sprint 15 — 2026-03-02

**參與角色**：PO、Architect、Developer、QA、Stakeholder、SRE

### Good

1. 連續 15 個 Sprint 維持 100% 完成率，Velocity 從 Sprint 14 的 2pt 回升至 4pt，確認品質優先策略不影響長期交付能力
2. 首次交付面向外部使用者的完整文件套件（Tutorial + Troubleshooting + 安裝驗證），M5 穩定化使用者就緒目標正式達成
3. Issue 快掃回覆 5 個 open issues（#3, #4, #5, #32, #33），QA 審核發現 2 個事實錯誤（#5 前提條件層級混淆、#33 路徑描述不精確）並修正後發布，品質門禁延伸至社群互動
4. QA 雙階段審查完整執行（Hard Gate Must），兩個 M-size Story 共 4 次審查（2 Spec + 2 Quality）全 PASS

### Problem

1. Token JSONL 提取持續失敗（連續 Sprint 14/15 均 N/A），Sprint 10 建立的 JSONL 提取機制在新 session 格式下完全失效，Token 成本分環節記錄表格累計 3 個 Sprint 無法自動填入
2. Code Quality Review 發現 2 個 Important 問題（GETTING_STARTED.md 缺 ToC、TROUBLESHOOTING.md 歷史問題標題定性模糊）未於本 Sprint 修復，PASS 門檻內但品質標準應更嚴

### Action Items

| # | Action | Owner | 驗收方式 | Issue | 狀態 |
|---|--------|-------|----------|-------|------|
| 1 | GETTING_STARTED.md 補上 ToC 目錄 | Developer | `docs/tutorial/GETTING_STARTED.md` 包含 7 步驟錨點目錄，與 TROUBLESHOOTING.md 格式對齊 | #37 | Closed（Sprint 16） |
| 2 | Token JSONL 提取機制需重新調查 session 格式變化 | Architect | Token 成本分環節記錄表格至少有一個 Sprint 的 Planning/Execution/Review 為非 N/A | #38 | Closed（Sprint 16） |

---

## Sprint 14 — 2026-03-02

### 參與角色
PO、Architect、QA Engineer、Developer、Stakeholder

### Good
1. **連續 14 個 Sprint 完成率 100%** — 團隊交付節奏持續穩定
2. **QA Hard Gate（Must）首次執行，品質門檻正確運作** — ADR-004 觸發後首個 Sprint，雙階段審查無 Bypass，US-15/US-16 因 AC 不完整被正確退回
3. **Sprint 13 Retro Action Items 全數清零** — #29 和 #30 均在 Sprint 14 首輪完成
4. **Phase 1 全平行策略成功** — 兩個 Story 修改不同檔案，零合併衝突

### Problem
1. **Sprint 14 Velocity 僅 2 points（歷史最低）** — 原因是 Backlog 中無符合 QA Hard Gate 要求的候選 Story 可補足容量。品質優先決策正確，但 Velocity 下降反映 Backlog 健康度不足（US-15/US-16 無正式 AC）
2. **US-15/US-16 在 PRODUCT_BACKLOG.md 無正式條目** — ROADMAP 列出但 Backlog 未建立完整 Story（含 AC），PO 需在下次 Planning 前完成精化

### Action Items

| # | Action | Owner | 驗收方式 | Issue | 狀態 |
|---|--------|-------|----------|-------|------|
| 1 | US-15/US-16 Backlog 精化：PO 在下次 Sprint Planning 前，為 US-15 和 US-16 在 PRODUCT_BACKLOG.md 建立完整 Story 條目（含 AC 表格），使其符合 QA Hard Gate 要求 | PO | 下次 Sprint Planning 時 QA 確認 AC 可測試性為 PASS | [#31](https://github.com/KCTW/shikigami/issues/31) | Closed（Sprint 15 Planning — US-15/US-16 AC 精化完成，QA 確認可測試性 PASS，已選入 Sprint 15） |
