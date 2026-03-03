# Sprint 25

**狀態**：進行中
**期間**：2026-03-30 ~ 2026-04-05
**Sprint Goal**：在 M5 穩定化收尾階段，執行 M5 完成條件終審、Tech Debt Registry 清理、及 OpenCode POC 可行性調查，為 v1.0.0 前置條件提供明確評估依據
**總計**：3 Stories / 4 Points

---

## Sprint Backlog

| Story ID | 標題 | Size | Points | 狀態 |
|----------|------|------|--------|------|
| US-43 | M5 完成條件終審 + Issues #3/#4/#5 結論決策 | M | 2 | 完成 |
| US-44 | Tech Debt Grooming Sprint 25 + TD-001 降級決策 | S | 1 | 完成 |
| US-45 | OpenCode POC 可行性調查 | S | 1 | 完成 |

**Sprint 容量**：4 Points

---

## Story 詳細 AC

---

### US-43：M5 完成條件終審 + Issues #3/#4/#5 結論決策

**來源**：ROADMAP M5 穩定化 / v1.0.0 前置條件
**Size**：M / 2 Points
**Owner**：Developer

**User Story**
As a Product Owner, I want a formal completion assessment of Milestone 5 covering all three completion criteria and definitive conclusions for Issues #3/#4/#5, so that the team has a clear, documented basis for declaring M5 complete and advancing toward v1.0.0.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | M5 完成條件逐項評估文件建立 | 建立 `docs/prd/M5_COMPLETION_ASSESSMENT.md`，逐項評估三個完成條件：(a) 至少 1 位外部使用者完成安裝並走完一個 Sprint；(b) Issues #3/#4 有明確結論（引用 US-17 調查報告）；(c) Issue #5 有明確結論（上架計畫或延後決策） |
| AC2 | [靜態] | ROADMAP.md M5 區塊更新 + Issues #3/#4 comment | `docs/prd/ROADMAP.md` 更新 M5 區塊，在 US-17 條目後新增平台優先排序決策記錄（Sprint 25）；Issues #3/#4 各新增包含決策摘要的 comment |
| AC3 | [靜態] | Issue #5 PO 立場回覆 + ROADMAP v1.0.0 前提狀態更新 | Issue #5 收到代表 PO 立場的回覆，說明 v1.0.0 前置條件進度與上架時間線評估；ROADMAP.md v1.0.0 區段更新前提狀態 |
| AC4 | [靜態] | M5 達成結論明確標記 | `M5_COMPLETION_ASSESSMENT.md` 末尾明確標記：「M5 已達成完成條件」或「M5 尚有 N 項未達成（附具體缺口清單）」；若已達成，ROADMAP.md M5 標題標注「完成（Sprint 25）」 |

---

### US-44：Tech Debt Grooming Sprint 25 + TD-001 降級決策

**來源**：Sprint 23 建立 Tech_Debt_Registry.md（TD-001、TD-002）/ Sprint 25 首次 Grooming
**Size**：S / 1 Point
**Owner**：Developer

**User Story**
As a Product Owner, I want the first Tech Debt Registry grooming session completed in Sprint 25, with a definitive status ruling on TD-001 and a MoSCoW re-evaluation of TD-002, so that the registry accurately reflects actionable technical debt before v1.0.0.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | Grooming #1 記錄新增 | `docs/km/Tech_Debt_Registry.md` 的 Grooming 歷史區塊新增「Grooming #1 — 日期（Sprint 25）」記錄，含 Active 條目清單、本次解決條目、趨勢判定 |
| AC2 | [靜態] | TD-001 狀態裁定 | TD-001 已標注 [EXAMPLE]，更新狀態為 Accepted 並於 Grooming #1 記錄中說明裁定理由（Shikigami 無實際使用者認證模組）；若調查後判定為真實技術債，維持 Active 並補充解決 Story 建議 |
| AC3 | [靜態] | TD-002 MoSCoW 重評記錄 | TD-002 MoSCoW 重評結果記錄於 Grooming #1 及 Registry 表格：若 v1.0.0 前不需解決，更新 MoSCoW 為 Won't 附理由；若需解決，新建 Backlog Story |
| AC4 | [靜態] | 趨勢判定輸出 | Grooming #1 記錄包含趨勢判定（首次 Grooming 依規則輸出「資料不足」） |

---

### US-45：OpenCode POC 可行性調查

**來源**：Retro #42 / Issue #3 / US-17 調查報告後續行動
**Size**：S / 1 Point
**Owner**：Developer

**User Story**
As a Product Owner, I want a structured OpenCode POC feasibility investigation that produces a clear Go/No-Go decision with supporting rationale, so that the platform expansion roadmap has a concrete data point for prioritization.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | OPENCODE_POC.md 建立 | 建立 `docs/km/OPENCODE_POC.md`，標頭含調查日期、執行者、引用 US-17 結論（連結 `docs/km/MULTI_PLATFORM_SURVEY.md`）；明確定義 POC 驗證範圍 |
| AC2 | [靜態] | Go / No-Go 決策區塊 | `OPENCODE_POC.md` 包含「Go / No-Go」決策區塊，附決策理由與關鍵技術阻礙（若有）；若 Go 列出 MVP 整合路徑；若 No-Go 說明根本性阻礙 |
| AC3a | [靜態] | Issue #3 引用 | `OPENCODE_POC.md` 內文包含 Issue #3 超連結或引用 |
| AC3b | [靜態] | Issue #3 comment 更新 | Story 完成後由執行者在 Issue #3 新增 comment，說明 OPENCODE_POC.md 建立完成及 Go/No-Go 結論摘要 |

---

## 平行分群（Architect 建議）

### 全部平行執行

| Story | 負責人 | 說明 |
|-------|--------|------|
| US-43 | Developer | M5 完成條件終審，doc-only，無檔案衝突 |
| US-44 | Developer | Tech Debt Grooming，doc-only，無檔案衝突 |
| US-45 | Developer | OpenCode POC 調查，doc-only，無檔案衝突 |

**執行順序**：US-43、US-44、US-45 可完全平行執行（三者均為 doc-only，無同檔案競態條件）

---

## 工作容量

| 項目 | 數值 |
|------|------|
| Sprint 期間 | 2026-03-30 ~ 2026-04-05（7 天） |
| 總 Stories | 3 |
| 總 Points | 4 |
| 平行分群 | 全部平行（無依賴） |

---

## ADR 觸發清單

| Story | ADR 編號 | 說明 |
|-------|----------|------|
| US-43 | 無新 ADR | 文件評估與 Issue 回覆，無架構決策變更 |
| US-44 | 無新 ADR | Tech Debt Registry Grooming，純文件更新 |
| US-45 | 無新 ADR | POC 可行性調查報告，無架構決策變更 |

**本 Sprint 無新 ADR**。

---

## Sprint Planning 簽核

- **PO Round 1**：完成（Story 選取：US-43、US-44、US-45；初版 AC；Sprint Goal 確定；總計 4pt）
- **Architect Round 1**：完成（US-43 M/2pt 確認；US-44 S/1pt 確認；US-45 S/1pt 確認；三者全部平行可執行；無 ADR 觸發；全部 doc-only）
- **QA Round 1**：完成（三個 Stories 均通過可測試性評估；AC 精化：US-43 AC1 三個完成條件明確化、AC4 達成/未達成兩路徑分支明確化；US-44 AC2 [EXAMPLE] 標注與裁定規則明確化、AC4 首次 Grooming 趨勢判定規則明確化；US-45 AC3 拆分為 AC3a/AC3b 靜態與動態分離）
- **PO Round 2**：完成（Architect sizing 修正與 QA AC 精化整合完成；所有 Stories 確認為 doc-only；平行分群確認；Sprint 文件建立確認）
