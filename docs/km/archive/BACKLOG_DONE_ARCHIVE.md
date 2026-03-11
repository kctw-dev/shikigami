# BACKLOG_DONE 歷史歸檔

**來源**：`docs/prd/BACKLOG_DONE.md`
**最後更新**：2026-03-11（Sprint 72–74 歸檔）
**歸檔範圍**：Sprint 1–74

> 主文件現況：[BACKLOG_DONE.md](../../prd/BACKLOG_DONE.md)（保留 Sprint 75–77）

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

---

## Sprint 13（2026-03-01）

**Sprint Goal**：清零 Sprint 12 Retro 流程缺口，建立 Sprint Planning 平行派工正式規範，為 M5 外部發布排除最後的流程控制風險

| Story | RICE | MoSCoW | ADR | 完成狀態 |
|-------|------|--------|-----|----------|
| Retro #26：PO Demo 應讀取 repo 源碼而非 plugin cache | — | Must | ADR-003 | Done |
| Retro #27：Developer Board 更新範圍限制 | — | Must | ADR-003 | Done |
| Retro #25：PO Sprint Planning Story 選取應納入平行派工可行性考量 | — | Must | ADR-003 | Done |
| Retro #24：Architect Sprint Planning 評估應包含平行派工策略 | — | Must | ADR-003 | Done |

---

### Retro #26：PO Demo 應讀取 repo 源碼而非 plugin cache

**來源**：Sprint 12 Retro Action Item #26（[Issue #26](https://github.com/KCTW/shikigami/issues/26)）
**交付摘要**：`skills/sprint-review/SKILL.md` §2 Step 1 新增【源碼路徑】和【禁止項】兩條規則，明確指定讀取 repo working directory 源碼，禁止依賴 plugin cache 版本。
**驗收結果**：AC1 PASS（靜態），AC2 待動態驗證（PO Demo 已即時自證）；Issue #26 CLOSED
**Size**：S / **Points**：1

---

### Retro #27：Developer Board 更新範圍限制

**來源**：Sprint 12 Retro Action Item #27（[Issue #27](https://github.com/KCTW/shikigami/issues/27)）
**交付摘要**：`skills/sprint-execution/SKILL.md` 步驟 8 新增 HARD-GATE 區塊，明確限定 Developer 只能更新 Story 狀態行，禁止修改 Sprint 級別欄位。sprint_N.md 同樣限定。
**驗收結果**：AC 全通過（2/2）；Issue #27 CLOSED
**Size**：S / **Points**：1

---

### Retro #25：PO Sprint Planning Story 選取應納入平行派工可行性考量

**來源**：Sprint 12 Retro Action Item #25（[Issue #25](https://github.com/KCTW/shikigami/issues/25)）
**交付摘要**：`skills/sprint-planning/SKILL.md` §6 Step 1 PO 第一輪回傳表格新增「獨立性評估」欄位，描述段落加入檔案修改獨立性評估指引。
**驗收結果**：AC 全通過（2/2）；Issue #25 CLOSED
**Size**：S / **Points**：1

---

### Retro #24：Architect Sprint Planning 評估應包含平行派工策略

**來源**：Sprint 12 Retro Action Item #24（[Issue #24](https://github.com/KCTW/shikigami/issues/24)）
**交付摘要**：`skills/sprint-planning/SKILL.md` §6 Step 2 Architect 區段新增「平行分群建議」正式輸出項目，含 Phase 1/Phase 2 分組表格、檔案衝突分析表格、分群規則。
**驗收結果**：AC 全通過（2/2）；Issue #24 CLOSED
**Size**：S / **Points**：1

---

## Sprint 14（2026-03-02）

**Sprint Goal**：清零 Sprint 13 Retro Action Items，收窄 Retro #29 修改範圍至 sprint-execution SKILL.md，完成 sprint-review 硬編碼版本號修正，確保框架指引文件在 M5 穩定化階段維持長期可維護性。

| Story | RICE | MoSCoW | ADR | 完成狀態 |
|-------|------|--------|-----|----------|
| Retro #29：Issue 快掃觸發條件排除 retro-action label | — | Must | — | Done |
| Retro #30：sprint-review SKILL.md 禁止項硬編碼版本號修正 | — | Must | — | Done |

---

### Retro #29：Issue 快掃觸發條件排除 retro-action label

**來源**：Sprint 13 Retro Action Item #29（[Issue #29](https://github.com/KCTW/shikigami/issues/29)）
**交付摘要**：`skills/sprint-execution/SKILL.md` 的 Issue 快掃觸發條件 (a) 新增排除 `retro-action` label 規則，防止內部追蹤 issue 被誤判為社群使用者問題。修改範圍收窄至 sprint-execution SKILL.md（不含 standup.md）。
**驗收結果**：AC 通過；Issue #29 CLOSED
**Size**：S / **Points**：1

---

### Retro #30：sprint-review SKILL.md 禁止項硬編碼版本號修正

**來源**：Sprint 13 Retro Action Item #30（[Issue #30](https://github.com/KCTW/shikigami/issues/30)）
**交付摘要**：`skills/sprint-review/SKILL.md` 禁止項說明中移除硬編碼版本號 `v0.3.5`，改為版本無關的描述（「目前已安裝版本」或「plugin cache 中的版本」），確保指引文件長期可維護性。
**驗收結果**：AC 通過；Issue #30 CLOSED
**Size**：S / **Points**：1

---

## Sprint 15（2026-03-02）

**Sprint Goal**：完成 M5 穩定化核心工作，建立完整安裝流程驗證機制與外部使用者導向文件體系，讓外部使用者能順利安裝並走完第一個 Sprint。

| Story | RICE | MoSCoW | ADR | 完成狀態 |
|-------|------|--------|-----|----------|
| US-15：完整安裝流程驗證（全新環境測試） | 28.0 | Must | — | Done |
| US-16：使用者文件完善（Tutorial + Troubleshooting） | 22.5 | Must | — | Done |

---

### US-15：完整安裝流程驗證（全新環境測試）

**標題**：在全新環境中執行 README 安裝步驟，建立可重複的驗證報告

**User Story**
As an external user, I want the installation flow to be verified in a clean environment and documented in a reproducible checklist, so that I can confidently follow the README and get a working Shikigami setup without hidden assumptions or undocumented prerequisites.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 建立安裝驗證 Checklist | 新建 `docs/km/INSTALL_VERIFICATION.md`；包含逐步 Checklist（每步驟含：指令/動作描述、預期輸出、PASS/FAIL 欄位、備注欄位）；涵蓋全部安裝步驟 |
| AC2 | [動態] | 全新環境實際執行 | 依照 README 安裝步驟在無任何 Shikigami 預設前提的環境中逐步執行，將每步驟結果填入 AC1 Checklist；最終 Checklist 所有步驟標記 PASS |
| AC3 | [靜態] | 驗證報告完整性 | 包含：(a) 測試環境規格、(b) 至少 5 個驗證場景、(c) 測試日期與執行者、(d) 發現問題清單 |
| AC4 | [靜態] | README 對齊 | 若 AC2 執行中發現 README 有任何錯誤、缺漏、過時描述，須同步修正 `README.md` 對應段落 |

**RICE 評分**

| 維度 | 分數 |
|------|------|
| Reach | 10 |
| Impact | 2 |
| Confidence | 70% |
| Effort | 0.5 人週 |
| **RICE Score** | **28.0** |

**MoSCoW**：Must
**Size**：M / **Points**：2
**對應 ROADMAP**：M5 穩定化（US-15，Sprint 15）

---

### US-16：使用者文件完善（Tutorial + Troubleshooting）

**標題**：建立 Tutorial 與 Troubleshooting 文件，讓外部使用者能端對端上手

**User Story**
As an external user who has installed Shikigami, I want a step-by-step tutorial covering installation to first Sprint, and a troubleshooting guide for common failure scenarios, so that I can get productive without needing to read all the internal documentation or ask questions in issues.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | Tutorial 文件建立 | 新建 `docs/tutorial/GETTING_STARTED.md`；覆蓋「安裝 → 第一個 Sprint」完整端對端路徑，包含 7 個步驟，每個步驟含指令範例與預期輸出摘要 |
| AC2 | [靜態] | Troubleshooting 文件建立 | 新建 `docs/tutorial/TROUBLESHOOTING.md`；至少涵蓋 6 個常見失敗情境，每個情境包含：情境描述、症狀、根因說明、解決步驟 |
| AC3 | [靜態] | README 文件導覽區段 | `README.md` 新增「## 文件導覽」區段（位置：在 Installation 之後，Features 之前） |
| AC4 | [靜態] | 文件可發現性 | `docs/tutorial/` 目錄下建立 `README.md`（或 `INDEX.md`）；`docs/PROJECT_BOARD.md` 工件導覽區段新增 Tutorial 連結 |

**RICE 評分**

| 維度 | 分數 |
|------|------|
| Reach | 10 |
| Impact | 3 |
| Confidence | 75% |
| Effort | 1.0 人週 |
| **RICE Score** | **22.5** |

**MoSCoW**：Must
**Size**：M / **Points**：2
**對應 ROADMAP**：M5 穩定化（US-16，Sprint 15）

---

## Sprint 16（2026-03-02）

**Sprint Goal**：清零 Sprint 15 Retro Action Items，完成 US-17 多平台可行性調查，修正 SKILL.md 越權執行風險，更新 sprint-review 覆蓋缺口，導入快思/慢想雙模式精簡化，鞏固 M5 穩定化最後一哩路。

| Story | RICE | MoSCoW | ADR | 完成狀態 |
|-------|------|--------|-----|----------|
| Retro #37：GETTING_STARTED.md 補上 ToC 目錄 | — | Should | — | Done |
| US-17：多平台調查（Cursor / OpenCode / Codex 可行性） | 18.0 | Should | — | Done |
| Issue #34：sprint-execution SKILL.md doc-only Story 執行保護 | — | Must | — | Done |
| Issue #36：sprint-review SKILL.md 覆蓋缺口修正 | — | Must | — | Done |
| Retro #38：Token JSONL 提取機制調查 | — | Should | — | Done |
| US-28：快思/慢想雙模式 — Sprint Planning & Standup 精簡化 | — | Should | — | Done |

---

## Sprint 17（2026-03-02）

**Sprint Goal**：檔案瘦身優先 — 建立歷史歸檔機制，清零 Sprint 16 Retro Action Items，確保效能可觀測性與知識管理基礎就緒

| Story | RICE | MoSCoW | ADR | 完成狀態 |
|-------|------|--------|-----|----------|
| Retro #41：Token 記錄指引更新 — 三個 SKILL.md 納入 cache tokens 加總計算 | — | Must | ADR-003 | Done |
| Retro #42：OpenCode POC 可行性調查佔位入 Backlog | — | Could | — | Done |
| US-29（Issue #44）：PROJECT_BOARD 與 Retrospective_Log 歷史歸檔機制 | 18.0 | Should | — | Done |

---

### Retro #41：Token 記錄指引更新 — cache tokens 加總

**來源**：Sprint 16 Retro Action Item #41（[Issue #41](https://github.com/KCTW/shikigami/issues/41)）
**交付摘要**：三個 SKILL.md（sprint-planning、sprint-execution、sprint-review）的 token 提取指引新增 `cache_read_input_tokens` + `cache_creation_input_tokens` 加總規則，計算公式：有效 input tokens = input_tokens + cache_read_input_tokens + cache_creation_input_tokens。
**驗收結果**：AC 全通過（5/5）；Issue #41 CLOSED
**Size**：S / **Points**：1

---

### Retro #42：OpenCode POC 可行性調查佔位入 Backlog

**來源**：Sprint 16 Retro Action Item #42（[Issue #42](https://github.com/KCTW/shikigami/issues/42)）
**交付摘要**：`docs/prd/PRODUCT_BACKLOG.md` 新增 OpenCode POC 候選條目，MoSCoW: Could，Size: 待定，狀態: 候選。
**驗收結果**：AC 全通過（3/3）；Issue #42 CLOSED
**Size**：S / **Points**：1

---

### US-29（Issue #44）：PROJECT_BOARD 與 Retrospective_Log 歷史歸檔機制

**標題**：建立歷史記錄歸檔機制，確保主文件保持精簡

**User Story**
As a Product Owner, I want a formal archiving mechanism for PROJECT_BOARD.md and Retrospective_Log.md historical records, so that these files stay lean and don't grow unboundedly, while historical data remains accessible via archive files.

**交付摘要**：
- 建立 `docs/km/archive/` 目錄，含 `PROJECT_BOARD_ARCHIVE.md`（Sprint 1–13）、`RETRO_ARCHIVE.md`（Sprint 1–13）、`README.md`（目錄索引）
- PROJECT_BOARD.md 從 266 行縮減至 73 行（保留 Sprint 14–17）
- Retrospective_Log.md 從 582 行縮減至 77 行（保留 Sprint 14–16）
- 主文件底部新增歸檔連結
- sprint-review SKILL.md 新增 §6 歸檔觸發檢查步驟

**驗收結果**：AC 全通過（5/5）；Issue #44 CLOSED
**RICE**：18.0
**MoSCoW**：Should
**Size**：M / **Points**：2

---

## Sprint 18（2026-03-02）

**Sprint Goal**：建立 Schedule Skill — 實現 Sprint 自動排程執行能力

| Story | RICE | MoSCoW | ADR | 完成狀態 |
|-------|------|--------|-----|----------|
| US-35（Issue #46）：Sprint 排程執行 + 權限 bypass 機制 | 待定 | Should | ADR-005 | Done |

---

### US-35（Issue #46）：Sprint 排程執行 + 權限 bypass 機制（shikigami:schedule）

**標題**：一行指令完成 Sprint 自動排程設定

**User Story**
As a framework user, I want to set up automated Sprint execution scheduling with a single command, so that Sprint cycles can run continuously without manual intervention, with proper permission bypass and pre/post QA gates ensuring safe and reliable automation.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 一行指令完成設定 | `/schedule <skill> --interval <duration>` 完成排程設定，支援 1m/5m/15m/1h |
| AC2 | [靜態] | Pre-flight 阻擋 | 6 項環境檢測，未通過則阻擋 |
| AC3 | [靜態] | 腳本生成 | `scripts/<skill-name>_cron.sh` 含 flock + allowedTools + unset ANTHROPIC_API_KEY |
| AC4 | [靜態] | 冪等 crontab | 重複執行不產生重複 entry |
| AC5 | [靜態] | Post-deploy 自動回滾 | 4 項驗證 + 原子性回滾 |
| AC6 | [靜態] | --remove 移除 | 冪等移除，不存在時警告但 exit 0 |
| AC7 | [靜態] | --dry-run | 只執行 Pre-flight，不部署 |
| AC8 | [靜態] | Log 機制 | `logs/schedule-<skill>.log`，START/SKIPPED/END 格式 |
| AC9 | [靜態] | docs 說明 | SKILL.md 記載完整使用方式 |

**交付摘要**：
- `skills/schedule/SKILL.md`（14 節完整文件）
- `templates/schedule_cron.sh.tmpl`（flock + OAuth + Log 模板）
- `tests/test-schedule.sh`（74 項測試全 PASS）
- `docs/adr/ADR-005-schedule-skill-technical-decisions.md`（5 決策域）

**驗收結果**：AC1-AC9 全通過（9/9）；測試 74/74 PASS
**MoSCoW**：Should
**Size**：L / **Points**：3
**ADR**：ADR-005（Accepted）

---

## Sprint 19（2026-03-02）

**Sprint Goal**：強化 schedule skill 安全性，修正 PO drift 保護缺口，建立序列群組鎖機制

| Story | RICE | MoSCoW | ADR | 完成狀態 |
|-------|------|--------|-----|----------|
| Retro #53：schedule skill — skill name 字元白名單驗證 | — | Must | — | Done |
| Retro #54：schedule skill — 模板品質強化 | — | Must | — | Done |
| US-30：PO subagent 多輪派遣 Story 內容偏離修正機制 | 25.6 | Should | — | Done |
| US-36：Planning + Execution 序列排程 — 避免平行衝突 | 待定 | Should | — | Done |

---

### Retro #53：schedule skill — skill name 字元白名單驗證

**來源**：Sprint 18 Retro Action Item #53（[Issue #53](https://github.com/KCTW/shikigami/issues/53)）

**交付摘要**：`skills/schedule/SKILL.md` 新增 skill name 字元白名單驗證規則，僅允許小寫字母、數字與連字號（`[a-z0-9-]`）；不符合規則時阻擋排程設定並輸出明確錯誤訊息，防止注入類風險。

**Acceptance Criteria**
- AC1：SKILL.md 定義 skill name 白名單格式（`^[a-z0-9-]+$`）
- AC2：Pre-flight 檢查新增白名單驗證步驟；不符合時輸出 ERROR 並拒絕繼續
- AC3：測試案例覆蓋合法名稱與非法名稱（含空格、大寫、特殊字元等邊界案例）

**驗收結果**：AC 全通過；Issue #53 CLOSED
**Size**：S / **Points**：1

---

### Retro #54：schedule skill — 模板品質強化

**來源**：Sprint 18 Retro Action Item #54（[Issue #54](https://github.com/KCTW/shikigami/issues/54)）

**交付摘要**：`templates/schedule_cron.sh.tmpl` 新增 `set -euo pipefail` 嚴格模式與備份安全機制；確保腳本在非零 exit 時立即終止，避免靜默錯誤；備份操作使用原子性步驟，防止備份失敗留下損壞狀態。

**Acceptance Criteria**
- AC1：模板新增 `set -euo pipefail` 於腳本頭部
- AC2：備份流程新增完整性驗證步驟；備份失敗時阻擋後續操作並回滾
- AC3：相關測試案例更新覆蓋新增的嚴格模式行為

**驗收結果**：AC 全通過；Issue #54 CLOSED
**Size**：S / **Points**：1

---

### US-30：PO subagent 多輪派遣 Story 內容偏離修正機制

**標題**：防止 PO subagent 在多輪派遣間發生 Story 內容偏離

**User Story**
As a Scrum Master, I want the PO subagent to include a consistency check when dispatched across multiple rounds, so that Story acceptance criteria and scope remain stable and do not drift between planning rounds due to context divergence.

**Acceptance Criteria**
- AC1：`skills/sprint-planning/SKILL.md` PO subagent 派遣 prompt 新增「偏離偵測」指引：PO subagent 於第二輪起須比對本輪輸出與前輪存檔，若 AC 變動 > 20% 標記 DRIFT WARNING
- AC2：DRIFT WARNING 觸發時輸出差異摘要（變動欄位 + 前後值），主 session 決定是否接受變更或重派
- AC3：偏離偵測邏輯記錄於 sprint_N.md PO 輪次區塊，保留比對記錄

**RICE 評分**：25.6
**MoSCoW**：Should
**Size**：S / **Points**：1
**來源**：Sprint 17 Retro / Issue #48（對應 Retro #48）

**驗收結果**：AC 全通過；Issue #48 CLOSED

---

### US-36：Planning + Execution 序列排程 — 避免平行衝突

**標題**：在 schedule skill 中實作序列群組鎖，確保 Planning 與 Execution 不會同時執行

**User Story**
As a framework user using automated scheduling, I want Planning and Execution phases to be locked sequentially so they cannot run concurrently, preventing file conflicts and state corruption that would occur if both phases write to sprint documents simultaneously.

**Acceptance Criteria**
- AC1：`skills/schedule/SKILL.md` 定義「序列群組」概念：Planning 與 Execution 屬同一群組，同群組內同時只允許一個排程執行
- AC2：腳本生成邏輯新增群組鎖機制（lockfile 或 flock group key），同群組第二個排程啟動時輸出 SKIPPED 並記錄原因
- AC3：`--dry-run` 模式顯示群組鎖狀態（當前是否有同群組排程執行中）
- AC4：相關測試案例覆蓋群組鎖衝突偵測與 SKIPPED 路徑

**MoSCoW**：Should
**Size**：M / **Points**：2
**來源**：GitHub Issue #50

**驗收結果**：AC 全通過；Issue #50 CLOSED

---

## Sprint 20（2026-03-02）

**Sprint Goal**：清零 Sprint 19 Retro Action Items（#56、#57），交付 /shoot 短衝模式（US-31）

| Story | RICE | MoSCoW | ADR | 完成狀態 |
|-------|------|--------|-----|----------|
| Retro #56（Issue #56）：修復 test-schedule.sh assert_contains SIGPIPE 非確定性失敗 | — | Must | — | Done |
| Retro #57（Issue #57）：Developer subagent 狀態更新衝突防護 | — | Must | — | Done |
| US-31（Issue #47）：/shoot 短衝模式 | 待定 | Should | — | Done |

---

### Retro #56（Issue #56）：修復 test-schedule.sh assert_contains SIGPIPE 非確定性失敗

**來源**：Sprint 19 Retro Action Item #56（[Issue #56](https://github.com/KCTW/shikigami/issues/56)）

**交付摘要**：`assert_contains` 函式修正管線寫入競態問題，消除 SIGPIPE 非確定性失敗；連續執行 10 次零失敗驗證通過。

**Acceptance Criteria**
- AC1：SIGPIPE 根因修正
- AC2：連續執行 10 次零失敗
- AC3：無迴歸

**驗收結果**：AC 全通過（3/3）；Issue #56 CLOSED
**Size**：S / **Points**：1

---

### Retro #57（Issue #57）：Developer subagent 狀態更新衝突防護

**來源**：Sprint 19 Retro Action Item #57（[Issue #57](https://github.com/KCTW/shikigami/issues/57)）

**交付摘要**：`skills/sprint-execution/SKILL.md` 新增「狀態更新衝突防護」段落，定義 read-then-compare 偵測機制與 [CONFLICT] 輸出格式，防止 Developer subagent 靜默覆蓋主 session 已更新的狀態欄。

**Acceptance Criteria**
- AC1：衝突偵測機制定義
- AC2：可觀察的衝突指示
- AC3：衝突場景驗收

**驗收結果**：AC 全通過（3/3）；Issue #57 CLOSED
**Size**：S / **Points**：1

---

### US-31（Issue #47）：/shoot 短衝模式

**標題**：單一任務快速執行，跳過完整 Sprint 儀式

**User Story**
As a framework user, I want a `/shoot` command that executes a single task without full Sprint ceremony, so that I can deliver small improvements quickly without the overhead of Planning, Review, and Retrospective.

**Acceptance Criteria**
- AC1：自動抓取模式（bug → retro-action → Backlog S-size 優先順序）
- AC2：直接描述模式
- AC3：GitHub Issue 模式
- AC4：Backlog Story 模式
- AC5：文件產出完整性（Shoot_Log.md + PROJECT_BOARD 短衝記錄）
- AC6：瘦身歸檔（超過 20 筆時移出最舊記錄）
- AC7：Sprint Review 連動（掃描 Shoot_Log.md）
- AC8：Hard Gate 保留（QA + Architect 審查必須保留）

**交付摘要**：
- `skills/shoot/SKILL.md` 完整短衝模式定義
- `tests/test-shoot.sh`（62 項測試）+ `tests/test-conflict-guard.sh`（12 項測試）全 PASS
- 總計 238 個測試全綠

**驗收結果**：AC1-AC8 全通過（8/8）；測試 74/74 PASS
**MoSCoW**：Should
**Size**：L / **Points**：3
**來源**：Sprint 17 Retro / Issue #47

---

## Sprint 35（2026-04-20 ~ 2026-04-26）

**Sprint Goal**：ADR-010 原子性實作交付 — Backlog Source of Truth 從 PRODUCT_BACKLOG.md 遷移至 GitHub Issues，完成三個 SKILL.md 改寫 + DEPRECATED 標頭 + Label 基礎設施

| Story ID | 標題 | Size | Points | 狀態 |
|----------|------|------|--------|------|
| US-69 | ADR-010 Label 基礎設施 — 建立所有 ADR-010 定義 labels 並更新 onboarding Pre-flight | S | 1 | Done |
| US-70 | `backlog-intake` SKILL.md 重大改寫 — 移除 PRODUCT_BACKLOG.md 寫入，改為 Issue label + body template 兩層架構 | M | 2 | Done |
| US-71 | `sprint-planning` SKILL.md 修改 — PO Story 選取來源改為 `gh issue list` + 即時 MoSCoW/RICE 排序計算 | M | 2 | Done |
| US-72 | `backlog-management` SKILL.md 修改 — Grooming 流程改為操作 GitHub Issues，加入 Pre-flight 錯誤恢復掃描 | M | 2 | Done |
| US-73 | PRODUCT_BACKLOG.md DEPRECATED 標頭加入 + ADR-009 格式契約決策域「Superseded by ADR-010」標注 | S | 1 | Done |

### US-69：ADR-010 Label 基礎設施

**來源**：ADR-010 Label 基礎設施建立
**Size**：S / 1 Point
**MoSCoW**：Must
**QA doc-only 判定**：No

**User Story**
As a Developer executing the ADR-010 migration, I want all ADR-010-defined labels created in the GitHub repository and the onboarding Pre-flight checklist updated to verify these labels exist, so that subsequent Sprint 35 Stories can operate on a verified label infrastructure.

**交付摘要**：14 個 ADR-010 labels 全數建立（Original Issue 5 + Backlog Issue 3 + Priority 3 + Size 3），onboarding Pre-flight §2.1.2 新增 ADR-010 Labels 驗證步驟

**驗收結果**：AC1–AC4 全通過（4/4）

---

### US-70：`backlog-intake` SKILL.md 重大改寫

**來源**：ADR-010 backlog-intake 流程遷移
**Size**：M / 2 Points
**MoSCoW**：Must
**QA doc-only 判定**：No

**User Story**
As a Product Owner running the backlog-intake workflow, I want the backlog-intake SKILL.md rewritten to remove all PRODUCT_BACKLOG.md write operations and instead output to GitHub Issues via label application and Issue body template filling, so that the Backlog source of truth is exclusively GitHub Issues per ADR-010.

**交付摘要**：移除所有 PRODUCT_BACKLOG.md 寫入步驟，新增兩層 Issue 建立流程（原始 Issue + Backlog Issue），Issue body Story template 含 RICE 評分表格，冪等性保護以「來源：#N」body 掃描實作

**驗收結果**：AC1–AC7 全通過（7/7），ADR-003 Checklist PASS

---

### US-71：`sprint-planning` SKILL.md 修改

**來源**：ADR-010 sprint-planning 流程遷移
**Size**：M / 2 Points
**MoSCoW**：Must
**QA doc-only 判定**：No

**User Story**
As a PO subagent running Sprint Planning, I want the sprint-planning SKILL.md updated so that Story selection uses `gh issue list` with label/milestone filtering and real-time MoSCoW/RICE sorting instead of reading PRODUCT_BACKLOG.md.

**交付摘要**：§2 Step 4 來源替換為 gh issue list，§6 Step 1 PO 讀取來源移除 PRODUCT_BACKLOG.md，新增即時 RICE 排序計算邏輯，§6 Step 4 PO Round 2 改為套用 status: in-sprint label + Milestone

**驗收結果**：AC1–AC6 全通過（6/6），ADR-003 Checklist PASS

---

### US-72：`backlog-management` SKILL.md 修改

**來源**：ADR-010 backlog-management 流程遷移
**Size**：M / 2 Points
**MoSCoW**：Must
**QA doc-only 判定**：No

**User Story**
As a Product Owner running Backlog Grooming, I want the backlog-management SKILL.md updated so that all Grooming operations work against GitHub Issues instead of PRODUCT_BACKLOG.md, and a Pre-flight error recovery scan is included.

**交付摘要**：§2 Product Discovery 產出改為 GitHub Issues + 原始 labels，§3 Grooming 全部改為 gh issue list/edit 操作，新增 Pre-flight 錯誤恢復掃描（三場景），§6 PRODUCT_BACKLOG.md 降格為非核心產出

**驗收結果**：AC1–AC5 全通過（5/5），ADR-003 Checklist PASS

---

### US-73：PRODUCT_BACKLOG.md DEPRECATED 標頭加入

**來源**：ADR-010 原子性交付後置條件
**Size**：S / 1 Point
**MoSCoW**：Must
**QA doc-only 判定**：Yes

**User Story**
As a Developer completing the ADR-010 atomic delivery, I want PRODUCT_BACKLOG.md marked with a DEPRECATED header and ADR-009's Format Contract decision domain annotated as "Superseded by ADR-010".

**交付摘要**：PRODUCT_BACKLOG.md 頂部加入完整 DEPRECATED blockquote 標頭，ADR-009 決策域二加入「Superseded by ADR-010」標注

**驗收結果**：AC1–AC4 全通過（4/4），原子性後置條件滿足（commit 時序位於 US-70/71/72 之後）

---

## Sprint 34（2026-04-13 ~ 2026-04-19）

**Sprint Goal**：Issue #46 自動化排程框架收尾結案 + Issue #49 CI 失敗根因修正

| Story ID | 標題 | Size | Points | 狀態 |
|----------|------|------|--------|------|
| US-66 | Issue #46 最終收尾 — 四條排程流程驗收條件逐項確認、缺口補齊，close Issue #46 | S | 1 | Done |
| US-68 | Issue #49 框架端主動修正評估 — workflow check 失敗根因分析（根因已確認：Sprint 33 commit 順序問題，非框架 bug） | S | 1 | Done |

### US-66：Issue #46 最終收尾

**來源**：GitHub Issue #46 最終結案
**Size**：S / 1 Point
**MoSCoW**：Must
**QA doc-only 判定**：Yes

**User Story**
As a Product Owner tracking Issue #46 completion, I want the four-flow acceptance conditions of the automated scheduling framework verified against the original 12 ACs, gaps documented, and Issue #46 closed, so that the framework's scheduling capability is formally marked as delivered.

**交付摘要**：逐項比對 Issue #46 原始 12 條 AC 與四條排程流程產出的覆蓋對照表，所有 AC 確認為 Covered。Issue #46 以詳細 comment 關閉。

**驗收結果**：AC1–AC4 全通過（4/4）；Issue #46 CLOSED

---

### US-68：Issue #49 框架端主動修正評估

**來源**：GitHub Issue #49 / CI 失敗調查
**Size**：S / 1 Point
**MoSCoW**：Must
**QA doc-only 判定**：Yes

**User Story**
As a Developer maintaining framework CI health, I want the root cause of Issue #49 workflow check failure confirmed, documented as a comment on Issue #49, and the issue closed if the root cause is a development process concern rather than a framework bug.

**交付摘要**：根因確認為 Sprint 33 commit 順序問題（Planning 文件引用 backlog-intake 10 分鐘早於 SKILL.md 建立）。根因分析報告以 comment 發布至 Issue #49，走 AC4 路徑關閉 Issue。

**驗收結果**：AC1 PASS、AC2 PASS、AC4 PASS（AC3 互斥分支跳過）；Issue #49 CLOSED

---

## Sprint 33（2026-04-06 ~ 2026-04-12）

| Story ID | 標題 | Size | Points | 狀態 |
|----------|------|------|--------|------|
| US-63 | Issue #46 子 Story #4 — 需求入庫自動化（PO Backlog Intake cron + shikigami:backlog-intake Skill） | M | 2 | Done |
| US-64 | M5 條件 (a) 主動觸及強化 — 外部社群推廣文案製作（GitHub README badges + 技術文章草稿 + 主動 outreach 指引） | S | 1 | Done |
| US-65 | US-T08（Intent Routing 測試）評估重開 — RICE 重新評分與 Sprint Planning 可行性確認 | S | 1 | Done |

---

## Sprint 32（2026-03-03）

**Sprint Goal**：完成排程衝刺程式碼入庫 QA 自動化（Issue #46 子 Story #3），強化 M5 條件 (a) 外部使用者觸及之 Onboarding 低摩擦路徑，並建立 Token 追蹤 Baseline Snapshot 機制

| Story ID | 標題 | Size | Points | 完成日期 |
|----------|------|------|--------|----------|
| US-60 | Issue #46 子 Story #3 — 排程衝刺程式碼入庫 QA 自動化（schedule SKILL.md + scrum-master/sprint-review SKILL.md） | M | 2 | 2026-03-03 |
| US-61 | M5 條件 (a) 外部使用者觸及強化 — Onboarding 低摩擦路徑最佳化（README + tutorial + M5 追蹤更新） | S | 1 | 2026-03-03 |
| US-62 | Issue #35 — Token 追蹤 Baseline Snapshot 機制（Metrics_Log.md + sprint-planning/execution SKILL.md） | S | 1 | 2026-03-03 |

### US-60：Issue #46 子 Story #3 — 排程衝刺程式碼入庫 QA 自動化

**來源**：GitHub Issue #46 子 Story #3 / Sprint 32 Planning
**Size**：M / 2 Points
**MoSCoW**：Should
**RICE**：待定

**User Story**
As a Scrum Master using the scheduled sprint execution mode, I want automated QA checks to run before committing code generated by scheduled sprints, so that schedule-driven code changes meet the same quality standards as interactively executed sprints without manual intervention.

**Acceptance Criteria**

- AC1：`skills/schedule/SKILL.md` 新增排程衝刺程式碼入庫前自動 QA 步驟說明
- AC2：`skills/scrum-master/SKILL.md` 更新排程模式下 QA 閘的觸發條件與通過標準
- AC3：`skills/sprint-review/SKILL.md` 新增排程衝刺完成後的 QA 結果記錄指引
- AC4：Issue #46 對應此子 Story 部分留言說明交付內容並關閉對應任務項

**驗收結果**：AC1–AC4 全通過（4/4）

---

### US-61：M5 條件 (a) 外部使用者觸及強化 — Onboarding 低摩擦路徑最佳化

**來源**：M5 條件 (a) 外部使用者觸及 / Architect 建議（Sprint 32 Planning）
**Size**：S / 1 Point
**MoSCoW**：Must
**RICE**：待定

**User Story**
As a new external user discovering Shikigami, I want the onboarding path to be frictionless with clear entry points in README and tutorial, so that I can start my first Sprint without needing to read extensive internal documentation.

**Acceptance Criteria**

- AC1：`README.md` Onboarding 引導路徑精化，入口清晰且步驟減少不必要跳轉
- AC2：`docs/tutorial/GETTING_STARTED.md` 更新以反映最新 Onboarding 流程
- AC3：M5 追蹤文件（`docs/prd/M5_COMPLETION_ASSESSMENT.md`）更新條件 (a) 進展狀態

**驗收結果**：AC1–AC3 全通過（3/3）

---

### US-62：Issue #35 — Token 追蹤 Baseline Snapshot 機制

**來源**：GitHub Issue #35 / Sprint 32 Planning
**Size**：S / 1 Point
**MoSCoW**：Should
**RICE**：待定

**User Story**
As a Product Owner tracking framework efficiency, I want a Token tracking baseline snapshot mechanism in Metrics_Log.md and integrated into sprint-planning/execution SKILL.md, so that I can compare token consumption trends across Sprints against a stable baseline reference point.

**Acceptance Criteria**

- AC1：`docs/km/Metrics_Log.md` 新增 Baseline Snapshot 區段，定義基準值格式與更新條件
- AC2：`skills/sprint-planning/SKILL.md` 新增 Baseline Snapshot 參照步驟（Token 消耗與基準值對比）
- AC3：`skills/sprint-execution/SKILL.md` 新增執行環節 Token 超標預警指引（超過 Baseline 閾值時觸發提醒）

**驗收結果**：AC1–AC3 全通過（3/3）

---

## Sprint 31（2026-03-03）

**Sprint Goal**：完成排程衝刺 worktree 隔離執行框架（Issue #46 子 Story #2），同步強化 M5 Beta 回饋閉環（Issue #59 追蹤機制 + README 招募文案精化）與 README 自動更新排程設定指引（Issue #52），推進 M5 條件 (a) 外部使用者觸及

| Story ID | 標題 | Size | Points | 完成日期 |
|----------|------|------|--------|----------|
| US-57 | Issue #46 子 Story #2 — 排程衝刺 worktree 隔離執行框架（schedule SKILL.md + scrum-master SKILL.md） | M | 2 | 2026-03-03 |
| US-58 | M5 Beta 回饋閉環強化 — Issue #59 追蹤機制與 README 招募文案精化 | S | 1 | 2026-03-03 |
| US-59 | Issue #52 — README 自動更新排程設定指引（schedule SKILL.md 使用範例） | S | 1 | 2026-03-03 |

### US-57：Issue #46 子 Story #2 — 排程衝刺 worktree 隔離執行框架

**來源**：GitHub Issue #46 子 Story #2 / Sprint 31 Planning
**Size**：M / 2 Points
**MoSCoW**：Should
**RICE**：待定

**User Story**
As a Scrum Master using the scheduled sprint execution mode, I want each scheduled sprint to run inside an isolated git worktree, so that concurrent scheduled executions do not interfere with each other or with the main working tree, and failed runs can be inspected and cleaned up independently.

**Acceptance Criteria**

- AC1：`skills/schedule/SKILL.md` 新增 worktree 隔離執行框架說明，定義排程衝刺啟動時自動建立獨立 worktree 的流程
- AC2：`skills/scrum-master/SKILL.md` 新增排程模式下 worktree 生命週期管理指引（建立、執行、清理）
- AC3：worktree 命名規則與路徑隔離策略有明確定義（防止同一 Sprint 多次觸發時路徑衝突）
- AC4：Issue #46 對應此子 Story 部分留言說明交付內容並關閉對應任務項

**驗收結果**：AC1–AC4 全通過（4/4）

---

### US-58：M5 Beta 回饋閉環強化

**來源**：M5 條件 (a) 缺口 / Architect 建議（Sprint 31 Planning）
**Size**：S / 1 Point
**MoSCoW**：Must
**RICE**：待定

**User Story**
As a Product Owner managing the M5 Beta program, I want Issue #59 to have a structured tracking mechanism and the README Beta recruitment copy to be refined, so that potential external users can clearly understand how to participate and their feedback is systematically captured.

**Acceptance Criteria**

- AC1：GitHub Issue #59 建立追蹤機制（label、milestone 或 checklist），確保回饋收集有明確入口
- AC2：`README.md` Beta 招募文案精化，使邀請語氣更明確、參與流程更清晰（步驟與聯絡方式可見）
- AC3：精化後的 README 文案不產生新的平台宣稱矛盾（與現有 M5 文件一致）

**驗收結果**：AC1–AC3 全通過（3/3）

---

### US-59：Issue #52 — README 自動更新排程設定指引

**來源**：GitHub Issue #52 / Architect 建議（Sprint 31 Planning）
**Size**：S / 1 Point
**MoSCoW**：Should
**RICE**：待定

**User Story**
As an external user who has installed Shikigami and wants to use the scheduled sprint feature, I want the README to contain clear setup instructions for the auto-update schedule with concrete examples from schedule SKILL.md, so that I can configure scheduled execution without needing to read internal documentation.

**Acceptance Criteria**

- AC1：`README.md` 新增「排程設定」說明區段，涵蓋 `shikigami:schedule` 基本使用範例
- AC2：說明內容與 `skills/schedule/SKILL.md` 現有指引一致，無過時或矛盾描述
- AC3：GitHub Issue #52 留言說明交付內容並關閉

**驗收結果**：AC1–AC3 全通過（3/3）

---

## Sprint 30（2026-03-03）

**Sprint Goal**：以 Issue #46 排程 PR 偵測為最高優先，同步修正 README 準確性並強化版本 Tag 策略，確保框架在開源延後期間的自我一致性與維護品質

| Story ID | 標題 | Size | Points | 完成日期 |
|----------|------|------|--------|----------|
| US-54 | 互動 Session 自動偵測待審排程 PR + Scrum Master 提醒機制（Issue #46 子 Story #1） | S | 1 | 2026-03-03 |
| US-55 | README 準確性修正 — 版本號、Skill 數量、版本歷史對齊 | S | 1 | 2026-03-03 |
| US-56 | Deployment Readiness 版本 Tag 決策規則強化（Issue #36） | M | 2 | 2026-03-03 |

### US-54：互動 Session 自動偵測待審排程 PR + Scrum Master 提醒機制

**來源**：GitHub Issue #46 子 Story #1
**Size**：S / 1 Point
**MoSCoW**：Should

**User Story**
As a Scrum Master running an interactive session, I want the system to automatically detect pending scheduled PRs and remind me at session start, so that I never miss reviewing a queued scheduled execution PR and the team's Sprint cadence remains unblocked.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | scrum-master SKILL.md 新增 PR 偵測步驟 | `skills/scrum-master/SKILL.md` 互動 Session 啟動段落新增排程 PR 偵測步驟 |
| AC2 | [靜態] | 有待審 PR 時的提醒格式 | 標準提醒區塊（PR 數量摘要 + 各 PR 編號/標題/建立時間 + 三選項） |
| AC3 | [靜態] | label 標準化定義 | `skills/schedule/SKILL.md` 腳本生成模板補充 `scheduled` label |
| AC4 | [靜態] | ADR-003 Checklist 通過 | 修改 skills/ 下 SKILL.md 前確認 ADR-003 四項條件 |

---

### US-55：README 準確性修正 — 版本號、Skill 數量、版本歷史對齊

**來源**：Architect 建議（Sprint 30 Planning）
**Size**：S / 1 Point
**MoSCoW**：Must

**User Story**
As an external user reading the README, I want the version number, Skill count, version history, and Sprint streak to accurately reflect the current project state, so that I can trust the documentation and make informed decisions about adopting Shikigami.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 版本號更新 | `README.md` 版本號（v0.3.9→v0.13.0 或最新 plugin.json 版本）更新；版本號與 `plugin.json` version 一致 |
| AC2 | [靜態] | Skill 數量與清單對齊 | 「17 個 Skills」→「21 個 Skills」（對齊 skills/ 目錄計數）；清單補入 schedule 與 shoot |
| AC3 | [靜態] | 版本歷史表格對齊 | 版本歷史表格補充 Sprint 16-29 交付里程碑 |
| AC4 | [靜態] | Sprint 連勝數更新 | 「連續 15 個 Sprint / 56 Stories / 4 ADR」更新為截至 Sprint 29 正確數值 |
| AC5 | [靜態] | ADR-003 Not Triggered | README.md 為說明文件，ADR-003 不適用 |

---

### US-56：Deployment Readiness 版本 Tag 決策規則強化（Issue #36）

**來源**：GitHub Issue #36 / Architect 建議（Sprint 30 Planning）
**Size**：M / 2 Points
**MoSCoW**：Must

**User Story**
As a Scrum Master running sprint review, I want deployment-readiness SKILL.md to define clear version Tag decision rules including a PO Override mechanism, and sprint-review SKILL.md to verify ROADMAP milestone alignment before deployment, so that the team has deterministic governance over version tagging and avoids accidental or inconsistent releases.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 版本號選擇規則定義 | `skills/deployment-readiness/SKILL.md` 新增「版本 Tag 決策規則」段落 |
| AC2 | [靜態] | sprint-review SKILL.md 整合 ROADMAP 對齊檢查 | sprint-review deployment-readiness 步驟前新增里程碑對齊子步驟 |
| AC3 | [靜態] | 緊急覆蓋機制 | 定義 PO Override 機制，覆蓋行為標注 [PO-OVERRIDE] |
| AC4 | [動態] | Issue #36 關閉 | GitHub Issue #36 留言說明解決內容並關閉 |
| AC5 | [靜態] | ADR-003 Checklist 通過 | 修改兩個 SKILL.md 前通過 ADR-003 四項條件 |

---

## Sprint 29（2026-03-03）

**Sprint Goal**：以 Issue #3 正式結案為里程碑，完成 OpenCode 平台動態驗證（US-52）與 M5 條件 (a) 外部使用者觸及的具體招募行動（US-53），使 M5 最後一個開放條件進入可達成狀態

| Story ID | 標題 | Size | Points | 完成日期 |
|----------|------|------|--------|----------|
| US-52 | OpenCode Phase 4 — Issue #3 正式結案：動態驗證補完與 Issue 關閉 | M | 2 | 2026-03-03 |
| US-53 | M5 Beta 使用者招募 — README 招募文案 + Issue 引導機制 | S | 1 | 2026-03-03 |

---

## Sprint 28

| Story ID | 標題 | Size | Points | 完成日期 |
|----------|------|------|--------|----------|
| US-49 | OpenCode Phase 3a — 剩餘四個角色 Agent 移植 | S | 1 | 2026-03-02 |
| US-50 | OpenCode Phase 3b — INSTALL_OPENCODE.md 安裝指南 | S | 1 | 2026-03-02 |
| US-51 | OpenCode Phase 3c — Task Tool 參數確認與 Developer dispatch 動態驗證 | M | 2 | 2026-03-02 |

---

## Sprint 27（2026-03-15）

**Sprint Goal**：完成 ADR-008 架構決策 + 啟動 OpenCode Phase 2，為 M5 條件 (a) 外部使用者觸及提供完整平台整合策略與首個角色移植驗證

| Story ID | 標題 | Size | Points | 完成 Sprint |
|----------|------|------|--------|-------------|
| US-47 | ADR-008: OpenCode 平台整合策略架構決策 | S | 1 | Sprint 27 |
| US-48 | OpenCode Phase 2 — Subagent 角色移植與派遣驗證 | L | 3 | Sprint 27 |

---

## Sprint 26（2026-03-03）

| Story ID | 標題 | Size | Points | 完成 Sprint |
|----------|------|------|--------|-------------|
| US-46 | OpenCode 目錄適配與 SKILL.md 載入驗證（Phase 1） | M | 2 | Sprint 26 |

---

## Sprint 25（2026-03-03）

**Sprint Goal**：在 M5 穩定化收尾階段，執行 M5 完成條件終審、Tech Debt Registry 清理、及 OpenCode POC 可行性調查，為 v1.0.0 前置條件提供明確評估依據

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-43：M5 完成條件終審 + Issues #3/#4/#5 結論決策 | M | 2 | Sprint 25 |
| US-44：Tech Debt Grooming Sprint 25 + TD-001 降級決策 | S | 1 | Sprint 25 |
| US-45：OpenCode POC 可行性調查 | S | 1 | Sprint 25 |

---

## Sprint 24（2026-03-30）

**Sprint Goal**：在 ADR-007 Phase 1 架構基準上實作外部抽樣審查機制（Phase 2），完成「自審為主、抽檢為輔」品質保障層，並同步強化 Architect/QA 角色在 Story-Lifecycle 架構下的決策知識

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-41：ADR-007 Phase 2 — 外部抽樣審查機制實作 | M | 3 | Sprint 24 |
| US-42：Architect/QA 框架知識強化 — Story-Lifecycle 架構下角色決策指引 | S | 2 | Sprint 24 |

---

## Sprint 23（2026-03-29）

**Sprint Goal**：落實 ADR-007 首個實作里程碑，同步清零 Sprint 22 技術品質欠帳

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-40：Story-Lifecycle Subagent 實作 — ADR-007 Phase 1 | M | 2 | Sprint 23 |
| Retro #59（Issue #59）：Cron template SHIKIGAMI_SCHEDULED 條件化 export 修正 | S | 1 | Sprint 23 |
| Retro #60（Issue #60）：TECH-DEBT Registry 補登 ADR-006 JSON Schema 技術債 (TD-002) | S | 1 | Sprint 23 |
| Retro #61（Issue #61）：Onboarding SKILL.md stale reference 審查與修正 | S | 1 | Sprint 23 |

---

## Sprint 22（2026-03-03）

**Sprint Goal**：強化框架安全性與排程智能化

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-33（Issue #33）：Onboarding 缺少 BACKLOG_DONE.md 模板 | S | 1 | Sprint 22 |
| US-37（Issue #55）：防範 Issue 提示注入攻擊 | S | 1 | Sprint 22 |
| US-38（Issue #51）：排程模式下 Velocity 自動調小 — 僅選 S size Stories | S | 1 | Sprint 22 |
| US-39（Issue #45）：Sprint Execution context overflow — Story 生命週期封裝為 subagent | L | 3 | Sprint 22 |

---

## Sprint 21（2026-03-02）

**Sprint Goal**：清零 Sprint 20 Retro Action Item（#58）+ parallel-dispatch 衝突偵測（US-32）+ Onboarding Labels 補完（US-34）

| Story | Size | Points | 完成狀態 |
|-------|------|--------|----------|
| Retro #58（Issue #58）：L-size Story QA checklist 強化 — SKILL.md 新增大型 Story 審查增強項 | S | 1 | Done |
| US-32（Issue #40）：parallel-dispatch 應內建同檔案衝突偵測與自動序列化 | M | 2 | Done |
| US-34（Issue #32）：Onboarding 應預建常用 GitHub Labels | S | 1 | Done |

---

## Sprint 36（2026-04-27）

**Sprint Goal**：ADR-010 生命週期閉環完成 — sprint-review Issue 狀態回寫、Backlog 初始化、Tech Debt Grooming Sprint 36

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-74（Issue #67）：ADR-010 後置 — sprint-review SKILL.md Story 完成後 Issue 狀態回寫對齊 | S | 1 | Sprint 36 |
| US-75（Issue #68）：ADR-010 Backlog 初始化 — 將現有候選 Stories 建立為 GitHub Issues | M | 2 | Sprint 36 |
| US-76（Issue #62）：Tech Debt Grooming Sprint 36 — TD-002 評估 + ADR-010 遷移後新技術債掃描 | S | 1 | Sprint 36 |

---

## Sprint 37（2026-05-04 ~ 2026-05-10）

**Sprint Goal**：單層 Issue 架構改造 + PO Review Gate + shoot ADR-010 適配

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-77（Issue #73）：單層 Issue 架構改造 — backlog-intake / backlog-management 棄用兩層 Issue | M | 2 | Sprint 37 |
| US-78（Issue #72）：shoot skill US-XX 模式需適配 ADR-010 | S | 1 | Sprint 37 |
| US-80（Issue #74）：backlog-intake PO Review Gate — AI 自動入庫後新增 PO 審查階段 | S | 1 | Sprint 37 |

---

## Sprint 38（2026-05-11 ~ 2026-05-17）

**Sprint Goal**：ADR-011 起草 + Decision Knowledge Base + PO 審查積壓量可視化

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-81（Issue #75）：ADR-011 起草 — GitHub Actions 整合架構決策 | S | 1 | Sprint 38 |
| US-11（Issue #76）：Decision Knowledge Base — ADR 查詢與決策影響追蹤 | M | 2 | Sprint 38 |
| US-82（Issue #77）：PO 審查積壓量可視化 — backlog-management 新增待審 Issues 計數與老齡警示 | S | 1 | Sprint 38 |

---

## Sprint 39（2026-05-18 ~ 2026-05-24）

**Sprint Goal**：ADR-011 正式裁決 + US-12 CI/CD 狀態感知

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-83（Issue #78）：ADR-011 正式裁決 — GitHub Actions 整合架構決策 Proposed → Accepted | S | 1 | Sprint 39 |
| US-12（Issue #79）：GitHub Actions 整合 — CI/CD 狀態感知與 Sprint Health Check 整合 | M | 2 | Sprint 39 |

---

## Sprint 40（2026-05-25 ~ 2026-05-31）

**Sprint Goal**：M4 度量層 — US-13 DORA Metrics 交付 + TD-002 技術債清償

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-13（Issue #80）：DORA Metrics — 部署頻率、變更前置時間、MTTR、變更失敗率追蹤 | L | 3 | Sprint 40 |
| TD-002（Issue #65）：PO subagent 輸出格式 JSON Schema 正式驗證 | M | 2 | Sprint 40 |

---

## Sprint 41（2026-03-04）

**Sprint Goal**：M4 收尾與文件一致性強化

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-84（Issue #80）：M4 里程碑正式收尾 — ROADMAP US-14 完成標注 + M4 結案評估 | S | 1 | Sprint 41 |
| US-85（Issue #80）：TD-002 技術債結案 + Schema 文案修正 | S | 1 | Sprint 41 |
| US-86（Issue #81）：交付物文案一致性審查機制 — 回應 Sprint 38-40 連續 Retro Problem | M | 2 | Sprint 41 |
| US-87（Issue #82）：GitHub Action 自動觸發 backlog-intake — Issue labeled 事件驅動入庫 | S | 1 | Sprint 41 |

---

## Sprint 42（2026-03-04）

**Sprint Goal**：完善 Onboarding 自動化鏈路（GitHub Action 串接）並強化 Sprint 執行品質（Done 定義 checkbox 強化）

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-88（Issue #83）：Onboarding 自動串接 GitHub Action — runner 偵測 + backlog-intake 驗證 | M | 2 | Sprint 42 |
| US-89（Issue #84）：story-lifecycle-prompt.md Done 定義 checkbox 自動勾選提醒強化 | S | 1 | Sprint 42 |

---

## Sprint 43（2026-03-04）

**Sprint Goal**：為 Backlog 下一個發展方向奠定決策基礎：精化 #69 為可執行 Story，並執行 M5 外部觸及效果最終診斷

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-90（Issue #69）：Issue #69 精化 — 「開發不中斷 營運不中斷」可行性分析與 Story 拆解 | S | 1 | Sprint 43 |
| US-91（Issue #85）：M5 條件 (a) 觸及診斷 — Outreach Log 審查 + 安裝阻力掃描 | M | 2 | Sprint 43 |

---

## Sprint 44（2026-03-05）

**Sprint Goal**：建立多開發環境認證架構基礎 — 起草 ADR-012，確認 ToS 合規性與多 GCE 平行開發認證方案

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-92（Issue #86）：ADR-012 起草 — Claude Max 多開發環境認證架構決策 | S | 1 | Sprint 44 |

---

## Sprint 45（2026-03-05）

**Sprint Goal**：完善多開發環境操作文件 — 建立 GCE 認證設定指引與 CI/CD workflow 拆分指引

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-A（Issue #87）：多 GCE 認證設定指引 — 文件化各開發環境 OAuth 認證與使用紀律規範 | S | 1 | Sprint 45 |
| US-93（Issue #88）：CI/CD workflow 拆分指引 — GitHub-hosted tests + self-hosted notification trigger | S | 1 | Sprint 45 |

---

### Sprint 52（2026-03-06）

| Story ID | Issue | 標題 | Size | Points |
|----------|-------|------|------|--------|
| US-103 | #104 | Design Tokens 定義檔建立 | S | 1 |
| US-104 | #105 | 元件庫白名單 AC 注入機制 | S | 1 |

---

## Sprint 51（2026-03-06）

**Sprint Goal**：結案 backlog-intake 修正，並為 UIUX Agent 建立架構決策基礎（ADR-014）

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-100（Issue #102）：backlog-intake GitHub Action 結案確認 | S | 1 | Sprint 51 |
| US-102（Issue #100）：ADR-014 起草 — UIUX Agent 架構決策 | S | 1 | Sprint 51 |

---

## Sprint 52（2026-03-06）

**Sprint Goal**：建立 UIUX Agent 工作流的「防呆設計基礎」—— 定義機器可讀的 Design Tokens 規格、強制元件庫白名單，以及前端 Story AC 模板注入機制，使 ADR-014 Phase 1 具體落地。

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-103（Issue #104）：Design Tokens 定義檔建立 | S | 1 | Sprint 52 |
| US-104（Issue #105）：元件庫白名單 AC 注入機制 | S | 1 | Sprint 52 |

---

## Sprint 53（2026-03-06）

**Sprint Goal**：完成 ADR-014 全部三個 Phase 的 SKILL.md 定義（UX Agent / UI Agent / Vision Critic），決策 OQ-1 與 OQ-3 開放問題，並設計三層 Agent 管線端對端整合測試規格。

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-105（Issue #112）：UX Agent SKILL.md 實作 | M | 2 | Sprint 53 |
| OQ-1（Issue #109）：Playwright 截圖可行性調查 | S | 1 | Sprint 53 |
| OQ-3（Issue #111）：Vision Critic 通過閾值量化決策 | S | 1 | Sprint 53 |
| US-106（Issue #113）：UI Agent SKILL.md 實作 | M | 2 | Sprint 53 |
| US-107（Issue #114）：Vision Critic Agent SKILL.md 實作 | M | 2 | Sprint 53 |
| US-108（Issue #115）：三層 Agent 管線端對端整合測試設計 | M | 2 | Sprint 53 |

---

## Sprint 55（2026-03-06）

**Sprint Goal**：建立 Figma 整合環境基礎 — 完成 MCP Server 選型與本地設定驗證、Figma 文件結構定義，並執行 AI 透過 Figma MCP 生成 Frame 的端對端 PoC，確認 ADR-015 Phase 1 技術路徑可落地。

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-149（Issue #147）：SDD 前端模板更新 — 新增 Figma 設計稿連結欄位 | S | 1 | Sprint 55 |
| US-145（Issue #146）：Figma MCP Server 選型與本地設定驗證 | M | 2 | Sprint 55 |
| US-146（Issue #148）：Figma 文件結構定義 — Page 架構、Layer 命名規則、Frame 模板 | S | 1 | Sprint 55 |
| US-148（Issue #149）：Component Library 基礎建立 — Button / Input / Card | M | 2 | Sprint 55 |
| US-147（Issue #150）：AI 生成 Frame PoC — 透過 Figma MCP 生成帶 Auto Layout 的 Frame | M | 2 | Sprint 55 |

---

## Sprint 56（2026-03-06）

**Sprint Goal**：驗證 UIUX Figma 管線可運作性 — 建立 Figma Desktop 本地驗證環境 SOP、定義 Vision Critic Frame 截圖審查 PoC 規格、撰寫 Figma 管線使用指南，使 ADR-015 Phase 1 從技術文件走向可操作的驗證與使用文件。

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-150（Issue #151）：Figma Desktop 本地驗證環境 SOP | S | 1 | Sprint 56 |
| US-151（Issue #118）：Vision Critic PoC — Figma Frame 截圖審查 | M | 2 | Sprint 56 |
| US-152（Issue #123）：Figma 管線使用指南 | M | 2 | Sprint 56 |

---

## Sprint 57（2026-03-08）

**Sprint Goal**：鞏固 ADR-015 Phase 1 文件一致性 — 同步 Vision Critic SKILL.md 至 Figma 架構、標記舊 UX/UI Agent 文件為 Deprecated。

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-153（Issue #153）：Vision Critic SKILL.md 同步 ADR-015 Figma 架構更新 | S | 1 | Sprint 57 |
| US-154（Issue #152）：UX Agent / UI Agent SKILL.md 標記 Deprecated | S | 1 | Sprint 57 |

---

## Sprint 58（2026-03-08）

**Sprint Goal**：精簡 Sprint Review 執行流程，降低每次 Review 的時間成本與認知負荷，使 Velocity 恢復正向趨勢。

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-155（Issue #154）：Sprint Review 執行時間過長 — 流程精簡化 | M | 2 | Sprint 58 |
| US-156（Issue #106）：模型分層策略：Planning 用高階模型、Coding 用合適模型 | S | 1 | Sprint 58 |

---

## Sprint 62（2026-03-08）

**Sprint Goal**：新手體驗提升與框架減法落地 — 系統化整理首次 Sprint 常見卡關點指引（M5 條件 (a) 前提），並執行 SKILL.md 冗餘內容合併精簡（延續減法策略）。

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-165（Issue #164）：Tutorial 新手體驗改善 — 首次 Sprint 成功率提升（錯誤訊息說明 + 常見卡關點指引） | S | 1 | Sprint 62 |
| US-166（Issue #163）：框架文件精簡 — SKILL.md 重複指引合併與冗餘步驟移除 | S | 1 | Sprint 62 |
| US-167（Issue #165）：多模型 CLI 路由 Phase 1 — Adapter 介面設計與 Gemini CLI 整合實作 | M | 2 | Sprint 62 |

---

## Sprint 61（2026-03-08）

**Sprint Goal**：Backlog 健康化與框架減法持續。

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-162（Issue #160）：框架流程減法審查 — SKILL.md 冗餘步驟與重複內容清理 | S | 1 | Sprint 61 |
| US-163（Issue #161）：多模型 CLI 路由 Phase 0 — Gemini CLI 呼叫介面調查 | S | 1 | Sprint 61 |
| US-164（Issue #162）：Backlog Grooming — 現有 Issues RICE 評分補齊 + 新候選 Story 提案 | S | 1 | Sprint 61 |

---

## Sprint 60（2026-03-08）

**Sprint Goal**：輕量化與實踐 — 精簡 Sprint 流程步驟（減法）、完成模型分層 Phase 1 落地、優化 Metrics 分析視窗，鞏固框架持續改善能力。

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-158（Issue #155）：Sprint Review / Planning 流程精簡化 — Token Baseline 與 Beta 檢查降級 | S | 1 | Sprint 60 |
| US-159（Issue #156）：模型分層策略 Phase 1 落地 — SKILL.md + tutorial 新增模型切換提示 | S | 1 | Sprint 60 |
| US-160（Issue #157）：Metrics 計算視窗限制 — 趨勢分析僅讀取最近 30 個 Sprint | S | 1 | Sprint 60 |

---

## Sprint 59（2026-03-08）

**Sprint Goal**：鞏固 M5 穩定化 — 修補已知 plugin 載入問題的框架端文件缺口（TROUBLESHOOTING.md shallow clone 根因文件化）。

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-157（Issue #101）：Plugin 載入失敗 Workaround 正式文件化 — TROUBLESHOOTING.md 新增 shallow clone 根因分析與操作 SOP | S | 1 | Sprint 59 |

## Sprint 63（2026-03-08）

**Sprint Goal**：流程修正與技術債清理 — 修復 Sprint Review Issue 自動關閉問題（#166），評估開源 CLI Adapter 替代方案（#167），清理 50+ Sprint 懸而未決的 Retro Action Items（#168）。

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-168（Issue #166）：Sprint Review Issue 關閉邏輯修正 — 區分內部/外部 Issue 關閉策略 | S | 1 | Sprint 63 |
| US-169（Issue #167）：多模型 CLI 路由 Phase 2 — 開源 Adapter 評估與決策 | S | 1 | Sprint 63 |
| US-170（Issue #168）：Retro Action Items 批次處理 — Sprint 11-12 懸而未決項目清理 | S | 1 | Sprint 63 |

---

## Sprint 64（2026-03-08）

**Sprint Goal**：清空 Backlog，終結所有懸而未決的 Open Issues — 評估並結案或推進 #159、#59、#5、#4。

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-171（Issue #159）：多模型 CLI 路由 Phase 3 方向決策 — Issue #159 結案或規劃後續 | S | 1 | Sprint 64 |
| US-172（Issue #59）：Beta 回饋機制評估與結案 — Issue #59 現狀審查 | S | 1 | Sprint 64 |
| US-173（Issue #5）：Marketplace 上架現狀審查 — Issue #5 結案決策 | S | 1 | Sprint 64 |
| US-174（Issue #4）：Cursor 平台現狀審查 — Issue #4 結案決策 | S | 1 | Sprint 64 |

---

## Sprint 65（2026-03-08）

**Sprint Goal**：Subagent 模型自動調度完善 — 補齊所有 subagent 派遣點的 model 參數標注，建立角色→模型對照表，實現成本分層自動化。

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-175（Issue #169）：Subagent 多模型自動調度 — 角色對照表建立與派遣點 model 參數補齊 | S | 1 | Sprint 65 |

---

## Sprint 66（2026-03-08）

**Sprint Goal**：CLI Adapter Phase 3 SKILL.md 整合 — 建立雙軌派遣機制，讓框架能透過 cli-adapter.sh 派遣 Gemini 執行特定角色任務。

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-176（Issue #170）：CLI Adapter Phase 3 -- SKILL.md 整合與角色→Provider 路由機制 | M | 2 | Sprint 66 |

---

## Sprint 67（2026-03-08）

**Sprint Goal**：簡化多模型派遣架構 — 移除基於錯誤前提設計的 cli-adapter.sh 抽象層，直接利用 Gemini CLI 原生 agent 能力。

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-177（Issue #171）：CLI Adapter 簡化 — 移除不必要的抽象層，直接使用 Gemini CLI 原生 agent 能力 | S | 1 | Sprint 67 |

---

## Sprint 68（2026-03-08）

**Sprint Goal**：KM 減法 — 移除無用的 DORA Metrics + KM 檔案瘦身

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-178（Issue #172）：移除 DORA Metrics — 刪除 sprint-review §2.7 整段、Metrics_Log DORA 區塊、相關 checklist | S | 1 | Sprint 68 |
| US-179（Issue #173）：BACKLOG_DONE.md 歸檔機制 — 主檔只保留最近 5 個 Sprint | S | 1 | Sprint 68 |

---

## Sprint 69（2026-03-08）

**Sprint Goal**：Developer Provider 路由落地 — Gemini CLI 自動 Fallback 派遣機制

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-180（Issue #175）：Developer 角色 Provider 路由 — 支援 Gemini CLI 可切換派遣（環境變數控制） | S | 1 | Sprint 69 |

---

## Sprint 70（2026-03-08）

**Sprint Goal**：Provider 路由品質修正 — 宿主平台自動偵測，消除 Gemini CLI 預設值邏輯矛盾

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-181（Issue #176）：Provider 路由預設值應偵測宿主平台 — 修正寫死 claude 預設值 | S | 1 | Sprint 70 |

---

## Sprint 71（2026-03-10）

**Sprint Goal**：建立 QA 測試覆蓋驗證機制第一層

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-182（Issue #182）：QA 測試覆蓋驗證 — 第一層 Story-level checklist | M | 2 | Sprint 71 |

---

## Sprint 72（2026-03-10）

**Sprint Goal**：框架品質全面強化 — Bug 修復 + 流程補全 + 平行安全防護

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-183（Issue #181）：Bug: dispel skill 設定 disable-model-invocation 導致無法透過 Skill tool 呼叫 | S | 1 | Sprint 72 |
| US-184（Issue #180）：P0: Sprint Execution 缺少修復驗證步驟 | M | 2 | Sprint 72 |
| US-185（Issue #184）：sprint-execution: Story-Lifecycle subagent 預設使用 general-purpose agent type | S | 1 | Sprint 72 |
| US-186（Issue #178）：Developer subagent 缺少 API 契約對齊步驟 | M | 2 | Sprint 72 |
| US-187（Issue #179）：Sprint Review 缺少生產環境部署驗證步驟 | S | 1 | Sprint 72 |
| US-188（Issue #183）：sprint-execution: 平行 subagent 禁止直接修改共用文件 — 主 session 批次更新 | M | 2 | Sprint 72 |
| US-189（Issue #177）：CI/CD 變更強制 QA + SRE 雙審查 Gate | M | 2 | Sprint 72 |
| US-190（Issue #185）：Dispel 及 Sprint Execution 應產出 Mermaid SA 圖表 | L | 3 | Sprint 72 |
| US-191（Issue #4）：支援 Cursor 平台安裝 | L | 3 | Sprint 72 |

---

## Sprint 73（2026-03-11）

**Sprint Goal**：落地延期 2 Sprint 的 Retro Action（PO R1 Sonnet 預設）+ 補強部署驗證模板

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-192（Issue #186）：sprint-planning SKILL.md PO R1 模型改為 Sonnet 預設 | S | 1 | Sprint 73 |
| US-193（Issue #190）：deployment-readiness SKILL.md 新增 L2 API 驗證步驟模板 | M | 2 | Sprint 73 |

---

## Sprint 74（2026-03-11）

**Sprint Goal**：使用者體驗與開發流程雙強化 — README 首印象重塑 + API 契約 Hard Gate 落地 + E2E 測試基礎設施補齊

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-194（Issue #194）：feat: README 資訊架構重設計 — 30 秒內讓人知道怎麼開始用 | M | 2 | Sprint 74 |
| US-195（Issue #191）：feat: API 契約 Hard Gate — 涉及 API 的 Story 無契約不得進入開發 | M | 2 | Sprint 74 |
| US-196（Issue #193）：docs: E2E 測試 Client 端教學手冊 — CDP 穿隧 + 本地瀏覽器連接 SOP | S | 1 | Sprint 74 |
| US-197（Issue #192）：feat: E2E 測試 Server 端模板 — Playwright workflow + CI 登入自動化模板 | L | 3 | Sprint 74 |

---
