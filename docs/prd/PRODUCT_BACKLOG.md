# Product Backlog

**最後更新**：2026-03-01（Sprint 6 Planning 完成）
**管理者**：Product Owner

---

## 進行中 Stories（Sprint 6）

| Story | Size | Points | ADR |
|-------|------|--------|-----|
| Retro #7：DoD 第 8 層同步 | S | 1 | — |
| Retro #8：QA Review 範圍界定 | S | 1 | — |
| US-T02：Agent 完整性驗證 | S | 1 | ADR-002 |
| US-T03：JSON Schema 驗證 | M | 2 | ADR-002 |
| US-FIX-02：Hard Gate Checklist 機制 | L | 3 | ADR-003 |

> 各 Story 完整 AC 見 `docs/sprints/sprint_6.md`。以下為 QA 修訂後的正式 AC 版本。

### Retro #7：DoD 第 8 層同步

**GitHub Issue**：#7

**Acceptance Criteria**
- AC1：`skills/scrum-master/SKILL.md` 第 8 節 DoD 表格新增「技術債」層，內容與 `skills/sprint-execution/SKILL.md` 對應行完全一致
- AC2：兩份文件 DoD 表格層數相同（8 層），逐行完全一致

### Retro #8：QA Review 範圍界定

**GitHub Issue**：#8

**Acceptance Criteria**
- AC1：`skills/sprint-execution/quality-reviewer-prompt.md` 新增「審查範圍界定」條款：僅審查本次 Story 變更範圍，既存問題不計入 FAIL，應分類為觀察記錄
- AC2：範圍界定條款使用「應分類」而非「可列」

### US-T02：Agent 完整性驗證

**User Story**
As a Developer, I want a script that verifies every agent file has correct frontmatter fields, so that plugin installation doesn't fail silently.

**Acceptance Criteria**（QA 修訂後版本）
- AC1：掃描 `agents/` 下所有 `.md` 檔案，輸出清單，數量與目錄實際 `.md` 檔案數一致
- AC2：驗證 frontmatter 包含 `name`、`description`、`model` 三個欄位；任一缺失則 ERROR
- AC3：驗證 `model` 值為合法值之一：`sonnet`、`haiku`、`opus`（hardcode，大小寫敏感完全比對）
- AC4：驗證 `description` 欄位存在且非空字串；空字串或僅含空白字元則 ERROR
- AC5：exit code 0 = 全部通過，非 0 = 存在至少一個 ERROR

**RICE**：54.0 / **MoSCoW**：Must / **ADR**：ADR-002

### US-T03：JSON Schema 驗證

**User Story**
As a Developer, I want automated validation of plugin.json and marketplace.json, so that malformed manifests are caught before users try to install.

**Acceptance Criteria**（QA 修訂後版本）
- AC1：驗證 `plugin.json` 包含必填欄位：`name`、`version`、`description`、`author`；任一缺失則 ERROR
- AC2：驗證 `marketplace.json` 包含必填欄位：`name`、`plugins` 陣列；任一缺失則 ERROR
- AC3：驗證 `version` 格式符合 semver（`major.minor.patch`，三段純數字，以 `.` 分隔）
- AC4：定義 `plugin.json` 允許欄位白名單：`name`、`version`、`description`、`author`、`homepage`、`license`、`tags`、`minVersion`；白名單以外的欄位觸發 WARNING（非 ERROR），不影響 exit code
- AC5：exit code 0 = 無 ERROR；非 0 = 存在至少一個 ERROR；WARNING 不影響 exit code

> **AC4 決策說明**：原 AC4「不包含多餘路徑欄位」定義模糊。改為 whitelist approach，額外欄位降級為 WARNING 避免 false positive。

**RICE**：25.7 / **MoSCoW**：Must / **ADR**：ADR-002 / **Size**：M（Architect 上調）

### US-FIX-02：Hard Gate Checklist 機制

**User Story**
As a Scrum Master, I want structural Hard Gate checklists at framework document changes, out-of-sprint changes, and ceremony completion, so that process compliance is enforced by mechanism rather than by memory.

**前置條件**：ADR-003（已完成，Accepted）

**Acceptance Criteria**（QA 修訂後版本）
- AC-B1：ADR-003 狀態為 Accepted（前置條件）
- AC-B2：`skills/scrum-master/SKILL.md` 新增 Preflight Check 區段，4 項二元 checklist：(1) 修改對應 Story ID (2) 修改範圍在 AC 涵蓋內 (3) 修改前已讀取目標文件 (4) 修改後執行 health-check
- AC-B3：Framework Document Change Audit 與 ADR-003 觸發條件、checklist 內容、Pass/Fail 判定完全對應
- AC-B4a：Out-of-Sprint Change 偵測邏輯 — 正常路徑須對應 Story ID，無則先建緊急 Story
- AC-B4b：緊急例外路徑 — `[EMERGENCY]` 標注 + 48hr 稽核 + Sprint Review 追蹤
- AC-B5：Ceremony Integrity Audit — Sprint Planning 4 項 + Sprint Review 5 項獨立 checklist

> **AC-B4 拆分說明**：原 AC-B4 混合偵測邏輯與例外路徑，拆分為 B4a（正常路徑）與 B4b（緊急例外），便於獨立驗證。

**RICE**：27.0 / **MoSCoW**：Must / **ADR**：ADR-003 / **Size**：L / **Points**：3

---

## 待選 Stories

### v0.3.0 知識沉澱 — 候選 Stories

（US-09、US-10 已完成；US-11 待排入）

### 測試框架 — 候選 Stories

| 排序 | Story | RICE | MoSCoW | Size | ADR |
|------|-------|------|--------|------|-----|
| 1 | US-T05：交叉引用驗證 | 25.6 | Should | M | — |
| 2 | US-T07：CI Pipeline | 24.0 | Should | M | — |
| 3 | US-T09：孤兒文件清理規範 | 16.7 | Could | S | — |
| 4 | US-T08：Intent Routing 測試 | 6.0 | Could | L | — |

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
