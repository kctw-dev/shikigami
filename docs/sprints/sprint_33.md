# Sprint 33

**狀態**：進行中
**期間**：2026-04-06 ~ 2026-04-12
**Sprint Goal**：以 Issue #46 第四條流程「需求入庫自動化」為核心交付，同步啟動 M5 外部使用者觸及的主動推廣行動與 Backlog 精化
**總計**：3 Stories / 4 Points

---

## Sprint Backlog

| Story ID | 標題 | Size | Points | QA doc-only 判定 | 狀態 |
|----------|------|------|--------|-----------------|------|
| US-63 | Issue #46 子 Story #4 — 需求入庫自動化（PO Backlog Intake cron + shikigami:backlog-intake Skill） | M | 2 | No | 完成 |
| US-64 | M5 條件 (a) 主動觸及強化 — 外部社群推廣文案製作（GitHub README badges + 技術文章草稿 + 主動 outreach 指引） | S | 1 | Yes | 完成 |
| US-65 | US-T08（Intent Routing 測試）評估重開 — RICE 重新評分與 Sprint Planning 可行性確認 | S | 1 | Yes | 完成 |

**Sprint 容量**：4 Points

---

## Story 詳細 AC

---

### US-63：Issue #46 子 Story #4 — 需求入庫自動化

**來源**：GitHub Issue #46 子 Story #4
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：No

**User Story**
As a Product Owner managing the Backlog, I want a cron-driven backlog intake skill that automatically pulls new GitHub Issues into the Product Backlog in structured User Story format, so that incoming requirements are captured without manual PO intervention and the Backlog stays current between Sprint cycles.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | ADR-009 建立且 Accepted | `docs/adr/ADR-009.md` 建立，涵蓋五決策域：(1) 輸入來源模型 (2) 格式契約 (3) injection 防護邊界（明確說明與 ADR-006 的繼承或補充關係） (4) cron 認證策略（明確引用 ADR-005 決策域四並標注繼承範圍） (5) 冪等性保護 |
| AC2 | [靜態] | SKILL.md 建立 | `skills/backlog-intake/SKILL.md` 建立完成，frontmatter 包含 name、description、requiredTools；定義輸入格式契約（至少 1 種輸入來源）與解析流程（至少 3 步條列） |
| AC3 | [靜態] | cron 腳本模板可生成 | `/schedule backlog-intake` Pre-flight 可通過（requiredTools 格式驗證、OAuth 認證狀態、flock 可用性），可生成符合 ADR-005 規格的 cron 腳本模板。前置條件：AC2 requiredTools 已正確填寫 |
| AC4 | [靜態] | ADR-003 Checklist | 修改 `skills/` 下 SKILL.md 前確認 ADR-003 四項條件全部通過 |

---

### US-64：M5 條件 (a) 主動觸及強化 — 外部社群推廣文案製作

**來源**：M5 條件 (a) 外部使用者觸及 / Sprint 33 Planning
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：Yes

**User Story**
As a Product Owner tracking M5 condition (a) completion, I want README badges, a technical article draft, and a proactive outreach guide created, so that Shikigami gains visible external credibility signals and the team has actionable materials to drive community reach toward the M5 external user engagement target.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | README badges | `README.md` 新增 badges（版本號 + license），連結有效，位置在 H1 標題之後 |
| AC2 | [靜態] | OUTREACH_LOG.md 建立 | `docs/km/OUTREACH_LOG.md` 建立，欄位結構含推廣日期/管道/行動摘要/累積回饋數；說明與 M5_COMPLETION_ASSESSMENT.md 的分工（OUTREACH_LOG 記錄所有推廣行動細節，M5 文件僅追蹤條件達成狀態） |
| AC3 | [靜態] | M5 追蹤更新 | `docs/prd/M5_COMPLETION_ASSESSMENT.md` 條件 (a) 追蹤更新，反映本 Story 推廣行動 |

---

### US-65：US-T08（Intent Routing 測試）評估重開

**來源**：PRODUCT_BACKLOG.md 測試框架候選 Stories / Sprint 33 Planning
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：Yes

**User Story**
As a Product Owner managing the Backlog, I want US-T08 Intent Routing test re-evaluated with updated RICE scoring that reflects current Skill count and tooling improvements, so that I can make an informed Go/No-Go decision on whether to schedule this story in a future sprint.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | RICE 重新評分 | 重新閱讀 US-T08 定義，確認 Skills 數量（當前非 14 個）、mock 可行性、既有驗證腳本可降低 Effort，輸出包含 RICE 各維度數值的重算報告 |
| AC2 | [靜態] | Go/No-Go 決策與 Backlog 更新 | 更新 `docs/prd/PRODUCT_BACKLOG.md`：含 Go/No-Go 明確決策；若 Go 則更新 RICE 分數與建議 Size；若 No-Go 則標記為「延後」或「取消」 |

---

## 平行分群（Architect 建議）

### Phase 1 — 全部可平行執行

| 群組 | Stories | 說明 |
|------|---------|------|
| Phase 1（平行） | US-63 | 新建 docs/adr/ADR-009.md + skills/backlog-intake/SKILL.md；需 ADR-009 新建與 ADR-003 Checklist 通過 |
| Phase 1（平行） | US-64 | 修改 README.md + 新建 docs/km/OUTREACH_LOG.md + 修改 docs/prd/M5_COMPLETION_ASSESSMENT.md；與 US-63 / US-65 無共同修改檔案，可平行 |
| Phase 1（平行） | US-65 | 修改 docs/prd/PRODUCT_BACKLOG.md；與 US-63 / US-64 無共同修改檔案，可平行 |

**執行順序說明**：
- 所有 3 Stories 可完全平行執行，無共同修改檔案
- 本 Sprint 無 Phase 2

---

## 工作容量

| 項目 | 數值 |
|------|------|
| Sprint 期間 | 2026-04-06 ~ 2026-04-12（7 天） |
| 總 Stories | 3 |
| 總 Points | 4 |
| 平行分群 | Phase 1（US-63 + US-64 + US-65 全部平行）；無 Phase 2 |

---

## ADR 觸發清單

| Story | ADR 編號 | 說明 |
|-------|----------|------|
| US-63 | ADR-009（新建） | 需求入庫自動化技術決策，五決策域：輸入來源模型、格式契約、injection 防護邊界、cron 認證策略、冪等性保護 |
| US-64 | 無新 ADR | ADR-003 不適用（修改範圍為 README.md + docs/ 目錄，不在 skills/commands/agents/ 範圍內） |
| US-65 | 無新 ADR | ADR-003 不適用（修改範圍為 docs/prd/ 目錄） |

---

## Sprint Planning 簽核

- **PO Round 1**：完成（Story 選取：US-63 M/2pt + US-64 S/1pt + US-65 S/1pt；Sprint Goal 確定；總計 4pt）
- **Architect Round 1**：完成（US-63 需 ADR-009 新建；平行分群：全部 Phase 1 平行，無 Phase 2；AC 路徑與衝突分析通過）
- **QA Round 1**：完成（US-63 AC 修正 3 項已整合；US-64 AC2 修正已整合；doc-only 判定：US-63 No / US-64 Yes / US-65 Yes；US-63 AC1 injection 防護邊界與 ADR-006 關係明確化；US-63 AC1 cron 認證策略引用 ADR-005 決策域四；US-63 AC2 requiredTools 與 SKILL.md frontmatter 要求明確化）
- **PO Round 2**：完成（整合 Architect/QA 反饋；AC 最終確認；Sprint Backlog 最終確認；總計 4pt / 3 Stories）
