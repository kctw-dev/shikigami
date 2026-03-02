# Sprint 16

**狀態**：完成
**Sprint Goal**：清零 Sprint 15 Retro Action Items，完成 US-17 多平台可行性調查，修正文件類 SKILL.md 越權執行風險（Issue #34），更新 sprint-review SKILL.md 覆蓋缺口（Issue #36），導入快思/慢想雙模式精簡化（Issue #39），鞏固 M5 穩定化最後一哩路。
**結果**：Goal 達成（6/6 Stories PASS）。Velocity 8 points，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-03-02 ~ 2026-03-08

---

## Sprint Backlog

| Story ID | 標題 | Size | Points | 狀態 |
|----------|------|------|--------|------|
| Retro #37 | GETTING_STARTED.md 補上 ToC 目錄 | S | 1 | 完成 |
| US-17 | 多平台調查（Cursor / OpenCode / Codex 可行性） | M | 2 | 完成 |
| Issue #34 | sprint-execution SKILL.md 跳過 doc-only Story 執行保護 | S | 1 | 完成 |
| Issue #36 | sprint-review SKILL.md 覆蓋缺口修正 | S | 1 | 完成 |
| Retro #38 | Token JSONL 提取機制調查與 SKILL.md 主要方法更新 | S | 1 | 完成 |
| US-28 | 快思/慢想雙模式 — Sprint Planning & Standup 預設精簡化 | M | 2 | 完成 |

**總計：6 Stories / 8 Points**

---

## Acceptance Criteria

### Retro #37：GETTING_STARTED.md 補上 ToC 目錄

**User Story**
As a developer using the tutorial, I want GETTING_STARTED.md to have a Table of Contents with anchor links for all 7 steps, so that I can quickly navigate to any step without scrolling through the entire document.

**QA 狀態**：PASS（直接進入 Sprint，無需修訂）

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | ToC 結構建立 | `docs/tutorial/GETTING_STARTED.md` 新增目錄區塊（位置：文件標題之後、正文之前）；目錄包含全部 7 個步驟的錨點連結（(1) 前置條件確認、(2) 安裝 Shikigami、(3) 初始化專案、(4) 定義第一個 User Story、(5) 執行 Sprint Planning、(6) 執行 Sprint Execution、(7) 執行 Sprint Review） |
| AC2 | [靜態] | 格式對齊 | ToC 格式（標題層級、錨點語法、縮排）與 `docs/tutorial/TROUBLESHOOTING.md` 的現有目錄格式保持一致 |
| AC3 | [靜態] | 錨點有效性 | ToC 中所有 7 個錨點連結目標（`#heading-text`）在文件中對應的標題實際存在，無斷裂錨點 |

**MoSCoW**：Should / **Size**：S / **Points**：1
**依賴**：無（獨立可執行）
**ADR-003**：不適用（修改 docs/tutorial/ 非 skills/commands/agents/）

---

### US-17：多平台調查（Cursor / OpenCode / Codex 可行性）

**User Story**
As a Product Owner, I want a structured feasibility investigation of running Shikigami on Cursor, OpenCode, and Codex CLI platforms, so that I can make an informed prioritization decision about which platforms to support and in what order.

**QA 狀態**：NEEDS_REVISION（已修訂如下）

**前置條件**：Issues #3、#4 在執行前確認仍為 open 狀態（以確認外部使用者對多平台支援仍有需求）

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | Cursor 可行性分析 | 針對 Cursor 平台，從以下四個維度完成結構化分析並記錄於調查報告中：(a) SKILL.md 載入機制（Cursor 是否支援等效的 CLAUDE.md / instructions file 機制）；(b) Subagent 派遣支援（Cursor 是否支援 Task tool 或等效的子任務並行執行能力）；(c) 權限模型（Cursor 的工具呼叫權限是否支援 bash、file read/write、gh CLI 等 Shikigami 必要操作）；(d) 整合可行性評分（1–5 分，附評分理由） |
| AC2 | [靜態] | OpenCode 可行性分析 | 針對 OpenCode 平台，從相同四個維度完成結構化分析：(a) SKILL.md 載入機制；(b) Subagent 派遣支援；(c) 權限模型；(d) 整合可行性評分（1–5 分，附評分理由） |
| AC3 | [靜態] | Codex CLI 可行性分析 | 針對 Codex CLI 平台，從相同四個維度完成結構化分析：(a) SKILL.md 載入機制；(b) Subagent 派遣支援；(c) 權限模型；(d) 整合可行性評分（1–5 分，附評分理由） |
| AC4 | [靜態] | 後續行動建議 | 調查報告末尾包含「後續行動建議」區塊，至少涵蓋：(a) 三個平台的優先排序（1st / 2nd / 3rd）及排序理由；(b) 最優先平台的已知阻礙事項清單（若無，明確標記「無已知阻礙」）；(c) 下一步具體行動（如「建立 Cursor-specific POC Sprint」或「等待 OpenCode API 穩定後再評估」），需具體可執行而非泛稱「繼續研究」 |
| AC5 | [靜態] | 調查報告建立與 M5 標注 | 建立 `docs/km/MULTI_PLATFORM_SURVEY.md`；文件標頭包含調查日期、執行者（可為 AI Agent）、M5 前置條件確認記錄（Issues #3 #4 open 狀態截圖或文字確認）；ROADMAP.md M5 區塊中 US-17 條目狀態標注為「M5: 調查完成」（格式：在現有 TBD 標記後補充 `（調查完成，Sprint 16）`） |

**RICE 評分**：18.0（Reach 6 × Impact 3 × Confidence 75% ÷ Effort 0.75）
**MoSCoW**：Should / **Size**：M / **Points**：2
**依賴**：Issues #3、#4 仍為 open（前置確認）
**ADR-003**：不適用（建立新文件 docs/km/，不修改 skills/ 下 SKILL.md；ROADMAP.md 更新不屬於 ADR-003 觸發範疇）

---

### Issue #34：sprint-execution SKILL.md 跳過 doc-only Story 執行保護

**User Story**
As a Developer subagent, I want sprint-execution SKILL.md to clearly define that Stories marked as doc-only should skip code execution steps, so that I never accidentally run commands or modify non-documentation files when executing a documentation-only Story.

**QA 狀態**：NEEDS_REVISION（已修訂如下）

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | doc-only 標記定義 | `skills/sprint-execution/SKILL.md` 新增「doc-only Story 識別規則」段落：定義 doc-only Story 為「CLAUDE.md 含 `doc-only: true` 欄位，或 Story AC 所有條目均為 [靜態] 類型，且目標檔案均在 `docs/` 目錄下」 |
| AC2 | [靜態] | 跳過邏輯與判定機制 | `skills/sprint-execution/SKILL.md` 新增執行分支：識別為 doc-only 時，跳過「執行 bash 指令」「修改 src/ 或 skills/ 目錄檔案」等步驟；判定機制由 QA subagent 在 Sprint Planning 時確認，確認標準為「Story 所有 AC 引用路徑均為 .md 副檔名」；負面案例排除清單：以下情況**不適用** doc-only 路徑：(a) AC 含 [動態] 類型且需執行 shell 命令；(b) 目標路徑含 `skills/`、`commands/`、`agents/` 目錄（即使副檔名為 .md，仍需 ADR-003 Checklist） |
| AC3 | [靜態] | 可觀察驗收指標 | 修改後的 `skills/sprint-execution/SKILL.md` 中，doc-only 識別規則段落明確包含：(a) 正向識別條件（文字明確）；(b) 負面案例排除清單（至少 2 個排除情境）；(c) 執行分支說明（doc-only 路徑 vs 一般路徑的差異）；QA 可透過靜態文件審查（讀取 SKILL.md）驗證以上三項均存在 |
| AC4 | [靜態] | ADR-003 Checklist 通過 | 本 Story 修改 `skills/sprint-execution/SKILL.md`，需在 Sprint 執行前確認 ADR-003 Framework Document Change Audit Checklist 通過：(a) 修改目的對應 Sprint Backlog Issue #34；(b) 修改範圍在 AC 所涵蓋文件範圍內；(c) 修改前已讀取目標文件當前版本；(d) 修改後執行 health-check 確認結構完整性；CLAUDE.md 需含 `doc-only: true` 或等效標記以觸發本功能時，Developer 需在修改前確認此前置條件存在 |

**MoSCoW**：Must / **Size**：S / **Points**：1
**依賴**：無（獨立可執行）
**ADR-003**：適用（修改 `skills/sprint-execution/SKILL.md`）

---

### Issue #36：sprint-review SKILL.md 覆蓋缺口修正

**User Story**
As a Scrum Master running sprint review, I want sprint-review SKILL.md to correctly define all required review artifacts and steps without coverage gaps, so that sprint review execution is complete and consistent every Sprint.

**QA 狀態**：PASS（直接進入 Sprint，無需修訂）

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 覆蓋缺口識別 | 讀取 `skills/sprint-review/SKILL.md` 當前版本，逐節比對：Sprint Review 應產出的工件清單（Retrospective_Log 更新、Metrics_Log 更新、PROJECT_BOARD 更新、sprint_N.md 狀態回寫、ROADMAP 更新）是否在 SKILL.md 各步驟中均有對應指引；發現缺口或描述不一致處列出清單 |
| AC2 | [靜態] | 缺口補全 | 針對 AC1 識別的每個缺口，在 `skills/sprint-review/SKILL.md` 對應節次補入完整指引（包含：操作步驟、目標檔案路徑、必要輸出格式）；若無缺口，輸出「覆蓋完整，無需修改」並記錄於 `docs/sprints/sprint_16.md` Story 備注欄 |
| AC3 | [靜態] | ADR-003 Checklist 通過 | 本 Story 修改 `skills/sprint-review/SKILL.md`，需在 Sprint 執行前確認 ADR-003 Framework Document Change Audit Checklist 通過（同 Issue #34 AC4 之四項條件） |

**MoSCoW**：Must / **Size**：S / **Points**：1
**依賴**：無（獨立可執行）
**ADR-003**：適用（修改 `skills/sprint-review/SKILL.md`）

---

### Retro #38：Token JSONL 提取機制調查與 SKILL.md 主要方法更新

**User Story**
As an Architect, I want to investigate the current session JSONL format for token extraction and update the three SKILL.md token recording guidelines accordingly, so that Sprint token cost tracking can resume with accurate data instead of perpetual N/A entries.

**QA 狀態**：NEEDS_REVISION（已修訂如下）

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [動態] | JSONL 路徑與格式調查 | 執行以下調查步驟並記錄結果：(a) 執行 `ls ~/.claude/projects/` 列出當前所有 project 目錄；(b) 嘗試讀取最新 JSONL 檔案的 `message.usage` 欄位，記錄操作是否成功及原因；(c) 依結果判定分支：若可存取（分支 A），記錄 JSONL 路徑格式及 `message.usage` 欄位結構；若不可存取（分支 B），記錄具體失敗原因（權限、路徑不存在、欄位不存在等） |
| AC2 | [靜態] | 分支對應的 SKILL.md 更新規格 | 依 AC1 結果執行對應更新：**分支 A（可存取）**：確認三個 SKILL.md（`skills/sprint-planning/SKILL.md`、`skills/sprint-execution/SKILL.md`、`skills/sprint-review/SKILL.md`）的主要方法描述是否與實際可存取的 JSONL 路徑及 `message.usage` 欄位結構一致；若一致，標記「無需更新」並附確認記錄；若不一致，更新三個 SKILL.md 的 token 提取指引至正確路徑與欄位名稱。**分支 B（不可存取）**：將三個 SKILL.md 的主要方法描述改寫為「降級方法」，說明以下替代記錄方式：(i) 從 Claude Code UI 手動讀取 session token 用量；(ii) 依 `Metrics_Log.md` 手動記錄模板填入；移除誤導性的 JSONL 路徑指引 |
| AC3 | [靜態] | Metrics_Log.md 調查記錄 | 在 `docs/km/Metrics_Log.md` 底部追加 `## Token JSONL 調查記錄` 區塊，包含：(a) 調查日期；(b) 執行者（可為 AI Agent）；(c) 調查步驟結果（AC1 的操作記錄）；(d) 結論（分支 A：可提取，含路徑格式；或分支 B：不可提取，含失敗原因）；(e) 對應採用的 SKILL.md 更新策略（分支 A 一致確認 / 分支 A 路徑修正 / 分支 B 降級方法） |
| AC4 | [靜態] | ADR-003 Checklist（若分支 A 不一致或分支 B） | 若 AC2 執行結果需修改任一 SKILL.md，須在修改前確認 ADR-003 Checklist 通過；若結論為「分支 A 一致，無需更新」，ADR-003 Checklist 不適用，記錄豁免理由 |

**MoSCoW**：Should / **Size**：S / **Points**：1
**依賴**：無（獨立可執行）
**ADR-003**：條件適用（依調查結果決定是否修改 SKILL.md；分支 A 一致時不適用）

---

### US-28（Issue #39）：快思/慢想雙模式 — Sprint Planning & Standup 預設精簡化

**User Story**
As a framework user, I want Sprint Planning and Daily Standup to default to a streamlined "fast thinking" mode that skips non-essential diagnostics, so that daily iteration is faster and less token-intensive, while retaining a "deep" mode for thorough checks when needed.

**QA 狀態**：待 QA 審查

**背景**：Issue #39 提出日常 Planning/Standup 每次跑完整健康檢查 + Token 測量 + 權重調整過於繁重。引入快思（預設）/慢想（`--deep`）雙模式，快思跳過非核心步驟直接進入選 Stories 流程。

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | sprint-planning SKILL.md 快思模式定義 | `skills/sprint-planning/SKILL.md` 新增「快思/慢想模式」區塊：(a) 快思模式（預設）跳過完整健康檢查、Token 消耗測量、角色權重調整檢查，直接進入 PO 選 Stories → Architect 評估 → QA 驗收 → 建立 Sprint 文件；(b) 慢想模式（`--deep`）維持現有完整流程；(c) 模式選擇邏輯明確標注於 §2 流程 Checklist 開頭 |
| AC2 | [靜態] | standup command 快思模式定義 | `commands/standup.md` 新增快思/慢想分支：(a) 快思模式（預設）精簡為 Git 同步 + Sprint 進度，跳過 Issues 深度掃描與完整健康檢查；(b) 慢想模式（`--deep`）維持現有完整流程 |
| AC3 | [靜態] | 模式觸發方式文件化 | sprint-planning SKILL.md 與 commands/standup.md 均明確記載觸發方式：預設為快思，使用者傳入 `--deep` 參數或說「完整檢查」時切換至慢想模式 |
| AC4 | [靜態] | ADR-003 Checklist 通過 | 修改 `skills/sprint-planning/SKILL.md` 與 `commands/standup.md`，需在執行前確認 ADR-003 Checklist 四項條件全部通過 |

**MoSCoW**：Should / **Size**：M / **Points**：2
**依賴**：無（獨立可執行，但建議在 Issue #34 之後執行以避免 SKILL.md 衝突）
**ADR-003**：適用（修改 `skills/sprint-planning/SKILL.md` + `commands/standup.md`）

---

## 權重調整記錄

- **觸發歷史**：Sprint 14 Problem 含 QA 相關關鍵字（「QA Code Quality Review 發現 Retro #26 硬編碼版本號」）；Sprint 15 Problem 含 QA 相關關鍵字（「Code Quality Review 發現 2 個 Important 問題未於本 Sprint 修復」）→ 連續 2 個 Sprint 出現 QA 相關 Problem，觸發升級門檻
- **調整項目**：QA Review 升為 Hard Gate（Must），Bypass 不適用 QA 相關審查
- **生效 Sprint**：Sprint 16（生效）
- **降級條件**：需連續 2 個 Sprint 無 QA 相關 Problem，方可於第三個 Sprint 降級

---

## 平行分群策略

（Architect Sprint 16 Planning 建議）

### Phase 1（可平行）

| Story ID | 修改目標 | 說明 |
|----------|---------|------|
| Retro #37 | `docs/tutorial/GETTING_STARTED.md` | 補 ToC，不影響其他檔案 |
| US-17 | `docs/km/MULTI_PLATFORM_SURVEY.md`（新建）+ `docs/prd/ROADMAP.md`（標注） | 建立調查報告，與其他工作無衝突 |

**平行化理由**：Retro #37 修改 docs/tutorial/，US-17 建立新文件 docs/km/ 並標注 ROADMAP.md，兩者目標檔案完全不重疊，可完全平行執行。

### Phase 2（序列）

| 步驟 | Story ID | 修改目標 | 說明 |
|------|----------|---------|------|
| 2-1 | Issue #34 | `skills/sprint-execution/SKILL.md` | ADR-003 適用，需序列處理 |
| 2-2 | Issue #36 | `skills/sprint-review/SKILL.md` | ADR-003 適用，依賴 #34 完成後確認 ADR-003 流程無障礙 |
| 2-3 | Retro #38 | 三個 SKILL.md（條件適用）+ `docs/km/Metrics_Log.md` | 依賴 Issue #34/#36 完成後執行（避免 SKILL.md 同時修改衝突） |
| 2-4 | US-28 | `skills/sprint-planning/SKILL.md` + `commands/standup.md` | 依賴 Retro #38 完成後執行（sprint-planning SKILL.md 可能被 Retro #38 修改） |

**序列理由**：Issue #34 修改 sprint-execution SKILL.md，Retro #38 的分支 B 也可能修改三個 SKILL.md（含 sprint-execution）；Issue #36 修改 sprint-review SKILL.md，Retro #38 亦可能修改同一檔案；US-28 修改 sprint-planning SKILL.md，Retro #38 亦可能修改同一檔案。為避免合併衝突，Phase 2 採序列執行。

---

## 工作容量

| 指標 | 數值 |
|------|------|
| 計畫 Stories | 6 |
| 計畫 Points | 8（4S + 2M = 1+2+1+1+1+2） |
| 近 3 Sprint 平均 Velocity | 3.3pt（Sprint 13: 4、Sprint 14: 2、Sprint 15: 4） |
| Sprint 15 Velocity | 4pt |
| 緩衝率 | 242%（高於歷史平均，但 6 個 Story 均為 QA Hard Gate 通過或待審查，含 2 個 PASS + 3 個 NEEDS_REVISION 已修訂 + 1 個新增） |

**容量決策說明**：
Sprint 16 選入 6 Stories（8 points），高於近 3 Sprint 平均 Velocity（3.3pt）。選入理由：
1. QA Hard Gate 已通過（2 個 PASS，3 個 NEEDS_REVISION 已由 PO Round 2 修訂 AC，1 個新增待 QA 審查）
2. 6 個 Story 均為 S 或 M size，無 L 或 XL 高風險 Story
3. Retro #37（S/1pt）為純文件補充，風險極低
4. Issue #34/#36 為 ADR-003 觸發 Story，但均為 S size，執行風險可控
5. Retro #38 調查型 Story，結論為分支 A 無需修改時可快速完成
6. US-17 為調查型 Story，不涉及框架文件修改，ADR-003 不適用
7. US-28（Issue #39）為流程精簡化 Story，修改範圍明確（sprint-planning SKILL.md + standup.md），M size 合理

---

## ADR-003 觸發清單

| Story | 觸發原因 | 適用狀態 |
|-------|---------|---------|
| Retro #38 | 分支 B 或分支 A 不一致時修改三個 SKILL.md（sprint-planning / sprint-execution / sprint-review） | 條件適用（視調查結果） |
| Issue #36 | 修改 `skills/sprint-review/SKILL.md` | 適用 |
| Issue #34 | 修改 `skills/sprint-execution/SKILL.md` | 適用 |
| Retro #37 | 修改 `docs/tutorial/GETTING_STARTED.md`（非 skills/commands/agents/） | 不適用 |
| US-17 | 建立 `docs/km/MULTI_PLATFORM_SURVEY.md`、標注 ROADMAP.md（非 skills/ 下 .md） | 不適用 |
| US-28 | 修改 `skills/sprint-planning/SKILL.md` + `commands/standup.md` | 適用 |

---

## Token 記錄

| 環節 | Token | 備註 |
|------|-------|------|
| Planning | 待補 | Sprint 16 Planning 完成後從 JSONL 提取（或依 Retro #38 調查結論決定提取方式） |
| Execution | 待補 | Sprint 16 Execution 完成後填入 |
| Review | 待補 | Sprint 16 Review 完成後填入 |
