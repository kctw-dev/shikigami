# Sprint 6

> 週期：2026-03-01 ~ 2026-03-08
> 狀態：完成
> 專案等級：low（完全自治）

---

## Sprint Goal

**「建立 Hard Gate Checklist 機制（US-FIX-02），擴展測試框架覆蓋（US-T02、US-T03），並清零 Sprint 5 Retro 技術債」**

Retro #7 和 #8 清除 Sprint 5 遺留的 DoD 不一致與 QA 審查範圍模糊問題，恢復框架文件一致性。US-T02 和 US-T03 延續 ADR-002 測試框架擴展計畫，覆蓋 Agent 完整性與 JSON Schema 驗證。US-FIX-02 以 ADR-003（Accepted）為前置，實作 Framework Document Change、Out-of-Sprint Change 與 Ceremony Integrity 三個 Hard Gate，將流程合規性從規則層提升至機制層。

對應 ROADMAP：v0.3.0「知識沉澱」框架品質強化 + 測試框架擴展第二階段。

---

## Sprint Backlog

| Story | 任務 | 負責 | 狀態 |
|---|---|---|---|
| Retro #7：DoD 第 8 層同步 | `skills/scrum-master/SKILL.md` 第 8 節 DoD 補入「技術債」層（第 8 層），與 `skills/sprint-execution/SKILL.md` 對齊，兩份文件 DoD 表格內容完全一致 | Developer | 完成 |
| Retro #8：QA Review 範圍界定 | `skills/sprint-execution/quality-reviewer-prompt.md` 新增「僅審查本次 Story 變更範圍，既存問題不計入 FAIL」指引；問題分類標注改為「應分類」 | QA | 完成 |
| US-T02：Agent 完整性驗證 | 新建 Agent 完整性驗證腳本（建議 `scripts/validate-agents.sh`），掃描 `agents/` 下所有 `.md` 檔案，驗證 frontmatter 合規（含 model hardcode whitelist） | Developer + QA | 完成 |
| US-T03：JSON Schema 驗證 | 新建 JSON Schema 驗證腳本（建議 `scripts/validate-json.sh`），驗證 `plugin.json` 與 `marketplace.json` 必填欄位、version semver 格式、plugin.json 欄位白名單 | Developer + QA | 完成 |
| US-FIX-02：Hard Gate Checklist 機制 | `skills/scrum-master/SKILL.md` 新增 Preflight Check 區段與三個 Hard Gate（Framework Document Change、Out-of-Sprint Change、Ceremony Integrity），與 ADR-003 實作方式一致 | Developer + QA | 完成 |

---

## 工作容量

- Retro #7：< 0.1 Sprint（S，單一文件單一節次補行，文字修改）
- Retro #8：< 0.1 Sprint（S，單一文件新增指引段落，無架構設計）
- US-T02：~0.2 Sprint（S，腳本驗證，路徑清晰，ADR-002 技術棧已定）
- US-T03：~0.35 Sprint（M，JSON 解析複雜度較 S 高，AC4 whitelist 邏輯需實作）
- US-FIX-02：~0.7 Sprint（L，跨三個 Gate 場景，結構性新增，自我引用風險需管控）
- 合計：~1.35 Sprint（8 points，實質開發負荷約 6pt，Retro #7/#8 不計入有效工時）

**Points 換算**（T-shirt Sizing）：Retro #7 = 1pt（S）、Retro #8 = 1pt（S）、US-T02 = 1pt（S）、US-T03 = 2pt（M）、US-FIX-02 = 3pt（L）= 合計 **8 points**

> **容量決策說明**：歷史 Velocity 為 5-6pt。Retro #7 和 #8 為小型文件修改（實際工時 < 1hr），實質開發負荷約 6pt，符合歷史 Velocity 上緣。US-FIX-02 設為最後執行，如有超載可獨立 Carry-over，不影響其他 Stories 的交付。

> **T-shirt Sizing 參考**：
> - S（< 0.3 Sprint）：單一模組小改動，路徑清晰
> - M（0.3-0.7 Sprint）：跨模組，需設計但風險可控
> - L（> 0.7 Sprint）：跨層、新架構、高不確定性

---

## 執行順序

```
Retro #7 ─────────────────────────────────> 完成（無依賴）

Retro #8 ─────────────────────────────────> 完成（無依賴，可與 #7 並行）

US-T02 ────────────────────────────────────> 完成（無依賴，Retro 完成後啟動）

US-T03 ────────────────────────────────────> 完成（無依賴，與 US-T02 可並行）

US-FIX-02 ─────────────────────────────────> 完成（前置：ADR-003 Accepted，已滿足）
```

- Retro #7 與 Retro #8 可同步啟動，目標 Sprint Day 1 完成
- US-T02 與 US-T03 無相互依賴，可並行；建議於 Day 2-3 完成
- US-FIX-02 前置條件（ADR-003 Accepted）已滿足，可於 US-T02/T03 完成後啟動
- Architect 建議執行順序：Retro #7 → Retro #8 → US-T02 → US-T03 → US-FIX-02

---

## 風險

| 風險 | 可能性 | 影響 | 應對 |
|---|---|---|---|
| US-FIX-02 自我引用風險：修改 scrum-master SKILL.md 本身即觸發 Framework Document Change Audit，若 Preflight Check 邏輯尚未完成，稽核機制處於未激活狀態 | 中 | 中 | US-FIX-02 的 AC-B3 明確要求 Preflight Check 與 ADR-003 一致；Developer 在新增 Preflight Check 區段時須同步激活機制，而非分兩步完成；QA 在 Code Quality Review 時驗證自我引用情境 |
| US-T03 AC4 whitelist 維護問題：plugin.json 允許欄位白名單若未來需要擴充，腳本需同步更新 | 低 | 低 | 白名單定義於腳本頭部常數，修改集中化；AC5 已明確 WARNING 不阻塞 exit code，擴充成本可控 |
| US-FIX-02 超載造成 Carry-over：L/3pt 為本 Sprint 最大單一 Story，若 Retro 和測試框架 Stories 耗時超出預期，US-FIX-02 時間窗口壓縮 | 中 | 低 | US-FIX-02 設為最後執行；Carry-over 至 Sprint 7 不影響其他 Stories；ADR-003 前置已滿足，下個 Sprint 直接啟動無額外成本 |
| US-T02 AC3 model whitelist hardcode 過時：若平台新增 model 名稱，腳本需更新 | 低 | 低 | PO 決策：model 名稱變化極低頻，hardcode 優先於 configurable；平台 model 變更時 Grooming 觸發腳本更新，納入正常維護週期 |
| 8pt 超出歷史 Velocity 上緣：若所有 Stories 實際複雜度高於估計，Sprint 全數完成壓力大 | 低 | 中 | Retro #7/#8 實際工時 < 1hr，確保前 2pt 高速完成；US-T02 路徑清晰（ADR-002 技術棧已定）；容量緩衝透過執行順序管控（後期 Stories 可 Carry-over） |

---

## Story 詳情

### Retro #7：DoD 第 8 層同步

**背景與動機**

Sprint 5 US-10 新增技術債層（第 8 層）至 `skills/sprint-execution/SKILL.md`，但未同步更新 `skills/scrum-master/SKILL.md`，導致兩份 DoD 定義不一致。Stakeholder 於 Sprint 5 Review 指出此問題，建立 GitHub Issue #7。

**修改目標**：`skills/scrum-master/SKILL.md`（第 8 節 DoD 補入技術債層）

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | DoD 第 8 層補入 | `skills/scrum-master/SKILL.md` 第 8 節 DoD 表格新增「技術債」層，內容與 `skills/sprint-execution/SKILL.md` 對應行一致（欄位名稱、說明文字完全相同） |
| AC2 | [靜態] | 兩份文件一致性 | `skills/scrum-master/SKILL.md` 與 `skills/sprint-execution/SKILL.md` 的 DoD 表格層數相同（8 層），表格內容逐行完全一致 |

**RICE**：Reach 10 × Impact 2 × Confidence 100% ÷ Effort 0.1 = **200.0**
**MoSCoW**：Must（Retro Action Item，技術債清零）
**GitHub Issue**：#7
**Size**：S
**Points**：1

---

### Retro #8：QA Review 範圍界定

**背景與動機**

Sprint 5 US-FIX-01 Code Quality Review 3 項發現中有 2 項為 false positive（QA 讀取過時資料、將既存問題歸入當前 Story）。根因是 `quality-reviewer-prompt.md` 未明確界定審查範圍，QA 將非本次變更的既存問題也納入 FAIL。

**修改目標**：`skills/sprint-execution/quality-reviewer-prompt.md`（新增審查範圍界定指引）

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 範圍界定條款 | `skills/sprint-execution/quality-reviewer-prompt.md` 新增「審查範圍界定」條款：明確說明「僅審查本次 Story 變更範圍內的修改；既存問題（本 Story 開始前已存在的缺陷）不計入 FAIL，應分類為觀察記錄，於下次 Grooming 評估是否建立獨立 Story」 |
| AC2 | [靜態] | 「應分類」用語 | 範圍界定條款使用「應分類」而非「可列」，確保用語具規範性而非選擇性 |

**RICE**：Reach 10 × Impact 2 × Confidence 100% ÷ Effort 0.1 = **200.0**
**MoSCoW**：Must（Retro Action Item，QA 流程修復）
**GitHub Issue**：#8
**Size**：S
**Points**：1

---

### US-T02：Agent 完整性驗證

**User Story**
As a Developer, I want a script that verifies every agent file has correct frontmatter fields, so that plugin installation doesn't fail silently.

**修改目標**：新建 Agent 完整性驗證腳本（路徑由 Developer 決定，建議 `scripts/validate-agents.sh` 或整合至現有驗證框架）

**Acceptance Criteria**（含類型標注）

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 掃描範圍 | 掃描 `agents/` 下所有 `.md` 檔案；腳本輸出掃描到的檔案清單，數量與 `agents/` 目錄實際 `.md` 檔案數一致 |
| AC2 | [靜態] | Frontmatter 必填欄位 | 驗證每個 agent `.md` 的 frontmatter 包含 `name`、`description`、`model` 三個欄位；任一欄位缺失則 ERROR |
| AC3 | [靜態] | model 值白名單（hardcode） | 驗證 `model` 值為合法值之一：`sonnet`、`haiku`、`opus`（hardcode，大小寫敏感完全字串比對）；不在白名單內的值則 ERROR |
| AC4 | [靜態] | description 非空 | 驗證 `description` 欄位存在且值非空字串；空字串或僅含空白字元則 ERROR |
| AC5 | [靜態] | Exit code | exit code 0 = 全部通過，非 0 = 存在至少一個 ERROR |

**RICE**：Reach 10 × Impact 3 × Confidence 90% ÷ Effort 0.5 = **54.0**
**MoSCoW**：Must
**ADR**：ADR-002（Pure Bash + shared library）
**Size**：S
**Points**：1

---

### US-T03：JSON Schema 驗證

**User Story**
As a Developer, I want automated validation of plugin.json and marketplace.json, so that malformed manifests are caught before users try to install.

**修改目標**：新建 JSON Schema 驗證腳本（路徑由 Developer 決定，建議 `scripts/validate-json.sh` 或整合至現有驗證框架）

**Acceptance Criteria**（QA 修訂後版本，含類型標注）

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | plugin.json 必填欄位 | 驗證 `plugin.json` 包含必填欄位：`name`、`version`、`description`、`author`；任一欄位缺失則 ERROR |
| AC2 | [靜態] | marketplace.json 必填欄位 | 驗證 `marketplace.json` 包含必填欄位：`name`、`plugins` 陣列；任一欄位缺失則 ERROR |
| AC3 | [靜態] | version semver 格式 | 驗證 `version` 格式符合 semver（`major.minor.patch`，三段純數字，以 `.` 分隔）；格式不符則 ERROR |
| AC4 | [靜態] | plugin.json 欄位白名單 | 定義 `plugin.json` 允許欄位白名單：`name`、`version`、`description`、`author`、`homepage`、`license`、`tags`、`minVersion`；白名單以外的欄位觸發 WARNING（非 ERROR），腳本繼續執行；WARNING 不影響 exit code |
| AC5 | [靜態] | Exit code | exit code 0 = 全部 AC1-AC4 無 ERROR；非 0 = 存在至少一個 ERROR；WARNING 不影響 exit code |

**AC4 決策說明**：原 AC4「不包含多餘路徑欄位」定義模糊，QA 無法量化「多餘」邊界。改為 whitelist approach：明確列舉允許欄位，額外欄位降級為 WARNING 以避免未來擴充時 false positive 增加。

**RICE**：Reach 10 × Impact 2 × Confidence 90% ÷ Effort 0.7 = **25.7**（Architect 調整 Size M/2pt，Effort 從 0.5 上調至 0.7）
**MoSCoW**：Must
**ADR**：ADR-002（Pure Bash + shared library）
**Size**：M（Architect 上調，原 S）
**Points**：2

---

### US-FIX-02：Hard Gate Checklist 機制

**User Story**
As a Scrum Master, I want structural Hard Gate checklists at framework document changes, out-of-sprint changes, and ceremony completion, so that process compliance is enforced by mechanism rather than by memory.

**前置條件**：ADR-003（已完成，Accepted）

**修改目標**：`skills/scrum-master/SKILL.md`（新增 Preflight Check 區段與三個 Hard Gate 定義）

**Acceptance Criteria**（QA 修訂後版本，含類型標注）

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC-B1 | [靜態] | 前置條件確認 | `docs/adr/ADR-003.md` 存在且狀態欄位值為 Accepted |
| AC-B2 | [靜態] | Preflight Check 區段 | `skills/scrum-master/SKILL.md` 新增「Preflight Check」區段，定義框架文件修改前的強制稽核；區段包含 4 項二元 checklist：(1) 修改目的對應 Sprint Backlog 中的某個 Story ID；(2) 修改範圍在該 Story 的 AC 所涵蓋文件範圍內；(3) 修改前已讀取目標文件的當前版本；(4) 修改後執行 health-check 確認結構完整性；觸發條件：`skills/`、`commands/`、`agents/` 下任一 `.md` 檔案修改前；結果判定：全部 Pass 方可繼續，任一 Fail 則阻塞 |
| AC-B3 | [靜態] | Framework Document Change Audit Hard Gate | Preflight Check 與 ADR-003「Framework Document Change Audit」實作方式一致：觸發條件、4 項 checklist 內容、Pass/Fail 判定邏輯三項完全對應；ADR-003 為此 AC 的正式規格來源 |
| AC-B4a | [靜態] | Out-of-Sprint Change 偵測邏輯 | `skills/scrum-master/SKILL.md` 描述 Out-of-Sprint Change Hard Gate 偵測邏輯：Sprint 期間偵測到 Sprint Backlog 無對應項目的框架文件修改時，正常路徑要求修改對應現有 Backlog Story；若無對應 Story，必須先由 PO 建立緊急 Story 並核准後方可繼續修改 |
| AC-B4b | [靜態] | Out-of-Sprint Change 緊急例外路徑 | `skills/scrum-master/SKILL.md` 描述緊急例外路徑（僅限安全漏洞或框架破損）：(1) commit message 標注 `[EMERGENCY]` 並記錄緊急變更原因；(2) 48 小時內完成事後稽核；(3) 於下次 Sprint Review 將此事件列入 Retrospective Problem 追蹤 |
| AC-B5 | [靜態] | Ceremony Integrity Audit Hard Gate | `skills/scrum-master/SKILL.md` 的 Sprint Planning 與 Sprint Review 儀式結束前各有獨立 checklist；Sprint Planning 必要條件：Sprint Goal 已定義、Sprint Backlog 已選取且完成 Story 點數估算、所有 Story 有明確 AC、GitHub open issues 已掃描（4 項）；Sprint Review 必要條件：PO Demo 已完成、Stakeholder 已確認、Retrospective_Log.md 已更新、Action Items 已建立、ROADMAP.md 已更新（5 項）；任一項未完成則儀式不得宣告結束 |

**RICE**：Reach 10 × Impact 3 × Confidence 90% ÷ Effort 1.0 = **27.0**
**MoSCoW**：Must
**ADR**：ADR-003（Hard Gate）
**Size**：L
**Points**：3

---

## Retro Action Items 處理

| # | Action（原始） | 本 Sprint 處理方式 | 狀態 |
|---|---------------|-------------------|------|
| Sprint 5 #1（Issue #7） | DoD 第 8 層同步：scrum-master SKILL.md 補入技術債層 | Retro #7 納入 Sprint 6，作為獨立 1pt Story 交付 | Done |
| Sprint 5 #2（Issue #8） | QA Review 範圍界定：quality-reviewer-prompt.md 新增範圍界定條款 | Retro #8 納入 Sprint 6，作為獨立 1pt Story 交付 | Done |

---

## 驗收標準

### Retro #7：DoD 第 8 層同步

- [ ] Retro #7：`skills/scrum-master/SKILL.md` 第 8 節 DoD 新增技術債層，與 `skills/sprint-execution/SKILL.md` 對應行內容完全一致（AC1 通過）
- [ ] Retro #7：兩份文件 DoD 層數相同（8 層），逐行一致（AC2 通過）
- [ ] GitHub Issue #7 關閉

### Retro #8：QA Review 範圍界定

- [ ] Retro #8：`skills/sprint-execution/quality-reviewer-prompt.md` 新增審查範圍界定條款（AC1 通過）
- [ ] Retro #8：範圍界定條款使用「應分類」而非「可列」（AC2 通過）
- [ ] GitHub Issue #8 關閉

### US-T02：Agent 完整性驗證

- [ ] US-T02：掃描 `agents/` 所有 `.md` 檔案，輸出清單，數量與目錄實際 `.md` 檔案數一致（AC1 通過）
- [ ] US-T02：frontmatter 驗證含 `name`、`description`、`model` 三個欄位（AC2 通過）
- [ ] US-T02：`model` 值為 `sonnet`/`haiku`/`opus` 之一，大小寫敏感完全比對（AC3 通過）
- [ ] US-T02：`description` 欄位存在且非空字串（AC4 通過）
- [ ] US-T02：exit code 0 全通過，非 0 存在 ERROR（AC5 通過）
- [ ] 既有功能不受影響（反回歸：validate-skills.sh、validate-commands.sh 其他腳本正常）

### US-T03：JSON Schema 驗證

- [ ] US-T03：`plugin.json` 必填欄位驗證（name、version、description、author），缺失則 ERROR（AC1 通過）
- [ ] US-T03：`marketplace.json` 必填欄位驗證（name、plugins 陣列），缺失則 ERROR（AC2 通過）
- [ ] US-T03：`version` 格式符合 semver（major.minor.patch 三段純數字），格式不符則 ERROR（AC3 通過）
- [ ] US-T03：`plugin.json` 白名單外欄位觸發 WARNING，不觸發 ERROR，exit code 不受影響（AC4 通過）
- [ ] US-T03：exit code 0 = 無 ERROR；非 0 = 存在 ERROR；WARNING 不影響 exit code（AC5 通過）
- [ ] 既有功能不受影響（反回歸：plugin.json 正常格式、marketplace.json 正常格式驗證通過）

### US-FIX-02：Hard Gate Checklist 機制

- [ ] US-FIX-02：`docs/adr/ADR-003.md` 存在且狀態為 Accepted（AC-B1 通過）
- [ ] US-FIX-02：`skills/scrum-master/SKILL.md` 新增 Preflight Check 區段，含 4 項二元 checklist（AC-B2 通過）
- [ ] US-FIX-02：Preflight Check 的觸發條件、4 項 checklist、Pass/Fail 判定與 ADR-003 Framework Document Change Audit 完全對應（AC-B3 通過）
- [ ] US-FIX-02：`skills/scrum-master/SKILL.md` 含 Out-of-Sprint Change 正常路徑偵測邏輯（需對應 Story ID，無則建立緊急 Story）（AC-B4a 通過）
- [ ] US-FIX-02：`skills/scrum-master/SKILL.md` 含緊急例外路徑（[EMERGENCY] 標注 + 48hr 稽核 + Sprint Review 追蹤）（AC-B4b 通過）
- [ ] US-FIX-02：Sprint Planning checklist 4 項全數列出，Sprint Review checklist 5 項全數列出，任一未完成則儀式不得結束（AC-B5 通過）
- [ ] 既有功能不受影響（反回歸：scrum-master 原有路由邏輯、sprint-planning、sprint-review 原有流程）
