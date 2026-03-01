# Sprint 7

> 週期：2026-03-01 ~ 2026-03-08
> 狀態：進行中
> 專案等級：low（完全自治）

---

## Sprint Goal

**「啟動 v0.5.0 穩定化，清零 Sprint 6 Retro 技術債，建立解咒模式（Legacy 系統考古 Skill），並完成測試框架 CI 整合」**

Retro #10 和 #11 清除 Sprint 6 遺留的狀態回寫與檔案歸檔問題。shikigami:dispel 為新 Skill，讓七個式神各自從角色視角解讀 Legacy 系統。US-T05 補完交叉引用驗證，US-T07 建立 CI Pipeline 將所有驗證腳本自動化。

對應 ROADMAP：v0.5.0「穩定化」+ 測試框架 CI 整合。

---

## Sprint Backlog

| Story | 任務 | 負責 | 狀態 |
|---|---|---|---|
| Retro #10：sprint_N.md 狀態回寫機制 | `skills/sprint-execution/SKILL.md` 步驟 7 新增「同步 sprint_N.md」子步驟；回溯修復 sprint_6.md 歷史狀態欄 | Developer | 待開始 |
| Retro #11：PLUGIN_DEV_NOTES.md 歸入 KM | `docs/PLUGIN_DEV_NOTES.md` 移至 `docs/km/`，更新全倉庫引用路徑 | Developer | 完成 |
| shikigami:dispel 解咒模式 | 新建 `skills/dispel/SKILL.md`（七角色分析框架）+ `commands/dispel.md` + scrum-master 路由更新 | Developer + Architect | 待開始 |
| US-T05：交叉引用驗證 | 新建 `scripts/validate-xrefs.sh`，掃描所有 .md 的 shikigami:xxx 引用並驗證對應 skill 存在 | Developer + QA | 待開始 |
| US-T07：CI Pipeline | 新建 `.github/workflows/validate.yml`，自動執行所有驗證腳本 | Developer + QA | 待開始（前置：US-T05） |

---

## 工作容量

- Retro #10：< 0.1 Sprint（S，SKILL.md 步驟補充 + sprint_6.md 歷史修復）
- Retro #11：< 0.1 Sprint（S，git mv + 引用路徑更新）
- shikigami:dispel：~0.4 Sprint（M，新 Skill 建立，七角色 prompt 設計）
- US-T05：~0.15 Sprint（S，grep + 路徑驗證，ADR-002 技術棧已定）
- US-T07：~0.3 Sprint（M，GitHub Actions YAML 從零建立 + 觸發條件設計）
- 合計：~1.05 Sprint（7 points）

**Points 換算**（T-shirt Sizing）：Retro #10 = 1pt（S）、Retro #11 = 1pt（S）、dispel = 2pt（M）、US-T05 = 1pt（S）、US-T07 = 2pt（M）= 合計 **7 points**

> **容量決策說明**：歷史 Velocity 為 4→5→4→6→8，7pt 處於中位。無 L Story，以 S+M 組合為主，執行壓力可控。

---

## 執行順序

```
Retro #11 ─────────────────────────────────> 待開始（無依賴，最小改動先行）

Retro #10 ─────────────────────────────────> 待開始（無依賴，可與 #11 並行）

shikigami:dispel ──────────────────────────> 待開始（無依賴，Sprint 主體工作）

US-T05 ────────────────────────────────────> 待開始（無依賴，測試框架延續）

US-T07 ────────────────────────────────────> 待開始（前置：US-T05 完成）
```

- Retro #10 與 #11 可同步啟動，目標 Sprint Day 1 完成
- shikigami:dispel 為 Sprint 主體工作，Day 2-4 完成
- US-T05 在 Retro 完成後啟動，Day 3-4 完成
- US-T07 需等 US-T05 完成後啟動，Day 4-5 完成

---

## 風險

| 風險 | 可能性 | 影響 | 應對 |
|---|---|---|---|
| dispel 七角色 prompt 設計工作量超出 M 估計 | 中 | 中 | 每個角色的分析指引控制在 3-5 項，不追求完美；後續 Sprint 可迭代深化 |
| US-T07 GitHub Actions runner 環境與本地差異 | 低 | 低 | 本地先驗證所有腳本可執行；CI 設定 bash strict mode |
| US-T05 掃描到合法但無對應 skill 的引用（如 command-only 路由） | 低 | 低 | AC 中定義豁免清單，或在腳本中明確排除 |
| scrum-master 路由更新觸發 ADR-003 Preflight Check | 確定 | 低 | 已知觸發，dispel 路由新增屬 Sprint Backlog 內 Story，Preflight Check 通過 |

---

## Story 詳情

### Retro #10：sprint_N.md 狀態回寫機制

**背景與動機**

Sprint 6 Execution 更新 PROJECT_BOARD.md 時未回頭更新 sprint_6.md 的狀態欄，造成兩份文件不一致。

**修改目標**：`skills/sprint-execution/SKILL.md` 步驟 7 + `docs/sprints/sprint_6.md` 歷史修復

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 同步指引新增 | `skills/sprint-execution/SKILL.md` 步驟 7 新增「同步 sprint_N.md」子步驟：(a) 從 PROJECT_BOARD.md 符合 `/^## Sprint (\d+)/` 的最近標題取得 Sprint 編號 N；(b) 開啟 `docs/sprints/sprint_N.md`，將 Sprint Backlog 表格的「狀態」欄更新為與 PROJECT_BOARD.md 對應 Story 列一致；(c) 每個 Story 更新 PROJECT_BOARD 後立即執行 |
| AC2 | [靜態] | sprint_6.md 歷史修復 | sprint_6.md Sprint Backlog 表格中所有 Story 的狀態欄值，與 PROJECT_BOARD.md Sprint 6 區塊對應 Story 的狀態欄值字串完全一致 |

**MoSCoW**：Must（Retro Action Item）
**GitHub Issue**：#10
**Size**：S / **Points**：1

---

### Retro #11：PLUGIN_DEV_NOTES.md 歸入 KM 目錄

**背景與動機**

`docs/PLUGIN_DEV_NOTES.md` 位於 `docs/` 根目錄而非 `docs/km/`，不符合知識管理目錄結構慣例。

**修改目標**：檔案移動 + 全倉庫引用更新

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 檔案位置 | `docs/km/PLUGIN_DEV_NOTES.md` 存在；`docs/PLUGIN_DEV_NOTES.md` 不再存在 |
| AC2 | [靜態] | 舊路徑清零 | `grep -r "docs/PLUGIN_DEV_NOTES" --include="*.md" --include="*.sh" .` 結果為空 |
| AC3 | [靜態] | 新路徑引用正確 | 凡原先引用 `docs/PLUGIN_DEV_NOTES.md` 的文件，其引用路徑已更新為 `docs/km/PLUGIN_DEV_NOTES.md` |

**MoSCoW**：Must（Retro Action Item）
**GitHub Issue**：#11
**Size**：S / **Points**：1

---

### shikigami:dispel 解咒模式

**背景與動機**

Legacy 系統考古是開發者的常見需求。解咒模式讓七個式神各自從角色視角分析當前 repo，產出「咒文解析」報告，作為後續 `/sprint` 改動的基礎。命名延續式神世界觀：Legacy 系統是前人施下的咒，需要先解讀才能動。

**輸入**：當前 repo（與其他 skill 一致）
**輸出**：咒文解析報告文件

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態]+[人工] | Skill 文件 | `skills/dispel/SKILL.md` 存在；[靜態] 包含 6 個角色（PO、Architect、Developer、QA、Security、SRE）的獨立章節（H2 或 H3）；[人工] 每個角色章節含至少 3 個具體分析指引項目 |
| AC2 | [靜態] | Command 文件 | `commands/dispel.md` 存在；frontmatter 含 `description`（非空字串）；body 含 `invoke shikigami:dispel` |
| AC3 | [靜態] | 路由更新 | `skills/scrum-master/SKILL.md` 意圖決策樹新增「解咒/考古/legacy 分析 → invoke shikigami:dispel」節點 |
| AC4 | [靜態]+[人工] | 輸出定義 | SKILL.md 定義輸出文件路徑格式（如 `docs/dispel/`）；文件結構骨架包含：執行摘要、各角色分析章節（6 個）、重建建議 |
| AC5 | [靜態] | 路由邊界 | scrum-master SKILL.md 明確描述 dispel vs systematic-debugging 的適用邊界：dispel = legacy/不活躍 codebase 考古；systematic-debugging = 活躍開發中的 bug/測試失敗 |

**MoSCoW**：Must（Stakeholder 要求）
**GitHub Issue**：#13
**Size**：M / **Points**：2

---

### US-T05：交叉引用驗證

**User Story**
As a Developer, I want a script that verifies all `shikigami:xxx` references point to existing skills.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 掃描範圍 | `scripts/validate-xrefs.sh` 存在；掃描倉庫根目錄下所有 .md 檔案（遞迴），擷取 `shikigami:[a-z-]+` 格式的引用 |
| AC2 | [靜態] | 存在性驗證 | 對每個引用 `shikigami:<name>`，驗證 `skills/<name>/SKILL.md` 存在；不存在則標記為 ERROR |
| AC3 | [靜態] | 報告格式 | 有 broken reference 時輸出：`ERROR: <file>:<line>: broken reference 'shikigami:<name>'` |
| AC4 | [靜態] | Exit code | exit code 0 = 無 broken reference；非 0 = 至少一個 broken reference |

**RICE**：25.6
**MoSCoW**：Should
**Size**：S / **Points**：1

---

### US-T07：CI Pipeline

**User Story**
As a Developer, I want all structural validation scripts to run automatically on every push, so that broken commits never reach users.

**前置條件**：US-T05 完成

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
**Size**：M / **Points**：2

---

## Retro Action Items 處理

| # | Action（原始） | 本 Sprint 處理方式 | 狀態 |
|---|---------------|-------------------|------|
| Sprint 6 #1（Issue #10） | sprint_N.md 狀態回寫 | Retro #10 納入 Sprint 7，作為獨立 1pt Story | 待開始 |
| Sprint 6 #2（Issue #11） | PLUGIN_DEV_NOTES.md 歸檔 | Retro #11 納入 Sprint 7，作為獨立 1pt Story | 待開始 |

---

## 驗收標準

### Retro #10：sprint_N.md 狀態回寫機制

- [ ] sprint-execution SKILL.md 步驟 7 含同步 sprint_N.md 子步驟（AC1 通過）
- [ ] sprint_6.md Sprint Backlog 狀態欄與 PROJECT_BOARD.md 一致（AC2 通過）
- [ ] GitHub Issue #10 關閉

### Retro #11：PLUGIN_DEV_NOTES.md 歸入 KM

- [ ] `docs/km/PLUGIN_DEV_NOTES.md` 存在，原路徑已移除（AC1 通過）
- [ ] 舊路徑引用全部清零（AC2 通過）
- [ ] 新路徑引用正確存在（AC3 通過）
- [ ] GitHub Issue #11 關閉

### shikigami:dispel 解咒模式

- [ ] `skills/dispel/SKILL.md` 存在，含 6 個角色分析框架（AC1 通過）
- [ ] `commands/dispel.md` 存在，frontmatter 與 body 正確（AC2 通過）
- [ ] scrum-master 路由新增 dispel 節點（AC3 通過）
- [ ] 輸出文件路徑與結構骨架已定義（AC4 通過）
- [ ] dispel vs systematic-debugging 邊界明確（AC5 通過）
- [ ] GitHub Issue #13 關閉

### US-T05：交叉引用驗證

- [ ] `scripts/validate-xrefs.sh` 存在並可執行（AC1 通過）
- [ ] shikigami:xxx 引用對應 skill 存在性驗證（AC2 通過）
- [ ] broken reference 報告格式正確（AC3 通過）
- [ ] exit code 正確（AC4 通過）

### US-T07：CI Pipeline

- [ ] `.github/workflows/validate.yml` 存在（AC1 通過）
- [ ] 6 支驗證腳本全部列入 pipeline（AC2 通過）
- [ ] 無 continue-on-error，失敗即停（AC3 通過）
- [ ] 本地執行總時間 < 20 秒（AC4 通過）
- [ ] Step 命名可讀（AC5 通過）
