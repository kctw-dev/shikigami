# Sprint 43

**狀態**：進行中
**期間**：2026-03-04 ~ 2026-03-10
**Sprint Goal**：為 Backlog 下一個發展方向奠定決策基礎：精化 #69（開發不中斷）為可執行 Story，並執行 M5 外部觸及效果最終診斷，確認對外最後一哩是否有可改善空白。
**總計**：2 Stories / 3 Points

---

## Sprint Backlog

| Story ID | Issue # | 標題 | Size | Points | Phase | 狀態 |
|----------|---------|------|------|--------|-------|------|
| US-90 | #69 | Issue #69 精化 — 「開發不中斷 營運不中斷」可行性分析與 Story 拆解 | S | 1 | Phase 1（平行） | 完成 |
| US-91 | #85 | M5 條件 (a) 觸及診斷 — Outreach Log 審查 + 安裝阻力掃描 | M | 2 | Phase 1（平行） | 完成 |

**Sprint 容量**：3 Points

---

## 平行分群方案

| Phase | Stories | 說明 |
|-------|---------|------|
| Phase 1（全平行） | US-90、US-91 | 修改檔案不重疊：US-90 僅操作 GitHub Issue #69（body 更新 + 可能建立新 Issues）；US-91 修改 M5_COMPLETION_ASSESSMENT.md、OUTREACH_LOG.md、可能修改 README.md 與 tutorial/ 文件 |

**平行可行性判定**：APPROVED — 兩個 Story 的檔案修改路徑無交集，可同時執行。

---

## Story 詳細 AC

---

### US-90：Issue #69 精化 — 可行性分析與 Story 拆解

**來源**：Backlog Item — Issue #69
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：Yes（僅更新 GitHub Issue body + 可能建立新 Issues）
**ADR 參考**：無（精化分析不需 ADR；後續實作子 Stories 可能需要）

**User Story**

As a PO, I want to decompose Issue #69 into actionable Stories, so that the team has executable backlog items for the next Sprint.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 拆解 #69 為至少 2 個獨立子主題（認證輪流 / 模型分級 / 他牌模型） | 每個子主題有獨立描述，邏輯邊界清晰 |
| AC2 | [靜態] | 每個子主題 RICE 初評 | Reach/Impact/Confidence/Effort 各給分並說明依據 |
| AC3 | [靜態] | 判定哪些子主題需 ADR 前置或 POC 驗證 | 每個子主題有明確的 ADR/POC 需求標記與理由 |
| AC4 | [靜態] | 輸出至少 1 個精化 User Story draft，更新至 GitHub Issue #69 body 或建立新 Issue | User Story 格式完整（As a... I want... So that... + AC 清單 + 估點） |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 1 | 僅影響 PO 決策品質 |
| Impact | 3 | 為未來 3+ Sprint 奠定方向 |
| Confidence | 0.9 | |
| Effort | 0.5 | S-size |
| **RICE Score** | **5.4** | R×I×C/E |

**Done 定義**

- [x] 拆解 #69 為至少 2 個獨立子主題
- [x] 每個子主題 RICE 初評完成
- [x] ADR 前置需求判定完成
- [x] 至少 1 個精化 User Story draft 輸出
- [x] Issue #69 body 更新或新 Issue 建立

---

### US-91：M5 條件 (a) 觸及診斷 — Outreach Log 審查 + 安裝阻力掃描

**來源**：M5 完成條件 (a) 推進 — Issue #85
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：No（AC1 需執行 gh CLI，AC5 需動態修正）
**ADR 參考**：無

**User Story**

As a PO, I want to diagnose the current external user acquisition situation, so that I can decide whether to continue waiting or take a new action to fulfill M5 condition (a).

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [動態] | `gh issue view 59 --comments`，更新 `docs/prd/M5_COMPLETION_ASSESSMENT.md` | Issue #59 累積回饋數記錄至招募行動記錄表 |
| AC2 | [靜態] | 審查 `docs/km/OUTREACH_LOG.md` | 確認最後一次 outreach 行動時間距今天數，評估推廣行動空窗 |
| AC3 | [靜態] | 端到端安裝路徑快速審查（README.md → docs/tutorial/GETTING_STARTED.md → docs/tutorial/README.md） | 確認是否有自 US-61（Sprint 32）以來新增的阻力點 |
| AC4 | [靜態] | 診斷報告輸出至 `docs/prd/M5_COMPLETION_ASSESSMENT.md` 新增「Sprint 43 觸及診斷」章節 | 必填欄位：(i) 累積回饋數 (ii) 最後 outreach 距今天數 (iii) 安裝路徑阻力項目數 (iv) 觸及狀態評估 (v) 建議下一步 |
| AC5 | [動態] | 修正發現的 doc-level 安裝阻力 | 僅修正 broken links、版本號不一致、outdated instructions；程式碼層級阻力另開 Story |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響所有潛在外部使用者 |
| Impact | 3 | M5 唯一剩餘阻礙的直接診斷 |
| Confidence | 0.8 | |
| Effort | 1 | M-size |
| **RICE Score** | **7.2** | R×I×C/E |

**Done 定義**

- [x] Issue #59 回饋數確認並記錄
- [x] OUTREACH_LOG.md 審查完成
- [x] 端到端安裝路徑審查完成
- [x] 診斷報告輸出至 M5_COMPLETION_ASSESSMENT.md
- [x] doc-level 安裝阻力已修正（若有發現）
- [x] Issue #85 關閉

---

## ADR 觸發清單

| Story | ADR | 觸發原因 | 動作 |
|-------|-----|----------|------|
| US-90 | — | 精化分析不需 ADR；AC3 將判定後續子 Stories 的 ADR 需求 | — |
| US-91 | — | 無 ADR 觸發 | — |

---

## Sprint Planning 簽核記錄

| 角色 | 確認項目 | 狀態 |
|------|----------|------|
| Product Owner | Sprint Goal 對齊 Backlog 發展方向 + M5 條件 (a) 推進，US-90 + US-91 優先級確認 | 已確認 |
| Architect | US-90 S-size + US-91 M-size 技術可行性，Phase 1 全平行 APPROVED | 已確認 |
| QA | US-90 AC1-AC4 驗收標準（4/4 PASS）；US-91 AC1-AC5 驗收標準（AC4 已精化修正，5/5 PASS） | 已確認 |
| Developer | Story 清晰度確認，Phase 1 全平行執行可行 | 待確認 |

**Sprint Planning 決策記錄**

- Sprint 43 選入 2 Stories（US-90 + US-91），共 3 Points
- 平行分群：Phase 1 全平行（檔案範圍無重疊）
- US-90 doc-only 判定：Yes（僅操作 GitHub Issues）
- US-91 doc-only 判定：No（AC1 需 gh CLI，AC5 需動態修正）
- Milestone "Sprint 43" (#7) 建立於 GitHub，Issue #69、#85 已設定 in-sprint 標籤
- Backlog 現況：極薄（#69 為唯一 backlog item），US-90 精化後可為 Sprint 44 準備新 Stories
- QA 回饋：US-91 AC4 已補充輸出位置與必填欄位；AC5 已限制為 doc-level 修正
