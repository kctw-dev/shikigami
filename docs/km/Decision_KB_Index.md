# Decision Knowledge Base Index

**建立日期**：2026-05-11
**最後更新**：2026-05-11（修正：補收 ADR-011）
**維護者**：Developer（手動維護，每次新增或更新 ADR 時同步更新本文件）
**ADR 目錄**：`docs/adr/`

---

## 使用說明

### ADR 查詢介面

本索引提供三種篩選方式，協助快速定位架構決策記錄：

#### 依關鍵字篩選

搜尋 ADR 標題或下方「決策影響追蹤」區段中的關鍵字。常用關鍵字範例：

| 關鍵字 | 相關 ADR |
|--------|---------|
| Backlog | ADR-001、ADR-009、ADR-010 |
| 測試 / 驗證腳本 | ADR-002 |
| SQA / 稽核 / Hard Gate | ADR-003 |
| Retrospective / 關鍵字比對 | ADR-004 |
| 排程 / cron / flock | ADR-005 |
| 注入防護 / Prompt Injection | ADR-006 |
| Subagent / Context overflow | ADR-007 |
| OpenCode / 平台整合 | ADR-008 |
| backlog-intake / 需求入庫 | ADR-009 |
| GitHub Issues / Source of Truth | ADR-010 |
| GitHub Actions / CI/CD / 整合 | ADR-011 |

#### 依狀態篩選

| 狀態 | ADR 列表 |
|------|---------|
| **Accepted**（正式採用） | ADR-001、ADR-002、ADR-003、ADR-004、ADR-005、ADR-006、ADR-007、ADR-008、ADR-009、ADR-010 |
| **Proposed**（起草中，待審查） | ADR-011 |
| **Deprecated**（已棄用） | — |

#### 依日期篩選

| 日期 | ADR |
|------|-----|
| 2026-02-28 | ADR-001 |
| 2026-03-01 | ADR-002、ADR-003、ADR-004 |
| 2026-03-02 | ADR-005、ADR-006、ADR-007 |
| 2026-03-03 | ADR-008、ADR-009、ADR-010 |
| 2026-05-11 | ADR-011 |

---

## ADR 彙整表

| ADR | 標題 | 狀態 | 日期 | 關聯 Story / Issue |
|-----|------|------|------|-------------------|
| [ADR-001](../adr/ADR-001.md) | Backlog Bridge 跨 Skill 編排模式 | Accepted | 2026-02-28 | Backlog Bridge 功能（issue-management Skill） |
| [ADR-002](../adr/ADR-002.md) | 測試框架技術選型 | Accepted | 2026-03-01 | US-T01 ~ US-T09（框架結構驗證測試系列） |
| [ADR-003](../adr/ADR-003.md) | SQA 稽核閘門介入模式 | Accepted | 2026-03-01 | US-22（Retrospective 驅動角色權重自動調整） |
| [ADR-004](../adr/ADR-004.md) | Retrospective Problem 主題比對機制 | Accepted | 2026-03-01 | US-22（Retrospective 驅動角色權重自動調整） |
| [ADR-005](../adr/ADR-005-schedule-skill-technical-decisions.md) | Schedule Skill 技術決策（cron / flock / allowedTools / OAuth / rollback） | Accepted | 2026-03-02 | Issue #46、US-36（跨 Skill 序列鎖） |
| [ADR-006](../adr/ADR-006-prompt-injection-protection.md) | Issue 內容提示注入防護 | Accepted | 2026-03-02 | Issue #55、US-37 |
| [ADR-007](../adr/ADR-007-story-lifecycle-subagent.md) | Story 生命週期 Subagent 封裝 | Accepted | 2026-03-02 | Issue #45、US-39（Sprint 22） |
| [ADR-008](../adr/ADR-008.md) | OpenCode 平台整合策略（Symlink 適配） | Accepted | 2026-03-03 | Issue #3、US-46（Sprint 26）、US-47（Sprint 27） |
| [ADR-009](../adr/ADR-009.md) | Backlog Intake 自動化技術決策 | Accepted | 2026-03-03 | Issue #46、US-63（Sprint 33） |
| [ADR-010](../adr/ADR-010.md) | Backlog Source of Truth — GitHub Issues 優先策略 | Accepted | 2026-03-03 | Issue #46、US-69 ~ US-73（Sprint 35） |
| [ADR-011](../adr/ADR-011-github-actions-integration.md) | GitHub Actions 整合架構決策 | Proposed | 2026-05-11 | Issue #46、Issue #76、US-81（Sprint 38） |

---

## 決策影響追蹤

本區段列出每個 Accepted ADR 影響的 Skills 與文件路徑。
**維護說明**：本區段為靜態手動維護，每次 ADR 狀態變更為 Accepted、或受影響文件有異動時，手動更新對應條目。

---

### ADR-001：Backlog Bridge 跨 Skill 編排模式

**核心決策**：`issue-management` 以委派模式呼叫 `backlog-management`，RICE 評分邏輯集中於 backlog-management。

| 影響類型 | 路徑 | 說明 |
|---------|------|------|
| Skills | `skills/issue-management/SKILL.md` | Backlog Bridge 子流程的步驟 4：invoke backlog-management |
| Skills | `skills/backlog-management/SKILL.md` | RICE 評分邏輯的唯一擁有者 |

---

### ADR-002：測試框架技術選型

**核心決策**：採用純 Bash 腳本 + 共享函式庫（`scripts/lib/validate-helpers.sh`）。

| 影響類型 | 路徑 | 說明 |
|---------|------|------|
| 腳本 | `scripts/lib/validate-helpers.sh` | 共享輔助函式庫 |
| 腳本 | `scripts/validate-commands.sh` | Command 路由驗證（US-T06） |
| 腳本 | `scripts/validate-version.sh` | 版號一致性驗證（US-T04） |
| 腳本 | `scripts/validate-skills.sh` | Skill 完整性驗證（US-T01） |
| 腳本 | `scripts/validate-agents.sh` | Agent 完整性驗證（US-T02） |

---

### ADR-003：SQA 稽核閘門介入模式

**核心決策**：分級介入 — Framework Document Change 與 Ceremony Integrity 採 Hard Gate；Story Completion DoD Audit 採 Soft Gate。

| 影響類型 | 路徑 | 說明 |
|---------|------|------|
| Skills | `skills/sqa-audit/SKILL.md` | SQA 稽核閘門的實作主體 |
| Skills | `skills/quality-gate/SKILL.md` | Hard Gate 機制定義 |
| Skills | `skills/scrum-master/SKILL.md` | §6.1「不阻塞原則」與此 ADR 的相容性 |
| Skills | `skills/sprint-planning/SKILL.md` | Ceremony Integrity Hard Gate：Sprint Planning 必要條件 |
| Skills | `skills/sprint-review/SKILL.md` | Ceremony Integrity Hard Gate：Sprint Review 必要條件 |

---

### ADR-004：Retrospective Problem 主題比對機制

**核心決策**：關鍵字清單比對（多關鍵字、可演進），確保決策確定性優先。

| 影響類型 | 路徑 | 說明 |
|---------|------|------|
| Skills | `skills/sprint-planning/SKILL.md` | §3 Role Weight Check：關鍵字清單定義與比對演算法 |
| 文件 | `docs/km/Retrospective_Log.md` | 關鍵字比對的資料來源 |

---

### ADR-005：Schedule Skill 技術決策

**核心決策**：cron 排程、flock 互斥鎖、SKILL.md frontmatter `requiredTools`、OAuth 認證（unset ANTHROPIC_API_KEY）、原子性回滾。

| 影響類型 | 路徑 | 說明 |
|---------|------|------|
| Skills | `skills/schedule/SKILL.md` | 核心受影響 Skill，排程部署全流程定義 |
| Skills | `skills/*/SKILL.md`（所有計劃排程的 Skill） | frontmatter 需新增 `requiredTools` 欄位 |
| 腳本 | `scripts/shikigami-schedule-*.sh`（生成腳本） | 排程腳本的生成格式與 Pre-flight 邏輯 |

---

### ADR-006：Issue 內容提示注入防護

**核心決策**：XML 資料隔離標記 + 角色限制宣告（Prompt Injection Isolation Rule）。

| 影響類型 | 路徑 | 說明 |
|---------|------|------|
| Skills | `skills/sprint-execution/SKILL.md` | §3 Issue 快掃：PO subagent prompt 建構步驟須套用 Isolation Rule |
| Skills | `skills/backlog-intake/SKILL.md` | 繼承 ADR-006 完整兩條規則（ADR-009 §決策域三定義） |

---

### ADR-007：Story 生命週期 Subagent 封裝

**核心決策**：完整 Story-Lifecycle Subagent（選項 B），主 session 僅接收摘要；審查獨立性補償機制（30% 抽樣審查）。

| 影響類型 | 路徑 | 說明 |
|---------|------|------|
| Skills | `skills/sprint-execution/SKILL.md` | §3 執行流程：改為派遣 Story-Lifecycle subagent |
| 文件 | `skills/sprint-execution/story-lifecycle-prompt.md` | Story-Lifecycle subagent 的 prompt 定義（Developer + self-review） |
| 文件 | `docs/km/Metrics_Log.md` | 自審通過率、外部抽樣執行率、DISPUTE 率追蹤 |

---

### ADR-008：OpenCode 平台整合策略

**核心決策**：Symlink 適配（`.opencode/skills -> ../skills`）、雙平台標注、subagent 設定檔存放於 `.opencode/agents/`。

| 影響類型 | 路徑 | 說明 |
|---------|------|------|
| 目錄結構 | `.opencode/skills` | symlink 指向 `skills/`，零重複維護 |
| 目錄結構 | `.opencode/agents/` | OpenCode subagent 設定檔目錄 |
| 文件 | `AGENTS.md` | OpenCode 框架入口（對應 CLAUDE.md） |
| 文件 | `docs/km/OPENCODE_POC.md` | Phase 1/2 調查與驗證記錄 |
| Skills | `skills/*/SKILL.md` | R-1 至 R-7 殘留項加入雙平台標注 |

---

### ADR-009：Backlog Intake 自動化技術決策

**核心決策**：GitHub Issues 為輸入來源（`backlog-intake` label 過濾）、繼承 ADR-006 Injection 防護、OAuth 認證（繼承 ADR-005）、`backlog-intake-done` label 冪等性保護。
**注意**：格式契約決策域已由 ADR-010 取代（Superseded）。

| 影響類型 | 路徑 | 說明 |
|---------|------|------|
| Skills | `skills/backlog-intake/SKILL.md` | 核心受影響 Skill（輸入來源、冪等性、Injection 防護） |
| Skills | `skills/schedule/SKILL.md` | §使用範例：`/schedule backlog-intake` 的 cron 範例 |

---

### ADR-010：Backlog Source of Truth — GitHub Issues 優先策略

**核心決策**：GitHub Issues 為唯一 Backlog source of truth；PRODUCT_BACKLOG.md 降級為唯讀快照；兩層 label 體系；Sprint Planning 改用 `gh issue list`。

| 影響類型 | 路徑 | 說明 |
|---------|------|------|
| Skills | `skills/backlog-intake/SKILL.md` | 輸出目標從寫入 .md 改為為 Issue 套用 label + 填補 Story template |
| Skills | `skills/sprint-planning/SKILL.md` | PO Story 選取來源改為 `gh issue list`；加入即時排序計算邏輯 |
| Skills | `skills/backlog-management/SKILL.md` | Grooming 流程改為操作 GitHub Issues；加入 Pre-flight 錯誤恢復掃描 |
| 文件 | `docs/prd/PRODUCT_BACKLOG.md` | 降級為唯讀歷史快照，加入 DEPRECATED 標頭 |
| ADR | `docs/adr/ADR-009.md` | 格式契約決策域標注「Superseded by ADR-010」 |

---

## 維護指引

新增 ADR 時，請依序執行：

1. 在 ADR 彙整表新增一行（含標題、狀態、日期、關聯 Story/Issue）
2. 在決策影響追蹤區段新增對應條目（至少一筆影響路徑記錄）
3. 更新「依關鍵字篩選」與「依狀態篩選」表格
4. 記錄本次更新日期於本文件頂部「最後更新」欄位
