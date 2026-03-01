# Product Backlog

**最後更新**：2026-03-01（Sprint 5 Review 完成）
**管理者**：Product Owner

---

## 待選 Stories

### v0.3.0 知識沉澱 — 候選 Stories

（US-09、US-10 已完成；US-11 待排入）

### 測試框架 — 候選 Stories

| 排序 | Story | RICE | MoSCoW | Size | ADR |
|------|-------|------|--------|------|-----|
| 1 | US-T02：Agent 完整性驗證 | 54.0 | Must | S | ADR-002 |
| 3 | US-T03：JSON Schema 驗證 | 36.0 | Must | S | ADR-002 |
| 4 | US-T05：交叉引用驗證 | 25.6 | Should | M | — |
| 5 | US-T07：CI Pipeline | 24.0 | Should | M | — |
| 6 | US-T09：孤兒文件清理規範 | 16.7 | Could | S | — |
| 7 | US-T08：Intent Routing 測試 | 6.0 | Could | L | — |

> US-T01 詳情見「進行中 Stories（Sprint 5）」區段（含 QA 修正後版本 AC）。

### 框架品質 — 候選 Stories

| 排序 | Story | RICE | MoSCoW | Size | ADR |
|------|-------|------|--------|------|-----|
| 1 | US-FIX-02：Hard Gate Checklist 機制 | 27.0 | Must | L | ADR-003 |

---

### US-FIX-02：Hard Gate Checklist 機制

**User Story**
As a Scrum Master, I want structural Hard Gate checklists at framework document changes, out-of-sprint changes, and ceremony completion, so that process compliance is enforced by mechanism rather than by memory.

**前置條件**：ADR-003（已完成，Accepted）

**Acceptance Criteria**
- AC-B1：ADR-003 狀態為 Accepted（前置條件）
- AC-B2：`skills/scrum-master/SKILL.md` 新增 Preflight Check 區段：框架文件（skills/、commands/、agents/）修改前自動觸發 4 項二元 checklist
- AC-B3：Framework Document Change Audit 實作為 Hard Gate，checklist 內容與 ADR-003 實作方式一致
- AC-B4：Out-of-Sprint Change Audit 實作為 Hard Gate，含緊急例外路徑（[EMERGENCY] 標注 + 48hr 事後稽核）
- AC-B5：Ceremony Integrity Audit 實作為 Hard Gate，Sprint Planning 與 Sprint Review 各有獨立 checklist

**RICE**：Reach 10 × Impact 3 × Confidence 90% ÷ Effort 1.0 = **27.0**
**MoSCoW**：Must
**ADR**：ADR-003
**Size**：L / **Points**：3

---

### US-T02：Agent 完整性驗證

**User Story**
As a Developer, I want a script that verifies every agent file has correct frontmatter fields, so that plugin installation doesn't fail silently.

**Acceptance Criteria**
- AC1：掃描 `agents/` 下所有 `.md` 檔案
- AC2：驗證 frontmatter 包含 `name`、`description`、`model` 三個欄位
- AC3：驗證 `model` 值為合法值（`sonnet`、`haiku`、`opus`）
- AC4：驗證 `description` 欄位存在且非空

**RICE**：Reach 10 × Impact 3 × Confidence 90% ÷ Effort 0.5 = **54.0**
**MoSCoW**：Must
**ADR**：ADR-002

---

### US-T03：JSON Schema 驗證

**User Story**
As a Developer, I want automated validation of plugin.json and marketplace.json, so that malformed manifests are caught before users try to install.

**Acceptance Criteria**
- AC1：驗證 `plugin.json` 包含必填欄位：`name`、`version`、`description`、`author`
- AC2：驗證 `marketplace.json` 包含必填欄位：`name`、`plugins` 陣列
- AC3：驗證 `version` 格式符合 semver
- AC4：驗證 `plugin.json` 不包含多餘路徑欄位

**RICE**：Reach 10 × Impact 2 × Confidence 90% ÷ Effort 0.5 = **36.0**
**MoSCoW**：Must
**ADR**：ADR-002

---

### US-T05：交叉引用驗證

**User Story**
As a Developer, I want a script that verifies all `shikigami:xxx` references point to existing skills.

**Acceptance Criteria**
- AC1：掃描所有 `*.md` 中的 `shikigami:[a-z-]+` 引用
- AC2：驗證對應的 `skills/<name>/SKILL.md` 存在
- AC3：產出斷掉的引用報告（來源檔案 + 行號 + 引用名稱）

**RICE**：Reach 8 × Impact 2 × Confidence 80% ÷ Effort 0.5 = **25.6**
**MoSCoW**：Should

---

### US-T07：CI Pipeline

**User Story**
As a Developer, I want all structural validation scripts to run automatically on every push, so that broken commits never reach users.

**Acceptance Criteria**
- AC1：建立 `.github/workflows/validate.yml`
- AC2：Pipeline 依序執行 US-T01 到 US-T06 的驗證
- AC3：任一步驟失敗則整體失敗
- AC4：Pipeline 執行時間 < 30 秒

**RICE**：Reach 10 × Impact 3 × Confidence 80% ÷ Effort 1.0 = **24.0**
**MoSCoW**：Should

---

### US-T08：Intent Routing 測試（Prompt Evaluation）

**User Story**
As a Developer, I want a test suite that verifies scrum-master correctly routes user intents to expected skills.

**Acceptance Criteria**
- AC1：至少 20 個測試案例，覆蓋所有 14 個 skill
- AC2：包含邊界案例（模糊意圖、多意圖混合）
- AC3：支援離線 mock 模式
- AC4：結果以表格呈現

**RICE**：Reach 10 × Impact 3 × Confidence 60% ÷ Effort 3.0 = **6.0**
**MoSCoW**：Could（L1/L2 穩定後再做）

---

### US-T09：孤兒文件清理規範

**User Story**
As a Product Owner, I want a defined policy for handling orphan artifacts, so that the repo stays clean.

**Acceptance Criteria**
- AC1：定義「孤兒」判斷規則
- AC2：linter 輸出中標記孤兒（warning 等級）
- AC3：Retro Action Item 逾期問題裁定

**RICE**：Reach 5 × Impact 1 × Confidence 100% ÷ Effort 0.3 = **16.7**
**MoSCoW**：Could

---

## 設計決策：分級自治 + 專案等級

自治行為由**專案等級**決定，影響所有 Skill 的確認閘：

| 專案等級 | 低風險操作 | 高風險操作 | 適用場景 |
|----------|-----------|-----------|----------|
| **low** | 自動執行 | 自動執行，事後通知 | 個人專案、實驗 |
| **medium** | 自動執行 | QA subagent 審核後自動執行 | 一般開發專案 |
| **high** | 自動執行 | 人工確認後執行 | 重要產品、公開 repo |

**原則**：團隊自治優先。預設 medium — QA subagent 取代人工確認閘，確保品質不阻塞工作流程。

---

## 已完成 Stories

歸檔於 [`BACKLOG_DONE.md`](./BACKLOG_DONE.md)，按 Sprint 整理。
