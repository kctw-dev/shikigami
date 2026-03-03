# Sprint 35

**狀態**：進行中
**期間**：2026-04-20 ~ 2026-04-26
**Sprint Goal**：ADR-010 原子性實作交付 — Backlog Source of Truth 從 PRODUCT_BACKLOG.md 遷移至 GitHub Issues，完成三個 SKILL.md 改寫 + DEPRECATED 標頭 + Label 基礎設施
**總計**：5 Stories / 8 Points

---

## Sprint Backlog

| Story ID | 標題 | Size | Points | QA doc-only 判定 | 狀態 |
|----------|------|------|--------|-----------------|------|
| US-69 | ADR-010 Label 基礎設施 — 建立所有 ADR-010 定義 labels 並更新 onboarding Pre-flight | S | 1 | No | 已完成 |
| US-70 | `backlog-intake` SKILL.md 重大改寫 — 移除 PRODUCT_BACKLOG.md 寫入，改為 Issue label + body template 兩層架構 | M | 2 | No | 完成 |
| US-71 | `sprint-planning` SKILL.md 修改 — PO Story 選取來源改為 `gh issue list` + 即時 MoSCoW/RICE 排序計算 | M | 2 | No | 完成 |
| US-72 | `backlog-management` SKILL.md 修改 — Grooming 流程改為操作 GitHub Issues，加入 Pre-flight 錯誤恢復掃描 | M | 2 | No | 完成 |
| US-73 | PRODUCT_BACKLOG.md DEPRECATED 標頭加入 + ADR-009 格式契約決策域「Superseded by ADR-010」標注 | S | 1 | Yes | 完成 |

**Sprint 容量**：8 Points

---

## Story 詳細 AC

---

### US-69：ADR-010 Label 基礎設施

**來源**：ADR-010 實作路線圖 Step 1
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：No
**ADR 參考**：ADR-010（Label 設計 §兩層 Issue 設計）
**ADR-003 Checklist**：不適用（本 Story 不修改 skills/ 目錄；labels 操作與 onboarding Pre-flight 更新屬框架基礎設施範疇）

**User Story**

As a Developer executing the ADR-010 migration, I want all ADR-010-defined labels created in the GitHub repository and the onboarding Pre-flight checklist updated to verify these labels exist, so that subsequent Sprint 35 Stories (US-70/71/72) can operate on a verified label infrastructure.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 完整 Label 清單建立 | 以下 ADR-010 定義的全部 9 個 labels 均已建立於 GitHub repo（`gh label list` 可查詢）：原始 Issue labels：`feature-request`、`bug`、`question`、`triaged`、`backlog-linked`；Backlog Issue labels：`type: backlog-item`、`status: backlog`、`status: in-sprint`；優先級 labels：`priority: must`、`priority: should`、`priority: could`；Size labels：`size: S`、`size: M`、`size: L`（共 14 個 labels，完整對應 ADR-010 兩層 Label 設計） |
| AC2 | [靜態] | Label 驗證指令 | `gh label list --json name` 回傳結果包含上述所有 labels，無遺漏 |
| AC3 | [靜態] | Pre-flight 更新 | onboarding 文件或 Pre-flight 相關 SKILL.md 中的 Pre-flight 核查步驟，加入對 ADR-010 labels 存在性的驗證項目（至少驗證 `type: backlog-item`、`status: backlog`、`status: in-sprint` 三個 Backlog Issue 核心 labels） |
| AC4 | [靜態] | 冪等性保護 | Label 建立步驟具備冪等性：若 label 已存在則跳過（`gh label create` 以 `--force` 或先查詢後建立方式實作） |

---

### US-70：`backlog-intake` SKILL.md 重大改寫

**來源**：ADR-010 實作路線圖 Step 3
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：No
**ADR 參考**：ADR-010（§對 skills/backlog-intake/SKILL.md 的影響 + §兩層 Issue 設計 + §RICE 分數儲存方案 + §錯誤恢復策略）
**ADR-003 Checklist**：必須執行（修改 skills/ 目錄）

**User Story**

As a Product Owner running the backlog-intake workflow, I want the backlog-intake SKILL.md rewritten to remove all PRODUCT_BACKLOG.md write operations and instead output to GitHub Issues via label application and Issue body template filling, so that the Backlog source of truth is exclusively GitHub Issues per ADR-010.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | PRODUCT_BACKLOG.md 寫入步驟移除 | 舊有「Step 6：Append Story 至 PRODUCT_BACKLOG.md」步驟完全移除，SKILL.md 中不存在任何寫入 `docs/prd/PRODUCT_BACKLOG.md` 的指令或描述 |
| AC2 | [靜態] | 兩層 Issue 建立流程 | §3 解析流程加入兩層 Issue 建立步驟：原始 Issue 套用 `triaged` + `backlog-linked` labels；建立 Backlog Issue 並在 body 寫入「來源：#原始Issue編號」；Backlog Issue 套用 `type: backlog-item` + `status: backlog` + `priority: <MoSCoW>` labels |
| AC3 | [靜態] | Issue body template 格式 | §5 輸出格式規範改為 Issue body Story template 格式，包含：User Story 欄位、Acceptance Criteria 欄位、RICE 評分表格（含 Reach / Impact / Confidence / Effort / RICE Score 欄位，使用 `**RICE Score** | **數字**` 格式以供正則提取） |
| AC4 | [靜態] | Step 5 regex 格式驗證 | §3 Step 5（或相應步驟）明確記載 RICE Score 正則提取格式，確保與 ADR-010 定義一致：`\*\*RICE Score\*\* \| \*\*[\d.]+\*\*` |
| AC5 | [靜態] | §4.2 AI 角色聲明更新 | §4.2（或相應的 AI 角色定義區段）中，AI 的職責聲明更新為「填補 Issue body Story template」，移除所有「轉化至 PRODUCT_BACKLOG.md 格式」的描述 |
| AC6 | [靜態] | 冪等性保護 | §3 加入冪等性保護描述：執行前掃描 Backlog Issues 的 body「來源：#N」欄位，若對應 Backlog Issue 已存在則跳過建立，防止重複入庫 |
| AC7 | [靜態] | ADR-003 Checklist 執行 | SKILL.md 修改伴隨 ADR-003 稽核閘門執行記錄（在 sprint_35.md 或 commit message 中附上 ADR-003 Checklist 通過確認） |

---

### US-71：`sprint-planning` SKILL.md 修改

**來源**：ADR-010 實作路線圖 Step 4
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：No
**ADR 參考**：ADR-010（§對 skills/sprint-planning/SKILL.md 的影響 + §Backlog 排序機制）
**ADR-003 Checklist**：必須執行（修改 skills/ 目錄）

**User Story**

As a PO subagent running Sprint Planning, I want the sprint-planning SKILL.md updated so that Story selection uses `gh issue list` with label/milestone filtering and real-time MoSCoW/RICE sorting instead of reading PRODUCT_BACKLOG.md, so that Sprint Planning operates on GitHub Issues as the source of truth.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | §2 Step 4 來源替換 | §2 Checklist Step 4（PO Story 選取）的指令改為 `gh issue list --label "type: backlog-item" --label "status: backlog" --state open --json number,title,body,labels --limit 200`，不再引用 PRODUCT_BACKLOG.md |
| AC2 | [靜態] | §6 Step 1 讀取清單更新 | §6（Subagent 派遣順序）Step 1 的 PO 讀取來源清單移除 `docs/prd/PRODUCT_BACKLOG.md`，改為 `gh issue list`（Backlog Issues）+ `docs/prd/ROADMAP.md`（里程碑目標） |
| AC3 | [靜態] | 即時排序邏輯加入 | §6 Step 1 或 Step 4 加入即時排序計算步驟：(1) 從 Issue body 以正則提取 RICE Score；(2) 排序規則：MoSCoW tier 優先（must > should > could），同 tier 內 RICE Score 降序；(3) 從排序頂部選取適合本 Sprint 的 Stories |
| AC4 | [靜態] | §6 Step 4 PO Round 2 來源移除 | §6 Step 4（PO Round 2 sprint_N.md 建立）中，產出步驟移除「更新 PRODUCT_BACKLOG.md」項目；改為「為選入的 Issues 設定 Milestone + 套用 `status: in-sprint` label」 |
| AC5 | [靜態] | §5 產出文件更新 | §5（產出文件清單）移除 PRODUCT_BACKLOG.md 更新項目，加入：更新 GitHub Issues labels/milestone 的步驟說明 |
| AC6 | [靜態] | ADR-003 Checklist 執行 | SKILL.md 修改伴隨 ADR-003 稽核閘門執行記錄（在 sprint_35.md 或 commit message 中附上 ADR-003 Checklist 通過確認） |

---

### US-72：`backlog-management` SKILL.md 修改

**來源**：ADR-010 實作路線圖 Step 5
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：No
**ADR 參考**：ADR-010（§對 skills/backlog-management/SKILL.md 的影響 + §錯誤恢復策略）
**ADR-003 Checklist**：必須執行（修改 skills/ 目錄）

**User Story**

As a Product Owner running Backlog Grooming, I want the backlog-management SKILL.md updated so that all Grooming operations work against GitHub Issues (via `gh issue list` and label/body updates) instead of PRODUCT_BACKLOG.md, and a Pre-flight error recovery scan is included to ensure consistent Issue state before operations begin.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | §2 Product Discovery 產出更新 | §2 Product Discovery 產出描述改為：新需求直接開 GitHub Issue + 套用原始 Issue labels（`feature-request`/`bug`/`question`），不再寫入 PRODUCT_BACKLOG.md |
| AC2 | [靜態] | §3 Backlog Grooming 核心流程改寫 | §3 Backlog Grooming 的所有內部步驟文字更新為操作 GitHub Issues：以 `gh issue list --label "type: backlog-item" --label "status: backlog" --state open` 查看 Backlog；以 `gh issue edit` 更新 Issue labels/body 執行 Grooming（調整優先級、補充 AC、更新 RICE 分數）；不再讀取或寫入 PRODUCT_BACKLOG.md |
| AC3 | [靜態] | §3 Pre-flight 錯誤恢復掃描 | §3 開頭加入 Pre-flight 錯誤恢復掃描步驟，對應 ADR-010 §錯誤恢復策略三種場景：(1) Label 操作中斷後掃描不一致 label 狀態；(2) Backlog Issue 建立部分完成後以「來源：#N」欄位偵測已存在對應關係；(3) Sprint Planning milestone 中斷後掃描 label/milestone 不一致 Issues |
| AC4 | [靜態] | §6 產出文件降格 | §6（產出文件清單）中，PRODUCT_BACKLOG.md 降格為「非核心產出（唯讀歷史快照）」；核心產出改為 GitHub Issues 狀態（labels / body / milestone） |
| AC5 | [靜態] | ADR-003 Checklist 執行 | SKILL.md 修改伴隨 ADR-003 稽核閘門執行記錄（在 sprint_35.md 或 commit message 中附上 ADR-003 Checklist 通過確認） |

---

### US-73：PRODUCT_BACKLOG.md DEPRECATED 標頭 + ADR-009 標注

**來源**：ADR-010 實作路線圖 Step 2 + Step 6
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：Yes
**ADR 參考**：ADR-010（§對 PRODUCT_BACKLOG.md 的影響 + §對 ADR-009 的影響）
**ADR-003 Checklist**：不適用（doc-only；不修改 skills/ 目錄）
**原子性約束**：US-73 必須在 US-70 + US-71 + US-72 全部完成後執行（Phase 3 最後）

**User Story**

As a Developer completing the ADR-010 atomic delivery, I want PRODUCT_BACKLOG.md marked with a DEPRECATED header and ADR-009's Format Contract decision domain annotated as "Superseded by ADR-010", so that the codebase clearly communicates the new source of truth and the historical ADR chain remains accurate.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | PRODUCT_BACKLOG.md DEPRECATED 標頭 | `docs/prd/PRODUCT_BACKLOG.md` 頂部加入完整 DEPRECATED 標頭，內容符合 ADR-010 規範：`> **DEPRECATED**：自 ADR-010 起，PRODUCT_BACKLOG.md 降級為唯讀歷史快照。Backlog 的 source of truth 已遷移至 GitHub Issues。請使用 \`gh issue list --label "type: backlog-item" --label "status: backlog"\` 查看當前 Backlog。本文件將不再被框架 Skills 寫入，保留作為歷史參考。` |
| AC2 | [靜態] | ADR-009 格式契約標注 | `docs/adr/ADR-009.md` 的格式契約決策域（決策域二）加入「Superseded by ADR-010（格式契約決策域）」標注，說明 backlog-intake Skill 的輸出目標已從「寫入 PRODUCT_BACKLOG.md」改為「為 GitHub Issue 套用 label + 填補 Story template body」 |
| AC3 | [靜態] | 原子性後置條件 | US-73 commit 在時序上位於 US-70、US-71、US-72 的 commit 之後（可透過 git log 驗證）；即三個 SKILL.md 改寫完成前，DEPRECATED 標頭不應存在於 PRODUCT_BACKLOG.md |
| AC4 | [靜態] | ADR-010 標注一致性 | PRODUCT_BACKLOG.md 的 DEPRECATED 標頭與 ADR-010 §對 PRODUCT_BACKLOG.md 的影響 中定義的標頭文字內容一致，無出入 |

---

## 平行分群（Architect 建議）

### Phase 1 — 序列先決

| 群組 | Stories | 說明 |
|------|---------|------|
| Phase 1（序列） | US-69 | 建立 Label 基礎設施；US-70/71/72 依賴此 Phase 的 label 存在性 |

### Phase 2 — 平行執行

| 群組 | Stories | 說明 |
|------|---------|------|
| Phase 2（平行） | US-70 | backlog-intake SKILL.md 改寫；不與 US-71/72 共同修改同一檔案，可平行 |
| Phase 2（平行） | US-71 | sprint-planning SKILL.md 修改；不與 US-70/72 共同修改同一檔案，可平行 |
| Phase 2（平行） | US-72 | backlog-management SKILL.md 修改；不與 US-70/71 共同修改同一檔案，可平行 |

### Phase 3 — 原子性後置

| 群組 | Stories | 說明 |
|------|---------|------|
| Phase 3（序列，後置） | US-73 | DEPRECATED 標頭 + ADR-009 標注；必須在 Phase 2 全部完成後執行，以確保原子性約束 |

**執行順序說明**：
- Phase 1（US-69）先行完成，建立 label 基礎設施
- Phase 2（US-70 + US-71 + US-72）可三路平行執行，各自修改不同 SKILL.md 檔案
- Phase 3（US-73）最後執行，確保 DEPRECATED 標頭在三個 SKILL.md 改寫完成後才加入
- 8pt 以 3-way 平行壓縮為有效約 4pt wall-clock 執行量

---

## 工作容量

| 項目 | 數值 |
|------|------|
| Sprint 期間 | 2026-04-20 ~ 2026-04-26（7 天） |
| 總 Stories | 5 |
| 總 Points | 8 |
| 平行分群 | Phase 1（US-69 序列先決）→ Phase 2（US-70 + US-71 + US-72 三路平行）→ Phase 3（US-73 原子性後置） |
| 有效 Wall-clock | 約 4pt（3-way 平行壓縮） |

---

## ADR 觸發清單

| Story | ADR 編號 | 說明 |
|-------|----------|------|
| US-69 | 無新 ADR | Label 基礎設施建立；設計規範已在 ADR-010 中完整定義，無需新增 ADR |
| US-70 | 無新 ADR | backlog-intake SKILL.md 改寫依照 ADR-010 實作，ADR-003 Checklist 適用（skills/ 修改） |
| US-71 | 無新 ADR | sprint-planning SKILL.md 修改依照 ADR-010 實作，ADR-003 Checklist 適用（skills/ 修改） |
| US-72 | 無新 ADR | backlog-management SKILL.md 修改依照 ADR-010 實作，ADR-003 Checklist 適用（skills/ 修改） |
| US-73 | 無新 ADR | doc-only；ADR-009 格式契約決策域「Superseded by ADR-010」標注為已決策事項的文件化落實 |

**備註**：ADR-010 已 Accepted，涵蓋本 Sprint 所有實作決策。ADR-003 Checklist 為 US-70/71/72 的必要執行項目（非新 ADR，為現有稽核閘門應用）。

---

## 權重調整記錄

歷史趨勢穩定，無需調整（快思模式不執行完整權重調整）

---

## Sprint Planning 簽核

- **PO Round 1**：完成（Story 選取：US-69 S/1pt + US-70 M/2pt + US-71 M/2pt + US-72 M/2pt + US-73 S/1pt；Sprint Goal 確定；總計 8pt / 5 Stories）
- **Architect Round 1**：完成（無新 ADR 需求；ADR-010 Accepted 涵蓋全部；平行分群：Phase 1（US-69）→ Phase 2（US-70+71+72 平行）→ Phase 3（US-73）；ADR-003 Checklist 適用於 US-69/70/71/72；容量可行：8pt 以 3-way 平行有效壓縮至約 4pt wall-clock）
- **QA Round 1**：完成（所有 AC 可測試性 PASS；所有路徑驗證 PASS；doc-only：US-73 Yes / 其餘 No；原子性約束 PASS（US-70/71/72/73 同 Sprint，US-73 最後）；AC 精化項目：US-69 完整 label 清單明確化、US-70 加入 §4.2 AI 角色聲明更新 + §3.3 Step 5 regex 格式、US-71 加入 §6 Step 4 PRODUCT_BACKLOG.md 移除、US-72 澄清 §3 內部步驟文字 + Pre-flight 錯誤恢復範疇）
- **PO Round 2**：完成（整合 Architect/QA 反饋；Drift Protection 驗證通過；AC 最終確認；Sprint Backlog 最終確認；總計 8pt / 5 Stories）
