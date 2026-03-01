# Product Backlog

**最後更新**：2026-03-01（Sprint 11 Review — US-25、US-S02 完成歸檔）
**管理者**：Product Owner

---

## 待選 Stories

### Issue #9 / #12 — Backlog Bridge 新增 Stories（2026-03-01）

| 排序 | Story | RICE | MoSCoW | Size | 來源 | 狀態 |
|------|-------|------|--------|------|------|------|
| 1 | US-21：真實制衡案例文件 | 25.3 | Should | S | Issue #12-3 | Done (Sprint 8) |
| 2 | US-18：Sprint Execution Issue 回覆自動化 | 23.8 | Should | M | Issue #9 | Done (Sprint 8) |
| 3 | US-20：輕量 Bypass 機制 | 20.25 | Should | M | Issue #12-2 | Done (Sprint 8) |
| 4 | US-19：Token 成本透明化 | 11.2 | Must | M | Issue #12-1 | Done (Sprint 9) |
| 5 | US-22：Retrospective 驅動角色權重自動調整 | 6.6 | Could | L | Issue #12-4 | Done (Sprint 10) |
| 6 | US-23：Token 成本分環節記錄 | 33.6 | Must | M | Retro #18 | Done (Sprint 10) |

### Sprint 10 後 — 新增 Stories

| 排序 | Story | RICE | MoSCoW | Size | 來源 | 狀態 |
|------|-------|------|--------|------|------|------|
| 1 | US-25：Scrum Master 零讀取架構（主 session context 瘦身） | 45.0 | Must | M | Issue #12 | Done (Sprint 11) |
| 2 | US-24：Subagent Token 成本優化（成本 + 速度） | 36.0 | Should | L | Sprint 10 Retro | 待選 |
| 3 | Retro #20：SKILL.md token 記錄指引更新為 JSONL 提取 | — | Must | S | Sprint 10 Retro | Done (Sprint 11) |
| 4 | US-S02：Standup 健康快篩框架 Repo 誤判修正 | 18.0 | Should | S | Standup 回饋 | Done (Sprint 11) |

---

### US-25：Scrum Master 零讀取架構（主 session context 瘦身）

**標題**：主 session 不直接讀取大檔案，全部委託 Subagent 處理並回傳摘要

**User Story**
As a framework user, I want the Scrum Master (main session) to never read large files directly but instead delegate all file reading to subagents who return concise summaries, so that the main session's context stays lean and each API call's cache read overhead is minimized.

**背景**
Sprint 10 實測：957 API calls、104M cache read tokens。根因是主 session 直接讀取 PRODUCT_BACKLOG.md（355 行）、ROADMAP.md、PROJECT_BOARD.md 等大檔案，內容進入對話歷史後每次 API call 都重傳。Subagent 本身已有獨立乾淨 context，但主 session 作為 orchestrator 卻累積了所有讀取結果。解法：Scrum Master 改為「純調度者」，所有檔案讀取由 subagent 執行，主 session 僅接收結構化摘要（一句話級別）。

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | sprint-planning 零讀取 | `skills/sprint-planning/SKILL.md` 修改 Scrum Master 調度指引：主 session 不使用 Read tool 讀取 PRODUCT_BACKLOG、ROADMAP、PROJECT_BOARD 等檔案；改為在 subagent prompt 中指定檔案路徑，由 subagent 自行讀取並回傳結構化摘要（Story 清單 + 估點 + AC 確認結果） |
| AC2 | [靜態] | sprint-execution 零讀取 | `skills/sprint-execution/SKILL.md` 修改：Developer / QA / Security subagent 的派遣 prompt 指定需讀取的檔案路徑，主 session 不預讀 Story 內容；subagent 回傳格式限定為狀態 + 結論（PASS/FAIL + 一句話摘要） |
| AC3 | [靜態] | sprint-review 零讀取 | `skills/sprint-review/SKILL.md` 修改：Retro Analytics、PO Demo、Stakeholder 確認等步驟均由 subagent 讀取所需檔案；主 session 不直接讀取 Retrospective_Log、Metrics_Log、sprint_N.md |
| AC4 | [動態] | context 瘦身驗證 | 下一個 Sprint 的主 session cache read tokens 較 Sprint 10（104M）下降 60% 以上 |

**RICE 評分**

| 維度 | 分數 |
|------|------|
| Reach | 10 |
| Impact | 3 |
| Confidence | 75% |
| Effort | 0.5 人週 |
| **RICE Score** | **45.0** |

**MoSCoW**：Must
**Size**：M / **Points**：2
**對應 Issue**：#12（狀態外化架構）
**設計原則**：SM 只需知道做決策的最小資訊。所有資料的讀取、過濾、摘要都是 Subagent 的職責，SM 不碰原始資料。
**備注**：與 US-24 AC1（檔案傳遞模式）有重疊。US-25 聚焦「主 session 不讀檔」的架構改變；US-24 的 AC2（模型分級）暫緩、AC3/AC4（call 數量與成本驗證）可作為 US-25 的後續驗證指標。需 ADR-003 Checklist（修改 3 個 SKILL.md）。

---

### US-24：Subagent Token 成本優化（成本 + 速度）

**標題**：降低 Subagent 派遣的 Token 消耗與回應延遲

**User Story**
As a framework user paying per-token API costs, I want the Subagent dispatch pattern to minimize token exchange overhead, so that running a full Sprint cycle is affordable (target: <$50/Sprint on API pricing) and fast.

**背景**
Sprint 10 實測數據：108M tokens / $234 / 957 API calls。Planning 佔 81%（87M），根因是每次 subagent 派遣都帶入完整 context（104M cache read tokens）。對 API 付費使用者而言，每月 4 Sprint ≈ $1000，構成採用門檻。

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 檔案傳遞模式 | sprint-planning SKILL.md subagent 派遣改為「指令 + 檔案路徑」模式：主 agent 不預讀檔案內容塞入 prompt，subagent 自行讀檔。中間結果寫入 `docs/sprints/sprint_N.md`，下一個 subagent 從檔案讀取 |
| AC2 | [靜態] | 輕量模型指定 | QA Review（Spec Compliance + Code Quality）、PO Issue Triage、Architect Size 估算等例行任務的 subagent 指定使用 haiku 模型，僅在需要深度推理時使用 opus/sonnet |
| AC3 | [動態] | API call 數量下降 | Sprint Planning 的 API call 數量從 ~800 降至 <200（透過合併步驟、減少來回） |
| AC4 | [動態] | 成本下降驗證 | 下一個 Sprint 的 token 總量較 Sprint 10 下降 50% 以上，或估算成本 <$120 |

**RICE 評分**

| 維度 | 分數 |
|------|------|
| Reach | 9 |
| Impact | 3 |
| Confidence | 60% |
| Effort | 2.0 人週 |
| **RICE Score** | **36.0** |

**MoSCoW**：Should
**Size**：L / **Points**：3
**備注**：AC2 的模型指定可能需要 ADR（是否屬於技術選型），Sprint Planning 時由 Architect 判斷

---

### US-S02：Standup 健康快篩框架 Repo 誤判修正

**標題**：健康快篩在框架 Repo 本身執行時跳過 CLAUDE.md 檢查

**User Story**
As a framework developer working in the shikigami repo itself, I want the standup health check to recognize it's running in the framework repo (not a consumer project) and skip the CLAUDE.md existence check, so that I don't get false positive CRITICAL alerts every standup.

**背景**
`CLAUDE.md` 是 `/onboarding` 為消費端專案產生的設定檔。shikigami 框架 repo 本身不需要此檔案，但 standup 健康快篩一律檢查導致每次報告 CRITICAL，掩蓋真正的健康問題。偵測方式：`plugin.json` 存在 → 框架 repo → 跳過 CLAUDE.md 檢查。

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 框架 Repo 偵測 | `commands/standup.md`「區塊零：健康快篩」的「檢查 1」新增前置判斷：若 `./.claude-plugin/plugin.json` 存在且非空，跳過 `CLAUDE.md` 檢查，標記為 PASS 並附加「（框架 Repo，CLAUDE.md 檢查略過）」 |
| AC2 | [動態] | 消費端不受影響 | 在無 `plugin.json` 的專案中執行 standup，CLAUDE.md 缺失時仍出現 CRITICAL |
| AC3 | [動態] | 框架端正向驗證 | 在含 `plugin.json` 且缺少 `CLAUDE.md` 的 repo 中執行 standup，輸出不含「CLAUDE.md 缺失」，快篩為 HEALTHY（若無其他 FAIL） |

**RICE 評分**

| 維度 | 分數 |
|------|------|
| Reach | 5 |
| Impact | 1 |
| Confidence | 90% |
| Effort | 0.25 人週 |
| **RICE Score** | **18.0** |

**MoSCoW**：Should
**Size**：S / **Points**：1
**來源**：Standup 回饋（2026-03-01）

---

### v0.3.0 知識沉澱 — 候選 Stories

（US-09、US-10 已完成；US-11 待排入）

### 測試框架 — 候選 Stories

| 排序 | Story | RICE | MoSCoW | Size | ADR | 狀態 |
|------|-------|------|--------|------|-----|------|
| 1 | US-T05：交叉引用驗證 | 25.6 | Should | S | — | Done (Sprint 7) |
| 2 | US-T07：CI Pipeline | 24.0 | Should | M | — | Done (Sprint 7) |
| 3 | US-T09：孤兒文件清理規範 | 16.7 | Could | M | — | Done (Sprint 9) |
| 4 | US-T08：Intent Routing 測試 | 6.0 | Could | L | — | 待選 |

---

### US-18：Sprint Execution Issue 回覆自動化

**標題**：Sprint Execution 每個 Story 開始前自動掃描並回覆 Open Issues

**User Story**
As a Product Owner, I want open GitHub issues to be automatically scanned and acknowledged at the start of each story in sprint execution, so that external collaborators receive timely responses and their feedback is not silently ignored between Sprint Planning sessions.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 流程整合 | `skills/sprint-execution/SKILL.md` 第 3 節流程圖在「取出 Story」步驟前新增「Issue 快掃」子步驟 |
| AC2 | [動態] | 掃描執行 | 執行 `gh issue list --state open --limit 10`；失敗（gh 未認證/離線）→ 靜默略過，不阻塞 Story 執行 |
| AC3 | [動態] | 回覆觸發條件 | 距上次回覆超過 24 小時且無 `in-backlog` label 的 issue，由 PO subagent 生成確認收到回覆草稿；QA subagent 審核後依專案等級發布 |
| AC4 | [動態] | 不重複打擾 | 已有 `in-backlog`、`in-progress`、`closed` 狀態的 issue 不觸發回覆；同一 issue 同一 Sprint 內只回覆一次 |

**RICE 評分**

| 維度 | 分數 |
|------|------|
| Reach | 7 |
| Impact | 2 |
| Confidence | 85% |
| Effort | 0.5 人週 |
| **RICE Score** | **23.8** |

**MoSCoW**：Should
**Size**：S
**對應 Issue**：#9

---

### US-19：Token 成本透明化

**標題**：Sprint Review 自動輸出 Token 消耗與成本對照表

**User Story**
As a Product Owner, I want token consumption recorded and displayed at each Sprint Review, so that I can understand the AI infrastructure cost of operating this framework and make informed decisions about sprint scope and automation depth.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 記錄格式 | 在 `docs/km/Metrics_Log.md` 定義 Token 消耗記錄欄位：Sprint 編號、輸入 token、輸出 token、估算成本（USD）、資料來源 |
| AC2 | [動態] | Sprint Review 整合 | `skills/sprint-review/SKILL.md` 第 6 節新增 Token 成本摘要區塊；資料不可得時輸出「Token 資料不可用，需手動補充」 |
| AC3 | [動態] | 成本對照 | 累積 2+ Sprint 後，Sprint Review 報告顯示每個 Story 的平均 token 消耗，標記離群值（超過平均 2 倍）|
| AC4 | [靜態] | 手動降級 | 若 Claude Code 無法自動取得 token 用量，提供手動記錄模板（Markdown 表格格式），不強制自動化 |

**RICE 評分**

| 維度 | 分數 |
|------|------|
| Reach | 8 |
| Impact | 2 |
| Confidence | 70% |
| Effort | 1.0 人週 |
| **RICE Score** | **11.2** |

**MoSCoW**：Could
**Size**：M
**對應 Issue**：#12（建議 1）

---

### US-20：輕量 Bypass 機制

**標題**：低複雜度任務自動跳過 Scrum 儀式，直接執行

**User Story**
As a Scrum Master, I want a lightweight bypass mode for simple, well-defined tasks, so that the framework does not impose full Scrum ceremony overhead when the task complexity clearly does not warrant it, allowing faster iteration on routine work.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | Bypass 觸發條件 | `skills/scrum-master/SKILL.md` 定義 Bypass 觸發條件：(a) Story Size = S 且無依賴 ADR；(b) 使用者明確標注 `[QUICK]`；(c) Retro Action Item 類任務（非 Backlog Story） |
| AC2 | [靜態] | Bypass 流程定義 | Bypass 模式跳過：Architect T-shirt 估點、QA AC 審查、雙階段 QA Review；保留：DoD 自檢（功能層）、Commit、PROJECT_BOARD 更新 |
| AC3 | [動態] | 不可 Bypass 的保護項目 | 涉及 Framework Document Change、外部 API、安全相關的任務，即使標注 `[QUICK]` 仍強制走完整流程，Scrum Master 輸出明確拒絕理由 |
| AC4 | [靜態] | 稽核追蹤 | Bypass 執行後在 `docs/sprints/sprint_N.md` 的 Story 行標注 `[BYPASS]`，每 Sprint 累積 Bypass 次數不超過 Sprint 總 Story 數的 40% |

**RICE 評分**

| 維度 | 分數 |
|------|------|
| Reach | 9 |
| Impact | 3 |
| Confidence | 75% |
| Effort | 1.0 人週 |
| **RICE Score** | **20.25** |

**MoSCoW**：Should
**Size**：M
**對應 Issue**：#12（建議 2）

---

### US-21：真實制衡案例文件

**標題**：在 docs/ 收錄真實的角色制衡案例（QA 推翻 Architect、PO 退回 Story 等）

**User Story**
As a new user, I want to read documented real-world examples of role-based checks and balances within Shikigami, so that I can understand how the framework prevents groupthink and trust that the multi-agent governance model delivers meaningful quality gates rather than ceremonial overhead.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 文件建立 | 新建 `docs/km/ROLE_BALANCE_CASES.md`；包含至少 4 個案例，每個案例含：Sprint 來源、情境描述、制衡角色、決策結果、後續影響 |
| AC2 | [靜態] | 案例類型覆蓋 | 4 個案例需覆蓋至少 3 種不同制衡類型：QA 推翻設計、PO 退回 Story、Architect 上調估點、Security 阻擋合併 |
| AC3 | [靜態] | README / Onboarding 引用 | `README.md` 或 `skills/onboarding/SKILL.md` 新增「角色制衡案例」參考連結，讓新使用者能發現此文件 |
| AC4 | [靜態] | 每 Sprint 更新機制 | `skills/sprint-review/SKILL.md` 第 7 節（或新增節次）加入「是否有新制衡案例值得記錄？」提示，維持文件持續更新 |

**RICE 評分**

| 維度 | 分數 |
|------|------|
| Reach | 8 |
| Impact | 1 |
| Confidence | 95% |
| Effort | 0.3 人週 |
| **RICE Score** | **25.3** |

**MoSCoW**：Should
**Size**：S
**對應 Issue**：#12（建議 3）

---

### US-22：Retrospective 驅動角色權重自動調整

**標題**：Sprint Planning 自動讀取 Retro 趨勢，調整角色介入深度

**User Story**
As a Scrum Master, I want Sprint Planning to automatically read Retrospective trends and adjust the depth of each role's involvement for the upcoming sprint, so that the framework learns from past problems rather than applying the same fixed ceremony depth regardless of team history.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 觸發時機 | `skills/sprint-planning/SKILL.md` 在 PO 第一輪步驟前，新增「讀取 Retrospective 趨勢」步驟，呼叫 US-09 產出的 Retrospective Analytics 報告 |
| AC2 | [動態] | 權重調整規則 | 根據 Retro 趨勢自動調整：連續 2 Sprint 出現 QA 相關 Problem → QA Review 從 Should 升為 Must + 雙輪；連續 2 Sprint 無任何 Problem → Bypass 門檻從 S 放寬至 M |
| AC3 | [動態] | 調整透明化 | Sprint Planning 輸出「本次調整項目」清單，說明調整依據（引用具體 Retro Sprint 編號）；若未發生調整，輸出「歷史趨勢穩定，無需調整」 |
| AC4 | [靜態] | 資料不足降級 | Retrospective_Log.md 少於 3 個 Sprint 記錄時，略過調整步驟，輸出「歷史資料不足 3 個 Sprint，跳過權重調整」 |

**RICE 評分**

| 維度 | 分數 |
|------|------|
| Reach | 8 |
| Impact | 3 |
| Confidence | 55% |
| Effort | 2.0 人週 |
| **RICE Score** | **6.6** |

**MoSCoW**：Could
**Size**：L
**對應 Issue**：#12（建議 4）
**備注**：US-09 Retrospective Analytics（已完成）實現展示歷史趨勢；本 Story 進一步將趨勢轉化為 Sprint Planning 的自動決策輸入，屬新增能力而非重複。
**狀態**：Done (Sprint 10)

---

### US-23：Token 成本分環節記錄

**標題**：Sprint 各環節（Planning / Execution / Review）Token 消耗獨立記錄與佔比分析

**User Story**
As a Product Owner, I want token consumption broken down by sprint phase (Planning, Execution, Review) and recorded in Metrics_Log.md, so that I can understand which phases consume the most resources and make data-driven decisions about where to optimize or reduce ceremony depth.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 分環節表格格式 | 在 `docs/km/Metrics_Log.md` 現有 Token 成本記錄表格之後，新建獨立 H2 區塊「## Token 成本分環節記錄」。表格欄位：Sprint 編號、Planning token、Execution token、Review token、合計 token、各環節佔比。「各環節佔比」計算基準：本環節 token ÷ 三環節 token 總和（Planning + Execution + Review）。不修改現有 Token 成本記錄表格 |
| AC2 | [靜態] | sprint-planning 整合 | `skills/sprint-planning/SKILL.md` 新增指引：Sprint Planning 結束時，記錄本次 Planning 環節的 token 消耗至分環節表格對應列（Planning token 欄）；不修改現有 Token 成本摘要指引的任何內容 |
| AC3 | [靜態] | 示範資料 | 分環節表格含至少一列示範資料；數值採 K 格式（如 `12K`）；各環節佔比三欄加總等於 100% |
| AC4 | [動態] | 降級處理 | 當 token 數據不可得時，分環節表格各 token 欄填「N/A」，佔比欄填「N/A」；在 sprint-planning SKILL.md 對應位置輸出精確字串「Token 資料不可用，需手動補充」 |
| AC5 | [靜態] | ADR-003 Checklist | 本 Story 修改 `skills/sprint-planning/SKILL.md`，需在 Sprint 執行前確認 ADR-003 Framework Document Change Audit Checklist 通過 |

**RICE 評分**

| 維度 | 分數 |
|------|------|
| Reach | 8 |
| Impact | 3 |
| Confidence | 70% |
| Effort | 0.5 人週 |
| **RICE Score** | **33.6** |

**MoSCoW**：Must
**Size**：M / **Points**：2
**對應 Retro Action**：#18（Sprint 9，合併執行）
**狀態**：Done (Sprint 10)

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
