# Product Backlog

**最後更新**：2026-03-01（Sprint 9 Planning 完成）
**管理者**：Product Owner

---

## 待選 Stories

### Issue #9 / #12 — Backlog Bridge 新增 Stories（2026-03-01）

| 排序 | Story | RICE | MoSCoW | Size | 來源 | 狀態 |
|------|-------|------|--------|------|------|------|
| 1 | US-21：真實制衡案例文件 | 25.3 | Should | S | Issue #12-3 | Done (Sprint 8) |
| 2 | US-18：Sprint Execution Issue 回覆自動化 | 23.8 | Should | M | Issue #9 | Done (Sprint 8) |
| 3 | US-20：輕量 Bypass 機制 | 20.25 | Should | M | Issue #12-2 | Done (Sprint 8) |
| 4 | US-19：Token 成本透明化 | 11.2 | Must | M | Issue #12-1 | In Sprint 9 |
| 5 | US-22：Retrospective 驅動角色權重自動調整 | 6.6 | Could | L | Issue #12-4 | 待選 |

### v0.3.0 知識沉澱 — 候選 Stories

（US-09、US-10 已完成；US-11 待排入）

### 測試框架 — 候選 Stories

| 排序 | Story | RICE | MoSCoW | Size | ADR | 狀態 |
|------|-------|------|--------|------|-----|------|
| 1 | US-T05：交叉引用驗證 | 25.6 | Should | S | — | Done (Sprint 7) |
| 2 | US-T07：CI Pipeline | 24.0 | Should | M | — | Done (Sprint 7) |
| 3 | US-T09：孤兒文件清理規範 | 16.7 | Could | M | — | In Sprint 9 |
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
