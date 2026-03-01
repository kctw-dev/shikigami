# Backlog Done — 已完成 Stories 歸檔

按 Sprint 整理，保留完整 RICE 評分與驗收標準。

---

## Sprint 1（2026-02-28）

**Sprint Goal**：建立 Issue Management Skill 基礎 + 專案等級自治框架

| Story | RICE | MoSCoW | ADR | 完成狀態 |
|-------|------|--------|-----|----------|
| Story 5：專案等級自治策略 | 24.0 | Must | — | Done |
| Story 1：Issue Lifecycle Management | 8.0 | Must | — | Done |
| ADR-001：Backlog Bridge 編排模式 | — | — | Accepted | Done |
| Story 2：Backlog Bridge | 8.4 | Must | ADR-001 | Done |
| Story 3：Issue Comment | 6.0 | Should | — | Done |
| Story 4：Issue Triage | 5.6 | Should | — | Done |

---

### Story 5：專案等級自治策略

**標題**：依專案等級決定自治程度

**User Story**
As a Scrum Master, I want the framework to adjust autonomy level based on project importance, so that low-stakes projects move fast while critical projects maintain quality gates.

**Acceptance Criteria**
- AC1：在 scrum-master Skill 中定義三個專案等級（low / medium / high）
- AC2：專案等級可在 CLAUDE.md 中設定（`shikigami.project_level: medium`）
- AC3：各等級自治策略如下表
- AC4：未設定時預設為 `medium`
- AC5：所有 Skill 的確認閘行為依專案等級調整

**RICE 評分**
| 維度 | 分數 |
|------|------|
| Reach | 10 |
| Impact | 3 |
| Confidence | 80% |
| Effort | 1 人週 |
| **RICE Score** | **24.0** |

**MoSCoW**：Must

---

### Story 1：Issue Lifecycle Management

**標題**：完整 GitHub Issue 生命週期管理

**User Story**
As a Product Owner, I want to list, create, close, and label GitHub issues using the Shikigami framework, so that I can manage the full issue lifecycle without leaving the AI workflow.

**Acceptance Criteria**
- AC1：支援 `list`（列出 issue，可篩選 state / label / assignee）
- AC2：支援 `create`（新增 issue，帶 title / body / label / assignee）
- AC3：支援 `close`（關閉 issue，可附理由留言）
- AC4：支援 `label`（新增或移除 label）
- AC5：支援 `assign`（指派處理人）
- AC6：低風險操作（label、assign）自動執行；高風險操作（close）由 QA subagent 審核後自動執行

**RICE 評分**
| 維度 | 分數 |
|------|------|
| Reach | 8 |
| Impact | 2 |
| Confidence | 100% |
| Effort | 2 人週 |
| **RICE Score** | **8.0** |

**MoSCoW**：Must

---

### Story 2：Backlog Bridge（Issue 轉 Backlog）

**標題**：將 GitHub Issue 轉換為 Backlog User Story

**User Story**
As a Product Owner, I want to convert a GitHub issue into a formatted User Story in the product backlog, so that external feature requests and bug reports are automatically captured in the Sprint planning process.

**Acceptance Criteria**
- AC1：讀取指定 issue 的內容，生成符合 Shikigami 格式的 User Story（含 RICE 評分建議與 MoSCoW 分類）
- AC2：由 QA subagent 審核生成品質後自動寫入 `docs/prd/PRODUCT_BACKLOG.md`
- AC3：在對應的 GitHub Issue 上留言，說明「已轉入 Backlog」（由 QA subagent 審核留言內容後自動發布）
- AC4：在 issue 加上 `in-backlog` label（自動執行，低風險）

**RICE 評分**
| 維度 | 分數 |
|------|------|
| Reach | 7 |
| Impact | 3 |
| Confidence | 80% |
| Effort | 2 人週 |
| **RICE Score** | **8.4** |

**MoSCoW**：Must
**ADR**：ADR-001 — 採用委派模式

---

### Story 3：Issue Comment（自動回覆）

**標題**：對 GitHub Issue 留言回覆

**User Story**
As a Developer or Product Owner, I want to post comments on GitHub issues in response to user reports, so that issue reporters receive timely feedback.

**Acceptance Criteria**
- AC1：根據 issue 內容自動生成回覆草稿
- AC2：由 QA subagent 審核草稿品質後自動發布（高風險操作，公開留言）
- AC3：支援常見回覆場景：確認收到、要求補充資訊、說明已修復、Won't Fix 說明
- AC4：留言中可帶入 issue 編號、相關 PR 連結等動態內容

**RICE 評分**
| 維度 | 分數 |
|------|------|
| Reach | 6 |
| Impact | 1 |
| Confidence | 100% |
| Effort | 1 人週 |
| **RICE Score** | **6.0** |

**MoSCoW**：Should

---

---

## Sprint 2（2026-02-28）

**Sprint Goal**：讓框架能感知自己的狀態

| Story | RICE | MoSCoW | ADR | 完成狀態 |
|-------|------|--------|-----|----------|
| US-07：Health Check Skill | 27.0 | Must | — | Done |
| US-S01：Standup 遠端差距感知 | 63.3 | Must | — | Done |

---

### US-07：Health Check Skill

**標題**：框架自我診斷

**User Story**
As a Scrum Master, I want to check the framework's health status with a single command, so that I can immediately identify broken configurations, orphan artifacts, and overdue action items without manually inspecting each file.

**Acceptance Criteria**
- AC1：skills/health-check/SKILL.md 存在且含有效 frontmatter；scrum-master 決策樹含 health-check 路由
- AC2：檢查 ./CLAUDE.md、docs/PROJECT_BOARD.md、docs/prd/PRODUCT_BACKLOG.md；缺失或為空標記 FAIL
- AC3：掃描 sprint_N.md 中的 Story，反向驗證存在於 PRODUCT_BACKLOG.md 或 BACKLOG_DONE.md
- AC4：ADR 欄位非「—」的 Story，驗證 ADR 文件存在且狀態為 Accepted
- AC5：Retrospective_Log.md 中 Open Action Items，超 14 天標記 OVERDUE
- AC6：報告含 Overall Status + 4 項檢查 + 修復建議
- AC7：4 項檢查全部出現，即使通過亦顯示 PASS

**RICE 評分**
| 維度 | 分數 |
|------|------|
| Reach | 10 |
| Impact | 3 |
| Confidence | 90% |
| Effort | 1.0 |
| **RICE Score** | **27.0** |

**MoSCoW**：Must

---

### US-S01：Standup 遠端差距感知

**標題**：Standup 報告新增 Git 同步狀態

**User Story**
As a Developer, I want the daily standup to show the git sync status between local and remote, so that I can immediately know if I need to pull or push before starting work.

**Acceptance Criteria**
- AC1：standup 報告新增 Git 同步狀態區塊；顯示未推送 commits；無 tracking branch 時顯示提示
- AC2：先 git fetch（超時 5 秒），顯示未拉取 commits；N > 0 附警告
- AC3：git remote 為空時靜默略過
- AC4：git fetch 超時/失敗時降級顯示

**RICE 評分**
| 維度 | 分數 |
|------|------|
| Reach | 10 |
| Impact | 2 |
| Confidence | 95% |
| Effort | 0.3 |
| **RICE Score** | **63.3** |

**MoSCoW**：Must

---

### Story 4：Issue Triage（自動分類）

**標題**：自動 Triage 新進 GitHub Issue

**User Story**
As a Product Owner, I want to automatically triage new GitHub issues by classifying them and applying labels, so that issues are actionable without manual overhead.

**Acceptance Criteria**
- AC1：列出指定 repo 中所有 open、無 label 的 issues
- AC2：對每個 issue 分析標題與描述，判定類型（bug / feature-request / question / docs / invalid）
- AC3：自動套用對應 label（低風險，自動執行）
- AC4：若 issue 缺少重現步驟（bug 類型）或驗收標準（feature-request 類型），由 QA subagent 審核留言後自動發布補充資訊請求
- AC5：Triage 結果以摘要表格呈現給團隊知會

**RICE 評分**
| 維度 | 分數 |
|------|------|
| Reach | 7 |
| Impact | 2 |
| Confidence | 80% |
| Effort | 2 人週 |
| **RICE Score** | **5.6** |

**MoSCoW**：Should

---

## Sprint 3（2026-03-01）

**Sprint Goal**：完成 v0.2.0 自我感知，並修復跨兩個 Sprint 的行為性缺陷

| Story | RICE | MoSCoW | ADR | 完成狀態 |
|-------|------|--------|-----|----------|
| US-06：Onboarding（專案初始化） | 40.8 | Must | — | Done |
| US-T04：版號一致性驗證 | 48.0 | Should | — | Done |

> 備注：Story 1（Retro #3）和 Story 3（Retro #2）為 Retro Action Items，不是 Backlog Stories，不歸入此表。

---

### US-06：Onboarding（專案初始化）

**標題**：新使用者專案初始化自動引導

**User Story**
As a new user, I want Shikigami to automatically scaffold my project's document structure after installation, so that I can start my first Sprint within 5 minutes without manually creating directories or copying templates.

**Acceptance Criteria**（Sprint 3 Planning QA 修正後）

| # | 條件 | 通過標準 |
|---|------|----------|
| AC1 | 觸發與路由 | (a) `skills/onboarding/SKILL.md` 存在且 frontmatter 含 `name` 與 `description` 欄位；(b) `skills/scrum-master/SKILL.md` 5.1 決策樹新增一條「意圖描述 → invoke shikigami:onboarding」路由 |
| AC2 | 目錄結構建立 | 執行後 `docs/prd/`、`docs/adr/`、`docs/sprints/`、`docs/km/` 四個目錄全部存在；已存在不寫入，AI 輸出「[略過] docs/xxx/ 已存在」 |
| AC3 | 初始文件複製 | 從 `templates/` 複製 `PRODUCT_BACKLOG.md`、`ROADMAP.md`、`PROJECT_BOARD.md` 至 `docs/prd/`；已存在不覆蓋，標記警告而非中斷 |
| AC4 | CLAUDE.md 生成 | `CLAUDE.md` 不存在時，詢問使用者 3 個問題（專案名稱、技術棧、專案等級）後生成。**【豁免不阻塞原則】**：CLAUDE.md 是框架根設定，錯誤等級=高風險，任何專案等級皆需人工確認。已存在略過，輸出「CLAUDE.md 已存在，使用現有設定」 |
| AC5 | Product Discovery 引導 | 初始化完成後輸出下一步清單，必含 3 項：確認 CLAUDE.md 內容、執行 `/standup` 確認環境、說明如何啟動 Sprint Planning；允許輸出額外引導項目 |
| AC6 | 冪等性 | 重複執行不產生錯誤、不覆蓋已存在內容；輸出「跳過 X 目錄、Y 檔案（共 Z 項）」摘要 |
| AC7 | 錯誤處理 | `templates/` 不存在時輸出明確錯誤訊息「templates/ 目錄遺失，請確認 Shikigami 安裝完整」，不靜默失敗 |

**RICE 評分**
| 維度 | 分數 |
|------|------|
| Reach | 8 |
| Impact | 3 |
| Confidence | 85% |
| Effort | 0.5 |
| **RICE Score** | **40.8** |

**MoSCoW**：Must
**Size**：M

---

### US-T04：版號一致性驗證

**標題**：`.claude-plugin/` 版號跨文件一致性驗證

**User Story**
As a Developer, I want a check that ensures version numbers are consistent across `.claude-plugin/` files, so that plugin installation doesn't silently use mismatched versions.

**範圍說明**：範圍限定為 `.claude-plugin/` 下的檔案。`.cursor-plugin` 是 Cursor 適配，與 Claude Code 主體獨立，版本策略不同，不納入本 Story 驗證範圍。

**Acceptance Criteria**（Sprint 3 Planning QA 修正後）

| # | 條件 | 通過標準 |
|---|------|----------|
| AC1 | plugin.json 與 marketplace.json 一致性 | 驗證 `.claude-plugin/plugin.json` 的 `version` 與 `.claude-plugin/marketplace.json` 的 `plugins[0].version` 相同；不同則 FAIL + 非零 exit code |
| AC2 | git tag 一致性 | 若存在 git tag，最新 semver tag 與 `.claude-plugin/plugin.json` 的 `version` 一致；不一致則報錯 |
| AC3 | 0.x.x 開發期降級 | `version` 符合 `^0\.\d+\.\d+$` 時，AC2 降級為 WARNING（非 FAIL），允許開發期 tag 未對齊；1.0.0 以上恢復強制 FAIL |

**RICE 評分**
| 維度 | 分數 |
|------|------|
| Reach | 8 |
| Impact | 2 |
| Confidence | 90% |
| Effort | 0.3 |
| **RICE Score** | **48.0** |

**MoSCoW**：Should
**Size**：S
**TDD**：Red-Green-Refactor，11 個測試案例全覆蓋

---

## Sprint 4（2026-03-01）

**Sprint Goal**：啟動 v0.3.0 知識沉澱，以 US-08 Sprint Metrics 完成 v0.2.0 收尾，並建立 Retrospective Analytics 的第一層能力

| Story | RICE | MoSCoW | ADR | 完成狀態 |
|-------|------|--------|-----|----------|
| US-08：Sprint Metrics（Velocity 追蹤與趨勢分析） | 13.7 | Should | — | Done |
| US-09：Retrospective Analytics（問題趨勢分析） | 17.0 | Should | — | Done |
| US-T06：Command 路由驗證 | 18.0 | Should | — | Done |

---

### US-08：Sprint Metrics（Velocity 追蹤與趨勢分析）

**標題**：Sprint Review 自動計算 Velocity 與趨勢

**User Story**
As a Scrum Master, I want Sprint Metrics automatically calculated and appended at the end of each Sprint Review, so that I can track Velocity trends across Sprints and make data-driven capacity decisions for Sprint Planning.

**Acceptance Criteria**（含類型標注）

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 觸發整合 | sprint-review SKILL.md 第 6 節檢查清單新增 Metrics 計算 |
| AC2 | [靜態] | Velocity 計算 | T-shirt Sizing 換算（S=1, M=2, L=3） |
| AC3 | [靜態] | 完成率計算 | Done/計畫總數，分母為 0 時 N/A |
| AC4 | [靜態] | 累積記錄 | 追加至 docs/km/Metrics_Log.md |
| AC5 | [動態] | 趨勢分析 | 3+ Sprint 啟用，先判連續方向再判穩定 |
| AC6 | [動態] | 資料不足降級 | Sprint 1-2 輸出資料不足訊息 |
| AC7 | [靜態] | 歷史回溯 | 檔案不存在時從 sprint_N.md 回溯 |

**RICE**：13.7
**MoSCoW**：Should
**Size**：S（Architect 調整，原 M）

---

### US-09：Retrospective Analytics（問題趨勢分析與模式辨識）

**標題**：Retrospective 開始前展示歷史趨勢分析報告

**User Story**
As a Scrum Master, I want the Retrospective Analytics report displayed automatically before each Retrospective session, so that the team can review recurring problems and unresolved root causes rather than re-discovering the same issues every Sprint.

**Acceptance Criteria**（含類型標注）

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 觸發時機 | sprint-review SKILL.md 第 3 節步驟 0 |
| AC2 | [動態] | Good 頻率統計 | 2+ 次清單 |
| AC3 | [動態] | Problem 頻率統計 | 含「未解決」判定 |
| AC4 | [靜態] | 重複 Problem 警示 | 連續→醒目，間斷→說明不觸發 |
| AC5 | [靜態] | Action Items 關閉速度 | 平均/最快/最慢 |
| AC6 | [靜態] | Open Action Items 警示 | 單獨列出 |
| AC7 | [動態] | 報告格式一致性 | 四區塊缺一不可 |
| AC8 | [動態] | 資料不足降級 | 1 Sprint 時頻率統計降級 |
| AC9 | [靜態] | 檔案不存在處理 | 明確提示正常結束 |

**RICE**：17.0
**MoSCoW**：Should
**Size**：M

---

### US-T06：Command 路由驗證

**標題**：驗證 Command 到 Skill 的路由正確性

**User Story**
As a Developer, I want to verify that each command correctly delegates to an existing skill, so that routing failures are caught before users encounter them.

**Acceptance Criteria**（含類型標注）

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 掃描範圍 | commands/ 下所有 .md |
| AC2 | [靜態] | 引用存在性 | shikigami:xxx 指向存在的 Skill，無引用→INFO |
| AC3 | [靜態] | Frontmatter | 含 description 欄位 |
| AC4 | [靜態] | Exit code | 0=全通過，非0=有 ERROR |

**RICE**：18.0
**MoSCoW**：Should
**Size**：S
**TDD**：Red-Green-Refactor，5 test cases，16 assertions

---

## Sprint 5（2026-03-01）

**Sprint Goal**：完成 v0.3.0 Tech Debt Registry，並同步建立 ADR-002 解鎖測試框架擴展路徑，並修復 16 項框架監控缺口

| Story | RICE | MoSCoW | ADR | 完成狀態 |
|-------|------|--------|-----|----------|
| ADR-002：測試框架技術選型 | 90.0 | Must | Accepted | Done |
| US-10：Tech Debt Registry | 19.4 | Must | — | Done |
| US-T01：Skill 完整性驗證 | 54.0 | Must | ADR-002 | Done |
| US-FIX-01：修復審計發現 | 90.0 | Must | — | Done |

---

### ADR-002：測試框架技術選型

**標題**：測試框架技術選型決策

**Acceptance Criteria**
- AC1：建立 `docs/adr/ADR-002.md`；格式與 ADR-001 一致
- AC2：至少列出 2 個技術選項，每個選項含優缺點分析
- AC3：Decision 區段含選定工具名稱、選擇理由、排除方案說明
- AC4：包含「實作方式」區段，說明目錄結構或命名規範

**RICE**：90.0
**MoSCoW**：Must（Hard Gate for US-T01）
**Size**：S

---

### US-10：Tech Debt Registry

**標題**：技術債追蹤與系統化管理

**User Story**
As a Developer, I want a structured Tech Debt Registry that captures and tracks technical debt across Sprints, so that the team can make informed decisions about when to address shortcuts and prevent debt accumulation from degrading system quality.

**Acceptance Criteria**
- AC1：Registry 格式定義（ID/描述/引入 Story/解決 Story/嚴重度/建議解法/RICE/狀態 + 趨勢判定規則）
- AC2：Developer Prompt 整合（標記格式 + Registry 更新指引 + SKILL.md DoD 引用）
- AC3：Grooming 觸發（掃描 Registry，標記逾期未解決項目）
- AC4：Story 關聯欄位（「引入 Story」與「解決 Story」）
- AC5：取捷徑場景觸發（3 種場景 + [TECH-DEBT] 標記格式）
- AC6：Grooming 報告輸出（Active 清單、解決清單、變化量、趨勢判定）
- AC7：趨勢判定規則（連續 2 次增加/減少/不變/資料不足）

**RICE**：19.4
**MoSCoW**：Must
**Size**：M

---

### US-T01：Skill 完整性驗證

**標題**：Skill 目錄結構與 frontmatter 驗證腳本

**User Story**
As a Developer, I want a script that verifies every skill directory has a valid SKILL.md with required frontmatter, so that I can catch missing or malformed skill definitions before pushing.

**Acceptance Criteria**
- AC1：掃描 `skills/` 下所有直接子目錄（depth=1），輸出目錄清單，數量與實際一致
- AC2：驗證每個 SKILL.md frontmatter 包含 `name` 和 `description` 欄位
- AC3：驗證 `name` 值與目錄名稱一致（大小寫敏感完全字串比對）
- AC4：空目錄報錯，不靜默略過
- AC5：exit code 0 = 通過，非 0 = 失敗

**RICE**：54.0
**MoSCoW**：Must
**ADR**：ADR-002
**Size**：S
**TDD**：Red-Green-Refactor，共享函式庫 + 主腳本

---

### US-FIX-01：修復審計發現

**標題**：修復 QA 審計 16 項框架監控缺口（13 項文件修正）

**User Story**
As a Developer, I want framework documents (DoD, standup, health-check, sprint-planning, sprint-review) to be consistent and complete, so that monitoring gaps don't allow defects to slip through undetected.

**Acceptance Criteria**
- AC-A1：DoD 統一為 7 層（功能、測試、安全、文件、設定、度量、反回歸）
- AC-A2：standup 新增 GitHub Issues 掃描區塊
- AC-A3：health-check 掃描清單新增 ROADMAP.md 與 Metrics_Log.md
- AC-A4：sprint-planning 新增 ROADMAP 讀取步驟
- AC-A5：sprint-review 產出文件含 ROADMAP + Issue close 步驟

**RICE**：90.0
**MoSCoW**：Must
**Size**：M

---

## Sprint 6（2026-03-01）

**Sprint Goal**：建立 Hard Gate Checklist 機制（US-FIX-02），擴展測試框架覆蓋（US-T02、US-T03），並清零 Sprint 5 Retro 技術債

| Story | RICE | MoSCoW | ADR | 完成狀態 |
|-------|------|--------|-----|----------|
| US-T02：Agent 完整性驗證 | 54.0 | Must | ADR-002 | Done |
| US-T03：JSON Schema 驗證 | 25.7 | Must | ADR-002 | Done |
| US-FIX-02：Hard Gate Checklist 機制 | 27.0 | Must | ADR-003 | Done |

> 備注：Retro #7 和 Retro #8 為 Retro Action Items，不是 Backlog Stories，不歸入此表。

---

### US-T02：Agent 完整性驗證

**標題**：Agent 目錄 frontmatter 驗證腳本

**User Story**
As a Developer, I want a script that verifies every agent file has correct frontmatter fields, so that plugin installation doesn't fail silently.

**Acceptance Criteria**
- AC1：掃描 `agents/` 下所有 `.md` 檔案，輸出清單，數量與目錄實際 `.md` 檔案數一致
- AC2：驗證 frontmatter 包含 `name`、`description`、`model` 三個欄位；任一缺失則 ERROR
- AC3：驗證 `model` 值為合法值之一：`sonnet`、`haiku`、`opus`（hardcode，大小寫敏感完全比對）
- AC4：驗證 `description` 欄位存在且非空字串；空字串或僅含空白字元則 ERROR
- AC5：exit code 0 = 全部通過，非 0 = 存在至少一個 ERROR

**RICE**：54.0
**MoSCoW**：Must
**ADR**：ADR-002
**Size**：S
**TDD**：Red-Green-Refactor，validate-agents.sh + shared library

---

### US-T03：JSON Schema 驗證

**標題**：plugin.json / marketplace.json Schema 驗證腳本

**User Story**
As a Developer, I want automated validation of plugin.json and marketplace.json, so that malformed manifests are caught before users try to install.

**Acceptance Criteria**
- AC1：驗證 `plugin.json` 包含必填欄位：`name`、`version`、`description`、`author`；任一缺失則 ERROR
- AC2：驗證 `marketplace.json` 包含必填欄位：`name`、`plugins` 陣列；任一缺失則 ERROR
- AC3：驗證 `version` 格式符合 semver（`major.minor.patch`，三段純數字）
- AC4：`plugin.json` 允許欄位白名單（10 欄位）；白名單以外觸發 WARNING（非 ERROR），不影響 exit code
- AC5：exit code 0 = 無 ERROR；非 0 = 存在至少一個 ERROR

**RICE**：25.7
**MoSCoW**：Must
**ADR**：ADR-002
**Size**：M（Architect 上調）

---

### US-FIX-02：Hard Gate Checklist 機制

**標題**：Framework Document Change / Out-of-Sprint Change / Ceremony Integrity 三重 Hard Gate

**User Story**
As a Scrum Master, I want structural Hard Gate checklists at framework document changes, out-of-sprint changes, and ceremony completion, so that process compliance is enforced by mechanism rather than by memory.

**Acceptance Criteria**
- AC-B1：ADR-003 狀態為 Accepted（前置條件）
- AC-B2：Preflight Check 區段，4 項二元 checklist
- AC-B3：Framework Document Change Audit 與 ADR-003 完全對應
- AC-B4a：Out-of-Sprint Change 偵測邏輯（正常路徑）
- AC-B4b：緊急例外路徑（`[EMERGENCY]` + 48hr 稽核）
- AC-B5：Ceremony Integrity Audit（Planning 4 項 + Review 5 項）

**RICE**：27.0
**MoSCoW**：Must
**ADR**：ADR-003
**Size**：L

---

## Sprint 7（2026-03-01）

**Sprint Goal**：啟動 v0.5.0 穩定化，清零 Sprint 6 Retro 技術債，建立解咒模式（Legacy 系統考古 Skill），並完成測試框架 CI 整合

| Story | RICE | MoSCoW | ADR | 完成狀態 |
|-------|------|--------|-----|----------|
| US-T05：交叉引用驗證 | 25.6 | Should | — | Done |
| US-T07：CI Pipeline | 24.0 | Should | — | Done |

> 備注：Retro #10（狀態回寫）、Retro #11（KM 歸檔）、shikigami:dispel（解咒模式）為 Retro Action Items / Stakeholder 要求，不是 Backlog Stories，不歸入此表。

---

### US-T05：交叉引用驗證

**標題**：shikigami:xxx 引用完整性驗證腳本

**User Story**
As a Developer, I want a script that verifies all `shikigami:xxx` references point to existing skills, so that broken cross-references are caught before pushing.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 掃描範圍 | `scripts/validate-xrefs.sh` 存在；掃描倉庫根目錄下所有 .md 檔案（遞迴），擷取 `shikigami:[a-z-]+` 格式的引用 |
| AC2 | [靜態] | 存在性驗證 | 對每個引用 `shikigami:<name>`，驗證 `skills/<name>/SKILL.md` 存在；不存在則標記為 ERROR |
| AC3 | [靜態] | 報告格式 | 有 broken reference 時輸出：`ERROR: <file>:<line>: broken reference 'shikigami:<name>'` |
| AC4 | [靜態] | Exit code | exit code 0 = 無 broken reference；非 0 = 至少一個 broken reference |

**RICE**：25.6
**MoSCoW**：Should
**Size**：S

---

### US-T07：CI Pipeline

**標題**：GitHub Actions 自動化驗證 Pipeline

**User Story**
As a Developer, I want all structural validation scripts to run automatically on every push, so that broken commits never reach users.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | Workflow 文件 | `.github/workflows/validate.yml` 存在；trigger 條件包含 push 與 pull_request |
| AC2 | [靜態] | 腳本清單 | Pipeline 執行以下腳本：`validate-skills.sh`、`validate-agents.sh`、`validate-json.sh`、`validate-version.sh`、`validate-xrefs.sh`、`validate-commands.sh` |
| AC3 | [靜態] | 失敗行為 | workflow YAML 無 `continue-on-error: true`；任一腳本 exit 非 0 則 job 失敗 |
| AC4 | [靜態] | 執行時間 | 本地執行全部驗證腳本總時間 < 20 秒 |
| AC5 | [靜態] | Step 命名 | 每個 step 有可讀名稱對應腳本功能，不接受全部命名為 "run" |

**RICE**：24.0
**MoSCoW**：Should
**Size**：M

---

## Sprint 8（2026-03-01）

**Sprint Goal**：修復 Sprint Execution Issue 回覆缺口，恢復 QA 雙階段審查，建立制衡案例文件庫，引入輕量 Bypass 機制

| Story | RICE | MoSCoW | ADR | 完成狀態 |
|-------|------|--------|-----|----------|
| US-21：真實制衡案例文件 | 25.3 | Should | — | Done |
| US-18：Sprint Execution Issue 回覆自動化 | 23.8 | Should | — | Done |
| US-20：輕量 Bypass 機制 | 20.25 | Should | — | Done |

> 備注：Retro #14（恢復 QA 雙階段審查）為 Retro Action Item，不是 Backlog Story，不歸入此表。

---

### US-21：真實制衡案例文件

**標題**：在 docs/ 收錄真實的角色制衡案例

**User Story**
As a new user, I want to read documented real-world examples of role-based checks and balances within Shikigami, so that I can understand how the framework prevents groupthink and trust that the multi-agent governance model delivers meaningful quality gates.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 文件建立 | `docs/km/ROLE_BALANCE_CASES.md` 存在；含至少 4 個案例，每個案例含 5 個必填欄位 |
| AC2 | [靜態] | 類型覆蓋 | 每個案例含「制衡類型」欄位，4 個案例覆蓋至少 3 種不同類型 |
| AC3 | [靜態] | README 引用 | `README.md` 實戰驗證區段新增指向 `docs/km/ROLE_BALANCE_CASES.md` 的連結 |
| AC4 | [靜態] | Sprint Review 提示 | `skills/sprint-review/SKILL.md` 執行檢查清單新增制衡案例記錄提示 |

**RICE**：25.3
**MoSCoW**：Should
**Size**：S

---

### US-18：Sprint Execution Issue 回覆自動化

**標題**：Sprint Execution 每個 Story 開始前自動掃描並回覆 Open Issues

**User Story**
As a Product Owner, I want open GitHub issues to be automatically scanned and acknowledged at the start of each story in sprint execution, so that external collaborators receive timely responses.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 流程整合 | sprint-execution SKILL.md 第 3 節流程圖新增「Issue 快掃」子步驟 |
| AC2 | [靜態] | 降級指引 | 含 `gh issue list` 指令；含降級指引文字 |
| AC3 | [靜態] | 回覆觸發規則 | 定義觸發條件三項 + 回覆流程（PO 草稿 → QA 審核 → 依專案等級發布） |
| AC4 | [靜態] | 防重複機制 | 定義 `sprint-N-replied` label 防重複 |

**RICE**：23.8
**MoSCoW**：Should
**Size**：M

---

### US-20：輕量 Bypass 機制

**標題**：低複雜度任務自動跳過 Scrum 儀式，直接執行

**User Story**
As a Scrum Master, I want a lightweight bypass mode for simple, well-defined tasks, so that the framework does not impose full Scrum ceremony overhead when the task complexity clearly does not warrant it.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | Bypass 觸發條件 | scrum-master SKILL.md 定義 3 項觸發條件 |
| AC2 | [靜態] | Bypass 流程定義 | 跳過/保留清單明確定義 |
| AC3 | [靜態] | 保護清單 | 3 項禁止 Bypass 情況 + 拒絕格式範例 |
| AC4 | [靜態] | 稽核追蹤 | `[BYPASS]` 標注 + 40% 上限 |
| AC5 | [靜態] | Hard Gate 豁免 | sprint-execution SKILL.md Hard Gate 豁免子句 |

**RICE**：20.25
**MoSCoW**：Should
**Size**：M

---

## Sprint 9（2026-03-01）

**Sprint Goal**：建立 Token 成本透明化機制，強化 Sprint 流程檔案即時持久化，並建立孤兒文件自動偵測能力

| Story | RICE | MoSCoW | ADR | 完成狀態 |
|-------|------|--------|-----|----------|
| US-19：Token 成本透明化 | 11.2 | Must | — | Done |
| US-T09：孤兒文件清理規範 | 16.7 | Could | — | Done |

> 備注：Retro #16（Sprint 文件即時 commit + push）為 Retro Action Item，不是 Backlog Story，不歸入此表。

---

### US-19：Token 成本透明化

**標題**：Sprint Review 自動輸出 Token 消耗與成本對照表

**User Story**
As a Product Owner, I want token consumption recorded and displayed at each Sprint Review, so that I can understand the AI infrastructure cost of operating this framework and make informed decisions about sprint scope and automation depth.

**Acceptance Criteria**（Sprint 9 精化版）

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 記錄格式 | Metrics_Log.md 新增獨立 Token 表格，五欄位 + 資料來源允許值定義 |
| AC2 | [靜態+動態] | Sprint Review 整合 | sprint-review SKILL.md 新增 Token 成本摘要子節 + fallback 規範 |
| AC3 | [動態] | 成本對照 | 前置條件 3+ 完整記錄；2x 平均值標記 [OUTLIER] |
| AC4 | [靜態] | 手動降級 | 手動記錄模板含示範資料 |

**RICE**：11.2
**MoSCoW**：Must
**Size**：M

---

### US-T09：孤兒文件清理規範

**標題**：定義孤兒文件判斷規則、自動偵測與處置流程

**User Story**
As a Product Owner, I want a defined policy for handling orphan artifacts, so that the repo stays clean.

**Acceptance Criteria**（Sprint 9 精化版）

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 孤兒判斷規則 | 正向定義 + 4 類豁免清單 + 每次 CI 判定 |
| AC2 | [靜態+動態] | Linter 孤兒標記 | validate-orphans.sh + CI 步驟 + exit code = 0 + WARNING 格式 |
| AC3 | [靜態] | 孤兒處置規範 | Retro Problem → PO 裁定（刪除/補引用/加豁免）→ 關閉 issue |

**RICE**：16.7
**MoSCoW**：Could
**Size**：M

---

## Sprint 10（2026-03-01）

**Sprint Goal**：填入 Token 真實數據並細化至分環節記錄，引入 Retrospective 驅動的角色權重自動調整

| Story | RICE | MoSCoW | ADR | 完成狀態 |
|-------|------|--------|-----|----------|
| US-23：Token 成本分環節記錄 | 33.6 | Must | — | Done |
| US-22：Retrospective 驅動角色權重自動調整 | 6.6 | Could | ADR-004 | Done |

> 備注：Retro #19（領域專家審查機制設計）為 Retro Action Item，不是 Backlog Story，不歸入此表。ADR-004 為 US-22 前置依賴。

---

### US-23：Token 成本分環節記錄

**標題**：Sprint 各環節（Planning / Execution / Review）Token 消耗獨立記錄與佔比分析

**User Story**
As a Product Owner, I want token consumption broken down by sprint phase (Planning, Execution, Review) and recorded in Metrics_Log.md, so that I can understand which phases consume the most resources and make data-driven decisions about where to optimize or reduce ceremony depth.

**Acceptance Criteria**（Sprint 10 精化版）

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 分環節表格格式 | Metrics_Log.md 新增 H2「Token 成本分環節記錄」，六欄位 + 佔比計算基準定義 |
| AC2 | [靜態] | sprint-planning 整合 | sprint-planning SKILL.md 新增 Planning token 記錄指引 |
| AC3 | [靜態] | 示範資料 | K 格式，佔比三欄加總 100% |
| AC4 | [動態] | 降級處理 | N/A 填入 + 精確字串「Token 資料不可用，需手動補充」 |
| AC5 | [靜態] | ADR-003 Checklist | Framework Document Change Audit 通過 |

**RICE**：33.6
**MoSCoW**：Must
**Size**：M

---

## Sprint 11（2026-03-01）

**Sprint Goal**：導入 Scrum Master 零讀取架構，讓主 session context 瘦身，同步清零 Sprint 10 Retro Action Item，為 Token 成本大幅下降奠定結構基礎

| Story | RICE | MoSCoW | ADR | 完成狀態 |
|-------|------|--------|-----|----------|
| US-25：Scrum Master 零讀取架構 | 45.0 | Must | ADR-003 | Done |
| US-S02：Standup 健康快篩框架 Repo 誤判修正 | 18.0 | Should | ADR-003 | Done |

> 備注：Retro #20（SKILL.md token 記錄指引更新）為 Retro Action Item，不是 Backlog Story，不歸入此表。

---

### US-25：Scrum Master 零讀取架構

**標題**：主 session 不直接讀取大檔案，全部委託 Subagent 處理並回傳摘要

**User Story**
As a framework user, I want the Scrum Master (main session) to never read large files directly but instead delegate all file reading to subagents who return concise summaries, so that the main session's context stays lean and each API call's cache read overhead is minimized.

**Acceptance Criteria**（Sprint 11 精化版）

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | sprint-planning 零讀取 | PO subagent prompt 指定完整路徑，由 subagent 自行讀取；主 session 不 Read；subagent 回傳 Markdown 表格 |
| AC2 | [靜態] | sprint-execution 零讀取 | Developer/QA/Security subagent 接收檔案路徑，主 session 不預讀；回傳 PASS/FAIL + 一句話摘要 |
| AC3 | [靜態] | sprint-review 零讀取 | Retro Analytics/PO Demo/Stakeholder/Metrics 由 subagent 讀取所需檔案；主 session 不直接讀取 |
| AC4 | [動態] | context 瘦身驗證 | 量測 Sprint：Sprint 12。基準：Sprint 10 = 104M。通過：Sprint 12 < 41.6M（下降 60%）|

**RICE**：45.0
**MoSCoW**：Must
**Size**：M / **Points**：2

---

### US-S02：Standup 健康快篩框架 Repo 誤判修正

**標題**：健康快篩在框架 Repo 本身執行時跳過 CLAUDE.md 檢查

**User Story**
As a framework developer working in the shikigami repo itself, I want the standup health check to recognize it's running in the framework repo and skip the CLAUDE.md existence check, so that I don't get false positive CRITICAL alerts every standup.

**Acceptance Criteria**（Sprint 11 精化版）

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 框架 Repo 偵測 | commands/standup.md 新增前置判斷：若 `./.claude-plugin/plugin.json` 存在且非空，跳過 CLAUDE.md 檢查 |
| AC2 | [動態] | 消費端不受影響 | 無 plugin.json 專案中 CLAUDE.md 缺失仍觸發 CRITICAL |
| AC3 | [動態] | 框架端正向驗證 | 含 plugin.json 且缺 CLAUDE.md 時快篩為 HEALTHY |

**RICE**：18.0
**MoSCoW**：Should
**Size**：S / **Points**：1

---

### US-22：Retrospective 驅動角色權重自動調整

**標題**：Sprint Planning 自動讀取 Retro 趨勢，調整角色介入深度

**User Story**
As a Scrum Master, I want Sprint Planning to automatically read Retrospective trends and adjust the depth of each role's involvement for the upcoming sprint, so that the framework learns from past problems rather than applying the same fixed ceremony depth regardless of team history.

**Acceptance Criteria**（Sprint 10 精化版）

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 觸發時機與插入位置 | sprint-planning SKILL.md 在「健康檢查」後、「PO 第一輪」前新增步驟 |
| AC2 | [動態] | 權重調整規則 | ADR-004 關鍵字清單比對 + 連續 2 Sprint 觸發 + 重置條件 |
| AC3 | [動態] | 調整透明化與持久化 | 輸出調整清單 + 持久化至 sprint_N.md 權重調整記錄區塊 |
| AC4 | [靜態] | 資料不足降級 | < 3 Sprint 記錄時輸出降級訊息 |

**RICE**：6.6
**MoSCoW**：Could
**Size**：L
**ADR**：ADR-004（Accepted）

---

## Sprint 12（2026-03-01）

**Sprint Goal**：修正 health-check 架構對齊、完成 US-25 AC4 零讀取效果量測、強化 QA 路徑驗證，讓 M5 穩定化的架構完整性與流程品質收斂

| Story | RICE | MoSCoW | ADR | 完成狀態 |
|-------|------|--------|-----|----------|
| US-24 AC3/AC4：Subagent Token 成本優化量測 | —（子集） | Should | — | Done（部分；AC1/AC2 暫緩） |

> 備注：Retro #21（Sprint Planning QA 精化）、Retro #22（US-25 AC4 量測）、Issue #23（health-check SKILL.md 零讀取架構對齊）為 Retro Action Items / GitHub Issue，非 Backlog 原生 Story，不帶 RICE 評分，以交付摘要歸檔。

---

### Retro #21：Sprint Planning QA 精化 — AC 路徑驗證步驟

**來源**：Sprint 11 Retro Action Item #21（[Issue #21](https://github.com/KCTW/shikigami/issues/21)）
**交付摘要**：`skills/sprint-planning/SKILL.md` §6 QA 條目新增路徑驗證規則；若 Story AC 含具體檔案路徑，QA 需執行 Glob/ls 存在性確認，回報 Path verification: PASS / FAIL / N/A。
**驗收結果**：AC 全通過（3/3）；Issue #21 CLOSED
**Size**：S / **Points**：1

---

### Retro #22：US-25 AC4 量測

**來源**：Sprint 11 Retro Action Item #22（[Issue #22](https://github.com/KCTW/shikigami/issues/22)）
**交付摘要**：Sprint 12 Review 從 JSONL 提取 `cache_read_input_tokens` 加總 = 41.93M，相較 Sprint 10 基準 104M 降幅 59.7%（門檻 41.6M，差距 0.3%）；Stakeholder 裁定接受。
**驗收結果**：邊緣 FAIL，Stakeholder 裁定接受；Issue #22 CLOSED
**Size**：S / **Points**：1

---

### Issue #23：health-check SKILL.md 零讀取架構對齊

**來源**：GitHub Issue #23
**交付摘要**：`skills/health-check/SKILL.md` §4 改寫為 Subagent 委派模式；主 session 不直接呼叫 Read/Glob/Grep；Subagent 失敗時輸出 Overall Status: UNKNOWN，不降級讀取，維持零讀取架構。
**驗收結果**：AC 全通過（3/3）；Issue #23 CLOSED
**Size**：S / **Points**：1

---

### US-24 AC3/AC4：Subagent Token 成本優化量測

**標題**：Sprint 12 Planning API call 數量與 token 降幅量測（US-24 的 AC3/AC4 子集）

**交付摘要**
- AC3 PASS：Sprint 12 Planning message 物件數 = 123（< 200 門檻）
- AC4 PASS：Sprint 12 Planning token = 8.76M vs Sprint 10 基準 87M，降幅 89.9%（> 50% 門檻）

**備注**：US-24 AC1（檔案傳遞模式）與 AC2（輕量模型指定）暫緩，US-24 未從 PRODUCT_BACKLOG.md 移除。本條目僅記錄 AC3/AC4 的部分交付。
**Size（子集）**：S / **Points**：1
