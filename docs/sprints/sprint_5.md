# Sprint 5

> 週期：2026-03-08 ~ 2026-03-15
> 狀態：完成
> 專案等級：low（完全自治）

---

## Sprint Goal

**「完成 v0.3.0 Tech Debt Registry，建立 ADR-002 解鎖測試框架，並修復 16 項框架監控缺口」**

US-10 為 v0.3.0「知識沉澱」主題的第二個交付，建立技術債務追蹤基礎。ADR-002 作為測試框架技術選型決策，是 US-T01 執行的硬性前置條件，須優先完成。US-FIX-01 修復 QA 審計發現的 13 項監控缺口，涵蓋 DoD 統一、standup 擴充、health-check 補完、sprint-planning 與 sprint-review 修正。

對應 ROADMAP：v0.3.0「知識沉澱」推進 + 測試框架擴展解鎖 + 框架品質修復。

---

## Sprint Backlog

| Story | 任務 | 負責 | 狀態 |
|---|---|---|---|
| ADR-002：測試框架技術選型 | 建立 `docs/adr/ADR-002.md`，依本專案 ADR 格式完成選項分析與決策；內容需包含測試框架技術選型的背景、選項比較、最終決策及排除方案說明 | Architect | 待開始 |
| US-10：Tech Debt Registry | 在 `skills/sprint-execution/developer-prompt.md` 新增 Tech Debt Registry 操作指引；建立 `docs/km/Tech_Debt_Registry.md` 格式規範；設計 [TECH-DEBT] 標記格式；實作 Grooming 流程中的 Tech Debt Review 觸發邏輯 | Developer + QA | 待開始 |
| US-T01：Skill 完整性驗證 | 新建 Skill 完整性驗證腳本（路徑由 Developer 決定，建議 `scripts/validate-skills.sh`），掃描 `skills/` 直接子目錄，驗證 SKILL.md 存在且 frontmatter 合規 | Developer + QA | 待開始（Hard Gate：等待 ADR-002 完成） |
| US-FIX-01：修復審計發現 | 修復 QA 審計 16 項發現中的 13 項：DoD 統一（scrum-master + sprint-execution SKILL.md）、standup Issues 掃描（commands/standup.md）、health-check 擴充（health-check SKILL.md）、sprint-planning 修復（sprint-planning SKILL.md）、sprint-review 修復（sprint-review SKILL.md） | Developer + QA | 待開始 |

---

## 工作容量

- ADR-002：~0.2 Sprint（S，技術決策文件，格式參照 ADR-001，範圍明確）
- US-10：~0.5 Sprint（M，跨技術債務文件設計與 Skill 整合，語意定義需精確）
- US-T01：~0.3 Sprint（S，腳本驗證，路徑清晰，等待 ADR-002 解鎖）
- US-FIX-01：~0.4 Sprint（M，跨 6 個框架文件修正，每項修改範圍小但數量多）
- 合計：~1.4 Sprint（預估 6 points，歷史 Velocity 4-5，超出緩衝——可能 Carry-over）

**Points 換算**（T-shirt Sizing）：ADR-002 = 1pt（S）、US-10 = 2pt（M）、US-T01 = 1pt（S）、US-FIX-01 = 2pt（M）= 合計 **6 points**

> **T-shirt Sizing 參考**：
> - S（< 0.3 Sprint）：單一模組小改動，路徑清晰
> - M（0.3-0.7 Sprint）：跨模組，需設計但風險可控
> - L（> 0.7 Sprint）：跨層、新架構、高不確定性

---

## 執行順序

```
ADR-002 ──────────────────────────────────> 完成
   │
   └─(Hard Gate)──> US-T01 ──────────────> 完成

US-10 ─────────────────────────────────────> 完成（與 ADR-002 並行）

US-FIX-01 ─────────────────────────────────> 完成（無依賴，可與其他 Story 並行）
```

- ADR-002 與 US-10 可同步啟動
- US-T01 必須等待 ADR-002 完成後才能開始（Hard Gate）
- US-FIX-01 無前置依賴，可在任何時間點啟動

---

## 風險

| 風險 | 可能性 | 影響 | 應對 |
|---|---|---|---|
| ADR-002 阻塞 US-T01：若 ADR-002 延遲完成，US-T01 無法啟動，Sprint Goal 部分落空 | 中 | 高 | ADR-002 設為 Sprint 第一優先，目標 Sprint Day 2 完成；若延遲超過 Day 3，US-T01 轉為 Carry-over |
| US-10 Tech Debt 嚴重度分類標準主觀性高，AC 驗收邊界不易量化 | 中 | 中 | AC1 已明確定義欄位名稱（ID/描述/引入 Story/解決 Story/嚴重度/建議解法/RICE/狀態）及趨勢判定規則，降低歧義空間 |
| US-10 [TECH-DEBT] 標記格式若與 developer-prompt.md 插入點不一致，造成 DoD 自檢混亂 | 低 | 中 | AC2 已明確以 `skills/sprint-execution/developer-prompt.md` 為主文件，SKILL.md 引用需標記插入點 |
| US-T01 掃描深度限制若設計不當，可能掃到非 Skill 的子目錄 | 低 | 低 | AC1 已明確限定 depth=1（`skills/` 下直接子目錄），排除多層嵌套 |
| US-FIX-01 跨 6 檔修改造成 Sprint 超載（6pt > 歷史 Velocity 4-5） | 高 | 中 | 每項 AC 修改範圍小（單一文件 section 級）；若超載，優先完成 AC-A1（DoD 統一）和 AC-A2（standup），其餘 Carry-over |

---

## Story 詳情

### ADR-002：測試框架技術選型

**背景與動機**

測試框架（US-T01 ~ US-T09）目前以 Shell Script 實作，但隨著 Sprint 4 US-T06 驗收完成、US-T01 進入 Sprint 5，框架技術選型決策缺失成為明顯風險：不同驗證腳本可能選用不同技術棧，導致維護一致性問題。ADR-002 作為硬性前置條件，需在 US-T01 啟動前完成。

**Acceptance Criteria**（QA 修正後版本，含類型標注）

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 文件格式 | 建立 `docs/adr/ADR-002.md`；格式與 ADR-001 一致（使用本專案 ADR 格式：標題、狀態、背景、決策問題、選項分析、決策、實作方式） |
| AC2 | [靜態] | 選項分析完整性 | 至少列出 2 個技術選項，每個選項含優缺點分析 |
| AC3 | [靜態] | 決策內容 | Decision 區段需含：選定工具名稱、選擇理由（≥1 點）、排除方案說明（≥1 個替代方案及排除原因） |
| AC4 | [靜態] | 實作指引 | 包含「實作方式」區段，說明測試框架的目錄結構或命名規範，使 US-T01 可據此實作 |

**RICE**：Reach 10 × Impact 3 × Confidence 90% ÷ Effort 0.3 = **90.0**
**MoSCoW**：Must（Hard Gate for US-T01）
**Size**：S
**Points**：1

---

### US-10：Tech Debt Registry

**User Story**
As a Developer, I want a structured Tech Debt Registry that captures and tracks technical debt across Sprints, so that the team can make informed decisions about when to address shortcuts and prevent debt accumulation from degrading system quality.

**修改目標**：`skills/sprint-execution/developer-prompt.md`（新增 Tech Debt 操作指引）；新建 `docs/km/Tech_Debt_Registry.md`；`skills/sprint-execution/SKILL.md` DoD 自檢區塊新增引用

**Acceptance Criteria**（QA 修正後版本，含類型標注）

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | Registry 格式定義 | `docs/km/Tech_Debt_Registry.md` 建立且包含標準表格格式；通過標準補充：表頭說明需含欄位定義（至少包含 ID/描述/引入 Story/解決 Story/嚴重度/建議解法/RICE/狀態）及趨勢判定規則 |
| AC2 | [靜態] | Developer Prompt 整合 | `skills/sprint-execution/developer-prompt.md` 為主文件，新增 Tech Debt 標記格式說明與 Registry 更新指引；`SKILL.md` 的 DoD 自檢區塊新增引用；標記插入點：DoD 自檢環節 |
| AC3 | [靜態] | Grooming 觸發 | Sprint Grooming 流程中包含 Tech Debt Review 步驟（掃描 Registry，標記逾期未解決項目） |
| AC4 | [靜態] | Story 關聯欄位 | Tech Debt 條目需記錄「引入 Story」與「解決 Story」，支援追蹤從發現到解決的完整生命週期；通過標準補充：欄位名稱固定為「引入 Story」與「解決 Story」 |
| AC5 | [動態] | 取捷徑場景觸發 | Developer Prompt 包含「何時應標記 Tech Debt」說明；(a) 列舉 3 種取捷徑場景：跳過測試、使用硬編碼、延後必要重構；(b) 補充「輸出的 [TECH-DEBT] 標記需符合 AC2 定義的格式」 |
| AC6 | [靜態] | Grooming 報告輸出 | Tech Debt Grooming 輸出包含：Active 條目清單、解決條目清單、本次變化量、趨勢判定；(a) 補充「趨勢判定依 AC7 定義的規則執行」；(b) 變化量定義為相對上一次 Grooming 的 Active 總數差值 |
| AC7 | [靜態] | 趨勢判定規則 | Registry 表頭說明中定義趨勢判定規則；通過標準補充：判定規則需包含連續 2 次 Grooming Active 增加定義為「增加中」、減少定義為「減少中」、不變定義為「穩定」；前 2 次 Grooming 輸出「資料不足」 |

**RICE**：Reach 8 × Impact 2 × Confidence 85% ÷ Effort 0.7 = **19.4**
**MoSCoW**：Must
**Size**：M
**Points**：2

---

### US-T01：Skill 完整性驗證

**User Story**
As a Developer, I want a script that verifies every skill directory has a valid SKILL.md with required frontmatter, so that I can catch missing or malformed skill definitions before pushing.

**修改目標**：新建 Skill 完整性驗證腳本（路徑由 Developer 決定，建議 `scripts/validate-skills.sh` 或整合至現有驗證框架）

**Acceptance Criteria**（QA 修正後版本，含類型標注）

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 掃描範圍 | 掃描 `skills/` 下所有直接子目錄（depth=1），驗證每個子目錄都有 `SKILL.md`；腳本輸出掃描到的目錄清單，數量與 `skills/` 直接子目錄實際數一致 |
| AC2 | [靜態] | Frontmatter 驗證 | 驗證每個 SKILL.md 的 frontmatter 包含 `name` 和 `description` 欄位 |
| AC3 | [靜態] | Name 一致性 | 驗證 `name` 值與目錄名稱一致；比對為大小寫敏感的完全字串比對 |
| AC4 | [靜態] | 空目錄處理 | 驗證空目錄報錯，而非靜默略過 |
| AC5 | [靜態] | Exit code | exit code 0 = 通過，非 0 = 失敗 |

**RICE**：Reach 10 × Impact 3 × Confidence 90% ÷ Effort 0.5 = **54.0**
**MoSCoW**：Must
**ADR**：ADR-002（Hard Gate 依賴）
**Size**：S
**Points**：1

---

### US-FIX-01：修復審計發現

**背景與動機**

QA 審計發現框架存在 16 項監控缺口（3 CRITICAL / 6 HIGH / 6 MEDIUM / 1 LOW）。本 Story 修復其中 13 項（文件修正類），剩餘 3 項（Hard Gate 機制類）歸入 US-FIX-02（Sprint 6，依賴 ADR-003）。ADR-003 已完成閘門介入模式的技術決策。

**修改目標**：`skills/scrum-master/SKILL.md`、`skills/sprint-execution/SKILL.md`、`commands/standup.md`、`skills/health-check/SKILL.md`、`skills/sprint-planning/SKILL.md`、`skills/sprint-review/SKILL.md`

**Acceptance Criteria**

| # | 類型 | 對應發現 | 條件 | 通過標準 |
|---|------|----------|------|----------|
| AC-A1 | [靜態] | C-001, H-001, M-001 | DoD 統一 | `scrum-master/SKILL.md` 第 8 節與 `sprint-execution/SKILL.md` 第 5 節 DoD 統一為 7 層（功能、測試、安全、文件、設定、度量、反回歸），兩份文件的 DoD 表格內容完全一致 |
| AC-A2 | [靜態] | C-002, H-002, H-003 | standup Issues 掃描 | `commands/standup.md` 新增「GitHub Issues 掃描」區塊：執行 `gh issue list` 掃描 open issues，顯示數量與摘要；區塊說明包含掃描範圍限定（僅掃描本 repo open issues，不含 PR） |
| AC-A3 | [靜態] | H-004, M-002 | health-check 擴充 | `skills/health-check/SKILL.md` 掃描清單新增 `docs/prd/ROADMAP.md` 與 `docs/km/Metrics_Log.md`；ROADMAP 同步檢查：驗證 ROADMAP 中的當前版本與 `plugin.json` 版號一致 |
| AC-A4 | [靜態] | M-003, L-001 | sprint-planning 修復 | `skills/sprint-planning/SKILL.md` 第 2 節 checklist 新增「讀取 ROADMAP.md 確認當前里程碑」步驟；第 2 節與第 6 節的步驟順序與角色分配保持一致 |
| AC-A5 | [靜態] | H-005, M-004, M-005 | sprint-review 修復 | `skills/sprint-review/SKILL.md` 產出文件表格新增 `docs/prd/ROADMAP.md` 更新項；執行檢查清單新增 ROADMAP 已更新 checkbox；Action Items 驗收流程新增 `gh issue close` 步驟說明 |

**RICE**：Reach 10 × Impact 3 × Confidence 90% ÷ Effort 0.3 = **90.0**
**MoSCoW**：Must
**Size**：M
**Points**：2

---

## Retro Action Items 處理

| # | Action（原始） | 本 Sprint 處理方式 | 狀態 |
|---|---------------|-------------------|------|
| Sprint 4 A1 | 框架工作計點：US-T 類 Story 是否應計入 Velocity | PO 決策：維持現有計點體系，US-T 佔比控制 ≤ 25%（本 Sprint US-T01 1pt / 4pt = 25%，符合上限） | Closed（Sprint 5 Planning） |
| Sprint 4 A2 | Metrics_Log 列入 DoD | scrum-master SKILL.md 第 8 節 DoD 已新增「度量」層次，決策已落地 | Closed（Sprint 4 Review 驗收） |

> **備注（A1 決策說明）**：US-T 類 Story 計入 Velocity 的理由是其交付物（驗證腳本）具有明確商業價值（阻斷缺陷擴散），與業務 Story 性質相當。佔比上限 25% 確保 Sprint 資源不過度傾斜於技術基礎設施。

---

## 驗收標準

### ADR-002：測試框架技術選型

- [ ] ADR-002：`docs/adr/ADR-002.md` 建立，格式與 ADR-001 一致（標題、狀態、背景、決策問題、選項分析、決策、實作方式）（AC1 通過）
- [ ] ADR-002：至少列出 2 個技術選項，每個選項含優缺點分析（AC2 通過）
- [ ] ADR-002：Decision 區段含選定工具名稱、選擇理由（≥1 點）、排除方案說明（≥1 個替代方案及排除原因）（AC3 通過）
- [ ] ADR-002：包含「實作方式」區段，說明目錄結構或命名規範（AC4 通過）

### US-10：Tech Debt Registry

- [ ] US-10：`docs/km/Tech_Debt_Registry.md` 建立，表頭說明含欄位定義（ID/描述/引入 Story/解決 Story/嚴重度/建議解法/RICE/狀態）及趨勢判定規則（AC1 通過）
- [ ] US-10：`skills/sprint-execution/developer-prompt.md` 新增 Tech Debt 標記格式說明與 Registry 更新指引（AC2 主文件通過）
- [ ] US-10：`skills/sprint-execution/SKILL.md` DoD 自檢區塊新增引用，插入點標記為 DoD 自檢環節（AC2 引用通過）
- [ ] US-10：Sprint Grooming 流程含 Tech Debt Review 步驟，可掃描 Registry 並標記逾期未解決項目（AC3 通過）
- [ ] US-10：Tech Debt 條目欄位名稱固定為「引入 Story」與「解決 Story」（AC4 通過）
- [ ] US-10：Developer Prompt 列舉 3 種取捷徑場景（跳過測試、使用硬編碼、延後必要重構），且 [TECH-DEBT] 標記格式符合 AC2 定義（AC5 通過，[動態]）
- [ ] US-10：Grooming 報告輸出含 Active 清單、解決清單、相對上一次 Grooming 的 Active 總數差值、趨勢判定（AC6 通過）
- [ ] US-10：趨勢判定規則包含「連續 2 次增加 → 增加中」、「連續 2 次減少 → 減少中」、「不變 → 穩定」、「前 2 次 → 資料不足」（AC7 通過）

### US-T01：Skill 完整性驗證

- [ ] US-T01：掃描 `skills/` 直接子目錄（depth=1），輸出目錄清單，數量與實際一致（AC1 通過）
- [ ] US-T01：SKILL.md frontmatter 驗證含 `name` 和 `description` 欄位（AC2 通過）
- [ ] US-T01：`name` 值與目錄名稱的比對為大小寫敏感的完全字串比對（AC3 通過）
- [ ] US-T01：空目錄報錯，不靜默略過（AC4 通過）
- [ ] US-T01：exit code 0 全通過，非 0 存在失敗（AC5 通過）
- [ ] 既有功能不受影響（反回歸：sprint-execution、sprint-grooming 其餘流程、scrum-master 路由）

### US-FIX-01：修復審計發現

- [ ] US-FIX-01：scrum-master SKILL.md 與 sprint-execution SKILL.md DoD 統一為 7 層，兩份文件內容完全一致（AC-A1 通過）
- [ ] US-FIX-01：commands/standup.md 新增 GitHub Issues 掃描區塊，含 `gh issue list` 執行與範圍說明（AC-A2 通過）
- [ ] US-FIX-01：health-check SKILL.md 掃描清單含 ROADMAP.md 與 Metrics_Log.md，ROADMAP 版號同步檢查（AC-A3 通過）
- [ ] US-FIX-01：sprint-planning SKILL.md 第 2 節含 ROADMAP 讀取步驟，第 2 節與第 6 節一致（AC-A4 通過）
- [ ] US-FIX-01：sprint-review SKILL.md 產出文件含 ROADMAP，checklist 含 ROADMAP checkbox，Action Items 含 Issue close 步驟（AC-A5 通過）
- [ ] 既有功能不受影響（反回歸：standup 原有區塊、health-check 原有掃描、sprint-planning 原有流程）
