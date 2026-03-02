# Retrospective Log

> 歷史 Retro 記錄：[RETRO_ARCHIVE](archive/RETRO_ARCHIVE.md)（Sprint 1–13）

---

## Sprint 18 — 2026-03-02

**參與角色**：PO、Architect、Developer、QA、Security、Stakeholder

### Good

1. 完成率 100%（連續 Sprint 15-18 四個 Sprint），US-35 全部 9 項 AC 通過驗收，74 項測試零失敗
2. Stakeholder 即時發現 multi-project lock collision bug（ADR-005 鎖名撞名）並修正，角色制衡有效
3. ADR-005 先行完成解鎖 Hard Gate 零阻塞，5 個技術決策域全部 Accepted
4. 三階段 QA 審查（Spec Compliance + Code Quality + Security）全 PASS，Security Review 首次觸發運作正常

### Problem

1. Security Review 發現 skill name 缺少字元白名單驗證（中嚴重度），Developer 實作與 QA Code Quality Review 均未攔截此輸入驗證缺口
2. Code Quality Review 發現 `set -uo pipefail` 缺少 `-e` flag，模板基礎品質有改善空間
3. Token 記錄持續為 N/A（快思模式跳過 Token 測量），成本可見性仍為長尾問題

### Action Items

| # | Action | Owner | 驗收方式 | Issue | 狀態 |
|---|--------|-------|----------|-------|------|
| 1 | schedule skill — skill name 字元白名單驗證，Pre-flight 入口加入正則 `^[a-z0-9][a-z0-9-]{0,63}$` | Developer | 測試套件覆蓋非法字元場景 | #53 | Open |
| 2 | schedule skill — 模板品質強化（`set -euo pipefail` + crontab 備份 `mktemp` + `chmod 600`） | Developer | 模板修正後測試套件驗證 | #54 | Open |

---

## Sprint 17 — 2026-03-02

**參與角色**：PO、Architect、Developer、QA、Stakeholder

### Good

1. 檔案瘦身效果顯著 — PROJECT_BOARD.md 從 266 行縮減至 73 行（-72%），Retrospective_Log.md 從 582 行縮減至 77 行（-87%），US-29 歸檔機制成功建立
2. Phase 1 平行派遣（Retro #41 + Retro #42）零衝突成功，Phase 2 US-29 歸檔作業順利完成
3. QA 雙階段審查全面執行，3 個 Story 共 6 次審查（3 Spec + 3 Quality）全 PASS
4. Sprint 16 Retro Action Items 全數清零（#41 Token cache 修正 + #42 OpenCode POC 佔位），平均關閉速度維持 1 個 Sprint

### Problem

1. PO Round 2 subagent 混淆 Retro #41 Story 內容（「Token cache tokens 加總計算」→「Sprint Review SKILL.md 歷史 Sprint 紀錄截斷修正」），需主 session 人工介入修正，暴露 PO subagent 跨輪次一致性風險
2. Sprint 儀式過重：Stakeholder 反映小任務不需完整 Planning/Review/Retro/Metrics 流程，希望有「短衝模式」快速執行

### Action Items

| # | Action | Owner | 驗收方式 | Issue | 狀態 |
|---|--------|-------|----------|-------|------|
| 1 | 短衝模式設計與實作 — 建立跳過 Sprint 儀式但保留 QA + Architect 審查的快速執行路徑 | Architect | SKILL.md 新增短衝模式定義，含觸發條件、保留項目、文件產出規範 | #47 | Open |
| 2 | PO subagent 跨輪次一致性檢查 — 防止 PO Round 2 混淆或改寫 Round 1 已通過的 Story 內容 | QA | sprint-planning SKILL.md 新增 PO Round 2 輸入驗證步驟 | #48 | Open |

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
| 1 | Token 記錄指引更新：三個 SKILL.md 的 token 提取指引需納入 cache_read_input_tokens + cache_creation_input_tokens 加總計算 | Architect | 三個 SKILL.md 的主要方法描述明確包含 cache tokens 加總規則 | #41 | Closed（Sprint 17） |
| 2 | Sprint 17 Planning 依 US-17 結論評估 OpenCode POC 優先排入 Backlog | PO | Sprint 17 Planning 時 PO 確認是否排入，並記錄決策理由 | #42 | Closed（Sprint 17） |

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
