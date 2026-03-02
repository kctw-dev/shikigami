# Sprint 15

**Sprint Goal**：完成 M5 穩定化的使用者就緒工作 — 建立可重複的全新環境安裝驗證報告，並交付端對端使用者文件（Tutorial + Troubleshooting），讓外部使用者能獨立完成安裝並走完第一個 Sprint。
**期間**：2026-03-02 ~ 2026-03-08

---

## Sprint Backlog

| Story ID | 標題 | Size | Points | 狀態 |
|----------|------|------|--------|------|
| US-15 | 完整安裝流程驗證（全新環境測試） | M | 2 | 待開始 |
| US-16 | 使用者文件完善（Tutorial + Troubleshooting） | M | 2 | 待開始 |

**總計：2 Stories / 4 Points**

---

## Acceptance Criteria

### US-15：完整安裝流程驗證（全新環境測試）

**User Story**
As an external user, I want the installation flow to be verified in a clean environment and documented in a reproducible checklist, so that I can confidently follow the README and get a working Shikigami setup without hidden assumptions or undocumented prerequisites.

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 建立安裝驗證 Checklist | 新建 `docs/km/INSTALL_VERIFICATION.md`；包含逐步 Checklist（每步驟含：指令/動作描述、預期輸出、PASS/FAIL 欄位、備注欄位）；涵蓋全部安裝步驟：環境前提確認 → Clone → Claude Code CLI 設定 → Plugin 掛載 → 首次 `shikigami:standup` 確認 |
| AC2 | [動態] | 全新環境實際執行（已降級） | 依照 README 安裝步驟在無任何 Shikigami 預設前提的環境中逐步執行，將每步驟結果填入 AC1 Checklist；任何步驟失敗須記錄失敗原因與修正動作（不可略過），最終 Checklist 所有步驟標記 PASS。**Architect 降級決策**：AC2 以「文件審查模式」執行 — 逐步審查 README 步驟合理性、指令可執行性、前提假設完整性，填入 Checklist 並標記審查結論（不需實際執行環境）。降級原因：測試環境限制。 |
| AC3 | [靜態] | 驗證報告完整性 | `INSTALL_VERIFICATION.md` 包含：(a) 測試環境規格（OS、Node 版本、Claude Code CLI 版本、git 版本）；(b) 至少 5 個驗證場景（含：環境前提、Clone、CLI 設定、Plugin 掛載、首次執行各 1 個）；(c) 測試日期與執行者（可為 AI Agent）；(d) 發現問題清單（若為空則明確標記「無發現問題」） |
| AC4 | [靜態] | README 對齊 | 若 AC2 執行中發現 README 有任何錯誤、缺漏、過時描述，須同步修正 `README.md` 對應段落，修正內容列入 AC3「發現問題清單」 |

**RICE 評分**：28.0（Reach 10 × Impact 2 × Confidence 70% ÷ Effort 0.5）
**MoSCoW**：Must / **Size**：M / **Points**：2
**依賴**：無前置 Story（獨立可執行）

---

### US-16：使用者文件完善（Tutorial + Troubleshooting）

**User Story**
As an external user who has installed Shikigami, I want a step-by-step tutorial covering installation to first Sprint, and a troubleshooting guide for common failure scenarios, so that I can get productive without needing to read all the internal documentation or ask questions in issues.

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | Tutorial 文件建立 | 新建 `docs/tutorial/GETTING_STARTED.md`；覆蓋「安裝 → 第一個 Sprint」完整端對端路徑，包含步驟：(1) 前置條件確認、(2) 安裝 Shikigami、(3) 初始化專案（`shikigami:onboarding`）、(4) 定義第一個 User Story、(5) 執行 Sprint Planning、(6) 執行 Sprint Execution（至少 1 個 Story）、(7) 執行 Sprint Review；每個步驟含指令範例與預期輸出摘要 |
| AC2 | [靜態] | Troubleshooting 文件建立 | 新建 `docs/tutorial/TROUBLESHOOTING.md`；至少涵蓋 6 個常見失敗情境，每個情境包含：情境描述、症狀（錯誤訊息或異常行為）、根因說明、解決步驟；涵蓋情境類型：(a) Claude Code CLI 未認證、(b) GitHub CLI 未認證、(c) Plugin 掛載失敗、(d) Standup 健康快篩 CRITICAL、(e) Sprint Planning QA Hard Gate 失敗、(f) 任意 1 個來自 US-15 驗證報告的發現問題 |
| AC3 | [靜態] | README 文件導覽區段 | `README.md` 新增「## 文件導覽」區段（位置：在 Installation 之後，Features 之前）；包含：(1) Tutorial 連結 → `docs/tutorial/GETTING_STARTED.md`、(2) Troubleshooting 連結 → `docs/tutorial/TROUBLESHOOTING.md`、(3) 一句話摘要說明各文件用途；區段格式使用 Markdown 表格或清單 |
| AC4 | [靜態] | 文件可發現性 | `docs/tutorial/` 目錄下建立 `README.md`（或 `INDEX.md`），列出目錄內所有文件與用途，作為 Tutorial 目錄的導覽起點；`docs/PROJECT_BOARD.md` 工件導覽區段新增 Tutorial 連結 |

**RICE 評分**：22.5（Reach 10 × Impact 3 × Confidence 75% ÷ Effort 1.0）
**MoSCoW**：Must / **Size**：M / **Points**：2
**依賴**：US-15 AC2/AC3（Troubleshooting AC2(f) 需引用 US-15 驗證報告發現）；若 US-15 未在同 Sprint 完成，AC2(f) 降級為「任意 1 個安裝常見問題」，不阻塞 US-16 整體交付

---

## 權重調整記錄

- 檢查結果：Sprint 13 Problem 含 QA 關鍵字（QA Code Quality Review），Sprint 14 Problem 不含 QA 關鍵字 → 連續計數歸零（僅 1 Sprint 無 QA Problem，未達降級門檻 2 Sprint）
- 當前狀態：QA Hard Gate 維持 Must（Sprint 14 開始生效，Sprint 15 繼續）
- 降級條件：需再累積 1 個 Sprint（Sprint 15）無 QA Problem，才可於 Sprint 16 降級

---

## 平行分群策略

（Architect Sprint 15 Planning 建議）

### Phase 1（可平行）

| Story ID | AC | 修改目標 |
|----------|----|---------|
| US-15 | AC1 | 新建 `docs/km/INSTALL_VERIFICATION.md`（Checklist 結構） |
| US-15 | AC3 | 填入 INSTALL_VERIFICATION.md 完整性欄位（環境規格、場景清單） |
| US-16 | AC1 | 新建 `docs/tutorial/GETTING_STARTED.md` |
| US-16 | AC2 | 新建 `docs/tutorial/TROUBLESHOOTING.md` |
| US-16 | AC4 | 新建 `docs/tutorial/README.md`（目錄導覽）；PROJECT_BOARD 新增 Tutorial 連結 |

**平行化理由**：Phase 1 各工作項目目標檔案互異，無讀寫衝突，可完全平行執行。

### Phase 2（序列，基於 Phase 1 完成）

| 步驟 | Story ID | AC | 說明 |
|------|----------|----|------|
| 2-1 | US-15 | AC2 | 文件審查模式執行：逐步審查 README 步驟，填入 Checklist 審查結論 |
| 2-2 | US-15 | AC4 | README 對齊修正（基於 AC2 的發現問題清單） |

**序列理由**：AC2 審查結果決定 AC4 修正範圍，必須序列執行。

### Phase 3（序列，基於 US-15 AC4 完成後）

| 步驟 | Story ID | AC | 說明 |
|------|----------|----|------|
| 3-1 | US-16 | AC3 | README 文件導覽區段（基於 US-15 AC4 完成後的 README 最終狀態） |

**序列理由**：README 導覽區段應在 README 內容穩定後建立，避免連結位置衝突。

---

## 工作容量

| 指標 | 數值 |
|------|------|
| 計畫 Stories | 2 |
| 計畫 Points | 4（2 × M） |
| 近 3 Sprint 平均 Velocity | 3.3pt（Sprint 12: 4、Sprint 13: 4、Sprint 14: 2） |
| Sprint 14 Velocity | 2pt |
| 緩衝率 | 121%（略超近 3 Sprint 平均，但兩個 Story 均為 QA Hard Gate APPROVED，風險可控） |

**容量決策說明**：
Sprint 15 選入 US-15/US-16（4 points），高於 Sprint 14 的 2pt 但接近 Sprint 12/13 的 4pt 歷史水準。選入理由：
1. 兩個 Story 均經 Architect 評估（M-size，無 ADR 阻礙）
2. QA 確認兩個 Story AC 可測試性全部 PASS（Hard Gate 通過）
3. US-15 AC2 已由 Architect 降級為文件審查模式，降低動態執行風險
4. M5 里程碑關鍵路徑：US-15/US-16 是外部使用者就緒的最後兩個必要條件

---

## ADR 前提

| Story | ADR 需求 | 狀態 |
|-------|---------|------|
| US-15 | 無（建立新文件，未修改現有 SKILL.md） | N/A |
| US-16 | 無（建立新文件，未修改現有 SKILL.md）；README 修改不屬於 ADR-003 Framework Document Change 範疇 | N/A |

**說明**：Architect 確認 US-15/US-16 均無 ADR 阻礙。兩個 Story 的主要工作為建立新文件（docs/km/、docs/tutorial/）及 README 補充，不修改 skills/ 下的 SKILL.md，ADR-003 Hard Gate 不適用。

---

## Token 記錄

| 環節 | Token | 備註 |
|------|-------|------|
| Planning | 待補 | Sprint 15 Planning 完成後從 JSONL 提取 |
| Execution | 待補 | Sprint 15 Execution 完成後填入 |
| Review | 待補 | Sprint 15 Review 完成後填入 |
