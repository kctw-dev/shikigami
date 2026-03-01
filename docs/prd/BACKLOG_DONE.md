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
