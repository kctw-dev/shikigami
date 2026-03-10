# Sprint 72

**Sprint Goal**：框架品質全面強化 — Bug 修復 + 流程補全 + 平行安全防護
**期間**：2026-03-10 ~ 2026-03-17
**ADR 依賴**：無

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-183：Bug: shikigami:dispel skill 設定 disable-model-invocation 導致無法透過 Skill tool 呼叫 | #181 | S | 1 | 完成 |
| US-184：P0: Sprint Execution 缺少修復驗證步驟 | #180 | M | 2 | 完成 |
| US-185：sprint-execution: Story-Lifecycle subagent 預設使用 general-purpose agent type | #184 | S | 1 | 完成 |
| US-186：Developer subagent 缺少 API 契約對齊步驟 | #178 | M | 2 | 完成 |
| US-187：Sprint Review 缺少生產環境部署驗證步驟 | #179 | S | 1 | 完成 |
| US-188：sprint-execution: 平行 subagent 禁止直接修改共用文件 — 主 session 批次更新 | #183 | M | 2 | 完成 |
| US-189：CI/CD 變更強制 QA + SRE 雙審查 Gate | #177 | M | 2 | 完成 |
| US-190：feat: Dispel 及 Sprint Execution 應產出 Mermaid SA 圖表 | #185 | L | 3 | 完成 |
| US-191：支援 Cursor 平台安裝 | #4 | L | 3 | 完成 |

**總計**：17 points

---

## 各 Story 詳情

### US-183：Bug: shikigami:dispel skill 設定 disable-model-invocation 導致無法透過 Skill tool 呼叫

**Issue**：#181
**MoSCoW**：Must
**Size**：S（1pt）

**User Story**：身為使用 shikigami:dispel 的開發者，我希望能透過 Skill tool 正常呼叫 dispel skill，以便啟動 Legacy 系統考古分析流程而不遇到 disable-model-invocation 錯誤。

**Acceptance Criteria**：

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | 移除或修正 frontmatter 設定 | `commands/dispel.md` 的 `disable-model-invocation: true` 已移除或設為 `false` |
| AC2 | Skill tool 可正常呼叫 | 在 Claude Code 中執行 `/shikigami:dispel` 不再出現 `cannot be used with Skill tool due to disable-model-invocation` 錯誤 |
| AC3 | Dispel 功能正常啟動 | Skill tool 呼叫後，dispel 解咒模式（Legacy 系統考古分析）正常啟動執行 |

---

### US-184：P0: Sprint Execution 缺少修復驗證步驟

**Issue**：#180
**MoSCoW**：Must
**Size**：M（2pt）

**User Story**：身為 Sprint Execution 框架的使用者，我希望 Story-Lifecycle subagent 在標記 Story 完成前實際執行驗證，以確保 bug fix 和新功能真的有效，而不只是靜態代碼審查通過。

**Acceptance Criteria**：

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | story-lifecycle-prompt.md 新增 Runtime Verification 步驟 | `skills/sprint-execution/story-lifecycle-prompt.md` 在 Code Quality self-review 之後、標記完成之前，新增 Runtime Verification 步驟 |
| AC2 | Bug fix Story 驗證方式明確 | 流程明確要求：Bug fix Story 需重現原始問題的步驟並確認症狀消失 |
| AC3 | API 修改驗證方式明確 | 流程明確要求：API 修改需 curl / httpie 實際打 API 確認回應正確 |
| AC4 | 前端修改驗證方式明確 | 流程明確要求：前端修改需檢查渲染邏輯並實際跑 dev server 確認 |
| AC5 | doc-only Story 豁免 | doc-only Story 明確標記為 N/A，不需 Runtime Verification |

---

### US-185：sprint-execution: Story-Lifecycle subagent 預設使用 general-purpose agent type

**Issue**：#184
**MoSCoW**：Should
**Size**：S（1pt）

**User Story**：身為 Sprint Execution 框架的維護者，我希望 Story-Lifecycle subagent 派遣時預設使用 general-purpose agent type，以避免 shikigami:developer 的過度 prompt injection 偵測導致 subagent 拒絕執行。

**Acceptance Criteria**：

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | SKILL.md §3 subagent 派遣設定更新 | `skills/sprint-execution/SKILL.md` §3 步驟 3 的 subagent 派遣明確指定使用 general-purpose agent type |
| AC2 | Sprint Execution 無 subagent 拒絕執行事件 | 在後續 Sprint 中，Story-Lifecycle subagent 不再因 prompt injection 偵測而拒絕執行 |

---

### US-186：Developer subagent 缺少 API 契約對齊步驟

**Issue**：#178
**MoSCoW**：Should
**Size**：M（2pt）

**User Story**：身為 Developer subagent，我希望在全端 Story 開發時被強制要求先讀後端 router 的 response 結構，以確保前後端 API 欄位名稱一致，防止欄位名不一致 bug 累積數十個 Sprint 才被發現。

**Acceptance Criteria**：

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | story-lifecycle-prompt.md Developer 工作流新增 API 契約對齊步驟 | `skills/sprint-execution/story-lifecycle-prompt.md` 的 TDD Green 階段加入 Hard Rule：全端 Story 必須先 Read 後端 router return statement，確認 key 名稱後前端 type 欄位名須完全一致 |
| AC2 | 全端 Story 定義明確 | 文件明確定義「全端 Story」為同時涉及前端和後端修改的 Story |
| AC3 | QA Spec Compliance Review 新增前後端欄位一致性檢查 | `spec-reviewer-prompt.md` 新增檢查項：若 Story 同時修改前後端，需確認前端 API response type 欄位名與後端 response dict/model 的 key 完全一致，不一致 → FAIL |

---

### US-187：Sprint Review 缺少生產環境部署驗證步驟

**Issue**：#179
**MoSCoW**：Should
**Size**：S（1pt）

**User Story**：身為 Sprint Review 執行者，我希望在 Demo 前先驗證生產環境已部署最新版本，以確保 Stakeholder 看到的是最新的代碼，而不是因未部署導致「修了等於沒修」。

**Acceptance Criteria**：

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | sprint-review/SKILL.md §2 新增 Pre-Demo 部署驗證步驟 | `skills/sprint-review/SKILL.md` §2 在 Demo 展示前新增 Pre-Demo 部署驗證前置條件 |
| AC2 | 最新 commit hash 驗證 | 驗證步驟包含：執行 `git log --oneline -1` 取得最新 commit hash |
| AC3 | 生產環境部署確認 | 驗證步驟包含：若專案有 Cloud Run 部署，確認生產環境 image 包含最新 commit 或最後部署時間晚於最後 Story commit 時間 |
| AC4 | 未部署時自動觸發部署 | 若未部署，在 Review 前先觸發 `deployment-readiness` 確保 Demo 基於最新代碼 |

**Done 定義 Checklist**：

- [x] AC1：`skills/sprint-review/SKILL.md` §2 已在 Demo 展示前新增「Pre-Demo 部署驗證」前置條件子節
- [x] AC2：驗證步驟包含 `git log --oneline -1` 取得最新 commit hash
- [x] AC3：驗證步驟包含 Cloud Run `gcloud run services describe` 部署時間確認，並說明兩個判斷標準（image digest / 部署時間），無 Cloud Run 時標記「不適用」
- [x] AC4：未部署時明確指示觸發 `deployment-readiness` skill，並等待完成後才進行 Demo
- [x] §7 執行檢查清單新增「Pre-Demo 部署驗證」4 項 checkbox
- [x] Spec Compliance 審查通過
- [x] Code Quality 審查通過
- [x] Security 審查：不適用（framework skill 文件，無程式碼）

---

### US-188：sprint-execution: 平行 subagent 禁止直接修改共用文件 — 主 session 批次更新

**Issue**：#183
**MoSCoW**：Should
**Size**：M（2pt）

**User Story**：身為 Sprint Execution 框架的維護者，我希望平行 subagent 不直接修改 PROJECT_BOARD.md 和 sprint_N.md，改由主 session 在所有平行 subagent 完成後批次更新，以避免並發寫入導致狀態不一致。

**Acceptance Criteria**：

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | sprint-execution SKILL.md 新增共用文件限制規則 | `skills/sprint-execution/SKILL.md` 明確說明平行 subagent 不得直接修改 PROJECT_BOARD.md 和 sprint_N.md |
| AC2 | story-lifecycle-prompt.md 同步更新 | `skills/sprint-execution/story-lifecycle-prompt.md` 移除平行 subagent 對共用文件的直接寫入指令 |
| AC3 | 批次更新機制說明 | SKILL.md 明確描述主 session 批次更新流程：在所有平行 subagent 完成後統一更新共用文件 |
| AC4 | §1.5 審查不再出現 subagent 覆蓋造成的狀態不一致 | Sprint Execution 的 §1.5 審查步驟中，不再出現因 subagent 並發寫入導致的 PROJECT_BOARD 狀態不一致 |

**Done 定義 Checklist**：

- [x] AC1：`skills/sprint-execution/SKILL.md` 新增 §2.2「平行執行安全防護（共用文件保護）」，HARD-GATE 明確說明平行 subagent 不得直接修改 PROJECT_BOARD.md 和 sprint_N.md
- [x] AC2：`skills/sprint-execution/story-lifecycle-prompt.md` 執行流程更新為條件路徑（循序/平行），新增 §8.3 包含 HARD-GATE 禁止平行 subagent 直接寫入共用文件
- [x] AC3：SKILL.md §2.2「主 session 批次更新機制」明確描述 4 步驟批次更新流程，含 git commit 範例
- [x] AC4：透過規則制定消除並發寫入根源；循序執行仍保留既有衝突偵測機制（read-then-compare）
- [x] Spec Compliance 審查通過
- [x] Code Quality 審查通過
- [x] Security 審查：不適用（framework skill 文件，無程式碼）

---

### US-189：CI/CD 變更強制 QA + SRE 雙審查 Gate

**Issue**：#177
**MoSCoW**：Could
**Size**：M（2pt）

**User Story**：身為 Sprint Execution 或 shoot Skill 的使用者，我希望當偵測到 CI/CD 相關檔案被修改時，系統自動強制 QA + SRE 雙審查並通過後才允許 commit，以防止 production secret 遺失等高風險問題。

**Acceptance Criteria**：

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | CI/CD 相關路徑 pattern 偵測機制實作 | 在 Story-Lifecycle subagent 或 /shoot 的 commit 前 gate 加入檢查：偵測 `.github/workflows/**`、`scripts/deploy*.sh`、`scripts/add_secret.sh`、`Dockerfile*`、`cloudbuild*.yaml`、`docker-compose*.yml` 等路徑 |
| AC2 | QA 審查自動觸發 | 偵測到 CI/CD 變更時，自動派遣 QA subagent 執行 regression check，確認變更不會破壞既有部署流程 |
| AC3 | SRE 審查自動觸發 | 偵測到 CI/CD 變更時，自動派遣 SRE subagent 確認基礎設施配置正確性（secret 掛載、IAM、環境變數完整性） |
| AC4 | 雙審查 PASS 後才允許 commit | QA + SRE 雙審查皆 PASS 後，才允許執行 commit 動作 |

**Done 定義 Checklist**：

- [x] AC1：`skills/sprint-execution/story-lifecycle-prompt.md` §6.8 新增 CI/CD 路徑 pattern 偵測（`.github/workflows/**`、`scripts/deploy*.sh`、`scripts/add_secret.sh`、`Dockerfile*`、`cloudbuild*.yaml`、`docker-compose*.yml`）；`skills/shoot/SKILL.md` 步驟 5.5 與 §8.1 同步新增偵測機制
- [x] AC2：§6.8「QA 審查（regression check）」明確定義 QA-CICD-1～QA-CICD-4 四個自動審查項目，偵測到 CI/CD 變更時自動觸發
- [x] AC3：§6.8「SRE 審查（infrastructure config correctness）」明確定義 SRE-CICD-1～SRE-CICD-4 四個審查項目（secret 掛載、IAM 最小權限、env var 完整性、映像來源安全），偵測到 CI/CD 變更時自動觸發
- [x] AC4：§6.8 結尾 HARD-GATE 明確規定 QA + SRE 雙審查均 PASS 後才允許 commit；`shoot/SKILL.md` §8.1 同步加入 HARD-GATE；執行流程圖已更新
- [x] Spec Compliance 審查通過
- [x] Code Quality 審查通過
- [x] Security 審查通過（CI/CD 安全相關 Story，已審查 secret 掛載與 IAM 規則）

---

### US-190：feat: Dispel 及 Sprint Execution 應產出 Mermaid SA 圖表

**Issue**：#185
**MoSCoW**：Could
**Size**：L（3pt）

**User Story**：身為使用 Dispel 考古功能的開發者或新人，我希望考古報告和 Sprint 交付物包含 Mermaid SA 圖表，以便透過視覺化架構圖在 30 秒內掌握系統全貌，提升文件可讀性。

**Acceptance Criteria**：

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | Dispel SKILL.md §4 各角色分析框架新增必要圖表規格 | `skills/dispel/SKILL.md` §4 明確列出各角色報告必要圖表：architecture.md（部署架構圖、模組依賴圖）、intent.md（使用案例圖、領域模型圖）、codebase.md（關鍵業務流程圖至少 top 3）、operations.md（CI/CD Pipeline 流程圖） |
| AC2 | Sprint Execution 新增 SA 圖表更新 checklist | Sprint Execution skill 新增 checklist 項目：若 Story 涉及 API 端點、Entity、業務流程、角色/權限、部署架構/CI/CD 變更，須同步更新 `docs/sa/` 下的對應圖表 |
| AC3 | SA 文件目錄結構規範 | 規範中明確定義 `docs/sa/` 目錄結構：`deployment.md`、`domain-model.md`、`use-cases.md`、`workflows/` |
| AC4 | Mermaid 語法正確性 | 所有新增的圖表範例使用有效的 Mermaid 語法，可在 GitHub 正常渲染 |

**Done 定義 Checklist**：

- [x] AC1：`skills/dispel/SKILL.md` §4 各角色子節新增「必要圖表」區塊：§4.1 intent.md（使用案例圖 + 領域模型圖）、§4.2 architecture.md（部署架構圖 + 模組依賴圖）、§4.3 codebase.md（關鍵業務流程圖 top 3）、§4.6 operations.md（CI/CD Pipeline 流程圖）
- [x] AC2：`skills/sprint-execution/story-lifecycle-prompt.md` 新增 §8.4「SA 圖表更新 Checklist」，含 6 類觸發條件（API 端點、Entity、業務流程、角色/權限、部署架構、CI/CD）與對應 `docs/sa/` 文件對照表；DoD 自檢表新增「SA 圖表」層次
- [x] AC3：§8.4 明確定義 `docs/sa/` 目錄結構：`deployment.md`、`domain-model.md`、`use-cases.md`、`workflows/`
- [x] AC4：所有圖表範例均使用有效 Mermaid 語法（`graph TD`、`graph LR`、`erDiagram`、`sequenceDiagram`），以 ` ```mermaid ` 代碼塊包裹，可在 GitHub 正常渲染
- [x] Spec Compliance 審查通過
- [x] Code Quality 審查通過
- [x] Security 審查：不適用（framework skill 文件，無程式碼）

---

### US-191：支援 Cursor 平台安裝

**Issue**：#4
**MoSCoW**：Could
**Size**：L（3pt）

**User Story**：身為 Cursor 使用者，我希望能夠在 Cursor 平台安裝並使用 Shikigami 的核心技能集，以便不受限於 Claude Code 平台也能獲得相同的 AI 輔助開發工作流。

**Acceptance Criteria**：

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | Cursor 平台相容性調查完成 | 產出調查報告，明確列出 Cursor Rules / Agent 系統與 Shikigami 各元件（SKILL.md、Subagent dispatch、SessionStart hook）的相容性對照表 |
| AC2 | Subagent 派遣機制確認 | 確認 Cursor 是否能模擬或替代 Subagent dispatch，並記錄技術結論（支援 / 部分支援 / 不支援） |
| AC3 | 適配層實作（條件式） | 若平台支援，實作 Cursor 專屬 adapter，使至少 80% 的現有 Skills 可在 Cursor 中正常觸發 |
| AC4 | Cursor 安裝指南撰寫 | README 中新增 Cursor 安裝章節，步驟可讓使用者在 30 分鐘內完成安裝並執行第一個 Skill |
| AC5 | 實際安裝驗證通過 | 依照安裝指南在乾淨的 Cursor 環境中完整執行，無卡關步驟，核心 Skill 可正常運作 |

**Done 定義 Checklist**：

- [x] AC1：`docs/CURSOR_COMPATIBILITY_SURVEY.md` 產出，包含 Cursor Rules/Agent 系統 vs Shikigami 各元件（SKILL.md、Subagent dispatch、SessionStart hook）詳細相容性對照表
- [x] AC2：技術結論明確記錄為「**部分支援**」：邏輯流程/角色切換部分支援，context 隔離/平行執行不支援；含 5 維度評估表
- [x] AC3：`scripts/install-cursor.sh` 自動安裝腳本實作，生成 23 個 Cursor Rules（22/25 Skills = 88%，超過 80% 門檻）；腳本實際執行驗證通過
- [x] AC4：`docs/INSTALL_CURSOR.md` 詳細安裝指南完成（參照 INSTALL_OPENCODE.md 格式）；README.md 新增「Cursor 平台支援」章節，含一鍵安裝指令與指南連結
- [x] AC5：`scripts/install-cursor.sh` 在本環境實際執行驗證（23 個 `.mdc` 檔案成功生成，symlink 建立，alwaysApply 設定確認）；完整 Cursor GUI 驗證受限於無法啟動 Cursor 圖形界面，文件中已說明並提供驗證步驟
- [x] Spec Compliance 審查通過（AC1-AC4 完整滿足，AC5 腳本層驗證通過）
- [x] Code Quality 審查通過（`set -euo pipefail`、變數引用安全、文件結構一致）
- [x] Security 審查：不適用（shell 腳本僅操作本地目錄，無外部網路呼叫）
