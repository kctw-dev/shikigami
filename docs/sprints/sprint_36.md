# Sprint 36

**狀態**：Planning 完成
**期間**：2026-04-27 ~ 2026-05-03
**Sprint Goal**：完成 ADR-010 生命週期閉環 — 補全 sprint-review Issue 狀態回寫、初始化 GitHub Issues Backlog，讓 Backlog Source of Truth 遷移進入「全流程可用」狀態
**總計**：3 Stories / 4 Points

---

## Sprint Backlog

| Story ID | 標題 | Size | Points | QA doc-only 判定 | 狀態 |
|----------|------|------|--------|-----------------|------|
| US-74 | ADR-010 後置 — sprint-review SKILL.md Story 完成後 Issue 狀態回寫對齊 | S | 1 | Yes | 待執行 |
| US-75 | ADR-010 Backlog 初始化 — 將現有候選 Stories 建立為 GitHub Issues | M | 2 | No | 待執行 |
| US-76 | Tech Debt Grooming Sprint 36 — TD-002 評估 + ADR-010 遷移後新技術債掃描 | S | 1 | Yes | 待執行 |

**Sprint 容量**：4 Points

---

## Story 詳細 AC

---

### US-74：ADR-010 後置 — sprint-review SKILL.md Story 完成後 Issue 狀態回寫對齊

**來源**：ADR-010 生命週期閉環 — sprint-review 流程補全
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：Yes
**ADR 參考**：ADR-010（§對 skills/sprint-review/SKILL.md 的影響）
**ADR-003 Checklist**：必須執行（修改 skills/ 目錄）

**User Story**

As a Developer completing the ADR-010 lifecycle, I want the sprint-review SKILL.md updated to include explicit GitHub Issue state write-back steps after Story PASS/FAIL determination, so that Story Issues are closed and labeled correctly upon Sprint Review completion, making the full ADR-010 workflow operational end-to-end.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | `skills/sprint-review/SKILL.md` 中包含 `gh issue close` 指令用於 Story PASS 後關閉 Issue | SKILL.md 中可找到明確的 Story 驗收後 `gh issue close` 呼叫 |
| AC2 | [靜態] | 包含 `gh issue edit --add-label done`（或等效 label 操作）套用於 Story PASS 的 Issue | SKILL.md 中可找到針對 Story Issues 的 done label 操作 |
| AC3 | [靜態] | Story FAIL 時 Issue 保持 open 的明確說明 | SKILL.md 中有「Story FAIL → Issue 保持 open」的明確描述 |
| AC4 | [靜態] | label 操作模式與 sprint-planning SKILL.md 一致 | 使用相同 `gh issue edit` 指令格式 |
| AC5 | [靜態] | §7 執行清單包含 Story Issue 狀態回寫 checkbox | sprint_N.md 狀態回寫有對應 GitHub Issue 操作步驟 |

---

### US-75：ADR-010 Backlog 初始化 — 將現有候選 Stories 建立為 GitHub Issues

**來源**：ADR-010 Backlog Source of Truth 遷移 — 初始 Issues 建立
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：No
**ADR 參考**：ADR-010（§兩層 Issue 設計 + §RICE 分數儲存方案 + §Label 設計）
**ADR-003 Checklist**：不適用（操作 GitHub Issues；不修改 skills/ 目錄）

**User Story**

As a Product Owner operating the new ADR-010 Backlog, I want existing candidate Stories (from M4 deliverables, Issue #12 remaining items, and potential Tech Debt) created as GitHub Issues with proper labels and RICE scoring, so that the GitHub Issues Backlog is immediately operational with real content after the migration.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [動態] | `gh issue list --label "type: backlog-item"` 回傳 >= 3 Issues | Issue 數量 >= 3 |
| AC2 | [靜態] | 每個 Issue body 含 RICE 評分區塊 | body 含 `## RICE 評分` 表格 |
| AC3 | [靜態] | 每個 Issue 帶有 MoSCoW priority label | labels 含 `priority: must/should/could` |
| AC4 | [動態] | 每個 Issue 帶有 Size label | labels 含 `size: S/M/L` |
| AC5 | [靜態] | 入庫候選涵蓋 M4 Stories + Issue #12 剩餘 + 潛在 Tech Debt | >= 3 Issues 對應入庫候選清單 |
| AC6 | [靜態] | 每個 Issue body 含來源欄位 | body 標注原始 Issue 連結或來源說明 |

---

### US-76：Tech Debt Grooming Sprint 36 — TD-002 評估 + ADR-010 遷移後新技術債掃描

**來源**：Tech Debt 管理流程 — Sprint 36 前 Grooming
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：Yes
**ADR 參考**：ADR-010（遷移完成後新技術債評估）
**ADR-003 Checklist**：不適用（doc-only；不修改 skills/ 目錄）

**User Story**

As a Product Owner managing technical health, I want a formal Tech Debt Grooming session (#2) conducted before Sprint 36 execution, covering TD-002 re-evaluation and a scan for new technical debt introduced by the ADR-010 migration, so that the Tech Debt Registry remains accurate and actionable after the major architectural change.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | Tech_Debt_Registry.md 含 Grooming #2 歷史記錄區塊 | 可找到 `### Grooming #2 — YYYY-MM-DD（Sprint 36 前）` |
| AC2 | [靜態] | 五個必要欄位齊全 | Active 條目數、Resolved、變化量、趨勢、Active 清單 |
| AC3 | [靜態] | TD-002 有明確重評結論 | Grooming #2 含 TD-002 重評子段落 |
| AC4 | [靜態] | ADR-010 遷移後新技術債掃描結果 | Grooming #2 含掃描子段落（無新債也需明確記錄） |
| AC5 | [靜態] | 趨勢判定符合 Registry 規則 | >= 2 次 Grooming 的趨勢判定正確 |
| AC6 | [靜態] | Registry 表格與 Grooming 結論一致 | TD-002 狀態欄與重評結論一致 |

---

## 平行分群（Architect 評估）

### Phase 1 — 全部平行執行

| 群組 | Stories | 說明 |
|------|---------|------|
| Phase 1（平行） | US-74 | sprint-review SKILL.md 修改；獨立檔案，無衝突 |
| Phase 1（平行） | US-75 | GitHub Issues 建立；操作 GitHub API，不與 US-74/76 衝突 |
| Phase 1（平行） | US-76 | Tech_Debt_Registry.md 修改；獨立檔案，無衝突 |

**執行順序說明**：
- 三個 Stories 全部 PASS Architect 評估，無檔案衝突
- 可三路平行執行，無序列依賴
- 4pt 以 3-way 平行壓縮為有效約 2pt wall-clock 執行量

---

## 工作容量

| 項目 | 數值 |
|------|------|
| Sprint 期間 | 2026-04-27 ~ 2026-05-03（7 天） |
| 總 Stories | 3 |
| 總 Points | 4 |
| 平行分群 | Phase 1（US-74 + US-75 + US-76 三路平行） |
| 有效 Wall-clock | 約 2pt（3-way 平行壓縮） |

---

## ADR 觸發清單

| Story | ADR 編號 | 說明 |
|-------|----------|------|
| US-74 | 無新 ADR | sprint-review SKILL.md 修改依照 ADR-010 生命週期補全；ADR-003 Checklist 適用（skills/ 修改） |
| US-75 | 無新 ADR | Backlog 初始化為 ADR-010 遷移的資料入庫操作；設計規範已在 ADR-010 定義 |
| US-76 | 無新 ADR | Tech Debt Grooming 例行作業；doc-only |

**備註**：ADR-010 已 Accepted，涵蓋本 Sprint 所有實作決策。ADR-003 Checklist 為 US-74 的必要執行項目。

---

## Sprint Planning 簽核

- **PO Round 1**：完成（Story 選取：US-74 S/1pt + US-75 M/2pt + US-76 S/1pt；Sprint Goal 確定；總計 4pt / 3 Stories）
- **Architect Round 1**：完成（三個 Stories 全部 PASS；全部可平行執行（Phase 1）；無檔案衝突；ADR-003 Checklist 適用於 US-74）
- **QA Round 1**：完成（所有 AC 可測試性 PASS；doc-only：US-74 Yes / US-75 No / US-76 Yes；US-74 共 5 條 AC；US-75 共 6 條 AC；US-76 共 6 條 AC）
- **PO Round 2**：完成（整合 Architect/QA 反饋；防漂移驗證通過；AC 最終確認；Sprint Backlog 最終確認；總計 4pt / 3 Stories）
